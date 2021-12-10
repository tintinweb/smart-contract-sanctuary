// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC721Receiver.sol";

interface IRandomNumGenerator {
    function getRandomNumber(
        uint256 _seed,
        uint256 _limit,
        uint256 _random
    ) external view returns (uint16);
}

interface IAngryFrogs {
    function isHunter(uint16 tokenId) external view returns (bool);
}

interface IStakingDevice {
    function getMultifier(uint16 tokenId) external view returns (uint8);
}

interface IRibbitToken {
    function mint(address to, uint256 amount) external;
}

contract GoldStaking is Ownable, IERC721Receiver {
    using Address for address;

    struct NftInfo {
        uint256 lastClaimTime;
        uint256 penddingAmount;
    }

    struct TokenReward {
        uint16 id;
        uint256 reward;
    }

    struct UserRewards {
        uint256 totalReward;
        TokenReward[] tokenRewards;
    }

    address public angryfrogAddress;
    address public deviceAddress;
    address public ribbitAddress;
    IRandomNumGenerator randomGen;

    uint256 public dailyRewardAmount;
    uint16[] public multifierValue;

    mapping(uint16 => NftInfo) public nftInfos;
    mapping(address => uint16[]) public stakers;
    mapping(address => uint16[]) public devices;
    uint16[] public hunterHolders;

    event Staked(address indexed user, uint16[] tokenIds);
    event Claim(address indexed user, uint16[] tokenIds, uint256 amount);
    event Withdraw(address indexed user, uint16[] tokenIds, uint256 amount);
    event Steel(address from, address to, uint256 amount);

    constructor() {
        dailyRewardAmount = 10 * 10**18;
        multifierValue = [25, 35, 50, 60, 70, 80, 90, 100, 200, 500];
    }

    function setRibbitAddress(address _ribbitAddress) public onlyOwner {
        require(_ribbitAddress != address(0), "Zero address.");
        ribbitAddress = _ribbitAddress;
    }

    function setNFTAddress(address _angryfrogAddress, address _deviceAddress)
        public
        onlyOwner
    {
        require(
            _angryfrogAddress != address(0) && _deviceAddress != address(0),
            "Zero address."
        );
        angryfrogAddress = _angryfrogAddress;
        deviceAddress = _deviceAddress;
    }

    function setRandomContract(IRandomNumGenerator _randomGen)
        external
        onlyOwner
    {
        randomGen = _randomGen;
    }

    function setDailyTokenReward(uint256 _dailyRewardAmount) public onlyOwner {
        require(dailyRewardAmount != _dailyRewardAmount, "Already set.");
        dailyRewardAmount = _dailyRewardAmount;
    }

    function getMultifierByTokenId(uint16 deviceId)
        public
        view
        returns (uint16)
    {
        uint8 number = IStakingDevice(deviceAddress).getMultifier(deviceId);
        return multifierValue[number];
    }

    function getRewardByTokenId(uint16 tokenId, address user)
        public
        view
        returns (uint256)
    {
        NftInfo memory nftInfo = nftInfos[tokenId];

        if (nftInfo.lastClaimTime == 0) {
            return 0;
        } else {
            uint16[] memory deviceIds = devices[user];
            uint16 _totalMultifier = 100;
            for (uint8 i; i < deviceIds.length; i++) {
                _totalMultifier =
                    _totalMultifier +
                    getMultifierByTokenId(deviceIds[i]);
            }

            return
                nftInfo.penddingAmount +
                dailyRewardAmount *
                _totalMultifier *
                // ((block.timestamp - nftInfo.lastClaimTime) / (100 * 1 days));
                (block.timestamp - nftInfo.lastClaimTime); //// For Test
        }
    }

    function getReward(address user) public view returns (UserRewards memory) {
        uint16[] memory tokenIds = stakers[user];
        uint16[] memory deviceIds = devices[user];

        uint256 _totalReward;

        uint16 _totalMultifier = 100;
        for (uint8 i; i < deviceIds.length; i++) {
            _totalMultifier =
                _totalMultifier +
                getMultifierByTokenId(deviceIds[i]);
        }

        TokenReward[] memory _tokenRewards = new TokenReward[](tokenIds.length);

        for (uint8 i; i < tokenIds.length; i++) {
            uint256 _available = getRewardByTokenId(tokenIds[i], user);

            _totalReward = _totalReward + _available;

            _tokenRewards[i] = TokenReward({
                id: tokenIds[i],
                reward: _available
            });
        }

        UserRewards memory _userRewards = UserRewards({
            totalReward: _totalReward,
            tokenRewards: _tokenRewards
        });

        return _userRewards;
    }

    function stake(address account, uint16[] memory tokenIds) public {
        require(
            account == msg.sender || msg.sender == angryfrogAddress,
            "You do not have a permission to do that"
        );
        require(tokenIds.length > 0, "Stake: Could not be empty.");

        uint16[] storage staker = stakers[account];

        for (uint8 i; i < tokenIds.length; i++) {
            if (msg.sender != angryfrogAddress) {
                require(
                    IERC721(angryfrogAddress).ownerOf(tokenIds[i]) ==
                        msg.sender,
                    "This NFT does not belong to address"
                );
                IERC721(angryfrogAddress).transferFrom(
                    msg.sender,
                    address(this),
                    tokenIds[i]
                );
            }

            staker.push(tokenIds[i]);
            nftInfos[tokenIds[i]].lastClaimTime = block.timestamp;

            if (IAngryFrogs(angryfrogAddress).isHunter(tokenIds[i])) {
                hunterHolders.push(tokenIds[i]);
            }
        }

        emit Staked(account, tokenIds);
    }

    function stakeDevice(address account, uint16[] memory deviceIds) public {
        require(
            account == msg.sender || msg.sender == deviceAddress,
            "You do not have a permission to do that"
        );
        require(deviceIds.length > 0, "Stake: Could not be empty.");
        _tempClaimReward(account);

        uint16[] storage device = devices[account];

        for (uint8 i; i < deviceIds.length; i++) {
            if (msg.sender != deviceAddress) {
                require(
                    IERC721(deviceAddress).ownerOf(deviceIds[i]) == msg.sender,
                    "This NFT does not belong to address"
                );
                IERC721(deviceAddress).transferFrom(
                    msg.sender,
                    address(this),
                    deviceIds[i]
                );
            }
            device.push(deviceIds[i]);
        }
        emit Staked(account, deviceIds);
    }

    function _tempClaimReward(address account) internal {
        uint16[] memory tokenIds = stakers[account];
        for (uint8 i; i < tokenIds.length; i++) {
            uint256 available = getRewardByTokenId(tokenIds[i], account);
            if (available > 0) {
                nftInfos[tokenIds[i]].penddingAmount =
                    nftInfos[tokenIds[i]].penddingAmount +
                    available;
                nftInfos[tokenIds[i]].lastClaimTime = block.timestamp;
            }
        }
    }

    function _setNftInfo(uint16 tokenId) internal {
        NftInfo storage nftInfo = nftInfos[tokenId];

        nftInfo.lastClaimTime = block.timestamp;
        nftInfo.penddingAmount = 0;
    }

    function _resetNftInfo(uint16 tokenId) internal {
        NftInfo storage nftInfo = nftInfos[tokenId];

        nftInfo.lastClaimTime = 0;
        nftInfo.penddingAmount = 0;
    }

    function _existTokenId(address account, uint16 tokenId)
        internal
        view
        returns (bool, uint8)
    {
        uint16[] memory tokenIds = stakers[account];
        for (uint8 i; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function _existDeviceId(address account, uint16 tokenId)
        internal
        view
        returns (bool, uint8)
    {
        uint16[] memory tokenIds = devices[account];
        for (uint8 i; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function claimReward(uint16[] memory tokenIds) external returns (bool) {
        require(tx.origin == msg.sender, "Only EOA");

        for (uint8 i; i < tokenIds.length; i++) {
            (bool exist, ) = _existTokenId(msg.sender, tokenIds[i]);
            require(exist, "Not Your Own");
        }

        uint256 total;
        for (uint8 i; i < tokenIds.length; i++) {
            uint256 available = getRewardByTokenId(tokenIds[i], msg.sender);
            total = total + available;
            _setNftInfo(tokenIds[i]);
        }

        if (total > 0) {
            address recipient = _selectRecipient(total);

            IRibbitToken(ribbitAddress).mint(recipient, total);

            if (recipient != msg.sender) {
                emit Steel(msg.sender, recipient, total);
            } else {
                emit Claim(_msgSender(), tokenIds, total);
            }

            return true;
        } else {
            return false;
        }
    }

    function withdraw(uint16[] memory tokenIds) external {
        require(tx.origin == msg.sender, "Only EOA");

        for (uint8 i; i < tokenIds.length; i++) {
            (bool exist, ) = _existTokenId(msg.sender, tokenIds[i]);
            require(exist, "Not Your Own");
        }

        uint16[] storage staker = stakers[_msgSender()];
        uint256 total;
        for (uint8 i; i < tokenIds.length; i++) {
            uint256 available = getRewardByTokenId(tokenIds[i], msg.sender);
            total = total + available;
            _resetNftInfo(tokenIds[i]);

            (, uint8 index) = _existTokenId(msg.sender, tokenIds[i]);
            staker[index] = staker[staker.length - 1];
            staker.pop();

            IERC721(angryfrogAddress).transferFrom(
                address(this),
                _msgSender(),
                tokenIds[i]
            );

            if (IAngryFrogs(angryfrogAddress).isHunter(tokenIds[i])) {
                uint256 indexOfHolder = 0;
                for (uint256 j; j < hunterHolders.length; j++) {
                    if (hunterHolders[j] == tokenIds[i]) {
                        indexOfHolder = j;
                        break;
                    }
                }
                hunterHolders[indexOfHolder] = hunterHolders[
                    hunterHolders.length - 1
                ];
                hunterHolders.pop();
            }
        }

        if (total > 0) {
            address recipient = _selectRecipient(total);

            IRibbitToken(ribbitAddress).mint(recipient, total);

            if (recipient != msg.sender) {
                emit Steel(msg.sender, recipient, total);
            } else {
                emit Withdraw(_msgSender(), tokenIds, total);
            }
        }
    }

    function withdrawDevice(uint16[] memory deviceIds) external {
        require(tx.origin == msg.sender, "Only EOA");

        for (uint8 i; i < deviceIds.length; i++) {
            (bool exist, ) = _existDeviceId(msg.sender, deviceIds[i]);
            require(exist, "Not Your Own");
        }
        _tempClaimReward(msg.sender);

        uint16[] storage device = devices[msg.sender];

        for (uint8 i; i < deviceIds.length; i++) {
            (, uint8 index) = _existDeviceId(msg.sender, deviceIds[i]);
            device[index] = device[device.length - 1];
            device.pop();

            IERC721(angryfrogAddress).transferFrom(
                address(this),
                _msgSender(),
                deviceIds[i]
            );
        }

        emit Withdraw(_msgSender(), deviceIds, 0);
    }

    function _selectRecipient(uint256 seed) private view returns (address) {
        if (
            randomGen.getRandomNumber(
                hunterHolders.length + seed,
                100,
                block.timestamp
            ) >= 10
        ) {
            return msg.sender;
        }

        address thief = randomHunterOwner(hunterHolders.length + seed);
        if (thief == address(0x0)) {
            return msg.sender;
        }
        return thief;
    }

    function randomHunterOwner(uint256 seed) public view returns (address) {
        if (hunterHolders.length == 0) return address(0x0);

        uint256 holderIndex = randomGen.getRandomNumber(
            hunterHolders.length + seed,
            hunterHolders.length,
            block.timestamp
        );

        return IERC721(angryfrogAddress).ownerOf(hunterHolders[holderIndex]);
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