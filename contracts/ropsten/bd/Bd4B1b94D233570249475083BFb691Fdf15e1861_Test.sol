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
    address constant public usdt = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
    
    function getDecimals8() external returns (uint8 decimals) {
        return Deci8(usdt).decimals();
    }
    
    function getDecimals256() external returns (uint8 decimals) {
        return uint8(Deci256(usdt).decimals());
    }
    
    function useDecimals8() external returns (bool) {
        uint8 d = this.getDecimals8();
        state = 123 * (10 ** (d + 1));
        return true;
    }
    
    function useDecimals256() external returns (bool) {
        uint8 d = this.getDecimals256();
        state = 123 * (10 ** (d + 1));
        return true;
    }
}