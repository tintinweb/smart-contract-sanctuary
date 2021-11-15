/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// account1: 0xdaefD5396c77433D5DD301f057b19D9AaA09eBB6
// account2: 0xEDFcf41ad1911c823f48166e1c41C9769bb9B747
// account3: 0xa7be73F35503adE9193d55Ed4909D6D28E0D812C


contract AssignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    address private owner;
    uint256 internal constant MAXSUPPLY = 1000000;
    address minter;
    uint256 supply;
    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    // TODO: specify event to be emitted on approval
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint)) allowances;
    
    // TODO: create mapping for balances

    // TODO: create mapping for allowances

    constructor() {
        // TODO: set sender's balance to total supply
        minter = msg.sender;
        balances[msg.sender] = MAXSUPPLY/2;
        emit Transfer(address(0), msg.sender, MAXSUPPLY/2);
        emit MintershipTransfer(address(0), owner);
    }

    function totalSupply() public pure returns (uint256) {
        // TODO: return total supply
        return MAXSUPPLY;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // TODO: mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require(msg.sender == minter);
        require(supply + amount <= MAXSUPPLY);
        balances[receiver] += amount;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender] >= amount);
        
        balances[msg.sender] -= amount;
        supply -= amount;
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender == minter);
        minter = msg.sender;
        emit MintershipTransfer(minter,newMinter);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        balances[msg.sender] = balances[msg.sender] -_value;
        balances[_to] = balances[_to]+ _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        balances[_from] = balances[_from] - _value;
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}