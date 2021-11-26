/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.10;

/**

 interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

 }
**/
contract WildRooster {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;

 //   0x1234...
 //   -> 0x1234a.... => 10000
 //   -> 0x1234b.... => 15000;

    uint   public totalSupply = 100000000000000 * 10 ** 18;
    string public name = "Wild Rooster";
    string public symbol = "WRO";
    uint   public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'not enough balance');
                 balances[to] = balances[to] + value;
                 balances[msg.sender] = balances[msg.sender] - value;
                 emit Transfer(msg.sender, to , value);
                 return true;
    }
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'not enough balance');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
                 balances[to] = balances [to] + value;
                 balances[from] = balances [from] - value;
                 emit Transfer(from, to , value);
                 return true;
    }
    function approve(address spender, uint value) public returns(bool){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender , value);
        return true;
    }
  }

// }