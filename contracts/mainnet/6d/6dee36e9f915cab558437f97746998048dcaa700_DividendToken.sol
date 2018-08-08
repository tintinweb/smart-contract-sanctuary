pragma solidity ^0.4.23;

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

UI: https://www.pennyether.com/status/tokens

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