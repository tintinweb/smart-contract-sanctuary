pragma solidity ^0.4.23;


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

    /**
    * @title Standard ERC20 token
    *
    * @dev Implementation of the basic standard token.
    * @dev https://github.com/ethereum/EIPs/issues/20
    * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
    */
    
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
    
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    uint256 public totalSupply_;

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

    /**
    * @title BnkTestToken
    * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
    * Note they can later distribute these tokens as they wish using `transfer` and other
    * `StandardToken` functions.
    * 
    */
    contract TestTokenERC20 is StandardToken {

    string public constant name = &quot;TestTokenERC20&quot;; // solium-disable-line uppercase
    string public constant symbol = &quot;T20&quot;; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor(TestTokenERC20) public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }


    function giveMeTokens() public {
        balances[msg.sender] += INITIAL_SUPPLY;
        totalSupply_ += INITIAL_SUPPLY;
    }
}


///-=-=-=-=-=-=-=-=-=-=-=-TOKEN-UNION-CONTRACT-=-=-=-=-=-=-=-=-=-=-=-\\\
/// @title TokenUnion
/// @author tokenunion.io
contract TokenUnion {

    using SafeMath for *;
    /// Helper for coversion to and from ETH
    // uint256 public constant PPB = 10**9;

    /// @notice Withdrawal fee percentage in units per billion. 2.5%.
    uint256 public constant FEE_RATIO = 25 * PPB / 1000;
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
     * @notice  Tracks whether a deposited token is new to the system or is not.
     */
    mapping(address => uint) public newToken;

    /// Array of addresses for all deposited tokens
    address[] public tokens;

    /**
     * Events -----------
     */
    event DepositMade(address _from, uint value, address _token);
    event WithdrawalMade(address _to, uint value, address token, uint fee, uint reward);


    /// Initialize the contract.
    constructor(TokenUnion) public {

    }

    
    /// @notice Deposit funds into contract.
    function depositToken(address _token) public returns(
        uint _reward,
        uint _amount,
        uint _oldBalance,
        uint _newBalance
    ) {
        if (_token != address(0) && balanceToken[_token] > 0) {
            tokens.push(_token);
            newToken[_token] = 0;
        }
        // if (msg.value < toWEI)
            // Deposits smaller than 1 Gwei not accepted
            // revert();
        address _user = msg.sender;
        var reward = computeCurrentReward(_token, _user);
        uint amount = TestTokenERC20(_token).allowance(_user, this);

        
        var oldBalance = tokenBalance[_token][_user];
        var newBalance = oldBalance + amount + reward;


        TestTokenERC20 token = TestTokenERC20(_token);
        require(token.transferFrom(_user, address(this), amount));

        tokenBalance[_token][_user] = newBalance;

        balanceToken[_token] += (newBalance / PPB - oldBalance / PPB);
        // mark starting term in reward series
        rewardInitialPerUserPerToken[_token][_user] = reward_ppb_total[_token];

        
        emit DepositMade(msg.sender, amount, _token);

        return(reward, amount, oldBalance, newBalance);
        
    }

    // @dev returns the total qty of a token currently held in deposit
    // @param _token address of the token for total balance to be returned
    function totalTokenBalance(address _token) public view returns (uint256) {
        return TestTokenERC20(_token).balanceOf(address(this));
    }

    /**
     * @notice Returns the amount that would be sent by a real withdrawal.
     * @param _token address of the token for simulated withdrawal
     * @param _user address of the user for simulated token withdrawal
     **/
    function simulateWithdrawalAmount(address _token, address _user) public view returns (uint256 withdrawAmt) {
        var startingBalance = tokenBalance[_token][_user];
        var fee = startingBalance / PPB * FEE_RATIO;  // all integer
        var reward = computeCurrentReward(_token, _user);
        return startingBalance - fee + reward;
    }

    /** @notice Returns the amount that would be sent by a real withdrawal.
     *  @param _token address
     *  @param _user address
     */ 
    function simulatedWithdrawal(address _token, address _user) public view returns (
        uint _startingBalance,
        uint _reward,
        uint _fee,
        uint _tokenBalance) {
        var startingBalance = tokenBalance[_token][_user];
        var fee = startingBalance / PPB * FEE_RATIO;  // all integer
        var reward = computeCurrentReward(_token, _user);
        var withdrawAmount = startingBalance - fee + reward;
        return (startingBalance, reward, fee, withdrawAmount);
    }

    function getAccountTokenStats(address _token) public view {
        address _user = msg.sender;
        simulatedWithdrawal(_token, _user);
    }
    /// @notice Withdraw funds associated with the sender address,
    ///  deducting fee and adding reward.
    function withdraw(address _token) public returns (bool) {
        address _user = msg.sender;
        require(tokenBalance[_token][_user] > 0);

        // init
        var startingBalance = tokenBalance[_token][_user];
        var fee = startingBalance / PPB * FEE_RATIO; // all integer
        var reward = computeCurrentReward(_token, _user);

        // clear user account
        tokenBalance[_token][_user] = 0;
        rewardInitialPerUserPerToken[_token][_user] = 0;
        balanceToken[_token] -= startingBalance / PPB;

        // update total reward and remainder
        if (balanceToken[_token] > 0) {
            var amount = fee + rewardRemainingPerToken[_token];              // wei
            var ratio = amount / balanceToken[_token];             // 1/Gwei
            reward_ppb_total[_token] += ratio;
            rewardRemainingPerToken[_token] = amount % balanceToken[_token];      // wei
        } else {
            assert(balanceToken[_token] == 0);
            // special case for last withdrawal: no fee
            fee = 0;
            reward += rewardRemainingPerToken[_token];
            rewardRemainingPerToken[_token] = 0;
        }

        var send_amount = startingBalance - fee + reward;

        TestTokenERC20 token = TestTokenERC20(_token);
        token.approve(this, 0); 
        if (token.approve(this, send_amount)) {
            return token.transferFrom(this, _user, send_amount);
        }

        // msg.sender.transfer(send_amount);

        emit WithdrawalMade(msg.sender, send_amount, _token, fee, reward);
        
        
    }

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
     * @notice tokenX address + userY address <-IN + OUT-> balance of tokenX for userY.
     * @dev returns the token balance of a user given the address of token and user
     * @param _token address is the address of the token contract
     * @param _user address is the address of the user account
     * @return uint256 balance of specified token for given user
     */
    function getUserTokenBalance(address _token, address _user) public view returns (uint256) {
        uint256 balance = tokenBalance[_token][_user];
        return balance;
    }

    /**
     * @notice user address <-IN + OUT-> array of token balances for user
     * @dev returns the balance of each token for a given user
     * @dev use in conjunction with getTokenList()
     * @param _user address of the user for whom token balances should be returned
     */
    function userTokenBalances(address _user) public view returns (uint256[]) {
        uint256 tokenCount;
        tokenCount = tokens.length;
        uint[] memory tokenHoldings = new uint[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenHoldings[i] = tokenBalance[tokens[i]][_user];
        }
        return (tokenHoldings);
    }

    function getMyTokenBalances() public view returns (uint256[]) {
        address _user = msg.sender;
        return userTokenBalances(_user);
    }

    /**
     * @dev computes the current reward of _user for _token which is F(n) of calculated fees
     * @param _token address of the _user in computation
     * @param _user address of the token for calculation
     * @return uint256 
     */
    function computeCurrentReward(address _token, address _user) internal view returns (uint256) {
        var reward_ppb = reward_ppb_total[_token] - rewardInitialPerUserPerToken[_token][_user];
        return tokenBalance[_token][_user] / PPB * reward_ppb;
    }


    /// Dispatch to deposit or withdraw functions.
    function () public payable {
        
    }
}