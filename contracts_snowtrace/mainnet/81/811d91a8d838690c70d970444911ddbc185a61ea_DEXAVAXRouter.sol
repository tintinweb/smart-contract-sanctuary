// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './interfaces/IBEP20.sol';
import './interfaces/IDEXAVAXRouter.sol';
import './interfaces/IDEXRouter.sol';

contract DEXAVAXRouter is IDEXRouter {
  IDEXAVAXRouter private router;

  constructor(address _router) {
    router = IDEXAVAXRouter(_router);
  }

  function getRouter() external view returns (address) {
    return address(router);
  }

  function factory() external view override returns (address) {
    return router.factory();
  }

  function WETH() external view override returns (address) {
    return router.WAVAX();
  }

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountAVAXMin,
    address to,
    uint256 deadline
  )
    external
    payable
    override
    returns (
      uint256 amountToken,
      uint256 amountAVAX,
      uint256 liquidity
    )
  {
    IBEP20 t = IBEP20(token);
    t.transferFrom(msg.sender, address(this), amountToken);
    t.approve(address(router), amountToken);
    return
      router.addLiquidityAVAX{ value: msg.value }(
        token,
        amountTokenDesired,
        amountTokenMin,
        amountAVAXMin,
        to,
        deadline
      );
  }

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external override {
    IBEP20 t = IBEP20(path[0]);
    t.transferFrom(msg.sender, address(this), amountIn);
    t.approve(address(router), amountIn);
    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amountIn,
      amountOutMin,
      path,
      to,
      deadline
    );
  }

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable override {
    router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
      value: msg.value
    }(amountOutMin, path, to, deadline);
  }

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external override {
    IBEP20 t = IBEP20(path[0]);
    t.transferFrom(msg.sender, address(this), amountIn);
    t.approve(address(router), amountIn);
    router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
      amountIn,
      amountOutMin,
      path,
      to,
      deadline
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDEXAVAXRouter {
  function factory() external pure returns (address);

  function WAVAX() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityAVAX(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountAVAXMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountAVAX,
      uint256 liquidity
    );

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDEXRouter {
  function factory() external view returns (address);

  function WETH() external view returns (address);

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}