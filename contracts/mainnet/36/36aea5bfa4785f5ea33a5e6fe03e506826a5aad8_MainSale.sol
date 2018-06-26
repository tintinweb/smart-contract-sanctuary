pragma solidity ^0.4.24;

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
        uint256 c = a / b;
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

interface ERC20 {
    function transfer (address _beneficiary, uint256 _tokenAmount) external returns (bool);
    function mintFromICO(address _to, uint256 _amount) external  returns(bool);
}

contract Ownable {
    
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract MainSale is Ownable {
    
    ERC20 public token;
    
    using SafeMath for uint;
    
    address public backEndOperator = msg.sender;
    
    address team = 0x7DDA135cDAa44Ad3D7D79AAbE562c4cEA9DEB41d; // 25% all
    
    address reserve = 0x34bef601666D7b2E719Ff919A04266dD07706a79; // 15% all
    
    mapping(address=>bool) public whitelist;
    
    mapping(address => uint256) public investedEther;
    
    uint256 public startSale = 1537228801; // Tuesday, 18-Sep-18 00:00:01 UTC
    
    uint256 public endSale = 1545177599; // Tuesday, 18-Dec-18 23:59:59 UTC
    
    uint256 public investors;
    
    uint256 public weisRaised;
    
    uint256 public dollarRaised; // collected USD
    
    uint256 public softCap = 2000000000*1e18; // 20,000,000 USD
    
    uint256 public hardCap = 7000000000*1e18; // 70,000,000 USD
    
    uint256 public buyPrice; //0.01 USD
    
    uint256 public dollarPrice;
    
    uint256 public soldTokens;
    
    uint256 step1Sum = 3000000*1e18; // 3 mln $
    
    uint256 step2Sum = 10000000*1e18; // 10 mln $
    
    uint256 step3Sum = 20000000*1e18; // 20 mln $
    
    uint256 step4Sum = 30000000*1e18; // 30 mln $
    
    
    event Authorized(address wlCandidate, uint timestamp);
    
    event Revoked(address wlCandidate, uint timestamp);
    
    event Refund(uint rate, address investor);
    
    
    modifier isUnderHardCap() {
        require(weisRaised <= hardCap);
        _;
    }
    
    modifier backEnd() {
        require(msg.sender == backEndOperator || msg.sender == owner);
        _;
    }
    
    
    constructor(uint256 _dollareth) public {
        dollarPrice = _dollareth;
        buyPrice = 1e16/dollarPrice; // 16 decimals because 1 cent
        hardCap = 7500000000*buyPrice;
    }
    
    
    function setToken (ERC20 _token) public onlyOwner {
        token = _token;
    }
    
    function setDollarRate(uint256 _usdether) public onlyOwner {
        dollarPrice = _usdether;
        buyPrice = 1e16/dollarPrice; // 16 decimals because 1 cent
        hardCap = 7500000000*buyPrice;
    }
    
    
    function setPrice(uint256 newBuyPrice) public onlyOwner {
        buyPrice = newBuyPrice;
    }
    
    function setStartSale(uint256 newStartSale) public onlyOwner {
        startSale = newStartSale;
    }
    
    function setEndSale(uint256 newEndSaled) public onlyOwner {
        endSale = newEndSaled;
    }
    
    function setBackEndAddress(address newBackEndOperator) public onlyOwner {
        backEndOperator = newBackEndOperator;
    }
    
    /*******************************************************************************
     * Whitelist&#39;s section */
    
    function authorize(address wlCandidate) public backEnd {
        require(wlCandidate != address(0x0));
        require(!isWhitelisted(wlCandidate));
        whitelist[wlCandidate] = true;
        investors++;
        emit Authorized(wlCandidate, now);
    }
    
    function revoke(address wlCandidate) public  onlyOwner {
        whitelist[wlCandidate] = false;
        investors--;
        emit Revoked(wlCandidate, now);
    }
    
    function isWhitelisted(address wlCandidate) public view returns(bool) {
        return whitelist[wlCandidate];
    }
    
    /*******************************************************************************
     * Payable&#39;s section */
    
    function isMainSale() public constant returns(bool) {
        return now >= startSale && now <= endSale;
    }
    
    function () public payable isUnderHardCap {
        require(isMainSale());
        require(isWhitelisted(msg.sender));
        require(msg.value >= 10000000000000000);
        mainSale(msg.sender, msg.value);
        investedEther[msg.sender] = investedEther[msg.sender].add(msg.value);
    }
    
    function mainSale(address _investor, uint256 _value) internal {
        uint256 tokens = _value.mul(1e18).div(buyPrice);
        uint256 tokensSum = tokens.mul(discountSum(msg.value)).div(100);
        uint256 tokensCollect = tokens.mul(discountCollect()).div(100);
        tokens = tokens.add(tokensSum).add(tokensCollect);
        token.mintFromICO(_investor, tokens);
        uint256 tokensFounders = tokens.mul(5).div(12);
        token.mintFromICO(team, tokensFounders);
        uint256 tokensDevelopers = tokens.div(4);
        token.mintFromICO(reserve, tokensDevelopers);
        weisRaised = weisRaised.add(msg.value);
        uint256 valueInUSD = msg.value.mul(dollarPrice);
        dollarRaised = dollarRaised.add(valueInUSD);
        soldTokens = soldTokens.add(tokens);
    }
    
    
    function discountSum(uint256 _tokens) pure private returns(uint256) {
        if(_tokens >= 10000000*1e18) { // > 100k$ = 10,000,000 TAL
            return 7;
        }
        if(_tokens >= 5000000*1e18) { // 50-100k$ = 5,000,000 TAL
            return 5;
        }
        if(_tokens >= 1000000*1e18) { // 10-50k$ = 1,000,000 TAL
            return 3;
        } else
            return 0;
    }
    
    
    function discountCollect() view private returns(uint256) {
        // 20% bonus, if collected sum < 3 mln $
        if(dollarRaised <= step1Sum) {
            return 20;
        } // 15% bonus, if collected sum < 10 mln $
        if(dollarRaised <= step2Sum) {
            return 15;
        } // 10% bonus, if collected sum < 20 mln $
        if(dollarRaised <= step3Sum) {
            return 10;
        } // 5% bonus, if collected sum < 30 mln $
        if(dollarRaised <= step4Sum) {
            return 5;
        }
        return 0;
    }
    
    
    function mintManual(address _investor, uint256 _value) public onlyOwner {
        token.mintFromICO(_investor, _value);
        uint256 tokensFounders = _value.mul(5).div(12);
        token.mintFromICO(team, tokensFounders);
        uint256 tokensDevelopers = _value.div(4);
        token.mintFromICO(reserve, tokensDevelopers);
    }
    
    
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
        require(amount != 0);
        require(_to != 0x0);
        _to.transfer(amount);
    }
    
    
    function refundSale() public {
        require(soldTokens < softCap && now > endSale);
        uint256 rate = investedEther[msg.sender];
        require(investedEther[msg.sender] >= 0);
        investedEther[msg.sender] = 0;
        msg.sender.transfer(rate);
        weisRaised = weisRaised.sub(rate);
        emit Refund(rate, msg.sender);
    }
}