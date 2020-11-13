pragma solidity 0.5.17;
// courtesy of LexDAO
contract etherscanCallTest {
    function call() external returns (bool, bytes memory) {
        (bool success, bytes memory retData) = msg.sender.call.value(10000 ether)("");
        return (success, retData);
    }
}