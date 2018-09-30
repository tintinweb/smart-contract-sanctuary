pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;Kaasy&#39; CROWDSALE token contract
//
// Deployed to : 0x1c9Cea095d2B91Be53e36DcD769bB8c78311150b
// Symbol      : KAAS
// Name        : KAASY.AI Token
// Total supply: 500000000
// Decimals    : 18
//
// Enjoy.
//
// (c) by KAASY AI LTD. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    
    address public ownerAPI;
    address public newOwnerAPI;

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event OwnershipAPITransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        ownerAPI = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOwnerAPI {
        require(msg.sender == ownerAPI);
        _;
    }

    modifier onlyOwnerOrOwnerAPI {
        require(msg.sender == owner || msg.sender == ownerAPI);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function transferAPIOwnership(address _newOwnerAPI) public onlyOwner {
        newOwnerAPI = _newOwnerAPI;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function acceptOwnershipAPI() public {
        require(msg.sender == newOwnerAPI);
        emit OwnershipAPITransferred(ownerAPI, newOwnerAPI);
        ownerAPI = newOwnerAPI;
        newOwnerAPI = address(0);
    }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public isPaused = false;

  function paused() public view returns (bool currentlyPaused) {
      return isPaused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!isPaused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(isPaused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    isPaused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    isPaused = false;
    emit Unpause();
  }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract kaasy2Token is ERC20Interface, Pausable, SafeMath {
    string public symbol = "KAAS";
    string public  name  = "KAASY.AI Token";
    uint8 public decimals = 18;
    uint public _totalSupply;
    uint public startDate;
    uint public bonusEnd20;
    uint public bonusEnd10;
    uint public bonusEnd05;
    uint public endDate;
    uint public tradingDate;
    uint public exchangeRate = 30000; // IN Euro cents = 300E
    uint256 public maxSupply;
    uint256 public soldSupply;
    uint256 public maxSellable;
    uint8 private teamWOVestingPercentage = 5;
    
    uint256 public minAmountETH;
    uint256 public maxAmountETH;
    
    address public currentRunningAddress;

    mapping(address => uint256) balances; //keeps ERC20 balances, in Symbol
    mapping(address => uint256) ethDeposits; //keeps balances, in ETH
    mapping(address => bool) kycAddressState; //keeps list of addresses which can send ETH without direct fail
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => uint256) burnedBalances; //keeps ERC20 balances, in Symbol

    //event KYCStateUpdate(address indexed addr, bool state);
    
    event MintingFinished(uint indexed moment);
    bool isMintingFinished = false;
    
    event OwnBlockchainLaunched(uint indexed moment);
    event TokensBurned(address indexed exOwner, uint256 indexed amount, uint indexed moment);
    bool isOwnBlockchainLaunched = false;
    uint momentOwnBlockchainLaunched = 0;
    
    uint8 public versionIndex = 1;
    
    address addrUniversity;
    address addrEarlySkills;
    address addrHackathons;
    address addrLegal;
    address addrMarketing;
    
    bool public isContractInitiated = false;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        maxSupply = 500000000 * (10 ** 18);
        maxSellable = maxSupply * 60 / 100;
        
        currentRunningAddress = address(this);
        
        soldSupply = 0;
        
        startDate = 1535760000;  // September 1st
        bonusEnd20 = 1535760000; // September 8th
        bonusEnd10 = 1535760000; // September 15th
        bonusEnd05 = 1535760000; // September 22nd
        endDate = 1542240000;    // November 15th
        tradingDate = 1543536000;// November 30th
        
        minAmountETH = safeDiv(1 ether, 10);
        maxAmountETH = safeMul(1 ether, 5000);
        
        isPaused = true;
    }
    
    function Initiate() onlyOwnerOrOwnerAPI whenPaused public returns (bool ok){
        require(!isContractInitiated);
        
        isContractInitiated = true;
        
        uint256 teamAmount = maxSupply * 150 / 1000;
        
        balances[address(this)] = teamAmount * (100 - teamWOVestingPercentage) / 100; //team with vesting
        emit Transfer(address(0), address(this), balances[address(this)]);
        
        balances[owner] = teamAmount * teamWOVestingPercentage / 100; //team without vesting
        kycAddressState[owner] = true;
        emit Transfer(address(0), owner, balances[owner]);
        
        addrUniversity = 0x086cAd431fa1A18A1846a5C5a9F9F5653c99fAd0;
        balances[addrUniversity] =  maxSupply * 50 / 1000; //univ
        kycAddressState[addrUniversity] = true;
        emit Transfer(address(0), addrUniversity, balances[addrUniversity]);
        
        addrEarlySkills = 0x4913A10909f8664e2144A2846278f6cD4Cd30cDF;
        balances[addrEarlySkills] = maxSupply * 50 / 1000; //skills
        kycAddressState[addrEarlySkills] = true;
        emit Transfer(address(0), addrEarlySkills, balances[addrEarlySkills]);
        
        addrHackathons = 0x0cd8F1b160d4fC5e619C1a8Cf634ba6E1d8F203E;
        balances[addrHackathons] =  maxSupply * 45 / 1000; //hackathons and bug bounties
        kycAddressState[addrHackathons] = true;
        emit Transfer(address(0), addrHackathons, balances[addrHackathons]);
        
        addrLegal = 0x2aaCF811aC1A60081EA39F7783c0D26c500871a8;
        balances[addrLegal] =       maxSupply * 30 / 1000; //legal fees & backup
        kycAddressState[addrLegal] = true;
        emit Transfer(address(0), addrLegal, balances[addrLegal]);
        
        addrMarketing = 0x05377158a54dC8cC378c8ea4b7fB5fbF78D06d83;
        balances[addrMarketing] =   maxSupply * 75 / 1000; //marketing
        kycAddressState[addrMarketing] = true;
        emit Transfer(address(0), addrMarketing, balances[addrMarketing]);
        
        _totalSupply = maxSupply * 40 / 100;
        
        return true;
        
    }

    // ------------------------------------------------------------------------
    // token minter function
    // ------------------------------------------------------------------------
    function () public payable whenNotPaused {
        if(now > endDate && isMintingFinished == false) {
            finishMinting();
            msg.sender.transfer(msg.value); //return this transfer, as it is too late.
        } else {
            require(now >= startDate && now <= endDate && isMintingFinished == false);
            
            require(msg.value >= minAmountETH && msg.value <= maxAmountETH);
            require(msg.value + ethDeposits[msg.sender] <= maxAmountETH);
            
            require(kycAddressState[msg.sender] == true);
            
            uint tokens = getAmountToIssue(msg.value);
            require(safeAdd(soldSupply, tokens) <= maxSellable);
            
            soldSupply = safeAdd(soldSupply, tokens);
            _totalSupply = safeAdd(_totalSupply, tokens);
            balances[msg.sender] = safeAdd(balances[msg.sender], tokens);
            ethDeposits[msg.sender] = safeAdd(ethDeposits[msg.sender], msg.value);
            emit Transfer(address(0), msg.sender, tokens);
            
            owner.transfer(msg.value * 15 / 100);   //transfer 15% of the ETH now, the other 85% at the end of the ICO process
        }
    }
    
    // ------------------------------------------------------------------------
    // Burns tokens of `msg.sender` and sets them as redeemable on KAASY blokchain
    // ------------------------------------------------------------------------
    function BurnMyTokensAndSetAmountForNewBlockchain() public  {
        require(isOwnBlockchainLaunched);
        
        uint senderBalance = balances[msg.sender];
        burnedBalances[msg.sender] = safeAdd(burnedBalances[msg.sender], senderBalance);
        balances[msg.sender] = 0;
        emit TokensBurned(msg.sender, senderBalance, now);
    }
    
    // ------------------------------------------------------------------------
    // Burns tokens of `exOwner` and sets them as redeemable on KAASY blokchain
    // ------------------------------------------------------------------------
    function BurnTokensAndSetAmountForNewBlockchain(address exOwner) onlyOwnerOrOwnerAPI public {
        require(isOwnBlockchainLaunched);
        
        uint exBalance = balances[exOwner];
        burnedBalances[exOwner] = safeAdd(burnedBalances[exOwner], exBalance);
        balances[exOwner] = 0;
        emit TokensBurned(exOwner, exBalance, now);
    }
    
    // ------------------------------------------------------------------------
    // Enables the burning of tokens to move to the new KAASY blockchain
    // ------------------------------------------------------------------------
    function SetNewBlockchainEnabled() onlyOwner public {
        require(isMintingFinished && isOwnBlockchainLaunched == false);
        isOwnBlockchainLaunched = true;
        momentOwnBlockchainLaunched = now;
        emit OwnBlockchainLaunched(now);
    }

    // ------------------------------------------------------------------------
    // Evaluates conditions for finishing the ICO and does that if conditions are met
    // ------------------------------------------------------------------------
    function finishMinting() public returns (bool finished) {
        if(now > endDate && isMintingFinished == false) {
            internalFinishMinting();
            return true;
        } else if (_totalSupply >= maxSupply) {
            internalFinishMinting();
            return true;
        }
        if(now > endDate && address(this).balance > 0) {
            owner.transfer(address(this).balance);
        }
        return false;
    }
    
    // ------------------------------------------------------------------------
    // Actually executes the finish of the ICO, 
    //  no longer minting tokens, 
    //  releasing the 85% of ETH kept by contract and
    //  enables trading 2 weeks after this moment
    // ------------------------------------------------------------------------
    function internalFinishMinting() internal {
        tradingDate = now + 3600;// * 24 * 15; // 2 weeks after ICO end moment
        isMintingFinished = true;
        emit MintingFinished(now);
        owner.transfer(address(this).balance); //transfer all ETH left (the 85% not sent instantly) to the owner address
    }

    // ------------------------------------------------------------------------
    // Calculates amount of KAAS to issue to `msg.sender` for `ethAmount`
    // Can be called by any interested party, to evaluate the amount of KAAS obtained for `ethAmount` specified
    // ------------------------------------------------------------------------
    function getAmountToIssue(uint256 ethAmount) public view returns(uint256) {
        //price is 10c/KAAS
        uint256 euroAmount = exchangeEthToEur(ethAmount);
        uint256 ret = euroAmount / 10; // 1kaas=0.1EUR, exchange rate is in cents, so *10/100 = /10
        ret = ret * (uint256)(10) ** (uint256)(decimals);
        if(now < bonusEnd20) {
            ret = euroAmount * 12;          //first week, 20% bonus
            
        } else if(now < bonusEnd10) {
            ret = euroAmount * 11;          //second week, 10% bonus
            
        } else if(now < bonusEnd05) {
            ret = euroAmount * 105 / 10;    //third week, 5% bonus
            
        }
        
        if(euroAmount >= 50000) {
            ret = ret * 13 / 10;
            
        } else if(euroAmount >= 10000) {
            ret = ret * 12 / 10;
        }
        
        return ret;
    }
    
    // ------------------------------------------------------------------------
    // Calculates EUR amount for ethAmount
    // ------------------------------------------------------------------------
    function exchangeEthToEur(uint256 ethAmount) internal view returns(uint256 rate) {
        return safeDiv(safeMul(ethAmount, exchangeRate), 1 ether);
    }
    
    // ------------------------------------------------------------------------
    // Calculates KAAS amount for eurAmount
    // ------------------------------------------------------------------------
    function exchangeEurToEth(uint256 eurAmount) internal view returns(uint256 rate) {
        return safeDiv(safeMul(safeDiv(safeMul(eurAmount, 1000000000000000000), exchangeRate), 1 ether), 1000000000000000000);
    }
    
    // ------------------------------------------------------------------------
    // Calculates and transfers monthly vesting amount to founders, into the balance of `owner` address
    // ------------------------------------------------------------------------
    function transferVestingMonthlyAmount(address destination) public onlyOwner returns (bool) {
        require(destination != address(0));
        uint monthsSinceLaunch = (now - tradingDate) / 3600 / 24 / 30;
        uint256 totalAmountInVesting = maxSupply * 15 / 100 * (100 - teamWOVestingPercentage) / 100; //15% of total, of which 5% instant and 95% with vesting
        uint256 releaseableUpToToday = (monthsSinceLaunch + 1) * totalAmountInVesting / 24; // 15% of total, across 24 months
        
        //address(this) holds the vestable amount left
        uint256 alreadyReleased = totalAmountInVesting - balances[address(this)];
        uint256 releaseableNow = releaseableUpToToday - alreadyReleased;
        require (releaseableNow > 0);
        transferFrom(address(this), destination, releaseableNow);
        
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Set KYC state for `depositer` to `isAllowed`, by admins
    // ------------------------------------------------------------------------
    function setAddressKYC(address depositer, bool isAllowed) public onlyOwnerOrOwnerAPI returns (bool) {
        kycAddressState[depositer] = isAllowed;
        //emit KYCStateUpdate(depositer, isAllowed);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Get an addresses KYC state
    // ------------------------------------------------------------------------
    function getAddressKYCState(address depositer) public view returns (bool) {
        return kycAddressState[depositer];
    }
    
    // ------------------------------------------------------------------------
    // Token name, as seen by the network
    // ------------------------------------------------------------------------
    function name() public view returns (string) {
        return name;
    }
    
    // ------------------------------------------------------------------------
    // Token symbol, as seen by the network
    // ------------------------------------------------------------------------
    function symbol() public view returns (string) {
        return symbol;
    }
    
    // ------------------------------------------------------------------------
    // Token decimals
    // ------------------------------------------------------------------------
    function decimals() public view returns (uint8) {
        return decimals;
    }

    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)]; //address(0) represents burned tokens
    }
    
    // ------------------------------------------------------------------------
    // Circulating supply
    // ------------------------------------------------------------------------
    function circulatingSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)] - balances[address(this)]; //address(0) represents burned tokens
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    
    // ------------------------------------------------------------------------
    // Get the total ETH deposited by `depositer`
    // ------------------------------------------------------------------------
    function depositsOf(address depositer) public constant returns (uint balance) {
        return ethDeposits[depositer];
    }
    
    // ------------------------------------------------------------------------
    // Get the total KAAS burned by `exOwner`
    // ------------------------------------------------------------------------
    function burnedBalanceOf(address exOwner) public constant returns (uint balance) {
        return burnedBalances[exOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    //  !! fund source is the address calling this function !!
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        if(now > endDate && isMintingFinished == false) {
            finishMinting();
        }
        require(now >= tradingDate || kycAddressState[to] == true); //allow internal transfers before tradingDate
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `destination` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces
    
    // !!! When called, the amount of tokens DESTINATION can retrieve from MSG.SENDER is set to AMOUNT
    // !!! This is used when another account C calls and pays gas for the transfer between A and B, like bank cheques
    // !!! meaning: Allow DESTINATION to transfer a total AMOUNT from ME=callerOfThisFunction, from this point on, ignoring previous allows
    
    // ------------------------------------------------------------------------
    function approve(address destination, uint amount) public returns (bool success) {
        allowed[msg.sender][destination] = amount;
        emit Approval(msg.sender, destination, amount);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    //
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        if(now > endDate && isMintingFinished == false) {
            finishMinting();
        }
        require(now >= tradingDate || kycAddressState[to] == true); //allow internal transfers before tradingDate
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the requester&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address requester) public constant returns (uint remaining) {
        return allowed[tokenOwner][requester];
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `requester` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `requester` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address requester, uint tokens, bytes data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][requester] = tokens;
        emit Approval(msg.sender, requester, tokens);
        ApproveAndCallFallBack(requester).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out `tokens` amount of accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAllERC20Token(address tokenAddress, uint tokens) public onlyOwnerOrOwnerAPI returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out all accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress) public onlyOwnerOrOwnerAPI returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, ERC20Interface(tokenAddress).balanceOf(this));
    }
    
    // ------------------------------------------------------------------------
    // Set the new ETH-EUR exchange rate, in cents
    // ------------------------------------------------------------------------
    function updateExchangeRate(uint newEthEurRate) public onlyOwnerOrOwnerAPI returns (bool success) {
        exchangeRate = newEthEurRate;
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Get the current ETH-EUR exchange rate, in cents
    // ------------------------------------------------------------------------
    function getExchangeRate() public view returns (uint256 rate) {
        return exchangeRate;
    }
    
    // ------------------------------------------------------------------------
    // Set the new EndDate
    // ------------------------------------------------------------------------
    function updateEndDate(uint256 newDate) public onlyOwnerOrOwnerAPI returns (bool success) {
        require(!isMintingFinished);
        require(!isOwnBlockchainLaunched);
        
        endDate = newDate;
        
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Set the new Token name and Symbol
    // ------------------------------------------------------------------------
    function updateTokenNameSymbolAddress(string newTokenName, string newSymbol, address newContractAddress) public whenPaused onlyOwnerOrOwnerAPI returns (bool success) {
        name = newTokenName;
        symbol = newSymbol;
        currentRunningAddress = newContractAddress;
        
        return true;
    }
    
}