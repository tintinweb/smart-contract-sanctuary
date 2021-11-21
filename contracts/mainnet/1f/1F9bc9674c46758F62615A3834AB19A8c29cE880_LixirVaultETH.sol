// File contracts/LixirVaultETH.sol
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./LixirVault.sol";

contract LixirVaultETH is LixirVault, ILixirVaultETH {
  using SafeMath for uint256;
  using SafeCast for uint256;

  IWETH9 public immutable weth9;

  TOKEN public override WETH_TOKEN;

  constructor(address _registry) LixirVault(_registry) {
    weth9 = LixirRegistry(_registry).weth9();
  }

  function initialize(
    string memory name,
    string memory symbol,
    address _token0,
    address _token1,
    address _strategist,
    address _keeper,
    address _strategy
  ) public override(LixirVault, ILixirVault) initializer {
    LixirVault.initialize(
      name,
      symbol,
      _token0,
      _token1,
      _strategist,
      _keeper,
      _strategy
    );
    TOKEN _WETH_TOKEN;
    if (_token0 == address(weth9)) {
      _WETH_TOKEN = TOKEN.ZERO;
    } else {
      require(_token1 == address(weth9));
      _WETH_TOKEN = TOKEN.ONE;
    }
    WETH_TOKEN = _WETH_TOKEN;
  }

  /**
    @notice equivalent to `deposit` except logic is configured for
    ETH instead of ERC20 payments.
    @param amountDesired amount of ERC20 token desired by caller
    @param amountEthMin minimum amount of ETH desired by caller
    @param amountMin minimum amount of ERC20 token desired by caller
    @param recipient The address for which the liquidity will be created
    @param deadline Blocktimestamp that this must execute before
    @return shares
    @return amountEthIn how much ETH was actually deposited
    @return amountIn how much the ERC20 token was actually deposited
   */
  function depositETH(
    uint256 amountDesired,
    uint256 amountEthMin,
    uint256 amountMin,
    address recipient,
    uint256 deadline
  )
    external
    payable
    override
    notExpired(deadline)
    returns (
      uint256 shares,
      uint256 amountEthIn,
      uint256 amountIn
    )
  {
    TOKEN _WETH_TOKEN = WETH_TOKEN;
    if (_WETH_TOKEN == TOKEN.ZERO) {
      (shares, amountEthIn, amountIn) = _depositETH(
        _WETH_TOKEN,
        msg.value,
        amountDesired,
        amountEthMin,
        amountMin,
        recipient,
        deadline
      );
    } else {
      (shares, amountIn, amountEthIn) = _depositETH(
        _WETH_TOKEN,
        amountDesired,
        msg.value,
        amountMin,
        amountEthMin,
        recipient,
        deadline
      );
    }
  }

  function _depositETH(
    TOKEN _WETH_TOKEN,
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address recipient,
    uint256 deadline
  )
    internal
    returns (
      uint256 shares,
      uint256 amount0In,
      uint256 amount1In
    )
  {
    DepositPositionData memory mainData;
    DepositPositionData memory rangeData;
    uint256 total0;
    uint256 total1;
    (
      mainData,
      rangeData,
      shares,
      amount0In,
      amount1In,
      total0,
      total1
    ) = _depositStepOne(
      amount0Desired,
      amount1Desired,
      amount0Min,
      amount1Min,
      recipient
    );
    if (_WETH_TOKEN == TOKEN.ZERO) {
      if (0 < amount0In) {
        weth9.deposit{value: amount0In}();
      }
      if (0 < amount1In) {
        TransferHelper.safeTransferFrom(
          address(token1),
          msg.sender,
          address(this),
          amount1In
        );
      }
    } else {
      if (0 < amount0In) {
        TransferHelper.safeTransferFrom(
          address(token0),
          msg.sender,
          address(this),
          amount0In
        );
      }
      if (0 < amount1In) {
        weth9.deposit{value: amount1In}();
      }
    }

    _depositStepTwo(
      mainData,
      rangeData,
      recipient,
      shares,
      amount0In,
      amount1In,
      total0,
      total1
    );
    Address.sendValue(msg.sender, address(this).balance);
  }

  /**
    @notice withdraws the desired shares from the vault
    @dev same as `withdraw` except this can be called from an `approve`d address
    @param withdrawer the address to withdraw from
    @param shares number of shares to withdraw
    @param amountEthMin amount of ETH desired by user
    @param amountMin Minimum amount of ERC20 token desired by user
    @param recipient address to recieve ETH and ERC20 withdrawals
    @param deadline blocktimestamp that this must execute by
    @return amountEthOut how much ETH was actually withdrawn
    @return amountOut how much ERC20 token was actually withdrawn
   */
  function withdrawETHFrom(
    address withdrawer,
    uint256 shares,
    uint256 amountEthMin,
    uint256 amountMin,
    address payable recipient,
    uint256 deadline
  )
    external
    override
    canSpend(withdrawer, shares)
    returns (uint256 amountEthOut, uint256 amountOut)
  {
    TOKEN _WETH_TOKEN = WETH_TOKEN;
    uint256 amount0Min;
    uint256 amount1Min;
    if (_WETH_TOKEN == TOKEN.ZERO) {
      amount0Min = amountEthMin;
      amount1Min = amountMin;
      (amountEthOut, amountOut) = _withdrawETH(
        _WETH_TOKEN,
        withdrawer,
        shares,
        amount0Min,
        amount1Min,
        recipient,
        deadline
      );
    } else {
      amount0Min = amountMin;
      amount1Min = amountEthMin;
      (amountOut, amountEthOut) = _withdrawETH(
        _WETH_TOKEN,
        withdrawer,
        shares,
        amount0Min,
        amount1Min,
        recipient,
        deadline
      );
    }
  }

  /**
    @notice withdraws the desired shares from the vault
    @param shares number of shares to withdraw
    @param amountEthMin amount of ETH desired by user
    @param amountMin Minimum amount of ERC20 token desired by user
    @param recipient address to recieve ETH and ERC20 withdrawals
    @param deadline blocktimestamp that this must execute by
    @return amountEthOut how much ETH was actually withdrawn
    @return amountOut how much ERC20 token was actually withdrawn
   */
  function withdrawETH(
    uint256 shares,
    uint256 amountEthMin,
    uint256 amountMin,
    address payable recipient,
    uint256 deadline
  ) external override returns (uint256 amountEthOut, uint256 amountOut) {
    TOKEN _WETH_TOKEN = WETH_TOKEN;
    uint256 amount0Min;
    uint256 amount1Min;
    if (_WETH_TOKEN == TOKEN.ZERO) {
      amount0Min = amountEthMin;
      amount1Min = amountMin;
      (amountEthOut, amountOut) = _withdrawETH(
        _WETH_TOKEN,
        msg.sender,
        shares,
        amount0Min,
        amount1Min,
        recipient,
        deadline
      );
    } else {
      amount0Min = amountMin;
      amount1Min = amountEthMin;
      (amountOut, amountEthOut) = _withdrawETH(
        _WETH_TOKEN,
        msg.sender,
        shares,
        amount0Min,
        amount1Min,
        recipient,
        deadline
      );
    }
  }

  function _withdrawETH(
    TOKEN _WETH_TOKEN,
    address withdrawer,
    uint256 shares,
    uint256 amount0Min,
    uint256 amount1Min,
    address payable recipient,
    uint256 deadline
  )
    internal
    notExpired(deadline)
    returns (uint256 amount0Out, uint256 amount1Out)
  {
    (amount0Out, amount1Out) = _withdrawStep(
      withdrawer,
      shares,
      amount0Min,
      amount1Min,
      recipient
    );
    if (_WETH_TOKEN == TOKEN.ZERO) {
      if (0 < amount1Out) {
        TransferHelper.safeTransfer(address(token1), recipient, amount1Out);
      }
      if (0 < amount0Out) {
        weth9.withdraw(amount0Out);
        Address.sendValue(recipient, amount0Out);
      }
    } else {
      if (0 < amount0Out) {
        TransferHelper.safeTransfer(address(token0), recipient, amount0Out);
      }
      if (0 < amount1Out) {
        weth9.withdraw(amount1Out);
        Address.sendValue(recipient, amount1Out);
      }
    }
  }

  receive() external payable override {
    require(msg.sender == address(weth9));
  }
}