pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

/*
@title Parent contract.
@author
*/
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /*
    @notice Transer Ownership to &#39;newOwner&#39;.
    @dev Transer Ownership to &#39;newOwner&#39;, the caller restricted to owner.
    @param newOwner New owner address.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}

/*
@title Main contract.
@author
*/
contract TokenERC20 is owned {
    using SafeMath for uint256;
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    struct FreezeAccountInfo{
        uint256 freezeStartTime;
        uint256 freezePeriod;
        uint256 freezeAmount;
    }

    mapping (address => FreezeAccountInfo) public freezeAccount;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event IssueAndFreeze(address indexed to, uint256 _value, uint256 _freezePeriod);

    /*
    Constrctor function
    Initializes contract with initial supply tokens to the creator of the contract
    */
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10**uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }
    /*
    @notice Issue &#39;_value&#39; token to &#39;_to&#39;, the &#39;_value&#39; tokens was freeze,
    and specify a freeze period is &#39;_freezePeriod&#39; day(s).
    @dev Issue &#39;_value&#39; token to &#39;_to&#39;, the &#39;_value&#39; tokens was freeze,
    and specify a freeze period is &#39;_freezePeriod&#39; day(s).
    @param _to Receiving address.
    @param _value Issue and freeze token amount.
    @param _freezePeriod Freeze Period(days).
    */
    function issueAndFreeze(address _to, uint _value, uint _freezePeriod) public onlyOwner {
        _transfer(msg.sender, _to, _value);

        freezeAccount[_to] = FreezeAccountInfo({
            freezeStartTime : now,
            freezePeriod : _freezePeriod,
            freezeAmount : _value
        });
        emit IssueAndFreeze(_to, _value, _freezePeriod);
    }

    /*
    @notice Get Freeze Information of &#39;_target&#39;.
    @dev Get Freeze Information of &#39;_target&#39;.
    @param _target Target address.
    @param _value Issue and freeze token amount.
    @return _freezeStartTime Freeze start time.
    @return _freezePeriod Freeze Period(days).
    @return _freezeAmount Freeze token Amount.
    @return _freezeDeadline Freeze deadline.
    */
    function getFreezeInfo(address _target) view public 
        returns (
            uint _freezeStartTime,
            uint _freezePeriod, 
            uint _freezeAmount, 
            uint _freezeDeadline) {
        FreezeAccountInfo storage targetFreezeInfo = freezeAccount[_target];
        return (targetFreezeInfo.freezeStartTime, 
        targetFreezeInfo.freezePeriod,
        targetFreezeInfo.freezeAmount,
        now + targetFreezeInfo.freezePeriod * 1 days);
    }

    /*
    @notice Transfer &#39;_value&#39; tokens to &#39;_to&#39;.
    @dev Send &#39;_value&#39; tokens to &#39;_to&#39; from your account.
    @param _to The address of the recipient.
    @param _value The token amount to send.
    */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /*
    @notice Transfer tokens from other address.
    @dev Send &#39;_value&#39; tokens to &#39;_to&#39; in behalf of &#39;_from&#39;.
    @param _from The address of the sender.
    @param _to The address of the recipient.
    @param _value The amount to send.
    @return Whether succeed.
    */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    /*
    @notice Set allowance for other address.
    @dev Allows &#39;_spender&#39; to spend no more than &#39;_value&#39; tokens in your behalf.
    @param _spender The address authorized to spend.
    @param _value The max amount they can spend.
    @return Whether succeed.
    */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /*
    @notice Set allowance for other address and notify
    @dev Allows &#39;_spender&#39; to spend no more than &#39;_value&#39; tokens in your behalf, and then ping the contract about it.
    @param _spender The address authorized to spend.
    @param _value The max amount they can spend.
    @param _extraData Some extra information to send to the approved contract.
    @return Whether succeed.
    */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /*
    @dev Internal transfer, only can be called by this contract.
    @param _from The address of the sender.
    @param _to The address of the recipient.
    @param _value The amount to send.
    */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0));

        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to].add(_value) > balanceOf[_to]);

        // _from freeze Information
        uint256 freezeStartTime;
        uint256 freezePeriod;
        uint256 freezeAmount;
        uint256 freezeDeadline;

        (freezeStartTime,freezePeriod,freezeAmount,freezeDeadline) = getFreezeInfo(_from);
        // The free amount of _from
        uint256 freeAmountFrom = balanceOf[_from].sub(freezeAmount);

        require(freezeStartTime == 0 || //Check if it is a freeze account
        freezeDeadline < now || //Check if in Lock-up Period
        (freeAmountFrom >= _value)); //Check if the transfer amount > free amount

        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = balanceOf[_from].sub(_value);
        // Add the same to the recipient
        balanceOf[_to] += balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }
}