pragma solidity ^0.6.0;

import "./AaveHelper.sol";

contract AaveSafetyRatio is AaveHelper {

    function getSafetyRatio(address _user) public view returns(uint256) {
        address lendingPoolAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        (,,uint256 totalBorrowsETH,,uint256 availableBorrowsETH,,,) = ILendingPool(lendingPoolAddress).getUserAccountData(_user);

        return wdiv(add(totalBorrowsETH, availableBorrowsETH), totalBorrowsETH);
    }
}