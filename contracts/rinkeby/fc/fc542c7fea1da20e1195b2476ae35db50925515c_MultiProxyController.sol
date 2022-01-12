/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File contracts/solidity/testing/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File contracts/solidity/util/Ownable.sol



pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/solidity/interface/IAdminUpgradeabilityProxy.sol



pragma solidity ^0.8.0;

interface IAdminUpgradeabilityProxy {
    // Read functions.
    function admin() external view returns (address);
    function implementation() external view returns (address);

    // Write functions.
    function changeAdmin(address newAdmin) external;
    function upgradeTo(address newImplementation) external;
}


// File contracts/solidity/proxy/MultiProxyController.sol



pragma solidity ^0.8.0;


contract MultiProxyController is Ownable {
    struct Proxy {
        string name;
        IAdminUpgradeabilityProxy proxy;
        address impl;
    }

    Proxy[] private proxies;

    event ProxyAdded(string name, address proxy);
    event ProxyRemoved(uint256 index);
    event ProxyAdminChanged(uint256 index, address newAdmin);

    constructor(string[] memory _names, address[] memory _proxies) Ownable() {
        uint256 length = _proxies.length;
        require(_names.length == length, "Not equal length");
        for (uint256 i; i < length; i++) {
            addProxy(_names[i], _proxies[i]);
        } 
    }

    function upgradeProxyTo(uint256 index, address newImpl) public onlyOwner {
        require(index < proxies.length, "Out of bounds");
        proxies[index].proxy.upgradeTo(newImpl);
    }

    function changeProxyAdmin(uint256 index, address newAdmin) public onlyOwner {
        require(index < proxies.length, "Out of bounds");
        proxies[index].proxy.changeAdmin(newAdmin);
        emit ProxyAdminChanged(index, newAdmin);
    }

    function addProxy(string memory name, address proxy) public onlyOwner {
        IAdminUpgradeabilityProxy _proxy = IAdminUpgradeabilityProxy(proxy);
        proxies.push(Proxy(name, _proxy, address(0)));
        emit ProxyAdded(name, proxy);
    }

    function removeProxy(uint256 index) public onlyOwner {
        // Preferably want to maintain order to reduce chance of mistake.
        uint256 length = proxies.length;
        if (index >= length) return;

        for (uint i = index; i < length-1; ++i) {
            proxies[i] = proxies[i+1];
        }
        proxies.pop();
        emit ProxyRemoved(index);
    }

    function changeAllAdmins(address newAdmin) public onlyOwner {
        uint256 length = proxies.length;
        for (uint256 i; i < length; ++i) {
            changeProxyAdmin(i, newAdmin);
        }
    }

    function changeAllAdmins(uint256 start, uint256 count, address newAdmin) public onlyOwner {
        require(start + count <= proxies.length, "Out of bounds");
        for (uint256 i = start; i < start + count; ++i) {
            changeProxyAdmin(i, newAdmin);
        }
    }

    function getName(uint256 index) public view returns (string memory) {
        return proxies[index].name;
    }

    function getAdmin(uint256 index) public view returns (address) {
        return proxies[index].proxy.admin();
    }

    function getImpl(uint256 index) public view returns(address) {
        return proxies[index].proxy.implementation();
    }

    function getAllProxiesInfo() public view returns (string[] memory) {
        uint256 length = proxies.length;
        string[] memory proxyInfos = new string[](length);
        for (uint256 i; i < length; ++i) {
            Proxy memory _proxy = proxies[i];
            proxyInfos[i] = string(abi.encodePacked(uint2str(i), ": ", _proxy.name));
        }
        return proxyInfos;
    }

    function getAllProxies() public view returns (address[] memory) {
        uint256 length = proxies.length;
        address[] memory proxyInfos = new address[](length);
        for (uint256 i; i < length; ++i) {
            proxyInfos[i] = address(proxies[i].proxy);
        }
        return proxyInfos;
    }
    
    function getAllImpls() public view returns (address[] memory) {
        uint256 length = proxies.length;
        address[] memory proxyInfos = new address[](length);
        for (uint256 i; i < length; ++i) {
            proxyInfos[i] = address(proxies[i].proxy.implementation());
        }
        return proxyInfos;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}