/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity 0.6.2;

abstract contract Proxy {
    address private _IMPLEMENTATION;
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    // function _implementation() internal view virtual returns (address);
    function _implementation() internal view  returns (address impl) {
        return _IMPLEMENTATION;
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        // _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    // function _beforeFallback() internal virtual {}
    
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        // emit Upgraded(newImplementation);
    }
    
    function _setImplementation(address newImplementation) private {
        require(
            isContract(newImplementation),
            "UpgradeableProxy: new implementation is not a contract"
        );

        _IMPLEMENTATION = newImplementation;
    }

    function isContract(address c) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(c)
        }
        return size > 0;
    }
}


contract ProxyMock is Proxy {
    address private _ADMIN;
        
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }
    
    function admin() external view returns (address) {
        return _admin();
    }
    
    function implementation() external view  returns (address) {
        return _implementation();
    }
    
    function changeAdmin(address newAdmin) external ifAdmin {
        require(
            newAdmin != address(0),
            "TransparentUpgradeableProxy: new admin is the zero address"
        );
        // emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }
    
    function upgradeTo(address newImplementation) external ifAdmin {
        super._upgradeTo(newImplementation);
    }
    
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        ifAdmin
    {
        super._upgradeTo(newImplementation);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }
    
    function _admin() internal view returns (address adm) {
        return _ADMIN;
    }
    
    function _setAdmin(address newAdmin) private {
        _ADMIN = newAdmin;
    }
    
    // function _beforeFallback() internal virtual override {
    //     require(
    //         msg.sender != _admin(),
    //         "TransparentUpgradeableProxy: admin cannot fallback to proxy target"
    //     );
    //     super._beforeFallback();
    // }
    
    constructor(address _implementation) public {
         _upgradeTo(_implementation);
         _setAdmin(msg.sender);
    }
}