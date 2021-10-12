/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

pragma solidity ^0.5.17;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 

contract ERC20Interface {
    function totalSupply() public returns (uint);
    function balanceOf(address tokenOwner) public returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


contract USDTInterface{
    uint public _totalSupply;
    function totalSupply() public returns (uint);
    function balanceOf(address who) public returns (uint);
    function transfer(address to, uint value) public;
    function transferFrom(address from, address to, uint value) public;
}



contract DCTFactory {
    using SafeMath for uint;
    
    ERC20Interface DCT = ERC20Interface(address(0xe7c40137fa1EE1cdBCf9d23a0C8E4916463E2925));
    USDTInterface USDT = USDTInterface(address(0x8e23d92C97BafD1A5518A9e9aE7F4f7De796eFD0));
    
    function test()public {
        USDT.transferFrom(msg.sender,address(this),10000000);
        DCT.transfer(msg.sender,1000000000);
    }
    
    
    
    
}