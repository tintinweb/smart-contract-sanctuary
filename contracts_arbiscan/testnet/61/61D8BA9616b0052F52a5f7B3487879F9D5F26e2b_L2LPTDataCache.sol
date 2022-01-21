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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IArbSys} from "../../arbitrum/IArbSys.sol";

abstract contract L2ArbitrumMessenger {
    event TxToL1(
        address indexed _from,
        address indexed _to,
        uint256 indexed _id,
        bytes _data
    );

    function sendTxToL1(
        address user,
        address to,
        bytes memory data
    ) internal returns (uint256) {
        // note: this method doesn't support sending ether to L1 together with a call
        uint256 id = IArbSys(address(100)).sendTxToL1(to, data);
        emit TxToL1(user, to, id, data);
        return id;
    }

    modifier onlyL1Counterpart(address l1Counterpart) {
        require(
            msg.sender == applyL1ToL2Alias(l1Counterpart),
            "ONLY_COUNTERPART_GATEWAY"
        );
        _;
    }

    uint160 internal constant OFFSET =
        uint160(0x1111000000000000000000000000000000001111);

    // l1 addresses are transformed durng l1->l2 calls
    function applyL1ToL2Alias(address l1Address)
        internal
        pure
        returns (address l2Address)
    {
        l2Address = address(uint160(l1Address) + OFFSET);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {L2ArbitrumMessenger} from "./L2ArbitrumMessenger.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract L2LPTDataCache is Ownable, L2ArbitrumMessenger {
    address public l1LPTDataCache;
    address public l2LPTGateway;

    // Total supply of LPT on L1
    // Updates are initiated by a call from the L1LPTDataCache on L1
    uint256 public l1TotalSupply;
    // Amount of L2 LPT transferred from L1 via the LPT bridge
    uint256 public l2SupplyFromL1;

    event CacheTotalSupplyFinalized(uint256 totalSupply);

    modifier onlyL2LPTGateway() {
        require(msg.sender == l2LPTGateway, "NOT_L2_LPT_GATEWAY");
        _;
    }

    /**
     * @notice Sets the L1LPTDataCache
     * @param _l1LPTDataCache L1 address of L1LPTDataCache
     */
    function setL1LPTDataCache(address _l1LPTDataCache) external onlyOwner {
        l1LPTDataCache = _l1LPTDataCache;
    }

    /**
     * @notice Sets the L2LPTGateway
     * @param _l2LPTGateway L2 address of L2LPTGateway
     */
    function setL2LPTGateway(address _l2LPTGateway) external onlyOwner {
        l2LPTGateway = _l2LPTGateway;
    }

    /**
     * @notice Called by L2LPTGateway to increase l2SupplyFromL1
     * @dev Should be called when L2LPTGateway mints LPT to ensure that L2 total supply and l2SupplyFromL1 increase by the same amount
     * @param _amount Amount to increase l2SupplyFromL1
     */
    function increaseL2SupplyFromL1(uint256 _amount) external onlyL2LPTGateway {
        l2SupplyFromL1 += _amount;

        // No event because the L2LPTGateway events are sufficient
    }

    /**
     * @notice Called by L2LPTGateway to decrease l2SupplyFromL1
     * @dev Should be called when L2LPTGateway burns LPT ensure L2 total supply and l2SupplyFromL1 decrease by the same amount
     * @param _amount Amount to decrease l2SupplyFromL1
     */
    function decreaseL2SupplyFromL1(uint256 _amount) external onlyL2LPTGateway {
        // If there is a mass withdrawal from L2, _amount could exceed l2SupplyFromL1.
        // In this case, we just set l2SupplyFromL1 = 0 because there will be no more supply on L2
        // that is from L1 and the excess (_amount - l2SupplyFromL1) is inflationary LPT that was
        // never from L1 in the first place.
        if (_amount > l2SupplyFromL1) {
            l2SupplyFromL1 = 0;
        } else {
            l2SupplyFromL1 -= _amount;
        }

        // No event because the L2LPTGateway events are sufficient
    }

    /**
     * @notice Called by L1LPTDataCache from L1 to cache L1 LPT total supply
     * @param _totalSupply L1 LPT total supply
     */
    function finalizeCacheTotalSupply(uint256 _totalSupply)
        external
        onlyL1Counterpart(l1LPTDataCache)
    {
        l1TotalSupply = _totalSupply;

        emit CacheTotalSupplyFinalized(_totalSupply);
    }

    /**
     * @notice Calculate and return L1 LPT circulating supply
     * @return L1 LPT circulating supply
     */
    function l1CirculatingSupply() public view returns (uint256) {
        // After the first update from L1, l1TotalSupply should always be >= l2SupplyFromL1
        // The below check is defensive to avoid reverting if this invariant for some reason violated
        return
            l1TotalSupply >= l2SupplyFromL1
                ? l1TotalSupply - l2SupplyFromL1
                : 0;
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

pragma solidity ^0.8.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint256);

    function arbChainID() external view returns (uint256);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1)
        external
        payable
        returns (uint256);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account)
        external
        view
        returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint256 amount);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );
}