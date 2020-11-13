pragma solidity 0.5.11; // optimization runs: 200, evm version: petersburg


/**
 * @title DTokenInterface
 * @author 0age
 * @notice Interface for dTokens (in addition to the standard ERC20 interface).
 */
interface DTokenInterface {
  // Events bear similarity to Compound's supply-related events.
  event Mint(address minter, uint256 mintAmount, uint256 mintDTokens);
  event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemDTokens);
  event Accrue(uint256 dTokenExchangeRate, uint256 cTokenExchangeRate);
  event CollectSurplus(uint256 surplusAmount, uint256 surplusCTokens);

  // The block number and cToken + dToken exchange rates are updated on accrual.
  struct AccrualIndex {
    uint112 dTokenExchangeRate;
    uint112 cTokenExchangeRate;
    uint32 block;
  }

  // These external functions trigger accrual on the dToken and backing cToken.
  function mint(uint256 underlyingToSupply) external returns (uint256 dTokensMinted);
  function redeem(uint256 dTokensToBurn) external returns (uint256 underlyingReceived);
  function redeemUnderlying(uint256 underelyingToReceive) external returns (uint256 dTokensBurned);
  function pullSurplus() external returns (uint256 cTokenSurplus);

  // These external functions only trigger accrual on the dToken.
  function mintViaCToken(uint256 cTokensToSupply) external returns (uint256 dTokensMinted);
  function redeemToCToken(uint256 dTokensToBurn) external returns (uint256 cTokensReceived);
  function redeemUnderlyingToCToken(uint256 underlyingToReceive) external returns (uint256 dTokensBurned);
  function accrueInterest() external;
  function transferUnderlying(
    address recipient, uint256 underlyingEquivalentAmount
  ) external returns (bool success);
  function transferUnderlyingFrom(
    address sender, address recipient, uint256 underlyingEquivalentAmount
  ) external returns (bool success);

  // This function provides basic meta-tx support and does not trigger accrual.
  function modifyAllowanceViaMetaTransaction(
    address owner,
    address spender,
    uint256 value,
    bool increase,
    uint256 expiration,
    bytes32 salt,
    bytes calldata signatures
  ) external returns (bool success);

  // View and pure functions do not trigger accrual on the dToken or the cToken.
  function getMetaTransactionMessageHash(
    bytes4 functionSelector, bytes calldata arguments, uint256 expiration, bytes32 salt
  ) external view returns (bytes32 digest, bool valid);
  function totalSupplyUnderlying() external view returns (uint256);
  function balanceOfUnderlying(address account) external view returns (uint256 underlyingBalance);
  function exchangeRateCurrent() external view returns (uint256 dTokenExchangeRate);
  function supplyRatePerBlock() external view returns (uint256 dTokenInterestRate);
  function accrualBlockNumber() external view returns (uint256 blockNumber);
  function getSurplus() external view returns (uint256 cTokenSurplus);
  function getSurplusUnderlying() external view returns (uint256 underlyingSurplus);
  function getSpreadPerBlock() external view returns (uint256 rateSpread);
  function getVersion() external pure returns (uint256 version);
  function getCToken() external pure returns (address cToken);
  function getUnderlying() external pure returns (address underlying);
}


interface ERC20Interface {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}


interface ERC1271Interface {
  function isValidSignature(
    bytes calldata data, bytes calldata signature
  ) external view returns (bytes4 magicValue);
}


interface CTokenInterface {
  function mint(uint256 mintAmount) external returns (uint256 err);
  function redeem(uint256 redeemAmount) external returns (uint256 err);
  function redeemUnderlying(uint256 redeemAmount) external returns (uint256 err);
  function accrueInterest() external returns (uint256 err);
  function transfer(address recipient, uint256 value) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 value) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function balanceOfUnderlying(address account) external returns (uint256 balance);
  function exchangeRateCurrent() external returns (uint256 exchangeRate);

  function getCash() external view returns (uint256);
  function totalSupply() external view returns (uint256 supply);
  function totalBorrows() external view returns (uint256 borrows);
  function totalReserves() external view returns (uint256 reserves);
  function interestRateModel() external view returns (address model);
  function reserveFactorMantissa() external view returns (uint256 factor);
  function supplyRatePerBlock() external view returns (uint256 rate);
  function exchangeRateStored() external view returns (uint256 rate);
  function accrualBlockNumber() external view returns (uint256 blockNumber);
  function balanceOf(address account) external view returns (uint256 balance);
  function allowance(address owner, address spender) external view returns (uint256);
}


