/**
 *Submitted for verification at polygonscan.com on 2022-01-20
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.9.0;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

interface ERC55 {

    // Functions which read data from the contract

    function getTotalSupply() external view returns(uint);

    function getInReserve() external view returns(uint);

    function getInCirculation() external view returns(uint);

    function getBalanceOf(address account) external view returns(uint);

    // Functions that manipulate data

    function mintFromReserve(address recipient, uint amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint amount) external returns(bool);

    function burnFrom(address burner, uint amount) external returns(bool);

    // Events that should be triggered

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed from, address indexed to, uint value);
}

contract CCAD is ERC55 {

    string public constant name = "Canadian Cannabis Dollar";
    string public constant symbol = "CCAD";
    uint8 public constant decimals = 1;

    uint inReserve;
    uint inCirculation;

    mapping(address => uint256) balances;

    using SafeMath for uint256;

    constructor(uint totalSupply) {
        inReserve = totalSupply; // Putting the entire supply into the reserve
        inCirculation = 0;
    }

    function getTotalSupply() override external view returns(uint) {
        return inReserve + inCirculation;
    }

    function getInReserve() override external view returns(uint) {
        return inReserve;
    }

    function getInCirculation() override external view returns(uint) {
        return inCirculation;
    }

    function getBalanceOf(address account) override external view returns(uint) {
        return balances[account];
    }

    function mintFromReserve(address recipient, uint amount) override public returns(bool) {
        require(inReserve >= amount, "There is not enough currency in the reserve.");
        inReserve = inReserve.sub(amount);
        inCirculation = inCirculation.add(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(address(0), recipient, amount);
        emit Approval(address(0), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) override public returns(bool) {
        require(balances[sender] >= amount, "The sender does not have enough tokens to complete this transaction");
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);       
        emit Transfer(sender, recipient, amount);
        emit Approval(sender, recipient, amount);
        return true;
    }

    function burnFrom(address burner, uint amount) override public returns(bool) {
        require(balances[burner] >= amount);
        balances[burner] = balances[burner].sub(amount);
        inCirculation = inCirculation.sub(amount);
        emit Transfer(burner, address(0), amount);
        return true;
    }

}