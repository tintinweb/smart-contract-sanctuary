pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../management/Managed.sol";
import "../management/Constants.sol";
import "../interfaces/factorys/IGenesisStakeFactory.sol";
import "../interfaces/stakings/IGenesisStaking.sol";
import "../stakings/GenesisStaking.sol";

contract GenesisStakeFactory is IGenesisStakeFactory, Managed {
    using SafeMath for uint256;
    using Math for uint256;

    uint256 public blockPerDay = 6450;

    mapping(address => uint256) public stakingIndex;
    mapping(address => address[]) public ownerStakes;
    mapping(address => mapping(address => uint256)) ownerIndex;

    address[] public staking;

    modifier canCreate() {
        require(
            hasPermission(_msgSender(), ROLE_ADMIN) ||
                hasPermission(_msgSender(), ROLE_REGULAR),
            "You don't have permission's"
        );
        _;
    }

    modifier canChange(address stakingAddr) {
        require(
            hasPermission(_msgSender(), ROLE_ADMIN) ||
                (hasPermission(_msgSender(), ROLE_REGULAR) &&
                    ownerIndex[msg.sender][stakingAddr] != 0),
            "You don't have permission's"
        );
        _;
    }

    constructor(address _management) Managed(_management) {}

    function list(uint256 _offset, uint256 _limit)
        external
        view
        override
        returns (address[] memory result)
    {
        uint256 to = (_offset.add(_limit)).min(staking.length).max(_offset);

        result = new address[](to - _offset);

        for (uint256 i = _offset; i < to; i++) {
            result[i - _offset] = staking[i];
        }
    }

    function getBlockPerDay() external view override returns (uint256) {
        return blockPerDay;
    }

    function listByUser(
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view override returns (address[] memory result) {
        uint256 to =
            (_offset.add(_limit)).min(ownerStakes[_user].length).max(_offset);

        result = new address[](to - _offset);

        for (uint256 i = _offset; i < to; i++) {
            result[i - _offset] = ownerStakes[_user][i];
        }
    }

    function createGenesisStaking(
        string memory _stakingName,
        bool _isETHStake,
        bool _isPrivate,
        address _stakedToken,
        uint256 _startBlock,
        uint256 _duration
    ) external override canCreate {
        GenesisStaking stake =
            new GenesisStaking(
                address(management),
                _stakingName,
                _isETHStake,
                _isPrivate,
                false,
                _stakedToken,
                _startBlock,
                _duration,
                PERCENTAGE_1
            );

        address stakeAddress = address(stake);
        ownerStakes[msg.sender].push(stakeAddress);
        ownerIndex[msg.sender][stakeAddress] = ownerStakes[msg.sender].length;
        staking.push(stakeAddress);
        stakingIndex[stakeAddress] = staking.length;

        emit CreateStaking(_msgSender(), address(stake));
    }

    function add(address _owner, address _addr)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        require(
            ownerIndex[_owner][_addr] == 0,
            "GF: Owner already has this staking"
        );

        staking.push(_addr);
        stakingIndex[_addr] = staking.length;

        ownerStakes[_owner].push(_addr);
        ownerIndex[_owner][_addr] = ownerStakes[_owner].length;
    }

    function remove(address _owner, address _addr)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        delete staking[stakingIndex[_addr]];
        delete stakingIndex[_addr];
        delete ownerStakes[_owner][ownerIndex[_owner][_addr]];
        delete ownerIndex[_owner][_addr];
    }

    function setDepositeFee(address _addr, uint256 _amount)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        IGenesisStaking(_addr).setDepositeFee(_amount);
        emit DepositFeeChange(_msgSender(), _addr, _amount);
    }

    function setBlockPerDay(uint256 _amount)
        external
        override
        requirePermission(ROLE_ADMIN)
    {
        blockPerDay = _amount;
        emit BlockPerDayChange(_msgSender(), _amount);
    }

    function setCanTakeReward(address _addr, bool _value)
        external
        override
        canChange(_addr)
    {
        IGenesisStaking(_addr).setCanTakeReward(_value);
        emit SetCanTakeRewardChange(_msgSender(), _addr, _value);
    }

    function setPrivate(address _addr, bool _value)
        external
        override
        canChange(_addr)
    {
        IGenesisStaking(_addr).setPrivate(_value);
        emit PrivateSet(_msgSender(),_addr, _value);
    }

    function setSettingReward(
        address _addr,
        address[] memory _rewardTokens,
        uint256[] memory _rewardPerBlock
    ) external canChange(_addr) {
        require(
            (_rewardTokens.length == _rewardPerBlock.length),
            "GF: Reward settings are incorrect"
        );

        IGenesisStaking genesisStaking = IGenesisStaking(_addr);
        uint256 startBlock;
        uint256 rewardEndBlock;
        uint256 rewardMustBePaid;
        (startBlock, rewardEndBlock) = genesisStaking.getTimePoint();
        startBlock = Math.max(block.number, startBlock);

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            rewardMustBePaid = genesisStaking.getMustBePaid(_rewardTokens[i]);
            _calculateAndTransfer(
                _rewardTokens[i],
                address(genesisStaking),
                rewardEndBlock,
                startBlock,
                _rewardPerBlock[i],
                rewardMustBePaid
            );
        }

        genesisStaking.setRewardSetting(_rewardTokens, _rewardPerBlock);
    }

    function takeNotUseTokens(address _addr, address _token)
        external
        override
        canChange(_addr)
    {
        IGenesisStaking(_addr).takeNotUseTokens(_token, msg.sender);
        emit TakeTokenFromStaking(msg.sender, _addr, _token);
    }

    function _calculateAndTransfer(
        address token,
        address stakingAddr,
        uint256 rewardEndBlock,
        uint256 startBlock,
        uint256 rewardPerBlock,
        uint256 rewardMustBePaid
    ) internal {
        uint256 needTokens = rewardEndBlock.sub(startBlock).mul(rewardPerBlock);

        uint256 balance =
            IERC20(token).balanceOf(stakingAddr).sub(rewardMustBePaid);
        uint256 amount = needTokens.sub(balance);
        if (needTokens < balance) {
            amount = balance.sub(needTokens);
        }
        IERC20(token).transferFrom(stakingAddr, msg.sender, amount);
    }
}

