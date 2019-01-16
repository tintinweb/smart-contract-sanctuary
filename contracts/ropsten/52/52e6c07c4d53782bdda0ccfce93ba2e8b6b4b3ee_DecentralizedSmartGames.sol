pragma solidity ^0.4.25;

contract DecentralizedSmartGames{
    using SafeMath for uint256;
    
    string public constant name = "Decentralized Smart Games";
    string public constant symbol = "DSG";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public dividendsPerToken;
    uint256 public tokenPrice = 1e15;
    uint256 public tokenPriceStep = 1e11;
    uint256 public constant MIN_REFERRER_BALANCE = 100e18;
    uint256 public constant FIRST_REFERRER_REWARD = 5;
    uint256 public constant SECOND_REFERRER_REWARD = 3;
    uint256 public constant THIRD_REFERRER_REWARD = 1;
    uint256 public constant DIVIDENDS_FEE = 5;
    uint256 public constant DEVELOPER_FEE = 1;
    uint256 public constant BUY_FEE = 15;
    uint256 public constant SELL_FEE = 5;
    uint256 public totalInvestors = 1;
    uint256 public developerBalance;
    address public developerAddress;
    address public ownerAddress;
    address public candidateAddress;
    
    mapping (address => Account) accounts;
    mapping (address => ReferrerAddresses) referrer;
    
    struct ReferrerAddresses{
        address first;
        address second;
        address third;
    }
    
    struct Account {
        uint256 tokenBalance;
        uint256 ethereumBalance;
        uint256 lastDividendsPerToken;
    }
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress);
        _;
    }
    
    modifier payDividends() {
        uint dividends = getDividends();
		if(dividends > 0){
			accounts[msg.sender].ethereumBalance = accounts[msg.sender].ethereumBalance.add(dividends);
			accounts[msg.sender].lastDividendsPerToken = dividendsPerToken;
		}
        _;
    }
    
    event onBuy(
        address indexed customerAddress,
        address indexed referrer,
        uint256 amountEthereum,
        uint256 outputToken,
        uint256 totalSupply,
        uint256 timestamp,
        uint256 averagePrice
    );
    
    event onSell(
        address indexed customerAddress,
        uint256 amountTokens,
        uint256 outputEthereum,
        uint256 totalSupply,
        uint256 timestamp,
        uint256 averagePrice
    );
    
    event onReinvest(
        address indexed customerAddress,
        uint256 amountEthereum,
        uint256 outputToken,
        uint256 totalSupply,
        uint256 timestamp,
        uint256 averagePrice
    );
    
    event onWithdraw(
        address indexed customerAddress,
        uint256 amountEthereum,
        uint256 timestamp
    );
    
    constructor() public{
        ownerAddress = msg.sender;
        developerAddress = msg.sender;
        referrer[ownerAddress].first = ownerAddress;
        referrer[ownerAddress].second = ownerAddress;
        referrer[ownerAddress].third = ownerAddress;
    }
    
    function buy(address referrerAddress) public payable payDividends
    {
        require(msg.value > 0, "{_BUY_ZERO_ETH_}");
        uint256 realValue = msg.value.sub(msg.value.mul(BUY_FEE).div(100));
        uint256 tokens = calculateTokens(realValue);
        uint256 price =  calculatePrice(tokens, true);
        uint256 dividendsFee = msg.value.mul(DIVIDENDS_FEE).div(100);
        uint256 firstReferrer = msg.value.mul(FIRST_REFERRER_REWARD).div(100);
        uint256 secondReferrer = msg.value.mul(SECOND_REFERRER_REWARD).div(100);
        uint256 thirdReferrer = msg.value.mul(THIRD_REFERRER_REWARD).div(100);
        uint256 developerFee = msg.value.mul(DEVELOPER_FEE).div(100);
        uint256 averagePrice = tokenPrice.add(price).div(2);
        tokenPrice = price;
        setTokenBalance(tokens, true);
        setTotalSupply(tokens, true);
        setRefer(referrerAddress);
        distributionForRefers(firstReferrer, secondReferrer, thirdReferrer);
        setDividends(dividendsFee);
        developerCommissionFee(developerFee);
        emit onBuy(msg.sender, referrerAddress, msg.value, tokens, totalSupply, now, averagePrice);
    }
    function sell(uint256 amountTokens) public payDividends
    {
        require(accounts[msg.sender].tokenBalance >= amountTokens, "{_SELL_TOO_MUCH_DSG_}");
        uint256 ethereum = calculateEthereum(amountTokens);
        uint256 price = calculatePrice(amountTokens, false);
        uint256 fee = ethereum.mul(SELL_FEE).div(100);
        uint256 developerFee = ethereum.mul(DEVELOPER_FEE).div(100);
        uint256 averagePrice = tokenPrice.add(price).div(2);
        uint256 dividends = fee.sub(developerFee);
        tokenPrice = price;
        setTokenBalance(amountTokens, false);
        setTotalSupply(amountTokens, false);
        accounts[msg.sender].ethereumBalance = accounts[msg.sender].ethereumBalance.add(ethereum.sub(fee));
        if(totalSupply == 0){
            developerCommissionFee(fee);
        }
        else{
            developerCommissionFee(developerFee);
            setDividends(dividends);
        }
        emit onSell(msg.sender, amountTokens, ethereum, totalSupply, now, averagePrice);
    }
    function setRefer(address referrerAddress) private
    {
        if(referrer[msg.sender].first == address(0)){
            require(referrerAddress != msg.sender, "{_REFERRER_IS_CUSTOMER_}");
            require(referrer[referrerAddress].first != address(0), "{_REFERRER_NOT_IN_CONTRACT_}");
            require(accounts[referrerAddress].tokenBalance > MIN_REFERRER_BALANCE, "{_REFERRER_NOT_HAVE_MIN_DSG_BALANCE_}");
            referrer[msg.sender].first = referrerAddress;
            referrer[msg.sender].second = referrer[referrerAddress].first;
            referrer[msg.sender].third = referrer[referrerAddress].second;
            totalInvestors = totalInvestors.add(1);
        }
    }
    function distributionForRefers(uint256 x, uint256 y, uint256 z) private{
        accounts[referrer[msg.sender].first].ethereumBalance = accounts[referrer[msg.sender].first].ethereumBalance.add(x);
        accounts[referrer[msg.sender].second].ethereumBalance = accounts[referrer[msg.sender].second].ethereumBalance.add(y);
        accounts[referrer[msg.sender].third].ethereumBalance = accounts[referrer[msg.sender].third].ethereumBalance.add(z);
    }
    function reinvest(uint256 amountEthereum) public payDividends{
        require(accounts[msg.sender].ethereumBalance >= amountEthereum, "{_REINVEST_TOO_MUCH_ETH_}");
        uint256 tokens = calculateTokens(amountEthereum);
        uint256 price =  calculatePrice(tokens, true);
        uint256 averagePrice = tokenPrice.add(price).div(2);
        tokenPrice = price;
        setTokenBalance(tokens, true);
        setTotalSupply(tokens, true);
        setEthereumBalance(amountEthereum, false);
        emit onSell(msg.sender, amountEthereum, tokens, totalSupply, now, averagePrice);
    }
    function withdraw(uint256 amountEthereum) public payDividends{
        require(accounts[msg.sender].ethereumBalance >= amountEthereum, "{_WITHDRAW_TOO_MUCH_ETH_}");
        msg.sender.transfer(amountEthereum);
        setEthereumBalance(amountEthereum, false);
        exit();
        emit onWithdraw(msg.sender, amountEthereum, now);
    }
    function exit() private{
        if(accounts[msg.sender].ethereumBalance < 1e10 && accounts[msg.sender].tokenBalance < 1e10){
            uint256 customerToken = accounts[msg.sender].tokenBalance;
            uint256 customerEthereum = accounts[msg.sender].ethereumBalance;
            uint256 ethereum = calculateEthereum(customerToken);
            uint256 price = calculatePrice(customerToken, false);
            tokenPrice = price;
            setTotalSupply(customerToken, false);
            developerBalance = developerBalance.add(ethereum).add(customerEthereum);
            if(msg.sender != ownerAddress){
                totalInvestors = totalInvestors.sub(1);
            }
            if(totalSupply == 0){
                tokenPrice = 0;
                dividendsPerToken = 0;
            }
            delete accounts[msg.sender];
        }
    }
    function developerWithdraw() onlyOwner public{
        developerAddress.transfer(developerBalance);
    }
    function setDividends(uint256 amountEthereum) private{
        if(amountEthereum > 0){
			accounts[msg.sender].lastDividendsPerToken = dividendsPerToken;	
		    dividendsPerToken = dividendsPerToken.add(amountEthereum.mul(1e18).div(totalSupply));
        }
    }
    function getDividends() public view returns(uint256)
    {
        uint newDividendsPerToken = dividendsPerToken.sub(accounts[msg.sender].lastDividendsPerToken);
		if(newDividendsPerToken > 0){
            return accounts[msg.sender].tokenBalance.mul(newDividendsPerToken).div(1e18);
		}
    }
    function getReferrer() public view returns(address, address, address)
    {
        return (referrer[msg.sender].first, referrer[msg.sender].second, referrer[msg.sender].third);
    }
    function getTokenBalance() public view returns (uint256)
    {
        return accounts[msg.sender].tokenBalance;
    }
    function getEthereumBalance() public view returns (uint256)
    {
        return accounts[msg.sender].ethereumBalance.add(getDividends());
    }
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function calculateEthereum(uint256 incomingTokens) public view returns(uint256 quantityEthereum){
        uint256 ethereum = ((2 * tokenPrice.mul(1e18) - tokenPriceStep * (incomingTokens + 1e18)) / 2 / 1e18) * incomingTokens / 1e18;
        return ethereum;
    }
    function calculateTokens(uint256 incomingEthereum) public view returns(uint256 quantityTokens){
        uint x = tokenPrice.mul(1e18).sub(tokenPriceStep.mul(1e18).div(2));
        uint sqrtBody = x**2 + 2 * tokenPriceStep.mul(1e18) * incomingEthereum.mul(1e18);
        uint tokens = (-x + sqrt(sqrtBody)).div(tokenPriceStep);
        return tokens;
    }
    function calculatePrice(uint256 incomingTokens, bool action) private view returns(uint256 newTokenPrice){
        uint256 newPrice;
        if(action == true){
            newPrice = tokenPrice.add(incomingTokens.mul(tokenPriceStep).div(1e18));
        }
        else if(action == false){
            newPrice = tokenPrice.sub(incomingTokens.mul(tokenPriceStep).div(1e18));
        }
        return newPrice;
    }
    function setTokenBalance(uint256 incomingTokens, bool action) private{
        if(action == true){
            accounts[msg.sender].tokenBalance = accounts[msg.sender].tokenBalance.add(incomingTokens);
        }
        else if(action == false){
            accounts[msg.sender].tokenBalance = accounts[msg.sender].tokenBalance.sub(incomingTokens);
        }
    }
    function setEthereumBalance(uint256 incomingEthereum, bool action) private{
        if(action == true){
            accounts[msg.sender].ethereumBalance = accounts[msg.sender].ethereumBalance.add(incomingEthereum);
        }
        else if(action == false){
            accounts[msg.sender].ethereumBalance = accounts[msg.sender].ethereumBalance.sub(incomingEthereum);
        }
    }
    function setTotalSupply(uint256 incomingTokens, bool action) private{
        if(action == true){
            totalSupply = totalSupply.add(incomingTokens);
        }
        else if(action == false){
            totalSupply = totalSupply.sub(incomingTokens);
        }
    }
    function developerCommissionFee(uint incomingEthereum) private{
        developerBalance = developerBalance.add(incomingEthereum);
    }
    function transferOwnership(address newOwnerAddress) public onlyOwner {
        candidateAddress = newOwnerAddress;
    }
    function confirmOwner() public {
        require(msg.sender == candidateAddress, "{_YOU_ARE_NOT_CANDIDATE_}");
        ownerAddress = candidateAddress;
    }
    function sqrt(uint x) public pure returns (uint y) {
        if (x == 0) return 0;
        else if (x <= 3) return 1;
        uint z = (x + 1) / 2;
        y = x;
        while (z < y)
        {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}