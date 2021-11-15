// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;

import "./interface/ISignal.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XPNSignal is ISignal, Ownable {
    struct signalMetaData {
        string signalType;
        bool signalExist;
        bool signalActive;
    }
    mapping(address => mapping(string => bool)) ownSignals;
    mapping(string => int256[]) signalsWeight;
    mapping(string => string[]) signalsSymbol;
    mapping(string => signalMetaData) signalsMetaData;
    mapping(address => bool) signalProviderWhitelist;

    address[] assetAddress;
    event SignalProviderWhitelisted(address wallet);
    event SignalProviderDeWhitelisted(address wallet);

    constructor() {
        whitelistsignalProvider(msg.sender);
    }

    // @notice register a new signal. caller will own the signal
    // @param signalName unique identifier of the signal.
    // @param signalType general info about the signal.
    // @param symbols list of symbol that this signal will address. order sensitive. immutable
    function registerSignal(
        string memory signalName,
        string memory signalType,
        string[] memory symbols
    ) external override returns (string memory) {
        require(
            _signalProviderIsWhitelisted(msg.sender),
            "Wallet is not whitelisted"
        );

        if (signalsMetaData[signalName].signalExist) {
            revert("signal already exist");
        }

        ownSignals[msg.sender][signalName] = true;
        signalsMetaData[signalName] = signalMetaData({
            signalType: signalType,
            signalExist: true,
            signalActive: false
        });
        signalsSymbol[signalName] = symbols;
    }

    // @notice whitelist wallet by address
    // @param address of the wallet to whitelist
    // @dev only callable by owner
    function whitelistsignalProvider(address wallet) public onlyOwner {
        signalProviderWhitelist[wallet] = true;
        emit SignalProviderWhitelisted(wallet);
    }

    // @notice un-whitelist wallet by address
    // @param address of the wallet to un-whitelist
    // @dev only callable by owner
    function deWhitelistsignalProvider(address wallet) public onlyOwner {
        signalProviderWhitelist[wallet] = false;
        emit SignalProviderDeWhitelisted(wallet);
    }

    function _signalProviderIsWhitelisted(address wallet)
        private
        view
        returns (bool)
    {
        return signalProviderWhitelist[wallet];
    }

    // @notice make a signal inactive
    // @dev caller must be signal owner
    function withdrawSignal(string memory signalName) external override {
        require(ownSignals[msg.sender][signalName], "not your signal");
        signalsMetaData[signalName].signalActive = false;
    }

    // @notice signal weight setter. just store signal weight as signal.
    // @dev some of the param are just from ISignal, not really in use.
    // @param signalName unique identifier of signal
    // @param ref not in use.
    // @param weights of each asset.
    // @param data not in use.
    function submitSignal(
        string memory signalName,
        string[] memory ref,
        int256[] memory weights,
        bytes calldata data
    ) external override {
        require(ownSignals[msg.sender][signalName], "not your signal");
        require(
            weights.length == signalsSymbol[signalName].length,
            "signal length mismatch"
        );
        signalsWeight[signalName] = weights;
        signalsMetaData[signalName].signalActive = true;
    }

    // @notice do nothing. this function is from ISignal.
    function updateSignal(string memory signalName) external override {
        revert("this signal do not require any update");
    }

    // @notice get symbol list of the signal
    // @param signalName unique identifier of signal
    // @return string[] list of symbol
    function getSignalSymbols(string memory signalName)
        external
        view
        override
        returns (string[] memory)
    {
        require(
            signalsMetaData[signalName].signalActive,
            "signal not available"
        );
        return signalsSymbol[signalName];
    }

    // @notice get symbol list of the signal
    // @param signalName unique identifier of signal
    // @return int256[] signal, % target allocation between each symbols.
    function getSignal(string memory signalName)
        external
        view
        override
        returns (int256[] memory)
    {
        require(
            signalsMetaData[signalName].signalActive,
            "signal not available"
        );

        return signalsWeight[signalName];
    }
}

pragma solidity 0.8.0;

interface ISignal {
    function registerSignal(
        string memory,
        string memory,
        string[] memory
    ) external returns (string memory);

    function withdrawSignal(string memory) external;

    function submitSignal(
        string memory,
        string[] memory,
        int256[] memory,
        bytes calldata
    ) external;

    function updateSignal(string memory) external;

    function getSignal(string memory) external view returns (int256[] memory);

    function getSignalSymbols(string memory)
        external
        view
        returns (string[] memory);
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

