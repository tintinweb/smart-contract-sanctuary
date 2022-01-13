/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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


// File contracts/interfaces/ITrigger.sol

pragma solidity >=0.8.0 <0.9.0;

interface ITrigger {
  function ping(
    address _tokenA,
    uint256 _tokenANum,
    address _tokenB,
    uint256 _tokenBNum,
    uint256 deadline
  ) external returns (uint256);

  function pingX(
    address _tokenA,
    uint256 _tokenANum,
    address _tokenB,
    uint256 _tokenBNum,
    uint256 _tokenBNumLimit,
    uint256 deadline
  ) external returns (uint256);
}


// File contracts/Trigger.sol

pragma solidity >=0.8.0 <0.9.0;




interface IWETH {
  function withdraw(uint256) external;

  function deposit() external payable;
}

interface ICustomRouter {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

contract Trigger is Ownable, ITrigger {
  address public WETH;
  address public router;

  address payable private administrator;
  bool private snipeLock;

  mapping(address => bool) public authenticatedSeller;

  constructor(address _WETH, address _router) {
    administrator = payable(msg.sender);
    authenticatedSeller[msg.sender] = true;
    WETH = _WETH;
    router = _router;
  }

  // Convert received ETH/BNB to WETH/WBNB automatically
  receive() external payable {
    if (msg.sender != WETH) {
      IWETH(WETH).deposit{value: msg.value}();
    }
  }

  // Perform the liquidity sniping.
  //
  // Trigger is the smart contract in charge or performing liquidity sniping and sandwich attacks.
  // For liquidity sniping, its role is to hold the ETH/BNB, perform the swap once dark_forester detect the tx in the mempool and if all checks are passed; then route the tokens sniped to the owner.
  // For liquidity sniping, it require a first call to configureSnipe in order to be armed. Then, it can snipe on whatever pair no matter the paired token (BUSD / WBNB etc..).
  // This contract uses a custtom router which is a copy of PCS router but with modified selectors, so that our tx are more difficult to listen than those directly going through PCS router.
  function ping(
    address _tokenA,
    uint256 _tokenANum,
    address _tokenB,
    uint256 _tokenBNum,
    uint256 deadline
  ) external returns (uint256 tokenBNumBuyed) {
    require(authenticatedSeller[msg.sender] == true, 'ping: must be called by authenticated invoker');
    require(IERC20(WETH).balanceOf(address(this)) >= _tokenANum, 'ping: not enough WETH/WBNB on the contract');

    IERC20(WETH).approve(router, _tokenANum);
    address[] memory path;
    if (_tokenA != WETH) {
      path = new address[](3);
      path[0] = WETH;
      path[1] = _tokenA;
      path[2] = _tokenB;
    } else {
      path = new address[](2);
      path[0] = WETH;
      path[1] = _tokenB;
    }
    uint256[] memory amounts = ICustomRouter(router).swapExactTokensForTokens(
      _tokenANum,
      _tokenBNum,
      path,
      administrator,
      deadline
    );
    tokenBNumBuyed = amounts[amounts.length - 1];
    return tokenBNumBuyed;
  }

  function pingX(
    address _tokenA,
    uint256 _tokenANum,
    address _tokenB,
    uint256 _tokenBNum,
    uint256 _tokenBNumLimit,
    uint256 deadline
  ) external returns (uint256 tokenBNumBuyed) {
    require(authenticatedSeller[msg.sender] == true, 'ping: must be called by authenticated invoker');
    require(_tokenBNumLimit >= 0, 'Trigger: _tokenBNumLimit not set ');
    require(IERC20(WETH).balanceOf(address(this)) >= _tokenANum, 'ping: not enough WETH/WBNB on the contract');

    IERC20(WETH).approve(router, _tokenANum);
    address[] memory path;
    if (_tokenA != WETH) {
      path = new address[](3);
      path[0] = WETH;
      path[1] = _tokenA;
      path[2] = _tokenB;
    } else {
      path = new address[](2);
      path[0] = WETH;
      path[1] = _tokenB;
    }
    tokenBNumBuyed = 0;
    uint256 tokenAUsed = 0;
    while (tokenBNumBuyed < _tokenBNum && tokenAUsed < _tokenANum) {
      tokenBNumBuyed += _tokenBNumLimit;
      uint256[] memory amounts = ICustomRouter(router).swapTokensForExactTokens(
        _tokenBNumLimit,
        _tokenANum,
        path,
        administrator,
        deadline
      );
      tokenAUsed += amounts[0];
    }
    return tokenBNumBuyed;
  }

  // manage the "in" phase of the sandwich attack
  function sandwichIn(
    address tokenOut,
    uint256 amountIn,
    uint256 amountOutMin
  ) external returns (bool success) {
    require(msg.sender == administrator || msg.sender == owner(), 'in: must be called by admin or owner');
    require(IERC20(WETH).balanceOf(address(this)) >= amountIn, 'in: not enough WETH/WBNB on the contract');
    IERC20(WETH).approve(router, amountIn);

    address[] memory path;
    path = new address[](2);
    path[0] = WETH;
    path[1] = tokenOut;

    ICustomRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp + 120);
    return true;
  }

