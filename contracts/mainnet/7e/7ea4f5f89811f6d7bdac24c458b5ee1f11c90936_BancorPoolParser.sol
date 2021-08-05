/**
 *Submitted for verification at Etherscan.io on 2020-11-24
*/

pragma solidity ^0.6.12;

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

interface IGetBancorData {
  function getBancorContractAddresByName(string calldata _name) external view returns (address result);
}

interface IBancorFormula {
  function fundCost(uint256 _supply,
                    uint256 _reserveBalance,
                    uint32 _reserveRatio,
                    uint256 _amount)
    external
    view returns (uint256);
}

interface IBancorConverter {
  function reserveRatio() external view returns(uint32);
  function connectorTokens(uint index) external view returns(address);
  function getConnectorBalance(address _connectorToken) external view returns (uint256);
  function connectorTokenCount() external view returns (uint16);
}


interface ISmartToken {
  function owner() external view returns(address);
  function totalSupply() external view returns(uint256);
}

interface IExchangePortal {
  function getValueViaDEXsAgregators(address _from, address _to, uint256 _amount) external view returns (uint256);
}

contract BancorPoolParser {
  using SafeMath for uint256;
  IGetBancorData public GetBancorData;
  IExchangePortal public ExchangePortal;

  constructor(address _GetBancorData, address _ExchangePortal) public {
    GetBancorData = IGetBancorData(_GetBancorData);
    ExchangePortal = IExchangePortal(_ExchangePortal);
  }

  // Works for new Bancor pools
  // parse total value of pool conenctors
  function parseConnectorsByPool(address _from, address _to, uint256 poolAmount)
    external
    view
    returns(uint256)
  {
     // get common data
     address converter = ISmartToken(address(_from)).owner();
     uint16 connectorTokenCount = IBancorConverter(converter).connectorTokenCount();
     uint256 poolTotalSupply = ISmartToken(address(_from)).totalSupply();
     uint32 reserveRatio =  IBancorConverter(converter).reserveRatio();

     IBancorFormula bancorFormula = IBancorFormula(
       GetBancorData.getBancorContractAddresByName("BancorFormula")
     );

     return calculateTotalSum(
       converter,
       poolTotalSupply,
       reserveRatio,
       connectorTokenCount,
       bancorFormula,
       _to,
       poolAmount
       );
  }


  // internal helper
  function calculateTotalSum(
    address converter,
    uint256 poolTotalSupply,
    uint32 reserveRatio,
    uint16 connectorTokenCount,
    IBancorFormula bancorFormula,
    address _to,
    uint256 poolAmount
    )
    internal
    view
    returns(uint256 totalValue)
  {
    for(uint16 i = 0; i < connectorTokenCount; i++){
      // get amount of token in pool by pool input
      address connectorToken = IBancorConverter(converter).connectorTokens(i);
      uint256 connectorBalance = IBancorConverter(converter).getConnectorBalance(address(connectorToken));
      uint256 amountByShare = bancorFormula.fundCost(poolTotalSupply, connectorBalance, reserveRatio, poolAmount);

      // get ratio of pool token
      totalValue = totalValue.add(ExchangePortal.getValueViaDEXsAgregators(connectorToken, _to, amountByShare));
    }
  }
}