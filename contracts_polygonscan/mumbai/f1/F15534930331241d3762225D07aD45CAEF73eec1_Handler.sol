/**
 *Submitted for verification at polygonscan.com on 2021-11-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Handler {
    address public owner;
    IERC20 public ERC20Interface;

    event Paid(address sender, address to, uint256 amount);
    event ItemBought(address user, string item, uint256 amount);

    constructor(address _owner, address _token) {
        require(_owner != address(0), "Zero owner address");
        require(_token != address(0), "Zero token address");
        owner = _owner;
        ERC20Interface = IERC20(_token);
    }

    function signUp(address user, uint256 amount) external returns (bool) {
        require(msg.sender == owner, "Only owner can call");
        require(
            ERC20Interface.allowance(owner, address(this)) > amount,
            "Not enough allowance"
        );
        require(
            ERC20Interface.transferFrom(owner, user, amount),
            "Payment failed"
        );
        emit Paid(owner, user, amount);
        return true;
    }

    function buyItem(
        string memory _itemName,
        uint256 amount,
        address user
    ) public returns (bool) {
        require(msg.sender == owner, "Only owner can call");
        require(
            ERC20Interface.allowance(user, address(this)) >= amount,
            "Not enough allowance"
        );
        require(
            ERC20Interface.transferFrom(user, owner, amount),
            "Payment failed"
        );
        emit ItemBought(user, _itemName, amount);
        return true;
    }
}