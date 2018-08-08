pragma solidity ^0.4.13;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(
        address indexed _from,
        address indexed _to
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract DataeumToken is Owned, ERC20Interface {
    // Adding safe calculation methods to uint256
    using SafeMath for uint256;

    // Defining balances mapping (ERC20)
    mapping(address => uint256) balances;

    // Defining allowances mapping (ERC20)
    mapping(address => mapping(address => uint256)) allowed;

    // Defining addresses allowed to bypass global freeze
    mapping(address => bool) public freezeBypassing;

    // Defining addresses that have custom lockups periods
    mapping(address => uint256) public lockupExpirations;

    // Token Symbol
    string public constant symbol = "XDT";

    // Token Name
    string public constant name = "Dataeum Token";

    // Token Decimals
    uint8 public constant decimals = 18;

    // Current distributed supply
    uint256 public circulatingSupply = 0;

    // global freeze one-way toggle
    bool public tradingLive = false;

    // Total supply of token
    uint256 public totalSupply;

    /**
     * @notice Event for Lockup period applied to address
     * @param owner Specific lockup address target
     * @param until Timestamp when lockup end (seconds since epoch)
     */
    event LockupApplied(
        address indexed owner,
        uint256 until
    );

    /**
     * @notice Contract constructor
     * @param _totalSupply Total supply of token wanted
     */
    constructor(uint256 _totalSupply) public {
        totalSupply = _totalSupply;
    }

    /**
     * @notice distribute tokens to an address
     * @param to Who will receive the token
     * @param tokens How much token will be sent
     */
    function distribute(
        address to,
        uint256 tokens
    )
        public onlyOwner
    {
        uint newCirculatingSupply = circulatingSupply.add(tokens);
        require(newCirculatingSupply <= totalSupply);
        circulatingSupply = newCirculatingSupply;
        balances[to] = balances[to].add(tokens);

        emit Transfer(address(this), to, tokens);
    }

    /**
     * @notice Prevents the given wallet to transfer its token for the given duration.
     *      This methods resets the lock duration if one is already in place.
     * @param wallet The wallet address to lock
     * @param duration How much time is the token locked from now (in sec)
     */
    function lockup(
        address wallet,
        uint256 duration
    )
        public onlyOwner
    {
        uint256 lockupExpiration = duration.add(now);
        lockupExpirations[wallet] = lockupExpiration;
        emit LockupApplied(wallet, lockupExpiration);
    }

    /**
     * @notice choose if an address is allowed to bypass the global freeze
     * @param to Target of the freeze bypass status update
     * @param status New status (if true will bypass)
     */
    function setBypassStatus(
        address to,
        bool status
    )
        public onlyOwner
    {
        freezeBypassing[to] = status;
    }

    /**
     * @notice One-way toggle to allow trading (remove global freeze)
     */
    function setTradingLive() public onlyOwner {
        tradingLive = true;
    }

    /**
     * @notice Modifier that checks if the conditions are met for a token to be
     * tradable. To be so, it must :
     *  - Global Freeze must be removed, or, "from" must be allowed to bypass it
     *  - "from" must not be in a custom lockup period
     * @param from Who to check the status
     */
    modifier tradable(address from) {
        require(
            (tradingLive || freezeBypassing[from]) && //solium-disable-line indentation
            (lockupExpirations[from] <= now)
        );
        _;
    }

    /**
     * @notice Return the total supply of the token
     * @dev This function is part of the ERC20 standard 
     * @return {"supply": "The token supply"}
     */
    function totalSupply() public view returns (uint256 supply) {
        return totalSupply;
    }

    /**
     * @notice Get the token balance of `owner`
     * @dev This function is part of the ERC20 standard
     * @param owner The wallet to get the balance of
     * @return {"balance": "The balance of `owner`"}
     */
    function balanceOf(
        address owner
    )
        public view returns (uint256 balance)
    {
        return balances[owner];
    }

    /**
     * @notice Transfers `amount` from msg.sender to `destination`
     * @dev This function is part of the ERC20 standard
     * @param destination The address that receives the tokens
     * @param amount Token amount to transfer
     * @return {"success": "If the operation completed successfuly"}
     */
    function transfer(
        address destination,
        uint256 amount
    )
        public tradable(msg.sender) returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[destination] = balances[destination].add(amount);
        emit Transfer(msg.sender, destination, amount);
        return true;
    }

    /**
     * @notice Transfer tokens from an address to another one
     * through an allowance made before
     * @dev This function is part of the ERC20 standard
     * @param from The address that sends the tokens
     * @param to The address that receives the tokens
     * @param tokenAmount Token amount to transfer
     * @return {"success": "If the operation completed successfuly"}
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenAmount
    )
        public tradable(from) returns (bool success)
    {
        balances[from] = balances[from].sub(tokenAmount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokenAmount);
        balances[to] = balances[to].add(tokenAmount);
        emit Transfer(from, to, tokenAmount);
        return true;
    }

    /**
     * @notice Approve an address to send `tokenAmount` tokens to `msg.sender` (make an allowance)
     * @dev This function is part of the ERC20 standard
     * @param spender The allowed address
     * @param tokenAmount The maximum amount allowed to spend
     * @return {"success": "If the operation completed successfuly"}
     */
    function approve(
        address spender,
        uint256 tokenAmount
    )
        public returns (bool success)
    {
        allowed[msg.sender][spender] = tokenAmount;
        emit Approval(msg.sender, spender, tokenAmount);
        return true;
    }

    /**
     * @notice Get the remaining allowance for a spender on a given address
     * @dev This function is part of the ERC20 standard
     * @param tokenOwner The address that owns the tokens
     * @param spender The spender
     * @return {"remaining": "The amount of tokens remaining in the allowance"}
     */
    function allowance(
        address tokenOwner,
        address spender
    )
        public view returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    /**
     * @notice Permits to create an approval on a contract and then call a method
     * on the approved contract right away.
     * @param spender The allowed address
     * @param tokenAmount The maximum amount allowed to spend
     * @param data The data sent back as parameter to the contract (bytes array)
     * @return {"success": "If the operation completed successfuly"}
     */
    function approveAndCall(
        address spender,
        uint256 tokenAmount,
        bytes data
    )
        public tradable(spender) returns (bool success)
    {
        allowed[msg.sender][spender] = tokenAmount;
        emit Approval(msg.sender, spender, tokenAmount);

        ApproveAndCallFallBack(spender)
            .receiveApproval(msg.sender, tokenAmount, this, data);

        return true;
    }

    /**
     * @notice Permits to withdraw any ERC20 tokens that have been mistakingly sent to this contract
     * @param tokenAddress The received ERC20 token address
     * @param tokenAmount The amount of ERC20 tokens to withdraw from this contract
     * @return {"success": "If the operation completed successfuly"}
     */
    function withdrawERC20Token(
        address tokenAddress,
        uint256 tokenAmount
    )
        public onlyOwner returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokenAmount);
    }
}

library SafeMath {
    /**
    * @notice Adds two numbers, throws on overflow.
    */
    function add(
        uint256 a,
        uint256 b
    )
        internal pure returns (uint256 c)
    {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
    * @notice Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(
        uint256 a,
        uint256 b
    )
        internal pure returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }


    /**
    * @notice Multiplies two numbers, throws on overflow.
    */
    function mul(
        uint256 a,
        uint256 b
    )
        internal pure returns (uint256 c)
    {
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
    function div(
        uint256 a,
        uint256 b
    )
        internal pure returns (uint256)
    {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }
}