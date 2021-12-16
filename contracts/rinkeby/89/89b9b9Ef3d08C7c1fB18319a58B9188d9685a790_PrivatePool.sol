// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./libraries/DecimalsConverter.sol";
import "./management/ManagedUpgradeable.sol";
import "./management/Constants.sol";
import "./interfaces/IPoolPrivate.sol";

contract PrivatePool is IPoolPrivate, ManagedUpgradeable {
    using DecimalsConverter for uint256;

    RewardTokenInfo[] public rewardsTokenInfo;
    uint256 internal _saleStartDate;
    uint256 internal _secondRoundStart;
    uint256 internal _saleEndDate;
    uint256 internal _vestingDate;
    uint256 internal _initialUnlockPercentage;
    uint256 internal _percentagePerBlock;
    uint256 internal _totalRaise;
    uint256 internal _totalDeposited;
    uint256 internal _feePercentage;
    uint256 internal _blockDuration;
    string internal _name;
    address internal _ownerRecipient;
    address internal _depositeToken;
    bool internal _isContribute;
    bool internal _isKYC;
    uint256[] internal _percentagePerMonth;
    mapping(address => mapping(address => uint256)) public harvestPaid;
    mapping(address => uint256) internal _deposited;
    mapping(address => uint256) internal allocation;
    mapping(address => uint256) internal _decimals;

    modifier canDeposit(
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        if (_isKYC) {
            require(
                management.isKYCPassed(_msgSender(), _deadline, _v, _r, _s),
                ERROR_KYC_MISSING
            );
        }
        _;
    }

    function initialize(
        address management_,
        string memory name_,
        bool isKyc_,
        address depositeToken_,
        address ownerRecipient_,
        uint256 totalRaise_,
        uint256 feePercentage_
    ) external initializer {
        require(ownerRecipient_ != address(0), ERROR_INVALID_ADDRESS);
        require(totalRaise_ > 0, ERROR_AMOUNT_IS_ZERO);
        require(feePercentage_ <= MAX_FEE_PERCENTAGE, ERROR_MORE_THEN_MAX);
        _name = name_;
        _ownerRecipient = ownerRecipient_;
        _depositeToken = depositeToken_;
        _isKYC = isKyc_;
        _totalRaise = totalRaise_;
        _feePercentage = feePercentage_;
        if (depositeToken_ != address(0)) {
            _decimals[depositeToken_] = IERC20Metadata(depositeToken_)
                .decimals();
        }
        __Managed_init(management_);
    }

    function getInfo()
        external
        view
        returns (
            string memory name,
            address depositeToken,
            bool isKYC,
            uint256 totalRaise,
            uint256 totalDeposited,
            uint256 feePercentage
        )
    {
        name = _name;
        depositeToken = _depositeToken;
        isKYC = _isKYC;
        totalRaise = _totalRaise;
        totalDeposited = _totalDeposited;
        feePercentage = _feePercentage;
    }

    function balanceOf(address _recipient)
        external
        view
        override
        returns (uint256)
    {
        return _deposited[_recipient];
    }

    function getAvailHarvest(address _sender)
        external
        view
        returns (address[] memory rewardTokens, uint256[] memory availHarverst)
    {
        uint256 length = rewardsTokenInfo.length;
        rewardTokens = new address[](length);
        availHarverst = new uint256[](length);
        for (uint256 i; i < length; i++) {
            rewardTokens[i] = rewardsTokenInfo[i].token;
            availHarverst[i] = _calculateAvailHarvest(
                _sender,
                rewardsTokenInfo[i].token,
                rewardsTokenInfo[i].amount
            );
        }
    }

    function getAllTimePoint()
        external
        view
        returns (
            uint256 saleStart,
            uint256 secondRoundStart,
            uint256 saleEnd
        )
    {
        return (_saleStartDate, _secondRoundStart, _saleEndDate);
    }

    function getTokensPriceInfo()
        external
        view
        returns (address[] memory tokens, uint256[] memory pricePerToken)
    {
        uint256 size = rewardsTokenInfo.length;
        tokens = new address[](size);
        pricePerToken = new uint256[](size);
        for (uint256 i = 0; i < rewardsTokenInfo.length; i++) {
            tokens[i] = rewardsTokenInfo[i].token;
            pricePerToken[i] =
                (_totalRaise * DECIMALS18) /
                rewardsTokenInfo[i].amount;
        }
    }

    function getVestingInfo()
        external
        view
        override
        returns (
            uint256 vestingDateStart,
            uint256 initialUnlockPercentage,
            uint256 blockDuration,
            uint256 percentPerBlock,
            uint256[] memory percentPerMonth
        )
    {
        percentPerMonth = new uint256[](_percentagePerMonth.length);
        for (uint256 i; i < _percentagePerMonth.length; i++) {
            percentPerMonth[i] = _percentagePerMonth[i];
        }
        return (
            _vestingDate,
            _initialUnlockPercentage,
            _blockDuration,
            _percentagePerBlock,
            percentPerMonth
        );
    }

    function getRewardsTokenInfo()
        external
        view
        override
        returns (RewardTokenInfo[] memory rewardsInfo)
    {
        rewardsInfo = new RewardTokenInfo[](rewardsTokenInfo.length);
        for (uint256 index; index < rewardsTokenInfo.length; index++) {
            rewardsInfo[index] = rewardsTokenInfo[index];
        }
    }

    function deposite(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_depositeToken != address(0), ERROR_INCORRECT_CALL_METHOD);
        _deposite(_amount, _deadline, _v, _r, _s);
    }

    function depositeETH(
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        require(_depositeToken == address(0), ERROR_INCORRECT_CALL_METHOD);
        _deposite(msg.value, _deadline, _v, _r, _s);
    }

    function harvest() external override {
        for (uint256 i; i < rewardsTokenInfo.length; i++) {
            RewardTokenInfo storage info = rewardsTokenInfo[i];
            uint256 availHarvest = _calculateAvailHarvest(
                _msgSender(),
                info.token,
                info.amount
            );
            require(availHarvest > 0, ERROR_AMOUNT_IS_ZERO);
            harvestPaid[info.token][_msgSender()] += availHarvest;
            _transfer(info.token, _msgSender(), availHarvest);
            emit Harvest(_msgSender(), availHarvest);
        }
    }

    function setKYC(bool value_) external requirePermission(ROLE_ADMIN) {
        _isKYC = value_;
    }

    function setTimePoints(
        uint256 saleStartDate_,
        uint256 secondRoundStartDate_,
        uint256 saleEndDate_
    ) external requirePermission(ROLE_ADMIN) {
        require(
            saleStartDate_ < saleEndDate_ &&
                secondRoundStartDate_ > saleStartDate_ &&
                secondRoundStartDate_ < saleEndDate_,
            ERROR_INCORRECT_DATE
        );
        _saleStartDate = saleStartDate_;
        _secondRoundStart = secondRoundStartDate_;
        _saleEndDate = saleEndDate_;
        emit SetTimePoints(saleStartDate_, _secondRoundStart, _saleEndDate);
    }

    function setVesting(
        uint256 vestingDate_,
        uint256 initialUnlockPercentage_,
        uint256 percentagePerBlock_,
        uint256 blockDuration_,
        uint256[] calldata percentagePerMonth_
    ) external override requirePermission(ROLE_ADMIN) {
        require(
            initialUnlockPercentage_ <= PERCENTAGE_100,
            ERROR_AMOUNT_IS_MORE_TS
        );
        if (initialUnlockPercentage_ < PERCENTAGE_100) {
            require(
                (percentagePerBlock_ > 0 || percentagePerMonth_.length > 0) &&
                    !(percentagePerBlock_ > 0 &&
                        percentagePerMonth_.length > 0),
                ERROR_FAIL
            );
            _blockDuration = blockDuration_;
            _percentagePerBlock = percentagePerBlock_;
            delete _percentagePerMonth;
            for (uint256 i = 0; i < percentagePerMonth_.length; i++) {
                _percentagePerMonth.push(percentagePerMonth_[i]);
            }
        }
        _initialUnlockPercentage = initialUnlockPercentage_;
        _vestingDate = vestingDate_;
        emit SetVesting(
            vestingDate_,
            initialUnlockPercentage_,
            percentagePerBlock_,
            blockDuration_,
            percentagePerMonth_
        );
    }

    function withdrawContributions() external override {
        require(_ownerRecipient == _msgSender(), ERROR_ACCESS_DENIED);
        require(!_isContribute, ERROR_ALREADY_CALL_METHOD);
        require(
            _saleEndDate != 0 && block.timestamp > _saleEndDate,
            ERROR_VESTING_NOT_START
        );
        _isContribute = true;
        uint256 balance;
        uint256 fee;
        address payable tresuary = management.contractRegistry(
            ADDRESS_TRESUARY
        );
        if (_depositeToken == address(0)) {
            balance = address(this).balance;
            fee = (_feePercentage * balance) / PERCENTAGE_100;
            _sendValue(_ownerRecipient, balance - fee);
            if (fee > 0) {
                _sendValue(tresuary, fee);
            }
        } else {
            balance = IERC20Metadata(_depositeToken).balanceOf(address(this));
            fee = (_feePercentage * balance) / PERCENTAGE_100;
            _transfer(_depositeToken, _ownerRecipient, balance - fee);
            if (fee > 0) {
                _transfer(_depositeToken, tresuary, fee);
            }
        }
        uint256 finishPercentage = (_totalDeposited * DECIMALS18) / _totalRaise;
        for (uint256 i; i < rewardsTokenInfo.length; i++) {
            RewardTokenInfo memory info = rewardsTokenInfo[i];
            uint256 unsoldTokens = info.amount -
                (info.amount * finishPercentage) /
                DECIMALS18;
            _transfer(info.token, _ownerRecipient, unsoldTokens);
            emit WithdrawOwner(
                _msgSender(),
                info.token,
                unsoldTokens,
                finishPercentage
            );
        }
        emit WithdrawOwner(_msgSender(), _depositeToken, balance, fee);
    }

    function setTotalRaise(uint256 _amount)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        _totalRaise = _amount;
        emit SetTotalRaise(_amount);
    }

    function addRewardToken(
        RewardTokenInfo calldata _info,
        uint256 _id,
        bool _isUpdate
    ) external override requirePermission(ROLE_ADMIN) {
        if (_isUpdate) {
            uint256 amount = rewardsTokenInfo[_id].amount;
            if (amount < _info.amount) {
                _transferFrom(_info.token, _info.amount - amount);
            } else {
                _transfer(_info.token, _msgSender(), amount - _info.amount);
            }
            rewardsTokenInfo[_id] = _info;
        } else {
            if (_decimals[_info.token] == 0) {
                _decimals[_info.token] = IERC20Metadata(_info.token).decimals();
                rewardsTokenInfo.push(_info);
            }
            if (_info.token != address(0)) {
                _transferFrom(_info.token, _info.amount);
            }
        }
        emit AddRewardToken(_info);
    }

    function setWhitelist(
        address[] calldata _users,
        uint256[] calldata _allocation
    ) external requirePermission(ROLE_ADMIN) {
        require(_users.length == _allocation.length, ERROR_DIFF_ARR_LENGTH);
        for (uint256 i; i < _users.length; i++) {
            allocation[_users[i]] = _allocation[i];
        }
        emit SetWhitelist(_users, _allocation);
    }

    function emergencyFunction()
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            _sendValue(EMERGENCY_ADDRESS, balance);
        }
        if (_depositeToken != address(0)) {
            _transfer(
                _depositeToken,
                EMERGENCY_ADDRESS,
                IERC20Metadata(_depositeToken).balanceOf(address(this))
            );
        }
        for (uint256 i; i < rewardsTokenInfo.length; i++) {
            address token = rewardsTokenInfo[i].token;
            if (token != address(0)) {
                _transfer(
                    token,
                    EMERGENCY_ADDRESS,
                    IERC20Metadata(token).balanceOf(address(this))
                );
            }
        }
        emit EmergencyCall(_msgSender());
    }

    function getAvailAllocation(address _recipient)
        public
        view
        returns (uint256)
    {
        return
            block.timestamp > _secondRoundStart
                ? _totalRaise - _totalDeposited
                : (allocation[_recipient] * _totalRaise) /
                    PERCENTAGE_100 -
                    _deposited[_recipient];
    }

    function _calculateAvailHarvest(
        address _recipient,
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        if (_vestingDate != 0 && block.timestamp > _vestingDate) {
            uint256 canHarvestAmount = (_deposited[_recipient] *
                DECIMALS18 *
                _amount) /
                _totalRaise /
                DECIMALS18;
            if (_initialUnlockPercentage >= PERCENTAGE_100) {
                return canHarvestAmount - harvestPaid[_token][_recipient];
            } else {
                uint256 amountImmediatelu = (_initialUnlockPercentage *
                    canHarvestAmount) / PERCENTAGE_100;
                uint256 accruedAmount;

                uint256 timePass = block.timestamp - _vestingDate;
                if (_percentagePerMonth.length > 0) {
                    for (
                        uint256 i;
                        i < timePass / 30 days &&
                            i < _percentagePerMonth.length;
                        i++
                    ) {
                        accruedAmount += _percentagePerMonth[i];
                    }
                } else {
                    accruedAmount =
                        (timePass / _blockDuration) *
                        _percentagePerBlock;
                }
                accruedAmount =
                    (accruedAmount * (canHarvestAmount - amountImmediatelu)) /
                    PERCENTAGE_100 +
                    amountImmediatelu;
                canHarvestAmount = canHarvestAmount > accruedAmount
                    ? accruedAmount
                    : canHarvestAmount;
                return canHarvestAmount - harvestPaid[_token][_recipient];
            }
        }
        return 0;
    }

    function _deposite(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal canDeposit(_deadline, _v, _r, _s) {
        require(
            block.timestamp >= _saleStartDate &&
                block.timestamp <= _saleEndDate,
            ERROR_IS_NOT_SALE
        );
        require(_amount > 0, ERROR_AMOUNT_IS_ZERO);
        require(
            getAvailAllocation(_msgSender()) >= _amount,
            ERROR_HAVENT_ALLOCATION
        );
        if (_depositeToken != address(0)) {
            _transferFrom(_depositeToken, _amount);
        }
        _deposited[_msgSender()] += _amount;
        _totalDeposited += _amount;
        emit Deposit(_msgSender(), _amount);
    }

    function _sendValue(address _recipient, uint256 _amount) internal {
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, ERROR_SEND_VALUE);
    }

    function _transferFrom(address _token, uint256 _amount) internal {
        require(
            IERC20Metadata(_token).transferFrom(
                _msgSender(),
                address(this),
                _convertFrom18(_amount, _decimals[_token])
            ),
            ERROR_ERC20_CALL_ERROR
        );
    }

    function _transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        require(
            IERC20Metadata(_token).transfer(
                _to,
                _convertFrom18(_amount, _decimals[_token])
            ),
            ERROR_ERC20_CALL_ERROR
        );
    }

    function _convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        if (18 > destinationDecimals) {
            amount = amount / (10**(18 - destinationDecimals));
        } else if (18 < destinationDecimals) {
            amount = amount * (10**(destinationDecimals - 18));
        }
        return amount;
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

