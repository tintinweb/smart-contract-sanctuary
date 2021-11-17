/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

contract assignmentToken {
    
    //start supply of minter
    address public minter;
    uint256 supply = 50000;
    uint256 constant MAXSUPPLY = 1000000;
    uint256 constant transactionFee = 1;

    //specify event to be emitted on transfer
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // specify event to be emitted on approval
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // transfer Mintership
    event MintershipTransfer(address indexed previousMinter, address indexed newMinter);

    // create mapping for balances
    mapping (address => uint256) public balances;

    // create mapping for allowances
    mapping (address => mapping(address => uint256)) public allowances;

    // set contract creator's balance to initial supply and only allows minter to mint
    constructor() public {
        balances[msg.sender] = supply;
        minter = msg.sender;
    }


    // return total supply
    function totalSupply() public view returns (uint256) {
        return supply;
    }

    // return the balance of _owner
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
    
    // mint tokens by updating receiver's balance and total supply
    // NOTE: total supply must not exceed `MAXSUPPLY`
    function mint(address receiver, uint256 amount) public returns (bool) {
        require(msg.sender == minter, "only verified minter can mint new tokens");
        require(amount + supply <=  MAXSUPPLY, "Maximum supply of token mined");
        balances[receiver] += amount;
        supply += amount;
        return true;
    }
    
    // burn tokens by sending tokens to `address(0)`
    // must have enough balance to burn
    function burn(address burner, uint256 amount) public returns (bool) {
        require(burner != address(0), "cannot burn from address zero");
        require(balances[burner] >= amount, "burn volume is bigger than balances");
        balances[burner] -= amount;
        emit Transfer(burner, address(0), amount);
        return true;
    }

    // transfer mintership to newminter
    // only incumbent minter can transfer mintership
    // should emit `MintershipTransfer` event
    function transferMintership(address newMinter) public returns (bool) {
        require(newMinter != address(0), "cannot transfer mintership to address zero");
        require(msg.sender == minter, "only minters can transfer mintership");
        minter = newMinter;
        emit MintershipTransfer(msg.sender, newMinter);
        return true;
    }

    // transfer `_value` tokens from sender to `_to`
    // sender needs to have enough tokens
    // transfer value needs to be sufficient to cover fee
    // I have assumed that the transaction fee is included in _value so the receiver gets _value - transactionFee
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        require(_value >= transactionFee, "amaount does not cover transaction Fee");
        balances[msg.sender] -= _value;
        balances[_to] += _value - transactionFee;
        balances[minter] += transactionFee;
        emit Transfer(msg.sender, _to, _value - transactionFee);
        emit Transfer(msg.sender, minter, transactionFee);
        return true;
    }

    // transfer `_value` tokens from `_from` to `_to`
    // `_from` needs to have enough tokens and to have allowed sender to spend on his behalf
    // transfer value needs to be sufficient to cover fee
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_value <= balances[_from], "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_value >= transactionFee, "amaount does not cover transaction Fee");
        balances[_from] -= _value;
        balances[_to] += _value - transactionFee;
        balances[minter] += transactionFee;
        allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value - transactionFee);
        emit Transfer(_from, minter, transactionFee);
        return true; 

    }
    // allow `_spender` to spend `_value` on sender's behalf
    // if an allowance already exists, it should be overwritten
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowances[_owner][_spender];

    }
}