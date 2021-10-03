/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract MultiSend {
    IERC20 public token;
    address public dev;

    constructor(address _token) {
        token = IERC20(_token);
        dev = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == dev, "access denied");
        _;
    }

    function updateToken(address _token) public restricted {
        token = IERC20(_token);
    }

    function Multisend(
        address[] memory _receivers,
        uint256[] memory _amount
    ) external restricted {
        require(_receivers.length == _amount.length, "Invalid data");

        for (uint256 index = 0; index < _receivers.length; index++) {
            token.transfer(_receivers[index], _amount[index]);
        }
    }

    function safu(address _token) external restricted {
        IERC20(_token).transfer(dev, IERC20(_token).balanceOf(address(this)));
    }
}