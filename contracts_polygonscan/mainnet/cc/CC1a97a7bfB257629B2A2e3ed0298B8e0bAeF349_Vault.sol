/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC20 { // lite
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Vault is IERC20 {

    address wallet1;
    address wallet2;
    address wallet3;
    event Withdraw(uint256 amount);

    function name() public pure returns (string memory) {
        return "Vault Token";
    }
    function symbol() public pure returns (string memory) {
        return "VAULT";
    }

    constructor(address a1, address a2, address a3) {
      wallet1 = a1;
      if (a2 != address(0)) {
      wallet2 = a2;
      }
      if (a3 != address(0)) {
      wallet3 = a3;
      }
    }

    function totalSupply() public view override returns (uint256) {
      uint256 supply_ = 1;
      if (wallet2 != address(0)) {
        supply_++;
      }
      if (wallet3 != address(0)) {
        supply_++;
      }
      return supply_;
    }

    fallback() external payable {}
    receive() external payable {}
    uint8 public decimals = 0;

    function withdrawAll() public {
      withdrawCoin(address(this).balance);
    }
    function withdrawCoin(uint256 amount) public {
        require(address(this).balance >= amount, "exceeds balance");
        uint256 count = totalSupply();
        uint256 amount1 = amount / count;
        payable(wallet1).transfer(amount1);
        if (count > 1) {
          payable(wallet2).transfer(amount1);
        }
        if (count > 2) {
          payable(wallet3).transfer(amount - (amount1 * 2));
        }
        emit Withdraw(amount);
    }
    function withdrawAllToken(IERC20 tok_) public {
      uint256 balance = tok_.balanceOf(address(this));
      withdrawToken(tok_, balance);
    }
    function withdrawToken(IERC20 tok_, uint256 amount) public {
        uint256 balance = tok_.balanceOf(address(this));
        require(balance >= amount, "exceeds balance");
        uint256 amount1 = (amount * 100) / 33;
        uint256 amount2 = amount1;
        uint256 amount3 = (amount - (amount1 + amount2));
        require(tok_.transfer(wallet1, amount1), "tx 1 failed"); 
        require(tok_.transfer(wallet2, amount2), "tx 2 failed"); 
        require(tok_.transfer(wallet3, amount3), "tx 3 failed"); 
    }
    
    // balanceOf
    function balanceOf(address addr) public view override returns (uint256) {
      if (addr == wallet1 || addr == wallet2 || addr == wallet3) {
        return 20000;
      }
      return 0;
    }

    // transfer key
    function transfer(address newAddr, uint256) public override returns (bool) {
        require(msg.sender == wallet1 || msg.sender == wallet2 || msg.sender == wallet3, "not authorized");
        if (msg.sender == wallet1) {
          wallet1 = newAddr;
        } else if (msg.sender == wallet2) {
          wallet2 = newAddr;
        } else if (msg.sender == wallet3) {
          wallet3 = newAddr;
        } 
        return true;
    }
}