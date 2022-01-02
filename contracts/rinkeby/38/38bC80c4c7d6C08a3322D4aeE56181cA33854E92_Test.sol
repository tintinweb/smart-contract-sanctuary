/**
 *Submitted for verification at Etherscan.io on 2022-01-02
*/

contract Test{
    function getSelector(string calldata _func) external pure returns (bytes4) {
    return bytes4(keccak256(bytes(_func)));
    }

}