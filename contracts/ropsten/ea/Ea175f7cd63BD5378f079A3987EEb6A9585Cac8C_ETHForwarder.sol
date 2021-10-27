// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract ETHForwarder {
    address payable private _forwardAddress;
    event Received(address indexed sender, uint amount);

    constructor(address payable forwardAddress_) {
        _forwardAddress = forwardAddress_;

    }

    /**
     * @dev Allows the contract to recieve ETH.
     */
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Returns the forward address of the contract.
     */
    function forwardAddress() public view virtual returns (address) {
        return _forwardAddress;
    }

    /**
     * @dev Transfers all existing ETH Token to the determined
     * forwardAddress.
     *
     */
    function forwardETH() public {
        _forwardAddress.transfer(address(this).balance);
    }
}