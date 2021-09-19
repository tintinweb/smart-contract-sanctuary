/**
 *Submitted for verification at Etherscan.io on 2021-09-19
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract MyLunch {
    string[] public foodList;
    mapping(string => uint256) private foodVoted;
    mapping(string => bool) private wasAdded;

    constructor(string[] memory initialFoodNameList) public {
        //initial food list
        foodList = initialFoodNameList;

        //initial food was added
        for (uint256 i = 0; i < initialFoodNameList.length; i++) {
            wasAdded[initialFoodNameList[i]] = true;
        }
    }

    function getFoodCount() public view returns (uint256) {
        return foodList.length;
    }

    function getVotedFoodByName(string memory foodName)
        public
        view
        returns (uint256)
    {
        return foodVoted[foodName];
    }

    function voteFoodByName(string memory foodName) public {
        foodVoted[foodName] = foodVoted[foodName] + 1;
    }

    function addFood(string memory foodName) public {
        require(!wasAdded[foodName], "food was added");
        foodList.push(foodName);
        wasAdded[foodName] = true;
    }
}