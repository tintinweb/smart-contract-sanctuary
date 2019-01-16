contract MarmoProxy {
    function () external payable {
        assembly {
            calldatacopy(0, 0, calldatasize)
            let result := delegatecall(gas, 0x3618a379f2624f42c0a8c79aad8db9d24d6e0312, 0, calldatasize, 0, 0)
            returndatacopy(0, 0, returndatasize)
            if iszero(result) {
                revert(0, returndatasize)
            }
            return (0, returndatasize)
        }
    }
}