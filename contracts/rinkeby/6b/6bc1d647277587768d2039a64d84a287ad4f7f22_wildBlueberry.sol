/**
 *Submitted for verification at Etherscan.io on 2021-12-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;






interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  
  
  //function allowance(address owner, address spender) external view returns (uint256);
  //function approve(address spender, uint256 value) external returns (bool);
  //function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  //event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract wildBlueberry is IERC20{
    string public name = 'Wild Blueberry';
    string public symbol = 'WILDB';
    uint public decimals = 0;
    uint public override totalSupply;
    
    address public founder;
    mapping (address => uint) public balances;


    constructor(){
        totalSupply = 1000000;
        founder = msg.sender;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance){
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 value) public override returns (bool success){
        require(balances[msg.sender] >= value);

        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }


}