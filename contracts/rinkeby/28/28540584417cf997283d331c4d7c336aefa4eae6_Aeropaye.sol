/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

//create a contract that show ownership
contract owned {
    address  public owner;
    
    constructor()public{
        owner = msg.sender;
        
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "I am the owner");
        _;
    }
    
    //This function enable transfer on ownership of the token 
    function transferOwnership (address newOwner) internal onlyOwner{
        owner = newOwner;
    }
   
}

contract Aeropaye is owned {
    //This is the token name
    string public name = "Aeropaye";
    //This is the token symbol
    string public symbol = "APE";
    //This is the token decimals
    uint public decimals = 2;
    //This is the token total supply
    uint256 public totalSupply;
    //This is the token balance of the owner
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed _from, uint256 _value);
    event Minted(address indexed _to, uint256 _amount);

  constructor(uint256 _initialSupply) public{

        totalSupply = _initialSupply*10**uint256(decimals);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0),msg.sender, totalSupply);
  }
  // This is the function that transfer the token to the owner
  function transfer(address to, uint256 value) public {
    require(balances[msg.sender] >= value, "Insufficient balance");
    balances[msg.sender] -= value;
    balances[to] += value;
    emit Transfer(msg.sender, to, value);
  }
  
  // This is the function that return the balance of the owner
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  // This is the function that allow the owner to approve the transfer of the token to the other address
  function approve(address _spender, uint256 _value) public {
    require(balances[msg.sender] >= _value, "Insufficient balance");
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }
  //This is the function thall allow the other address to transfer the token to the owner
  function transferFrom(address _from, address _to, uint256 _value) public {
    require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
    balances[_from] -= _value;
    balances[_to] += _value;
    allowed[_from][msg.sender] -= _value;
    emit Transfer(_from, _to, _value);
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  // This is the function that burn the token
  function burn(uint256 _value) internal onlyOwner {
    require(balances[msg.sender] >= _value, "Insufficient balance");
    balances[msg.sender] -= _value;
    emit Burn(msg.sender, _value);
  }

  // This is the function that mint the token
  function mint(address _to, uint256 _value) internal {
    balances[_to] += _value;
    emit Minted(msg.sender, _value);
  }

  // create a buy token function by minting the token to the owner
  function buyToken(uint256 _value) public payable {
    // check if the value is greater than 0
    require(_value > 0, "Value must be greater than 0");
    mint(msg.sender, _value);
    transfer(msg.sender, _value); 
    //add the value to the total supply
    totalSupply += _value;
    emit Minted(msg.sender, _value);

  }
}