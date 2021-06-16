/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/
pragma solidity ^0.8.0;

/// @title Implement the public auction
/// @author HUST Blockchain Research Group
///  Note: Blockchain course assignment code, Group ID 7
contract Proxy {
    // Contract deployer
    address private owner;
    // Current address
    address private _implementation;
    
    // Triggered when the contract is upgraded
    event Upgraded(address indexed implementation);

    /// @dev Initialize using constructor
    constructor() {
        owner = msg.sender;
    }
    
    /// @dev Only contract deployers can upgrade
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    /// @dev Get a new contract address
    function implementation() public view returns (address) {
        return _implementation;
    }
    /// @dev Upgrade to an address
    function upgradeTo(address impl) public onlyOwner {
        require(impl != address(0), "Cannot upgrade to invalid address");
        require(impl != _implementation, "Cannot upgrade to the same implementation");
        _implementation = impl;
        emit Upgraded(impl);
    }
    
    /// @dev The fallback function
    fallback() external payable {
        address _impl = _implementation;
        require(_impl != address(0), "implementation contract not set");
        
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}