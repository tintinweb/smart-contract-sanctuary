pragma solidity 0.5.16;

interface IStrategy {

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256);

    function doHardWork() external;

    function depositArbCheck() external view returns (bool);
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

contract HarvestBridgeStrategy is IBridgeStrategy {

    function underlying(address strategy) external view returns (address){
        return IStrategy(strategy).underlying();
    }

    function vault(address strategy) external view returns (address){

        return IStrategy(strategy).vault();
    }

    function depositArbCheck(address strategy) public view returns (bool) {

        return IStrategy(strategy).depositArbCheck();
    }

    /*
    * Returns the total invested amount.
    */
    function investedUnderlyingBalance(address strategy) view public returns (uint256) {

        return IStrategy(strategy).investedUnderlyingBalance();
    }

    /*
    * Cashes everything out and withdraws to the vault
    */
    function withdrawAllToVault(address strategy) external {

        IStrategy(strategy).withdrawAllToVault();
    }

    /*
    * Cashes some amount out and withdraws to the vault
    */
    function withdrawToVault(address strategy, uint256 amount) external {

        IStrategy(strategy).withdrawToVault(amount);
    }

    /*
    * Honest harvesting. It's not much, but it pays off
    */
    function doHardWork(address strategy) external {

        IStrategy(strategy).doHardWork();
    }

}

