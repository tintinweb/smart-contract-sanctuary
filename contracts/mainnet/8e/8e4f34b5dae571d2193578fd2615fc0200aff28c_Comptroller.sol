pragma solidity ^0.4.23;

/************************************************************************
*********************** COMPTROLLER *************************************
*************************************************************************

   The Comptroller creates the DividendToken and DividendTokenLocker,
   runs the CrowdSale, and can raise capital for Treasury.


THE CROWDSALE
------------------------------------------------------------------------

  The owner can configure the CrowdSale via .initSale().
  Owner is allowed to change the terms of the CrowdSale at any time,
  as long as it hasn&#39;t started yet. Configurable parameters are:
    - dateSaleStarted: when the sale will start
    - daleSaleEnded: when the sale will end
    - softCap: amount required for the sale to be considered successful
    - hardCap: maximum amount to be raised
    - bonusCap: how many Ether the bonus period extends to
    - capital: how many Ether to send to Treasury as capital

  The CrowdSale is started as soon as one user buys tokens, and ends
  if the hardCap is met, or dateSaleEnded is reached. The CrowdSale
  will be considered "successful" if the SoftCap is reached. The 
  exchange rate is 1 Ether = 1 Token, plus a bonus amount that 
  starts at 50% for the 1st Ether, sliding down to 0% at `bonusCap`.

  Upon a successful CrowdSale:
    - Tokens are unfronzen
    - Owner wallet gets 20% of tokens, which will vest for 600 days.
    - `capitalPct` of raised funds go to Treasury
    - the remaning Ether is sent to the owner wallet

  Upon an unsuccessful CrowdSale:
    - Tokens remain frozen
    - Investors can call .getRefund() for a full refund
    - Owner gets minted a ton of tokens (to maintain ~100% ownership)

RAISING CAPITAL
------------------------------------------------------------------------

  The Treasury has a method called .capitalNeeded(). This value is 
  changable by Admin, via a governance described in Treasury. When this
  value is > 0, Comptroller will accept Ether in exchange for tokens at
  a rate of 1 Ether per Token, until Treasury.capitalNeeded() is zero.

  For each Ether raised, a token is minted, and the Ether is sent to
  the Treasury as Capital.


PERMISSIONS
------------------------------------------------------------------------

  Comptroller owns the Token, and is only address that can call:
    - token.mint(address, amount)
        - Initially mints 1 token for the owner
        - During CrowdSale
        - When raising capital for Treasury
    - token.burn(address, amount)
        - never called

  The following addresses have permission on Comptroller:
    - Owner Wallet (permanent):
        - Can set CrowdSale parameters, if it hasn&#39;t started yet.
    - Anybody:
        - During CrowdSale:
            .fund(): Send Ether, get Tokens. Refunds on failure.
            .endSale(): End the sales, provided conditions are met.
        - After unsuccessful Crowdsale:
            .refund(): Receive a full refund of amount sent to .fund()
        - If Treasury.capitalNeeded() > 0
            .fundCapital(): Send Ether, get Tokens. Refunds on failure.

CONCLUSION
------------------------------------------------------------------------

  The above description covers the entirety of this contract. There are
  no emergency features or emergency stop gaps in the contract. All
  addresses in this contract (wallet, treasury, token, locker) are 
  unchangable. If you find behavior in this contract that is incorrect,
  do the right thing and let us know. Enjoy.

  A full suite of tests can be found here:


  And, ideally, this contract will have been audited by third parties.

*************************************************************************/

