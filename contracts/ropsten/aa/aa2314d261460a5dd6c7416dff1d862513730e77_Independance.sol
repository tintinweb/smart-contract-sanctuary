/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity ^0.5.0;

contract Independance {
    
    constructor (uint256 _qty, string memory _name, string memory _symbol, uint8 _decimal) public {
        totalsupply = _qty;
        // All the tokens are to be in account of deployer.
        balances[msg.sender] = totalsupply;
        name_ = _name;
        symbol_ = _symbol;
        decimal_ = _decimal;
    }
     
    string name_;
    function name() public view returns (string memory) {
        return name_;
    }
    string symbol_;
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    uint8 decimal_;
    function decimals() public view returns (uint8) {
        return decimal_;
    }




    uint256 totalsupply;
    // Returns the total token supply.
    function totalSupply() public view returns (uint256) {
        return totalsupply;
    }
    
    mapping ( address => uint256) balances;
    //Returns the account balance of another account with address _owner
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    
    // sender of message is transferring some token (_value) to a beneficiary account (_to).
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require( balances[msg.sender] >= _value, "Insuffcient balance");
      //  balances[msg.sender] = balances[msg.sender] - _value;
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
        
    }

}