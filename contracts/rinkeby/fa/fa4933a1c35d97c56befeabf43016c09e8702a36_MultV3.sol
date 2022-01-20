/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IFactory {
    function withdraw(uint256 salt, address token, address receiver) external returns (address wallet);
}

interface IERC20 {
    function transfer(address, uint256) external;
}

contract MultV3 {

    address _ADMIN;

    event IncreaseBalance(address sender, uint256 amount);

    event DecreaseBalance(address target, uint256 amount);

    mapping (address => bool) public Owners;

    function modifyOwner(address _wallet, bool _enabled) external {
        require(_ADMIN == msg.sender, "Only for admin");

        Owners[_wallet]=_enabled;
    }

    function contains(address _wallet) public view returns (bool) {
        return Owners[_wallet];
    }

    modifier ownerOnly () {
      require(Owners[msg.sender], "Only for owners");
         _;
    }

    constructor () public {
        _ADMIN = msg.sender;
    }

    receive () external payable {
        emit IncreaseBalance(msg.sender, msg.value);
    }

    function dumpFactory(address factory, uint[] memory salt, address[] memory token, address receiver) external {
        uint arrayLength = salt.length;

        for (uint i=0; i < arrayLength; i++) {
            IFactory(factory).withdraw(salt[i], token[i], receiver);
        }
    }

    function transferErc20(address[] memory token, address[] memory reviever, uint256[] memory amount) ownerOnly external {
        for (uint i=0; i < token.length; i++) {
            IERC20(token[i]).transfer(reviever[i], amount[i]);
        }
    }

    function withdrawAsset(address[] memory targets, uint256[] memory amounts) ownerOnly external {
        require(targets.length == amounts.length, "Invalid params length");

        uint256 amountSum = 0;

        for (uint i = 0; i < amounts.length; i++) {
            amountSum += amounts[i];
        }

        uint256 balance = address(this).balance;

        require(balance >= amountSum, "Invalid factory balance");

        for (uint i=0; i < targets.length; i++) {
            payable(targets[i]).transfer(amounts[i]);
            emit DecreaseBalance(targets[i], amounts[i]);
        }
    }
}