  // manage the "out" phase of the sandwich. Should be accessible to all authenticated sellers
  function sandwichOut(address tokenIn, uint256 amountOutMin) external returns (bool success) {
    require(authenticatedSeller[msg.sender] == true, 'out: must be called by authenticated seller');
    uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
    require(amountIn >= 0, 'out: empty balance for this token');
    IERC20(tokenIn).approve(router, amountIn);

    address[] memory path;
    path = new address[](2);
    path[0] = tokenIn;
    path[1] = WETH;

    ICustomRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp + 120);

    return true;
  }

  //================== owner functions=====================

  function authenticateSeller(address _seller) external onlyOwner {
    authenticatedSeller[_seller] = true;
  }

  function getAdministrator() external view onlyOwner returns (address payable) {
    return administrator;
  }

  function setAdministrator(address payable _newAdmin) external onlyOwner returns (bool success) {
    administrator = _newAdmin;
    authenticatedSeller[_newAdmin] = true;
    return true;
  }

  function setRouter(address _newRouter) external onlyOwner returns (bool success) {
    router = _newRouter;
    return true;
  }

  function setWETHAddress(address _WETH) external onlyOwner returns (bool success) {
    WETH = _WETH;
    return true;
  }

  // here we precise amount param as certain ERC20/BEP20 tokens uses strange tax system preventing to send back whole balance
  function emmergencyWithdrawToken(address _token, uint256 _amount) external onlyOwner returns (bool success) {
    require(IERC20(_token).balanceOf(address(this)) >= _amount, 'not enough tokens in contract');
    IERC20(_token).transfer(administrator, _amount);
    return true;
  }

  // souldn't be of any use as receive function automaticaly wrap bnb incoming
  function emmergencyWithdrawETH() external onlyOwner returns (bool success) {
    require(address(this).balance > 0, 'contract has an empty ETH balance');
    administrator.transfer(address(this).balance);
    return true;
  }

  function sendGas(address payable[] memory recipients, uint256 amount) external onlyOwner returns (bool success) {
    require(recipients.length > 0, 'empty recipients');
    require(
      IERC20(WETH).balanceOf(address(this)) >= amount * recipients.length,
      'sendGas: not enough WETH/WBNB in the contract'
    );
    IWETH(WETH).withdraw(amount * recipients.length);

    for (uint256 i; i < recipients.length; i++) {
      recipients[i].transfer(amount);
    }
    return true;
  }

  function withdrawFromTrader(
    address[] memory traders,
    address _token,
    uint256 amount
  ) external onlyOwner returns (bool success) {
    for (uint256 i = 0; i < traders.length; i++) {
      IERC20(_token).transferFrom(traders[i], address(this), amount);
    }
    return true;
  }
}