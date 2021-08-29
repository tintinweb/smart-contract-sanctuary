/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity ^0.5.0;

interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

interface LendingPool {
    function getReserveData(address _reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            address aTokenAddress,
            uint40 lastUpdateTimestamp
        );
}

contract Cybor {
    LendingPoolAddressesProvider provider = LendingPoolAddressesProvider(0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5);
    LendingPool lendingPool = LendingPool(provider.getLendingPool());
    
    function retrieve() public view returns (
            uint[4] memory totalBorrowsVariables,
            uint[4] memory variableBorrowRates
        ){
        
        uint usdtTotalBorrowsVariable;
        uint usdtVariableBorrowRate;
        
        (, , ,usdtTotalBorrowsVariable , ,usdtVariableBorrowRate , , , , , , ,)  = lendingPool.getReserveData(0x13512979ADE267AB5100878E2e0f485B568328a4);
        
        totalBorrowsVariables[0] = usdtTotalBorrowsVariable;
        variableBorrowRates[0] = usdtVariableBorrowRate;
        
        uint daiTotalBorrowsVariable;
        uint daiVariableBorrowRate;
        
        (, , ,daiTotalBorrowsVariable , ,daiVariableBorrowRate , , , , , , ,)  = lendingPool.getReserveData(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);
        
        totalBorrowsVariables[1] = daiTotalBorrowsVariable;
        variableBorrowRates[1] = daiVariableBorrowRate;
        
        uint usdcTotalBorrowsVariable;
        uint usdcVariableBorrowRate;
        
        (, , ,usdcTotalBorrowsVariable , ,usdcVariableBorrowRate , , , , , , ,)  = lendingPool.getReserveData(0xe22da380ee6B445bb8273C81944ADEB6E8450422);
        
        totalBorrowsVariables[2] = usdcTotalBorrowsVariable;
        variableBorrowRates[2] = usdcVariableBorrowRate;
        
        uint tusdTotalBorrowsVariable;
        uint tusdVariableBorrowRate;
        
        (, , ,tusdTotalBorrowsVariable , ,tusdVariableBorrowRate , , , , , , ,)  = lendingPool.getReserveData(0x1c4a937d171752e1313D70fb16Ae2ea02f86303e);
        
        totalBorrowsVariables[3] = tusdTotalBorrowsVariable;
        variableBorrowRates[3] = tusdVariableBorrowRate;
    }
    
}