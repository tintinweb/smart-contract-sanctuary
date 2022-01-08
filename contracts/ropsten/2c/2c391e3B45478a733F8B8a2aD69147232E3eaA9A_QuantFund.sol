/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
    
}

interface Token {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256);
}


contract StandardToken is Context, Token {
    uint256 public totalSupply;

    modifier onlyPayloadSize(uint256 numWords) {
        assert(_msgData().length >= numWords * 32 + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2) public virtual returns (bool success) {
        require(_to != address(0));
        require(balances[_msgSender()] >= _value && _value > 0);
        balances[_msgSender()] = balances[_msgSender()] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(_msgSender(), _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3) public virtual returns (bool success) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][_msgSender()] >= _value && _value > 0);
        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][_msgSender()] = allowed[_from][_msgSender()] - _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2) public returns (bool success) {
        require((_value == 0) || (allowed[_msgSender()][_spender] == 0));
        allowed[_msgSender()][_spender] = _value;
        emit Approval(_msgSender(), _spender, _value);

        return true;
    }

    function changeApproval(address _spender, uint256 _oldValue, uint256 _newValue) onlyPayloadSize(3) external returns (bool success) {
        require(allowed[_msgSender()][_spender] == _oldValue);
        allowed[_msgSender()][_spender] = _newValue;
        emit Approval(_msgSender(), _spender, _newValue);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

}


