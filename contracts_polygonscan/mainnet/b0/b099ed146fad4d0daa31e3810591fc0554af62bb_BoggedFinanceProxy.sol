/**
 *Submitted for verification at polygonscan.com on 2021-12-13
*/

//SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

/**
 * $$$$$$$\                                                $$\     $$$$$$$$\ $$\                                                   
 * $$  __$$\                                               $$ |    $$  _____|\__|                                                  
 * $$ |  $$ | $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$$ |    $$ |      $$\ $$$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$\  $$$$$$\  
 * $$$$$$$\ |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$ |    $$$$$\    $$ |$$  __$$\  \____$$\ $$  __$$\ $$  _____|$$  __$$\ 
 * $$  __$$\ $$ /  $$ |$$ /  $$ |$$ /  $$ |$$$$$$$$ |$$ /  $$ |    $$  __|   $$ |$$ |  $$ | $$$$$$$ |$$ |  $$ |$$ /      $$$$$$$$ |
 * $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$   ____|$$ |  $$ |    $$ |      $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |      $$   ____|
 * $$$$$$$  |\$$$$$$  |\$$$$$$$ |\$$$$$$$ |\$$$$$$$\ \$$$$$$$ |$$\ $$ |      $$ |$$ |  $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$\ \$$$$$$$\ 
 * \_______/  \______/  \____$$ | \____$$ | \_______| \_______|\__|\__|      \__|\__|  \__| \_______|\__|  \__| \_______| \_______|
 *                     $$\   $$ |$$\   $$ |                                                                                        
 *                     \$$$$$$  |\$$$$$$  |                                                                                        
 *                      \______/  \______/
 * 
 * https://bogged.finance/
 */

library LibCoreStorage {
    struct CoreStorage {
        address owner;
        bool paused;
        bool guardReentrancy;
        mapping (bytes4 => address) implementations;
    }
    function coreStorage() internal pure returns (CoreStorage storage cs) {
        bytes32 location = keccak256("bogged.proxy.core");
        assembly { cs.slot := location }
    }
}

abstract contract ProxyOwnable {
    constructor(){
        LibCoreStorage.coreStorage().owner = msg.sender;
    }
    
    modifier onlyOwner {
        require(msg.sender == getOwner(), "BOGProxy: !OWNER");
        _;
    }

    function getOwner() public view returns (address) {
        return LibCoreStorage.coreStorage().owner;
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        LibCoreStorage.coreStorage().owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }
    
    event OwnershipTransferred(address newOwner);
}

abstract contract ProxyPausable is ProxyOwnable {
    modifier notPaused {
        require(!paused(), "BOGProxy: PAUSED");
        _;
    }
    
    modifier whenPaused {
        require(paused(), "BOGProxy: !PAUSED");
        _;
    }
    
    function paused() public view returns (bool) {
        return LibCoreStorage.coreStorage().paused;
    }
    
    function pause() external notPaused onlyOwner {
        LibCoreStorage.coreStorage().paused = true;
        emit Paused();
    }
    
    function unpause() external whenPaused onlyOwner {
        LibCoreStorage.coreStorage().paused = false;
        emit Unpaused();
    }
    
    event Paused();
    event Unpaused();
}

abstract contract ProxyReentrancyGuard {
    modifier nonReentrant {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        require(!cs.guardReentrancy, "BOGProxy: REENTRANCY_DISALLOWED");
        cs.guardReentrancy = true;
        _;
        cs.guardReentrancy = false;
    }
}

contract BoggedFinanceProxy is ProxyOwnable, ProxyPausable, ProxyReentrancyGuard {
    fallback() external payable notPaused {
        address impl = getImplementation(msg.sig);
        require(impl != address(0), "BOGProxy: INVALID_SELECTOR");
        (bool success, bytes memory data) = impl.delegatecall(msg.data);
        require(success, _getRevertMsg(data));
        assembly { return(add(data, 32), mload(data)) }
    }
    
    receive() external payable { }
    
    function getImplementation(bytes4 selector) public view returns (address) {
        return LibCoreStorage.coreStorage().implementations[selector];
    }
    
    function setImplementation(bytes4 selector, address implementation, bool initialize) external onlyOwner {
        require(implementation == address(0) || _isContract(implementation), "BOGProxy: INVALID_IMPLEMENTAION");
        LibCoreStorage.coreStorage().implementations[selector] = implementation;
        if(initialize){
            (bool success, ) = implementation.delegatecall(abi.encode(bytes4(keccak256("initialize()"))));
            require(success, "BOGProxy: INITIALIZATION_FAILED");
        }
        emit ImplementationUpdated(selector, implementation);
    }
    
    function _getRevertMsg(bytes memory data) internal pure returns (string memory reason) {
        uint l = data.length;
        if (l < 68) return "";
        uint t;
        assembly {
            data := add(data, 4)
            t := mload(data)
            mstore(data, sub (l, 4))
        }
        reason = abi.decode(data, (string));
        assembly {
            mstore(data, t)
        }
    }
    
    function _isContract(address adr) internal view returns (bool){
        uint32 size;
        assembly { size := extcodesize(adr) }
        return (size > 0);
    }

    event ImplementationUpdated(bytes4 selector, address delegate);
}