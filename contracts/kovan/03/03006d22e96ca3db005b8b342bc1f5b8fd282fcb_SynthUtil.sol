/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

pragma solidity ^0.5.16;

// Inheritance

contract SynthUtil {
    bytes32 internal constant DUSD = "dUSD";


    function totalSynthsInKey(address account, bytes32 currencyKey) external view returns (uint total) {
        return 1e24;
    }

    function synthsBalances(address account)
        external
        view
        returns (
            bytes32[] memory,
            uint[] memory,
            uint[] memory
        )
    {
        uint numSynths = 2;
        bytes32[] memory currencyKeys = new bytes32[](numSynths);
        uint[] memory balances = new uint[](numSynths);
        uint[] memory sUSDBalances = new uint[](numSynths);

        currencyKeys[0] = bytes32("sTSLA");
        currencyKeys[1] = bytes32("sAPPLE");

        balances[0] = 1e24;
        balances[1] = 1e24;

        sUSDBalances[0] = 2e25;
        sUSDBalances[1] = 3e25;

        return (currencyKeys, balances, sUSDBalances);
    }

    function frozenSynths() external view returns (bytes32[] memory) {
        bytes32[] memory frozenSynthsKeys = new bytes32[](1);
        frozenSynthsKeys[0] = bytes32("sTSLA");
        return frozenSynthsKeys;
    }

    function synthsRates() external view returns (bytes32[] memory, uint[] memory) {
        uint numSynths = 2;
        bytes32[] memory currencyKeys = new bytes32[](numSynths);
        uint[] memory currencyRates = new uint[](numSynths);

        currencyKeys[0] = bytes32("sTSLA");
        currencyKeys[1] = bytes32("sAPPLE");

        currencyRates[0] = 20;
        currencyRates[1] = 30;

        return (currencyKeys, currencyRates);
    }

    function synthsTotalSupplies()
        external
        view
        returns (
            bytes32[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint numSynths = 2;
        bytes32[] memory currencyKeys = new bytes32[](numSynths);
        uint[] memory balances = new uint[](numSynths);
        uint[] memory sUSDBalances = new uint[](numSynths);

        currencyKeys[0] = bytes32("sTSLA");
        currencyKeys[1] = bytes32("sAPPLE");

        balances[0] = 1e24;
        balances[1] = 1e24;

        sUSDBalances[0] = 2e25;
        sUSDBalances[1] = 3e25;

        return (currencyKeys, balances, sUSDBalances);
    }
}