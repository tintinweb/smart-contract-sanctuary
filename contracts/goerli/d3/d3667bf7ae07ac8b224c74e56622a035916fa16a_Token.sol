/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.4;

//start of token contract
contract Token {
    string public name;
    string public symbol;
    uint public decimals;
    uint public _totalSupply;
    
    //define Approval and Transfer events
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    //define associative array (dictionary) to store acount addresses (keys) and adress token values (values) as object "balances"
    mapping(address => uint256) balances;

    //define associative array (dictionary) to store account addresses approved to withdrawel (keys) and approved amount of token transfer (values) as object 'allowed'
    mapping(address => mapping (address => uint256)) allowed;
    
    constructor() {
        name = 'Acorns';
        symbol = 'ACRN';
        decimals = 18;
        _totalSupply = 1000000000000 * 10 ** decimals;
        balances[msg.sender] = _totalSupply;
    }
    
    //return the total number of all tokens in circulation
    function totalSupply() public view returns (uint256 Acorns) {
        return _totalSupply;
    }
    
    //return the current token balance of a specific account
    function balanceOf(address _account) public view returns (uint256 Acorns) {
        return balances[_account];
    }
    
    //transfer tokens from owner address to that of another user
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_value <= balances[msg.sender], 'Insufficient funds.');
        require(_to != address(0), 'Not a valid address.');
        require(_to != address(this), 'Not a valid address');
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    //allow owner to approve "spender" account to withdrawal tokens from his account and transfer to other users (often used for token marketplace scenereo)
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), 'Not a valid address.');
        require(_spender != address(this), 'Not a valid address.');
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    //returns the current approved number of tokens by an owner to a specific spender (set in approve function)
    function allowance(address _owner, address _spender) public view returns (uint256 Acorns) {
        return allowed[_owner][_spender];
    }
    
    //verify the owner has enough tokens and the spender has enough withdrawal allowance left, then subtract from owner's account and spender's withdrawal allowance
    function transferFrom(address _owner, address _buyer, uint256 _value) public returns (bool success) {
        require(_value <= balances[_owner], 'Insufficient funds.');
        require(_value <= allowed[_owner][msg.sender], 'Transfer value exceeds spender allowance.');
        require(_buyer != address(0), 'Not a valid address.');
        require(_buyer != address(this), 'Not a valid address.');
        balances[_owner] -= _value;
        allowed[_owner][msg.sender] -= _value;
        balances[_buyer] += _value;
        emit Transfer(_owner, _buyer, _value);
        return true;
    }
    
    //Increase the allowance of a "spender"
    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool success) {
        require(_spender != address(0), 'Not a valid address.');
        require(_spender != address(this), 'Not a valid address');
        allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    //Decrease the allowance of a "spender" 
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool success) {
        require(_spender != address(0), 'Not a valid address.');
        require(_spender != address(this), 'Not a valid address.');
        allowed[msg.sender][_spender] -= _subtractedValue;
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    //mint tokens (Why should this be an internal function?)
    function mint(address _account, uint256 _value) public returns (bool success) {
        require(_account != address(0), 'Not a valid address.');
        require(_account != address(this), 'Not a valid address');
        _totalSupply += _value;
        balances[_account] += _value;
        emit Transfer(address(0), _account, _value);
        return true;
    }
    
    //burn tokens (Why should this be an internal function?)
    function burn(address _account, uint256 _value) public returns (bool success) {
        require(_account != address(0), 'Not a valid address.');
        require(_account != address(this), 'Not a valid address.');
        require(_value <= balances[_account]);
        _totalSupply -= _value;
        balances[_account] -= _value;
        emit Transfer(_account, address(0), _value);
        return true;
    }
}