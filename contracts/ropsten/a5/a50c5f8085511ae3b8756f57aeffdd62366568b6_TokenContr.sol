/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.4.24;

contract ERC20
{
    function totalSupply() public view returns (uint256);
    function balanceOf(address _who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    
    function burnToken(uint256 _value) public returns (bool);
}



contract TokenContr is ERC20{
    
    mapping (address => uint256) public balanceOfUser;
    
    uint256 totalTokens;
    string public name;
    string public symbol;
    uint256 public decimals;
    
    constructor(uint256 paramtotalTokens, string paramname, string paramsymbol, uint256 paramdecimals)
    {
        totalTokens = paramtotalTokens;
        name = paramname;
        symbol = paramsymbol;
        decimals = paramdecimals;
    }
    
    function totalSupply() public view returns (uint256)
    {
        return totalTokens;
    }
    
    function balanceOf(address _who) public view returns (uint256)
    {
        return balanceOfUser[_who];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool)
    {
        balanceOfUser[msg.sender] -= (_value * (10**decimals));
        balanceOfUser[_to] += (_value * (10**decimals));
        return true;
    }
    
    function burnToken(uint256 _value) public returns (bool)
    {
        totalTokens -= _value;
        balanceOfUser[msg.sender] -= _value;
        return true;
    }
    
}