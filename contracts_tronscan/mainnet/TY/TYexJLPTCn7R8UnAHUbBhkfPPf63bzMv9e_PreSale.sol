//SourceUnit: presaleImran.sol

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT Licensed

interface ITRC20 {
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

interface AggregatorInterface {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);
}

contract PreSale {
    using SafeMath for uint256;

    ITRC20 public token;
    AggregatorInterface public priceFeed;

    address payable public owner;

    uint256 public tokenPerUsd;
    uint256 public minAmount;
    uint256 public maxAmount;
    bool public preSaleEnabled;
    uint256 public boughtToken;
    uint256 public soldToken;
    uint256 public amountRaisedtrx;
    uint256 [4] public refPercent = [10,15,20,30];
    uint256 [4] public refamounts = [0,3000,7000,1400];
    uint256 public totalUsers;
    uint256 public CTOAmount;
    uint256 public CTOpercentage;
    uint256 public CTOtriggredAt;
    uint256 public CTOinvestment;
    uint256 public sellTax;
    uint256 public holdPercentage;
    uint256 public clubReward;
    uint256 public constant percentDivider = 100;
    address [] public users;
    
    struct User{
        uint256 referralCount;
        uint256 refAmount;
        uint256 buytime;
        uint256 selltime;
        uint256 personalAmount;
        bool registerd;
    }
    
    // mapping(address => uint256) public coinBalance;
    mapping(address => User) public userData;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event BuyToken(address indexed _user, uint256 indexed _amount);
    event SellToken(address indexed _user, uint256 indexed _amount);
    
    constructor( address payable _owner,address _token , address Aggregator,uint256 minamounttrx,uint256 maxamounttrx) {
        owner = _owner;
        token =ITRC20( _token );
        priceFeed = AggregatorInterface(
            Aggregator
        );
        tokenPerUsd = 148;
        minAmount = minamounttrx;
        maxAmount =  maxamounttrx;
        preSaleEnabled = true;
        CTOpercentage = 5;
        sellTax = 5;
        holdPercentage  = 1;
        CTOinvestment = 1400;
        CTOtriggredAt = block.timestamp;
        totalUsers = 0;
    }

    receive() external payable {}

    function getLatestPricetrx() public view returns (uint256) {
        // If the round is not complete yet, timestamp is 0
        require(priceFeed.latestTimestamp() > 0, "Round not complete");
        uint256 price = uint256(priceFeed.latestAnswer()*1);
        return price;
    }

    // to buy token during preSale time => for web3 use

    function buy(address _referrer) public payable {
        uint256 trxval = uint256(msg.value);
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "PRESALE: invalid referrer"
        );
        require(
            preSaleEnabled,
            "PRESALE: PreSale not Enabled"
        );
        require(
            trxval >= minAmount && trxval <= maxAmount,
            "PRESALE: Amount not correct"
        );
        if(!userData[msg.sender].registerd){
            userData[msg.sender].registerd = true;
            users.push(msg.sender);
            userData[_referrer].referralCount++;
            totalUsers++;
        }
        uint256 numberOfTokens = trxToToken(trxval);
        token.transferFrom(owner, msg.sender, numberOfTokens);
        boughtToken = boughtToken.add(numberOfTokens);
        amountRaisedtrx = amountRaisedtrx.add(trxval);
        userData[_referrer].refAmount = userData[_referrer].refAmount.add(numberOfTokens);
        if(userData[_referrer].refAmount >= refamounts[0].mul(tokenPerUsd).mul(10**token.decimals()) && userData[_referrer].refAmount <= refamounts[1].mul(tokenPerUsd).mul(10**token.decimals())){
            token.transferFrom(owner, _referrer, numberOfTokens.mul(refPercent[0]).div(percentDivider));
        }else if(userData[_referrer].refAmount >= refamounts[1].mul(tokenPerUsd).mul(10**token.decimals()) && userData[_referrer].refAmount <= refamounts[2].mul(tokenPerUsd).mul(10**token.decimals())){
            token.transferFrom(owner, _referrer, numberOfTokens.mul(refPercent[1]).div(percentDivider));
        }else if(userData[_referrer].refAmount >= refamounts[2].mul(tokenPerUsd).mul(10**token.decimals()) && userData[_referrer].refAmount <= refamounts[3].mul(tokenPerUsd).mul(10**token.decimals())){
            token.transferFrom(owner, _referrer, numberOfTokens.mul(refPercent[2]).div(percentDivider));
        }else if(userData[_referrer].refAmount >= refamounts[3].mul(tokenPerUsd).mul(10**token.decimals())){
            token.transferFrom(owner, _referrer, numberOfTokens.mul(refPercent[3]).div(percentDivider));
        }
        userData[msg.sender].personalAmount = userData[msg.sender].personalAmount.add(numberOfTokens);
        userData[msg.sender].buytime = block.timestamp;
        
        emit BuyToken(msg.sender, numberOfTokens);
    }
    function sell(uint256 _amount) public {
        uint256 sendAmount = _amount.mul(100-sellTax).div(percentDivider);
        uint256 ethAmount = tokenTotrx(sendAmount);
        require(
            preSaleEnabled,
            "PRESALE: PreSale not Enabled"
        );
        require(
            ethAmount <= address(this).balance,
            "Insufficent Contract Funds"
        );
        if(userData[msg.sender].buytime + 30 days <= block.timestamp && userData[msg.sender].buytime < userData[msg.sender].selltime ){
            token.transferFrom(msg.sender, owner, boughtToken.mul(holdPercentage).div(percentDivider));
        }
        token.transferFrom(msg.sender, owner, _amount);
        payable(msg.sender).transfer(ethAmount);
        soldToken = soldToken.add(_amount);
        clubReward = clubReward.add(_amount.mul(sellTax).div(percentDivider));
        userData[msg.sender].selltime = block.timestamp;
        emit SellToken(msg.sender, _amount);
    }
    function sendToCTO() external onlyOwner {
        require(
            CTOtriggredAt + 30 days <= block.timestamp,
            "PRESALE: PreSale Enabled"
        );
        require(boughtToken > tokenPerUsd.mul(CTOinvestment),"not one Capable of CTO yet");
        CTOAmount = boughtToken.mul(CTOpercentage).div(percentDivider);
        uint256 ctocount;
        for(uint256 i; i < totalUsers ; i ++){
            if(userData[users[i]].referralCount >2 && userData[users[i]].personalAmount > tokenPerUsd.mul(CTOinvestment)){
                ctocount++;
            }
        }
        if(ctocount > 0)
        {
            for(uint256 i; i < totalUsers ; i ++){
            if(userData[users[i]].referralCount >2 && userData[users[i]].personalAmount > tokenPerUsd.mul(CTOinvestment)){
                token.transferFrom(owner, users[i], CTOAmount.div(ctocount));
            }
        }
        }
        CTOtriggredAt = block.timestamp;
    }

    // to check number of token for given trx
    function trxToToken(uint256 _amount) public view returns (uint256) {
        uint256 trxToUsd = _amount.mul(getLatestPricetrx()).div(1e10);
        uint256 numberOfTokens = trxToUsd.mul(tokenPerUsd);
        return numberOfTokens.mul(10**token.decimals()).div(1e2);
    }
    // to check number of ETH for given token
    function tokenTotrx(uint256 _amount) public view returns (uint256) {

            return _amount.mul(1e12).div(getLatestPricetrx()).div(10**token.decimals()).div(tokenPerUsd);
    }
    function getReferrerData(address _user) public view returns(uint256 _refCount, uint256 _refAmount){
        return (userData[_user].referralCount, userData[_user].refAmount);
    }

    // to change Price of the token
    function changePrice(uint256 _price) external onlyOwner {
        tokenPerUsd = _price;
    }
    
    function changeRefPercent(uint256 [4] memory _percent) external onlyOwner {
        refPercent = _percent;
    }
    function changeRefAmounts(uint256 [4] memory _amounts) external onlyOwner {
        refamounts = _amounts;
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
    function setPreSale(bool _set)
        external
        onlyOwner
    {
        preSaleEnabled = _set;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    
    // change tokens
    function changeToken(address _token) external onlyOwner{
        token = ITRC20(_token);
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

    function contractBalancetrx() external view returns (uint256) {
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