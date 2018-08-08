/*

  Copyright 2018 bZeroX, LLC

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
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
 * functions, this simplifies the implementation of "user permissions".
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
// Since it inherits Ownable provides typical ownership functionality with a slight modification to the transferOwnership function
// Setting owner and bZxContractAddress to the same address is not supported.
contract BZxOwnable is Ownable {

    address public bZxContractAddress;

    event BZxOwnershipTransferred(address indexed previousBZxContract, address indexed newBZxContract);

    // modifier reverts if bZxContractAddress isn&#39;t set
    modifier onlyBZx() {
        require(msg.sender == bZxContractAddress, "only bZx contracts can call this function");
        _;
    }

    /**
    * @dev Allows the current owner to transfer the bZx contract owner to a new contract address
    * @param newBZxContractAddress The bZx contract address to transfer ownership to.
    */
    function transferBZxOwnership(address newBZxContractAddress) public onlyOwner {
        require(newBZxContractAddress != address(0) && newBZxContractAddress != owner, "transferBZxOwnership::unauthorized");
        emit BZxOwnershipTransferred(bZxContractAddress, newBZxContractAddress);
        bZxContractAddress = newBZxContractAddress;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    * This overrides transferOwnership in Ownable to prevent setting the new owner the same as the bZxContract
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0) && newOwner != bZxContractAddress, "transferOwnership::unauthorized");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract GasRefunder {
    using SafeMath for uint256;

    // If true, uses the "transfer" method, which throws on failure, reverting state.
    // If false, a failed "send" won&#39;t throw, and fails silently.
    // Note that a throw will prevent a GasRefund event.
    bool public throwOnGasRefundFail = false;

    struct GasData {
        address payer;
        uint gasUsed;
        bool isPaid;
    }

    event GasRefund(address payer, uint gasUsed, uint currentGasPrice, uint refundAmount, bool refundSuccess);

    modifier refundsGas(address payer, uint gasPrice, uint gasUsed, uint percentMultiplier)
    {
        _;
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
        _;
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
            emit GasRefund(
                payer,
                gasUsed,
                gasPrice,
                refundAmount,
                payer.send(refundAmount)
            );
        }

        return true;
    }

}

// supports a single EMA calculated for the inheriting contract
contract EMACollector {

    uint public emaValue; // the last ema calculated
    uint public emaPeriods; // averaging periods for EMA calculation

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

        require(emaPeriods >= 2, "emaPeriods < 2");

        // calculate new EMA
        emaValue = 
            SafeMath.sub(
                SafeMath.add(
                    value / (emaPeriods + 1) * 2,
                    emaValue
                ),
                emaValue / (emaPeriods + 1) * 2
            );
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

        require(result, "eip20Transfer failed");
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

        require(result, "eip20TransferFrom failed");
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

        require(result, "eip20Approve failed");
    }
}

interface OracleInterface {

    /// @dev Called by bZx after a loan order is taken
    /// @param loanOrderHash A unique hash representing the loan order
    /// @param taker The taker of the loan order
    /// @param gasUsed The initial used gas, collected in a modifier in bZx, for optional gas refunds
    /// @return Successful execution of the function
    function didTakeOrder(
        bytes32 loanOrderHash,
        address taker,
        uint gasUsed)
        external
        returns (bool);

    /// @dev Called by bZx after a position token is traded
    /// @param loanOrderHash A unique hash representing the loan order
    /// @param trader The trader doing the trade
    /// @param tradeTokenAddress The token that was bought in the trade
    /// @param tradeTokenAmount The amount of token that was bought
    /// @param gasUsed The initial used gas, collected in a modifier in bZx, for optional gas refunds
    /// @return Successful execution of the function
    function didTradePosition(
        bytes32 loanOrderHash,
        address trader,
        address tradeTokenAddress,
        uint tradeTokenAmount,
        uint gasUsed)
        external
        returns (bool);

