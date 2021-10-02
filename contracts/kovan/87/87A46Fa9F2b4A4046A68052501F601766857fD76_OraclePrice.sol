/**
 *Submitted for verification at Etherscan.io on 2021-10-02
*/

// File: contracts/v6/interface/KeeperCompatibleInterface.sol

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.6.12;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// File: contracts/v6/interface/IOmsPolicy.sol

pragma solidity =0.6.12;

interface IOmsPolicy {
    function setTargetPrice(uint256 _targetPrice) external;
    function targetPrice() external view returns (uint256);
}

// File: contracts/v6/interface/EACAggregatorProxy.sol

pragma solidity =0.6.12;

interface EACAggregatorProxy {
    function latestAnswer() external view returns (int256); 
    function decimals() external view returns (uint8);
}

// File: contracts/v6/library/SafeMath.sol

pragma solidity =0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
 
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/v6/common/Context.sol

pragma solidity =0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/v6/common/Ownable.sol

pragma solidity =0.6.12;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/v6/OraclePrice.sol

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;






contract OraclePrice is Ownable, KeeperCompatibleInterface {
    using SafeMath for uint256;

    struct PriceLog {
        int256 lastUpdatedPrice;
    }

    struct AverageLog {
        int256 averageMovement;
        int256 referenceRate;
    }

    struct OracleInfo {
        address oracleAddress;
        bool isActive;
        bytes32 symbolHash;
        int256 lastPrice; 
    }
    
    event LogTargetPriceUpdated(uint256 indexed performUpkeepCycle, uint256 timestampSec, int256 averageMovement, uint256 oldReferenceRate, uint256 newReferenceRate);
    event LogReferenceRateDataUsed(uint256 indexed performUpkeepCycle, uint256 timestampSec, address oracleAddress, int256 oldPrice, int256 newPrice);

    // Storing all the details of oracle address
    OracleInfo[] public oracleInfo;

    // OmsPolicy contract address
    address public policyContract;

    // More than this much time must pass between keepers operations.
    uint public immutable interval;

    // Block timestamp of last Keepers operations.
    uint public lastTimeStamp;

    // The number of keepers cycles since inception
    uint public counter;

    // PriceLog represents last price of each currency
    mapping (address => PriceLog) public priceLog;

    // AverageLog represents last average and ref rate of currency
    AverageLog public averageLog;
    
    constructor(OracleInfo[] memory _oracles, address _policyContract, uint _updateInterval) public {
        policyContract = _policyContract;
        
        for(uint256 i=0; i<_oracles.length; i++) {
            OracleInfo memory oracle = _oracles[i];
            oracleInfo.push(OracleInfo({
                oracleAddress: oracle.oracleAddress,
                isActive: oracle.isActive,
                symbolHash: oracle.symbolHash,
                lastPrice: 0
            }));
        }
        // oracleInfo = _oracles;

        interval = _updateInterval;
        lastTimeStamp = 0;
        counter = 0;
    }

    function getOracleInfoCount() public view returns (uint256) {
        return oracleInfo.length;
    }
    
    /**
     * @param _oracleId index number of oracle address.
     * Fetching updated price of perticular oracles from chainlink. 
     */
    function getOraclePriceInUsd(uint256 _oracleId) public view returns (int256) {
        OracleInfo storage oracle = oracleInfo[_oracleId];
        int256 latestPrice = EACAggregatorProxy(oracle.oracleAddress).latestAnswer();
        return latestPrice;
    }

    function checkUpkeep(bytes calldata checkData) external override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata performData) external override {
        bool upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        require(upkeepNeeded == true, "Can Not call this method at this time");

        lastTimeStamp = block.timestamp;
        counter = counter + 1;

        updateTargetPrice();
    }

    // calculate average movement and ReferenceRate from all currency price 
    function calculateReferenceRate() internal returns(uint256) {
        uint256 oracleInfoCount = oracleInfo.length;
        
        int256 sumPrice = 0;
        int256 decimals = 1e18;
        uint256 activeOracle = 0;
        for(uint256 i=0; i<oracleInfoCount; i++) {
            OracleInfo storage oracle = oracleInfo[i];
            if(oracle.isActive == true) {
                PriceLog storage pricelog = priceLog[oracle.oracleAddress];
                // PriceLog storage pricelogs = priceLog[oracle.oracleAddress];
                sumPrice = addUnderFlow(sumPrice, divUnderFlow(mulUnderFlow(subUnderFlow(oracle.lastPrice, pricelog.lastUpdatedPrice), 100000), oracle.lastPrice));
                if(pricelog.lastUpdatedPrice == 0) {
                    sumPrice = 0;
                }

                emit LogReferenceRateDataUsed(counter, lastTimeStamp, oracle.oracleAddress, pricelog.lastUpdatedPrice, oracle.lastPrice);
                
                pricelog.lastUpdatedPrice = oracle.lastPrice;
                activeOracle = activeOracle.add(1);
            }
        }

        int256 avgMovement = divUnderFlow(sumPrice, int256(activeOracle));
        if(averageLog.referenceRate == 0) {
            averageLog.referenceRate = decimals;
        }
        int256 refRate = divUnderFlow(mulUnderFlow(averageLog.referenceRate, addUnderFlow(decimals, divUnderFlow(mulUnderFlow(decimals, avgMovement), 10000000))), decimals);

        averageLog.averageMovement = avgMovement;
        averageLog.referenceRate = refRate;

        return uint256(refRate);
    }
    
    /**
     * Fetching updated price from all oracles and calculating ref rate to update 
     * Target price.
     */
    function updateTargetPrice() internal {
        uint256 length = oracleInfo.length;
        for(uint256 i=0; i<length; i++) {
            OracleInfo storage oracle = oracleInfo[i];
            if(oracle.isActive == true) {
                int256 latestPrice = EACAggregatorProxy(oracle.oracleAddress).latestAnswer();
                uint8 decimals = EACAggregatorProxy(oracle.oracleAddress).decimals();
                uint256 restDec = SafeMath.sub(18, uint256(decimals));
                latestPrice = int256(SafeMath.mul(uint256(latestPrice), 10**restDec));
                oracle.lastPrice = latestPrice;
            }
        }
    
        uint256 oldTargetPrice = IOmsPolicy(policyContract).targetPrice();
        uint256 newTargetPrice = calculateReferenceRate();

        IOmsPolicy(policyContract).setTargetPrice(newTargetPrice);
        
        emit LogTargetPriceUpdated(counter, lastTimeStamp, averageLog.averageMovement, oldTargetPrice, newTargetPrice);
    }
    
    /**
     * @param _pid index number of oracle address.
     * @param _oracle updated oracle address.
     * @param _isActive true if oracle is active otherwise inactive.
     * @param _symbolHash symbolHash of crypto currency.
     */
    function updateOracle(uint256 _pid, address _oracle, bool _isActive, bytes32 _symbolHash) public onlyOwner {
        OracleInfo storage oracle = oracleInfo[_pid];
        require(oracle.oracleAddress != address(0), "No Oracle Found");
        oracle.oracleAddress = _oracle;
        oracle.isActive = _isActive;
        oracle.symbolHash = _symbolHash;
    }

    /**
     * @param _oracle new oracle address to add in structure.
     * @param _isActive true if oracle is active otherwise inactive.
     * @param _symbolHash symbolHash of crypto currency.
     */
    function addOracle(address _oracle, bool _isActive, bytes32 _symbolHash) public onlyOwner {
        oracleInfo.push(OracleInfo({
                oracleAddress: _oracle,
                isActive: _isActive,
                symbolHash: _symbolHash,
                lastPrice: 0
            }));
    }
    
    /**
     * @param _policy new policy address.
     */
    function updatePolicy(address _policy) public onlyOwner {
        policyContract = _policy;
    }

    /**
    * @dev Subtracts two int256 variables.
    */
    function subUnderFlow(int256 a, int256 b)
            internal
            pure
            returns (int256)
    {
        int256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function addUnderFlow(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        return c;
    }

    /**
    * @dev Division of two int256 variables and fails on overflow.
     */
    function divUnderFlow(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        require(b != 0, "div overflow");

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mulUnderFlow(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;
        return c;
    }
}