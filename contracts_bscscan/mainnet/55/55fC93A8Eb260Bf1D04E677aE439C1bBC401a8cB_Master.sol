/**
 *Submitted for verification at BscScan.com on 2021-11-15
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-24
*/

// SPDX-License-Identifier: MIT

/*
MIT License
Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.
Copyright (c) 2020 Ditto Money
Copyright (c) 2021 Goes Up Higher

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity >=0.5.17 <0.8.0;

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}
library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}
contract Ownable {
  address private _owner;

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
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
interface IOracle {
    function getData() external view returns (uint256);
    function update() external;
}
interface IGuh {
    function totalSupply() external view returns (uint256);
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
}


/**
 * @title Guh's Master
 * @dev Controller for an elastic supply currency based on the uFragments Ideal Money protocol a.k.a. Ampleforth.
 *      uFragments operates symmetrically on expansion and contraction. It will both split and
 *      combine coins to maintain a stable unit price.
 *
 *      This component regulates the token supply of the uFragments ERC20 token in response to
 *      market oracles.
 */
contract Master is Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using UInt256Lib for uint256;

    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }

    event TransactionFailed(address indexed destination, uint index, bytes data);

    // Stable ordering is not guaranteed.
    Transaction[] public transactions;

    event LogRebase(
        uint256 indexed epoch,
        uint256 exchangeRate,
        int256 requestedSupplyAdjustment,
        uint256 timestampSec
    );

    IGuh public guh;

    // Market oracle provides the GUH/USD exchange rate as an 18 decimal fixed point number.
    IOracle public marketOracle;
    
    // Market oracle provides the BTC/USD exchange rate as an 18 decimal fixed point number.
    IOracle public marketOracleBTC;


    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    // DECIMALS Fixed point number.
    uint256 public deviationThreshold;

    // More than this much time must pass between rebase operations.
    uint256 public rebaseCooldown;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 9;

    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 1000000000 * 10**6 * 10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = ~(uint256(1) << 255) / MAX_RATE;

    // Rebase will remain restricted to the owner until the final Oracle is deployed and battle-tested.
    // Ownership will be renounced after this inital period.
    
    // Start at $.001
    uint256 public targetRate;
    
    bool public rebaseLocked; 

    constructor(address _guh) public {
        deviationThreshold = 5 * 10 ** (DECIMALS-2);
        // Start at .04 cents 5-24-2021
        targetRate =  224502886 * 10 ** DECIMALS;

        rebaseCooldown = 1 minutes;
        lastRebaseTimestampSec = 1621900800;
        // Start at epoch 80 5-24-2021
        epoch = 80;
        rebaseLocked = true;
        
        guh = IGuh(_guh);
    }
    
    function setTargetRate(uint256 _targetRate) external onlyOwner {
        targetRate = _targetRate;
    }
    
    function setDeviationThreshold(uint256 _dt) external onlyOwner {
        deviationThreshold = _dt;
    }
    
    function setGuh(address _guh) external onlyOwner{
        guh = IGuh(_guh);
    }
    
    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Override to ensure that rebases aren't locked when this happens.
     */
     
    function setReabaseCooldown(uint256 _rebaseCooldown) external onlyOwner {
        rebaseCooldown = _rebaseCooldown;    
    }
        
    function setRebaseLocked(bool _locked) external onlyOwner {
        rebaseLocked = _locked;
    }

    /**
     * @notice Returns true if the cooldown timer has expired since the last rebase.
     *
     */
     
    function canRebase() public view returns (bool) {
        return ((!rebaseLocked || isOwner()) && lastRebaseTimestampSec.add(rebaseCooldown) < now);
    }
    
    function cooldownExpiryTimestamp() public view returns (uint256) {
        return lastRebaseTimestampSec.add(rebaseCooldown);
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     */
     
    function rebase() external {

        require(tx.origin == msg.sender);
        require(canRebase(), "Rebase not allowed");

        lastRebaseTimestampSec = now;

        epoch = epoch.add(1);

        (uint256 exchangeRate, int256 supplyDelta) = getRebaseValues();
        
        /**
        //Ignore positive rebases 5-24-2021
        if (supplyDelta > 0) {
            supplyDelta = 0;
        }
        */
        
        
        uint256 supplyAfterRebase = guh.rebase(epoch, supplyDelta);
        
        assert(supplyAfterRebase <= MAX_SUPPLY);
        
        for (uint i = 0; i < transactions.length; i++) {
            Transaction storage t = transactions[i];
            if (t.enabled) {
                bool result =
                    externalCall(t.destination, t.data);
                if (!result) {
                    emit TransactionFailed(t.destination, i, t.data);
                    revert("Transaction Failed");
                }
            }
        }
        
        marketOracle.update();

        if (epoch < 360) {
            incrementTargetRate();
        } else {
            setTargetRateBTC();
        }
        
        emit LogRebase(epoch, exchangeRate, supplyDelta, now);
    }
    
    // increment by 5%
    function incrementTargetRate() internal {
        targetRate = targetRate.mul(21).div(20);
    }
    
    // set rate to BTC rate + 1% ATH 5-24-2021
    function setTargetRateBTC() internal {
        uint256 btcRate = marketOracleBTC.getData();
        targetRate = btcRate.mul(101).div(100);
    }
    
    /**
     * @notice Calculates the supplyDelta and returns the current set of values for the rebase
     *
     * @dev The supply adjustment equals (_totalSupply * DeviationFromTargetRate) / rebaseLag
     *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
     * 
     */    
    
    function getRebaseValues() public view returns (uint256, int256) {

        uint256 exchangeRate = marketOracle.getData();

        if (exchangeRate > MAX_RATE) {
            exchangeRate = MAX_RATE;
        }

        int256 supplyDelta = computeSupplyDelta(exchangeRate);

        // Apply the dampening factor.
        if (supplyDelta < 0) {
            supplyDelta = supplyDelta.div(2);
        } else {
            supplyDelta = supplyDelta.div(5);                   
        }

        if (supplyDelta > 0 && guh.totalSupply().add(uint256(supplyDelta)) > MAX_SUPPLY) {
            supplyDelta = (MAX_SUPPLY.sub(guh.totalSupply())).toInt256Safe();
        }

        return (exchangeRate, supplyDelta);
    }


    /**
     * @return Computes the total supply adjustment in response to the exchange rate
     *         and the targetRate.
     */
    function computeSupplyDelta(uint256 rate)
        internal
        view
        returns (int256)
    {
        if (withinDeviationThreshold(rate)) {
            return 0;
        }

        int256 targetRateSigned = targetRate.toInt256Safe();
        return guh.totalSupply().toInt256Safe()
            .mul(rate.toInt256Safe().sub(targetRateSigned))
            .div(targetRateSigned);
    }

    /**
     * @param rate The current exchange rate, an 18 decimal fixed point number.
     * @return If the rate is within the deviation threshold from the target rate, returns true.
     *         Otherwise, returns false.
     */
    function withinDeviationThreshold(uint256 rate)
        internal
        view
        returns (bool)
    {
        uint256 absoluteDeviationThreshold = targetRate.mul(deviationThreshold)
            .div(10 ** DECIMALS);

        return (rate >= targetRate && rate.sub(targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate.sub(rate) < absoluteDeviationThreshold);
    }
    
    function setEpoch(uint256 _epoch) external onlyOwner{
        epoch = _epoch;
    }
    
    /**
     * @notice Sets the reference to the market oracle.
     * @param marketOracle_ The address of the market oracle contract.
     */
    function setMarketOracle(IOracle marketOracle_)
        external
        onlyOwner
    {
        marketOracle = marketOracle_;
    }
    
    /**
     * @notice Sets the reference to the market oracle.
     * @param marketOracleBTC_ The address of the market oracle contract.
     */
    function setMarketOracleBTC(IOracle marketOracleBTC_)
        external
        onlyOwner
    {
        marketOracleBTC = marketOracleBTC_;
    }

    
    /**
     * @notice Adds a transaction that gets called for a downstream receiver of rebases
     * @param destination Address of contract destination
     * @param data Transaction data payload
     */
    function addTransaction(address destination, bytes calldata data)
        external
        onlyOwner
    {
        transactions.push(Transaction({
            enabled: true,
            destination: destination,
            data: data
        }));
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint index)
        external
        onlyOwner
    {
        require(index < transactions.length, "index out of bounds");

        if (index < transactions.length - 1) {
            transactions[index] = transactions[transactions.length - 1];
        }
        
        transactions.length;
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint index, bool enabled)
        external
        onlyOwner
    {
        require(index < transactions.length, "index must be in range of stored tx list");
        transactions[index].enabled = enabled;
    }

    /**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */
    function transactionsSize()
        external
        view
        returns (uint256)
    {
        return transactions.length;
    }

    /**
     * @dev wrapper to call the encoded transactions on downstream consumers.
     * @param destination Address of destination contract.
     * @param data The encoded data payload.
     * @return True on success
     */
    function externalCall(address destination, bytes memory data)
        internal
        returns (bool)
    {
        bool result;
        assembly {  // solhint-disable-line no-inline-assembly
            // "Allocate" memory for output
            // (0x40 is where "free memory" pointer is stored by convention)
            let outputAddress := mload(0x40)

            // First 32 bytes are the padded length of data, so exclude that
            let dataAddress := add(data, 32)

            result := call(
                sub(gas(), 34710),
                destination,
                0, // transfer value in wei
                dataAddress,
                mload(data),  // Size of the input, in bytes. Stored in position 0 of the array.
                outputAddress,
                0  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }    
    
}