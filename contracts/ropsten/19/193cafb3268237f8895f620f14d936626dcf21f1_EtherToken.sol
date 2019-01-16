pragma solidity 0.4.15;

/// @title provides subject to role checking logic
contract IAccessPolicy {

    ////////////////////////
    // Public functions
    ////////////////////////

    /// @notice We don&#39;t make this function constant to allow for state-updating access controls such as rate limiting.
    /// @dev checks if subject belongs to requested role for particular object
    /// @param subject address to be checked against role, typically msg.sender
    /// @param role identifier of required role
    /// @param object contract instance context for role checking, typically contract requesting the check
    /// @param verb additional data, in current AccessControll implementation msg.sig
    /// @return if subject belongs to a role
    function allowed(
        address subject,
        bytes32 role,
        address object,
        bytes4 verb
    )
        public
        returns (bool);
}

/// @title enables access control in implementing contract
/// @dev see AccessControlled for implementation
contract IAccessControlled {

    ////////////////////////
    // Events
    ////////////////////////

    /// @dev must log on access policy change
    event LogAccessPolicyChanged(
        address controller,
        IAccessPolicy oldPolicy,
        IAccessPolicy newPolicy
    );

    ////////////////////////
    // Public functions
    ////////////////////////

    /// @dev allows to change access control mechanism for this contract
    ///     this method must be itself access controlled, see AccessControlled implementation and notice below
    /// @notice it is a huge issue for Solidity that modifiers are not part of function signature
    ///     then interfaces could be used for example to control access semantics
    /// @param newPolicy new access policy to controll this contract
    /// @param newAccessController address of ROLE_ACCESS_CONTROLLER of new policy that can set access to this contract
    function setAccessPolicy(IAccessPolicy newPolicy, address newAccessController)
        public;

    function accessPolicy()
        public
        constant
        returns (IAccessPolicy);

}

contract StandardRoles {

    ////////////////////////
    // Constants
    ////////////////////////

    // @notice Soldity somehow doesn&#39;t evaluate this compile time
    // @dev role which has rights to change permissions and set new policy in contract, keccak256("AccessController")
    bytes32 internal constant ROLE_ACCESS_CONTROLLER = 0xac42f8beb17975ed062dcb80c63e6d203ef1c2c335ced149dc5664cc671cb7da;
}

/// @title Granular code execution permissions
/// @notice Intended to replace existing Ownable pattern with more granular permissions set to execute smart contract functions
///     for each function where &#39;only&#39; modifier is applied, IAccessPolicy implementation is called to evaluate if msg.sender belongs to required role for contract being called.
///     Access evaluation specific belong to IAccessPolicy implementation, see RoleBasedAccessPolicy for details.
/// @dev Should be inherited by a contract requiring such permissions controll. IAccessPolicy must be provided in constructor. Access policy may be replaced to a different one
///     by msg.sender with ROLE_ACCESS_CONTROLLER role
contract AccessControlled is IAccessControlled, StandardRoles {

    ////////////////////////
    // Mutable state
    ////////////////////////

    IAccessPolicy private _accessPolicy;

    ////////////////////////
    // Modifiers
    ////////////////////////

    /// @dev limits function execution only to senders assigned to required &#39;role&#39;
    modifier only(bytes32 role) {
        require(_accessPolicy.allowed(msg.sender, role, this, msg.sig));
        _;
    }

    ////////////////////////
    // Constructor
    ////////////////////////

    function AccessControlled(IAccessPolicy policy) internal {
        require(address(policy) != 0x0);
        _accessPolicy = policy;
    }

    ////////////////////////
    // Public functions
    ////////////////////////

    //
    // Implements IAccessControlled
    //

    function setAccessPolicy(IAccessPolicy newPolicy, address newAccessController)
        public
        only(ROLE_ACCESS_CONTROLLER)
    {
        // ROLE_ACCESS_CONTROLLER must be present
        // under the new policy. This provides some
        // protection against locking yourself out.
        require(newPolicy.allowed(newAccessController, ROLE_ACCESS_CONTROLLER, this, msg.sig));

        // We can now safely set the new policy without foot shooting.
        IAccessPolicy oldPolicy = _accessPolicy;
        _accessPolicy = newPolicy;

        // Log event
        LogAccessPolicyChanged(msg.sender, oldPolicy, newPolicy);
    }

    function accessPolicy()
        public
        constant
        returns (IAccessPolicy)
    {
        return _accessPolicy;
    }
}

