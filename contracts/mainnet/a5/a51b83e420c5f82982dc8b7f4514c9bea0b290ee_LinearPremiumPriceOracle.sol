/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/ethregistrar/SafeMath.sol

pragma solidity >=0.8.4;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


// File contracts/ethregistrar/PriceOracle.sol

pragma solidity >=0.8.4;

interface PriceOracle {
    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (0 if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return The price of this renewal or registration, in wei.
     */
    function price(string calldata name, uint expires, uint duration) external view returns(uint);
}


// File contracts/ethregistrar/StringUtils.sol

pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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


// File contracts/ethregistrar/StablePriceOracle.sol

pragma solidity >=0.8.4;




interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
}


// StablePriceOracle sets a price in USD, based on an oracle.
contract StablePriceOracle is Ownable, PriceOracle {
    using SafeMath for *;
    using StringUtils for *;

    // Rent in base price units by length. Element 0 is for 1-length names, and so on.
    uint[] public rentPrices;

    // Oracle address
    AggregatorInterface public immutable usdOracle;

    event OracleChanged(address oracle);

    event RentPriceChanged(uint[] prices);

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ORACLE_ID = bytes4(keccak256("price(string,uint256,uint256)") ^ keccak256("premium(string,uint256,uint256)"));

    constructor(AggregatorInterface _usdOracle, uint[] memory _rentPrices) public {
        usdOracle = _usdOracle;
        setPrices(_rentPrices);
    }

    function price(string calldata name, uint expires, uint duration) external view override returns(uint) {
        uint len = name.strlen();
        if(len > rentPrices.length) {
            len = rentPrices.length;
        }
        require(len > 0);
        
        uint basePrice = rentPrices[len - 1].mul(duration);
        basePrice = basePrice.add(_premium(name, expires, duration));

        return attoUSDToWei(basePrice);
    }

    /**
     * @dev Sets rent prices.
     * @param _rentPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element. Values are
     *                    in base price units, equal to one attodollar (1e-18
     *                    dollar) each.
     */
    function setPrices(uint[] memory _rentPrices) public onlyOwner {
        rentPrices = _rentPrices;
        emit RentPriceChanged(_rentPrices);
    }

    /**
     * @dev Returns the pricing premium in wei.
     */
    function premium(string calldata name, uint expires, uint duration) external view returns(uint) {
        return attoUSDToWei(_premium(name, expires, duration));
    }

    /**
     * @dev Returns the pricing premium in internal base units.
     */
    function _premium(string memory name, uint expires, uint duration) virtual internal view returns(uint) {
        return 0;
    }

    function attoUSDToWei(uint amount) internal view returns(uint) {
        uint ethPrice = uint(usdOracle.latestAnswer());
        return amount.mul(1e8).div(ethPrice);
    }

    function weiToAttoUSD(uint amount) internal view returns(uint) {
        uint ethPrice = uint(usdOracle.latestAnswer());
        return amount.mul(ethPrice).div(1e8);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
        return interfaceID == INTERFACE_META_ID || interfaceID == ORACLE_ID;
    }
}


// File contracts/ethregistrar/LinearPremiumPriceOracle.sol

pragma solidity >=0.8.4;


contract LinearPremiumPriceOracle is StablePriceOracle {
    using SafeMath for *;

    uint immutable GRACE_PERIOD = 90 days;

    uint public immutable initialPremium;
    uint public immutable premiumDecreaseRate;

    bytes4 constant private TIME_UNTIL_PREMIUM_ID = bytes4(keccak256("timeUntilPremium(uint,uint"));

    constructor(AggregatorInterface _usdOracle, uint[] memory _rentPrices, uint _initialPremium, uint _premiumDecreaseRate) public
        StablePriceOracle(_usdOracle, _rentPrices)
    {
        initialPremium = _initialPremium;
        premiumDecreaseRate = _premiumDecreaseRate;
    }

    function _premium(string memory name, uint expires, uint /*duration*/) override internal view returns(uint) {
        expires = expires.add(GRACE_PERIOD);
        if(expires > block.timestamp) {
            // No premium for renewals
            return 0;
        }

        // Calculate the discount off the maximum premium
        uint discount = premiumDecreaseRate.mul(block.timestamp.sub(expires));

        // If we've run out the premium period, return 0.
        if(discount > initialPremium) {
            return 0;
        }
        
        return initialPremium - discount;
    }

    /**
     * @dev Returns the timestamp at which a name with the specified expiry date will have
     *      the specified re-registration price premium.
     * @param expires The timestamp at which the name expires.
     * @param amount The amount, in wei, the caller is willing to pay
     * @return The timestamp at which the premium for this domain will be `amount`.
     */
    function timeUntilPremium(uint expires, uint amount) external view returns(uint) {
        amount = weiToAttoUSD(amount);
        require(amount <= initialPremium);

        expires = expires.add(GRACE_PERIOD);

        uint discount = initialPremium.sub(amount);
        uint duration = discount.div(premiumDecreaseRate);
        return expires.add(duration);
    }

    function supportsInterface(bytes4 interfaceID) public view virtual override returns (bool) {
        return (interfaceID == TIME_UNTIL_PREMIUM_ID) || super.supportsInterface(interfaceID);
    }
}