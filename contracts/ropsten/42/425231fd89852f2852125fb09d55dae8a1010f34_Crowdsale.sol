pragma solidity ^0.4.15;



contract IToken {
  uint256 public totalSupply;
  function mint(address _to, uint _amount) public returns(bool);
  function start() public;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
}

contract TokenTimelock {
  IToken public token;
  address public beneficiary;
  uint64 public releaseTime;

  function TokenTimelock(address _token, address _beneficiary, uint64 _releaseTime) public {
    require(_releaseTime > now);
    token = IToken(_token);
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  function release() public {
    require(now >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.transfer(beneficiary, amount);
  }
}



contract Owned {
    address public owner;
    address public newOwner;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) onlyOwner public {
        newOwner = _newOwner;
    }

    function acceptOwnership() onlyOwner public {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);
}



contract Base {
    
    modifier only(address allowed) {
        require(msg.sender == allowed);
        _;
    }

    // *************************************************
    // *          reentrancy handling                  *
    // *************************************************

    uint private bitlocks = 0;
    modifier noReentrancy(uint m) {
        var _locks = bitlocks;
        require(_locks & m <= 0);
        bitlocks |= m;
        _;
        bitlocks = _locks;
    }

    modifier noAnyReentrancy {
        var _locks = bitlocks;
        require(_locks <= 0);
        bitlocks = uint(-1);
        _;
        bitlocks = _locks;
    }

    modifier reentrant { _; }
}





library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}






