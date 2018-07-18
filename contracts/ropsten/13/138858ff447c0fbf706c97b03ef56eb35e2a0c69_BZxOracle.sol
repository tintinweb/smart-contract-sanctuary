/*

  Copyright 2018 bZeroX, LLC

  Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// This provides a gatekeeping modifier for functions that can only be used by the bZx contract
// Since it inherits Ownable it provides typical ownership functionality with a slight modification to the transferOwnership function
// Setting owner and bZxContractAddress to the same address is not supported.
contract BZxOwnable is Ownable {

    address public bZxContractAddress;

    event BZxOwnershipTransferred(address indexed previousBZxContract, address indexed newBZxContract);

    // modifier reverts if bZxContractAddress isn&#39;t set
    modifier onlyBZx() {
        require(msg.sender == bZxContractAddress, &quot;only bZx contracts can call this function&quot;);
        _;
    }

    /**
    * @dev Allows the current owner to transfer the bZx contract owner to a new contract address
    * @param newBZxContractAddress The bZx contract address to transfer ownership to.
    */
    function transferBZxOwnership(address newBZxContractAddress) public onlyOwner {
        require(newBZxContractAddress != address(0) && newBZxContractAddress != owner, &quot;transferBZxOwnership::unauthorized&quot;);
        emit BZxOwnershipTransferred(bZxContractAddress, newBZxContractAddress);
        bZxContractAddress = newBZxContractAddress;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    * This overrides transferOwnership in Ownable to prevent setting the new owner the same as the bZxContract
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0) && newOwner != bZxContractAddress, &quot;transferOwnership::unauthorized&quot;);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract GasRefunder {
    using SafeMath for uint256;

    // If true, uses the &quot;transfer&quot; method, which throws on failure, reverting state.
    // If false, a failed &quot;send&quot; won&#39;t throw, and fails silently.
    // Note that a throw will prevent a GasRefund event.
    bool public throwOnGasRefundFail = false;

    event GasRefund(address payer, uint gasUsed, uint currentGasPrice, uint refundAmount, bool refundSuccess);

    modifier refundsGas(address payer, uint gasPrice, uint gasUsed, uint percentMultiplier)
    {
        _; // modified function body inserted here

        calculateAndSendRefund(
            payer,
            gasUsed,
            gasPrice,
            percentMultiplier
        );
    }

    modifier refundsGasAfterCollection(address payer, uint gasPrice, uint percentMultiplier)
    {
        uint startingGas = gasleft();

        _; // modified function body inserted here
        
        calculateAndSendRefund(
            payer,
            startingGas,
            gasPrice,
            percentMultiplier
        );
    }

    function calculateAndSendRefund(
        address payer,
        uint gasUsed,
        uint gasPrice,
        uint percentMultiplier)
        internal
    {

        if (gasUsed == 0 || gasPrice == 0)
            return;

        gasUsed = gasUsed - gasleft();

        sendRefund(
            payer,
            gasUsed,
            gasPrice,
            percentMultiplier
        );
    }

    function sendRefund(
        address payer,
        uint gasUsed,
        uint gasPrice,
        uint percentMultiplier)
        internal
        returns (bool)
    {
        if (percentMultiplier == 0) // 0 percentMultiplier not allowed
            percentMultiplier = 100;
        
        uint refundAmount = gasUsed.mul(gasPrice).mul(percentMultiplier).div(100);

        if (throwOnGasRefundFail) {
            payer.transfer(refundAmount);
            emit GasRefund(
                payer,
                gasUsed,
                gasPrice,
                refundAmount,
                true
            );
        } else {
            // allow payer.send(refundAmount) to silently fail
            emit GasRefund(
                payer,
                gasUsed,
                gasPrice,
                refundAmount,
                payer.send(refundAmount) // solhint-disable-line check-send-result
            );
        }

        return true;
    }

}

