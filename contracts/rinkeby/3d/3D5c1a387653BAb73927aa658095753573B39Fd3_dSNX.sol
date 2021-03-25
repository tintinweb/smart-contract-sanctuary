/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// File: contracts\ERC20Basic.sol

pragma solidity ^0.5.16;


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  
  constructor (address _owner) public {
    require(_owner != address(0));
    owner = _owner;
  }

  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0),"invalid address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract BasicToken is ERC20Basic {
    using SafeMath for uint256;
    
    mapping(address => uint256) balances;
    
    uint256 public _totalSupply;
    uint256 public demandFactor;
    bool public transferAllowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
     
    function totalSupply() public view returns (uint256) {
        return (_totalSupply.mul(demandFactor)).div(1 ether);
    }
    
    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */ 
    function transfer(address _to, uint256 _value) public returns (bool) {
        
        require(_to != address(0),"invalid address");
        require(_value <= balanceOf(msg.sender));
        require(transferAllowance,"Not allowed to transfer");
    
        // SafeMath.sub will throw if there is not enough balance.
        uint256 _value1 = (_value.mul(1 ether)).div(demandFactor);
        balances[msg.sender] = balances[msg.sender].sub(_value1);
        balances[_to] = balances[_to].add(_value1);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        
        return (balances[_owner].mul(demandFactor)).div(1 ether);
    
    }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

    require(_to != address(0),"invalid address");
    require(_value <= balanceOf(msg.sender),"value exceed user balance");
    require(_value <= allowed[_from][msg.sender],"value exceed allowed by user");
    require(transferAllowance,"Not allowed to transfer");
    
    uint256 _value1 = (_value.mul(1 ether)).div(demandFactor);
    balances[_from] = balances[_from].sub(_value1);
    balances[_to] = balances[_to].add(_value1);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
    emit Transfer(_from, _to, _value);
    return true;
  }

  
  function approve(address _spender, uint256 _value) public returns (bool) {
    
    require(_spender != address(0),"invalid address");
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract dSNX is StandardToken, Ownable
{
    
    string public constant name = "DAFI SNX";
    string public constant symbol = "dSNX";
    uint8 public constant decimals = 18;
    
    address public DAFIContract;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Rebase(uint256 epoch, uint256 value);
    event DAFIContractChange(address indexed oldAddress, address indexed newAddress);
    
    modifier onlyDAFI{
        require(msg.sender == DAFIContract, "Not Authorized address");
        _;
    }
    
    constructor() public Ownable(msg.sender){ 

        _totalSupply = 0;

    }
    
    function mint(uint256 _value, address _beneficiary)  external onlyDAFI{

        require(_value > 0,"invalid value entered");
        balances[_beneficiary] = balances[_beneficiary].add(_value);
        _totalSupply = _totalSupply.add(_value);
        
        emit Transfer(address(this),_beneficiary, _value);
        
    }
    
    function balanceCheck(address _beneficiary) public view returns(uint256){
        return balances[_beneficiary];
    }
    
    function burn(uint256 _value, address _beneficiary)  external onlyOwner {
        require(balanceCheck(_beneficiary) >= _value,"User does not have sufficient synths to burn");
        uint256 _value1 = (_value.mul(1 ether)).div(demandFactor);
        _totalSupply = _totalSupply.sub(_value1);
        balances[_beneficiary] = balances[_beneficiary].sub(_value1);
        
        emit Transfer(address(this),_beneficiary, _value);
    }
    
    function rebase(uint256 _demandFactor) external onlyDAFI{
        demandFactor = _demandFactor;
    }
    
    function setDAFIContract(address _address) public onlyOwner {
        require(_address != address(0),"invalid address");
        emit DAFIContractChange(DAFIContract,_address);
        DAFIContract = _address;
    }

    function enableTransfer() public onlyOwner {

        require(!transferAllowance,"Already Enabled");

        transferAllowance = true;
    }

    function disableTransfer() public onlyOwner {

        require(transferAllowance,"Already Disabled");

        transferAllowance = false;
    }
}