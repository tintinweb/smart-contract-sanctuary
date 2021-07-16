/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

/*
    ___            _       ___  _                          
    | .\ ___  _ _ <_> ___ | __><_>._ _  ___ ._ _  ___  ___ 
    |  _// ._>| '_>| ||___|| _> | || ' |<_> || ' |/ | '/ ._>
    |_|  \___.|_|  |_|     |_|  |_||_|_|<___||_|_|\_|_.\___.
    
* PeriFinance: PynthUtil.sol
*
* Latest source (may be newer): https://github.com/perifinance/peri-finance/blob/master/contracts/PynthUtil.sol
* Docs: Will be added in the future. 
* https://docs.peri.finance/contracts/source/contracts/PynthUtil
*
* Contract Dependencies: (none)
* Libraries: (none)
*
* MIT License
* ===========
*
* Copyright (c) 2021 PeriFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/



pragma solidity 0.5.16;

// https://docs.peri.finance/contracts/source/interfaces/ipynth
interface IPynth {
    // Views
    function currencyKey() external view returns (bytes32);

    function transferablePynths(address account) external view returns (uint);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    function transferFromAndSettle(
        address from,
        address to,
        uint value
    ) external returns (bool);

    // Restricted: used internally to PeriFinance
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}


interface IVirtualPynth {
    // Views
    function balanceOfUnderlying(address account) external view returns (uint);

    function rate() external view returns (uint);

    function readyToSettle() external view returns (bool);

    function secsLeftInWaitingPeriod() external view returns (uint);

    function settled() external view returns (bool);

    function pynth() external view returns (IPynth);

    // Mutative functions
    function settle(address account) external;
}


// https://docs.peri.finance/contracts/source/interfaces/iperiFinance
interface IPeriFinance {
    // Views
    function getRequiredAddress(bytes32 contractName) external view returns (address);

    function anyPynthOrPERIRateIsInvalid() external view returns (bool anyRateInvalid);

    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availablePynthCount() external view returns (uint);

    function availablePynths(uint index) external view returns (IPynth);

    function collateral(address account) external view returns (uint);

    function collateralisationRatio(address issuer) external view returns (uint);

    function debtBalanceOf(address issuer, bytes32 currencyKey) external view returns (uint);

    function isWaitingPeriod(bytes32 currencyKey) external view returns (bool);

    function maxIssuablePynths(address issuer) external view returns (uint maxIssuable);

    function remainingIssuablePynths(address issuer)
        external
        view
        returns (
            uint maxIssuable,
            uint alreadyIssued,
            uint totalSystemDebt
        );

    function pynths(bytes32 currencyKey) external view returns (IPynth);

    function pynthsByAddress(address pynthAddress) external view returns (bytes32);

    function totalIssuedPynths(bytes32 currencyKey) external view returns (uint);

    function totalIssuedPynthsExcludeEtherCollateral(bytes32 currencyKey) external view returns (uint);

    function transferablePeriFinance(address account) external view returns (uint transferable);

    function currentUSDCDebtQuota(address _account) external view returns (uint);

    function usdcStakedAmountOf(address _account) external view returns (uint);

    function usdcTotalStakedAmount() external view returns (uint);

    function userUSDCStakingShare(address _account) external view returns (uint);

    function totalUSDCStakerCount() external view returns (uint);

    // Mutative Functions
    function issuePynthsAndStakeUSDC(uint _issueAmount, uint _usdcStakeAmount) external;

    function issueMaxPynths() external;

    function issuePynthsAndStakeMaxUSDC(uint _issueAmount) external;

    function burnPynthsAndUnstakeUSDC(uint _burnAmount, uint _unstakeAmount) external;

    function burnPynthsAndUnstakeUSDCToTarget() external;

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
    ) external returns (uint amountReceived, IVirtualPynth vPynth);

    function mint(address _user, uint _amount) external returns (bool);

    function inflationalMint(uint _networkDebtShare) external returns (bool);

    function settle(bytes32 currencyKey)
        external
        returns (
            uint reclaimed,
            uint refunded,
            uint numEntries
        );

    // Liquidations
    function liquidateDelinquentAccount(address account, uint pusdAmount) external returns (bool);

    // Restricted Functions

    function mintSecondary(address account, uint amount) external;

    function mintSecondaryRewards(uint amount) external;

    function burnSecondary(address account, uint amount) external;
}


// https://docs.peri.finance/contracts/source/interfaces/iexchangerates
interface IExchangeRates {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    struct InversePricing {
        uint entryPoint;
        uint upperLimit;
        uint lowerLimit;
        bool frozenAtUpperLimit;
        bool frozenAtLowerLimit;
    }

    // Views
    function aggregators(bytes32 currencyKey) external view returns (address);

    function aggregatorWarningFlags() external view returns (address);

    function anyRateIsInvalid(bytes32[] calldata currencyKeys) external view returns (bool);

    function canFreezeRate(bytes32 currencyKey) external view returns (bool);

    function currentRoundForRate(bytes32 currencyKey) external view returns (uint);

    function currenciesUsingAggregator(address aggregator) external view returns (bytes32[] memory);

    function effectiveValue(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external view returns (uint value);

    function effectiveValueAndRates(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    )
        external
        view
        returns (
            uint value,
            uint sourceRate,
            uint destinationRate
        );

    function effectiveValueAtRound(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey,
        uint roundIdForSrc,
        uint roundIdForDest
    ) external view returns (uint value);

    function getCurrentRoundId(bytes32 currencyKey) external view returns (uint);

    function getLastRoundIdBeforeElapsedSecs(
        bytes32 currencyKey,
        uint startingRoundId,
        uint startingTimestamp,
        uint timediff
    ) external view returns (uint);

    function inversePricing(bytes32 currencyKey)
        external
        view
        returns (
            uint entryPoint,
            uint upperLimit,
            uint lowerLimit,
            bool frozenAtUpperLimit,
            bool frozenAtLowerLimit
        );

    function lastRateUpdateTimes(bytes32 currencyKey) external view returns (uint256);

    function oracle() external view returns (address);

    function rateAndTimestampAtRound(bytes32 currencyKey, uint roundId) external view returns (uint rate, uint time);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function rateAndInvalid(bytes32 currencyKey) external view returns (uint rate, bool isInvalid);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateIsFlagged(bytes32 currencyKey) external view returns (bool);

    function rateIsFrozen(bytes32 currencyKey) external view returns (bool);

    function rateIsInvalid(bytes32 currencyKey) external view returns (bool);

    function rateIsStale(bytes32 currencyKey) external view returns (bool);

    function rateStalePeriod() external view returns (uint);

    function ratesAndUpdatedTimeForCurrencyLastNRounds(bytes32 currencyKey, uint numRounds)
        external
        view
        returns (uint[] memory rates, uint[] memory times);

    function ratesAndInvalidForCurrencies(bytes32[] calldata currencyKeys)
        external
        view
        returns (uint[] memory rates, bool anyRateInvalid);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);

    // Mutative functions
    function freezeRate(bytes32 currencyKey) external;
}


// https://docs.peri.finance/contracts/source/interfaces/iaddressresolver
interface IAddressResolver {
    function getAddress(bytes32 name) external view returns (address);

    function getPynth(bytes32 key) external view returns (address);

    function requireAndGetAddress(bytes32 name, string calldata reason) external view returns (address);
}


// https://docs.peri.finance/contracts/source/interfaces/ierc20
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


// Inheritance


// https://docs.peri.finance/contracts/source/contracts/pynthutil
contract PynthUtil {
    IAddressResolver public addressResolverProxy;

    bytes32 internal constant CONTRACT_PERIFINANCE = "PeriFinance";
    bytes32 internal constant CONTRACT_EXRATES = "ExchangeRates";
    bytes32 internal constant PUSD = "pUSD";

    constructor(address resolver) public {
        addressResolverProxy = IAddressResolver(resolver);
    }

    function _periFinance() internal view returns (IPeriFinance) {
        return IPeriFinance(addressResolverProxy.requireAndGetAddress(CONTRACT_PERIFINANCE, "Missing PeriFinance address"));
    }

    function _exchangeRates() internal view returns (IExchangeRates) {
        return IExchangeRates(addressResolverProxy.requireAndGetAddress(CONTRACT_EXRATES, "Missing ExchangeRates address"));
    }

    function totalPynthsInKey(address account, bytes32 currencyKey) external view returns (uint total) {
        IPeriFinance periFinance = _periFinance();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numPynths = periFinance.availablePynthCount();
        for (uint i = 0; i < numPynths; i++) {
            IPynth pynth = periFinance.availablePynths(i);
            total += exchangeRates.effectiveValue(
                pynth.currencyKey(),
                IERC20(address(pynth)).balanceOf(account),
                currencyKey
            );
        }
        return total;
    }

    function pynthsBalances(address account)
        external
        view
        returns (
            bytes32[] memory,
            uint[] memory,
            uint[] memory
        )
    {
        IPeriFinance periFinance = _periFinance();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numPynths = periFinance.availablePynthCount();
        bytes32[] memory currencyKeys = new bytes32[](numPynths);
        uint[] memory balances = new uint[](numPynths);
        uint[] memory pUSDBalances = new uint[](numPynths);
        for (uint i = 0; i < numPynths; i++) {
            IPynth pynth = periFinance.availablePynths(i);
            currencyKeys[i] = pynth.currencyKey();
            balances[i] = IERC20(address(pynth)).balanceOf(account);
            pUSDBalances[i] = exchangeRates.effectiveValue(currencyKeys[i], balances[i], PUSD);
        }
        return (currencyKeys, balances, pUSDBalances);
    }

    function frozenPynths() external view returns (bytes32[] memory) {
        IPeriFinance periFinance = _periFinance();
        IExchangeRates exchangeRates = _exchangeRates();
        uint numPynths = periFinance.availablePynthCount();
        bytes32[] memory frozenPynthsKeys = new bytes32[](numPynths);
        for (uint i = 0; i < numPynths; i++) {
            IPynth pynth = periFinance.availablePynths(i);
            if (exchangeRates.rateIsFrozen(pynth.currencyKey())) {
                frozenPynthsKeys[i] = pynth.currencyKey();
            }
        }
        return frozenPynthsKeys;
    }

    function pynthsRates() external view returns (bytes32[] memory, uint[] memory) {
        bytes32[] memory currencyKeys = _periFinance().availableCurrencyKeys();
        return (currencyKeys, _exchangeRates().ratesForCurrencies(currencyKeys));
    }

    function pynthsTotalSupplies()
        external
        view
        returns (
            bytes32[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        IPeriFinance periFinance = _periFinance();
        IExchangeRates exchangeRates = _exchangeRates();

        uint256 numPynths = periFinance.availablePynthCount();
        bytes32[] memory currencyKeys = new bytes32[](numPynths);
        uint256[] memory balances = new uint256[](numPynths);
        uint256[] memory pUSDBalances = new uint256[](numPynths);
        for (uint256 i = 0; i < numPynths; i++) {
            IPynth pynth = periFinance.availablePynths(i);
            currencyKeys[i] = pynth.currencyKey();
            balances[i] = IERC20(address(pynth)).totalSupply();
            pUSDBalances[i] = exchangeRates.effectiveValue(currencyKeys[i], balances[i], PUSD);
        }
        return (currencyKeys, balances, pUSDBalances);
    }
}