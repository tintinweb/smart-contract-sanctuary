/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// https://kovan.etherscan.io/tx/0x9c9b2dffe1be3e1f6951d0b8c513ac20d1b2b68aee312046f635ffb3cff5794e
// https://kovan.etherscan.io/tx/0x7ba424b257248aa38c23a8b6daaf8d4c23958c54e0fe468899a2f540cd867774
// https://kovan.etherscan.io/tx/0x7950d6ae360f96092c8488bf0819651e3c8b4328bc8738c73092bf38198abac8
// https://kovan.etherscan.io/tx/0xb6e8b1bbb0002c81926ad1dd07fdef88cff46ca1b644393aaa12fbd4dcd6443b
// https://kovan.etherscan.io/tx/0x148dd4dd8dff7deba64be7067f3a655513568277b204d089104d5471b558b9d8
// https://kovan.etherscan.io/tx/0x2d16cd3769b546a46085a09514217660a16d766031925e070175f513dc36b27f

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000;
    uint256 public supply = 50000;
    address public minter;

    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // TODO: create mapping for balances
    mapping(address => uint) public balances;

    // TODO: create mapping for allowances
    mapping (
     address => mapping(address => uint)
   )public allowances;

    constructor() {
        // TODO: set sender's balance to total supply
        minter = msg.sender;
        balances[minter]= supply;
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
        require((supply+amount) <= MAXSUPPLY);
        require(amount>=0);
        supply+=amount;
        balances[receiver]+=amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender]>=amount);
        require(amount>=0 && amount<=MAXSUPPLY);
        balances[msg.sender]-=amount;
        balances[address(0)]+=amount;
        emit Transfer(msg.sender,address(0),amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        require(msg.sender == minter);
        minter = newMinter;
        emit MintershipTransfer(msg.sender,newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[msg.sender]>=_value);
        require(_value >= 1 && _value<=MAXSUPPLY);
        // require(balance[minter]+1 <= MAXSUPPLY && balance[_to]+_value-1 <= MAXSUPPLY);
        balances[_to]+=_value - 1;
        balances[msg.sender]-=_value;
        balances[minter]+= 1;
        emit Transfer(msg.sender,_to,_value);
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
        require(_value >= 1 && _value<=MAXSUPPLY);
        require(_value<=balances[_from] && allowances[_from][msg.sender]>=_value);
        // require(balance[minter]+1 <= MAXSUPPLY && balance[_to]+_value-1 <= MAXSUPPLY);
        balances[_from] -= _value;
        balances[_to] += _value - 1;
        allowances[_from][msg.sender]-=_value;
        balances[minter] += 1;
        emit Transfer(_from,_to,_value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender ,_value);
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