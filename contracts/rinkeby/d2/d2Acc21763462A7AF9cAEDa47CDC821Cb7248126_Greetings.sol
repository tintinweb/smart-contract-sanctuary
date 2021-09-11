/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

pragma solidity >=0.7.0 <0.9.0;


contract Greetings {
    
    
    mapping(address => uint256) public luckyNumber;
    
    function hello(string memory _helloInput) public pure returns(string memory) {
        return _helloInput;
    }
    function bye(string memory _byeInput) public pure returns(string memory) {
        return _byeInput;
    }
    
    function setLuckyNumber(uint256 _number) public {
        luckyNumber[msg.sender] = _number;
    }
    
}