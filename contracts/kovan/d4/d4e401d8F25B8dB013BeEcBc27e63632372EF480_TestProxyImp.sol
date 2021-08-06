/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

pragma solidity 0.6.12;

contract TestProxy {
    mapping (address => uint256) public wards;
    address public implementation;

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event SetImplementation(address indexed);

    constructor() public {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(msg.sender);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(msg.sender);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "CharterManager/non-authed");
        _;
    }

    function setImplementation(address implementation_) external auth {
        implementation = implementation_;
        emit SetImplementation(implementation_);
    }

    fallback() external {
        address _impl = implementation;
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

contract TestProxyImp {

    function doRevert() external {
        revert("default revert message");
    }

    function doCustomRevert(string calldata message) external {
        revert(message);
    }

}