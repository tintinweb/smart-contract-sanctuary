/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity ^0.4.16;

contract TokenERC20{

    //Contract owner
    address public owner;
    
    //Token name
    string public name;
    
    //Unit of token
    string public symbol;

    //decimal
    uint8 public decimals = 6;

    //Total issue of token
    uint256 public totalSupply;
    

    //Using mapping to save the balance of each address, erc20 standard
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    //Notify client of transaction
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //Notify client of token destruction
    event Burn(address indexed _owner, uint256 _value);
    

    //Contract initialization
    function TokenERC20(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        owner = msg.sender;
        //Initial issue quantity
        totalSupply = initialSupply*10**uint256(decimals);
        //Founder holding
        balanceOf[owner] = totalSupply;
        //token name
        name = tokenName;
        //symbol
        symbol = tokenSymbol;
    }

    //Number of additional tokens
    function mint(uint256 _value) public {
        //Only the creator of the smart contract instance can issue additional shares
        require(msg.sender == owner);
        require(totalSupply + _value > totalSupply);
        require(balanceOf[owner] + _value > balanceOf[owner]);
        balanceOf[owner] += _value;
    }

    //Transfer to designated account
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0));
        require(msg.sender != _to);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        Transfer(msg.sender, _to, _value);
        return true;
    }

    //Transfer from one account to another
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        return true;
    }

    //Destroy the specified amount of tokens in the founding account
    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender == owner);
        require(totalSupply >= _value);
        require(balanceOf[owner] >= _value);
        balanceOf[owner] -= _value;
        totalSupply -= _value;
        Burn(owner, _value);
        return true;
    }
}