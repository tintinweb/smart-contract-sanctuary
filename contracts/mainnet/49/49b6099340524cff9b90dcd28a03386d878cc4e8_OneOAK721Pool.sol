/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

/**
 *Submitted for verification at Etherscan.io on 2020-08-11
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-17
*/

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: YAMRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/


// File: @openzeppelin/contracts/math/Math.sol

pragma solidity ^0.5.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    
    
    function mint(address account, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.5.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/IRewardDistributionRecipient.sol

pragma solidity ^0.5.0;

interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`

    // Changed mutability to implicit non-payable
    // Changed visibility to public
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer

    // Changed mutability to implicit non-payable
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer

    // Changed mutability to implicit non-payable
    // Changed visibility to public
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve

    // Changed mutability to implicit non-payable
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your assets.
    /// @dev Throws unless `msg.sender` is the current NFT owner.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IOneOAKGovernance {
    function getGovernanceContract(uint256 _type) external view returns (address);
}

interface INFTGovernance {
    function getListingActiveDelay() external view returns (uint256);
    function getBuyBonusResidual() external view returns (uint256);
    function getMarketFee() external view returns (uint256);
    function getAbsoluteMinPrice() external view returns (uint256);
    function getMinPrice() external view returns (uint256);
    function getMaxPrice() external view returns (uint256);
    function getTokensForPrice(uint256 price) external view returns (uint256);
    function getApproved(uint256 _tokenId) external view returns (address);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function getNftAddress(uint256 _tokenId) external view returns (address);
}

contract IRewardDistributionRecipient is Ownable {
    event RewardDistributionChanged(address indexed rewardDistribution);

    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;

        emit RewardDistributionChanged(rewardDistribution);
    }
}

contract OneOAK721Pool is IRewardDistributionRecipient {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    IERC20 public rewardToken;
    IOneOAKGovernance public governanceContract;
    address public rewardsPoolAddress;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    // 90% locked for LOCKED_PERIOD length of time. vesting begins after LOCKUP_HURDLE length of time
    uint256 public constant DURATION      = 62500000; // ~723 days
    uint256 public constant LOCKUP_HURDLE = 31250000; // 365 days
    uint256 public constant LOCKUP_PERIOD = 31250000; // 365 days
    uint256 public constant LOCKUP_FACTOR = 10; // 10% ulocked immediately, 90% locked

    uint256 public starttime = 1616169600; // 2021-03-19 16:00:00 (UTC UTC +00:00)
    mapping(address => uint256) public unlockStart;

    uint256 public periodFinish = 0;
    mapping(address => uint256) public unlockEnd;

    uint256 public rewardRate = 0;
    mapping(address => uint256) public unlockedRewardRate;

    uint256 public lastUpdateTime;
    mapping(address => uint256) public lastUnlockedUpdateTime;

    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public unlockedRewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public userUnlockedRewardPerTokenPaid;

    mapping(address => uint256) public rewards; 
    mapping(address => uint256) public unlockedRewards;
    
    mapping(address => uint256) public penalties;

    mapping(address => uint256) public allTimeLockedRewards;
    
    mapping(address => mapping(uint256 => mapping(uint256 => Listing))) public listings;
    
    struct Listing { 
       uint256 blockNumber;
       uint256 price;
       uint256 tokenId;
       uint256 tokensStaked;
       address seller;
       bool active;
    }
    
    event RewardLocked(address indexed user, uint256 reward, uint256 start, uint256 end);
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event NftSold(address indexed seller, address buyer, uint256 nftType, uint256 nftId, uint256 price);

    constructor(address _oakTokenAddress, address _governanceContract, address _rewardsPoolAddress) public {
        rewardToken = IERC20(_oakTokenAddress);
        governanceContract = IOneOAKGovernance(_governanceContract);
        rewardsPoolAddress = _rewardsPoolAddress;
    }

    modifier checkStart() {
        require(block.timestamp >= starttime,"not start");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier updateUnlockedReward(address account) {
        unlockedRewardPerTokenStored[account] = unlockedRewardForAccount(account);
        lastUnlockedUpdateTime[account] = lastTimeUnlockedRewardApplicable(account);
        if (account != address(0)) {
            unlockedRewards[account] = unlockedEarned(account);
            userUnlockedRewardPerTokenPaid[account] = unlockedRewardPerTokenStored[account];
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }
    
    function lastTimeUnlockedRewardApplicable(address account) public view returns (uint256) {
        return Math.min(block.timestamp, unlockEnd[account]);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }    

    function unlockedRewardForAccount(address account) public view returns (uint256) {
        if (lastTimeUnlockedRewardApplicable(account) < lastUnlockedUpdateTime[account]) {
            return 0;
        } 
        return
            unlockedRewardPerTokenStored[account].add(
                lastTimeUnlockedRewardApplicable(account)
                    .sub(lastUnlockedUpdateTime[account])
                    .mul(unlockedRewardRate[account])
                    .mul(1e18)
            );
    }

    function earned(address account) public view returns (uint256) {
        if (penalties[account] >= balanceOf(account)) {
            return 0;
        } else {
            return
                (balanceOf(account).sub(penalties[account]))
                    .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                    .div(1e18)
                    .add(rewards[account]);
        }
    }

    function unlockedEarned(address account) public view returns (uint256) {
        if (block.timestamp <= unlockStart[account] 
            || penalties[account] >= unlockedRewardForAccount(account)
            || userUnlockedRewardPerTokenPaid[account] >= (unlockedRewardForAccount(account).sub(penalties[account]))
        ) {
            return 0;
        }
        return 
            (unlockedRewardForAccount(account).sub(penalties[account]))
                .sub(userUnlockedRewardPerTokenPaid[account])
                .div(1e18)
                .add(unlockedRewards[account]);
    }

    function addRewards(address account, uint256 amount) private updateReward(account) checkStart {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Staked(account, amount);
    }

    function removeRewards(address account, uint256 amount) private updateReward(account) checkStart {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        emit Withdrawn(account, amount);
    }

    function exit() external {
        removeRewards(msg.sender, balanceOf(msg.sender));
        getReward();
    }
        
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function getReward() public updateReward(msg.sender) checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            
            rewardToken.mint(address(this), reward);

            // unlock 10% immediately
            uint256 availableReward = reward.div(LOCKUP_FACTOR);
            uint256 lockedReward = reward.sub(availableReward);
    
            // lock remaining 90% for 1 year
            // tokens vest continuously the course of 1 year

            updateLockedAmount(msg.sender, lockedReward);
            
            rewardToken.safeTransfer(msg.sender, availableReward);
            emit RewardPaid(msg.sender, availableReward);
        }
    }

    function getUnlockedReward() public updateUnlockedReward(msg.sender) checkStart {
        uint256 reward = unlockedEarned(msg.sender);
        if (reward > 0) {
            unlockedRewards[msg.sender] = 0;
            
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp > starttime) {
          if (block.timestamp >= periodFinish) {
              rewardRate = reward.div(DURATION);
          } else {
              uint256 remaining = periodFinish.sub(block.timestamp);
              uint256 leftover = remaining.mul(rewardRate);
              rewardRate = reward.add(leftover).div(DURATION);
          }
          lastUpdateTime = block.timestamp;
          periodFinish = block.timestamp.add(DURATION);
          emit RewardAdded(reward);
        } else {
          rewardRate = reward.div(DURATION);
          lastUpdateTime = starttime;
          periodFinish = starttime.add(DURATION);
          emit RewardAdded(reward);
        }
    }

    function updateLockedAmount(address account, uint256 reward)
        internal
    {   
        if (unlockStart[account] > 0) {
            uint256 remaining = unlockEnd[account].sub(block.timestamp);
            uint256 leftover = remaining.mul(unlockedRewardRate[account]);
            unlockedRewardRate[account] = reward.add(leftover).div(LOCKUP_PERIOD);

            if (block.timestamp >= unlockStart[account]) {
                unlockEnd[account] = block.timestamp.add(LOCKUP_PERIOD);
            }

            lastUnlockedUpdateTime[account] = block.timestamp;
        } else {
            unlockedRewardRate[account] = reward.div(LOCKUP_PERIOD);
            unlockStart[account] = block.timestamp.add(LOCKUP_HURDLE);
            unlockEnd[account] = unlockStart[account].add(LOCKUP_PERIOD);
            lastUnlockedUpdateTime[account] = unlockStart[account];
        }

        allTimeLockedRewards[account] = allTimeLockedRewards[account].add(reward);
        emit RewardLocked(account, reward, unlockStart[account], unlockEnd[account]);
    }

    function getOwner(uint256 _type, uint256 _tokenId) public view returns (address) {
        address _governanceContract = governanceContract.getGovernanceContract(_type);
        return INFTGovernance(_governanceContract).ownerOf(_tokenId);
    }
        
    function getApproved(uint256 _type, uint256 _tokenId) public view returns (address) {
        address _governanceContract = governanceContract.getGovernanceContract(_type);
        return INFTGovernance(_governanceContract).getApproved(_tokenId);
    }
    
    function getMinPrice(uint _type) public view returns (uint256) {
        address _governanceContract = governanceContract.getGovernanceContract(_type);
        return INFTGovernance(_governanceContract).getMinPrice();
    }
    
    function getMaxPrice(uint _type) public view returns (uint256) {
        address _governanceContract = governanceContract.getGovernanceContract(_type);
        return INFTGovernance(_governanceContract).getMaxPrice();
    }
    
    function getBuyBonusResidual(uint _type) public view returns (uint256) {
        address _governanceContract = governanceContract.getGovernanceContract(_type);
        return INFTGovernance(_governanceContract).getBuyBonusResidual();
    }
    
    function getTokensForPrice(uint _type, uint price) public view returns (uint256) {
        address _governanceContract = governanceContract.getGovernanceContract(_type);
        return INFTGovernance(_governanceContract).getTokensForPrice(price);
    }
    
    function getMarketFee(uint _type) public view returns (uint256) {
        address _governanceContract = governanceContract.getGovernanceContract(_type);
        return INFTGovernance(_governanceContract).getMarketFee();
    }
    
    function getAbsoluteMinPrice(uint _type) public view returns (uint256) {
        address _governanceContract = governanceContract.getGovernanceContract(_type);
        return INFTGovernance(_governanceContract).getAbsoluteMinPrice();
    }

    function getListingActiveDelay(uint _type) public view returns (uint256) {
        address _governanceContract = governanceContract.getGovernanceContract(_type);
        return INFTGovernance(_governanceContract).getListingActiveDelay();
    }

    function list(uint _type, uint256 _tokenId, uint256 _price) public {
        address user = msg.sender;
        address owner = getOwner(_type, _tokenId);
        address approved = getApproved(_type, _tokenId);
        
        require(address(this) == approved, "Approval required");
        require(user == owner, "Owner required");
        require(_price >= getAbsoluteMinPrice(_type), "Price too low");

        Listing storage previousListing = listings[owner][_type][_tokenId];
        if (previousListing.active) {
            uint256 tokensStaked = previousListing.tokensStaked;
            if (tokensStaked > 0) { 
                removeRewards(user, tokensStaked);
            }
        }
        
        uint256 tokensForPrice = getTokensForPrice(_type, _price);

        Listing memory listing = Listing({
            blockNumber: block.number,
            price: _price, 
            tokenId: _tokenId, 
            seller: user,
            tokensStaked: tokensForPrice,
            active: true
        });
        listings[user][_type][_tokenId] = listing;
        
        if (tokensForPrice > 0) {
            addRewards(user, tokensForPrice);
            emit Staked(user, tokensForPrice);
        }
    }
    
    function cancel(uint256 _type, uint256 _tokenId) external {
        address user = msg.sender;
        Listing storage listing = listings[user][_type][_tokenId];
        listing.active = false;
        
        uint256 tokensStaked = listing.tokensStaked;
        if (tokensStaked > 0) {
            removeRewards(user, tokensStaked);
        }
    }
    
    function staleListing(uint256 _type, address _owner, uint256 _tokenId) external payable {
        Listing storage listing = listings[_owner][_type][_tokenId];
        address seller = listing.seller;
        
        uint256 listingDelay = getListingActiveDelay(_type);
        require(block.number.sub(listing.blockNumber) > listingDelay, "Listing will be availale in a few blocks");
        require(listing.active, "Listing not active");
        require(listing.price > 0, "Listing not found");
        
        address approved = getApproved(_type, _tokenId);
        address owner = getOwner(_type, _tokenId);
        
        if ((owner != seller || address(this) != approved)) {
            listing.active = false;
            addPenalty(seller, listing.tokensStaked);
        } else {
            revert("Listing is OK");
        }
    }
    
    function addPenalty(address owner, uint256 tokensStaked) internal {
        penalties[owner] = penalties[owner].add(tokensStaked);
    }

    function purchase(uint256 _type, address _owner, uint256 _tokenId) external updateReward(_owner) payable {
        address buyer = msg.sender;

        Listing storage listing = listings[_owner][_type][_tokenId];
        address seller = listing.seller;
        uint256 price = listing.price;
        
        address owner = getOwner(_type, _tokenId);
        address approved = getApproved(_type, _tokenId);
        uint256 listingDelay = getListingActiveDelay(_type);

        require(price > 0, "Listing not found");
        require(listing.active, "Listing not active");
        require(owner == seller, "Seller must own the item");
        require(approved == address(this), "Approve required");
        require(block.number.sub(listing.blockNumber) > listingDelay, "Listing pending");
        require(msg.value >= listing.price, "ETH payed below listed price");
        
        listing.active = false;
        
        if (getBuyBonusResidual(_type) > 0) {
            uint256 residual = listing.tokensStaked.div(getBuyBonusResidual(_type));
            uint256 realizedRewards = listing.tokensStaked.sub(residual);

            if (realizedRewards > 0) {
                removeRewards(seller, realizedRewards);
            }
        } else {
            if (listing.tokensStaked > 0) {
                removeRewards(seller, listing.tokensStaked);
            }
        }

        transferNft(seller, buyer, _type, _tokenId);
        
        if (getMarketFee(_type) > 0) {
            uint256 taxes = price.div(getMarketFee(_type));
            uint256 taxedPrice = price.sub(taxes);
            
            address payable payableSeller = address(uint160(seller));
            payableSeller.send(taxedPrice);
            
            address payable payableRewardsPool = address(uint160(rewardsPoolAddress));
            if (!payableRewardsPool.send(taxes)) {
                revert("Error paying RewardsPool");
            }
            IRewardDistributionRecipient(rewardsPoolAddress).notifyRewardAmount(taxes);
        } else {
            address payable payableSeller = address(uint160(seller));
            payableSeller.send(price);
        }
        
        emit NftSold(seller, buyer, _type, _tokenId, price);
    }
    
    function transferNft(address from, address to, uint256 _type, uint256 _tokenId) internal {
        ERC721 nftToken = ERC721(INFTGovernance(governanceContract.getGovernanceContract(_type)).getNftAddress(_tokenId));
        nftToken.safeTransferFrom(from, to, _tokenId);
    }

    function getListing(address _owner, uint256 _type, uint256 _tokenId) public view returns (uint256, uint256, address, uint256, bool) {
        Listing storage listing = listings[_owner][_type][_tokenId];
        uint256 price = listing.price;
        uint256 tokenId = listing.tokenId;
        address seller = listing.seller;
        uint256 tokensStaked = listing.tokensStaked;
        bool active = listing.active;

        return (
            price,
            tokenId,
            seller,
            tokensStaked,
            active
        );
    }

}