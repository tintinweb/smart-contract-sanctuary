/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

pragma solidity 0.5.10;

contract WhitelistContract {
	using SafeMath for uint256;


	uint256 public totalDeposits;

	address payable public privateSaleOwner;

	struct Deposit {
		uint256 amount;
		uint256 start;
	}



	event NewDeposit(address indexed user, uint256 amount);


	constructor(address payable projectAddr) public {
		require(!isContract(projectAddr));

		privateSaleOwner = projectAddr;
	}

	function depositContribute() public payable {
		totalDeposits = totalDeposits.add(msg.value);

		emit NewDeposit(msg.sender, msg.value);

	}
	function withdraw(uint _amount) public returns(bool) {
		require(msg.sender == privateSaleOwner, "Only Admin Can execute this");
		privateSaleOwner.transfer(_amount);
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