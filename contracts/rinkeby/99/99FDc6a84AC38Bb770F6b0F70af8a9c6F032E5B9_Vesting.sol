// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IERC20Mintable.sol";
import "./interfaces/IVesting.sol";

contract Vesting is IVesting, EIP712Upgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    bytes32 private constant _CONTAINER_TYPEHASE =
        keccak256(
            "Container(address sender,uint256 amount,bool isFiat,uint256 nonce)"
        );

    uint256 public constant MAX_INITIAL_PERCENTAGE = 1e20;

    bool public isCompleted;
    address public signer;
    uint256 private _startDate;
    uint256 private _endDate;
    uint8 public rewardTokenDecimals;
    uint8 public stakedTokenDecimals;

    mapping(address => uint256) public rewardsPaid;
    mapping(address => uint256) public deposited;
    mapping(address => uint256) public specificAllocation;
    mapping(address => VestingInfo) public specificVesting;

    string private _name;
    uint256 private _totalSupply;
    uint256 private _tokenPrice;
    uint256 private _totalDeposited;
    uint256 private _initialPercentage;
    uint256 private _minAllocation;
    uint256 private _maxAllocation;
    IERC20 private _rewardToken;
    IERC20 private _depositToken;
    VestingType private _vestingType;
    VestingInfo private _vestingInfo;

    mapping(address => mapping(uint256 => bool)) private nonces;

    function initialize(
        string memory name_,
        address rewardToken_,
        address depositToken_,
        address signer_,
        uint256 initialUnlockPercentage_,
        uint256 minAllocation_,
        uint256 maxAllocation_,
        VestingType vestingType_
    ) external override initializer {
        require(
            rewardToken_ != address(0) && depositToken_ != address(0),
            "Incorrect token address"
        );
        require(
            minAllocation_ <= maxAllocation_ && maxAllocation_ != 0,
            "Incorrect allocation size"
        );
        require(
            initialUnlockPercentage_ <= MAX_INITIAL_PERCENTAGE,
            "Incorrect initial percentage"
        );
        require(signer_ != address(0), "Incorrect signer address");

        _initialPercentage = initialUnlockPercentage_;
        _minAllocation = minAllocation_;
        _maxAllocation = maxAllocation_;
        _name = name_;
        _vestingType = vestingType_;
        _rewardToken = IERC20(rewardToken_);
        _depositToken = IERC20(depositToken_);
        rewardTokenDecimals = IERC20Metadata(rewardToken_).decimals();
        stakedTokenDecimals = IERC20Metadata(depositToken_).decimals();

        signer = signer_;

        __Ownable_init();
        __EIP712_init("Vesting", "v1");
    }

    function getTimePoint()
        external
        view
        virtual
        override
        returns (uint256 startDate, uint256 endDate)
    {
        return (_startDate, _endDate);
    }

    function getAvailAmountToDeposit(address _addr)
        external
        view
        virtual
        override
        returns (uint256 minAvailAllocation, uint256 maxAvailAllocation)
    {
        uint256 totalCurrency = convertToCurrency(_totalSupply);

        if (totalCurrency <= _totalDeposited) {
            return (0, 0);
        }

        uint256 depositedAmount = deposited[_addr];

        uint256 remaining = totalCurrency - _totalDeposited;

        uint256 maxAllocation = specificAllocation[_addr] > 0
            ? specificAllocation[_addr]
            : _maxAllocation;
        maxAvailAllocation = depositedAmount < maxAllocation
            ? Math.min(maxAllocation - depositedAmount, remaining)
            : 0;
        minAvailAllocation = depositedAmount == 0 ? _minAllocation : 0;
    }

    function getInfo()
        external
        view
        virtual
        override
        returns (
            string memory name,
            address stakedToken,
            address rewardToken,
            uint256 minAllocation,
            uint256 maxAllocation,
            uint256 totalSupply,
            uint256 totalDeposited,
            uint256 tokenPrice,
            uint256 initialUnlockPercentage,
            VestingType vestingType
        )
    {
        return (
            _name,
            address(_depositToken),
            address(_rewardToken),
            _minAllocation,
            _maxAllocation,
            _totalSupply,
            _totalDeposited,
            _tokenPrice,
            _initialPercentage,
            _vestingType
        );
    }

    function getVestingInfo()
        external
        view
        virtual
        override
        returns (
            uint256 periodDuration,
            uint256 countPeriodOfVesting,
            Interval[] memory intervals
        )
    {
        VestingInfo memory info = _vestingInfo;
        uint256 size = info.unlockIntervals.length;
        intervals = new Interval[](size);

        for (uint256 i = 0; i < size; i++) {
            intervals[i] = info.unlockIntervals[i];
        }
        periodDuration = info.periodDuration;
        countPeriodOfVesting = info.countPeriodOfVesting;
    }

    function getBalanceInfo(address _addr)
        external
        view
        virtual
        override
        returns (uint256 lockedBalance, uint256 unlockedBalance)
    {
        uint256 tokenBalance = convertToToken(deposited[_addr]);

        if (!_isVestingStarted()) {
            return (tokenBalance, 0);
        }

        uint256 unlock = _calculateUnlock(_addr, 0);
        return (tokenBalance - unlock - rewardsPaid[_addr], unlock);
    }

    function initializeToken(uint256 tokenPrice_, uint256 totalSypply_)
        external
        virtual
        override
        onlyOwner
    {
        require(_tokenPrice == 0, "Is was initialized before");
        require(totalSypply_ > 0 && tokenPrice_ > 0, "Incorrect amount");

        _tokenPrice = tokenPrice_;
        _totalSupply = totalSypply_;

        _rewardToken.safeTransferFrom(
            _msgSender(),
            address(this),
            totalSypply_
        );
    }

    function increaseTotalSupply(uint256 _amount)
        external
        virtual
        override
        onlyOwner
    {
        require(!isCompleted, "Vesting should be not completed");
        _totalSupply += _amount;
        _rewardToken.safeTransferFrom(_msgSender(), address(this), _amount);
        emit IncreaseTotalSupply(_amount);
    }

    function setTimePoint(uint256 startDate_, uint256 endDate_)
        external
        virtual
        override
        onlyOwner
    {
        require(
            startDate_ < endDate_ && block.timestamp < startDate_,
            "Incorrect dates"
        );
        _startDate = startDate_;
        _endDate = endDate_;
        emit SetTimePoint(startDate_, endDate_);
    }

    function setSigner(address addr_) external virtual override onlyOwner {
        require(addr_ != address(0), "Incorrect signer address");
        signer = addr_;
    }

    function setSpecificAllocation(
        address[] calldata addrs_,
        uint256[] calldata amount_
    ) external virtual override onlyOwner {
        require(addrs_.length == amount_.length, "Diff array size");

        for (uint256 index = 0; index < addrs_.length; index++) {
            specificAllocation[addrs_[index]] = amount_[index];
        }
        emit SetSpecificAllocation(addrs_, amount_);
    }

    function setSpecificVesting(
        address addr_,
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        Interval[] calldata intervals_
    ) external virtual override onlyOwner {
        VestingInfo storage info = specificVesting[addr_];
        require(
            !(info.countPeriodOfVesting > 0 || info.unlockIntervals.length > 0),
            "was initialized before"
        );
        _setVesting(info, periodDuration_, countPeriodOfVesting_, intervals_);
    }

    function setVesting(
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        Interval[] calldata intervals_
    ) external virtual override onlyOwner {
        VestingInfo storage info = _vestingInfo;
        _setVesting(info, periodDuration_, countPeriodOfVesting_, intervals_);
    }

    function addDepositeAmount(
        address[] calldata _addrArr,
        uint256[] calldata _amountArr
    ) external virtual override onlyOwner {
        require(_addrArr.length == _amountArr.length, "Incorrect array length");
        require(!_isVestingStarted(), "Sale is closed");

        uint256 remainingAllocation = _totalSupply -
            convertToToken(_totalDeposited);

        for (uint256 index = 0; index < _addrArr.length; index++) {
            uint256 convertAmount = convertToToken(_amountArr[index]);
            require(
                convertAmount <= remainingAllocation,
                "Not enough allocation"
            );

            remainingAllocation -= convertAmount;

            deposited[_addrArr[index]] += _amountArr[index];

            _totalDeposited += _amountArr[index];
        }
        emit Deposites(_addrArr, _amountArr);
    }

    function completeVesting() external virtual override onlyOwner {
        require(_isVestingStarted(), "Vesting can't be started");
        require(!isCompleted, "Complete was called before");
        isCompleted = true;

        uint256 soldToken = convertToToken(_totalDeposited);

        if (soldToken < _totalSupply)
            _rewardToken.safeTransfer(_msgSender(), _totalSupply - soldToken);

        uint256 balance = _depositToken.balanceOf(address(this));
        _depositToken.safeTransfer(_msgSender(), balance);
    }

    function deposite(
        uint256 _amount,
        bool _fiat,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual override {
        require(!nonces[_msgSender()][_nonce], "Nonce used before");
        require(
            _isValidSigner(_msgSender(), _amount, _fiat, _nonce, _v, _r, _s),
            "Invalid signer"
        );
        require(_isSale(), "Sale is closed");
        require(_isValidAmount(_amount), "Invalid amount");

        nonces[_msgSender()][_nonce] = true;
        deposited[_msgSender()] += _amount;
        _totalDeposited += _amount;

        uint256 transferAmount = _convertToCorrectDecimals(
            _amount,
            rewardTokenDecimals,
            stakedTokenDecimals
        );
        if (!_fiat) {
            _depositToken.safeTransferFrom(
                _msgSender(),
                address(this),
                transferAmount
            );
        }

        if (VestingType.SWAP == _vestingType) {
            uint256 tokenAmount = convertToToken(_amount);
            rewardsPaid[_msgSender()] += tokenAmount;
            _rewardToken.safeTransfer(_msgSender(), tokenAmount);
            emit Harvest(_msgSender(), tokenAmount);
        }

        emit Deposite(_msgSender(), _amount, _fiat);
    }

    function harvestFor(address _addr) external virtual override {
        _harvest(_addr, 0);
    }

    function harvest() external virtual override {
        _harvest(_msgSender(), 0);
    }

    function harvestInterval(uint256 intervalIndex) external virtual override {
        _harvest(_msgSender(), intervalIndex);
    }

    function DOMAIN_SEPARATOR()
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return _domainSeparatorV4();
    }

    function convertToToken(uint256 _amount)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return (_amount * 10**rewardTokenDecimals) / _tokenPrice;
    }

    function convertToCurrency(uint256 _amount)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return (_amount * _tokenPrice) / 10**rewardTokenDecimals;
    }

    function _calculateUnlock(address _addr, uint256 intervalIndex)
        internal
        view
        virtual
        returns (uint256)
    {
        uint256 tokenAmount = convertToToken(deposited[_addr]);
        uint256 oldRewards = rewardsPaid[_addr];

        VestingInfo memory info = specificVesting[_addr].periodDuration > 0 ||
            specificVesting[_addr].unlockIntervals.length > 0
            ? specificVesting[_addr]
            : _vestingInfo;

        if (VestingType.LINEAR_VESTING == _vestingType) {
            tokenAmount = _calculateLinearUnlock(info, tokenAmount);
        } else if (VestingType.INTERVAL_VESTING == _vestingType) {
            tokenAmount = _calculateIntervalUnlock(
                info.unlockIntervals,
                tokenAmount,
                intervalIndex
            );
        }
        return tokenAmount > oldRewards ? tokenAmount - oldRewards : 0;
    }

    function _calculateLinearUnlock(
        VestingInfo memory info,
        uint256 tokenAmount
    ) internal view virtual returns (uint256) {
        uint256 initialUnlockAmount = (tokenAmount * _initialPercentage) /
            MAX_INITIAL_PERCENTAGE;
        uint256 passePeriod = Math.min(
            (block.timestamp - _endDate) / info.periodDuration,
            info.countPeriodOfVesting
        );
        return
            (((tokenAmount - initialUnlockAmount) * passePeriod) /
                info.countPeriodOfVesting) + initialUnlockAmount;
    }

    function _calculateIntervalUnlock(
        Interval[] memory intervals,
        uint256 tokenAmount,
        uint256 intervalIndex
    ) internal view virtual returns (uint256) {
        uint256 unlockPercentage = _initialPercentage;
        if (intervalIndex > 0) {
            require(intervals[intervalIndex].timeStamp < block.timestamp, "Incorrect interval index");
            unlockPercentage = intervals[intervalIndex].percentage;
        } else {
            for (uint256 i = 0; i < intervals.length; i++) {
                if (block.timestamp > intervals[i].timeStamp) {
                    unlockPercentage = intervals[i].percentage;
                } else {
                    break;
                }
            }
        }

        return (tokenAmount * unlockPercentage) / MAX_INITIAL_PERCENTAGE;
    }

    function _convertToCorrectDecimals(
        uint256 _amount,
        uint256 _fromDecimals,
        uint256 _toDecimals
    ) internal pure virtual returns (uint256) {
        if (_fromDecimals < _toDecimals) {
            _amount = _amount * (10**(_toDecimals - _fromDecimals));
        } else if (_fromDecimals > _toDecimals) {
            _amount = _amount / (10**(_fromDecimals - _toDecimals));
        }
        return _amount;
    }

    function _isVestingStarted() internal view virtual returns (bool) {
        return block.timestamp > _endDate && _endDate != 0;
    }

    function _isSale() internal view virtual returns (bool) {
        return block.timestamp >= _startDate && block.timestamp < _endDate;
    }

    function _isValidSigner(
        address _sender,
        uint256 _amount,
        bool _fiat,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view virtual returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(_CONTAINER_TYPEHASE, _sender, _amount, _fiat, _nonce)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address messageSigner = ECDSAUpgradeable.recover(hash, _v, _r, _s);

        return messageSigner == signer;
    }

    function _isValidAmount(uint256 _amount)
        internal
        view
        virtual
        returns (bool)
    {
        uint256 maxAllocation = specificAllocation[_msgSender()] > 0
            ? specificAllocation[_msgSender()]
            : _maxAllocation;
        uint256 depositAmount = deposited[_msgSender()];
        uint256 remainingAmount = Math.min(
            maxAllocation - depositAmount,
            convertToCurrency(_totalSupply) - _totalDeposited
        );
        return
            (_amount < _minAllocation && depositAmount == 0) ||
                (_amount > maxAllocation || _amount > remainingAmount)
                ? false
                : true;
    }

    function _setVesting(
        VestingInfo storage info,
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        Interval[] calldata _intervals
    ) internal virtual {
        if (VestingType.LINEAR_VESTING == _vestingType) {
            require(
                countPeriodOfVesting_ > 0 && periodDuration_ > 0,
                "Incorrect linear vesting setup"
            );
            info.periodDuration = periodDuration_;
            info.countPeriodOfVesting = countPeriodOfVesting_;
        } else {
            delete info.unlockIntervals;
            uint256 lastUnlockingPart = _initialPercentage;
            uint256 lastIntervalStartingTimestamp = _endDate;
            for (uint256 i = 0; i < _intervals.length; i++) {
                uint256 percent = _intervals[i].percentage;
                require(
                    percent > lastUnlockingPart &&
                        percent <= MAX_INITIAL_PERCENTAGE,
                    "Invalid interval unlocking part"
                );
                require(
                    _intervals[i].timeStamp > lastIntervalStartingTimestamp,
                    "Invalid interval starting timestamp"
                );
                lastUnlockingPart = percent;
                info.unlockIntervals.push(_intervals[i]);
            }
            require(
                lastUnlockingPart == MAX_INITIAL_PERCENTAGE,
                "Invalid interval unlocking part"
            );
        }
    }

    function _harvest(address _addr, uint256 intervalIndex) internal virtual {
        require(_isVestingStarted(), "Vesting can't be started");

        uint256 amountToTransfer = _calculateUnlock(_addr, intervalIndex);

        require(amountToTransfer > 0, "Amount is zero");

        rewardsPaid[_addr] += amountToTransfer;

        _rewardToken.safeTransfer(_addr, amountToTransfer);

        emit Harvest(_addr, amountToTransfer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVesting {
    event Harvest(address indexed sender, uint256 amount);
    event Deposite(address indexed sender, uint256 amount, bool isFiat);
    event Deposites(address[] indexed senders, uint256[] amounts);
    event SetSpecificAllocation(address[] users, uint256[] allocation);
    event SetWhitelist(address[] users, uint256[] allocation);
    event IncreaseTotalSupply(uint256 amount);
    event SetTimePoint(uint256 startDate, uint256 endDate);

    enum VestingType {
        SWAP,
        LINEAR_VESTING,
        INTERVAL_VESTING
    }

    struct Interval {
        uint256 timeStamp;
        uint256 percentage;
    }

    struct VestingInfo {
        uint256 periodDuration;
        uint256 countPeriodOfVesting;
        Interval[] unlockIntervals;
    }

    function initialize(
        string memory name_,
        address rewardToken_,
        address depositToken_,
        address signer_,
        uint256 initialUnlockPercentage_,
        uint256 minAllocation_,
        uint256 maxAllocation_,
        VestingType vestingType_
    ) external;

    function getAvailAmountToDeposit(address _addr)
        external
        view
        returns (uint256 minAvailAllocation, uint256 maxAvailAllocation);

    function getInfo()
        external
        view
        returns (
            string memory name,
            address stakedToken,
            address rewardToken,
            uint256 minAllocation,
            uint256 maxAllocation,
            uint256 totalSupply,
            uint256 totalDeposited,
            uint256 tokenPrice,
            uint256 initialUnlockPercentage,
            VestingType vestingType
        );

    function getVestingInfo()
        external
        view
        returns (
            uint256 periodDuration,
            uint256 countPeriodOfVesting,
            Interval[] memory intervals
        );

    function getBalanceInfo(address _addr)
        external
        view
        returns (uint256 lockedBalance, uint256 unlockedBalance);

    function initializeToken(uint256 tokenPrice_, uint256 totalSypply_)
        external;

    function increaseTotalSupply(uint256 _amount) external;

    function setTimePoint(uint256 _startDate, uint256 _endDate) external;

    function setSigner(address addr_) external;

    function setSpecificAllocation(
        address[] calldata addrs_,
        uint256[] calldata amount_
    ) external;

    function setSpecificVesting(
        address addr_,
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        Interval[] calldata intervals_
    ) external;

    function setVesting(
        uint256 periodDuration_,
        uint256 countPeriodOfVesting_,
        Interval[] calldata intervals_
    ) external;

    function addDepositeAmount(
        address[] calldata _addrArr,
        uint256[] calldata _amountArr
    ) external;

    function completeVesting() external;

    function deposite(
        uint256 _amount,
        bool _fiat,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function harvestFor(address _addr) external;

    function harvest() external;

    function harvestInterval(uint256 intervalIndex) external;

    function DOMAIN_SEPARATOR() external view returns(bytes32);

    function convertToToken(uint256 _amount) external view returns (uint256);

    function convertToCurrency(uint256 _amount) external view returns (uint256);

    function getTimePoint()
        external
        view
        returns (uint256 startDate, uint256 endDate);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20Mintable {
    function mint(address _to, uint256 _value) external;

    function burn(address account, uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}