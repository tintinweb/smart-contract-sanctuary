/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

/**
 *SPDX-License-Identifier: MIT
*/

// File: @openzeppelin/contracts/GSN/Context.sol

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
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}



interface IMasterchef {
    function updatePendingRewards() external;

    function depositFor(
        address _depositFor,
        uint256 _pid,
        uint256 _amount
    ) external;

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256,
            uint256,
            uint256
        );
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

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

// File: contracts/ISAPE.sol



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ISAPE is IERC20 {
    function devFundAddress() external view returns (address);

    function farmingFeeDistributor() external view returns (address);

    function pullFarmingReward() external;

    function computeFarmingReward() external view returns (uint256);
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.6.0 <0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
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

// File: contracts/SAPE.sol


contract Slim is Context, Ownable, ISAPE {
    using SafeMath for uint256;
    using Address for address;

    struct LockedToken {
        bool isUnlocked;
        uint256 unlockedTime;
        uint256 amount;
    }

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public constant MAX_SUPPLY = 90000000e18;

    uint256 public PRESALE_SALE = 36000000e18; //10%
    uint256 public LIQUIDITY = 4500000e18;
    uint256 public TEAM = 9000000e18;
    uint256 public MARKETING = 4500000e18;
    uint256 public COVER_REWARDS = 18000000e18;
    uint256 public FARMING_REWARDS = 18000000e18;

    address public override farmingFeeDistributor;
    address public stakingDistributor;
    uint256 public stakingPercent = 0;

    uint256 public farmingRate = 5e18;

    address public coverReward;

    uint256 public contractStartTimestamp;

    address public override devFundAddress;
    uint256 public farmingRewardsCount = 0;
    uint256 public coverRewardsCount = 0;
    uint256 public lastRewardBlock = 0;
    uint256 public startFarmingReward = 0;

    LockedToken[] public devFunds;

    function name() public view returns (string memory) {
        return _name;
    }

    constructor() {
        initialSetup(owner());
    }

    function initialSetup(address _dev) internal {
        _name = "FutureSwap.US";
        _symbol = "FTC";
        _decimals = 18;
        uint256 initialMint = MAX_SUPPLY;

        devFundAddress = _dev;

        _mint(address(this), initialMint);
        _editNoFeeList(address(this), true);
        _transfer(
            address(this),
            devFundAddress,
            PRESALE_SALE.add(LIQUIDITY).add(MARKETING)
        );
        contractStartTimestamp = block.timestamp;
        {
            //dev fund locked 6 months, then release every month
            uint256 devFundPerRelease = TEAM.div(10);
            for (uint256 i = 0; i < 9; i++) {
                devFunds.push(
                    LockedToken({
                        unlockedTime: block.timestamp +
                            6 *
                            30 *
                            86400 +
                            i.mul(30 days),
                        amount: devFundPerRelease,
                        isUnlocked: false
                    })
                );
            }
            devFunds.push(
                LockedToken({
                    unlockedTime: block.timestamp +
                        6 *
                        30 *
                        86400 +
                        uint256(9).mul(30 days),
                    amount: TEAM.sub(devFundPerRelease.mul(9)),
                    isUnlocked: false
                })
            );
        }
    }

    function pendingReleasableDevFund() public view returns (uint256) {
        if (contractStartTimestamp == 0) return 0;
        uint256 ret = 0;
        for (uint256 i = 0; i < devFunds.length; i++) {
            if (devFunds[i].unlockedTime > block.timestamp) break;
            if (!devFunds[i].isUnlocked) {
                ret = ret.add(devFunds[i].amount);
            }
        }
        return ret;
    }

    function unlockDevFund() public {
        for (uint256 i = 0; i < devFunds.length; i++) {
            if (devFunds[i].unlockedTime >= block.timestamp) break;
            if (!devFunds[i].isUnlocked) {
                devFunds[i].isUnlocked = true;
                _transfer(address(this), devFundAddress, devFunds[i].amount);
            }
        }
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public override view returns (uint256) {
        return _balances[_owner];
    }

    function setDevFundReciever(address _devaddr) public {
        require(devFundAddress == msg.sender, "only dev can change");
        devFundAddress = _devaddr;
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function setFeeDistributor(address _feeDistributor) public onlyOwner {
        require(
            farmingFeeDistributor == address(0) &&
                _feeDistributor != address(0),
            "farming already set"
        );
        farmingFeeDistributor = _feeDistributor;
        lastRewardBlock = block.number.sub(1);
        startFarmingReward = block.number;
    }

    function setStakingDistributor(address _stakingDistributor)
        public
        onlyOwner
    {
        require(
            stakingDistributor == address(0) &&
                _stakingDistributor != address(0),
            "staking already set"
        );
        stakingDistributor = _stakingDistributor;
    }

    function setStakingPercent(uint256 _percent) public onlyOwner {
        require(_percent <= 20);
        stakingPercent = _percent;
    }

    function pullFarmingReward() public override {
        require(msg.sender == farmingFeeDistributor);
        uint256 _farmReward = computeFarmingReward();
        uint256 _total = _farmReward;
        if (stakingDistributor != address(0) && stakingPercent > 0) {
            uint256 farmPercent = 100 - stakingPercent;
            _total = _total.mul(100).div(farmPercent);
        }
        uint256 staking = _total.sub(_farmReward);
        if (farmingRewardsCount.add(_total) > FARMING_REWARDS) {
            _total = FARMING_REWARDS.sub(farmingRewardsCount);
            staking = _total.mul(stakingPercent).div(100);
            _farmReward = _total.sub(staking);
        }
        farmingRewardsCount = farmingRewardsCount.add(_total);
        _transfer(address(this), msg.sender, _farmReward);
        if (staking > 0) {
            _transfer(address(this), stakingDistributor, staking);
            IMasterchef(stakingDistributor).updatePendingRewards();
        }
        lastRewardBlock = block.number;
    }

    function computeFarmingReward() public override view returns (uint256) {
        if (farmingFeeDistributor == address(0)) return 0;
        if (block.number <= lastRewardBlock) return 0;
        if (block.number < startFarmingReward) return 0;
        uint256 ret = 0;
        if (block.number <= startFarmingReward.add(50000)) {
            ret = block.number.sub(lastRewardBlock).mul(farmingRate).mul(3);
        } else if (lastRewardBlock < startFarmingReward.add(50000)) {
            uint256 reward1 = startFarmingReward
                .add(50000)
                .sub(lastRewardBlock)
                .mul(farmingRate)
                .mul(3);
            uint256 reward2 = block
                .number
                .sub(startFarmingReward.add(50000))
                .mul(farmingRate);
            ret = reward1.add(reward2);
        } else {
            ret = block.number.sub(lastRewardBlock).mul(farmingRate);
        }
        if (stakingDistributor != address(0) && stakingPercent > 0) {
            uint256 staking = ret.mul(stakingPercent).div(100);
            ret = ret.sub(staking);
        }
        return ret;
    }

    function setCoverReward(address _coverReward) public onlyOwner {
        //cover rewards start 3 months after farming
        require(
            block.timestamp > contractStartTimestamp.add(90 days),
            "cover rewards not start yet"
        );
        require(
            coverReward == address(0) && _coverReward != address(0),
            "cover reward already set"
        );

        coverReward = _coverReward;
    }

    function pullCoverReward(uint256 _amount) public {
        require(msg.sender == coverReward);
        if (coverRewardsCount.add(_amount) > COVER_REWARDS) {
            _amount = COVER_REWARDS.sub(coverRewardsCount);
        }
        coverRewardsCount = coverRewardsCount.add(_amount);
        _transfer(address(this), msg.sender, _amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );

        (
            uint256 transferToAmount,
            uint256 transferToFeeDistributorAmount
        ) = calculateAmountsAfterFee(sender, recipient, amount);

        require(
            transferToAmount.add(transferToFeeDistributorAmount) == amount,
            "Math broke!"
        );

        _balances[recipient] = _balances[recipient].add(transferToAmount);
        emit Transfer(sender, recipient, transferToAmount);

        if (
            transferToFeeDistributorAmount > 0 &&
            farmingFeeDistributor != address(0)
        ) {
            _balances[farmingFeeDistributor] = _balances[farmingFeeDistributor]
                .add(transferToFeeDistributorAmount);
            emit Transfer(
                sender,
                farmingFeeDistributor,
                transferToFeeDistributorAmount
            );
            IMasterchef(farmingFeeDistributor).updatePendingRewards();
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    mapping(address => bool) public noFeeList;
    uint256 public feePercentX100;

    function setFeeMultiplier(uint8 _feeMultiplier) public onlyOwner {
        require(_feeMultiplier <= 20, "Max fee is 2%");
        feePercentX100 = _feeMultiplier;
    }

    function editNoFeeList(address _address, bool noFee) public onlyOwner {
        _editNoFeeList(_address, noFee);
    }

    function _editNoFeeList(address _address, bool noFee) internal {
        noFeeList[_address] = noFee;
    }

    function calculateAmountsAfterFee(
        address sender,
        address recipient, // unusued maybe use din future
        uint256 amount
    )
        public view
        returns (
            uint256 transferToAmount,
            uint256 transferToFeeDistributorAmount
        )
    {
        if (noFeeList[sender] || noFeeList[recipient]) {
            // Dont have a fee when masterchef is sending, or infinite loop
            transferToFeeDistributorAmount = 0;
            transferToAmount = amount;
        } else {
            transferToFeeDistributorAmount = amount.mul(feePercentX100).div(
                1000
            );
            transferToAmount = amount.sub(transferToFeeDistributorAmount);
        }
    }
}