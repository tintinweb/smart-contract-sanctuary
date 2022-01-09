/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

pragma solidity ^0.8.7;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
}

contract TeamPresaleContract {
    using SafeMath for uint256;
    using Address for address;

    IBEP20 public token;
    address payable public owner1;
    address payable public owner2;

    uint256 public tokenPerBnb;
    uint256 public minAmount;
    uint256 public maxAmount;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public totalSupply;
    uint256 public firstClaimPercentage = 50;
    uint256 public teamClaimDays = 705;
    uint256 public TIME_STEP = 1 minutes;
    uint256 public owner1Fee = 600;
    uint256 public owner2Fee = 400;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public BASE_PERCENT = 10;
    bool public isClaimEnabled;
    uint256 public claimStartTime;

    uint256[4] public refPercent = [20, 23, 30, 30];
    uint256[3] public refLimit = [10 ether, 20 ether, 30 ether];

    bool public isTeamSaleEnable;

    struct refData {
        uint256 refBalance;
        uint256 refcount;
        uint256 refEarning;
    }

    mapping(address => uint256) public tokenBalance;
    mapping(address => uint256) public claimedBalance;
    mapping(address => uint256) public coinBalance;
    mapping(address => refData) public refDataStore;
    mapping(address => bool) public teamlist;
    mapping(address => uint256) public claimTime;
    mapping(address => bool) public firstClaim;
    mapping(address => uint256) public base_amount;

    modifier onlyOwner() {
        require(msg.sender == owner1, "PreSale: Not an owner");
        _;
    }

    modifier isTeamMember(address _user) {
        require(teamlist[_user], "PreSale: Not a team member");
        _;
    }

    modifier isContract(address _user) {
        require(!address(_user).isContract(), "PreSale: contract can not buy");
        _;
    }

    event BuyToken(address _user, uint256 _amount);

    constructor(address payable _owner1, address payable _owner2, IBEP20 _token) {
        owner1 = _owner1;
        owner2 = _owner2;
        token = _token;
        totalSupply = 8000000000 * 1e18;
        tokenPerBnb = 1000;
        minAmount = 0.01 ether;
        maxAmount = 10 ether;
        preSaleStartTime = block.timestamp;
        preSaleEndTime = block.timestamp + 4 hours;
        isTeamSaleEnable = true;
    }

    receive() external payable {}

    // to buy token during team preSale time => for web3 use
    function buyTokenTeam(uint256 _amountOfBnb)
        public
        isTeamMember(msg.sender)
        isContract(msg.sender)
    {
        require(isTeamSaleEnable,"PreSale: Sale disbaled");
        require(_amountOfBnb >= minAmount, "PreSale: Amount less than minimum");
        require(
            coinBalance[msg.sender].add(_amountOfBnb) <= maxAmount,
            "PreSale: Amount exceeded max buy limit"
        );
        require(
            block.timestamp >= preSaleStartTime &&
                block.timestamp < preSaleEndTime,
            "PreSale: PreSale over"
        );

        uint256 numberOfTokens = bnbToToken(_amountOfBnb);
        token.transferFrom(owner1, address(this), numberOfTokens);
        tokenBalance[msg.sender] = tokenBalance[msg.sender].add(numberOfTokens);
        coinBalance[msg.sender] = coinBalance[msg.sender].add(_amountOfBnb);
        soldToken = soldToken.add(numberOfTokens);
        amountRaised = amountRaised.add(_amountOfBnb);

        emit BuyToken(msg.sender, numberOfTokens);
    }

    // to claim tokens in vesting => for web3 use
    function claim() public {
        require(isClaimEnabled && (block.timestamp > claimStartTime), "Presale: Claim not started yet");
        require(tokenBalance[msg.sender] > 0, "Presale: Insufficient Balance");
        require(claimedBalance[msg.sender] < tokenBalance[msg.sender], "Presale: Already claimed.");
        require (block.timestamp > claimTime[msg.sender] + TIME_STEP, "Presale: Wait for next claim.");
        
        // Transfer 25% on first claim.
        if(block.timestamp > claimStartTime && !firstClaim[msg.sender]){
            uint256 firstPurchase = tokenBalance[msg.sender].mul(firstClaimPercentage).div(PERCENTS_DIVIDER);
            token.transferFrom(owner1, msg.sender, firstPurchase);
            claimedBalance[msg.sender] = claimedBalance[msg.sender].add(firstPurchase);
            
            claimTime[msg.sender] = block.timestamp;
            // Setting daily percentage for user.
            base_amount[msg.sender] = (tokenBalance[msg.sender].sub(firstPurchase)).div(teamClaimDays);
            firstClaim[msg.sender] = true;
        } else {
            // set First Timestamp after claim start.
            uint256 timestamp = claimTime[msg.sender];
            if(timestamp == 0) {
                timestamp = claimStartTime;
            }
            require (block.timestamp > timestamp + TIME_STEP, "Presale: Wait for next claim.");
            
            uint256 multiplier = block.timestamp.sub(timestamp).div(TIME_STEP);
            uint256 dividends = base_amount[msg.sender].mul(multiplier);
            claimTime[msg.sender] = block.timestamp;
            if(claimedBalance[msg.sender].add(dividends) > tokenBalance[msg.sender]){
                dividends = tokenBalance[msg.sender].sub(claimedBalance[msg.sender]);
            }
            token.transferFrom(owner1, msg.sender, dividends);
            claimedBalance[msg.sender] = claimedBalance[msg.sender].add(dividends); 

        }
    }

    function bnbToToken(uint256 _amount) public view returns (uint256) {
        uint256 numberOfTokens = _amount.mul(tokenPerBnb);
        return numberOfTokens;
    }

    function getProgress() public view returns (uint256 _percent) {
        uint256 remaining = totalSupply.sub(soldToken);
        remaining = remaining.mul(100).div(totalSupply);
        uint256 hundred = 100;
        return hundred.sub(remaining);
    }

    function startClaim() public onlyOwner {
        require(block.timestamp > preSaleEndTime && !isClaimEnabled, "Presale: Not over yet.");
        isClaimEnabled = true;
        claimStartTime = block.timestamp;
    }

    function setTeamUsers(address[] memory _users, bool _value) external onlyOwner {
        for(uint256 i = 0; i < _users.length; i++) {
            teamlist[_users[i]] = _value;
        }
    }

    // to change Price of the token
    function changePrice(uint256 _tokenPerBnb) external onlyOwner {
        tokenPerBnb = _tokenPerBnb;
    }

    function setAmountLimits(
        uint256 _minAmount,
        uint256 _maxAmount,
        uint256 _total
    ) external onlyOwner {
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        totalSupply = _total;
    }

    function setFirstClaimPercent(uint256 _percentage) external onlyOwner {
        firstClaimPercentage = _percentage;
    }

    function setTeamClaimDays(uint256 _days) external onlyOwner {
        teamClaimDays = _days;
    }

    function setDurationForEveryClaim(uint256 _time) external onlyOwner {
        TIME_STEP = _time;
    }

    function setTeamPreSale(bool _value, uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        isTeamSaleEnable = _value;
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
        isClaimEnabled = false;
        claimStartTime = 0;
    }

    function setRefPercent(
        uint256 _percent1,
        uint256 _percent2,
        uint256 _percent3,
        uint256 _percent4
    ) external onlyOwner {
        refPercent[0] = _percent1;
        refPercent[1] = _percent2;
        refPercent[2] = _percent3;
        refPercent[3] = _percent4;
    }

    function setRefLimit(
        uint256 _limit1,
        uint256 _limit2,
        uint256 _limit3
    ) external onlyOwner {
        refLimit[0] = _limit1;
        refLimit[1] = _limit2;
        refLimit[2] = _limit3;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        owner1 = _newOwner;
    }

    function getTokenInfo(address _user) public view returns(
        uint256 claimable,
        uint256 remaining,
        uint256 claimed
    ) {
        uint256 dividends;
        uint256 firstClaimAmnt;

        if(!firstClaim[_user]) {
            firstClaimAmnt = tokenBalance[_user].mul(firstClaimPercentage).div(PERCENTS_DIVIDER);            
        }
        
        // Calculate dividens if claim is started.
        if (firstClaim[_user] && (isClaimEnabled || claimStartTime > 0)) {
            
            // Get user's total amount till today.
            dividends = getDividends(_user);
            
            if(claimedBalance[_user].add(dividends) > tokenBalance[_user]){
                dividends = tokenBalance[_user].sub(claimedBalance[_user]);
            } 
        }

        return (
            dividends.add(firstClaimAmnt),
            tokenBalance[_user],
            claimedBalance[_user]
        );
    }

    function getDividends(address _user) public view returns (uint256) {
        uint256 dividends;
        uint256 timestamp = claimTime[_user];
        // Calculating dividens.
        if(timestamp == 0) {
            timestamp = claimStartTime;
        }

        uint256 baseAmount = base_amount[_user];
        // Daily percentage of user.
        if(baseAmount == 0){
            baseAmount = (tokenBalance[_user]
                            .sub(tokenBalance[_user].mul(firstClaimPercentage)
                            .div(PERCENTS_DIVIDER)))
                            .div(teamClaimDays);
        }

        // calculate dividens
        uint256 timeStep = block.timestamp.sub(timestamp);
        dividends = baseAmount.mul(timeStep).div(TIME_STEP);

        return dividends;
    }

    function changeToken(address _token) external onlyOwner {
        token = IBEP20(_token);
    }

    // to draw funds for liquidity
    function transferFunds(uint256 _value) external onlyOwner returns (bool) {
        owner1.transfer(_value);
        return true;
    }

    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    function contractBalanceBnb() external view returns (uint256) {
        return address(this).balance;
    }

    function getContractTokenBalance() external view returns (uint256) {
        return token.allowance(owner1, address(this));
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