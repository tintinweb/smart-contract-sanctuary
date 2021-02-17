// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import 'synthetix/contracts/interfaces/IERC20.sol';
import 'synthetix/contracts/interfaces/ISystemStatus.sol';
import 'synthetix/contracts/interfaces/ISynthetix.sol';

import './IBPool.sol';
import './ISwaps.sol';

/**
 * @title sTSLA on-ramp
 */
contract TSLAExchange {
  // tokens
  address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address private constant SUSD = 0x57Ab1ec28D129707052df4dF418D58a2D46d5f51;
  address private constant STSLA = 0x918dA91Ccbc32B7a6A0cc4eCd5987bbab6E31e6D;
  // synthetix
  address private constant SNX = 0x97767D7D04Fd0dB0A1a2478DCd4BA85290556B48;
  address private constant SYSTEM_STATUS = 0x1c86B3CDF2a60Ae3a574f7f71d44E2C50BDdB87E;
  // curve
  address private constant SWAPS = 0xD1602F68CC7C4c7B59D686243EA35a9C73B0c6a2;
  // balancer
  address private constant BPOOL = 0x055dB9AFF4311788264798356bbF3a733AE181c6;

  constructor () {
    IERC20(USDC).approve(SWAPS, type(uint).max);
    IERC20(SUSD).approve(BPOOL, type(uint).max);
  }

  /**
   * @notice exchange USDC for sTSLA on behalf of sender
   * @dev contract must be approved to spend USDC
   * @dev contract must be approved to exchange on Synthetix on behalf of sender
   * @param amount quantity of USDC to exchange
   * @param susdMin minimum quantity of sUSD output by Curve
   * @param stslaMin minimum quantity of sTSLA output by Balancer
   * @return susd sUSD output amount
   * @return stsla sTSLA output amount
   */
  function exchange (
    uint amount,
    uint susdMin,
    uint stslaMin
  ) external returns (uint susd, uint stsla) {
    IERC20(USDC).transferFrom(msg.sender, address(this), amount);

    (bool suspended, ) = ISystemStatus(SYSTEM_STATUS).synthExchangeSuspension(
      'sTSLA'
    );

    susd = ISwaps(SWAPS).exchange_with_best_rate(
      USDC,
      SUSD,
      amount,
      susdMin,
      suspended ? address(this) : msg.sender
    );

    if (suspended) {
      (stsla, ) = IBPool(BPOOL).swapExactAmountIn(
        SUSD,
        susd,
        STSLA,
        stslaMin,
        type(uint).max
      );

      IERC20(STSLA).transfer(msg.sender, stsla);
    } else {
      stsla = ISynthetix(SNX).exchangeOnBehalf(
        msg.sender,
        'sUSD',
        susd,
        'sTSLA'
      );
    }

    return (susd, stsla);
  }
}

pragma solidity >=0.4.24;


// https://docs.synthetix.io/contracts/source/interfaces/ierc20
interface IERC20 {
    // ERC20 Optional Views
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    // Views
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Mutative functions
    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Events
    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}

pragma solidity >=0.4.24;


// https://docs.synthetix.io/contracts/source/interfaces/isystemstatus
interface ISystemStatus {
    struct Status {
        bool canSuspend;
        bool canResume;
    }

    struct Suspension {
        bool suspended;
        // reason is an integer code,
        // 0 => no reason, 1 => upgrading, 2+ => defined by system usage
        uint248 reason;
    }

    // Views
    function accessControl(bytes32 section, address account) external view returns (bool canSuspend, bool canResume);

    function requireSystemActive() external view;

    function requireIssuanceActive() external view;

    function requireExchangeActive() external view;

    function requireExchangeBetweenSynthsAllowed(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function requireSynthActive(bytes32 currencyKey) external view;

    function requireSynthsActive(bytes32 sourceCurrencyKey, bytes32 destinationCurrencyKey) external view;

    function systemSuspension() external view returns (bool suspended, uint248 reason);

    function issuanceSuspension() external view returns (bool suspended, uint248 reason);

    function exchangeSuspension() external view returns (bool suspended, uint248 reason);

    function synthExchangeSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function synthSuspension(bytes32 currencyKey) external view returns (bool suspended, uint248 reason);

    function getSynthExchangeSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory exchangeSuspensions, uint256[] memory reasons);

    function getSynthSuspensions(bytes32[] calldata synths)
        external
        view
        returns (bool[] memory suspensions, uint256[] memory reasons);

    // Restricted functions
    function suspendSynth(bytes32 currencyKey, uint256 reason) external;

    function updateAccessControl(
        bytes32 section,
        address account,
        bool canSuspend,
        bool canResume
    ) external;
}

pragma solidity >=0.4.24;

import "./ISynth.sol";
import "./IVirtualSynth.sol";


// https://docs.synthetix.io/contracts/source/interfaces/isynthetix
interface ISynthetix {
    // Views
    function anySynthOrSNXRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableSynthCount() external view returns (uint);

    function availableSynths(uint index) external view returns (ISynth);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuableSynths(address issuer) external view returns (uint maxIssuable);

    function remainingIssuableSynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function synths(bytes32 currencyKey) external view returns (ISynth);

    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedSynths(bytes32 currencyKey) external view returns (uint);

    function totalIssuedSynthsExcludeEtherCollateral(bytes32 currencyKey) external view returns (uint);

    function transferableSynthetix(address account) external view returns (uint transferable);

    // Mutative Functions
    function burnSynths(uint amount) external;

    function burnSynthsOnBehalf(address burnForAddress, uint amount) external;

    function burnSynthsToTarget() external;

    function burnSynthsToTargetOnBehalf(address burnForAddress) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeOnBehalf(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function exchangeWithTracking(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeOnBehalfWithTracking(
        address exchangeForAddress,
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        address originator,
        bytes32 trackingCode
    ) external returns (uint amountReceived);

    function exchangeWithVirtual(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        bytes32 trackingCode
    ) external returns (uint amountReceived, IVirtualSynth vSynth);

    function issueMaxSynths() external;

    function issueMaxSynthsOnBehalf(address issueForAddress) external;

    function issueSynths(uint amount) external;

    function issueSynthsOnBehalf(address issueForAddress, uint amount) external;

    function mint() external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    // Liquidations
    function liquidateDelinquentAccount(address account, uint susdAmount) external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint amount) external;

    function mintSecondaryRewards(uint amount) external;

    function burnSecondary(address account, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface IBPool {
  function swapExactAmountIn (
    address tokenIn,
    uint tokenAmountIn,
    address tokenOut,
    uint minAmountOut,
    uint maxPrice
  ) external returns (uint tokenAmountOut, uint spotPriceAfter);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

interface ISwaps {
  function exchange_with_best_rate(
    address from,
    address to,
    uint amount,
    uint expected,
    address recipient
  ) external payable returns (uint);
}

pragma solidity >=0.4.24;


// https://docs.synthetix.io/contracts/source/interfaces/isynth
interface ISynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferableSynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to Synthetix
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}

pragma solidity >=0.4.24;

import "./ISynth.sol";


interface IVirtualSynth {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function synth() external view returns (ISynth);

    // Mutative functions
    function settle(address account) external;
}