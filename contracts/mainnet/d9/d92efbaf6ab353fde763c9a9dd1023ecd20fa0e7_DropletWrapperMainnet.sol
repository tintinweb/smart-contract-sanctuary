// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.6.2;

import './Utilities.sol';

/// @notice This contract manages 'dripping assets' from a droplet and acts as a wrapper/gatekeeper
/// around the assets for `rollupBridge`.
/// The `rollupBridge` can only be set once and has an activation delay of `ACTIVATION_DELAY`.
contract DropletWrapper is Utilities {
  struct PendingChange {
    uint64 activationDate;
    address reserve;
  }

  /// @dev Address that can claim `SOURCE_TOKEN`.
  address rollupBridge;
  /// @dev Used for temporary state until `rollupBridge` is set.
  PendingChange public pendingChange;

  /// @dev Owner of this contract that can propose changes.
  function OWNER () internal view virtual returns (address) {
  }

  /// @dev The droplet this contract drips from.
  function DROPLET () internal view virtual returns (address) {
  }

  /// @dev The address of the ERC-20 token this contract manages.
  function SOURCE_TOKEN () internal view virtual returns (address) {
  }

  /// @dev How long (in seconds) we have to wait once the change of `rollupBridge` can be applied.
  function ACTIVATION_DELAY () internal view virtual returns (uint256) {
  }

  /// @notice Drips funds from `DROPLET` and calls `rollupBridge` with `data` as calldata.
  function execute (bytes calldata data) external {
    require(rollupBridge != address(0));

    // drip any funds
    IDroplet(DROPLET()).drip();
    // check balance
    uint256 balance = Utilities._safeBalance(SOURCE_TOKEN(), address(this));
    // approve
    Utilities._safeApprove(SOURCE_TOKEN(), rollupBridge, balance);

    (bool success,) = rollupBridge.call(data);
    require(success);
  }

  /// @notice Sets the `rollupBridge`. Must be called 2 times,
  /// once for initalization and afterwards for activation.
  /// This function also allows to overwrite a yet pending change.
  function setReserve (address reserve) external {
    require(msg.sender == OWNER());
    require(rollupBridge == address(0));
    require(reserve != address(0));

    PendingChange memory _pendingChange = pendingChange;
    if (_pendingChange.reserve == reserve) {
      require(block.timestamp >= _pendingChange.activationDate, 'EARLY');
      rollupBridge = reserve;
    } else {
      _pendingChange.reserve = reserve;
      _pendingChange.activationDate = uint64(block.timestamp + ACTIVATION_DELAY());
      // save
      pendingChange = _pendingChange;
    }
  }

  /// @notice Allows to recover `token` except `SOURCE_TOKEN`.
  /// Transfers `token` to `msg.sender`.
  /// @param token The address of the ERC-20 token to recover.
  function recoverLostTokens (address token) external {
    require(token != SOURCE_TOKEN());

    Utilities._safeTransfer(token, msg.sender, Utilities._safeBalance(token, address(this)));
  }
}

import '../DropletWrapper.sol';

contract DropletWrapperMainnet is DropletWrapper {
  address _droplet;

  /// @notice Can only be set by the `OWNER`.
  /// Works only once after setting a non-zero address.
  function setDroplet (address droplet) external {
    require(msg.sender == OWNER());
    require(_droplet == address(0));

    _droplet = droplet;
  }

  function DROPLET () internal view override returns (address) {
    return _droplet;
  }

  function OWNER () internal view override returns (address) {
    // multisig
    return 0xc97f82c80DF57c34E84491C0EDa050BA924D7429;
  }

  function SOURCE_TOKEN () internal view override returns (address) {
    // HBT
    return 0x0aCe32f6E87Ac1457A5385f8eb0208F37263B415;
  }

  function ACTIVATION_DELAY () internal view override returns (uint256) {
    // 2 weeks
    return 1209600;
  }
}

// SPDX-License-Identifier: MIT

interface IWETH {
  function deposit() external payable;
  function transfer(address to, uint value) external returns (bool);
  function withdraw(uint) external;
}

