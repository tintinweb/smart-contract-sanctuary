// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IPriceUSD.sol';

/**
 * @title SWMPriceOracle
 * Serves to get the currently valid (not necessarily current) price of SWM in USD.
 *
 * Note: 0.019 will be returned as (19, 1000). Solidity at this point cannot natively
 *       handle decimal numbers, so we work with two values. Caller needs to be aware of this.
 *
 * @dev Needs to conform to the IPriceUSD interface, otherwise can be rewritten to
 *      use whichever method of setting the price is desired (manual, external oracle...)
 */
contract SWMPriceOracle is IPriceUSD, Ownable {
  event UpdatedSWMPriceUSD(
    uint256 oldPriceNumerator,
    uint256 oldPriceDenominator,
    uint256 newPriceNumerator,
    uint256 newPriceDenominator
  );

  uint256 public priceNumerator;
  uint256 public priceDenominator;

  constructor(uint256 _priceNumerator, uint256 _priceDenominator) {
    require(_priceNumerator > 0, 'numerator must not be zero');
    require(_priceDenominator > 0, 'denominator must not be zero');

    priceNumerator = _priceNumerator;
    priceDenominator = _priceDenominator;

    emit UpdatedSWMPriceUSD(0, 0, _priceNumerator, _priceNumerator);
  }

  /**
   *  This function gets the price of SWM in USD
   *
   *  0.0736 is returned as (736, 10000)
   *  @return numerator The numerator of the currently valid price of SWM in USD
   *  @return denominator The denominator of the currently valid price of SWM in USD
   **/
  function getPrice() external override view returns (uint256 numerator, uint256 denominator) {
    return (priceNumerator, priceDenominator);
  }

  /**
   *  This function can be called manually or programmatically to update the
   *  currently valid price of SWM in USD
   *
   *  To update to 0.00378 call with (378, 100000)
   *  @param _priceNumerator The new SWM price in USD
   *  @param _priceDenominator The new SWM price in USD
   *  @return true on success
   */
  function updatePrice(uint256 _priceNumerator, uint256 _priceDenominator)
    external
    onlyOwner
    returns (bool)
  {
    require(_priceNumerator > 0, 'numerator must not be zero');
    require(_priceDenominator > 0, 'denominator must not be zero');

    emit UpdatedSWMPriceUSD(priceNumerator, priceDenominator, _priceNumerator, _priceDenominator);

    priceNumerator = _priceNumerator;
    priceDenominator = _priceDenominator;

    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
    @title The interface for the exchange rate provider contracts
 */
interface IPriceUSD {
  function getPrice() external view returns (uint256 numerator, uint256 denominator);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}