interface CUSDCInterestRateModelInterface {
  function getBorrowRate(
    uint256 cash, uint256 borrows, uint256 reserves
  ) external view returns (uint256 err, uint256 borrowRate);
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


/**
 * @title DharmaTokenOverrides
 * @author 0age
 * @notice A collection of internal view and pure functions that should be
 * overridden by the ultimate Dharma Token implementation.
 */
contract DharmaTokenOverrides {
  /**
   * @notice Internal view function to get the current cToken exchange rate and
   * supply rate per block. This function is meant to be overridden by the
   * dToken that inherits this contract.
   * @return The current cToken exchange rate, or amount of underlying tokens
   * that are redeemable for each cToken, and the cToken supply rate per block
   * (with 18 decimal places added to each returned rate).
   */
  function _getCurrentCTokenRates() internal view returns (
    uint256 exchangeRate, uint256 supplyRate
  );

  /**
   * @notice Internal pure function to supply the name of the underlying token.
   * @return The name of the underlying token.
   */
  function _getUnderlyingName() internal pure returns (string memory underlyingName);

  /**
   * @notice Internal pure function to supply the address of the underlying
   * token.
   * @return The address of the underlying token.
   */
  function _getUnderlying() internal pure returns (address underlying);

  /**
   * @notice Internal pure function to supply the symbol of the backing cToken.
   * @return The symbol of the backing cToken.
   */
  function _getCTokenSymbol() internal pure returns (string memory cTokenSymbol);

  /**
   * @notice Internal pure function to supply the address of the backing cToken.
   * @return The address of the backing cToken.
   */
  function _getCToken() internal pure returns (address cToken);

  /**
   * @notice Internal pure function to supply the name of the dToken.
   * @return The name of the dToken.
   */
  function _getDTokenName() internal pure returns (string memory dTokenName);

  /**
   * @notice Internal pure function to supply the symbol of the dToken.
   * @return The symbol of the dToken.
   */
  function _getDTokenSymbol() internal pure returns (string memory dTokenSymbol);

  /**
   * @notice Internal pure function to supply the address of the vault that
   * receives surplus cTokens whenever the surplus is pulled.
   * @return The address of the vault.
   */
  function _getVault() internal pure returns (address vault);
}


/**
 * @title DharmaTokenHelpers
 * @author 0age
 * @notice A collection of constants and internal pure functions used by Dharma
 * Tokens.
 */
contract DharmaTokenHelpers is DharmaTokenOverrides {
  using SafeMath for uint256;

  uint8 internal constant _DECIMALS = 8; // matches cToken decimals
  uint256 internal constant _SCALING_FACTOR = 1e18;
  uint256 internal constant _SCALING_FACTOR_MINUS_ONE = 999999999999999999;
  uint256 internal constant _HALF_OF_SCALING_FACTOR = 5e17;
  uint256 internal constant _COMPOUND_SUCCESS = 0;
  uint256 internal constant _MAX_UINT_112 = 5192296858534827628530496329220095;
  /* solhint-disable separate-by-one-line-in-contract */
  uint256 internal constant _MAX_UNMALLEABLE_S = (
    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
  );
  /* solhint-enable separate-by-one-line-in-contract */

  /**
   * @notice Internal pure function to determine if a call to Compound succeeded
   * and to revert, supplying the reason, if it failed. Failure can be caused by
   * a call that reverts, or by a call that does not revert but returns a
   * non-zero error code.
   * @param functionSelector bytes4 The function selector that was called.
   * @param ok bool A boolean representing whether the call returned or
   * reverted.
   * @param data bytes The data provided by the returned or reverted call.
   */
  function _checkCompoundInteraction(
    bytes4 functionSelector, bool ok, bytes memory data
  ) internal pure {
    CTokenInterface cToken;
    if (ok) {
      if (
        functionSelector == cToken.transfer.selector ||
        functionSelector == cToken.transferFrom.selector
      ) {
        require(
          abi.decode(data, (bool)), string(
            abi.encodePacked(
              "Compound ",
              _getCTokenSymbol(),
              " contract returned false on calling ",
              _getFunctionName(functionSelector),
              "."
            )
          )
        );
      } else {
        uint256 compoundError = abi.decode(data, (uint256)); // throw on no data
        if (compoundError != _COMPOUND_SUCCESS) {
          revert(
            string(
              abi.encodePacked(
                "Compound ",
                _getCTokenSymbol(),
                " contract returned error code ",
                uint8((compoundError / 10) + 48),
                uint8((compoundError % 10) + 48),
                " on calling ",
                _getFunctionName(functionSelector),
                "."
              )
            )
          );
        }
      }
    } else {
      revert(
        string(
          abi.encodePacked(
            "Compound ",
            _getCTokenSymbol(),
            " contract reverted while attempting to call ",
            _getFunctionName(functionSelector),
            ": ",
            _decodeRevertReason(data)
          )
        )
      );
    }
  }

  /**
   * @notice Internal pure function to get a Compound function name based on the
   * selector.
   * @param functionSelector bytes4 The function selector.
   * @return The name of the function as a string.
   */
  function _getFunctionName(
    bytes4 functionSelector
  ) internal pure returns (string memory functionName) {
    CTokenInterface cToken;
    if (functionSelector == cToken.mint.selector) {
      functionName = "mint";
    } else if (functionSelector == cToken.redeem.selector) {
      functionName = "redeem";
    } else if (functionSelector == cToken.redeemUnderlying.selector) {
      functionName = "redeemUnderlying";
    } else if (functionSelector == cToken.transferFrom.selector) {
      functionName = "transferFrom";
    } else if (functionSelector == cToken.transfer.selector) {
      functionName = "transfer";
    } else if (functionSelector == cToken.accrueInterest.selector) {
      functionName = "accrueInterest";
    } else {
      functionName = "an unknown function";
    }
  }

  /**
   * @notice Internal pure function to decode revert reasons. The revert reason
   * prefix is removed and the remaining string argument is decoded.
   * @param revertData bytes The raw data supplied alongside the revert.
   * @return The decoded revert reason string.
   */
  function _decodeRevertReason(
    bytes memory revertData
  ) internal pure returns (string memory revertReason) {
    // Solidity prefixes revert reason with 0x08c379a0 -> Error(string) selector
    if (
      revertData.length > 68 && // prefix (4) + position (32) + length (32)
      revertData[0] == byte(0x08) &&
      revertData[1] == byte(0xc3) &&
      revertData[2] == byte(0x79) &&
      revertData[3] == byte(0xa0)
    ) {
      // Get the revert reason without the prefix from the revert data.
      bytes memory revertReasonBytes = new bytes(revertData.length - 4);
      for (uint256 i = 4; i < revertData.length; i++) {
        revertReasonBytes[i - 4] = revertData[i];
      }

      // Decode the resultant revert reason as a string.
      revertReason = abi.decode(revertReasonBytes, (string));
    } else {
      // Simply return the default, with no revert reason.
      revertReason = "(no revert reason)";
    }
  }

  /**
   * @notice Internal pure function to construct a failure message string for
   * the revert reason on transfers of underlying tokens that do not succeed.
   * @return The failure message.
   */
  function _getTransferFailureMessage() internal pure returns (
    string memory message
  ) {
    message = string(
      abi.encodePacked(_getUnderlyingName(), " transfer failed.")
    );
  }

  /**
   * @notice Internal pure function to convert a uint256 to a uint112, reverting
   * if the conversion would cause an overflow.
   * @param input uint256 The unsigned integer to convert.
   * @return The converted unsigned integer.
   */
  function _safeUint112(uint256 input) internal pure returns (uint112 output) {
    require(input <= _MAX_UINT_112, "Overflow on conversion to uint112.");
    output = uint112(input);
  }

  /**
   * @notice Internal pure function to convert an underlying amount to a dToken
   * or cToken amount using an exchange rate and fixed-point arithmetic.
   * @param underlying uint256 The underlying amount to convert.
   * @param exchangeRate uint256 The exchange rate (multiplied by 10^18).
   * @param roundUp bool Whether the final amount should be rounded up - it will
   * instead be truncated (rounded down) if this value is false.
   * @return The cToken or dToken amount.
   */
  function _fromUnderlying(
    uint256 underlying, uint256 exchangeRate, bool roundUp
  ) internal pure returns (uint256 amount) {
    if (roundUp) {
      amount = (
        (underlying.mul(_SCALING_FACTOR)).add(exchangeRate.sub(1))
      ).div(exchangeRate);
    } else {
      amount = (underlying.mul(_SCALING_FACTOR)).div(exchangeRate);
    }
  }

  /**
   * @notice Internal pure function to convert a dToken or cToken amount to the
   * underlying amount using an exchange rate and fixed-point arithmetic.
   * @param amount uint256 The cToken or dToken amount to convert.
   * @param exchangeRate uint256 The exchange rate (multiplied by 10^18).
   * @param roundUp bool Whether the final amount should be rounded up - it will
   * instead be truncated (rounded down) if this value is false.
   * @return The underlying amount.
   */
  function _toUnderlying(
    uint256 amount, uint256 exchangeRate, bool roundUp
  ) internal pure returns (uint256 underlying) {
    if (roundUp) {
      underlying = (
        (amount.mul(exchangeRate).add(_SCALING_FACTOR_MINUS_ONE)
      ) / _SCALING_FACTOR);
    } else {
      underlying = amount.mul(exchangeRate) / _SCALING_FACTOR;
    }
  }

  /**
   * @notice Internal pure function to convert an underlying amount to a dToken
   * or cToken amount and back to the underlying, so as to properly capture
   * rounding errors, by using an exchange rate and fixed-point arithmetic.
   * @param underlying uint256 The underlying amount to convert.
   * @param exchangeRate uint256 The exchange rate (multiplied by 10^18).
   * @param roundUpOne bool Whether the intermediate dToken or cToken amount
   * should be rounded up - it will instead be truncated (rounded down) if this
   * value is false.
   * @param roundUpTwo bool Whether the final underlying amount should be
   * rounded up - it will instead be truncated (rounded down) if this value is
   * false.
   * @return The intermediate cToken or dToken amount and the final underlying
   * amount.
   */
  function _fromUnderlyingAndBack(
    uint256 underlying, uint256 exchangeRate, bool roundUpOne, bool roundUpTwo
  ) internal pure returns (uint256 amount, uint256 adjustedUnderlying) {
    amount = _fromUnderlying(underlying, exchangeRate, roundUpOne);
    adjustedUnderlying = _toUnderlying(amount, exchangeRate, roundUpTwo);
  }
}


/**
 * @title DharmaTokenV2
 * @author 0age (dToken mechanics derived from Compound cTokens, ERC20 mechanics
 * derived from Open Zeppelin's ERC20 contract)
 * @notice DharmaTokenV2 deprecates the interest-bearing component and prevents
 * minting of new tokens or redeeming to cTokens. It also returns COMP in
 * proportion to the respective dToken balance in relation to total supply.
 */
contract DharmaTokenV2 is ERC20Interface, DTokenInterface, DharmaTokenHelpers {
  // Set the version of the Dharma Token as a constant.
  uint256 private constant _DTOKEN_VERSION = 2;

  ERC20Interface internal constant _COMP = ERC20Interface(
    0xc00e94Cb662C3520282E6f5717214004A7f26888 // mainnet
  );

  // Set block number and dToken + cToken exchange rate in slot zero on accrual.
  AccrualIndex private _accrualIndex;

  // Slot one tracks the total issued dTokens.
  uint256 private _totalSupply;

  // Slots two and three are entrypoints into balance and allowance mappings.
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  // Slot four is an entrypoint into a mapping for used meta-transaction hashes.
  mapping (bytes32 => bool) private _executedMetaTxs;
  
  bool exchangeRateFrozen; // initially false

  /**
   * @notice Deprecated.
   */
  function mint(
    uint256 underlyingToSupply
  ) external returns (uint256 dTokensMinted) {
    revert("Minting is no longer supported.");
  }

  /**
   * @notice Deprecated.
   */
  function mintViaCToken(
    uint256 cTokensToSupply
  ) external returns (uint256 dTokensMinted) {
    revert("Minting is no longer supported.");
  }

  /**
   * @notice Redeem `dTokensToBurn` dTokens from `msg.sender`, use the
   * corresponding cTokens to redeem the required underlying, and transfer the
   * redeemed underlying tokens to `msg.sender`.
   * @param dTokensToBurn uint256 The amount of dTokens to provide in exchange
   * for underlying tokens.
   * @return The amount of underlying received in return for the provided
   * dTokens.
   */
  function redeem(
    uint256 dTokensToBurn
  ) external returns (uint256 underlyingReceived) {
    require(exchangeRateFrozen, "Call `pullSurplus()` to freeze exchange rate first.");

    // Instantiate interface for the underlying token.
    ERC20Interface underlying = ERC20Interface(_getUnderlying());

    require(dTokensToBurn > 0, "No funds specified to redeem.");
    
    // Get the total supply, as well as current underlying and COMP balances.
    uint256 originalSupply = _totalSupply;
    uint256 underlyingBalance = underlying.balanceOf(address(this));
    uint256 compBalance = _COMP.balanceOf(address(this));

     // Apply dToken ratio to balances to determine amount to transfer out.
    underlyingReceived = underlyingBalance.mul(dTokensToBurn) / originalSupply;
    uint256 compReceived = compBalance.mul(dTokensToBurn) / originalSupply;
    require(
      underlyingReceived.add(compReceived) > 0,
      "Supplied dTokens are insufficient to redeem."
    );
    
    // Burn the dTokens.
    _burn(msg.sender, underlyingReceived, dTokensToBurn);
    
    // Transfer out the proportion of each associated with the burned tokens.
    if (underlyingReceived > 0) {
      require(
        underlying.transfer(msg.sender, underlyingReceived),
        _getTransferFailureMessage()
      );
    }

    if (compReceived > 0) {
      require(
        _COMP.transfer(msg.sender, compReceived),
        "COMP transfer out failed."
      );
    }
  }

  /**
   * @notice Deprecated.
   */
  function redeemToCToken(
    uint256 dTokensToBurn
  ) external returns (uint256 cTokensReceived) {
    revert("Redeeming to cTokens is no longer supported.");
  }

  /**
   * @notice Redeem the dToken equivalent value of the underlying token amount
   * `underlyingToReceive` from `msg.sender`, use the corresponding cTokens to
   * redeem the underlying, and transfer the underlying to `msg.sender`.
   * @param underlyingToReceive uint256 The amount, denominated in the
   * underlying token, of the cToken to redeem in exchange for the received
   * underlying token.
   * @return The amount of dTokens burned in exchange for the returned
   * underlying tokens.
   */
  function redeemUnderlying(
    uint256 underlyingToReceive
  ) external returns (uint256 dTokensBurned) {
    require(exchangeRateFrozen, "Call `pullSurplus()` to freeze exchange rate first.");

    // Instantiate interface for the underlying token.
    ERC20Interface underlying = ERC20Interface(_getUnderlying());

    // Get the dToken exchange rate.
    (uint256 dTokenExchangeRate, ) = _accrue(false);

    // Determine dToken amount to burn using the exchange rate, rounded up.
    dTokensBurned = _fromUnderlying(
      underlyingToReceive, dTokenExchangeRate, true
    );

    // Determine dToken amount for returning COMP by rounding down.
    uint256 dTokensForCOMP = _fromUnderlying(
      underlyingToReceive, dTokenExchangeRate, false
    );
    
    // Get the total supply and current COMP balance.
    uint256 originalSupply = _totalSupply;
    uint256 compBalance = _COMP.balanceOf(address(this));

     // Apply dToken ratio to COMP balance to determine amount to transfer out.
    uint256 compReceived = compBalance.mul(dTokensForCOMP) / originalSupply;
    require(
      underlyingToReceive.add(compReceived) > 0,
      "Supplied amount is insufficient to redeem."
    );
    
    // Burn the dTokens.
    _burn(msg.sender, underlyingToReceive, dTokensBurned);
    
    // Transfer out the proportion of each associated with the burned tokens.
    if (underlyingToReceive > 0) {
      require(
        underlying.transfer(msg.sender, underlyingToReceive),
        _getTransferFailureMessage()
      );
    }

    if (compReceived > 0) {
      require(
        _COMP.transfer(msg.sender, compReceived),
        "COMP transfer out failed."
      );
    }
  }

  /**
   * @notice Deprecated.
   */
  function redeemUnderlyingToCToken(
    uint256 underlyingToReceive
  ) external returns (uint256 dTokensBurned) {
    revert("Redeeming to cTokens is no longer supported.");
  }

  /**
   * @notice Transfer cTokens with underlying value in excess of the total
   * underlying dToken value to a dedicated "vault" account. A "hard" accrual
   * will first be performed, triggering an accrual on both the cToken and the
   * dToken.
   * @return The amount of cTokens transferred to the vault account.
   */
  function pullSurplus() external returns (uint256 cTokenSurplus) {
    require(!exchangeRateFrozen, "No surplus left to pull.");

    // Instantiate the interface for the backing cToken.
    CTokenInterface cToken = CTokenInterface(_getCToken());

    // Accrue interest on the cToken and ensure that the operation succeeds.
    (bool ok, bytes memory data) = address(cToken).call(abi.encodeWithSelector(
      cToken.accrueInterest.selector
    ));
    _checkCompoundInteraction(cToken.accrueInterest.selector, ok, data);

    // Accrue interest on the dToken, reusing the stored cToken exchange rate.
    _accrue(false);

    // Determine cToken surplus in underlying (cToken value - dToken value).
    uint256 underlyingSurplus;
    (underlyingSurplus, cTokenSurplus) = _getSurplus();

    // Transfer cToken surplus to vault and ensure that the operation succeeds.
    (ok, data) = address(cToken).call(abi.encodeWithSelector(
      cToken.transfer.selector, _getVault(), cTokenSurplus
    ));
    _checkCompoundInteraction(cToken.transfer.selector, ok, data);

    emit CollectSurplus(underlyingSurplus, cTokenSurplus);
    
    exchangeRateFrozen = true;
    
    // Redeem all cTokens for underlying and ensure that the operation succeeds.
    (ok, data) = address(cToken).call(abi.encodeWithSelector(
      cToken.redeem.selector, cToken.balanceOf(address(this))
    ));
    _checkCompoundInteraction(cToken.redeem.selector, ok, data);
  }

  /**
   * @notice Deprecated.
   */
  function accrueInterest() external {
    revert("Interest accrual is longer supported.");
  }

  /**
   * @notice Transfer `amount` dTokens from `msg.sender` to `recipient`.
   * @param recipient address The account to transfer the dTokens to.
   * @param amount uint256 The amount of dTokens to transfer.
   * @return A boolean indicating whether the transfer was successful.
   */
  function transfer(
    address recipient, uint256 amount
  ) external returns (bool success) {
    _transfer(msg.sender, recipient, amount);
    success = true;
  }

  /**
   * @notice Transfer dTokens equivalent to `underlyingEquivalentAmount`
   * underlying from `msg.sender` to `recipient`.
   * @param recipient address The account to transfer the dTokens to.
   * @param underlyingEquivalentAmount uint256 The underlying equivalent amount
   * of dTokens to transfer.
   * @return A boolean indicating whether the transfer was successful.
   */
  function transferUnderlying(
    address recipient, uint256 underlyingEquivalentAmount
  ) external returns (bool success) {
    // Accrue interest and retrieve the current dToken exchange rate.
    (uint256 dTokenExchangeRate, ) = _accrue(true);

    // Determine dToken amount to transfer using the exchange rate, rounded up.
    uint256 dTokenAmount = _fromUnderlying(
      underlyingEquivalentAmount, dTokenExchangeRate, true
    );

    // Transfer the dTokens.
    _transfer(msg.sender, recipient, dTokenAmount);
    success = true;
  }

  /**
   * @notice Approve `spender` to transfer up to `value` dTokens on behalf of
   * `msg.sender`.
   * @param spender address The account to grant the allowance.
   * @param value uint256 The size of the allowance to grant.
   * @return A boolean indicating whether the approval was successful.
   */
  function approve(
    address spender, uint256 value
  ) external returns (bool success) {
    _approve(msg.sender, spender, value);
    success = true;
  }

  /**
   * @notice Transfer `amount` dTokens from `sender` to `recipient` as long as
   * `msg.sender` has sufficient allowance.
   * @param sender address The account to transfer the dTokens from.
   * @param recipient address The account to transfer the dTokens to.
   * @param amount uint256 The amount of dTokens to transfer.
   * @return A boolean indicating whether the transfer was successful.
   */
  function transferFrom(
    address sender, address recipient, uint256 amount
  ) external returns (bool success) {
    _transferFrom(sender, recipient, amount);
    success = true;
  }

  /**
   * @notice Transfer dTokens eqivalent to `underlyingEquivalentAmount`
   * underlying from `sender` to `recipient` as long as `msg.sender` has
   * sufficient allowance.
   * @param sender address The account to transfer the dTokens from.
   * @param recipient address The account to transfer the dTokens to.
   * @param underlyingEquivalentAmount uint256 The underlying equivalent amount
   * of dTokens to transfer.
   * @return A boolean indicating whether the transfer was successful.
   */
  function transferUnderlyingFrom(
    address sender, address recipient, uint256 underlyingEquivalentAmount
  ) external returns (bool success) {
    // Accrue interest and retrieve the current dToken exchange rate.
    (uint256 dTokenExchangeRate, ) = _accrue(true);

    // Determine dToken amount to transfer using the exchange rate, rounded up.
    uint256 dTokenAmount = _fromUnderlying(
      underlyingEquivalentAmount, dTokenExchangeRate, true
    );

    // Transfer the dTokens and adjust allowance accordingly.
    _transferFrom(sender, recipient, dTokenAmount);
    success = true;
  }

  /**
   * @notice Increase the current allowance of `spender` by `value` dTokens.
   * @param spender address The account to grant the additional allowance.
   * @param addedValue uint256 The amount to increase the allowance by.
   * @return A boolean indicating whether the modification was successful.
   */
  function increaseAllowance(
    address spender, uint256 addedValue
  ) external returns (bool success) {
    _approve(
      msg.sender, spender, _allowances[msg.sender][spender].add(addedValue)
    );
    success = true;
  }

  /**
   * @notice Decrease the current allowance of `spender` by `value` dTokens.
   * @param spender address The account to decrease the allowance for.
   * @param subtractedValue uint256 The amount to subtract from the allowance.
   * @return A boolean indicating whether the modification was successful.
   */
  function decreaseAllowance(
    address spender, uint256 subtractedValue
  ) external returns (bool success) {
    _approve(
      msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue)
    );
    success = true;
  }

