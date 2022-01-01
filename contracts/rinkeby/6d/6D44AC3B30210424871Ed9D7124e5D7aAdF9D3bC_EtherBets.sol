// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "hardhat/console.sol";
 
contract EtherBets{ // how do I name this..
    /**
     * The name of this lottery's instance.
     */
    string public name;
    
    /**
     * The cost in ETH or MATIC to place a bet.
     */
    uint256 public betCost;
    
    /**
     * The largest number that can be picked/drawn (up to 255).
     */
    uint8 public maximumNumber;

    /**
     * How many numbers must be picked in a bet. 
     */
    uint8 public picks;

    uint8[] public winningNumbers;
    
    /**
     * A number representing the draw, it is incremented after each draw.
     */
    uint256 public draw;

    /**
     * Maps a bet to the addresses that made them.
     * The bet is the keccak256(abi.encode(arr, n)), where arr
     * is an ascending uint8 array with the numbers chosen by the user,
     * and n is the number of the draw.
     */
    mapping(uint => address[]) public betToAddresses;

    /**
     * Stores the time in seconds of the last draw.
     */
    uint256 lastDrawTime;

    /**
     * Stores the minimum wait time in seconds between draws.
     */
    uint256 timeBetweenDraws;

    constructor(string memory _name, uint _betCost, uint8 _maximumNumber, uint8 _picks, uint256 _timeBetweenDraws) {
        name = _name;
        betCost = _betCost;
        maximumNumber = _maximumNumber;
        picks = _picks;
        timeBetweenDraws = _timeBetweenDraws;
    }
 
    /**
     * Checks if an array input matches the requirements of this contract.
     */
    function checkRequirements(uint8[] memory arr) public view{
        require(ascending(arr), "Numbers must be unique and in ascending order.");
        require(inAcceptableRange(arr), "Numbers must be larger than 0 and less than or equal to maximumNumber.");
        require(arr.length == picks, "Numbers must match expected length.");
    }
    /**
     * Checks if the numbers in the array are in the acceptable range.
     */
    function inAcceptableRange(uint8[] memory arr) public view returns (bool){
        for(uint8 i = 0; i < arr.length; i++){
            if(arr[i] == 0 || arr[i] > maximumNumber){
                return false;
            }
        }
        return true;
    }

    /**
     * Checks if an array is in ascending order. 
     */

    function ascending(uint8[] memory arr) public pure returns (bool){
        for(uint8 i = 0; i < arr.length - 1; i++){
            if(arr[i + 1] <= arr[i]){
                return false;
            }
        }
        return true;
    }

    /**
     * Checks if arr contains n.
     */

    function contains(uint8 n, uint8[] memory arr) public pure returns (bool){
        for(uint8 i = 0; i < arr.length; i++){
            if(arr[i] == n){
                return true;
            }
        }
        return false;
    }

    /**
     * Returns the index to insert a number, used to create an ascending array.
     * Example: n = 5, arr = [1 4 9 10 0] -> returns 2 so that the array will be [1 4 5 9 10].
     */

    function findInsertIndex(uint8 n, uint8[] memory arr) public pure returns (uint8){
        for(int8 i = int8(uint8(arr.length) - 1); i >= 0; i--){
            if(n > arr[uint8(i)] && arr[uint8(i)] != 0){
                return uint8(i + 1);
            }
        }
        return 0;
    }

    /**
     * Inserts n at index at, shifts the other values to the right. Example:
     * arr = [1 5 7 9 0 0], at = 2, n = 6 ->  shiftedArr = [1 5 6 7 9 0].
     */
    function insertAt(uint8[] memory arr, uint8 at, uint8 n) public pure returns (uint8[] memory){
        for(uint8 i = uint8(arr.length - 1); i > at; i--){
            arr[i] = arr[i - 1];
        }
        arr[at] = n;
        return arr;
    }

    /**
     * Expands randomValue into n random, unique numbers, in ascending order.
     */
    function expand(uint256 randomValue) public view returns (uint8[] memory expandedValues){
        expandedValues = new uint8[](picks);
        
        uint8 inserted = 0;
        uint256 j = 0;

        while(inserted < picks){
            uint8 value = uint8(uint256(keccak256(abi.encode(randomValue, j))) % maximumNumber + 1);
            if(contains(value, expandedValues)){
                j++;
                continue;
            }

            else{
                uint8 at = findInsertIndex(value, expandedValues);
                expandedValues = insertAt(expandedValues, at, value);
                inserted++;
                j++;
            }
        }
        
        return expandedValues;
    }

    function drawNumbers(uint256 randomValue) public{
        require(block.timestamp - lastDrawTime > timeBetweenDraws, "You must wait longer before another draw is available.");
        winningNumbers = expand(randomValue);
        distributePrize();
        draw++;
    }

    /**
    * To test wins. 
     */

    function drawNumbersRigged(uint8[] memory numbers) public{
        require(block.timestamp - lastDrawTime > timeBetweenDraws, "You must wait longer before another draw is available.");
        checkRequirements(numbers);
        winningNumbers = numbers;
        distributePrize();
        draw++;
    }

    function placeBet(uint8[] memory numbers) public payable{
        require(msg.value == betCost, "msg.value does not match betCost");
        checkRequirements(numbers);
        betToAddresses[uint(keccak256(abi.encode(numbers, draw)))].push(msg.sender);
    }

    function distributePrize() internal{
        uint winners = betToAddresses[uint(keccak256(abi.encode(winningNumbers, draw)))].length;        
        if(winners == 0){
            return;
        }
        uint splitPrize = address(this).balance / winners; // have to learn how to calculate this correctly.
        for(uint i = 0; i < winners; i++){
            address payable a = payable(betToAddresses[uint(keccak256(abi.encode(winningNumbers, draw)))][i]);
            (bool sent, bytes memory data) = a.call{value: splitPrize}("");
            require(sent, "Failed to send Ether");
        }
    }
}