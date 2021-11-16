/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// ABC: 0xB5B8b9F4DdAca45786598bdE7C5bdC7516aADB22
// XYZ: 0xfa2Dc42FC141b2A83d1030f1220944caB8a991CC
// third: 0x44d7750c1DCC5ed6B6aF333e26894Dd70540762A


contract AssignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    address private owner;
    uint256 internal constant MAXSUPPLY = 1000000;
    uint256 internal constant FEE = 1;
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
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender] >= amount);
        require(msg.sender == minter);
        
        balances[msg.sender] -= amount;
        supply -= amount;
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(minter,newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(_value>1);
        require(balances[msg.sender]>_value);
        balances[msg.sender] = balances[msg.sender] -_value;
        balances[_to] = balances[_to]+ _value-1;
        balances[minter] += 1;
        emit Transfer(msg.sender, minter, 1);
        emit Transfer(msg.sender, _to, _value-1);
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
        require(_value>1);
        require(balances[msg.sender]>_value);
        balances[_from] = balances[_from] - _value;
        allowances[_from][msg.sender] = allowances[_from][msg.sender] - _value;
        balances[_to] = balances[_to]+ _value-1;
        balances[minter] += 1;
        emit Transfer(msg.sender, minter, 1);
        emit Transfer(_from, _to, _value-1);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        require(balances[msg.sender]>1);
        require(balances[msg.sender]>_value);
        allowances[msg.sender][_spender] = _value;
        balances[msg.sender] -= 1;
        balances[minter] += 1;
        emit Transfer(msg.sender, minter, 1);
        emit Approval(msg.sender, _spender, _value-1);
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