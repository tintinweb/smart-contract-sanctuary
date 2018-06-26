pragma solidity ^0.4.23;

/// @dev imports included in file for development.
/// import &quot;./contracts-tu/contracts/UnionDAO/TestTokenERC20.sol&quot;;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
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
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
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
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
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

    string public constant name = &quot;TestTokenERC20&quot;; // solium-disable-line uppercase
    string public constant symbol = &quot;T20&quot;; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase
    uint256 public constant INITIAL_SUPPLY = 10000 * (10 ** uint256(decimals));

  /**
   * @dev Constructor that gives msg.sender all of existing tokens.
   */
    function TestTokenERC20() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }

}


contract TokenUnion{

    using SafeMath for uint;


    uint256 public constant FEE_NUMERATOR = 1;
    uint256 public constant FEE_DENOMANATOR = 40;

    /**
     * @notice  Amount of each supported token deposited by user.
     * @dev     Mapping of user address to token contract address to balance
     * @dev     allows balance lookup for _user _token via balanceUserToken[_user][_token]
     */
    mapping(address => mapping(address => uint256)) public UserTokenBalance;

    /**
     * @notice  Total deposited tokens of each supported token.
     * @dev     Total balance of each supported token across all depositors
     */
    mapping(address => uint256) public TotalTokenBalance;

    /**
     * @notice  Total rewards accumulated from fees for each supported token
     * @dev     Tally of all fees for a given token which are distributed as rewards
     */
    mapping(address => uint256) public TokenCummRewardPerDeposit;


    /**
     * @notice  Stores the total amount of rewards at the time of deposit for a user.
     * @dev     Used with rewardTotalPerToken to determine rewards / fee.
     * @dev     In essence, a snapshot of the TNV at deposit whereas rewardRemainingPerToken
     * @dev     is a snapshot at the time of withdrawal and together allow fee/reward calcs
     */
    mapping(address => mapping(address => uint256)) public UserCummRewardPerToken;

    /// Array of token contract addresses for all deposited tokens
    address[] public tokens;

    event DepositMade(address _from, uint256 value, address _token);
    event WithdrawalMade(address _to, uint256 value, address token, uint256 fee, uint256 reward);


    /// Initialize the contract.
    constructor() public {
    }



    /**
     * @notice  Deposit tokens into contract.
     * @dev     NOTE: token allowance must be call on token contract
     * @dev     prior to calling this function or no tokens will transfer
     * @param   _token address of the token contract of the token for deposit
     * @param   _amount uint quantity of tokens to deposit
     */
    function depositToken(address _token, uint _amount) public {
        /// @notice add token contract address array if new and valid
        /// TODO:   prevent token from being added again if 0 balance
        if (_token != 0x0 && TotalTokenBalance[_token] == 0) {
            tokens.push(_token);
        }
        /// Transfer allowance of token from user to this contract
        TestTokenERC20 token = TestTokenERC20(_token);
        require(token.transferFrom(msg.sender, this, _amount));

        if (UserTokenBalance[msg.sender][_token] == 0){
            UserTokenBalance[msg.sender][_token] = _amount;
            UserCummRewardPerToken[msg.sender][_token] = TokenCummRewardPerDeposit[_token];
        }else{
            claim(_token, msg.sender);
            UserTokenBalance[msg.sender][_token]= UserTokenBalance[msg.sender][_token].add(_amount);
        }

        TotalTokenBalance[_token] = TotalTokenBalance[_token].add(_amount);
        /// Emit event and return parameters (return can be removed for production)
        emit DepositMade(msg.sender, _amount, _token);

    }


    /**
     * @dev distributes rewards accrued for a given token
     * @param _reward uint amount of reward to distribute
     * @param _token address of the token corresponding to accrued rewards
     */
    function distribute(uint _reward, address _token ) public returns (bool){
        require(TotalTokenBalance[_token] != 0);
        uint rewardAddedPerToken = _reward/TotalTokenBalance[_token];
        TokenCummRewardPerDeposit[_token] = TokenCummRewardPerDeposit[_token].add(rewardAddedPerToken);
    }


    /**
     * @dev claim function for transferring accrued rewards to acrruer
     * @param _token address of the token for reward claim
     * @param _receiver address to receive the accrued rewards
     */
    function claim(address _token, address _receiver)  public returns (uint) {
        uint depositAmount = UserTokenBalance[msg.sender][_token];
        //the amount per token for this user for this claim
        uint amountOwedPerToken = TokenCummRewardPerDeposit[_token].sub(UserCummRewardPerToken[msg.sender][_token]);
        uint claimableAmount = depositAmount.mul(amountOwedPerToken); //total amoun that can be claimed by this user
        UserCummRewardPerToken[_token][msg.sender]=TokenCummRewardPerDeposit[_token];
        if (_receiver == address(0)){
            require(ERC20(_token).transfer(msg.sender,claimableAmount));
        }else{
            require(ERC20(_token).transfer(_receiver,claimableAmount));
        }
        return claimableAmount;

    }


    /**
     * @notice  Withdraw token balance (all-or-none)
     * @dev     Called by _user to withdraw entire balance of a _token
     * @dev     Calculation of reward processing of payment of fee occur here
     * @param   _token address of the token to be withdrawn
     */
    function withdrawToken(address _token, uint _amount) public returns (bool) {
        require(UserTokenBalance[msg.sender][_token] > _amount );
        claim(_token, msg.sender);
        uint fee = calculateFee(_amount);
        uint amountToWithdraw = _amount.sub(fee);
        distribute(fee,_token);
        require(TestTokenERC20(_token).transfer(msg.sender,amountToWithdraw));
        TotalTokenBalance[_token] = TotalTokenBalance[_token].sub(_amount);
        UserTokenBalance[msg.sender][_token] = UserTokenBalance[msg.sender][_token].sub(_amount);
        return true;
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
    function getUserTokenBalance(address _token, address _user) public view returns (uint) {
        uint256 balance = UserTokenBalance[_user][_token];
        return balance;
    }

    /**
     * @notice user address <-IN + OUT-> array of token balances for user
     * @dev returns the balance of each token for a given user
     * @dev use in conjunction with getTokenList()
     * @param _user address of the user for whom token balances should be returned
     */
    function userTokenBalances(address _user) public view returns (uint[]) {
        uint256 tokenCount;
        tokenCount = tokens.length;
        uint[] memory tokenHoldings = new uint[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenHoldings[i] = UserTokenBalance[_user][tokens[i]];
        }
        return (tokenHoldings);
    }

    /**
     * @dev checkMyBalance allows user to check balances without method call args
     */
    function checkMyBalance() public view returns (uint[]) {
        address _user = msg.sender;
        return (userTokenBalances(_user));
    }

    /**
     * @dev returns a bool indicating if the user has any current deposits
     * @param _user address of user for balance determination
     */
    function doesUserHaveBalance(address _user) public view returns (bool) {
        uint256 tokenCount = tokens.length;
        for (uint256 i = 0; i < tokenCount; i++) {
            if(UserTokenBalance[_user][tokens[i]] > 0){
                return true;
            }
        }
        return false;
    }

    /// Revert if ETH accidentally sent to contract
    function () public payable {
        revert();
    }


    /**
     * @dev TokenDecimals is a helper function to change decimal place of
     * @dev token quantities to be compatible with other contract functions.
     * @dev NOTE: this may need to be changed to an actual call to token contract
     * @dev       since not all tokens are 18 decimals.
     * @param   _amount uint256 qty to have decimal moved right e.g. 0.01 --> 100
     */
    function TokenDecimals(uint256 _amount) internal pure returns (uint) {
        return SafeMath.mul(_amount, 10**18);
    }


    /**
     * @dev Function for comparing stored balance for a token in this contract
     * @dev against the balance recorded for this contract in the token contract
     * @dev Currently not implemented at this time.
     * @param _token address of the token to view aggregated balance
     */
    function totalTokenBalance(address _token) internal view returns (uint256) {
        return TestTokenERC20(_token).balanceOf(address(this));
    }


    /**
     * @dev fromTokenDecimals is a helper function to change decimal place of
     * @dev token quantities in the opposite direction as TokenDecimals
     * @dev NOTE: Same change as TokenDecimals may apply
     * @param  _amount uint256 qty to have decimal moved left e.g. 100 --> 0.01
     */
    function fromTokenDecimals(uint256 _amount) internal pure returns (uint) {
        return SafeMath.div(_amount, 10**18);
    }



    /**
     * @dev calculateFee returns the calculated fee amount from a given amount
     * @param _amount uint256 is the principle to use in calculating the fee
     */
    function calculateFee(uint256 _amount) internal pure returns (uint256) {
        require(_amount > 0);
        return (_amount.mul(FEE_NUMERATOR).div(FEE_DENOMANATOR));
    }

}