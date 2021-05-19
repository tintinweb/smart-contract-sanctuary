// SPDX-License-Identifier: MIT
pragma solidity ^0.5.3;

/// @title Proxy - GSVE  proxy contract allows to execute all transactions applying the code of a master contract and then burning a gas token.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
/// @author Gas Save Protocol - <GasSave.org>

interface IGasToken {
    /**
     * @dev return number of tokens freed up.
     */
    function freeFromUpTo(address from, uint256 value) external returns (uint256); 
}

/**
* @dev interface to allow gsve to be burned for upgrades
*/
interface IBeacon {
    function getAddressGastoken(address safe) external view returns(address);
    function getAddressGasTokenSaving(address safe) external view returns(uint256);
}

contract Proxy {

    // masterCopy always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal masterCopy;

    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    function () 
        external
        payable
    {
        uint256 gasStart = gasleft();
        uint256 returnDataLength;
        bool success;
        bytes memory returndata;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }

            //set returndata to the location of the free data pointer
            returndata := mload(0x40)
            calldatacopy(0, 0, calldatasize())
            success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)

            //copy the return data and then MOVE the free data pointer to avoid overwriting. Without this movement, the operation reverts.
            //ptr movement amount is probably overkill and wastes a few hundred gas for no reason, but better to be safe!
            returndatacopy(returndata, 0, returndatasize())
            returnDataLength:= returndatasize()
            mstore(0x40, add(0x40, add(0x200, mul(returndatasize(), 0x20)))) 
        }

        //work out how much gas we've spent so far
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        
        //if the gas amount is low, then don't burn anything and finish the proxy operation
        if(gasSpent < 48000){
            assembly{
                if eq(success, 0) { revert(returndata, returnDataLength) }
                return(returndata, returnDataLength)
            }
        }
        //if the operation has been expensive, then look at burning gas tokens
        else{
            //query the beacon to see what gas token the user want's to burn
            IBeacon beacon = IBeacon(0x1370CAf8181771871cb493DFDC312cdeD17a2de8);
            address gsveBeaconGastoken = beacon.getAddressGastoken(address(this));
            if(gsveBeaconGastoken == address(0)){
                assembly{
                    if eq(success, 0) { revert(returndata, returnDataLength) }
                    return(returndata, returnDataLength)
                }
            }
            else{
                uint256 gsveBeaconAmount = beacon.getAddressGasTokenSaving(gsveBeaconGastoken);
                gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
                IGasToken(gsveBeaconGastoken).freeFromUpTo(msg.sender,  (gasSpent + 16000) / gsveBeaconAmount);
                assembly{
                    if eq(success, 0) { revert(returndata, returnDataLength) }
                    return(returndata, returnDataLength)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.3;

import "./Proxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(Proxy proxy, address _mastercopy, bytes calldata initializer, uint256 saltNonce) external;
}

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <[email protected]>
/// @author Gas Save - <GasSave.org>
interface IProxy {
    function masterCopy() external view returns (address);
}

/**
* @dev interface to allow gsve to be burned for upgrades
*/
interface IGSVEToken {
    function burnFrom(address account, uint256 amount) external;
}

/**
* @dev interface to allow gsve to be burned for upgrades
*/
interface IGSVEBeacon {
    function initSafe(address owner, address safe) external;
}

/// @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
/// @author Stefan George - <[email protected]>
/// @author Gas Save - <GasSave.org>
contract ProxyFactory {
    address public GSVEToken;
    address public GSVEBeacon;
    event ProxyCreation(Proxy proxy);
    
    /// @dev sets the addresses of the GSVE token AND GSVE Beacon. Used in the creation process
    constructor (address _GSVEToken, address _GSVEBeacon) public {
        GSVEToken = _GSVEToken;
        GSVEBeacon = _GSVEBeacon;
    }
    

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param masterCopy Address of master copy.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(address masterCopy, bytes memory data)
        public
        returns (Proxy proxy)
    {
        proxy = new Proxy(masterCopy);
        if (data.length > 0)
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                if eq(call(gas, proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) { revert(0, 0) }
            }
        emit ProxyCreation(proxy);
    }

    /// @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(Proxy).runtimeCode;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(Proxy).creationCode;
    }

    /// @dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
    ///      This method is only meant as an utility to be called from other methods
    /// @param _mastercopy Address of master copy.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function deployProxyWithNonce(address _mastercopy, bytes memory initializer, uint256 saltNonce)
        internal
        returns (Proxy proxy)
    {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        bytes memory deploymentData = abi.encodePacked(type(Proxy).creationCode, uint256(_mastercopy));
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _mastercopy Address of master copy.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    /// BURNS GSVE IN THE PROCESS OF CREATING THE PROXY AND ADDS THE CREATED SAFE TO THE BEACON
    function createProxyWithNonce(address _mastercopy, bytes memory initializer, uint256 saltNonce)
        public
        returns (Proxy proxy)
    {
        IGSVEToken(GSVEToken).burnFrom(msg.sender, 50*10**18);
        proxy = deployProxyWithNonce(_mastercopy, initializer, saltNonce);
        if (initializer.length > 0)
            // solium-disable-next-line security/no-inline-assembly
            assembly {
                if eq(call(gas, proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) { revert(0,0) }
            }

        IGSVEBeacon(GSVEBeacon).initSafe(msg.sender, address(proxy));
        emit ProxyCreation(proxy);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}