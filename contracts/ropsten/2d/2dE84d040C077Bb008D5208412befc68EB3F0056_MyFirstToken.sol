/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: NOLICENSE

pragma solidity  0.8.5;

contract MyFirstToken{

    string public constant name = "Muhammad";
    string public constant symbol = "MT";
    uint public constant decimal = 18;

    uint private total_no_tokens = 1000000000000000000;

    mapping (address => uint) private balance_of;
    mapping (address =>mapping(address => uint)) private allownces;
    
    //set balance 
    function setBalance() public {
        balance_of[msg.sender] = total_no_tokens;
    }


    //Returns the total token supply.
    function totalSupply() public view returns (uint ){
        return total_no_tokens;
    }
    
    //Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) public view returns (uint){
        return balance_of[_owner];
    }
    
    //Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
    //The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    //Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint _value) public returns (bool success){
        if(_value != 0 && _value <= balance_of[msg.sender])
        {
            balance_of[msg.sender] = balance_of[msg.sender] - _value;
            balance_of[_to] = balance_of[_to] + _value;
            return true;
        }
        else
            return false;
    }


    
    //Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    //The transferFrom method is used for a withdraw workflow, allowing contracts
    // to transfer tokens on your behalf. This can be used for example to allow a
    // contract to transfer tokens on your behalf and/or to charge fees in sub-currencies.
    // The function SHOULD throw unless the _from account has deliberately authorized 
    //the sender of the message via some mechanism.
    //Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        if (allownces[_from][msg.sender] > 0 && _value > 0 && allownces[_from][msg.sender] >= _value)
        {
            balance_of[_from] = balance_of[_from] - _value;
            balance_of[_to] = balance_of[_to] + _value;
            return true;
        }
        else
            return false;
    }
    
    // Allows _spender to withdraw from your account multiple times, 
    //up to the _value amount. If this function is called again 
    //it overwrites the current allowance with _value.
    function approve(address _spender, uint _value) public returns (bool success){
        allownces[msg.sender][_spender] = _value;
        return true;
    }
    
    // Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) public view returns(uint){
        return allownces[_owner][_spender];
    }

    //Events
    //MUST trigger when tokens are transferred, including zero value transfers.
    //A token contract which creates new tokens SHOULD trigger a Transfer event 
    //with the _from address set to 0x0 when tokens are created.
       //event Transfer(address indexed _from, address indexed _to, uint256 _value);

    //MUST trigger on any successful call to approve(address _spender, uint256 _value).
        //event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}