contract IsContract {

    ////////////////////////
    // Internal functions
    ////////////////////////

    function isContract(address addr)
        internal
        constant
        returns (bool)
    {
        uint256 size;
        // takes 700 gas
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract AccessRoles {

    ////////////////////////
    // Constants
    ////////////////////////

    // NOTE: All roles are set to the keccak256 hash of the
    // CamelCased role name, i.e.
    // ROLE_LOCKED_ACCOUNT_ADMIN = keccak256("LockedAccountAdmin")

    // may setup LockedAccount, change disbursal mechanism and set migration
    bytes32 internal constant ROLE_LOCKED_ACCOUNT_ADMIN = 0x4675da546d2d92c5b86c4f726a9e61010dce91cccc2491ce6019e78b09d2572e;

    // may setup whitelists and abort whitelisting contract with curve rollback
    bytes32 internal constant ROLE_WHITELIST_ADMIN = 0xaef456e7c864418e1d2a40d996ca4febf3a7e317fe3af5a7ea4dda59033bbe5c;

    // May issue (generate) Neumarks
    bytes32 internal constant ROLE_NEUMARK_ISSUER = 0x921c3afa1f1fff707a785f953a1e197bd28c9c50e300424e015953cbf120c06c;

    // May burn Neumarks it owns
    bytes32 internal constant ROLE_NEUMARK_BURNER = 0x19ce331285f41739cd3362a3ec176edffe014311c0f8075834fdd19d6718e69f;

    // May create new snapshots on Neumark
    bytes32 internal constant ROLE_SNAPSHOT_CREATOR = 0x08c1785afc57f933523bc52583a72ce9e19b2241354e04dd86f41f887e3d8174;

    // May enable/disable transfers on Neumark
    bytes32 internal constant ROLE_TRANSFER_ADMIN = 0xb6527e944caca3d151b1f94e49ac5e223142694860743e66164720e034ec9b19;

    // may reclaim tokens/ether from contracts supporting IReclaimable interface
    bytes32 internal constant ROLE_RECLAIMER = 0x0542bbd0c672578966dcc525b30aa16723bb042675554ac5b0362f86b6e97dc5;

    // represents legally platform operator in case of forks and contracts with legal agreement attached. keccak256("PlatformOperatorRepresentative")
    bytes32 internal constant ROLE_PLATFORM_OPERATOR_REPRESENTATIVE = 0xb2b321377653f655206f71514ff9f150d0822d062a5abcf220d549e1da7999f0;

    // allows to deposit EUR-T and allow addresses to send and receive EUR-T. keccak256("EurtDepositManager")
    bytes32 internal constant ROLE_EURT_DEPOSIT_MANAGER = 0x7c8ecdcba80ce87848d16ad77ef57cc196c208fc95c5638e4a48c681a34d4fe7;
}

contract IBasicToken {

    ////////////////////////
    // Events
    ////////////////////////

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 amount);

    ////////////////////////
    // Public functions
    ////////////////////////

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply()
        public
        constant
        returns (uint256);

    /// @param owner The address that&#39;s balance is being requested
    /// @return The balance of `owner` at the current block
    function balanceOf(address owner)
        public
        constant
        returns (uint256 balance);

    /// @notice Send `amount` tokens to `to` from `msg.sender`
    /// @param to The address of the recipient
    /// @param amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address to, uint256 amount)
        public
        returns (bool success);

}

/// @title allows deriving contract to recover any token or ether that it has balance of
/// @notice note that this opens your contracts to claims from various people saying they lost tokens and they want them back
///     be ready to handle such claims
/// @dev use with care!
///     1. ROLE_RECLAIMER is allowed to claim tokens, it&#39;s not returning tokens to original owner
///     2. in derived contract that holds any token by design you must override `reclaim` and block such possibility.
///         see LockedAccount as an example
contract Reclaimable is AccessControlled, AccessRoles {

    ////////////////////////
    // Constants
    ////////////////////////

    IBasicToken constant internal RECLAIM_ETHER = IBasicToken(0x0);

    ////////////////////////
    // Public functions
    ////////////////////////

    function reclaim(IBasicToken token)
        public
        only(ROLE_RECLAIMER)
    {
        address reclaimer = msg.sender;
        if(token == RECLAIM_ETHER) {
            reclaimer.transfer(this.balance);
        } else {
            uint256 balance = token.balanceOf(this);
            require(token.transfer(reclaimer, balance));
        }
    }
}

contract ITokenMetadata {

    ////////////////////////
    // Public functions
    ////////////////////////

    function symbol()
        public
        constant
        returns (string);

    function name()
        public
        constant
        returns (string);

    function decimals()
        public
        constant
        returns (uint8);
}

/// @title adds token metadata to token contract
/// @dev see Neumark for example implementation
contract TokenMetadata is ITokenMetadata {

    ////////////////////////
    // Immutable state
    ////////////////////////

    // The Token&#39;s name: e.g. DigixDAO Tokens
    string private NAME;

    // An identifier: e.g. REP
    string private SYMBOL;

    // Number of decimals of the smallest unit
    uint8 private DECIMALS;

    // An arbitrary versioning scheme
    string private VERSION;

    ////////////////////////
    // Constructor
    ////////////////////////

    /// @notice Constructor to set metadata
    /// @param tokenName Name of the new token
    /// @param decimalUnits Number of decimals of the new token
    /// @param tokenSymbol Token Symbol for the new token
    /// @param version Token version ie. when cloning is used
    function TokenMetadata(
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        string version
    )
        public
    {
        NAME = tokenName;                                 // Set the name
        SYMBOL = tokenSymbol;                             // Set the symbol
        DECIMALS = decimalUnits;                          // Set the decimals
        VERSION = version;
    }

    ////////////////////////
    // Public functions
    ////////////////////////

    function name()
        public
        constant
        returns (string)
    {
        return NAME;
    }

    function symbol()
        public
        constant
        returns (string)
    {
        return SYMBOL;
    }

    function decimals()
        public
        constant
        returns (uint8)
    {
        return DECIMALS;
    }

    function version()
        public
        constant
        returns (string)
    {
        return VERSION;
    }
}

contract IERC223Callback {

    ////////////////////////
    // Public functions
    ////////////////////////

    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes data
    )
        public;

}

