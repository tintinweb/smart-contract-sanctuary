/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity 0.5.16;

contract Proxy {
    bytes32 public constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 public constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    /**
     * @dev Fallback function.
     * Implemented entirely in `_fallback`.
     */
    function() payable external {
        _fallback();
    }


    function _getSlot(bytes32 slot) internal view returns (address impl);

    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param implementation Address to delegate.
     */
    function _delegate(address implementation) internal {
        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize)

        // Call the implementation.
        // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize)

            switch result
            // delegatecall returns 0 on error.
            case 0 {revert(0, returndatasize)}
            default {return (0, returndatasize)}
        }
    }

    /**
     * @dev Function that is run as the first thing in the fallback function.
     * Can be redefined in derived contracts to add functionality.
     * Redefinitions must call super._willFallback().
     */
    function _willFallback() internal {
    }

    /**
     * @dev fallback implementation.
     * Extracted to enable manual triggering.
     */
    function _fallback() internal {
        _willFallback();
        _delegate(_getSlot(IMPLEMENTATION_SLOT));
    }
}

library OpenZeppelinUpgradesAddress {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

contract BaseUpgradeabilityProxy is Proxy {
    /**
     * @dev Emitted when the implementation is upgraded.
     * @param implementation Address of the new implementation.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */

    /**
     * @dev Returns the current implementation.
     * @return Address of the current implementation
     */
    function _getSlot(bytes32 slot) internal view returns (address impl) {
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * @param newImplementation Address of the new implementation.
     */
    function _upgradeTo(address newImplementation) internal {
        _setSlot(IMPLEMENTATION_SLOT, newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation address of the proxy.
     * @param newImplementation Address of the new implementation.
     */
    function _setSlot(bytes32 slot, address newImplementation) internal {
        assembly {
            sstore(slot, newImplementation)
        }
    }


}


contract UpgradeableProxy is BaseUpgradeabilityProxy {
    constructor(address _implementation) public {
        _setSlot(ADMIN_SLOT, msg.sender);
        _setSlot(IMPLEMENTATION_SLOT, _implementation);
    }
    modifier onlyGovernance(){
        require(msg.sender == _getSlot(ADMIN_SLOT), "VP0");
        _;
    }

    /**
    * The main logic. If the timer has elapsed and there is a schedule upgrade,
    * the governance can upgrade the vault
    */
    function upgrade(address _implementation) external onlyGovernance {
        _upgradeTo(_implementation);
    }

    function implementation() external view returns (address) {
        return _getSlot(IMPLEMENTATION_SLOT);
    }

    function setGovernance(address _governance) external onlyGovernance {
        _setSlot(ADMIN_SLOT, _governance);
    }
}