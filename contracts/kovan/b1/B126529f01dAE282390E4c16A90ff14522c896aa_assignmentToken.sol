/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    
    string public constant name = 'assignmentToken Nathan';
    string public constant symbol = 'aTK';
    
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    address public minter = 0x4FC12848755b7B4c9C5A276d9A123be9067aa176;

    uint256 public supply;

    uint256 public MAXSUPPLY=1000000;
    // TODO: specify event to be emitted on transfer

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed value
    );

    // TODO: specify event to be emitted on approval

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed value
    );

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // TODO: create mapping for balances

    mapping (address => uint256) public balances;

    // TODO: create mapping for allowances

    mapping (address => mapping (address => uint256)) allowances;

    constructor() {
        // TODO: set sender's balance to total supply
        minter=msg.sender;
        supply=50000;
        balances[msg.sender]=supply;
    }

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return supply;
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
        balances[receiver]+=amount;
        supply+=amount;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender]>=amount);
        balances[msg.sender]-=amount;
        balances[address(0)]+=amount;
        supply-=amount;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender==minter);
        minter=newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[msg.sender]>=_value);
        require(_value>=1);
        balances[msg.sender]-=_value;
        balances[_to]+=_value-1;
        balances[minter]+=1;
        emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[_from]>=_value);
        require(_value>=1);
        require(allowances[_from][msg.sender]>=_value);
        balances[_from]-=_value;
        balances[_to]+=_value-1;
        balances[minter]+=1;
        allowances[_from][msg.sender]-=_value;
        emit Transfer(_from, _to, _value);        
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);
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