pragma solidity ^0.4.18;
    
    // File: zeppelin-solidity/contracts/ownership/Ownable.sol
    
    /**
     * @title Ownable
     * @dev The Ownable contract has an owner address, and provides basic authorization control
     * functions, this simplifies the implementation of "user permissions".
     */
    contract Ownable {
      address public owner;
    
    
      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    
      /**
       * @dev The Ownable constructor sets the original `owner` of the contract to the sender
       * account.
       */
      function Ownable() public {
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
       * @dev Allows the current owner to transfer control of the contract to a newOwner.
       * @param newOwner The address to transfer ownership to.
       */
      function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
      }
    
    }
    
    // File: zeppelin-solidity/contracts/lifecycle/Pausable.sol
    
    /**
     * @title Pausable
     * @dev Base contract which allows children to implement an emergency stop mechanism.
     */
    contract Pausable is Ownable {
      event Pause();
      event Unpause();
    
      bool public paused = false;
    
    
      /**
       * @dev Modifier to make a function callable only when the contract is not paused.
       */
      modifier whenNotPaused() {
        require(!paused);
        _;
      }
    
      /**
       * @dev Modifier to make a function callable only when the contract is paused.
       */
      modifier whenPaused() {
        require(paused);
        _;
      }
    
      /**
       * @dev called by the owner to pause, triggers stopped state
       */
      function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
      }
    
      /**
       * @dev called by the owner to unpause, returns to normal state
       */
      function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
      }
    }
    
    // File: zeppelin-solidity/contracts/math/SafeMath.sol
    
    /**
     * @title SafeMath
     * @dev Math operations with safety checks that throw on error
     */
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
    
    // File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol
    
    /**
     * @title ERC20Basic
     * @dev Simpler version of ERC20 interface
     * @dev see https://github.com/ethereum/EIPs/issues/179
     */
    contract ERC20Basic {
      function totalSupply() public view returns (uint256);
      function balanceOf(address who) public view returns (uint256);
      function transfer(address to, uint256 value) public returns (bool);
      event Transfer(address indexed from, address indexed to, uint256 value);
    }
    
    // File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol
    
    /**
     * @title Basic token
     * @dev Basic version of StandardToken, with no allowances.
     */
    contract BasicToken is ERC20Basic {
      using SafeMath for uint256;
    
      mapping(address => uint256) balances;
    
      uint256 totalSupply_;
    
      /**
      * @dev total number of tokens in existence
      */
      function totalSupply() public view returns (uint256) {
        return totalSupply_;
      }
    
      /**
      * @dev transfer token for a specified address
      * @param _to The address to transfer to.
      * @param _value The amount to be transferred.
      */
      function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
    
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
      }
    
      /**
      * @dev Gets the balance of the specified address.
      * @param _owner The address to query the the balance of.
      * @return An uint256 representing the amount owned by the passed address.
      */
      function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
      }
    
    }
    
    // File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol
    
    /**
     * @title ERC20 interface
     * @dev see https://github.com/ethereum/EIPs/issues/20
     */
    contract ERC20 is ERC20Basic {
      function allowance(address owner, address spender) public view returns (uint256);
      function transferFrom(address from, address to, uint256 value) public returns (bool);
      function approve(address spender, uint256 value) public returns (bool);
      event Approval(address indexed owner, address indexed spender, uint256 value);
    }
    
    // File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol
    
    /**
     * @title Standard ERC20 token
     *
     * @dev Implementation of the basic standard token.
     * @dev https://github.com/ethereum/EIPs/issues/20
     * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
     */
    contract StandardToken is ERC20, BasicToken {
    
      mapping (address => mapping (address => uint256)) internal allowed;
    
    
      /**
       * @dev Transfer tokens from one address to another
       * @param _from address The address which you want to send tokens from
       * @param _to address The address which you want to transfer to
       * @param _value uint256 the amount of tokens to be transferred
       */
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
    
      /**
       * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
       *
       * Beware that changing an allowance with this method brings the risk that someone may use both the old
       * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
       * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
       * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
       * @param _spender The address which will spend the funds.
       * @param _value The amount of tokens to be spent.
       */
      function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
      }
    
      /**
       * @dev Function to check the amount of tokens that an owner allowed to a spender.
       * @param _owner address The address which owns the funds.
       * @param _spender address The address which will spend the funds.
       * @return A uint256 specifying the amount of tokens still available for the spender.
       */
      function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
      }
    
      /**
       * @dev Increase the amount of tokens that an owner allowed to a spender.
       *
       * approve should be called when allowed[_spender] == 0. To increment
       * allowed value is better to use this function to avoid 2 calls (and wait until
       * the first transaction is mined)
       * From MonolithDAO Token.sol
       * @param _spender The address which will spend the funds.
       * @param _addedValue The amount of tokens to increase the allowance by.
       */
      function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
      }
    
      /**
       * @dev Decrease the amount of tokens that an owner allowed to a spender.
       *
       * approve should be called when allowed[_spender] == 0. To decrement
       * allowed value is better to use this function to avoid 2 calls (and wait until
       * the first transaction is mined)
       * From MonolithDAO Token.sol
       * @param _spender The address which will spend the funds.
       * @param _subtractedValue The amount of tokens to decrease the allowance by.
       */
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
    
    // File: contracts/CurrentToken.sol
    
    contract CurrentToken is StandardToken, Pausable {
        string constant public name = "CurrentCoin";
        string constant public symbol = "CUR";
        uint8 constant public decimals = 18;
    
        uint256 constant public INITIAL_TOTAL_SUPPLY = 1e11 * (uint256(10) ** decimals);
    
        address private addressIco;
    
        modifier onlyIco() {
            require(msg.sender == addressIco);
            _;
        }
    
        /**
        * @dev Create CurrentToken contract and set pause
        * @param _ico The address of ICO contract.
        */
        function CurrentToken (address _ico) public {
            require(_ico != address(0));
    
            addressIco = _ico;
    
            totalSupply_ = totalSupply_.add(INITIAL_TOTAL_SUPPLY);
            balances[_ico] = balances[_ico].add(INITIAL_TOTAL_SUPPLY);
            Transfer(address(0), _ico, INITIAL_TOTAL_SUPPLY);
    
            pause();
        }
    
        /**
        * @dev Transfer token for a specified address with pause feature for owner.
        * @dev Only applies when the transfer is allowed by the owner.
        * @param _to The address to transfer to.
        * @param _value The amount to be transferred.
        */
        function transfer(address _to, uint256 _value) whenNotPaused public returns (bool) {
            super.transfer(_to, _value);
        }
    
        /**
        * @dev Transfer tokens from one address to another with pause feature for owner.
        * @dev Only applies when the transfer is allowed by the owner.
        * @param _from address The address which you want to send tokens from
        * @param _to address The address which you want to transfer to
        * @param _value uint256 the amount of tokens to be transferred
        */
        function transferFrom(address _from, address _to, uint256 _value) whenNotPaused public returns (bool) {
            super.transferFrom(_from, _to, _value);
        }
    
        /**
        * @dev Transfer tokens from ICO address to another address.
        * @param _to The address to transfer to.
        * @param _value The amount to be transferred.
        */
        function transferFromIco(address _to, uint256 _value) onlyIco public returns (bool) {
            super.transfer(_to, _value);
        }
    
        /**
        * @dev Burn remaining tokens from the ICO balance.
        */
        function burnFromIco() onlyIco public {
            uint256 remainingTokens = balanceOf(addressIco);
    
            balances[addressIco] = balances[addressIco].sub(remainingTokens);
            totalSupply_ = totalSupply_.sub(remainingTokens);
            Transfer(addressIco, address(0), remainingTokens);
        }
    
        /**
        * @dev Burn all tokens form balance of token holder during refund process.
        * @param _from The address of token holder whose tokens to be burned.
        */
        function burnFromAddress(address _from) onlyIco public {
            uint256 amount = balances[_from];
    
            balances[_from] = 0;
            totalSupply_ = totalSupply_.sub(amount);
            Transfer(_from, address(0), amount);
        }
    }
    
    // File: contracts/Whitelist.sol
    
    /**
     * @title Whitelist contract
     * @dev Whitelist for wallets.
    */
    contract Whitelist is Ownable {
        mapping(address => bool) whitelist;
    
        uint256 public whitelistLength = 0;
    
        /**
        * @dev Add wallet to whitelist.
        * @dev Accept request from the owner only.
        * @param _wallet The address of wallet to add.
        */  
        function addWallet(address _wallet) onlyOwner public {
            require(_wallet != address(0));
            require(!isWhitelisted(_wallet));
            whitelist[_wallet] = true;
            whitelistLength++;
        }
    
        /**
        * @dev Remove wallet from whitelist.
        * @dev Accept request from the owner only.
        * @param _wallet The address of whitelisted wallet to remove.
        */  
        function removeWallet(address _wallet) onlyOwner public {
            require(_wallet != address(0));
            require(isWhitelisted(_wallet));
            whitelist[_wallet] = false;
            whitelistLength--;
        }
    
        /**
        * @dev Check the specified wallet whether it is in the whitelist.
        * @param _wallet The address of wallet to check.
        */ 
        function isWhitelisted(address _wallet) constant public returns (bool) {
            return whitelist[_wallet];
        }
    
    }
    
    // File: contracts/Whitelistable.sol
    
    contract Whitelistable {
        Whitelist public whitelist;
    
        modifier whenWhitelisted(address _wallet) {
            require(whitelist.isWhitelisted(_wallet));
            _;
        }
    
        /**
        * @dev Constructor for Whitelistable contract.
        */
        function Whitelistable() public {
            whitelist = new Whitelist();
        }
    }
    
    // File: contracts/CurrentCrowdsale.sol
    
    contract CurrentCrowdsale is Pausable, Whitelistable {
        using SafeMath for uint256;
    
        uint256 constant private DECIMALS = 18;
        uint256 constant public RESERVED_TOKENS_FOUNDERS = 40e9 * (10 ** DECIMALS);
        uint256 constant public RESERVED_TOKENS_OPERATIONAL_EXPENSES = 10e9 * (10 ** DECIMALS);
        uint256 constant public HARDCAP_TOKENS_PRE_ICO = 100e6 * (10 ** DECIMALS);
        uint256 constant public HARDCAP_TOKENS_ICO = 499e8 * (10 ** DECIMALS);
    
        uint256 public startTimePreIco = 0;
        uint256 public endTimePreIco = 0;
    
        uint256 public startTimeIco = 0;
        uint256 public endTimeIco = 0;
    
        uint256 public exchangeRatePreIco = 0;
    
        bool public isTokenRateCalculated = false;
    
        uint256 public exchangeRateIco = 0;
    
        uint256 public mincap = 0;
        uint256 public maxcap = 0;
    
        mapping(address => uint256) private investments;    
    
        uint256 public tokensSoldIco = 0;
        uint256 public tokensRemainingIco = HARDCAP_TOKENS_ICO;
        uint256 public tokensSoldTotal = 0;
    
        uint256 public weiRaisedPreIco = 0;
        uint256 public weiRaisedIco = 0;
        uint256 public weiRaisedTotal = 0;
    
        mapping(address => uint256) private investmentsPreIco;
        address[] private investorsPreIco;
    
        address private withdrawalWallet;
    
        bool public isTokensPreIcoDistributed = false;
        uint256 public distributionPreIcoCount = 0;
    
        CurrentToken public token = new CurrentToken(this);
    
        modifier beforeReachingHardCap() {
            require(tokensRemainingIco > 0 && weiRaisedTotal < maxcap);
            _;
        }
    
        modifier whenPreIcoSaleHasEnded() {
            require(now > endTimePreIco);
            _;
        }
    
        modifier whenIcoSaleHasEnded() {
            require(endTimeIco > 0 && now > endTimeIco);
            _;
        }
    
        /**
        * @dev Constructor for CurrentCrowdsale contract.
        * @dev Set the owner who can manage whitelist and token.
        * @param _mincap The mincap value.
        * @param _startTimePreIco The pre-ICO start time.
        * @param _endTimePreIco The pre-ICO end time.
        * @param _foundersWallet The address to which reserved tokens for founders will be transferred.
        * @param _operationalExpensesWallet The address to which reserved tokens for operational expenses will be transferred.
        * @param _withdrawalWallet The address to which raised funds will be withdrawn.
        */
        function CurrentCrowdsale(
            uint256 _mincap,
            uint256 _maxcap,
            uint256 _startTimePreIco,
            uint256 _endTimePreIco,
            address _foundersWallet,
            address _operationalExpensesWallet,
            address _withdrawalWallet
        ) Whitelistable() public
        {
            require(_foundersWallet != address(0) && _operationalExpensesWallet != address(0) && _withdrawalWallet != address(0));
            require(_startTimePreIco >= now && _endTimePreIco > _startTimePreIco);
            require(_mincap > 0 && _maxcap > _mincap);
    
            startTimePreIco = _startTimePreIco;
            endTimePreIco = _endTimePreIco;
    
            withdrawalWallet = _withdrawalWallet;
    
            mincap = _mincap;
            maxcap = _maxcap;
    
            whitelist.transferOwnership(msg.sender);
    
            token.transferFromIco(_foundersWallet, RESERVED_TOKENS_FOUNDERS);
            token.transferFromIco(_operationalExpensesWallet, RESERVED_TOKENS_OPERATIONAL_EXPENSES);
            token.transferOwnership(msg.sender);
        }
    
        /**
        * @dev Fallback function can be used to buy tokens.
        */
        function() public payable {
            if (isPreIco()) {
                sellTokensPreIco();
            } else if (isIco()) {
                sellTokensIco();
            } else {
                revert();
            }
        }
    
        /**
        * @dev Check whether the pre-ICO is active at the moment.
        */
        function isPreIco() public constant returns (bool) {
            bool withinPreIco = now >= startTimePreIco && now <= endTimePreIco;
            return withinPreIco;
        }
    
        /**
        * @dev Check whether the ICO is active at the moment.
        */
        function isIco() public constant returns (bool) {
            bool withinIco = now >= startTimeIco && now <= endTimeIco;
            return withinIco;
        }
    
        /**
        * @dev Manual refund if mincap has not been reached.
        * @dev Only applies when the ICO was ended. 
        */
        function manualRefund() whenIcoSaleHasEnded public {
            require(weiRaisedTotal < mincap);
    
            uint256 weiAmountTotal = investments[msg.sender];
            require(weiAmountTotal > 0);
    
            investments[msg.sender] = 0;
    
            uint256 weiAmountPreIco = investmentsPreIco[msg.sender];
            uint256 weiAmountIco = weiAmountTotal;
    
            if (weiAmountPreIco > 0) {
                investmentsPreIco[msg.sender] = 0;
                weiRaisedPreIco = weiRaisedPreIco.sub(weiAmountPreIco);
                weiAmountIco = weiAmountIco.sub(weiAmountPreIco);
            }
    
            if (weiAmountIco > 0) {
                weiRaisedIco = weiRaisedIco.sub(weiAmountIco);
                uint256 tokensIco = weiAmountIco.mul(exchangeRateIco);
                tokensSoldIco = tokensSoldIco.sub(tokensIco);
            }
    
            weiRaisedTotal = weiRaisedTotal.sub(weiAmountTotal);
    
            uint256 tokensAmount = token.balanceOf(msg.sender);
    
            tokensSoldTotal = tokensSoldTotal.sub(tokensAmount);
    
            token.burnFromAddress(msg.sender);
    
            msg.sender.transfer(weiAmountTotal);
        }
    
        /**
        * @dev Sell tokens during pre-ICO.
        * @dev Sell tokens only for whitelisted wallets.
        */
        function sellTokensPreIco() beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused public payable {
            require(isPreIco());
            require(msg.value > 0);
    
            uint256 weiAmount = msg.value;
            uint256 excessiveFunds = 0;
    
            uint256 plannedWeiTotal = weiRaisedTotal.add(weiAmount);
    
            if (plannedWeiTotal > maxcap) {
                excessiveFunds = plannedWeiTotal.sub(maxcap);
                weiAmount = maxcap.sub(weiRaisedTotal);
            }
    
            investments[msg.sender] = investments[msg.sender].add(weiAmount);
    
            weiRaisedPreIco = weiRaisedPreIco.add(weiAmount);
            weiRaisedTotal = weiRaisedTotal.add(weiAmount);
    
            addInvestmentPreIco(msg.sender, weiAmount);
    
            if (excessiveFunds > 0) {
                msg.sender.transfer(excessiveFunds);
            }
        }
    
        /**
        * @dev Sell tokens during ICO.
        * @dev Sell tokens only for whitelisted wallets.
        */
        function sellTokensIco() beforeReachingHardCap whenWhitelisted(msg.sender) whenNotPaused public payable {
            require(isIco());
            require(msg.value > 0);
    
            uint256 weiAmount = msg.value;
            uint256 excessiveFunds = 0;
    
            uint256 plannedWeiTotal = weiRaisedTotal.add(weiAmount);
    
            if (plannedWeiTotal > maxcap) {
                excessiveFunds = plannedWeiTotal.sub(maxcap);
                weiAmount = maxcap.sub(weiRaisedTotal);
            }
    
            uint256 tokensAmount = weiAmount.mul(exchangeRateIco);
    
            if (tokensAmount > tokensRemainingIco) {
                uint256 weiToAccept = tokensRemainingIco.div(exchangeRateIco);
                excessiveFunds = excessiveFunds.add(weiAmount.sub(weiToAccept));
                
                tokensAmount = tokensRemainingIco;
                weiAmount = weiToAccept;
            }
    
            investments[msg.sender] = investments[msg.sender].add(weiAmount);
    
            tokensSoldIco = tokensSoldIco.add(tokensAmount);
            tokensSoldTotal = tokensSoldTotal.add(tokensAmount);
            tokensRemainingIco = tokensRemainingIco.sub(tokensAmount);
    
            weiRaisedIco = weiRaisedIco.add(weiAmount);
            weiRaisedTotal = weiRaisedTotal.add(weiAmount);
    
            token.transferFromIco(msg.sender, tokensAmount);
    
            if (excessiveFunds > 0) {
                msg.sender.transfer(excessiveFunds);
            }
        }
    
        /**
        * @dev Send raised funds to the withdrawal wallet.
        */
        function forwardFunds() onlyOwner public {
            require(weiRaisedTotal >= mincap);
            withdrawalWallet.transfer(this.balance);
        }
    
        /**
        * @dev Calculate token exchange rate for pre-ICO and ICO.
        * @dev Only applies when the pre-ICO was ended.
        * @dev May be called only once.
        */
        function calcTokenRate() whenPreIcoSaleHasEnded onlyOwner public {
            require(!isTokenRateCalculated);
            require(weiRaisedPreIco > 0);
    
            exchangeRatePreIco = HARDCAP_TOKENS_PRE_ICO.div(weiRaisedPreIco);
    
            exchangeRateIco = exchangeRatePreIco.div(2);
    
            isTokenRateCalculated = true;
        }
    
        /**
        * @dev Distribute tokens to pre-ICO investors using pagination.
        * @dev Pagination proceeds the set value (paginationCount) of tokens distributions per one function call.
        * @param _paginationCount The value that used for pagination.
        */
        function distributeTokensPreIco(uint256 _paginationCount) onlyOwner public {
            require(isTokenRateCalculated && !isTokensPreIcoDistributed);
            require(_paginationCount > 0);
    
            uint256 count = 0;
            for (uint256 i = distributionPreIcoCount; i < getPreIcoInvestorsCount(); i++) {
                if (count == _paginationCount) {
                    break;
                }
                uint256 investment = getPreIcoInvestment(getPreIcoInvestor(i));
                uint256 tokensAmount = investment.mul(exchangeRatePreIco);
                
                tokensSoldTotal = tokensSoldTotal.add(tokensAmount);
    
                token.transferFromIco(getPreIcoInvestor(i), tokensAmount);
    
                count++;
            }
    
            distributionPreIcoCount = distributionPreIcoCount.add(count);
    
            if (distributionPreIcoCount == getPreIcoInvestorsCount()) {
                isTokensPreIcoDistributed = true;
            }
        }
    
        /**
        * @dev Burn unsold tokens from the ICO balance.
        * @dev Only applies when the ICO was ended.
        */
        function burnUnsoldTokens() whenIcoSaleHasEnded onlyOwner public {
            require(tokensRemainingIco > 0);
            token.burnFromIco();
            tokensRemainingIco = 0;
        }
    
        /**
        * @dev Count the pre-ICO investors total.
        */
        function getPreIcoInvestorsCount() constant public returns (uint256) {
            return investorsPreIco.length;
        }
    
        /**
        * @dev Get the pre-ICO investor address.
        * @param _index the index of investor in the array. 
        */
        function getPreIcoInvestor(uint256 _index) constant public returns (address) {
            return investorsPreIco[_index];
        }
    
        /**
        * @dev Gets the amount of tokens for pre-ICO investor.
        * @param _investorPreIco the pre-ICO investor address.
        */
        function getPreIcoInvestment(address _investorPreIco) constant public returns (uint256) {
            return investmentsPreIco[_investorPreIco];
        }
    
        /**
        * @dev Set start time and end time for ICO.
        * @dev Only applies when tokens distributions to pre-ICO investors were processed.
        * @param _startTimeIco The ICO start time.
        * @param _endTimeIco The ICO end time.
        */
        function setStartTimeIco(uint256 _startTimeIco, uint256 _endTimeIco) whenPreIcoSaleHasEnded beforeReachingHardCap onlyOwner public {
            require(_startTimeIco >= now && _endTimeIco > _startTimeIco);
            require(isTokenRateCalculated);
    
            startTimeIco = _startTimeIco;
            endTimeIco = _endTimeIco;
        }
    
        /**
        * @dev Add new investment to the pre-ICO investments storage.
        * @param _from The address of a pre-ICO investor.
        * @param _value The investment received from a pre-ICO investor.
        */
        function addInvestmentPreIco(address _from, uint256 _value) internal {
            if (investmentsPreIco[_from] == 0) {
                investorsPreIco.push(_from);
            }
            investmentsPreIco[_from] = investmentsPreIco[_from].add(_value);
        }  
    }