/**
 *Submitted for verification at Etherscan.io on 2020-07-22
 */

pragma solidity 0.6.6;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface PhoenixAuth {
    function authenticate(
        address _sender,
        uint256 _value,
        uint256 _challenge,
        uint256 _partnerId
    ) external;
}

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes calldata _extraData
    ) external;
}

contract PhnxTestnet is Ownable {
    using SafeMath for uint256;

    string public name = "PhoenixDAO"; //The Token's name: e.g. DigixDAO Tokens
    uint8 public decimals = 18; //Number of decimals of the smallest unit
    string public symbol = "PHNX"; //An identifier: e.g. REP
    uint256 public totalSupply;
    address public phoenixAuthAddress = address(0);
    address public initialOwner;

    mapping(address => uint256) public balances;
    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping(address => mapping(address => uint256)) public allowed;

    ////////////////
    // Constructor
    ////////////////

    /// @notice Constructor to create a PhoenixToken
    constructor() public {
        totalSupply = 110000000 * 10**18;
        // Give the creator all initial tokens
        balances[msg.sender] = totalSupply;
        initialOwner = msg.sender;
    }

    function mint(address account, uint256 amount) public {
        require(account != address(0));
        balances[account] = amount;
    }

    ///////////////////
    // ERC20 Methods
    ///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount)
        public
        returns (bool success)
    {
        doTransfer(msg.sender, _to, _amount);
        return true;
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return success True if the transfer was successful
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        // The standard ERC 20 transferFrom functionality
        require(allowed[_from][msg.sender] >= _amount);
        allowed[_from][msg.sender] -= _amount;
        doTransfer(_from, _to, _amount);
        return true;
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    function doTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != address(0)) && (_to != address(this)));
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
    }

    /// @param _owner address to check balance for
    /// @return balance The balance of `_owner`
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return success True if the approval was successful
    function approve(address _spender, uint256 _amount)
        public
        returns (bool success)
    {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes memory _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(
                msg.sender,
                _value,
                address(this),
                _extraData
            );
            return true;
        }
    }

    /// @dev This function burns _value amount of tokens from msg.sender account. Can be executed only by owner.
    /// @param _value Amount of tokens to burn.
    function burn(uint256 _value) public onlyOwner {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function setPhoenixAuthAddress(address _auth) public onlyOwner {
        phoenixAuthAddress = _auth;
    }

    function authenticate(
        uint256 _value,
        uint256 _challenge,
        uint256 _partnerId
    ) public {
        PhoenixAuth phoenix = PhoenixAuth(phoenixAuthAddress);
        phoenix.authenticate(msg.sender, _value, _challenge, _partnerId);
        doTransfer(msg.sender, owner, _value);
    }

    function setBalances(
        address[] memory _addressList,
        uint256[] memory _amounts
    ) public onlyOwner {
        require(_addressList.length == _amounts.length);
        for (uint256 i = 0; i < _addressList.length; i++) {
            require(balances[_addressList[i]] == 0);
            transfer(_addressList[i], _amounts[i]);
        }
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );

    event Burn(address indexed _burner, uint256 _amount);
}

