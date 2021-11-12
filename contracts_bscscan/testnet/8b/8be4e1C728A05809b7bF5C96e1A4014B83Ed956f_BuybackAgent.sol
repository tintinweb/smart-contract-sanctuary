// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/dex/IPancakeRouter02.sol";
import "./interfaces/dex/IPancakeFactory.sol";
import "./interfaces/dex/IWETH.sol";
import "./interfaces/IBuyback.sol";
import "./utils/EmergencyWithdraw.sol";
import "./utils/AntiWhale.sol";
import "./utils/TradingGuard.sol";
import "./utils/CoinDexTools.sol";

contract BuybackAgent is IBuyback, EmergencyWithdraw, ReentrancyGuardUpgradeable, CoinDexTools {
  uint private constant _RATE_NOMINATOR = 10000;
  IPancakeFactory private _factory;
  IWETH private _WETH;

  // senders[user][from token] => pending
  mapping(address => mapping(address => uint)) public senders;

  /**
   * @dev Upgradable initializer
   */
  function __BuybackAgent_init(address _router) public initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    setRouter(_router);
  }

  /**
   * @dev Set exchange router
   * @param _router address of main token
   */
  function setRouter(address _router) public override onlyOwner {
    router = _router;
    IPancakeRouter02 router_ = IPancakeRouter02(router);
    _factory = IPancakeFactory(router_.factory());
    _WETH = IWETH(router_.WETH());
  }

  /**
   * @dev Solve pending tax
   */
  function getLP(address _token) public view override returns (address) {
    return _factory.getPair(address(_token), address(_WETH));
  }

  /**
   * @dev Get transaction type
   * 0: transfer
   * 1: buy
   * 2: sell
   * 3: remove lp
   */
  function getTransactionType(
    address _spender,
    address _sender,
    address _recipient,
    address _token
  ) public view override returns (uint) {
    address lp_ = getLP(_token);
    // Trigger from router
    bool isViaRouter = _spender == router;
    // Trigger from lp pair
    bool isViaLP = _spender == lp_;
    // Check is to user = _to not router && not lp
    bool isToUser = (_recipient != lp_ && _recipient != router);
    // Check is from user = _from not router && not lp
    bool isFromUser = (_sender != lp_ && _sender != router);
    // In case buy: LP transfer to user directly
    bool isBuy = isViaLP && _sender == lp_ && isToUser;
    if (isBuy) return 1;
    // In case sell (Same with add LP case): User send to LP via router (using transferFrom)
    bool isSell = isViaRouter && (isFromUser && _recipient == lp_);
    if (isSell) return 2;
    // In case remove LP
    bool isRemoveLP = (_sender == lp_ && _recipient == router) || (_sender == router && isToUser);
    if (isRemoveLP) return 3;
    return 0;
  }

  /**
   * @dev Estimate buyback amount by tax
   */
  function estimateTaxAmount(
    address _spender,
    address _sender,
    address _recipient,
    address _token,
    uint _amount,
    uint _tax
  ) external view override returns (uint _taxAmount, bool _canAutoTax) {
    uint code_ = getTransactionType(_spender, _sender, _recipient, _token);
    if (code_ != 3 && !(_sender == address(this) || _recipient == address(this))) {
      return ((_amount * _tax) / _RATE_NOMINATOR, code_ != 1);
    }
    return (0, false);
  }

  /**
   * @dev Deposit taxed amount
   */
  function depositTax(address _fromToken, uint _amount) external override {
    IERC20 token_ = IERC20(_fromToken);
    uint previousBalance_ = token_.balanceOf(address(this));
    token_.transferFrom(msg.sender, address(this), _amount);
    uint newBalance_ = token_.balanceOf(address(this));
    uint addedAmount_ = newBalance_ - previousBalance_;
    senders[msg.sender][_fromToken] += addedAmount_;
  }

  /**
   * @dev Solve pending tax
   * We need use correct current balance which not include transferred amount built in transaction
   */
  function solvePendingTax(
    address _fromToken,
    address _buybackToken,
    address _recipient,
    uint _debt
  ) external override {
    uint bal_ = IERC20(_fromToken).balanceOf(address(this)) - _debt;
    uint pending_ = senders[msg.sender][_fromToken];
    if (pending_ > bal_) {
      pending_ = bal_;
    }
    bal_ -= pending_;
    if (pending_ > 0) {
      IERC20 buybackToken_ = IERC20(_buybackToken);
      uint previousBalance_ = buybackToken_.balanceOf(address(this));
      _swapTokensForTokens(_fromToken, _buybackToken, pending_, address(this), true);
      uint newBalance_ = buybackToken_.balanceOf(address(this));
      uint buybackAmount_ = newBalance_ - previousBalance_;
      buybackToken_.transfer(_recipient, buybackAmount_);
      pending_ = 0;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TradingGuard is OwnableUpgradeable {
  // Config structure
  struct TradingConfig {
    bool enabled;
    uint maxAmount;
    uint minAmount;
  }

  TradingConfig public buyConfig;
  TradingConfig public sellConfig;
  TradingConfig public transferConfig;

  /**
   * @dev update trading config
   * @param _config TradingConfig object
   * @param _code 0: transfer, 1: buy, otherwise: sell
   */
  function updateTradingConfig(TradingConfig memory _config, uint _code) public onlyOwner {
    TradingConfig storage config;
    if (_code == 0) config = transferConfig;
    else if (_code == 1) config = buyConfig;
    else config = sellConfig;

    config.enabled = _config.enabled;
    config.maxAmount = _config.maxAmount;
    config.minAmount = _config.minAmount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmergencyWithdraw is OwnableUpgradeable {
  event Received(address sender, uint amount);

  /**
   * @dev allow contract to receive ethers
   */
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  /**
   * @dev get the eth balance on the contract
   * @return eth balance
   */
  function getEthBalance() external view returns (uint) {
    return address(this).balance;
  }

  /**
   * @dev withdraw eth balance
   */
  function emergencyWithdrawEthBalance(address _to, uint _amount) external onlyOwner {
    payable(_to).transfer(_amount);
  }

  /**
   * @dev get the token balance
   * @param _tokenAddress token address
   */
  function getTokenBalance(address _tokenAddress) external view returns (uint) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
   * @dev withdraw token balance
   * @param _tokenAddress token address
   */
  function emergencyWithdrawTokenBalance(
    address _tokenAddress,
    address _to,
    uint _amount
  ) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(_to, _amount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/dex/IPancakeRouter02.sol";
import "../interfaces/dex/IPancakeFactory.sol";

contract CoinDexTools is OwnableUpgradeable {
  address public router;
  address public deadAddress;

  event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
  event SwapTokensForTokens(
    address _tokenAddressFrom,
    address _tokenAddressTo,
    uint256 _tokenAmount,
    address _to,
    bool _keepWETH
  );

  /**
   * @dev Upgradable initializer
   */
  function __CoinDexTools_init() internal virtual initializer {
    deadAddress = 0x000000000000000000000000000000000000dEaD;
  }

  /**
   * @dev set exchange router
   * @param _router address of main token
   */
  function setRouter(address _router) external virtual onlyOwner {
    router = _router;
  }

  /**
   * @dev set the zero Address
   * @param _deadAddress address of zero
   */
  function setDeadAddress(address _deadAddress) external virtual onlyOwner {
    deadAddress = _deadAddress;
  }

  /**
   * @dev swap tokens. Auto swap to ETH directly if _tokenAddressTo == weth
   * @param _tokenAddressFrom address of from token
   * @param _tokenAddressTo address of to token
   * @param _tokenAmount amount of tokens
   * @param _to recipient
   * @param _keepWETH For _tokenAddressTo == weth, _keepWETH = true if you want to keep output WETH instead of ETH native
   */
  function _swapTokensForTokens(
    address _tokenAddressFrom,
    address _tokenAddressTo,
    uint256 _tokenAmount,
    address _to,
    bool _keepWETH
  ) internal virtual {
    IERC20(_tokenAddressFrom).approve(router, _tokenAmount);

    address weth = IPancakeRouter02(router).WETH();
    bool isNotToETH = _tokenAddressTo != weth;
    address[] memory path;
    if (isNotToETH) {
      path = new address[](3);
      path[0] = _tokenAddressFrom;
      path[1] = weth;
      path[2] = _tokenAddressTo;
    } else {
      path = new address[](2);
      path[0] = _tokenAddressFrom;
      path[1] = weth;
    }

    // Make the swap
    if (isNotToETH || _keepWETH) {
      IPancakeRouter02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
        _tokenAmount,
        0,
        path,
        _to,
        block.timestamp
      );
    } else {
      IPancakeRouter02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
        _tokenAmount,
        0,
        path,
        _to,
        block.timestamp
      );
    }

    emit SwapTokensForTokens(_tokenAddressFrom, _tokenAddressTo, _tokenAmount, _to, _keepWETH);
  }

  /**
   * @dev swap tokens to ETH
   * @param _tokenAddress address of from token
   * @param _tokenAmount amount of tokens
   * @param _to recipient
   */
  function _swapTokensForETH(
    address _tokenAddress,
    uint256 _tokenAmount,
    address _to
  ) internal virtual {
    _swapTokensForTokens(_tokenAddress, IPancakeRouter02(router).WETH(), _tokenAmount, _to, false);
  }

  /**
   * @dev add liquidity in pair
   * @param _tokenAddress address of token
   * @param _tokenAmount amount of tokens
   * @param _ethAmount amount of eth tokens
   * @param _to recipient
   */
  function _addLiquidityETH(
    address _tokenAddress,
    uint256 _tokenAmount,
    uint256 _ethAmount,
    address _to
  ) internal virtual {
    // approve token transfer to cover all possible scenarios
    IERC20(_tokenAddress).approve(router, _tokenAmount);

    // add the liquidity
    IPancakeRouter02(router).addLiquidityETH{ value: _ethAmount }(
      address(_tokenAddress),
      _tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      _to,
      block.timestamp
    );
  }

  /**
   * @dev swap tokens and add liquidity
   * @param _tokenAddress address of token
   * @param _tokenAmount amount of tokens
   * @param _to recipient
   */
  function _swapAndLiquify(
    address _tokenAddress,
    uint256 _tokenAmount,
    address _to
  ) internal virtual {
    // split the contract balance into halves
    uint256 half = _tokenAmount / 2;
    if (half > 0) {
      uint256 otherHalf = _tokenAmount - half;

      // capture the contract's current ETH balance.
      // this is so that we can capture exactly the amount of ETH that the
      // swap creates, and not make the liquidity event include any ETH that
      // has been manually sent to the contract
      uint256 initialBalance = address(this).balance;

      // swap tokens for ETH
      _swapTokensForETH(_tokenAddress, half, address(this));

      // how much ETH did we just swap into?
      uint256 swappedETHAmount = address(this).balance - initialBalance;

      // add liquidity to dex
      if (swappedETHAmount > 0) {
        _addLiquidityETH(_tokenAddress, otherHalf, swappedETHAmount, _to);
        emit SwapAndLiquify(half, swappedETHAmount, otherHalf);
      }
    }
  }

  /**
   * @dev burn by transfer to dead address
   * @param _tokenAddress address of token
   * @param _tokenAmount amount of tokens
   */
  function _burnByDeadAddress(address _tokenAddress, uint256 _tokenAmount) internal virtual {
    IERC20(_tokenAddress).transfer(deadAddress, _tokenAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AntiWhale is OwnableUpgradeable {
  uint256 public startDate;
  uint256 public endDate;
  uint256 public limitWhale;
  bool public antiWhaleActivated;

  /**
   * @dev activate antiwhale
   */
  function activateAntiWhale() external onlyOwner {
    require(antiWhaleActivated == false, "Already activated");
    antiWhaleActivated = true;
  }

  /**
   * @dev deactivate antiwhale
   */
  function deActivateAntiWhale() external onlyOwner {
    require(antiWhaleActivated == true, "Already activated");
    antiWhaleActivated = false;
  }

  /**
   * @dev set antiwhale settings
   * @param _startDate start date of the antiwhale
   * @param _endDate end date of the antiwhale
   * @param _limitWhale limit amount of antiwhale
   */
  function setAntiWhale(
    uint256 _startDate,
    uint256 _endDate,
    uint256 _limitWhale
  ) external onlyOwner {
    startDate = _startDate;
    endDate = _endDate;
    limitWhale = _limitWhale;
    antiWhaleActivated = true;
  }

  /**
   * @dev check if antiwhale is enable and amount should be less than to whale in specify duration
   * @param _from from address
   * @param _to to address
   * @param _amount amount to check antiwhale
   */
  function isWhale(
    address _from,
    address _to,
    uint256 _amount
  ) public view returns (bool) {
    if (_from == owner() || _to == owner() || antiWhaleActivated == false || _amount <= limitWhale) return false;

    if (block.timestamp >= startDate && block.timestamp <= endDate) return true;

    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IWETH {
  function deposit() external payable;

  function transfer(address to, uint value) external returns (bool);

  function withdraw(uint) external;

  function approve(address spender, uint value) external;

  function balanceOf(address account) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakeRouter01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  )
    external
    payable
    returns (
      uint amountToken,
      uint amountETH,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
  ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountA, uint amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint amountToken, uint amountETH);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapTokensForExactTokens(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function swapTokensForExactETH(
    uint amountOut,
    uint amountInMax,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapETHForExactTokens(
    uint amountOut,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function quote(
    uint amountA,
    uint reserveA,
    uint reserveB
  ) external pure returns (uint amountB);

  function getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountOut);

  function getAmountIn(
    uint amountOut,
    uint reserveIn,
    uint reserveOut
  ) external pure returns (uint amountIn);

  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPancakeFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint) external view returns (address pair);

  function allPairsLength() external view returns (uint);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IBuyback {
  /**
   * @dev Buy back config
   */
  struct Info {
    IBuyback agent; // buyback agent address
    address token; // buyback token address
    uint tax; // buyback tax
    address burn; // burn address
  }

  /**
   * @dev Get transaction type
   * 0: transfer
   * 1: buy
   * 2: sell
   * 3: remove lp
   */
  function getTransactionType(
    address _spender,
    address _sender,
    address _recipient,
    address _token
  ) external view returns (uint);

  /**
   * @dev Return LP address
   */
  function getLP(address _token) external view returns (address _lpAddress);

  /**
   * @dev Estimate buyback amount by tax
   */
  function estimateTaxAmount(
    address _spender,
    address _sender,
    address _recipient,
    address _token,
    uint _amount,
    uint _tax
  ) external view returns (uint _taxAmount, bool _canAutoTax);

  /**
   * @dev Deposit taxed amount
   */
  function depositTax(address _fromToken, uint _amount) external;

  /**
   * @dev Solve pending tax
   */
  function solvePendingTax(
    address _fromToken,
    address _buybackToken,
    address _recipient,
    uint _debt
  ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}