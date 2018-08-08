pragma solidity ^0.4.21;

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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
        emit Transfer(msg.sender, _to, _value);
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
        emit Transfer(_from, _to, _value);
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
        emit Approval(msg.sender, _spender, _value);
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
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}

contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will receive the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}


contract APOToken is MintableToken {
    string public name = "Advanced Parimutuel Options";
    string public symbol = "APO";
    uint8 public decimals = 18;
}

contract TokenTimelock {
    
    using SafeERC20 for ERC20Basic;

    // ERC20 basic token contract being held
    ERC20Basic public token;

    // beneficiary of tokens after they are released
    address public beneficiary;

    // timestamp when token release is enabled
    uint256 public releaseTime;
    
    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
        require(_releaseTime > now);
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
    * @notice Transfers tokens held by timelock to beneficiary.
    */
    function release() public {
        require(now >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
    
}

contract RefundVault is Ownable {
    using SafeMath for uint256;   
    
    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;
    //  
     
    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    
     
    /**
    * @param _wallet Vault address
    */
    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }
    
    /**
    * @param investor Investor address
    */
    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }
    
    function close() onlyOwner public  {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(address(this).balance); // check
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    /**
    * @param investor Investor address
    */
    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
     
}

contract Crowdsale {
    
  using SafeMath for uint256;
  
    // The token being sold
    ERC20 public token;

    // Address where funds are collected
    address public wallet;

    // How many token units a buyer gets per wei
    uint256 public rate;

    // Amount of wei raised
    uint256 public weiRaised;
    
    
   /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public 
    {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
    }
  
    // -----------------------------------------
    // Crowdsale external interface
    // -----------------------------------------

   /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
        buyTokens(msg.sender);
    }
    
   /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) public payable {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        
        _forwardFunds();
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------


    /**
    * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
    }


    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.transfer(_beneficiary, _tokenAmount);
    }


    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }


    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 etherAmount = _weiAmount.mul(rate).div(1 ether);
        return etherAmount;
    }


    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }
    
}

contract APOTokenCrowdsale is Ownable, Crowdsale  {

    // The token being sold
    APOToken public token = new APOToken();
    
    // Locked Tokens for 12 month
    TokenTimelock public teamTokens;
    TokenTimelock public reserveTokens;
    
    // Address where funds are collected
    address public wallet;
    
    // Address of ither wallets
    address public bountyWallet;
    
    address public privateWallet;
    
    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault = new RefundVault(msg.sender);

    // How many token units a buyer gets per wei
    uint256 public rate = 15000;

    // ICO start time
    uint256 public startTime = 1524650400;
    
    // ICO end time
    uint256 public endTime = 1527069599;
    
    // Min Amount for Purchase
    uint256 public minAmount = 0.1 * 1 ether;
    
    // Soft Cap
    uint256 public softCap = 5500 * 1 ether;
    
    // Hard Cap
    uint256 public hardCap = 12700 * 1 ether;
    
    // Unlock Date
    uint256 public unlockTime = endTime + 1 years;
    
    // Discount
    uint256 public discountPeriod =  1 weeks;
         
    // Finished
    bool public isFinalized = false;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event Finalized();

    modifier onlyWhileOpen {
        require(now >= startTime && now <= endTime);
        _;
    }
    
    // Initial function
    function APOTokenCrowdsale() public
    Crowdsale(rate, vault, token) 
    {
        wallet = msg.sender;
        bountyWallet = 0x06F05ebdf3b871813f80C4A1744e66357B0d9e44;
        privateWallet = 0xb62109986F19f710415e71F27fAaF4ece89eFf83;
        teamTokens = new TokenTimelock(token, msg.sender, unlockTime);
        reserveTokens = new TokenTimelock(token, 0x2700C56A67F12899a4CB9316ab6541d90EcE52E9, unlockTime);
    }


    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(_weiAmount >= minAmount);
        require(weiRaised.add(_weiAmount) <= hardCap);
    }
    

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        // Calculate discount rate
        if (now <= startTime + 1 * discountPeriod) {
            _tokenAmount = _tokenAmount.mul(125).div(100);
        } else if ((now > startTime + 1 * discountPeriod) && (now <= startTime + 2 * discountPeriod))  {
            _tokenAmount = _tokenAmount.mul(115).div(100);
        } else if ((now > startTime + 2 * discountPeriod) && (now <= startTime + 3 * discountPeriod))  {
            _tokenAmount = _tokenAmount.mul(105).div(100);
        }
        
        // Mint token for contributor
        token.mint(_beneficiary, _tokenAmount);
    }


    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }


    /**
    * @dev Checks whether the cap has been reached. 
    * @return Whether the cap was reached
    */
    function capReached() public view returns (bool) {
        return weiRaised >= hardCap;
    }


    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract&#39;s finalization function.
    */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasClosed());
        
        // Finalize
        finalization();
        emit Finalized();

        isFinalized = true;
    }


    /**
    * @dev Can be overridden to add finalization logic. The overriding function
    * should call super.finalization() to ensure the chain of finalization is
    * executed entirely.
    */
    function finalization() internal {
        // 
        if (goalReached()) {
            
            vault.close();
            
            // For team - 20%, reserve - 25%, bounty - 5%, private investors - 10%
            uint issuedTokenSupply = token.totalSupply();
            uint teamPercent = issuedTokenSupply.mul(20).div(40);
            uint reservePercent = issuedTokenSupply.mul(25).div(40);
            uint bountyPercent = issuedTokenSupply.mul(5).div(40);
            uint privatePercent = issuedTokenSupply.mul(10).div(40);   
            
            // Mint
            token.mint(teamTokens, teamPercent);
            token.mint(reserveTokens, reservePercent);
            token.mint(bountyWallet, bountyPercent);
            token.mint(privateWallet, privatePercent);
            
            // Finish minting
            token.finishMinting();
            
        } else {
            vault.enableRefunds();
            // Finish minting
            token.finishMinting();
        }
        
    }


    /**
    * @dev Checks whether the period in which the crowdsale is open has already elapsed.
    * @return Whether crowdsale period has elapsed
    */
    function hasClosed() public view returns (bool) {
        return now > endTime;
    }


    /**
    * @dev Investors can claim refunds here if crowdsale is unsuccessful
    */
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }
    

    /**
    * @dev Checks whether funding goal was reached. 
    * @return Whether funding goal was reached
    */
    function goalReached() public view returns (bool) {
        return weiRaised >= softCap;
    }

}