    /// @dev Called by bZx after interest should be paid to a lender
    /// @dev Assume the interest token has already been transfered to
    /// @dev this contract before this function is called.
    /// @param loanOrderHash A unique hash representing the loan order
    /// @param trader The trader
    /// @param lender The lender
    /// @param interestTokenAddress The token that will be paid for interest
    /// @param amountOwed The amount interest to pay
    /// @param convert A boolean indicating if the interest should be converted to Ether
    /// @param gasUsed The initial used gas, collected in a modifier in bZx, for optional gas refunds
    /// @return Successful execution of the function
    function didPayInterest(
        bytes32 loanOrderHash,
        address trader,
        address lender,
        address interestTokenAddress,
        uint amountOwed,
        bool convert,
        uint gasUsed)
        external
        returns (bool);

    /// @dev Called by bZx after a borrower has deposited additional collateral
    /// @dev token for an open loan
    /// @param loanOrderHash A unique hash representing the loan order.
    /// @param borrower The borrower
    /// @param gasUsed The initial used gas, collected in a modifier in bZx, for optional gas refunds
    /// @return Successful execution of the function
    function didDepositCollateral(
        bytes32 loanOrderHash,
        address borrower,
        uint gasUsed)
        external
        returns (bool);

    /// @dev Called by bZx after a borrower has withdrawn excess collateral
    /// @dev token for an open loan
    /// @param loanOrderHash A unique hash representing the loan order.
    /// @param borrower The borrower
    /// @param gasUsed The initial used gas, collected in a modifier in bZx, for optional gas refunds
    /// @return Successful execution of the function
    function didWithdrawCollateral(
        bytes32 loanOrderHash,
        address borrower,
        uint gasUsed)
        external
        returns (bool);

    /// @dev Called by bZx after a borrower has changed the collateral token
    /// @dev used for an open loan
    /// @param loanOrderHash A unique hash representing the loan order
    /// @param borrower The borrower
    /// @param gasUsed The initial used gas, collected in a modifier in bZx, for optional gas refunds
    /// @return Successful execution of the function
    function didChangeCollateral(
        bytes32 loanOrderHash,
        address borrower,
        uint gasUsed)
        external
        returns (bool);

    /// @dev Called by bZx after a borrower has withdraw their profits, if any
    /// @dev used for an open loan
    /// @param loanOrderHash A unique hash representing the loan order
    /// @param borrower The borrower
    /// @param gasUsed The initial used gas, collected in a modifier in bZx, for optional gas refunds
    /// @return Successful execution of the function
    function didWithdrawProfit(
        bytes32 loanOrderHash,
        address borrower,
        uint profitOrLoss,
        uint gasUsed)
        external
        returns (bool);

    /// @dev Called by bZx after a loan is closed
    /// @param loanOrderHash A unique hash representing the loan order.
    /// @param loanCloser The user that closed the loan
    /// @param isLiquidation A boolean indicating if the loan was closed due to liquidation
    /// @param gasUsed The initial used gas, collected in a modifier in bZx, for optional gas refunds
    /// @return Successful execution of the function
    function didCloseLoan(
        bytes32 loanOrderHash,
        address loanCloser,
        bool isLiquidation,
        uint gasUsed)
        external
        returns (bool);

    /// @dev Places a manual on-chain trade with a liquidity provider
    /// @param sourceTokenAddress The token being sold
    /// @param destTokenAddress The token being bought
    /// @param sourceTokenAmount The amount of token being sold
    /// @return The amount of destToken bought
    function doManualTrade(
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount)
        external
        returns (uint);

    /// @dev Places an automatic on-chain trade with a liquidity provider
    /// @param sourceTokenAddress The token being sold
    /// @param destTokenAddress The token being bought
    /// @param sourceTokenAmount The amount of token being sold
    /// @return The amount of destToken bought
    function doTrade(
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount)
        external
        returns (uint);

