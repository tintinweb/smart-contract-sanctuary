// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { InstaAaveV2MerkleResolver } from "./aaveResolver.sol";

interface IndexInterface {
    function master() external view returns (address);
}

interface InstaListInterface {
    function accountID(address) external view returns (uint64);
}

interface InstaAccountInterface {
    function version() external view returns (uint256);
}

contract InstaAaveV2MerkleDistributor is InstaAaveV2MerkleResolver, Ownable {
    event Claimed(
        uint256 indexed index,
        address indexed dsa,
        address account,
        uint256 claimedRewardAmount,
        uint256 claimedNetworthsAmount
    );

    address public constant token = 0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb;
    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    InstaListInterface public constant instaList = 
        InstaListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);
    bytes32 public immutable merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(bytes32 merkleRoot_, address _owner) public {
        merkleRoot = merkleRoot_;
        transferOwnership(_owner);
    }

    /**
     * @dev Throws if the sender not is Master Address from InstaIndex or owner
    */
    modifier isOwner {
        require(_msgSender() == IndexInterface(instaIndex).master() || owner() == _msgSender(), "caller is not the owner or master");
        _;
    }

    modifier isDSA {
        require(instaList.accountID(msg.sender) != 0, "InstaAaveV2MerkleDistributor:: not a DSA wallet");
        require(InstaAccountInterface(msg.sender).version() == 2, "InstaAaveV2MerkleDistributor:: not a DSAv2 wallet");
        _;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 rewardAmount,
        uint256 networthAmount,
        bytes32[] calldata merkleProof,
        address[] memory supplytokens,
        address[] memory borrowtokens,
        uint256[] memory supplyAmounts,
        uint256[] memory borrowAmounts
    ) 
        external
        isDSA
    {
        require(!isClaimed(index), 'InstaAaveV2MerkleDistributor: Drop already claimed.');
        require(supplytokens.length > 0, "InstaAaveV2MerkleDistributor: Address length not vaild");
        require(supplytokens.length == supplyAmounts.length, "InstaAaveV2MerkleDistributor: supply addresses and amounts doesn't match");
        require(borrowtokens.length == borrowAmounts.length, "InstaAaveV2MerkleDistributor: borrow addresses and amounts doesn't match");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, rewardAmount, networthAmount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'InstaAaveV2MerkleDistributor: Invalid proof.');

        // Calculate claimable amount
        (uint256 claimableRewardAmount, uint256 claimableNetworth) = getPosition(
            networthAmount,
            rewardAmount,
            supplytokens,
            borrowtokens,
            supplyAmounts,
            borrowAmounts
        );
        require(claimableRewardAmount > 0 && claimableNetworth > 0, "InstaAaveV2MerkleDistributor: claimable amounts not vaild");
        require(rewardAmount >= claimableRewardAmount, 'InstaAaveV2MerkleDistributor: claimableRewardAmount more then reward.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(msg.sender, claimableRewardAmount), 'InstaAaveV2MerkleDistributor: Transfer failed.');

        emit Claimed(index, msg.sender, account, claimableRewardAmount, claimableNetworth);
    }

    function spell(address _target, bytes memory _data) public isOwner {
        require(_target != address(0), "target-invalid");
        assembly {
        let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
        switch iszero(succeeded)
            case 1 {
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
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

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import { DSMath } from "../../../../common/math.sol";
import { TokenInterface } from "../../../../common/interfaces.sol";

interface AaveProtocolDataProvider {
    function getUserReserveData(address asset, address user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );

    function getReserveConfigurationData(address asset) external view returns (
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    );
}

interface AaveAddressProvider {
    function getLendingPool() external view returns (address);
    function getPriceOracle() external view returns (address);
}

interface AavePriceOracle {
    function getAssetPrice(address _asset) external view returns(uint256);
    function getAssetsPrices(address[] calldata _assets) external view returns(uint256[] memory);
    function getSourceOfAsset(address _asset) external view returns(uint256);
    function getFallbackOracle() external view returns(uint256);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}


contract Variables {
    ChainLinkInterface public constant ethPriceFeed = ChainLinkInterface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    AaveProtocolDataProvider public constant aaveDataProvider = AaveProtocolDataProvider(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    AaveAddressProvider public constant aaveAddressProvider = AaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    address public constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
}

contract Resolver is Variables, DSMath {
    struct Position {
        uint256 supplyLength;
        uint256 borrowLength;
        address[] _supplyTokens;
        address[] _borrowTokens;
        uint256 ethPriceInUSD;
        uint256 totalSupplyInETH;
        uint256 totalBorrowInETH;
        uint256[] supplyTokenPrices;
        uint256[] borrowTokenPrices;
        uint256[] supplyTokenDecimals;
        uint256[] borrowTokenDecimals;
    }
    function _getPosition(
        uint256 networthAmount,
        uint256 rewardAmount,
        address[] memory supplyTokens,
        address[] memory borrowTokens,
        uint256[] memory supplyAmounts,
        uint256[] memory borrowAmounts
    ) 
    internal
    view 
    returns (
        uint256 claimableRewardAmount,
        uint256 claimableNetworth
    ) {
        Position memory position;
        position.supplyLength = supplyTokens.length;
        position.borrowLength = borrowTokens.length;

        position._supplyTokens = new address[](position.supplyLength);
        position._borrowTokens = new address[](position.borrowLength);
        position.supplyTokenDecimals = new uint256[](position.supplyLength);
        position.borrowTokenDecimals = new uint256[](position.borrowLength);

        for (uint i = 0; i < position.supplyLength; i++) {
            position._supplyTokens[i] = supplyTokens[i] == ethAddr ? wethAddr : supplyTokens[i];
            position.supplyTokenDecimals[i] = TokenInterface(position._supplyTokens[i]).decimals();
        }
        
        for (uint i = 0; i < position.borrowLength; i++) {
            position._borrowTokens[i] = borrowTokens[i] == ethAddr ? wethAddr : borrowTokens[i];
            position.borrowTokenDecimals[i] = TokenInterface(position._borrowTokens[i]).decimals();
        }

        position.ethPriceInUSD = uint(ethPriceFeed.latestAnswer());

        AavePriceOracle aavePriceOracle = AavePriceOracle(aaveAddressProvider.getPriceOracle());

        position.totalSupplyInETH = 0;
        position.totalBorrowInETH = 0;

       position.supplyTokenPrices = aavePriceOracle.getAssetsPrices(position._supplyTokens);
       position.borrowTokenPrices = aavePriceOracle.getAssetsPrices(position._borrowTokens);

        for (uint256 i = 0; i < position.supplyLength; i++) {
            require(supplyAmounts[i] > 0, "InstaAaveV2MerkleDistributor:: _getPosition: supply amount not valid");
            uint256 supplyInETH = wmul((supplyAmounts[i] * 10 ** (18 - position.supplyTokenDecimals[i])), position.supplyTokenPrices[i]);

            position.totalSupplyInETH = add(position.totalSupplyInETH, supplyInETH);
        }

        for (uint256 i = 0; i < position.borrowLength; i++) {
            require(borrowAmounts[i] > 0, "InstaAaveV2MerkleDistributor:: _getPosition: borrow amount not valid");
            uint256 borrowInETH = wmul((borrowAmounts[i] * 10 ** (18 - position.borrowTokenDecimals[i])), position.borrowTokenPrices[i]);

            position.totalBorrowInETH = add(position.totalBorrowInETH, borrowInETH);
        }

        claimableNetworth = sub(position.totalSupplyInETH, position.totalBorrowInETH);
        claimableNetworth = wmul(claimableNetworth, position.ethPriceInUSD * 1e10);

        if (networthAmount > claimableNetworth) {
            claimableRewardAmount = wdiv(claimableNetworth, networthAmount);
            claimableRewardAmount = wmul(rewardAmount, claimableRewardAmount);
        } else {
            claimableRewardAmount = rewardAmount;
        }
    }

    function getPosition(
        uint256 networthAmount,
        uint256 rewardAmount,
        address[] memory supplyTokens,
        address[] memory borrowTokens,
        uint256[] memory supplyAmounts,
        uint256[] memory borrowAmounts
    ) 
    public
    view 
    returns (
        uint256 claimableRewardAmount,
        uint256 claimableNetworth
    ) { 
        return _getPosition(
            networthAmount,
            rewardAmount,
            supplyTokens,
            borrowTokens,
            supplyAmounts,
            borrowAmounts
        ); 
    }
}

contract InstaAaveV2MerkleResolver is Resolver {
    string public constant name = "AaveV2-Merkle-Resolver-v1.0";
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

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
    function cast(
        string[] calldata _targets,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
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