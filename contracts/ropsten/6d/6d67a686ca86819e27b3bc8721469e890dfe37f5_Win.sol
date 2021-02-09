// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./MinterRole.sol";

contract Win is ERC20("Win", "WIN"), ERC20Burnable, MinterRole {
    address public owner;
    uint256 private _totalMinted;
    uint256 private _cap;

    constructor() public {
        owner = msg.sender;
        _setupDecimals(8);
        _cap = 5000000000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller not owner");
        _;
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount);
        _totalMinted = _totalMinted.add(amount);
    }

    function cap() public view returns (uint256) {
        return _cap;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted;
    }

    function mintBulk(address[] memory accounts, uint256[] memory amounts)
        public
        onlyMinter
        returns (bool)
    {
        require(accounts.length == amounts.length, "arrays must have same length");
        for (uint256 i = 0; i < accounts.length; i++) {
            require(amounts[i] > 0, "amount must be greater than 0");
            _mint(accounts[i], amounts[i]);
        }
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // When minting tokens
            require(totalMinted().add(amount) <= cap(), "ERC20Capped: cap exceeded");
        }
    }

    function addMinter(address account) public override onlyOwner {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }
}