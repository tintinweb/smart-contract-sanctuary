pragma solidity ^0.5.10;
// SPDX-License-Identifier: CC-BY-SA-2.1-JP
import "./SafeMath.sol";
import "./ownable.sol";

contract USDZtoken is ownable {
    using SafeMath for uint;
    
//****************************************************************************
//* Variables
//****************************************************************************
    string _name;
    string _symbol;
    uint8 _decimals;
    uint _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

//****************************************************************************
//* Events
//****************************************************************************
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    event Mint(address _to, uint _amount);
    
//****************************************************************************
//* Main Functions
//****************************************************************************
    constructor() public {
        _name = 'Zheton';
        _symbol = 'USDZ';
        _decimals = 18;
        _totalSupply = 0;
        balances[admin] = _totalSupply;
    }

// Outputs the name of the token.
    function name() public view returns(string memory) {
        return(_name);
    }
    
// Outputs the symbol of the token.
    function symbol() public view returns(string memory) {
        return(_symbol);
    }
    
// Outputs the number of deciaml places in the token.
    function decimals() public view returns(uint8) {
        return(_decimals);
    }

// Outputs total supply of the token. 
    function totalSupply() public view returns(uint) {
        return(_totalSupply);
    }

// Outputs the token balance of _owner parameter address.
    function balanceOf(address _owner) public view returns(uint256) {
        return(balances[_owner]);
    }
    
// Transfers _amount tokens from the sender to the destination _to address.
    function transfer(address _to, uint256 _amount) public returns(bool) {
        require(_amount > 0,"Invalid amount.");
        require(_amount <= balanceOf(msg.sender),"Out of balance.");
        require(_to != address(0),"Invalid address.");
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return(true);
    }
    
// Transfers _amount tokens from _from address (deligated address) to the destionation _to address.
    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) {
        require(_amount <= balanceOf(_from),"Transfer value is out of balance.");
        require(_amount <= allowed[_from][msg.sender],"Transfer value is not allowed.");
        require(_to != address(0),"Receiver value is not valid.");
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        emit Transfer(_from, _to, _amount);
        return(true);
    }
    
// Delegates the _spender address to transfer maximum _amount tokens.
    function approve(address _spender, uint256 _amount) public returns(bool) {
        require(_spender != address(0),"Spender address is not valid.");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return(true);
    }
    
// get the remained amount that _owner address delegated the _spender address.
    function allowance(address _owner, address _spender) public view returns(uint256) {
        return allowed[_owner][_spender];
    }
    
// Increases delegation of _spender address by _addedValue tokens.
    function increaseAllowance(address _spender, uint256 _addedValue) public returns(bool) {
        require(_spender != address(0),"Spender address is not valid.");
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return(true);
    }

// decreases delegation of _spender address by _subtractedValue tokens.
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns(bool) {
        require(_spender != address(0),"Spender address is not valid.");
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].sub(_subtractedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return(true);
    }

//
    function mint(uint _amount) public returns(bool) {
        require(_amount > 0,"Amount is zero.");
        balances[admin] = balances[admin].add(_amount);
        _totalSupply = _totalSupply.add(_amount);
    }
    
    function burn(uint _amount) public returns(bool) {
        require(_amount > 0,"Amount is zero.");
        require(balances[admin] >= _amount,"Insufficient amount.");
        balances[admin] = balances[admin].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
    }
    
}