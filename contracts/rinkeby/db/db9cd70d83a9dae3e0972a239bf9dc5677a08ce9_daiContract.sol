/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

pragma solidity ^0.4.24;

contract daiContract {

    uint value;
    string name = 'dd';
    string symbol = '123456';
    
    constructor (uint _p) public {
        value = _p;
    }

    function setP(uint _n) payable public {
        value = _n;
    }

    function setNP(uint _n) public {
        value = _n;
    }

    function get () view public returns (uint) {
        return value;
    }
    
    function getName() public view returns (string) {
        return name;
    }
    
     function getSymbol() public view returns (string) {
        return symbol;
    }
    function getBalance(address addr) constant public returns (uint){
        return addr.balance;   // balance属性(余额)
    }
}