  /**
   * @notice Modify the current allowance of `spender` for `owner` by `value`
   * dTokens, increasing it if `increase` is true otherwise decreasing it, via a
   * meta-transaction that expires at `expiration` (or does not expire if the
   * value is zero) and uses `salt` as an additional input, validated using
   * `signatures`.
   * @param owner address The account granting the modified allowance.
   * @param spender address The account to modify the allowance for.
   * @param value uint256 The amount to modify the allowance by.
   * @param increase bool A flag that indicates whether the allowance will be
   * increased by the specified value (if true) or decreased by it (if false).
   * @param expiration uint256 A timestamp indicating how long the modification
   * meta-transaction is valid for - a value of zero will signify no expiration.
   * @param salt bytes32 An arbitrary salt to be provided as an additional input
   * to the hash digest used to validate the signatures.
   * @param signatures bytes A signature, or collection of signatures, that the
   * owner must provide in order to authorize the meta-transaction. If the
   * account of the owner does not have any runtime code deployed to it, the
   * signature will be verified using ecrecover; otherwise, it will be supplied
   * to the owner along with the message digest and context via ERC-1271 for
   * validation.
   * @return A boolean indicating whether the modification was successful.
   */
  function modifyAllowanceViaMetaTransaction(
    address owner,
    address spender,
    uint256 value,
    bool increase,
    uint256 expiration,
    bytes32 salt,
    bytes calldata signatures
  ) external returns (bool success) {
    require(expiration == 0 || now <= expiration, "Meta-transaction expired.");

    // Construct the meta-transaction's message hash based on relevant context.
    bytes memory context = abi.encodePacked(
      address(this),
      // _DTOKEN_VERSION,
      this.modifyAllowanceViaMetaTransaction.selector,
      expiration,
      salt,
      abi.encode(owner, spender, value, increase)
    );
    bytes32 messageHash = keccak256(context);

    // Ensure message hash has never been used before and register it as used.
    require(!_executedMetaTxs[messageHash], "Meta-transaction already used.");
    _executedMetaTxs[messageHash] = true;

    // Construct the digest to compare signatures against using EIP-191 0x45.
    bytes32 digest = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    // Calculate new allowance by applying modification to current allowance.
    uint256 currentAllowance = _allowances[owner][spender];
    uint256 newAllowance = (
      increase ? currentAllowance.add(value) : currentAllowance.sub(value)
    );

    // Use EIP-1271 if owner is a contract - otherwise, use ecrecover.
    if (_isContract(owner)) {
      // Validate via ERC-1271 against the owner account.
      bytes memory data = abi.encode(digest, context);
      bytes4 magic = ERC1271Interface(owner).isValidSignature(data, signatures);
      require(magic == bytes4(0x20c13b0b), "Invalid signatures.");
    } else {
      // Validate via ecrecover against the owner account.
      _verifyRecover(owner, digest, signatures);
    }

    // Modify the allowance.
    _approve(owner, spender, newAllowance);
    success = true;
  }

