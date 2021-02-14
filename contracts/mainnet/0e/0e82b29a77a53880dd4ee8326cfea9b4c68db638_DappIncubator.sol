/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

// SPDX-License-Identifier: MIT

/**
 *  Program Name    : DappIncubator
 *  Website         : https://www.dappincubator.com
 *  Telegram        : https://t.me/dappincubatorofficial
 *  Concept         : High Return On Investment
 *  Category        : Passive Income
 *  Risk Category   : High Risk
 **/

pragma solidity >=0.6.0 <0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract DappIncubator is Ownable, ReentrancyGuard {
    
    /**
     * @dev Structure to hold tokens supplu and dividend per share against collateral.
     */
    struct TokenLedger {
        uint supply;
        uint dividend;
        uint initialPrice;
        uint incrementPrice;
    }
    
    /**
     * @dev Structure to hold collateral balalnce of wallet.
     */
    struct BalanceLedger {
        uint tokenBalance;
        uint referralBalance;
        int payOut;
    }
    
    /**
     * @dev mapping to store all active contract addresses and wallet addresses. This will be used to check if contract address and wallet address already part of system.
     */
    mapping(address => bool) contractAddressRecord;
    mapping(address => bool) walletAddressRecord;
    
    uint constant magnitude = 1e18 ;
    uint constant dividendFee = 10;
    
    /**
     * @dev structure mapping created for storing balance and token information.
     */
    mapping (address => mapping(address => BalanceLedger)) balanceLedger;
    mapping(address => TokenLedger) tokenLedger;
    
    /**
     * @dev events to register information about collateral buy, sell, reinvest and token withdraw.
     */
     
    event onTokenOnboard(address indexed contractAddress, uint initialPrice, uint incrementPrice);
    event onPurchase(address indexed walletAddress, address indexed contractAddress, uint incomingTokenAmount, uint collateralMinted, address indexed referredBy);
    event onSell(address indexed walletAddress, address indexed contractAddress, uint tokenAmountToReceiver, uint collateralBurned);
    event onReinvest(address indexed walletAddress, address indexed contractAddress, uint reInvestTokenAmount, uint collateralMinted);
    event onWithdraw(address indexed walletAddress, address indexed contractAddress, uint amountToWithdraw);
    event onTransfer(address indexed contractAddress, address indexed from,address indexed to,uint256 tokens);
    
    /**
     * @dev function to add ERC-20 Token to ecosystem.
     */
     function tokenOnboard(address contractAddress, uint initialPrice, uint incrementPrice) public nonReentrant onlyOwner returns(bool)
     {
         if(contractAddressRecord[contractAddress] == false)
         {
            contractAddressRecord[contractAddress] = true;
            tokenLedger[contractAddress].initialPrice = initialPrice;
            tokenLedger[contractAddress].incrementPrice = incrementPrice;
            tokenLedger[contractAddress].supply = 0;
            tokenLedger[contractAddress].dividend = 0;
            
            emit onTokenOnboard(contractAddress, initialPrice, incrementPrice);
            
            return true;
         }
         
     }
    
    
    /**
     * @dev function to purchase collateral by sending Ethereum.
     */
    function buy(address _referredBy) public nonReentrant payable returns(uint256)
    {
        require(msg.value>0);
        require(contractAddressRecord[address(0)] == true);
        
        // if first investment from user then activate wallet address in system.
        if(walletAddressRecord[msg.sender] == false){
            walletAddressRecord[msg.sender] = true;
        }
        
        uint256 collateAmount = purchaseCollate(address(0), msg.value, _referredBy);
        return collateAmount;
    }
    
    /**
     * @dev function to purchase collateral by sending any ERC-20 Tokens except Ethereum.
     */
    function buy(address contractAddress, uint256 tokenAmount, address _referredBy) public nonReentrant returns(uint256)
    {
        
        // transfer token to system from user wallet
        require(contractAddressRecord[contractAddress] == true);
        require(tokenAmount > 0);
        require(ERC20(contractAddress).allowance(msg.sender, address(this)) >= tokenAmount);
        require(ERC20(contractAddress).transferFrom(msg.sender, address(this), tokenAmount));
        
        
        
        // if first investment from user then activate wallet address in system.
        if(walletAddressRecord[msg.sender] == false){
            walletAddressRecord[msg.sender] = true;
        }
        
        uint256 collateAmount = purchaseCollate(contractAddress,tokenAmount, _referredBy);
        return collateAmount;
    }
    
    /**
     * @dev function to purchase collateral by sending Ethereum directly to smart contract address.
     */
    fallback() nonReentrant payable external
    {
        require(msg.value > 0);
        require(contractAddressRecord[address(0)] == true);
        
        // if first investment from user then activate wallet address in system.
        if(walletAddressRecord[msg.sender] == false){
            walletAddressRecord[msg.sender] = true;
        }
        purchaseCollate(address(0), msg.value, address(0));
    }
    
    /**
     * @dev function to convert all dividend to collateral.
     */
    function reinvest(address contractAddress) public nonReentrant
    {
        require(contractAddressRecord[contractAddress] == true);
        require(walletAddressRecord[msg.sender] == true);
        
        // fetch dividends
        uint256 _dividends = myDividends(contractAddress, false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        balanceLedger[_customerAddress][contractAddress].payOut +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += balanceLedger[_customerAddress][contractAddress].referralBalance;
        
        balanceLedger[_customerAddress][contractAddress].referralBalance = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _collate = purchaseCollate(contractAddress, _dividends, address(0));
        
        // fire event
        emit onReinvest(_customerAddress, contractAddress, _dividends, _collate);
    }
    
    /**
     * @dev function to sell collateral and withdraw tokens.
     */
    function exit(address contractAddress) public nonReentrant
    {
        require(contractAddressRecord[contractAddress] == true);
        require(walletAddressRecord[msg.sender] == true);
        
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = balanceLedger[_customerAddress][contractAddress].tokenBalance;
        if(_tokens > 0) sell(contractAddress, _tokens);
    
        withdraw(contractAddress);
    }

    /**
     * @dev function to withdraw tokens, dividend and referralBalance.
     */
    function withdraw(address contractAddress) public nonReentrant
    {
        require(contractAddressRecord[contractAddress] == true);
        require(walletAddressRecord[msg.sender] == true);
        
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(contractAddress, false); // get ref. bonus later in the code
        
        // update dividend tracker
        balanceLedger[_customerAddress][contractAddress].payOut +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += balanceLedger[_customerAddress][contractAddress].referralBalance;
        balanceLedger[_customerAddress][contractAddress].referralBalance = 0;
        
        // delivery service
        if (contractAddress == address(0)){
            payable(address(_customerAddress)).transfer(_dividends);
        }
        else{
            ERC20(contractAddress).transfer(_customerAddress,_dividends);
        }
        
        
        // fire event
        emit onWithdraw(_customerAddress, contractAddress, _dividends);
    }
    
    
    /**
     * Transfer collateral from the caller to a new holder.
     * Remember, there's a 10% fee here as well.
     */
    function transfer(address contractAddress, address toAddress, uint256 amountOfCollate) public returns(bool)
    {
        address _customerAddress = msg.sender;
        
        require(contractAddressRecord[contractAddress] == true);
        require(walletAddressRecord[_customerAddress] == true);
        require(amountOfCollate <= balanceLedger[_customerAddress][contractAddress].tokenBalance);
        
        if(walletAddressRecord[toAddress] == false){
            walletAddressRecord[toAddress] = true;
        }
        
        // withdraw all outstanding dividends first
        if(myDividends(contractAddress, true) > 0) withdraw(contractAddress);
        
        // calculate divident fees, tokens to transfer
        uint256 _tokenFee = SafeMath.div(amountOfCollate, dividendFee);
        uint256 _taxedTokens = SafeMath.sub(amountOfCollate, _tokenFee);
        uint256 _dividends = collateralToToken_(contractAddress, _tokenFee);
  
        // burn the fee tokens
        tokenLedger[contractAddress].supply = SafeMath.sub(tokenLedger[contractAddress].supply, _tokenFee);

        // exchange tokens
        balanceLedger[_customerAddress][contractAddress].tokenBalance = SafeMath.sub(balanceLedger[_customerAddress][contractAddress].tokenBalance, amountOfCollate);
        balanceLedger[toAddress][contractAddress].tokenBalance = SafeMath.add(balanceLedger[toAddress][contractAddress].tokenBalance, _taxedTokens);
        
        // update dividend trackers
        balanceLedger[_customerAddress][contractAddress].payOut -= (int256) (tokenLedger[contractAddress].dividend * amountOfCollate);
        balanceLedger[toAddress][contractAddress].payOut += (int256) (tokenLedger[contractAddress].dividend * _taxedTokens);
        
        // disperse dividends among holders
        tokenLedger[contractAddress].dividend = SafeMath.add(tokenLedger[contractAddress].dividend, (_dividends * magnitude) / tokenLedger[contractAddress].supply);
        
        // emit transfer events
        emit onTransfer(contractAddress, _customerAddress, toAddress, _taxedTokens);
        
        return true;

    }
    
    
    /**
     * @dev function to sell collatral.
     */
    function sell(address contractAddress, uint256 _amountOfCollate) public
    {
        require(contractAddressRecord[contractAddress] == true);
        require(walletAddressRecord[msg.sender] == true);
      
        address _customerAddress = msg.sender;
       
        require(_amountOfCollate <= balanceLedger[_customerAddress][contractAddress].tokenBalance);
        
        uint256 _collates = _amountOfCollate;
        uint256 _tokens = collateralToToken_(contractAddress, _collates);
        uint256 _dividends = SafeMath.div(_tokens, dividendFee);
        uint256 _taxedToken = SafeMath.sub(_tokens, _dividends);
        
        // burn the sold tokens
        tokenLedger[contractAddress].supply = SafeMath.sub(tokenLedger[contractAddress].supply, _collates);
        balanceLedger[_customerAddress][contractAddress].tokenBalance = SafeMath.sub(balanceLedger[_customerAddress][contractAddress].tokenBalance, _collates);
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (tokenLedger[contractAddress].dividend * _collates + (_taxedToken * magnitude));
        balanceLedger[_customerAddress][contractAddress].payOut -= _updatedPayouts;       
        
        // dividing by zero is a bad idea
        if (tokenLedger[contractAddress].supply > 0) {
            // update the amount of dividends per token
            tokenLedger[contractAddress].dividend = SafeMath.add(tokenLedger[contractAddress].dividend, (_dividends * magnitude) / tokenLedger[contractAddress].supply);
        }
        
        // fire event
        emit onSell(_customerAddress, contractAddress, _taxedToken, _collates);
    }
        
    /**
     * @dev function to get current purchase price of single collateral.
     */
    function buyPrice(address contractAddress) public view returns(uint currentBuyPrice) {
        require(contractAddressRecord[contractAddress] == true);
        
        if(tokenLedger[contractAddress].supply == 0){
            return tokenLedger[contractAddress].initialPrice + tokenLedger[contractAddress].incrementPrice;
        } else {
            uint256 _token = collateralToToken_(contractAddress, 1e18);
            uint256 _dividends = SafeMath.div(_token, dividendFee);
            uint256 _taxedToken = SafeMath.add(_token, _dividends);
            return _taxedToken;
        }
    }
    
    /**
     * @dev function to get current sell price of single collateral.
     */
    function sellPrice(address contractAddress) public view returns(uint) {
        require(contractAddressRecord[contractAddress] == true);
        
        if(tokenLedger[contractAddress].supply == 0){
            return tokenLedger[contractAddress].initialPrice - tokenLedger[contractAddress].incrementPrice;
        } else {
            uint256 _token = collateralToToken_(contractAddress, 1e18);
            uint256 _dividends = SafeMath.div(_token, dividendFee);
            uint256 _taxedToken = SafeMath.sub(_token, _dividends);
            return _taxedToken;
        }
    }

    
    /**
     * @dev function to calculate collateral price based on an amount of incoming token
     * It's an scientific algorithm;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokentoCollateral_(address contractAddress, uint amount) internal view returns(uint)
    {
        uint256 _tokenPriceInitial = tokenLedger[contractAddress].initialPrice * 1e18;
        uint256 tokenSupply_ = tokenLedger[contractAddress].supply;
        uint tokenPriceIncremental_ = tokenLedger[contractAddress].incrementPrice;
        
        uint256 _tokensReceived = 
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +
                            (2*(tokenPriceIncremental_ * 1e18)*(amount * 1e18))
                            +
                            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +
                            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;
  
        return _tokensReceived;
    }
    
    /**
     * @dev function to calculate token price based on an amount of incoming collateral
     * It's an scientific algorithm;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function collateralToToken_(address contractAddress, uint256 _tokens) internal view returns(uint256)
    {

        uint256 tokens_ = _tokens + 1e18 ;
        uint256 _tokenSupply = tokenLedger[contractAddress].supply + 1e18;
        uint256 tokenPriceInitial_ = tokenLedger[contractAddress].initialPrice;
        uint tokenPriceIncremental_ = tokenLedger[contractAddress].incrementPrice;
        
        uint256 _etherReceived =
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (
                    (
                        (
                            tokenPriceInitial_ +(tokenPriceIncremental_ * (_tokenSupply/1e18))
                        )-tokenPriceIncremental_
                    )*(tokens_ - 1e18)
                ),(tokenPriceIncremental_*((tokens_**2-tokens_)/1e18))/2
            )
        /1e18);
        
        return _etherReceived;
    }
    
    /**
     * @dev function to calculate amount of collateral received after sending tokens
     */
    function calculateCollateReceived(address contractAddress, uint256 _tokenAmount) public view returns(uint256)
    {
        require(contractAddressRecord[contractAddress] == true);
        
        uint256 _dividends = SafeMath.div(_tokenAmount, dividendFee);
        uint256 _taxedToken = SafeMath.sub(_tokenAmount, _dividends);
        uint256 _amountOfCollatral = tokentoCollateral_(contractAddress, _taxedToken);
        
        return _amountOfCollatral;
    }
     
    /**
     * @dev function to calculate amount of tokens received after sending collateral
     */
    function calculateTokenReceived(address contractAddress, uint256 _collateToSell) public view returns(uint256)
    {
        require(contractAddressRecord[contractAddress] == true);
        require(_collateToSell <= tokenLedger[contractAddress].supply);
        
        uint256 _token = collateralToToken_(contractAddress, _collateToSell);
        uint256 _dividends = SafeMath.div(_token, dividendFee);
        uint256 _taxedToken = SafeMath.sub(_token, _dividends);
        return _taxedToken;
    }  
    
    /**
     * @dev function to process purchase of collateral and update user balance, dividend
     */
    function purchaseCollate(address contractAddress, uint256 _incomingToken, address _referredBy) internal returns(uint256)
    {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingToken, dividendFee);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedToken = SafeMath.sub(_incomingToken, _undividedDividends);
        uint256 _amountOfCollate = tokentoCollateral_(contractAddress,_taxedToken);
        uint256 _fee = _dividends * magnitude;
 
      
        require(_amountOfCollate > 0 && (SafeMath.add(_amountOfCollate,tokenLedger[contractAddress].supply) > tokenLedger[contractAddress].supply));
        
        // is the user referred by a karmalink?
        if(
            // is this a referred purchase?
            _referredBy != address(0) &&
            
            // no cheating!
            _referredBy != _customerAddress &&
            
            walletAddressRecord[_referredBy] == true
        ){
            // wealth redistribution
            balanceLedger[_referredBy][contractAddress].referralBalance = SafeMath.add(balanceLedger[_referredBy][contractAddress].referralBalance, _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
        // we can't give people infinite ethereum
        if(tokenLedger[contractAddress].supply > 0){
            
            // add tokens to the pool
            tokenLedger[contractAddress].supply = SafeMath.add(tokenLedger[contractAddress].supply, _amountOfCollate);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            tokenLedger[contractAddress].dividend += (_dividends * magnitude / (tokenLedger[contractAddress].supply));
            
            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfCollate * (_dividends * magnitude / (tokenLedger[contractAddress].supply))));
        
        } else {
            // add tokens to the pool
            tokenLedger[contractAddress].supply = _amountOfCollate;
        }
        
        // update circulating supply & the ledger address for the customer
        balanceLedger[_customerAddress][contractAddress].tokenBalance = SafeMath.add(balanceLedger[_customerAddress][contractAddress].tokenBalance, _amountOfCollate);
        
        int256 _updatedPayouts = (int256) ((tokenLedger[contractAddress].dividend * _amountOfCollate) - _fee);
        balanceLedger[_customerAddress][contractAddress].payOut += _updatedPayouts;
        
        // fire event
        emit onPurchase(_customerAddress, contractAddress, _incomingToken, _amountOfCollate, _referredBy);
        
        return _amountOfCollate;
    }
    
    /**
     * @dev function to get tokens contract hold
     */
    function totalTokenBalance(address contractAddress) public view returns(uint)
    {   
        require(contractAddressRecord[contractAddress] == true);
        
        if (contractAddress== address(0)){
            return address(this).balance;
        }
        else{
            return ERC20(contractAddress).balanceOf(address(this));
        }
    }
    
    /**
     * @dev function to retrieve the total token supply.
     */
    function totalSupply(address contractAddress) public view returns(uint256)
    {
        require(contractAddressRecord[contractAddress] == true);
        
        return tokenLedger[contractAddress].supply;
    }
    
    /**
     * @dev function to retrieve the tokens owned by the caller.
     */
    function myTokens(address contractAddress) public view returns(uint256)
    {
        require(contractAddressRecord[contractAddress] == true);
        
        address _customerAddress = msg.sender;
        return balanceOf(contractAddress, _customerAddress);
    }
    
    /**
     * @dev function to retrieve the dividends owned by the caller.
      */ 
    function myDividends(address contractAddress, bool _includeReferralBonus) public view returns(uint256)
    {
        require(contractAddressRecord[contractAddress] == true);
        
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(contractAddress,_customerAddress) + balanceLedger[_customerAddress][contractAddress].referralBalance : dividendsOf(contractAddress, _customerAddress) ;
    }
    
    /**
     * @dev function to retrieve the token balance of any single address.
     */
    function balanceOf(address contractAddress, address _customerAddress) view public returns(uint256)
    {
        require(contractAddressRecord[contractAddress] == true);
        
        return balanceLedger[_customerAddress][contractAddress].tokenBalance;
    }
    
    /**
     * @dev function to retrieve the dividend balance of any single address.
     */
    function dividendsOf(address contractAddress, address _customerAddress) view public returns(uint256)
    {
        require(contractAddressRecord[contractAddress] == true);
        
        return (uint256) ((int256)(tokenLedger[contractAddress].dividend * balanceLedger[_customerAddress][contractAddress].tokenBalance) - balanceLedger[_customerAddress][contractAddress].payOut) / magnitude;
    }
    
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

/**
 * @dev interface to process transfer of ERC20 tokens
 */ 
interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function approve(address _spender, uint _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);

    event Approval(address indexed _owner, address indexed _spender,    uint _value);
    event Transfer(address indexed _from, address indexed _to, uint    _value);
}

/**
 * @dev safemath library to avoid mathematical overflow error
 */ 
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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