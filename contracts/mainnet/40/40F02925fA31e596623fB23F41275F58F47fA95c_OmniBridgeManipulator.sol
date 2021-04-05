pragma solidity ^0.8.0;

interface I_ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract OmniBridgeManipulator {

    address public reserve = 0x390a8Fb3fCFF0bB0fCf1F91c7E36db9c53165d17;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    /// @notice Manipulate omni bridge by sending DAI to router
    function relayTokens(
        address reserveToken,
        address charity,
        uint256 charityCutAmount
    ) external {
        require(msg.sender == reserve, "relayTokens: !reserve");
        require(I_ERC20(dai).transferFrom(reserve, charity, charityCutAmount));
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