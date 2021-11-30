// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IGenesisStaking.sol";
import "./management/ManagedUpgradeable.sol";
import "./management/Constants.sol";
import "./libraries/DecimalsConverter.sol";

contract GenesisStaking is IGenesisStaking, ManagedUpgradeable {
    using DecimalsConverter for uint256;

    address[] public rewardTokenAddress;
    mapping(address => RewardInfo) public rewardsInfo;

    string internal _name;
    bool internal _canTakeReward;
    bool internal _isPrivate;
    bool internal _isKYC;
    uint256 internal _startBlock;
    uint256 internal _totalStaked;
    uint256 internal _rewardEndBlock;
    uint256 internal _lastUpdateBlock;
    uint256 internal _depositFee;
    address internal _stakedToken;
    address payable internal _tresuary;
    mapping(address => uint256) internal _staked;
    mapping(address => uint256) internal _decimals;

    modifier canStake(
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        if (_isPrivate) {
            require(
                _hasPermission(_msgSender(), MANAGEMENT_WHITELISTED_PRIVATE),
                ERROR_ACCESS_DENIED
            );
        }
        if (_isKYC) {
            require(
                management.isKYCPassed(_msgSender(), _deadline, _v, _r, _s),
                ERROR_KYC_MISSING
            );
        }
        _;
    }

    modifier requireAccess() {
        require(
            management.requireAccess(_msgSender(), address(this)),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    function initialize(
        address management_,
        string memory name_,
        bool isETHStake_,
        bool isPrivate_,
        bool canTakeReward_,
        address stakedToken_,
        uint256 startBlock_,
        uint256 durationBlock_,
        uint256 depositFee_
    ) external initializer {
        require(
            isETHStake_ || stakedToken_ != address(0),
            ERROR_INVALID_ADDRESS
        );
        _name = name_;
        _startBlock = startBlock_ < block.number ? block.number : startBlock_;
        _rewardEndBlock = _startBlock + durationBlock_;
        _lastUpdateBlock = _startBlock;
        _isPrivate = isPrivate_;
        _canTakeReward = canTakeReward_;
        _depositFee = depositFee_;
        _stakedToken = stakedToken_;
        if (!isETHStake_) {
            _decimals[stakedToken_] = IERC20Metadata(stakedToken_).decimals();
        }
        __Managed_init(management_);
        _setDependency();
    }

    function getFutureEarn(address _recipient, uint256 _blockPerDay)
        external
        view
        returns (FutureEarnInfo[] memory result)
    {
        result = new FutureEarnInfo[](rewardTokenAddress.length);
        uint256 poolShare = _totalStaked == 0
            ? 0
            : (_staked[_recipient] * DECIMALS18) / _totalStaked;
        for (uint256 i; i < rewardTokenAddress.length; i++) {
            result[i].token = rewardTokenAddress[i];
            uint256 userRewardPerBlock = (rewardsInfo[rewardTokenAddress[i]]
                .rewardPerBlock * poolShare) / DECIMALS18;
            result[i].perDay = _rewardsPerDays(
                _blockPerDay,
                userRewardPerBlock,
                1
            );
            result[i].perWeek = _rewardsPerDays(
                _blockPerDay,
                userRewardPerBlock,
                7
            );
            result[i].perMonth = _rewardsPerDays(
                _blockPerDay,
                userRewardPerBlock,
                30
            );
            result[i].perYear = _rewardsPerDays(
                _blockPerDay,
                userRewardPerBlock,
                365
            );
        }
    }

    function getInfo()
        external
        view
        override
        returns (
            string memory name,
            address stakedToken,
            uint256 startBlock,
            uint256 endBlock,
            bool canTakeRewards,
            bool isPrivate,
            bool isKYC,
            uint256 totalStaked,
            uint256 depositeFee
        )
    {
        name = _name;
        stakedToken = _stakedToken;
        startBlock = _startBlock;
        endBlock = _rewardEndBlock;
        canTakeRewards = _canTakeReward;
        isPrivate = _isPrivate;
        isKYC = _isKYC;
        totalStaked = _totalStaked;
        depositeFee = _depositFee;
    }

    function getRewardsPerBlockInfos()
        external
        view
        override
        returns (address[] memory rewardTokens, uint256[] memory rewardPerBlock)
    {
        uint256 length = rewardTokenAddress.length;
        rewardTokens = new address[](length);
        rewardPerBlock = new uint256[](length);
        for (uint256 i; i < length; i++) {
            address token = rewardTokenAddress[i];
            rewardTokens[i] = token;
            rewardPerBlock[i] = rewardsInfo[token].rewardPerBlock;
        }
    }

    function getAvailHarvest(address _recipient)
        external
        view
        override
        returns (address[] memory tokens, uint256[] memory rewards)
    {
        uint256 length = rewardTokenAddress.length;
        tokens = new address[](length);
        rewards = new uint256[](length);
        for (uint256 i; i < length; i++) {
            RewardInfo storage info = rewardsInfo[rewardTokenAddress[i]];
            uint256 newRewardPerTokenStore = _calculateNewRewardPerTokenStore(
                info.rewardPerBlock,
                info.rewardPerTokenStore
            );
            tokens[i] = rewardTokenAddress[i];
            rewards[i] =
                info.rewards[_recipient] +
                ((newRewardPerTokenStore -
                    info.rewardsPerTokenPaid[_recipient]) *
                    _staked[_recipient]) /
                DECIMALS18;
        }
    }

    function balanceOf(address _recipient)
        external
        view
        override
        returns (uint256)
    {
        return _staked[_recipient];
    }

    function harvest() external override {
        _harvest(_msgSender());
    }

    function harvestFor(address _recipient) external override {
        _harvest(_recipient);
    }

    function stakeETH(
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable override {
        require(_stakedToken == address(0), ERROR_INCORRECT_CALL_METHOD);
        _stake(msg.value, _deadline, _v, _r, _s);
    }

    function stake(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        require(_stakedToken != address(0), ERROR_INCORRECT_CALL_METHOD);
        _stake(_amount, _deadline, _v, _r, _s);
    }

    function unstake(uint256 _amount) external override {
        require(_amount > 0, ERROR_AMOUNT_IS_ZERO);
        require(_staked[_msgSender()] >= _amount, ERROR_AMOUNT_IS_MORE_TS);
        _updateRewards(_msgSender());
        _staked[_msgSender()] -= _amount;
        _totalStaked -= _amount;
        if (_stakedToken == address(0)) {
            _sendValue(_msgSender(), _amount);
        } else {
            _transfer(_stakedToken, _msgSender(), _amount);
        }
        emit Withdrawn(_msgSender(), _amount);
    }

    function setCanTakeReward(bool value_) external override requireAccess {
        _canTakeReward = value_;
    }

    function addDurartion(uint256 _blockAmount)
        external
        override
        requireAccess
    {
        for (uint256 i; i < rewardTokenAddress.length; i++) {
            RewardInfo storage info = rewardsInfo[rewardTokenAddress[i]];
            if (info.rewardPerBlock > 0) {
                _transferFrom(
                    rewardTokenAddress[i],
                    info.rewardPerBlock * _blockAmount
                );
            }
        }
        _rewardEndBlock += _blockAmount;
        emit AddDuration(_blockAmount);
    }

    function setRewardSetting(
        address[] memory _rewardTokens,
        uint256[] memory _rewardPerBlock
    ) external override requireAccess {
        require(
            _rewardTokens.length == _rewardPerBlock.length,
            ERROR_DIFF_ARR_LENGTH
        );
        _updateRewards(address(0));
        for (uint256 i; i < _rewardTokens.length; i++) {
            address token = _rewardTokens[i];
            uint256 newRewardPerBlock = _rewardPerBlock[i];
            RewardInfo storage info = rewardsInfo[token];
            if (!info.isExists) {
                _decimals[token] = IERC20Metadata(token).decimals();
                rewardTokenAddress.push(token);
                info.isExists = true;
            }
            uint256 amount = _calculateNeedReward(
                info.rewardPerBlock,
                newRewardPerBlock
            );
            info.rewardPerBlock = newRewardPerBlock;
            if (amount > 0) {
                _transferFrom(token, amount);
            }
        }
        emit SetRewardSetting(_rewardTokens, _rewardPerBlock);
    }

    function setDepositeFee(uint256 amount_)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        require(amount_ < MAX_FEE_PERCENTAGE, ERROR_MORE_THEN_MAX);
        _depositFee = amount_;
    }

    function setKYC(bool value_)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        _isKYC = value_;
    }

    function setPrivate(bool value_)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        _isPrivate = value_;
    }

    function setDependency()
        external
        override
        requirePermission(GENERAL_CAN_UPDATE_DEPENDENCY)
    {
        _setDependency();
    }

    function _calculateNeedReward(
        uint256 _oldRewardPerBlock,
        uint256 _newRewardPerBlock
    ) internal view returns (uint256) {
        uint256 blockNumber = block.number;
        if (
            _rewardEndBlock > blockNumber &&
            _newRewardPerBlock > _oldRewardPerBlock
        ) {
            uint256 rewardStartBlock = blockNumber < _startBlock
                ? _startBlock
                : block.number;
            return
                (_rewardEndBlock - rewardStartBlock) *
                (_newRewardPerBlock - _oldRewardPerBlock);
        } else {
            return 0;
        }
    }

    function _setDependency() internal {
        _tresuary = management.contractRegistry(ADDRESS_TRESUARY);
    }

    function _stake(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal canStake(_deadline, _v, _r, _s) {
        require(_amount > 0, ERROR_AMOUNT_IS_ZERO);
        _updateRewards(_msgSender());
        uint256 fee;
        if (_depositFee > 0) {
            fee = (_amount * _depositFee) / PERCENTAGE_100;
            _amount -= fee;
            if (_stakedToken == address(0)) {
                _sendValue(_tresuary, fee);
            } else {
                _transferFrom(_stakedToken, fee);
            }
        }
        if (_stakedToken != address(0)) {
            _transferFrom(_stakedToken, _amount);
        }
        _staked[_msgSender()] += _amount;
        _totalStaked += _amount;
        emit Staked(_msgSender(), _amount, fee);
    }

    function _harvest(address _recipient) internal {
        require(_canTakeReward, ERROR_METHOD_DISABLE);
        _updateRewards(_recipient);
        for (uint256 i; i < rewardTokenAddress.length; i++) {
            address token = rewardTokenAddress[i];
            RewardInfo storage info = rewardsInfo[token];
            uint256 rewards = info.rewards[_recipient];
            if (rewards > 0) {
                info.rewards[_recipient] -= rewards;
                _transfer(token, _recipient, rewards);
                emit RewardPaid(_recipient, token, rewards);
            }
        }
    }

    function _updateRewards(address _recipient) internal {
        for (uint256 i; i < rewardTokenAddress.length; i++) {
            RewardInfo storage info = rewardsInfo[rewardTokenAddress[i]];
            uint256 newRewardPerToken = _calculateNewRewardPerTokenStore(
                info.rewardPerBlock,
                info.rewardPerTokenStore
            );
            info.rewardPerTokenStore = newRewardPerToken;
            if (_recipient != address(0)) {
                info.rewards[_recipient] +=
                    ((newRewardPerToken -
                        info.rewardsPerTokenPaid[_recipient]) *
                        _staked[_recipient]) /
                    DECIMALS18;
                info.rewardsPerTokenPaid[_recipient] = newRewardPerToken;
            }
        }
        _lastUpdateBlock = block.number;
    }

    function _calculateNewRewardPerTokenStore(
        uint256 _rewardPerBlock,
        uint256 _rewardPerTokenStore
    ) internal view returns (uint256) {
        uint256 blockPassted = _calculateBlocksPassted();
        if (blockPassted == 0 || _totalStaked == 0) {
            return _rewardPerTokenStore;
        } else {
            return
                _rewardPerTokenStore +
                (blockPassted * _rewardPerBlock * DECIMALS18) /
                _totalStaked;
        }
    }

    function _sendValue(address recipient, uint256 amount) internal {
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, ERROR_SEND_VALUE);
    }

    function _calculateBlocksPassted() internal view returns (uint256) {
        uint256 blockNumber = block.number;
        if (
            blockNumber > _lastUpdateBlock && _lastUpdateBlock < _rewardEndBlock
        ) {
            if (blockNumber <= _rewardEndBlock) {
                return blockNumber - _lastUpdateBlock;
            } else {
                return _rewardEndBlock - _lastUpdateBlock;
            }
        } else {
            return 0;
        }
    }

    function _transferFrom(address _token, uint256 _amount) internal {
        require(
            IERC20Metadata(_token).transferFrom(
                _msgSender(),
                address(this),
                _amount.convertFrom18(_decimals[_token])
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
                _amount.convertFrom18(_decimals[_token])
            ),
            ERROR_ERC20_CALL_ERROR
        );
    }

    function _rewardsPerDays(
        uint256 _blockPerDay,
        uint256 _rewardPerBlock,
        uint256 _days
    ) internal view returns (uint256) {
        uint256 blocksToEnd;
        if (_rewardEndBlock > block.number) {
            blocksToEnd =
                _rewardEndBlock -
                (block.number > _startBlock ? block.number : _startBlock);
        }
        return
            (
                blocksToEnd > (_blockPerDay * _days)
                    ? (_blockPerDay * _days)
                    : blocksToEnd
            ) * _rewardPerBlock;
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

pragma solidity ^0.8.9;
import "./IStaking.sol";

interface IGenesisStaking is IStaking {
    struct RewardInfo {
        uint256 rewardPerBlock;
        uint256 rewardPerTokenStore;
        bool isExists;
        mapping(address => uint256) rewardsPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    event SetRewardSetting(address[] rewardToken, uint256[] rewardPerBlock);

    function stakeETH(
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable;

    function addDurartion(uint256 _blockAmount) external;

    function setRewardSetting(
        address[] memory _rewardTokens,
        uint256[] memory _rewardPerBlock
    ) external;
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

interface IStaking {
    struct FutureEarnInfo {
        address token;
        uint256 perDay;
        uint256 perWeek;
        uint256 perMonth;
        uint256 perYear;
    }
    event AddDuration(uint256 blockAmount);
    event Staked(address indexed user, uint256 amount, uint256 fee);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address token, uint256 reward);

    function balanceOf(address _recipient) external view returns (uint256);

    function getInfo()
        external
        view
        returns (
            string memory name,
            address stakedToken,
            uint256 startBlock,
            uint256 endBlock,
            bool canTakeRewards,
            bool isPrivate,
            bool isKYC,
            uint256 totalStaked,
            uint256 depositeFee
        );

    function getAvailHarvest(address _recipient)
        external
        view
        returns (address[] memory tokens, uint256[] memory availRewards);

    function getRewardsPerBlockInfos()
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory rewardPerBlock
        );

    function setDependency() external;

    function stake(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function unstake(uint256 _amount) external;

    function harvest() external;

    function harvestFor(address _recipient) external;

    function setDepositeFee(uint256 amount_) external;

    function setCanTakeReward(bool value_) external;

    function setPrivate(bool value_) external;

    function setKYC(bool value_) external;
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