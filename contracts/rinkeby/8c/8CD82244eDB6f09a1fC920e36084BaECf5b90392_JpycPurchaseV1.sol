/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

pragma solidity ^0.6.2;

interface IERC20 {
	function allowance(address owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface AggregatorV3Interface {
	function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract  JpycPurchaseV1 {

	using SafeMath for uint256;

	address payable jpyc_supplyer;
	address public jpyc_address; // Rinkeby: 0x995c66f0fa6666c2c3b2fc49f4442d588ebeda68
	AggregatorV3Interface internal priceFeedEthUsd;
	AggregatorV3Interface internal priceFeedJpyUsd;

	IERC20 internal _jpycInterface;

	constructor(address _jpyc_address) public { //
		jpyc_supplyer = msg.sender;
		jpyc_address = _jpyc_address;
		_jpycInterface = IERC20(_jpyc_address);
		priceFeedEthUsd = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); //Mainnet 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419, Ropsten 0x6B927dc8cF91c69d9dBFbf630D8951709cB0885D
		priceFeedJpyUsd = AggregatorV3Interface(0x3Ae2F46a2D84e3D5590ee6Ee5116B80caF77DeCA); //Mainnet 0xBcE206caE7f0ec07b545EddE332A47C2F75bbeb3, Ropsten 0x795122664E4D4A3F7e66E8674953C97ADc60B17C
	}

	function getLatestEthUsdPrice() public view returns (int) {
		(
			uint80 roundID,
			int price,
			uint startedAt,
			uint timeStamp,
			uint80 answeredInRound
		) = priceFeedEthUsd.latestRoundData();
		return price;
	}

	function getLatestJpyUsdPrice() public view returns (int) {
		(
			uint80 roundID,
			int price,
			uint startedAt,
			uint timeStamp,
			uint80 answeredInRound
		) = priceFeedJpyUsd.latestRoundData();
		return price;
	}

	function getEstimatedEthFromJpy (uint256 _jpyAmount) public view returns (uint256 estimatedEth) {
		uint256 estimatedUsd = uint256(getLatestJpyUsdPrice()).mul(_jpyAmount);
		return estimatedEth = (estimatedUsd * 10 ** 18).div(uint256(getLatestEthUsdPrice()));
	}

	function getJpycFromContractAllowance(uint256 _amount) payable public returns(bool success) {
		uint _jpycAmount = _amount * 10 ** 18;
		require(_jpycInterface.allowance(jpyc_supplyer, address(this)) >= _jpycAmount, "insufficient allowance amount in contract");
		uint256 ethAmount = getEstimatedEthFromJpy(_amount);
		require(msg.value == ethAmount, "msg.value does not match with a necessary ether amount");
		jpyc_supplyer.transfer(ethAmount);
		_jpycInterface.transferFrom(jpyc_supplyer, msg.sender, _jpycAmount);
		success = true;
	}
}