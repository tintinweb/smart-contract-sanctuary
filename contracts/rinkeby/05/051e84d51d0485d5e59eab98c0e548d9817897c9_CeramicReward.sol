// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICeramic.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";

abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(
            _initializing || _isConstructor() || !_initialized,
            "Initializable: contract is already initialized"
        );

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

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

contract CeramicReward is Ownable, ReentrancyGuard, Initializable {
    using SafeMath for uint256;
    using Address for address;

    struct NftInfo {
        uint256 lastClaimEpochId;
    }

    struct MonthlyRewardInfo {
        uint256 monthlyTotalRewards;
        uint256 CERAMIC_SUPPLY;
    }

    struct NftInfoForToken {
        uint256 claimAmount;
        uint256 lastClaimTime;
    }

    struct TokenReward {
        uint256 id;
        uint256 available;
        uint256 pending;
    }

    struct UserRewards {
        uint256 totalAvailable;
        uint256 totalPending;
        TokenReward[] tokenRewards;
    }

    address public ceramicAddress;
    address public rewardTokenAddress;
    address public communityAddress;

    uint256 public communityFee;
    uint256 public ownerFee;

    uint256 public epoch1Start;
    uint256 public epochDuration;

    uint256 public communityAmount;
    uint256 public ownerAmount;

    mapping(uint256 => NftInfo) public nftsInfo;
    mapping(uint256 => MonthlyRewardInfo) public monthlyRewardInfos;

    uint256 public startedTimeForToken;
    uint256 public tokenRewardPeriod;
    uint256 public tokenRewardDuration;
    uint256 private totalTokenAmount;

    mapping(uint256 => NftInfoForToken) public nftsInfoForToken;

    bool public rewardInEth = true; // true: ETH Reward, false: Token Reward

    event Received(address sender, uint256 amount, uint256 totalSupply);
    event Withdraw(address indexed user, uint256[] tokenIds, uint256 amount);

    constructor() {}

    function initialize(address owner) public initializer {
        epoch1Start = block.timestamp;
        initOwner(owner);
        initGuard();

        ceramicAddress = 0x583753739B324820A6Ea244bCb0b31Da8Bb11734;
        communityFee = 20;
        ownerFee = 20;
        epochDuration = 4 weeks;
    }

    receive() external payable {
        uint256 receivedAmount = msg.value;
        uint256 receivedCommunityAmount = receivedAmount.mul(communityFee).div(
            100
        );
        uint256 receivedOwnerAmount = receivedAmount.mul(ownerFee).div(100);
        uint256 receivedRewardAmount = receivedAmount
            .sub(receivedCommunityAmount)
            .sub(receivedOwnerAmount);

        communityAmount = communityAmount.add(receivedCommunityAmount);
        ownerAmount = ownerAmount.add(receivedOwnerAmount);

        uint256 currentEpochId = getCurrentEpoch();
        MonthlyRewardInfo storage monthlyRewardInfo = monthlyRewardInfos[
            currentEpochId
        ];
        monthlyRewardInfo.monthlyTotalRewards = monthlyRewardInfo
            .monthlyTotalRewards
            .add(receivedRewardAmount);
        monthlyRewardInfo.CERAMIC_SUPPLY = getCeramicTotalSupply();

        emit Received(msg.sender, msg.value, monthlyRewardInfo.CERAMIC_SUPPLY);
    }

    function setFeePercent(uint256 _communityFee, uint256 _ownerFee)
        public
        onlyOwner
    {
        require(
            communityFee != _communityFee && ownerFee != _ownerFee,
            "Already set."
        );
        communityFee = _communityFee;
        ownerFee = _ownerFee;
    }

    function setTokenReward(address _rewardTokenAddress) public onlyOwner {
        require(_rewardTokenAddress != address(0), "Zero address.");
        require(rewardTokenAddress != _rewardTokenAddress, "Already set.");
        rewardTokenAddress = _rewardTokenAddress;
    }

    function setCommunityAddress(address _communityAddress) public onlyOwner {
        require(_communityAddress == address(0), "Already set.");
        communityAddress = _communityAddress;
    }

    function setTokenRewardPeriod(uint256 _tokenRewardPeriod) public onlyOwner {
        require(rewardTokenAddress != address(0), "Zero address.");
        startedTimeForToken = block.timestamp;
        tokenRewardPeriod = _tokenRewardPeriod;
        totalTokenAmount = IERC20(rewardTokenAddress).balanceOf(address(this));
    }

    function setTokenRewardDuration(uint256 _tokenRewardDuration)
        public
        onlyOwner
    {
        require(_tokenRewardDuration != 0, "Zero value.");
        tokenRewardDuration = _tokenRewardDuration;
    }

    function switchRewardToken(bool _rewardInEth) public onlyOwner {
        require(rewardInEth != _rewardInEth, "Already set.");
        rewardInEth = _rewardInEth;
    }

    function getCurrentEpoch() public view returns (uint256) {
        if (block.timestamp < epoch1Start) {
            return 0;
        }

        return uint256((block.timestamp - epoch1Start) / epochDuration + 1);
    }

    function getCeramicTotalSupply() public view returns (uint256) {
        uint256 totalsupply = ICeramic(ceramicAddress).totalSupply();

        return totalsupply;
    }

    function getEthRewardByTokenId(uint256 tokenId)
        public
        view
        returns (uint256, uint256)
    {
        uint256 available;
        uint256 pending;

        uint256 currentEpochId = getCurrentEpoch();

        MonthlyRewardInfo storage monthlyRewardInfo = monthlyRewardInfos[
            currentEpochId
        ];
        pending = monthlyRewardInfo.monthlyTotalRewards.div(
            monthlyRewardInfo.CERAMIC_SUPPLY
        );

        if (currentEpochId <= 1) {
            return (available, pending);
        }

        NftInfo storage nftInfo = nftsInfo[tokenId];

        for (
            uint256 i = nftInfo.lastClaimEpochId + 1;
            i < currentEpochId;
            i++
        ) {
            MonthlyRewardInfo storage monthlyRewardInfo1 = monthlyRewardInfos[
                currentEpochId
            ];
            available = monthlyRewardInfo1.monthlyTotalRewards.div(
                monthlyRewardInfo1.CERAMIC_SUPPLY
            );
        }

        return (available, pending);
    }

    function getReward(address user) public view returns (UserRewards memory) {
        uint256[] memory tokenIds = ICeramic(ceramicAddress).tokensOfOwner(
            user
        );

        uint256 _totalAvailable;
        uint256 _totalPending;
        TokenReward[] memory _tokenRewards = new TokenReward[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 _available;
            uint256 _pending;
            if (rewardInEth) {
                (_available, _pending) = getEthRewardByTokenId(tokenIds[i]);
            } else {
                (_available, _pending) = getTokenRewardByTokenId(tokenIds[i]);
            }
            _totalAvailable = _totalAvailable.add(_available);
            _totalPending = _totalPending.add(_pending);

            _tokenRewards[i] = TokenReward({
                id: tokenIds[i],
                available: _available,
                pending: _pending
            });
        }

        UserRewards memory _userRewards = UserRewards({
            totalAvailable: _totalAvailable,
            totalPending: _totalPending,
            tokenRewards: _tokenRewards
        });

        return _userRewards;
    }

    function _resetNftInfo(uint256 tokenId) internal {
        NftInfo storage nftInfo = nftsInfo[tokenId];
        uint256 currentEpochId = getCurrentEpoch();
        nftInfo.lastClaimEpochId = currentEpochId.sub(1);
    }

    function _withdrawEthReward(uint256[] memory tokenIds)
        internal
        returns (bool)
    {
        uint256 total;
        for (uint256 i; i < tokenIds.length; i++) {
            (uint256 available, ) = getEthRewardByTokenId(tokenIds[i]);
            total = total.add(available);
            _resetNftInfo(tokenIds[i]);
        }

        if (total > 0) {
            payable(_msgSender()).transfer(total);

            emit Withdraw(_msgSender(), tokenIds, total);
            return true;
        } else {
            return false;
        }
    }

    function getLastClaimedTime(uint256 tokenId) public view returns (uint256) {
        NftInfoForToken storage nftInfoForToken = nftsInfoForToken[tokenId];
        if (nftInfoForToken.lastClaimTime == 0) {
            return startedTimeForToken;
        }
        return nftInfoForToken.lastClaimTime;
    }

    function totalRewardPerToken(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        NftInfoForToken storage nftInfoForToken = nftsInfoForToken[tokenId];
        uint256 availableAmount = totalTokenAmount
            .div(getCeramicTotalSupply())
            .sub(nftInfoForToken.claimAmount);

        return availableAmount;
    }

    function getCurrentBlockTime() internal view returns (uint256) {
        if (block.timestamp > startedTimeForToken.add(tokenRewardPeriod)) {
            return startedTimeForToken.add(tokenRewardPeriod);
        }

        return block.timestamp;
    }

    function getLeftEpochCount() internal view returns (uint256) {
        uint256 leftTime = startedTimeForToken.add(tokenRewardPeriod).sub(
            block.timestamp
        );

        return leftTime.div(tokenRewardDuration);
    }

    function rewardEpochCount(uint256 tokenId) internal view returns (uint256) {
        return
            (getCurrentBlockTime().sub(getLastClaimedTime(tokenId))).div(
                tokenRewardDuration
            );
    }

    function getTokenRewardByTokenId(uint256 tokenId)
        public
        view
        returns (uint256, uint256)
    {
        if (
            totalTokenAmount == 0 ||
            tokenRewardDuration == 0 ||
            tokenRewardPeriod == 0
        ) {
            return (0, 0);
        }

        uint256 rewardPerEpoch = totalRewardPerToken(tokenId).div(
            getLeftEpochCount()
        );

        uint256 available = rewardPerEpoch.mul(rewardEpochCount(tokenId));
        uint256 pending = rewardPerEpoch;

        return (available, pending);
    }

    function _resetNftInfoForToken(uint256 tokenId, uint256 amount) internal {
        NftInfoForToken storage nftInfoForToken = nftsInfoForToken[tokenId];

        uint256 rewardTime = rewardEpochCount(tokenId).mul(tokenRewardDuration);
        nftInfoForToken.lastClaimTime = nftInfoForToken.lastClaimTime.add(
            rewardTime
        );
        nftInfoForToken.claimAmount = nftInfoForToken.claimAmount.add(amount);
    }

    function _withdrawTokenReward(uint256[] memory tokenIds)
        internal
        returns (bool)
    {
        uint256 total;
        for (uint256 i; i < tokenIds.length; i++) {
            (uint256 available, ) = getTokenRewardByTokenId(tokenIds[i]);
            total = total.add(available);
            _resetNftInfoForToken(tokenIds[i], available);
        }

        if (total > 0) {
            IERC20(rewardTokenAddress).transfer(_msgSender(), total);

            emit Withdraw(_msgSender(), tokenIds, total);
            return true;
        } else {
            return false;
        }
    }

    function withdraw(uint256[] memory tokenIds) external returns (bool) {
        require(!isContract(_msgSender()), "Could not be contract.");

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                ICeramic(ceramicAddress).ownerOf(tokenIds[i]) == _msgSender(),
                "This is not token owner."
            );
        }

        bool result;
        if (rewardInEth) {
            result = _withdrawEthReward(tokenIds);
        } else {
            result = _withdrawTokenReward(tokenIds);
        }

        return result;
    }

    function withdrawOwnerReWard() public onlyOwner {
        require(rewardInEth, "ETH reward finished");
        payable(_msgSender()).transfer(ownerAmount);
    }

    function withdrawCommunityReward() public {
        require(_msgSender() == communityAddress);
        require(rewardInEth, "ETH reward finished");
        payable(_msgSender()).transfer(ownerAmount);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}