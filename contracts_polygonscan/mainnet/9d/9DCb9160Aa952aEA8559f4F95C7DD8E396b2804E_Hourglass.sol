/**
 *Submitted for verification at polygonscan.com on 2021-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/***
 *
 *     __  __                            __                  
 *    / / / /____   __  __ _____ ____ _ / /____ _ _____ _____
 *   / /_/ // __ \ / / / // ___// __ `// // __ `// ___// ___/
 *  / __  // /_/ // /_/ // /   / /_/ // // /_/ /(__  )(__  ) 
 * /_/ /_/ \____/ \__,_//_/    \__, //_/ \__,_//____//____/  
 *                           /____/                         
 * v 1.0.0
 * P3C - Hourglass deployed on MATIC / Polygon Network
 * 
 * MODIFICATIONS:
 * -> Deployer is the referrer for Compounds
 * -> Added 'Total Referrals'
 * -> Added 'Total Referral Earnings'
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
 * OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
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

contract Hourglass {
    struct UserData {
        uint256 deposited;
        uint256 withdrawn;
        uint256 compounded;
        uint256 harvested;
        
        uint256 xDeposited;
        uint256 xWithdrawn;
        uint256 xCompounded;
        uint256 xHarvested;
    }
    
    address public deployer;
    
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyHolders() {
        require(myTokens() > 0);
        _;
    }
    
    // only people with profits
    modifier onlyStronghands() {
        require(myDividends(true) > 0);
        _;
    }
    
    modifier whenActivated() {
        require(activated == true || msg.sender == deployer, "NOT_ACTIVATED_YET");
        _;
    }
    
    /*==============================
    =            EVENTS            =
    ==============================*/
    
    // Normal Events
    event onTokenPurchase(address indexed customerAddress, uint256 incomingBase, uint256 tokensMinted, address indexed referredBy);
    event onTokenSell(address indexed customerAddress, uint256 tokensBurned, uint256 baseEarned);
    event onReinvestment(address indexed customerAddress, uint256 baseReinvested, uint256 tokensMinted);
    event onWithdraw(address indexed customerAddress, uint256 baseWithdrawn);
    
    // ERC20 Events
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    
    // One-shot Events
    event onActivation(address indexed callerAddress, uint256 _timestamp);
    
    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    
    bool public activated; // One-time activation switch
    
    string public name = "PolyGlass P3C";
    string public symbol = "P3C";
    
    uint8 constant public decimals = 18;
    uint8 constant internal dividendFee_ = 10;
    
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    
   /*================================
    =            DATASETS            =
    ================================*/
    // amount of shares for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;
    mapping(address => uint256) internal referralBalance_;
    mapping(address => int256) internal payoutsTo_;
    
    mapping(address => uint256) internal referralsOf_;
    mapping(address => uint256) internal referralEarningsOf_;
    
    mapping(address => UserData) internal userData_;
    
    uint256 internal players;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    
    uint256 internal totalDeposited_;
    uint256 internal totalWithdrawn_;
    uint256 internal totalCompounded_;
    uint256 internal totalHarvested_;
    
    /*=======================================
    =            PUBLIC FUNCTIONS           =
    =======================================*/

    constructor() public {
        deployer = msg.sender;
        activated = false;
    }
    
    // Fallback function
    receive() payable external {
        deposit(deployer);
    }
    
    function activate() public returns (bool _success) {
        require(msg.sender == deployer, "ONLY_DEPLOYER");
        require(activated == false, "ALREADY_ACTIVATED");
        
        activated = true;
        
        emit onActivation(msg.sender, block.timestamp);
        return true;
    }
     
    // Converts all incoming base to tokens for the caller, and passes down the referral addy (if any)
    function deposit(address _referredBy) whenActivated() public payable returns (uint256) {
        
        // If the deposits of msgSender = 0, this is their first deposit.
        if (userData_[msg.sender].deposited == 0) {
            players += 1;
        }
        
        // Deposit Base to the contract, create the tokens.
        purchaseTokens(msg.value, _referredBy);
        
        // Count the referral
        referralsOf_[_referredBy] += 1;
        
        userData_[msg.sender].deposited += msg.value;
        userData_[msg.sender].xDeposited += 1;
        
        totalDeposited_ += msg.value;
    }
    
    // Liquifies tokens to Base.
    function withdraw(uint256 _amountOfTokens) onlyHolders() public {
        
        address _customerAddress = msg.sender;
        
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _base = tokensToBase_(_tokens);
        uint256 _dividends = SafeMath.div(_base, dividendFee_);
        uint256 _taxedBase = SafeMath.sub(_base, _dividends);
        
        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _tokens);
        
        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedBase * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;       
        
        // dividing by zero is a bad idea
        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }
        
        // Update Stats
        userData_[msg.sender].withdrawn += _dividends;
        userData_[msg.sender].xWithdrawn += 1;
        
        totalWithdrawn_ += _dividends;
        
        // fire event
        emit onTokenSell(_customerAddress, _tokens, _taxedBase);
    }
    
    // Converts all of caller's dividends to tokens.
    function compound() onlyStronghands() public {
        // fetch dividends
        uint256 _dividends = myDividends(false); // retrieve ref. bonus later in the code
        
        // pay out the dividends virtually
        address _customerAddress = msg.sender;
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens = purchaseTokens(_dividends, deployer);
        
        // Update stats...
        userData_[msg.sender].deposited += _dividends;
        userData_[msg.sender].compounded += _dividends;
        userData_[msg.sender].xCompounded += 1;
        
        totalCompounded_ += _dividends;
        
        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    // Withdraws all of the callers earnings.
    function harvest() onlyStronghands() public {
        // setup data
        address payable _customerAddress = msg.sender;
        uint256 _dividends = myDividends(false); // get ref. bonus later in the code
        
        // update dividend tracker
        payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);
        
        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;
        
        // lambo delivery service
        _customerAddress.transfer(_dividends);
        
        // 
        userData_[msg.sender].harvested += _dividends;
        userData_[msg.sender].xHarvested += 1;
        
        totalHarvested_ += _dividends;
        
        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }
    
    // Transfer token to a different address. No fees.
    function transfer(address _toAddress, uint256 _amountOfTokens) onlyHolders() public returns (bool) {
        // cant send to 0 address
        require(_toAddress != address(0));
        // setup
        address _customerAddress = msg.sender;

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        // withdraw all outstanding dividends first
        if(myDividends(true) > 0) harvest();

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        tokenBalanceLedger_[_toAddress] = SafeMath.add(tokenBalanceLedger_[_toAddress], _amountOfTokens);

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256) (profitPerShare_ * _amountOfTokens);
        payoutsTo_[_toAddress] += (int256) (profitPerShare_ * _amountOfTokens);

        // fire event
        emit Transfer(_customerAddress, _toAddress, _amountOfTokens);
        return true;
    }
        
    // Alias of sell() and withdraw()
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if(_tokens > 0) withdraw(_tokens);
        
        // lambo delivery service
        harvest();
    }
    
    /*----------  HELPERS AND CALCULATORS  ----------*/
    
    function myTotalReferrals() public view returns (uint) {
        return referralsOf_[msg.sender];
    }
    
    function myTotalReferralEarnings() public view returns (uint) {
        return referralEarningsOf_[msg.sender];
    }
    
    function contractStats() public view returns (uint256 _totalDeposited, uint256 _totalWithdrawn, uint256 _totalCompounded, uint256 _totalHarvested) {
        return (totalDeposited_, totalWithdrawn_, totalCompounded_, totalHarvested_);
    }
    
    function getAmountStatsOf(address _user) public view returns (uint256 _deposited, uint256 _withdrawn, uint256 _compounded, uint256 _harvested) {
        return (
            userData_[_user].deposited,
            userData_[_user].withdrawn,
            userData_[_user].compounded,
            userData_[_user].harvested
        );
    }
    
    function getRepeatStatsOf(address _user) public view returns (uint256 _xDeposited, uint256 _xWithdrawn, uint256 _xCompounded, uint256 _xHarvested) {
        return (
            userData_[_user].xDeposited,
            userData_[_user].xWithdrawn,
            userData_[_user].xCompounded,
            userData_[_user].xHarvested
        );
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    
    function totalReferralsOf(address _user) public view returns (uint) {
        return referralsOf_[_user];
    }
    
    function totalReferralEarningsOf(address _user) public view returns (uint) {
        return referralEarningsOf_[_user];
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////
    
    // View the current Base stored in the contract
    function totalBaseBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    // Retrieve the total token supply.
    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }
    
    // Retrieve the tokens owned by the caller.
    function myTokens() public view returns(uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        address _customerAddress = msg.sender;
        return dividendsOf(_customerAddress,_includeReferralBonus);
    }
    
    // Retrieve the token balance of any single address.
    function balanceOf(address _customerAddress) view public returns(uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }
    
    // Retrieve the dividend balance of any single address.
    function dividendsOf(address _customerAddress,bool _includeReferralBonus) view public returns(uint256) {
        uint256 regularDividends = (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
        if (_includeReferralBonus){
            return regularDividends + referralBalance_[_customerAddress];
        } else {
            return regularDividends;
        }
    }
    
    
    // Return the buy price of 1 individual token.
    function sellPrice() public view returns(uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _base = tokensToBase_(1e18);
            uint256 _dividends = SafeMath.div(_base, dividendFee_  );
            uint256 _taxedBase = SafeMath.sub(_base, _dividends);
            return _taxedBase;
        }
    }
    
    // Return the sell price of 1 individual token.
    function buyPrice() public view returns(uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if(tokenSupply_ == 0){
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _base = tokensToBase_(1e18);
            uint256 _dividends = SafeMath.div(_base, dividendFee_  );
            uint256 _taxedBase = SafeMath.add(_base, _dividends);
            return _taxedBase;
        }
    }
    
    // Function for the frontend to dynamically retrieve the price scaling of buy orders.
    function calculateTokensReceived(uint256 _baseToSpend) public view returns(uint256) {
        uint256 _dividends = SafeMath.div(_baseToSpend, dividendFee_);
        uint256 _taxedBase = SafeMath.sub(_baseToSpend, _dividends);
        uint256 _amountOfTokens = baseToTokens_(_taxedBase);
        
        return _amountOfTokens;
    }
    
    // Function for the frontend to dynamically retrieve the price scaling of sell orders.
    function calculateBaseReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _base = tokensToBase_(_tokensToSell);
        uint256 _dividends = SafeMath.div(_base, dividendFee_);
        uint256 _taxedBase = SafeMath.sub(_base, _dividends);
        return _taxedBase;
    }
    
    
    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    
    // Deposit tokens into the contract and issue the correct amount of tokens to the depositor
    function purchaseTokens(uint256 _incomingBase, address _referredBy) internal returns(uint256) {
        // data setup
        address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingBase, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedBase = SafeMath.sub(_incomingBase, _undividedDividends);
        uint256 _amountOfTokens = baseToTokens_(_taxedBase);
        uint256 _fee = _dividends * magnitude;
 
        // prevents overflow
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens,tokenSupply_) > tokenSupply_));
        
        if(
            // is this a referred purchase?
            _referredBy != 0x0000000000000000000000000000000000000000
        ){
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }
        
        // we can't give people infinite Base
        if(tokenSupply_ > 0){
            
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);
 
            // take the amount of dividends gained through this transaction, and allocates them evenly to each participant
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));
            
            // calculate the amount of tokens the customer receives over his purchase 
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));
        
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }
        
        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);
        
        // Tells the contract that the buyer doesn't deserve dividends for the tokens before they owned them;
        // really i know you think you do but you don't
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;
        
        referralEarningsOf_[_referredBy] += (_referralBonus);
        
        // fire event
        emit onTokenPurchase(_customerAddress, _incomingBase, _amountOfTokens, _referredBy);
        return _amountOfTokens;
    }

    // Calculate Token price based on an amount of incoming Base | Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
    function baseToTokens_(uint256 _base) internal view returns(uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived = 
         (
            (
                // underflow attempts BTFO
                SafeMath.sub(
                    (sqrt
                        (
                            (_tokenPriceInitial**2)
                            +(2*(tokenPriceIncremental_ * 1e18)*(_base * 1e18))
                            +(((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                            +(2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                        )
                    ), _tokenPriceInitial
                )
            )/(tokenPriceIncremental_)
        )-(tokenSupply_)
        ;
  
        return _tokensReceived;
    }
    
    // Calculate token sell value | Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
    function tokensToBase_(uint256 _tokens) internal view returns(uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
        uint256 _baseReceived =
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
        return _baseReceived;
    }
    
    // SQUARE ROOT!
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}