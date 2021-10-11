/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;


contract assignmentToken {
    // MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000;
    uint256 supply             = 50000;
    address public minter;
    // declare transfer fee constant
    uint256 constant transferFee = 1;
    // event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer(address indexed previousMinter,address indexed newMinter);

    // mapping for balances
    mapping (address => uint) public balances;

    // mapping for allowances 
    mapping (address => mapping(address => uint)) public allowances;

    constructor() {
        //we set sender's balance to total supply
        balances[msg.sender] = supply ; 
        // the sender becomes the minter
        minter= msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        //return total supply
        return supply ;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        //return the balance of _owner
        return balances[_owner];
    }

    function mint(address receiver, uint256 amount) public returns (bool) {
        // mint tokens by updating receiver's balance and total supply
        // NOTE: total supply must not exceed `MAXSUPPLY`

        require(msg.sender == minter);          // first identify the sender of the mint request
        require(supply + amount <= MAXSUPPLY) ; // avoid exceeding  MAXSUPPLY

        // update receiver balance
        balances[receiver] += amount;
        // update the current supply
        supply += amount;
        // return True
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        //  burn tokens by sending tokens to `address(0)`
        //  NOTE: must have enough balance to burn
        require(balances[msg.sender] > amount); // avoid negative balance
        // update sender balance
        balances[msg.sender]-=amount; 
        // update address(0) balance
        balances[address(0)] += amount;
        // update supply
        supply -= amount;
        // return True
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // transfer mintership to newminter
        // NOTE: only incumbent minter can transfer mintership
        // NOTE: should emit `MintershipTransfer` event

        // identify request sender
        require(msg.sender == minter);
        // emit `MintershipTransfer` event
        emit MintershipTransfer(minter,newMinter);
        // update minter address
        minter = newMinter;
        // return True
        return true;
    }
    // private function that transfer '_value' from '_form' to to_ this function can only be used by other functions of the contract
    function simple_transfer(address _from,address _to, uint256 _value) private returns (bool) {
        require(balances[_from] >=_value ); // check if _from has enough tokens
        require(_value>=transferFee);       // check if _from transfer value covers fee

        // update sender balance
        balances[_from]-=_value;
        // update receiver balance
        balances[_to]+=_value-transferFee;
        // update minter balance
        balances[minter]+=transferFee;
        // emit 'Transfer' events
        emit Transfer(_from,  _to, _value-transferFee);
        emit Transfer(_from,  minter, transferFee);
        // return True
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        // simply use the private function 'simple_transfer' using the sender as '_from' address
        return simple_transfer(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        //  transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(allowances[_from][msg.sender] >= _value); // check allowance
        // proceed to transfer and save bolean result
        bool success = simple_transfer(_from, _to,  _value);
        // update allowance if the transfer succeeded
        if(success){allowances[_from][msg.sender] -= _value;}
        // return succes status
        return success;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        //  allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten

        // update allowance 
        allowances[msg.sender][_spender] = _value;
        // emit 'Approval' event
        emit Approval(msg.sender, _spender, _value);
        // return true
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