  /**
   * @notice View function to determine a meta-transaction message hash, and to
   * determine if it is still valid (i.e. it has not yet been used and is not
   * expired). The returned message hash will need to be prefixed using EIP-191
   * 0x45 and hashed again in order to generate a final digest for the required
   * signature - in other words, the same procedure utilized by `eth_Sign`.
   * @param functionSelector bytes4 The function selector for the given
   * meta-transaction. There is only one function selector available for V1:
   * `0x2d657fa5` (the selector for `modifyAllowanceViaMetaTransaction`).
   * @param arguments bytes The abi-encoded function arguments (aside from the
   * `expiration`, `salt`, and `signatures` arguments) that should be supplied
   * to the given function.
   * @param expiration uint256 A timestamp indicating how long the given
   * meta-transaction is valid for - a value of zero will signify no expiration.
   * @param salt bytes32 An arbitrary salt to be provided as an additional input
   * to the hash digest used to validate the signatures.
   * @return The total supply.
   */
  function getMetaTransactionMessageHash(
    bytes4 functionSelector,
    bytes calldata arguments,
    uint256 expiration,
    bytes32 salt
  ) external view returns (bytes32 messageHash, bool valid) {
    // Construct the meta-transaction's message hash based on relevant context.
    messageHash = keccak256(
      abi.encodePacked(
        address(this), functionSelector, expiration, salt, arguments
      )
    );

    // The meta-transaction is valid if it has not been used and is not expired.
    valid = (
      !_executedMetaTxs[messageHash] && (expiration == 0 || now <= expiration)
    );
  }