contract IERC223Token is IBasicToken {

    /// @dev Departure: We do not log data, it has no advantage over a standard
    ///     log event. By sticking to the standard log event we
    ///     stay compatible with constracts that expect and ERC20 token.

    // event Transfer(
    //    address indexed from,
    //    address indexed to,
    //    uint256 amount,
    //    bytes data);


    /// @dev Departure: We do not use the callback on regular transfer calls to
    ///     stay compatible with constracts that expect and ERC20 token.

    // function transfer(address to, uint256 amount)
    //     public
    //     returns (bool);

    ////////////////////////
    // Public functions
    ////////////////////////

    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool);
}

contract IERC20Allowance {

    ////////////////////////
    // Events
    ////////////////////////

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount);

    ////////////////////////
    // Public functions
    ////////////////////////

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param owner The address of the account that owns the token
    /// @param spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of owner that spender is allowed
    ///  to spend
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256 remaining);

    /// @notice `msg.sender` approves `spender` to spend `amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param spender The address of the account able to transfer the tokens
    /// @param amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address spender, uint256 amount)
        public
        returns (bool success);

    /// @notice Send `amount` tokens to `to` from `from` on the condition it
    ///  is approved by `from`
    /// @param from The address holding the tokens being transferred
    /// @param to The address of the recipient
    /// @param amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address from, address to, uint256 amount)
        public
        returns (bool success);

}

