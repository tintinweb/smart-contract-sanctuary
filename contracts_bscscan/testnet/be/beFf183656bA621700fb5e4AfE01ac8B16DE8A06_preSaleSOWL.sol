/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

pragma solidity ^0.8.6;

//SPDX-License-Identifier: MIT Licensed

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

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

contract preSaleSOWL {
    using SafeMath for uint256;

    IERC20 public token;
    AggregatorV3Interface public priceFeedbnb;

    address payable public owner;

    uint256 public tokensPerbnb;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaisedbnb;
    uint256 public refPercent;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }
    
    mapping(address => uint256) public coinBalance;

    event BuyToken(address indexed _user, uint256 indexed _amount);

    constructor(address payable _owner, IERC20 _token) {
        owner = _owner;
        token = _token;
        priceFeedbnb = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        tokensPerbnb = 5000;
        minAmount = 0.05 ether;
        maxAmount = 5 ether;
        refPercent = 5;
        preSaleStartTime = block.timestamp;
        preSaleEndTime = preSaleStartTime + 30 days;
    }

    receive() external payable {}

    // to get real time price of bnb
    function getLatestPricebnb() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedbnb.latestRoundData();
        return uint256(price);
    }

    // to buy token during preSale time => for web3 use

    function buyToken(address _referrer) public payable {
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "PRESALE: invalid referrer"
        );
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PRESALE: PreSale time not met"
        );
        require(
            coinBalance[msg.sender].add(msg.value) <= maxAmount,
            "PRESALE: Amount exceeds max limit"
        );
        require(
            msg.value >= minAmount && msg.value <= maxAmount,
            "PRESALE: Amount not correct"
        );
        
        uint256 numberOfTokens = bnbToToken(msg.value);
        token.transferFrom(owner, msg.sender, numberOfTokens);
        token.transferFrom(owner, _referrer, numberOfTokens.mul(refPercent).div(100));
        soldToken = soldToken.add(numberOfTokens);
        amountRaisedbnb = amountRaisedbnb.add(msg.value);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(msg.value);

        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to check number of token for given bnb
    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 bnbToUsd = _amount.mul(getLatestPricebnb());
        uint256 numberOfTokens = bnbToUsd.mul(tokensPerbnb);
        return numberOfTokens.div(1e8).div(1e6);
    }

    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokensPerbnb = _price;
    }
    
    function changeRefPercent(uint256 _percent) external onlyOwner {
        refPercent = _percent;
    }

    // to change preSale amount limits
    function setPreSaletLimits(uint256 _minAmount, uint256 _maxAmount)
        external
        onlyOwner
    {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
    }

    // to change preSale time duration
    function setPreSaleTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out tokens
    function transferTokens(uint256 _value) external onlyOwner {
        token.transfer(owner, _value);
    }

    // to get current UTC time
    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function contractBalancebnb() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenApproval() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}