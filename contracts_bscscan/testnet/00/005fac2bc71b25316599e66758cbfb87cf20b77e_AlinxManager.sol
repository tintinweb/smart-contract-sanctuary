/**
 *Submitted for verification at BscScan.com on 2021-08-28
*/

// SPDX-License-Identifier: MI
pragma solidity >=0.6.0 <0.8.0;

contract AlinxManager{
  
    mapping(address => bool) Chesters;
    
    uint256 PriceKey = 10000000000000000000000;
    
    uint256 FeeMarket = 5**18;
    uint256 DivPercent = 10**20;
    uint256 FeeChest = 10000000000000000000000 ;
    address FeeAddress;
    
    
    constructor(address _feeAddress){
        FeeAddress = _feeAddress;
    }
    
    
    function chesters(address _address) external view returns (bool){
        return Chesters[_address];
    }

    function priceKey() external view returns (uint256){
        return PriceKey;
    }
    

    function divPercent() external view returns (uint256){
        return DivPercent;
    }

    function feeMarket() external view returns (uint256){
        return FeeMarket;
    }

    function feeChest() external view returns (uint256){
        return FeeChest;
    }
    
    function feeAddress() external view returns (address){
        return FeeAddress;
    }
    
}