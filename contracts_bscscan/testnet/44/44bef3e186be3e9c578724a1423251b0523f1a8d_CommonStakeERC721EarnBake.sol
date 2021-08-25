// SPDX-License-Identifier: MIT

pragma solidity =0.8.0;

import './IERC20.sol';
import './ERC20.sol';
import './SafeERC20.sol';
import './IERC721.sol';
import './ERC721Holder.sol';
import './Ownable.sol';
import './Pausable.sol';
import './EnumerableSet.sol';
import './SafeMath.sol';

import './ICommonStakeERC721EarnBake.sol';
import './ICommonMaster.sol';
import './IGetStakingPower.sol';

contract CommonStakeERC721EarnBake is ICommonStakeERC721EarnBake, ERC20, Ownable, ERC721Holder, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;

    // Info of each user.
    struct UserInfo {
        uint256 stakingPower;
        uint256 rewardDebt;
    }

    uint256 accBakePerShare; // Accumulated BAKEs per share, times 1e12. See below.
    uint256 public constant accBakePerShareMultiple = 1E4;
    uint256 public lastRewardBlock;
    // total has stake to BakeryMaster stakingPower
    uint256 public totalStakingPower;
    IERC721 public immutable erc721;
    address public constant bakeryToken = 0xE02dF9e3e622DeBdD69fb838bB799E3F168902c5;
    ICommonMaster public immutable bakeryMaster;
    IGetStakingPower public immutable getStakingPowerProxy;
    bool public immutable isMintPowerTokenEveryTimes;
    mapping(uint256 => bool) private _mintPowers;
    mapping(address => UserInfo) private _userInfoMap;
    mapping(address => EnumerableSet.UintSet) private _stakingTokens;

    constructor(
        string memory _name,
        string memory _symbol,
        address _bakeryMaster,
        address _erc721,
        address _getStakingPower,
        bool _isMintPowerTokenEveryTimes
    ) public ERC20(_name, _symbol) {
        bakeryMaster = ICommonMaster(_bakeryMaster);
        erc721 = IERC721(_erc721);
        getStakingPowerProxy = IGetStakingPower(_getStakingPower);
        isMintPowerTokenEveryTimes = _isMintPowerTokenEveryTimes;
    }

    function getStakingPower(uint256 _tokenId) public view override returns (uint256) {
        return getStakingPowerProxy.getStakingPower(address(erc721), _tokenId);
    }

    // View function to see pending BAKEs on frontend.
    function pendingBake(address _user) external view override returns (uint256) {
        UserInfo memory userInfo = _userInfoMap[_user];
        uint256 _accBakePerShare = accBakePerShare;
        if (totalStakingPower != 0) {
            uint256 totalPendingBake = bakeryMaster.pendingToken(address(this), address(this));
            _accBakePerShare = _accBakePerShare.add(
                totalPendingBake.mul(accBakePerShareMultiple).div(totalStakingPower)
            );
        }
        return userInfo.stakingPower.mul(_accBakePerShare).div(accBakePerShareMultiple).sub(userInfo.rewardDebt);
    }

    function updateStaking() public override {
        if (block.number <= lastRewardBlock) {
            return;
        }
        if (totalStakingPower == 0) {
            lastRewardBlock = block.number;
            return;
        }
        (, uint256 lastRewardDebt) = bakeryMaster.poolUserInfoMap(address(this), address(this));
        bakeryMaster.stake(address(this), 0);
        (, uint256 newRewardDebt) = bakeryMaster.poolUserInfoMap(address(this), address(this));
        accBakePerShare = accBakePerShare.add(
            newRewardDebt.sub(lastRewardDebt).mul(accBakePerShareMultiple).div(totalStakingPower)
        );
        lastRewardBlock = block.number;
    }

    function _harvest(UserInfo storage userInfo) internal {
        updateStaking();
        if (userInfo.stakingPower != 0) {
            uint256 pending = userInfo.stakingPower.mul(accBakePerShare).div(accBakePerShareMultiple).sub(
                userInfo.rewardDebt
            );
            if (pending != 0) {
                safeBakeTransfer(_msgSender(), pending);
                emit Harvest(_msgSender(), pending);
            }
        }
    }

    function harvest() external override {
        UserInfo storage userInfo = _userInfoMap[_msgSender()];
        _harvest(userInfo);
        userInfo.rewardDebt = userInfo.stakingPower.mul(accBakePerShare).div(accBakePerShareMultiple);
    }

    function stake(uint256 _tokenId) public override whenNotPaused {
        UserInfo storage userInfo = _userInfoMap[_msgSender()];
        _harvest(userInfo);
        uint256 stakingPower = getStakingPower(_tokenId);
        if (isMintPowerTokenEveryTimes || !_mintPowers[_tokenId]) {
            _mintPowers[_tokenId] = true;
        }

        erc721.safeTransferFrom(_msgSender(), address(this), _tokenId);
        userInfo.stakingPower = userInfo.stakingPower.add(stakingPower);
        _stakingTokens[_msgSender()].add(_tokenId);
        _approveToMasterIfNecessary(stakingPower);
        bakeryMaster.stake(address(this), stakingPower);
        totalStakingPower = totalStakingPower.add(stakingPower);
        userInfo.rewardDebt = userInfo.stakingPower.mul(accBakePerShare).div(accBakePerShareMultiple);
        emit Stake(_msgSender(), _tokenId, stakingPower);
    }

    function batchStake(uint256[] calldata _tokenIds) external override whenNotPaused {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            stake(_tokenIds[i]);
        }
    }

    function unstake(uint256 _tokenId) public override {
        require(_stakingTokens[_msgSender()].contains(_tokenId), 'UNSTAKE FORBIDDEN');
        UserInfo storage userInfo = _userInfoMap[_msgSender()];
        _harvest(userInfo);
        uint256 stakingPower = getStakingPower(_tokenId);
        userInfo.stakingPower = userInfo.stakingPower.sub(stakingPower);
        _stakingTokens[_msgSender()].remove(_tokenId);
        erc721.safeTransferFrom(address(this), _msgSender(), _tokenId);
        bakeryMaster.unstake(address(this), stakingPower);
        totalStakingPower = totalStakingPower.sub(stakingPower);
        userInfo.rewardDebt = userInfo.stakingPower.mul(accBakePerShare).div(accBakePerShareMultiple);
        if (isMintPowerTokenEveryTimes) {
            _burn(address(this), stakingPower);
        }
        emit Unstake(_msgSender(), _tokenId, stakingPower);
    }

    function batchUnstake(uint256[] calldata _tokenIds) external override {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            unstake(_tokenIds[i]);
        }
    }

    function unstakeAll() external override {
        EnumerableSet.UintSet storage stakingTokens = _stakingTokens[_msgSender()];
        uint256 length = stakingTokens.length();
        for (uint256 i = 0; i < length; ++i) {
            unstake(stakingTokens.at(0));
        }
    }

    function _approveToMasterIfNecessary(uint256 amount) internal {
        uint256 currentAllowance = allowance(address(this), address(bakeryMaster));
        if (currentAllowance < amount) {
            _approve(address(this), address(bakeryMaster), 2**256 - 1 - currentAllowance);
        }
    }

    function pauseStake() external override onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseStake() external override onlyOwner whenPaused {
        _unpause();
    }

    function emergencyUnstake(uint256 _tokenId) external override {
        require(_stakingTokens[_msgSender()].contains(_tokenId), 'EMERGENCY UNSTAKE FORBIDDEN');
        UserInfo storage userInfo = _userInfoMap[_msgSender()];
        uint256 stakingPower = getStakingPower(_tokenId);
        userInfo.stakingPower = userInfo.stakingPower.sub(stakingPower);
        _stakingTokens[_msgSender()].remove(_tokenId);
        erc721.safeTransferFrom(address(this), _msgSender(), _tokenId);
        totalStakingPower = totalStakingPower.sub(stakingPower);
        userInfo.rewardDebt = userInfo.stakingPower.mul(accBakePerShare).div(accBakePerShareMultiple);
        emit EmergencyUnstake(_msgSender(), _tokenId, stakingPower);
    }

    function emergencyUnstakeAllFromBake(uint256 _amount) external override onlyOwner whenPaused {
        bakeryMaster.emergencyUnstake(address(this), _amount);
        emit EmergencyUnstakeAllFromBake(_msgSender(), _amount);
    }

    function safeBakeTransfer(address _to, uint256 _amount) internal {
        uint256 bakeBal = IERC20(bakeryToken).balanceOf(address(this));
        if (_amount > bakeBal) {
            IERC20(bakeryToken).transfer(_to, bakeBal);
        } else {
            IERC20(bakeryToken).transfer(_to, _amount);
        }
    }

    function getUserInfo(address user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256[] memory
        )
    {
        UserInfo memory userInfo = _userInfoMap[user];
        uint256[] memory tokenIds = new uint256[](_stakingTokens[user].length());
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            tokenIds[i] = _stakingTokens[user].at(i);
        }
        return (userInfo.stakingPower, userInfo.rewardDebt, tokenIds);
    }
}