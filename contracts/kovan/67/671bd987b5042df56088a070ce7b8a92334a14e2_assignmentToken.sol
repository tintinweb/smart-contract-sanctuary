/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    
    // specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant public MAXSUPPLY = 1000000; //1M
    uint256 public supply = 50000; //50k
    address public minter;
    
    // specify event to be emitted on transfer
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );
    
    // specify event to be emitted on approval
    event Approval(
        address indexed _owner, 
        address indexed _spender, 
        uint256 _value
    );
    
    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // create mapping for balances
    mapping (address => uint) public balances;
    
    // create mapping for allowances
    mapping (address => mapping(address => uint)) public allowances;


    constructor() {
        // set sender's balance to total supply
        balances[msg.sender] = supply;
        
        // "the original minter is the contract creator"
        minter = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        // return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require(msg.sender == minter, "you are not an authorized minter");
        require((supply + amount) <= MAXSUPPLY, "max supply exceeded");
        
        // update receiver
        balances[receiver] += amount;
        
        // update supply
        supply += amount;
        
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender] >= (amount + 1), "the amount to be burned exceed your current balance");
        require(supply >= amount, "the amount to be burned exceed current supply");
        
        // update balances
        balances[msg.sender] -= (amount + 1);
        supply -= amount;
        
        // fee
        balances[minter] += 1;
        
        // emit
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event
        minter = newMinter;
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[msg.sender] >= (_value + 1));
        
        // update balances
        balances[msg.sender] -= (_value + 1);
        balances[_to] += _value;
        
        // fee
        balances[minter] += 1;
        
        // emit 
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[_from] >= (_value + 1), "balances too low");
        require(allowances[_from][msg.sender] >= (_value + 1), "allowances too low");
        
        // update balances
        balances[_from] -= (_value + 1);
        balances[_to] += _value;
        
        // fee
        balances[minter] += 1;
        
        // update allowances
        allowances[_from][msg.sender] -= _value;
        
        // emit
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // allow `_spender` to spend `_value` on sender's behalf
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
        // return how much `_spender` is allowed to spend on behalf of `_owner`
        remaining = allowances[_owner][_spender];
        return remaining;
    }
}