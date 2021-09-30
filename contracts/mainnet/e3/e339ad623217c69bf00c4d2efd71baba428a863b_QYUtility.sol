/**
 *Submitted for verification at Etherscan.io on 2021-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

  library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
  
    function div(uint a, uint b) internal pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
  
    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }
  
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
  }


  contract Authorization {
    address public owner;
    bool public paused;
    mapping(address => bool) public blackListedAddresses;
    mapping(address => bool) public minterAddresses;
  
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Pause();
    event Unpause();
    event Blacklist(address indexed blackListed);
    event Whitelist(address indexed whiteListed);
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
  
    modifier onlyOwner() {
      require(msg.sender == owner, "Only Owner Can Call This Function");
      _;
    }

    modifier whenNotPaused() {
      require(!paused, "Contract Is Paused");
      _;
    }

    modifier whenPaused() {
      require(paused, "Contract Is Not Paused");
      _;
    }
    
    modifier onlyMinter() {
      require(minterAddresses[msg.sender] == true, "Only Minter Can Call This Function");
      _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
      require(newOwner != address(0), "New Address Must Not Be 0x");
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }
    
    function addMinter(address minter) onlyOwner whenNotPaused public {
        require(minterAddresses[minter] != true, "Address Is Already Minter");
        minterAddresses[minter] = true;
        emit MinterAdded(minter);
    }
    
    function removeMinter(address minter) onlyOwner whenNotPaused public {
        require(minterAddresses[minter] != false, "Address Is Not Minter");
        minterAddresses[minter] = false;
        emit MinterRemoved(minter);
    }
    
    function isMinter(address minter) public view returns (bool success) {
        return minterAddresses[minter];
    }

    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    function blackListAddress(address _address) public onlyOwner {
        require(blackListedAddresses[_address] != true, "Address Is Already BlackListed");
        blackListedAddresses[_address] = true;
        emit Blacklist(_address);
    }

    function whiteListAddress(address _address) public onlyOwner {
        require(blackListedAddresses[_address] == true, "Address Is Not BlackListed");
        blackListedAddresses[_address] = false;
        emit Whitelist(_address);
    }
  }


  contract QYUtility is Authorization {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    event IncreaseApproval(address indexed _owner, address indexed _spender, uint _oldvalue, uint _newvalue);
    event DecreaseApproval(address indexed _owner, address indexed _spender, uint _oldvalue, uint _newvalue);
    event Burn(address indexed _owner, uint _oldsupply, uint _newsupply);
    event Mint(address indexed _owner, uint _oldsupply, uint _newsupply);
    
    constructor(){
        name = "QYUtility";
        symbol= "QYU";
        decimals = 18;
        _totalSupply = _totalSupply.add(200000000000000000000000000);
        balances[msg.sender] = balances[msg.sender].add(_totalSupply);
        
        owner = msg.sender;
        paused = false;
        
        emit OwnershipTransferred(address(0), msg.sender);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint totalsupply) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint balance){
        return balances[_owner];
    }

    function transfer(address _to, uint _value) public whenNotPaused returns (bool success){
        require(blackListedAddresses[msg.sender] != true, "Sender Address Is BlackListed");
        require(balances[msg.sender] >= _value, "Sender Balance Is Low");
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused returns (bool success){
        require(blackListedAddresses[msg.sender] != true, "Sender Address Is BlackListed");
        require(blackListedAddresses[_from] != true, "_from Address Is BlackListed");
        require(balances[_from]>= _value, "From Balance Is Low");
        require(allowed[_from][msg.sender] >= _value, "Allowed Balance To Transfer Is Low");
        
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

    function approve(address _spender, uint _value) public whenNotPaused returns (bool success){
        require(blackListedAddresses[msg.sender] != true, "Sender Address Is BlackListed");
        require(blackListedAddresses[_spender] != true, "_spender Address Is BlackListed");
        
        allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining){
        return allowed[_owner][_spender];
    }
    
    function increaseApproval(address _spender, uint _value) public whenNotPaused returns (bool success){
        require(blackListedAddresses[msg.sender] != true, "Sender Address Is BlackListed");
        require(blackListedAddresses[_spender] != true, "_spender Address Is BlackListed");
        
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_value);
        
        emit DecreaseApproval(msg.sender, _spender, allowed[msg.sender][_spender].sub(_value), allowed[msg.sender][_spender]);
        
        return true;
    }
    
    function decreaseApproval(address _spender, uint _value) public whenNotPaused returns (bool success){
        require(blackListedAddresses[msg.sender] != true, "Sender Address Is BlackListed");
        require(blackListedAddresses[_spender] != true, "_spender Address Is BlackListed");
        require(allowed[msg.sender][_spender].sub(_value) >= 0, "Allowed Balance To Transfer Is Low Than _value");
        
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].sub(_value);
        
        emit DecreaseApproval(msg.sender, _spender, allowed[msg.sender][_spender].add(_value), allowed[msg.sender][_spender]);
        
        return true;
    }
    
    function burn(uint _value) public whenNotPaused returns (bool success){
        require(balances[msg.sender] >= _value, "Sender Balance Is Low");
        require(blackListedAddresses[msg.sender] != true, "Sender Address Is BlackListed");
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        
        emit Burn(msg.sender, _totalSupply.add(_value), _totalSupply);
        
        return true;
    }
    
    function mint(address _to, uint _value) public whenNotPaused onlyMinter returns (bool success){
        balances[_to] = balances[_to].add(_value);
        _totalSupply = _totalSupply.add(_value);
        
        emit Mint(_to, _totalSupply.sub(_value), _totalSupply);
        
        return true;
    }
    
  }