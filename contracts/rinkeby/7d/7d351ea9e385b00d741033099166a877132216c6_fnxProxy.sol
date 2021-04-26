/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// File: contracts\Proxy\fnxProxy.sol

pragma solidity =0.5.16;
/**
 * @title  fnxProxy Contract

 */
contract fnxProxy {
    bytes32 private constant implementPositon = keccak256("org.Finnexus.implementation.storage");
    bytes32 private constant versionPositon = keccak256("org.Finnexus.version.storage");
    bytes32 private constant proxyOwnerPosition  = keccak256("org.Finnexus.Owner.storage");
    event Upgraded(address indexed implementation,uint256 indexed version);
    constructor(address implementation_) public {
        // Creator of the contract is admin during initialization
        _setProxyOwner(msg.sender);
        _setImplementation(implementation_);
        (bool success, bytes memory returnData) = implementation_.delegatecall(abi.encodeWithSignature("implementationVersion()"));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        uint256 version_ = abi.decode(returnData, (uint256));
        _setVersion(version_);
        emit Upgraded(implementation_,version_);
        (success,) = implementation_.delegatecall(abi.encodeWithSignature("initialize()"));
        require(success);
    }
    /**
     * @dev Allows the current owner to transfer ownership
     * @param _newOwner The address to transfer ownership to
     */
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner 
    {
        require(_newOwner != address(0));
        _setProxyOwner(_newOwner);
    }
    function _setProxyOwner(address _newOwner) internal 
    {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newOwner)
        }
    }
    function _setVersion(uint256 version_) internal 
    {
        bytes32 position = versionPositon;
        assembly {
            sstore(position, version_)
        }
    }
    function version() public view returns(uint256 version_){
        bytes32 position = versionPositon;
        assembly {
            version_ := sload(position)
        }
    }
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }
    function proxyType() public pure returns (uint256){
        return 2;
    }
    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementPositon;
        assembly {
            impl := sload(position)
        }
    }
    function _setImplementation(address _newImplementation) internal 
    {
        bytes32 position = implementPositon;
        assembly {
            sstore(position, _newImplementation)
        }
    }
    function upgradeTo(address _newImplementation)public onlyProxyOwner{
        address currentImplementation = implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
        (bool success, bytes memory returnData) = _newImplementation.delegatecall(abi.encodeWithSignature("implementationVersion()"));
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize)
            }
        }
        uint256 version_ = abi.decode(returnData, (uint256));
        require (version_>version(),"upgrade version number must greater than current version");
        _setVersion(version_);
        emit Upgraded(_newImplementation,version_);
        (success,) = _newImplementation.delegatecall(abi.encodeWithSignature("update()"));
        require(success);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner(),"proxyOwner: caller is not the proxy owner");
        _;
    }
    function () payable external {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
        let ptr := mload(0x40)
        calldatacopy(ptr, 0, calldatasize)
        let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
        let size := returndatasize
        returndatacopy(ptr, 0, size)

        switch result
        case 0 { revert(ptr, size) }
        default { return(ptr, size) }
        }
    }
}