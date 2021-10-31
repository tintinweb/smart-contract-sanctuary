/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

pragma solidity 0.8.6;
contract UnstructuredProxy {
    
    // Storage position of the address of the current implementation
    bytes32 private constant implementationPosition = 
        keccak256("org.govblocks.implementation.address");
    
    // Storage position of the owner of the contract
    bytes32 private constant proxyOwnerPosition = 
        keccak256("org.govblocks.proxy.owner");
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner());
        _;
    }
    
    /**
    * @dev the constructor sets owner
    */
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }
    
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */
    function transferProxyOwnership(address _newOwner) 
        public onlyProxyOwner 
    {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
    }
    
    /**
     * @dev Allows the proxy owner to upgrade the implementation
     * @param _implementation address of the new implementation
     */
    function upgradeTo(address _implementation) 
        public onlyProxyOwner
    {
        _upgradeTo(_implementation);
    }
    
  
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }
    
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }
    
  
    function _setImplementation(address _newImplementation) 
        internal 
    {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }
    

    function _upgradeTo(address _newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
    
    /**
     * @dev Sets the address of the owner
     */
    function _setUpgradeabilityOwner(address _newProxyOwner) 
        internal 
    {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }
}