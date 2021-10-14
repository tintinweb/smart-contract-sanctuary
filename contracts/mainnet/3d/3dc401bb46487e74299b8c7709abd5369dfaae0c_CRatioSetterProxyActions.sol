/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity 0.6.7;

abstract contract CRatioSetterLike {
     function setDefaultCRatio(bytes32, uint256) external virtual;
     function setMinDesiredCollateralizationRatio(bytes32, uint256) external virtual;
    
}

contract CRatioSetterProxyActions {
    
    function setDefaultCRatio(address target, bytes32 collateral, uint val) public {
        CRatioSetterLike(target).setDefaultCRatio(collateral,val);
    }    
    
    function setMinDesiredCollateralizationRatio(address target, bytes32 collateral, uint val) public {
        CRatioSetterLike(target).setMinDesiredCollateralizationRatio(collateral,val);
    }        
    
    function setBothCRatios(address target, bytes32 collateral, uint val) public {
        CRatioSetterLike(target).setDefaultCRatio(collateral,val);
        CRatioSetterLike(target).setMinDesiredCollateralizationRatio(collateral,val);
    }            
}