  /**
   * @notice View function to get the total dToken supply.
   * @return The total supply.
   */
  function totalSupply() external view returns (uint256 dTokenTotalSupply) {
    dTokenTotalSupply = _totalSupply;
  }

  /**
   * @notice View function to get the total dToken supply, denominated in the
   * underlying token.
   * @return The total supply.
   */
  function totalSupplyUnderlying() external view returns (
    uint256 dTokenTotalSupplyInUnderlying
  ) {
    (uint256 dTokenExchangeRate, ,) = _getExchangeRates(true);

    // Determine total value of all issued dTokens, denominated as underlying.
    dTokenTotalSupplyInUnderlying = _toUnderlying(
      _totalSupply, dTokenExchangeRate, false
    );
  }

  /**
   * @notice View function to get the total dToken balance of an account.
   * @param account address The account to check the dToken balance for.
   * @return The balance of the given account.
   */
  function balanceOf(address account) external view returns (uint256 dTokens) {
    dTokens = _balances[account];
  }

  /**
   * @notice View function to get the dToken balance of an account, denominated
   * in the underlying equivalent value.
   * @param account address The account to check the balance for.
   * @return The total underlying-equivalent dToken balance.
   */
  function balanceOfUnderlying(
    address account
  ) external view returns (uint256 underlyingBalance) {
    // Get most recent dToken exchange rate by determining accrued interest.
    (uint256 dTokenExchangeRate, ,) = _getExchangeRates(true);

    // Convert account balance to underlying equivalent using the exchange rate.
    underlyingBalance = _toUnderlying(
      _balances[account], dTokenExchangeRate, false
    );
  }