    /// @dev Verifies a position has fallen below margin maintenance
    /// @dev then liquidates the position on-chain
    /// @param loanTokenAddress The token that was loaned
    /// @param positionTokenAddress The token in the current position (could also be the loanToken)
    /// @param collateralTokenAddress The token used for collateral
    /// @param loanTokenAmount The amount of loan token
    /// @param positionTokenAmount The amount of position token
    /// @param collateralTokenAmount The amount of collateral token
    /// @param maintenanceMarginAmount The maintenance margin amount from the loan
    /// @return The amount of destToken bought
    function verifyAndLiquidate(
        address loanTokenAddress,
        address positionTokenAddress,
        address collateralTokenAddress,
        uint loanTokenAmount,
        uint positionTokenAmount,
        uint collateralTokenAmount,
        uint maintenanceMarginAmount)
        external
        returns (uint);

    /// @dev Liquidates collateral to cover loan losses
    /// @param collateralTokenAddress The collateral token
    /// @param loanTokenAddress The loan token
    /// @param collateralTokenAmountUsable The total amount of collateral usable to cover losses
    /// @param loanTokenAmountNeeded The amount of loan token needed to cover losses
    /// @param initialMarginAmount The initial margin amount set for the loan
    /// @param maintenanceMarginAmount The maintenance margin amount set for the loan
    /// @return The amount of destToken bought
    function doTradeofCollateral(
        address collateralTokenAddress,
        address loanTokenAddress,
        uint collateralTokenAmountUsable,
        uint loanTokenAmountNeeded,
        uint initialMarginAmount,
        uint maintenanceMarginAmount)
        external
        returns (uint, uint);

    /// @dev Checks if a position has fallen below margin
    /// @dev maintenance and should be liquidated
    /// @param loanOrderHash A unique hash representing the loan order
    /// @param trader The address of the trader
    /// @param loanTokenAddress The token that was loaned
    /// @param positionTokenAddress The token in the current position (could also be the loanToken)
    /// @param collateralTokenAddress The token used for collateral
    /// @param loanTokenAmount The amount of loan token
    /// @param positionTokenAmount The amount of position token
    /// @param collateralTokenAmount The amount of collateral token
    /// @param maintenanceMarginAmount The maintenance margin amount from the loan
    /// @return Returns True if the trade should be liquidated immediately
    function shouldLiquidate(
        bytes32 loanOrderHash,
        address trader,
        address loanTokenAddress,
        address positionTokenAddress,
        address collateralTokenAddress,
        uint loanTokenAmount,
        uint positionTokenAmount,
        uint collateralTokenAmount,
        uint maintenanceMarginAmount)
        external
        view
        returns (bool);

    /// @dev Gets the trade price of the ERC-20 token pair
    /// @param sourceTokenAddress Token being sold
    /// @param destTokenAddress Token being bought
    /// @return The trade rate
    function getTradeRate(
        address sourceTokenAddress,
        address destTokenAddress)
        external
        view 
        returns (uint);

    /// @dev Returns the profit/loss data for the current position
    /// @param positionTokenAddress The token in the current position (could also be the loanToken)
    /// @param loanTokenAddress The token that was loaned
    /// @param positionTokenAmount The amount of position token
    /// @param loanTokenAmount The amount of loan token
    /// @return isProfit, profitOrLoss (denominated in positionToken)
    function getProfitOrLoss(
        address positionTokenAddress,
        address loanTokenAddress,
        uint positionTokenAmount,
        uint loanTokenAmount)
        external
        view
        returns (bool isProfit, uint profitOrLoss);

    /// @dev Returns the current margin level for this particular loan/position
    /// @param loanTokenAddress The token that was loaned
    /// @param positionTokenAddress The token in the current position (could also be the loanToken)
    /// @param collateralTokenAddress The token used for collateral
    /// @param loanTokenAmount The amount of loan token
    /// @param positionTokenAmount The amount of position token
    /// @param collateralTokenAmount The amount of collateral token
    /// @return The current margin amount (a percentage -> i.e. 54350000000000000000 == 54.35%)
    function getCurrentMarginAmount(
        address loanTokenAddress,
        address positionTokenAddress,
        address collateralTokenAddress,
        uint loanTokenAmount,
        uint positionTokenAmount,
        uint collateralTokenAmount)
        external
        view
        returns (uint);

