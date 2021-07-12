/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

pragma solidity ^0.4.24;




interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function decimals() external view returns (uint8);
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}


contract borrow_usdt {
    
    AggregatorInterface eth_usd = AggregatorInterface(address(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e));
    ERC20Interface deth = ERC20Interface(address(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e));
    
    
    function get()public view returns(int){
        return eth_usd.latestAnswer();
    }
    
    function _get()public view returns(int){
        return eth_usd.decimals();
    }
    
    
}