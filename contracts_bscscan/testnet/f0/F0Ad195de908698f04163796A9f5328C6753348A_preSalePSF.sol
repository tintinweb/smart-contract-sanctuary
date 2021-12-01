/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
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

contract preSalePSF {
    using SafeMath for uint256;

    IBEP20 public token;
    AggregatorV3Interface public priceFeedbnb;
    address payable public owner;
    address payable public airDrop;

    uint256 public tokenPerBnb;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public refPercent;

    struct Ref {
        uint256 referralCount;
        uint256 refAmount;
    }

    mapping(address => uint256) public coinBalance;
    mapping(address => Ref) private refData;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);

    constructor(
        address payable _owner,
        address payable _airDrop,
        IBEP20 _token
    ) {
        owner = _owner;
        airDrop = _airDrop;
        token = _token;
        priceFeedbnb = AggregatorV3Interface(
            0x0630521aC362bc7A19a4eE44b57cE72Ea34AD01c
        );
        tokenPerBnb = 333;
        minAmount = 0.001 ether;
        maxAmount = 1000 ether;
        refPercent = 10;
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

    function buyTokenBnb(address _referrer) public payable {
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "PRESALE: invalid referrer"
        );
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PRESALE: PreSale time not met"
        );
        require(msg.value >= minAmount, "PRESALE: Amount less than min amount");
        require(
            coinBalance[msg.sender].add(msg.value) <= maxAmount,
            "PRESALE: Amount exceeds max limit"
        );

        uint256 numberOfTokens = bnbToToken(msg.value);
        token.transferFrom(owner, msg.sender, numberOfTokens);
        soldToken = soldToken.add(numberOfTokens);
        amountRaised = amountRaised.add(msg.value);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(msg.value);

        refData[_referrer].referralCount++;
        refData[_referrer].refAmount = refData[_referrer].refAmount.add(
            numberOfTokens.mul(refPercent).div(100)
        );
        token.transferFrom(
            airDrop,
            _referrer,
            numberOfTokens.mul(refPercent).div(100)
        );

        emit BuyToken(msg.sender, numberOfTokens);
    }

    function buyTokenBusd(address _referrer, uint256 _amount) public {
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "PRESALE: invalid referrer"
        );
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PRESALE: PreSale time not met"
        );
        uint256 bnbValue = busdToBnb(_amount);
        require(bnbValue >= minAmount, "PRESALE: Amount less than min amount");
        require(
            coinBalance[msg.sender].add(bnbValue) <= maxAmount,
            "PRESALE: Amount exceeds max limit"
        );
        token.transferFrom(msg.sender, owner, _amount);
        uint256 numberOfTokens = bnbToToken(bnbValue);
        token.transferFrom(owner, msg.sender, numberOfTokens);
        soldToken = soldToken.add(numberOfTokens);
        amountRaised = amountRaised.add(bnbValue);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(bnbValue);

        refData[_referrer].referralCount++;
        refData[_referrer].refAmount = refData[_referrer].refAmount.add(
            numberOfTokens.mul(refPercent).div(100)
        );
        token.transferFrom(
            airDrop,
            _referrer,
            numberOfTokens.mul(refPercent).div(100)
        );

        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to check number of token for given bnb
    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(tokenPerBnb);
        return numberOfTokens.mul(10**token.decimals()).div(1e18);
    }

    // to check number of bnb for given Busd
    function busdToBnb(uint256 _amount) public view returns (uint256 bnbValue) {
        bnbValue = _amount.mul(getLatestPricebnb()).div(1e18);
    }

    // to check number of token for given Busd
    function BusdToToken(uint256 _amount) public view returns (uint256 numberOfTokens) {
        uint256 bnbAmount = busdToBnb(_amount);
        numberOfTokens = bnbToToken(bnbAmount);
    }

    function getReferrerData(address _user)
        public
        view
        returns (uint256 _refCount, uint256 _refAmount)
    {
        return (refData[_user].referralCount, refData[_user].refAmount);
    }

    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokenPerBnb = _price;
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

    // change tokens
    function changeToken(address _token) external onlyOwner {
        token = IBEP20(_token);
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to draw out stuck tokens
    function transferTokens(IBEP20 _token, uint256 _value) external onlyOwner {
        _token.transfer(owner, _value);
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