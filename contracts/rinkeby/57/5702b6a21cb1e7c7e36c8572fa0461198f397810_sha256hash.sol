pragma solidity ^0.4.26;
import './verifier.sol';
contract sha256hash is Verifier {
    bool public success = false;
    function sha256hashTest(
        uint[2] a,
        uint[2] a_p,
        uint[2][2] b,
        uint[2] b_p,
        uint[2] c,
        uint[2] c_p,
        uint[2] h,
        uint[2] k,
        uint[1] input) public {
        // Verifiy the proof
        success = verifyTx(a, a_p, b, b_p, c, c_p, h, k, input);
    }
    function get() public view returns (bool) {
        return success;
    }
}