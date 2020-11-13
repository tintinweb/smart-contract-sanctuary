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
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Owned {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    event Released(uint256 amount);
    event Revoked();

    // beneficiary of tokens after they are released
    address public beneficiary;

    uint256 public cliff;
    uint256 public start;
    uint256 public duration;

    bool public revocable;

    mapping (address => uint256) public released;
    mapping (address => bool) public revoked;

    address internal ownerShip;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
     * of the balance will have vested.
     * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
     * @param _start the time (as Unix time) at which point vesting starts
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _revocable whether the vesting is revocable or not
     */
    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        bool _revocable,
        address _realOwner
    )
        public
    {
        require(_beneficiary != address(0));
        require(_cliff <= _duration);

        beneficiary = _beneficiary;
        revocable = _revocable;
        duration = _duration;
        cliff = _start.add(_cliff);
        start = _start;
        ownerShip = _realOwner;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param token ERC20 token which is being vested
     */
    function release(ERC20Basic token) public {
        uint256 unreleased = releasableAmount(token);

        require(unreleased > 0);

        released[token] = released[token].add(unreleased);

        token.safeTransfer(beneficiary, unreleased);

        emit Released(unreleased);
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param token ERC20 token which is being vested
     */
    function revoke(ERC20Basic token) public onlyOwner {
        require(revocable);
        require(!revoked[token]);

        uint256 balance = token.balanceOf(this);

        uint256 unreleased = releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        revoked[token] = true;

        token.safeTransfer(ownerShip, refund);

        emit Revoked();
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param token ERC20 token which is being vested
     */
    function releasableAmount(ERC20Basic token) public view returns (uint256) {
        return vestedAmount(token).sub(released[token]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param token ERC20 token which is being vested
     */
    function vestedAmount(ERC20Basic token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration) || revoked[token]) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(start)).div(duration);
        }
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
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
    }
}

