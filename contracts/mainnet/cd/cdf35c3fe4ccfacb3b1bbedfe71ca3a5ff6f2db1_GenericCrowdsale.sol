pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ContractReceiver {
     
    struct TKN {
        address sender;
        uint value;
        bytes data;
        bytes4 sig;
    }
    
    
    function tokenFallback(address _from, uint _value, bytes _data) public pure {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
      
      /* tkn variable is analogue of msg variable of Ether transaction
      *  tkn.sender is person who initiated this token transaction   (analogue of msg.sender)
      *  tkn.value the number of tokens that were sent   (analogue of msg.value)
      *  tkn.data is data of token transaction   (analogue of msg.data)
      *  tkn.sig is 4 bytes signature of function
      *  if data of token transaction is a function execution
      */
    }
}

contract StandardToken is ERC223 {
    using SafeMath for uint;

    //user token balances
    mapping (address => uint) balances;
    //token transer permissions
    mapping (address => mapping (address => uint)) allowed;

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = balanceOf(msg.sender).sub(_value);
            balances[_to] = balanceOf(_to).add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            Transfer(msg.sender, _to, _value);
            return true;
        }
        else {
            return transferToAddress(_to, _value);
        }
    }
    

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
          
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value);
        }
    }
      
    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) public returns (bool success) {
          
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value);
        }
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
      
      //function that is called when transaction target is a contract
      function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Token transfer from from to _to (permission needed)
     */
    function transferFrom(
        address _from, 
        address _to,
        uint _value
    ) 
        public 
        returns (bool)
    {
        if (balanceOf(_from) < _value && allowance(_from, msg.sender) < _value) revert();

        bytes memory empty;
        balances[_to] = balanceOf(_to).add(_value);
        balances[_from] = balanceOf(_from).sub(_value);
        allowed[_from][msg.sender] = allowance(_from, msg.sender).sub(_value);
        if (isContract(_to)) {
            ContractReceiver receiver = ContractReceiver(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * Increase permission for transfer
     */
    function increaseApproval(
        address spender,
        uint value
    )
        public
        returns (bool) 
    {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(value);
        return true;
    }

    /**
     * Decrease permission for transfer
     */
    function decreaseApproval(
        address spender,
        uint value
    )
        public
        returns (bool) 
    {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(value);
        return true;
    }

    /**
     * User token balance
     */
    function balanceOf(
        address owner
    ) 
        public 
        constant 
        returns (uint) 
    {
        return balances[owner];
    }

    /**
     * User transfer permission
     */
    function allowance(
        address owner, 
        address spender
    )
        public
        constant
        returns (uint remaining)
    {
        return allowed[owner][spender];
    }
}

contract MyDFSToken is StandardToken {

    string public name = "MyDFS Token";
    uint8 public decimals = 6;
    string public symbol = "MyDFS";
    string public version = &#39;H1.0&#39;;
    uint256 public totalSupply;

    function () external {
        revert();
    } 

    function MyDFSToken() public {
        totalSupply = 125 * 1e12;
        balances[msg.sender] = totalSupply;
    }

    // Function to access name of token .
    function name() public view returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply;
    }
}

contract Ownable {
    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed _by, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() { require(msg.sender == owner); _;}

    /// Proposes to transfer control of the contract to a newOwnerCandidate.
    /// @param _newOwnerCandidate address The address to transfer ownership to.
    function transferOwnership(address _newOwnerCandidate) external onlyOwner {
        require(_newOwnerCandidate != address(0));

        newOwnerCandidate = _newOwnerCandidate;

        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /// Accept ownership transfer. This method needs to be called by the perviously proposed owner.
    function acceptOwnership() external {
        if (msg.sender == newOwnerCandidate) {
            owner = newOwnerCandidate;
            newOwnerCandidate = address(0);

            OwnershipTransferred(owner, newOwnerCandidate);
        }
    }
}

contract DevTokensHolder is Ownable {
    using SafeMath for uint256;

    uint256 collectedTokens;
    GenericCrowdsale crowdsale;
    MyDFSToken token;

    event ClaimedTokens(address token, uint256 amount);
    event TokensWithdrawn(address holder, uint256 amount);
    event Debug(uint256 amount);

    function DevTokensHolder(address _crowdsale, address _token, address _owner) public {
        crowdsale = GenericCrowdsale(_crowdsale);
        token = MyDFSToken(_token);
        owner = _owner;
    }

    function tokenFallback(
        address _from, 
        uint _value, 
        bytes _data
    ) 
        public 
        view 
    {
        require(_from == owner || _from == address(crowdsale));
        require(_value > 0 || _data.length > 0);
    }

    /// @notice The Dev (Owner) will call this method to extract the tokens
    function collectTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        uint256 total = collectedTokens.add(balance);

        uint256 finalizedTime = crowdsale.finishTime();
        require(finalizedTime > 0 && getTime() > finalizedTime.add(14 days));

        uint256 canExtract = total.mul(getTime().sub(finalizedTime)).div(months(12));
        canExtract = canExtract.sub(collectedTokens);

        if (canExtract > balance) {
            canExtract = balance;
        }

        collectedTokens = collectedTokens.add(canExtract);
        require(token.transfer(owner, canExtract));
        TokensWithdrawn(owner, canExtract);
    }

    function months(uint256 m) internal pure returns (uint256) {
        return m.mul(30 days);
    }

    function getTime() internal view returns (uint256) {
        return now;
    }

    //////////
    // Safety Methods
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(token));
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        token = MyDFSToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, balance);
    }
}