// supports a single EMA calculated for the inheriting contract
contract EMACollector {
    //using SafeMath for uint256;

    uint public emaValue; // the last ema calculated
    uint public emaPeriods; // averaging periods for EMA calculation

    uint public outlierMultiplier = 2;
    uint public outlierAdder = 5**9 wei; // 5 gwei

    //event EMAUpdated(uint newEMA);

    modifier updatesEMA(uint value) {
        _;

        updateEMA(value);
    }

    function updateEMA(uint value) 
        internal {
        /*
            Multiplier: 2 / (emaPeriods + 1)
            EMA: (LastestValue - PreviousEMA) * Multiplier + PreviousEMA 
        */

        require(emaPeriods >= 2, &quot;emaPeriods < 2&quot;);

        // outliers are ignored
        if (value > emaValue && value >= SafeMath.add(SafeMath.mul(outlierMultiplier, emaValue), outlierAdder))
            return;

        // calculate new EMA
        emaValue = 
            SafeMath.sub(
                SafeMath.add(
                    value / (emaPeriods + 1) * 2,   // no overflow
                    emaValue
                ),
                emaValue / (emaPeriods + 1) * 2     // no overflow
            );
        //emit EMAUpdated(emaValue);
    }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title EIP20/ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract EIP20 is ERC20 {
    string public name;
    uint8 public decimals;
    string public symbol;
}

interface NonCompliantEIP20 {
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
}

/**
 * @title EIP20/ERC20 wrapper that will support noncompliant ERC20s
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev see https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
contract EIP20Wrapper {

    function eip20Transfer(
        address token,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transfer(to, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, &quot;eip20Transfer failed&quot;);
    }

    function eip20TransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transferFrom(from, to, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, &quot;eip20TransferFrom failed&quot;);
    }

    function eip20Approve(
        address token,
        address spender,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).approve(spender, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, &quot;eip20Approve failed&quot;);
    }
}

interface WETH_Interface {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface KyberNetwork_Interface {
    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    /// @dev makes a trade between src and dest token and send dest token to destAddress
    /// @param src Src token
    /// @param srcAmount amount of src tokens
    /// @param dest   Destination token
    /// @param destAddress Address to send tokens to
    /// @param maxDestAmount A limit on the amount of dest tokens
    /// @param minConversionRate The minimal conversion rate. If actual rate is lower, trade is canceled.
    /// @param walletId is the wallet ID to send part of the fees
    /// @return amount of actual dest tokens
    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        external
        payable
        returns(uint);

    /// @notice use token address ETH_TOKEN_ADDRESS for ether
    function getExpectedRate(
        address src,
        address dest,
        uint srcQty) 
        external 
        view 
        returns (uint expectedRate, uint slippageRate);
}

contract BZxOracle is EIP20Wrapper, EMACollector, GasRefunder, BZxOwnable {
    using SafeMath for uint256;

    // this is the value the Kyber portal uses when setting a very high maximum number
    uint internal constant MAX_FOR_KYBER = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    address internal constant KYBER_ETH_TOKEN_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    // Bounty hunters are remembursed from collateral
    // The oracle requires a minimum amount for a loan to be opened
    uint public minimumCollateralInEthAmount = 5**17 wei; // 0.5 ether

    // Percentage of interest retained as fee
    // This will always be between 0 and 100
    uint public interestFeePercent = 10;

    // Percentage of EMA-based gas refund paid to bounty hunters after successfully liquidating a position
    uint public bountyRewardPercent = 110;

    // An upper bound estimation on the liquidation gas cost
    uint public gasUpperBound = 300000;

    // A threshold of minimum initial margin for loan to be insured by the guarantee fund
    // A value of 0 indicates that no threshold exists for this parameter.
    uint public minInitialMarginAmount = 0;

    // A threshold of minimum maintenance margin for loan to be insured by the guarantee fund
    // A value of 0 indicates that no threshold exists for this parameter.
    uint public minMaintenanceMarginAmount = 25;

    bool public isManualTradingAllowed = true;

    address public vaultContract;
    address public kyberContract;
    address public wethContract;
    address public bZRxTokenContract;

    constructor(
        address _vaultContract,
        address _kyberContract,
        address _wethContract,
        address _bZRxTokenContract)
        public
        payable
    {
        vaultContract = _vaultContract;
        kyberContract = _kyberContract;
        wethContract = _wethContract;
        bZRxTokenContract = _bZRxTokenContract;

        // settings for EMACollector
        emaValue = 8 * 10**9 wei; // set an initial price average for gas (8 gwei)
        emaPeriods = 10; // set periods to use for EMA calculation
    }

    // The contract needs to be able to receive Ether from Kyber trades
    function() public payable {}


    // orderAddresses: loanTokenAddress, collateralTokenAddress, interestTokenAddress, taker
    // orderAmounts: loanTokenAmount, collateralTokenAmount, interestTokenAmount, gasUsed
    function didTakeOrder(
        bytes32 /* loanOrderHash */,
        address[4] orderAddresses,
        uint[4] orderAmounts)
        public
        onlyBZx
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        uint collateralInEthAmount;
        if (orderAddresses[1] != wethContract) {
            (uint collateralToEthRate,) = _getExpectedRate(
                orderAddresses[1], // collateralTokenAddress
                wethContract,
                0
            );
            collateralInEthAmount = orderAmounts[1].mul(collateralToEthRate).div(10**18);
        } else {
            collateralInEthAmount = orderAmounts[1];
        }
        
        require(collateralInEthAmount >= minimumCollateralInEthAmount, &quot;collateral below minimum for BZxOracle&quot;);

        return true;
    }

    function didTradePosition(
        bytes32 /* loanOrderHash */,
        address /* trader */,
        address /* tradeTokenAddress */,
        uint /* tradeTokenAmount */,
        uint /* gasUsed */)
        public
        onlyBZx
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        return true;
    }

    function didPayInterest(
        bytes32 /* loanOrderHash */,
        address /* trader */,
        address lender,
        address interestTokenAddress,
        uint amountOwed,
        bool convert,
        uint /* gasUsed */)
        public
        onlyBZx
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        // interestFeePercent is only editable by owner
        uint interestFee = amountOwed.mul(interestFeePercent).div(100);

        // Transfers the interest to the lender, less the interest fee.
        // The fee is retained by the oracle.
        if (!_transferToken(
            interestTokenAddress,
            lender,
            amountOwed.sub(interestFee))) {
            revert(&quot;BZxOracle::didPayInterest: _transferToken failed&quot;);
        }

        if (interestTokenAddress == wethContract) {
            // interest paid in WETH is withdrawn to Ether
            WETH_Interface(wethContract).withdraw(interestFee);
        } else if (convert && interestTokenAddress != bZRxTokenContract) {
            // interest paid in BZRX is retained as is, other tokens are sold for Ether
            _doTradeForEth(
                interestTokenAddress,
                interestFee,
                this, // BZxOracle receives the Ether proceeds
                MAX_FOR_KYBER // no limit on the dest amount
            );
        }

        return true;
    }

    function didDepositCollateral(
        bytes32 /* loanOrderHash */,
        address /* borrower */,
        uint /* gasUsed */)
        public
        onlyBZx
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        return true;
    }

    function didWithdrawCollateral(
        bytes32 /* loanOrderHash */,
        address /* borrower */,
        uint /* gasUsed */)
        public
        onlyBZx
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        return true;
    }

    function didChangeCollateral(
        bytes32 /* loanOrderHash */,
        address /* borrower */,
        uint /* gasUsed */)
        public
        onlyBZx
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        return true;
    }

    function didWithdrawProfit(
        bytes32 /* loanOrderHash */,
        address /* borrower */,
        uint /* profitOrLoss */,
        uint /* gasUsed */)
        public
        onlyBZx
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        return true;
    }
    
    function didCloseLoan(
        bytes32 /* loanOrderHash */,
        address loanCloser,
        bool isLiquidation,
        uint gasUsed)
        public
        onlyBZx
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        // sends gas and bounty reward to bounty hunter
        if (isLiquidation) {
            calculateAndSendRefund(
                loanCloser,
                gasUsed,
                emaValue,
                bountyRewardPercent);
        }
        
        return true;
    }

    function doManualTrade(
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount)
        public
        onlyBZx
        returns (uint destTokenAmount)
    {
        if (isManualTradingAllowed) {
            destTokenAmount = _doTrade(
                sourceTokenAddress,
                destTokenAddress,
                sourceTokenAmount,
                MAX_FOR_KYBER); // no limit on the dest amount
        }
        else {
            revert(&quot;Manual trading is disabled.&quot;);
        }
    }

    function doTrade(
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount)
        public
        onlyBZx
        returns (uint destTokenAmount)
    {
        destTokenAmount = _doTrade(
            sourceTokenAddress,
            destTokenAddress,
            sourceTokenAmount,
            MAX_FOR_KYBER); // no limit on the dest amount
    }

    function verifyAndLiquidate(
        address loanTokenAddress,
        address positionTokenAddress,
        address collateralTokenAddress,
        uint loanTokenAmount,
        uint positionTokenAmount,
        uint collateralTokenAmount,
        uint maintenanceMarginAmount)
        public
        onlyBZx
        returns (uint destTokenAmount)
    {
        if (!shouldLiquidate(
            0x0,
            0x0,
            loanTokenAddress,
            positionTokenAddress,
            collateralTokenAddress,
            loanTokenAmount,
            positionTokenAmount,
            collateralTokenAmount,
            maintenanceMarginAmount)) {
            return 0;
        }
        
        destTokenAmount = _doTrade(
            positionTokenAddress,
            loanTokenAddress,
            positionTokenAmount,
            MAX_FOR_KYBER); // no limit on the dest amount
    }

    // note: bZx will only call this function if isLiquidation=true or loanTokenAmountNeeded > 0
    function processCollateral(
        address collateralTokenAddress,
        address loanTokenAddress,
        uint collateralTokenAmountUsable,
        uint loanTokenAmountNeeded,
        uint initialMarginAmount,
        uint maintenanceMarginAmount,
        bool isLiquidation)
        public
        onlyBZx
        returns (uint loanTokenAmountCovered, uint collateralTokenAmountUsed)
    {   
        require(isLiquidation || loanTokenAmountNeeded > 0, &quot;!isLiquidation && loanTokenAmountNeeded == 0&quot;);
        
        uint collateralTokenBalance = EIP20(collateralTokenAddress).balanceOf.gas(4999)(this); // Changes to state require at least 5000 gas
        if (collateralTokenBalance < collateralTokenAmountUsable) { // sanity check
            revert(&quot;BZxOracle::processCollateral: collateralTokenBalance < collateralTokenAmountUsable&quot;);
        }

        uint etherAmountNeeded = 0;
        uint etherAmountReceived = 0;

        if (loanTokenAmountNeeded > 0) {
            if (loanTokenAddress == wethContract) {
                etherAmountNeeded = loanTokenAmountNeeded;
            } else {
                uint etherToLoan;
                (etherToLoan,) = _getExpectedRate(
                    wethContract,
                    loanTokenAddress, 
                    0
                );
                etherAmountNeeded = loanTokenAmountNeeded.mul(10**18).div(etherToLoan);
            }
        }

        // trade collateral token for ether
        etherAmountReceived = _doTradeForEth(
            collateralTokenAddress,
            collateralTokenAmountUsable,
            this, // BZxOracle receives the Ether proceeds
            !isLiquidation ? etherAmountNeeded : etherAmountNeeded.add(gasUpperBound.mul(emaValue).mul(bountyRewardPercent).div(100))
        );
        
        if (loanTokenAmountNeeded > 0) {
            if ((minInitialMarginAmount == 0 || initialMarginAmount >= minInitialMarginAmount) &&
                (minMaintenanceMarginAmount == 0 || maintenanceMarginAmount >= minMaintenanceMarginAmount)) {
                // cover losses with collateral proceeds + oracle insurance
                loanTokenAmountCovered = _doTradeWithEth(
                    loanTokenAddress,
                    address(this).balance, // maximum usable amount
                    vaultContract,
                    loanTokenAmountNeeded
                );
            } else {
                // cover losses with just collateral proceeds
                loanTokenAmountCovered = _doTradeWithEth(
                    loanTokenAddress,
                    etherAmountReceived, // maximum usable amount
                    vaultContract,
                    loanTokenAmountNeeded
                );
            }
        }

        collateralTokenAmountUsed = collateralTokenBalance.sub(EIP20(collateralTokenAddress).balanceOf.gas(4999)(this)); // Changes to state require at least 5000 gas
        
        if (collateralTokenAmountUsed < collateralTokenAmountUsable) {
            // send unused collateral token back to the vault
            if (!_transferToken(
                collateralTokenAddress,
                vaultContract,
                collateralTokenAmountUsable-collateralTokenAmountUsed)) {
                revert(&quot;BZxOracle::processCollateral: _transferToken failed&quot;);
            }
        }
    }

    /*
    * Public View functions
    */

    function shouldLiquidate(
        bytes32 /* loanOrderHash */,
        address /* trader */,
        address loanTokenAddress,
        address positionTokenAddress,
        address collateralTokenAddress,
        uint loanTokenAmount,
        uint positionTokenAmount,
        uint collateralTokenAmount,
        uint maintenanceMarginAmount)
        public
        view
        returns (bool)
    {
        return (
            getCurrentMarginAmount(
                loanTokenAddress,
                positionTokenAddress,
                collateralTokenAddress,
                loanTokenAmount,
                positionTokenAmount,
                collateralTokenAmount) <= maintenanceMarginAmount.mul(10**18)
            );
    } 

    function isTradeSupported(
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount)
        public
        view 
        returns (bool)
    {
        (uint rate, uint slippage) = _getExpectedRate(
            sourceTokenAddress,
            destTokenAddress,
            sourceTokenAmount);
        
        if (rate > 0 && (sourceTokenAmount == 0 || slippage > 0))
            return true;
        else
            return false;
    }

    function getTradeRate(
        address sourceTokenAddress,
        address destTokenAddress)
        public
        view 
        returns (uint rate)
    {
        (rate,) = _getExpectedRate(
            sourceTokenAddress,
            destTokenAddress,
            0);
    }

    // returns bool isProfit, uint profitOrLoss
    // the position&#39;s profit/loss denominated in positionToken
    function getProfitOrLoss(
        address positionTokenAddress,
        address loanTokenAddress,
        uint positionTokenAmount,
        uint loanTokenAmount)
        public
        view
        returns (bool isProfit, uint profitOrLoss)
    {
        uint loanToPositionAmount;
        if (positionTokenAddress == loanTokenAddress) {
            loanToPositionAmount = loanTokenAmount;
        } else {
            (uint positionToLoanRate,) = _getExpectedRate(
                positionTokenAddress,
                loanTokenAddress,
                0);
            if (positionToLoanRate == 0) {
                return;
            }
            loanToPositionAmount = loanTokenAmount.mul(10**18).div(positionToLoanRate);
        }

        if (positionTokenAmount > loanToPositionAmount) {
            isProfit = true;
            profitOrLoss = positionTokenAmount - loanToPositionAmount;
        } else {
            isProfit = false;
            profitOrLoss = loanToPositionAmount - positionTokenAmount;
        }
    }

    /// @return The current margin amount (a percentage -> i.e. 54350000000000000000 == 54.35%)
    function getCurrentMarginAmount(
        address loanTokenAddress,
        address positionTokenAddress,
        address collateralTokenAddress,
        uint loanTokenAmount,
        uint positionTokenAmount,
        uint collateralTokenAmount)
        public
        view
        returns (uint)
    {
        uint collateralToLoanAmount;
        if (collateralTokenAddress == loanTokenAddress) {
            collateralToLoanAmount = collateralTokenAmount;
        } else {
            (uint collateralToLoanRate,) = _getExpectedRate(
                collateralTokenAddress,
                loanTokenAddress,
                0);
            if (collateralToLoanRate == 0) {
                return 0;
            }
            collateralToLoanAmount = collateralTokenAmount.mul(collateralToLoanRate).div(10**18);
        }

        uint positionToLoanAmount;
        if (positionTokenAddress == loanTokenAddress) {
            positionToLoanAmount = positionTokenAmount;
        } else {
            (uint positionToLoanRate,) = _getExpectedRate(
                positionTokenAddress,
                loanTokenAddress,
                0);
            if (positionToLoanRate == 0) {
                return 0;
            }
            positionToLoanAmount = positionTokenAmount.mul(positionToLoanRate).div(10**18);
        }

        return collateralToLoanAmount.add(positionToLoanAmount).sub(loanTokenAmount).mul(10**20).div(loanTokenAmount);
    }

    /*
    * Owner functions
    */

    function setMinimumCollateralInEthAmount(
        uint newValue) 
        public
        onlyOwner
    {
        require(newValue != minimumCollateralInEthAmount);
        minimumCollateralInEthAmount = newValue;
    }

    function setInterestFeePercent(
        uint newRate) 
        public
        onlyOwner
    {
        require(newRate != interestFeePercent && newRate <= 100);
        interestFeePercent = newRate;
    }

    function setBountyRewardPercent(
        uint newValue) 
        public
        onlyOwner
    {
        require(newValue != bountyRewardPercent);
        bountyRewardPercent = newValue;
    }

    function setGasUpperBound(
        uint newValue) 
        public
        onlyOwner
    {
        require(newValue != gasUpperBound);
        gasUpperBound = newValue;
    }

    function setMarginThresholds(
        uint newInitialMargin,
        uint newMaintenanceMargin) 
        public
        onlyOwner
    {
        require(newInitialMargin >= newMaintenanceMargin);
        minInitialMarginAmount = newInitialMargin;
        minMaintenanceMarginAmount = newMaintenanceMargin;
    }

    function setManualTradingAllowed (
        bool _isManualTradingAllowed)
        public
        onlyOwner
    {
        if (isManualTradingAllowed != _isManualTradingAllowed)
            isManualTradingAllowed = _isManualTradingAllowed;
    }

    function setVaultContractAddress(
        address newAddress) 
        public
        onlyOwner
    {
        require(newAddress != vaultContract && newAddress != address(0));
        vaultContract = newAddress;
    }

    function setKyberContractAddress(
        address newAddress) 
        public
        onlyOwner
    {
        require(newAddress != kyberContract && newAddress != address(0));
        kyberContract = newAddress;
    }

    function setWethContractAddress(
        address newAddress) 
        public
        onlyOwner
    {
        require(newAddress != wethContract && newAddress != address(0));
        wethContract = newAddress;
    }

    function setBZRxTokenContractAddress(
        address newAddress) 
        public
        onlyOwner
    {
        require(newAddress != bZRxTokenContract && newAddress != address(0));
        bZRxTokenContract = newAddress;
    }

    function setEMAValue (
        uint _newEMAValue)
        public
        onlyOwner {
        require(_newEMAValue != emaValue);
        emaValue = _newEMAValue;
    }

    function setEMAPeriods (
        uint _newEMAPeriods)
        public
        onlyOwner {
        require(_newEMAPeriods > 1 && _newEMAPeriods != emaPeriods);
        emaPeriods = _newEMAPeriods;
    }

    function transferEther(
        address to,
        uint value)
        public
        onlyOwner
        returns (bool)
    {
        return (_transferEther(
            to,
            value
        ));
    }

    function transferToken(
        address tokenAddress,
        address to,
        uint value)
        public
        onlyOwner
        returns (bool)
    {
        return (_transferToken(
            tokenAddress,
            to,
            value
        ));
    }

    /*
    * Internal functions
    */

    // ref: https://github.com/KyberNetwork/smart-contracts/blob/master/integration.md#rate-query
    function _getExpectedRate(
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount)
        internal
        view 
        returns (uint expectedRate, uint slippageRate)
    {
        if (sourceTokenAddress == destTokenAddress) {
            expectedRate = 10**18;
            slippageRate = 0;
        } else {
            if (sourceTokenAddress == wethContract) {
                (expectedRate, slippageRate) = KyberNetwork_Interface(kyberContract).getExpectedRate(
                    KYBER_ETH_TOKEN_ADDRESS,
                    destTokenAddress, 
                    sourceTokenAmount
                );
            } else if (destTokenAddress == wethContract) {
                (expectedRate, slippageRate) = KyberNetwork_Interface(kyberContract).getExpectedRate(
                    sourceTokenAddress,
                    KYBER_ETH_TOKEN_ADDRESS,
                    sourceTokenAmount
                );
            } else {
                (uint sourceToEther, uint sourceToEtherSlippage) = KyberNetwork_Interface(kyberContract).getExpectedRate(
                    sourceTokenAddress,
                    KYBER_ETH_TOKEN_ADDRESS,
                    sourceTokenAmount
                );
                if (sourceTokenAmount > 0) {
                    sourceTokenAmount = sourceTokenAmount.mul(sourceToEther).div(10**18);
                }

                (uint etherToDest, uint etherToDestSlippage) = KyberNetwork_Interface(kyberContract).getExpectedRate(
                    KYBER_ETH_TOKEN_ADDRESS,
                    destTokenAddress,
                    sourceTokenAmount
                );

                expectedRate = sourceToEther.mul(etherToDest).div(10**18);
                slippageRate = sourceToEtherSlippage.mul(etherToDestSlippage).div(10**18);
            }
        }
    }

    function _doTrade(
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount,
        uint maxDestTokenAmount)
        internal
        returns (uint destTokenAmount)
    {
        if (sourceTokenAddress == destTokenAddress) {
            if (maxDestTokenAmount < MAX_FOR_KYBER) {
                destTokenAmount = maxDestTokenAmount;
            } else {
                destTokenAmount = sourceTokenAmount;
            }
        } else {
            if (sourceTokenAddress == wethContract) {
                WETH_Interface(wethContract).withdraw(sourceTokenAmount);

                destTokenAmount = KyberNetwork_Interface(kyberContract).trade
                    .value(sourceTokenAmount)( // send Ether along 
                    KYBER_ETH_TOKEN_ADDRESS,
                    sourceTokenAmount,
                    destTokenAddress,
                    vaultContract, // bZxVault recieves the destToken
                    maxDestTokenAmount,
                    0, // no min coversation rate
                    address(0)
                );
            } else if (destTokenAddress == wethContract) {
                // re-up the Kyber spend approval if needed
                if (EIP20(sourceTokenAddress).allowance.gas(4999)(this, kyberContract) < 
                    MAX_FOR_KYBER) {
                    
                    eip20Approve(
                        sourceTokenAddress,
                        kyberContract,
                        MAX_FOR_KYBER);
                }

                destTokenAmount = KyberNetwork_Interface(kyberContract).trade(
                    sourceTokenAddress,
                    sourceTokenAmount,
                    KYBER_ETH_TOKEN_ADDRESS,
                    this, // BZxOracle receives the Ether proceeds
                    maxDestTokenAmount,
                    0, // no min coversation rate
                    address(0)
                );

                WETH_Interface(wethContract).deposit.value(destTokenAmount)();

                if (!_transferToken(
                    destTokenAddress,
                    vaultContract,
                    destTokenAmount)) {
                    revert(&quot;BZxOracle::_doTrade: _transferToken failed&quot;);
                }
            } else {
                // re-up the Kyber spend approval if needed
                if (EIP20(sourceTokenAddress).allowance.gas(4999)(this, kyberContract) < 
                    MAX_FOR_KYBER) {
                    
                    eip20Approve(
                        sourceTokenAddress,
                        kyberContract,
                        MAX_FOR_KYBER);
                }
                
                uint maxDestEtherAmount = maxDestTokenAmount;
                if (maxDestTokenAmount < MAX_FOR_KYBER) {
                    uint etherToDest;
                    (etherToDest,) = KyberNetwork_Interface(kyberContract).getExpectedRate(
                        KYBER_ETH_TOKEN_ADDRESS,
                        destTokenAddress, 
                        0
                    );
                    maxDestEtherAmount = maxDestTokenAmount.mul(10**18).div(etherToDest);
                }

                uint destEtherAmount = KyberNetwork_Interface(kyberContract).trade(
                    sourceTokenAddress,
                    sourceTokenAmount,
                    KYBER_ETH_TOKEN_ADDRESS,
                    this, // BZxOracle receives the Ether proceeds
                    maxDestEtherAmount,
                    0, // no min coversation rate
                    address(0)
                );

                destTokenAmount = KyberNetwork_Interface(kyberContract).trade
                    .value(destEtherAmount)( // send Ether along 
                    KYBER_ETH_TOKEN_ADDRESS,
                    destEtherAmount,
                    destTokenAddress,
                    vaultContract, // bZxVault recieves the destToken
                    maxDestTokenAmount,
                    0, // no min coversation rate
                    address(0)
                );
            }
        }
    }

    function _doTradeForEth(
        address sourceTokenAddress,
        uint sourceTokenAmount,
        address receiver,
        uint destEthAmountNeeded)
        internal
        returns (uint)
    {
        if (sourceTokenAddress == wethContract) {
            if (destEthAmountNeeded > sourceTokenAmount)
                destEthAmountNeeded = sourceTokenAmount;
            WETH_Interface(wethContract).withdraw(destEthAmountNeeded);

            if (receiver != address(this)) {
                if (!_transferEther(
                    receiver,
                    destEthAmountNeeded)) {
                    revert(&quot;BZxOracle::_doTradeForEth: _transferEther failed&quot;);
                }
            }
            
            return destEthAmountNeeded;
        } else {
            // re-up the Kyber spend approval if needed
            if (EIP20(sourceTokenAddress).allowance.gas(4999)(this, kyberContract) < 
                MAX_FOR_KYBER) {

                eip20Approve(
                    sourceTokenAddress,
                    kyberContract,
                    MAX_FOR_KYBER);
            }


            /* the following code is to allow the Kyber trade to fail silently and not revert if it does, preventing a &quot;bubble up&quot; */
            
            // bytes4(keccak256(&quot;trade(address,uint256,address,address,uint256,uint256,address)&quot;)) = 0xcb3c28c7
            bool result = kyberContract.call
                .gas(gasleft())(
                0xcb3c28c7,
                sourceTokenAddress,
                sourceTokenAmount,
                KYBER_ETH_TOKEN_ADDRESS,
                receiver,
                destEthAmountNeeded,
                0, // no min coversation rate
                address(0)
            );

            assembly {
                let size := returndatasize
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, size)
                switch result
                case 0 { return(0, 0x20) }
                default { return(ptr, size) }
            }
        }
    }

    function _doTradeWithEth(
        address destTokenAddress,
        uint sourceEthAmount,
        address receiver,
        uint destTokenAmountNeeded)
        internal
        returns (uint)
    {
        if (destTokenAddress == wethContract) {
            if (destTokenAmountNeeded > sourceEthAmount)
                destTokenAmountNeeded = sourceEthAmount;
            if (destTokenAmountNeeded > address(this).balance)
                destTokenAmountNeeded = address(this).balance;
            
            WETH_Interface(wethContract).deposit.value(destTokenAmountNeeded)();
            if (receiver != address(this)) {
                if (!_transferToken(
                    wethContract,
                    receiver,
                    destTokenAmountNeeded)) {
                    revert(&quot;BZxOracle::_doTradeWithEth: _transferToken failed&quot;);
                }
            }
            
            return destTokenAmountNeeded;
        } else {
            if (sourceEthAmount == address(this).balance) {
                // only send a little more than needed, rather than the entire contract balance
                uint etherToDest;
                (etherToDest,) = KyberNetwork_Interface(kyberContract).getExpectedRate(
                    KYBER_ETH_TOKEN_ADDRESS,
                    destTokenAddress, 
                    0
                );
                // calculate amount of ETH to use with a 5% buffer (unused ETH is returned by Kyber)
                sourceEthAmount = destTokenAmountNeeded.mul(10**18).div(etherToDest).mul(105).div(100);
                if (sourceEthAmount > address(this).balance) {
                    sourceEthAmount = address(this).balance;
                }
            }


            /* the following code is to allow the Kyber trade to fail silently and not revert if it does, preventing a &quot;bubble up&quot; */

            // bytes4(keccak256(&quot;trade(address,uint256,address,address,uint256,uint256,address)&quot;)) = 0xcb3c28c7
            bool result = kyberContract.call
                .gas(gasleft())
                .value(sourceEthAmount)( // send Ether along 
                0xcb3c28c7,
                KYBER_ETH_TOKEN_ADDRESS,
                sourceEthAmount,
                destTokenAddress,
                receiver,
                destTokenAmountNeeded,
                0, // no min coversation rate
                address(0)
            );

            assembly {
                let size := returndatasize
                let ptr := mload(0x40)
                returndatacopy(ptr, 0, size)
                switch result
                case 0 { return(0, 0x20) }
                default { return(ptr, size) }
            }
        }
    }

    function _transferEther(
        address to,
        uint value)
        internal
        returns (bool)
    {
        uint amount = value;
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }

        return (to.send(amount));
    }

    function _transferToken(
        address tokenAddress,
        address to,
        uint value)
        internal
        returns (bool)
    {
        eip20Transfer(
            tokenAddress,
            to,
            value);

        return true;
    }
}