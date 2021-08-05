/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

interface ICurveV2 {
    function price_oracle(uint256) external view returns (uint256);
}

contract EMAPriceOracle {
    address public _CURVE_V2_; 
    int public _ORDER_;
    
    
    function getPrice() public view returns(uint256) {
        uint256 originPrice = ICurveV2(0x80466c64868E1ab14a1Ddf27A676C3fcBE638Fe5).price_oracle(1);
        return originPrice/10**12;
    }
    
}