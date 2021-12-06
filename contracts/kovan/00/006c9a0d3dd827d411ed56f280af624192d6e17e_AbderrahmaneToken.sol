/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract AbderrahmaneToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 public _totalSupply = 50000;
    uint256 public constant _MAXSUPPLY = 1000000;
    address public minter;

    // specify event to be emitted on transfer
    event Transfer(address indexed from, address indexed to, uint256 value);

    // specify event to be emitted on approval
    event Approval(address indexed owner, address indexed spender, uint256 value);

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );
    // events to be emitted on minting and burning tokens
    event Mint(address indexed minter, address indexed account, uint256 value);
    event Burn(address indexed burner, address indexed account, uint256 value);

    // create mapping for balances
    mapping (address => uint256) public balances;

    // create mapping for allowances
    mapping (address => mapping (address => uint256)) public allowed;

    constructor() {
        // set sender's balance to total supply
        minter = msg.sender;
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        // return total supply
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // mint tokens by updating receiver's balance and total supply
        require(amount > 0, 'ERC20: amount is not valid');
        require(amount < (_MAXSUPPLY - _totalSupply), 'ERC20: amount is not valid');
        balances[receiver] += amount;
        _totalSupply += amount;
        emit Mint(msg.sender, receiver, amount);
        return true;
        // NOTE: total supply must not exceed `MAXSUPPLY`
    }

    function burn(address from, uint256 amount) public returns (bool) {
        // burn tokens by sending tokens to `address(0)`
        require(from != address(0), 'ERC20: from address is not valid');
        require(balances[from] >= amount, 'ERC20: insufficient balance');
        balances[from] -= amount;
        _totalSupply -= amount;
        emit Burn(msg.sender, from, amount);
        return true;
        // NOTE: must have enough balance to burn
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        require(newMinter != address(0), 'ERC20: from address is not valid');
        require(msg.sender == minter);
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // transfer `_value` tokens from sender to `_to`
        require(_to != address(0), 'ERC20: from address is not valid');
        require(_value > 0, 'ERC20: amount is not valid');
        require(_value < balances[msg.sender]+1, 'ERC20: amount is not valid');
        balances[msg.sender] -= _value + 1;
        balances[_to] += _value;
        balances[minter] += 1;
        emit Transfer(msg.sender, _to, _value);
        return true;
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // transfer `_value` tokens from `_from` to `_to`
        require(_to != address(0), 'ERC20: from address is not valid');
        require(_value > 0, 'ERC20: amount is not valid');
        require(_value <= (allowed[_from][msg.sender]-1), 'The sender is not allowed to spend this amount');
        balances[_from] -= _value + 1;
        balances[_to] += _value;
        balances[minter] += 1;
        emit Transfer(_from, _to, _value);
        return true;
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // allow `_spender` to spend `_value` on sender's behalf
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
        // NOTE: if an allowance already exists, it should be overwritten
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // return how much `_spender` is allowed to spend on behalf of `_owner`
        remaining = allowed[_owner][_spender];
        return remaining;
    }
}