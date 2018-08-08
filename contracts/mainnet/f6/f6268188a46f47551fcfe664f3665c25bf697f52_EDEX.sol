pragma solidity ^0.4.16;

contract SafeMath{

  // math operations with safety checks that throw on error
  // small gas improvement

  function safeMul(uint256 a, uint256 b) internal returns (uint256){
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  
  function safeDiv(uint256 a, uint256 b) internal returns (uint256){
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }
  
  function safeSub(uint256 a, uint256 b) internal returns (uint256){
    assert(b <= a);
    return a - b;
  }
  
  function safeAdd(uint256 a, uint256 b) internal returns (uint256){
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  // mitigate short address attack
  // https://github.com/numerai/contract/blob/c182465f82e50ced8dacb3977ec374a892f5fa8c/contracts/Safe.sol#L30-L34
  modifier onlyPayloadSize(uint numWords){
     assert(msg.data.length >= numWords * 32 + 4);
     _;
  }

}


contract Token{ // ERC20 standard

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

}


contract StandardToken is Token, SafeMath{

    uint256 public totalSupply;

    function transfer(address _to, uint256 _value) onlyPayloadSize(2) returns (bool success){
        require(_to != address(0));
        require(balances[msg.sender] >= _value && _value > 0);
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) returns (bool success){
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0);
        balances[_from] = safeSub(balances[_from], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance){
        return balances[_owner];
    }
    
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address _spender, uint256 _value) onlyPayloadSize(2) returns (bool success){
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) onlyPayloadSize(3) returns (bool success){
        require(allowed[msg.sender][_spender] == _oldValue);
        allowed[msg.sender][_spender] = _newValue;
        Approval(msg.sender, _spender, _newValue);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    // this creates an array with all balances
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

}


contract EDEX is StandardToken{

    // public variables of the token

    string public name = "Equadex";
    string public symbol = "EDEX";
    uint256 public decimals = 18;
    
    // reachable if max amount raised
    uint256 public maxSupply = 100000000e18;
    
    // ICO starting and ending blocks, can be changed as needed
    uint256 public icoStartBlock;
    // icoEndBlock = icoStartBlock + 345,600 blocks for 2 months ICO
    uint256 public icoEndBlock;

    // set the wallets with different levels of authority
    address public mainWallet;
    address public secondaryWallet;
    
    // time to wait between secondaryWallet price updates, mainWallet can update without restrictions
    uint256 public priceUpdateWaitingTime = 1 hours;

    uint256 public previousUpdateTime = 0;
    
    // strucure of price
    PriceEDEX public currentPrice;
    uint256 public minInvestment = 0.01 ether;
    
    // for tokens allocated to the team
    address public grantVestedEDEXContract;
    bool private grantVestedEDEXSet = false;
    
    // halt the crowdsale should any suspicious behavior of a third-party be identified
    // tokens will be locked for trading until they are listed on exchanges
    bool public haltICO = false;
    bool public setTrading = false;

    // maps investor address to a liquidation request
    mapping (address => Liquidation) public liquidations;
    // maps previousUpdateTime to the next price
    mapping (uint256 => PriceEDEX) public prices;
    // maps verified addresses
    mapping (address => bool) public verified;

    event Verification(address indexed investor);
    event LiquidationCall(address indexed investor, uint256 amountTokens);
    event Liquidations(address indexed investor, uint256 amountTokens, uint256 etherAmount);
    event Buy(address indexed investor, address indexed beneficiary, uint256 ethValue, uint256 amountTokens);
    event PrivateSale(address indexed investor, uint256 amountTokens);
    event PriceEDEXUpdate(uint256 topInteger, uint256 bottomInteger);
    event AddLiquidity(uint256 etherAmount);
    event RemoveLiquidity(uint256 etherAmount);
    
    // for price updates as a rational number
    struct PriceEDEX{
        uint256 topInteger;
        uint256 bottomInteger;
    }

    struct Liquidation{
        uint256 tokens;
        uint256 time;
    }

    // grantVestedEDEXContract and mainWallet can transfer to allow team allocations
    modifier isSetTrading{
        require(setTrading || msg.sender == mainWallet || msg.sender == grantVestedEDEXContract);
        _;
    }

    modifier onlyVerified{
        require(verified[msg.sender]);
        _;
    }

    modifier onlyMainWallet{
        require(msg.sender == mainWallet);
        _;
    }

    modifier onlyControllingWallets{
        require(msg.sender == secondaryWallet || msg.sender == mainWallet);
        _;
    }

    modifier only_if_secondaryWallet{
        if (msg.sender == secondaryWallet) _;
    }
    modifier require_waited{
        require(safeSub(now, priceUpdateWaitingTime) >= previousUpdateTime);
        _;
    }
    modifier only_if_increase (uint256 newTopInteger){
        if (newTopInteger > currentPrice.topInteger) _;
    }

    function EDEX(address secondaryWalletInput, uint256 priceTopIntegerInput, uint256 startBlockInput, uint256 endBlockInput){
        require(secondaryWalletInput != address(0));
        require(endBlockInput > startBlockInput);
        require(priceTopIntegerInput > 0);
        mainWallet = msg.sender;
        secondaryWallet = secondaryWalletInput;
        verified[mainWallet] = true;
        verified[secondaryWallet] = true;
        // priceTopIntegerInput = 800,000 for 1 ETH = 800 EDEX
        currentPrice = PriceEDEX(priceTopIntegerInput, 1000);
        // icoStartBlock should be around block number 5,709,200 = June 1st 2018
        icoStartBlock = startBlockInput;
        // icoEndBlock = icoStartBlock + 345,600 blocks
        icoEndBlock = endBlockInput;
        previousUpdateTime = now;
    }

    function setGrantVestedEDEXContract(address grantVestedEDEXContractInput) external onlyMainWallet{
        require(grantVestedEDEXContractInput != address(0));
        grantVestedEDEXContract = grantVestedEDEXContractInput;
        verified[grantVestedEDEXContract] = true;
        grantVestedEDEXSet = true;
    }

    function updatePriceEDEX(uint256 newTopInteger) external onlyControllingWallets{
        require(newTopInteger > 0);
        require_limited_change(newTopInteger);
        currentPrice.topInteger = newTopInteger;
        // maps time to new PriceEDEX
        prices[previousUpdateTime] = currentPrice;
        previousUpdateTime = now;
        PriceEDEXUpdate(newTopInteger, currentPrice.bottomInteger);
    }

    function require_limited_change (uint256 newTopInteger) private only_if_secondaryWallet require_waited only_if_increase(newTopInteger){
        uint256 percentage_diff = 0;
        percentage_diff = safeMul(newTopInteger, 100) / currentPrice.topInteger;
        percentage_diff = safeSub(percentage_diff, 100);
        // secondaryWallet can increase price by 20% maximum once every priceUpdateWaitingTime
        require(percentage_diff <= 20);
    }

    function updatePriceBottomInteger(uint256 newBottomInteger) external onlyMainWallet{
        require(block.number > icoEndBlock);
        require(newBottomInteger > 0);
        currentPrice.bottomInteger = newBottomInteger;
        // maps time to new Price
        prices[previousUpdateTime] = currentPrice;
        previousUpdateTime = now;
        PriceEDEXUpdate(currentPrice.topInteger, newBottomInteger);
    }

    function tokenAllocation(address investor, uint256 amountTokens) private{
        require(grantVestedEDEXSet);
        // the 15% allocated to the team
        uint256 teamAllocation = safeMul(amountTokens, 1764705882352941) / 1e16;
        uint256 newTokens = safeAdd(amountTokens, teamAllocation);
        require(safeAdd(totalSupply, newTokens) <= maxSupply);
        totalSupply = safeAdd(totalSupply, newTokens);
        balances[investor] = safeAdd(balances[investor], amountTokens);
        balances[grantVestedEDEXContract] = safeAdd(balances[grantVestedEDEXContract], teamAllocation);
    }

    function privateSaleTokens(address investor, uint amountTokens) external onlyMainWallet{
        require(block.number < icoEndBlock);
        require(investor != address(0));
        verified[investor] = true;
        tokenAllocation(investor, amountTokens);
        Verification(investor);
        PrivateSale(investor, amountTokens);
    }

    function verifyInvestor(address investor) external onlyControllingWallets{
        verified[investor] = true;
        Verification(investor);
    }
    
    // blacklists bot addresses using ICO whitelisted addresses
    function removeVerifiedInvestor(address investor) external onlyControllingWallets{
        verified[investor] = false;
        Verification(investor);
    }

    function buy() external payable{
        buyTo(msg.sender);
    }

    function buyTo(address investor) public payable onlyVerified{
        require(!haltICO);
        require(investor != address(0));
        require(msg.value >= minInvestment);
        require(block.number >= icoStartBlock && block.number < icoEndBlock);
        uint256 icoBottomInteger = icoBottomIntegerPrice();
        uint256 tokensToBuy = safeMul(msg.value, currentPrice.topInteger) / icoBottomInteger;
        tokenAllocation(investor, tokensToBuy);
        // send ether to mainWallet
        mainWallet.transfer(msg.value);
        Buy(msg.sender, investor, msg.value, tokensToBuy);
    }

    // bonus scheme during ICO, 1 ETH = 800 EDEX for 1st 20 days, 1 ETH = 727 EDEX for 2nd 20 days, 1 ETH = 667 EDEX for 3rd 20 days
    function icoBottomIntegerPrice() public constant returns (uint256){
        uint256 icoDuration = safeSub(block.number, icoStartBlock);
        uint256 bottomInteger;
        // icoDuration < 115,200 blocks = 20 days
        if (icoDuration < 115200){
            return currentPrice.bottomInteger;
        }
        // icoDuration < 230,400 blocks = 40 days
        else if (icoDuration < 230400 ){
            bottomInteger = safeMul(currentPrice.bottomInteger, 110) / 100;
            return bottomInteger;
        }
        else{
            bottomInteger = safeMul(currentPrice.bottomInteger, 120) / 100;
            return bottomInteger;
        }
    }

    // change ICO starting date if more time needed for preparation
    function changeIcoStartBlock(uint256 newIcoStartBlock) external onlyMainWallet{
        require(block.number < icoStartBlock);
        require(block.number < newIcoStartBlock);
        icoStartBlock = newIcoStartBlock;
    }

    function changeIcoEndBlock(uint256 newIcoEndBlock) external onlyMainWallet{
        require(block.number < icoEndBlock);
        require(block.number < newIcoEndBlock);
        icoEndBlock = newIcoEndBlock;
    }

    function changePriceUpdateWaitingTime(uint256 newPriceUpdateWaitingTime) external onlyMainWallet{
        priceUpdateWaitingTime = newPriceUpdateWaitingTime;
    }

    function requestLiquidation(uint256 amountTokensToLiquidate) external isSetTrading onlyVerified{
        require(block.number > icoEndBlock);
        require(amountTokensToLiquidate > 0);
        address investor = msg.sender;
        require(balanceOf(investor) >= amountTokensToLiquidate);
        require(liquidations[investor].tokens == 0);
        balances[investor] = safeSub(balances[investor], amountTokensToLiquidate);
        liquidations[investor] = Liquidation({tokens: amountTokensToLiquidate, time: previousUpdateTime});
        LiquidationCall(investor, amountTokensToLiquidate);
    }

    function liquidate() external{
        address investor = msg.sender;
        uint256 tokens = liquidations[investor].tokens;
        require(tokens > 0);
        uint256 requestTime = liquidations[investor].time;
        // obtain the next price that was set after the request
        PriceEDEX storage price = prices[requestTime];
        require(price.topInteger > 0);
        uint256 liquidationValue = safeMul(tokens, price.bottomInteger) / price.topInteger;
        // if there is enough ether on the contract, proceed. Otherwise, send back tokens
        liquidations[investor].tokens = 0;
        if (this.balance >= liquidationValue)
            enact_liquidation_greater_equal(investor, liquidationValue, tokens);
        else
            enact_liquidation_less(investor, liquidationValue, tokens);
    }

    function enact_liquidation_greater_equal(address investor, uint256 liquidationValue, uint256 tokens) private{
        assert(this.balance >= liquidationValue);
        balances[mainWallet] = safeAdd(balances[mainWallet], tokens);
        investor.transfer(liquidationValue);
        Liquidations(investor, tokens, liquidationValue);
    }
    
    function enact_liquidation_less(address investor, uint256 liquidationValue, uint256 tokens) private{
        assert(this.balance < liquidationValue);
        balances[investor] = safeAdd(balances[investor], tokens);
        Liquidations(investor, tokens, 0);
    }

    function checkLiquidationValue(uint256 amountTokensToLiquidate) constant returns (uint256 etherValue){
        require(amountTokensToLiquidate > 0);
        require(balanceOf(msg.sender) >= amountTokensToLiquidate);
        uint256 liquidationValue = safeMul(amountTokensToLiquidate, currentPrice.bottomInteger) / currentPrice.topInteger;
        require(this.balance >= liquidationValue);
        return liquidationValue;
    }

    // add liquidity to contract for investor liquidation
    function addLiquidity() external onlyControllingWallets payable{
        require(msg.value > 0);
        AddLiquidity(msg.value);
    }

    // remove liquidity from contract
    function removeLiquidity(uint256 amount) external onlyControllingWallets{
        require(amount <= this.balance);
        mainWallet.transfer(amount);
        RemoveLiquidity(amount);
    }

    function changeMainWallet(address newMainWallet) external onlyMainWallet{
        require(newMainWallet != address(0));
        mainWallet = newMainWallet;
    }

    function changeSecondaryWallet(address newSecondaryWallet) external onlyMainWallet{
        require(newSecondaryWallet != address(0));
        secondaryWallet = newSecondaryWallet;
    }

    function enableTrading() external onlyMainWallet{
        require(block.number > icoEndBlock);
        setTrading = true;
    }

    function claimEDEX(address _token) external onlyMainWallet{
        require(_token != address(0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(mainWallet, balance);
     }

    // disable transfers and allow them once token is tradeable
    function transfer(address _to, uint256 _value) isSetTrading returns (bool success){
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) isSetTrading returns (bool success){
        return super.transferFrom(_from, _to, _value);
    }

    function haltICO() external onlyMainWallet{
        haltICO = true;
    }
    
    function unhaltICO() external onlyMainWallet{
        haltICO = false;
    }
    
    // fallback function
    function() payable{
        require(tx.origin == msg.sender);
        buyTo(msg.sender);
    }
}