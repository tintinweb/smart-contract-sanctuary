pragma solidity ^0.4.15;

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract AbstractSingularDTVToken is Token {

}


/// @title Fund contract - Implements reward distribution.
/// @author Stefan George - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="dfacabbab9beb1f1b8bab0adb8ba9fbcb0b1acbab1aca6acf1b1baab">[email&#160;protected]</a>>
/// @author Milad Mostavi - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="a2cfcbcec3c68ccfcdd1d6c3d4cbe2c1cdccd1c7ccd1dbd18cccc7d6">[email&#160;protected]</a>>
contract SingularDTVFund {
    string public version = "0.1.0";

    /*
     *  External contracts
     */
    AbstractSingularDTVToken public singularDTVToken;

    /*
     *  Storage
     */
    address public owner;
    uint public totalReward;

    // User&#39;s address => Reward at time of withdraw
    mapping (address => uint) public rewardAtTimeOfWithdraw;

    // User&#39;s address => Reward which can be withdrawn
    mapping (address => uint) public owed;

    modifier onlyOwner() {
        // Only guard is allowed to do this action.
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    /*
     *  Contract functions
     */
    /// @dev Deposits reward. Returns success.
    function depositReward()
        public
        payable
        returns (bool)
    {
        totalReward += msg.value;
        return true;
    }

    /// @dev Withdraws reward for user. Returns reward.
    /// @param forAddress user&#39;s address.
    function calcReward(address forAddress) private returns (uint) {
        return singularDTVToken.balanceOf(forAddress) * (totalReward - rewardAtTimeOfWithdraw[forAddress]) / singularDTVToken.totalSupply();
    }

    /// @dev Withdraws reward for user. Returns reward.
    function withdrawReward()
        public
        returns (uint)
    {
        uint value = calcReward(msg.sender) + owed[msg.sender];
        rewardAtTimeOfWithdraw[msg.sender] = totalReward;
        owed[msg.sender] = 0;
        if (value > 0 && !msg.sender.send(value)) {
            revert();
        }
        return value;
    }

    /// @dev Credits reward to owed balance.
    /// @param forAddress user&#39;s address.
    function softWithdrawRewardFor(address forAddress)
        external
        returns (uint)
    {
        uint value = calcReward(forAddress);
        rewardAtTimeOfWithdraw[forAddress] = totalReward;
        owed[forAddress] += value;
        return value;
    }

    /// @dev Setup function sets external token address.
    /// @param singularDTVTokenAddress Token address.
    function setup(address singularDTVTokenAddress)
        external
        onlyOwner
        returns (bool)
    {
        if (address(singularDTVToken) == 0) {
            singularDTVToken = AbstractSingularDTVToken(singularDTVTokenAddress);
            return true;
        }
        return false;
    }

    /// @dev Contract constructor function sets guard address.
    function SingularDTVFund() {
        // Set owner address
        owner = msg.sender;
    }

    /// @dev Fallback function acts as depositReward()
    function ()
        public
        payable
    {
        if (msg.value == 0) {
            withdrawReward();
        } else {
            depositReward();
        }
    }
}