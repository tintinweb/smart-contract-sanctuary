// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.7;

import "./IGasRefunder.sol";

import "@openzeppelin/contracts-0.8/access/Ownable.sol";

contract GasRefunder is IGasRefunder, Ownable {
    mapping(address => bool) public allowedContracts;
    mapping(address => bool) public allowedRefundees;
    mapping(address => uint256) public lastContractRefund;
    address public disallower;

    struct CommonParameters {
        uint128 maxRefundeeBalance;
        uint32 extraGasMargin;
        uint8 calldataCost;
        uint64 maxGasTip;
        uint64 maxGasCost;
        uint32 maxSingleGasUsage;
    }

    CommonParameters public commonParams;

    enum CommonParameterKey {
        MAX_REFUNDEE_BALANCE,
        EXTRA_GAS_MARGIN,
        CALLDATA_COST,
        MAX_GAS_TIP,
        MAX_GAS_COST,
        MAX_SINGLE_GAS_USAGE
    }

    enum RefundDenyReason {
        CONTRACT_NOT_ALLOWED,
        REFUNDEE_NOT_ALLOWED,
        ALREADY_REFUNDED_THIS_BLOCK,
        REFUNDEE_ABOVE_MAX_BALANCE,
        OUT_OF_FUNDS
    }

    event RefundedGasCosts(
        address indexed refundee,
        address indexed contractAddress,
        bool indexed success,
        uint256 gas,
        uint256 gasPrice,
        uint256 amountPaid
    );
    event RefundGasCostsDenied(
        address indexed refundee,
        address indexed contractAddress,
        RefundDenyReason indexed reason,
        uint256 gas
    );
    event Deposited(address sender, uint256 amount);
    event Withdrawn(address initiator, address destination, uint256 amount);
    event ContractAllowedSet(address indexed addr, bool indexed allowed);
    event RefundeeAllowedSet(address indexed addr, bool indexed allowed);
    event DisallowerSet(address indexed addr);
    event CommonParameterSet(CommonParameterKey indexed parameter, uint256 value);

    constructor() Ownable() {
        commonParams = CommonParameters({
            maxRefundeeBalance: 0, // no limit
            extraGasMargin: 4000, // 4k gas
            calldataCost: 12, // Between 4 for zero bytes and 16 for non-zero bytes
            maxGasTip: 2 gwei,
            maxGasCost: 120 gwei,
            maxSingleGasUsage: 2e6 // 2 million gas
        });
    }

    function setDisallower(address addr) external onlyOwner {
        disallower = addr;
        emit DisallowerSet(addr);
    }

    function allowContracts(address[] calldata addresses) external onlyOwner {
        setContractsAllowedImpl(addresses, true);
    }

    function disallowContracts(address[] calldata addresses) external {
        require(msg.sender == owner() || msg.sender == disallower, "NOT_AUTHORIZED");
        setContractsAllowedImpl(addresses, false);
    }

    function setContractsAllowedImpl(address[] calldata addresses, bool allow) internal {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            allowedContracts[addr] = allow;
            emit ContractAllowedSet(addr, allow);
        }
    }

    function allowRefundees(address[] calldata addresses) external onlyOwner {
        setRefundeesAllowedImpl(addresses, true);
    }

    function disallowRefundees(address[] calldata addresses) external {
        require(msg.sender == owner() || msg.sender == disallower, "NOT_AUTHORIZED");
        setRefundeesAllowedImpl(addresses, false);
    }

    function setRefundeesAllowedImpl(address[] calldata addresses, bool allow) internal {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            allowedRefundees[addr] = allow;
            emit RefundeeAllowedSet(addr, allow);
        }
    }

    function setMaxRefundeeBalance(uint128 newValue) external onlyOwner {
        commonParams.maxRefundeeBalance = newValue;
        emit CommonParameterSet(CommonParameterKey.MAX_REFUNDEE_BALANCE, newValue);
    }

    function setExtraGasMargin(uint32 newValue) external onlyOwner {
        commonParams.extraGasMargin = newValue;
        emit CommonParameterSet(CommonParameterKey.EXTRA_GAS_MARGIN, newValue);
    }

    function setCalldataCost(uint8 newValue) external onlyOwner {
        commonParams.calldataCost = newValue;
        emit CommonParameterSet(CommonParameterKey.CALLDATA_COST, newValue);
    }

    function setMaxGasTip(uint64 newValue) external onlyOwner {
        commonParams.maxGasTip = newValue;
        emit CommonParameterSet(CommonParameterKey.MAX_GAS_TIP, newValue);
    }

    function setMaxGasCost(uint64 newValue) external onlyOwner {
        commonParams.maxGasCost = newValue;
        emit CommonParameterSet(CommonParameterKey.MAX_GAS_COST, newValue);
    }

    function setMaxSingleGasUsage(uint32 newValue) external onlyOwner {
        commonParams.maxSingleGasUsage = newValue;
        emit CommonParameterSet(CommonParameterKey.MAX_SINGLE_GAS_USAGE, newValue);
    }

    receive() external payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(address payable destination, uint256 amount) external onlyOwner {
        // It's expected that destination is an EOA
        (bool success, ) = destination.call{ value: amount }("");
        require(success, "WITHDRAW_FAILED");
        emit Withdrawn(msg.sender, destination, amount);
    }

    function onGasSpent(
        address payable refundee,
        uint256 gasUsed,
        uint256 calldataSize
    ) external override returns (bool success) {
        uint256 startGasLeft = gasleft();

        uint256 ownBalance = address(this).balance;

        if (ownBalance == 0) {
            emit RefundGasCostsDenied(refundee, msg.sender, RefundDenyReason.OUT_OF_FUNDS, gasUsed);
            return false;
        }

        if (!allowedContracts[msg.sender]) {
            emit RefundGasCostsDenied(
                refundee,
                msg.sender,
                RefundDenyReason.CONTRACT_NOT_ALLOWED,
                gasUsed
            );
            return false;
        }
        if (!allowedRefundees[refundee]) {
            emit RefundGasCostsDenied(
                refundee,
                msg.sender,
                RefundDenyReason.REFUNDEE_NOT_ALLOWED,
                gasUsed
            );
            return false;
        }

        if (lastContractRefund[msg.sender] == block.number) {
            // There was already a refund this block, don't refund further
            emit RefundGasCostsDenied(
                refundee,
                msg.sender,
                RefundDenyReason.ALREADY_REFUNDED_THIS_BLOCK,
                gasUsed
            );
            return false;
        }
        lastContractRefund[msg.sender] = block.number;

        uint256 estGasPrice = block.basefee + commonParams.maxGasTip;
        if (tx.gasprice < estGasPrice) {
            estGasPrice = tx.gasprice;
        }
        if (commonParams.maxGasCost != 0 && estGasPrice > commonParams.maxGasCost) {
            estGasPrice = commonParams.maxGasCost;
        }

        // Retrieve these variables before measuring gasleft()
        uint256 refundeeBalance = refundee.balance;
        uint256 maxRefundeeBalance = commonParams.maxRefundeeBalance;
        uint256 maxSingleGasUsage = commonParams.maxSingleGasUsage;

        // Add in a bit of a buffer for the tx costs not measured with gasleft
        gasUsed +=
            startGasLeft +
            commonParams.extraGasMargin +
            (calldataSize * commonParams.calldataCost);
        // Split this up into two statements so that gasleft() comes after the storage loads
        gasUsed -= gasleft();

        if (maxSingleGasUsage != 0 && gasUsed > maxSingleGasUsage) {
            gasUsed = maxSingleGasUsage;
        }

        uint256 refundAmount = estGasPrice * gasUsed;
        if (maxRefundeeBalance != 0 && refundeeBalance + refundAmount > maxRefundeeBalance) {
            if (refundeeBalance > maxRefundeeBalance) {
                // The refundee is already above their max balance
                emit RefundGasCostsDenied(
                    refundee,
                    msg.sender,
                    RefundDenyReason.REFUNDEE_ABOVE_MAX_BALANCE,
                    gasUsed
                );
                return false;
            } else {
                refundAmount = maxRefundeeBalance - refundeeBalance;
            }
        }

        if (refundAmount > ownBalance) {
            refundAmount = ownBalance;
        }

        // It's expected that refundee is an EOA
        (success, ) = refundee.call{ value: refundAmount }("");
        emit RefundedGasCosts(refundee, msg.sender, success, gasUsed, estGasPrice, refundAmount);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity >=0.6.11 <0.7.0||>=0.8.7 <0.9.0;

interface IGasRefunder {
    function onGasSpent(
        address payable spender,
        uint256 gasUsed,
        uint256 calldataSize
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