contract QuantFund is StandardToken {

    // FIELDS

    string public name = "QuantFund";
    string public symbol = "QUANT";
    uint256 public decimals = 18;

    // crowdsale parameters
    uint256 public fundingStartBlock;
    uint256 public fundingEndBlock;

    // root control
    address payable public fundWallet;

    // fundWallet controlled state variables
    bool public tradeable = false;
    uint8 public feePercent = 2;

    // -- totalSupply defined in StandardToken
    // -- mapping to token balances done in StandardToken

    uint256 public previousUpdateTime = 0;
    Price public currentPrice;

    // map participant address to a withdrawal request
    mapping (address => Withdrawal) public withdrawals;
    // maps previousUpdateTime to the next price
    mapping (uint256 => Price) public prices;
    // maps addresses
    mapping (address => bool) public whitelist;

    // TYPES

    struct Price { // tokensPerEth
        uint256 numerator;
        uint256 denominator;
    }

    struct Withdrawal {
        uint256 tokens;
        uint256 time; // time for each withdrawal is set to the previousUpdateTime
    }

    // EVENTS

    event Deposit(address indexed participant, address indexed beneficiary, uint256 ethValue, uint256 amountTokens);
    event Received(address, uint256);
    event AllocatePresale(address indexed participant, uint256 amountTokens);
    event Whitelist(address indexed participant);
    event PriceUpdate(uint256 numerator, uint256 denominator);
    event AddLiquidity(uint256 ethAmount);
    event RemoveLiquidity(uint256 ethAmount);
    event WithdrawRequest(address indexed participant, uint256 amountTokens);
    event Withdraw(address indexed participant, uint256 amountTokens, uint256 etherAmount);

    // MODIFIERS

    modifier isTradeable {
        require(tradeable || _msgSender() == fundWallet);
        _;
    }

    modifier onlyWhitelist {
        require(whitelist[_msgSender()]);
        _;
    }

    modifier onlyFundWallet {
        require(_msgSender() == fundWallet);
        _;
    }

    modifier only_if_increase (uint256 newNumerator) {
        if (newNumerator > currentPrice.numerator) _;
    }

    // CONSTRUCTOR

    constructor(uint256 priceNumeratorInput, uint256 startBlockInput, uint256 endBlockInput) {
        require(priceNumeratorInput > 0);
        require(endBlockInput > startBlockInput);
        fundWallet = _msgSender();
        whitelist[fundWallet] = true;
        currentPrice = Price(priceNumeratorInput, 1000); // 1 token = 1 usd at ICO start
        fundingStartBlock = startBlockInput;
        fundingEndBlock = endBlockInput;
        previousUpdateTime = block.timestamp;
    }

    // METHODS

    function updatePrice(uint256 newNumerator) external onlyFundWallet {
        require(block.number > fundingEndBlock);
        require(newNumerator > 0);
        currentPrice.numerator = newNumerator;
        prices[previousUpdateTime] = currentPrice;
        previousUpdateTime = block.timestamp;
        emit PriceUpdate(newNumerator, currentPrice.denominator);
    }

    function updatePriceDenominator(uint256 newDenominator) external onlyFundWallet {
        require(block.number > fundingEndBlock);
        require(newDenominator > 0);
        currentPrice.denominator = newDenominator;
        // maps time to new Price
        prices[previousUpdateTime] = currentPrice;
        previousUpdateTime = block.timestamp;
        emit PriceUpdate(currentPrice.numerator, newDenominator);
    }

    function allocateTokens(address participant, uint256 amountTokens) private {
        uint256 fee = amountTokens * feePercent / 100;
        uint256 newToken = amountTokens + fee;
        // increase token supply, assign tokens to participant
        totalSupply = totalSupply + newToken;
        balances[participant] = balances[participant] + amountTokens;
        balances[fundWallet] = balances[fundWallet] + fee;
    }

    function updateFeePercent(uint8 percent) external onlyFundWallet {
        require(feePercent<=10);
        feePercent = percent;
    }

    function allocatePresaleTokens(address participant, uint amountTokens) external onlyFundWallet {
        require(block.number < fundingEndBlock);
        require(participant != address(0));
        whitelist[participant] = true; // automatically whitelist accepted presale
        allocateTokens(participant, amountTokens);
        emit Whitelist(participant);
        emit AllocatePresale(participant, amountTokens);
    }

    function verifyParticipant(address participant) external onlyFundWallet {
        whitelist[participant] = true;
        emit Whitelist(participant);
    }

    function deposit() external payable {
        depositFrom(_msgSender());
    }

    function depositFrom(address participant) private {
        require(participant != address(0));
        require(block.number >= fundingStartBlock);
        uint256 tokensToBuy = 0;
        if (block.number < fundingEndBlock)
        {
            require(whitelist[participant], "Only whitelist can deposit during ICO.");
            uint256 icoDenominator = icoDenominatorPrice();
            tokensToBuy = msg.value * currentPrice.numerator / icoDenominator;
        }
        else
        {
            tokensToBuy = msg.value * currentPrice.numerator / currentPrice.denominator;
        }
        
        allocateTokens(participant, tokensToBuy);

        // send ether to fundWallet
        fundWallet.transfer(msg.value);
        emit Deposit(_msgSender(), participant, msg.value, tokensToBuy);
    }

    // time based on blocknumbers, assuming a blocktime of 15s / exactly 14s
    function icoDenominatorPrice() public view returns (uint256) {
        uint256 icoDuration = block.number - fundingStartBlock;
        uint256 denominator;
        if (icoDuration < 11520) { // #blocks = 48*60*60/15 = 11520
            denominator = currentPrice.denominator * 95 / 100;
            return denominator;
        } else if (icoDuration < 40320 ) { // #blocks = 7*24*60*60/15 = 161280
            return denominator;
        } else if (currentPrice.denominator < 161280) { // #blocks = 4*7*24*60*60/15
            denominator = currentPrice.denominator * 105 / 100;
            return denominator;
        } else {
            denominator = currentPrice.denominator * 110 / 100;
            return denominator;
        }
    }

    function requestWithdrawal(uint256 amountTokensToWithdraw) external isTradeable {
        require(block.number > fundingEndBlock);
        require(amountTokensToWithdraw > 0);
        address participant = _msgSender();
        require(balanceOf(participant) >= amountTokensToWithdraw);
        require(withdrawals[participant].tokens == 0); // participant cannot have outstanding withdrawals
        balances[participant] = balances[participant] - amountTokensToWithdraw;
        withdrawals[participant] = Withdrawal({tokens: amountTokensToWithdraw, time: previousUpdateTime});
        emit WithdrawRequest(participant, amountTokensToWithdraw);
    }

    function withdraw() external {
        address payable participant = _msgSender();
        uint256 tokens = withdrawals[participant].tokens;
        require(tokens > 0); // participant must have requested a withdrawal
        uint256 requestTime = withdrawals[participant].time;
        // obtain the next price that was set after the request
        Price memory price = prices[requestTime];
        require(price.numerator > 0); // price must have been set
        uint256 withdrawValue = tokens * price.denominator / price.numerator;
        // if contract ethbal > then send + transfer tokens to fundWallet, otherwise give tokens back
        withdrawals[participant].tokens = 0;
        if (address(this).balance >= withdrawValue)
            enact_withdrawal_greater_equal(participant, withdrawValue, tokens);
        else
            enact_withdrawal_less(participant, withdrawValue, tokens);
    }

    function enact_withdrawal_greater_equal(address payable participant, uint256 withdrawValue, uint256 tokens)
        private
    {
        assert(address(this).balance >= withdrawValue);
        balances[fundWallet] = balances[fundWallet] + tokens;
        participant.transfer(withdrawValue);
        emit Withdraw(participant, tokens, withdrawValue);
    }
    function enact_withdrawal_less(address payable participant, uint256 withdrawValue, uint256 tokens)
        private
    {
        assert(address(this).balance < withdrawValue);
        balances[participant] = balances[participant] + tokens;
        emit Withdraw(participant, tokens, 0); // indicate a failed withdrawal
    }


    function checkWithdrawValue(uint256 amountTokensToWithdraw) external view returns (uint256 etherValue) {
        require(amountTokensToWithdraw > 0);
        require(balanceOf(_msgSender()) >= amountTokensToWithdraw);
        uint256 withdrawValue = amountTokensToWithdraw * currentPrice.denominator / currentPrice.numerator;
        require(address(this).balance >= withdrawValue);
        return withdrawValue;
    }

    // allow fundWallet add ether to contract
    function addLiquidity() external onlyFundWallet payable {
        require(msg.value > 0);
        emit AddLiquidity(msg.value);
    }

    // allow fundWallet to remove ether from contract
    function removeLiquidity(uint256 amount) external onlyFundWallet {
        require(amount <= address(this).balance);
        fundWallet.transfer(amount);
        emit RemoveLiquidity(amount);
    }

    function changeFundWallet(address payable newFundWallet) external onlyFundWallet {
        require(newFundWallet != address(0));
        fundWallet = newFundWallet;
    }

    function updateFundingStartBlock(uint256 newFundingStartBlock) external onlyFundWallet {
        require(block.number < fundingStartBlock);
        require(block.number < newFundingStartBlock);
        fundingStartBlock = newFundingStartBlock;
    }

    function updateFundingEndBlock(uint256 newFundingEndBlock) external onlyFundWallet {
        require(block.number < fundingEndBlock);
        require(block.number < newFundingEndBlock);
        fundingEndBlock = newFundingEndBlock;
    }

    function enableTrading() external onlyFundWallet {
        require(block.number > fundingEndBlock);
        tradeable = true;
    }

    fallback() external payable {
        require(tx.origin == _msgSender());
        depositFrom(_msgSender());
    }
    
    receive() external payable {
        emit Received(_msgSender(), msg.value);
    }

    function claimTokens(address _token) external onlyFundWallet {
        require(_token != address(0));
        Token token = Token(_token);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(fundWallet, balance);
     }

    // prevent transfers until trading allowed
    function transfer(address _to, uint256 _value) isTradeable public override returns (bool success) {
        return super.transfer(_to, _value);
    }
    function transferFrom(address _from, address _to, uint256 _value) isTradeable public override returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

}