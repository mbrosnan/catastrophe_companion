# Insolvency Algorithm Implementation Guide

## Overview
This document describes a probability-mass function (PMF) algorithm using convolution to calculate the probability that a player will become insolvent (run out of money) in the board game "Catastrophe". The algorithm efficiently computes exact probabilities without exhaustive enumeration.

## Game Mechanics

### Dice Structure
- **7 occurrence dice** (D20s) determine which storms occur
- **8 severity dice** (D6s) determine the damage amount for each storm
- Special case: Hurricane-Other and Hurricane-Florida share ONE occurrence die but have SEPARATE severity dice

### Storm Mapping
```
Die 0 → Storm 0 (Snow)
Die 1 → Storm 1 (Earthquake)
Die 2 → Storm 2 (Hurricane-Other) AND Storm 7 (Hurricane-Florida)
Die 3 → Storm 3 (Flood)
Die 4 → Storm 4 (Fire)
Die 5 → Storm 5 (Hail)
Die 6 → Storm 6 (Tornado)
```

### Payout Calculation
When a storm occurs:
- Roll its severity die (D6)
- Payout = severity_value × number_of_properties_for_that_storm
- Total payout = sum of all storm payouts

### Insolvency
Player is insolvent if: total_payout > player_money

## Algorithm Inputs

1. **player_money**: Integer (≥ 0)
   - Current money the player has

2. **property_count**: Array of 8 integers
   - Number of properties for each storm type
   - Index order: [Snow, Earthquake, Hurricane-Other, Flood, Fire, Hail, Tornado, Hurricane-Florida]

3. **storm_occurrences**: Array of 8 integers (1-20)
   - Number of sides on the D20 that trigger each storm
   - Probability of storm = occurrences[i] / 20

4. **storm_severities**: Array of 8 arrays, each containing 6 integers
   - The six face values for each storm's severity die
   - Example: [[1,2,2,3,4,5], [2,3,3,4,5,6], ...]

## Algorithm Steps

### Step 1: Handle Edge Cases

```
IF all property_count values are 0:
    RETURN 0.0  // No properties means no payout possible

IF player_money == 0:
    // Special handling - see Edge Case section below
```

### Step 2: Pre-calculate Adjusted Severities

For each storm i (0 to 7):
```
adjusted_severities[i] = []
FOR each severity_value in storm_severities[i]:
    adjusted_severities[i].append(severity_value × property_count[i])
```

### Step 3: Initialize Probability Distribution

```
max_single_payout = maximum value in all adjusted_severities
total_cap = max_single_payout × 8  // Upper bound for total payout

// Create probability distribution array
dp = array of size (total_cap + 1) filled with 0.0
dp[0] = 1.0  // 100% probability of 0 payout initially
```

### Step 4: Process Each Storm/Die

Process storms in order, but handle the hurricane specially:

```
processed_hurricane = false

FOR i from 0 to 7:
    p_storm = storm_occurrences[i] / 20.0
    
    IF i == 2 OR i == 7:  // Hurricane storms
        IF processed_hurricane:
            CONTINUE  // Skip, already processed both together
        
        // Get both hurricane severities
        ho_severities = adjusted_severities[2]  // Hurricane-Other
        hf_severities = adjusted_severities[7]  // Hurricane-Florida
        
        // Create PMF for hurricane occurrence
        pmf = array of size (total_cap + 1) filled with 0.0
        pmf[0] = 1.0 - p_storm  // Probability hurricane doesn't occur
        
        // When hurricane occurs, both storms happen
        FOR each ho_value in ho_severities:
            FOR each hf_value in hf_severities:
                combined_payout = ho_value + hf_value
                pmf[combined_payout] += p_storm / 36.0  // 6×6 = 36 combinations
        
        processed_hurricane = true
    
    ELSE:  // Regular storm
        pmf = array of size (total_cap + 1) filled with 0.0
        pmf[0] = 1.0 - p_storm  // Probability storm doesn't occur
        
        // When storm occurs
        p_each = p_storm / 6.0  // Each die face has 1/6 probability
        FOR each value in adjusted_severities[i]:
            pmf[value] += p_each
    
    // Update dp using convolution
    dp = convolve(dp, pmf, trimmed to size total_cap + 1)
```

