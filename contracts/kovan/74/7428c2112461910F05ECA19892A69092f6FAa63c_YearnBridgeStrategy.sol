pragma solidity 0.5.16;

interface IStrategy {
    function want() external view returns (address);

    function vault() external view returns (address);

    function deposit() external;

    function withdraw(uint _amount) external;

    function withdrawAll() external returns (uint balance);

    function balanceOf() external view returns (uint);
}

interface IBridgeStrategy {

    function underlying(address strategy) external view returns (address);

    function vault(address strategy) external view returns (address);

    function withdrawAllToVault(address strategy) external;

    function withdrawToVault(address strategy, uint256 amount) external;

    function investedUnderlyingBalance(address strategy) external view returns (uint256);

    function doHardWork(address strategy) external;

    function depositArbCheck(address strategy) external view returns (bool);
}

contract YearnBridgeStrategy is IBridgeStrategy {

    function underlying(address strategy) external view returns (address){
        return IStrategy(strategy).want();
    }

    function vault(address strategy) external view returns (address){

        return IStrategy(strategy).vault();
    }

    function depositArbCheck(address strategy) public view returns (bool) {

        return true;
    }

    /*
    * Returns the total invested amount.
    */
    function investedUnderlyingBalance(address strategy) view public returns (uint256) {

        return IStrategy(strategy).balanceOf();
    }

    /*
    * Cashes everything out and withdraws to the vault
    */
    function withdrawAllToVault(address strategy) external {

        IStrategy(strategy).withdrawAll();
    }

    /*
    * Cashes some amount out and withdraws to the vault
    */
    function withdrawToVault(address strategy, uint256 amount) external {

        IStrategy(strategy).withdraw(amount);
    }

    /*
    * Honest harvesting. It's not much, but it pays off
    */
    function doHardWork(address strategy) external {

        IStrategy(strategy).deposit();
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}