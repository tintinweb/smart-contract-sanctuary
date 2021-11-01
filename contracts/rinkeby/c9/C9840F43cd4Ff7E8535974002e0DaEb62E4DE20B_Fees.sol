// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @title meToken Fees
/// @author Carl Farterson (@carlfarterson)
/// @notice contract to manage all meToken fees
contract Fees is Ownable, Initializable {
    uint256 private _feeMax = 10**18;
    /// @dev for when a meToken is minted
    uint256 private _mintFee;
    /// @dev for when a meToken is burned by non-owner
    uint256 private _burnBuyerFee;
    /// @dev for when a meToken is burned by owner
    uint256 private _burnOwnerFee;
    /// @dev for when a meToken is transferred
    uint256 private _transferFee;
    /// @dev Generated from interest on collateral
    uint256 private _interestFee;
    /// @dev Generated from liquidity mining
    uint256 private _yieldFee;

    event SetMintFee(uint256 rate);
    event SetBurnBuyerFee(uint256 rate);
    event SetBurnOwnerFee(uint256 rate);
    event SetTransferFee(uint256 rate);
    event SetInterestFee(uint256 rate);
    event SetYieldFee(uint256 rate);

    function initialize(
        uint256 mintFee_,
        uint256 burnBuyerFee_,
        uint256 burnOwnerFee_,
        uint256 transferFee_,
        uint256 interestFee_,
        uint256 yieldFee_
    ) external onlyOwner initializer {
        _mintFee = mintFee_;
        _burnBuyerFee = burnBuyerFee_;
        _burnOwnerFee = burnOwnerFee_;
        _transferFee = transferFee_;
        _interestFee = interestFee_;
        _yieldFee = yieldFee_;
    }

    function setMintFee(uint256 rate) external onlyOwner {
        require(rate != _mintFee && rate < _feeMax, "out of range");
        _mintFee = rate;
        emit SetMintFee(rate);
    }

    function setBurnBuyerFee(uint256 rate) external onlyOwner {
        require(rate != _burnBuyerFee && rate < _feeMax, "out of range");
        _burnBuyerFee = rate;
        emit SetBurnBuyerFee(rate);
    }

    function setBurnOwnerFee(uint256 rate) external onlyOwner {
        require(rate != _burnOwnerFee && rate < _feeMax, "out of range");
        _burnOwnerFee = rate;
        emit SetBurnOwnerFee(rate);
    }

    function setTransferFee(uint256 rate) external onlyOwner {
        require(rate != _transferFee && rate < _feeMax, "out of range");
        _transferFee = rate;
        emit SetTransferFee(rate);
    }

    function setInterestFee(uint256 rate) external onlyOwner {
        require(rate != _interestFee && rate < _feeMax, "out of range");
        _interestFee = rate;
        emit SetInterestFee(rate);
    }

    function setYieldFee(uint256 rate) external onlyOwner {
        require(rate != _yieldFee && rate < _feeMax, "out of range");
        _yieldFee = rate;
        emit SetYieldFee(rate);
    }

    function mintFee() public view returns (uint256) {
        return _mintFee;
    }

    function burnBuyerFee() public view returns (uint256) {
        return _burnBuyerFee;
    }

    function burnOwnerFee() public view returns (uint256) {
        return _burnOwnerFee;
    }

    function transferFee() public view returns (uint256) {
        return _transferFee;
    }

    function interestFee() public view returns (uint256) {
        return _interestFee;
    }

    function yieldFee() public view returns (uint256) {
        return _yieldFee;
    }
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
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