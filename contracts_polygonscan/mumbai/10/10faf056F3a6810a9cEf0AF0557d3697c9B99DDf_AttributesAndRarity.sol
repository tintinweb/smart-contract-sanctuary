// SPDX-License-Identifier: MIT
pragma solidity 0.8;

// Loop over all categories and call GetAttributePerCategory for each.
// Return an array of all finalattributes for the new mint
contract AttributesAndRarity{


    //TODO: REMOVE HARDED (3) NUMBER OF CATEGORIES
    function getAttributesArray(uint256[5] memory randomNumbers, uint256[][] memory rarityArrays) public pure returns (uint256[] memory){
        uint256[] memory finalAttributes = new uint256[](randomNumbers.length); 
        for (uint256 i=0; i < randomNumbers.length; i++){
            finalAttributes[i] = getAttributePerCategory(randomNumbers[i], rarityArrays[i]);
        }
        return finalAttributes;
    }

    // For a category, find the attribute for the mint based on the rarityValues array.
    // Return the index value for this attribute
    function getAttributePerCategory(uint256 randomNumber, uint256[] memory rarityValues) public pure returns (uint256){
        uint256 i = 0;
        uint256 cumulativeRarity = rarityValues[i];
        while (randomNumber >= cumulativeRarity) {
            cumulativeRarity += rarityValues[i];
            i++;
        }
        return i;
    }
    
    // //TODO: REMOVE HARDED (3) NUMBER OF CATEGORIES
    // function getAttributesRarity(uint256[][] memory allAvgPriceArrays) internal pure returns (uint256[] memory) {
    //     uint256[] memory rarityForAllCategories = new uint256[](allAvgPriceArrays.length); 

    //     for (uint256 i=0; i < allAvgPriceArrays.length; i++){
    //         rarityForAllCategories[i] = getRarityForCategory(allAvgPriceArrays[i]);
            
    //     }
    //     return rarityForAllCategories;
    //     //TODO
    // }


    // TODO HOW MANY ZEROES? NUMBER TOO BIG IS AN ISSUE
    function getRarityForCategory(uint256[] memory avgPriceArray) public pure returns (uint256[] memory) {
        uint256 reverseValueSum = 0;
        uint256[] memory reverseArray = new uint256[](avgPriceArray.length); 
        uint256[] memory ProbabilitiesArray = new uint256[](avgPriceArray.length); 
        //For each average price, divide 1 by the price save in new array
        for (uint256 i=0; i < avgPriceArray.length; i++){
            uint256 reverseValue = ((1 * 10 ** 8)/avgPriceArray[i]);
            reverseArray[i] = reverseValue;
            reverseValueSum += reverseValue;
        }
        // Loop over the array again and calculate the new probabilities
        // TODO Fix rounding issue
        for (uint256 i=0; i < reverseArray.length; i++){
            ProbabilitiesArray[i] = (reverseArray[i] * 100)  / reverseValueSum;
        }
        return ProbabilitiesArray; 
    }
}