// SPDX-License-Identifier: MIT
/**
 *
 *
 *    TBIRD Presale Contract
 *
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

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract TBIRDPresale is Ownable {
    using SafeMath for uint256;

    uint256 public privPresaleStartTime;
    uint256 public privPresaleEndTime;

    uint256 public pubPresaleStartTime;
    uint256 public pubPresaleEndTime;

    uint256 public privPresaleCap = 60_000_000e9; //10% of total supply
    uint256 public pubPresaleCap = 60_000_000e9; //10% of total supply

    uint256 public privPresalePrice = 8000; // $0.008 USDC (decimal 6)
    uint256 public pubPresalePrice = 9000; // $0.009 USDC

    uint256 public privPresaleMinLimit = 200_000e6; //USD
    uint256 public pubPresaleMinLimit = 10_000e6; //USD

    struct User {
        uint256 ethAmount;
        uint256 tbirdAmount;
        address polygonWalletAddress;
    }

    mapping(address => bool) privWhiteList;
    mapping(address => User) privUsers;
    mapping(uint256 => address) privUserIDs;
    uint256 public privUserCount = 0;
    uint256 public privSoldTokenAmount = 0;
    uint256 public privTotalPurchased = 0;

    mapping(address => bool) pubWhiteList;
    mapping(address => User) pubUsers;
    mapping(uint256 => address) pubUserIDs;
    uint256 public pubUserCount = 0;
    uint256 public pubSoldTokenAmount = 0;
    uint256 public pubTotalPurchased = 0;

    AggregatorV3Interface internal priceFeedETH;

    address serviceWallet;

    constructor() {
        priceFeedETH = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    function buyPrivTBIRD(address polygonWalletAddress) external payable {
        require(checkPrivWhiteList(msg.sender), "Not white list user");

        uint256 ethAmount = msg.value;
        uint256 ethPrice = getETHPrice();
        uint256 usdAmount = ethAmount.mul(ethPrice).div(1e20);
        require(usdAmount >= privPresaleMinLimit, "Less than minimun limit");

        uint256 tbirdAmount = usdAmount.mul(1e9).div(privPresalePrice);
        privSoldTokenAmount = privSoldTokenAmount.add(tbirdAmount);
        require(
            privSoldTokenAmount <= privPresaleCap,
            "Insufficient Token Balance"
        );

        if (privUserExists(msg.sender)) {
            User storage user = privUsers[msg.sender];
            user.ethAmount = user.ethAmount.add(ethAmount);
            user.tbirdAmount = user.tbirdAmount.add(tbirdAmount);
            user.polygonWalletAddress = polygonWalletAddress;
        } else {
            privUsers[msg.sender] = User({
                ethAmount: ethAmount,
                tbirdAmount: tbirdAmount,
                polygonWalletAddress: polygonWalletAddress
            });
            privUserIDs[privUserCount] = msg.sender;

            privUserCount++;
        }

        privTotalPurchased = privTotalPurchased.add(ethAmount);
    }

    function buyPubTBIRD(address polygonWalletAddress) external payable {
        require(checkPubWhiteList(msg.sender), "Not white list user");

        uint256 ethAmount = msg.value;
        uint256 ethPrice = getETHPrice();
        uint256 usdAmount = ethAmount.mul(ethPrice).div(1e20);
        require(usdAmount >= pubPresaleMinLimit, "Less than minimun limit");

        uint256 tbirdAmount = usdAmount.mul(1e9).div(pubPresalePrice);
        pubSoldTokenAmount = pubSoldTokenAmount.add(tbirdAmount);
        require(
            pubSoldTokenAmount <= pubPresaleCap,
            "Insufficient Token Balance"
        );

        if (pubUserExists(msg.sender)) {
            User storage user = pubUsers[msg.sender];
            user.ethAmount = user.ethAmount.add(ethAmount);
            user.tbirdAmount = user.tbirdAmount.add(tbirdAmount);
            user.polygonWalletAddress = polygonWalletAddress;
        } else {
            pubUsers[msg.sender] = User({
                ethAmount: ethAmount,
                tbirdAmount: tbirdAmount,
                polygonWalletAddress: polygonWalletAddress
            });
            pubUserIDs[pubUserCount] = msg.sender;
            pubUserCount++;
        }

        pubTotalPurchased = pubTotalPurchased.add(ethAmount);
    }

    function privUserExists(address userAddress) public view returns (bool) {
        return (privUsers[userAddress].ethAmount != 0);
    }

    function pubUserExists(address userAddress) public view returns (bool) {
        return (pubUsers[userAddress].ethAmount != 0);
    }

    function privSaleUserInfo(uint256 index)
        public
        view
        returns (
            uint256 ethAmount,
            uint256 tbirdAmount,
            address polygonWalletAddress
        )
    {
        require(index < privUserCount, "Invalid index");

        return privSaleUserInfoFromAddress(privUserIDs[index]);
    }

    function privSaleUserInfoFromAddress(address userAddress)
        public
        view
        returns (
            uint256 ethAmount,
            uint256 tbirdAmount,
            address polygonWalletAddress
        )
    {
        require(privUserExists(userAddress), "Not exists");

        User memory user = privUsers[userAddress];

        ethAmount = user.ethAmount;
        tbirdAmount = user.tbirdAmount;
        polygonWalletAddress = user.polygonWalletAddress;
    }

    function pubSaleUserInfo(uint256 index)
        public
        view
        returns (
            uint256 ethAmount,
            uint256 tbirdAmount,
            address polygonWalletAddress
        )
    {
        require(index < pubUserCount, "Invalid index");

        return pubSaleUserInfoFromAddress(pubUserIDs[index]);
    }

    function pubSaleUserInfoFromAddress(address userAddress)
        public
        view
        returns (
            uint256 ethAmount,
            uint256 tbirdAmount,
            address polygonWalletAddress
        )
    {
        require(pubUserExists(userAddress), "Not exists");

        User memory user = pubUsers[userAddress];

        ethAmount = user.ethAmount;
        tbirdAmount = user.tbirdAmount;
        polygonWalletAddress = user.polygonWalletAddress;
    }

    function estimateAmount(uint256 ethAmount, uint256 price)
        public
        view
        returns (uint256, uint256)
    {
        uint256 ethPrice = getETHPrice();
        uint256 usdAmount = ethAmount.mul(ethPrice).div(1e20);
        uint256 tbirdAmount = usdAmount.mul(1e9).div(price);

        return (usdAmount, tbirdAmount);
    }

    function getETHPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeedETH.latestRoundData();

        return uint256(price);
    }

    function checkPrivWhiteList(address userAddress)
        public
        view
        returns (bool)
    {
        if (privWhiteList[userAddress]) return true;

        return false;
    }

    function checkPubWhiteList(address userAddress) public view returns (bool) {
        if (pubWhiteList[userAddress]) return true;

        return false;
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

        if (flag == 0) privPresaleStartTime = timestamp;
        else if (flag == 1) privPresaleEndTime = timestamp;
        else if (flag == 2) pubPresaleStartTime = timestamp;
        else if (flag == 3) pubPresaleEndTime = timestamp;
    }

    function setPrivPresaleCap(uint256 cap) public onlyOwner {
        privPresaleCap = cap;
    }

    function setPubPresaleCap(uint256 cap) public onlyOwner {
        pubPresaleCap = cap;
    }

    function setPrivPresaleMinLimit(uint256 _privPresaleMinLimit)
        public
        onlyOwner
    {
        privPresaleMinLimit = _privPresaleMinLimit;
    }

    function setPubPresaleMinLimit(uint256 _pubPresaleMinLimit)
        public
        onlyOwner
    {
        pubPresaleMinLimit = _pubPresaleMinLimit;
    }

    function addPrivWhiteList(address userAddress) public onlyOwner {
        require(checkPrivWhiteList(userAddress) != true, "Already exists");
        privWhiteList[userAddress] = true;
    }

    function removePrivWhiteList(address userAddress) public onlyOwner {
        require(checkPrivWhiteList(userAddress) == true, "No exist.");
        require(privUserExists(userAddress) == false, "Already purchased");
        privWhiteList[userAddress] = false;
    }

    function addPubWhiteList(address userAddress) public onlyOwner {
        require(checkPubWhiteList(userAddress) != true, "Already exists");
        pubWhiteList[userAddress] = true;
    }

    function removePubWhiteList(address userAddress) public onlyOwner {
        require(checkPubWhiteList(userAddress) == true, "No exist.");
        require(pubUserExists(userAddress) == false, "Already purchased");
        pubWhiteList[userAddress] = false;
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