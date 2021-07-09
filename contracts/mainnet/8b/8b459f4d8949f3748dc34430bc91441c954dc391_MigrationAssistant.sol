/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// Sources flattened with hardhat v2.4.1 https://hardhat.org

// File interfaces/badger/ISett.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

interface ISett {
    function token() external view returns (address);

    function keeper() external view returns (address);

    function deposit(uint256) external;

    function depositFor(address, uint256) external;

    function depositAll() external;

    function withdraw(uint256) external;

    function withdrawAll() external;

    function earn() external;

    function balance() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this

    function getPricePerFullShare() external view returns (uint256);
}


// File interfaces/badger/IStrategy.sol




pragma solidity >=0.5.0 <0.8.0;

interface IStrategy {
    function want() external view returns (address);

    function deposit() external;

    // NOTE: must exclude any tokens used in the yield
    // Controller role - withdraw should return to Controller
    function withdrawOther(address) external returns (uint256 balance);

    // Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);
    function balanceOfPool() external view returns (uint256);
    function balanceOfWant() external view returns (uint256);

    function getName() external pure returns (string memory);

    function setStrategist(address _strategist) external;

    function setWithdrawalFee(uint256 _withdrawalFee) external;

    function setPerformanceFeeStrategist(uint256 _performanceFeeStrategist) external;

    function setPerformanceFeeGovernance(uint256 _performanceFeeGovernance) external;

    function setGovernance(address _governance) external;

    function setController(address _controller) external;

    function controller() external returns (address);

    function governance() external returns (address);

    function tend() external;

    function harvest() external;
}


// File interfaces/badger/IController.sol


pragma solidity >=0.5.0 <0.8.0;

interface IController {
    function withdraw(address, uint256) external;

    function withdrawAll(address) external;

    function strategies(address) external view returns (address);

    function approvedStrategies(address, address) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function approveStrategy(address, address) external;

    function setStrategy(address, address) external;

    function setVault(address, address) external;

    function want(address) external view returns (address);

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);
}


// File interfaces/convex/IBaseRewardsPool.sol



pragma solidity ^0.6.0;

interface IBaseRewardsPool {
    //balance
    function balanceOf(address _account) external view returns (uint256);

    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns (bool);

    //claim rewards
    function getReward() external returns (bool);

    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);

    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account, uint256 _amount) external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function rewards(address _account) external view returns (uint256);

    function earned(address _account) external view returns (uint256);

    function stakingToken() external view returns (address);
}


// File contracts/badger-sett/MigrationAssistant.sol



pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;




contract MigrationAssistant {
    event Debug(uint256 value);
    event DebugAddress(address value);

    struct MigrationParams {
        address want;
        address beforeStrategy;
        address afterStrategy;
    }

    function migrate(IController controller, MigrationParams[] memory migrations) public {
        for (uint256 i = 0; i < migrations.length; i++) {
            MigrationParams memory params = migrations[i];

            ISett sett = ISett(controller.vaults(params.want));
            IStrategy beforeStrategy = IStrategy(params.beforeStrategy);
            IStrategy afterStrategy = IStrategy(params.afterStrategy);

            // ===== Pre Verification =====
            // Strategies must have same want
            require(beforeStrategy.want() == afterStrategy.want(), "strategy-want-mismatch");
            require(afterStrategy.want() == sett.token(), "strategy-sett-want-mismatch");
            require(params.want == sett.token(), "want-param-mismatch");
            require(beforeStrategy.controller() == afterStrategy.controller(), "strategy-controller-mismatch");
            // require(beforeStrategy.governance() == afterStrategy.governance(), "strategy-governance-mismatch");

            require(beforeStrategy.controller() == address(controller), "before-strategy-controller-mismatch");
            require(afterStrategy.controller() == address(controller), "after-strategy-controller-mismatch");

            uint256 beforeBalance = sett.balance();
            uint256 beforePpfs = sett.getPricePerFullShare();

            // ===== Run Migration =====
            controller.setStrategy(params.want, params.afterStrategy);

            uint256 afterBalance = sett.balance();
            uint256 afterPpfs = sett.getPricePerFullShare();

            // ===== Post Verification =====
            // Strategy must report same total balance
            require(afterBalance == beforeBalance, "sett-balance-mismatch");

            // PPFS must not change
            require(beforePpfs == afterPpfs, "ppfs-mismatch");
        }
    }
}