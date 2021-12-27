/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-26
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/AssetManager.sol

// contracts/AssetManager.sol

pragma solidity ^0.8.10;


struct Asset {
    bool listedForSale;
    address payable owner;
    string name;
    uint256 fixedPrice;
    uint8 stakesAvailable;
    uint8 stakesReserved;
    mapping(uint => address payable) stakes;
}

contract AssetManager {

    using SafeMath for uint256;
    using SafeMath for uint8;

    uint public assetCount = 0;
    mapping(uint => Asset) public assets;

    event AssetPurchase(uint AssetId, address PreviousOwner, address NewOwner, uint PurchasePrice);
    event DelistAsset(uint AssetId);
    event ListAsset(uint AssetId);
    event PriceAdjusted(uint AssetId, uint PreviousPrice, uint NewPrice);
    event Registered(uint AssetId, address Owner, string Name, uint FixedPrice, uint8 StakesAvailable);
    event StakePurchase(uint AssetId, address Stakeholder, uint StakePrice);

    function adjustFixedPrice(uint assetId, uint newPrice) external {
        Asset storage a = assets[assetId];
        require(a.owner == msg.sender, "Only the Asset owner can de-list this asset");
        uint oldPrice = a.fixedPrice;
        a.fixedPrice = newPrice;

        emit PriceAdjusted(assetId, oldPrice, newPrice);
    }

    function delist(uint assetId) external {
        Asset storage a = assets[assetId];
        require(a.owner == msg.sender, "Only the Asset owner can de-list this asset");
        a.listedForSale = false;

        emit DelistAsset(assetId);
    }

    function getRemainingStakes(uint assetId) public view returns (uint8) {
        Asset storage a = assets[assetId];
        return uint8(a.stakesAvailable.sub(a.stakesReserved));
    }

    function getStakeHolders(uint assetId) external view returns (address[] memory) {
        Asset storage a = assets[assetId];
        address[] memory result = new address[](a.stakesReserved);
        for (uint x = 0; x < a.stakesReserved; x++) {
            result[x] = a.stakes[x];
        }
        return result;
    }

    function getStakePrice(uint assetId) public view returns (uint) {
        return assets[assetId].fixedPrice.div(assets[assetId].stakesAvailable);
    }

    function list(uint assetId) external {
        Asset storage a = assets[assetId];
        require(a.owner == msg.sender, "Only the Asset owner can list this asset");
        a.listedForSale = true;

        emit ListAsset(assetId);
    }

    function purchaseAsset(uint assetId) external payable {
        Asset storage a = assets[assetId];
        require(a.listedForSale, "This asset is not listed for sale");
        require(msg.value >= a.fixedPrice, "Transaction value does not match the asset price");
        uint stakePrice = getStakePrice(assetId);
        for (uint i = 0; i < a.stakesReserved; i++) {
            //pay stakeholders
            a.stakes[i].transfer(stakePrice);
        }

        if (a.stakesAvailable > a.stakesReserved) {
            //pay balance to owner
            uint8 stakesRemaining = getRemainingStakes(assetId);
            a.owner.transfer(uint(stakesRemaining) * stakePrice);
        }
        address previousOwner = a.owner;
        a.owner = payable(msg.sender);
        
        emit AssetPurchase(assetId, previousOwner, msg.sender, a.fixedPrice);
    }

    function purchaseStake(uint assetId) external payable {
        uint8 remainingStakes = getRemainingStakes(assetId);
        require(remainingStakes > 0, "No Stake available");
        uint stakePrice = getStakePrice(assetId);
        require(msg.value == stakePrice, "Transaction value does not match the stake price");
        
        Asset storage a = assets[assetId];
        a.owner.transfer(msg.value);
        a.stakes[a.stakesReserved] = payable(msg.sender); 
        a.stakesReserved++;
        
        emit StakePurchase(assetId, msg.sender, msg.value);
    }

    function register(string memory name, uint fixedPrice, uint8 stakesAvailable) external {
        bytes memory byteString = bytes(name);
        require(byteString.length > 0, "Asset must have a valid name");
        require(stakesAvailable > 0, "Asset must have at least 1 stake");
        Asset storage a = assets[assetCount];
        a.listedForSale = false;  
        a.owner = payable(msg.sender);
        a.name = name;
        a.fixedPrice = fixedPrice;
        a.stakesAvailable = stakesAvailable;
        a.stakesReserved = 0;

        emit Registered(assetCount, msg.sender, name, fixedPrice, stakesAvailable);

        assetCount++;
    }
}