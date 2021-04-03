/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity >=0.7.0 <0.9.0;

contract Champ {
    int256 number;
    uint256 unsignedNumber = 0;
    bool boolean;
    mapping (uint256 => string) object;
    mapping (uint256 => address) nft;
    mapping (address => uint256) balance;
    address addr;
    string str;
    
    //Called when Deployed
    constructor(string memory name){
        str = name;
    }
    
    function add(uint256 amount) public {
        unsignedNumber += amount;
    } 
}