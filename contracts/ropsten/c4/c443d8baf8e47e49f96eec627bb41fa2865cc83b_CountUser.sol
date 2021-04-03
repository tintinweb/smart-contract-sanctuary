/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity >=0.7.0 <0.9.0;
//use for bitkub day
contract CountUser {
    uint256  s;
    address owner;
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }
    constructor(uint256 init)public{
       s = init;
       owner = msg.sender;
    }
    function add(uint256 val)public onlyOwner{
       s += val;
    }
    function get() public view  returns (uint256){
       return s;
    }
}