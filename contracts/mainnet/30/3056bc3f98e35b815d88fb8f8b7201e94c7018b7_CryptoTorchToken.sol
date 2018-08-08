// CryptoTorch-Token Source code
// copyright 2018 CryptoTorch <https://cryptotorch.io>

pragma solidity 0.4.19;


/**
 * @title SafeMath
 * Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
* @title Ownable
 *
 * Owner rights:
 *   - change the name of the contract
 *   - change the name of the token
 *   - change the Proof of Stake difficulty
 *   - transfer ownership
 *
 * Owner CANNOT:
 *   - withdrawal funds
 *   - disable withdrawals
 *   - kill the contract
 *   - change the price of tokens
*/
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


/**
 * @title ERC20 interface (Good parts only)
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}


/**
 * @title CryptoTorchToken
 *
 * Token + Dividends System for the Cryptolympic-Torch
 *
 * Token: KMS - Kilometers (Distance of Torch Run)
 */
contract CryptoTorchToken is ERC20, Ownable {
    using SafeMath for uint256;

    //
    // Events
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    event onWithdraw(
        address indexed to,
        uint256 amount
    );
    event onMint(
        address indexed to,
        uint256 pricePaid,
        uint256 tokensMinted,
        address indexed referredBy
    );
    event onBurn(
        address indexed from,
        uint256 tokensBurned,
        uint256 amountEarned
    );

    //
    // Token Configurations
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    string internal name_ = "Cryptolympic Torch-Run Kilometers";
    string internal symbol_ = "KMS";
    uint256 constant internal dividendFee_ = 5;
    uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
    uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
    uint256 constant internal magnitude = 2**64;
    uint256 public stakingRequirement = 50e18;

    //
    // Token Internals
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;
    address internal tokenController_;
    address internal donationsReceiver_;
    mapping (address => uint256) internal tokenBalanceLedger_; // scaled by 1e18
    mapping (address => uint256) internal referralBalance_;
    mapping (address => uint256) internal profitsReceived_;
    mapping (address => int256) internal payoutsTo_;

    //
    // Modifiers
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    // No buying tokens directly through this contract, only through the
    // CryptoTorch Controller Contract via the CryptoTorch Dapp
    //
    modifier onlyTokenController() {
        require(tokenController_ != address(0) && msg.sender == tokenController_);
        _;
    }

    // Token Holders Only
    modifier onlyTokenHolders() {
        require(myTokens() > 0);
        _;
    }

    // Dividend Holders Only
    modifier onlyProfitHolders() {
        require(myDividends(true) > 0);
        _;
    }

    //
    // Public Functions
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    /**
     * Contract Constructor
     */
    function CryptoTorchToken() public {}

    /**
     * Sets the Token Controller Contract (CryptoTorch)
     */
    function setTokenController(address _controller) public onlyOwner {
        tokenController_ = _controller;
    }

    /**
     * Sets the Contract Donations Receiver address
     */
    function setDonationsReceiver(address _receiver) public onlyOwner {
        donationsReceiver_ = _receiver;
    }

    /**
     * Do not make payments directly to this contract (unless it is a donation! :)
     *  - payments made directly to the contract do not receive tokens.  Tokens
     *    are only available through the CryptoTorch Controller Contract, which
     *    is managed by the Dapp at https://cryptotorch.io
     */
    function() payable public {
        if (msg.value > 0 && donationsReceiver_ != 0x0) {
            donationsReceiver_.transfer(msg.value); // donations?  Thank you!  :)
        }
    }

    /**
     * Liquifies tokens to ether.
     */
    function sell(uint256 _amountOfTokens) public onlyTokenHolders {
        sell_(msg.sender, _amountOfTokens);
    }

    /**
     * Liquifies tokens to ether.
     */
    function sellFor(address _for, uint256 _amountOfTokens) public onlyTokenController {
        sell_(_for, _amountOfTokens);
    }

    /**
     * Liquifies tokens to ether.
     */
    function withdraw() public onlyProfitHolders {
        withdraw_(msg.sender);
    }

    /**
     * Liquifies tokens to ether.
     */
    function withdrawFor(address _for) public onlyTokenController {
        withdraw_(_for);
    }

    /**
     * Liquifies tokens to ether.
     */
    function mint(address _to, uint256 _amountPaid, address _referredBy) public onlyTokenController payable returns(uint256) {
        require(_amountPaid == msg.value);
        return mintTokens_(_to, _amountPaid, _referredBy);
    }

    /**
     * Transfer tokens from the caller to a new holder.
     * There&#39;s a small fee here that is redistributed to all token holders
     */
    function transfer(address _to, uint256 _value) public onlyTokenHolders returns(bool) {
        return transferFor_(msg.sender, _to, _value);
    }

    //
    // Owner Functions
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    /**
     * If we want to rebrand, we can.
     */
    function setName(string _name) public onlyOwner {
        name_ = _name;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string _symbol) public onlyOwner {
        symbol_ = _symbol;
    }

    /**
     * Precautionary measures in case we need to adjust the masternode rate.
     */
    function setStakingRequirement(uint256 _amountOfTokens) public onlyOwner {
        stakingRequirement = _amountOfTokens;
    }

    //
    // Helper Functions
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //
    /**
     * View the total balance of the contract
     */
    function contractBalance() public view returns (uint256) {
        return this.balance;
    }

    /**
     * Retrieve the total token supply.
     */
    function totalSupply() public view returns(uint256) {
        return tokenSupply_;
    }

    /**
     * ERC20 Token Name
     */
    function name() public view returns (string) {
        return name_;
    }

    /**
     * ERC20 Token Symbol
     */
    function symbol() public view returns (string) {
        return symbol_;
    }

    /**
     * ERC20 Token Decimals
     */
    function decimals() public pure returns (uint256) {
        return 18;
    }

    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens() public view returns(uint256) {
        address _playerAddress = msg.sender;
        return balanceOf(_playerAddress);
    }

    /**
     * Retrieve the dividends owned by the caller.
     * If `_includeBonus` is to to true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeBonus) public view returns(uint256) {
        address _playerAddress = msg.sender;
        return _includeBonus ? dividendsOf(_playerAddress) + referralBalance_[_playerAddress] : dividendsOf(_playerAddress);
    }

    /**
     * Retreive the Total Profits previously paid out to the Caller
     */
    function myProfitsReceived() public view returns (uint256) {
        address _playerAddress = msg.sender;
        return profitsOf(_playerAddress);
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _playerAddress) public view returns(uint256) {
        return tokenBalanceLedger_[_playerAddress];
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _playerAddress) public view returns(uint256) {
        return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_playerAddress]) - payoutsTo_[_playerAddress]) / magnitude;
    }

    /**
     * Retrieve the paid-profits balance of any single address.
     */
    function profitsOf(address _playerAddress) public view returns(uint256) {
        return profitsReceived_[_playerAddress];
    }

    /**
     * Retrieve the referral dividends balance of any single address.
     */
    function referralBalanceOf(address _playerAddress) public view returns(uint256) {
        return referralBalance_[_playerAddress];
    }

    /**
     * Return the sell price of 1 individual token.
     */
    function sellPrice() public view returns(uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _ether = tokensToEther_(1e18);
            uint256 _dividends = SafeMath.div(_ether, dividendFee_);
            uint256 _taxedEther = SafeMath.sub(_ether, _dividends);
            return _taxedEther;
        }
    }

    /**
     * Return the buy price of 1 individual token.
     */
    function buyPrice() public view returns(uint256) {
        // our calculation relies on the token supply, so we need supply. Doh.
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _ether = tokensToEther_(1e18);
            uint256 _dividends = SafeMath.div(_ether, dividendFee_);
            uint256 _taxedEther = SafeMath.add(_ether, _dividends);
            return _taxedEther;
        }
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _etherToSpend) public view returns(uint256) {
        uint256 _dividends = _etherToSpend.div(dividendFee_);
        uint256 _taxedEther = _etherToSpend.sub(_dividends);
        uint256 _amountOfTokens = etherToTokens_(_taxedEther);
        return _amountOfTokens;
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateEtherReceived(uint256 _tokensToSell) public view returns(uint256) {
        require(_tokensToSell <= tokenSupply_);
        uint256 _ether = tokensToEther_(_tokensToSell);
        uint256 _dividends = _ether.div(dividendFee_);
        uint256 _taxedEther = _ether.sub(_dividends);
        return _taxedEther;
    }

    //
    // Internal Functions
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //

    /**
     * Liquifies tokens to ether.
     */
    function sell_(address _recipient, uint256 _amountOfTokens) internal {
        require(_amountOfTokens <= tokenBalanceLedger_[_recipient]);

        uint256 _tokens = _amountOfTokens;
        uint256 _ether = tokensToEther_(_tokens);
        uint256 _dividends = SafeMath.div(_ether, dividendFee_);
        uint256 _taxedEther = SafeMath.sub(_ether, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_recipient] = SafeMath.sub(tokenBalanceLedger_[_recipient], _tokens);

        // update dividends tracker
        int256 _updatedPayouts = (int256) (profitPerShare_ * _tokens + (_taxedEther * magnitude));
        payoutsTo_[_recipient] -= _updatedPayouts;

        // update the amount of dividends per token
        if (tokenSupply_ > 0) {
            profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);
        }

        // fire event
        onBurn(_recipient, _tokens, _taxedEther);
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw_(address _recipient) internal {
        require(_recipient != address(0));

        // setup data
        uint256 _dividends = getDividendsOf_(_recipient, false);

        // update dividend tracker
        payoutsTo_[_recipient] += (int256)(_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_recipient];
        referralBalance_[_recipient] = 0;

        // fire event
        onWithdraw(_recipient, _dividends);

        // transfer funds
        profitsReceived_[_recipient] = profitsReceived_[_recipient].add(_dividends);
        _recipient.transfer(_dividends);

        // Keep contract clean
        if (tokenSupply_ == 0 && this.balance > 0) {
            owner.transfer(this.balance);
        }
    }

    /**
     * Assign tokens to player
     */
    function mintTokens_(address _to, uint256 _amountPaid, address _referredBy) internal returns(uint256) {
        require(_to != address(this) && _to != tokenController_);

        uint256 _undividedDividends = SafeMath.div(_amountPaid, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 10);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedEther = SafeMath.sub(_amountPaid, _undividedDividends);
        uint256 _amountOfTokens = etherToTokens_(_taxedEther);
        uint256 _fee = _dividends * magnitude;

        // prevents overflow in the case that the pyramid somehow magically starts being used by everyone in the world
        // (or hackers)
        require(_amountOfTokens > 0 && (SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_));

        // is the user referred by a masternode?
        if (_referredBy != address(0) && _referredBy != _to && tokenBalanceLedger_[_referredBy] >= stakingRequirement) {
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(referralBalance_[_referredBy], _referralBonus);
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        if (tokenSupply_ > 0) {
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_to] = SafeMath.add(tokenBalanceLedger_[_to], _amountOfTokens);

        // Tells the contract that the buyer doesn&#39;t deserve dividends for the tokens before they owned them
        int256 _updatedPayouts = (int256)((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_to] += _updatedPayouts;

        // fire event
        onMint(_to, _amountPaid, _amountOfTokens, _referredBy);

        return _amountOfTokens;
    }

    /**
     * Transfer tokens from the caller to a new holder.
     * There&#39;s a small fee here that is redistributed to all token holders
     */
    function transferFor_(address _from, address _to, uint256 _amountOfTokens) internal returns(bool) {
        require(_to != address(0));
        require(tokenBalanceLedger_[_from] >= _amountOfTokens && tokenBalanceLedger_[_to] + _amountOfTokens >= tokenBalanceLedger_[_to]);

        // make sure we have the requested tokens
        require(_amountOfTokens <= tokenBalanceLedger_[_from]);

        // withdraw all outstanding dividends first
        if (getDividendsOf_(_from, true) > 0) {
            withdraw_(_from);
        }

        // liquify 10% of the tokens that are transferred
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToEther_(_tokenFee);

        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_from] = SafeMath.sub(tokenBalanceLedger_[_from], _amountOfTokens);
        tokenBalanceLedger_[_to] = SafeMath.add(tokenBalanceLedger_[_to], _taxedTokens);

        // update dividend trackers
        payoutsTo_[_from] -= (int256)(profitPerShare_ * _amountOfTokens);
        payoutsTo_[_to] += (int256)(profitPerShare_ * _taxedTokens);

        // disperse dividends among holders
        profitPerShare_ = SafeMath.add(profitPerShare_, (_dividends * magnitude) / tokenSupply_);

        // fire event
        Transfer(_from, _to, _taxedTokens);

        // ERC20
        return true;
    }

    /**
     * Retrieve the dividends of the owner.
     */
    function getDividendsOf_(address _recipient, bool _includeBonus) internal view returns(uint256) {
        return _includeBonus ? dividendsOf(_recipient) + referralBalance_[_recipient] : dividendsOf(_recipient);
    }

    /**
     * Calculate Token price based on an amount of incoming ether;
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function etherToTokens_(uint256 _ether) internal view returns(uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
        uint256 _tokensReceived =
        (
        (
        // underflow attempts BTFO
        SafeMath.sub(
            (sqrt
        (
            (_tokenPriceInitial**2)
            +
            (2*(tokenPriceIncremental_ * 1e18)*(_ether * 1e18))
            +
            (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
            +
            (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
        )
            ), _tokenPriceInitial
        )
        )/(tokenPriceIncremental_)
        )-(tokenSupply_);

        return _tokensReceived;
    }

    /**
     * Calculate token sell value.
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokensToEther_(uint256 _tokens) internal view returns(uint256) {
        uint256 tokens_ = (_tokens + 1e18);
        uint256 _tokenSupply = (tokenSupply_ + 1e18);
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
     * Squirts gas! ;)
     */
    function sqrt(uint x) internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}