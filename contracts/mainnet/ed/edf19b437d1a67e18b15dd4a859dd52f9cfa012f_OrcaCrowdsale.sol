pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

// Custom smart contracts developed or adapted for OrcaCrowdsale
// -------------------------------------------------------------

contract TokenRecoverable is Ownable {
    using SafeERC20 for ERC20Basic;

    function recoverTokens(ERC20Basic token, address to, uint256 amount) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance >= amount);
        token.safeTransfer(to, amount);
    }
}

contract ERC820Registry {
    function getManager(address addr) public view returns(address);
    function setManager(address addr, address newManager) public;
    function getInterfaceImplementer(address addr, bytes32 iHash) public constant returns (address);
    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;
}

contract ERC820Implementer {
    ERC820Registry erc820Registry = ERC820Registry(0x991a1bcb077599290d7305493c9A630c20f8b798);

    function setInterfaceImplementation(string ifaceLabel, address impl) internal {
        bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
        erc820Registry.setInterfaceImplementer(this, ifaceHash, impl);
    }

    function interfaceAddr(address addr, string ifaceLabel) internal constant returns(address) {
        bytes32 ifaceHash = keccak256(abi.encodePacked(ifaceLabel));
        return erc820Registry.getInterfaceImplementer(addr, ifaceHash);
    }

    function delegateManagement(address newManager) internal {
        erc820Registry.setManager(this, newManager);
    }
}

contract ERC777Token {
    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256);
    function balanceOf(address owner) public view returns (uint256);
    function granularity() public view returns (uint256);

    function defaultOperators() public view returns (address[]);
    function isOperatorFor(address operator, address tokenHolder) public view returns (bool);
    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;

    function send(address to, uint256 amount, bytes holderData) public;
    function operatorSend(address from, address to, uint256 amount, bytes holderData, bytes operatorData) public;

    function burn(uint256 amount, bytes holderData) public;
    function operatorBurn(address from, uint256 amount, bytes holderData, bytes operatorData) public;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes holderData,
        bytes operatorData
    ); // solhint-disable-next-line separate-by-one-line-in-contract
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes holderData, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

contract ERC777TokensRecipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint amount,
        bytes userData,
        bytes operatorData
    ) public;
}