    /// @dev Checks if the ERC20 token pair is supported by the oracle
    /// @param sourceTokenAddress Token being sold
    /// @param destTokenAddress Token being bought
    /// @param sourceTokenAmount Amount of token being sold
    /// @return True if price discovery and trading is supported
    function isTradeSupported(
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount)
        external
        view 
        returns (bool);
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

contract BZxOracle is OracleInterface, EIP20Wrapper, EMACollector, GasRefunder, BZxOwnable {
    using SafeMath for uint256;

    // this is the value the Kyber portal uses when setting a very high maximum number
    uint internal constant MAX_FOR_KYBER = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    address internal constant KYBER_ETH_TOKEN_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    // Percentage of interest retained as fee
    // This will always be between 0 and 100
    uint public interestFeePercent = 10;

    // Percentage of liquidation level that will trigger a liquidation of positions
    // This can never be less than 100
    uint public liquidationThresholdPercent = 105;

    // Percentage of gas refund paid to non-bounty hunters
    uint public gasRewardPercent = 10;

    // Percentage of gas refund paid to bounty hunters after successfully liquidating a position
    uint public bountyRewardPercent = 110;

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

    mapping (bytes32 => GasData[]) public gasRefunds; // mapping of loanOrderHash to array of GasData

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
        emaValue = 20 * 10**9 wei; // set an initial price average for gas (20 gwei)
        emaPeriods = 10; // set periods to use for EMA calculation
    }

    // The contract needs to be able to receive Ether from Kyber trades
    function() public payable {}

    // standard functions
    function didTakeOrder(
        bytes32 loanOrderHash,
        address taker,
        uint gasUsed)
        public
        onlyBZx
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        gasRefunds[loanOrderHash].push(GasData({
            payer: taker,
            gasUsed: gasUsed.sub(gasleft()),
            isPaid: false
        }));

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
        uint interestFee = amountOwed.mul(interestFeePercent).div(100);

        // Transfers the interest to the lender, less the interest fee.
        // The fee is retained by the oracle.
        if (!_transferToken(
            interestTokenAddress,
            lender,
            amountOwed.sub(interestFee))) {
            revert("BZxOracle::didPayInterest: _transferToken failed");
        }

