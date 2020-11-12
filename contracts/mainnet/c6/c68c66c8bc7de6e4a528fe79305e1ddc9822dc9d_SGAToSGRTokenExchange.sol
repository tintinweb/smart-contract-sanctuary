pragma solidity 0.4.25;

// File: openzeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  /**
  * @dev Returns the largest of two numbers.
  */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
  * @dev Returns the smallest of two numbers.
  */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
  * @dev Calculates the average of two numbers. Since these are integers,
  * averages of an even and odd number cannot be represented, and will be
  * rounded down.
  */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/migrations/SGAToSGRTokenExchange.sol

/**
 * Details of usage of licenced software see here: https://www.sogur.com/software/readme_v1
 */

/**
 * @title SGA to SGR Token Exchange.
 */
contract SGAToSGRTokenExchange {
    string public constant VERSION = "1.0.0";

    using Math for uint256;
    // Exchanged SGA tokens are transferred to this address. The zero address can not be used as transfer to this address will revert.
    address public constant SGA_TARGET_ADDRESS = address(1);

    IERC20 public sgaToken;
    IERC20 public sgrToken;

    event ExchangeSgaForSgrCompleted(address indexed _sgaHolder, uint256 _exchangedAmount);

    /**
     * @dev Create the contract.
     * @param _sgaTokenAddress The SGA token contract address.
     * @param _sgrTokenAddress The SGR token contract address.
     */
    constructor(address _sgaTokenAddress, address _sgrTokenAddress) public {
        require(_sgaTokenAddress != address(0), "SGA token address is illegal");
        require(_sgrTokenAddress != address(0), "SGR token address is illegal");

        sgaToken = IERC20(_sgaTokenAddress);
        sgrToken = IERC20(_sgrTokenAddress);
    }


    /**
     * @dev Exchange SGA to SGR.
     */
    function exchangeSGAtoSGR() external {
        handleExchangeSGAtoSGRFor(msg.sender);
    }

    /**
     * @dev Exchange SGA to SGR for a given sga holder.
     * @param _sgaHolder The sga holder address.
     */
    function exchangeSGAtoSGRFor(address _sgaHolder) external {
        require(_sgaHolder != address(0), "SGA holder address is illegal");
        handleExchangeSGAtoSGRFor(_sgaHolder);
    }

    /**
     * @dev Handle the SGA to SGR exchange.
     */
    function handleExchangeSGAtoSGRFor(address _sgaHolder) internal {
        uint256 allowance = sgaToken.allowance(_sgaHolder, address(this));
        require(allowance > 0, "SGA allowance must be greater than zero");
        uint256 balance = sgaToken.balanceOf(_sgaHolder);
        require(balance > 0, "SGA balance must be greater than zero");
        uint256 amountToExchange = allowance.min(balance);

        sgaToken.transferFrom(_sgaHolder, SGA_TARGET_ADDRESS, amountToExchange);
        sgrToken.transfer(_sgaHolder, amountToExchange);
        emit ExchangeSgaForSgrCompleted(_sgaHolder, amountToExchange);
    }
}