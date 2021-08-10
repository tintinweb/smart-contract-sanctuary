// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FeeCollector.sol"; 
import "./OwnedUpgradeabilityProxy.sol"; 
import "./Ownable.sol"; 
import "./Create2.sol";
 
contract FeeCollectorDeployer is Ownable {

    using Create2 for uint256;

    /** @dev when deploying*/
    /** Step 1: Deploy Proxy */
    /** Step 2: Deploy Fee Collector */
    /** Step 3: Call upgradeToAndCall from Proxy, with initialize function */

    function getFeeCollectorBytecode() public pure returns (bytes memory) {
        bytes memory bytecode = type(FeeCollector).creationCode;
        return abi.encodePacked(bytecode);
    }

    function getProxyBytecode() public pure returns (bytes memory) {
        bytes memory bytecode = type(OwnedUpgradeabilityProxy).creationCode;
        return abi.encodePacked(bytecode);
    }

    /** @param bytecode  can be retrieved by calling get___Bytecode()*/
    /** @param _salt is a random number used to create an address */
    function getAddress(bytes memory bytecode, uint _salt) public view returns (address) {
        return _salt.getAddress(bytecode, address(this));
    }

    /** @param bytecode  can be retrieved by calling get___Bytecode()*/
    /** @param _salt is a random number used to create an address */
    function deployPrecomputed(bytes memory bytecode, uint _salt) public {
        _salt.deployContract(bytecode);
    }

    /** @dev this function is used to change ownership of upgrdability contract */
    /** @param _newOwner address of new proxy owner */
    /** @param _proxy address  */
    function setProxyOwner(address _newOwner, address _proxy) external onlyOwner {
        require(_proxy != address(0), "proxy address cannot be 0");
        require(_newOwner != address(0), "new owner address cannot be 0");
        OwnedUpgradeabilityProxy proxy = OwnedUpgradeabilityProxy(payable(_proxy));
        proxy.transferProxyOwnership(_newOwner);
    }
}