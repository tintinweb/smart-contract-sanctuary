/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity ^0.4.26;
contract DDHCoin
{
    address public minter;
    string public coinName="DDHCoin";
    string public coinUnit="DDH";
    
    mapping(address=>uint256) public balances;
    constructor() public { minter=msg.sender;}
    
    function mint(uint256 amount) public
    {
        require(msg.sender==minter);
        balances[minter]+=amount;
    }
    
    function send(address receiver,uint256 amount) public
    {
        require(amount<=balances[msg.sender],"not money.");
        balances[msg.sender]-=amount;
        balances[receiver]+=amount;
    }
    
    function balancesOf(address _owner) public constant returns (uint256)
    {
        return balances[_owner];
    }
    
    function transfer(address _to,uint256 _value) public returns (bool success)
    {
        if(balances[msg.sender]>=_value&&_value>0)
        {
            balances[msg.sender]-=_value;
            balances[_to]+=_value;
       
            return true;
        }
        else
        {
         return false;   
        }

        
        
    }
}