// SPDX-License-Identifier: MIT
/**
 *
 *
 *    tudaBirds NFT9k Presale Contract
 *    auto-generate NFT and transfer to buyers   
 *
 *
 **/

pragma solidity ^0.7.4;

import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

abstract contract DateTimeAPI {
    /*
     *  Abstract contract for interfacing with the DateTime contract.
     *
     */
    function isLeapYear(uint16 year) public pure virtual returns (bool);

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public pure virtual returns (uint256 timestamp);

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public pure virtual returns (uint256 timestamp);
}

contract NFBPresale is Ownable {
    using SafeMath for uint256;

    uint256 public presaleStartTime = 1633975200;
    uint256 public presaleEndTime = 1634061600;

    uint256 public presaleCap = 900; //10% of total supply
    uint256 public mintPrice = 224e18; // 0.09 ether, 10% discount
    uint256 public presaleMinLimitPrice = 224e19; //mintPrice * 10

    uint256 public mintLimit = 10; //10 NFT, bonus 1
    

    bool public endedPresale = false;

    struct User {
        uint256 ethAmount;
        uint256 nftAmount;
        address polygonWalletAddress;
    }

    mapping(address => User) users;
    mapping(uint256 => address) userIDs;
    uint256 public userCount = 0;
    uint256 public totalPurchased = 0;
    uint256 public soldNFTAmount = 0;
    

    address serviceWallet;

    constructor() {
        serviceWallet = msg.sender;
    }

    //auto claiming, system will mint NFT and send them to users.
    function reserveNFTs(address polygonWalletAddress) external payable {
        require(checkStartedPresale(), "Not started yet");
        require(checkEndedPresale() == false, "Ended Presale");

        uint256 ethAmount = msg.value;
        require(ethAmount >= presaleMinLimitPrice, "Less than minimun limit");

        soldNFTAmount = soldNFTAmount.add(mintLimit);
        require(
            soldNFTAmount <= presaleCap,
            "Sold out"
        );

        if (userExists(msg.sender)) {
            User storage user = users[msg.sender];
            user.ethAmount = user.ethAmount.add(ethAmount);
            user.nftAmount = user.nftAmount.add(mintLimit + 1);
            user.polygonWalletAddress = polygonWalletAddress;
        } else {
            users[msg.sender] = User({
                ethAmount: ethAmount,
                nftAmount: mintLimit + 1,
                polygonWalletAddress: polygonWalletAddress
            });
            userIDs[userCount] = msg.sender;
            userCount++;
        }

        totalPurchased = totalPurchased.add(ethAmount);
    }

    function userExists(address userAddress) public view returns (bool) {
        return (users[userAddress].ethAmount != 0);
    }

    function userInfo(uint256 index)
        public
        view
        returns (
            uint256 ethAmount,
            uint256 nftAmount,
            address polygonWalletAddress
        )
    {
        require(index < userCount, "Invalid index");

        return userInfoFromAddress(userIDs[index]);
    }

    function userInfoFromAddress(address userAddress)
        public
        view
        returns (
            uint256 ethAmount,
            uint256 nftAmount,
            address polygonWalletAddress
        )
    {
        require(userExists(userAddress), "Not exists");

        User memory user = users[userAddress];

        ethAmount = user.ethAmount;
        nftAmount = user.nftAmount;
        polygonWalletAddress = user.polygonWalletAddress;
    }

    function checkEndedPresale() public view returns(bool) {
      return endedPresale || block.timestamp > presaleEndTime;
    }

    function checkStartedPresale() public view returns(bool) {
      return presaleStartTime <= block.timestamp;
    }

    function setTime(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second,
        uint8 flag
    ) public onlyOwner {
        uint256 timestamp = toTimestamp(year, month, day, hour, minute, second);

         if (flag == 0) presaleStartTime = timestamp;
        else if (flag == 1) presaleEndTime = timestamp;
    }

    function setPresaleCap(uint256 cap) public onlyOwner {
        presaleCap = cap;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        mintPrice = price;
        presaleMinLimitPrice = price.mul(10);
    }

    function setEndPresale(bool ended) public onlyOwner {
        endedPresale = ended;
    }

    function setServiceWallet(address _serviceWallet) public onlyOwner {
        serviceWallet = _serviceWallet;
    }

    function withdraw() public payable onlyOwner {
        address payable wallet = address(uint160(serviceWallet));
        uint256 amount = address(this).balance;
        wallet.transfer(amount);
    }

    /**
     * Utils
     */
    //////////////////////////////////////////////////////////////////

    function isLeapYear(uint16 year) private pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) private pure returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) private pure returns (uint256 timestamp) {
        uint32 DAY_IN_SECONDS = 86400;
        uint32 YEAR_IN_SECONDS = 31536000;
        uint32 LEAP_YEAR_IN_SECONDS = 31622400;

        uint32 HOUR_IN_SECONDS = 3600;
        uint32 MINUTE_IN_SECONDS = 60;

        uint16 ORIGIN_YEAR = 1970;

        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }
}