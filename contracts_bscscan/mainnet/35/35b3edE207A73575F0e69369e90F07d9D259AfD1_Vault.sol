// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Vault {

    address public immutable pool;

    constructor (address pool_) {
        pool = pool_;
    }

    fallback() external payable {
        _delegate();
    }

    receive() external payable {

    }

    function _delegate() internal {
        address imp = IPool(pool).vaultImplementation();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}

interface IPool {
    function vaultImplementation() external view returns (address);
}