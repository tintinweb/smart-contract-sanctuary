// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import './interfaces/IERC20.sol';
import './interfaces/IMistXJar.sol';
import './interfaces/IUniswap.sol';
import './libraries/SafeERC20.sol';


/// @author Nathan Worsley (https://github.com/CodeForcer)
/// @title MistX Gasless Router
contract MistXRouter {
  /***********************
  + Global Settings      +
  ***********************/

  using SafeERC20 for IERC20;

  IMistXJar MistXJar;

  address public owner;
  mapping (address => bool) public managers;

  receive() external payable {}
  fallback() external payable {}

  /***********************
  + Structures           +
  ***********************/

  struct Swap {
    uint256 amount0;
    uint256 amount1;
    address[] path;
    address to;
    uint256 deadline;
  }

  /***********************
  + Swap wrappers        +
  ***********************/

  function swapExactETHForTokens(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    MistXJar.deposit{value: _bribe}();

    _router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value - _bribe}(
      _swap.amount1,
      _swap.path,
      _swap.to,
      _swap.deadline
    );
  }

  function swapETHForExactTokens(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    MistXJar.deposit{value: _bribe}();

    _router.swapETHForExactTokens{value: msg.value - _bribe}(
      _swap.amount1,
      _swap.path,
      _swap.to,
      _swap.deadline
    );

    // Refunded ETH needs to be swept from router to user address
    (bool success, ) = payable(_swap.to).call{value: address(this).balance}("");
    require(success);
  }

  function swapExactTokensForTokens(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    MistXJar.deposit{value: _bribe}();

    IERC20 from = IERC20(_swap.path[0]);
    from.safeTransferFrom(msg.sender, address(this), _swap.amount0);
    from.safeIncreaseAllowance(address(_router), _swap.amount0);

    _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      _swap.amount0,
      _swap.amount1,
      _swap.path,
      _swap.to,
      _swap.deadline
    );
  }

  function swapTokensForExactTokens(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    MistXJar.deposit{value: _bribe}();

    IERC20 from = IERC20(_swap.path[0]);
    from.safeTransferFrom(msg.sender, address(this), _swap.amount1);
    from.safeIncreaseAllowance(address(_router), _swap.amount1);

    _router.swapTokensForExactTokens(
      _swap.amount0,
      _swap.amount1,
      _swap.path,
      _swap.to,
      _swap.deadline
    );

    from.safeTransfer(msg.sender, from.balanceOf(address(this)));
  }

  function swapTokensForExactETH(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    IERC20 from = IERC20(_swap.path[0]);
    from.safeTransferFrom(msg.sender, address(this), _swap.amount1);
    from.safeIncreaseAllowance(address(_router), _swap.amount1);

    _router.swapTokensForExactETH(
      _swap.amount0,
      _swap.amount1,
      _swap.path,
      address(this),
      _swap.deadline
    );

    MistXJar.deposit{value: _bribe}();
  
    // ETH after bribe must be swept to _to
    (bool success, ) = payable(_swap.to).call{value: address(this).balance}("");
    require(success);

    // Left-over from tokens must be swept to _to
    from.safeTransfer(msg.sender, from.balanceOf(address(this)));
  }

  function swapExactTokensForETH(
    Swap calldata _swap,
    IUniswapRouter _router,
    uint256 _bribe
  ) external payable {
    IERC20 from = IERC20(_swap.path[0]);
    from.safeTransferFrom(msg.sender, address(this), _swap.amount0);
    from.safeIncreaseAllowance(address(_router), _swap.amount0);

    _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      _swap.amount0,
      _swap.amount1,
      _swap.path,
      address(this),
      _swap.deadline
    );

    MistXJar.deposit{value: _bribe}();
  
    // ETH after bribe must be swept to _to
    (bool success, ) = payable(_swap.to).call{value: address(this).balance}("");
    require(success);
  }

  /***********************
  + Administration       +
  ***********************/

  event OwnershipChanged(
    address indexed oldOwner,
    address indexed newOwner
  );

  constructor(
    address _mistJar
  ) {
    MistXJar = IMistXJar(_mistJar);
    owner = msg.sender;
    managers[msg.sender] = true;
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

  function changeJar(
    address _mistJar
  ) public onlyManager {
    MistXJar = IMistXJar(_mistJar);
  }

  function changeOwner(
    address _owner
  ) public onlyOwner {
    emit OwnershipChanged(owner, _owner);
    owner = _owner;
  }

  function rescueStuckETH(
    uint256 _amount,
    address _to
  ) external onlyManager {
    payable(_to).transfer(_amount);
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

interface IMistXJar {
  function deposit() external payable;
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

