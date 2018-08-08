pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error.
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
        uint256 c = a / b;
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization
 *      control functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    // Public variable with address of owner
    address public owner;

    /**
     * Log ownership transference
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the
     *      contract to the sender account.
     */
    function Ownable() public {
        // Set the contract creator as the owner
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // Check that sender is owner
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) onlyOwner public {
        // Check for a non-null owner
        require(newOwner != address(0));
        // Log ownership transference
        OwnershipTransferred(owner, newOwner);
        // Set new owner
        owner = newOwner;
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
 * @title Qwasder Token contract.
 * @dev Custom ERC20 Token.
 */
contract QwasderToken is ERC20Basic, Ownable {

    using SafeMath for uint256;

    /**
     * BasicToken data.
     */
    uint256 public totalSupply_ = 0;
    mapping(address => uint256) balances;

    /**
     * StandardToken data.
     */
    mapping (address => mapping (address => uint256)) internal allowed;

    /**
     * MintableToken data.
     */
    bool public mintingFinished = false;

    /**
     * GrantableToken modifiers.
     */
    uint256 public grantsUnlock = 1523318400; // Tue, 10 Apr 2018 00:00:00 +0000 (GMT)
    uint256 public reservedSupply = 20000000000000000000000000;
    // -------------------------------------^

    /**
     * CappedToken data.
     */
    uint256 public cap = 180000000000000000000000000;
    // ---------------------------^

    /**
     * DetailedERC20 data.
     */
    string public name     = "Qwasder";
    string public symbol   = "QWS";
    uint8  public decimals = 18;

    /**
     * QwasderToken data.
     */
    mapping (address => bool) partners;
    mapping (address => bool) blacklisted;
    mapping (address => bool) freezed;
    uint256 public publicRelease   = 1525046400; // Mon, 30 Apr 2018 00:00:00 +0000 (GMT)
    uint256 public partnersRelease = 1539129600; // Wed, 10 Oct 2018 00:00:00 +0000 (GMT)
    uint256 public hardcap = 200000000000000000000000000;
    // -------------------------------^

    /**
     * ERC20Basic events.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * ERC20 events.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * MintableToken events.
     */
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    /**
     * GrantableToken events.
     */
    event Grant(address indexed to, uint256 amount);

    /**
     * BurnableToken events.
     */
    event Burn(address indexed burner, uint256 value);

    /**
     * QwasderToken events.
     */
    event UpdatedPublicReleaseDate(uint256 date);
    event UpdatedPartnersReleaseDate(uint256 date);
    event UpdatedGrantsLockDate(uint256 date);
    event Blacklisted(address indexed account);
    event Freezed(address indexed investor);
    event PartnerAdded(address indexed investor);
    event PartnerRemoved(address indexed investor);
    event Unfreezed(address indexed investor);

    /**
     * Initializes contract.
     */
    function QwasderToken() public {
        assert(reservedSupply < cap && reservedSupply.add(cap) == hardcap);
        assert(publicRelease <= partnersRelease);
        assert(grantsUnlock < partnersRelease);
    }

    /**
     * MintableToken modifiers.
     */

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
     * GrantableToken modifiers.
     */

    modifier canGrant() {
        require(now >= grantsUnlock && reservedSupply > 0);
        _;
    }

    /**
     * ERC20Basic interface.
     */

    /**
     * @dev Gets the total raised token supply.
     */
    function totalSupply() public view returns (uint256 total) {
        return totalSupply_;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param investor The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address investor) public view returns (uint256 balance) {
        return balances[investor];
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address which you want to transfer to.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transfer(address to, uint256 amount) public returns (bool success) {
        require(!freezed[msg.sender] && !blacklisted[msg.sender]);
        require(to != address(0) && !freezed[to] && !blacklisted[to]);
        require((!partners[msg.sender] && now >= publicRelease) || now >= partnersRelease);
        require(0 < amount && amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        Transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * ERC20 interface.
     */

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param holder The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address holder, address spender) public view returns (uint256 remaining) {
        return allowed[holder][spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *      Beware that changing an allowance with this method brings the risk that someone may use both
     *      the old and the new allowance by unfortunate transaction ordering. One possible solution to
     *      mitigate this race condition is to first reduce the spender&#39;s allowance to 0 and set the
     *      desired value afterwards.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be spent.
     * @return A boolean that indicates if the operation was successful.
     */
    function approve(address spender, uint256 amount) public returns (bool success) {
        allowed[msg.sender][spender] = amount;
        Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param amount The amount of tokens to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        require(!blacklisted[msg.sender]);
        require(to != address(0) && !freezed[to] && !blacklisted[to]);
        require(from != address(0) && !freezed[from] && !blacklisted[from]);
        require((!partners[from] && now >= publicRelease) || now >= partnersRelease);
        require(0 < amount && amount <= balances[from]);
        require(amount <= allowed[from][msg.sender]);
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        Transfer(from, to, amount);
        return true;
    }

    /**
     * StandardToken interface.
     */

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @param spender The address which will spend the funds.
     * @param amount The amount of token to be decreased, in fraction units.
     * @return A boolean that indicates if the operation was successful.
     */
    function decreaseApproval(address spender, uint256 amount) public returns (bool success) {
        uint256 oldValue = allowed[msg.sender][spender];
        if (amount > oldValue) {
            allowed[msg.sender][spender] = 0;
        } else {
            allowed[msg.sender][spender] = oldValue.sub(amount);
        }
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *      approve should be called when allowance(owner, spender) == 0. To
     *      increment allowed value is better to use this function to avoid 2
     *      calls (and wait until the first transaction is mined).
     * @param spender The address which will spend the funds.
     * @param amount The amount of token to be increased, in fraction units.
     * @return A boolean that indicates if the operation was successful.
     */
    function increaseApproval(address spender, uint amount) public returns (bool success) {
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(amount);
        Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * MintableToken interface.
     */

    /**
     * @dev Function to mint tokens to investors.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint, in fraction units.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount) onlyOwner canMint public returns (bool success) {
        require(!freezed[to] && !blacklisted[to] && !partners[to]);
        uint256 total = totalSupply_.add(amount);
        require(total <= cap);
        totalSupply_ = total;
        balances[to] = balances[to].add(amount);
        Mint(to, amount);
        Transfer(address(0), to, amount);
        return true;
    }

    /**
     * @dev Function to stop minting new tokens.
     * @return True if the operation was successful.
     */
    function finishMinting() onlyOwner public returns (bool success) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    /**
     * GrantableToken interface.
     */

    /**
     * @dev Function to mint tokens to partners (grants), including up to reserved tokens.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint, in fraction units.
     * @return A boolean that indicates if the operation was successful.
     */
    function grant(address to, uint256 amount) onlyOwner canGrant public returns (bool success) {
        require(!freezed[to] && !blacklisted[to] && partners[to]);
        require(amount <= reservedSupply);
        totalSupply_ = totalSupply_.add(amount);
        reservedSupply = reservedSupply.sub(amount);
        balances[to] = balances[to].add(amount);
        Grant(to, amount);
        Transfer(address(0), to, amount);
        return true;
    }

    /**
     * BurnableToken interface.
     */

    /**
     * @dev Burns a specific amount of tokens.
     * @param amount The amount of token to be burned, in fraction units.
     * @return A boolean that indicates if the operation was successful.
     */
    function burn(uint256 amount) public returns (bool success) {
        require(!freezed[msg.sender]);
        require((!partners[msg.sender] && now >= publicRelease) || now >= partnersRelease);
        require(amount > 0 && amount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        Burn(msg.sender, amount);
        Transfer(msg.sender, address(0), amount);
        return true;
    }

    /**
     * QwasderToken interface.
     */

    /**
     * Add a new partner.
     */
    function addPartner(address investor) onlyOwner public returns (bool) {
        require(investor != address(0));
        require(!partners[investor] && !blacklisted[investor] && balances[investor] == 0);
        partners[investor] = true;
        PartnerAdded(investor);
        return partners[investor];
    }

    /**
     * Remove a partner.
     */
    function removePartner(address investor) onlyOwner public returns (bool) {
        require(partners[investor] && balances[investor] == 0);
        partners[investor] = false;
        PartnerRemoved(investor);
        return !partners[investor];
    }

    /**
     * Freeze permanently an investor.
     * WARNING: This will burn out any token sold to the blacklisted account.
     */
    function blacklist(address account) onlyOwner public returns (bool) {
        require(account != address(0));
        require(!blacklisted[account]);
        blacklisted[account] = true;
        totalSupply_ = totalSupply_.sub(balances[account]);
        uint256 amount = balances[account];
        balances[account] = 0;
        Blacklisted(account);
        Burn(account, amount);
        return blacklisted[account];
    }

    /**
     * Freeze (temporarily) an investor.
     */
    function freeze(address investor) onlyOwner public returns (bool) {
        require(investor != address(0));
        require(!freezed[investor]);
        freezed[investor] = true;
        Freezed(investor);
        return freezed[investor];
    }

    /**
     * Unfreeze an investor.
     */
    function unfreeze(address investor) onlyOwner public returns (bool) {
        require(freezed[investor]);
        freezed[investor] = false;
        Unfreezed(investor);
        return !freezed[investor];
    }

    /**
     * @dev Set a new release date for investor&#39;s transfers.
     *      Must be executed before the current release date, and the new
     *      date must be a later one. Up to one more week for security reasons.
     * @param date UNIX timestamp of the new release date for investor&#39;s transfers.
     * @return True if the operation was successful.
     */
    function setPublicRelease(uint256 date) onlyOwner public returns (bool success) {
        require(now < publicRelease && date > publicRelease);
        require(date.sub(publicRelease) <= 604800);
        publicRelease = date;
        assert(publicRelease <= partnersRelease);
        UpdatedPublicReleaseDate(date);
        return true;
    }

    /**
     * @dev Set a new release date for partners&#39; transfers.
     *      Must be executed before the current release date, and the new
     *      date must be a later one. Up to one more week for security reasons.
     * @param date UNIX timestamp of the new release date for partners&#39; transfers.
     * @return True if the operation was successful.
     */
    function setPartnersRelease(uint256 date) onlyOwner public returns (bool success) {
        require(now < partnersRelease && date > partnersRelease);
        require(date.sub(partnersRelease) <= 604800);
        partnersRelease = date;
        assert(grantsUnlock < partnersRelease);
        UpdatedPartnersReleaseDate(date);
        return true;
    }

    /**
     * @dev Function to set a new unlock date for partners&#39; minting grants.
     *      Must be executed before the current unlock date, and the new
     *      date must be a later one. Up to one more week for security reasons.
     * @param date UNIX timestamp of the new unlock date for partners&#39; grants.
     * @param extendLocking boolean value, true to extend the locking periods,
     *        false to leave the current dates.
     * @return True if the operation was successful.
     */
    function setGrantsUnlock(uint256 date, bool extendLocking) onlyOwner public returns (bool success) {
        require(now < grantsUnlock && date > grantsUnlock);
        if (extendLocking) {
          uint256 delay = date.sub(grantsUnlock);
          require(delay <= 604800);
          grantsUnlock = date;
          publicRelease = publicRelease.add(delay);
          partnersRelease = partnersRelease.add(delay);
          assert(publicRelease <= partnersRelease);
          assert(grantsUnlock < partnersRelease);
          UpdatedPublicReleaseDate(publicRelease);
          UpdatedPartnersReleaseDate(partnersRelease);
        }
        else {
          // Can set a date more than one week later, provided it is before the release date.
          grantsUnlock = date;
          assert(grantsUnlock < partnersRelease);
        }
        UpdatedGrantsLockDate(date);
        return true;
    }

    /**
     * @dev Function to extend the transfer locking periods up to one more
     *      week. Must be executed before the current public release date.
     * @param delay The amount of hours to extend the locking period.
     * @return True if the operation was successful.
     */
    function extendLockPeriods(uint delay, bool extendGrantLock) onlyOwner public returns (bool success) {
        require(now < publicRelease && 0 < delay && delay <= 168);
        delay = delay * 3600;
        publicRelease = publicRelease.add(delay);
        partnersRelease = partnersRelease.add(delay);
        assert(publicRelease <= partnersRelease);
        UpdatedPublicReleaseDate(publicRelease);
        UpdatedPartnersReleaseDate(partnersRelease);
        if (extendGrantLock) {
            grantsUnlock = grantsUnlock.add(delay);
            assert(grantsUnlock < partnersRelease);
            UpdatedGrantsLockDate(grantsUnlock);
        }
        return true;
    }

}