        if (interestTokenAddress == wethContract) {
            // interest paid in WETH is withdrawn to Ether
            WETH_Interface(wethContract).withdraw(interestFee);
        } else if (convert && interestTokenAddress != bZRxTokenContract) {
            // interest paid in BZRX is retained as is, other tokens are sold for Ether
            _doTradeForEth(
                interestTokenAddress,
                interestFee,
                this // BZxOracle receives the Ether proceeds
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
        bytes32 loanOrderHash,
        address loanCloser,
        bool isLiquidation,
        uint gasUsed)
        public
        onlyBZx
        //refundsGas(taker, emaValue, gasUsed, 0) // refunds based on collected gas price EMA
        updatesEMA(tx.gasprice)
        returns (bool)
    {
        // sends gas refunds owed from earlier transactions
        for (uint i=0; i < gasRefunds[loanOrderHash].length; i++) {
            GasData storage gasData = gasRefunds[loanOrderHash][i];
            if (!gasData.isPaid) {
                if (sendRefund(
                    gasData.payer,
                    gasData.gasUsed,
                    emaValue,
                    gasRewardPercent))               
                        gasData.isPaid = true;
            }
        }

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
            revert("Manual trading is disabled.");
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

    function doTradeofCollateral(
        address collateralTokenAddress,
        address loanTokenAddress,
        uint collateralTokenAmountUsable,
        uint loanTokenAmountNeeded,
        uint initialMarginAmount,
        uint maintenanceMarginAmount)
        public
        onlyBZx
        returns (uint loanTokenAmountCovered, uint collateralTokenAmountUsed)
    {
        uint collateralTokenBalance = EIP20(collateralTokenAddress).balanceOf.gas(4999)(this); // Changes to state require at least 5000 gas
        if (collateralTokenBalance < collateralTokenAmountUsable) { // sanity check
            revert("BZxOracle::doTradeofCollateral: collateralTokenBalance < collateralTokenAmountUsable");
        }

        loanTokenAmountCovered = _doTrade(
            collateralTokenAddress,
            loanTokenAddress,
            collateralTokenAmountUsable,
            loanTokenAmountNeeded);

        collateralTokenAmountUsed = collateralTokenBalance.sub(EIP20(collateralTokenAddress).balanceOf.gas(4999)(this)); // Changes to state require at least 5000 gas
        
        if (collateralTokenAmountUsed < collateralTokenAmountUsable) {
            // send unused collateral token back to the vault
            if (!_transferToken(
                collateralTokenAddress,
                vaultContract,
                collateralTokenAmountUsable.sub(collateralTokenAmountUsed))) {
                revert("BZxOracle::doTradeofCollateral: _transferToken failed");
            }
        }

        if (loanTokenAmountCovered < loanTokenAmountNeeded) {
            // cover losses with insurance if applicable
            if ((minInitialMarginAmount == 0 || initialMarginAmount >= minInitialMarginAmount) &&
                (minMaintenanceMarginAmount == 0 || maintenanceMarginAmount >= minMaintenanceMarginAmount)) {
                
                loanTokenAmountCovered = loanTokenAmountCovered.add(
                    _doTradeWithEth(
                        loanTokenAddress,
                        loanTokenAmountNeeded.sub(loanTokenAmountCovered),
                        vaultContract
                ));
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
                collateralTokenAmount).div(maintenanceMarginAmount).div(10**16) <= (liquidationThresholdPercent)
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

    function setInterestFeePercent(
        uint newRate) 
        public
        onlyOwner
    {
        require(newRate != interestFeePercent && newRate >= 0 && newRate <= 100);
        interestFeePercent = newRate;
    }

    function setLiquidationThresholdPercent(
        uint newValue) 
        public
        onlyOwner
    {
        require(newValue != liquidationThresholdPercent && liquidationThresholdPercent >= 100);
        liquidationThresholdPercent = newValue;
    }

    function setGasRewardPercent(
        uint newValue) 
        public
        onlyOwner
    {
        require(newValue != gasRewardPercent);
        gasRewardPercent = newValue;
    }

    function setBountyRewardPercent(
        uint newValue) 
        public
        onlyOwner
    {
        require(newValue != bountyRewardPercent);
        bountyRewardPercent = newValue;
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
        uint amount = value;
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }

        return (to.send(amount));
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
                    revert("BZxOracle::_doTrade: _transferToken failed");
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
        address receiver)
        internal
        returns (uint)
    {
        // re-up the Kyber spend approval if needed
        if (EIP20(sourceTokenAddress).allowance.gas(4999)(this, kyberContract) < 
            MAX_FOR_KYBER) {

            eip20Approve(
                sourceTokenAddress,
                kyberContract,
                MAX_FOR_KYBER);
        }
        
        // bytes4(keccak256("trade(address,uint256,address,address,uint256,uint256,address)")) = 0xcb3c28c7
        bool result = kyberContract.call
            .gas(gasleft())(
            0xcb3c28c7,
            sourceTokenAddress,
            sourceTokenAmount,
            KYBER_ETH_TOKEN_ADDRESS,
            receiver,
            MAX_FOR_KYBER, // no limit on the dest amount
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

    function _doTradeWithEth(
        address destTokenAddress,
        uint destTokenAmountNeeded,
        address receiver)
        internal
        returns (uint)
    {
        uint etherToDest;
        (etherToDest,) = KyberNetwork_Interface(kyberContract).getExpectedRate(
            KYBER_ETH_TOKEN_ADDRESS,
            destTokenAddress, 
            0
        );

        // calculate amount of ETH to use with a 5% buffer (unused ETH is returned by Kyber)
        uint ethToSend = destTokenAmountNeeded.mul(10**18).div(etherToDest).mul(105).div(100);
        if (ethToSend > address(this).balance) {
            ethToSend = address(this).balance;
        }

        // bytes4(keccak256("trade(address,uint256,address,address,uint256,uint256,address)")) = 0xcb3c28c7
        bool result = kyberContract.call
            .gas(gasleft())
            .value(ethToSend)( // send Ether along 
            0xcb3c28c7,
            KYBER_ETH_TOKEN_ADDRESS,
            ethToSend,
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