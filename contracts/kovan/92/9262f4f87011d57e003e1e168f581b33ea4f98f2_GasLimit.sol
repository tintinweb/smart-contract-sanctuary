/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

contract GasLimit {
    function gasLimit(uint256 c) public view returns (uint256) {
        unchecked {
            uint256 x = 2;
            for (uint256 i=1; i < c; i++) {
                x = x ** 112068002364947537014802701075021898324313602097276044616656536065636132166093;
            }
            return x;
        }
    }
    
    function gasLimit2(uint256 c) public view returns (uint256) {
        unchecked {
            uint256 x = 0;
            for (uint256 i=1; i < c * 1000; i++) {
                x = x + i;
            }
            return x;
        }
    }
}