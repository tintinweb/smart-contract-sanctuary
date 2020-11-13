pragma solidity 0.6.12; // optimization runs: 200, evm version: istanbul
pragma experimental ABIEncoderV2;


interface DharmaTradeBotV1Interface {
  struct LimitOrderArguments {
    address account;
    address assetToSupply;        // Ether = address(0)
    address assetToReceive;       // Ether = address(0)
    uint256 maximumAmountToSupply;
    uint256 maximumPriceToAccept; // represented as a mantissa (n * 10^18)
    uint256 expiration;
    bytes32 salt;
  }

  struct LimitOrderExecutionArguments {
    uint256 amountToSupply; // will be lower than maximum for partial fills
    bytes signatures;
    address tradeTarget;
    bytes tradeData;
  }

  function processLimitOrder(
    LimitOrderArguments calldata args,
    LimitOrderExecutionArguments calldata executionArgs
  ) external returns (uint256 amountReceived);
}


contract BasicTradeBotCommanderStaging {
  DharmaTradeBotV1Interface _TRADE_BOT = DharmaTradeBotV1Interface(
    0x0f36f2DA9F935a7802a4f1Af43A3740A73219A9e
  );
    
  function processLimitOrder(
    DharmaTradeBotV1Interface.LimitOrderArguments calldata args,
    DharmaTradeBotV1Interface.LimitOrderExecutionArguments calldata executionArgs
  ) external returns (uint256 amountReceived) {
    amountReceived = _TRADE_BOT.processLimitOrder(
      args, executionArgs
    );
  }
}