### Step 5: Calculate Insolvency Probability

```
insolvency_probability = sum of dp[player_money + 1] through dp[total_cap]
RETURN insolvency_probability × 100.0  // Convert to percentage
```

## Convolution Implementation

The convolution operation combines two probability distributions:

```
FUNCTION convolve(dp, pmf, max_size):
    result = array of size (length(dp) + length(pmf) - 1) filled with 0.0
    
    FOR i from 0 to length(dp) - 1:
        IF dp[i] > 0:  // Skip zero probabilities for efficiency
            FOR j from 0 to length(pmf) - 1:
                IF pmf[j] > 0:
                    result[i + j] += dp[i] × pmf[j]
    
    // Trim to max_size
    RETURN first max_size elements of result
```

## Edge Case: Player Money = 0

When player has no money, any storm with properties causes insolvency:

```
IF player_money == 0:
    no_relevant_storm_prob = 1.0
    
    // Check each die
    FOR die_idx from 0 to 6:
        IF die_idx == 2:  // Hurricane die
            IF property_count[2] > 0 OR property_count[7] > 0:
                // Hurricane die affects properties
                no_relevant_storm_prob *= (1 - storm_occurrences[2] / 20.0)
        ELSE:
            // Other dice map directly to storms
            IF property_count[die_idx] > 0:
                no_relevant_storm_prob *= (1 - storm_occurrences[die_idx] / 20.0)
    
    RETURN (1 - no_relevant_storm_prob) × 100.0
```

## Example Walkthrough

### Simple Example: Single Storm
```
player_money = 10
property_count = [0, 0, 0, 0, 2, 0, 0, 0]  // Only Fire (index 4) has 2 properties
storm_occurrences = [1, 1, 1, 1, 4, 1, 1, 1]  // Fire: 4/20 = 20% chance
storm_severities[4] = [1, 2, 2, 3, 4, 5]

Step 1: adjusted_severities[4] = [2, 4, 4, 6, 8, 10]
Step 2: dp = [1.0, 0, 0, ..., 0]
Step 3: Process Fire storm
    - pmf[0] = 0.8 (80% no fire)
    - pmf[2] = 0.0333 (20% × 1/6)
    - pmf[4] = 0.0333
    - pmf[6] = 0.0333
    - pmf[8] = 0.0333
    - pmf[10] = 0.0333
Step 4: After convolution, dp has probabilities for each payout
Step 5: Sum dp[11] onwards = 0% (no payout exceeds 10)
```

### Hurricane Example
```
player_money = 15
property_count = [0, 0, 2, 0, 0, 0, 0, 3]  // Hurricane-Other: 2, Hurricane-Florida: 3
storm_occurrences = [1, 1, 3, 1, 1, 1, 1, 3]  // Hurricane: 3/20 = 15% chance
storm_severities[2] = storm_severities[7] = [1, 2, 2, 3, 4, 5]

When hurricane occurs (15% chance):
- Both storms roll severity
- Example: Other rolls 3 (×2 properties = 6), Florida rolls 4 (×3 properties = 12)
- Total payout = 6 + 12 = 18, which exceeds player_money
- This specific combination has probability: 0.15 × (1/6) × (1/6) = 0.00417
```

## Implementation Notes

1. **Floating-point precision**: Use double precision for probability calculations

2. **Array sizing**: The total_cap calculation ensures arrays are large enough but not excessive

3. **Efficiency optimizations**:
   - Skip zero probabilities in convolution
   - Pre-multiply severities by property counts
   - Process hurricane storms together

4. **Validation**:
   - Ensure storm_occurrences values are between 1 and 20
   - Ensure all inputs are non-negative integers
   - Result should be between 0% and 100%

5. **Testing**: Verify edge cases:
   - No properties → 0% insolvency
   - Player money = 0 with properties → Special calculation
   - Very high player money → 0% or very low insolvency

This algorithm provides exact probabilities and is significantly faster than exhaustive enumeration, especially for scenarios with many properties.