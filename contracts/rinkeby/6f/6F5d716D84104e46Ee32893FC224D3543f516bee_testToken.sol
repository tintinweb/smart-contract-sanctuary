/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity ^0.8.3;


abstract contract ERC20Basic {

    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint);
    function allowance(address tokenOwner, address spender)
    public virtual view returns (uint);
    function transfer(address to, uint tokens) public virtual returns (bool);
    function approve(address spender, uint tokens)  public virtual returns (bool);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool);

}

contract testToken {
    address public manager;
    address tokenAddress;
    ERC20Basic token;

    constructor() {
        manager = msg.sender;
    }
    
    function setTokenAddress(address _tokenAddress) public {
        tokenAddress = _tokenAddress;
        token = ERC20Basic(tokenAddress);
    }
    
    function transferToken(address to, uint value) public returns(bool){
       return token.transfer(to,value);
    }

}