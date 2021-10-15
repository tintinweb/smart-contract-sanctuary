// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./AggregatorV3Interface.sol";
import "./IYoNFT.sol";

contract YoPresale is AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    AggregatorV3Interface internal priceFeed;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 startTime;
    uint256 endTime;
    uint256 totalNum;
    uint256 boxNum;
    uint256 curPrice = 50;
    uint256 tokenPrice = 1;
    uint256 openLimit = 30;

    IERC20 public token;
    IYoNFT public yo;
    address public fund;

    mapping(address => uint256) private countList;

    receive() external payable {}

    event OpenBox(
        uint256[] rewards,
        address indexed owner,
        uint256 openNum,
        uint256 leftBoxNum,
        uint256 ownerLimit,
        uint256 yoConsume,
        uint256 balanceConsume
    );

    constructor(
        address token_,
        address yo_,
        address fund_,
        bool isTestnet
    ) public {
        token = IERC20(token_);
        yo = IYoNFT(yo_);
        fund = fund_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        address addr = isTestnet
            ? 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
            : 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        priceFeed = AggregatorV3Interface(addr);
    }

    function addBox(
        uint256 _startTime,
        uint256 _endTime,
        uint256 addAmount,
        uint256 price,
        uint256 _tokenPrice,
        uint256 limit
    ) public {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        require(_startTime > 0, "Invalid startTime");
        require(_endTime > 0 && _endTime > _startTime, "Invalid endTime");
        require(addAmount >= 0, "Invalid amount");
        require(price > 0, "Invalid price");
        require(_tokenPrice >= 0, "Invalid tokenPrice");
        require(limit > 0, "Invalid limit");
        startTime = _startTime;
        endTime = _endTime;
        totalNum = totalNum.add(addAmount);
        boxNum = boxNum.add(addAmount);
        curPrice = price;
        tokenPrice = _tokenPrice;
        openLimit = limit;
    }

    function withdraw(address payable addr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Permission denied");
        addr.transfer(address(this).balance);
    }

    function openBox(uint256 num) external payable {
        require(boxNum > 0, "Sold out");
        require(block.timestamp >= startTime, "Pre-sale has not yet started");
        require(num >= 1 && num <= 10, "Maximum of 10 at a time");
        require(
            countList[msg.sender].add(num) <= openLimit,
            "Purchase limit reached"
        );
        require(boxNum > num, "Box not enough");
        require(curPrice > 0, "No price available");

        uint256 latestPrice = uint256(getLatestPrice());
        require(latestPrice > 0, "Invalid price");
        uint256 totalPrice = curPrice.mul(num).mul(1e8).mul(1e18).div(
            latestPrice
        );
        require(msg.value >= totalPrice, "Bid inadequate");
        uint256 totalToken = tokenPrice.mul(num).mul(1e18);
        if (totalToken > 0) {
            require(
                token.transferFrom(msg.sender, fund, totalToken),
                "Token transfer failed"
            );
        }
        boxNum = boxNum.sub(num);
        countList[msg.sender] = countList[msg.sender].add(num);

        uint256[] memory yoloList = new uint256[](10);
        for (uint8 i = 0; i < num; i++) {
            yoloList[i] = yo.mintGenesis(msg.sender);
        }
        emit OpenBox(
            yoloList,
            msg.sender,
            num,
            boxNum,
            openLimit.sub(countList[msg.sender]),
            totalToken,
            msg.value
        );
    }

    function getLatestPrice() public view returns (int256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function getLatestData(address sender)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 ownerLimit = 0;
        if (countList[sender] < openLimit) {
            ownerLimit = openLimit.sub(countList[sender]);
        }
        return (
            startTime,
            endTime,
            curPrice,
            tokenPrice,
            totalNum,
            boxNum,
            openLimit,
            ownerLimit,
            uint256(getLatestPrice())
        );
    }
}