  /**
   * @notice View function to get the total allowance that `spender` has to
   * transfer dTokens from the `owner` account using `transferFrom`.
   * @param owner address The account that is granting the allowance.
   * @param spender address The account that has been granted the allowance.
   * @return The allowance of the given spender for the given owner.
   */
  function allowance(
    address owner, address spender
  ) external view returns (uint256 dTokenAllowance) {
    dTokenAllowance = _allowances[owner][spender];
  }

  /**
   * @notice View function to get the current dToken exchange rate (multiplied
   * by 10^18).
   * @return The current exchange rate.
   */
  function exchangeRateCurrent() external view returns (
    uint256 dTokenExchangeRate
  ) {
    // Get most recent dToken exchange rate by determining accrued interest.
    (dTokenExchangeRate, ,) = _getExchangeRates(true);
  }

  /**
   * @notice View function to get the current dToken interest earned per block
   * (multiplied by 10^18).
   * @return The current interest rate.
   */
  function supplyRatePerBlock() external view returns (
    uint256 dTokenInterestRate
  ) {
    (dTokenInterestRate,) = _getRatePerBlock();
  }

  /**
   * @notice View function to get the block number where accrual was last
   * performed.
   * @return The block number where accrual was last performed.
   */
  function accrualBlockNumber() external view returns (uint256 blockNumber) {
    blockNumber = _accrualIndex.block;
  }

  /**
   * @notice View function to get the total surplus, or the cToken balance that
   * exceeds the aggregate underlying value of the total dToken supply.
   * @return The total surplus in cTokens.
   */
  function getSurplus() external view returns (uint256 cTokenSurplus) {
    // Determine the cToken (cToken underlying value - dToken underlying value).
    (, cTokenSurplus) = _getSurplus();
  }

  /**
   * @notice View function to get the total surplus in the underlying, or the
   * underlying equivalent of the cToken balance that exceeds the aggregate
   * underlying value of the total dToken supply.
   * @return The total surplus, denominated in the underlying.
   */
  function getSurplusUnderlying() external view returns (
    uint256 underlyingSurplus
  ) {
    // Determine cToken surplus in underlying (cToken value - dToken value).
    (underlyingSurplus, ) = _getSurplus();
  }

  /**
   * @notice View function to get the interest rate spread taken by the dToken
   * from the current cToken supply rate per block (multiplied by 10^18).
   * @return The current interest rate spread.
   */
  function getSpreadPerBlock() external view returns (uint256 rateSpread) {
    (
      uint256 dTokenInterestRate, uint256 cTokenInterestRate
    ) = _getRatePerBlock();
    rateSpread = cTokenInterestRate.sub(dTokenInterestRate);
  }

  /**
   * @notice Pure function to get the name of the dToken.
   * @return The name of the dToken.
   */
  function name() external pure returns (string memory dTokenName) {
    dTokenName = _getDTokenName();
  }

  /**
   * @notice Pure function to get the symbol of the dToken.
   * @return The symbol of the dToken.
   */
  function symbol() external pure returns (string memory dTokenSymbol) {
    dTokenSymbol = _getDTokenSymbol();
  }

  /**
   * @notice Pure function to get the number of decimals of the dToken.
   * @return The number of decimals of the dToken.
   */
  function decimals() external pure returns (uint8 dTokenDecimals) {
    dTokenDecimals = _DECIMALS;
  }

  /**
   * @notice Pure function to get the dToken version.
   * @return The version of the dToken.
   */
  function getVersion() external pure returns (uint256 version) {
    version = _DTOKEN_VERSION;
  }

  /**
   * @notice Pure function to get the address of the cToken backing this dToken.
   * @return The address of the cToken backing this dToken.
   */
  function getCToken() external pure returns (address cToken) {
    cToken = _getCToken();
  }

  /**
   * @notice Pure function to get the address of the underlying token of this
   * dToken.
   * @return The address of the underlying token for this dToken.
   */
  function getUnderlying() external pure returns (address underlying) {
    underlying = _getUnderlying();
  }

  /**
   * @notice Private function to trigger accrual and to update the dToken and
   * cToken exchange rates in storage if necessary. The `compute` argument can
   * be set to false if an accrual has already taken place on the cToken before
   * calling this function.
   * @param compute bool A flag to indicate whether the cToken exchange rate
   * needs to be computed - if false, it will simply be read from storage on the
   * cToken in question.
   * @return The current dToken and cToken exchange rates.
   */
  function _accrue(bool compute) private returns (
    uint256 dTokenExchangeRate, uint256 cTokenExchangeRate
  ) {
    bool alreadyAccrued;
    (
      dTokenExchangeRate, cTokenExchangeRate, alreadyAccrued
    ) = _getExchangeRates(compute);

    if (!alreadyAccrued) {
      // Update storage with dToken + cToken exchange rates as of current block.
      AccrualIndex storage accrualIndex = _accrualIndex;
      accrualIndex.dTokenExchangeRate = _safeUint112(dTokenExchangeRate);
      accrualIndex.cTokenExchangeRate = _safeUint112(cTokenExchangeRate);
      accrualIndex.block = uint32(block.number);
      emit Accrue(dTokenExchangeRate, cTokenExchangeRate);
    }
  }

  /**
   * @notice Private function to burn `amount` tokens by exchanging `exchanged`
   * tokens from `account` and emit corresponding `Redeeem` & `Transfer` events.
   * @param account address The account to burn tokens from.
   * @param exchanged uint256 The amount of underlying tokens given for burning.
   * @param amount uint256 The amount of tokens to burn.
   */
  function _burn(address account, uint256 exchanged, uint256 amount) private {
    require(
      exchanged > 0 && amount > 0, "Redeem failed: insufficient funds supplied."
    );

    uint256 balancePriorToBurn = _balances[account];
    require(
      balancePriorToBurn >= amount, "Supplied amount exceeds account balance."
    );

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = balancePriorToBurn - amount; // overflow checked above

    emit Transfer(account, address(0), amount);
    emit Redeem(account, exchanged, amount);
  }

