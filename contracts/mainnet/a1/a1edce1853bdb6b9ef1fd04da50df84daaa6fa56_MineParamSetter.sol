/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

// pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


// Dependency file: contracts/interfaces/IMineParam.sol

// pragma solidity >=0.5.0;

interface IMineParam {
    function minePrice() external view returns (uint256);
    function getMinePrice() external view returns (uint256);
    function mineIncomePerTPerSecInWei() external view returns(uint256);
    function incomePerTPerSecInWei() external view returns(uint256);
    function setIncomePerTPerSecInWeiAndUpdateMinePrice(uint256 _incomePerTPerSecInWei) external;
    function updateMinePrice() external;
    function paramSetter() external view returns(address);
    function addListener(address _listener) external;
    function removeListener(address _listener) external returns(bool);
}

// Dependency file: contracts/modules/Ownable.sol

// pragma solidity >=0.5.0;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


// Dependency file: contracts/modules/Paramable.sol

// pragma solidity >=0.5.0;

// import 'contracts/modules/Ownable.sol';

contract Paramable is Ownable {
    address public paramSetter;

    event ParamSetterChanged(address indexed previousSetter, address indexed newSetter);

    constructor() public {
        paramSetter = msg.sender;
    }

    modifier onlyParamSetter() {
        require(msg.sender == owner || msg.sender == paramSetter, "!paramSetter");
        _;
    }

    function setParamSetter(address _paramSetter) external onlyOwner {
        require(_paramSetter != address(0), "param setter is the zero address");
        emit ParamSetterChanged(paramSetter, _paramSetter);
        paramSetter = _paramSetter;
    }

}


// Root file: contracts/MineParamSetter.sol

pragma solidity >=0.5.0;

// import "@openzeppelin/contracts/math/SafeMath.sol";
// import 'contracts/interfaces/IMineParam.sol';
// import 'contracts/modules/Paramable.sol';

interface IPOWToken {
    function mineParam() external returns (address);
}

contract MineParamSetter is Paramable {
    using SafeMath for uint256;

    uint256 public minIncomeRate;
    uint256 public maxIncomeRate;
    uint256 public minPriceRate;
    uint256 public maxPriceRate;

    function setRate(uint256 _minIncomeRate, uint256 _maxIncomeRate, uint256 _minPriceRate, uint256 _maxPriceRate) public onlyParamSetter {
        minIncomeRate = _minIncomeRate;
        maxIncomeRate = _maxIncomeRate;
        minPriceRate = _minPriceRate;
        maxPriceRate = _maxPriceRate;
    }

    // return >9 is pass
    function checkWithCode (address[] memory params, uint256[] memory values) public view returns (uint256) {
        if(params.length != values.length) {
            return 1;
        }
        for(uint256 i; i<params.length; i++) {
            if(IMineParam(params[i]).paramSetter() != address(this)) {
                return 2;
            }
            uint256 oldIncomePer = IMineParam(params[i]).incomePerTPerSecInWei();
            uint256 oldPrice = IMineParam(params[i]).minePrice();
            uint256 _incomePerTPerSecInWei = values[i];
            
            if(oldIncomePer == 0 || oldPrice == 0) {
                return 10;
            } else {
                uint256 rate;
                if(_incomePerTPerSecInWei > oldIncomePer) {
                    rate = _incomePerTPerSecInWei.sub(oldIncomePer).mul(10000).div(oldIncomePer);
                } else {
                    rate = oldIncomePer.sub(_incomePerTPerSecInWei).mul(10000).div(oldIncomePer);
                }
                if(rate >= minIncomeRate && rate <= maxIncomeRate) {
                    return 11;
                }

                uint256 currentPrice = IMineParam(params[i]).getMinePrice();
                rate = 0;
                if(currentPrice > oldPrice) {
                    rate = currentPrice.sub(oldPrice).mul(10000).div(oldPrice);
                } else {
                    rate = oldPrice.sub(currentPrice).mul(10000).div(oldPrice);
                }
                if(rate >= minIncomeRate && rate <= maxIncomeRate) {
                    return 12;
                }
            }
        }
        return 0;
    }

    function check (address[] memory params, uint256[] memory values) public view returns (bool) {
        uint256 result = checkWithCode(params, values);
        if(result > 9)
            return true;
        return false;
    }

    function update (address[] memory params, uint256[] memory values) public onlyParamSetter {
        require(params.length == values.length, 'invalid parameters');
        for(uint256 i; i<params.length; i++) {
            bool isUpdate;
            uint256 oldIncomePer = IMineParam(params[i]).incomePerTPerSecInWei();
            uint256 oldPrice = IMineParam(params[i]).minePrice();
            uint256 _incomePerTPerSecInWei = values[i];

            if(oldIncomePer == 0 || oldPrice == 0) {
                isUpdate = true;
            } else {
                uint256 rate;
                if(_incomePerTPerSecInWei > oldIncomePer) {
                    rate = _incomePerTPerSecInWei.sub(oldIncomePer).mul(10000).div(oldIncomePer);
                } else {
                    rate = oldIncomePer.sub(_incomePerTPerSecInWei).mul(10000).div(oldIncomePer);
                }
                if(rate >= minIncomeRate && rate <= maxIncomeRate) {
                    isUpdate = true;
                }

                if(!isUpdate) {
                    uint256 currentPrice = IMineParam(params[i]).getMinePrice();
                    if(currentPrice > oldPrice) {
                        rate = currentPrice.sub(oldPrice).mul(10000).div(oldPrice);
                    } else {
                        rate = oldPrice.sub(currentPrice).mul(10000).div(oldPrice);
                    }
                    if(rate >= minIncomeRate && rate <= maxIncomeRate) {
                        isUpdate = true;
                    }
                }
            }
            if(isUpdate) {
                updateOne(params[i], _incomePerTPerSecInWei);
            }
        }
    }

    function updateOne (address param, uint256 _incomePerTPerSecInWei) public onlyParamSetter {
        IMineParam(param).setIncomePerTPerSecInWeiAndUpdateMinePrice(_incomePerTPerSecInWei);
    }

    function updateMinePrice(address param) external onlyParamSetter {
        IMineParam(param).updateMinePrice();
    }

    function addListener(address param, address _listener) external onlyParamSetter {
        IMineParam(param).addListener(_listener);
    }

    function removeListener(address param, address _listener) external onlyParamSetter returns(bool){
        return IMineParam(param).removeListener(_listener);
    }

    function setHashTokenMineParam(address hashToken) public onlyParamSetter {
        IMineParam(IPOWToken(hashToken).mineParam()).addListener(hashToken);
    }

    function setHashTokenMineParams(address[] memory hashTokens) public onlyParamSetter {
        for(uint256 i; i<hashTokens.length; i++) {
            setHashTokenMineParam(hashTokens[i]);
        }
    }
    
}