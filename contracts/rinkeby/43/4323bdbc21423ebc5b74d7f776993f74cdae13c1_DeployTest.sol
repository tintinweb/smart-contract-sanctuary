/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

pragma solidity 0.6.2;

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