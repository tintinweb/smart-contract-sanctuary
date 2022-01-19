/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

pragma solidity 0.8.10;

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

contract preSale {
    using SafeMath for uint256;
    IBEP20 public token;
    AggregatorV3Interface public priceFeedbnb;
    address payable public owner;
    
    uint256 public tokenPerUsd;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaisedBNB;
    bool    public Claimable;
    uint256 public totalParticipants;

    struct User {
        uint256 amount;
        uint256 UserAmount;
    }

    mapping(address => uint256) public coinBalance;
    mapping(address => uint256) public tokenBalance;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event Claimed(address indexed _user, uint256 indexed _amountClaimed);
    event BuyToken(address indexed _user, uint256 indexed _amountInvested);

    constructor(address payable _owner, IBEP20 _token) {
        owner = _owner;
        token = _token;
        priceFeedbnb = AggregatorV3Interface(
            //   0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        tokenPerUsd = 10;
        minAmount = 0.1 * 1e18;
        maxAmount = 0.5 * 1e18;
        preSaleStartTime = block.timestamp;
        preSaleEndTime = preSaleStartTime + 30 days;
         
    }

    receive() external payable {}

    // to get real time price of bnb
    function getLatestPricebnb() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedbnb.latestRoundData();
        return uint256(price).div(1e8);
    }

    // to buy token during preSale time => for web3 use

    function buyToken() public payable {
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
            msg.value >= minAmount,
            "PRESALE: Amount not correct"
        );
          require(
            coinBalance[msg.sender].add(msg.value) <= maxAmount,
            "PRESALE: Amount not correct"
        );
        uint256 numberOfTokens = bnbToToken(msg.value);
        soldToken = soldToken.add(numberOfTokens);
        amountRaisedBNB = amountRaisedBNB.add(msg.value);
        if (tokenBalance[msg.sender] == 0) {
            totalParticipants += 1;
        }
        coinBalance[msg.sender] = coinBalance[msg.sender].add(msg.value);
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);

        emit BuyToken(msg.sender, msg.value);
    }

    function claim() public {
        require(Claimable == true, "PRESALE: Claim not started.");
        require(tokenBalance[msg.sender] > 0, "PRESALE: Insufficient Balance.");

        token.transferFrom(owner, msg.sender, tokenBalance[msg.sender]);
        tokenBalance[msg.sender] = 0;
        emit Claimed(msg.sender, tokenBalance[msg.sender]);
    }

    // to check number of token for given bnb
    function bnbToToken(uint256 _amountInvested) public view returns (uint256) {
        uint256 bnbToUsd = _amountInvested.mul(getLatestPricebnb()).div(1e18);
        uint256 numberOfTokens = bnbToUsd.mul(tokenPerUsd);
        return numberOfTokens.mul(10**token.decimals());
    }

    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokenPerUsd = _price;
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

    function ClaimableState(bool _state) external onlyOwner {
        Claimable = _state;
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