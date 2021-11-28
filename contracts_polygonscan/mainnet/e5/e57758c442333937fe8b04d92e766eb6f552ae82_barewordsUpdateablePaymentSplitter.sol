/**
 *Submitted for verification at polygonscan.com on 2021-11-28
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

// File: payment splitter.sol


pragma solidity ^0.8.10;


interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract barewordsUpdateablePaymentSplitter is Ownable {

  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalShares;
  uint256 private _totalReleased;
  mapping(address => uint256) private _totalReleasedERC20;

  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  mapping(address => mapping(address => uint256)) private _releasedERC20;
  address[] private _payees;
  address[] private _supportedERC20;

  /**
   * @dev Constructor
   */
  constructor(address[] memory payees, uint256[] memory shareAmounts) payable {
    require(payees.length == shareAmounts.length);
    require(payees.length > 0);

    for (uint256 i = 0; i < payees.length; i++) {
      _addPayee(payees[i], shareAmounts[i]);
    }
  }

  function addSupportedERC20(address tokenAddress) public onlyOwner {
    _supportedERC20.push(tokenAddress);
  }
  
  function updatePayeesAndShares(address[] memory newPayees, uint256[] memory shareAmounts) public onlyOwner {
    for (uint256 j = 0; j < _supportedERC20.length; j++) {
      _totalReleasedERC20[_supportedERC20[j]] = 0;
    }
    _totalReleased = 0;
    _totalShares = 0; // reset released amount and shares to not overpay new payees
    address[] memory emptyPayees;
    for (uint256 i = 0; i < _payees.length; i++) {
      _shares[_payees[i]] = 0; // reset shares of existing payees
    }
    _payees = emptyPayees; // empty current payees
    
    for (uint256 i = 0; i < newPayees.length; i++) {
      _addPayee(newPayees[i], shareAmounts[i]); // add all new payees and their shares
    }
  }

  /**
   * @dev payable fallback
   */
  fallback() external payable {
    emit PaymentReceived(msg.sender, msg.value);
  }
  
  receive() external payable {
    emit PaymentReceived(msg.sender, msg.value);
  }

  /**
   * @return the total shares of the contract.
   */
  function totalShares() public view returns(uint256) {
    return _totalShares;
  }

  /**
   * @return the total amount already released.
   */
  function totalReleased() public view returns(uint256) {
    return _totalReleased;
  }

  /**
   * @return the shares of an account.
   */
  function shares(address account) public view returns(uint256) {
    return _shares[account];
  }

  /**
   * @return the amount already released to an account.
   */
  function released(address account) public view returns(uint256) {
    return _released[account];
  }

  /**
   * @return the address of a payee.
   */
  function payee(uint256 index) public view returns(address) {
    return _payees[index];
  }

  /**
   * @dev Release one of the payee's proportional payment.
   * @param account Whose payments will be released.
   */
  function release(address account) public {
    require(_shares[account] > 0);

    uint256 totalReceived = address(this).balance + _totalReleased;
    uint256 payment = totalReceived * _shares[account] / _totalShares - _released[account];

    require(payment > 0);

    _released[account] = _released[account] + payment;
    _totalReleased = _totalReleased + payment;

    payable(account).transfer(payment);
    emit PaymentReleased(account, payment);
  }

  function releaseToken(address tokenAddress, address account) external {
    bool found = false;
    for (uint256 i; i<_supportedERC20.length; i++) {
      if (_supportedERC20[i] == tokenAddress) {
        found = true;
      }
    }
    require(found, "Token is not supported");
    require(_shares[account] > 0);
    IERC20 tokenContract = IERC20(tokenAddress);
    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

    uint256 totalReceived = balance + _totalReleasedERC20[tokenAddress];
    
    uint256 payment = totalReceived * _shares[account] / _totalShares - _releasedERC20[tokenAddress][account];

    require(payment > 0);

    _releasedERC20[tokenAddress][account] = _releasedERC20[tokenAddress][account] + payment;
    _totalReleasedERC20[tokenAddress] = _totalReleasedERC20[tokenAddress] + payment;

    tokenContract.transfer(account, payment);
    emit PaymentReleased(account, payment);

  }

  /**
   * @dev Add a new payee to the contract.
   * @param account The address of the payee to add.
   * @param shares_ The number of shares owned by the payee.
   */
  function _addPayee(address account, uint256 shares_) private {
    require(account != address(0));
    require(shares_ > 0);
    require(_shares[account] == 0);

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;
    emit PayeeAdded(account, shares_);
  }
}