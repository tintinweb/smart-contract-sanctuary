pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// SencTokenSale - SENC Token Sale Contract
//
// Copyright (c) 2018 InfoCorp Technologies Pte Ltd.
// http://www.sentinel-chain.org/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// The SENC Token Sale is organised as follows:
// 1. 10% (50,000,000) of total supply will be minted and sent to founding team weallet.
// 2. 20% (100,000,000) of total supply will be minted and sent to early supporter wallet.
// 3. 20% (100,000,000) of total supply will be minted and sent to presale wallet.
// 4. 20% (100,000,000) of total supply will be available for minting and purchase by public.
// 5. 30% (150,000,000) of total supply will be minted and sent to treaury wallet.
// 6. Public sale is designed to be made available in batches.
// 
// Tokens can only be purchased by contributors depending on the batch that
// contributors are assigned to in the WhiteListed smart contract to prevent a
// gas war. Each batch will be assigned a timestamp. Contributors can only 
// make purchase once the current timestamp on the main net is above the 
// batch&#39;s assigned timestamp.
//    - batch 0: start_date 00:01   (guaranteed allocations)
//    - batch 1: start_date+1 00:01 (guaranteed allocations)
//    - batch 2: start_date+2 00:01 (guaranteed and non-guaranteed allocations)
//    - batch 3: start_date+2 12:01 (guaranteed and non-guaranteed allocations)
// ----------------------------------------------------------------------------

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

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
 
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract OperatableBasic {
    function setPrimaryOperator (address addr) public;
    function setSecondaryOperator (address addr) public;
    function isPrimaryOperator(address addr) public view returns (bool);
    function isSecondaryOperator(address addr) public view returns (bool);
}

contract Operatable is Ownable, OperatableBasic {
    address public primaryOperator;
    address public secondaryOperator;

    modifier canOperate() {
        require(msg.sender == primaryOperator || msg.sender == secondaryOperator || msg.sender == owner);
        _;
    }

    function Operatable() public {
        primaryOperator = owner;
        secondaryOperator = owner;
    }

    function setPrimaryOperator (address addr) public onlyOwner {
        primaryOperator = addr;
    }

    function setSecondaryOperator (address addr) public onlyOwner {
        secondaryOperator = addr;
    }

    function isPrimaryOperator(address addr) public view returns (bool) {
        return (addr == primaryOperator);
    }

    function isSecondaryOperator(address addr) public view returns (bool) {
        return (addr == secondaryOperator);
    }
}

contract Salvageable is Operatable {
    // Salvage other tokens that are accidentally sent into this token
    function emergencyERC20Drain(ERC20 oddToken, uint amount) public canOperate {
        if (address(oddToken) == address(0)) {
            owner.transfer(amount);
            return;
        }
        oddToken.transfer(owner, amount);
    }
}

