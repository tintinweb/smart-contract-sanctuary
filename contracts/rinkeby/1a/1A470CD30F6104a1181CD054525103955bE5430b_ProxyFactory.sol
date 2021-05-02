/**
 *Submitted for verification at Etherscan.io on 2021-05-01
*/

/***
* Shoutouts:
*
* Bytecode origin https://www.reddit.com/r/ethereum/comments/6ic49q/any_assembly_programmers_willing_to_write_a/dj5ceuw/
* Modified version of Vitalik's https://www.reddit.com/r/ethereum/comments/6c1jui/delegatecall_forwarders_how_to_save_5098_on/
* Credits to Jorge Izquierdo (@izqui) for coming up with this design here: https://gist.github.com/izqui/7f904443e6d19c1ab52ec7f5ad46b3a8
* Credits to Stefan George (@Georgi87) for inspiration for many of the improvements from Gnosis Safe: https://github.com/gnosis/gnosis-safe-contracts
*
* This version has many improvements over the original @izqui's library like using REVERT instead of THROWing on failed calls.
* It also implements the awesome design pattern for initializing code as seen in Gnosis Safe Factory: https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/ProxyFactory.sol
* but unlike this last one it doesn't require that you waste storage on both the proxy and the proxied contracts (v. https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/Proxy.sol#L8 & https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol#L14)
*
*
* v0.0.2
* The proxy is now only 60 bytes long in total. Constructor included.
* No functionalities were added. The change was just to make the proxy leaner.
*
* v0.0.3
* Thanks @dacarley for noticing the incorrect check for the subsequent call to the proxy. 🙌
* Note: I'm creating a new version of this that doesn't need that one call.
*       Will add tests and put this in its own repository soon™.
*
* v0.0.4
* All the merit in this fix + update of the factory is @dacarley 's. 🙌
* Thank you! 😄
*
* Potential updates can be found at https://gist.github.com/GNSPS/ba7b88565c947cfd781d44cf469c2ddb
*
***/

pragma solidity ^0.5.0;


/* solhint-disable no-inline-assembly, indent, state-visibility, avoid-low-level-calls */

contract ProxyFactory {

    constructor() public {}

    event ProxyDeployed(address proxyAddress, address targetAddress);

    function createProxy(address _target, bytes memory _data)
        public
        payable
        returns (address proxyContract)
    {
        proxyContract = createProxyImpl(_target, _data);
        emit ProxyDeployed(proxyContract, _target);
    }

    function createProxyImpl(address _target, bytes memory _data)
        internal
        returns (address proxyContract)
    {
        assembly {
            let contractCode := mload(0x40) // Find empty storage location using "free memory pointer"

            mstore(add(contractCode, 0x0b), _target) // Add target address, with a 11 bytes [i.e. 23 - (32 - 20)] offset to later accomodate first part of the bytecode
            mstore(sub(contractCode, 0x09), 0x000000000000000000603160008181600b9039f3600080808080368092803773) // First part of the bytecode, shifted left by 9 bytes, overwrites left padding of target address
            mstore(add(contractCode, 0x2b), 0x5af43d828181803e808314602f57f35bfd000000000000000000000000000000) // Final part of bytecode, offset by 43 bytes

            proxyContract := create(0, contractCode, 60) // total length 60 bytes
            if iszero(extcodesize(proxyContract)) {
                revert(0, 0)
            }

            // check if the _data.length > 0 and if it is forward it to the newly created contract
            let dataLength := mload(_data)
            if iszero(iszero(dataLength)) {
                if iszero(call(gas, proxyContract, callvalue, add(_data, 0x20), dataLength, 0, 0)) {
                    revert(0, 0)
                }
            }
        }
    }
}