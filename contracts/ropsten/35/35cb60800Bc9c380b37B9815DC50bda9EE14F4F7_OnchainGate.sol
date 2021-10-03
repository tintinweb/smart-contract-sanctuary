// contracts/OnchainGate.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces

interface IOffchainZombie {
    function ownerOf(uint token_id_) external returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IOnchainZombie {
    function claimMouse(address claimer) external;
    function claimMice(address claimer, uint8 num) external;
}

contract OnchainGate {
    // Mappings

    mapping(uint => address) offchainIdToOwner;

    // Addresses

    address offChainAddress;
    address onChainAddress;
    address _owner;

    // Constructor

    constructor() {
        _owner = msg.sender;
    }

    // Claim functions

    /** 
     * @dev Claim onchain zombiemouse for the offchain
     * @param offchain_uid_ Offhchain mouse ID used to claim
     */
    function claimOnchainMouse(uint offchain_uid_) external {
        //require(offchain.ownerOf(offchain_uid_)==msg.sender, "You are not the mice owner");
        offchainIdToOwner[offchain_uid_]=msg.sender;
        //offchain.transferFrom(msg.sender, address(this), offchain_uid_);
        IOnchainZombie(onChainAddress).claimMouse(msg.sender);
    }

    /** 
     * @dev Claim several onchain zombiemice for the offchain
     * @param offchain_uids_ Offhchain mice IDs used to claim
     */
    function claimOnchainMice(uint[] memory offchain_uids_) external {
        uint8 claim_counter;
        for (uint8 i =0;i<offchain_uids_.length;i++)
        {
            //if (offchain.ownerOf(offchain_uids_[i])!=msg.sender) {
            //    continue;
            //}
            offchainIdToOwner[offchain_uids_[i]]=msg.sender;
            //offchain.transferFrom(msg.sender, address(this), offchain_uids_[i]);
            claim_counter++;
        }
        IOnchainZombie(onChainAddress).claimMice(msg.sender, claim_counter);
    }

    // Public functions

    /** 
     * @dev Get address of who claimed the mouse by ID
     * @param offchain_uid_ Offhchain mice IDs used to claim
     */
    function getClaimedOwner(uint offchain_uid_) external view returns(address) {
        return offchainIdToOwner[offchain_uid_];
    }

    // Owner only functions
    // Contracts linking

    /** 
     * @dev Set offchain zombiemice contract address and create an interface instance
     * @param _offChainAddress contract address
     */
    function setOffchainAddress(address _offChainAddress) external onlyOwner {
        offChainAddress = _offChainAddress;
    }

    /** 
     * @dev Set onchain zombiemice contract address and create an interface instance
     * @param _onChainAddress contract address
     */
    function setOnchainAddress(address _onChainAddress) external onlyOwner {
        onChainAddress = _onChainAddress;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}