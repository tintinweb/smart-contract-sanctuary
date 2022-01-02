// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

// ___          ___         __             
//  |  _  |_     | |_   _  /__  _   _. _|_ 
//  | (_) |_) \/ | | | (/_ \_| (_) (_|  |_ 
//            /
// $FUR token contract
// Utility token for Toby The Goat (TTG)
//
// Toby The Goat (TTG)
// Collection of 9999 NFTs
// Website: https://tobythegoat.io
//     (_(
//     /_/'_____/)
//     "  |      |
//        |""""""|

contract NFTContract {
    function ownerOf(uint256 tokenId) external view returns (address owner) {}
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {}
}

contract Fur is Ownable, ERC20("TobyTheGoat FUR", "FUR"), ERC20Burnable {
    uint256 public constant DAILY_RATE = 10 ether;

    uint256 public constant START_TIME = 1641049200; /* Saturday, January 1, 2022 15:00 (UTC) */
    uint256 public constant TIME_BLOCKSIZE = 10_000;
    
    uint256 public constant BONUS_TIME_LIMIT_1 = 1641391200; /* Wednesday, January 5, 2022 14:00 (UTC) */
    uint256 public constant BONUS_TIME_LIMIT_2 = 1642258800; /* Saturday, January 15, 2022 15:00 (UTC) */

    event ChangeCommit(uint256 indexed tokenId, uint256 price, bytes changeData);

    NFTContract private delegate;
    uint256 public distributionEndTime = 1893510000; /* Tuesday, January 1, 2030 15:00 (UTC) */
    uint256 public gweiPerFur = 0;

    mapping(uint256 => uint256) public lastUpdateMap;
    mapping(address => uint256) public permittedContracts;

    constructor(address nftContract) {
        delegate = NFTContract(nftContract);
    }

    function getUpdateTime(uint256 id) public view returns (uint256 updateTime) {
        uint256 value = lastUpdateMap[id >> 4];
        value = (value >> ((id & 0xF) << 4)) & 0xFFFF;
        return value * TIME_BLOCKSIZE + START_TIME;
    }
    function setUpdateTime(uint256 id, uint256 time) internal returns (uint256 roundedTime) {
        require(time > START_TIME, "invalid time");
        uint256 currentValue = lastUpdateMap[id >> 4];
        uint256 shift = ((id & 0xF) << 4);
        uint256 mask = ~(0xFFFF << shift);
        // Round up block time
        uint256 newEncodedValue = (time - START_TIME + TIME_BLOCKSIZE - 1) / TIME_BLOCKSIZE;
        lastUpdateMap[id >> 4] = ((currentValue & mask) | (newEncodedValue << shift));
        return newEncodedValue * TIME_BLOCKSIZE + START_TIME;
    }

    function setPermission(address addr, uint256 permitted) public onlyOwner {
        permittedContracts[addr] = permitted;
    }

    function setGweiPerFur(uint256 value) public onlyOwner {
        gweiPerFur = value;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function setDistributionEndTime(uint256 endTime) public onlyOwner {
        distributionEndTime = endTime;
    }

    function getInitialGrant(uint256 t) public pure returns (uint256) {
        if (t < BONUS_TIME_LIMIT_1) {
            return 500 ether;
        }
        if (t < BONUS_TIME_LIMIT_2) {
            return 250 ether;
        } else {
            return 0;
        }
    }

    function getGrantBetween(uint256 beginTime, uint256 endTime) public pure returns (uint256) {
        if (beginTime > BONUS_TIME_LIMIT_2) {
            return ((endTime - beginTime) * DAILY_RATE) / 86400;
        }
        uint256 weightedTime = 0;
        if (beginTime < BONUS_TIME_LIMIT_1) {
            weightedTime += (min(endTime, BONUS_TIME_LIMIT_1) - beginTime) * 4; //40 $FUR per day
        }
        if (beginTime < BONUS_TIME_LIMIT_2 && endTime > BONUS_TIME_LIMIT_1) {
            weightedTime += (min(endTime, BONUS_TIME_LIMIT_2) - max(beginTime, BONUS_TIME_LIMIT_1)) * 2; //20 $FUR per day
        }
        if (endTime > BONUS_TIME_LIMIT_2) {
            weightedTime += endTime - max(beginTime, BONUS_TIME_LIMIT_2); //10 $FUR per day
        }
        return (weightedTime * DAILY_RATE) / 86400; //86400 == 24 hours
    }

    function claim(uint256 tokenId) internal returns (uint256) {
        uint256 lastUpdate = getUpdateTime(tokenId);
        // Round up by block
        uint256 timeUpdate = min(block.timestamp, distributionEndTime);
        timeUpdate = setUpdateTime(tokenId, timeUpdate);
        if (lastUpdate == START_TIME) {
            return getInitialGrant(timeUpdate);
        } else {
            return getGrantBetween(lastUpdate, timeUpdate);
        }
    }

    function claimReward(uint256[] memory id) public {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < id.length; i++) {
            require(delegate.ownerOf(id[i]) == msg.sender, "id not owned");
            totalReward += claim(id[i]);
        }
        if (totalReward > 0) {
            _mint(msg.sender, totalReward);
        }
    }

    function claimAll() public {
        claimAllFor(msg.sender);
    }

    function claimAllFor(address addr) public {
        uint256[] memory id = delegate.tokensOfOwner(addr);
        uint256 totalReward = 0;
        for (uint256 i = 0; i < id.length; i++) {
            totalReward += claim(id[i]);
        }
        if (totalReward > 0) {
            _mint(addr, totalReward);
        }
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    // burn tokens, allowing sent ETH to be converted according to gweiPerFur
    function burnTokens(uint256 amount) private {
        if (msg.value > 0 && gweiPerFur > 0) {
            uint256 converted = (msg.value * 1 gwei) / gweiPerFur;
            if (converted >= amount) {
                amount = 0;
            } else {
                amount -= converted;
            }
        }
        if (amount > 0) {
            _burn(msg.sender, amount);
        }
    }

    // Buy items
    function commitChange(
        uint256 tokenId,
        uint256 pricePaid,
        bytes memory changeData
    ) public payable {
        require(delegate.ownerOf(tokenId) == msg.sender, "not owner");
        burnTokens(pricePaid);
        emit ChangeCommit(tokenId, pricePaid, changeData);
    }

    function permittedMint(address destination, uint256 amount) public {
        require(permittedContracts[msg.sender] == 1);
        _mint(destination, amount);
    }

    function permittedBurn(address src, uint256 amount) public {
        require(permittedContracts[msg.sender] == 1);
        _burn(src, amount);
    }

    function permittedTransfer(
        address src,
        address dest,
        uint256 amount
    ) public {
        require(permittedContracts[msg.sender] == 1);
        _transfer(src, dest, amount);
    }

    function withdrawBalance(address to, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}