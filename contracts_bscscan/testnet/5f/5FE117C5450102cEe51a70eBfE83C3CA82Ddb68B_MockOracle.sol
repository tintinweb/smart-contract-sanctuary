pragma solidity >=0.8.0;

interface IOracle {
	function update() external;

	function consult(address token, uint256 amountIn)
		external
		view
		returns (uint256 amountOut);
}

pragma solidity >=0.8.0;
import '../Interfaces/IOracle.sol';

contract MockOracle is IOracle {
	function update() public override {}

	function consult(address token, uint256 amountIn)
		public
		view
		override
		returns (uint256 amountOut)
	{
		return price;
	}

	uint256 private price = 10**18;

	function setPrice(uint256 price_) public {
		price = price_;
	}
}

