pragma solidity ^0.8.0;

interface IStakingRegister {
    event SetCanTakeReward(
        address indexed sender,
        address staking,
        bool amount
    );

    event RemoveStaking(address indexed sender, address owner, address staking);
    event CreateStaking(
        address indexed sender,
        address owner,
        address staking,
        bool isLiquidityMining
    );

    event SetDefaultDepositFee(address indexed sender, uint256 amount);

    event SetDepositFee(
        address indexed sender,
        address staking,
        uint256 amount
    );

    event SetPrivate(address indexed sender, address staking, bool value);

    event WithdrawExtraTokensFromStaking(
        address indexed user,
        address staking,
        address token
    );

    event SetRewardSetting(
        address indexed sender,
        address staking,
        address[] rewardTokens,
        uint256[] rewardPerBlock,
        uint256[][] approvedNFTid
    );

    event AddDuration(address indexed sender, address staking, uint256 amount);

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

    function isOwner(address owner, address staking)
        external
        view
        returns (bool);

    function harvestAll(address[] calldata stakings) external;

    function withdrawExtraTokens(address _addr, address _token) external;

    function add(
        address _owner,
        address _stakingAddress,
        bool _isLiquidityMining
    ) external;

    function remove(address _owner, address _addr) external;

    function setDepositeFee(address _addr, uint256 _amount) external;

    function setBlockPerDay(uint256 _amount) external;

    function setCanTakeReward(address _addr, bool _value) external;

    function setPrivate(address _addr, bool _value) external;

    function setDefaultDepositFeePercentage(uint256 _amount) external;

    function getDefaultFeePercentage() external view returns (uint256);

    function addDurationLiquidityMining(
        address _stakingAddress,
        uint256 _blockAmount,
        address[] calldata _rewardTokenAddress,
        uint256[][] calldata _approvedNFTid
    ) external;

    function addDurationGenesisStaking(
        address _stakingAddress,
        uint256 _blockAmount
    ) external;

    function setRewardSettingGenesisStaking(
        address _stakingAddress,
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardPerBlock
    ) external;

    function setRewardSettingLiquidityMining(
        address _stakingAddress,
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardPerBlock,
        uint256[][] calldata _rewardApprovedNFTId
    ) external;
}

pragma solidity ^0.8.0;

interface IStaking {
    event Staked(address indexed user, uint256 amount, uint256 fee);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address token, uint256 reward);
    event WithdrawExtraTokens(
        address indexed user,
        address token,
        uint256 amount
    );

    event SetRewardSetting(address[] rewardToken, uint256[] rewardPerBlock);

    struct RewardInfo {
        uint256 rewardPerBlock;
        uint256 rewardPerTokenStore;
        uint256 rewardMustBePaid;
        mapping(address => uint256) rewardsPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    function balanceOf(address _recipient) external view returns (uint256);

    function getAvailHarvest(address recipient)
        external
        view
        returns (address[] memory tokens, uint256[] memory availRewards);

    function getRewardsPerBlockInfo(address _rewardTokens)
        external
        view
        returns (uint256);

    function getRewardsPerBlockInfos()
        external
        view
        returns (
            address[] memory rewardTokens,
            uint256[] memory rewardPerBlock
        );

    function getTimePoint()
        external
        view
        returns (uint256 startBlock, uint256 endBlock);

    function getMustBePaid(address _rewardTokens)
        external
        view
        returns (uint256);

    function withdrawExtraTokens(address _token, address _recipient) external;

    function stake(uint256 _amount) external;

    function unstake(uint256 _amount) external;

    function harvest() external;

    function harvestFor(address _recipient) external;

    function setDepositeFee(uint256 amount_) external;

    function setCanTakeReward(bool value_) external;

    function setPrivate(bool value_) external;

    function setRewardEndBlock(uint256 _rewardEndBlock) external;

    function setRewardSetting(
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardPerBlock
    ) external;
}

pragma solidity ^0.8.0;

uint256 constant DECIMALS = 18;
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
uint256 constant CAN_MINT_NFT = 31;
uint256 constant CAN_BURN_NFT = 32;

uint256 constant CAN_ADD_STAKING = 43;
uint256 constant CAN_ADD_POOL = 45;

