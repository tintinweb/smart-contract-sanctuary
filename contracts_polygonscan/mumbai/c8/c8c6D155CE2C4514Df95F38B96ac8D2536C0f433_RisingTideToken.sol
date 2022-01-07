// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces.sol";


contract RisingTideToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 private constant transferFee = 95;

    mapping(address => bool) public canIncreaseAllowanceForStake;

    constructor() public ERC20("RisingTideToken", "RTT") {
        uint256 initialSupply = 1000000000 * 10**18;
        mint(initialSupply);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function increaseAllowanceForStake(address owner, address spender, uint256 addedValue) public override returns(bool) {
        require(canIncreaseAllowanceForStake[msg.sender], "You are not allowd to increase allowance for staking purpose");
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowanceForStake(address owner, address spender, uint256 subtractedValue) public virtual override returns (bool) {
        require(canIncreaseAllowanceForStake[msg.sender], "You are not allowd to decrrease allowance for staking purpose");
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);

        return true;
    }

    function enableAllowanseForStake(address enabled) public onlyOwner {
        canIncreaseAllowanceForStake[enabled] = true;
    }

    function disableAllowanseForStake(address disabled) public onlyOwner {
        canIncreaseAllowanceForStake[disabled] = false;
    }
}