pragma solidity ^0.8.0;

interface IFactoryInfo {
    event SetCanTakeRewardChange(
        address indexed sender,
        address staking,
        bool amount
    );

    event Approve(address indexed sender, address staking);
    event Remove(address indexed sender, address staking);

    event DepositFeeChange(
        address indexed sender,
        address staking,
        uint256 amount
    );

    event BlockPerDayChange(address indexed sender, uint256 amount);
    event PrivateSet(address indexed sender, address staking, bool value);

    event TakeTokenFromStaking(
        address indexed user,
        address staking,
        address token
    );

    function list(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory result);

    function listByUser(
        address _user,
        uint256 _offset,
        uint256 _limit
    ) external view returns (address[] memory result);

    function getBlockPerDay() external view returns (uint256);

    function add(address _owner, address _addr) external;

    function remove(address _owner, address _addr) external;

    function setDepositeFee(address _addr, uint256 _amount) external;

    function setBlockPerDay(uint256 _amount) external;

    function setCanTakeReward(address _addr, bool _value) external;

    function takeNotUseTokens(address _addr, address _token) external;

    function setPrivate(address _addr, bool _value) external;
}

pragma solidity ^0.8.0;
import "./IFactoryInfo.sol";

interface IGenesisStakeFactory is IFactoryInfo {
    event CreateStaking(address indexed sender, address staking);

    function createGenesisStaking(
        string memory _stakingName,
        bool _isETHStake,
        bool _isPrivate,
        address _stakedToken,
        uint256 _startBlock,
        uint256 _duration
    ) external;
}

pragma solidity ^0.8.0;

import "./IStakeInfoAndHarvest.sol";

interface IGenesisStaking is IStakeInfoAndHarvest {
    struct RewardInfo {
        uint256 rewardPerBlock;
        uint256 rewardPerTokenStore;
        uint256 rewardMustBePaid;
        mapping(address => uint256) rewardsPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    function stakeETH() external payable;

    function stake(uint256 _amount) external;

    function setRewardSetting(
        address[] memory _rewardToken,
        uint256[] memory _rewardPerBlock
    ) external;
}

pragma solidity ^0.8.0;

interface IStakeInfoAndHarvest {
    event Staked(address indexed user, uint256 amount, uint256 fee);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address token, uint256 reward);
    event TakeTokenFromStaking(
        address indexed user,
        address token,
        uint256 amount
    );

    function getPoolShare(address recipient)
        external
        view
        returns (uint256 _percentage);

