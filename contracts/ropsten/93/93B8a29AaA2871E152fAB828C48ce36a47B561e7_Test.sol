/**
 *Submitted for verification at Etherscan.io on 2021-09-18
*/

interface Deci8 {
  function decimals() external view returns (uint8);
}

interface Deci256 {
  function decimals() external view returns (uint256);
}

contract Test {
    uint256 public state = 0;
    
    function getDecimals8(address target) external view returns (uint8 decimals) {
        return Deci8(target).decimals();
    }
    
    function getDecimals256(address target) external view returns (uint8 decimals) {
        return uint8(Deci256(target).decimals());
    }
    
    function useDecimals8( address target, uint256 val ) external returns (bool) {
        uint8 d = Deci8(target).decimals();
        state = val * (10 ** (d + 1));
        if( d < 1000 ) {
            state += 1;
        }
        return true;
    }
    
    function useDecimals256( address target, uint256 val ) external returns (bool) {
        uint8 d = uint8(Deci256(target).decimals());
        state = val * (10 ** (d + 1));
        return true;
    }
}