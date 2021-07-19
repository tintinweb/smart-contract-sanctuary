//SourceUnit: InfinitronLifeboat.sol


pragma solidity 0.5.9;


contract InfinitronLifeBoat {
	using SafeMath for uint256;
    address payable infinitronContractAddress;
    address  owner;
	uint256 constant public INVESTOR_ZERO_PERCENTAGE = 20;
	uint256 constant public LIFE_BOAT_LIFELINE = 980;
	uint256 constant public PERCENTS_DIVIDER = 1000;


	constructor(address contractOwner) public {
		require(!isContract(contractOwner));
		owner = contractOwner;
	}

    function() external payable {

	}
  
	function reviveInfiniTron(address payable inversterZero) external payable {
	    require(msg.sender == infinitronContractAddress, "ONLY INFINFTRON CAN CALLTHIS METHOD");
	    require(infinitronContractAddress.balance == 0, "INFINITRON BALANCE MUST BE ZERO");
		uint256 pot = getContractBalance().div(2);
		uint256 investerCut = pot.mul(INVESTOR_ZERO_PERCENTAGE).div(PERCENTS_DIVIDER);
		uint256 revivalAmount = pot.mul(LIFE_BOAT_LIFELINE).div(PERCENTS_DIVIDER);
		inversterZero.transfer(investerCut);
		infinitronContractAddress.transfer(revivalAmount);

	}

	function Ownable() public {
    	owner = msg.sender;
  	}

  	modifier onlyOwner() {
    	require(msg.sender == owner);
    	_;
  	}

  	function transferOwnership(address newOwner) public onlyOwner {
    	require(newOwner != address(0));
   		owner = newOwner;
  	}


    function setInfinitronAddress(address payable newContract) public onlyOwner {
    	require(isContract(newContract));
    	require(infinitronContractAddress != newContract);
   		infinitronContractAddress = newContract;
  	}


	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function getContractBalance() public view returns (uint256) {
		return address(this).balance;
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