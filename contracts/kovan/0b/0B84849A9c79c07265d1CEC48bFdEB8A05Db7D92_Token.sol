/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Token {
    
    //variables of the contract
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;
    
    //This helps track approved balances and allwances(permission to use)
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    
    //These events fire when there is any change in state
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed approvedSeller, uint value);
    
    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupply) {
       name = _name;
       symbol = _symbol;
       decimals = _decimals;
       totalSupply = _totalSupply;
       balanceOf[msg.sender] = totalSupply;
    }
    
    
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    
    //This does the internal checks the balance and does not allow negative balances
    function _transfer(address _from, address _to, uint256 _value) internal {
        // So only real valid address can receive. burn using 0x0 
        require(_to != address(0));
        balanceOf[_from] = balanceOf[_from] - (_value);
        balanceOf[_to] = balanceOf[_to] + (_value);
        emit Transfer(_from, _to, _value);
    }
    
    //ensures that address is valid then sets of the event "Approval"
    function approve(address _approvedSeller, uint _value) external returns (bool) {
        require(_approvedSeller != address(0));
        allowance[msg.sender][_approvedSeller] = _value;
        emit Approval(msg.sender, _approvedSeller, _value);
        return true;
    }
    
    // this verifies the balance and identification if the from balance is the msg sender, 
    // then deducts the amount requested before transfering over to the requester 
    function transfersFrom(address _from, address _to, uint _value) external returns (bool) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender] - (_value);
        _transfer(_from, _to, _value);
        return true;
    }
}