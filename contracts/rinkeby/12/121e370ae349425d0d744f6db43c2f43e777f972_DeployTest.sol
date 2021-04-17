/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity 0.8.3;

contract Test {
    uint256 public a;
    constructor (uint256 _a) public {
        a = _a;
    }
}

contract DeployTest {
    function deploy(bytes32 _salt, uint256 param) public {
        new Test{salt: _salt}(param);
    }
}