/**
 *Submitted for verification at BscScan.com on 2021-11-23
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

contract PreSale {
    using SafeMath for uint256;

    IBEP20 public token;
    AggregatorV3Interface public priceFeedbnb;

    address payable public owner;

    uint256 public tokenPerUsd;
    uint256 public minAmount;
    uint256 public maxAmount;
    bool public preSaleEnabled;
    uint256 public boughtToken;
    uint256 public soldToken;
    uint256 public amountRaisedBNB;
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
    
    constructor() {
        owner = payable(0x71495a3fa8093824E7ac896f00b5Dd05C5CA6354);
        token =IBEP20(0x6F0C374a284C413155Ae74bC05065181bd5A7619);
        priceFeedbnb = AggregatorV3Interface(
            0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
        );
        tokenPerUsd = 148;
        minAmount = 0.001 ether;
        maxAmount =  10 ether;
        preSaleEnabled = true;
        CTOpercentage = 5;
        sellTax = 5;
        holdPercentage  = 1;
        CTOinvestment = 1400;
        CTOtriggredAt = block.timestamp;
        totalUsers = 0;
    }

    receive() external payable {}

    // to get real time price of bnb
    function getLatestPricebnb() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedbnb.latestRoundData();
        return uint256(price).div(1e8);
    }

    // to buy token during preSale time => for web3 use

    function buy(address _referrer) public payable {
        uint256 BNBval = uint256(msg.value);
        require(
            _referrer != address(0) && _referrer != msg.sender,
            "PRESALE: invalid referrer"
        );
        require(
            preSaleEnabled,
            "PRESALE: PreSale not Enabled"
        );
        require(
            BNBval >= minAmount && BNBval <= maxAmount,
            "PRESALE: Amount not correct"
        );
        if(!userData[msg.sender].registerd){
            userData[msg.sender].registerd = true;
            users.push(msg.sender);
            userData[_referrer].referralCount++;
            totalUsers++;
        }
        uint256 numberOfTokens = bnbToToken(BNBval);
        token.transferFrom(owner, msg.sender, numberOfTokens);
        boughtToken = boughtToken.add(numberOfTokens);
        amountRaisedBNB = amountRaisedBNB.add(BNBval);
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
        uint256 ethAmount = tokenToBNB(sendAmount);
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

    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 bnbToUsd = _amount.mul(getLatestPricebnb()).div(1e18);
        uint256 numberOfTokens = bnbToUsd.mul(tokenPerUsd);
        return numberOfTokens.mul(10**token.decimals());
    }
    // to check number of ETH for given token
    function tokenToBNB(uint256 _amount) public view returns (uint256) {

            return _amount.mul(1 ether).div(getLatestPricebnb()).div(10**token.decimals()).div(tokenPerUsd);
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
    
    function tokenChange(address _addr)external onlyOwner returns(bool){
        
        token = IBEP20(_addr);
        
        return true;
    }

    function AggregetorChange(address _addr)external onlyOwner returns(bool){
        
        priceFeedbnb = AggregatorV3Interface(
            _addr
        );
        
        return true;
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

    function contractBalanceBNB() external view returns (uint256) {
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