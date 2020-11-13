// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

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
contract Ownable is Context {
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
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/CrowdFund.sol

pragma solidity 0.6.12;






contract CrowdFund is Ownable {
    using SafeMath for uint256;
    IERC20 public yfethToken;
    mapping(address => bool) public isClaimed;
    mapping(address => uint256) public ethContributed;
    mapping(address => uint256) public refferer_earnings;

    address constant ETH_TOKEN_PLACHOLDER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public immutable startTime;
    uint256 public immutable endTime;
    uint256 public constant referralRewardAmount = 500 finney; //0.5 yfeth
    uint256 public constant claimRewardAmount = 3 ether;
    uint256 public yfePerWei = 150;
    uint256 public totalEthContributed;

    uint256[] public canClaimIfHasThisMuchTokens;
    address[] public canClaimIfHasTokens;

    event TokenWithdrawn(
        address indexed token,
        uint256 indexed amount,
        address indexed dest
    );
    event EthContributed(
        address indexed contributor,
        uint256 indexed amount,
        uint256 indexed yfeReceived
    );

    constructor(
        IERC20 _yfethToken,
        uint256 _startTime,
        uint256 _endTime,
        address[] memory _canClaimIfHasTokens,
        uint256[] memory _canClaimIfHasThisMuchTokens
    ) public {
        _updateClaimCondtions(
            _canClaimIfHasTokens,
            _canClaimIfHasThisMuchTokens
        );
        yfethToken = _yfethToken;
        endTime = _endTime;
        startTime = _startTime;
    }

    function claim() external {
        if (
            !(isClaimed[msg.sender] ||
                now < startTime ||
                yfePerWei == 0 ||
                now >= endTime)
        ) {
            if (canClaim(msg.sender)) {
                require(yfethToken.transfer(msg.sender, claimRewardAmount));
                isClaimed[msg.sender] = true;
            }
        }
    }

    function canClaim(address _who) public view returns (bool) {
        for (uint8 i = 0; i < canClaimIfHasTokens.length; i++) {
            if (
                IERC20(canClaimIfHasTokens[i]).balanceOf(_who) >=
                canClaimIfHasThisMuchTokens[i]
            ) {
                return true;
            }
        }
        return false;
    }

    function _updateClaimCondtions(
        address[] memory _canClaimIfHasTokens,
        uint256[] memory _canClaimIfHasThisMuchTokens
    ) internal {
        require(
            _canClaimIfHasTokens.length == _canClaimIfHasThisMuchTokens.length,
            "CrowdFund: Invalid Input"
        );
        canClaimIfHasTokens = _canClaimIfHasTokens;
        canClaimIfHasThisMuchTokens = _canClaimIfHasThisMuchTokens;
    }

    function updateClaimCondtions(
        address[] memory _canClaimIfHasTokens,
        uint256[] memory _canClaimIfHasThisMuchTokens
    ) public onlyOwner {
        _updateClaimCondtions(
            _canClaimIfHasTokens,
            _canClaimIfHasThisMuchTokens
        );
    }

    function contribute(address _referrer) external payable {
        //If you are early you just get your eth back
        if (now < startTime || yfePerWei == 0 || now >= endTime) {
            msg.sender.transfer(msg.value);
        } else {
            totalEthContributed = totalEthContributed.add(msg.value);
            ethContributed[msg.sender] = ethContributed[msg.sender].add(
                msg.value
            );

            require(ethContributed[msg.sender] <= 20 ether, "Limit reached");

            uint256 yfeToTransfer = yfePerWei.mul(msg.value);

            //transfer 0.5 yfe to the _referrer
            //transfer yfeToTransfer to the msg.sender
            emit EthContributed(msg.sender, msg.value, yfeToTransfer);
            require(yfethToken.transfer(msg.sender, yfeToTransfer));
            //limit for refferer to earn maximum of 20 yfe tokens
            if (
                _referrer != address(0) &&
                refferer_earnings[_referrer] <= 20 ether &&
                _referrer != msg.sender
            ) {
                refferer_earnings[_referrer] = refferer_earnings[_referrer].add(
                    referralRewardAmount
                );
                require(yfethToken.transfer(_referrer, referralRewardAmount));
            }

            if (totalEthContributed > 375 ether && yfePerWei == 75) {
                yfePerWei = 0;
            } else if (totalEthContributed > 175 ether && yfePerWei == 100) {
                yfePerWei = 75;
            } else if (totalEthContributed > 56 ether && yfePerWei == 150) {
                yfePerWei = 100;
            }
        }
    }

    /**
     * @notice Transfers all tokens of the input adress to the recipient. This is
     * useful tokens are accidentally sent to this contrasct
     * @param _tokenAddress address of token to send
     * @param _dest destination address to send tokens to
     */
    function withdrawToken(address _tokenAddress, address _dest)
        external
        onlyOwner
    {
        uint256 _balance = IERC20(_tokenAddress).balanceOf(address(this));
        emit TokenWithdrawn(_tokenAddress, _balance, _dest);
        require(IERC20(_tokenAddress).transfer(_dest, _balance));
    }

    /**
     * @notice Transfers all Ether to the specified address
     * @param _dest destination address to send ETH to
     */
    function withdrawEther(address payable _dest) external onlyOwner {
        uint256 _balance = address(this).balance;
        emit TokenWithdrawn(ETH_TOKEN_PLACHOLDER, _balance, _dest);
        _dest.transfer(_balance);
    }
}