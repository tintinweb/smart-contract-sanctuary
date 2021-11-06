/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.8.0;

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

// File: contracts/INO_HERA.sol


pragma solidity ^0.8.0;





interface IHERA721 {
  function mintTo(address to, uint256 amount)
    external
    returns (uint256 startTokenId, uint256 toTokenId);
}

contract INO is Ownable, Pausable {
  address public _heraToken;
  address public _hera721Token;
  uint16 public _levelOneRefRate;
  uint16 public _levelTwoRefRate;
  Stage public _stage;

  mapping(address => uint16) private _allocated;
  mapping(address => uint16) private _remainingAllocation;
  mapping(BoxLevel => Box) private _boxes;

  enum Stage {
    WHITELISTED,
    PUBLIC
  }
  enum BoxLevel {
    SILVER,
    GOLD,
    DIAMOND
  }

  struct Box {
    uint256 price;
    uint16 totalSupply;
    uint16 stock;
  }

  event Bought(
    address indexed _user,
    BoxLevel level,
    uint16 amount,
    uint256 _startTokenId,
    uint256 _toTokenId
  );

  constructor(
    address heraToken,
    address hera721Token,
    Box memory silverBox,
    Box memory goldBox,
    Box memory diamondBox,
    uint16 levelOneRefRate,
    uint16 levelTwoRefRate
  ) {
    _heraToken = heraToken;
    _hera721Token = hera721Token;
    _boxes[BoxLevel.SILVER] = silverBox;
    _boxes[BoxLevel.GOLD] = goldBox;
    _boxes[BoxLevel.DIAMOND] = diamondBox;
    _levelOneRefRate = levelOneRefRate;
    _levelTwoRefRate = levelTwoRefRate;
    _stage = Stage.WHITELISTED;
  }

  function setAllocations(
    address[] calldata users,
    uint16[] calldata allocations
  ) external onlyOwner {
    for (uint16 i = 0; i < users.length; i++) {
      _allocated[users[i]] = allocations[i];
      _remainingAllocation[users[i]] = allocations[i];
    }
  }

  function buy(
    BoxLevel level,
    uint16 amount,
    address[] calldata refs
  ) external whenNotPaused {
    require(amount > 0, 'Amount must be greater than zero');
    require(amount <= _boxes[level].stock, 'Not enough stock');

    if (_stage == Stage.WHITELISTED) {
      require(
        amount <= _remainingAllocation[_msgSender()],
        'Amount exceeds remaining allocation'
      );
      _remainingAllocation[_msgSender()] -= amount;
    }

    uint256 totalPrice = _boxes[level].price * amount;
    IERC20 t = IERC20(_heraToken);

    t.transferFrom(_msgSender(), address(this), totalPrice);
    (uint256 startTokenId, uint256 toTokenId) = IHERA721(_hera721Token).mintTo(
      _msgSender(),
      amount
    );
    _boxes[level].stock -= amount;

    if (refs.length == 2) {
      t.transfer(refs[0], (totalPrice * _levelOneRefRate) / 10000);
      t.transfer(refs[1], (totalPrice * _levelTwoRefRate) / 10000);
    } else if (refs.length == 1) {
      t.transfer(refs[0], (totalPrice * _levelOneRefRate) / 10000);
    }

    emit Bought(_msgSender(), level, amount, startTokenId, toTokenId);
  }

  function changeStage(Stage stage) external onlyOwner {
    _stage = stage;
  }

  /* For FE
        0: HERA address
        1: HERA721 address
        2: stage
            1: WHITELISTED
            2: PUBLIC
        3: silver box
        4: gold box
        5: diamond box
    */
  function info()
    public
    view
    returns (
      address,
      address,
      Stage,
      Box memory,
      Box memory,
      Box memory
    )
  {
    return (
      _heraToken,
      _hera721Token,
      _stage,
      _boxes[BoxLevel.SILVER],
      _boxes[BoxLevel.GOLD],
      _boxes[BoxLevel.DIAMOND]
    );
  }

  /* For FE
        0: allocated
        2: remaining allocation
    */
  function infoWallet(address user) public view returns (uint16, uint16) {
    return (_allocated[user], _remainingAllocation[user]);
  }

  function transferToken(
    address token,
    uint256 amount,
    address to
  ) external onlyOwner {
    IERC20 t = IERC20(token);

    require(
      t.balanceOf(address(this)) >= amount,
      'Insufficent token balance to transfer amount'
    );
    t.transfer(to, amount);
  }
  
  function changeHeraToken(address heraToken) external onlyOwner {
      _heraToken = heraToken;
  }
  
  function changeHera721Token(address hera721Token) external onlyOwner {
      _hera721Token = hera721Token;
  }
}