contract WhiteListedBasic is OperatableBasic {
    function addWhiteListed(address[] addrs, uint[] batches, uint[] weiAllocation) external;
    function getAllocated(address addr) public view returns (uint);
    function getBatchNumber(address addr) public view returns (uint);
    function getWhiteListCount() public view returns (uint);
    function isWhiteListed(address addr) public view returns (bool);
    function removeWhiteListed(address addr) public;
    function setAllocation(address[] addrs, uint[] allocation) public;
    function setBatchNumber(address[] addrs, uint[] batch) public;
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
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
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract SencTokenConfig {
    string public constant NAME = "Sentinel Chain Token";
    string public constant SYMBOL = "SENC";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 500000000 * DECIMALSFACTOR;
}

contract SencToken is PausableToken, SencTokenConfig, Salvageable {
    using SafeMath for uint;

    string public name = NAME;
    string public symbol = SYMBOL;
    uint8 public decimals = DECIMALS;
    bool public mintingFinished = false;

    event Mint(address indexed to, uint amount);
    event MintFinished();

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    function SencToken() public {
        paused = true;
    }

    function pause() onlyOwner public {
        revert();
    }

    function unpause() onlyOwner public {
        super.unpause();
    }

    function mint(address _to, uint _amount) onlyOwner canMint public returns (bool) {
        require(totalSupply_.add(_amount) <= TOTALSUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    // Airdrop tokens from bounty wallet to contributors as long as there are enough balance
    function airdrop(address bountyWallet, address[] dests, uint[] values) public onlyOwner returns (uint) {
        require(dests.length == values.length);
        uint i = 0;
        while (i < dests.length && balances[bountyWallet] >= values[i]) {
            this.transferFrom(bountyWallet, dests[i], values[i]);
            i += 1;
        }
        return(i);
    }
}

contract SencTokenSaleConfig is SencTokenConfig {
    uint public constant TOKEN_FOUNDINGTEAM =  50000000 * DECIMALSFACTOR;
    uint public constant TOKEN_EARLYSUPPORTERS = 100000000 * DECIMALSFACTOR;
    uint public constant TOKEN_PRESALE = 100000000 * DECIMALSFACTOR;
    uint public constant TOKEN_TREASURY = 150000000 * DECIMALSFACTOR;
    uint public constant MILLION = 1000000;
    uint public constant PUBLICSALE_USD_PER_MSENC =  80000;
    uint public constant PRIVATESALE_USD_PER_MSENC =  64000;
    uint public constant MIN_CONTRIBUTION      = 120 finney;
}

contract SencTokenSale is SencTokenSaleConfig, Ownable, Pausable, Salvageable {
    using SafeMath for uint;
    bool public isFinalized = false;

    SencToken public token;
    uint[] public batchStartTimes;
    uint public endTime;
    uint public startTime;
    address public agTechWallet;        // InfoCorp AgTech Wallet Address to receive ETH
    uint public usdPerMEth;             // USD per million ETH. E.g. ETHUSD 844.81 is specified as 844,810,000
    uint public publicSaleSencPerMEth;  // Amount of token 1 million ETH can buy in public sale
    uint public privateSaleSencPerMEth; // Amount of token 1 million ETH can buy in private sale
    uint public weiRaised;              // Amount of raised money in WEI
    WhiteListedBasic public whiteListed;
    uint public numContributors;        // Discrete number of contributors

    mapping (address => uint) public contributions; // to allow them to have multiple spends

    event Finalized();
    event TokenPurchase(address indexed beneficiary, uint value, uint amount);
    event TokenPresale(address indexed purchaser, uint amount);
    event TokenFoundingTeam(address purchaser, uint amount);
    event TokenTreasury(address purchaser, uint amount);
    event EarlySupporters(address purchaser, uint amount);

    function SencTokenSale(uint[] _batchStartTimes, uint _endTime, uint _usdPerMEth, uint _presaleWei,
        WhiteListedBasic _whiteListed, address _agTechWallet,  address _foundingTeamWallet,
        address _earlySupportersWallet, address _treasuryWallet, address _presaleWallet, address _tokenIssuer
    ) public {
        require(_batchStartTimes.length > 0);
        // require (now < batchStartTimes[0]);
        for (uint i = 0; i < _batchStartTimes.length - 1; i++) {
            require(_batchStartTimes[i+1] > _batchStartTimes[i]);
        }
        require(_endTime >= _batchStartTimes[_batchStartTimes.length - 1]);
        require(_usdPerMEth > 0);
        require(_whiteListed != address(0));
        require(_agTechWallet != address(0));
        require(_foundingTeamWallet != address(0));
        require(_earlySupportersWallet != address(0));
        require(_presaleWallet != address(0));
        require(_treasuryWallet != address(0));
        owner = _tokenIssuer;

        batchStartTimes = _batchStartTimes;
        startTime = _batchStartTimes[0];
        endTime = _endTime;
        agTechWallet = _agTechWallet;
        whiteListed = _whiteListed;
        weiRaised = _presaleWei;
        usdPerMEth = _usdPerMEth;
        publicSaleSencPerMEth = usdPerMEth.mul(MILLION).div(PUBLICSALE_USD_PER_MSENC);
        privateSaleSencPerMEth = usdPerMEth.mul(MILLION).div(PRIVATESALE_USD_PER_MSENC);

        // Let the token stuff begin
        token = new SencToken();

        // Mint initial tokens
        mintEarlySupportersTokens(_earlySupportersWallet, TOKEN_EARLYSUPPORTERS);
        mintPresaleTokens(_presaleWallet, TOKEN_PRESALE);
        mintTreasuryTokens(_treasuryWallet, TOKEN_TREASURY);
        mintFoundingTeamTokens(_foundingTeamWallet, TOKEN_FOUNDINGTEAM);
    }

    function getBatchStartTimesLength() public view returns (uint) {
        return batchStartTimes.length;
    }

    function updateBatchStartTime(uint _batchNumber, uint _batchStartTime) public canOperate {
        batchStartTimes[_batchNumber] = _batchStartTime;
	for (uint i = 0; i < batchStartTimes.length - 1; i++) {
            require(batchStartTimes[i+1] > batchStartTimes[i]);
        }
    }

    function updateEndTime(uint _endTime) public canOperate {
	require(_endTime >= batchStartTimes[batchStartTimes.length - 1]);
        endTime = _endTime;
    }

    function updateUsdPerMEth(uint _usdPerMEth) public canOperate {
        require(now < batchStartTimes[0]);
        usdPerMEth = _usdPerMEth;
        publicSaleSencPerMEth = usdPerMEth.mul(MILLION).div(PUBLICSALE_USD_PER_MSENC);
        privateSaleSencPerMEth = usdPerMEth.mul(MILLION).div(PRIVATESALE_USD_PER_MSENC);
    }

    function mintEarlySupportersTokens(address addr, uint amount) internal {
        token.mint(addr, amount);
        EarlySupporters(addr, amount);
    }

    function mintTreasuryTokens(address addr, uint amount) internal {
        token.mint(addr, amount);
        TokenTreasury(addr, amount);
    }

    function mintFoundingTeamTokens(address addr, uint amount) internal {
        token.mint(addr, amount);
        TokenFoundingTeam(addr, amount);
    }

    function mintPresaleTokens(address addr, uint amount) internal {
        token.mint(addr, amount);
        TokenPresale(addr, amount);
    }

    // Only fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender, msg.value);
    }

    function buyTokens(address beneficiary, uint weiAmount) internal whenNotPaused {
        require(beneficiary != address(0));
        require(isWhiteListed(beneficiary));
        require(isWithinPeriod(beneficiary));
        require(isWithinAllocation(beneficiary, weiAmount));

        uint tokens = weiAmount.mul(publicSaleSencPerMEth).div(MILLION);
        weiRaised = weiRaised.add(weiAmount);

        if (contributions[beneficiary] == 0) {
            numContributors++;
        }

        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);
        token.mint(beneficiary, tokens);
        TokenPurchase(beneficiary, weiAmount, tokens);

        forwardFunds();
    }

    function ethRaised() public view returns(uint) {
        return weiRaised.div(10 ** 18);
    }

    function usdRaised() public view returns(uint) {
        return weiRaised.mul(usdPerMEth).div(MILLION);
    }

    function sencSold() public view returns(uint) {
        return token.totalSupply();
    }

    function sencBalance() public view returns(uint) {
        return token.TOTALSUPPLY().sub(token.totalSupply());
    }

    // This can be used after the sale is over and tokens are unpaused
    function reclaimTokens() external canOperate {
        uint balance = token.balanceOf(this);
        token.transfer(owner, balance);
    }

    // Batch is in 0..n-1 format
    function isBatchActive(uint batch) public view returns (bool) {
        if (now > endTime) {
            return false;
        }
        if (uint(batch) >= batchStartTimes.length) {
            return false;
        }
        if (now > batchStartTimes[batch]) {
            return true;
        }
        return false;
    }

    // Returns
    // 0                           - not started
    // 1..batchStartTimes.length   - batch plus 1
    // batchStartTimes.length + 1  - ended
    function batchActive() public view returns (uint) {
        if (now > endTime) {
            return batchStartTimes.length + 1;
        }
        for (uint i = batchStartTimes.length; i > 0; i--) {
            if (now > batchStartTimes[i-1]) {
                return i;
            }
        }
        return 0;
    }

    // Return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }

    // Send ether to the fund collection wallet
    function forwardFunds() internal {
        agTechWallet.transfer(msg.value);
    }

    // Buyer must be whitelisted
    function isWhiteListed(address beneficiary) internal view returns (bool) {
        return whiteListed.isWhiteListed(beneficiary);
    }

    // Buyer must by within assigned batch period
    function isWithinPeriod(address beneficiary) internal view returns (bool) {
        uint batchNumber = whiteListed.getBatchNumber(beneficiary);
        return now >= batchStartTimes[batchNumber] && now <= endTime;
    }

    // Buyer must by withint allocated amount
    function isWithinAllocation(address beneficiary, uint weiAmount) internal view returns (bool) {
        uint allocation = whiteListed.getAllocated(beneficiary);
        return (weiAmount >= MIN_CONTRIBUTION) && (weiAmount.add(contributions[beneficiary]) <= allocation);
    }

    // Must be called after crowdsale ends, to do some extra finalization
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

    // Stops the minting and transfer token ownership to sale owner. Mints unsold tokens to owner
    function finalization() internal {
        token.mint(owner,sencBalance());
        token.finishMinting();
        token.transferOwnership(owner);
    }
}