// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ICeramic.sol";
import "./IRCCToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";

contract CeramicStaking is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    struct NftInfo {
        uint256 claimAmount;
        uint256 lastClaimTime;
    }

    struct TokenReward {
        uint256 id;
        uint256 reward;
    }

    struct UserRewards {
        uint256 totalReward;
        TokenReward[] tokenRewards;
    }

    address public ceramicAddress;
    address public rewardTokenAddress;
    address public mintableOwner;

    uint256 public dailyRewardAmount;

    mapping(uint256 => NftInfo) public nftInfos;
    mapping(address => uint256[]) public stakers;

    event Staked(address indexed user, uint256[] tokenIds);
    event Claim(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256[] tokenIds, uint256 amount);

    constructor() {
        ceramicAddress = 0x7C4d474bb7c274dDe68c0e6E82Bdfd81A2f8fa9F;
        dailyRewardAmount = 10**18;
    }

    function setRewardTokenAddress(
        address _rewardTokenAddress,
        address _ceramicAddress
    ) public onlyOwner {
        require(_rewardTokenAddress != address(0), "Zero address.");
        require(rewardTokenAddress != _rewardTokenAddress, "Already set.");
        rewardTokenAddress = _rewardTokenAddress;
        ceramicAddress = _ceramicAddress; // For test, will be removed
    }

    function setDailyTokenReward(uint256 _dailyRewardAmount) public onlyOwner {
        require(dailyRewardAmount != _dailyRewardAmount, "Already set.");
        dailyRewardAmount = _dailyRewardAmount;
    }

    function getRewardByTokenId(uint256 tokenId)
        public
        view
        returns (uint256, uint256)
    {
        NftInfo memory nftInfo = nftInfos[tokenId];

        if (nftInfo.lastClaimTime == 0) {
            return (10000, 0);
        } else {
            return (
                tokenId,
                dailyRewardAmount.mul(
                    (block.timestamp - nftInfo.lastClaimTime).div(1 days)
                )
            );
        }
    }

    function getReward(address user) public view returns (UserRewards memory) {
        uint256[] memory tokenIds = stakers[user];

        uint256 _totalReward;

        TokenReward[] memory _tokenRewards = new TokenReward[](tokenIds.length);

        for (uint256 i; i < tokenIds.length; i++) {
            (uint256 tokenId, uint256 _available) = getRewardByTokenId(
                tokenIds[i]
            );

            _totalReward = _totalReward.add(_available);

            _tokenRewards[i] = TokenReward({id: tokenId, reward: _available});
        }

        UserRewards memory _userRewards = UserRewards({
            totalReward: _totalReward,
            tokenRewards: _tokenRewards
        });

        return _userRewards;
    }

    function stake(uint256[] memory tokenIds) public nonReentrant {
        require(!_msgSender().isContract(), "Stake: Could not be contract.");
        require(tokenIds.length > 0, "Stake: Could not be empty.");

        bool allApproved = ICeramic(ceramicAddress).isApprovedForAll(
            _msgSender(),
            address(this)
        );
        require(allApproved, "Stake: Token is not approved.");

        uint256[] storage staker = stakers[_msgSender()];
        for (uint256 i; i < tokenIds.length; i++) {
            ICeramic(ceramicAddress).transferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );

            staker.push(tokenIds[i]);
            nftInfos[tokenIds[i]].lastClaimTime = block.timestamp;
        }

        emit Staked(_msgSender(), tokenIds);
    }

    function _setNftInfoTokenId(uint256 tokenId, uint256 amount) internal {
        NftInfo storage nftInfo = nftInfos[tokenId];

        nftInfo.lastClaimTime = nftInfo.lastClaimTime.add(
            amount.div(dailyRewardAmount) * 1 days
        );
        nftInfo.claimAmount = nftInfo.claimAmount.add(amount);
    }

    function _resetNftInfoTokenId(uint256 tokenId, uint256 amount) internal {
        NftInfo storage nftInfo = nftInfos[tokenId];

        nftInfo.lastClaimTime = 0;
        nftInfo.claimAmount = nftInfo.claimAmount.add(amount);
    }

    function claimReward(uint256[] memory indexes)
        external
        nonReentrant
        returns (bool)
    {
        uint256[] memory tokenIds = stakers[_msgSender()];
        for (uint256 i; i < indexes.length; i++) {
            require(indexes[i] < tokenIds.length, "Claim: Wrong Index.");
        }
        uint256 total;
        for (uint256 i; i < indexes.length; i++) {
            (, uint256 available) = getRewardByTokenId(tokenIds[indexes[i]]);
            total = total.add(available);
            _setNftInfoTokenId(tokenIds[indexes[i]], available);
        }

        if (total > 0) {
            IRCCToken(rewardTokenAddress).mint(_msgSender(), total);

            emit Claim(_msgSender(), total);
            return true;
        } else {
            return false;
        }
    }

    function withdraw(uint256[] memory indexes) external nonReentrant {
        uint256[] storage tokenIds = stakers[_msgSender()];
        for (uint256 i; i < indexes.length; i++) {
            require(indexes[i] < tokenIds.length, "Claim: Wrong Index.");
        }

        uint256[] memory withdrawIds = new uint256[](indexes.length);
        uint256 total;
        for (uint256 i; i < indexes.length; i++) {
            uint256 tokenId = tokenIds[indexes[i]];
            withdrawIds[i] = tokenId;

            (, uint256 available) = getRewardByTokenId(tokenId);
            total = total.add(available);
            _resetNftInfoTokenId(tokenId, available);
            delete tokenIds[indexes[i]];

            ICeramic(ceramicAddress).approve(_msgSender(), tokenId);
            ICeramic(ceramicAddress).transferFrom(
                address(this),
                _msgSender(),
                tokenId
            );
        }

        if (total > 0) {
            IRCCToken(rewardTokenAddress).mint(_msgSender(), total);
        }

        emit Withdraw(_msgSender(), withdrawIds, total);
    }

    function setMintableAddress(address _mintableOwner) external onlyOwner {
        mintableOwner = _mintableOwner;
    }

    function mintPoolToken(uint256 amount) public {
        require(
            _msgSender() == mintableOwner,
            "Not allowed to mint pool token."
        );

        IRCCToken(rewardTokenAddress).mint(_msgSender(), amount);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}