pragma solidity ^0.8.9;

library DecimalsConverter {
    function convert(
        uint256 amount,
        uint256 baseDecimals,
        uint256 destinationDecimals
    ) internal pure returns (uint256) {
        if (baseDecimals > destinationDecimals) {
            amount = amount / (10**(baseDecimals - destinationDecimals));
        } else if (baseDecimals < destinationDecimals) {
            amount = amount * (10**(destinationDecimals - baseDecimals));
        }

        return amount;
    }

    function convertTo18(uint256 amount, uint256 baseDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, baseDecimals, 18);
    }

    function convertFrom18(uint256 amount, uint256 destinationDecimals)
        internal
        pure
        returns (uint256)
    {
        return convert(amount, 18, destinationDecimals);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IManagement.sol";
import "./Constants.sol";

contract ManagedUpgradeable is OwnableUpgradeable {
    IManagement public management;

    modifier requirePermission(uint256 _permission) {
        require(_hasPermission(_msgSender(), _permission), ERROR_ACCESS_DENIED);
        _;
    }

    function setManagementContract(address _management) external onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);
        management = IManagement(_management);
    }

    function _hasPermission(address _subject, uint256 _permission)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permission);
    }

    function __Managed_init(address _managementAddress) internal initializer {
        management = IManagement(_managementAddress);
        __Ownable_init();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

uint256 constant DECIMALS = 18;
uint256 constant DECIMALS18 = 1e18;

uint256 constant MAX_UINT256 = type(uint256).max;
uint256 constant PERCENTAGE_100 = 100 * DECIMALS18;
uint256 constant PERCENTAGE_1 = DECIMALS18;
uint256 constant MAX_FEE_PERCENTAGE = 99 * DECIMALS18;
bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;

string constant ERROR_ACCESS_DENIED = "0x1";
string constant ERROR_NO_CONTRACT = "0x2";
string constant ERROR_NOT_AVAILABLE = "0x3";
string constant ERROR_KYC_MISSING = "0x4";
string constant ERROR_INVALID_ADDRESS = "0x5";
string constant ERROR_INCORRECT_CALL_METHOD = "0x6";
string constant ERROR_AMOUNT_IS_ZERO = "0x7";
string constant ERROR_HAVENT_ALLOCATION = "0x8";
string constant ERROR_AMOUNT_IS_MORE_TS = "0x9";
string constant ERROR_ERC20_CALL_ERROR = "0xa";
string constant ERROR_DIFF_ARR_LENGTH = "0xb";
string constant ERROR_METHOD_DISABLE = "0xc";
string constant ERROR_SEND_VALUE = "0xd";
string constant ERROR_NOT_ENOUGH_NFT_IDS = "0xe";
string constant ERROR_INCORRECT_FEE = "0xf";
string constant ERROR_WRONG_IMPLEMENT_ADDRESS = "0x10";
string constant ERROR_INVALIG_SIGNER = "0x11";
string constant ERROR_NOT_FOUND = "0x12";
string constant ERROR_IS_EXISTS = "0x13";
string constant ERROR_IS_NOT_EXISTS = "0x14";
string constant ERROR_TIME_OUT = "0x15";
string constant ERROR_NFT_NOT_EXISTS = "0x16";
string constant ERROR_MINTING_COMPLETED = "0x17";
string constant ERROR_TOKEN_NOT_SUPPORTED = "0x18";
string constant ERROR_NOT_ENOUGH_NFT_FOR_SALE = "0x19";
string constant ERROR_NOT_ENOUGH_PREVIEUS_NFT = "0x1a";
string constant ERROR_FAIL = "0x1b";
string constant ERROR_MORE_THEN_MAX = "0x1c";
string constant ERROR_VESTING_NOT_START = "0x1d";
string constant ERROR_VESTING_IS_STARTED = "0x1e";
string constant ERROR_IS_SET = "0x1f";
string constant ERROR_ALREADY_CALL_METHOD = "0x20";
string constant ERROR_INCORRECT_DATE = "0x21";
string constant ERROR_IS_NOT_SALE = "0x22";

bytes32 constant KYC_CONTAINER_TYPEHASE = keccak256(
    "Container(address sender,uint256 deadline)"
);

bytes32 constant _GENESIS_CONTAINER_TYPEHASE = keccak256(
    "Container(string stakingName,bool isETHStake,bool isPrivate,bool isCanTakeReward,address stakedToken,uint256 startBlock,uint256 duration,uint256 nonce)"
);
bytes32 constant _LIQUIDITY_MINING_CONTAINER_TYPEHASE = keccak256(
    "Container(string stakingName,bool isPrivate,bool isCanTakeReward,address stakedToken,uint256 startBlock,uint256 duration,uint256 nonce)"
);

address constant EMERGENCY_ADDRESS = 0x85CCc822A20768F50397BBA5Fd9DB7de68851D5B;

//permisionss
//WHITELIST
uint256 constant ROLE_ADMIN = 1;
uint256 constant ROLE_REGULAR = 2;

uint256 constant MANAGEMENT_CAN_SET_KYC_WHITELISTED = 3;
uint256 constant MANAGEMENT_CAN_SET_PRIVATE_WHITELISTED = 4;
uint256 constant MANAGEMENT_WHITELISTED_KYC = 5;
uint256 constant MANAGEMENT_WHITELISTED_PRIVATE = 6;
uint256 constant MANAGEMENT_CAN_SET_POOL_OWNER = 7;

uint256 constant REGISTER_CAN_ADD_STAKING = 21;
uint256 constant REGISTER_CAN_REMOVE_STAKING = 22;
uint256 constant REGISTER_CAN_ADD_POOL = 30;
uint256 constant REGISTER_CAN_REMOVE_POOL = 31;

uint256 constant GENERAL_CAN_UPDATE_DEPENDENCY = 100;
uint256 constant NFT_CAN_TRANSFER_NFT = 101;
uint256 constant NFT_CAN_MINT_NFT = 102;

//REGISTER_ADDRESS
uint256 constant CONTRACT_MANAGEMENT = 0;
uint256 constant CONTRACT_KAISHI_TOKEN = 1;
uint256 constant CONTRACT_STAKING_REGISTER = 2;
uint256 constant CONTRACT_POOL_REGISTER = 3;
uint256 constant CONTRACT_NFT_FACTORY = 4;
uint256 constant ADDRESS_TRESUARY = 5;
uint256 constant ADDRESS_FACTORY_SIGNER = 6;
uint256 constant ADDRESS_PROXY_OWNER = 7;
uint256 constant ADDRESS_MANAGED_OWNER = 8;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IPool.sol";

interface IPoolPrivate is IPool {
    event SetTimePoints(
        uint256 saleStartDate,
        uint256 secondRoundStart,
        uint256 saleEndDate
    );

    event SetRewardTokenAddress(uint256 id, address token);
    event SetTokenAmount(uint256 id, uint256 amount);
    event SetWhitelist(address[] users, uint256[] allocation);
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

pragma solidity ^0.8.9;

interface IManagement {
    event PoolOwnerSet(address indexed pool, address indexed owner, bool value);

    event PermissionsSet(
        address indexed subject,
        uint256[] indexed permissions,
        bool value
    );

    event UsersPermissionsSet(
        address[] indexed subject,
        uint256 indexed permissions,
        bool value
    );

    event PermissionSet(
        address indexed subject,
        uint256 indexed permission,
        bool value
    );

    event ContractRegistered(
        uint256 indexed key,
        address indexed source,
        address target
    );

    function isKYCPassed(
        address _address,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external view returns (bool);

    function requireAccess(address _address, address _pool)
        external
        view
        returns (bool);

    function contractRegistry(uint256 _key)
        external
        view
        returns (address payable);

    function permissions(address _address, uint256 _permission)
        external
        view
        returns (bool);

    function kycSigner() external view returns (address);

    function setPoolOwner(
        address _pool,
        address _owner,
        bool _value
    ) external;

    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    ) external;

    function setPermissions(
        address _address,
        uint256[] calldata _permissions,
        bool _value
    ) external;

    function registerContract(uint256 _key, address payable _target) external;

    function setKycWhitelists(address[] calldata _address, bool _value)
        external;

    function setPrivateWhitelists(address[] calldata _address, bool _value)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IPool {
    struct RewardTokenInfo {
        string name;
        address token;
        uint256 amount;
    }
    event Deposit(address indexed sender, uint256 amount);
    event Harvest(address indexed sender, uint256 amount);
    event WithdrawOwner(
        address indexed sender,
        address token,
        uint256 amount,
        uint256 fee
    );
    event SetVesting(
        uint256 delayDuration,
        uint256 availiableImmediately,
        uint256 percentagePerBlock,
        uint256 blockDuration,
        uint256[] percentagePerMonth
    );
    event AddRewardToken(RewardTokenInfo info);
    event EmergencyCall(address indexed sender);
    event SetTotalRaise(uint256 amount);

    function balanceOf(address _recipient) external returns (uint256);

    function getVestingInfo()
        external
        returns (
            uint256 delay,
            uint256 availiableInStart,
            uint256 percentPerBlock,
            uint256 timeUnitDuration,
            uint256[] memory percentPerMonth
        );

    function getRewardsTokenInfo()
        external
        returns (RewardTokenInfo[] memory rewardsInfo);

    function harvest() external;

    function addRewardToken(
        RewardTokenInfo calldata info,
        uint256 _id,
        bool _isUpdate
    ) external;

    function setTotalRaise(uint256 _amount) external;

    function withdrawContributions() external;

    function emergencyFunction() external;

    function setVesting(
        uint256 _delayDuration,
        uint256 _availiableImmediately,
        uint256 _percentagePerBlock,
        uint256 _blockDuration,
        uint256[] calldata _percentagePerMonth
    ) external;
}