contract Crowdsale is Base, Owned {
    using SafeMath for uint256;

    enum State { INIT, ICO, CLOSED, STOPPED }
    enum SupplyType { SALE, ADVISORY, INCENTIVISATION, LIQUIDITY_FUND, REFERRAL, BOUNTY }

    uint public constant DECIMALS = 10**18;
    uint public constant MILLION = 10**6;

    uint public constant MAX_TOKEN_SALE = 40 * MILLION * DECIMALS;
    uint public constant TEAMS_TOKENS = 14 * MILLION * DECIMALS;
    uint public constant MAX_ADVISORY_TOKENS = 12 * MILLION * DECIMALS;
    uint public constant MAX_INCENTIVISATION_TOKENS = 15 * MILLION * DECIMALS;
    uint public constant MAX_LIQUIDITY_FUND_TOKENS = 15 * MILLION * DECIMALS;
    uint public constant MAX_REFERRAL_TOKENS = 2 * MILLION * DECIMALS;
    uint public constant MAX_BOUNTY_TOKENS = 2 * MILLION * DECIMALS;

    State public currentState = State.INIT;
    IToken public token;

    uint public totalTokenSale = 0;
    uint public totalAdvisory = 0;
    uint public totalIncentivisation = 0;
    uint public totalLiquidityFund = 0;
    uint public totalReferral = 0;
    uint public totalBounty = 0;

    event TokenSale(address indexed _to, uint256 _value);
    event Bounty(address indexed _to, uint256 _value);
    event Advisory(address indexed _to, uint256 _value);
    event Incentivisation(address indexed _to, uint256 _value);
    event Referral(address indexed _to, uint256 _value);
    event LiquidityFund(address indexed _to, uint256 _value);

    modifier inState(State _state){
        require(currentState == _state);
        _;
    }

    modifier salesRunning(){
        require(currentState == State.ICO);
        _;
    }

    modifier notStopped(){
        require(currentState != State.STOPPED);
        _;
    }

    function Crowdsale() public {
    }

    function ()
        public
        payable
        salesRunning
    {
        revert();
    }

    function initialize(address _token, address _teamsTokens)
        public
        onlyOwner
        inState(State.INIT)
    {
        require(_token != address(0));

        token = IToken(_token);

        sendTeamTokens(_teamsTokens);
    }

    function setState(State _newState)
        public
        onlyOwner
    {
        require(
            (currentState == State.INIT && _newState == State.ICO)
            || (currentState == State.ICO && _newState == State.CLOSED)
            || (currentState == State.ICO && _newState == State.STOPPED)
            || (currentState == State.STOPPED && _newState == State.ICO)
        );
        if(_newState == State.CLOSED){
            _finish();
        }

        currentState = _newState;
    }

    function sendTokensSale(address _to, uint _amount)
        public
        onlyOwner
        salesRunning
    {
        _mint(_to, _amount, SupplyType.SALE);
    }

    function sendBounty(address _to, uint _amount)
        public
        onlyOwner
        salesRunning
    {
        _mint(_to, _amount, SupplyType.BOUNTY);
    }

    function sendReferral(address _to, uint _amount)
        public
        onlyOwner
        salesRunning
    {
        _mint(_to, _amount, SupplyType.REFERRAL);
    }

    function sendAdvisory(address _to, uint _amount)
        public
        onlyOwner
        salesRunning
    {
        _mint(_to, _amount, SupplyType.ADVISORY);
    }

    function sendIncentivisation(address _to, uint _amount)
        public
        onlyOwner
        salesRunning
    {
        _mint(_to, _amount, SupplyType.INCENTIVISATION);
    }

    function sendLiquidityFund(address _to, uint _amount)
        public
        onlyOwner
        salesRunning
    {
        _mint(_to, _amount, SupplyType.LIQUIDITY_FUND);
    }


    //==================== Internal Methods =================

    function sendTeamTokens(address _teamAddress)
        noAnyReentrancy
        internal
    {
        require(_teamAddress != address(0));
        IToken(token).mint(_teamAddress, TEAMS_TOKENS);
    }

    function _mint(address _to, uint _amount, SupplyType _supplyType)
        noAnyReentrancy
        internal
    {
        _amount = _amount.mul(DECIMALS);
        _checkMaxSaleSupply(_amount, _supplyType);
        _increaseSupply(_amount, _supplyType);

        IToken(token).mint(_to, _amount);

        if (_supplyType == SupplyType.SALE) {
            TokenSale(_to, _amount);
        } else if (_supplyType == SupplyType.BOUNTY) {
            Bounty(_to, _amount);
        } else if (_supplyType == SupplyType.REFERRAL) {
            Referral(_to, _amount);
        } else if (_supplyType == SupplyType.ADVISORY) {
            Advisory(_to, _amount);
        } else if (_supplyType == SupplyType.INCENTIVISATION) {
            Incentivisation(_to, _amount);
        } else if (_supplyType == SupplyType.LIQUIDITY_FUND) {
            LiquidityFund(_to, _amount);
        }
    }

    function _finish()
        noAnyReentrancy
        internal
    {
        IToken(token).start();
    }

    function _checkMaxSaleSupply(uint transferTokens, SupplyType _supplyType)
        internal
    {
        if (_supplyType == SupplyType.SALE) {
            require(totalTokenSale.add(transferTokens) <= MAX_TOKEN_SALE);
        } else if (_supplyType == SupplyType.BOUNTY) {
            require(totalBounty.add(transferTokens) <= MAX_BOUNTY_TOKENS);
        } else if (_supplyType == SupplyType.REFERRAL) {
            require(totalReferral.add(transferTokens) <= MAX_REFERRAL_TOKENS);
        } else if (_supplyType == SupplyType.ADVISORY) {
            require(totalAdvisory.add(transferTokens) <= MAX_ADVISORY_TOKENS);
        } else if (_supplyType == SupplyType.INCENTIVISATION) {
            require(totalIncentivisation.add(transferTokens) <= MAX_INCENTIVISATION_TOKENS);
        } else if (_supplyType == SupplyType.LIQUIDITY_FUND) {
            require(totalLiquidityFund.add(transferTokens) <= MAX_LIQUIDITY_FUND_TOKENS);
        }
    }

    function _increaseSupply(uint _amount, SupplyType _supplyType)
        internal
    {
        if (_supplyType == SupplyType.SALE) {
            totalTokenSale = totalTokenSale.add(_amount);
        } else if (_supplyType == SupplyType.BOUNTY) {
            totalBounty = totalBounty.add(_amount);
        } else if (_supplyType == SupplyType.REFERRAL) {
            totalReferral = totalReferral.add(_amount);
        } else if (_supplyType == SupplyType.ADVISORY) {
            totalAdvisory = totalAdvisory.add(_amount);
        } else if (_supplyType == SupplyType.INCENTIVISATION) {
            totalIncentivisation = totalIncentivisation.add(_amount);
        } else if (_supplyType == SupplyType.LIQUIDITY_FUND) {
            totalLiquidityFund = totalLiquidityFund.add(_amount);
        }
    }

}