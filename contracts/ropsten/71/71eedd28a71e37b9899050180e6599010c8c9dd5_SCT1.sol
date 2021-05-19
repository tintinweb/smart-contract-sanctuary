/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.5.0;

contract SCT1 {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 39000000 * 10 ** 18;
    string public name = "Second Chance Token 1";
    string public symbol = "SCT 1";
    uint public decimals = 18;
   
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() public payable {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public  view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public payable returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transfreFrom(address from, address to, uint value) public payable returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
      /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) external payable {
        require(account != address(0), "ERC20: mint to the zero address");
       
        emit Transfer(address(0), account, amount);
    }
    
      /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) external payable {
        require(account != address(0), "ERC20: burn from the zero address");

        emit Transfer(account, address(0), value);
    }
    
    //SPDX-License-Identifier: <SPDX- UNLICENSE
}