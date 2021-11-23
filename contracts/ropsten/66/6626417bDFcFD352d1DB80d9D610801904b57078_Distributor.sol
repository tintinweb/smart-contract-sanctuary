/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: MIT
// Sources flattened with hardhat v2.6.8 https://hardhat.org
// File @openzeppelin/contracts/utils/math/[email protected]

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/interfaces/IDistributor.sol

pragma solidity >= 0.6.12;

interface IDistributor
{
    struct ResultView 
    {
        address Token;
        uint256 Amount;
    }
    
    function FeePercentage() external returns (uint256);
    function SetFeePercentage(uint256 _fee) external;
    function TotalStaked() external returns (uint256);
    
    function GetListTokensLength() external view returns (uint256);
    function GetListTokens() external returns(address[] memory);
    function GetTokenRewardPerToken(address _token) external view returns (uint256);
    function GetUserBalance(address _user) external view returns (uint256);
    function GetUserDebt(address _user, address _token) external view returns (uint256);
    
    function OnFee(address _token, uint256 _amount) external;

    function TransferFee(address _user, address _token, uint256 _amount) external;
    function DepositStake(address _user, address _token, uint256 _amount) external;
    function WithdrawStake(address _user, uint256 _amount) external;
    function WithdrawRewards(address _user) external;
    function WithdrawReward(address _user, address _token) external;

    function ComputeRewards(address _user) external view returns (ResultView[] memory _result);
    function ComputeReward(address _user, address _token) external view returns (ResultView memory _result);
    function CalculateFee(uint256 _amount) external view returns (uint256);
    function Percentage(uint256 _amount, uint256 _perc) external pure returns (uint256 _result);
}


// File contracts/classes/Ownable.sol

pragma solidity ^0.8.0;

contract Ownable
{
    modifier onlyOwners()
    {
        require(DictionaryOwners[msg.sender] == true,'Not the Owner');
        _;
    }
    
    modifier onlyOwnersAndCallers()
    {
        require(DictionaryOwners[msg.sender] == true || DictionaryCallers[msg.sender] == true, 'Not the Owner or Caller');
        _;
    }
    
    // Owner of the contract, the only one who is able to se variables and enable/disable this contract
    mapping(address => bool) DictionaryOwners;
    function SetOwner(address _owner, bool _enabled) public virtual onlyOwners {DictionaryOwners[_owner] = _enabled;}
    
    // List of addresses that can execute this contract's functions
    mapping(address => bool) DictionaryCallers;
    function SetCaller(address _address, bool _enabled) public virtual onlyOwners {DictionaryCallers[_address] = _enabled;}
    
    constructor()
    {
        DictionaryOwners[msg.sender] = true;
    }
}


// File contracts/Distributor.sol

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "hardhat/console.sol";
//import "./classes/Dictionary.sol"

