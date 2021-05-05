// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import './interfaces/IERC20.sol';
import './interfaces/IUniswap.sol';
import './libraries/SafeERC20.sol';


/// @author Nathan Worsley (https://github.com/CodeForcer)
/// @title MistX Gasless Router
contract MistXJar {
  /***********************
  + Global Settings      +
  ***********************/

  using SafeERC20 for IERC20;

  address public owner;
  mapping (address => bool) public managers;

  address public pool;

  uint256 public bribePercent;

  receive() external payable {}
  fallback() external payable {}

  /***********************
  + Jar Functions        +
  ***********************/

  function deposit() public payable {
    require(msg.value > 0, "Don't be stingy");
    uint256 bribe = (msg.value * bribePercent) / 100;
    block.coinbase.transfer(bribe);
  }

  function empty(
    uint256 _amountOutMin,
    address _to,
    uint256 _deadline
  ) public onlyOwner {
    address[] memory path = new address[](2);
    path[0] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    path[1] = pool;

    IUniswapRouter(
      payable(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a)
    ).swapExactETHForTokens{value: address(this).balance}(
      _amountOutMin,
      path,
      _to,
      _deadline
    );
  }

  /***********************
  + Administration       +
  ***********************/

  constructor() {
    owner = msg.sender;
    managers[msg.sender] = true;
    bribePercent = 80;
    pool = 0xCD6bcca48069f8588780dFA274960F15685aEe0e;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can call this");
    _;
  }

  modifier onlyManager() {
    require(managers[msg.sender] == true, "Only managers can call this");
    _;
  }

  function addManager(
    address _manager
  ) external onlyOwner {
    managers[_manager] = true;
  }

  function removeManager(
    address _manager
  ) external onlyOwner {
    managers[_manager] = false;
  }

  function changeBribe(
    uint256 _bribePercent
  ) public onlyManager {
    if (_bribePercent > 100) {
      revert("Split must be a valid percentage");
    }
    bribePercent = _bribePercent;
  }

  function changePool(
    address _pool
  ) public onlyManager {
    pool = _pool;
  }

  function changeOwner(
    address _owner
  ) public onlyOwner {
    owner = _owner;
  }

  function rescueStuckToken(
    address _tokenContract,
    uint256 _value,
    address _to
  ) external onlyManager {
    IERC20(_tokenContract).safeTransfer(_to, _value);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

interface IUniswapRouter {
  function WETH() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (
    uint256 amountA,
    uint256 amountB,
    uint256 liquidity
  );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external payable returns (
    uint256 amountToken,
    uint256 amountETH,
    uint256 liquidity
  );

  function factory() external view returns (address);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountsIn(
    uint256 amountOut,
    address[] memory path
  ) external view returns (uint256[] memory amounts);

  function getAmountsOut(
    uint256 amountIn,
    address[] memory path
  ) external view returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

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

  receive() external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "../interfaces/IERC20.sol";
import "./Address.sol";


library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;


library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}