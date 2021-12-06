/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
contract assignmentTokenGW {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
 uint256 constant _MAXSUPPLY = 1000000;
 uint256 supply = 50000;
 uint256 constant fees = 1;
 address public minter;

  
    // TODO: specify event to be emitted on transfer==> il faudra peut etre changer address indexed par le vrai nom
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
   
    // TODO: specify event to be emitted on approval
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);

 event MintershipTransfer( address indexed previousMinter,  address indexed newMinter  );
   
    // TODO: create mapping for balances
mapping(address => uint256) public balances;
    
    // TODO: create mapping for allowances
mapping(address => mapping (address => uint256)) allowances;

        // TODO: set sender's balance to total supply
  constructor(){
      minter=msg.sender;
    balances[msg.sender]=supply;
    }

// TODO: return total supply
    function totalSupply() public view returns (uint256 ) {  
   return supply;
    }

 // TODO: return the balance of _owner
    function balanceOf(address _owner) public view returns (uint256) {
    return balances [_owner];
    }

 // TODO: mint tokens by updating receiver's balance and total supply
    function mint(address _receiver, uint256 _value) public returns (bool) {
    require(msg.sender==minter,"msg sender is not the minter");
 // NOTE: total supply must not exceed `MAXSUPPLY`
    require((supply +_value) <=_MAXSUPPLY);
    balances[_receiver] +=_value;
    supply +=_value;
    return true;
    }

    function burn(uint256 _value) public returns (bool) {
        // TODO: burn tokens by sending tokens to `address(0)`
        // NOTE: must have enough balance to burn
   require (balances[msg.sender]>=_value);
        balances[msg.sender]-=_value;
        supply-=_value;
    emit Transfer(msg.sender,address (0),_value);
        return true;
    }

    function transferMintership(address newMinter) public returns (bool) {
        // NOTE: only incumbent minter can transfer mintership
         require(msg.sender == minter);
        // TODO: transfer mintership to newminter
           minter = newMinter;
        // NOTE: should emit `MintershipTransfer` event
         emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
         // NOTE: sender needs to have enough tokens
      require (balances[msg.sender]>=_value,"no sufficient funds");
        // NOTE: transfer value needs to be sufficient to cover fee
        require (_value>=fees,"no sussifcient funds to cover fees");
        // TODO: transfer `_value` tokens from sender to `_to`
        balances[msg.sender]-=_value;
        balances[_to]+=(_value-fees);
        balances [minter]+=fees;
        // says that there were a transfer
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom( address _from, address _to,uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        require (_value<=balances[_from],"not enough funds");
        require (allowances[_from][msg.sender]>=_value,"not allowed to spend this amount");
        balances[_from]-=_value;
        balances[_to]+=(_value-fees);
        balances[minter]+=fees;
        emit Transfer(_from, _to, _value);
        allowances[_from][msg.sender]-=_value;
        require (_value >= fees);
        return true;
        // NOTE: transfer value needs to be sufficient to cover fee
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender]=_value;
        emit Approval (msg.sender,_spender,_value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining)  {
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        return allowances [_owner][_spender];
    }
}