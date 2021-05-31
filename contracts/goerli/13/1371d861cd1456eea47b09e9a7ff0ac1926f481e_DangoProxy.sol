/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

contract DangoProxy {
    address public immutable owner;
    mapping(address => bool) public auth;

    constructor(address _owner) {
        owner = _owner;
        auth[_owner] = true;
    }

    receive() external payable {}

    modifier isAuth {
        require(auth[msg.sender] || msg.sender == address(this), "permission-denied");
        _;
    }

    function addAuth(address _auth) public isAuth {
        require(!auth[_auth], "already-auth");
        auth[_auth] = true;
    }

    function removeAuth(address _auth) public isAuth {
        require(auth[_auth], "not-auth");
        delete auth[_auth];
    }

    function _execute(address _target, bytes memory _data) internal {
        require(_target != address(0), "target-invalid");

        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)

            switch iszero(succeeded)
                case 1 {
                    // throw if delegatecall failed
                    let size := returndatasize()
                    returndatacopy(0x00, 0x00, size)
                    revert(0x00, size)
                }
        }
    }

    function execute(address _target, bytes memory _data) public isAuth payable {
        _execute(_target, _data);
    }

    function multiExecute(address[] memory _targets, bytes[] memory _datas) public isAuth payable {
        require(_targets.length == _datas.length, "data-mismatch");
        for(uint i = 0; i < _targets.length; i++) {
            _execute(_targets[i], _datas[i]);
        }
    }
}