/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

pragma solidity ^0.4.24;

contract dynamicarray { 

    uint public constant MaxNumber = 50;

    uint[] numbers;

    function randomnumber() public returns (uint){
        uint random = uint(keccak256(block.timestamp)) % MaxNumber +1;
        for(uint i = MaxNumber; i > numbers.length; i++){
            numbers.push(random);  
            return  random;
        }
    }
    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
    }
    return expandedValues;
}

function expandX(uint256 randomValue, uint256 n, uint256 x) public pure returns (uint256) {
    
    uint256[] memory expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
    }
    return expandedValues[x];
}


    function getnumbers() public view returns(uint[]){
        return  numbers;
    }
    function getnumber() public view returns(uint){
        return  numbers[2];
    }
}