// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface bob {
    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


}

contract contract_interface {
    address tokenA;
    string name;
    uint256 total;
    // uint256 public account_bal;

    constructor(address deployer_address) {
        tokenA = deployer_address;
    }

    function totalSupply() public view returns (uint256) {
        return bob(tokenA).totalSupply();
    }

    function balanceOf(address account) external payable returns (uint256) {
        uint account_bal = bob(tokenA).balanceOf(account);
        return account_bal;
    }

    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return bob(tokenA).allowance(owner, spender);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return bob(tokenA).approve(spender, amount);
    }

  function transferfrom(address sender, address recipient, uint256 amount) external returns (bool) { 
    return bob(tokenA).transferFrom(sender, recipient, amount);
  }
 
}