contract AdvisorsTokensHolder is Ownable {
    using SafeMath for uint256;

    GenericCrowdsale crowdsale;
    MyDFSToken token;

    event ClaimedTokens(address token, uint256 amount);
    event TokensWithdrawn(address holder, uint256 amount);

    function AdvisorsTokensHolder(address _crowdsale, address _token, address _owner) public {
        crowdsale = GenericCrowdsale(_crowdsale);
        token = MyDFSToken(_token);
        owner = _owner;
    }

    function tokenFallback(
        address _from, 
        uint _value, 
        bytes _data
    ) 
        public 
        view 
    {
        require(_from == owner || _from == address(crowdsale));
        require(_value > 0 || _data.length > 0);
    }

    /// @notice The Dev (Owner) will call this method to extract the tokens
    function collectTokens() public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0);

        uint256 finalizedTime = crowdsale.finishTime();
        require(finalizedTime > 0 && getTime() > finalizedTime.add(14 days));

        require(token.transfer(owner, balance));
        TokensWithdrawn(owner, balance);
    }

    function getTime() internal view returns (uint256) {
        return now;
    }

    //////////
    // Safety Methods
    //////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    /// @param _token The address of the token contract that you want to recover
    ///  set to 0 in case you want to extract ether.
    function claimTokens(address _token) public onlyOwner {
        require(_token != address(token));
        if (_token == 0x0) {
            owner.transfer(this.balance);
            return;
        }

        token = MyDFSToken(_token);
        uint256 balance = token.balanceOf(this);
        token.transfer(owner, balance);
        ClaimedTokens(_token, balance);
    }
}

