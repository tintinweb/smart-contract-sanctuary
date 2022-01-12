/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

pragma solidity ^0.8.9;

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
    AggregatorV3Interface public priceFeedbnb;
    IBEP20 public token;
    IBEP20 public busd;
    address payable public owner;

    uint256 public tokenPerUsd;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public totalSupply;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaisedBusd;
    uint256 public totalParticipants;

    address[] public users;

    struct User {
        uint256 amount;
        uint256 UserAmount;
    }
    mapping(address => uint256) public coinBalance;
    mapping(address => uint256) public tokenBalance;
    mapping(address => bool) public whitelistUsers;
  
    bool public switchMethod;
    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(
        address indexed _user,
        uint256 indexed _amountInvested,
        uint256 indexed _amountRecieved
    );

    constructor(
        address _owner,
        address _token,
        address _busdToken
    ) {
        owner = payable(_owner);
        token = IBEP20(_token);
        busd = IBEP20(_busdToken);
        priceFeedbnb = AggregatorV3Interface(
            // mainnet
            // 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
            // testnet
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        tokenPerUsd = 5000;
        minAmount = 0.05 ether;
        maxAmount = 5 ether;
        totalSupply = 1900000 * (10**token.decimals());
        preSaleStartTime = block.timestamp;
        preSaleEndTime = preSaleStartTime + 30 days;
    }

    // to buy token during preSale time => for web3 use
    function buyTokenBnb() public payable {
        require(switchMethod==true,"current method of buying is with BUSD");
        require(whitelistUsers[msg.sender], "Presale: Cant buy tokens.");
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PRESALE: PreSale time not met"
        );
        require(
            coinBalance[msg.sender] + (msg.value) <= maxAmount,
            "PRESALE: Amount exceeds max limit"
        );
        require(msg.value >= minAmount, "PRESALE: Amount less than min limit");

        if (tokenBalance[msg.sender] == 0) {
            users.push(msg.sender);
        }
        uint256 numberOfTokens = bnbToToken(msg.value);
        soldToken = soldToken + (numberOfTokens);
        amountRaisedBusd = amountRaisedBusd + (msg.value);
        if (tokenBalance[msg.sender] == 0) {
            totalParticipants += 1;
        }
        coinBalance[msg.sender] =
            coinBalance[msg.sender] +
            ((msg.value * (getLatestPriceBnb())) /
                (10**priceFeedbnb.decimals()));
        tokenBalance[msg.sender] = tokenBalance[msg.sender] + (numberOfTokens);

        emit BuyToken(msg.sender, msg.value, numberOfTokens);
    }

    // to buy token during preSale time => for web3 use
    function buyToken(uint256 _amountBusd) public {
        require(switchMethod==false,"current method of buying is with BNB");
        require(whitelistUsers[msg.sender], "Presale: Cant buy tokens.");
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PRESALE: PreSale time not met"
        );
        require(
            coinBalance[msg.sender] + (_amountBusd) <= maxAmount,
            "PRESALE: Amount exceeds max limit"
        );
        require(
            _amountBusd >= minAmount,
            "PRESALE: Amount less than min limit"
        );

        busd.transferFrom(msg.sender, owner, _amountBusd);
        if (tokenBalance[msg.sender] == 0) {
            users.push(msg.sender);
        }
        uint256 numberOfTokens = busdToToken(_amountBusd);
        soldToken = soldToken + (numberOfTokens);
        amountRaisedBusd = amountRaisedBusd + (_amountBusd);
        if (tokenBalance[msg.sender] == 0) {
            totalParticipants += 1;
        }
        coinBalance[msg.sender] = coinBalance[msg.sender] + (_amountBusd);
        tokenBalance[msg.sender] = tokenBalance[msg.sender] + (numberOfTokens);
        emit BuyToken(msg.sender, _amountBusd, numberOfTokens);
    }

    // to check number of token for given Busd
    function busdToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount * (tokenPerUsd);
        return (numberOfTokens * (10**token.decimals())) / (busd.decimals());
    }

    // to check number of token for given Bnb
    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = (_amount *
            (getLatestPriceBnb()) *
            (tokenPerUsd)) / (10**priceFeedbnb.decimals());
        return (numberOfTokens * (10**token.decimals())) / (1e18);
    }

    // to extract data for CSV
    function getUserLength() public view returns (uint256) {
        uint256 _total;
        _total = users.length;
        return _total;
    }

    // get real time price of bnb in usd
    function getLatestPriceBnb() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedbnb.latestRoundData();
        return uint256(price);
    }

    function SwitchMethod(bool _state)public onlyOwner{
        switchMethod = _state;
    }
    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokenPerUsd = _price;
    }

    // updated whitelisters who can buy tokens.
    function setWhitelistUsers(address[] memory _users, bool _value)
        external
        onlyOwner
    {
        require(_users.length > 0, "PRESALE: Empty Data.");

        for (uint256 i = 0; i < _users.length; i++) {
            whitelistUsers[_users[i]] = _value;
        }
    }

    // to change preSale amount limits
    function setPreSaletLimits(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _totalSupply
    ) external onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        totalSupply = _totalSupply;
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

    // change busd
    function changeCoin(address _coin) external onlyOwner {
        busd = IBEP20(_coin);
    }

    // change feed
    function changeFeed(address _feed) external onlyOwner {
        priceFeedbnb = AggregatorV3Interface(_feed);
    }

    // get sale progress
    function getProgress() public view returns (uint256 _percent) {
        uint256 remaining = totalSupply * (soldToken);
        remaining = (remaining * (100)) / (totalSupply);
        uint256 hundred = 100;
        return hundred * (remaining);
    }

    // to draw out tokens
    function transferTokens(address _token, uint256 _value) external onlyOwner {
        IBEP20(_token).transfer(owner, _value);
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    // to get current UTC time
    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    // get contract token balance
    function contractBalance(address _token) external view returns (uint256) {
        return IBEP20(_token).balanceOf(address(this));
    }

    // get contract token allowances
    function getContractTokenApproval() external view returns (uint256) {
        return token.allowance(owner, address(this));
    }
}