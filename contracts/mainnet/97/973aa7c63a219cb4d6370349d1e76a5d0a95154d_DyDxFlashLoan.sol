pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
      Deposit,   // supply tokens
      Withdraw,  // borrow tokens
      Transfer,  // transfer balance between accounts
      Buy,       // buy an amount of some token (externally)
      Sell,      // sell an amount of some token (externally)
      Trade,     // trade tokens against another account
      Liquidate, // liquidate an undercollateralized or expiring account
      Vaporize,  // use excess tokens to zero-out a completely negative account
      Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei // the amount is denominated in wei
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

contract DyDxPool is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public;
}

contract DyDxFlashLoan is Structs {
    DyDxPool pool = DyDxPool(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e); //this is dydx solo margin sc

    // token address
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public SAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    mapping(address => uint256) public currencies;

    constructor() public {
        currencies[WETH] = 1;
        currencies[SAI] = 2;
        currencies[USDC] = 3;
        currencies[DAI] = 4;
    }

    modifier onlyPool() {
        require(
            msg.sender == address(pool),
            "FlashLoan: could be called by DyDx pool only"
        );
        _;
    }

    function tokenToMarketId(address token) public view returns (uint256) {
        uint256 marketId = currencies[token];
        require(marketId != 0, "FlashLoan: Unsupported token");
        return marketId - 1;
    }

    // the DyDx will call `callFunction(address sender, Info memory accountInfo, bytes memory data) public` after during `operate` call
    // token: erc20 token for flashloan from dydx
    function flashloan(
      address token,
      uint256 amount,
      bytes memory data
    )
        internal
    {
        // approve dydx solo pool
        IERC20(token).approve(address(pool), amount + 1);

        Info[] memory _infos = new Info[](1);
        ActionArgs[] memory _args = new ActionArgs[](3);

        _infos[0] = Info(address(this), 0);

        AssetAmount memory _withdrawAmt = AssetAmount(
            false,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount
        );
        ActionArgs memory _withdraw;
        _withdraw.actionType = ActionType.Withdraw;
        _withdraw.accountId = 0;
        _withdraw.amount = _withdrawAmt;
        _withdraw.primaryMarketId = tokenToMarketId(token);
        _withdraw.otherAddress = address(this);

        _args[0] = _withdraw;

        ActionArgs memory _call;
        _call.actionType = ActionType.Call;
        _call.accountId = 0;
        _call.otherAddress = address(this);
        _call.data = data;

        _args[1] = _call;

        ActionArgs memory _deposit;
        AssetAmount memory _depositAmt = AssetAmount(
            true,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount + 1
        );
        _deposit.actionType = ActionType.Deposit;
        _deposit.accountId = 0;
        _deposit.amount = _depositAmt;
        _deposit.primaryMarketId = tokenToMarketId(token);
        _deposit.otherAddress = address(this);

        _args[2] = _deposit;

        pool.operate(_infos, _args);
    }
}