//REGISTER_ADDRESS
uint256 constant CONTRACT_MANAGEMENT = 0;
uint256 constant CONTRACT_KAISHI_TOKEN = 1;
uint256 constant CONTRACT_STAKE_FACTORY = 2;
uint256 constant CONTRACT_NFT_FACTORY = 3;
uint256 constant CONTRACT_LIQUIDITY_MINING_FACTORY = 4;
uint256 constant CONTRACT_STAKING_REGISTER = 5;
uint256 constant CONTRACT_POOL_REGISTER = 6;

uint256 constant ADDRESS_TRESUARY = 10;
uint256 constant ADDRESS_SIGNER = 11;

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
        bool value
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

    function setKycWhitelists(address[] memory _address, bool _value)
        public
    {
        require(
            permissions[msg.sender][CAN_SET_KYC_WHITELISTED] == true,
            ERROR_ACCESS_DENIED
        );

        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_KYC] = _value;
        }
        emit UsersPermissionsSet(_address, WHITELISTED_KYC, _value);
    }

    function setPrivateWhitelists(address[] memory _address, bool _value) public {
        require(
            permissions[msg.sender][CAN_SET_PRIVATE_WHITELISTED] == true,
            ERROR_ACCESS_DENIED
        );

        for (uint256 i = 0; i < _address.length; i++) {
            permissions[_address[i]][WHITELISTED_PRIVATE] = _value;
        }

        emit UsersPermissionsSet(_address, WHITELISTED_PRIVATE, _value);
    }
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/stakings/IStaking.sol";
import "../interfaces/registers/IStakingRegister.sol";
import "../management/Managed.sol";
import "../management/Constants.sol";

