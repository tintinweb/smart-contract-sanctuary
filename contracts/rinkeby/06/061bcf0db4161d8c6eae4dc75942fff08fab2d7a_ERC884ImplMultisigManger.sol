/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// File: contracts\Multisig\Multisig.sol
pragma solidity 0.4.26;

// Holds list of signers and verifies MofN signature
contract Multisig {
    uint public threshold = 1;
    mapping (address => bool) isSigners; // for signers lookup
    address[] public signers;
    address owner;

    constructor (address[] _signers, uint _threshold) public {
        require(_signers.length >= _threshold, "signers.length >= _threshold");

        signers = _signers;

        owner = msg.sender;
        threshold = _threshold;
        for (uint i = 0; i < _signers.length; i++) {
            isSigners[_signers[i]] = true;
        }
    }

    function getSingersCount() public view returns (uint count) {
        return signers.length;
    }

    function getSinger(uint index) public view returns(address) {
        return signers[index];
    }

    function isSigner(address _signer) public view returns (bool) {
        return isSigners[_signer]; // if does not exists, will return null
    }

    function verify(bytes32 message, uint8[] v, bytes32[] r, bytes32[] s)
        public view returns (bool) {
        return verifyWithThreshold(message, v, r, s, threshold);
    }

    function verifyWithStrictThreshold(bytes32 message, uint8[] v, bytes32[] r, bytes32[] s, uint threshold_)
        public view returns (bool) {
        require(threshold_ >= threshold, "Threshold too small");
        return verifyWithThreshold(message, v, r, s, threshold_);
    }

    function verifyWithThreshold(bytes32 message, uint8[] v, bytes32[] r, bytes32[] s, uint threshold_)
        public view returns (bool) {
        require(v.length >= threshold_, "Count of signature not enough");
        bytes32 messageInternal = message;
        if(!isSigner(ecrecover(message, v[0], r[0], s[0]))) {
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
            messageInternal = prefixedHash;
        }
        //we use this address to check that we don't submit same sign from same address
        address lastAdd = address(0); // cannot have address(0) as an owner
        for (uint i = 0; i < threshold_; i++) {
            address recovered = ecrecover(messageInternal, v[i], r[i], s[i]);
            require (recovered > lastAdd && isSigner(recovered), "Wrong signature");
            lastAdd = recovered;
        }
        return true;
    }
}

// File: contracts\Ownable.sol

pragma solidity 0.4.26;