interface IUniswapV2Pair {
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

interface IDroplet {
  function drip () external;
}

library SafeMath {
  function add(uint x, uint y) internal pure returns (uint z) {
    require((z = x + y) >= x, 'ADD_OVERFLOW');
  }

  function sub(uint x, uint y) internal pure returns (uint z) {
    require((z = x - y) <= x, 'SUB_OVERFLOW');
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    require(y == 0 || (z = x * y) / y == x, 'MUL_OVERFLOW');
  }
}

library UniswapV2Library {
  using SafeMath for uint;

  // fetches and sorts the reserves for a pair
  function getReserves (uint256 pair) internal view returns (uint reserveA, uint reserveB) {
    address addr = address(pair >> 1);
    uint direction = pair & 1;
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(addr).getReserves();
    (reserveA, reserveB) = direction == 0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut (uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
    require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = amountIn.mul(997);
    uint numerator = amountInWithFee.mul(reserveOut);
    uint denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut (uint amountIn, uint256[] memory pairs) internal view returns (uint[] memory amounts) {
    amounts = new uint[](pairs.length);
    amounts[0] = amountIn;
    for (uint i = 1; i < pairs.length; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(pairs[i]);
      amounts[i] = getAmountOut(amounts[i - 1], reserveIn, reserveOut);
    }
  }
}

contract Utilities {
  bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
  bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)
  bytes4 private constant SIG_APPROVE = 0x095ea7b3; // approve(address,uint256)
  bytes4 private constant SIG_BALANCE = 0x70a08231; // balanceOf(address)

  /// @dev Provides a safe ERC-20.transfer version for different ERC-20 implementations.
  /// Reverts on a failed transfer.
  /// @param token The address of the ERC-20 token.
  /// @param to Transfer tokens to.
  /// @param amount The token amount.
  function _safeTransfer (address token, address to, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER');
  }

  /// @dev Provides a safe ERC-20.transferFrom version for different ERC-20 implementations.
  /// Reverts on a failed transfer.
  /// @param token The address of the ERC-20 token.
  /// @param from Transfer tokens from.
  /// @param to Transfer tokens to.
  /// @param amount The token amount.
  function _safeTransferFrom (address token, address from, address to, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FROM');
  }

  /// @dev Provides a ETH transfer wrapper.
  /// Reverts on a failed transfer.
  /// @param to Transfer ETH to.
  /// @param amount The ETH amount.
  function _safeTransferETH (address to, uint256 amount) internal {
    (bool success,) = to.call{value:amount}("");
    require(success, 'TRANSFER_ETH');
  }

  /// @dev Provides a safe ERC-20.approve version for different ERC-20 implementations.
  /// Reverts if failed.
  /// @param token The address of the ERC-20 token.
  /// @param spender of tokens.
  /// @param amount Allowance amount.
  function _safeApprove (address token, address spender, uint256 amount) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SIG_APPROVE, spender, amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'APPROVE');
  }

  /// @dev Provides a wrapper for ERC-20.balanceOf.
  /// Reverts if failed.
  /// @param token The address of the ERC-20 token.
  /// @param account Address of the account to query.
  function _safeBalance (address token, address account) internal returns (uint256) {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SIG_BALANCE, account));
    require(success, 'BALANCE');
    return abi.decode(data, (uint256));
  }

  /// @dev Wrapper for `_safeTransfer` or `_safeTransferFrom` depending on `from`.
  function _safeTransferWrapper (address token, address from, address to, uint256 amount) internal {
    if (from == address(this)) {
      _safeTransfer(token, to, amount);
    } else {
      _safeTransferFrom(token, from, to, amount);
    }
  }

  /// @dev Helper function for redeeming EIP-2612 and DAI-style permits.
  function _maybeRedeemPermit (address token, bytes memory permitData) internal {
    if (permitData.length > 0) {
      bool success;
      assembly {
        let dataPtr := add(permitData, 32)
        let functionSig := shr(224, mload(dataPtr))

        {
          // check if permit.owner is address(this). Yes, paranoia.
          // offset is <functionSig 4 bytes> + 12 bytes left-side part of permit.owner.
          // shift it to the right by 12 bytes so that we can *safely* compare
          let _owner := shr(96, mload(add(dataPtr, 16)))
          if eq(_owner, address()) {
            // even if a correct signature for this contract is just possible in theory,
            // attempting this deserves no error message
            revert(0, 0)
          }
        }

        // EIP-2612 = 0xd505accf || dai-like (old) permit = 0x8fcbaf0c
        if or( eq(functionSig, 0xd505accf), eq(functionSig, 0x8fcbaf0c) ) {
          let size := mload(permitData)
          success := call(gas(), token, 0, dataPtr, size, 0, 0)
        }
      }
      require(success, 'PERMIT');
    }
  }

  /// @dev Requires the initial amount to have already been sent to the first pair.
  function _swap (uint[] memory amounts, uint256[] memory path, address _to) internal {
    for (uint i = 1; i < path.length; i++) {
      uint amountOut = amounts[i];

      address pair = address(path[i] >> 1);
      uint direction = path[i] & 1;
      (uint amount0Out, uint amount1Out) = direction == 0 ? (uint(0), amountOut) : (amountOut, uint(0));
      address to = i < path.length - 1 ? pair : _to;

      IUniswapV2Pair(pair).swap(
        amount0Out, amount1Out, to, ""
      );
    }
  }

  function _swapExactTokensForTokens (
    uint256[] memory path,
    uint amountIn,
    address from,
    address to
  ) internal returns (uint[] memory amounts)
  {
    amounts = UniswapV2Library.getAmountsOut(amountIn, path);

    _safeTransferWrapper(address(path[0]), from, address(path[1] >> 1), amounts[0]);
    _swap(amounts, path, to);
  }

  function _swapExactETHForTokens (
    uint256[] memory path,
    uint amountIn,
    address to
  ) internal returns (uint[] memory amounts)
  {
    amounts = UniswapV2Library.getAmountsOut(amountIn, path);

    IWETH(path[0]).deposit{value: amounts[0]}();
    _safeTransferWrapper(address(path[0]), address(this), address(path[1] >> 1), amounts[0]);

    _swap(amounts, path, to);
  }

  function _swapExactTokensForETH (
    uint256[] memory path,
    uint amountIn,
    address from,
    address to,
    address weth
  ) internal returns (uint[] memory amounts)
  {
    amounts = UniswapV2Library.getAmountsOut(amountIn, path);

    _safeTransferWrapper(address(path[0]), from, address(path[1] >> 1), amounts[0]);
    _swap(amounts, path, address(this));

    uint256 finalOutputAmount = amounts[amounts.length - 1];
    IWETH(weth).withdraw(finalOutputAmount);
    _safeTransferETH(to, finalOutputAmount);
  }
}