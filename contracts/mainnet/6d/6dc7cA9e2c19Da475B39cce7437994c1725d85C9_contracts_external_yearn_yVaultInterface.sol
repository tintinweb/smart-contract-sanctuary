pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface yVaultInterface is IERC20 {
    function token() external view returns (address);

    function balance() external view returns (uint);
    
    function deposit(uint _amount) external;
    
    function withdraw(uint _shares) external;
    
    function getPricePerFullShare() external view returns (uint);
}