// This is the interface to the Treasury.
interface _ICompTreasury {
    // after CrowdSale, will add funds to bankroll.
    function addCapital() external payable;
    // used to determine if Treasury wants to raise capital.
    function capitalNeeded() external view returns (uint);
}
contract Comptroller {
    // These values are set in the constructor and can never be changed.
    address public wallet;              // Wallet can call .initSale().
    _ICompTreasury public treasury;     // Location of the treasury.
    DividendToken public token;         // Token contract
    DividendTokenLocker public locker;  // Locker that holds PennyEther&#39;s tokens.

    // These values are set on .initSale()
    uint public dateSaleStarted;    // date sale begins
    uint public dateSaleEnded;      // date sale is endable
    uint public softCap;            // sale considered successfull if amt met
    uint public hardCap;            // will not raise more than this
    uint public bonusCap;           // amt at which bonus ends
    uint public capitalPctBips;     // amt to send to Treasury as capital (100 = 1%)

    // CrowdSale Variables
    uint public totalRaised;
    bool public wasSaleStarted;             // True if sale was started
    bool public wasSaleEnded;               // True if sale was ended
    bool public wasSoftCapMet;              // True if softCap was met
    // Stores amtFunded for useres contributing before softCap is met
    mapping (address => uint) public amtFunded; 

    event Created(uint time, address wallet, address treasury, address token, address locker);
    // CrowdSale Meta Events
    event SaleInitalized(uint time);        // emitted when wallet calls .initSale()
    event SaleStarted(uint time);           // emitted upon first tokens bought
    event SaleSuccessful(uint time);        // emitted when sale ends (may happen early)
    event SaleFailed(uint time);            // emitted if softCap not reached
    // CrowdSale purchase
    event BuyTokensSuccess(uint time, address indexed account, uint funded, uint numTokens);
    event BuyTokensFailure(uint time, address indexed account, string reason);
    // If user sends too much, or if .refund() called
    event UserRefunded(uint time, address indexed account, uint refund);

    constructor(address _wallet, address _treasury)
        public
    {
        wallet = _wallet;
        treasury = _ICompTreasury(_treasury);
        token = new DividendToken("PennyEtherToken", "PENNY");
        locker = new DividendTokenLocker(token, _wallet);
        token.freeze(true);
        emit Created(now, wallet, treasury, token, locker);
    }


    /*************************************************************/
    /********** WALLET (OWNER) FUNCTIONS *************************/
    /*************************************************************/

    // Sets parameters of the CrowdSale
    // Cannot be called once the crowdsale has started.
    function initSale(uint _dateStarted, uint _dateEnded, uint _softCap, uint _hardCap, uint _bonusCap, uint _capitalPctBips)
        public
    {
        require(msg.sender == wallet);
        require(!wasSaleStarted);
        require(_softCap <= _hardCap);
        require(_bonusCap <= _hardCap);
        require(_capitalPctBips <= 10000);
        dateSaleStarted = _dateStarted;
        dateSaleEnded = _dateEnded;
        softCap = _softCap;
        hardCap = _hardCap;
        bonusCap = _bonusCap;
        capitalPctBips = _capitalPctBips;
        emit SaleInitalized(now);
    }


    /*************************************************************/
    /********** DURING CROWDSALE *********************************/
    /*************************************************************/

    function () public payable {
        fund();
    }

    // Allows the sender to buy tokens.
    //
    // Refunds if:
    //  - CrowdSale start not defined, or time is before it.
    //  - CrowdSale end date reached.
    //  - CrowdSale HardCap has been met.
    //  - Non-even amount of GWei sent.
    //
    // Otherwise:
    //  - Starts sale (if it&#39;s not already started)
    //  - Issues tokens to user (takes into account bonus period)
    //  - If SoftCap not yet met, records amtFunded (so can refund)
    //  - Refunds any excess amount sent (if HardCap was just met)
    function fund()
        public
        payable
    {
        if (dateSaleStarted==0 || now < dateSaleStarted)
            return _errorBuyingTokens("CrowdSale has not yet started.");
        if (now > dateSaleEnded)
            return _errorBuyingTokens("CrowdSale has ended.");
        if (totalRaised >= hardCap)
            return _errorBuyingTokens("HardCap has been reached.");
        if (msg.value % 1000000000 != 0)
            return _errorBuyingTokens("Must send an even amount of GWei.");

        // Mark sale as started if haven&#39;t done so already.
        if (!wasSaleStarted) {
            wasSaleStarted = true;
            emit SaleStarted(now);
        }

        // Only allow up to (hardCap - totalRaised) to be raised.
        uint _amtToFund = (totalRaised + msg.value) > hardCap
            ? hardCap - totalRaised
            : msg.value;

        // Mint the tokens for the user, increment totalRaised
        uint _numTokens = getTokensFromEth(_amtToFund);
        token.mint(msg.sender, _numTokens);
        totalRaised += _amtToFund;
        emit BuyTokensSuccess(now, msg.sender, _amtToFund, _numTokens);

        // Increment the amount they funded, if softCap not met.
        if (totalRaised < softCap) {
            amtFunded[msg.sender] += _amtToFund;
        }

        // Refund the user any amount sent over _amtToFund
        uint _refund = msg.value > _amtToFund ? msg.value - _amtToFund : 0;
        if (_refund > 0){
            require(msg.sender.call.value(_refund)());
            emit UserRefunded(now, msg.sender, _refund);
        }
    }
        
    // Ends the CrowdSale. Callable by anyone.
    //
    // Throws if:
    //   - Sale is not started, or sale is already ended.
    //   - HardCap not met and sale end date not reached.
    //
    // If SoftCap met:
    //   - Unfreezes tokens.
    //   - Gives owners 20% in TokenLocker, vesting 600 days.
    //   - Sends `capitalPctBip` to Treasury, as capital raised.
    //   - Sends remaining funds to Owner Wallet
    //
    // If SoftCap not met:
    //   - Mints a ton of tokens for owner (to maintain 100% ownership)
    //   - Funders will be able to call .refund()
    function endSale()
        public
    {
        // Require sale has been started but not yet ended.
        require(wasSaleStarted && !wasSaleEnded);
        // Require hardCap met, or date is after sale ended.
        require(totalRaised >= hardCap || now > dateSaleEnded);
        
        // Mark sale as over, and if it was successful.
        wasSaleEnded = true;
        wasSoftCapMet = totalRaised >= softCap;

        // Softcap not met. Mint tokens so wallet owns ~100%.
        if (!wasSoftCapMet) {
            token.mint(wallet, 1e30);
            emit SaleFailed(now);
            return;
        }

        // Unfreeze tokens
        token.freeze(false);

        // Mint 1/4 to locker (resuling in 20%), and start vesting.
        uint _lockerAmt = token.totalSupply() / 4;
        token.mint(locker, _lockerAmt);
        locker.startVesting(_lockerAmt, 600);   // vest for 600 days.

        // Send up to `_capitalAmt` ETH to treasury as capital
        uint _capitalAmt = (totalRaised * capitalPctBips) / 10000;
        if (address(this).balance < _capitalAmt) _capitalAmt = address(this).balance;
        treasury.addCapital.value(_capitalAmt)();
        
        // Send remaining balance to wallet
        if (wallet.call.value(address(this).balance)()) {}
        // Emit event once and forever
        emit SaleSuccessful(now);
    }


    /*************************************************************/
    /********** AFTER CROWDSALE **********************************/
    /*************************************************************/

    // If softCap was not met, allow users to get full refund.
    function refund()
        public
    {
        // Ensure softCap not met, and user funded.
        require(wasSaleEnded && !wasSoftCapMet);
        require(amtFunded[msg.sender] > 0);
        // Send the user the amount they funded, or throw
        uint _amt = amtFunded[msg.sender];
        amtFunded[msg.sender] = 0;
        require(msg.sender.call.value(_amt)());
        emit UserRefunded(now, msg.sender, _amt);
    }

    // Callable any time Treasury.capitalNeeded() > 0.
    //
    // For each Ether received, 1 Token is minted, and the Ether is sent
    //  to the Treasury as Captial.
    //
    // Raising capital dilutes everyone, owners included, and as such
    //  would only realistically happen if the raised funds are expected
    //  to generate returns. Additionally, the Ether raised only goes to
    //  Treasury -- 0 goes to the owners -- so there is no incentive to
    //  raise capital other than to increase dividends.
    function fundCapital()
        public
        payable
    {
        if (!wasSaleEnded)
            return _errorBuyingTokens("Sale has not ended.");
        if (!wasSoftCapMet)
            return _errorBuyingTokens("SoftCap was not met.");
            
        // Cap _amount to the amount we need. Error if 0.
        uint _amtNeeded = capitalFundable();
        uint _amount = msg.value > _amtNeeded ? _amtNeeded : msg.value;
        if (_amount == 0) {
            return _errorBuyingTokens("No capital is needed.");
        }

        // Mint tokens, send capital.
        totalRaised += _amount;
        token.mint(msg.sender, _amount);
        treasury.addCapital.value(_amount)();
        emit BuyTokensSuccess(now, msg.sender, _amount, _amount);

        // Refund excess
        uint _refund = msg.value > _amount ? msg.value - _amount : 0;
        if (_refund > 0) {
            require(msg.sender.call.value(_refund)());
            emit UserRefunded(now, msg.sender, _refund);
        }
    }


    /*************************************************************/
    /********** PRIVATE ******************************************/
    /*************************************************************/

    // Called when user cannot buy tokens.
    // Returns nice error message and saves gas.
    function _errorBuyingTokens(string _reason)
        private
    {
        require(msg.sender.call.value(msg.value)());
        emit BuyTokensFailure(now, msg.sender, _reason);
    }


    /*************************************************************/
    /********** PUBLIC VIEWS *************************************/
    /*************************************************************/

    // Returns the amount of Ether that can be sent to ".fundCapital()"
    function capitalFundable()
        public
        view
        returns (uint _amt)
    {
        return treasury.capitalNeeded();
    }

    // Returns the total amount of tokens minted at a given _ethAmt raised.
    // This hard codes the following:
    //   - Start at 50% bonus, linear decay to 0% bonus at bonusCap.
    // The math behind it is explaind in comments.
    function getTokensMintedAt(uint _ethAmt)
        public
        view
        returns (uint _numTokens)
    {
        if (_ethAmt > hardCap) {
            // Past HardCap. Return the full bonus amount, plus the rest
            _numTokens = (5*bonusCap/4) + (hardCap - bonusCap);
        } else if (_ethAmt > bonusCap) {
            // Past Bonus Period. Return the full bonus amount, plus the non-bonus amt.
            _numTokens = (5*bonusCap/4) + (_ethAmt - bonusCap);
        } else {
            // In Bonus period. Use a closed form integral to compute tokens.
            //
            //   First make a function for tokensPerEth:
            //      tokensPerEth(x) = 3/2 - x/(2c), where c is bonusCap
            //      Test: with c=20000: (0, 1.5), (10000, 1.25), (20000, 1)
            //   Next, create a closed form integral:
            //      integral(3/2 - x/(2c), x) = 3x/2 - x^2/(4c)
            //      Test: with c=20000: (0, 0), (10000, 13750), (20000, 25000)
            //
            // Note: if _ethAmt = bonusCap, _numTokens = (5*bonusCap)/4
            // Note: Overflows if _ethAmt^2 > 2^256, or ~3e38 Eth. Bonus Cap << 3e38
            _numTokens = (3*_ethAmt/2) - (_ethAmt*_ethAmt)/(4*bonusCap);
        }
    }

    // Returns how many tokens would be issued for _ethAmt sent,
    // depending on current totalRaised.
    function getTokensFromEth(uint _amt)
        public
        view
        returns (uint _numTokens)
    {
        return getTokensMintedAt(totalRaised + _amt) - getTokensMintedAt(totalRaised);
    }
}


