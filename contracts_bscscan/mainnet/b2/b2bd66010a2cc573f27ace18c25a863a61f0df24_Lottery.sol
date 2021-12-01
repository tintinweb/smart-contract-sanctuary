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

contract Lottery is Ownable {
    uint256 constant ONE_DOLLAR = 1e18;

    IERC20 vodkaToken;
    IERC721 cocktailNFT;
    ITokenConverter tokenConverter;

    mapping(address => uint[]) lotteryResults;

    address public BUSD;

    event Spin(address from, uint256 reward, uint256 lotteryResult);

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

    function spin(uint256[] memory tokenIds) public returns (uint256, uint256) {
        uint256 lotteryResult = randomInt(0, 10);

        uint256 rewardTokens = proccedSpin(tokenIds, lotteryResult);
        uint length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            cocktailNFT.transferFrom(msg.sender, address(this), tokenIds[i]);
            cocktailNFT.burn(tokenIds[i]);
        }

        vodkaToken.transfer(msg.sender, rewardTokens);
        emit Spin(msg.sender, rewardTokens, lotteryResult);

        lotteryResults[msg.sender].push(lotteryResult);

        return (lotteryResult, rewardTokens);
    }

    function proccedSpin(uint256[] memory tokenIds, uint256 result) public view returns (uint256) {
        uint256 reward = 0;
        uint length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            reward = reward + cocktailNFT.getPrice(tokenIds[i]) * ONE_DOLLAR;
        }

        if (result == 0) {
            reward = reward * 3;
        } else if (result == 1) {
            reward = reward * 2;
        } else if (result == 2) {
            reward = reward * 1;
        } else if (result == 3) {
            reward = reward / 2;
        } else {
            reward = 0;
        }

        uint256 rewardTokens = tokenConverter.convertTwoUniversal(BUSD, address(vodkaToken), reward);
        return rewardTokens;
    }

    function getResults(address player) external view returns (uint[] memory) {
        return lotteryResults[player];
        
    }

    function randomInt(uint256 from, uint256 to) public view returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender)));
        return (randomNumber % (to - from)) + from;
    }

    function changeTokenConverter(address tokenConverter_) external onlyOwner {
        tokenConverter = ITokenConverter(tokenConverter_);
    }
}