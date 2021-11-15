// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IMinersNFTs.sol";

contract MncNFTStore is Ownable, Pausable {
    using SafeMath for uint256;

    event ProductCreated(
        uint256 indexed productId,
        address indexed token,
        uint256 publishBlock,
        uint256 expireBlock,
        uint256 rebateWaitBlock,
        uint256 amountPerNFT,
        uint256 rebatePercentage,
        uint256 nftTypeId
    );
    event MinersNFTsChanged(address oldMinersNFTs, address newMinersNFTs);
    event CashierAddressChanged(address oldCashierAddress, address cashierAddress);

    event GetNFT(uint256 indexed productId, address indexed staker, address token, uint256 amount);
    event Rebate(address indexed staker, uint256 amount);

    /**
     * @param publishBlock the block from  starts
     * @param expireBlock the block from stops
     * @param rebateWaitBlock 
     * @param nftTypeId the nft tpye id for this product
     * @param amountPerNFT 
     * @param rebatePercentage the nft tpye id for this product
     * @param token token to be staked
     */
    struct ProductInfo {
        uint256 publishBlock;
        uint256 expireBlock;
        uint256 rebateWaitBlock;
        uint256 amountPerNFT;
        uint256 rebatePercentage; // 100% is 1 * e18 ,50% is 0.5 * e18
        uint256 nftTypeId;
        address token;
    }
    /**
     * @param totalTokenAmount total token amount of NFT sales
     */
    struct ProductData {
        uint256 totalTokenAmount;
    }
    /**
     * @param totalSpentAmount amount of token the user stakes
     */
    struct UserData {
        uint256 totalSpentAmount;
    }
    struct Vesting {
        uint256 productId;
        uint256 amount;
        uint256 entryBlock;
        uint256 unlockBlock;
    }

    struct VestingInfo {
        uint8 firstVesting;
        uint8 lastVesting;
    }

    uint256 public lastProductId; // The first product has ID of 1
    IMinersNFTs public minersNFTs;
    address public cashierAddress;
    uint256 private constant e18 = 10**18;


    mapping(uint256 => ProductInfo) public productInfos;
    mapping(uint256 => ProductData) public productData;
    mapping(uint256 => mapping(address => UserData)) public userData;
    mapping(address => VestingInfo) public userVestingInfo;
    mapping(address =>mapping(uint8 => Vesting)) public userVesting;


    modifier onlyProductExists(uint256 productId) {
        require(productInfos[productId].expireBlock > 0, "MncNFTStore: product not found");
        _;
    }

    modifier onlyProductActive(uint256 productId) {
        require(
            block.number >= productInfos[productId].publishBlock && block.number < productInfos[productId].expireBlock,
            "MncNFTStore: product not active"
        );
        _;
    }

    function pauseStaking() external onlyOwner whenNotPaused {
        _pause();
    }

    constructor(address _minersNFTs) {
        require(_minersNFTs != address(0), "MncNFTStore: zero address");

        minersNFTs = IMinersNFTs(_minersNFTs);
    }

    function createProduct(
        address token,
        uint256 publishBlock,
        uint256 expireBlock,
        uint256 rebateWaitBlock,
        uint256 amountPerNFT,
        uint256 rebatePercentage,
        uint256 nftTypeId
    ) external onlyOwner whenNotPaused{
        require(token != address(0), "MncNFTStore: zero address");
        require(
            publishBlock > block.number && expireBlock > publishBlock ,
            "MncNFTStore: invalid block range"
        );
        require(amountPerNFT > 0, "MncNFTStore: amountPerNFT must be positive");
        require(rebatePercentage > 0 && rebatePercentage <= 1 * e18, "MncNFTStore: rebatePercentage must be positive");
        require(nftTypeId <= minersNFTs.lastTypeId(), "MncNFTStore: nft tpyeId not found");

        uint256 newProductId = ++lastProductId;

        productInfos[newProductId] = ProductInfo({
            publishBlock: publishBlock,
            expireBlock: expireBlock,
            rebateWaitBlock: rebateWaitBlock,
            amountPerNFT: amountPerNFT,
            rebatePercentage: rebatePercentage,
            nftTypeId: nftTypeId,
            token: token
        });
        productData[newProductId] = ProductData({totalTokenAmount: 0});

        emit ProductCreated(newProductId, token, publishBlock, expireBlock, rebateWaitBlock, amountPerNFT, rebatePercentage, nftTypeId);
    }

    function setMinersNFTs(address newMinersNFTs) external onlyOwner {
        require(newMinersNFTs != address(0), "MncNFTStore: zero address");
        address oldMinersNFTs = address(minersNFTs);
        minersNFTs = IMinersNFTs(newMinersNFTs);

        emit MinersNFTsChanged(oldMinersNFTs, newMinersNFTs);
    }

    function setCashierAddress(address _cashierAddress) external onlyOwner {
        require(_cashierAddress != address(0), "MncNFTStore: zero address");
        address oldCashierAddress = cashierAddress;
        cashierAddress = _cashierAddress;

        emit CashierAddressChanged(oldCashierAddress, cashierAddress);
    }

    function getNFT(uint256 productId, uint256 amount) external whenNotPaused onlyProductExists(productId) onlyProductActive(productId) {
        _getNFT(productId, msg.sender, amount);
        //here mint nft
        uint256 nftAmount = amount.div(productInfos[productId].amountPerNFT).mul(10**18);
        minersNFTs.mintNFT(msg.sender, productInfos[productId].nftTypeId, nftAmount);
    }

    function rebate(uint256 amount) external whenNotPaused {
        _rebate(msg.sender, amount);
    }

    function emergencyUnstake(uint256 productId) external whenPaused onlyProductExists(productId) {
        uint256 amount = userData[productId][msg.sender].totalSpentAmount;
        TransferHelper.safeTransfer(productInfos[productId].token, msg.sender, amount);
        userData[productId][msg.sender].totalSpentAmount = 0;
        productData[productId].totalTokenAmount = productData[productId].totalTokenAmount.sub(amount);
    }
    function rebatable(address user) external whenNotPaused view returns (uint256) {
        return _rebatable(user);
    }

    function _rebatable(address user) private view returns (uint256) {
        uint8 i = userVestingInfo[user].firstVesting +1;
        uint256 rebatableAmount = 0;
        for (i; i <= userVestingInfo[user].lastVesting; i++ ){
            if (block.number >= userVesting[user][i].unlockBlock){
                rebatableAmount = rebatableAmount.add(userVesting[user][i].amount);
            }
        }
        return rebatableAmount;

    }

    function _getNFT(
        uint256 productId,
        address user,
        uint256 amount
    ) private {
        require(amount > 0, "MncNFTStore: cannot getNFT zero amount");
        require(amount.mod(productInfos[productId].amountPerNFT) == 0, "MncNFTStore: amount not amountPerNFT multiple");

        uint256 rebatePercentage = productInfos[productId].rebatePercentage;

        userData[productId][user].totalSpentAmount = userData[productId][user].totalSpentAmount.add(amount.mul(rebatePercentage).div(1*e18));
        productData[productId].totalTokenAmount = productData[productId].totalTokenAmount.add(amount.mul(rebatePercentage).div(1*e18));

        uint8 vestingIndex = userVestingInfo[user].lastVesting + 1;
        userVesting[user][vestingIndex] = Vesting({
            productId: productId,
            amount: amount.mul(rebatePercentage).div(1*e18),
            entryBlock: block.number,
            unlockBlock: block.number.add(productInfos[productId].rebateWaitBlock)
            });
        userVestingInfo[user].lastVesting = vestingIndex;

        TransferHelper.safeTransferFrom(productInfos[productId].token, user, address(this), amount.mul(rebatePercentage).div(1*e18));

        if (rebatePercentage != 1*e18){
            require(cashierAddress != address(0), "MncNFTStore: cashier is zero address");
            TransferHelper.safeTransferFrom(productInfos[productId].token, user, cashierAddress, amount.mul(uint256(1*e18).sub(rebatePercentage)).div(1*e18));
        } 

        emit GetNFT(productId, user, productInfos[productId].token, amount);
    }

    function _rebate(
        address user,
        uint256 amount
    ) private {
        uint256 rebatable = _rebatable(user);
        require(amount > 0, "MncNFTStore: cannot rebate zero amount");
        require(rebatable > 0, "MncNFTStore: no rebate amount");
        require(amount <= rebatable, "MncNFTStore: not enough rebate amount");


        uint8 i = userVestingInfo[user].firstVesting + 1;
        uint256 remaining = amount;
        uint256 productId;

        for (i; i <= userVestingInfo[user].lastVesting; i++ ){
            productId = userVesting[user][i].productId;

            if (block.number >= userVesting[user][i].unlockBlock){
                if (remaining >= userVesting[user][i].amount) {
                    remaining = remaining.sub(userVesting[user][i].amount);

                    // No sufficiency check required as sub() will throw anyways
                    userData[productId][user].totalSpentAmount = userData[productId][user].totalSpentAmount.sub(userVesting[user][i].amount);
                    productData[productId].totalTokenAmount = productData[productId].totalTokenAmount.sub(userVesting[user][i].amount);

                    delete userVesting[user][i];
                    userVestingInfo[user].firstVesting = userVestingInfo[user].firstVesting +1;
                } 
                else {
                    userVesting[user][i].amount = userVesting[user][i].amount.sub(remaining);

                    // No sufficiency check required as sub() will throw anyways
                    userData[productId][user].totalSpentAmount = userData[productId][user].totalSpentAmount.sub(remaining);
                    productData[productId].totalTokenAmount = productData[productId].totalTokenAmount.sub(remaining);

                    remaining = 0;
                }
                if (remaining == 0) {
                    break;
                }
            }
        }
        require(remaining == 0 , "MncNFTStore: not enough rebate amount");
        TransferHelper.safeTransfer(productInfos[productId].token, user, amount);

        emit Rebate(user, amount);
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

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMinersNFTs is IERC1155 {
    function lastTypeId() external view returns (uint256);
    function mintNFT(address _owner, uint256 _typeId, uint256 _amount) external; 
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

