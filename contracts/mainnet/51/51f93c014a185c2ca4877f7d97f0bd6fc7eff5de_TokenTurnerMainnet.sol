// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.6.2;

import './Utilities.sol';

/// @notice This contract looks to be useful for bootstrapping/funding purposes.
contract TokenTurner is Utilities {
  /// @dev How many epochs the funding event is open.
  uint256 constant FUNDING_EPOCHS = 12;
  /// @dev The decay rate per funding epoch.
  uint256 constant DECAY_PER_EPOCH = 4; // 4 %
  /// @dev Maximum decay rate.
  uint256 constant MAX_DECAY_RATE = 100; // 100 %
  /// @dev Price of 1 `OUTPUT_TOKEN` for 1 `INPUT_TOKEN`.
  uint256 constant FUNDING_PRICE = 25e6; // 25 dai-pennies
  /// @dev The maximum epoch that needs to be reached so that the last possible funding epoch has a decay of 100%.
  uint256 constant MAX_EPOCH = FUNDING_EPOCHS + (MAX_DECAY_RATE / DECAY_PER_EPOCH);

  /// @notice The ERC-20 token this contract wants in exchange of `OUTPUT_TOKEN`. For example: DAI
  function INPUT_TOKEN () internal view virtual returns (address) {
  }

  /// @notice The ERC-20 token this contract returns in exchange of `INPUT_TOKEN`. For example: HBT
  function OUTPUT_TOKEN () internal view virtual returns (address) {
  }

  /// @notice The address of the community fund that receives the decay of `INPUT_TOKEN`.
  function COMMUNITY_FUND () internal view virtual returns (address) {
  }

  struct InflowOutflow {
    uint128 inflow;
    uint128 outflow;
  }

  /// @dev The last closed epoch this contract knows of.  Used for bookkeeping purposes.
  uint256 activeEpoch;
  /// @notice epoch > address > amount (inflow `INPUT_TOKEN`, outflow `INPUT_TOKEN`)
  mapping (uint256 => mapping (address => InflowOutflow)) public inflowOutflow;

  event Buy (address indexed buyer, uint256 indexed epoch, uint256 amount);
  event Sell (address indexed seller, uint256 indexed epoch, uint256 amount);
  event Claim (uint256 epoch, uint256 amount);

  /// @notice Returns the current epoch. Can also return zero and maximum `MAX_EPOCH`.
  function getCurrentEpoch () public view virtual returns (uint256 epoch) {
    // ~~(Date.parse('2021-03-05 20:00 UTC+1') / 1000)
    uint256 FUNDING_START_DATE = 1614899552;
    // 7 days
    uint256 EPOCH_SECONDS = 604800;
    epoch = (block.timestamp - FUNDING_START_DATE) / EPOCH_SECONDS;
    if (epoch > MAX_EPOCH) {
      epoch = MAX_EPOCH;
    }
  }

  /// @notice Returns the decay rate for `epoch`.
  /// The first week has zero decay. After each new week, the decay increases by `DECAY_PER_EPOCH`
  /// up to a maximum of `MAX_DECAY_RATE`.
  function getDecayRateForEpoch (uint256 epoch) public view returns (uint256 rate) {
    rate = (getCurrentEpoch() - epoch) * DECAY_PER_EPOCH;
    if (rate > MAX_DECAY_RATE) {
      rate = MAX_DECAY_RATE;
    }
  }

  /// @notice Used for updating the epoch and claiming any decay.
  function updateEpoch () public {
    require(msg.sender != address(this));
    uint256 currentEpoch = getCurrentEpoch();

    if (currentEpoch >= MAX_EPOCH) {
      address receiver = COMMUNITY_FUND();
      // claim everything if the decay of the last funding epoch is 100%
      uint256 balance = Utilities._safeBalance(INPUT_TOKEN(), address(this));
      if (balance > 0) {
        Utilities._safeTransfer(INPUT_TOKEN(), receiver, balance);
      }

      // and claim any remaining `OUTPUT_TOKEN`
      balance = Utilities._safeBalance(OUTPUT_TOKEN(), address(this));
      if (balance > 0) {
        Utilities._safeTransfer(OUTPUT_TOKEN(), receiver, balance);
      }
      // nothing to do anymore
      return;
    }

    if (currentEpoch > activeEpoch) {
      // bookkeeping
      activeEpoch = currentEpoch;
      uint256 balance = Utilities._safeBalance(INPUT_TOKEN(), address(this));
      uint256 claimableAmount = (balance / MAX_DECAY_RATE) * DECAY_PER_EPOCH;

      if (claimableAmount > 0) {
        emit Claim(currentEpoch, claimableAmount);
        Utilities._safeTransfer(INPUT_TOKEN(), COMMUNITY_FUND(), claimableAmount);
      }
    }
  }

  /// @notice Helper function for calculating the `inflow` and `outflow` amounts given `amountIn` and `path`.
  function getQuote (uint256 amountIn, uint256[] memory path) public view returns (uint256 inflow, uint256 outflow) {
    uint256[] memory amounts = UniswapV2Library.getAmountsOut(amountIn, path);
    inflow = amounts[amounts.length - 1];
    outflow = inflow / FUNDING_PRICE;
  }

  /// @notice Swaps `INPUT_TOKEN` or any other ERC-20 with liquidity on Uniswap(v2) for `OUTPUT_TOKEN`.
  /// @param receiver The receiver of `OUTPUT_TOKEN`.
  /// @param inputAmount The amount of `swapRoute[0]` to trade for `OUTPUT_TOKEN`.
  /// @param swapRoute First element is the address of a ERC-20 used as input.
  /// If the address is not `INPUT_TOKEN` then this array should also include addresses for Uniswap(v2) pairs
  /// to swap from. In the format:
  /// uint256(address(pair) << 1 | direction)
  /// where direction = tokenA === token0 ? 0 : 1 (See Uniswap for ordering algo)
  /// @param permitData Optional EIP-2612 signed approval for `swapRoute[0]`.
  function swapIn (
    address receiver,
    uint256 inputAmount,
    uint256[] memory swapRoute,
    bytes memory permitData
  ) external payable {
    updateEpoch();
    address fromToken = address(swapRoute[0]);

    Utilities._maybeRedeemPermit(fromToken, permitData);

    // if `fromToken` == `INPUT_TOKEN` then this maps directly to our price
    uint256 inflowAmount = inputAmount;

    if (fromToken == INPUT_TOKEN()) {
      Utilities._safeTransferFrom(fromToken, msg.sender, address(this), inflowAmount);
    } else {
      // we have to swap first
      uint256 oldBalance = Utilities._safeBalance(INPUT_TOKEN(), address(this));

      if (msg.value == 0) {
        Utilities._swapExactTokensForTokens(swapRoute, inputAmount, msg.sender, address(this));
      } else {
        Utilities._swapExactETHForTokens(swapRoute, msg.value, address(this));
      }

      uint256 newBalance = Utilities._safeBalance(INPUT_TOKEN(), address(this));
      require(newBalance > oldBalance, 'BALANCE');
      inflowAmount = newBalance - oldBalance;
    }

    uint256 currentEpoch = getCurrentEpoch();
    require(currentEpoch < FUNDING_EPOCHS, 'PRESALE_OVER');
    uint256 outflowAmount = inflowAmount / FUNDING_PRICE;
    require(outflowAmount != 0, 'ZERO_AMOUNT');

    // bookkeeping
    emit Buy(msg.sender, currentEpoch, outflowAmount);
    // practically, this should never overflow
    inflowOutflow[currentEpoch][msg.sender].inflow += uint128(inflowAmount);

    // transfer `OUTPUT_TOKEN` to `receiver`
    Utilities._safeTransfer(OUTPUT_TOKEN(), receiver, outflowAmount);
  }

  /// @notice Swaps `OUTPUT_TOKEN` back.
  /// @param receiver Address of the receiver for the returned tokens.
  /// @param inputSellAmount The amount of `OUTPUT_TOKEN` to swap back.
  /// @param epoch The epoch `OUTPUT_TOKEN` was acquired. Needed to calculate the decay rate.
  /// @param swapRoute If `swapRoute.length` is greather than 1, then
  /// this array should also include addresses for Uniswap(v2) pairs to swap to/from. In the format:
  /// uint256(address(pair) << 1 | direction)
  /// where direction = tokenA === token0 ? 0 : 1 (See Uniswap for ordering algo)
  /// For receiving `INPUT_TOKEN` back, just use `swapRoute = [0]`.
  /// If ETH is wanted, then use `swapRoute [<address of WETH>, DAI-WETH-PAIR(see above for encoding)]`.
  /// Otherwise, use `swapRoute [0, DAI-WETH-PAIR(see above for encoding)]`.
  /// @param permitData Optional EIP-2612 signed approval for `OUTPUT_TOKEN`.
  function swapOut (
    address receiver,
    uint256 inputSellAmount,
    uint256 epoch,
    uint256[] memory swapRoute,
    bytes memory permitData
  ) external {
    updateEpoch();
    uint256 currentEpoch = getCurrentEpoch();
    require(epoch <= currentEpoch, 'EPOCH');

    Utilities._maybeRedeemPermit(OUTPUT_TOKEN(), permitData);

    uint128 sellAmount = uint128(inputSellAmount * FUNDING_PRICE);
    // check available amount
    {
      // practically, this should never overflow
      InflowOutflow storage account = inflowOutflow[epoch][msg.sender];
      uint128 swappableAmount = account.inflow;
      uint128 oldOutflow = account.outflow;
      uint128 newOutflow = sellAmount + oldOutflow;
      // just to make sure
      require(newOutflow > oldOutflow);

      if (epoch != currentEpoch) {
        uint256 decay = getDecayRateForEpoch(epoch);
        swappableAmount = uint128(swappableAmount - ((swappableAmount / MAX_DECAY_RATE) * decay));
      }
      require(newOutflow <= swappableAmount, 'AMOUNT');
      account.outflow = newOutflow;
    }

    emit Sell(msg.sender, epoch, inputSellAmount);
    // take the tokens back
    Utilities._safeTransferFrom(OUTPUT_TOKEN(), msg.sender, address(this), inputSellAmount);

    if (swapRoute.length == 1) {
      Utilities._safeTransfer(INPUT_TOKEN(), receiver, sellAmount);
    } else {
      // we swap `INPUT_TOKEN`
      address wethIfNotZero = address(swapRoute[0]);
      swapRoute[0] = uint256(INPUT_TOKEN());

      if (wethIfNotZero == address(0)) {
        Utilities._swapExactTokensForTokens(swapRoute, sellAmount, address(this), receiver);
      } else {
        Utilities._swapExactTokensForETH(swapRoute, sellAmount, address(this), receiver, wethIfNotZero);
      }
    }
  }

  /// @notice Allows to recover `token` except `INPUT_TOKEN` and `OUTPUT_TOKEN`.
  /// Transfers `token` to the `COMMUNITY_FUND`.
  /// @param token The address of the ERC-20 token to recover.
  function recoverLostTokens (address token) external {
    require(token != INPUT_TOKEN() && token != OUTPUT_TOKEN());

    Utilities._safeTransfer(token, COMMUNITY_FUND(), Utilities._safeBalance(token, address(this)));
  }

  /// @notice Required for receiving ETH from WETH.
  /// Reverts if caller == origin. Helps against wrong ETH transfers.
  fallback () external payable {
    assembly {
      if eq(caller(), origin()) {
        revert(0, 0)
      }
    }
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

// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.6.2;

import '../TokenTurner.sol';

contract TokenTurnerMainnet is TokenTurner {
  function INPUT_TOKEN () internal view override returns (address) {
    // DAI
    return 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  }

  function OUTPUT_TOKEN () internal view override returns (address) {
    // HBT
    return 0x0aCe32f6E87Ac1457A5385f8eb0208F37263B415;
  }

  function COMMUNITY_FUND () internal view override returns (address) {
    // multisig
    return 0xc97f82c80DF57c34E84491C0EDa050BA924D7429;
  }

  function getCurrentEpoch () public view override returns (uint256 epoch) {
    // ~~(Date.parse('2021-03-10 11:00 UTC+1') / 1000)
    uint256 FUNDING_START_DATE = 1615370400;
    // 1 week
    uint256 EPOCH_SECONDS = 604800;
    epoch = (block.timestamp - FUNDING_START_DATE) / EPOCH_SECONDS;
    if (epoch > MAX_EPOCH) {
      epoch = MAX_EPOCH;
    }
  }
}