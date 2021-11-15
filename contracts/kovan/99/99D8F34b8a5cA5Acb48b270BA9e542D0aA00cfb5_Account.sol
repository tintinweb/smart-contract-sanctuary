pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Account {
    mapping (address => bool) private auth;
    address public constant owner = 0x2b02AAd6f1694E7D9c934B7b3Ec444541286cF0f;

    receive() external payable {}

    function enable(address user) public {
        require(msg.sender == address(this), "not-self-index");
        require(user != address(0), "not-valid");
        require(!auth[user], "already-enabled");
        auth[user] = true;
    }

    function disable(address user) public {
        require(msg.sender == address(this), "not-self");
        require(user != address(0), "not-valid");
        require(auth[user], "already-disabled");
        delete auth[user];
    }

    function isAuth(address user) public view returns (bool) {
        return auth[user];
    }
    
    function spell(address _target, bytes memory _data) internal {
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
    
    function cast(address[] calldata _targets, bytes[] calldata _datas) external payable {
        require(isAuth(msg.sender) || msg.sender == owner, "permission-denied");
        for (uint i = 0; i < _targets.length; i++) {
            spell(_targets[i], _datas[i]);
        }
    }
}

