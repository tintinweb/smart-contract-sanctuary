/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

contract SafeCastLib2 {
    function to32(uint256 x) public pure returns (uint32 y) {
        require(x <= type(uint32).max);

        y = uint32(x);
    }
}