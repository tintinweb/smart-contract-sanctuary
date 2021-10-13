// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract TestContract {

    address private owner;
    
    struct TestStruct {
        bytes8 bytesMember;
        bool boolMember;
    }
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function pay(int amount) external payable {
    }
    
    function payWithUnnamedParam(int, bool confirm) external payable {
    }
    
    function privateFunction() private {
    }
    
    function functionWithLotsOfParams(string calldata stringParam, address[2] calldata fixedSizeAddressArrayParam, int[][] calldata int2DArrayParam, TestStruct calldata tupleParam, function(bytes memory) external functionParam) external {
        
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}