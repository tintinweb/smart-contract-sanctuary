/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract assignmentToken {
    // TODO: specify `MAXSUPPLY`, declare `minter` and `supply`
    uint256 constant MAXSUPPLY = 1000000; // // The total supply of the token is capped at 1,000,000 
    uint256  supply = 50000; // // initial supply of token at contract creation is 50,000
    address public minter; 

    // TODO: specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // TODO: specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event MintershipTransfer( address indexed previousMinter, address indexed newMinter);

    // TODO: create mapping for balances
    mapping(address => uint256) public balances;

    // TODO: create mapping for allowances
    mapping (address => mapping(address => uint256)) public allowances;

    constructor() {
        // TODO: set sender's balance to total supply
        balances[msg.sender] = supply;
        // The original minter is the contract creator (i.e., sender)
        minter = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        // TODO: return total supply
        return supply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        // TODO: return the balance of _owner
        return balances [_owner];
    }

    //https://programtheblockchain.com/posts/2018/05/16/changing-the-supply-of-erc20-tokens/
    function mint(address receiver, uint256 amount) public returns (bool) {
        // Only minter can mint the token 
        require(msg.sender == minter, 'sender is not a minter');
        // NOTE: total supply must not exceed `MAXSUPPLY`
        require((supply+amount)<=MAXSUPPLY, "total supply must not exceed 'MAXSUPPLY' ");
        supply += amount; //increasing supply
        balances[receiver]+=amount;
        // TODO: mint tokens by updating receiver's balance and total supply
        emit Transfer(msg.sender, receiver, amount); 
        //https://docs.openzeppelin.com/contracts/3.x/erc20-supply
    }

    function burn(uint256 amount) public returns (bool) {
        // NOTE: must have enough balance to burn
        require(balances[msg.sender] >= amount, "balances too low");    
        supply -= amount; // reducing supply
        balances[msg.sender]-=amount;
        // TODO: burn tokens by sending tokens to `address(0)`
        emit Transfer(msg.sender, address(0), amount);
    }

    //https://www.linkedin.com/pulse/erc20-token-sybren-boland
    function transferMintership(address newMinter) public returns (bool) {
        // NOTE: only incumbent minter can transfer mintership
        require(msg.sender == minter, 'Only minter can transfer mintership');//Only minter can mint the token
        // TODO: transfer mintership to newminter
        minter = newMinter; 
        // NOTE: should emit `MintershipTransfer` event
        emit MintershipTransfer(msg.sender, newMinter); // minter can transfer 'mintership to another address'
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from sender to `_to`
        // NOTE: sender needs to have enough tokens
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value+1;
        balances[_to] += _value-1;
        // A flat fee of 1 unit of the token is levied and rewarded to the minter with every transfer transaction
        balances[minter] ++;     
        emit Transfer(msg.sender, _to, _value);
        emit Transfer(msg.sender, minter, 1);
        return true;
    }

    function transferFrom( address _from, address _to, uint256 _value) public returns (bool) {
        // TODO: transfer `_value` tokens from `_from` to `_to`
        // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
        // NOTE: transfer value needs to be sufficient to cover fee
        require(balances[_from] >= _value  , "balances too low"); // +1?
        require(allowances[_from][msg.sender] >= _value, "allowances too low");
        balances[_from] -= _value;
        allowances[_from][msg.sender] -= _value;
        balances[_to] += _value-1; //sending one less to the receiver
        // A flat fee of 1 unit of the token is levied and rewarded to the minter with every transfer transaction
        balances[minter] ++;
        emit Transfer(_from, _to, _value);
        emit Transfer(_from, minter, 1);
            return true; 
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        // TODO: allow `_spender` to spend `_value` on sender's behalf
        // NOTE: if an allowance already exists, it should be overwritten
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
        remaining = allowances[_owner][_spender];
        return remaining;
    }
}
// https://forum.openzeppelin.com/t/create-erc20-with-burn-function-on-remix/4463
// https://docs.openzeppelin.com/contracts/3.x/api/token/erc20#ERC20-transfer-address-uint256-