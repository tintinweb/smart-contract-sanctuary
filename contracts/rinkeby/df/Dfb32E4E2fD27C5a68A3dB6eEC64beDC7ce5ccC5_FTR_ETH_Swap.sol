// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeMath} from "./safe_math.sol";
import "./futuristic_token.sol";
import "./AggregatorV3Interface.sol";
import "./ierc20.sol";

interface IHome2{
     function getStudentsList() external view returns (string[] memory); 
}


contract FTR_ETH_Swap {
    using SafeMath for *;
    string private _name = "FTR/ETH Swapper";

    AggregatorV3Interface internal priceFeed;

// /**
//  * Network: Rinkeby
//  * Aggregator: ETH/USD
//  * Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
//  */    
    address private rateSource = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e; 
    address private home2 = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D; // From previous HW2
    uint256 private NumberOfStudents;

    event Selling(address indexed receiver, uint value);
    event Failure(address indexed receiver, uint value, bytes data);
    event Interception(bytes message);
    event Recepting(bytes message);

    address private _owner;
    FuturisticToken internal token;

    constructor(address tokenAddress) {
        priceFeed = AggregatorV3Interface(rateSource);
        NumberOfStudents = uint256(IHome2(home2).getStudentsList().length);
        token = FuturisticToken(tokenAddress);
        _owner = msg.sender;
    }
    
    fallback() external payable {
        //buyTokens();
        _getBackEther();
        emit Interception(msg.data);
    }

    function _getBackEther() public payable {
        require(msg.sender == _owner, "No authority to take back tokens");
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        buyTokens();
        emit Recepting("Assets came back");
    }

    function getExchange() public view returns (uint) {   
        uint res_;
        uint8 priceFeedDecimals = priceFeed.decimals(); // = 8
        ( , int256 price, , , ) = priceFeed.latestRoundData();
        res_ = uint ( uint(price) / uint(priceFeedDecimals));
        return uint (res_ / NumberOfStudents);
    }

    function buyTokens() public payable returns (bool) {
        require(msg.value > 0, "Some Eth required");

        uint amount;
        amount = uint(msg.value * getExchange()) ;

        uint currentBalance = token.balanceOf(address(token));
    
        if( currentBalance > amount ) {
            bool is_sent = token.transfer(msg.sender, amount);
            require(is_sent, "Failled to transfer FTR tokens");
            emit Selling(msg.sender, amount);
            return true;
        }
        else {
            (bool is_sent, bytes memory data) = msg.sender.call {value : msg.value} ("Sorry,there is not enough tokens");
            require(is_sent, "Failled to return Eth back to buyer");
            emit Failure(msg.sender, amount, data);
            return false;
       }
    }
}

pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

import "./safe_math.sol";
import "./ierc20.sol";

contract FuturisticToken is IERC20 {
    using SafeMath for *;
    
    mapping (address => uint256) private _balances;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    uint256 private _totalSupply = 5_000 * (uint256(10) ** _decimals);

    address private owner = msg.sender;
    
    constructor () {
        _mint (msg.sender, _totalSupply); 
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}