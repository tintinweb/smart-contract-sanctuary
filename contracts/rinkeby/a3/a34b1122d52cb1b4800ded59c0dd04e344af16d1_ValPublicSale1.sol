/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

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
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

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
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/ValPublicSale1.sol

pragma solidity 0.6.12;

contract ValPublicSale1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TokenLock {
        uint256 timestamp;
        uint256 amount;
        bool isUnlocked;
    }

    struct User {
        uint256 alloc;
        uint256 bought;
        uint256 locked;
        TokenLock[] releases;
    }

    mapping(address => User) public whitelist;

    IERC20 public rdao;
    IERC20 public busd;

    uint256 public totalSold;
    uint256 public totalLocked;
    uint256 public totalUnlocked;
    uint256 public saleStart;
    uint256 public saleStop;

    address payable public tokenOwner;

    uint256 public bnbPegged; //in usd: i.e. 1150, 1200

    uint256 public constant MAX_SALE_DURATION = 2 days;

    event addedToWhitelist(address[] account);
    event removedFromWhitelist(address[] account);

    constructor(
        uint256 _start,
        uint256 _duration,
        uint256 _bnbPegged,
        address _rdao
    ) public {
        saleStart = _start == 0 ? block.timestamp : _start; // put _start 1618585200 for Fri Apr 16 2021 15:00:00 GMT+0000
        require(saleStart >= block.timestamp);
        require(_duration <= MAX_SALE_DURATION); // put _duration 86400 for 1 day
        saleStop = saleStart.add(_duration);

        bnbPegged = _bnbPegged;
        busd = IERC20(_rdao);
        rdao = IERC20(_rdao);
        tokenOwner = msg.sender;
    }

    function setTokenOwner(address payable _tokenOwner) external onlyOwner {
        tokenOwner = _tokenOwner;
    }

    function setPegged(uint256 _bnbPegged)
        external
        onlyOwner
    {
        bnbPegged = _bnbPegged;
    }

    function setSaleTime(uint256 _start, uint256 _duration) external onlyOwner {
        if (saleStart == 0) saleStart = _start;
        require(_duration < MAX_SALE_DURATION);
        saleStop = saleStart.add(_duration);
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function setRdao(address _rdao) external onlyOwner {
        rdao = IERC20(_rdao);
    }

    function add(address[] memory _addresses, uint256[] memory _allocations)
        external
        onlyOwner
    {
        require(_addresses.length == _allocations.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            setAllocation(_addresses[i], _allocations[i]);
        }
        emit addedToWhitelist(_addresses);
    }

    function setAllocation(address _addr, uint256 alloc) public onlyOwner {
        whitelist[_addr].alloc = alloc;
    }

    function remove(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i > _addresses.length; i++) {
            whitelist[_addresses[i]].alloc = 0;
        }
        emit removedFromWhitelist(_addresses);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return whitelist[_address].alloc > 0;
    }

    function withdrawToken(address _token) external onlyOwner {
        if (_token == address(rdao)) {
            //withdraw remaining, unsold rdao
            require(block.timestamp > saleStop);
            uint256 bal = rdao.balanceOf(address(this));
            rdao.transfer(tokenOwner, bal.sub(totalLocked));
        } else if (_token == address(0)) {
            tokenOwner.transfer(address(this).balance);
        } else {
            IERC20 t = IERC20(_token);
            uint256 bal = t.balanceOf(address(this));
            t.safeTransfer(tokenOwner, bal);
        }
    }

    fallback() external payable {
        buyTokenWithBNB();
    }

    receive() external payable {
        buyTokenWithBNB();
    }

    function lockRdao(address _user) internal {
        uint256 lockedAmount = whitelist[_user].locked;
        delete whitelist[_user].releases; //clear old data
        whitelist[_user].releases.push(
            TokenLock({
                timestamp: saleStart.add(32 days),
                amount: lockedAmount.mul(10).div(100),
                isUnlocked: false
            })
        );
        whitelist[_user].releases.push(
            TokenLock({
                timestamp: saleStart.add(62 days),
                amount: lockedAmount.mul(10).div(100),
                isUnlocked: false
            })
        );
        whitelist[_user].releases.push(
            TokenLock({
                timestamp: saleStart.add(122 days),
                amount: lockedAmount.mul(10).div(100),
                isUnlocked: false
            })
        );
        whitelist[_user].releases.push(
            TokenLock({
                timestamp: saleStart.add(152 days),
                amount: lockedAmount.mul(10).div(100),
                isUnlocked: false
            })
        );
        whitelist[_user].releases.push(
            TokenLock({
                timestamp: saleStart.add(182 days),
                amount: lockedAmount.mul(10).div(100),
                isUnlocked: false
            })
        );
    }

    function buyTokenWithBNB() public payable onlyWhitelisted {
        require(
            block.timestamp >= saleStart && block.timestamp <= saleStop,
            "invalid time"
        );
        uint256 tokenAmount = msg.value.mul(bnbPegged).div(11);
        uint256 bnbReturn = 0;
        if (
            whitelist[msg.sender].bought.add(tokenAmount) >
            whitelist[msg.sender].alloc
        ) {
            tokenAmount = whitelist[msg.sender].alloc.sub(
                whitelist[msg.sender].bought
            );
            uint256 actualBNBSpentInWei = tokenAmount.mul(11).div(bnbPegged);
            bnbReturn = msg.value.sub(actualBNBSpentInWei);
        }
        if (tokenAmount > 0) {
            //send 50%, locked 50%
            uint256 toSend = tokenAmount.div(2);
            uint256 locked = tokenAmount.sub(toSend);
            rdao.safeTransfer(msg.sender, toSend);
            whitelist[msg.sender].bought = whitelist[msg.sender].bought.add(
                tokenAmount
            );
            whitelist[msg.sender].locked = whitelist[msg.sender].locked.add(
                locked
            );
            totalSold = totalSold.add(tokenAmount);
            totalLocked = totalLocked.add(locked);
            lockRdao(msg.sender);
        }

        if (bnbReturn > 0) {
            msg.sender.transfer(bnbReturn); //revert if fallback of msg.sender has heavy opertions
        }
    }

    function buyTokenWithBUSD(uint256 _busdAmount) external onlyWhitelisted {
        require(
            block.timestamp >= saleStart && block.timestamp <= saleStop,
            "invalid time"
        );
        uint256 busdBefore = busd.balanceOf(address(this));
        busd.safeTransferFrom(msg.sender, address(this), _busdAmount);
        uint256 busdReceive = busd.balanceOf(address(this)).sub(busdBefore);
        uint256 tokenAmount = busdReceive.div(11);
        uint256 busdReturn = 0;
        if (
            whitelist[msg.sender].bought.add(tokenAmount) >
            whitelist[msg.sender].alloc
        ) {
            tokenAmount = whitelist[msg.sender].alloc.sub(
                whitelist[msg.sender].bought
            );
            uint256 actualBUSDSpentInWei = tokenAmount.mul(11);
            busdReturn = busdReceive.sub(actualBUSDSpentInWei);
        }
        
        if (tokenAmount > 0) {
            //send 50%, locked 50%
            uint256 toSend = tokenAmount.div(2);
            uint256 locked = tokenAmount.sub(toSend);
            rdao.safeTransfer(msg.sender, toSend);
            whitelist[msg.sender].bought = whitelist[msg.sender].bought.add(
                tokenAmount
            );
            whitelist[msg.sender].locked = whitelist[msg.sender].locked.add(
                locked
            );
            totalSold = totalSold.add(tokenAmount);
            totalLocked = totalLocked.add(locked);
            lockRdao(msg.sender);
        }

        if (busdReturn > 0) {
            busd.safeTransfer(msg.sender, busdReturn); //revert if fallback of msg.sender has heavy opertions
        }
    }

    function withdrawLockedToken() external {
        require(whitelist[msg.sender].locked > 0);
        User storage user = whitelist[msg.sender];
        uint256 totalRelease = 0;
        for (uint256 i = 0; i < user.releases.length; i++) {
            if (
                !user.releases[i].isUnlocked &&
                user.releases[i].timestamp < block.timestamp
                ) {
                totalRelease = totalRelease.add(user.releases[i].amount);
                user.releases[i].isUnlocked = true;
            }
        }
        if (totalRelease > 0) {
            rdao.safeTransfer(msg.sender, totalRelease);
            totalUnlocked = totalUnlocked.add(totalRelease);
        }
    }
}