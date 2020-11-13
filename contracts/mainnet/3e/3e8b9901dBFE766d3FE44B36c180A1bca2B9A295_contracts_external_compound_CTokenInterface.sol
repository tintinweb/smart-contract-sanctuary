pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface CTokenInterface is IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external override view returns (uint256);
    function underlying() external view returns (address);
    function balanceOfUnderlying(address owner) external returns (uint256);
    function supplyRatePerBlock() external returns (uint256);
    function exchangeRateCurrent() external returns (uint256);
    function mint(uint256 mintAmount) external returns (uint256);
    function balanceOf(address user) external override view returns (uint256);
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}
