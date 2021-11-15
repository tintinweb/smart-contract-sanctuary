// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./InterfacesPriceOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
}

contract PriceFeedOracle is PriceOracle, Ownable {
    address public cBNB;
    mapping(address => address) public priceFeeds;

    constructor(
        address cBNB_,
        address priceFeedBNB_
    ) {
        require(
            cBNB == address(0) &&
            priceFeeds[cBNB_] == address(0)
            , "FixedPriceOracle: address is 0"
        );

        cBNB = cBNB_;
        priceFeeds[cBNB_] = priceFeedBNB_;
    }

    function getUnderlyingPrice(address cToken) external view override returns (uint) {
        if (cToken == cBNB) {
            return getUSDPrice(cBNB);
        }

        address asset = CErc20Interface(cToken).underlying();
        uint price = getUSDPrice(asset);
        uint decimals = EIP20Interface(asset).decimals();

        return price * (10 ** (36 - decimals)) / 1e18;
    }

    function getUSDPrice(address asset) public view returns (uint) {
        uint usdPrice;
        uint assetCourse = 1e18;

        if (priceFeeds[asset] != address(0)) {
            usdPrice = uint(AggregatorInterface(priceFeeds[asset]).latestAnswer());
        }

        // div 1e8 is chainlink precision for ETH
        return usdPrice * assetCourse / 1e8;
    }

    function setCBNB(address cBNB_) public onlyOwner returns (bool) {
        cBNB = cBNB_;

        return true;
    }

    function setPriceFeed(address asset_, address feed_) public onlyOwner returns (bool) {
        priceFeeds[asset_] = feed_;

        return true;
    }

    function setPriceFeeds(address[] memory assets_, address[] memory feeds_) public onlyOwner returns (bool) {
        require(assets_.length == feeds_.length, "SpaceOracle::setPriceFeed: array length mismatch");

        for(uint i = 0; i < assets_.length; i++) {
            priceFeeds[assets_[i]] = feeds_[i];
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    bool public constant isPriceOracle = true;

    /**
      * @notice Get the underlying price of a cToken asset
      * @param cToken The cToken to get the underlying price of
      * @return The underlying asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
    function getUnderlyingPrice(address cToken) external view virtual returns (uint);
}

abstract contract CErc20Interface {
    address public underlying;
}

interface EIP20Interface {
    function decimals() external view returns (uint8);
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

/*
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

