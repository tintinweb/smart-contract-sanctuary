pragma solidity ^0.4.23;

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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
// @notice ERC20 function for balance of the token
// @dev any token implementing the ERC20 standard will be compatible
contract TokenBalance {
    function balanceOf(address) external returns (uint256) {}
}
// @title TokenMethods is a library of token related functions 
library TokenMethods {

    // @dev returns balance of the specified ERC20 token for this contract/address
    // @param _token address of the ERC20 token
    function balanceThis(address _token) public returns (uint256) {
        return TokenBalance(_token).balanceOf(address(this));
    }

    // @dev returns balance of the specified ERC20 token for this the function caller
    // @param _token address of the ERC20 token
    function balanceSender(address _token) public returns (uint256) {
        return balanceAddress(_token, msg.sender);
    }

    // @dev returns balance of the specified ERC20 token for the specified tokenHolder
    // @dev alternatively, the _token contract itself could be called to get this data
    // @param _token address of the ERC20 token
    // @param _tokenHolder address of the ERC20 tokenHolder
    function balanceAddress(address _token, address _tokenHolder) public returns (uint256) {
        return (TokenBalance(_token).balanceOf(_tokenHolder));
    }

}



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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
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
     * @title TestTokenERC20
     * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
     * Note they can later distribute these tokens as they wish using `transfer` and other
     * `StandardToken` functions.
     */
contract TestTokenERC20 is StandardToken {

    string public constant NAME = &quot;TestTokenERC20&quot;; // solium-disable-line uppercase
    string public constant SYMBOL = &quot;T20&quot;; // solium-disable-line uppercase
    uint8 public constant DECIMALS = 18; // solium-disable-line uppercase
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(DECIMALS));

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

    /**
     * @notice get some tokens to use for testing purposes
     * @dev mints some tokens to the function caller
     */
    function giveMeTokens() public {
        balances[msg.sender] += INITIAL_SUPPLY;
        totalSupply_ += INITIAL_SUPPLY;
    }
}

///-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-TOKEN-UNION-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\\\
/**
 *  ______   ______     __  __     ______     __   __
 * /\__  _\ /\  __ \   /\ \/ /    /\  ___\   /\ &quot;-.\ \
 * \/_/\ \/ \ \ \/\ \  \ \  _&quot;-.  \ \  __\   \ \ \-.  \
 *    \ \_\  \ \_____\  \ \_\ \_\  \ \_____\  \ \_\\&quot;\_\
 *     \/_/   \/_____/   \/_/\/_/   \/_____/   \/_/ \/_/
 *     __  __     __   __     __     ______     __   __
 *    /\ \/\ \   /\ &quot;-.\ \   /\ \   /\  __ \   /\ &quot;-.\ \
 *    \ \ \_\ \  \ \ \-.  \  \ \ \  \ \ \/\ \  \ \ \-.  \
 *     \ \_____\  \ \_\\&quot;\_\  \ \_\  \ \_____\  \ \_\\&quot;\_\
 *      \/_____/   \/_/ \/_/   \/_/   \/_____/   \/_/ \/_/
 *
 *
 * @title TokenUnion
 * @author tokenunion.io
 */
///-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\\\



///-=-=-=-=-=-=-=-=-=-=-=-TOKEN-UNION-CONTRACT-=-=-=-=-=-=-=-=-=-=-=-\\\

