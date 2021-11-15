// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev `owner` defaults to msg.sender on construction.
     */
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
     *      Can only be invoked by the current `owner`.
     * @param _newOwner Address of the new owner.
     * @param _direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
     */
    function transferOwnership(address _newOwner, bool _direct) external onlyOwner {
        if (_direct) {
            require(_newOwner != address(0), "zero address");

            emit OwnershipTransferred(owner, _newOwner);
            owner = _newOwner;
            pendingOwner = address(0);
        } else {
            pendingOwner = _newOwner;
        }
    }

    /**
     * @dev Needs to be called by `pendingOwner` to claim ownership.
     */
    function claimOwnership() external {
        address _pendingOwner = pendingOwner;
        require(msg.sender == _pendingOwner, "caller != pending owner");

        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the Owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { Ownable } from "../abstract/Ownable.sol";

contract CrossSaleData is Ownable {
    mapping(address => uint256) public balanceOf;

    function addUser(address user, uint256 amount) external onlyOwner {
        balanceOf[user] = amount;
    }

    function massAddUsers(address[] calldata user, uint256[] calldata amount) external onlyOwner {
        uint256 len = user.length;
        require(len == amount.length, "Data size mismatch");
        uint256 i;
        for (i; i < len; i++) {
            balanceOf[user[i]] = amount[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import { CrossSaleData } from "./CrossSaleData.sol";

contract CrossSaleDataPublicPolygon is CrossSaleData {}

