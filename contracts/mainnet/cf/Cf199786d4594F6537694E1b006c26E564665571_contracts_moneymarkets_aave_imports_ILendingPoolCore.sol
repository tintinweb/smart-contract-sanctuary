pragma solidity 0.5.17;


// Aave lending pool core interface
// Documentation: https://github.com/aave/aave-protocol/blob/master/contracts/lendingpool/LendingPoolCore.sol#L615
interface ILendingPoolCore {
    // The equivalent of exchangeRateStored() for Compound cTokens
    function getReserveNormalizedIncome(address _reserve)
        external
        view
        returns (uint256);
}