contract TokenUnion {

    using SafeMath for *;
    uint256 public FEE_RATIO = PPB.mul(25).div(1000);
    uint256 public constant TOKEN_DECIMALS = 18;
    uint8 public constant TOKEN_DECIMALS_UINT8 = uint8(TOKEN_DECIMALS);
    uint256 public constant PPB = 10 ** TOKEN_DECIMALS;
    
    /**
     * @notice  Amount deposited per address for each supported token.
     * @dev     allows balance lookup for _user _token via balanceUserToken[_user][_token]
     */
    mapping(address => mapping(address => uint256)) public tokenBalance;

    /**
     * @notice  Total deposited tokens of supported tokens.
     * @dev     Mapping of total deposited tokens across users by token.
     */
    mapping(address => uint256) public balanceToken;

    /**
     * @notice  Total amount of fees for each supported token
     * @dev     Fees and rewards are synonomous but referred to as rewards here
     */
    mapping(address => uint256) public reward_ppb_total;

    /**
     * @notice  Remaining rewards following last withdrawal
     * @dev     Handles any leftover rewards at the final withdrawal
     */    
    mapping(address => uint256) public rewardRemainingPerToken;

    /**
     * @notice  Stores the total amount of rewards at the time of deposit for a user.
     * @dev     Fees and rewards are synonomous but referred to as rewards here
     */
    mapping(address => mapping(address => uint256)) public rewardInitialPerUserPerToken;

    /**
     * @notice  Nonce representing txn count for a particular token
     * @dev     Nonce for each token mapped to token address
     * @dev     This allows tracking across all tokens within one variable.
     */
    mapping(address => uint256) public nonce;
    
    /// Array of addresses for all deposited tokens
    address[] public tokens;

///-=-=-=-=-=-=-=-=-=-=-=-=-EVENTS-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\\\
    event DepositMade(address indexed user, uint value, address indexed token);
    event WithdrawalMade(address indexed user, uint value, address indexed token, uint fee, uint reward);


///-=-=-=-=-=-=-=-=-=-=-=-=-CONSTRUCTOR-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\\\
    constructor() public {

    }


///-=-=-=-=-=-=-=-=-=-=-=-=-CORE-FUNCTIONS-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\\\

    /**
     * @notice Deposit funds into contract.
     * @param _token address of the tokenContract for deposit
     * @dev the amount of deposit is determined by allowance of this contract
     */
    function depositToken(address _token) public returns(
        uint256 userReward,
        uint256 depositAmount,
        uint256 oldBalanceUser,
        uint256 newBalanceUser
    ) {
        require(_token != address(0));

        /// if token nonce is zero and has zero balance add to list of tokens
        if (balanceToken[_token] == 0 && nonce[_token] == 0) {
            tokens.push(_token);
        }

        /// address calling function is deemed to be the user
        address _user = msg.sender;

        /// compute current reward for the _user + _token at time of deposit
        uint256 reward = computeCurrentReward(_token, _user);
        
        /// create a token for method calls
        TestTokenERC20 token = TestTokenERC20(_token);

        /// Determine amount of deposit using allowance of this contract
        uint amount = TestTokenERC20(_token).allowance(_user, this);

        /// Determine current and updated _token balances for _user
        uint256 oldBalance = tokenBalance[_token][_user];
        uint256 newBalance = oldBalance.add(amount).add(reward);

        /// Transfer allowance of token from user to this contract
        require(token.transferFrom(_user, address(this), amount));

        /// Update user balance
        tokenBalance[_token][_user] = newBalance;

        /// update the total balance for the token
        balanceToken[_token] = balanceToken[_token].add((newBalance.sub(oldBalance)).div(PPB));
        
        /// mark starting term in reward series
        rewardInitialPerUserPerToken[_token][_user] = reward_ppb_total[_token];

        /// increase token nonce
        nonce[_token] += 1;

        /// Fire event and return some goodies
        emit DepositMade(msg.sender, amount, _token);
        return(reward, amount, oldBalance, newBalance);
    }


    // /**
    //  * @dev claimForDeposit uses the same mechanism as withdraw but is called internally
    //  * to prevent calculation errors for accounts that make multiple deposits of a token
    //  * @param _token address of the token for claim and deposit
    //  * @param _user address of the user
    //  */
    // function claimForDeposit(address _token, address _user) internal returns (uint256 claimForDepositAmount) {
    //     uint256 startingBalance = tokenBalance[_token][_user];
    //     uint256 fee = startingBalance.div(PPB).mul(FEE_RATIO);
    //     uint256 reward = computeCurrentReward(_token, _user);

    //     // reset user account
    //     tokenBalance[_token][_user] = 0;
    //     rewardInitialPerUserPerToken[_token][_user] = 0;
    //     balanceToken[_token] = balanceToken[_token].sub(startingBalance.div(PPB));

    //     return(startingBalance.sub(fee).add(reward));
    // }
    
    


    /**
     * @notice Withdraw balance of specified token
     * @dev determines withdraw amount by taking balance - fee + reward.
     * @param _token address of the token for withdrawal
     */
    function withdraw(address _token) public returns (bool) {
        address _user = msg.sender;
        require(tokenBalance[_token][_user] > 0);

        // init
        uint256 startingBalance = tokenBalance[_token][_user];
        uint256 fee = startingBalance.div(PPB).mul(FEE_RATIO); // all integer
        uint256 reward = computeCurrentReward(_token, _user);

        // clear user account
        tokenBalance[_token][_user] = 0;
        rewardInitialPerUserPerToken[_token][_user] = 0;
        balanceToken[_token] = balanceToken[_token].sub(startingBalance.div(PPB));

        // update total reward and remainder
        if (balanceToken[_token] > 0) {
            uint256 amount = fee.add(rewardRemainingPerToken[_token]);              // wei
            uint256 ratio = amount.div(balanceToken[_token]);             // 1/Gwei
            reward_ppb_total[_token] = reward_ppb_total[_token].add(ratio);
            rewardRemainingPerToken[_token] = amount % balanceToken[_token];      // wei
        } else {
            assert(balanceToken[_token] == 0);
            // special case for last withdrawal: no fee
            fee = 0;
            reward = reward.add(rewardRemainingPerToken[_token]);
            rewardRemainingPerToken[_token] = 0;
        }

        nonce[_token] += 1;
        uint256 send_amount = startingBalance.sub(fee).add(reward);

        TestTokenERC20 token = TestTokenERC20(_token);
        token.approve(this, 0); 
        if (token.approve(this, send_amount)) {
            return token.transferFrom(this, _user, send_amount);
        }

        // msg.sender.transfer(send_amount);

        emit WithdrawalMade(msg.sender, send_amount, _token, fee, reward);
        
        
    }

///-=-=-=-=-=-=-=-=-=-=-=-=-VIEW-FUNCTIONS-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-\\\

    /**
     * @dev returns an array of tokens that have been deposited
     */
    function getTokenList() public view returns (address[]) {
        uint256 length;
        length = tokens.length;
        address[] memory tokenList = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            tokenList[i] = tokens[i];
        }
        return (tokenList);
    }

    /**
     * @notice tokenX address + userY address <-IN + OUT-> INTERNAL ACCOUNT balance of tokenX for userY.
     * @dev returns the token balance of a user given the address of token and user
     * @param _token address is the address of the token contract
     * @param _user address is the address of the user account
     * @return uint256 balance of specified token for given user
     */
    function getUserAccountTokenBalance(address _token, address _user) public view returns (uint256) {
        uint256 balance = tokenBalance[_token][_user];
        return balance;
    }
    

    /**
     * @notice tokenX address + userY address <-IN + OUT-> EXTERNAL WALLET balance of tokenX for userY.
     * @dev returns the token balance of a user given the address of token and user
     * @param _token address is the address of the token contract
     * @param _user address is the address of the user account
     * @return uint256 balance of specified token for given user
     */
    function getUserWalletTokenBalance(address _token, address _user) public view returns (uint256) {
        uint256 balance = TokenMethods.balanceAddress(_token,_user);
        return balance;
    }


    function userWalletTokenBalances(address _user) public view returns (uint256[]) {
        uint256 tokenCount;
        tokenCount = tokens.length;
        uint[] memory walletHoldings = new uint[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            walletHoldings[i] = getUserWalletTokenBalance(tokens[i], _user);
        }
        return (walletHoldings);
    }

    /**
     * @notice user address <-IN + OUT-> array of token balances for user
     * @dev returns the balance of each token for a given user
     * @dev use in conjunction with getTokenList()
     * @param _user address of the user for whom token balances should be returned
     */
    function userAccountTokenBalances(address _user) public view returns (uint256[]) {
        uint256 tokenCount;
        tokenCount = tokens.length;
        uint[] memory tokenHoldings = new uint[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenHoldings[i] = getUserAccountTokenBalance(tokens[i],_user);
        }
        return (tokenHoldings);
    }

    /**
     * @notice Returns the token information for the user given a token address
     * @dev This function gets the internal and external wallet token balances
     * @param _token address of the token for balance retrieval
     * @param _user address of the user for token balances
     */ 
    function userTokenStats(address _token, address _user) public view returns (
        uint256 accountBalance,
        uint256 walletBalance,
        uint256 accruedRewards,
        uint256 feesOwed
    ) {
        uint256 fee = tokenBalance[_token][_user].div(PPB).mul(FEE_RATIO);
        uint256 reward = computeCurrentReward(_token, _user);
        uint256 wallet = getUserWalletTokenBalance(_token, _user);
        uint256 account = tokenBalance[_token][_user];
        return(account, wallet, reward, fee);
    }

    /**
     * @notice Returns the amount that would be sent by a real withdrawal.
     * @param _token address of the token for simulated withdrawal
     * @param _user address of the user for simulated token withdrawal
     */ 
    function simulatedWithdrawal(address _token, address _user) public view returns (
        uint256 _startingBalance,
        uint256 _reward,
        uint256 _fee,
        uint256 _tokenBalance
    ) {
        uint256 startingBalance = tokenBalance[_token][_user];
        uint256 fee = startingBalance.div(PPB).mul(FEE_RATIO);
        uint256 reward = computeCurrentReward(_token, _user);
        uint256 withdrawAmount = startingBalance.sub(fee).add(reward);
        return (startingBalance, reward, fee, withdrawAmount);
    }

    /**
     * @dev gets balance, reward, fee, and est withdrawal amount for a token
     * @param _token address of the token for calculation
     */
    function getUserAccountInfo(address _token) public view returns (
        uint256 _startingBalance,
        uint256 _reward,
        uint256 _fee,
        uint256 _tokenBalance) {
        address _user = msg.sender;
        return simulatedWithdrawal(_token, _user);
    }

    /**
     * @dev gets accountbalance, walletbalance, fee, and reward for a token
     * @param _token address of the token for data retrieval
     */
    function getUserTokenInfo(address _token) public view returns (
        uint256 accountBalance,
        uint256 walletBalance,
        uint256 accruedRewards,
        uint256 feesOwed) {
        address _user = msg.sender;
        return userTokenStats(_token, _user);
    }

    /**
     * @notice returns an array of token balances for the function caller
     * @dev simply calls userAccountTokenBalances() using msg.sender as input and
     * @dev returns an array of balances corresponding to getTokenList()
     * @return uint256[] array of token balances
     */
    function getMyTokenBalances() public view returns (uint256[], uint256[]) {
        address _user = msg.sender;
        return (userAccountTokenBalances(_user), userWalletTokenBalances(_user));
    }

    /**
     * @dev computes the current reward of _user for _token which is F(n) of calculated fees
     * @param _token address of the _user in computation
     * @param _user address of the token for calculation
     * @return uint256 
     */
    function computeCurrentReward(address _token, address _user) internal view returns (uint256) {
        uint256 reward_ppb = reward_ppb_total[_token].sub(rewardInitialPerUserPerToken[_token][_user]);
        return tokenBalance[_token][_user].mul(reward_ppb).div(PPB);
    }


    function () public payable {
        revert();
    }
}