pragma solidity ^0.4.23;

/*
* The Blockchain Football network presents....
* https://fantasyfootballfund.co/
* https://discord.gg/qPjA6Tx
*
* Build your fantasy player portfolio. Earn crypto daily based on player performance.
*
* 4 Ways to earn
* [1] Price Fluctuations - buy and sell at the right moments
* [2] Match day Divs - allocated to shareholders of top performing players every day
* [3] Fame Divs - allocated to shareholders of infamous players on non-match days
* [4] Original Owner - allocated to owners of original player cards on blockchainfootball.co (2% per share sold)
*/

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract PlayerToken is ERC20 {

    // Ownable
    address public owner;
    bool public paused = false;

    // Events
    event PlayerTokenBuy(address indexed buyer, address indexed referrer, uint tokens, uint cost, string symbol);
    event PlayerTokenSell(address indexed seller, uint tokens, uint value, string symbol);

    // Libs
    using SafeMath for uint256;

    // Core token attributes
    uint256 public initialTokenPrice_;  // Typically = 1 Finney (0.001 Ether)
    uint256 public incrementalTokenPrice_; // Typically = 0.01 Finney (0.00001 Ether)

    // Token Properties - set via the constructor for each player
    string public name;
    string public symbol;
    uint8 public constant decimals = 0;

    // Exchange Contract - used to hold the dividend pool across all ERC20 player contracts
    // when shares are brought or sold the dividend fee gets transfered here
    address public exchangeContract_;
    
    // Blockchainfootball.co attributes - if this is set the owner receieves a fee for owning the original card
    BCFMain bcfContract_ = BCFMain(0x6abF810730a342ADD1374e11F3e97500EE774D1F);
    uint256 public playerId_;
    address public originalOwner_;

    // Fees - denoted in %
    uint8 constant internal processingFee_ = 5; // inc. fees to cover DAILY gas usage to assign divs to token holders
    uint8 constant internal originalOwnerFee_ = 2; // of all token buys per original player owned + set on blockchainfootball.co
    uint8 internal dividendBuyPoolFee_ = 15; // buys AND sells go into the div pool to promote gameplay - can be updated
    uint8 internal dividendSellPoolFee_ = 20;
    uint8 constant internal referrerFee_ = 1; // for all token buys (but not sells)

    // ERC20 data structures
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    // Player Exchange Data Structures
    address[] public tokenHolders;
    mapping(address => uint256) public addressToTokenHolderIndex; // Helps to gas-efficiently remove shareholders, by swapping last index
    mapping(address => int256) public totalCost; // To hold the total expenditure of each address, profit tracking

    // ERC20 Properties
    uint256 totalSupply_;

    // Additional accessors
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerOrExchange() {
        require(msg.sender == owner || msg.sender == exchangeContract_);
        _;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused() {
        require(paused);
        _;
    }

    // Constructor
    constructor(
        string _name, 
        string _symbol, 
        uint _startPrice, 
        uint _incrementalPrice, 
        address _owner, 
        address _exchangeContract, 
        uint256 _playerId,
        uint8 _promoSharesQuantity
    ) 
        public
        payable
    {
        require(_exchangeContract != address(0));
        require(_owner != address(0));

        exchangeContract_ = _exchangeContract;
        playerId_ = _playerId;

        // Set initial starting exchange values
        initialTokenPrice_ = _startPrice;
        incrementalTokenPrice_ = _incrementalPrice; // In most cases this will be 1 finney, 0.001 ETH

        // Initial token properties
        paused = true;
        owner = _owner;
        name = _name;
        symbol = _symbol;

        // Purchase promotional player shares - we purchase initial shares (the same way users do) as prizes for promos/competitions/giveaways
        if (_promoSharesQuantity > 0) {
            _buyTokens(msg.value, _promoSharesQuantity, _owner, address(0));
        }
    }

    // **External Exchange**
    function buyTokens(uint8 _amount, address _referredBy) payable external whenNotPaused {
        require(_amount > 0 && _amount <= 100, "Valid token amount required between 1 and 100");
        require(msg.value > 0, "Provide a valid fee"); 
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender == tx.origin, "Only valid users are allowed to buy tokens"); 
        _buyTokens(msg.value, _amount, msg.sender, _referredBy);
    }

    function sellTokens(uint8 _amount) external {
        require(_amount > 0, "Valid sell amount required");
        require(_amount <= balances[msg.sender]);
        _sellTokens(_amount, msg.sender);
    }

    // **Internal Exchange**
    function _buyTokens(uint _ethSent, uint8 _amount, address _buyer, address _referredBy) internal {
        
        uint _totalCost;
        uint _processingFee;
        uint _originalOwnerFee;
        uint _dividendPoolFee;
        uint _referrerFee;

        (_totalCost, _processingFee, _originalOwnerFee, _dividendPoolFee, _referrerFee) = calculateTokenBuyPrice(_amount);

        require(_ethSent >= _totalCost, "Invalid fee to buy tokens");

        // Send to original card owner if available
        // If we don&#39;t have an original owner we move this fee into the dividend pool
        if (originalOwner_ != address(0)) {
            originalOwner_.transfer(_originalOwnerFee);
        } else {
            _dividendPoolFee = _dividendPoolFee.add(_originalOwnerFee);
        }

        // Send to the referrer - if we don&#39;t have a referrer we move this fee into the dividend pool
        if (_referredBy != address(0)) {
            _referredBy.transfer(_referrerFee);
        } else {
            _dividendPoolFee = _dividendPoolFee.add(_referrerFee);
        }

        // These will always be available
        owner.transfer(_processingFee);
        exchangeContract_.transfer(_dividendPoolFee);

        // Refund excess
        uint excess = _ethSent.sub(_totalCost);
        _buyer.transfer(excess);

        // Track ownership of token holders - only if this is the first time the user is buying these player shares
        if (balanceOf(_buyer) == 0) {
            tokenHolders.push(_buyer);
            addressToTokenHolderIndex[_buyer] = tokenHolders.length - 1;
        }
        
        // Provide users with the shares
        _allocatePlayerTokensTo(_buyer, _amount);

        // Track costs
        totalCost[_buyer] = totalCost[_buyer] + int256(_totalCost); // No need for safe maths here, just holds profit tracking

        // Event tracking
        emit PlayerTokenBuy(_buyer, _referredBy, _amount, _totalCost, symbol);
    }

    function _sellTokens(uint8 _amount, address _seller) internal {
        
        uint _totalSellerProceeds;
        uint _processingFee;
        uint _dividendPoolFee;

        (_totalSellerProceeds, _processingFee, _dividendPoolFee) = calculateTokenSellPrice(_amount);

        // Burn the sellers shares
        _burnPlayerTokensFrom(_seller, _amount);

        // Track ownership of token holders if the user no longer has tokens let&#39;s remove them
        // we do this semi-efficently by swapping the last index
        if (balanceOf(_seller) == 0) {
            removeFromTokenHolders(_seller);
        }

        // Transfer to processor, seller and dividend pool
        owner.transfer(_processingFee);
        _seller.transfer(_totalSellerProceeds);
        exchangeContract_.transfer(_dividendPoolFee);

        // Track costs
        totalCost[_seller] = totalCost[_seller] - int256(_totalSellerProceeds); // No need for safe maths here, just holds profit tracking

        // Event tracking
        emit PlayerTokenSell(_seller, _amount, _totalSellerProceeds, symbol);
    }

    // **Calculations - these factor in all fees**
    function calculateTokenBuyPrice(uint _amount) 
        public 
        view 
        returns (
        uint _totalCost, 
        uint _processingFee, 
        uint _originalOwnerFee, 
        uint _dividendPoolFee, 
        uint _referrerFee
    ) {    
        uint tokenCost = calculateTokenOnlyBuyPrice(_amount);

        // We now need to apply fees on top of this
        // In all cases we apply fees - but if there&#39;s no original owner or referrer
        // these go into the dividend pool
        _processingFee = SafeMath.div(SafeMath.mul(tokenCost, processingFee_), 100);
        _originalOwnerFee = SafeMath.div(SafeMath.mul(tokenCost, originalOwnerFee_), 100);
        _dividendPoolFee = SafeMath.div(SafeMath.mul(tokenCost, dividendBuyPoolFee_), 100);
        _referrerFee = SafeMath.div(SafeMath.mul(tokenCost, referrerFee_), 100);

        _totalCost = tokenCost.add(_processingFee).add(_originalOwnerFee).add(_dividendPoolFee).add(_referrerFee);
    }

    function calculateTokenSellPrice(uint _amount) 
        public 
        view 
        returns (
        uint _totalSellerProceeds,
        uint _processingFee,
        uint _dividendPoolFee
    ) {
        uint tokenSellCost = calculateTokenOnlySellPrice(_amount);

        // We remove the processing and dividend fees on the final sell price
        // this represents the difference between the buy and sell price on the UI
        _processingFee = SafeMath.div(SafeMath.mul(tokenSellCost, processingFee_), 100);
        _dividendPoolFee = SafeMath.div(SafeMath.mul(tokenSellCost, dividendSellPoolFee_), 100);

        _totalSellerProceeds = tokenSellCost.sub(_processingFee).sub(_dividendPoolFee);
    }

    // **Calculate total cost of tokens without fees**
    function calculateTokenOnlyBuyPrice(uint _amount) public view returns(uint) {
        
        // We use a simple arithmetic progression series, summing the incremental prices
	    // ((n / 2) * (2 * a + (n - 1) * d))
	    // a = starting value (1st term), d = price increment (diff.), n = amount of shares (no. of terms)

        // NOTE: we use a mutiplier to avoid issues with an odd number of shares, dividing and limited fixed point support in Solidity
        uint8 multiplier = 10;
        uint amountMultiplied = _amount * multiplier; 
        uint startingPrice = initialTokenPrice_ + (totalSupply_ * incrementalTokenPrice_);
        uint totalBuyPrice = (amountMultiplied / 2) * (2 * startingPrice + (_amount - 1) * incrementalTokenPrice_) / multiplier;

        // Should never *concievably* occur, but more effecient than Safemaths on the entire formula
        assert(totalBuyPrice >= startingPrice); 
        return totalBuyPrice;
    }

    function calculateTokenOnlySellPrice(uint _amount) public view returns(uint) {
        // Similar to calculateTokenBuyPrice, but we abs() the incrementalTokenPrice so we get a reverse arithmetic series
        uint8 multiplier = 10;
        uint amountMultiplied = _amount * multiplier; 
        uint startingPrice = initialTokenPrice_ + ((totalSupply_-1) * incrementalTokenPrice_);
        int absIncrementalTokenPrice = int(incrementalTokenPrice_) * -1;
        uint totalSellPrice = uint((int(amountMultiplied) / 2) * (2 * int(startingPrice) + (int(_amount) - 1) * absIncrementalTokenPrice) / multiplier);
        return totalSellPrice;
    }

    // **UI Helpers**
    function buySellPrices() public view returns(uint _buyPrice, uint _sellPrice) {
        (_buyPrice,,,,) = calculateTokenBuyPrice(1);
        (_sellPrice,,) = calculateTokenSellPrice(1);
    }

    function portfolioSummary(address _address) public view returns(uint _tokenBalance, int _cost, uint _value) {
        _tokenBalance = balanceOf(_address);
        _cost = totalCost[_address];
        (_value,,) = calculateTokenSellPrice(_tokenBalance);       
    }

    function totalTokenHolders() public view returns(uint) {
        return tokenHolders.length;
    }

    function tokenHoldersByIndex() public view returns(address[] _addresses, uint[] _shares) {
        
        // This will only be called offchain to take snapshots of share count at cut off points for divs
        uint tokenHolderCount = tokenHolders.length;
        address[] memory addresses = new address[](tokenHolderCount);
        uint[] memory shares = new uint[](tokenHolderCount);

        for (uint i = 0; i < tokenHolderCount; i++) {
            addresses[i] = tokenHolders[i];
            shares[i] = balanceOf(tokenHolders[i]);
        }

        return (addresses, shares);
    }

    // In cases where there&#39;s bugs in the exchange contract we need a way to re-point
    function setExchangeContractAddress(address _exchangeContract) external onlyOwner {
        exchangeContract_ = _exchangeContract;
    }

    // **Blockchainfootball.co Support**
    function setBCFContractAddress(address _address) external onlyOwner {
        BCFMain candidateContract = BCFMain(_address);
        require(candidateContract.implementsERC721());
        bcfContract_ = candidateContract;
    }

    function setPlayerId(uint256 _playerId) external onlyOwner {
        playerId_ = _playerId;
    }

    function setSellDividendPercentageFee(uint8 _dividendPoolFee) external onlyOwnerOrExchange {
        // We&#39;ll need some flexibility to alter this as the right dividend structure helps promote gameplay
        // This pushes users to buy players who are performing well to grab divs rather than just getting in early to new players being released
        require(_dividendPoolFee <= 50, "Max of 50% is assignable to the pool");
        dividendSellPoolFee_ = _dividendPoolFee;
    }

    function setBuyDividendPercentageFee(uint8 _dividendPoolFee) external onlyOwnerOrExchange {
        require(_dividendPoolFee <= 50, "Max of 50% is assignable to the pool");
        dividendBuyPoolFee_ = _dividendPoolFee;
    }

    // Can be called by anyone, in which case we could use a another contract to set the original owner whenever it changes on blockchainfootball.co
    function setOriginalOwner(uint256 _playerCardId, address _address) external {
        require(playerId_ > 0, "Player ID must be set on the contract");
        
        // As we call .transfer() on buys to send original owners divs we need to make sure this can&#39;t be DOS&#39;d through setting the
        // original owner as a smart contract and then reverting any transfer() calls
        // while it would be silly to reject divs it is a valid DOS scenario
        // solium-disable-next-line security/no-tx-origin
        require(msg.sender == tx.origin, "Only valid users are able to set original ownership"); 
       
        address _cardOwner;
        uint256 _playerId;
        bool _isFirstGeneration;

        (_playerId,_cardOwner,,_isFirstGeneration) = bcfContract_.playerCards(_playerCardId);

        require(_isFirstGeneration, "Card must be an original");
        require(_playerId == playerId_, "Card must tbe the same player this contract relates to");
        require(_cardOwner == _address, "Card must be owned by the address provided");
        
        // All good, set the address as the original owner, happy div day \o/
        originalOwner_ = _address;
    }

    // ** Internal Token Handling - validation completed by callers **
    function _allocatePlayerTokensTo(address _to, uint256 _amount) internal {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    function _burnPlayerTokensFrom(address _from, uint256 _amount) internal {
        balances[_from] = balances[_from].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Transfer(_from, address(0), _amount);
    }

    function removeFromTokenHolders(address _seller) internal {
        
        uint256 tokenIndex = addressToTokenHolderIndex[_seller];
        uint256 lastAddressIndex = tokenHolders.length.sub(1);
        address lastAddress = tokenHolders[lastAddressIndex];
        
        tokenHolders[tokenIndex] = lastAddress;
        tokenHolders[lastAddressIndex] = address(0);
        tokenHolders.length--;

        addressToTokenHolderIndex[lastAddress] = tokenIndex;
    }

    // ** ERC20 Support **
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        // Track ownership of token holders - only if this is the first time the user is buying these player shares
        if (balanceOf(_to) == 0) {
            tokenHolders.push(_to);
            addressToTokenHolderIndex[_to] = tokenHolders.length - 1;
        }

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        // Track ownership of token holders if the user no longer has tokens let&#39;s remove them
        // we do this semi-efficently by swapping the last index
        if (balanceOf(msg.sender) == 0) {
            removeFromTokenHolders(msg.sender);
        }

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value > 0);
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        // Track ownership of token holders - only if this is the first time the user is buying these player shares
        if (balanceOf(_to) == 0) {
            tokenHolders.push(_to);
            addressToTokenHolderIndex[_to] = tokenHolders.length - 1;
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        // Track ownership of token holders if the user no longer has tokens let&#39;s remove them
        // we do this semi-efficently by swapping the last index
        if (balanceOf(_from) == 0) {
            removeFromTokenHolders(_from);
        }

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    // Utilities
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function pause() onlyOwnerOrExchange whenNotPaused public {
        paused = true;
    }

    function unpause() onlyOwnerOrExchange whenPaused public {
        paused = false;
    }
}

contract BCFMain {
    function playerCards(uint256 playerCardId) public view returns (uint256 playerId, address owner, address approvedForTransfer, bool isFirstGeneration);
    function implementsERC721() public pure returns (bool);
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract PlayerExchangeCore {

    // Events
    event InitialPlayerOffering(address indexed contractAddress, string name, string symbol);
    event DividendWithdrawal(address indexed user, uint amount);

    // Libs
    using SafeMath for uint256;

    // Ownership
    address public owner;
    address public referee; // Used to pay out divs and initiate an IPO

    // Structs
    struct DividendWinner {
        uint playerTokenContractId;
        uint perTokenEthValue;
        uint totalTokens;
        uint tokensProcessed; // So we can determine when all tokens have been allocated divs + settled
    }

    // State management
    uint internal balancePendingWithdrawal_; // this.balance - balancePendingWithdrawal_ = div prize pool

    // Data Store
    PlayerToken[] public playerTokenContracts_; // Holds a list of all player token contracts
    DividendWinner[] public dividendWinners_; // Holds a list of dividend winners (player contract id&#39;s, not users)
    mapping(address => uint256) public addressToDividendBalance;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyReferee() {
        require(msg.sender == referee);
        _;
    }

    modifier onlyOwnerOrReferee() {
        require(msg.sender == owner || msg.sender == referee);
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function setReferee(address newReferee) public onlyOwner {
        require(newReferee != address(0));
        referee = newReferee;
    }

    constructor(address _owner, address _referee) public {
        owner = _owner;
        referee = _referee;
    }

    // Create new instances of a PlayerToken contract and pass along msg.value (so the referee pays and not the contract)
    function newInitialPlayerOffering(
        string _name, 
        string _symbol, 
        uint _startPrice, 
        uint _incrementalPrice, 
        address _owner,
        uint256 _playerId,
        uint8 _promoSharesQuantity
    ) 
        external 
        onlyOwnerOrReferee
        payable
    {
        PlayerToken playerTokenContract = (new PlayerToken).value(msg.value)(
            _name, 
            _symbol, 
            _startPrice, 
            _incrementalPrice, 
            _owner, 
            address(this), 
            _playerId, 
            _promoSharesQuantity
        );

        // Add it to a local storage so we can iterate over it to pull portfolio stats
        playerTokenContracts_.push(playerTokenContract);

        // Event handling
        emit InitialPlayerOffering(address(playerTokenContract), _name, _symbol);
    }

    // Empty fallback - any Ether here just goes straight into the Dividend pool
    // this is useful as it provides a mechanism for the other blockchain football games
    // to top the fund up for special events / promotions
    function() payable public { }

    function getTotalDividendPool() public view returns (uint) {
        return address(this).balance.sub(balancePendingWithdrawal_);
    }

    function totalPlayerTokenContracts() public view returns (uint) {
        return playerTokenContracts_.length;
    }

    function totalDividendWinners() public view returns (uint) {
        return dividendWinners_.length;
    }

    // Called off-chain to manage UI state so no gas concerns - also never likely to be more than 50-200ish player contracts
    function allPlayerTokenContracts() external view returns (address[]) {
        uint playerContractCount = totalPlayerTokenContracts();
        address[] memory addresses = new address[](playerContractCount);

        for (uint i = 0; i < playerContractCount; i++) {
            addresses[i] = address(playerTokenContracts_[i]);
        }

        return addresses;
    }

    /* Safeguard function to quickly pause a stack of contracts */
    function pausePlayerContracts(uint startIndex, uint endIndex) onlyOwnerOrReferee external {
        for (uint i = startIndex; i < endIndex; i++) {
            PlayerToken playerTokenContract = playerTokenContracts_[i];
            if (!playerTokenContract.paused()) {
                playerTokenContract.pause();
            }
        }
    }

    function unpausePlayerContracts(uint startIndex, uint endIndex) onlyOwnerOrReferee external {
        for (uint i = startIndex; i < endIndex; i++) {
            PlayerToken playerTokenContract = playerTokenContracts_[i];
            if (playerTokenContract.paused()) {
                playerTokenContract.unpause();
            }
        }
    }

    function setSellDividendPercentageFee(uint8 _fee, uint startIndex, uint endIndex) onlyOwner external {
        for (uint i = startIndex; i < endIndex; i++) {
            PlayerToken playerTokenContract = playerTokenContracts_[i];
            playerTokenContract.setSellDividendPercentageFee(_fee);
        }
    }

    function setBuyDividendPercentageFee(uint8 _fee, uint startIndex, uint endIndex) onlyOwner external {
        for (uint i = startIndex; i < endIndex; i++) {
            PlayerToken playerTokenContract = playerTokenContracts_[i];
            playerTokenContract.setBuyDividendPercentageFee(_fee);
        }
    }

    /* Portfolio Support */
    // Only called offchain - so we can omit additional pagination/optimizations here
    function portfolioSummary(address _address) 
        external 
        view 
    returns (
        uint[] _playerTokenContractId, 
        uint[] _totalTokens, 
        int[] _totalCost, 
        uint[] _totalValue) 
    {
        uint playerContractCount = totalPlayerTokenContracts();

        uint[] memory playerTokenContractIds = new uint[](playerContractCount);
        uint[] memory totalTokens = new uint[](playerContractCount);
        int[] memory totalCost = new int[](playerContractCount);
        uint[] memory totalValue = new uint[](playerContractCount);

        PlayerToken playerTokenContract;

        for (uint i = 0; i < playerContractCount; i++) {
            playerTokenContract = playerTokenContracts_[i];
            playerTokenContractIds[i] = i;
            (totalTokens[i], totalCost[i], totalValue[i]) = playerTokenContract.portfolioSummary(_address);
        }

        return (playerTokenContractIds, totalTokens, totalCost, totalValue);
    }

    /* Dividend Handling */
    // These are all handled based on their corresponding index
    // Takes a snapshot of the current dividend pool balance and allocates a per share div award
    function setDividendWinners(
        uint[] _playerContractIds, 
        uint[] _totalPlayerTokens, 
        uint8[] _individualPlayerAllocationPcs, 
        uint _totalPrizePoolAllocationPc
    ) 
        external 
        onlyOwnerOrReferee 
    {
        require(_playerContractIds.length > 0, "Must have valid player contracts to award divs to");
        require(_playerContractIds.length == _totalPlayerTokens.length);
        require(_totalPlayerTokens.length == _individualPlayerAllocationPcs.length);
        require(_totalPrizePoolAllocationPc > 0);
        require(_totalPrizePoolAllocationPc <= 100);
        
        // Calculate how much dividends we have allocated
        uint dailyDivPrizePool = SafeMath.div(SafeMath.mul(getTotalDividendPool(), _totalPrizePoolAllocationPc), 100);

        // Iteration here should be fine as there should concievably only ever be 3 or 4 winning players each day
        uint8 totalPlayerAllocationPc = 0;
        for (uint8 i = 0; i < _playerContractIds.length; i++) {
            totalPlayerAllocationPc += _individualPlayerAllocationPcs[i];

            // Calculate from the total daily pool how much is assigned to owners of this player
            // e.g. a typical day might = Total Dividend pool: 100 ETH, _totalPrizePoolAllocationPc: 20 (%)
            // therefore the total dailyDivPrizePool = 20 ETH
            // Which could be allocated as follows
            // 1. 50% MVP Player - (Attacker) (10 ETH total)
            // 2. 25% Player - (Midfielder) (5 ETH total)
            // 3. 25% Player - (Defender) (5 ETH total)
            uint playerPrizePool = SafeMath.div(SafeMath.mul(dailyDivPrizePool, _individualPlayerAllocationPcs[i]), 100);

            // Calculate total div-per-share
            uint totalPlayerTokens = _totalPlayerTokens[i];
            uint perTokenEthValue = playerPrizePool.div(totalPlayerTokens);

            // Add to the winners array so it can then be picked up by the div payment processor
            DividendWinner memory divWinner = DividendWinner({
                playerTokenContractId: _playerContractIds[i],
                perTokenEthValue: perTokenEthValue,
                totalTokens: totalPlayerTokens,
                tokensProcessed: 0
            });

            dividendWinners_.push(divWinner);
        }

        // We need to make sure we are allocating a valid set of dividend totals (i.e. not more than 100%)
        // this is just to cover us for basic errors, this should never occur
        require(totalPlayerAllocationPc == 100);
    }

    function allocateDividendsToWinners(uint _dividendWinnerId, address[] _winners, uint[] _tokenAllocation) external onlyOwnerOrReferee {
        DividendWinner storage divWinner = dividendWinners_[_dividendWinnerId];
        require(divWinner.totalTokens > 0); // Basic check to make sure we don&#39;t access a 0&#39;d struct
        require(divWinner.tokensProcessed < divWinner.totalTokens);
        require(_winners.length == _tokenAllocation.length);

        uint totalEthAssigned;
        uint totalTokensAllocatedEth;
        uint ethAllocation;
        address winner;

        for (uint i = 0; i < _winners.length; i++) {
            winner = _winners[i];
            ethAllocation = _tokenAllocation[i].mul(divWinner.perTokenEthValue);
            addressToDividendBalance[winner] = addressToDividendBalance[winner].add(ethAllocation);
            totalTokensAllocatedEth = totalTokensAllocatedEth.add(_tokenAllocation[i]);
            totalEthAssigned = totalEthAssigned.add(ethAllocation);
        }

        // Update balancePendingWithdrawal_ - this allows us to get an accurate reflection of the div pool
        balancePendingWithdrawal_ = balancePendingWithdrawal_.add(totalEthAssigned);

        // As we will likely cause this function in batches this allows us to make sure we don&#39;t oversettle (failsafe)
        divWinner.tokensProcessed = divWinner.tokensProcessed.add(totalTokensAllocatedEth);

        // This should never occur, but a failsafe for when automated div payments are rolled out
        require(divWinner.tokensProcessed <= divWinner.totalTokens);
    }

    function withdrawDividends() external {
        require(addressToDividendBalance[msg.sender] > 0, "Must have a valid dividend balance");
        uint senderBalance = addressToDividendBalance[msg.sender];
        addressToDividendBalance[msg.sender] = 0;
        balancePendingWithdrawal_ = balancePendingWithdrawal_.sub(senderBalance);
        msg.sender.transfer(senderBalance);
        emit DividendWithdrawal(msg.sender, senderBalance);
    }
}