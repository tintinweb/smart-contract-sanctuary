pragma solidity 0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
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

    mapping(address => uint256) balances;

    uint256 totalSupply_;

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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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
    uint64 public releaseTime;

    constructor(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > uint64(block.timestamp));
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        require(uint64(block.timestamp) >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}

contract Owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

/**
 * @title TokenVault
 * @dev TokenVault is a token holder contract that will allow a
 * beneficiary to spend the tokens from some function of a specified ERC20 token
 */
contract TokenVault {
    using SafeERC20 for ERC20;

    // ERC20 token contract being held
    ERC20 public token;

    constructor(ERC20 _token) public {
        token = _token;
    }

    /**
     * @notice Allow the token itself to send tokens
     * using transferFrom().
     */
    function fillUpAllowance() public {
        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.approve(token, amount);
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
    }
}

contract IdealCoinToken is BurnableToken, Owned {
    string public constant name = "IdealCoin";
    string public constant symbol = "IDC";
    uint8 public constant decimals = 18;

    /// Maximum tokens to be allocated (2.2 billion IDC)
    uint256 public constant HARD_CAP = 2200000000 * 10**uint256(decimals);

    /// This address will receive the board of trustees and cold private sale tokens
    address public boardTokensAddress;

    /// This address will receive the platform tokens
    address public platformTokensAddress;

    /// This address is used to keep the tokens for sale
    address public saleTokensAddress;

    /// This address is used to keep the referral and bounty tokens
    address public referralBountyTokensAddress;

    /// Date when the Founders, Partners and Advisors can claim their locked tokens
    uint64 public date01Feb2019 = 1548979200;

    /// This vault is used to keep the Founders, Advisors and Partners tokens
    TokenVault public foundersAdvisorsPartnersTokensVault;

    /// Store the locking contract addresses
    mapping(address => address) public lockOf;

    /// when the token sale is closed, the trading will open
    bool public saleClosed = false;

    /// Only allowed to execute before the token sale is closed
    modifier beforeSaleClosed {
        require(!saleClosed);
        _;
    }

    constructor(address _boardTokensAddress, address _platformTokensAddress,
                address _saleTokensAddress, address _referralBountyTokensAddress) public {
        require(_boardTokensAddress != address(0));
        require(_platformTokensAddress != address(0));
        require(_saleTokensAddress != address(0));
        require(_referralBountyTokensAddress != address(0));

        boardTokensAddress = _boardTokensAddress;
        platformTokensAddress = _platformTokensAddress;
        saleTokensAddress = _saleTokensAddress;
        referralBountyTokensAddress = _referralBountyTokensAddress;

        /// Maximum tokens to be sold - 73.05 million IDC
        uint256 saleTokens = 73050000;
        createTokens(saleTokens, saleTokensAddress);

        /// Bounty tokens - 7.95 million IDC
        uint256 referralBountyTokens = 7950000;
        createTokens(referralBountyTokens, referralBountyTokensAddress);

        /// Board and cold private sale tokens - 12 million IDC
        uint256 boardTokens = 12000000;
        createTokens(boardTokens, boardTokensAddress);

        /// Platform tokens - 2.08 billion IDC
        uint256 platformTokens = 2080000000;
        createTokens(platformTokens, platformTokensAddress);

        require(totalSupply_ <= HARD_CAP);
    }

    function createLockingTokenVaults() external onlyOwner beforeSaleClosed {
        /// Founders, Advisors and Partners tokens - 27 million IDC
        uint256 foundersAdvisorsPartnersTokens = 27000000;
        foundersAdvisorsPartnersTokensVault = createTokenVault(foundersAdvisorsPartnersTokens);

        require(totalSupply_ <= HARD_CAP);
    }

    /// @dev Create a TokenVault and fill with the specified newly minted tokens
    function createTokenVault(uint256 tokens) internal onlyOwner returns (TokenVault) {
        TokenVault tokenVault = new TokenVault(ERC20(this));
        createTokens(tokens, tokenVault);
        tokenVault.fillUpAllowance();
        return tokenVault;
    }

    // @dev create specified number of tokens and transfer to destination
    function createTokens(uint256 _tokens, address _destination) internal onlyOwner {
        uint256 tokens = _tokens * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(tokens);
        balances[_destination] = tokens;
        emit Transfer(0x0, _destination, tokens);

        require(totalSupply_ <= HARD_CAP);
   }

    /// @dev lock tokens for a single whole period
    function lockTokens(address _beneficiary, uint256 _tokensAmount) external onlyOwner {
        require(lockOf[_beneficiary] == 0x0);
        require(_beneficiary != address(0));

        TokenTimelock lock = new TokenTimelock(ERC20(this), _beneficiary, date01Feb2019);
        lockOf[_beneficiary] = address(lock);
        require(this.transferFrom(foundersAdvisorsPartnersTokensVault, lock, _tokensAmount));
    }

    /// @dev releases vested tokens for the caller&#39;s own address
    function releaseLockedTokens() external {
        releaseLockedTokensFor(msg.sender);
    }

    /// @dev releases vested tokens for the specified address.
    /// Can be called by any account for any address.
    function releaseLockedTokensFor(address _owner) public {
        TokenTimelock(lockOf[_owner]).release();
    }

    /// @dev check the locked balance for an address
    function lockedBalanceOf(address _owner) public view returns (uint256) {
        return balances[lockOf[_owner]];
    }

    /// @dev will open the trading for everyone
    function closeSale() external onlyOwner beforeSaleClosed {
        /// The unsold and unallocated bounty tokens are allocated to the platform tokens

        uint256 unsoldTokens = balances[saleTokensAddress];
        balances[platformTokensAddress] = balances[platformTokensAddress].add(unsoldTokens);
        balances[saleTokensAddress] = 0;
        emit Transfer(saleTokensAddress, platformTokensAddress, unsoldTokens);

        uint256 unallocatedBountyTokens = balances[referralBountyTokensAddress];
        balances[platformTokensAddress] = balances[platformTokensAddress].add(unallocatedBountyTokens);
        balances[referralBountyTokensAddress] = 0;
        emit Transfer(referralBountyTokensAddress, platformTokensAddress, unallocatedBountyTokens);

        saleClosed = true;
    }

    /// @dev Trading limited - requires the token sale to have closed
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        if(saleClosed || msg.sender == address(this) || msg.sender == owner) {
            return super.transferFrom(_from, _to, _value);
        }
        return false;
    }

    /// @dev Trading limited - requires the token sale to have closed
    function transfer(address _to, uint256 _value) public returns (bool) {
        if(saleClosed || msg.sender == saleTokensAddress || msg.sender == referralBountyTokensAddress) {
            return super.transfer(_to, _value);
        }
        return false;
    }
}