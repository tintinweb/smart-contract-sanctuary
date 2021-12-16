/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

/*
 * This contract stores current Bohemian Bulldog's collection on chain. Is a helper for staking
 */

pragma solidity 0.8.10;


contract BohemianStorage {

    // Main storage variable
    mapping(uint => uint) public tokensData;
    address public owner;

    // Setting contract's owner
    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

    function initialDataUpload(uint[] calldata _data) onlyOwner external {
        for (uint i=0; i < _data.length; i+2) {
            //uint _i = stringToUint(i);
            tokensData[i] = tokensData[i];
        }
    }

    
}