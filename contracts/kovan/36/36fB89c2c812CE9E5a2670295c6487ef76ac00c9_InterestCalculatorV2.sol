//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

import "./InterestInterface.sol";
import "./multipliers/IMultiplierCalculator.sol";
import "../utils/SafeMath.sol";
import "../utils/Admin.sol";

/** @title Interest Module V2 for Paladin PalPools  */
/// @author Paladin
contract InterestCalculatorV2 is InterestInterface, Admin {
    using SafeMath for uint;


    bool private initiated = false;

    mapping(address => bool) public useMultiplier;

    uint public blocksPerYear = 2336000;

    uint public multiplierPerBlock;
    uint public baseRatePerBlock;
    uint public jumpMultiplierPerBlock;

    mapping(address => IMultiplierCalculator) public multiplierForPool;
    

    constructor(){
        admin = msg.sender;
    }


    function initiate(
        uint multiplierPerYear,
        uint baseRatePerYear,
        uint jumpMultiplierPerYear,
        address[] memory palPools,
        address[] memory multiplierCalculators
    ) external adminOnly {
        require(!initiated, "Already initiated");
        require(palPools.length == multiplierCalculators.length);

        multiplierPerBlock = multiplierPerYear.div(blocksPerYear);
        baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
        jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);

        for(uint i = 0; i < palPools.length; i++){
            multiplierForPool[palPools[i]] = IMultiplierCalculator(multiplierCalculators[i]);
        }

        initiated = true;
    }


    /**
    * @notice Calculates the Utilization Rate of a PalPool
    * @dev Calculates the Utilization Rate of a PalPool depending of Cash, Borrows & Reserves
    * @param cash Cash amount of the calling PalPool
    * @param borrows Total Borrowed amount of the calling PalPool
    * @param reserves Total Reserves amount of the calling PalPool
    * @return uint : Utilisation Rate of the Pool (scale 1e18)
    */
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns(uint){
        //If no funds are borrowed, the Pool is not used
        if(borrows == 0){
            return 0;
        }
        // Utilization Rate = Borrows / (Cash + Borrows - Reserves)
        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    /**
    * @notice Calculates the Supply Rate for the calling PalPool
    * @dev Calculates the Supply Rate depending on the Pool Borrow Rate & Reserve Factor
    * @param palPool Address of the PalPool calling the function
    * @param cash Cash amount of the calling PalPool
    * @param borrows Total Borrowed amount of the calling PalPool
    * @param reserves Total Reserves amount of the calling PalPool
    * @param reserveFactor Reserve Factor of the calling PalPool
    * @return uint : Supply Rate for the Pool (scale 1e18)
    */
    function getSupplyRate(address palPool, uint cash, uint borrows, uint reserves, uint reserveFactor) external view override returns(uint){
        //Fetch the Pool Utilisation Rate & Borrow Rate
        uint _utilRate = utilizationRate(cash, borrows, reserves);
        uint _bRate = _borrowRate(palPool, cash, borrows, reserves);

        //Supply Rate = Utilization Rate * (Borrow Rate * (1 - Reserve Factor))
        uint _tempRate = _bRate.mul(uint(1e18).sub(reserveFactor)).div(1e18);
        return _utilRate.mul(_tempRate).div(1e18);
    }
    
    /**
    * @notice Get the Borrow Rate for a PalPool depending on the given parameters
    * @dev Calls the internal fucntion _borrowRate
    * @param palPool Address of the PalPool calling the function
    * @param cash Cash amount of the calling PalPool
    * @param borrows Total Borrowed amount of the calling PalPool
    * @param reserves Total Reserves amount of the calling PalPool
    * @return uint : Borrow Rate for the Pool (scale 1e18)
    */
    function getBorrowRate(address palPool, uint cash, uint borrows, uint reserves) external view override returns(uint){
        //Internal call
        return _borrowRate(palPool, cash, borrows, reserves);
    }

    /**
    * @dev Calculates the Borrow Rate for the PalPool, depending on the utilisation rate & the kink value.
    * @param palPool Address of the PalPool calling the function
    * @param cash Cash amount of the calling PalPool
    * @param borrows Total Borrowed amount of the calling PalPool
    * @param reserves Total Reserves amount of the calling PalPool
    * @return uint : Borrow Rate for the Pool (scale 1e18)
    */
    function _borrowRate(address palPool, uint cash, uint borrows, uint reserves) internal view returns(uint){
        //Fetch the utilisation rate
        uint _utilRate = utilizationRate(cash, borrows, reserves);

        if(useMultiplier[palPool]){
            // multiplier model calculation
            uint _govMultiplier = multiplierForPool[palPool].getCurrentMultiplier();

            return (_utilRate.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock)).mul(_govMultiplier).div(1e18);
        
        
        } else if(_utilRate > 0.8e18){
            // jumpRate model calculation 
            uint _tempRate = uint256(0.8e18).mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);

            return (_utilRate.sub(0.8e18).mul(jumpMultiplierPerBlock).div(1e18)).add(_tempRate);
        }

        //Base rate calculation
        return _utilRate.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
    }


    //Admin functions


    function activateMultiplier(address palPool) external adminOnly {
        require(!useMultiplier[palPool], "Already activated");
        useMultiplier[palPool] = true;
    }

    function stopMultiplier(address palPool) external adminOnly {
        require(useMultiplier[palPool], "Not activated");
        useMultiplier[palPool] = false;
    }


    function updateBaseValues(uint newMultiplierPerYear, uint newBaseRatePerYear, uint jumpMultiplierPerYear) external adminOnly {
        multiplierPerBlock = newMultiplierPerYear.div(blocksPerYear);
        baseRatePerBlock = newBaseRatePerYear.div(blocksPerYear);
        jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);
    }


    function updateBlocksPerYear(uint newBlockPerYear) external adminOnly {
        blocksPerYear = newBlockPerYear;
    }

    function updatePoolMultiplierCalculator(address palPool, address newMultiplierCalculator) external adminOnly {
        //either update already existing item, or add a new one
        multiplierForPool[palPool] = IMultiplierCalculator(newMultiplierCalculator);
    }
}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title Interest Module Interface  */
/// @author Paladin
interface InterestInterface {

    function getSupplyRate(address palPool, uint cash, uint borrows, uint reserves, uint reserveFactor) external view returns(uint);
    function getBorrowRate(address palPool, uint cash, uint borrows, uint reserves) external view returns(uint);
}

//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝
                                                     

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

/** @title MultiplierCalculator Interface  */
/// @author Paladin
interface IMultiplierCalculator {

    function getCurrentMultiplier() external view returns(uint);
}

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.6;
//SPDX-License-Identifier: MIT


/** @title Admin contract  */
/// @author Paladin
contract Admin {

    /** @notice (Admin) Event when the contract admin is updated */
    event NewAdmin(address oldAdmin, address newAdmin);

    /** @dev Admin address for this contract */
    address payable internal admin;
    
    modifier adminOnly() {
        //allows only the admin of this contract to call the function
        require(msg.sender == admin, '1');
        _;
    }

        /**
    * @notice Set a new Admin
    * @dev Changes the address for the admin parameter
    * @param _newAdmin address of the new Controller Admin
    */
    function setNewAdmin(address payable _newAdmin) external adminOnly {
        address _oldAdmin = admin;
        admin = _newAdmin;

        emit NewAdmin(_oldAdmin, _newAdmin);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 25000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}