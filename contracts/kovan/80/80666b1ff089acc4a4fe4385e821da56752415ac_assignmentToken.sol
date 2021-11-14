/**
 *Submitted for verification at Etherscan.io on 2021-11-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    
    uint256 supply = 50000; // Setting the initial supply.
    
    uint256 constant MAXSUPPLY = 1000000; // Specifying the maximum supply.
    uint256 constant fee = 1; // Specifying the fee.

    address public minter; // Setting the minter to be a public variable (visible to the blockchain)
    
    // event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
     // event to be emitted on mintership transfer
    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    // mapping for balances
    mapping(address => uint256) public balances;
    
    // mapping for allowances
    mapping(address => mapping(address => uint256)) public allowances;
    
    constructor() {
        
        balances[msg.sender] = supply; // Setting the contract creator to have balance equal to supply
        minter = msg.sender;  // Setting the original minter to be the contract creator.
        
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
        require((supply + amount) <= MAXSUPPLY);
        require(msg.sender == minter);
        
        balances[receiver] += amount;
        supply += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // burn tokens by sending tokens to `address(0)`
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        supply -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // transfer mintership to newminter
        require(msg.sender == minter);
        
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
         // transfer `_value` tokens from sender to `_to`
        require(_value <= balances[msg.sender]);
        require(fee <= _value);
        
        balances[msg.sender] -= _value;
        balances[_to] += _value - fee;
        balances[minter] += fee;
        emit Transfer(msg.sender, _to, _value - fee); // Since this is a log statement, we're interested in printing how much was transfered.
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        require(_value <= balances[_from]);
        require(_value <= allowances[_from][msg.sender]);
        require(fee <= _value);
        
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        balances[_to] += _value - fee;
        balances[minter] += fee; 

        emit Transfer(_from, _to, _value - fee);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        //  allow `_spender` to spend `_value` on sender's behalf
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
        return allowances[_owner][_spender];
    }
}