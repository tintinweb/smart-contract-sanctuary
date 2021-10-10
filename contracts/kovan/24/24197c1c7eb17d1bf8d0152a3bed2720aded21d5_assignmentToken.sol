/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256          supply    =   50000;
    uint256 constant MAXSUPPLY = 1000000;
    address public minter;
    // other constants
    uint256 constant transFee = 1;
    address constant burnerAddress = address(0);
    // event to be emitted on transfer
    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );
    // event to be emitted on approval
    event Approval(
        address indexed _owner,
        address indexed _spender, 
        uint256 _value
    );
    // event to be emitted on mintership transfer
    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // mapping for balances
    mapping (address => uint) public balances;
    // mapping for allowances
    mapping (
      address => mapping(address => uint)
    ) public allowances;

    constructor() {
        // set sender's balance to total supply
        balances[msg.sender] = supply;
        // set minter to be the sender
        minter = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        // return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // mint tokens by updating receiver's balance and total supply
        // only minter can mint
        require(msg.sender == minter);
        // total supply must not exceed `MAXSUPPLY`
        uint256 newSupply = supply + amount;
        require(newSupply <= MAXSUPPLY);
        supply = newSupply;
        balances[receiver] += amount;
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        // burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
        require(balances[msg.sender] >= amount);        
        balances[msg.sender]    -= amount;
        balances[burnerAddress] += amount;
        //update supply
        supply -= amount;
        return true;

    }

    function transferMintership(address newMinter) public returns (bool) {
        // transfer mintership to newminter
        // only incumbent minter can transfer mintership
        require(msg.sender == minter);
        address previousMinter = minter;
        minter = newMinter;
        emit MintershipTransfer(previousMinter, newMinter);
        return true;
    }

    function transfer_helper(
        address _from,
        address _to, 
        uint256 _value) private returns (bool) {
        // transfer `_value` tokens from _from to `_to`

        // sender needs to have enough tokens  
        require(balances[_from] >= _value);
        uint256 transferValue = _value - transFee;
        // transfer value needs to be sufficient to cover fee
        require(transferValue >= 0);
        // perform actual transfer
        balances[_from] -= _value;
        balances[_to]        += transferValue;
        balances[minter]     += transFee;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // transfer `_value` tokens from sender to `_to`
        return transfer_helper(msg.sender, _to,_value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        // transfer `_value` tokens from `_from` to `_to`
        //  `_from` needs have allowed sender to spend on his behalf
        require(allowances[_from][msg.sender] >= _value);
        bool transfer_result = transfer_helper(_from,_to,_value);
        if (transfer_result) {
            allowances[_from][msg.sender] -= _value;
        }
        return transfer_result;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
        public view returns (uint256 remaining) {
        // return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances[_owner][_spender];
    }
}