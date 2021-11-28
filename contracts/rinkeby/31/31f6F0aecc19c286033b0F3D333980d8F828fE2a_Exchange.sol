// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IERC20.sol";


library SafeMath {
	/**
	 * SafeMath mul function
	 * @dev function for safe multiply, throws on overflow.
	 **/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	/**
	 * SafeMath div funciotn
	 * @dev function for safe devide, throws on overflow.
	 **/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	/**
	 * SafeMath sub function
	 * @dev function for safe subtraction, throws on overflow.
	 **/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}
	
	/**
	 * SafeMath add function
	 * @dev Adds two numbers, throws on overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

// Home token interface to get the list of students
interface IHome {
    function getStudentsList() external view returns(string[] memory);
}

contract Exchange {
	using SafeMath for uint256;

	AggregatorV3Interface internal priceFeed;
	address public owner;
	IERC20 public token;

    address constant HOME_TOKEN_ADDRESS = 0x0E822C71e628b20a35F8bCAbe8c11F274246e64D;
	address constant CHAINLINK_ADDRESS = 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e;

	modifier onlyOwner () {
       require(msg.sender == owner, "This can only be called by the contract owner!");
       _;
    }

	constructor(address tokenContractAddr) {
		token = IERC20(tokenContractAddr);
		owner = msg.sender;
        priceFeed = AggregatorV3Interface(CHAINLINK_ADDRESS);
	}

	// Get latest eth/usd price
    function getLatestPrice() public view returns (int) {
        (, int price,,,) = priceFeed.latestRoundData();
        return price;
    }

    // Get students count
    function getStudentsCount() public view returns (uint) {
        string[] memory studentsList = IHome(HOME_TOKEN_ADDRESS).getStudentsList();
        return uint(studentsList.length);
    }

	/**
	* receive function. Used to load the exchange with ether
	*/
    receive() external payable {}

	//Get wei cost of spesific [amount] of tokens 
    function getCost(uint amount) public view returns (uint) {
        uint costWei = amount * uint(getLatestPrice())/getStudentsCount()/100000000 ;
        return costWei;
    }

	/**
	* Sender requests to buy [amount] of tokens from the contract.
	* Sender needs to send enough ether
	*/

	function buyTokens(uint amount) payable public returns (bool) {
		uint costWei = getCost(amount);
		require(msg.value >= costWei, "Sorry, you don't have enough eth");

		// Ensure that the contract has enough tockens
		if(token.balanceOf(address(this)) >= amount){
		    assert(token.transfer(msg.sender, amount));

		    uint change = msg.value - costWei;
		    if (change >= 1) msg.sender.call{value: change}("Change");
		    return true;
        }
        else {
			msg.sender.call{value: msg.value}("Sorry, there is not enough tokens to buy");
            return false;
        }
	}

	//This function is created to be tested with Interceptor
	function buyOnePieceOfToken() payable public returns (bool){
		return buyTokens(1);
	}
	//Get Exchange Balance
	function getBalance() public view returns(uint) {
        return address(this).balance;
    }
	//Withdraw all eth from contract to the owner
	function withdraw(address payable _to) onlyOwner public {
        _to.transfer(getBalance());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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