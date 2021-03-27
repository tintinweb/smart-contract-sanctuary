/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity 0.5.17;


// SPDX-License-Identifier: MIT
interface IProxyAdmin {
    function getProxyImplementation(address proxy) external view returns (address);
    function isOwner() external view returns (bool);
    function owner() external view returns (address);
    function getProxyAdmin(address proxy) external view returns (address);

    function changeProxyAdmin(address proxy, address newAdmin) external;
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) external payable;
    function upgrade(address proxy, address implementation) external;
    function transferOwnership(address newOwner) external;
}

interface IAdminUpgradeabilityProxy {
    function changeAdmin(address newAdmin) external;
}

contract ProxyAdminRelayer {
    address public multiSig;
    address public upgrader;
    address public proxyAdmin;

    constructor(address _proxyAdmin, address _multiSig) public {
        proxyAdmin = _proxyAdmin;
        multiSig = _multiSig;
        upgrader = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the multiSig.
     */
    modifier onlyMultiSig() {
        require(isMultiSig());
        _;
    }

    modifier onlyUpgrader() {
        require(msg.sender == upgrader, "require upgrader");
        _;
    }

    /**
     * @return true if `msg.sender` is the multiSig of the contract.
     */
    function isMultiSig() public view returns (bool) {
        return msg.sender == multiSig;
    }

    /**
     * @dev Allows the current upgrader to transfer control of the contract to a newUpgrader.
     * @param newUpgrader The address to transfer upgradership to.
     */
    function transferUpgrader(address newUpgrader) public onlyMultiSig {
        upgrader = newUpgrader;
    }

    function setProxyAdmin(address newProxyAdmin) public onlyMultiSig {
        proxyAdmin = newProxyAdmin;
    }

    /**
     * @dev Allows the current multiSig to transfer control of the contract to a multiSig.
     * @param _multiSig The address to transfer multiSig to.
     */
    function transferMultiSig(address _multiSig) public onlyMultiSig {
        multiSig = _multiSig;
    }

    function getProxyImplementation(address proxy) external view returns (address) {
        return IProxyAdmin(proxyAdmin).getProxyImplementation(proxy);
    }

    function isOwner() external view returns (bool) {
        return IProxyAdmin(proxyAdmin).isOwner();
    }

    function owner() external view returns (address) {
        return IProxyAdmin(proxyAdmin).owner();
    }

    function getProxyAdmin(address proxy) external view returns (address) {
        return IProxyAdmin(proxyAdmin).getProxyAdmin(proxy);
    }

    function changeProxyAdmin(address proxy, address newAdmin) external onlyMultiSig {
        return IProxyAdmin(proxyAdmin).changeProxyAdmin(proxy, newAdmin);
    }
    
    function upgradeAndCall(address proxy, address implementation, bytes calldata data) external payable onlyUpgrader{
        return IProxyAdmin(proxyAdmin).upgradeAndCall.value(msg.value)(proxy, implementation, data);
    }

    function upgrade(address proxy, address implementation) external onlyUpgrader {
        return IProxyAdmin(proxyAdmin).upgrade(proxy, implementation);
    }

    function transferOwnership(address newOwner) external onlyMultiSig {
        return IProxyAdmin(proxyAdmin).transferOwnership(newOwner);
    }
    
    // 防止使用SDK新建合约时，未填入正确的proxyAdmin地址，此方法用于修正
    // Prevent creating a new contract with the SDK by not filling in the correct ProxyAdmin address.
    // This method is used to fix this
    function fixProxyAdmin(address proxy, address originalProxyAdmin) external onlyMultiSig {
        IAdminUpgradeabilityProxy(proxy).changeAdmin(originalProxyAdmin);
    }
}