/*
  Standard ERC20 Token.
  https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
*/
contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public totalSupply;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Created(uint time);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event AllowanceUsed(address indexed owner, address indexed spender, uint amount);

    constructor(string _name, string _symbol)
        public
    {
        name = _name;
        symbol = _symbol;
        emit Created(now);
    }

    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {
        return _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Attempts to transfer `_value` from `_from` to `_to`
    //  if `_from` has sufficient allowance for `msg.sender`.
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        address _spender = msg.sender;
        require(allowance[_from][_spender] >= _value);
        allowance[_from][_spender] -= _value;
        emit AllowanceUsed(_from, _spender, _value);
        return _transfer(_from, _to, _value);
    }

    // Transfers balance from `_from` to `_to` if `_to` has sufficient balance.
    // Called from transfer() and transferFrom().
    function _transfer(address _from, address _to, uint _value)
        private
        returns (bool success)
    {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

interface HasTokenFallback {
    function tokenFallback(address _from, uint256 _amount, bytes _data)
        external
        returns (bool success);
}
contract ERC667 is ERC20 {
    constructor(string _name, string _symbol)
        public
        ERC20(_name, _symbol)
    {}

    function transferAndCall(address _to, uint _value, bytes _data)
        public
        returns (bool success)
    {
        require(super.transfer(_to, _value));
        require(HasTokenFallback(_to).tokenFallback(msg.sender, _value, _data));
        return true;
    }
}



/*********************************************************
******************* DIVIDEND TOKEN ***********************
**********************************************************

An ERC20 token that can accept Ether and distribute it
perfectly to all Token Holders relative to each account&#39;s
balance at the time the dividend is received.

The Token is owned by the creator, and can be frozen,
minted, and burned by the owner.

Notes:
    - Accounts can view or receive dividends owed at any time
    - Dividends received are immediately credited to all
      current Token Holders and can be redeemed at any time.
    - Per above, upon transfers, dividends are not
      transferred. They are kept by the original sender, and
      not credited to the receiver.
    - Uses "pull" instead of "push". Token holders must pull
      their own dividends.

Comptroller Permissions:
    - mintTokens(account, amt): via comp.fund() and comp.fundCapital()
    - burnTokens(account, amt): via comp.burnTokens()
    - setFrozen(true): Called before CrowdSale
    - setFrozen(false): Called after CrowdSale, if softCap met
*/
contract DividendToken is ERC667
{
    // if true, tokens cannot be transferred
    bool public isFrozen;

    // Comptroller can call .mintTokens() and .burnTokens().
    address public comptroller = msg.sender;
    modifier onlyComptroller(){ require(msg.sender==comptroller); _; }

    // How dividends work:
    //
    // - A "point" is a fraction of a Wei (1e-32), it&#39;s used to reduce rounding errors.
    //
    // - totalPointsPerToken represents how many points each token is entitled to
    //   from all the dividends ever received. Each time a new deposit is made, it
    //   is incremented by the points oweable per token at the time of deposit:
    //     (depositAmtInWei * POINTS_PER_WEI) / totalSupply
    //
    // - Each account has a `creditedPoints` and `lastPointsPerToken`
    //   - lastPointsPerToken:
    //       The value of totalPointsPerToken the last time `creditedPoints` was changed.
    //   - creditedPoints:
    //       How many points have been credited to the user. This is incremented by:
    //         (`totalPointsPerToken` - `lastPointsPerToken` * balance) via
    //         `.updateCreditedPoints(account)`. This occurs anytime the balance changes
    //         (transfer, mint, burn).
    //
    // - .collectOwedDividends() calls .updateCreditedPoints(account), converts points
    //   to wei and pays account, then resets creditedPoints[account] to 0.
    //
    // - "Credit" goes to Nick Johnson for the concept.
    //
    uint constant POINTS_PER_WEI = 1e32;
    uint public dividendsTotal;
    uint public dividendsCollected;
    uint public totalPointsPerToken;
    uint public totalBurned;
    mapping (address => uint) public creditedPoints;
    mapping (address => uint) public lastPointsPerToken;

    // Events
    event Frozen(uint time);
    event UnFrozen(uint time);
    event TokensMinted(uint time, address indexed account, uint amount, uint newTotalSupply);
    event TokensBurned(uint time, address indexed account, uint amount, uint newTotalSupply);
    event CollectedDividends(uint time, address indexed account, uint amount);
    event DividendReceived(uint time, address indexed sender, uint amount);

    constructor(string _name, string _symbol)
        public
        ERC667(_name, _symbol)
    {}

    // Upon receiving payment, increment lastPointsPerToken.
    function ()
        payable
        public
    {
        if (msg.value == 0) return;
        // POINTS_PER_WEI is 1e32.
        // So, no multiplication overflow unless msg.value > 1e45 wei (1e27 ETH)
        totalPointsPerToken += (msg.value * POINTS_PER_WEI) / totalSupply;
        dividendsTotal += msg.value;
        emit DividendReceived(now, msg.sender, msg.value);
    }

    /*************************************************************/
    /******* COMPTROLLER FUNCTIONS *******************************/
    /*************************************************************/
    // Credits dividends, then mints more tokens.
    function mint(address _to, uint _amount)
        onlyComptroller
        public
    {
        _updateCreditedPoints(_to);
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit TokensMinted(now, _to, _amount, totalSupply);
    }
    
    // Credits dividends, burns tokens.
    function burn(address _account, uint _amount)
        onlyComptroller
        public
    {
        require(balanceOf[_account] >= _amount);
        _updateCreditedPoints(_account);
        balanceOf[_account] -= _amount;
        totalSupply -= _amount;
        totalBurned += _amount;
        emit TokensBurned(now, _account, _amount, totalSupply);
    }

    // when set to true, prevents tokens from being transferred
    function freeze(bool _isFrozen)
        onlyComptroller
        public
    {
        if (isFrozen == _isFrozen) return;
        isFrozen = _isFrozen;
        if (_isFrozen) emit Frozen(now);
        else emit UnFrozen(now);
    }

    /*************************************************************/
    /********** PUBLIC FUNCTIONS *********************************/
    /*************************************************************/
    
    // Normal ERC20 transfer, except before transferring
    //  it credits points for both the sender and receiver.
    function transfer(address _to, uint _value)
        public
        returns (bool success)
    {   
        // ensure tokens are not frozen.
        require(!isFrozen);
        _updateCreditedPoints(msg.sender);
        _updateCreditedPoints(_to);
        return ERC20.transfer(_to, _value);
    }

    // Normal ERC20 transferFrom, except before transferring
    //  it credits points for both the sender and receiver.
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(!isFrozen);
        _updateCreditedPoints(_from);
        _updateCreditedPoints(_to);
        return ERC20.transferFrom(_from, _to, _value);
    }
    
    // Normal ERC667 transferAndCall, except before transferring
    //  it credits points for both the sender and receiver.
    function transferAndCall(address _to, uint _value, bytes _data)
        public
        returns (bool success)
    {
        require(!isFrozen);
        _updateCreditedPoints(msg.sender);
        _updateCreditedPoints(_to);
        return ERC667.transferAndCall(_to, _value, _data);  
    }

    // Updates creditedPoints, sends all wei to the owner
    function collectOwedDividends()
        public
        returns (uint _amount)
    {
        // update creditedPoints, store amount, and zero it.
        _updateCreditedPoints(msg.sender);
        _amount = creditedPoints[msg.sender] / POINTS_PER_WEI;
        creditedPoints[msg.sender] = 0;
        dividendsCollected += _amount;
        emit CollectedDividends(now, msg.sender, _amount);
        require(msg.sender.call.value(_amount)());
    }


    /*************************************************************/
    /********** PRIVATE METHODS / VIEWS **************************/
    /*************************************************************/
    // Credits _account with whatever dividend points they haven&#39;t yet been credited.
    //  This needs to be called before any user&#39;s balance changes to ensure their
    //  "lastPointsPerToken" credits their current balance, and not an altered one.
    function _updateCreditedPoints(address _account)
        private
    {
        creditedPoints[_account] += _getUncreditedPoints(_account);
        lastPointsPerToken[_account] = totalPointsPerToken;
    }

    // For a given account, returns how many Wei they haven&#39;t yet been credited.
    function _getUncreditedPoints(address _account)
        private
        view
        returns (uint _amount)
    {
        uint _pointsPerToken = totalPointsPerToken - lastPointsPerToken[_account];
        // The upper bound on this number is:
        //   ((1e32 * TOTAL_DIVIDEND_AMT) / totalSupply) * balances[_account]
        // Since totalSupply >= balances[_account], this will overflow only if
        //   TOTAL_DIVIDEND_AMT is around 1e45 wei. Not ever going to happen.
        return _pointsPerToken * balanceOf[_account];
    }


    /*************************************************************/
    /********* CONSTANTS *****************************************/
    /*************************************************************/
    // Returns how many wei a call to .collectOwedDividends() would transfer.
    function getOwedDividends(address _account)
        public
        constant
        returns (uint _amount)
    {
        return (_getUncreditedPoints(_account) + creditedPoints[_account])/POINTS_PER_WEI;
    }
}




