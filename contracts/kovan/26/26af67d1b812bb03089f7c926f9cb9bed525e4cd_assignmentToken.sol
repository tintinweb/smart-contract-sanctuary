/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY=1000000;
    address public minter;
    uint256 public supply;


    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);


    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(
        address indexed previousMinter, 
        address indexed newMinter
    );

    // TODO: create mapping for balances
    mapping(address=>uint) public balances;

    // TODO: create mapping for allowances
    mapping(address=>mapping(address=>uint)) public allowances;

    constructor() public {
        // TODO: set sender's balance to total supply
        supply=50000;
        balances[msg.sender]=supply;
        minter = msg.sender;
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
        balances[receiver] += amount;
        supply += amount;
        require(supply<= MAXSUPPLY);
        //emit Transfer(address(0), receiver, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender]>=amount);
        address burner = msg.sender;
        balances[burner]-=amount;
        supply-=amount;
        emit Transfer(burner, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // TODO: transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        minter = newMinter;
        emit MintershipTransfer(minter,newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        require(balances[msg.sender] >= 1, "ERC20: balance cannot cover the transaction fee");
        balances[msg.sender]-=(_value+1);
        balances[_to] += _value;
        balances[minter] += 1;
        emit Transfer(msg.sender,_to,_value);
        emit Transfer(msg.sender,minter,1);
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
        require(balances[_from]>=_value,"balances too low");
        require(balances[_from]>=1,"balances too low and cannot cover the transaction fee");
        require(allowances[_from][msg.sender]>=_value,"allowances too low");
        require(allowances[_from][msg.sender]>=1,"allowances too low and cannot cover the transaction fee");
        balances[_from]-=(_value+1);
        allowances[_from][msg.sender]-=(_value+1);
        balances[_to]+=_value;
        balances[minter]+=1;
        emit Transfer(_from,_to,_value);
        emit Transfer(_from,minter,1);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        remaining=allowances[_owner][_spender];
        return remaining;
    }
}