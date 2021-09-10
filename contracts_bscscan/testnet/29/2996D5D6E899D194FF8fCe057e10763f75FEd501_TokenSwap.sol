/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

pragma solidity ^0.6.0;

// https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/
// https://github.com/OpenZeppelin/openzeppelin-sdk/tree/master/packages/lib/contracts
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



abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public{
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}
/**
 * Swap old 1ST token to new DAWN token.
 *
 * Recoverable allows us to recover any wrong ERC-20 tokens user send here by an accident.
 *
 * This contract *is not* behind a proxy.
 * We use Initializable pattern here to be in line with the other contracts.
 * Normal constructor would work as well, but then we would be mixing
 * base contracts from openzeppelin-contracts and openzeppelin-sdk both,
 * which is a huge mess.
 *
 * We are not using SafeMath here, as we are not doing accounting math.
 * user gets out the same amount of tokens they send in.
 *
 */
contract TokenSwap is Initializable, Ownable {

  /* Token coming for a burn */
  IERC20 public oldToken;

  /* Token sent to the swapper */
  IERC20 public newToken;

  /* Where old tokens are send permantly to die */
  address public burnDestination;

  /* Public key of our server-side signing mechanism to ensure everyone who calls swap is whitelisted */
  address public signerAddress;

  /* How many tokens we have successfully swapped */
  uint public totalSwapped;

  /* For following in the dashboard */
  event Swapped(address indexed owner, uint amount);

  /** When the contract owner sends old token to burn address */
  event LegacyBurn(uint amount);

  /** The server-side signer key has been updated */
  event SignerUpdated(address addr);

  /**
   *
   * 1. Owner is a multisig wallet
   * 2. Owner holds newToken supply
   * 3. Owner does approve() on this contract for the full supply
   * 4. Owner can pause swapping
   * 5. Owner can send tokens to be burned
   *
   */
  function initialize(address owner, address signer, address _oldToken, address _newToken, address _burnDestination)
    public initializer {

    // Note: ReentrancyGuard.initialze() was added in OpenZeppelin SDK 2.6.0, we are using 2.5.0
    // ReentrancyGuard.initialize();

    // Deployer account holds temporary ownership until the setup is done
    setSignerAddress(signer);

    transferOwnership(owner);

    _setBurnDestination(_burnDestination);

    oldToken = IERC20(_oldToken);
    newToken = IERC20(_newToken);
    require(oldToken.totalSupply() == newToken.totalSupply(), "Cannot create swap, old and new token supply differ");

  }

  function _swap(address whom, uint amount) internal {
    // Move old tokens to this contract
    address swapper = address(this);
    // We have added some user friendly error messages here if they
    // somehow manage to screw interaction
    totalSwapped += amount;
    require(oldToken.transferFrom(whom, swapper, amount), "Could not retrieve old tokens");
    require(newToken.transferFrom(owner(), whom, amount), "Could not send new tokens");
  }


  /**
   * A server-side whitelisted address can swap their tokens.
   *
   * Please note that after whitelisted once, the address can call this multiple times. This is intentional behavior.
   * As whitelisting per transaction is extra complexite that does not server any business goal.
   *
   */
  function swapTokensForSender(uint amount) public {
    address swapper = address(this);
    require(oldToken.allowance(msg.sender, swapper) >= amount, "You need to first approve() enough tokens to swap for this contract");
    require(oldToken.balanceOf(msg.sender) >= amount, "You do not have enough tokens to swap");
    _swap(msg.sender, amount);

    emit Swapped(msg.sender, amount);
  }

  /**
   * How much new tokens we have loaded on the contract to swap.
   */
  function getTokensLeftToSwap() public view returns(uint) {
    return newToken.allowance(owner(), address(this));
  }

  /**
   * Allows admin to burn old tokens
   *
   * Note that the owner could recoverToken() here,
   * before tokens are burned. However, the same
   * owner can upload the code payload of the new token,
   * so the trust risk for this to happen is low compared
   * to other trust risks.
   */
  function burn(uint amount) public onlyOwner {
    require(oldToken.transfer(burnDestination, amount), "Could not send tokens to burn");
    emit LegacyBurn(amount);
  }

  /**
   * Set the address (0x0000) where we are going to send burned tokens.
   */
  function _setBurnDestination(address _destination) internal {
    burnDestination = _destination;
  }

  /**
   * Allow to cycle the server-side signing key.
   */
  function setSignerAddress(address _signerAddress) public onlyOwner {
    signerAddress = _signerAddress;
    emit SignerUpdated(signerAddress);
  }

}