/*********************************************************
*************** DIVIDEND TOKEN LOCKER ********************
**********************************************************

This contract holds a balance of tokens and enforces that
the balance of tokens is always above the amount that has
not yet vested. All dividends are always collectable.

Owner Permissions:
    - to collect all dividends
    - to transfer tokens, such that some minimum balance
      is maintained, as defined by the vesting parameters

Comptroller Permissions:
    - Specifies the token and owner
    - Specifies the amount to vest, and over what period
*/
contract IDividendToken {
    function collectOwedDividends() external returns (uint);
    function transfer(address _to, uint _value) external;
    function balanceOf(address _addr) external view returns (uint);
}
contract DividendTokenLocker {
    // set in the constructor
    address public comptroller;
    address public owner;
    IDividendToken public token;
    // set by comptroller via .setVesting()
    uint public vestingAmt;
    uint public vestingStartDay;
    uint public vestingDays;

    // events, for transparency
    event Created(uint time, address comptroller, address token, address owner);
    event VestingStarted(uint time, uint numTokens, uint vestingDays);
    event Transferred(uint time, address recipient, uint numTokens);
    event Collected(uint time, address recipient, uint amount);
    
    // Initialize the comptroller, token, and owner addresses.
    constructor(address _token, address _owner)
        public
    {
        comptroller = msg.sender;
        token = IDividendToken(_token);
        owner = _owner;
        emit Created(now, comptroller, token, owner);
    }

    // Allow this contract to get sent Ether (eg, dividendsOwed)
    function () payable public {}


    /***************************************************/
    /*********** CREATOR FUNCTIONS *********************/
    /***************************************************/

    // Starts the vesting process for the current balance.
    // TokenLocker will ensure a minimum balance is maintained
    //  based off of the vestingAmt and vestingDays.
    function startVesting(uint _numTokens, uint _vestingDays)
        public
    {
        require(msg.sender == comptroller);
        vestingAmt = _numTokens;
        vestingStartDay = _today();
        vestingDays = _vestingDays;
        emit VestingStarted(now, _numTokens, _vestingDays);
    }


    /***************************************************/
    /*********** OWNER FUNCTIONS ***********************/
    /***************************************************/

    // Allows the owner to collect the balance of this contract,
    //  including any owed dividends.
    function collect()
        public
    {
        require(msg.sender == owner);
        // Collect dividends, and get new balance.
        token.collectOwedDividends();
        uint _amount = address(this).balance;

        // Send amount (if any), emit event.
        if (_amount > 0) require(owner.call.value(_amount)());
        emit Collected(now, owner, _amount);
    }

    // Allows the owner to transfer tokens, such that the
    //  balance of tokens cannot go below getMinTokenBalance().
    function transfer(address _to, uint _numTokens)
        public
    {
        require(msg.sender == owner);
        uint _available = tokensAvailable();
        if (_numTokens > _available) _numTokens = _available;

        // Transfer (if _numTokens > 0), and emit event.
        if (_numTokens > 0) {
            token.transfer(_to, _numTokens);
        }
        emit Transferred(now, _to, _numTokens);
    }


    /***************************************************/
    /*********** VIEWS *********************************/
    /***************************************************/

    function tokens()
        public
        view
        returns (uint)
    {
        return token.balanceOf(this);
    }

    // Returns the minimum allowed tokenBalance.
    // Starts at vestingAmt, goes to 0 after vestingDays.
    function tokensUnvested()
        public
        view
        returns (uint)
    {
        return vestingAmt - tokensVested();
    }

    // Returns how many tokens have vested.
    // Starts at 0, goes to vestingAmt after vestingDays.
    function tokensVested()
        public
        view
        returns (uint)
    {
        uint _daysElapsed = _today() - vestingStartDay;
        return _daysElapsed >= vestingDays
            ? vestingAmt
            : (vestingAmt * _daysElapsed) / vestingDays;
    }

    // Returns the amount of tokens available to be transferred.
    // This is the balance, minus how many tokens must be maintained due to vesting.
    function tokensAvailable()
        public
        view
        returns (uint)
    {
        // token.balanceOf() and getMinTokenBalance() can never be greater than
        //   all the Ether in the world, so we dont worry about overflow.
        int _available = int(tokens()) - int(tokensUnvested());
        return _available > 0 ? uint(_available) : 0;
    }

    // Returns the current day.
    function _today()
        private 
        view 
        returns (uint)
    {
        return now / 1 days;
    }
}