contract Ownable {
    address private owner;
    constructor() public {
        owner = msg.sender;
    }

    function _setOnwer(address owner_) internal{
        owner = owner_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

}

// File: openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

pragma solidity 0.4.26;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts\ERC884\ERC884.sol

pragma solidity 0.4.26;


/**
 *  An `ERC20` compatible token that conforms to Delaware State Senate,
 *  149th General Assembly, Senate Bill No. 69: An act to Amend Title 8
 *  of the Delaware Code Relating to the General Corporation Law.
 *
 *  Implementation Details.
 *
 *  An implementation of this token standard SHOULD provide the following:
 *
 *  `name` - for use by wallets and exchanges.
 *  `symbol` - for use by wallets and exchanges.
 *
 *  The implementation MUST take care not to allow unauthorised access to share
 *  transfer functions.
 *
 *  In addition to the above the following optional `ERC20` function MUST be defined.
 *
 *  `decimals` — MUST return `0` as each token represents a single Share and Shares are non-divisible.
 *
 *  @dev Ref https://github.com/ethereum/EIPs/pull/884
 */
contract ERC884 is IERC20 {

    /**
     *  This event is emitted when a verified address and associated identity hash are
     *  added to the contract.
     *  @param addr The address that was added.
     *  @param hash The identity hash associated with the address.
     *  @param sender The address that caused the address to be added.
     */
    event VerifiedAddressAdded(
        address indexed addr,
        bytes32 hash,
        address indexed sender
    );

    /**
     *  This event is emitted when a verified address its associated identity hash are
     *  removed from the contract.
     *  @param addr The address that was removed.
     *  @param sender The address that caused the address to be removed.
     */
    event VerifiedAddressRemoved(address indexed addr, address indexed sender);

    /**
     *  This event is emitted when the identity hash associated with a verified address is updated.
     *  @param addr The address whose hash was updated.
     *  @param oldHash The identity hash that was associated with the address.
     *  @param hash The hash now associated with the address.
     *  @param sender The address that caused the hash to be updated.
     */
    event VerifiedAddressUpdated(
        address indexed addr,
        bytes32 oldHash,
        bytes32 hash,
        address indexed sender
    );

    /**
     *  Address replaced for the lost address
     *  This event is emitted when an address is cancelled and replaced with
     *  a new address.  This happens in the case where a shareholder has
     *  lost access to their original address and needs to have their share
     *  reissued to a new address.  This is the equivalent of issuing replacement
     *  share certificates.
     *  @param original The address being superseded.
     *  @param replacement The new address.
     *  @param sender The address that caused the address to be superseded.
     */
    event VerifiedAddressSuperseded(
        address indexed original,
        address indexed replacement,
        address indexed sender
    );

    /**
     *  Add a verified address, along with an associated verification hash to the contract.
     *  Upon successful addition of a verified address, the contract must emit
     *  `VerifiedAddressAdded(addr, hash, msg.sender)`.
     *  It MUST throw if the supplied address or hash are zero, or if the address has already been supplied.
     *  @param addr The address of the person represented by the supplied hash.
     *  @param hash A cryptographic hash of the address holder's verified information.
     */
    function addVerified(address addr, bytes32 hash) public;

    /**
     *  Remove a verified address, and the associated verification hash. If the address is
     *  unknown to the contract then this does nothing. If the address is successfully removed, this
     *  function must emit `VerifiedAddressRemoved(addr, msg.sender)`.
     *  It MUST throw if an attempt is made to remove a verifiedAddress that owns Tokens.
     *  @param addr The verified address to be removed.
     */
    function removeVerified(address addr) public;

    /**
     *  Update the hash for a verified address known to the contract.
     *  Upon successful update of a verified address the contract must emit
     *  `VerifiedAddressUpdated(addr, oldHash, hash, msg.sender)`.
     *  If the hash is the same as the value already stored then
     *  no `VerifiedAddressUpdated` event is to be emitted.
     *  It MUST throw if the hash is zero, or if the address is unverified.
     *  @param addr The verified address of the person represented by the supplied hash.
     *  @param hash A new cryptographic hash of the address holder's updated verified information.
     */
    function updateVerified(address addr, bytes32 hash) public;

    /**
     *  Cancel the original address and reissue the Tokens to the replacement address.
     *  Access to this function MUST be strictly controlled.
     *  The `original` address MUST be removed from the set of verified addresses.
     *  Throw if the `original` address supplied is not a shareholder.
     *  Throw if the `replacement` address is not a verified address.
     *  Throw if the `replacement` address already holds Tokens.
     *  This function MUST emit the `VerifiedAddressSuperseded` event.
     *  @param original The address to be superseded. This address MUST NOT be reused.
     */
    function cancelAndReissue(address original, address replacement) public;

    /**
     *  The `transfer` function MUST NOT allow transfers to addresses that
     *  have not been verified and added to the contract.
     *  If the `to` address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce `msg.sender`'s balance to 0 then that address
     *  MUST be removed from the list of shareholders.
     */
    function transfer(address to, uint256 value) public returns (bool);

    /**
     *  The `transferFrom` function MUST NOT allow transfers to addresses that
     *  have not been verified and added to the contract.
     *  If the `to` address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce `from`'s balance to 0 then that address
     *  MUST be removed from the list of shareholders.
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool);

    /**
     *  Tests that the supplied address is known to the contract.
     *  @param addr The address to test.
     *  @return true if the address is known to the contract.
     */
    function isVerified(address addr) public view returns (bool);

    /**
     *  Checks to see if the supplied address is a share holder.
     *  @param addr The address to check.
     *  @return true if the supplied address owns a token.
     */
    function isHolder(address addr) public view returns (bool);

    /**
     *  Checks that the supplied hash is associated with the given address.
     *  @param addr The address to test.
     *  @param hash The hash to test.
     *  @return true if the hash matches the one supplied with the address in `addVerified`, or `updateVerified`.
     */
    function hasHash(address addr, bytes32 hash) public view returns (bool);

    /**
     *  The number of addresses that hold tokens.
     *  @return the number of unique addresses that hold tokens.
     */
    function holderCount() public view returns (uint);

    /**
     *  By counting the number of token holders using `holderCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if `index >= holderCount()`.
     *  @param index The zero-based index of the holder.
     *  @return the address of the token holder with the given index.
     */
    function holderAt(uint256 index) public view returns (address);

    /**
     *  Checks to see if the supplied address was superseded.
     *  @param addr The address to check.
     *  @return true if the supplied address was superseded by another address.
     */
    function isSuperseded(address addr) public view returns (bool);

    /**
     *  Gets the most recent address, given a superseded one.
     *  Addresses may be superseded multiple times, so this function needs to
     *  follow the chain of addresses until it reaches the final, verified address.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function getCurrentFor(address addr) public view returns (address);
}

// File: contracts\ERC20\Pausable.sol

pragma solidity 0.4.26;

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable  is Ownable {
    event Paused();
    event Unpaused();

    bool private isPaused;

    constructor() internal {
        isPaused = false; // Start paused
    }

    /**
    * @return true if the contract is paused, false otherwise.
    */
    function paused() public view returns(bool) {
        return isPaused;
    }

    /**
    *
    */
    modifier whenNotPausedOrExempt(bool exempt) {
        require(exempt || !isPaused,'whenNotPausedOrExempt');
        _;
    }

    modifier whenNotPaused() {
        require(!isPaused, 'whenNotPaused');
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPausedOrExempt(bool exempt) {
        require(exempt || isPaused,'whenPausedOrExempt');
        _;
    }

    modifier whenPaused() {
        require(isPaused, 'whenPaused');
        _;
    }

    function _pause() internal whenNotPaused {
        isPaused = true;
        emit Paused();
    }

    function _unpause() internal whenPaused {
        isPaused = false;
        emit Unpaused();
    }
    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() public whenNotPaused onlyOwner {
        isPaused = true;
        emit Paused();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public whenPaused onlyOwner {
        isPaused = false;
        emit Unpaused();
    }
}

// File: openzeppelin-solidity\contracts\math\SafeMath.sol

pragma solidity 0.4.26;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts\ERC20\ERC20.sol

pragma solidity 0.4.26;

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;
    uint256 private _maxTotalSupply;

    constructor(uint256 maxTotalSupply) public {
        _maxTotalSupply = maxTotalSupply;
    }
    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        returns (bool)
    {
        require(value <= _allowed[from][msg.sender]);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param addedValue The amount of tokens to increase the allowance by.
    */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Decrease the amount of tokens that an owner allowed to a spender.
    * approve should be called when allowed_[_spender] == 0. To decrement
    * allowed value is better to use this function to avoid 2 calls (and wait until
    * the first transaction is mined)
    * From MonolithDAO Token.sol
    * @param spender The address which will spend the funds.
    * @param subtractedValue The amount of tokens to decrease the allowance by.
    */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
        public
        returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(value <= _balances[from]);
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
    * @dev Internal function that mints an amount of the token and assigns it to
    * an account. This encapsulates the modification of balances such that the
    * proper events are emitted.
    * @param account The account that will receive the created tokens.
    * @param value The amount that will be created.
    */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));
        require(_maxTotalSupply == 0 || _totalSupply.add(value)<=_maxTotalSupply, "_totalSupply>_maxTotalSupply");
        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
    * @dev Internal function that burns an amount of the token of a given
    * account.
    * @param account The account whose tokens will be burnt.
    * @param value The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        require(value <= _balances[account]);

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _cancelAndReissue(address original, address replacement) internal {
        _balances[replacement] = _balances[original];
        _balances[original] = 0;
    }

    function _split(address address_, uint splitFactor_, uint splitFactorDecimals_) internal {
        _balances[address_] = _balances[address_].mul(splitFactor_).div(10 ** splitFactorDecimals_);
    }
}

// File: contracts\ERC20\ERC20Pausable.sol

pragma solidity 0.4.26;

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 **/
contract ERC20Pausable is ERC20, Pausable {
    mapping (address => bool) isExempt; // addresses exempt from pause

    function transfer(
        address to,
        uint256 value
    )
        public
        whenNotPausedOrExempt(isExempt[msg.sender])
        returns (bool)
    {
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        public
        whenNotPausedOrExempt(isExempt[msg.sender])
        returns (bool)
    {
        return super.transferFrom(from, to, value);
    }

    function approve(
        address spender,
        uint256 value
    )
        public
        whenNotPausedOrExempt(isExempt[msg.sender])
        returns (bool)
    {
        return super.approve(spender, value);
    }

    function increaseAllowance(
        address spender,
        uint addedValue
    )
        public
        whenNotPausedOrExempt(isExempt[msg.sender])
        returns (bool success)
    {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(
        address spender,
        uint subtractedValue
    )
        public
        whenNotPausedOrExempt(isExempt[msg.sender])
        returns (bool success)
    {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

// File: contracts\Multisig\Multisigned.sol

pragma solidity 0.4.26;

contract Multisigned {

    modifier onlySigners(address signersMultisig, bytes32 txHash, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) {
        Multisig multisig = Multisig(signersMultisig);
        require(multisig.verify(txHash, sigV, sigR, sigS), "incorrect signature");
        _;
    }

    function onlySignersWithThreshold(
        address signersMultisig,
        bytes32 txHash,
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        uint threshold) public view {
        Multisig multisig = Multisig(signersMultisig);
        require(multisig.verifyWithThreshold(txHash, sigV, sigR, sigS, threshold), "incorrect signature");
    }

    function onlySignersWithStrictThreshold(
        address signersMultisig,
        bytes32 txHash,
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        uint threshold) public view {
        Multisig multisig = Multisig(signersMultisig);
        require(multisig.verifyWithStrictThreshold(txHash, sigV, sigR, sigS, threshold), "incorrect signature");
    }
}

// File: openzeppelin-solidity\contracts\token\ERC20\ERC20Detailed.sol

pragma solidity 0.4.26;


/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  /**
   * @return the name of the token.
   */
  function name() public view returns(string) {
    return _name;
  }

  /**
   * @return the symbol of the token.
   */
  function symbol() public view returns(string) {
    return _symbol;
  }

  /**
   * @return the number of decimals of the token.
   */
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

// File: contracts\ERC20\ERC20Impl.sol

pragma solidity 0.4.26;

contract ERC20Impl is ERC20, ERC20Detailed, ERC20Pausable {

    bool private mintingFinished = false;

    constructor (string name, string symbol, uint8 decimals, uint256 maxTotalSupply) public
            ERC20Detailed(name, symbol, decimals)
            ERC20Pausable()
            ERC20(maxTotalSupply)
    {
    }

    /**
    * @dev Function to mint tokens
    * @param to The address that will receive the minted tokens.
    * @param value The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address to, uint256 value)
    public
    onlyOwner
    returns (bool)
    {
        _mint(to, value);
        return true;
    }

    modifier canMint() {
        require(!mintingFinished, "canMint");
        _;
    }

    event MintFinished();

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() public
        onlyOwner
        canMint
        returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

}

// File: contracts\ERC884\ERC884Impl.sol

pragma solidity 0.4.26;


/**
 *  An `ERC20` compatible token that conforms to Delaware State Senate,
 *  149th General Assembly, Senate Bill No. 69: An act to Amend Title 8
 *  of the Delaware Code Relating to the General Corporation Law.
 *
 *  Implementation Details.
 *
 *  An implementation of this token standard SHOULD provide the following:
 *
 *  `name` - for use by wallets and exchanges.
 *  `symbol` - for use by wallets and exchanges.
 *
 *  In addition to the above the following optional `ERC20` function MUST be defined.
 *
 *  `decimals` — MUST return `0` as each token represents a single Share and Shares are non-divisible.
 *
 *  @dev Ref https://github.com/ethereum/EIPs/blob/master/EIPS/eip-884.md
 */
contract ERC884Impl is ERC884, ERC20Impl {

    uint public splitFactor;
    uint public splitFactorDecimals;
    // example: split for 2:  splitFactor = 2, splitFactorDecimals  = 0
    // example: split for 0.5 (join):  splitFactor = 5, splitFactorDecimals  = 1

    uint public splittedHolders;
    bool public splitInProgress = false;
    event SplitComplete();
    event SplitStarted(uint splitFactor, uint splitFactorDecimals);
    event CancelAndReissue(address indexed from, address indexed to, uint256 value);

    bytes32 constant private ZERO_BYTES = bytes32(0);
    address constant private ZERO_ADDRESS = address(0);
    mapping(bytes32 => address[]) private labeling; // labeling addresses
    mapping(address => bytes32) private verified; // whitelisted addresses
    mapping(address => address) private cancellations; // lost addresses that have been replaced. Enables forwarding tokens

    address[] private shareholders;
    mapping(address => uint256) private holderIndices; // indicies in the shareholders array


    // // multisigs for different classes of owners and committees should be deployed separately
    constructor (
        address manager,
        string name,
        string symbol,
        uint256 maxTotalSupply)
        public ERC20Impl(name, symbol, 0, maxTotalSupply) {
        _setOnwer(manager);
    }

    function addLabel(address addr, bytes32 label) public onlyOwner {
        labeling[label].push(addr);
    }

    function removeLabel(address addr, bytes32 label) public onlyOwner {
        for(uint i = 0;i < labeling[label].length; i++) {
            if(labeling[label][i] == addr) {
                labeling[label][i] = ZERO_ADDRESS;
            }
        }
    }

    function getByLabel(bytes32 label, uint index) public view returns(address) {
        return labeling[label][index];
    }

    function getByLabelCount(bytes32 label) public view returns (uint256) {
        return labeling[label].length;
    }

    function split(uint splitFactor_, uint splitFactorDecimals_) public onlyOwner {
        require(!splitInProgress, "Split already in progress");
        splitFactor = splitFactor_;
        splitFactorDecimals = splitFactorDecimals_;
        splitInProgress = true;
        splittedHolders = 0; // split complete for this number of holders
        _pause();
        emit SplitStarted(splitFactor_, splitFactorDecimals_);
    }

    function executeSplit(uint count) public {
        require(splitInProgress, "Split should be in progress");
        uint holderNeedForSplit = shareholders.length - splittedHolders;

        if(holderNeedForSplit > count) {
            holderNeedForSplit = count;
        }

        for(uint i = splittedHolders;i < holderNeedForSplit; i++) {
            _split(shareholders[i], splitFactor, splitFactorDecimals);
        }

        splittedHolders += holderNeedForSplit;

        if(shareholders.length == splittedHolders ) { // check for last iteration
            splitInProgress = false;
            _unpause();
            emit SplitComplete();
        }
    }

    function burn(address account, uint256 value) public onlyOwner {
        _burn(account, value);
    }

    modifier isVerifiedAddress(address addr) {
        require(verified[addr] != ZERO_BYTES, "not verifyed address");
        _;
    }

    modifier isShareholder(address addr) {
        require(holderIndices[addr] != 0, "not share holder");
        _;
    }

    modifier isNotShareholder(address addr) {
        require(holderIndices[addr] == 0, "share holder");
        _;
    }

    modifier isNotCancelled(address addr) {
        require(cancellations[addr] == ZERO_ADDRESS, "cancelled");
        _;
    }

    /**
     * As each token is minted it is added to the shareholders array.
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount)
        public
        onlyOwner
        canMint
        isVerifiedAddress(_to)
        returns (bool)
    {
        require(!splitInProgress, "split in progress");
        // if the address does not already own share then
        // add the address to the shareholders array and record the index.
        updateShareholders(_to);
        return super.mint(_to, _amount);
    }

    /**
     *  The number of addresses that own tokens.
     *  @return the number of unique addresses that own tokens.
     */
    function holderCount()
        public
        view
        returns (uint)
    {
        return shareholders.length;
    }

    /**
     *  By counting the number of token holders using `holderCount`
     *  you can retrieve the complete list of token holders, one at a time.
     *  It MUST throw if `index >= holderCount()`.
     *  @param index The zero-based index of the holder.
     *  @return the address of the token holder with the given index.
     */
    function holderAt(uint256 index)
        public
        view
        returns (address)
    {
        require(index < shareholders.length, "index outbound");
        return shareholders[index];
    }

    /**
     *  Add a verified address, along with an associated verification hash to the contract.
     *  Upon successful addition of a verified address, the contract must emit
     *  `VerifiedAddressAdded(addr, hash, msg.sender)`.
     *  It MUST throw if the supplied address or hash are zero, or if the address has already been supplied.
     *  @param addr The address of the person represented by the supplied hash.
     *  @param hash A cryptographic hash of the address holder's verified information.
     */
    function addVerified(address addr, bytes32 hash)
        public
        onlyOwner
        isNotCancelled(addr)
    {
        require(addr != ZERO_ADDRESS, "zerp address");
        require(hash != ZERO_BYTES, "zero hash");
        require(verified[addr] == ZERO_BYTES, "addr already exist");
        verified[addr] = hash;
        emit VerifiedAddressAdded(addr, hash, msg.sender);
    }

    /**
     *  Remove a verified address, and the associated verification hash. If the address is
     *  unknown to the contract then this does nothing. If the address is successfully removed, this
     *  function must emit `VerifiedAddressRemoved(addr, msg.sender)`.
     *  It MUST throw if an attempt is made to remove a verifiedAddress that owns Tokens.
     *  @param addr The verified address to be removed.
     */
    function removeVerified(address addr)
        public
        onlyOwner
    {
        require(balanceOf(addr) == 0, "balance should be 0");
        if (verified[addr] != ZERO_BYTES) {
            verified[addr] = ZERO_BYTES;
            emit VerifiedAddressRemoved(addr, msg.sender);
        }
    }

    /**
     *  Update the hash for a verified address known to the contract.
     *  Upon successful update of a verified address the contract must emit
     *  `VerifiedAddressUpdated(addr, oldHash, hash, msg.sender)`.
     *  If the hash is the same as the value already stored then
     *  no `VerifiedAddressUpdated` event is to be emitted.
     *  It MUST throw if the hash is zero, or if the address is unverified.
     *  @param addr The verified address of the person represented by the supplied hash.
     *  @param hash A new cryptographic hash of the address holder's updated verified information.
     */
    function updateVerified(address addr, bytes32 hash)
        public
        onlyOwner
        isVerifiedAddress(addr)
    {
        require(hash != ZERO_BYTES, "hash is empty");
        bytes32 oldHash = verified[addr];
        if (oldHash != hash) {
            verified[addr] = hash;
            emit VerifiedAddressUpdated(addr, oldHash, hash, msg.sender);
        }
    }

    /**
     *  Cancel the original address and reissue the Tokens to the replacement address.
     *  Access to this function MUST be strictly controlled.
     *  The `original` address MUST be removed from the set of verified addresses.
     *  Throw if the `original` address supplied is not a shareholder.
     *  Throw if the replacement address is not a verified address.
     *  This function MUST emit the `VerifiedAddressSuperseded` event.
     *  @param original The address to be superseded. This address MUST NOT be reused.
     *  @param replacement The address  that supersedes the original. This address MUST be verified.
     */
    function cancelAndReissue(address original, address replacement)
        public
        onlyOwner
        isShareholder(original)
        isNotShareholder(replacement)
        isVerifiedAddress(replacement)
    {
        require(!splitInProgress, "split in progress");
        // replace the original address in the shareholders array
        // and update all the associated mappings
        verified[original] = ZERO_BYTES;
        cancellations[original] = replacement;
        uint256 holderIndex = holderIndices[original] - 1;
        shareholders[holderIndex] = replacement;
        holderIndices[replacement] = holderIndices[original];
        holderIndices[original] = 0;
        _cancelAndReissue(original, replacement);

        emit VerifiedAddressSuperseded(original, replacement, msg.sender);
        emit CancelAndReissue(original, replacement, balanceOf(replacement));
    }

    /**
     *  The `transfer` function MUST NOT allow transfers to addresses that
     *  have not been verified and added to the contract.
     *  If the `to` address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce `msg.sender`'s balance to 0 then that address
     *  MUST be removed from the list of shareholders.
     */
  function transfer(address _to, uint256 _value)
        public
        isVerifiedAddress(_to)
        returns (bool success)
    {
        require(!splitInProgress, "split in progress");
        updateShareholders(_to);
        pruneShareholders(msg.sender, _value);
        return super.transfer(_to, _value);
    }


    /**
     *  The `transferFrom` function MUST NOT allow transfers to addresses that
     *  have not been verified and added to the contract.
     *  If the `to` address is not currently a shareholder then it MUST become one.
     *  If the transfer will reduce `from`'s balance to 0 then that address
     *  MUST be removed from the list of shareholders.
     */
    function transferFrom(address from, address to, uint256 value)
        public
        isVerifiedAddress(to)
        returns (bool)
    {
        require(!splitInProgress, "split in progress");
        updateShareholders(to);
        pruneShareholders(from, value);
        return super.transferFrom(from, to, value);
    }

    /**
     *  Tests that the supplied address is known to the contract.
     *  @param addr The address to test.
     *  @return true if the address is known to the contract.
     */
    function isVerified(address addr)
        public
        view
        returns (bool)
    {
        return verified[addr] != ZERO_BYTES;
    }

    /**
     *  Checks to see if the supplied address is a share holder.
     *  @param addr The address to check.
     *  @return true if the supplied address owns a token.
     */
    function isHolder(address addr)
        public
        view
        returns (bool)
    {
        return holderIndices[addr] != 0;
    }

    /**
     *  Checks that the supplied hash is associated with the given address.
     *  @param addr The address to test.
     *  @param hash The hash to test.
     *  @return true if the hash matches the one supplied with the address in `addVerified`, or `updateVerified`.
     */
    function hasHash(address addr, bytes32 hash)
        public
        view
        returns (bool)
    {
        if (addr == ZERO_ADDRESS) {
            return false;
        }
        return verified[addr] == hash;
    }

    /**
     *  Checks to see if the supplied address was superseded.
     *  @param addr The address to check.
     *  @return true if the supplied address was superseded by another address.
     */
    function isSuperseded(address addr)
        public
        view
        returns (bool)
    {
        return cancellations[addr] != ZERO_ADDRESS;
    }

    /**
     *  Gets the most recent address, given a superseded one.
     *  Addresses may be superseded multiple times, so this function needs to
     *  follow the chain of addresses until it reaches the final, verified address.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function getCurrentFor(address addr)
        public
        view
        returns (address)
    {
        return findCurrentFor(addr);
    }

    /**
     *  Recursively find the most recent address given a superseded one.
     *  @param addr The superseded address.
     *  @return the verified address that ultimately holds the share.
     */
    function findCurrentFor(address addr)
        internal
        view
        returns (address)
    {
        address candidate = cancellations[addr];
        if (candidate == ZERO_ADDRESS) {
            return addr;
        }
        return findCurrentFor(candidate);
    }

    /**
     *  If the address is not in the `shareholders` array then push it
     *  and update the `holderIndices` mapping.
     *  @param addr The address to add as a shareholder if it's not already.
     */
    function updateShareholders(address addr)
        internal
    {
        if (holderIndices[addr] == 0) {
            holderIndices[addr] = shareholders.push(addr);
        }
    }

    /**
     *  If the address is in the `shareholders` array and the forthcoming
     *  transfer or transferFrom will reduce their balance to 0, then
     *  we need to remove them from the shareholders array.
     *  @param addr The address to prune if their balance will be reduced to 0.
     @  @dev see https://ethereum.stackexchange.com/a/39311
     */
    function pruneShareholders(address addr, uint256 value)
        internal
    {
        uint256 balance = balanceOf(addr) - value;
        if (balance > 0) {
            return;
        }
        uint256 holderIndex = holderIndices[addr] - 1;
        uint256 lastIndex = shareholders.length - 1;
        address lastHolder = shareholders[lastIndex];
        // overwrite the addr's slot with the last shareholder
        shareholders[holderIndex] = lastHolder;
        // also copy over the index (thanks @mohoff for spotting this)
        // ref https://github.com/davesag/ERC884-reference-implementation/issues/20
        holderIndices[lastHolder] = holderIndices[addr];
        // trim the shareholders array (which drops the last entry)
        shareholders.length--;
        // and zero out the index for addr
        holderIndices[addr] = 0;
    }
}

// File: contracts\ERC884\ERC884MultisigManager.sol

pragma solidity 0.4.26;

contract ERC884ImplMultisigManger is Ownable{
    uint public ownersNonce = 1; // current nonce
    uint public boardOfDirectorsNonce = 1; // current nonce
    uint public whiteListingNonce = 1; // current nonce

    address public ownerMultisigA;
    address public ownerMultisigB;
    uint public  totalSetCommiteeThreshold; // total number of signatures required

    address public whiteListingMultisig; // white-list committee
    address public boardOfDirectorsMultisig; // board of directors committee

    address public erc884;

    constructor (
    address ownerMultisigA_,
    address ownerMultisigB_,
    uint totalSetCommiteeThreshold_,
    address whiteListingMultisig_,
    address boardOfDirectorsMultisig_) public {
        ownerMultisigA = ownerMultisigA_;
        ownerMultisigB = ownerMultisigB_;
        whiteListingMultisig = whiteListingMultisig_;
        boardOfDirectorsMultisig = boardOfDirectorsMultisig_;
        totalSetCommiteeThreshold = totalSetCommiteeThreshold_;
    }

    function onlySigners(address signersMultisig, bytes encodePacked, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) internal view {
        Multisig multisig = Multisig(signersMultisig);
        bytes32 txHash = keccak256(encodePacked);
        require(multisig.verify(txHash, sigV, sigR, sigS), "incorrect signature");
    }

    function setToken(address erc884_) public onlyOwner {
        erc884 = erc884_;
    }

    function onlySignersWithThreshold(
        address signersMultisig,
        bytes32 txHash,
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        uint threshold) public view {
        Multisig multisig = Multisig(signersMultisig);
        require(multisig.verifyWithThreshold(txHash, sigV, sigR, sigS, threshold), "incorrect signature");
    }

    function onlySignersWithStrictThreshold(
        address signersMultisig,
        bytes32 txHash,
        uint8[] sigV,
        bytes32[] sigR,
        bytes32[] sigS,
        uint threshold) public view {
        Multisig multisig = Multisig(signersMultisig);
        require(multisig.verifyWithStrictThreshold(txHash, sigV, sigR, sigS, threshold), "incorrect signature");
    }

    function setBoardOfDirectors(
        address boardOfDirectorsMultisig_,
        uint8[] sigVA,
        bytes32[] sigRA,
        bytes32[] sigSA,
        uint8[] sigVB,
        bytes32[] sigRB,
        bytes32[] sigSB) public {

        bytes32 txHash = keccak256(abi.encodePacked("setBoardOfDirectors", erc884, boardOfDirectorsMultisig_, ownersNonce));
        onlySignersWithStrictThreshold(ownerMultisigA, txHash, sigVA, sigRA, sigSA, sigVA.length);
        uint bThreshold = totalSetCommiteeThreshold - sigVA.length;
        if(sigVA.length > totalSetCommiteeThreshold) {
            bThreshold = 1;
        }
        if(bThreshold > 0){
            onlySignersWithThreshold(ownerMultisigB, txHash, sigVB, sigRB, sigSB, bThreshold);
        }
        boardOfDirectorsMultisig = boardOfDirectorsMultisig_;
        ownersNonce++;
    }

    function setWhiteListing(
        address whiteListingMultisig_,
        uint8[] sigVA,
        bytes32[] sigRA,
        bytes32[] sigSA,
        uint8[] sigVB,
        bytes32[] sigRB,
        bytes32[] sigSB) public {
        bytes32 txHash = keccak256(abi.encodePacked("setWhiteListing", erc884, whiteListingMultisig_, ownersNonce));
        onlySignersWithStrictThreshold(ownerMultisigA, txHash, sigVA, sigRA, sigSA, sigVA.length);
        uint bThreshold = totalSetCommiteeThreshold - sigVA.length;
        if(sigVA.length > totalSetCommiteeThreshold) {
            bThreshold = 1;
        }
        if(bThreshold > 0) {
            onlySignersWithThreshold(ownerMultisigB, txHash, sigVB, sigRB, sigSB, bThreshold);
        }
        whiteListingMultisig = whiteListingMultisig_;
        ownersNonce++;
    }

    function setOwnersA(
        address ownerMultisigA_,
        uint8[] sigVA,
        bytes32[] sigRA,
        bytes32[] sigSA,
        uint8[] sigVB,
        bytes32[] sigRB,
        bytes32[] sigSB) public {

        bytes32 txHash = keccak256(abi.encodePacked("setOwnersA", erc884, ownerMultisigA_, ownersNonce));
        onlySignersWithStrictThreshold(ownerMultisigA, txHash, sigVA, sigRA, sigSA, sigVA.length);

        uint bThreshold = totalSetCommiteeThreshold - sigVA.length;
        if(sigVA.length > totalSetCommiteeThreshold) {
            bThreshold = 1;
        }
        if(bThreshold > 0) {
            onlySignersWithThreshold(ownerMultisigB, txHash, sigVB, sigRB, sigSB, bThreshold);
        }
        ownerMultisigA = ownerMultisigA_;
        ownersNonce++;
    }

    function setOwnersB(
        address ownerMultisigB_,
        uint8[] sigVA,
        bytes32[] sigRA,
        bytes32[] sigSA,
        uint8[] sigVB,
        bytes32[] sigRB,
        bytes32[] sigSB) public {

        bytes32 txHash = keccak256(abi.encodePacked("setOwnersB", erc884, ownerMultisigB_, ownersNonce));
        onlySignersWithStrictThreshold(ownerMultisigA, txHash, sigVA, sigRA, sigSA, sigVA.length);
        uint bThreshold = totalSetCommiteeThreshold - sigVA.length;
        if(sigVA.length > totalSetCommiteeThreshold) {
            bThreshold = 1;
        }
        if(bThreshold > 0){
            onlySignersWithThreshold(ownerMultisigB, txHash, sigVB, sigRB, sigSB, bThreshold);
        }
        ownerMultisigB = ownerMultisigB_;
        ownersNonce++;
    }

    function addLabel(address addr, bytes32 label, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(whiteListingMultisig,
            abi.encodePacked("addLabel", erc884, addr, label, whiteListingNonce),
            sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.addLabel(addr, label);

        whiteListingNonce++;
    }

    function removeLabel(address addr, bytes32 label, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(whiteListingMultisig,
            abi.encodePacked("removeLabel", erc884, addr, label, whiteListingNonce),
            sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.removeLabel(addr, label);

        whiteListingNonce++;
    }

    function addVerified(address addr, bytes32 hash, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(whiteListingMultisig,
            abi.encodePacked("addVerified", erc884, addr, hash, whiteListingNonce),
            sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.addVerified(addr, hash);

        whiteListingNonce++;
    }

    function removeVerified(address addr, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(whiteListingMultisig,
            abi.encodePacked("removeVerified", erc884, addr, whiteListingNonce),
            sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.removeVerified(addr);

        whiteListingNonce++;
    }

    function updateVerified(address addr, bytes32 hash, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(whiteListingMultisig,
            abi.encodePacked("updateVerified", erc884, addr, hash, whiteListingNonce),
            sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.updateVerified(addr, hash);

        whiteListingNonce++;
    }

    function cancelAndReissue(address original, address replacement, uint8[] sigV, bytes32[] sigR, bytes32[] sigS,
        uint8[] sigVB,
        bytes32[] sigRB,
        bytes32[] sigSB) public {

        bytes memory encoded = abi.encodePacked("cancelAndReissue", erc884, original, replacement, boardOfDirectorsNonce);
        bytes32 txHash = keccak256(encoded);


        onlySigners(boardOfDirectorsMultisig,
            encoded,
            sigV, sigR, sigS);
        onlySignersWithThreshold(ownerMultisigB, txHash, sigVB, sigRB, sigSB, 1);

        ERC884Impl token = ERC884Impl(erc884);
        token.cancelAndReissue(original, replacement);

        boardOfDirectorsNonce++;
    }

    function split(uint splitFactor_, uint splitFactorDecimals_, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(boardOfDirectorsMultisig,
            abi.encodePacked("split", erc884, splitFactor_, splitFactorDecimals_, boardOfDirectorsNonce),
            sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.split(splitFactor_, splitFactorDecimals_);

        boardOfDirectorsNonce++;
    }


    function burn(address account, uint256 value, uint8[] sigV, bytes32[] sigR, bytes32[] sigS,
        uint8[] sigVB,
        bytes32[] sigRB,
        bytes32[] sigSB) public {

        bytes memory encoded = abi.encodePacked("burn", erc884, account, value, boardOfDirectorsNonce);
        bytes32 txHash = keccak256(encoded);

        onlySigners(boardOfDirectorsMultisig,
            encoded,
            sigV, sigR, sigS);
        onlySignersWithThreshold(ownerMultisigB, txHash, sigVB, sigRB, sigSB, 1);

        ERC884Impl token = ERC884Impl(erc884);
        token.burn(account, value);

        boardOfDirectorsNonce++;
    }

    function mint(address to, uint256 value, uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(boardOfDirectorsMultisig,
            abi.encodePacked("mint", erc884, to, value, boardOfDirectorsNonce),
            sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.mint(to, value);

        boardOfDirectorsNonce++;
    }

    function finishMinting(uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(boardOfDirectorsMultisig,
            abi.encodePacked("finishMinting", erc884, boardOfDirectorsNonce),
            sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.finishMinting();

        boardOfDirectorsNonce++;
    }

    function pause(uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(boardOfDirectorsMultisig,
        abi.encodePacked("pause", erc884, boardOfDirectorsNonce),
        sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.pause();

        boardOfDirectorsNonce++;
    }

    function unpause(uint8[] sigV, bytes32[] sigR, bytes32[] sigS) public {
        onlySigners(boardOfDirectorsMultisig,
            abi.encodePacked("unpause", erc884, boardOfDirectorsNonce),
            sigV, sigR, sigS);

        ERC884Impl token = ERC884Impl(erc884);
        token.unpause();

        boardOfDirectorsNonce++;
    }
}