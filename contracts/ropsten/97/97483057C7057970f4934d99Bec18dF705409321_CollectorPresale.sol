// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract CollectorPresale is ERC20 {
    using SafeMath for uint256;

    address public _deployer;
    uint256 ETHER_DECIMALS = 1000000000000000000;

    event Create(uint256 amount);
    event Destroy(uint256 amount);

    modifier onlyDeployer() {
        require(_deployer == msg.sender, "only deployer");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialAmount
    ) ERC20(name, symbol) {
        _deployer = msg.sender;
        create(initialAmount);
    }

    function burn(address account, uint256 amount) public onlyDeployer {
        _burn(account, amount.mul(ETHER_DECIMALS));
        emit Destroy(amount);
    }

    function create(uint256 amount) public onlyDeployer {
        // mint new token
        _mint(msg.sender, amount.mul(ETHER_DECIMALS));
        emit Create(amount);
    }

}