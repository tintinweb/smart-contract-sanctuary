/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        assert(a == b * c + a % b);
        // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


pragma solidity 0.8.6;

abstract contract Ownable {
    address payable owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

pragma solidity 0.8.6;

contract Whitelisted is Ownable {
    mapping(address => uint8) public whitelist;
    mapping(address => bool) public provider;

    // Only whitelisted
    modifier onlyWhitelisted {
        require(isWhitelisted(msg.sender));
        _;
    }
    // Set purchaser to whitelist with zone code
    function joinWhitelist(address _purchaser, uint8 _zone) public {
        whitelist[_purchaser] = _zone;
    }
    // Delete purchaser from whitelist
    function deleteFromWhitelist(address _purchaser) public onlyOwner {
        whitelist[_purchaser] = 0;
    }
    // Check if purchaser is whitelisted : return true or false
    function isWhitelisted(address _purchaser) public view returns (bool){
        return whitelist[_purchaser] > 0;
    }
}

pragma solidity 0.8.6;

interface SwampWolfToken {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function burnUnsoldPresale(uint256 amount) external;
}

pragma solidity 0.8.6;

contract SwampWolfPresale is Ownable, Whitelisted {
    using SafeMath for uint256;

    uint256 public startTime;
    uint256 public endTime;
    mapping(address => uint256) public BuyerList;
    uint256 public MAX_BUY_LIMIT = 10000000000000000001;
    uint16 public referralReward = 300;
    uint256 public rate = 243e1;
    uint256 public weiRaised;
    bool public isPresaleStopped = false;
    bool public isPresalePaused = false;
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Transferred(address indexed purchaser, address indexed referral, uint256 amount);
    SwampWolfToken public token;

    constructor(
        SwampWolfToken _swampWolf,
        uint256 _startTime,
        uint256 _endTime
    ) {
        token = _swampWolf;
        startTime = _startTime;
        endTime = _endTime;
        require(endTime >= startTime);
    }

    fallback() external payable {
        buy(msg.sender, owner);
    }

    receive() external payable {}

    function isContract(address _addr) public view returns (bool _isContract){
        uint32 size;
        assembly {size := extcodesize(_addr)}
        return (size > 0);
    }

    //Buy tokens
    function buy(address beneficiary, address payable referral) public onlyWhitelisted payable {
        require(isPresaleStopped != true, 'Presale is stopped');
        require(isPresalePaused != true, 'Presale is paused');
        require(beneficiary != address(0), 'User asking for tokens sent to be on 0 address');
        require(validPurchase(), 'Its not a valid purchase');
        require(BuyerList[msg.sender] < MAX_BUY_LIMIT, 'MAX_BUY_LIMIT Achieved already for this wallet');
        uint256 weiAmount = msg.value;
        require(weiAmount < MAX_BUY_LIMIT, 'MAX_BUY_LIMIT is 10 BNB');
        uint256 tokens = weiAmount.mul(rate);
        uint256 refReward = tokens.mul(referralReward).div(10000);
        weiRaised = weiRaised.add(weiAmount);
        uint256 remainingTokens = tokensRemainingForSale();
        uint256 tokensNeeded = tokens.add(refReward);
        require(tokensNeeded <= remainingTokens, 'Not enough tokens');
        payReferral(referral, refReward);
        token.transfer(beneficiary, tokens);
        BuyerList[msg.sender] = BuyerList[msg.sender].add(msg.value);
        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function payReferral(address payable _referrer, uint256 amount) internal {
        _referrer.transfer(amount);
        emit Transferred(msg.sender, _referrer, amount);
    }

    function validPurchase() internal returns (bool) {
        bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    function hasEnded() public view returns (bool) {
        return block.timestamp > endTime;
    }

    function showMyTokenBalance() public view returns (uint256 tokenBalance) {
        tokenBalance = token.balanceOf(msg.sender);
    }

    function setEndDate(uint256 daysToEndFromToday) public onlyOwner returns (bool) {
        daysToEndFromToday = daysToEndFromToday * 1 days;
        endTime = block.timestamp + daysToEndFromToday;
        return true;
    }

    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) {
        rate = newPrice;
        return true;
    }

    function setReferralReward(uint16 newReward) public onlyOwner returns (bool) {
        referralReward = newReward;
        return true;
    }

    function pausePresale() public onlyOwner returns (bool) {
        isPresalePaused = true;
        return isPresalePaused;
    }

    function resumePresale() public onlyOwner returns (bool) {
        isPresalePaused = false;
        return !isPresalePaused;
    }

    function stopPresale() public onlyOwner returns (bool) {
        isPresaleStopped = true;
        return true;
    }

    function startPresale() public onlyOwner returns (bool) {
        isPresaleStopped = false;
        startTime = block.timestamp;
        return true;
    }

    function burnUnsoldTokens() public onlyOwner {
        uint256 unsold = token.balanceOf(address(this));
        token.burnUnsoldPresale(unsold);
    }

    // Recover lost bnb and send it to the contract owner
    function recoverLostBNB() public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    // Ensure requested tokens aren't users SWAMPWOLF tokens
    function recoverLostTokensExceptOurTokens(address _token, uint256 amount) public onlyOwner {
        require(_token != address(this), "Cannot recover SWAMPWOLF tokens");
        SwampWolfToken(_token).transfer(msg.sender, amount);
    }

    function tokensRemainingForSale() public view returns (uint256 balance) {
        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 rewardBalance = tokenBalance.div(10300).mul(referralReward);
        balance = tokenBalance.sub(rewardBalance);
    }
}