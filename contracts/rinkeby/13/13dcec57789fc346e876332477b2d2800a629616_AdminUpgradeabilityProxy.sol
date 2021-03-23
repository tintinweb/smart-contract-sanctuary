pragma solidity ^0.4.24;

import './UpgradeabilityProxy.sol';

/**
 * @title AdminUpgradeabilityProxy
 *
 * @dev This contract combines an upgradeability proxy with an authorization mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the `ifAdmin` modifier.
 * See ethereum/solidity#3864 for a Solidity feature proposal that would enable this to be done automatically.
 */
contract AdminUpgradeabilityProxy is UpgradeabilityProxy {
    /**
     * @dev Event emitted whenever the administration has been transferred.
     *
     * @param previousAdmin Address of the previous admin.
     * @param newAdmin Address of the new admin.
     *
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "speedProp20210323.proxy.admin", and is validated in the constructor.
     */
    bytes32 private constant ADMIN_SLOT = 0xd44beb5edcc3cd24234d3a3c7e6e0c32ab52862bb95767cf901b1bf4fee55a91;
    /**
     * @dev Modifier to check whether the `msg.sender` is the admin.
     * If it is, it will run the function. Otherwise, it will delegate the call to the implementation.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Contract constructor.
     * @dev It sets the `msg.sender` as the proxy administrator.
     *
     * @param _implementation address of the initial implementation.
     */
    constructor(address _implementation) UpgradeabilityProxy(_implementation) public {
        assert(ADMIN_SLOT == keccak256("speedProp20210323.proxy.admin"));

        _setAdmin(msg.sender);
    }
	
/**
Just for sage to defferentiate between ABIs
**/
/*    function contProxyVersion20210317013() external view returns (string) {
        return "20210317013.proxy.0001" ;
    }
    */
    function getAdminSlot() external view ifAdmin returns (bytes32) {
        return ADMIN_SLOT ;
    }


    /**
     * @return The address of the proxy admin.
     */
    function admin() external view ifAdmin returns (address) {
        return _admin();
    }

    /**
     * @return The address of the implementation.
     */
    function implementation() external view ifAdmin returns (address) {
        return _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     * Only the current admin can call this function.
     *
     * @param newAdmin Address to transfer proxy administration to.
     */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy.
     * Only the admin can call this function.
     *
     * @param newImplementation Address of the new implementation.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the backing implementation of the proxy and call a function on the new implementation.
     * This is useful to initialize the proxied contract.
     *
     * The given `data` should include the signature and parameters of the function to be called.
     * See https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding
     *
     * @param newImplementation Address of the new implementation.
     * @param data Data to send as msg.data in the low level call.
     */
    function upgradeToAndCall(address newImplementation, bytes data) payable external ifAdmin {
        _upgradeTo(newImplementation);
        require(address(this).call.value(msg.value)(data));
    }

    /**
     * @return The admin slot.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Sets the address of the proxy admin.
     *
     * @param newAdmin Address of the new proxy admin.
     */
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;

        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Only fall back when the sender is not the admin.
     */
    function _willFallback() internal {
        require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
        super._willFallback();
    }
}