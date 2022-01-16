// SPDX-License-Identifier: MIT
pragma solidity 0.8;

// Loop over all categories and call GetAttributePerCategory for each.
// Return an array of all attributes for the new mint
contract AttributesAndRarity{
    function getAttributesArray(uint256[3] memory randomNumbers, uint256[][] memory rarityArrays) public pure returns (uint256[] memory){
        uint256[] memory finalAttributes = new uint256[](randomNumbers.length); 
        for (uint256 i=0; i < randomNumbers.length; i++){
            finalAttributes[i] = (GetAttributePerCategory(randomNumbers[i], rarityArrays[i]));
        }
        return finalAttributes;
    }

    // For a category, find the attribute for the mint based on the rarityValues array.
    // Return the index value for this attribute
    function GetAttributePerCategory(uint256 randomNumber, uint256[] memory rarityValues) public pure returns (uint256){
        uint256 i = 0;
        uint256 cumulativeRarity = rarityValues[i];
        while (randomNumber < cumulativeRarity) {
            i++;
            cumulativeRarity = cumulativeRarity + rarityValues[i];
        }
        return i;
    }
    
    function getAttributesRarity() public {
        //TODO
    }

    function getRarityForAttribute(uint256[] memory avgPriceArray) public pure returns (uint256[] memory) {
        uint256 reverseValueSum = 0;
        uint256[] memory reverseArray = new uint256[](avgPriceArray.length); 
        uint256[] memory ProbabilitiesArray = new uint256[](avgPriceArray.length); 
        //For each average price, divide 1 by the price save in new array
        for (uint256 i=0; i < avgPriceArray.length; i++){
            uint256 reverseValue = (1/avgPriceArray[i]) * 10 ** 18;
            reverseArray[i] = reverseValue;
            reverseValueSum = reverseValueSum + reverseValue;
        }
        // Loop over the array again and calculate the new probabilities
        for (uint256 i=0; i < reverseArray.length; i++){
            ProbabilitiesArray[i] = (reverseArray[i]/reverseValueSum) * 100;
        }
        return ProbabilitiesArray; 
    }
}