    function getTotalStaked() external view returns (uint256);

    function balanceOf(address _recipient) external view returns (uint256);

    function getAPY()
        external
        view
        returns (address[] memory tokens, uint256[] memory amount);

    function getAvailHarvest(address recipient)
        external
        view
        returns (address[] memory tokens, uint256[] memory availRewards);

    function unstake(uint256 _amount) external;

    function harvest() external;

    function harvestFor(address _recipient) external;

    function setDepositeFee(uint256 amount_) external;

    function setCanTakeReward(bool value_) external;

    function setPrivate(bool value_) external;

    function takeNotUseTokens(address _token, address _recipient) external;

    function setRewardEndBlock(uint256 _rewardEndBlock) external;

    function getTimePoint() external view returns (uint256 startBlock, uint256 endBlock);

    function getMustBePaid(address _rewardTokens)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.0;

uint256 constant DECIMALS = 18;
uint256 constant SECONDS_IN_WEEKS = 1 weeks;
uint256 constant UNITS = 1_000_000_000_000_000_000;
uint256 constant MAX_UINT256 = 2**256 - 1;
uint256 constant PERCENTAGE_100  = 10000;
uint256 constant PERCENTAGE_1  = 100;

bytes4 constant InterfaceId_ERC721 = 0x80ac58cd;

string  constant ERROR_ACCESS_DENIED = "ERROR_ACCESS_DENIED";
string  constant ERROR_NO_CONTRACT = "ERROR_NO_CONTRACT";
string  constant ERROR_NOT_AVAILABLE = "ERROR_NOT_AVAILABLE";

//permisionss
//WHITELIST
uint256 constant ROLE_ADMIN = 1;
uint256 constant ROLE_REGULAR = 5;

uint256 constant CAN_SET_KYC_WHITELISTED = 10;
uint256 constant CAN_SET_PRIVATE_WHITELISTED = 11;



uint256 constant WHITELISTED_KYC = 20;
uint256 constant WHITELISTED_PRIVATE = 21;


uint256 constant CAN_TRANSFER_NFT = 30;

//CONTRACT_CODE
uint256 constant CONTRACT_MANAGEMENT = 0;
uint256 constant CONTRACT_KAISHI_TOKEN = 1;
uint256 constant CONTRACT_STAKE_FACTORY = 2;
uint256 constant CONTRACT_NFT_FACTORY = 3;
uint256 constant CONTRACT_TRESUARY = 4;
uint256 constant CONTRACT_LIQUIDITY_MINING_FACTORY = 5;

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Constants.sol";
import "./Management.sol";

contract Managed is Ownable {
    using SafeMath for uint256;

    Management public management;

    modifier requirePermission(uint256 _permissionBit) {
        require(
            hasPermission(msg.sender, _permissionBit),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireKYCWhitelist() {
        require(
            hasPermission(msg.sender, WHITELISTED_KYC),
            ERROR_ACCESS_DENIED
        );
        _;
    }
    modifier requirePrivateWhitelist(bool _isPrivate) {
        if (_isPrivate) {
            require(
                hasPermission(msg.sender, WHITELISTED_PRIVATE),
                ERROR_ACCESS_DENIED
            );
        }
        _;
    }

    modifier canCallOnlyRegisteredContract(uint256 _key) {
        require(
            msg.sender == management.contractRegistry(_key),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireContractExistsInRegistry(uint256 _key) {
        require(
            management.contractRegistry(_key) != address(0),
            ERROR_NO_CONTRACT
        );
        _;
    }

    constructor(address _managementAddress) {
        management = Management(_managementAddress);
    }

    function setManagementContract(address _management) public onlyOwner {
        require(address(0) != _management, ERROR_NO_CONTRACT);

        management = Management(_management);
    }

    function hasPermission(address _subject, uint256 _permissionBit)
        internal
        view
        returns (bool)
    {
        return management.permissions(_subject, _permissionBit);
    }

}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Constants.sol";

contract Management is Ownable {
    using SafeMath for uint256;

    // Contract Registry
    mapping(uint256 => address payable) public contractRegistry;

    // Permissions
    mapping(address => mapping(uint256 => bool)) public permissions;

    event PermissionsSet(address subject, uint256[] permissions, bool value);

    event UsersPermissionsSet(
        address[] subject,
        uint256 permissions,
        bool[] value
    );

    event PermissionSet(address subject, uint256 permission, bool value);

    event ContractRegistered(uint256 key, address source, address target);

    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    ) public onlyOwner {
        permissions[_address][_permission] = _value;
        emit PermissionSet(_address, _permission, _value);
    }

    function setPermissions(
        address _address,
        uint256[] memory _permissions,
        bool _value
    ) public onlyOwner {
        for (uint256 i = 0; i < _permissions.length; i++) {
            permissions[_address][_permissions[i]] = _value;
        }
        emit PermissionsSet(_address, _permissions, _value);
    }

    function registerContract(uint256 _key, address payable _target)
        public
        onlyOwner
    {
        contractRegistry[_key] = _target;
        emit ContractRegistered(_key, address(0), _target);
    }

    function setKycWhitelist(address _address, bool _value) public {
        require(
            permissions[msg.sender][CAN_SET_KYC_WHITELISTED] == true,
            ERROR_ACCESS_DENIED
        );

        permissions[_address][WHITELISTED_KYC] = _value;

        emit PermissionSet(_address, WHITELISTED_KYC, _value);
    }

    function setPrivateWhitelist(address _address, bool _value) public {
        require(
            permissions[msg.sender][CAN_SET_PRIVATE_WHITELISTED] == true,
            ERROR_ACCESS_DENIED
        );

        permissions[_address][WHITELISTED_PRIVATE] = _value;

        emit PermissionSet(_address, WHITELISTED_PRIVATE, _value);
    }

    function setKycWhitelists(address[] memory _address, bool[] memory _value)
        public
    {
        require(
            permissions[msg.sender][CAN_SET_KYC_WHITELISTED] == true,
            ERROR_ACCESS_DENIED
        );
        require(
            _address.length == _value.length,
            "Management: The length of the address does not match the length values"
        );
        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_KYC] = _value[i];
        }
        emit UsersPermissionsSet(_address, WHITELISTED_KYC, _value);
    }

    function setPrivateWhitelists(address[] memory _address, bool[] memory _value) public {
        require(
            permissions[msg.sender][CAN_SET_PRIVATE_WHITELISTED] == true,
            ERROR_ACCESS_DENIED
        );
        require(
            _address.length == _value.length,
            "Management: The length of the address does not match the length values"
        );
        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_PRIVATE] = _value[i];
        }
        emit UsersPermissionsSet(_address, WHITELISTED_PRIVATE, _value);
    }
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/stakings/IGenesisStaking.sol";
import "../interfaces/factorys/IGenesisStakeFactory.sol";
import "../management/Managed.sol";
import "../management/Constants.sol";

contract GenesisStaking is IGenesisStaking, Managed {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address[] public rewardTokenAddress;
    mapping(address => uint256) public rewardTokenAddressIndex;

    mapping(address => RewardInfo) public rewardsInfo;
    mapping(address => uint256) public staked;

    string public name;

    bool public isPrivate;
    bool public isETHStake;
    bool public canTakeReward;

    uint256 public startBlock;

    uint256 public depositFee;

    uint256 public totalStaked;
    uint256 public lastUpdateBlock;
    address public stakedToken;
    uint256 public rewardEndBlock;

    modifier updateRewards(address addr) {
        _updateRewards(addr);
        _;
    }

    modifier canHarvest() {
        require(canTakeReward, "GS: It is not allowed to take the reward");
        _;
    }

    modifier canStake(bool value) {
        require(value, "GS: contract get only eth");
        _;
    }

    constructor(
        address _management,
        string memory _stakingName,
        bool _isETHStake,
        bool _isPrivate,
        bool _canTakeReward,
        address _stakedToken,
        uint256 _startBlock,
        uint256 _durationBlock,
        uint256 _depositFee
    ) Managed(_management) {
        name = _stakingName;
        startBlock = _startBlock;
        rewardEndBlock = startBlock.add(_durationBlock);

        lastUpdateBlock = block.number;
        isPrivate = _isPrivate;
        canTakeReward = _canTakeReward;
        depositFee = _depositFee;
        stakedToken = _stakedToken;
        isETHStake = _isETHStake;
    }

    function getAPY()
        external
        view
        override
        returns (address[] memory tokens, uint256[] memory amount)
    {
        uint256 size = rewardTokenAddress.length;
        tokens = new address[](size);
        amount = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            address token = rewardTokenAddress[i];
            tokens[i] = token;
            amount[i] = totalStaked == 0 ? totalStaked : _calculateAPY(token);
        }
    }

