/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IERC721 {
    function getPrice(uint tokenId) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function burn(uint256 tokenId) external;
}

interface IERC20 {
    function balanceOf(address who) external view returns (uint256 balance);

    function transfer(address to, uint256 value) external returns (bool trans1);

    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool trans);

    function approve(address spender, uint256 value) external returns (bool hello);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface ITokenConverter {
    function convertTwoUniversal(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner can call this function');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'You cant tranfer ownerships to address 0x0');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Staking is Ownable {
    address public BUSD;

    IERC20 public vodkaToken;
    IERC721 public cocktailNFT;
    ITokenConverter tokenConverter;

    uint256 constant MONTH = 30 days;

    uint256 constant ONE_DOLLAR = 1e18;

    uint256[4] public periods = [MONTH, 3 * MONTH, 6 * MONTH, 12 * MONTH];
    uint8[4] public rates = [5, 6, 9, 12];

    struct Stake {
        uint8 class;
        uint256[] tokenIds;
        uint256 startTime;
        uint256 endTime;
        uint256 initialInBUSD;
        uint256 rewardBUSD;
        uint256 gainedBUSD;
    }

    mapping(address => Stake) public stakes;

    event Staked(address sender, uint8 class, uint256[] tokenIds, uint256 initialInBUSD, uint256 rewardBUSD);
    event Prolonged(
        address sender,
        uint8 class,
        uint256[] tokenIds,
        uint256 gainedBUSD,
        uint256 initialInBUSD,
        uint256 rewardBUSD
    );
    event Unstaked(address sender, uint8 class, uint256[] tokenIds, uint256 totalRewardTokens);

    constructor(
        address vodkaToken_,
        address cocktailNFT_,
        address busdAddress,
        address tokenConverter_
    ) {
        owner = msg.sender;

        vodkaToken = IERC20(vodkaToken_);
        cocktailNFT = IERC721(cocktailNFT_);
        tokenConverter = ITokenConverter(tokenConverter_);
        BUSD = busdAddress;
    }

    function stake(uint8 class, uint256[] memory tokenIds) public {
        require((class < periods.length), 'Wrong class');
        require(stakes[msg.sender].startTime == 0, 'You have already staked');

        uint256 initialInBUSD = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            cocktailNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
            initialInBUSD += cocktailNFT.getPrice(tokenIds[i]) * ONE_DOLLAR;
        }

        uint256 rewardBUSD = (rates[class] * periods[class] * initialInBUSD) / (60 * 60 * 24 * 30 * 100);

        stakes[msg.sender] = Stake({
            class: class,
            tokenIds: tokenIds,
            startTime: block.timestamp,
            endTime: block.timestamp + periods[class],
            initialInBUSD: initialInBUSD,
            rewardBUSD: rewardBUSD,
            gainedBUSD: 0
        });

        emit Staked(msg.sender, class, tokenIds, initialInBUSD, rewardBUSD);
    }


    function prolong() public {
        require(stakes[msg.sender].startTime > 0, 'You dont have staking');
        require(stakes[msg.sender].endTime < block.timestamp, 'Period did not pass');

        Stake memory stake = stakes[msg.sender];

        stakes[msg.sender] = Stake({
            class: stake.class,
            tokenIds: stake.tokenIds,
            startTime: block.timestamp,
            endTime: block.timestamp + periods[stake.class],
            initialInBUSD: stake.initialInBUSD,
            rewardBUSD: stake.rewardBUSD,
            gainedBUSD: stake.gainedBUSD + stake.rewardBUSD
        });

        emit Prolonged(
            msg.sender,
            stake.class,
            stake.tokenIds,
            stake.gainedBUSD + stake.rewardBUSD,
            stake.initialInBUSD,
            stake.rewardBUSD
        );
    }

    function unstake() public {
        require(stakes[msg.sender].startTime > 0, 'You dont have staking');
        require(stakes[msg.sender].endTime < block.timestamp, 'Period did not pass');

        Stake memory stake = stakes[msg.sender];

        uint256 totalRewardBUSD = stake.gainedBUSD + stake.rewardBUSD;
        uint256 _totalRewardTokens = tokenConverter.convertTwoUniversal(BUSD, address(vodkaToken), totalRewardBUSD);

        require(vodkaToken.balanceOf(address(this)) >= _totalRewardTokens, 'Dont enough tokens on contract');
        vodkaToken.transfer(msg.sender, _totalRewardTokens);

        for (uint256 i = 0; i < stake.tokenIds.length; i++) {
            cocktailNFT.transferFrom(address(this), msg.sender, stake.tokenIds[i]);
        }

        delete stakes[msg.sender];

        emit Unstaked(msg.sender, stake.class, stake.tokenIds, _totalRewardTokens);
    }

    function getStake() external view returns (Stake memory) {
        return stakes[msg.sender];
    }

    function changeTokenConverter(address tokenConverter_) external onlyOwner {
        tokenConverter = ITokenConverter(tokenConverter_);
    }
}