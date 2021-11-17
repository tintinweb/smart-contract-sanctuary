/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

//https://remix.ethereum.org/#optimize=false&runs=200&evmVersion=null&version=soljson-v0.7.0+commit.9e61f92b.js// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 private _totalSupply = 1000000000; 
    address public minter;
    
    modifier onlyMinter{
       require(minter==msg.sender);
            _;}
            
    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(address indexed previousMinter,address indexed newMinter);

    // TODO: create mapping for balances
    mapping(address => uint) private balances;

    // TODO: create mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;

    constructor() {
        // TODO: set sender's balance to total supply
        balances[msg.sender]=_totalSupply;
        minter = msg.sender;}

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return _totalSupply;}

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];}

    function mint(address account, uint256 amount) public onlyMinter(){ // view and pure 
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        balances[account] += amount;
        emit Transfer(address(0), account, amount);}

    function burn(uint256 amount) public{
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        address account = msg.sender;
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);}

    function transferMintership(address newMinter) public onlyMinter() { 
          require(newMinter!=minter,"you are doing something wrong .....");
          MintershipTransfer(minter,newMinter);
          minter = newMinter;}

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value <= balances[msg.sender]);
        balances[_to] += _value;
        balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;}

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value <= balances[msg.sender]);
        require(allowances[_from][msg.sender] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;}

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]= _value;
        emit Approval(msg.sender, _spender, _value);
        return true;}

    function allowance(address _owner, address _spender) public view returns (uint256 remaining)    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];}
}