contract CommunityLock is ERC777TokensRecipient, ERC820Implementer, TokenRecoverable {

    ERC777Token public token;

    constructor(address _token) public {
        setInterfaceImplementation("ERC777TokensRecipient", this);
        address tokenAddress = interfaceAddr(_token, "ERC777Token");
        require(tokenAddress != address(0));
        token = ERC777Token(tokenAddress);
    }

    function burn(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        token.burn(_amount, &#39;&#39;);
    }

    function tokensReceived(address, address, address, uint256, bytes, bytes) public {
        require(msg.sender == address(token));
    }
}

contract Debuggable {
    event LogUI(string message, uint256 value);

    function logUI(string message, uint256 value) internal {
        emit LogUI(message, value);
    }
}

contract ERC777TokenScheduledTimelock is ERC820Implementer, ERC777TokensRecipient, Ownable {
    using SafeMath for uint256;

    ERC777Token public token;
    uint256 public totalVested;

    struct Timelock {
        uint256 till;
        uint256 amount;
    }

    mapping(address => Timelock[]) public schedule;

    event Released(address to, uint256 amount);

    constructor(address _token) public {
        setInterfaceImplementation("ERC777TokensRecipient", this);
        address tokenAddress = interfaceAddr(_token, "ERC777Token");
        require(tokenAddress != address(0));
        token = ERC777Token(tokenAddress);
    }

    function scheduleTimelock(address _beneficiary, uint256 _lockTokenAmount, uint256 _lockTill) public onlyOwner {
        require(_beneficiary != address(0));
        require(_lockTill > getNow());
        require(token.balanceOf(address(this)) >= totalVested.add(_lockTokenAmount));
        totalVested = totalVested.add(_lockTokenAmount);

        schedule[_beneficiary].push(Timelock({ till: _lockTill, amount: _lockTokenAmount }));
    }

    function release(address _to) public {
        Timelock[] storage timelocks = schedule[_to];
        uint256 tokens = 0;
        uint256 till;
        uint256 n = timelocks.length;
        uint256 timestamp = getNow();
        for (uint256 i = 0; i < n; i++) {
            Timelock storage timelock = timelocks[i];
            till = timelock.till;
            if (till > 0 && till <= timestamp) {
                tokens = tokens.add(timelock.amount);
                timelock.amount = 0;
                timelock.till = 0;
            }
        }
        if (tokens > 0) {
            totalVested = totalVested.sub(tokens);
            token.send(_to, tokens, &#39;&#39;);
            emit Released(_to, tokens);
        }
    }

    function releaseBatch(address[] _to) public {
        require(_to.length > 0 && _to.length < 100);

        for (uint256 i = 0; i < _to.length; i++) {
            release(_to[i]);
        }
    }

    function tokensReceived(address, address, address, uint256, bytes, bytes) public {}

    function getScheduledTimelockCount(address _beneficiary) public view returns (uint256) {
        return schedule[_beneficiary].length;
    }

    function getNow() internal view returns (uint256) {
        return now; // solhint-disable-line
    }
}

contract ExchangeRateConsumer is Ownable {

    uint8 public constant EXCHANGE_RATE_DECIMALS = 3; // 3 digits precision for exchange rate

    uint256 public exchangeRate = 600000; // by default exchange rate is $600 with EXCHANGE_RATE_DECIMALS precision

    address public exchangeRateOracle;

    function setExchangeRateOracle(address _exchangeRateOracle) public onlyOwner {
        require(_exchangeRateOracle != address(0));
        exchangeRateOracle = _exchangeRateOracle;
    }

    function setExchangeRate(uint256 _exchangeRate) public {
        require(msg.sender == exchangeRateOracle || msg.sender == owner);
        require(_exchangeRate > 0);
        exchangeRate = _exchangeRate;
    }
}

contract OrcaToken is Ownable  {
    using SafeMath for uint256;

    string private constant name_ = "ORCA Token";
    string private constant symbol_ = "ORCA";
    uint256 private constant granularity_ = 1;

    function mint(address _tokenHolder, uint256 _amount, bytes _operatorData) public;
    function burn(uint256 _amount, bytes _holderData) public;
    function finishMinting() public;
}

contract Whitelist {
    mapping(address => uint256) public whitelist;
}

contract OrcaCrowdsale is TokenRecoverable, ExchangeRateConsumer, Debuggable {
    using SafeMath for uint256;

    // Wallet where all ether will be stored
    address internal constant WALLET = 0x0909Fb46D48eea996197573415446A26c001994a;
    // Partner wallet
    address internal constant PARTNER_WALLET = 0x536ba70cA19DF9982487e555E335e7d91Da4A474;
    // Team wallet
    address internal constant TEAM_WALLET = 0x5d6aF05d440326AE861100962e861CFF09203556;
    // Advisors wallet
    address internal constant ADVISORS_WALLET = 0xf44e377F35998a6b7776954c64a84fAf420C467B;

    uint256 internal constant TEAM_TOKENS = 58200000e18;      // 58 200 000 tokens
    uint256 internal constant ADVISORS_TOKENS = 20000000e18;  // 20 000 000 tokens
    uint256 internal constant PARTNER_TOKENS = 82800000e18;   // 82 800 000 tokens
    uint256 internal constant COMMUNITY_TOKENS = 92000000e18; // 92 000 000 tokens

    uint256 internal constant TOKEN_PRICE = 6; // Token costs 0.06 USD
    uint256 internal constant TEAM_TOKEN_LOCK_DATE = 1565049600; // 2019/08/06 00:00 UTC

    struct Stage {
        uint256 startDate;
        uint256 endDate;
        uint256 priorityDate; // allow priority users to purchase tokens until this date
        uint256 cap;
        uint64 bonus;
        uint64 maxPriorityId;
    }

    uint256 public icoTokensLeft = 193200000e18;   // 193 200 000 tokens for ICO
    uint256 public bountyTokensLeft = 13800000e18; // 13 800 000 bounty tokens
    uint256 public preSaleTokens = 0;

    Stage[] public stages;

    // The token being sold
    OrcaToken public token;
    Whitelist public whitelist;
    ERC777TokenScheduledTimelock public timelock;
    CommunityLock public communityLock;

    mapping(address => uint256) public bountyBalances;

    address public tokenMinter;

    uint8 public currentStage = 0;
    bool public initialized = false;
    bool public isFinalized = false;
    bool public isPreSaleTokenSet = false;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param weis paid for purchase
    * @param usd paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 weis, uint256 usd, uint256 rate, uint256 amount);

    event Finalized();
    /**
     * When there no tokens left to mint and token minter tries to manually mint tokens
     * this event is raised to signal how many tokens we have to charge back to purchaser
     */
    event ManualTokenMintRequiresRefund(address indexed purchaser, uint256 value);

    modifier onlyInitialized() {
        require(initialized);
        _;
    }

    constructor(address _token, address _whitelist) public {
        require(_token != address(0));
        require(_whitelist != address(0));

        uint256 stageCap = 30000000e18; // 30 000 000 tokens

        stages.push(Stage({
            startDate: 1533546000, // 6th of August, 9:00 UTC
            endDate: 1534150800, // 13th of August, 9:00 UTC
            cap: stageCap,
            bonus: 20,
            maxPriorityId: 5000,
            priorityDate: uint256(1533546000).add(48 hours) // 6th of August, 9:00 UTC + 48 hours
        }));

        icoTokensLeft = icoTokensLeft.sub(stageCap);

        token = OrcaToken(_token);
        whitelist = Whitelist(_whitelist);
        timelock = new ERC777TokenScheduledTimelock(_token);
    }

    function initialize() public onlyOwner {
        require(!initialized);

        token.mint(timelock, TEAM_TOKENS, &#39;&#39;);
        timelock.scheduleTimelock(TEAM_WALLET, TEAM_TOKENS, TEAM_TOKEN_LOCK_DATE);

        token.mint(ADVISORS_WALLET, ADVISORS_TOKENS, &#39;&#39;);
        token.mint(PARTNER_WALLET, PARTNER_TOKENS, &#39;&#39;);

        communityLock = new CommunityLock(token);
        token.mint(communityLock, COMMUNITY_TOKENS, &#39;&#39;);

        initialized = true;
    }

    function () external payable {
        buyTokens(msg.sender);
    }

    function mintPreSaleTokens(address[] _receivers, uint256[] _amounts, uint256[] _lockPeroids) external onlyInitialized {
        require(msg.sender == tokenMinter || msg.sender == owner);
        require(_receivers.length > 0 && _receivers.length <= 100);
        require(_receivers.length == _amounts.length);
        require(_receivers.length == _lockPeroids.length);
        require(!isFinalized);
        uint256 tokensInBatch = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            tokensInBatch = tokensInBatch.add(_amounts[i]);
        }
        require(preSaleTokens >= tokensInBatch);

        preSaleTokens = preSaleTokens.sub(tokensInBatch);
        token.mint(timelock, tokensInBatch, &#39;&#39;);

        address receiver;
        uint256 lockTill;
        uint256 timestamp = getNow();
        for (i = 0; i < _receivers.length; i++) {
            receiver = _receivers[i];
            require(receiver != address(0));

            lockTill = _lockPeroids[i];
            require(lockTill > timestamp);

            timelock.scheduleTimelock(receiver, _amounts[i], lockTill);
        }
    }

    function mintToken(address _receiver, uint256 _amount) external onlyInitialized {
        require(msg.sender == tokenMinter || msg.sender == owner);
        require(!isFinalized);
        require(_receiver != address(0));
        require(_amount > 0);

        ensureCurrentStage();

        uint256 excessTokens = updateStageCap(_amount);

        token.mint(_receiver, _amount.sub(excessTokens), &#39;&#39;);

        if (excessTokens > 0) {
            emit ManualTokenMintRequiresRefund(_receiver, excessTokens); // solhint-disable-line
        }
    }

    function mintTokens(address[] _receivers, uint256[] _amounts) external onlyInitialized {
        require(msg.sender == tokenMinter || msg.sender == owner);
        require(_receivers.length > 0 && _receivers.length <= 100);
        require(_receivers.length == _amounts.length);
        require(!isFinalized);

        ensureCurrentStage();

        address receiver;
        uint256 amount;
        uint256 excessTokens;

        for (uint256 i = 0; i < _receivers.length; i++) {
            receiver = _receivers[i];
            amount = _amounts[i];

            require(receiver != address(0));
            require(amount > 0);

            excessTokens = updateStageCap(amount);

            uint256 tokens = amount.sub(excessTokens);

            token.mint(receiver, tokens, &#39;&#39;);

            if (excessTokens > 0) {
                emit ManualTokenMintRequiresRefund(receiver, excessTokens); // solhint-disable-line
            }
        }
    }

    function mintBounty(address[] _receivers, uint256[] _amounts) external onlyInitialized {
        require(msg.sender == tokenMinter || msg.sender == owner);
        require(_receivers.length > 0 && _receivers.length <= 100);
        require(_receivers.length == _amounts.length);
        require(!isFinalized);
        require(bountyTokensLeft > 0);

        uint256 tokensLeft = bountyTokensLeft;
        address receiver;
        uint256 amount;
        for (uint256 i = 0; i < _receivers.length; i++) {
            receiver = _receivers[i];
            amount = _amounts[i];

            require(receiver != address(0));
            require(amount > 0);

            tokensLeft = tokensLeft.sub(amount);
            bountyBalances[receiver] = bountyBalances[receiver].add(amount);
        }

        bountyTokensLeft = tokensLeft;
    }

    function buyTokens(address _beneficiary) public payable onlyInitialized {
        require(_beneficiary != address(0));
        ensureCurrentStage();
        validatePurchase();
        uint256 weiReceived = msg.value;
        uint256 usdReceived = weiToUsd(weiReceived);

        uint8 stageIndex = currentStage;

        uint256 tokens = usdToTokens(usdReceived, stageIndex);
        uint256 weiToReturn = 0;

        uint256 excessTokens = updateStageCap(tokens);

        if (excessTokens > 0) {
            uint256 usdToReturn = tokensToUsd(excessTokens, stageIndex);
            usdReceived = usdReceived.sub(usdToReturn);
            weiToReturn = weiToReturn.add(usdToWei(usdToReturn));
            weiReceived = weiReceived.sub(weiToReturn);
            tokens = tokens.sub(excessTokens);
        }

        token.mint(_beneficiary, tokens, &#39;&#39;);

        WALLET.transfer(weiReceived);
        emit TokenPurchase(msg.sender, _beneficiary, weiReceived, usdReceived, exchangeRate, tokens); // solhint-disable-line
        if (weiToReturn > 0) {
            msg.sender.transfer(weiToReturn);
        }
    }

    function ensureCurrentStage() internal {
        uint256 currentTime = getNow();
        uint256 stageCount = stages.length;

        uint8 curStage = currentStage;
        uint8 nextStage = curStage + 1;

        while (nextStage < stageCount && stages[nextStage].startDate <= currentTime) {
            stages[nextStage].cap = stages[nextStage].cap.add(stages[curStage].cap);
            curStage = nextStage;
            nextStage = nextStage + 1;
        }
        if (currentStage != curStage) {
            currentStage = curStage;
        }
    }

    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract&#39;s finalization function.
    */
    function finalize() public onlyOwner onlyInitialized {
        require(!isFinalized);
        require(preSaleTokens == 0);
        Stage storage lastStage = stages[stages.length - 1];
        require(getNow() >= lastStage.endDate || (lastStage.cap == 0 && icoTokensLeft == 0));

        token.finishMinting();
        token.transferOwnership(owner);
        communityLock.transferOwnership(owner); // only in finalize just to be sure that it is the same owner as crowdsale

        emit Finalized(); // solhint-disable-line

        isFinalized = true;
    }

    function setTokenMinter(address _tokenMinter) public onlyOwner onlyInitialized {
        require(_tokenMinter != address(0));
        tokenMinter = _tokenMinter;
    }

    function claimBounty(address beneficiary) public onlyInitialized {
        uint256 balance = bountyBalances[beneficiary];
        require(balance > 0);
        bountyBalances[beneficiary] = 0;

        token.mint(beneficiary, balance, &#39;&#39;);
    }

    /// @notice Updates current stage cap and returns amount of excess tokens if ICO does not have enough tokens
    function updateStageCap(uint256 _tokens) internal returns (uint256) {
        Stage storage stage = stages[currentStage];
        uint256 cap = stage.cap;
        // normal situation, early exit
        if (cap >= _tokens) {
            stage.cap = cap.sub(_tokens);
            return 0;
        }

        stage.cap = 0;
        uint256 excessTokens = _tokens.sub(cap);
        if (icoTokensLeft >= excessTokens) {
            icoTokensLeft = icoTokensLeft.sub(excessTokens);
            return 0;
        }
        icoTokensLeft = 0;
        return excessTokens.sub(icoTokensLeft);
    }

    function weiToUsd(uint256 _wei) internal view returns (uint256) {
        return _wei.mul(exchangeRate).div(10 ** uint256(EXCHANGE_RATE_DECIMALS));
    }

    function usdToWei(uint256 _usd) internal view returns (uint256) {
        return _usd.mul(10 ** uint256(EXCHANGE_RATE_DECIMALS)).div(exchangeRate);
    }

    function usdToTokens(uint256 _usd, uint8 _stage) internal view returns (uint256) {
        return _usd.mul(stages[_stage].bonus + 100).div(TOKEN_PRICE);
    }

    function tokensToUsd(uint256 _tokens, uint8 _stage) internal view returns (uint256) {
        return _tokens.mul(TOKEN_PRICE).div(stages[_stage].bonus + 100);
    }

    function addStage(uint256 startDate, uint256 endDate, uint256 cap, uint64 bonus, uint64 maxPriorityId, uint256 priorityTime) public onlyOwner onlyInitialized {
        require(!isFinalized);
        require(startDate > getNow());
        require(endDate > startDate);
        Stage storage lastStage = stages[stages.length - 1];
        require(startDate > lastStage.endDate);
        require(startDate.add(priorityTime) <= endDate);
        require(icoTokensLeft >= cap);
        require(maxPriorityId >= lastStage.maxPriorityId);

        stages.push(Stage({
            startDate: startDate,
            endDate: endDate,
            cap: cap,
            bonus: bonus,
            maxPriorityId: maxPriorityId,
            priorityDate: startDate.add(priorityTime)
        }));
    }

    function validatePurchase() internal view {
        require(!isFinalized);
        require(msg.value != 0);

        require(currentStage < stages.length);
        Stage storage stage = stages[currentStage];
        require(stage.cap > 0);

        uint256 currentTime = getNow();
        require(stage.startDate <= currentTime && currentTime <= stage.endDate);

        uint256 userId = whitelist.whitelist(msg.sender);
        require(userId > 0);
        if (stage.priorityDate > currentTime) {
            require(userId < stage.maxPriorityId);
        }
    }

    function setPreSaleTokens(uint256 amount) public onlyOwner onlyInitialized {
        require(!isPreSaleTokenSet);
        require(amount > 0);
        preSaleTokens = amount;
        isPreSaleTokenSet = true;
    }

    function getStageCount() public view returns (uint256) {
        return stages.length;
    }

    function getNow() internal view returns (uint256) {
        return now; // solhint-disable-line
    }
}