  /**
   * @notice Private function to move `amount` tokens from `sender` to
   * `recipient` and emit a corresponding `Transfer` event.
   * @param sender address The account to transfer tokens from.
   * @param recipient address The account to transfer tokens to.
   * @param amount uint256 The amount of tokens to transfer.
   */
  function _transfer(
    address sender, address recipient, uint256 amount
  ) private {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "Insufficient funds.");

    _balances[sender] = senderBalance - amount; // overflow checked above.
    _balances[recipient] = _balances[recipient].add(amount);

    emit Transfer(sender, recipient, amount);
  }

  /**
   * @notice Private function to transfer `amount` tokens from `sender` to
   * `recipient` and to deduct the transferred amount from the allowance of the
   * caller unless the allowance is set to the maximum amount.
   * @param sender address The account to transfer tokens from.
   * @param recipient address The account to transfer tokens to.
   * @param amount uint256 The amount of tokens to transfer.
   */
  function _transferFrom(
    address sender, address recipient, uint256 amount
  ) private {
    _transfer(sender, recipient, amount);
    uint256 callerAllowance = _allowances[sender][msg.sender];
    if (callerAllowance != uint256(-1)) {
      require(callerAllowance >= amount, "Insufficient allowance.");
      _approve(sender, msg.sender, callerAllowance - amount); // overflow safe.
    }
  }

  /**
   * @notice Private function to set the allowance for `spender` to transfer up
   * to `value` tokens on behalf of `owner`.
   * @param owner address The account that has granted the allowance.
   * @param spender address The account to grant the allowance.
   * @param value uint256 The size of the allowance to grant.
   */
  function _approve(address owner, address spender, uint256 value) private {
    require(owner != address(0), "ERC20: approve for the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  /**
   * @notice Private view function to get the latest dToken and cToken exchange
   * rates and provide the value for each. The `compute` argument can be set to
   * false if an accrual has already taken place on the cToken before calling
   * this function.
   * @param compute bool A flag to indicate whether the cToken exchange rate
   * needs to be computed - if false, it will simply be read from storage on the
   * cToken in question.
   * @return The dToken and cToken exchange rate, as well as a boolean
   * indicating if interest accrual has been processed already or needs to be
   * calculated and placed in storage.
   */
  function _getExchangeRates(bool compute) private view returns (
    uint256 dTokenExchangeRate, uint256 cTokenExchangeRate, bool fullyAccrued
  ) {
    // Get the stored accrual block and dToken + cToken exhange rates.
    AccrualIndex memory accrualIndex = _accrualIndex;
    uint256 storedDTokenExchangeRate = uint256(accrualIndex.dTokenExchangeRate);
    uint256 storedCTokenExchangeRate = uint256(accrualIndex.cTokenExchangeRate);
    uint256 accrualBlock = uint256(accrualIndex.block);

    // Use stored exchange rates if an accrual has already occurred this block.
    fullyAccrued = (accrualBlock == block.number);
    if (fullyAccrued) {
      dTokenExchangeRate = storedDTokenExchangeRate;
      cTokenExchangeRate = storedCTokenExchangeRate;
    } else {
      // Only compute cToken exchange rate if it has not accrued this block.
      if (compute) {
        // Get current cToken exchange rate; inheriting contract overrides this.
        (cTokenExchangeRate,) = _getCurrentCTokenRates();
      } else {
        // Otherwise, get the stored cToken exchange rate.
        cTokenExchangeRate = CTokenInterface(_getCToken()).exchangeRateStored();
      }

      if (exchangeRateFrozen) {
         dTokenExchangeRate = storedDTokenExchangeRate;
      } else {
        // Determine the cToken interest earned during the period.
        uint256 cTokenInterest = (
          (cTokenExchangeRate.mul(_SCALING_FACTOR)).div(storedCTokenExchangeRate)
        ).sub(_SCALING_FACTOR);
    
        // Calculate dToken exchange rate by applying 90% of the cToken interest.
        dTokenExchangeRate = storedDTokenExchangeRate.mul(
          _SCALING_FACTOR.add(cTokenInterest.mul(9) / 10)
        ) / _SCALING_FACTOR;          
      }
    }
  }

  /**
   * @notice Private view function to get the total surplus, or cToken
   * balance that exceeds the total dToken balance.
   * @return The total surplus, denominated in both the underlying and in the
   * cToken.
   */
  function _getSurplus() private view returns (
    uint256 underlyingSurplus, uint256 cTokenSurplus
  ) {
    if (exchangeRateFrozen) {
        underlyingSurplus = 0;
        cTokenSurplus = 0;
    } else {
      // Instantiate the interface for the backing cToken.
      CTokenInterface cToken = CTokenInterface(_getCToken());

      (
        uint256 dTokenExchangeRate, uint256 cTokenExchangeRate,
      ) = _getExchangeRates(true);

      // Determine value of all issued dTokens in the underlying, rounded up.
      uint256 dTokenUnderlying = _toUnderlying(
        _totalSupply, dTokenExchangeRate, true
      );

      // Determine value of all retained cTokens in the underlying, rounded down.
      uint256 cTokenUnderlying = _toUnderlying(
        cToken.balanceOf(address(this)), cTokenExchangeRate, false
      );

      // Determine the size of the surplus in terms of underlying amount.
      underlyingSurplus = cTokenUnderlying > dTokenUnderlying
        ? cTokenUnderlying - dTokenUnderlying // overflow checked above
        : 0;

      // Determine the cToken equivalent of this surplus amount.
      cTokenSurplus = underlyingSurplus == 0
        ? 0
        : _fromUnderlying(underlyingSurplus, cTokenExchangeRate, false);
        
    }
  }

  /**
   * @notice Private view function to get the current dToken and cToken interest
   * supply rate per block (multiplied by 10^18).
   * @return The current dToken and cToken interest rates.
   */
  function _getRatePerBlock() private view returns (
    uint256 dTokenSupplyRate, uint256 cTokenSupplyRate
  ) {
    (, cTokenSupplyRate) = _getCurrentCTokenRates();
    if (exchangeRateFrozen) {
      dTokenSupplyRate = 0;
    } else {
      dTokenSupplyRate = cTokenSupplyRate.mul(9) / 10;
    }
  }

  /**
   * @notice Private view function to determine if a given account has runtime
   * code or not - in other words, whether or not a contract is deployed to the
   * account in question. Note that contracts that are in the process of being
   * deployed will return false on this check.
   * @param account address The account to check for contract runtime code.
   * @return Whether or not there is contract runtime code at the account.
   */
  function _isContract(address account) private view returns (bool isContract) {
    uint256 size;
    assembly { size := extcodesize(account) }
    isContract = size > 0;
  }

  /**
   * @notice Private pure function to verify that a given signature of a digest
   * resolves to the supplied account. Any error, including incorrect length,
   * malleable signature types, or unsupported `v` values, will cause a revert.
   * @param account address The account to validate against.
   * @param digest bytes32 The digest to use.
   * @param signature bytes The signature to verify.
   */
  function _verifyRecover(
    address account, bytes32 digest, bytes memory signature
  ) private pure {
    // Ensure the signature length is correct.
    require(
      signature.length == 65,
      "Must supply a single 65-byte signature when owner is not a contract."
    );

    // Divide the signature in r, s and v variables.
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    require(
      uint256(s) <= _MAX_UNMALLEABLE_S,
      "Signature `s` value cannot be potentially malleable."
    );

    require(v == 27 || v == 28, "Signature `v` value not permitted.");

    require(account == ecrecover(digest, v, r, s), "Invalid signature.");
  }
}


/**
 * @title DharmaUSDCImplementationV2
 * @author 0age (dToken mechanics derived from Compound cTokens, ERC20 methods
 * derived from Open Zeppelin's ERC20 contract)
 * @notice This contract provides the V2 implementation of Dharma USD Coin (or
 * dUSDC), which effectively deprecates Dharma USD Coin.
 */
contract DharmaUSDCImplementationV2 is DharmaTokenV2 {
  string internal constant _NAME = "Dharma USD Coin";
  string internal constant _SYMBOL = "dUSDC";
  string internal constant _UNDERLYING_NAME = "USD Coin";
  string internal constant _CTOKEN_SYMBOL = "cUSDC";

  CTokenInterface internal constant _CUSDC = CTokenInterface(
    0x39AA39c021dfbaE8faC545936693aC917d5E7563 // mainnet
  );

  ERC20Interface internal constant _USDC = ERC20Interface(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 // mainnet
  );

  address internal constant _VAULT = 0x7e4A8391C728fEd9069B2962699AB416628B19Fa;

  uint256 internal constant _SCALING_FACTOR_SQUARED = 1e36;

  /**
   * @notice Internal view function to get the current cUSDC exchange rate and
   * supply rate per block.
   * @return The current cUSDC exchange rate, or amount of USDC that is
   * redeemable for each cUSDC, and the cUSDC supply rate per block (with 18
   * decimal places added to each returned rate).
   */
  function _getCurrentCTokenRates() internal view returns (
    uint256 exchangeRate, uint256 supplyRate
  ) {
    // Determine number of blocks that have elapsed since last cUSDC accrual.
    uint256 blockDelta = block.number.sub(_CUSDC.accrualBlockNumber());

    // Return stored values if accrual has already been performed this block.
    if (blockDelta == 0) return (
      _CUSDC.exchangeRateStored(), _CUSDC.supplyRatePerBlock()
    );

    // Determine total "cash" held by cUSDC contract.
    uint256 cash = _USDC.balanceOf(address(_CUSDC));

    // Get the latest interest rate model from the cUSDC contract.
    CUSDCInterestRateModelInterface interestRateModel = (
      CUSDCInterestRateModelInterface(_CUSDC.interestRateModel())
    );

    // Get the current stored total borrows, reserves, and reserve factor.
    uint256 borrows = _CUSDC.totalBorrows();
    uint256 reserves = _CUSDC.totalReserves();
    uint256 reserveFactor = _CUSDC.reserveFactorMantissa();

    // Get the current borrow rate from the latest cUSDC interest rate model.
    (uint256 err, uint256 borrowRate) = interestRateModel.getBorrowRate(
      cash, borrows, reserves
    );
    require(
      err == _COMPOUND_SUCCESS, "Interest Rate Model borrow rate check failed."
    );

    // Get accumulated borrow interest via borrows, borrow rate, & block delta.
    uint256 interest = borrowRate.mul(blockDelta).mul(borrows) / _SCALING_FACTOR;

    // Update total borrows and reserves using calculated accumulated interest.
    borrows = borrows.add(interest);
    reserves = reserves.add(reserveFactor.mul(interest) / _SCALING_FACTOR);

    // Get "underlying" via (cash + borrows - reserves).
    uint256 underlying = (cash.add(borrows)).sub(reserves);

    // Determine cUSDC exchange rate via underlying / total supply.
    exchangeRate = (underlying.mul(_SCALING_FACTOR)).div(_CUSDC.totalSupply());

    // Get "borrows per" by dividing total borrows by underlying and scaling up.
    uint256 borrowsPer = (borrows.mul(_SCALING_FACTOR)).div(underlying);

    // Supply rate is borrow rate * (1 - reserveFactor) * borrowsPer.
    supplyRate = (
      borrowRate.mul(_SCALING_FACTOR.sub(reserveFactor)).mul(borrowsPer)
    ) / _SCALING_FACTOR_SQUARED;
  }

  /**
   * @notice Internal pure function to supply the name of the underlying token.
   * @return The name of the underlying token.
   */
  function _getUnderlyingName() internal pure returns (string memory underlyingName) {
    underlyingName = _UNDERLYING_NAME;
  }

  /**
   * @notice Internal pure function to supply the address of the underlying
   * token.
   * @return The address of the underlying token.
   */
  function _getUnderlying() internal pure returns (address underlying) {
    underlying = address(_USDC);
  }

  /**
   * @notice Internal pure function to supply the symbol of the backing cToken.
   * @return The symbol of the backing cToken.
   */
  function _getCTokenSymbol() internal pure returns (string memory cTokenSymbol) {
    cTokenSymbol = _CTOKEN_SYMBOL;
  }

  /**
   * @notice Internal pure function to supply the address of the backing cToken.
   * @return The address of the backing cToken.
   */
  function _getCToken() internal pure returns (address cToken) {
    cToken = address(_CUSDC);
  }

  /**
   * @notice Internal pure function to supply the name of the dToken.
   * @return The name of the dToken.
   */
  function _getDTokenName() internal pure returns (string memory dTokenName) {
    dTokenName = _NAME;
  }

  /**
   * @notice Internal pure function to supply the symbol of the dToken.
   * @return The symbol of the dToken.
   */
  function _getDTokenSymbol() internal pure returns (string memory dTokenSymbol) {
    dTokenSymbol = _SYMBOL;
  }

  /**
   * @notice Internal pure function to supply the address of the vault that
   * receives surplus cTokens whenever the surplus is pulled.
   * @return The address of the vault.
   */
  function _getVault() internal pure returns (address vault) {
    vault = _VAULT;
  }
}