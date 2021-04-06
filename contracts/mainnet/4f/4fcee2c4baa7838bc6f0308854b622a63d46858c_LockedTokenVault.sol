/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}


library DecimalMath {
    using SafeMath for uint256;

    uint256 constant ONE = 10**18;

    function mul(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d) / ONE;
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(d).divCeil(ONE);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).div(d);
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return target.mul(ONE).divCeil(d);
    }
}


contract Ownable {
    address public _OWNER_;
    address public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() internal {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}


interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}


library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract LockedTokenVault is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address _TOKEN_;

    mapping(address => uint256) internal originBalances;
    mapping(address => uint256) internal claimedBalances;
    mapping(address => uint256) internal startReleaseTime;
    mapping(address => uint256) internal releaseDuration;

    uint256 public _UNDISTRIBUTED_AMOUNT_;

    // ============ Events ============

    event Claim(address indexed holder, uint256 origin, uint256 claimed, uint256 amount);

    // ============ Init Functions ============

    constructor(
        address _token
    ) public {
        _TOKEN_ = _token;
    }

    function deposit(uint256 amount) external onlyOwner {
        _tokenTransferIn(_OWNER_, amount);
        _UNDISTRIBUTED_AMOUNT_ = _UNDISTRIBUTED_AMOUNT_.add(amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        _UNDISTRIBUTED_AMOUNT_ = _UNDISTRIBUTED_AMOUNT_.sub(amount);
        _tokenTransferOut(_OWNER_, amount);
    }

    // ============ For Owner ============

    function grant(address[] calldata holderList, uint256[] calldata amountList, uint256[] calldata startList, uint256[] calldata durationList)
    external
    onlyOwner
    {
        require(holderList.length == amountList.length, "batch grant length not match");
        require(holderList.length == startList.length, "batch grant length not match");
        require(holderList.length == durationList.length, "batch grant length not match");
        uint256 amount = 0;
        for (uint256 i = 0; i < holderList.length; ++i) {
            originBalances[holderList[i]] = originBalances[holderList[i]].add(amountList[i]);
            startReleaseTime[holderList[i]] = startList[i];
            releaseDuration[holderList[i]] = durationList[i];
            amount = amount.add(amountList[i]);
        }
        _UNDISTRIBUTED_AMOUNT_ = _UNDISTRIBUTED_AMOUNT_.sub(amount);
    }

    function recall(address holder) external onlyOwner {
        _UNDISTRIBUTED_AMOUNT_ = _UNDISTRIBUTED_AMOUNT_.add(originBalances[holder]).sub(
            claimedBalances[holder]
        );
        originBalances[holder] = 0;
        claimedBalances[holder] = 0;
        startReleaseTime[holder] = 0;
        releaseDuration[holder] = 0;
    }

    // ============ For Holder ============

    function claim() external {
        uint256 claimableToken = getClaimableBalance(msg.sender);
        _tokenTransferOut(msg.sender, claimableToken);
        claimedBalances[msg.sender] = claimedBalances[msg.sender].add(claimableToken);
        emit Claim(
            msg.sender,
            originBalances[msg.sender],
            claimedBalances[msg.sender],
            claimableToken
        );
    }

    // ============ View ============

    function isReleaseStart(address holder) external view returns (bool) {
        return block.timestamp >= startReleaseTime[holder];
    }

    function getStartReleaseTime(address holder) external view returns (uint256) {
        return startReleaseTime[holder];
    }

    function getReleaseDuration(address holder) external view returns (uint256) {
        return releaseDuration[holder];
    }

    function getOriginBalance(address holder) external view returns (uint256) {
        return originBalances[holder];
    }

    function getClaimedBalance(address holder) external view returns (uint256) {
        return claimedBalances[holder];
    }

    function getClaimableBalance(address holder) public view returns (uint256) {
        uint256 remainingToken = getRemainingBalance(holder);
        return originBalances[holder].sub(remainingToken).sub(claimedBalances[holder]);
    }

    function getRemainingBalance(address holder) public view returns (uint256) {
        uint256 remainingRatio = getRemainingRatio(block.timestamp, holder);
        return DecimalMath.mul(originBalances[holder], remainingRatio);
    }

    function getRemainingRatio(uint256 timestamp, address holder) public view returns (uint256) {
        if (timestamp < startReleaseTime[holder]) {
            return DecimalMath.ONE;
        }
        uint256 timePast = timestamp.sub(startReleaseTime[holder]);
        if (timePast < releaseDuration[holder]) {
            uint256 remainingTime = releaseDuration[holder].sub(timePast);
            return DecimalMath.ONE.mul(remainingTime).div(releaseDuration[holder]);
        } else {
            return 0;
        }
    }

    // ============ Internal Helper ============

    function _tokenTransferIn(address from, uint256 amount) internal {
        IERC20(_TOKEN_).safeTransferFrom(from, address(this), amount);
    }

    function _tokenTransferOut(address to, uint256 amount) internal {
        IERC20(_TOKEN_).safeTransfer(to, amount);
    }
}