    function getTimePoint() external view override returns (uint256, uint256) {
        return (startBlock, rewardEndBlock);
    }

    function getMustBePaid(address _addr)
        external
        view
        override
        returns (uint256)
    {
        return _getRewardMustBePaid(_addr);
    }

    function getAvailHarvest(address recipient)
        external
        view
        override
        returns (address[] memory tokens, uint256[] memory rewards)
    {
        uint256 length = rewardTokenAddress.length;
        tokens = new address[](length);
        rewards = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            address token = rewardTokenAddress[i];
            RewardInfo storage info = rewardsInfo[token];
            uint256 newRewardPerTokenStore =
                _calculateNewRewardPerTokenStore(info);
            uint256 calculateRewards =
                info.rewards[recipient].add(
                    _calculateEarnedRewards(
                        recipient,
                        info.rewardsPerTokenPaid[recipient],
                        newRewardPerTokenStore
                    )
                );
            tokens[i] = token;
            rewards[i] = calculateRewards;
        }
    }

    function getTotalStaked() external view override returns (uint256) {
        return totalStaked;
    }

    function getPoolShare(address recipient)
        external
        view
        override
        returns (uint256 percentage)
    {
        if (totalStaked == 0) return 0;
        return staked[recipient].mul(UNITS).div(totalStaked);
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return staked[addr];
    }

    function setDepositeFee(uint256 amount_)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKE_FACTORY)
    {
        depositFee = amount_;
    }

    function setCanTakeReward(bool value_)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKE_FACTORY)
    {
        canTakeReward = value_;
    }

    function stakeETH() external payable override canStake(isETHStake) {
        _stake(_msgSender(), msg.value);
    }

    function stake(uint256 _amount) external override canStake(!isETHStake) {
        _stake(_msgSender(), _amount);
    }

    function unstake(uint256 _amount)
        external
        override
        updateRewards(_msgSender())
    {
        require(_amount > 0, "GS: Amount should be greater than 0");
        require(
            staked[_msgSender()] >= _amount,
            "GS: Insufficient staked amount"
        );

        staked[_msgSender()] = staked[_msgSender()].sub(_amount);
        totalStaked = totalStaked.sub(_amount);

        address payable recipient = payable(_msgSender());
        if (isETHStake) {
            recipient.transfer(_amount);
        } else {
            IERC20(stakedToken).transfer(recipient, _amount);
        }

        emit Withdrawn(_msgSender(), _amount);
    }

    function setPrivate(bool value_)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKE_FACTORY)
    {
        isPrivate = value_;
    }

    function harvest()
        external
        override
        canHarvest
        updateRewards(_msgSender())
    {
        _harvest(msg.sender);
    }

    function harvestFor(address recipient)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKE_FACTORY)
        canHarvest
        updateRewards(recipient)
    {
        _harvest(recipient);
    }

    function setRewardEndBlock(uint256 _rewardEndBlock)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKE_FACTORY)
    {
        rewardEndBlock = _rewardEndBlock;
    }

    function setRewardSetting(
        address[] memory _rewardToken,
        uint256[] memory _rewardPerBlock
    )
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKE_FACTORY)
        updateRewards(address(0))
    {
        _setRewardSetting(_rewardToken, _rewardPerBlock);
    }

    function takeNotUseTokens(address _token, address _recipient)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKE_FACTORY)
    {
        require(_token != stakedToken, "Can'ot get staked token");
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        if (rewardTokenAddressIndex[_token] == 0) {
            IERC20(_token).transfer(_recipient, _amount);
        } else {
            uint256 notUseRewards = _getRewardMustBePaid(_token);
            IERC20(_token).transfer(_recipient, notUseRewards);
        }
        emit TakeTokenFromStaking(_recipient, _token, _amount);
    }

    function _stake(address _addr, uint256 _amount)
        internal
        requireKYCWhitelist()
        requirePrivateWhitelist(isPrivate)
        updateRewards(_addr)
    {
        uint256 value = _amount;

        require(value > 0, "GS: Amount should be greater than 0");

        uint256 fee = 0;
        if (depositFee > 0) {
            fee = value.mul(depositFee).div(PERCENTAGE_100);
            value = value.sub(fee);
            management.contractRegistry(CONTRACT_TRESUARY).transfer(fee);
        }

        staked[_addr] = staked[_addr].add(value);
        totalStaked = totalStaked.add(value);

        emit Staked(_addr, value, fee);
    }

    function _setRewardSetting(
        address[] memory _rewardToken,
        uint256[] memory _rewardPerBlock
    ) internal {
        address factory = management.contractRegistry(CONTRACT_STAKE_FACTORY);
        for (uint256 i = 0; i < _rewardToken.length; i++) {
            address token = _rewardToken[i];
            if (rewardTokenAddressIndex[token] == 0) {
                rewardTokenAddress.push(token);
                rewardTokenAddressIndex[token] = rewardTokenAddress.length;
                IERC20(token).approve(factory, MAX_UINT256);
            }
            RewardInfo storage rewType = rewardsInfo[token];
            rewType.rewardPerBlock = _rewardPerBlock[i];
        }
    }

    function _harvest(address recipient) internal {
        for (uint256 i = 0; i < rewardTokenAddress.length; i++) {
            address token = rewardTokenAddress[i];
            RewardInfo storage info = rewardsInfo[token];
            uint256 rewards = info.rewards[recipient];
            if (rewards > 0) {
                info.rewards[recipient] = info.rewards[recipient].sub(rewards);
                IERC20(token).transfer(recipient, rewards);
                emit RewardPaid(recipient, token, rewards);
            }
        }
    }

    function _updateRewards(address recipient) internal {
        for (uint256 i = 0; i < rewardTokenAddress.length; i++) {
            RewardInfo storage info = rewardsInfo[rewardTokenAddress[i]];
            uint256 newRewardPerTokenStore =
                _calculateNewRewardPerTokenStore(info);
            if (info.rewardPerTokenStore != newRewardPerTokenStore) {
                info.rewardPerTokenStore = newRewardPerTokenStore;
            }
            if (totalStaked > 0) {
                info.rewardMustBePaid = info.rewardMustBePaid.add(
                    _calculateBlocksLeft().mul(info.rewardPerBlock)
                );
            }

            if (recipient != address(0)) {
                info.rewards[recipient] = info.rewards[recipient].add(
                    _calculateEarnedRewards(
                        recipient,
                        info.rewardsPerTokenPaid[recipient],
                        newRewardPerTokenStore
                    )
                );
            }
        }
        lastUpdateBlock = block.number;
    }

    function _calculateNewRewardPerTokenStore(RewardInfo storage info)
        internal
        view
        returns (uint256)
    {
        uint256 blockPassted = _calculateBlocksLeft();

        if (blockPassted == 0 || totalStaked == 0)
            return info.rewardPerTokenStore;

        uint256 accumulativeRewardPerToken =
            blockPassted.mul(info.rewardPerBlock).mul(UNITS).div(totalStaked);
        return info.rewardPerTokenStore.add(accumulativeRewardPerToken);
    }

    function _calculateAPY(address addr) internal view returns (uint256) {
        RewardInfo storage info = rewardsInfo[addr];
        if (
            startBlock > block.number ||
            rewardEndBlock < block.number ||
            info.rewardPerBlock == 0
        ) return 0;
        uint256 blockPerDay =
            IGenesisStakeFactory(
                management.contractRegistry(CONTRACT_STAKE_FACTORY)
            )
                .getBlockPerDay();

        return
            info.rewardPerBlock.mul(UNITS).mul(blockPerDay).mul(365).div(
                totalStaked
            );
    }

    function _calculateEarnedRewards(
        address recipient,
        uint256 rewardsPerTokenPaid,
        uint256 newRewardPerTokenStore
    ) internal view returns (uint256) {
        uint256 rewardPerToken =
            newRewardPerTokenStore.sub(rewardsPerTokenPaid);
        return rewardPerToken.mul(staked[recipient]).div(UNITS);
    }

    function _getRewardMustBePaid(address _addr)
        internal
        view
        returns (uint256)
    {
        RewardInfo storage info = rewardsInfo[_addr];
        return
            info.rewardMustBePaid.add(
                _calculateBlocksLeft().mul(info.rewardPerBlock)
            );
    }

    function _calculateBlocksLeft() internal view returns (uint256) {
        uint256 blockNumber = block.number;
        if (startBlock > blockNumber || lastUpdateBlock > rewardEndBlock)
            return 0;

        if (blockNumber > rewardEndBlock) {
            blockNumber = rewardEndBlock;
        }
        return blockNumber.sub(lastUpdateBlock);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

