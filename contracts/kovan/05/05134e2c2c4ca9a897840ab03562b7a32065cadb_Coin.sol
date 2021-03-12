/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

pragma solidity >=0.5.0 <0.7.0;

contract Coin {
    address public minter;
    mapping (address => uint) public balances;

    event Sent(address from, address to, uint amount);
    
    event CustomLog(string blah);

    constructor() public {
        minter = msg.sender;
    }
    
    function mint(uint amt) public {
        balances[minter] += amt;
    }
    
    function junk() public {
        emit CustomLog("junk");
    }
}