contract Distributor is Ownable
{
    using SafeMath for uint256;
    

    struct UserInfo 
    {
        uint256 Balance;
        mapping(address => uint256) Debt;   // Token => Value
        mapping(address => uint256) Paid;   // Token => Value
    }

    struct TokenInfo 
    {
        uint256 RewardPerToken;
        uint256 IndexArray;
    }

    struct ResultView 
    {
        address Token;
        uint256 Amount;
    }
    
    modifier onlyEnabled()
    {
        if(Enabled == false)
            return;
        _;
    }
    
    modifier checkToken(address _token)
    {
        require(_token == address(Token), 'Token is Different');
        _;
    }

    
    
    // Main token reference for all this staking contract
    // Do not execute changes of the token while contract is live / production it will break everything
    IERC20 Token;
    function SetToken(address _token) public onlyOwners {Token = IERC20(_token);}
    
    // Ability to pause the contract and stop recieving fees and deposits from users
    bool Enabled = true;
    function SetEnabled(bool _enabled) public onlyOwners {Enabled = _enabled;}
    
    // Settings for Fees, 100 = 1%
    uint256 public FeePercentage = 100;
    function SetFeePercentage(uint256 _fee) public onlyOwners {FeePercentage = _fee;}

    // Dictionaries for Users and Tokens
    mapping(address => UserInfo) DictionaryUsers;
    mapping(address => TokenInfo) DictionaryTokens;
    address[] public ListTokens;
    function GetListTokens() public view returns(address[] memory) {return ListTokens;}

    // Global vars for Main Token
    uint256 public TotalStaked;


    
    constructor(address _token)
    {
        Token = IERC20(_token);
    }



    function GetListTokensLength() public view returns (uint256)
    {
        return ListTokens.length;
    }

    function GetTokenRewardPerToken(address _token) public view returns (uint256)
    {
        return DictionaryTokens[_token].RewardPerToken;
    }

    function GetUserBalance(address _user) public view returns (uint256) 
    {
        return DictionaryUsers[_user].Balance;
    }

    function GetUserDebt(address _user, address _token) public view returns (uint256) 
    {
        return DictionaryUsers[_user].Debt[_token];
    }
    
    

    /*
    * Function called after recieving a 'fee' or 'reward' depends how you call them.
    * if the token is not indexed it adds it to the list and saves its index
    */
    function OnFee(address _token, uint256 _amount) public onlyOwnersAndCallers
    {
        require(_amount > 0, "Fee Amount == 0");
        
        // if the index is not set pushes the token in ListTokens
        // note: indexes are always position +1 to avoid default value of uint == 0
        if (DictionaryTokens[_token].IndexArray == 0)
        {
            ListTokens.push(_token);
            DictionaryTokens[_token].IndexArray = ListTokens.length;
        }
            
        // updates the reward for that specific token
        DictionaryTokens[_token].RewardPerToken = DictionaryTokens[_token]
            .RewardPerToken
            .add(_amount.mul(1e12).div(TotalStaked));
    }
    
    /*
    * Function called to transfer amount from token to here
    * it calls the event OnFee afterwards to update all the necessary variables
    */
    function TransferFee(address _user, address _token, uint256 _amount) public onlyOwnersAndCallers
    {
        // calls event OnFee to update everything
        OnFee(_token, _amount);
        
        // transfer the tokens from the caller to here
        IERC20(_token).transferFrom(_user, address(this), _amount);
    }

    /*
    * Function that lets the user 'Deposit' or 'Stake' its MainToken here
    * allowing him to recieve fee based on his staking amount
    */
    function DepositStake(address _user, address _token, uint256 _amount) external onlyOwnersAndCallers checkToken(_token)
    {
        // Adds to total staked 
        TotalStaked = TotalStaked.add(_amount);

        // Retrieves the user for ease of use and update its info for each token
        UserInfo storage User = DictionaryUsers[_user];
        User.Balance = User.Balance.add(_amount);

        // for each token updates his reward 
        uint256 len = ListTokens.length;
        for (uint256 i = 0; i < len; i++)
        {
            // retrieve the token and updates its Paid amount
            TokenInfo storage token = DictionaryTokens[ListTokens[i]];
            User.Paid[ListTokens[i]] = User.Paid[ListTokens[i]]
            .add(token.RewardPerToken.mul(_amount));
        }
        
        // Transfers the token to this contract
        //Token.transferFrom(_user, address(this), _amount);
    }

    /*
    * Function that lets Withdraw Fully or Partially staking amount of tokens of user
    */
    function WithdrawStake(address _user, uint256 _amount) public onlyOwnersAndCallers
    {
        // updates Total and user balances
        TotalStaked = TotalStaked.sub(_amount);
        DictionaryUsers[_user].Balance = DictionaryUsers[_user].Balance.sub(_amount);

        // foreach token updates its reward ratio 
        uint256 len = ListTokens.length;
        for (uint256 i = 0; i < len; i++) 
        {
            address token = ListTokens[i];
            uint256 reward = DictionaryTokens[token].RewardPerToken.mul(_amount);
            uint256 paid = DictionaryUsers[_user].Paid[token];

            // if the reward goes underflow for the subtraction avoid it and add debit
            if (reward > paid) 
            {
                //save the debt (cannot go minus in uint) avoid contract SafeMath revert
                DictionaryUsers[_user].Debt[token] = DictionaryUsers[_user].Debt[token]
                .add((DictionaryTokens[token]
                .RewardPerToken.mul(_amount))
                .sub(DictionaryUsers[_user].Paid[token]));

                // set to 0 Paid
                DictionaryUsers[_user].Paid[token] = 0;
            }
            else 
            {
                //subtract normally since Paid doesn't underflow 
                DictionaryUsers[_user].Paid[token] = DictionaryUsers[_user].Paid[token]
                .sub((DictionaryTokens[token].RewardPerToken.mul(_amount)));
            }
        }
        
        // transfer tokens from this contract to the user
        Token.approve(address(this), _amount);
        Token.transferFrom(address(this), _user, _amount);
    }

    /*
    * Function that lets Withdraw the reward accumulated for the user for all tokens
    */
    function WithdrawRewards(address _user) public onlyOwnersAndCallers
    {
        uint256 len = ListTokens.length;

        //for each token in the list withdraw 
        for (uint256 i = 0; i < len; i++)
        {
            WithdrawReward(_user, ListTokens[i]);
        }
    }

    /*
    * Function that lets Withdraw the single reward accumulated for the user
    */
    function WithdrawReward(address _user, address _token) public onlyOwnersAndCallers
    {
        // computes the reward that needs to be transferred to the user
        ResultView memory reward = ComputeReward(_user, _token);
        //console.log("Amount Before div: %s after %s", reward.Amount, reward.Amount.div(1e12));
        
        // normalize reward amount to correct decimals and delete floating points
        uint256 amount = reward.Amount.div(1e12);
        
        // skips process if reward is not worth the withdraw expenses
        if(amount == 0)
            return;
            
        // to avoid losing devimals just subtract normal reward.Amount - normalized
        uint256 decimals = reward.Amount.sub(amount.mul(1e12));
        //console.log("Debt Remaining After Withdraw: %s", decimals);

        // updates Paid balance and also debt keeping count of what cannot be sent to user 
        DictionaryUsers[_user].Paid[_token] = DictionaryUsers[_user]
            .Balance
            .mul(DictionaryTokens[_token].RewardPerToken)
            .add(DictionaryUsers[_user].Debt[_token])
            .sub(decimals);

        // updates debt counting of lost decimals 
        DictionaryUsers[_user].Debt[_token] = 0;
        
        // transfer safe 
        IERC20 token = IERC20(_token);
        token.approve(address(this), amount);
        token.transferFrom(address(this), _user, amount);
    }
    
    
    
    /*
    * Computes the reward pending for the user going through all the tokens
    */
    function ComputeRewards(address _user) public view returns (ResultView[] memory _result)
    {
        // creates an array result for each token
        uint256 len = ListTokens.length;
        _result = new ResultView[](len);

        //foreach token computes reward 
        for (uint256 i = 0; i < len; i++)
        {
            _result[i] = ComputeReward(_user, ListTokens[i]);
        }
    }

    /*
    * Computes the reward pending for the single token
    */
    function ComputeReward(address _user, address _token) public view returns (ResultView memory _result)
    {
        // sets token 
        _result.Token = _token;

        // sets vars for ease
        uint256 reward = DictionaryUsers[_user]
            .Balance
            .mul(DictionaryTokens[_token].RewardPerToken)
            .add(DictionaryUsers[_user].Debt[_token]);
        uint256 paid = DictionaryUsers[_user].Paid[_token];

        // to avoid math underflow for Paid for SafeMath
        if (reward > paid)
        {
            _result.Amount = reward.sub(DictionaryUsers[_user].Paid[_token]);
        }
        else
        {
            _result.Amount = 0;
        }
    }
    
    /*
    * Calculates the fee for a given amount as input, if the distributor is disabled it will return 0 
    * External contracts should always ask first what is the amount of fees the distributor wants and 
    * then send to the distributor the amount returned by this CalculateFee
    */
    function CalculateFee(uint256 _amount) public view returns (uint256)
    {
        if(Enabled == false) return 0;
        return Percentage(_amount, FeePercentage);
    }

    /*
    * Performs percentage calculations, perc has to be a centesimal input 100 == 1% so we can 
    * compute centesimal floating points 1 == 0.01%
    */
    function Percentage(uint256 _amount, uint256 _perc) public pure returns (uint256 _result)
    {
        _result = _amount.mul(_perc).div(10000);
    }
}