contract GenericCrowdsale is Ownable {
    using SafeMath for uint256;

    //Crowrdsale states
    enum State { Initialized, PreIco, PreIcoFinished, Ico, IcoFinished}

    struct Discount {
        uint256 amount;
        uint256 value;
    }

    //ether trasfered to
    address public beneficiary;
    //Crowrdsale state
    State public state;
    //Hard goal in Wei
    uint public hardFundingGoal;
    //soft goal in Wei
    uint public softFundingGoal;
    //gathered Ether amount in Wei
    uint public amountRaised;
    //ICO/PreICO start timestamp in seconds
    uint public started;
    //Crowdsale finish time
    uint public finishTime;
    //price for 1 token in Wei
    uint public price;
    //minimum purchase value in Wei
    uint public minPurchase;
    //Token cantract
    ERC223 public tokenReward;
    //Wei balances for refund if ICO failed
    mapping(address => uint256) public balances;

    //Emergency stop sell
    bool emergencyPaused = false;
    //Soft cap reached
    bool softCapReached = false;
    //dev holder
    DevTokensHolder public devTokensHolder;
    //advisors holder
    AdvisorsTokensHolder public advisorsTokensHolder;
    
    //Disconts
    Discount[] public discounts;

    //price overhead for next stages
    uint8[2] public preIcoTokenPrice = [70,75];
    //price overhead for next stages
    uint8[4] public icoTokenPrice = [100,120,125,130];

    event TokenPurchased(address investor, uint sum, uint tokensCount, uint discountTokens);
    event PreIcoLimitReached(uint totalAmountRaised);
    event SoftGoalReached(uint totalAmountRaised);
    event HardGoalReached(uint totalAmountRaised);
    event Debug(uint num);

    //Sale is active
    modifier sellActive() { 
        require(
            !emergencyPaused 
            && (state == State.PreIco || state == State.Ico)
            && amountRaised < hardFundingGoal
        );
    _; }
    //Soft cap not reached
    modifier goalNotReached() { require(state == State.IcoFinished && amountRaised < softFundingGoal); _; }

    /**
     * Constrctor function
     */
    function GenericCrowdsale(
        address ifSuccessfulSendTo,
        address addressOfTokenUsedAsReward
    ) public {
        require(ifSuccessfulSendTo != address(0) 
            && addressOfTokenUsedAsReward != address(0));
        beneficiary = ifSuccessfulSendTo;
        tokenReward = ERC223(addressOfTokenUsedAsReward);
        state = State.Initialized;
    }

    function tokenFallback(
        address _from, 
        uint _value, 
        bytes _data
    ) 
        public 
        view 
    {
        require(_from == owner);
        require(_value > 0 || _data.length > 0);
    }

    /**
     * Start PreICO
     */
    function preIco(
        uint hardFundingGoalInEthers,
        uint minPurchaseInFinney,
        uint costOfEachToken,
        uint256[] discountEthers,
        uint256[] discountValues
    ) 
        external 
        onlyOwner 
    {
        require(hardFundingGoalInEthers > 0
            && costOfEachToken > 0
            && state == State.Initialized
            && discountEthers.length == discountValues.length);

        hardFundingGoal = hardFundingGoalInEthers.mul(1 ether);
        minPurchase = minPurchaseInFinney.mul(1 finney);
        price = costOfEachToken;
        initDiscounts(discountEthers, discountValues);
        state = State.PreIco;
        started = now;
    }

    /**
     * Start ICO
     */
    function ico(
        uint softFundingGoalInEthers,
        uint hardFundingGoalInEthers,
        uint minPurchaseInFinney,
        uint costOfEachToken,
        uint256[] discountEthers,
        uint256[] discountValues
    ) 
        external
        onlyOwner
    {
        require(softFundingGoalInEthers > 0
            && hardFundingGoalInEthers > 0
            && hardFundingGoalInEthers > softFundingGoalInEthers
            && costOfEachToken > 0
            && state < State.Ico
            && discountEthers.length == discountValues.length);

        softFundingGoal = softFundingGoalInEthers.mul(1 ether);
        hardFundingGoal = hardFundingGoalInEthers.mul(1 ether);
        minPurchase = minPurchaseInFinney.mul(1 finney);
        price = costOfEachToken;
        delete discounts;
        initDiscounts(discountEthers, discountValues);
        state = State.Ico;
        started = now;
    }

    /**
     * Finish ICO / PreICO
     */
    function finishSale() external onlyOwner {
        require(state == State.PreIco || state == State.Ico);
        
        if (state == State.PreIco)
            state = State.PreIcoFinished;
        else
            state = State.IcoFinished;
    }

    /**
     * Admin can pause token sell
     */
    function emergencyPause() external onlyOwner {
        emergencyPaused = true;
    }

    /**
     * Admin can unpause token sell
     */
    function emergencyUnpause() external onlyOwner {
        emergencyPaused = false;
    }

    /**
     * Transfer dev tokens to vesting wallet
     */
    function sendDevTokens() external onlyOwner returns(address) {
        require(successed());

        devTokensHolder = new DevTokensHolder(address(this), address(tokenReward), owner);
        tokenReward.transfer(address(devTokensHolder), 12500 * 1e9);
        return address(devTokensHolder);
    }

    /**
     * Transfer dev tokens to vesting wallet
     */
    function sendAdvisorsTokens() external onlyOwner returns(address) {
        require(successed());

        advisorsTokensHolder = new AdvisorsTokensHolder(address(this), address(tokenReward), owner);
        tokenReward.transfer(address(advisorsTokensHolder), 12500 * 1e9);
        return address(advisorsTokensHolder);
    }

    /**
     * Admin can withdraw ether beneficiary address
     */
    function withdrawFunding() external onlyOwner {
        require((state == State.PreIco || successed()));
        beneficiary.transfer(this.balance);
    }

    /**
     * Different coins purchase
     */
    function foreignPurchase(address user, uint256 amount)
        external
        onlyOwner
        sellActive
    {
        buyTokens(user, amount);
        checkGoals();
    }

    /**
     * Claim refund ether in soft goal not reached 
     */
    function claimRefund() 
        external 
        goalNotReached 
    {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        if (amount > 0){
            if (!msg.sender.send(amount)) {
                balances[msg.sender] = amount;
            }
        }
    }

    /**
     * Payment transaction
     */
    function () 
        external 
        payable 
        sellActive
    {
        require(msg.value > 0);
        require(msg.value >= minPurchase);
        uint amount = msg.value;
        if (amount > hardFundingGoal.sub(amountRaised)) {
            uint availableAmount = hardFundingGoal.sub(amountRaised);
            msg.sender.transfer(amount.sub(availableAmount));
            amount = availableAmount;
        }

        buyTokens(msg.sender,  amount);
        checkGoals();
    }

    /**
     * Transfer tokens to user
     */
    function buyTokens(
        address user,
        uint256 amount
    ) internal {
        require(amount <= hardFundingGoal.sub(amountRaised));

        uint256 passedSeconds = getTime().sub(started);
        uint256 week = 0;
        if (passedSeconds >= 604800){
            week = passedSeconds.div(604800);
        }
        Debug(week);

        uint256 tokenPrice;
        if (state == State.Ico){
            uint256 cup = amountRaised.mul(4).div(hardFundingGoal);
            if (cup > week)
                week = cup;
            if (week >= 4)
                 week = 3;
            tokenPrice = price.mul(icoTokenPrice[week]).div(100);
        } else {
            if (week >= 2)
                 week = 1;
            tokenPrice = price.mul(preIcoTokenPrice[week]).div(100);
        }

        Debug(tokenPrice);

        uint256 count = amount.div(tokenPrice);
        uint256 discount = getDiscountOf(amount);
        uint256 discountBonus = discount.mul(count).div(100);
        count = count.add(discountBonus);
        count = ceilTokens(count);

        require(tokenReward.transfer(user, count));
        balances[user] = balances[user].add(amount);
        amountRaised = amountRaised.add(amount);
        TokenPurchased(user, amount, count, discountBonus);
    }

    /**
     * Define distount percents for different token amounts
     */
    function ceilTokens(
        uint256 num
    ) 
        public
        pure
        returns(uint256) 
    {
        uint256 part = num % 1000000;
        return part > 0 ? num.div(1000000).mul(1000000) + 1000000 : num;
    }

    /**
     * ICO is finished successfully
     */
    function successed() 
        public 
        view 
        returns(bool) 
    {
        return state == State.IcoFinished && amountRaised >= softFundingGoal;
    }

    /**
     * Define distount percents for different token amounts
     */
    function initDiscounts(
        uint256[] discountEthers,
        uint256[] discountValues
    ) internal {
        for (uint256 i = 0; i < discountEthers.length; i++) {
            discounts.push(Discount(discountEthers[i].mul(1 ether), discountValues[i]));
        }
    }

    /**
     * Get discount percent for number of tokens
     */
    function getDiscountOf(
        uint256 _amount
    )
        public
        view
        returns (uint256)
    {
        if (discounts.length > 0)
            for (uint256 i = 0; i < discounts.length; i++) {
                if (_amount >= discounts[i].amount) {
                    return discounts[i].value;
                }
            }
        return 0;
    }

    /**
     * Check ICO goals achievement
     */
    function checkGoals() internal {
        if (state == State.PreIco) {
            if (amountRaised >= hardFundingGoal) {
                PreIcoLimitReached(amountRaised);
                state = State.PreIcoFinished;
            }
        } else {
            if (!softCapReached && amountRaised >= softFundingGoal){
                softCapReached = true;
                SoftGoalReached(amountRaised);
            }
            if (amountRaised >= hardFundingGoal) {
                finishTime = now;
                HardGoalReached(amountRaised);
                state = State.IcoFinished;
            }
        }
    }

    function getTime() internal view returns (uint) {
        return now;
    }
}