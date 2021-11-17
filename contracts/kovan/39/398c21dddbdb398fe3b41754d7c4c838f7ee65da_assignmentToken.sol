/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// https://kovan.etherscan.io/tx/0x29fa11f9e722cedb551087aacd8ad0b38a2a50c6be43a0286017036e63eeea91
// https://kovan.etherscan.io/tx/0xb41d09f872089d21a1f61b45148f712e3ac4ba9dec9ef59d4619df9f1e4fa692
// https://kovan.etherscan.io/tx/0xce044466b36638b3ceb1a9105d40247868a627d684ac60fb7f442ac52fbef222
// https://kovan.etherscan.io/tx/0x1338c1551428ad415518414c9b77bfe8cc65f056a7b25506c4bd9bdf6bcf9650
// https://kovan.etherscan.io/tx/0xc01b8fbad31a2c1b6f43f9f57ce0264272e2ff54299673aaec627dbbb5f63d0a
// https://kovan.etherscan.io/tx/0x0d5303097bc15af8fa0bb9882f6e1865270962788c786ee2f50f019b45f668bd

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
        supply -= amount;
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