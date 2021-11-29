/**
 *Submitted for verification at Etherscan.io on 2021-11-29
*/

contract SimpleStorage {
    uint storedData;
    function set(uint x) public {
        storedData = x;
    }
    function get() public view returns (uint) {
        return storedData;
    }
}