contract ODA_Token is BurnableToken, Owned {
    string public constant name = "ODA";
    string public constant symbol = "ODA";
    uint8 public constant decimals = 18;
 
    /// Maximum tokens to be allocated ( 3 billion ODA)
    uint256 public constant HARD_CAP = 3000000000 * 10**uint256(decimals);

    /// This address will be used to distribute the team, advisors and reserve tokens
    address public saleTokensAddress;

    /// This vault is used to keep the Founders, Advisors and Partners tokens
    TokenVault public reserveTokensVault;

    /// Date when the vesting for regular users starts
    uint64 internal daySecond     = 86400;
    uint64 internal lock90Days    = 90;
    uint64 internal unlock100Days = 100;
    uint64 internal lock365Days   = 365;

    /// Store the vesting contract addresses for each sale contributor
    mapping(address => address) public vestingOf;

    constructor(address _saleTokensAddress) public payable {
        require(_saleTokensAddress != address(0));

        saleTokensAddress = _saleTokensAddress;

        /// Maximum tokens to be sold - 2.1 billion
        uint256 saleTokens = 2100000000;
        createTokensInt(saleTokens, saleTokensAddress);

        require(totalSupply_ <= HARD_CAP);
    }

    /// @dev Create a ReserveTokenVault 
    function createReserveTokensVault() external onlyOwner {
        require(reserveTokensVault == address(0));

        /// Reserve tokens - 0.9 billion 
        uint256 reserveTokens = 900000000;
        reserveTokensVault = createTokenVaultInt(reserveTokens);

        require(totalSupply_ <= HARD_CAP);
    }

    /// @dev Create a TokenVault and fill with the specified newly minted tokens
    function createTokenVaultInt(uint256 tokens) internal onlyOwner returns (TokenVault) {
        TokenVault tokenVault = new TokenVault(ERC20(this));
        createTokensInt(tokens, tokenVault);
        tokenVault.fillUpAllowance();
        return tokenVault;
    }

    // @dev create specified number of tokens and transfer to destination
    function createTokensInt(uint256 _tokens, address _destination) internal onlyOwner {
        uint256 tokens = _tokens * 10**uint256(decimals);
        totalSupply_ = totalSupply_.add(tokens);
        balances[_destination] = balances[_destination].add(tokens);
        emit Transfer(0x0, _destination, tokens);

        require(totalSupply_ <= HARD_CAP);
    }

    /// @dev vest Detail : second unit
    function vestTokensDetailInt(
                        address _beneficiary,
                        uint256 _startS,
                        uint256 _cliffS,
                        uint256 _durationS,
                        bool _revocable,
                        uint256 _tokensAmountInt) external onlyOwner {
        require(_beneficiary != address(0));

        uint256 tokensAmount = _tokensAmountInt * 10**uint256(decimals);

        if(vestingOf[_beneficiary] == 0x0) {
            TokenVesting vesting = new TokenVesting(_beneficiary, _startS, _cliffS, _durationS, _revocable, owner);
            vestingOf[_beneficiary] = address(vesting);
        }

        require(this.transferFrom(reserveTokensVault, vestingOf[_beneficiary], tokensAmount));
    }

    /// @dev vest StartAt : day unit
    function vestTokensStartAtInt(
                            address _beneficiary, 
                            uint256 _tokensAmountInt,
                            uint256 _startS,
                            uint256 _afterDay,
                            uint256 _cliffDay,
                            uint256 _durationDay ) public onlyOwner {
        require(_beneficiary != address(0));

        uint256 tokensAmount = _tokensAmountInt * 10**uint256(decimals);
        uint256 afterSec = _afterDay * daySecond;
        uint256 cliffSec = _cliffDay * daySecond;
        uint256 durationSec = _durationDay * daySecond;

        if(vestingOf[_beneficiary] == 0x0) {
            TokenVesting vesting = new TokenVesting(_beneficiary, _startS + afterSec, cliffSec, durationSec, true, owner);
            vestingOf[_beneficiary] = address(vesting);
        }

        require(this.transferFrom(reserveTokensVault, vestingOf[_beneficiary], tokensAmount));
    }

    /// @dev vest function from now
    function vestTokensFromNowInt(address _beneficiary, uint256 _tokensAmountInt, uint256 _afterDay, uint256 _cliffDay, uint256 _durationDay ) public onlyOwner {
        vestTokensStartAtInt(_beneficiary, _tokensAmountInt, now, _afterDay, _cliffDay, _durationDay);
    }

    /// @dev vest the sale contributor tokens for 100 days, 1% gradual release 
    function vestCmdNow1PercentInt(address _beneficiary, uint256 _tokensAmountInt) external onlyOwner {
        vestTokensFromNowInt(_beneficiary, _tokensAmountInt, 0, 0, unlock100Days);
    }
    /// @dev vest the sale contributor tokens for 100 days, 1% gradual release after 3 month later, no cliff
    function vestCmd3Month1PercentInt(address _beneficiary, uint256 _tokensAmountInt) external onlyOwner {
        vestTokensFromNowInt(_beneficiary, _tokensAmountInt, lock90Days, 0, unlock100Days);
    }

    /// @dev vest the sale contributor tokens 100% release after 1 year
    function vestCmd1YearInstantInt(address _beneficiary, uint256 _tokensAmountInt) external onlyOwner {
        vestTokensFromNowInt(_beneficiary, _tokensAmountInt, 0, lock365Days, lock365Days);
    }

    /// @dev releases vested tokens for the caller's own address
    function releaseVestedTokens() external {
        releaseVestedTokensFor(msg.sender);
    }

    /// @dev releases vested tokens for the specified address.
    /// Can be called by anyone for any address.
    function releaseVestedTokensFor(address _owner) public {
        TokenVesting(vestingOf[_owner]).release(this);
    }

    /// @dev check the vested balance for an address
    function lockedBalanceOf(address _owner) public view returns (uint256) {
        return balances[vestingOf[_owner]];
    }

    /// @dev check the locked but releaseable balance of an owner
    function releaseableBalanceOf(address _owner) public view returns (uint256) {
        if (vestingOf[_owner] == address(0) ) {
            return 0;
        } else {
            return TokenVesting(vestingOf[_owner]).releasableAmount(this);
        }
    }

    /// @dev revoke vested tokens for the specified address.
    /// Tokens already vested remain in the contract, the rest are returned to the owner.
    function revokeVestedTokensFor(address _owner) public onlyOwner {
        TokenVesting(vestingOf[_owner]).revoke(this);
    }

    /// @dev Create a ReserveTokenVault 
    function makeReserveToVault() external onlyOwner {
        require(reserveTokensVault != address(0));
        reserveTokensVault.fillUpAllowance();
    }

}