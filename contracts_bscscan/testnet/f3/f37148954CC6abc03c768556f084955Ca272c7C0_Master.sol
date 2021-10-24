/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IShibin {
    function totalSupply() external view returns (uint256);
    function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256);
}


interface IOracle {
    function getData() external view returns (uint256);
    function update() external;
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


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract Master is Ownable {
    using UInt256Lib for uint256;
    
    event LogRebase(
        uint256 indexed epoch,
        uint256 exchangeRate,
        int256 requestedSupplyAdjustment,
        uint256 timestampSec
    );

    IShibin public Shibin;
    
    mapping(address => bool) private _authorized;

    // Market oracle provides the NTSL/USD exchange rate as an 18 decimal fixed point number.
    IOracle public marketOracle;

    // If the current exchange rate is within this fractional distance from the target, no supply
    // update is performed. Fixed point number--same format as the rate.
    // (ie) abs(rate - targetRate) / targetRate < deviationThreshold, then no supply change.
    // DECIMALS Fixed point number.
    uint256 public deviationThreshold;

    // Price finalTarget
    uint256 public finalTarget;

    // More than this much time must pass between rebase operations.
    uint256 public rebaseCooldown;

    // Block timestamp of last rebase operation
    uint256 public lastRebaseTimestampSec;

    // The number of rebase cycles since inception
    uint256 public epoch;

    uint256 private constant DECIMALS = 18;

    // Due to the expression in computeSupplyDelta(), MAX_RATE * MAX_SUPPLY must fit into an int256.
    // Both are 18 decimals fixed point numbers.
    uint256 private constant MAX_RATE = 2000000 * 10**DECIMALS;
    // MAX_SUPPLY = MAX_INT256 / MAX_RATE
    uint256 private constant MAX_SUPPLY = ~(uint256(1) << 255) / MAX_RATE;

    // Rebase will remain restricted to the owner until the final Oracle is deployed and battle-tested.
    // Ownership will be renounced after this inital period.

    uint256 public targetRate;

    bool public rebaseLocked;
    bool public rebaseOverride = false;

    bool private allowSetInitalRate = true;

    bool public posRebaseEnabled;
    
    modifier onlyAuth(){
        require(_authorized[msg.sender]);
        _;
    }


    constructor(address _Shibin)  {
        
        _authorized[msg.sender] = true;
        
        deviationThreshold = 100 * 10 ** (DECIMALS-2);

        targetRate = 1004837000;
        
        // Final Target = 384,403$
        finalTarget = 384403 * 10 ** DECIMALS;

        rebaseCooldown = 1 hours;
        epoch = 0;
        rebaseLocked = true;

        Shibin = IShibin(_Shibin);
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Override to ensure that rebases aren't locked when this happens.
     */

    function renounceOwnership() public override onlyOwner {
        require(!rebaseLocked);
        super.renounceOwnership();
    }

    function setRebaseLocked(bool _locked) external onlyOwner {
        rebaseLocked = _locked;
    }

    /**
     * @notice Returns true if the cooldown timer has expired since the last rebase.
     *
     */

    function canRebase() public view returns (bool) {
        if(rebaseOverride) return true;
        else return ((!rebaseLocked || msg.sender == owner()) && lastRebaseTimestampSec + (rebaseCooldown) < block.timestamp);

    }
    
    function setShibinAddress(address newShibinAddress) external onlyOwner{
        Shibin = IShibin(newShibinAddress);
    }
    
    function setFinalTarget(uint256 newTarget) external onlyOwner{
        finalTarget = newTarget * 10 ** DECIMALS;
    }

    function cooldownExpiryTimestamp() public view returns (uint256) {
        return lastRebaseTimestampSec + (rebaseCooldown);
    }
    
    function setInitialTargetRate(uint256 _initRate) external onlyOwner{
        targetRate = _initRate;    
    }

    /**
     * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
     *
     */

    function rebase() public {

        require(tx.origin == msg.sender);
        require(canRebase(), "Rebase not allowed");

        lastRebaseTimestampSec = block.timestamp;

        epoch = epoch + (1);

        (uint256 exchangeRate, int256 supplyDelta) = getRebaseValues();

        if (supplyDelta > 0 && !posRebaseEnabled) {
            supplyDelta = 0;
        }

        uint256 supplyAfterRebase = Shibin.rebase(epoch, supplyDelta);

        assert(supplyAfterRebase <= MAX_SUPPLY);


        marketOracle.update();

        if (exchangeRate < finalTarget) {
            incrementTargetRate();
        } else {
            targetRate = finalTarget;
            posRebaseEnabled = true;
        }

        emit LogRebase(epoch, exchangeRate, supplyDelta, block.timestamp);
    }
    
    function overrideRebase() external onlyAuth {
        rebaseOverride = true;
        rebase();
        rebaseOverride = false;
    }
    
    // if exchange rate is above target rate, then move up the target rate
    function adjustTargetRate() external
    {
      uint256 exchangeRate = marketOracle.getData();

      if (exchangeRate > targetRate){
        targetRate = exchangeRate * 963 / 800;
      }

    }

    // increment by 1.20375 to achieve 9.63% every 8hrs
    function incrementTargetRate() internal {

      uint256 newRate = targetRate * 963 / 800;

      if (newRate < finalTarget)
      {
        targetRate = newRate;
      } else {
        targetRate = finalTarget;
      }
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


        if (supplyDelta > 0 && Shibin.totalSupply() + (uint256(supplyDelta)) > MAX_SUPPLY) {
            supplyDelta = (MAX_SUPPLY - (Shibin.totalSupply())).toInt256Safe();
        }

        return (exchangeRate, supplyDelta);
    }


    /**
     * @return Computes the total supply adjustment in response to the exchange rate
     *         and the targetRate.
     */
    function computeSupplyDelta(uint256 rate) internal view returns (int256){
        int256 targetRateSigned = targetRate.toInt256Safe();
        return Shibin.totalSupply().toInt256Safe() * (rate.toInt256Safe() - (targetRateSigned)) / (targetRateSigned);
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
        uint256 absoluteDeviationThreshold = targetRate * (deviationThreshold)
             / (10 ** DECIMALS);

        return (rate >= targetRate && rate - (targetRate) < absoluteDeviationThreshold)
            || (rate < targetRate && targetRate - (rate) < absoluteDeviationThreshold);
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
    
    function setAuthorized(address account, bool value) external onlyOwner{
        _authorized[account] = value;
    }

}