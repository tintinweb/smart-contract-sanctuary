// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBEP20 {
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

// SPDX-License-Identifier: MIT
/*
6 triệu token, TGE unlock 20%, 80% trả dần trong 6 tháng
min 5k$ max 20k$ ....Giá 0.05$
*/
pragma solidity 0.8.6;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./SafeMath.sol";

contract MATPrivateSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    IBEP20 public MAT;
    IBEP20 public BUSD;

    uint256 public min;
    uint256 public max;
    uint256 public tgeClaimPercentage; //2decimal
    uint256 public price; //3 decimal

    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalLock;
    uint256 public totalReleased;

    address coldWallet;

    mapping(address => bool) public whilelists;
    mapping(address => uint256) private boughts; //BUSD
    mapping(address => uint256) private locks; // MAT
    mapping(address => uint256) private released; // MAT

    uint256 totalUsers;
    uint256 totalFunds;

    event Buy(
        address indexed from,
        uint256 amount,
        uint256 matAmount,
        uint256 time
    );
    event Claim(address indexed account, uint256 amount, uint256 time);
    uint8 public stage;

    // _mat = 0x73e9f666ca55cdc89a9dd734c7f31f3fbc8bc197
    constructor(
        IBEP20 _mat,
        IBEP20 _busd,
        uint256 _min,
        uint256 _max,
        uint256 _tgeClaimPercentage,
        uint256 _price,
        address _coldWallet
    ) {
        MAT = IBEP20(_mat);
        BUSD = IBEP20(_busd);
        stage = 0;
        min = _min;
        max = _max;
        tgeClaimPercentage = _tgeClaimPercentage;
        price = _price;
        coldWallet = _coldWallet;
    }

    modifier canBuy() {
        require(stage == 1, "Can not buy now");
        _;
    }

    modifier canClaim() {
        require(stage == 2, "Can not claim now");
        _;
    }

    function changeStage(uint8 _stage) public onlyOwner {
        stage = _stage;
    }

    function buy(uint256 _amount) public onlyWhilelist canBuy nonReentrant {
        require(_amount >= min, "Amount too small");
        // require(_amount <= max, "Input invalid");
        require(boughts[_msgSender()] + _amount <= max, "Exceed max");

        //calculate
        uint256 matAmount = (_amount * 1000) / price;

        require(MAT.balanceOf(address(this)) >= matAmount, "MAT insufficient");

        //transfer BUSD
        require(
            BUSD.transferFrom(_msgSender(), coldWallet, _amount),
            "BUSD transfer fail"
        );

        boughts[_msgSender()] += _amount;
        locks[_msgSender()] += matAmount;
        totalLock += matAmount;
        totalFunds += _amount;
        if (boughts[_msgSender()] != 0) {
            totalUsers += 1;
        }
        emit Buy(_msgSender(), _amount, matAmount, block.timestamp);
    }

    function claim() external canClaim nonReentrant {
        require(block.timestamp > startTime, "still locked");
        require(locks[_msgSender()] > released[_msgSender()], "no locked");

        uint256 amount = canUnlockAmount(_msgSender());
        require(amount > 0, "Nothing to claim");

        released[_msgSender()] += amount;

        MAT.transfer(_msgSender(), amount);

        totalLock -= amount;
        totalReleased += amount;

        emit Claim(_msgSender(), amount, block.timestamp);
    }

    function canUnlockAmount(address _account) public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0;
        } else if (block.timestamp >= endTime) {
            return locks[_account] - released[_account];
        } else {
            uint256 releasedTime = releasedTimes();
            uint256 totalVestingTime = endTime - startTime;
            uint256 tgeUnlock = (locks[_account] * tgeClaimPercentage) / 100;
            return
                tgeUnlock +
                (((locks[_account] - tgeUnlock) * releasedTime) /
                    totalVestingTime) -
                released[_account];
        }
    }

    function releasedTimes() public view returns (uint256) {
        uint256 targetNow = (block.timestamp >= endTime)
            ? endTime
            : block.timestamp;
        uint256 releasedTime = targetNow - startTime;
        return releasedTime;
    }

    /*For FE
    0: MAT address
    1: BUSD address
    2: stage
        0: PENDING
        1: BUY
        2: CLAIM
        3: CLOSE
    3: min 10^18
    4: max 10^18
    5: price (3 decimal)
    6: start time
    7: end time
    8: total users 
    9: total funds 10^18
    10: cap 
    */
    function info()
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            address(MAT),
            address(BUSD),
            stage,
            min,
            max,
            price,
            startTime,
            endTime,
            totalLock,
            totalReleased,
            totalUsers,
            totalFunds
        );
    }

    //For FE
    function infoWallet(address _user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (boughts[_user], locks[_user], released[_user]);
    }

    modifier onlyWhilelist() {
        require(whilelists[_msgSender()], "Not in whilelist");
        _;
    }

    function setWhilelist(
        address[] calldata _users,
        bool[] calldata _isWhilelists
    ) public onlyOwner {
        require(_users.length == _isWhilelists.length, "Input invalid");
        for (uint256 i = 0; i < _users.length; i++) {
            whilelists[_users[i]] = _isWhilelists[i];
        }
    }

    function setMin(uint256 _min) public onlyOwner {
        min = _min;
    }

    function setMax(uint256 _max) public onlyOwner {
        max = _max;
    }

    function setTime(uint256 _startTime, uint256 _endTime) public onlyOwner {
        startTime = _startTime;
        require(_startTime > block.timestamp, "TokenLocker: late");
        require(_endTime > _startTime, "TokenLocker: invalid _endTime");
        startTime = _startTime;
        endTime = _endTime;
    }

    function settgeClaimPercentage(uint256 _tgeClaimPercentage)
        public
        onlyOwner
    {
        tgeClaimPercentage = _tgeClaimPercentage;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setColdWallet(address _coldWallet) public onlyOwner {
        coldWallet = _coldWallet;
    }

    /* ========== EMERGENCY ========== */
    function governanceRecoverUnsupported(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(
            _token != address(MAT) ||
                MAT.balanceOf(address(this)) - _amount >= totalLock,
            "Not enough locked amount left"
        );
        IBEP20(_token).transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library SafeMath {

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

