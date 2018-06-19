pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

library SafeMath_Time {
    function addTime(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
  
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface token {
    function transfer(address receiver, uint amount) external;
    function freezeAccount(address target, bool freeze, uint startTime, uint endTime) external; 
}

interface marketPrice {
    function getUSDEth() external returns(uint256);
}

contract BaseCrowdsale{
    using SafeMath for uint256;
    using SafeMath_Time for uint;

    token public ctrtToken;
    address public wallet;
    uint256 public weiRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);    

    function init(address _wallet, address _token) internal {
        require(_wallet != address(0));
        require(_token != address(0));

        wallet = _wallet;
        ctrtToken = token(_token);
    }        

    function () external payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = weiAmount;
        tokens = _getTokenAmount(weiAmount);

        _preValidatePurchase(_beneficiary, weiAmount, tokens);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, weiAmount, tokens);

        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount, tokens);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount, tokens);
    }

    function _getTokenAmount(uint256 _tokenAmount) internal view returns (uint256) {
        uint256 Amount = _tokenAmount;
        return Amount;
    }

    function _updatePurchasingState(address _beneficiary, uint _weiAmount, uint256 _tokenAmount) internal {}
    
    function _preValidatePurchase(address _beneficiary, uint _weiAmount, uint256 _tokenAmount)  internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }

    function _postValidatePurchase(address _beneficiary, uint _weiAmount, uint256 _tokenAmount) internal {        
    }

    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        ctrtToken.transfer(_beneficiary, _tokenAmount);
    }

    function _processPurchase(address _beneficiary, uint _weiAmount, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
}

contract AdvanceCrowdsale is BaseCrowdsale, Ownable{
    using SafeMath for uint256;
    uint constant MAX_FUND_SIZE = 20;

    uint256[MAX_FUND_SIZE] public fundingGoalInToken;
    uint256[MAX_FUND_SIZE] public amountRaisedInToken;
    uint[MAX_FUND_SIZE] public rate;
    uint[MAX_FUND_SIZE] public openingTimeArray;
    uint[MAX_FUND_SIZE] public closingTimeArray;

    mapping(address => uint256) public balanceOf;

    uint256 public price;              //USD cent per token
    uint public tokenPerEth;
    uint public minFundInEther = 0;    
    uint public usdPerEth = 0;          //USD cent    
    marketPrice public ctrtMarketPrice;

    bool[MAX_FUND_SIZE] public isLockUpSale;
    uint[MAX_FUND_SIZE] public lockDurationTime;

    event Refunding(uint pos, uint256 FundingGoalInToken, uint _rate, uint _openingTime, uint _closingTime,
    bool _isLockUpSale, uint _lockDurationTime);
    event TokenPrice(uint usdPerEth, uint tokenPerEth);

    function init(
        address _wallet,
        address _token,
        address _marketPriceContract,
        uint _usdPerEth,
        uint _price
    ) public         
    {
        super.init(_wallet, _token);
        price = _price;
        minFundInEther = 1;
        ctrtMarketPrice = marketPrice(_marketPriceContract);
        setUSDPerETH(_usdPerEth);
    }
    
    function setFunding(
        uint pos, uint256 _fundingGoalInToken, uint _rate, uint _openingTime, 
        uint _closingTime, bool _isLockUpSale, uint _lockDurationTime)
    public onlyOwner
    {
        require(pos < MAX_FUND_SIZE);
        openingTimeArray[pos] = _openingTime;
        closingTimeArray[pos] = _closingTime;
        rate[pos] = _rate;
        fundingGoalInToken[pos] = _fundingGoalInToken.mul(1 ether);
        amountRaisedInToken[pos] = 0;

        isLockUpSale[pos] = _isLockUpSale;
        lockDurationTime[pos] = _lockDurationTime.mul(1 minutes);
        
        emit Refunding(pos, _fundingGoalInToken, _rate, _openingTime, _closingTime, _isLockUpSale, _lockDurationTime);
    }

    function hasClosed() public view returns (bool) {
        for(uint i = 0; i < MAX_FUND_SIZE; ++i)
        {
            if(openingTimeArray[i] <= now && now <= closingTimeArray[i])
            {
                return false;
            }
        }

        return true;
    }

    function fundPos() public view returns (uint) {
        for(uint i = 0; i < MAX_FUND_SIZE; ++i)
        {
            if(openingTimeArray[i] <= now && now <= closingTimeArray[i])
            {
                return i;
            }
        }

        require(false);
    }

    function setUSDPerETH(uint _usdPerEth) public onlyOwner{
        require(_usdPerEth != 0);
        usdPerEth = _usdPerEth;
        tokenPerEth = usdPerEth.div(price).mul(1 ether);

        TokenPrice(usdPerEth, tokenPerEth);
    }

    function SetUSDPerETH_byContract(uint _usdPerEth) internal {
        require(_usdPerEth != 0);
        usdPerEth = _usdPerEth;
        tokenPerEth = usdPerEth.div(price).mul(1 ether);

        TokenPrice(usdPerEth, tokenPerEth);
    }

    function setMarket(address _marketPrice) public onlyOwner{
        ctrtMarketPrice = marketPrice(_marketPrice);
    }

    function newLockUpAddress(address newAddress) public {
        uint pos = fundPos();

        ctrtToken.freezeAccount(newAddress, true, block.timestamp, closingTimeArray[pos].addTime(lockDurationTime[pos]));
    }

    function _preValidatePurchase(address _beneficiary, uint _weiAmount, uint256 _tokenAmount)  internal {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokenAmount);       
        
        require(hasClosed() == false);
        uint pos = fundPos();

        require(fundingGoalInToken[pos] >= amountRaisedInToken[pos].add(_tokenAmount));        
        require(minFundInEther <= msg.value);        
    }
     
    function _getTokenAmount(uint256 _tokenAmount) internal view returns (uint256) {
        if(ctrtMarketPrice != address(0))
        {           
            uint256 usd = ctrtMarketPrice.getUSDEth();
    
            if(usd != usdPerEth) {
                SetUSDPerETH_byContract(usd);
            }
        }
        require(usdPerEth != 0);

        uint256 Amount = _tokenAmount.mul(tokenPerEth).div(1 ether);
        
        require(hasClosed() == false);
        uint pos = fundPos();

        Amount = Amount.mul(rate[pos].add(100)).div(100);
        return Amount;
    }

    function _updatePurchasingState(address _beneficiary, uint _weiAmount, uint256 _tokenAmount) internal {        
        balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
        require(hasClosed() == false);
        uint pos = fundPos();
        amountRaisedInToken[pos] = amountRaisedInToken[pos].add(_tokenAmount);
    }

    function _postValidatePurchase(address _beneficiary, uint _weiAmount, uint256 _tokenAmount) internal {
        uint pos = fundPos();
        if(true == isLockUpSale[pos])
            newLockUpAddress(msg.sender);
    }
}