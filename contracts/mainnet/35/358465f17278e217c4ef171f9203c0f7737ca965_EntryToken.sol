pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

/**
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time
 */
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

  // ERC20 basic token contract being held
  ERC20Basic public token;

  // beneficiary of tokens after they are released
  address public beneficiary;

  // timestamp when token release is enabled
  uint256 public releaseTime;

  function TokenTimelock(ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
    // solium-disable-next-line security/no-block-members
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

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
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract EntryToken is StandardToken, Ownable {
    string public constant name = "Entry Token";
    string public constant symbol = "ENTRY";
    uint8 public constant decimals = 18;

    /// Maximum tokens to be allocated on the sale (55% of the hard cap)
    uint256 public constant TOKENS_SALE_HARD_CAP = 325000000000000000000000000; // 325000000 * 10**18

    /// Base exchange rate is set to 1 ETH = 6000 ENTRY.
    uint256 public constant BASE_RATE = 6000;

    /// pre sale start 03.05.2018
    uint256 private constant datePreSaleStart = 1525294800;
    
    /// pre sale end time 11.05.2018
    uint256 private constant datePreSaleEnd = 1525986000;

    /// sale start time 01.06.2018
    uint256 private constant dateSaleStart = 1527800400;

    /// sale end time 01.09.2018
    uint256 private constant dateSaleEnd = 1535749200;

    
    /// pre-sale token cap
    uint256 private preSaleCap = 75000000000000000000000000; // Pre-sale  75000000 * 10**18
    
    /// token caps for each round
    uint256[25] private stageCaps = [
        85000000000000000000000000	, // Stage 1   85000000 * 10**18
        95000000000000000000000000	, // Stage 2   95000000 * 10**18
        105000000000000000000000000	, // Stage 3   105000000 * 10**18
        115000000000000000000000000	, // Stage 4   115000000 * 10**18
        125000000000000000000000000	, // Stage 5   125000000 * 10**18
        135000000000000000000000000	, // Stage 6   135000000 * 10**18
        145000000000000000000000000	, // Stage 7   145000000 * 10**18
        155000000000000000000000000	, // Stage 8   155000000 * 10**18
        165000000000000000000000000	, // Stage 9   165000000 * 10**18
        175000000000000000000000000	, // Stage 10   175000000 * 10**18
        185000000000000000000000000	, // Stage 11   185000000 * 10**18
        195000000000000000000000000	, // Stage 12   195000000 * 10**18
        205000000000000000000000000	, // Stage 13   205000000 * 10**18
        215000000000000000000000000	, // Stage 14   215000000 * 10**18
        225000000000000000000000000	, // Stage 15   225000000 * 10**18
        235000000000000000000000000	, // Stage 16   235000000 * 10**18
        245000000000000000000000000	, // Stage 17   245000000 * 10**18
        255000000000000000000000000	, // Stage 18   255000000 * 10**18
        265000000000000000000000000	, // Stage 19   265000000 * 10**18
        275000000000000000000000000	, // Stage 20   275000000 * 10**18
        285000000000000000000000000	, // Stage 21   285000000 * 10**18
        295000000000000000000000000	, // Stage 22   295000000 * 10**18
        305000000000000000000000000	, // Stage 23   305000000 * 10**18
        315000000000000000000000000	, // Stage 24   315000000 * 10**18
        325000000000000000000000000   // Stage 25   325000000 * 10**18
    ];
    /// tokens rate for each round
    uint8[25] private stageRates = [15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 27, 
                        28, 29, 30, 31, 33, 34, 35, 36, 37, 40, 41, 42, 43, 44];

    uint64 private constant dateTeamTokensLockedTill = 1630443600;
   
    bool public tokenSaleClosed = false;

    address public timelockContractAddress;


    function isPreSalePeriod() public constant returns (bool) {
        if(totalSupply > preSaleCap || now >= datePreSaleEnd) {
            return false;
        } else {
            return now > datePreSaleStart;
        }
    }


    function isICOPeriod() public constant returns (bool) {
        if (totalSupply > TOKENS_SALE_HARD_CAP || now >= dateSaleEnd){
            return false;
        } else {
            return now > dateSaleStart;
        }
    }

    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP && !tokenSaleClosed && now >= datePreSaleStart);
        _;
    }


    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }


    modifier canBeTraded {
        require(tokenSaleClosed);
        _;
    }


    function EntryToken() public {
    	/// generate private investor tokens 
    	generateTokens(owner, 50000000000000000000000000); // 50000000 * 10**18
    }


    function () public payable inProgress {
        if(isPreSalePeriod()){
            buyPreSaleTokens(msg.sender);
        } else if (isICOPeriod()){
            buyTokens(msg.sender);
        }			
    } 
    

    function buyPreSaleTokens(address _beneficiary) internal {
        require(msg.value >= 0.01 ether);
        uint256 tokens = getPreSaleTokenAmount(msg.value);
        require(totalSupply.add(tokens) <= preSaleCap);
        generateTokens(_beneficiary, tokens);
        owner.transfer(address(this).balance);
    }
    
    
    function buyTokens(address _beneficiary) internal {
        require(msg.value >= 0.01 ether);
        uint256 tokens = getTokenAmount(msg.value);
        require(totalSupply.add(tokens) <= TOKENS_SALE_HARD_CAP);
        generateTokens(_beneficiary, tokens);
        owner.transfer(address(this).balance);
    }


    function getPreSaleTokenAmount(uint256 weiAmount)internal pure returns (uint256) {
        return weiAmount.mul(BASE_RATE);
    }
    
    
    function getTokenAmount(uint256 weiAmount) internal view returns (uint256 tokens) {
        uint256 tokenBase = weiAmount.mul(BASE_RATE);
        uint8 stageNumber = currentStageIndex();
        tokens = getStageTokenAmount(tokenBase, stageNumber);
        while(tokens.add(totalSupply) > stageCaps[stageNumber] && stageNumber < 24){
           stageNumber++;
           tokens = getStageTokenAmount(tokenBase, stageNumber);
        }
    }
    
    
    function getStageTokenAmount(uint256 tokenBase, uint8 stageNumber)internal view returns (uint256) {
    	uint256 rate = 10000000000000000000/stageRates[stageNumber];
    	uint256 base = tokenBase/1000000000000000000;
        return base.mul(rate);
    }
    
    
    function currentStageIndex() internal view returns (uint8 stageNumber) {
        stageNumber = 0;
        while(stageNumber < 24 && totalSupply > stageCaps[stageNumber]) {
            stageNumber++;
        }
    }
    
    
    function buyTokensOnInvestorBehalf(address _beneficiary, uint256 _tokens) public onlyOwner beforeEnd {
        generateTokens(_beneficiary, _tokens);
    }
    
    
    function buyTokensOnInvestorBehalfBatch(address[] _addresses, uint256[] _tokens) public onlyOwner beforeEnd {
        require(_addresses.length == _tokens.length);
        require(_addresses.length <= 100);

        for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
            generateTokens(_addresses[i], _tokens[i]);
        }
    }
    
    
    function generateTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));
        totalSupply = totalSupply.add(_tokens);
        balances[_beneficiary] = balances[_beneficiary].add(_tokens);
        emit Transfer(address(0), _beneficiary, _tokens);
    }


    function close() public onlyOwner beforeEnd {
        /// team tokens are equal to 5% of tokens
        uint256 lockedTokens = 16250000000000000000000000; // 16 250 000 * 10**18
        // partner tokens for advisors, bouties, SCO 40% of tokens
        uint256 partnerTokens = 260000000000000000000000; // 130 000 0000 * 10**18
        
        generateLockedTokens(lockedTokens);
        generatePartnerTokens(partnerTokens);
        
        totalSupply = totalSupply.add(lockedTokens+partnerTokens);

        tokenSaleClosed = true;

        owner.transfer(address(this).balance);
    }
    
    function generateLockedTokens( uint lockedTokens) internal{
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, dateTeamTokensLockedTill);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(lockedTokens);
        emit Transfer(address(0), timelockContractAddress, lockedTokens);
    }
    
    
    function generatePartnerTokens(uint partnerTokens) internal{
        balances[owner] = partnerTokens;
        emit Transfer(address(0), owner, partnerTokens);
    }
      
    
    function transferFrom(address _from, address _to, uint256 _value) public canBeTraded returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }


    function transfer(address _to, uint256 _value) public canBeTraded returns (bool) {
        return super.transfer(_to, _value);
    }
}