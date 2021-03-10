// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.6.2;

import './Utilities.sol';

/// @notice ERC-20 contract with support for EIP-2612 and other niceties.
contract HabitatToken is Utilities {
  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowances;
  mapping (address => uint256) _nonces;

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  constructor () {
    _balances[msg.sender] = totalSupply();
  }

  /// @notice Returns the name of token.
  function name () public virtual view returns (string memory) {
    return 'Habitat Token';
  }

  /// @notice Returns the symbol of the token.
  function symbol () public virtual view returns (string memory) {
    return 'HBT';
  }

  /// @notice Returns the number of decimals the token uses.
  function decimals () public virtual view returns (uint8) {
    return 10;
  }

  /// @notice Returns the DOMAIN_SEPARATOR. See EIP-2612.
  function DOMAIN_SEPARATOR () public virtual view returns (bytes32 ret) {
    assembly {
      // load free memory ptr
      let ptr := mload(64)
      // keep a copy to calculate the length later
      let start := ptr

      // keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)')
      mstore(ptr, 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866)
      ptr := add(ptr, 32)

      // keccak256(bytes('Habitat Token'))
      mstore(ptr, 0x825a5bd2b322b183692110889ab8fda39cd7c633901fc90cea3ce579a5694e95)
      ptr := add(ptr, 32)

      // store chainid
      mstore(ptr, chainid())
      ptr := add(ptr, 32)

      // store address(this)
      mstore(ptr, address())
      ptr := add(ptr, 32)

      // hash
      ret := keccak256(start, sub(ptr, start))
    }
  }

  /// @notice Returns the total supply of this token.
  function totalSupply () public virtual view returns (uint256) {
    return 1000000000000000000;
  }

  /// @notice Returns the balance of `account`.
  function balanceOf (address account) public virtual view returns (uint256) {
    return _balances[account];
  }

  /// @notice Returns the allowance for `spender` of `account`.
  function allowance (address account, address spender) public virtual view returns (uint256) {
    return _allowances[account][spender];
  }

  /// @notice Returns the nonce of `account`. Used in `permit`. See EIP-2612.
  function nonces (address account) public virtual view returns (uint256) {
    return _nonces[account];
  }

  /// @notice Approves `amount` from sender to be spend by `spender`.
  /// @param spender Address of the party that can draw from msg.sender's account.
  /// @param amount The maximum collective amount that `spender` can draw.
  /// @return (bool) Returns True if approved.
  function approve (address spender, uint256 amount) public virtual returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  /// @dev The concrete implementation of `approve`.
  function _approve (address owner, address spender, uint256 value) internal virtual {
    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /// @dev The concrete implementation of `transfer` and `transferFrom`.
  function _transferFrom (address from, address to, uint256 value) internal virtual returns (bool) {
    uint256 balance = _balances[from];
    require(balance >= value, 'BALANCE');

    if (from != to) {
      _balances[from] = balance - value;
      balance = _balances[to];
      uint256 newBalance = balance + value;
      // overflow check, also reverts if `value` is zero
      require(newBalance > balance, 'OVERFLOW');
      _balances[to] = newBalance;
    }

    emit Transfer(from, to, value);

    return true;
  }

  /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
  /// @param to The address to move the tokens.
  /// @param amount of the tokens to move.
  /// @return (bool) Returns True if succeeded.
  function transfer (address to, uint256 amount) public virtual returns (bool) {
    return _transferFrom(msg.sender, to, amount);
  }

  /// @notice Transfers `amount` tokens from `from` to `to`. Caller may need approval if `from` is not `msg.sender`.
  /// @param from Address to draw tokens from.
  /// @param to The address to move the tokens.
  /// @param amount The token amount to move.
  /// @return (bool) Returns True if succeeded.
  function transferFrom (address from, address to, uint256 amount) public virtual returns (bool) {
    uint256 _allowance = _allowances[from][msg.sender];
    require(_allowance >= amount, 'ALLOWANCE');

    if (_allowance != uint256(-1)) {
      _allowances[from][msg.sender] = _allowance - amount;
    }

    return _transferFrom(from, to, amount);
  }

  /// @notice Approves `value` from `owner` to be spend by `spender`.
  /// @param owner Address of the owner.
  /// @param spender The address of the spender that gets approved to draw from `owner`.
  /// @param value The maximum collective amount that `spender` can draw.
  /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
  function permit (
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(owner != address(0), 'OWNER');
    require(block.timestamp < deadline, 'EXPIRED');

    uint256 nonce = _nonces[owner]++;
    bytes32 domainSeparator = DOMAIN_SEPARATOR();
    bytes32 digest;
    assembly {
      // ptr to free memory
      let ptr := mload(64)
      // keep a copy to calculate the length later
      let start := ptr

      // keccak256('Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)');
      mstore(ptr, 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9)
      ptr := add(ptr, 32)

      // copy (owner, spender, value) from calldata in one go
      calldatacopy(ptr, 4, 96)
      ptr := add(ptr, 96)

      // store nonce
      mstore(ptr, nonce)
      ptr := add(ptr, 32)
      // store deadline
      mstore(ptr, deadline)
      ptr := add(ptr, 32)

      // Permit struct hash
      let permitStructHash := keccak256(start, sub(ptr, start))
      // reset ptr
      ptr := start
      // add 30 bytes to align correctly (0x1901)
      start := add(ptr, 30)

      // preamble
      mstore(ptr, 0x1901)
      ptr := add(ptr, 32)

      // DOMAIN_SEPARATOR
      mstore(ptr, domainSeparator)
      ptr := add(ptr, 32)

      // from above
      mstore(ptr, permitStructHash)
      ptr := add(ptr, 32)

      // hash it
      digest := keccak256(start, sub(ptr, start))
    }

    require(ecrecover(digest, v, r, s) == owner, 'SIG');
    _approve(owner, spender, value);
  }

  /// @dev Helper function for wrapping calls. Reverts on a call to 'self'.
  function _callWrapper (address to, bytes calldata data) internal returns (bytes memory) {
    require(to != address(this));
    (bool success, bytes memory ret) = to.call(data);
    require(success);
    return ret;
  }

  /// @notice Transfers `amount` from `msg.sender` to `to` and calls `to` with `data` as input.
  /// Reverts if not succesful. Otherwise returns any data from the call.
  function transferAndCall (address to, uint256 amount, bytes calldata data) external returns (bytes memory) {
    _transferFrom(msg.sender, to, amount);
    return _callWrapper(to, data);
  }

  /// @notice Approves `amount` from `msg.sender` to be spend by `to` and calls `to` with `data` as input.
  /// Reverts if not succesful. Otherwise returns any data from the call.
  function approveAndCall (address to, uint256 amount, bytes calldata data) external returns (bytes memory) {
    _approve(msg.sender, to, amount);
    return _callWrapper(to, data);
  }

  /// @notice Redeems a permit for this contract (`permitData`) and calls `to` with `data` as input.
  /// Reverts if not succesful. Otherwise returns any data from the call.
  function redeemPermitAndCall (address to, bytes calldata permitData, bytes calldata data) external returns (bytes memory) {
    Utilities._maybeRedeemPermit(address(this), permitData);
    return _callWrapper(to, data);
  }

  /// @notice Allows to recover `token`.
  /// Transfers `token` to `msg.sender`.
  /// @param token The address of the ERC-20 token to recover.
  function recoverLostTokens (address token) external {
    Utilities._safeTransfer(token, msg.sender, Utilities._safeBalance(token, address(this)));
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