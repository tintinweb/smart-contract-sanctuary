// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @notice EHCearly stage manual setting oracle
 */
contract EHCOracleManual is Ownable, IEHCOralce {
    uint256 private _price;
    
    /**
     * @dev manual setting EHC/USDT price
     */
    function setPrice(uint256 price) external onlyOwner{
        _price = price;
        
    }
    
   /**
     * @dev get EHC/USDT price
     */
    function getPrice() external view override returns(uint256) {
        return _price;
    }
}