pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

	/**
	* @dev Multiplies two numbers, throws on overflow.
	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			return 0;
		}
		c = a * b;
		assert(c / a == b);
		return c;
	}

	/**
	* @dev Integer division of two numbers, truncating the quotient.
	*/
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		// uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}

contract Hello2 {
	address admin;
	mapping (address => uint256) signedMap;
	using SafeMath for uint256;

	modifier onlyAdmin() {
		require(msg.sender == admin);
		_;
	}

	constructor() public {
		admin = msg.sender;
	}

	//返回当前时间
	function nowInSeconds() internal view returns (uint256) {
		return now;
	}

	//签到
	function signed() public {
		signedMap[msg.sender] = nowInSeconds();
	}

	//获取上次签到时间
	function getLastSignedTime() public view returns (uint256) {
		return signedMap[msg.sender];
	}

	//取消签到
	function unsigned() public {
		delete signedMap[msg.sender];
	}

	//管理员删除用户签到
	function adminUnsigned(address addr) onlyAdmin public {
		delete signedMap[addr];
	}

	//管理员获取用户签到时间
	function adminGetLastSignedTime(address addr) onlyAdmin public view returns (uint256) {
		return signedMap[addr];
	}

	function add(uint256 n1, uint256 n2) public returns (uint256) {
		return n1.add(n2);
	}
}