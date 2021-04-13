/**
 *Submitted for verification at Etherscan.io on 2021-04-12
*/

// File: @chainlink/contracts/src/v0.5/interfaces/AggregatorV3Interface.sol

pragma solidity >=0.5.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: contracts/price/ChainlinkService.sol

pragma solidity >=0.5.0 <0.7.0;


contract ChainlinkService {  
  
    function getLatestPrice(address feedAddress) 
        public 
        view 
        returns (int, uint, uint8) 
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feedAddress);
        ( ,int price, ,uint timeStamp, ) = priceFeed.latestRoundData();
        uint8 decimal = priceFeed.decimals();
        return (price, timeStamp, decimal);
    }
}

// File: contracts/external/YieldsterVaultMath.sol

pragma solidity >=0.5.0 <0.7.0;


/**
 * @title YieldsterVaultMath
 * @dev Math operations with safety checks that revert on error
 * Renamed from SafeMath to YieldsterVaultMath to avoid conflicts
 * TODO: remove once open zeppelin update to solc 0.5.0
 */
library YieldsterVaultMath{

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


  /**
  * @dev Returns the largest of two numbers.
  */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }
}

// File: contracts/interfaces/IRegistry.sol

pragma solidity >=0.5.0 <0.7.0;

interface IRegistry {
    
    function get_virtual_price_from_lp_token(address) external view returns(uint256);

}

// File: contracts/interfaces/yearn/IVault.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

interface IVault {
    function token() external view returns (address);

    function underlying() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function controller() external view returns (address);

    function governance() external view returns (address);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;
}

// File: contracts/interfaces/IYieldsterVault.sol

pragma solidity >=0.5.0 <0.7.0;

interface IYieldsterVault {
    
    function tokenValueInUSD() external view returns(uint256);

}

// File: contracts/interfaces/IYieldsterStrategy.sol

pragma solidity >=0.5.0 <0.7.0;

interface IYieldsterStrategy {
    
    function tokenValueInUSD() external view returns(uint256);

}

// File: contracts/price/PriceModule.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;








contract PriceModule is ChainlinkService
{

    using YieldsterVaultMath for uint256;
    
    address public priceModuleManager;
    
    address public curveRegistry;

    struct Token {
        address feedAddress;
        uint256 tokenType;
        bool created;
    }

    mapping(address => Token) tokens;

    constructor(address _curveRegistry)
    public
    {
        priceModuleManager = msg.sender;
        curveRegistry = _curveRegistry;
    }

    function setManager(address _manager)
        external
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        priceModuleManager = _manager;
    }

    function addToken(
        address _tokenAddress, 
        address _feedAddress, 
        uint256 _tokenType
    )
    external
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        Token memory newToken = Token({ feedAddress:_feedAddress, tokenType: _tokenType, created:true});
        tokens[_tokenAddress] = newToken;
    }

    function setCurveRegistry(address _curveRegistry)
        external
    {
        require(msg.sender == priceModuleManager, "Not Authorized");
        curveRegistry = _curveRegistry;
    }


    function getUSDPrice(address _tokenAddress) 
        public 
        view
        returns(uint256)
    {
        require(tokens[_tokenAddress].created, "Token not present");

        if(tokens[_tokenAddress].tokenType == 1) {
            (int price, , uint8 decimals) = getLatestPrice(tokens[_tokenAddress].feedAddress);

            if(decimals < 18) {
                return (uint256(price)).mul(10 ** uint256(18 - decimals));
            }
            else if (decimals > 18) {
                return (uint256(price)).div(uint256(decimals - 18));
            }
            else {
                return uint256(price);
            }

        } else if(tokens[_tokenAddress].tokenType == 2) {
            return IRegistry(curveRegistry).get_virtual_price_from_lp_token(_tokenAddress);

        } else if(tokens[_tokenAddress].tokenType == 3) {
            address token = IVault(_tokenAddress).token();
            uint256 tokenPrice = getUSDPrice(token);
            return (tokenPrice.mul(IVault(_tokenAddress).getPricePerFullShare())).div(1e18);

        } else if(tokens[_tokenAddress].tokenType == 4) {
            return IYieldsterStrategy(_tokenAddress).tokenValueInUSD();

        } else if(tokens[_tokenAddress].tokenType == 5) {
            return IYieldsterVault(_tokenAddress).tokenValueInUSD();

        } else {
            revert("Token not present");
        }
    }
}