/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

    // 1. TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
contract assignmentToken {
uint256 constant txnfee = 1;
uint256 constant MAXSUPPLY = 1000000;
uint256 supply = 50000;
address public minter;


    // 2. TODO: specify event to be emitted on transfer
event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
    );

    // 3. TODO: specify event to be emitted on approval
event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
    );

    event MintershipTransfer(
        address indexed previousMinter,
        address indexed newMinter
    );

    // 4. TODO: create mapping for balances
mapping (address => uint) public balances; //holds the token balance of each owner account

    // 5. TODO: create mapping for allowances
mapping (address => mapping(address => uint)) public allowances; 
        //it is like creating 3 columns will include all of the accounts approved to withdraw  
        //from a given account together with the withdrawal sum allowed for each
    
    // 6. TODO: set sender's balance to total supply
    constructor() {
        balances[msg.sender] = supply;
        minter = msg.sender;
        
    }
    // 7. TODO: return total supply
    function totalSupply() public view returns (uint256) {
        return supply;
        
    }
    // 8. TODO: return the balance of _owner
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    // 9. TODO: mint tokens by updating receiver's balance and total supply
    // NOTE 1: total supply must not exceed `MAXSUPPLY`
    function mint(address receiver, uint256 amount) public returns (bool) {
        
        require(msg.sender == minter); //only a minter can mint
        supply += amount;
        require(supply <= MAXSUPPLY); // NOTE 1: total supply must not exceed `MAXSUPPLY`
        balances[receiver]+= amount;
        return true;
    }

    // 10. TODO: burn tokens by sending tokens to `address(0)`
    // NOTE 1: must have enough balance to burn
    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender]>= amount);// NOTE 1: must have enough balance to burn
        balances[msg.sender] -= amount;
        supply -= amount;
        balances[address(0)] += amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    // 11. TODO: transfer mintership to newminter
    // NOTE 1: only incumbent minter can transfer mintership
    // NOTE 2: should emit `MintershipTransfer` event
    function transferMintership(address newMinter) public returns (bool) {
        require(msg.sender == minter); // NOTE 1: only incumbent minter can transfer mintership
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter); // NOTE 2: should emit `MintershipTransfer` event
        
        return true;
    }
    // 12. TODO: transfer `_value` tokens from sender to `_to`
    // NOTE 1: sender needs to have enough tokens
    // NOTE 2: transfer value needs to be sufficient to cover fee
    function transfer(address _to, uint256 _value) public returns (bool) { 
        require(balances[msg.sender]>= _value,"Insufficient tokens"); // NOTE 1: sender needs to have enough tokens
        require(_value >= txnfee); // NOTE 2: transfer value sufficient to cover fee
        balances[msg.sender]-= _value ; //implies that only the owner of the tokens can transfer them to others
        balances[_to]+= (_value - txnfee); //the receiver receives the value - the transaction costs
        balances [minter] += txnfee;
        emit Transfer(msg.sender, _to, _value); //only creates the log, doesn't change the state
        return true;
        
    }

    // 13. TODO: transfer `_value` tokens from `_from` to `_to`
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
    // NOTE: transfer value needs to be sufficient to cover fee
    //It allows a delegate approved for withdrawal to transfer owner funds to a third-party account
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require (balances[_from]>=_value);
        require (allowances[_from][msg.sender]>= _value, "Not allowed");
        require(_value >= txnfee);
        balances[_from] -=_value;
        balances [_to] += (_value-txnfee);
        allowances [_from] [msg.sender] -=_value;//updating the allowances
        balances[minter] += txnfee;
        emit Transfer (_from, _to,_value); //tokens are actually transferred
        return true;
        
    }
    // 14. TODO: allow `_spender` to spend `_value` on sender's behalf
    // NOTE: if an allowance already exists, it should be overwritten
    function approve(address _spender, uint256 _value) public returns (bool) { //allows the marketplace to finalize the transaction without waiting for prior approval.
        allowances [msg.sender][_spender] = _value; //approves _spender account to withdraw tokens from senders account
        //and to transfer them to other accounts
        emit Approval(msg.sender, _spender, _value); //granted rights to withdraw tokens from an account
        return true;
    }

    // 15. TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowances[_owner][_spender];
    }
}