contract IERC20Token is IBasicToken, IERC20Allowance {

}

contract IERC677Callback {

    ////////////////////////
    // Public functions
    ////////////////////////

    // NOTE: This call can be initiated by anyone. You need to make sure that
    // it is send by the token (`require(msg.sender == token)`) or make sure
    // amount is valid (`require(token.allowance(this) >= amount)`).
    function receiveApproval(
        address from,
        uint256 amount,
        address token, // IERC667Token
        bytes data
    )
        public
        returns (bool success);

}

contract IERC677Allowance is IERC20Allowance {

    ////////////////////////
    // Public functions
    ////////////////////////

    /// @notice `msg.sender` approves `spender` to send `amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param spender The address of the contract able to transfer the tokens
    /// @param amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(address spender, uint256 amount, bytes extraData)
        public
        returns (bool success);

}

contract IERC677Token is IERC20Token, IERC677Allowance {
}

contract Math {

    ////////////////////////
    // Internal functions
    ////////////////////////

    // absolute difference: |v1 - v2|
    function absDiff(uint256 v1, uint256 v2)
        internal
        constant
        returns(uint256)
    {
        return v1 > v2 ? v1 - v2 : v2 - v1;
    }

    // divide v by d, round up if remainder is 0.5 or more
    function divRound(uint256 v, uint256 d)
        internal
        constant
        returns(uint256)
    {
        return add(v, d/2) / d;
    }

    // computes decimal decimalFraction &#39;frac&#39; of &#39;amount&#39; with maximum precision (multiplication first)
    // both amount and decimalFraction must have 18 decimals precision, frac 10**18 represents a whole (100% of) amount
    // mind loss of precision as decimal fractions do not have finite binary expansion
    // do not use instead of division
    function decimalFraction(uint256 amount, uint256 frac)
        internal
        constant
        returns(uint256)
    {
        // it&#39;s like 1 ether is 100% proportion
        return proportion(amount, frac, 10**18);
    }

    // computes part/total of amount with maximum precision (multiplication first)
    // part and total must have the same units
    function proportion(uint256 amount, uint256 part, uint256 total)
        internal
        constant
        returns(uint256)
    {
        return divRound(mul(amount, part), total);
    }

    //
    // Open Zeppelin Math library below
    //

    function mul(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b)
        internal
        constant
        returns (uint256)
    {
        return a > b ? a : b;
    }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is IBasicToken, Math {

    ////////////////////////
    // Mutable state
    ////////////////////////

    mapping(address => uint256) internal _balances;

    uint256 internal _totalSupply;

    ////////////////////////
    // Public functions
    ////////////////////////

    /**
    * @dev transfer token for a specified address
    * @param to The address to transfer to.
    * @param amount The amount to be transferred.
    */
    function transfer(address to, uint256 amount)
        public
        returns (bool)
    {
        transferInternal(msg.sender, to, amount);
        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply()
        public
        constant
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner)
        public
        constant
        returns (uint256 balance)
    {
        return _balances[owner];
    }

    ////////////////////////
    // Internal functions
    ////////////////////////

    // actual transfer function called by all public variants
    function transferInternal(address from, address to, uint256 amount)
        internal
    {
        require(to != address(0));

        _balances[from] = sub(_balances[from], amount);
        _balances[to] = add(_balances[to], amount);
        Transfer(from, to, amount);
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is
    IERC20Token,
    BasicToken,
    IERC677Token
{

    ////////////////////////
    // Mutable state
    ////////////////////////

    mapping (address => mapping (address => uint256)) private _allowed;

    ////////////////////////
    // Public functions
    ////////////////////////

    //
    // Implements ERC20
    //

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param amount uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint256 amount)
        public
        returns (bool)
    {
        // check and reset allowance
        var allowance = _allowed[from][msg.sender];
        _allowed[from][msg.sender] = sub(allowance, amount);
        // do the transfer
        transferInternal(from, to, amount);
        return true;
    }

    /**
    * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param spender The address which will spend the funds.
    * @param amount The amount of tokens to be spent.
    */
    function approve(address spender, uint256 amount)
        public
        returns (bool)
    {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((amount == 0) || (_allowed[msg.sender][spender] == 0));

        _allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifing the amount of tokens still avaible for the spender.
    */
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256 remaining)
    {
        return _allowed[owner][spender];
    }

    //
    // Implements IERC677Token
    //

    function approveAndCall(
        address spender,
        uint256 amount,
        bytes extraData
    )
        public
        returns (bool)
    {
        require(approve(spender, amount));

        // in case of re-entry 1. approval is done 2. msg.sender is different
        bool success = IERC677Callback(spender).receiveApproval(
            msg.sender,
            amount,
            this,
            extraData
        );
        require(success);

        return true;
    }
}

contract EtherToken is
    IsContract,
    AccessControlled,
    StandardToken,
    TokenMetadata,
    Reclaimable
{
    ////////////////////////
    // Constants
    ////////////////////////

    string private constant NAME = "Ether Token";

    string private constant SYMBOL = "ETH-T";

    uint8 private constant DECIMALS = 18;

    ////////////////////////
    // Events
    ////////////////////////

    event LogDeposit(
        address indexed to,
        uint256 amount
    );

    event LogWithdrawal(
        address indexed from,
        uint256 amount
    );

    ////////////////////////
    // Constructor
    ////////////////////////

    function EtherToken(IAccessPolicy accessPolicy)
        AccessControlled(accessPolicy)
        StandardToken()
        TokenMetadata(NAME, DECIMALS, SYMBOL, "")
        Reclaimable()
        public
    {
    }

    ////////////////////////
    // Public functions
    ////////////////////////

    /// deposit msg.value of Ether to msg.sender balance
    function deposit()
        payable
        public
    {
        _balances[msg.sender] = add(_balances[msg.sender], msg.value);
        _totalSupply = add(_totalSupply, msg.value);
        LogDeposit(msg.sender, msg.value);
        Transfer(address(0), msg.sender, msg.value);
    }

    /// withdraws and sends &#39;amount&#39; of ether to msg.sender
    function withdraw(uint256 amount)
        public
    {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] = sub(_balances[msg.sender], amount);
        _totalSupply = sub(_totalSupply, amount);
        msg.sender.transfer(amount);
        LogWithdrawal(msg.sender, amount);
        Transfer(msg.sender, address(0), amount);
    }

    //
    // Implements IERC223Token
    //

    function transfer(address to, uint256 amount, bytes data)
        public
        returns (bool)
    {
        transferInternal(msg.sender, to, amount);

        // Notify the receiving contract.
        if (isContract(to)) {
            // in case of re-entry (1) transfer is done (2) msg.sender is different
            IERC223Callback(to).onTokenTransfer(msg.sender, amount, data);
        }
        return true;
    }

    //
    // Overrides Reclaimable
    //

    /// @notice allows EtherToken to reclaim tokens wrongly sent to its address
    /// @dev as EtherToken by design has balance of Ether (native Ethereum token)
    ///     such reclamation is not allowed
    function reclaim(IBasicToken token)
        public
    {
        // forbid reclaiming ETH hold in this contract.
        require(token != RECLAIM_ETHER);
        Reclaimable.reclaim(token);
    }
}