contract LiquidityMiningStaking is IStaking, IERC721Receiver, Managed {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.UintSet;

    address[] public rewardTokenAddress;
    mapping(address => uint256) rewardTokenAddressIndex;

    mapping(address => EnumerableSet.UintSet) private approvedNFT;

    mapping(address => RewardInfo) public rewardsInfo;

    mapping(address => uint256) public staked;

    string public name;
    bool public isPrivate;
    bool public canTakeReward;

    uint256 public startBlock;
    uint256 public totalStaked;
    uint256 public lastUpdateBlock;

    uint256 public rewardEndBlock;

    uint256 public depositFee;

    address public stakedToken;

    modifier updateRewards(address addr) {
        _updateRewards(addr);
        _;
    }

    modifier canHarvest() {
        require(canTakeReward, "not allowed");
        _;
    }

    constructor(
        address _management,
        string memory _liquidityMiningName,
        address _stakingToken,
        uint256 _startBlock,
        uint256 _durationBlock,
        bool _isPrivate,
        bool _canTakeReward,
        uint256 _depositFee
    ) Managed(_management) {
        require(_stakingToken != address(0), "can't be zero!");

        name = _liquidityMiningName;
        stakedToken = _stakingToken;
        startBlock = _startBlock;
        rewardEndBlock = startBlock.add(_durationBlock);
        lastUpdateBlock = startBlock;
        isPrivate = _isPrivate;
        canTakeReward = _canTakeReward;
        depositFee = _depositFee;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        if (rewardsInfo[msg.sender].rewardPerBlock == 0) {
            IERC721(msg.sender).setApprovalForAll(
                management.contractRegistry(CONTRACT_STAKING_REGISTER),
                true
            );
        }

        approvedNFT[msg.sender].add(tokenId);

        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function getAPY()
        external
        view
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

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function getPoolShare(address recipient)
        external
        view
        returns (uint256 percentage)
    {
        if (totalStaked == 0) return 0;
        return staked[recipient].mul(UNITS).div(totalStaked);
    }

    function getRewardsPerBlockInfo(address _rewardTokens)
        external
        view
        override
        returns (uint256 rewardPerBlock)
    {
        return rewardsInfo[_rewardTokens].rewardPerBlock;
    }

    function getRewardsPerBlockInfos()
        external
        view
        override
        returns (address[] memory rewardTokens, uint256[] memory rewardPerBlock)
    {
        uint256 size = rewardTokenAddress.length;
        rewardTokens = new address[](size);
        rewardPerBlock = new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            address token = rewardTokenAddress[i];
            rewardTokens[i] = token;
            rewardPerBlock[i] = rewardsInfo[token].rewardPerBlock;
        }
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

    function balanceOf(address addr) external view override returns (uint256) {
        return staked[addr];
    }

    function getApprovedNFTs(address addr)
        external
        view
        returns (uint256[] memory result)
    {
        uint256 length = approvedNFT[addr].length();
        result = new uint256[](length);
        for (uint256 index = 0; index < length; index++) {
            result[index] = approvedNFT[addr].at(index);
        }
    }

    function stake(uint256 _amount)
        external
        override
        requireKYCWhitelist()
        requirePrivateWhitelist(isPrivate)
        updateRewards(_msgSender())
    {
        uint256 value = _amount;
        require(value > 0, "LM: Amount should be greater than 0");

        uint256 fee = 0;

        if (depositFee > 0) {
            fee = value.mul(depositFee).div(PERCENTAGE_100);
            value = value.sub(fee);

            IERC20(stakedToken).safeTransferFrom(
                _msgSender(),
                management.contractRegistry(ADDRESS_TRESUARY),
                fee
            );
        }

        IERC20(stakedToken).safeTransferFrom(
            _msgSender(),
            address(this),
            value
        );

        staked[_msgSender()] = staked[_msgSender()].add(value);
        totalStaked = totalStaked.add(value);

        emit Staked(_msgSender(), value, fee);
    }

    function unstake(uint256 _amount)
        external
        override
        updateRewards(_msgSender())
    {
        require(_amount > 0, "LM: Amount should be greater than 0");
        require(
            staked[_msgSender()] >= _amount,
            "LM: Insufficient staked amount"
        );

        staked[_msgSender()] = staked[_msgSender()].sub(_amount);
        totalStaked = totalStaked.sub(_amount);

        IERC20(stakedToken).safeTransfer(_msgSender(), _amount);

        emit Withdrawn(_msgSender(), _amount);
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
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
        updateRewards(recipient)
    {
        if (canTakeReward) {
            _harvest(recipient);
        }
    }

    function getTimePoint() external view override returns (uint256, uint256) {
        return (startBlock, rewardEndBlock);
    }

    function setDepositeFee(uint256 amount_)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        depositFee = amount_;
    }

    function setRewardEndBlock(uint256 _rewardEndBlock)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        rewardEndBlock = _rewardEndBlock;
    }

    function setCanTakeReward(bool value_)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        canTakeReward = value_;
    }

    function setPrivate(bool value_)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        isPrivate = value_;
    }

    function setRewardSetting(
        address[] calldata _rewardTokens,
        uint256[] calldata _rewardPerBlock
    )
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
        updateRewards(address(0))
    {
        require(
            _rewardTokens.length == _rewardPerBlock.length,
            "LM: Reward settings are incorrect"
        );

        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            _setRewardSetting(_rewardTokens[i], _rewardPerBlock[i]);
        }

        emit SetRewardSetting(_rewardTokens, _rewardPerBlock);
    }

    function withdrawExtraTokens(address _token, address _recipient)
        external
        override
        canCallOnlyRegisteredContract(CONTRACT_STAKING_REGISTER)
    {
        require(_token != stakedToken, "Can'n get staked");

        uint256 _amount = 0;
        if (_token.supportsInterface(InterfaceId_ERC721)) {
            IERC721 erc721 = IERC721(_token);
            _amount = erc721.balanceOf(address(this));
            if (rewardTokenAddressIndex[_token] == 0) {
                for (uint256 index = 0; index < _amount; index++) {
                    erc721.safeTransferFrom(
                        address(this),
                        _recipient,
                        approvedNFT[_token].at(index)
                    );
                    approvedNFT[_token].remove(index);
                }
            } else {
                _amount = _amount.sub(
                    _getRewardMustBePaid(_token).div(UNITS).add(1)
                );
                for (uint256 index = 0; index < _amount; index++) {
                    erc721.safeTransferFrom(
                        address(this),
                        _recipient,
                        approvedNFT[_token].at(index)
                    );
                    approvedNFT[_token].remove(index);
                }
            }
        } else {
            IERC20 erc20 = IERC20(_token);
            _amount = erc20.balanceOf(address(this));
            if (rewardTokenAddressIndex[_token] == 0) {
                erc20.transfer(_recipient, _amount);
            } else {
                _amount = _amount.sub(_getRewardMustBePaid(_token));
                erc20.transfer(_recipient, _amount);
            }
        }
        emit WithdrawExtraTokens(_recipient, _token, _amount);
    }

    function _setRewardSetting(address _rewardToken, uint256 _rewardPerBlock)
        internal
    {
        if (rewardTokenAddressIndex[_rewardToken] == 0) {
            rewardTokenAddress.push(_rewardToken);
            rewardTokenAddressIndex[_rewardToken] = rewardTokenAddress.length;
            address factory =
                management.contractRegistry(CONTRACT_STAKING_REGISTER);
            if (_rewardToken.supportsInterface(InterfaceId_ERC721)) {
                IERC721(_rewardToken).setApprovalForAll(factory, true);
            } else {
                IERC20(_rewardToken).approve(factory, MAX_UINT256);
            }
        }
        RewardInfo storage rewType = rewardsInfo[_rewardToken];
        rewType.rewardPerBlock = _rewardPerBlock;
    }

    function _getRewardMustBePaid(address _addr)
        internal
        view
        returns (uint256)
    {
        RewardInfo storage info = rewardsInfo[_addr];

        if (lastUpdateBlock > rewardEndBlock) return info.rewardMustBePaid;
        uint256 lastUpdate = Math.max(startBlock, lastUpdateBlock);
        uint256 amount =
            rewardEndBlock.sub(lastUpdate).mul(info.rewardPerBlock);
        if (totalStaked > 0) {
            return info.rewardMustBePaid.add(amount);
        }
        return
            info.rewardMustBePaid.add(amount).sub(
                _calculateBlocksLeft().mul(info.rewardPerBlock)
            );
    }

    function _harvest(address recipient) internal {
        for (uint256 i = 0; i < rewardTokenAddress.length; i++) {
            address token = rewardTokenAddress[i];
            RewardInfo storage info = rewardsInfo[token];
            uint256 rewards = info.rewards[recipient];
            if (token.supportsInterface(InterfaceId_ERC721)) {
                if (rewards > UNITS) {
                    uint256 count = rewards.div(UNITS);
                    uint256 rewardInt = count.mul(UNITS);
                    info.rewards[recipient] = rewards.sub(rewardInt);
                    info.rewardMustBePaid = info.rewardMustBePaid.sub(
                        rewardInt
                    );

                    for (uint256 j = 0; j < count; j++) {
                        uint256 id = approvedNFT[token].at(0);
                        approvedNFT[token].remove(id);
                        IERC721(token).safeTransferFrom(
                            address(this),
                            recipient,
                            id
                        );
                    }
                    emit RewardPaid(recipient, token, count);
                }
            } else {
                if (rewards > 0) {
                    info.rewards[recipient] = info.rewards[recipient].sub(
                        rewards
                    );
                    info.rewardMustBePaid = info.rewardMustBePaid.sub(rewards);

                    IERC20(token).transfer(recipient, rewards);

                    emit RewardPaid(recipient, token, rewards);
                }
            }
        }
    }

    function _updateRewards(address recipient) internal {
        for (uint256 i = 0; i < rewardTokenAddress.length; i++) {
            RewardInfo storage info = rewardsInfo[rewardTokenAddress[i]];
            uint256 newRewardPerTokenStore =
                _calculateNewRewardPerTokenStore(info);
            info.rewardPerTokenStore = newRewardPerTokenStore;
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
                info.rewardsPerTokenPaid[recipient] = newRewardPerTokenStore;
            }
        }
        lastUpdateBlock = block.number;
    }

    function _calculateAPY(address addr) internal view returns (uint256) {
        RewardInfo storage info = rewardsInfo[addr];
        if (
            startBlock > block.number ||
            rewardEndBlock < block.number ||
            info.rewardPerBlock == 0
        ) return 0;
        uint256 blockPerDay =
            IStakingRegister(
                management.contractRegistry(CONTRACT_STAKING_REGISTER)
            )
                .getBlockPerDay();

        return
            info.rewardPerBlock.mul(UNITS).mul(blockPerDay).mul(365).div(
                totalStaked
            );
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

    function _calculateEarnedRewards(
        address recipient,
        uint256 rewardsPerTokenPaid,
        uint256 newRewardPerTokenStore
    ) internal view returns (uint256) {
        return
            newRewardPerTokenStore
                .sub(rewardsPerTokenPaid)
                .mul(staked[recipient])
                .div(UNITS);
    }

    function _calculateBlocksLeft() internal view returns (uint256) {
        uint256 blockNumber = Math.min(block.number, rewardEndBlock);

        if (blockNumber > startBlock && lastUpdateBlock < rewardEndBlock) {
            return blockNumber.sub(Math.max(startBlock, lastUpdateBlock));
        }
        return 0;
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) &&
            _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{ gas: 30000 }(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}