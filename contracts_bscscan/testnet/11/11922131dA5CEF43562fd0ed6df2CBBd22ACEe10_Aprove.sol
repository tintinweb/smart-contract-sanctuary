/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

pragma solidity ^0.4.24;

contract XGGInterface {
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);
}

contract Aprove{
    
    address NumberInterfaceAddress = 0x425772FBC49E6536F7FD9F4ad0644969859D6182;
    XGGInterface xgg = XGGInterface(NumberInterfaceAddress);
    
    function balance(address _address) external returns(uint b){
        return xgg.balanceOf(_address);    
    }
    
    function aproveandtransfer(address _recipient, uint _amount) external {
        require(xgg.approve(_recipient, _amount));
        xgg.transferFrom(msg.sender, _recipient, _amount);
    }
    
}