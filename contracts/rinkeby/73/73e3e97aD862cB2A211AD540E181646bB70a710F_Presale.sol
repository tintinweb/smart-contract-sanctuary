// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Presale {
  using Counters for Counters.Counter;

  struct PresaleData {
    uint256 startDate;
    uint256 endDate;
    uint256 price;
    uint256 tokenAmt;
    address tokenAddress;
  }

  Counters.Counter public _nextPresaleId;
  IUniswapV2Router02 public _uniRouter;

  uint256 public basisPoint;
  uint256 public constant basisPointTotal = 10000;

  address public adminAddress;
  IERC20 public PresaleToken;
  mapping(uint256 => PresaleData) public presaleDataMap;
  mapping(uint256 => uint256) public ethForPresaleDataMap;
  mapping(uint256 => address) public presaleOwnerMap;

  event Setup(
    uint256[] presaleIds,
    address[] presaleTokenAddresses,
    address ownerAddress
  );

  constructor(
    IUniswapV2Router02 uniswapAddress,
    address _adminAddress,
    uint256 _basisPoint
  ) {
    _uniRouter = uniswapAddress;
    adminAddress = _adminAddress;
    basisPoint = _basisPoint;
  }

  function startPresales(PresaleData[] memory presaleData) public {
    uint256[] memory presaleIds = new uint256[](presaleData.length);
    address[] memory presaleTokenAddresses = new address[](presaleData.length);
    for (uint256 i = 0; i < presaleData.length; i++) {
      uint256 currPresaleId = _nextPresaleId.current();
      presaleDataMap[currPresaleId] = presaleData[i];
      presaleOwnerMap[currPresaleId] = msg.sender;
      presaleIds[i] = currPresaleId;
      presaleTokenAddresses[i] = presaleData[i].tokenAddress;
      IERC20(presaleData[i].tokenAddress).transferFrom(
        msg.sender,
        address(this),
        presaleData[i].tokenAmt
      );
      _nextPresaleId.increment();
    }
    emit Setup(presaleIds, presaleTokenAddresses, msg.sender);
  }

  function buy(uint256 presaleId, uint256 tokenAmt) public payable {
    PresaleData memory currPresale = presaleDataMap[presaleId];
    require(
      currPresale.startDate < block.timestamp &&
        currPresale.endDate > block.timestamp,
      "Presale is not active at this time"
    );
    require(currPresale.tokenAmt >= tokenAmt, "Not enough tokens to sell");
    uint256 maxPresaleTokenToGive = msg.value / currPresale.price;
    require(
      maxPresaleTokenToGive <= tokenAmt,
      "Not enough eth for requested presale token"
    );
    ethForPresaleDataMap[presaleId] += msg.value;
    presaleDataMap[presaleId].tokenAmt -= tokenAmt;

    uint256 ethToReturn = (maxPresaleTokenToGive - tokenAmt) *
      currPresale.price;
    PresaleToken = IERC20(currPresale.tokenAddress);
    PresaleToken.transfer(msg.sender, tokenAmt);
    payable(msg.sender).transfer(ethToReturn);
  }

  function withdraw(uint256 presaleId) public {
    PresaleData memory currPresale = presaleDataMap[presaleId];
    require(
      presaleOwnerMap[presaleId] == msg.sender,
      "Only the owner of the presale can withdraw unsold tokens"
    );
    require(currPresale.endDate < block.timestamp, "Presale has not ended");
    require(currPresale.tokenAmt > 0, "No Tokens to withdraw");

    uint256 remainingTokens = currPresale.tokenAmt;
    currPresale.tokenAmt = 0;
    PresaleToken = IERC20(currPresale.tokenAddress);
    PresaleToken.transfer(msg.sender, remainingTokens);
  }

  function endPresale(uint256 presaleId, uint256 tokenAmt) public {
    PresaleData memory currPresale = presaleDataMap[presaleId];
    require(currPresale.endDate < block.timestamp);
    PresaleToken = IERC20(currPresale.tokenAddress);
    PresaleToken.transferFrom(msg.sender, address(this), tokenAmt);

    uint256 ethToSend = ethForPresaleDataMap[presaleId];
    ethForPresaleDataMap[presaleId] = 0;

    uint256 adminFee = (ethToSend * basisPoint) / basisPointTotal;
    // send ETH & ERC20 token (presale token) to uniswap
    // create locked liquidity and create trading pair

    PresaleToken.approve(address(_uniRouter), tokenAmt);

    _uniRouter.addLiquidityETH{ value: ethToSend - adminFee }(
      address(currPresale.tokenAddress),
      tokenAmt,
      0,
      0,
      address(this),
      block.timestamp + 20 minutes
    );

    // send ETH to admin based on usage fee (BIP)
    payable(adminAddress).transfer(adminFee);
  }

  function changeUsageFee(uint256 newBasisPoint) public {
    require(msg.sender == adminAddress, "Only admin can change the fee");
    require(
      newBasisPoint <= basisPointTotal,
      "new BIP must be lower than 10000"
    );
    basisPoint = newBasisPoint;
  }
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}