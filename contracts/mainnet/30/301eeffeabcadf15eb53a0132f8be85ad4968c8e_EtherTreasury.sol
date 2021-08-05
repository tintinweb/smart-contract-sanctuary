/**
 *Submitted for verification at Etherscan.io on 2020-12-18
*/

// SPDX-License-Identifier: MIT

/**
 *  Program Name: EtherTreasury
 *  Website     : https://www.ethertreasury.com/
 *  Concept     : Ethereum & ERC-20 Toekns Dividend Paying DApp
 *  Category    : Passive Income
 * */

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


contract EtherTreasury is Ownable {
    
    /**
     * @dev Structure to hold tokens supplu and dividend per share against collateral.
     */
    struct TokenMaster {
        uint supply;
        uint dividend;
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
    mapping(address => bool) contractAddressList;
    mapping(address => bool) walletAddressList;
    
    /**
     * @dev array to store active contract address and wallet addresses.
     */
    address[] contractAddressSet;
    address[] walletAddressSet;
    
    uint constant magnitude = 1e18 ;
    uint constant initialPrice = 100000000000;
    uint constant incrementPrice = 10000000000;
    uint constant dividendFee = 10;
    
    /**
     * @dev owner will start program on given time for investment.
     */
    bool startDeposit = false;
    
    /**
     * @dev structure mapping created for storing balance and token information.
     */
    mapping (address => mapping(address => BalanceLedger)) balanceDetails;
    mapping(address => TokenMaster) tokenDetails;
    
    /**
     * @dev events to register information about collateral buy, sell, reinvest and token withdraw.
     */
    event onPurchase(address walletAddress, address contractAddress, uint incomingTokenAmount, uint collateralMinted, address referredBy);
    event onSell(address walletAddress, address contractAddress, uint tokenAmountToReceiver, uint collateralBurned);
    event onReinvest(address walletAddress, address contractAddress, uint reInvestTokenAmount, uint collateralMinted);
    event onWithdraw(address walletAddress, address contractAddress, uint amountToWithdraw);
    
    /**
     * @dev function to purchase collateral by sending Ethereum.
     */
    function buy(address _referredBy) public payable returns(uint256)
    {
        require(startDeposit);
        require(msg.value>0);
        
        // if this is first deposit transaction for token then activate token struct storage with default initial parameters.
        if(contractAddressList[0x0000000000000000000000000000000000000000] == false){
            contractAddressList[0x0000000000000000000000000000000000000000] = true ;
            
            tokenDetails[0x0000000000000000000000000000000000000000].supply = 0;
            tokenDetails[0x0000000000000000000000000000000000000000].dividend = 0;
            
            contractAddressSet.push(0x0000000000000000000000000000000000000000);
        }
        
        // if first investment from user then activate wallet address in system.
        if(walletAddressList[msg.sender] == false){
            walletAddressList[msg.sender] = true;
            walletAddressSet.push(msg.sender);
        }
        
        uint256 collateAmount = purchaseCollate(0x0000000000000000000000000000000000000000, msg.value, _referredBy);
        return collateAmount;
    }
    
    /**
     * @dev function to purchase collateral by sending any ERC-20 Tokens except Ethereum.
     */
    function buy(address contractAddress, uint256 tokenAmount, address _referredBy) public returns(uint256)
    {
        require(startDeposit);
        
        // transfer token to system from user wallet
        require(ERC20(contractAddress).allowance(msg.sender, address(this)) >= tokenAmount);
        require(ERC20(contractAddress).transferFrom(msg.sender, address(this), tokenAmount));
        
        // if this is first deposit transaction for token then activate token struct storage with default initial parameters.
        if(contractAddressList[contractAddress]==false){
            contractAddressList[contractAddress]=true ;
            
            tokenDetails[contractAddress].supply = 0;
            tokenDetails[contractAddress].dividend = 0;
            
            contractAddressSet.push(contractAddress);
        }
        
        // if first investment from user then activate wallet address in system.
        if(walletAddressList[msg.sender] == false){
            walletAddressList[msg.sender] = true;
            walletAddressSet.push(msg.sender);
        }
        
        uint256 collateAmount = purchaseCollate(contractAddress,tokenAmount, _referredBy);
        return collateAmount;
    }
    
    /**
     * @dev function to purchase collateral by sending Ethereum directly to smart contract address.
     */
    fallback() payable external
    {
        require(startDeposit);
        require(msg.value > 0);
        // if this is first deposit transaction for token then activate token struct storage with default initial parameters.
        if(contractAddressList[0x0000000000000000000000000000000000000000] == false){
            contractAddressList[0x0000000000000000000000000000000000000000] = true ;
            
            tokenDetails[0x0000000000000000000000000000000000000000].supply = 0;
            tokenDetails[0x0000000000000000000000000000000000000000].dividend = 0;
            
            contractAddressSet.push(0x0000000000000000000000000000000000000000);
        }
        
        // if first investment from user then activate wallet address in system.
        if(walletAddressList[msg.sender] == false){
            walletAddressList[msg.sender] = true;
            walletAddressSet.push(msg.sender);
        }
        purchaseCollate(0x0000000000000000000000000000000000000000, msg.value, 0x0000000000000000000000000000000000000000);
    }
    
    /**
     * @dev function to convert all dividend to collateral.
     */
    function reinvest(address contractAddress) public
    {
        // fetch dividends
        uint256 _dividends = myDividends(contractAddress, false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        balanceDetails[_customerAddress][contractAddress].payOut +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += balanceDetails[_customerAddress][contractAddress].referralBalance;
        
        balanceDetails[_customerAddress][contractAddress].referralBalance = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _collate = purchaseCollate(contractAddress, _dividends, 0x0000000000000000000000000000000000000000);
        
        // fire event
        emit onReinvest(_customerAddress, contractAddress, _dividends, _collate);
    }
    
    /**
     * @dev function to sell collateral and withdraw tokens.
     */
    function sellAndwithdraw(address contractAddress) public
    {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = balanceDetails[_customerAddress][contractAddress].tokenBalance;
        if(_tokens > 0) sell(contractAddress, _tokens);
    
        withdraw(contractAddress);
    }

    /**
     * @dev function to withdraw tokens, dividend and referralBalance.
     */
    function withdraw(address contractAddress) public
    {
        // setup data
        address _customerAddress = msg.sender;
        uint256 _dividends = myDividends(contractAddress, false); // get ref. bonus later in the code
        
        // update dividend tracker
        balanceDetails[_customerAddress][contractAddress].payOut +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += balanceDetails[_customerAddress][contractAddress].referralBalance;
        balanceDetails[_customerAddress][contractAddress].referralBalance = 0;
        
        // delivery service
        if (contractAddress == 0x0000000000000000000000000000000000000000){
            payable(address(_customerAddress)).transfer(_dividends);
        }
        else{
            ERC20(contractAddress).transfer(_customerAddress,_dividends);
        }
        
        
        // fire event
        emit onWithdraw(_customerAddress, contractAddress, _dividends);
    }
    
    /**
     * @dev function to sell collatral.
     */
    function sell(address contractAddress, uint256 _amountOfCollate) public
    {
      
        address _customerAddress = msg.sender;
       
        require(_amountOfCollate <= balanceDetails[_customerAddress][contractAddress].tokenBalance);
        
        uint256 _collates = _amountOfCollate;
        uint256 _tokens = collateralToToken_(contractAddress, _collates);
        uint256 _dividends = SafeMath.div(_tokens, dividendFee);
        uint256 _taxedToken = SafeMath.sub(_tokens, _dividends);
        
        // burn the sold tokens
        tokenDetails[contractAddress].supply = SafeMath.sub(tokenDetails[contractAddress].supply, _collates);
        balanceDetails[_customerAddress][contractAddress].tokenBalance = SafeMath.sub(balanceDetails[_customerAddress][contractAddress].tokenBalance, _collates);
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (tokenDetails[contractAddress].dividend * _collates + (_taxedToken * magnitude));
        balanceDetails[_customerAddress][contractAddress].payOut -= _updatedPayouts;       
        
        // dividing by zero is a bad idea
        if (tokenDetails[contractAddress].supply > 0) {
            // update the amount of dividends per token
            tokenDetails[contractAddress].dividend = SafeMath.add(tokenDetails[contractAddress].dividend, (_dividends * magnitude) / tokenDetails[contractAddress].supply);
        }
        
        // fire event
        emit onSell(_customerAddress, contractAddress, _taxedToken, _collates);
    }
        
    /**
     * @dev function to get current purchase price of single collateral.
     */
    function buyPrice(address contractAddress) public view returns(uint currentBuyPrice) {
        if(tokenDetails[contractAddress].supply == 0){
            return initialPrice + incrementPrice;
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
        if(tokenDetails[contractAddress].supply == 0){
            return initialPrice - incrementPrice;
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
        uint256 _tokenPriceInitial = initialPrice * 1e18;
        uint256 tokenSupply_ = tokenDetails[contractAddress].supply;
        uint tokenPriceIncremental_ = incrementPrice;
        
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
        uint256 _tokenSupply = tokenDetails[contractAddress].supply + 1e18;
        uint256 tokenPriceInitial_ = initialPrice;
        uint tokenPriceIncremental_ = incrementPrice;
        
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
        require(_collateToSell <= tokenDetails[contractAddress].supply);
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
 
      
        require(_amountOfCollate > 0 && (SafeMath.add(_amountOfCollate,tokenDetails[contractAddress].supply) > tokenDetails[contractAddress].supply));
        
        // is the user referred by a karmalink?
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000 &&
            
            // no cheating!
            _referredBy != _customerAddress &&
            
            walletAddressList[_referredBy] == true
        ){
            // wealth redistribution
            balanceDetails[_referredBy][contractAddress].referralBalance = SafeMath.add(balanceDetails[_referredBy][contractAddress].referralBalance, _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
        // we can't give people infinite ethereum
        if(tokenDetails[contractAddress].supply > 0){
            
            // add tokens to the pool
            tokenDetails[contractAddress].supply = SafeMath.add(tokenDetails[contractAddress].supply, _amountOfCollate);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            tokenDetails[contractAddress].dividend += (_dividends * magnitude / (tokenDetails[contractAddress].supply));
            
            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfCollate * (_dividends * magnitude / (tokenDetails[contractAddress].supply))));
        
        } else {
            // add tokens to the pool
            tokenDetails[contractAddress].supply = _amountOfCollate;
        }
        
        // update circulating supply & the ledger address for the customer
        balanceDetails[_customerAddress][contractAddress].tokenBalance = SafeMath.add(balanceDetails[_customerAddress][contractAddress].tokenBalance, _amountOfCollate);
        
        int256 _updatedPayouts = (int256) ((tokenDetails[contractAddress].dividend * _amountOfCollate) - _fee);
        balanceDetails[_customerAddress][contractAddress].payOut += _updatedPayouts;
        
        // fire event
        emit onPurchase(_customerAddress, contractAddress, _incomingToken, _amountOfCollate, _referredBy);
        
        return _amountOfCollate;
    }
    
    /**
     * @dev function to get tokens contract hold
     */
    function totalTokenBalance(address contractAddress) public view returns(uint)
    {   
        if (contractAddress== 0x0000000000000000000000000000000000000000){
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
        return tokenDetails[contractAddress].supply;
    }
    
    /**
     * @dev function to retrieve the tokens owned by the caller.
     */
    function myTokens(address contractAddress) public view returns(uint256)
    {
        address _customerAddress = msg.sender;
        return balanceOf(contractAddress, _customerAddress);
    }
    
    /**
     * @dev function to retrieve the dividends owned by the caller.
      */ 
    function myDividends(address contractAddress, bool _includeReferralBonus) public view returns(uint256)
    {
        address _customerAddress = msg.sender;
        return _includeReferralBonus ? dividendsOf(contractAddress,_customerAddress) + balanceDetails[_customerAddress][contractAddress].referralBalance : dividendsOf(contractAddress, _customerAddress) ;
    }
    
    /**
     * @dev function to retrieve the token balance of any single address.
     */
    function balanceOf(address contractAddress, address _customerAddress) view public returns(uint256)
    {
        return balanceDetails[_customerAddress][contractAddress].tokenBalance;
    }
    
    /**
     * @dev function to retrieve the dividend balance of any single address.
     */
    function dividendsOf(address contractAddress, address _customerAddress) view public returns(uint256)
    {
        return (uint256) ((int256)(tokenDetails[contractAddress].dividend * balanceDetails[_customerAddress][contractAddress].tokenBalance) - balanceDetails[_customerAddress][contractAddress].payOut) / magnitude;
    }
    

    /**
     * @dev function to return active tokens list in system
     */ 
    function tokenList() public view returns (address [] memory){
        return contractAddressSet;
    }
    
    /**
     * @dev function to return active wallets list in system
     */ 
    function walletList() public view returns (address [] memory){
        return walletAddressSet;
    }
    

    /**
     * @dev function to process swapping of user balance to new token contract address in case project decide to swap ERC-20 token
     * This function will be used only when project team sent equivalent new contract in system token without asking for old tokens
     * token swap ratio must be same
     * this will protect users from price crash due to token sell for swapping. 
     */ 
    function swapTokenContract(address oldContractAddress, address newContractAddress) public onlyOwner returns(bool success)
    {
        // validate old contract is already part of system
        require(contractAddressList[oldContractAddress]=true, "Old contract tokens must be part of system");
        
        // activate new contractAddress in system
        if(contractAddressList[newContractAddress]==false)
        {
            contractAddressList[newContractAddress]=true ;
            tokenDetails[newContractAddress].supply = 0;
            tokenDetails[newContractAddress].dividend = 0;
            
            contractAddressSet.push(newContractAddress);
        }
        
        for(uint i = 0; i < walletAddressSet.length; i++)
        {
            if (balanceDetails[walletAddressSet[i]][oldContractAddress].tokenBalance > 0 || balanceDetails[walletAddressSet[i]][oldContractAddress].payOut > 0)
            {
                // swap user balance from old contract address to new contract address
                balanceDetails[walletAddressSet[i]][newContractAddress].tokenBalance = balanceDetails[walletAddressSet[i]][oldContractAddress].tokenBalance;
                balanceDetails[walletAddressSet[i]][newContractAddress].referralBalance = balanceDetails[walletAddressSet[i]][oldContractAddress].referralBalance;
                balanceDetails[walletAddressSet[i]][newContractAddress].payOut = balanceDetails[walletAddressSet[i]][oldContractAddress].payOut;
                
                // set old contract address balance to zero
                balanceDetails[walletAddressSet[i]][oldContractAddress].tokenBalance=0;
                balanceDetails[walletAddressSet[i]][oldContractAddress].referralBalance=0;
                balanceDetails[walletAddressSet[i]][oldContractAddress].payOut=0;
            }
        }
        
        // swap dividend, current price and supply from old contract to new contract
        tokenDetails[newContractAddress].supply = tokenDetails[oldContractAddress].supply;
        tokenDetails[newContractAddress].dividend = tokenDetails[oldContractAddress].dividend;
        
        // set old contract divdividend, price to zero
        tokenDetails[oldContractAddress].supply = 0;
        tokenDetails[oldContractAddress].dividend = 0;
        
        return true;
    }
    
    /**
     * @dev function to startDeposit
     */ 
    function startContract() public onlyOwner returns(bool status){
        startDeposit = true;
        return true;
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