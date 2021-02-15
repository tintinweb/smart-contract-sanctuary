// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


contract CloneFactory {

    event CloneContract(address cloner, address source, address target);

    // most recent cloned contract address using `clone`
    address public cloned;
    // controller of this factory contract
    address public controller;

    constructor () {
        controller = msg.sender;
    }

    function setController(address newController) public {
        require(msg.sender == controller, "CloneFactory: set controller caller is not current controller");
        controller = newController;
    }

    function clone(address source) public returns (address target) {
        require(msg.sender == controller, "CloneFactory: only controller can call clone");
        bytes20 sourceBytes = bytes20(source);
        assembly {
            let c := mload(0x40)
            mstore(c, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(c, 0x14), sourceBytes)
            mstore(add(c, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            target := create(0, c, 0x37)
        }
        cloned = target;
        emit CloneContract(msg.sender, source, target);
    }

}