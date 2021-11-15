// contracts/OnchainGate.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Interfaces

interface IOffchainZombie {
    function ownerOf(uint token_id_) external returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IOnchainZombie {
    function claimMouse(address claimer) external returns (uint);
    function claimMice(address claimer, uint8 num) external returns (uint[] memory);
}

contract OnchainGate {
    // Mappings

    mapping(uint => address) offchainIdToOwner;

    // Addresses

    address offChainAddress;
    address onChainAddress;
    address _owner;

    // Interface instances

    IOnchainZombie onchain;
    IOffchainZombie offchain;

    // Constructor

    constructor() {
        _owner = msg.sender;
    }

    // Claim functions

    /** 
     * @dev Claim onchain zombiemouse for the offchain
     * @param uid_ Offhchain mouse ID used to claim
     */
    function claimOnchainMouse(uint uid_) external onlyOwner {
        //require(offchain.ownerOf(uid_)==msg.sender, "You are not the mice owner");
        offchainIdToOwner[uid_]=msg.sender;
        //offchain.transferFrom(msg.sender, address(this), uid_);
        onchain.claimMouse(msg.sender);
    }

    /** 
     * @dev Claim several onchain zombiemice for the offchain
     * @param uids_ Offhchain mice IDs used to claim
     */
    function claimOnchainMice(uint[] memory uids_) external onlyOwner{
        uint8 claim_counter;
        for (uint8 i =0;i<uids_.length;i++)
        {
            //if (offchain.ownerOf(uids_[i])!=msg.sender) {
            //    continue;
            //}
            offchainIdToOwner[uids_[i]]=msg.sender;
            //offchain.transferFrom(msg.sender, address(this), uids_[i]);
            claim_counter++;
        }
        onchain.claimMice(msg.sender, claim_counter);
    }

    // Public functions

    /** 
     * @dev Get address of who claimed the mouse by ID
     * @param uid_ Offhchain mice IDs used to claim
     */
    function getClaimedOwner(uint uid_) external view returns(address) {
        return offchainIdToOwner[uid_];
    }

    // Owner only functions
    // Contracts linking

    /** 
     * @dev Set offchain zombiemice contract address and create an interface instance
     * @param _offChainAddress contract address
     */
    function setOffchainAddress(address _offChainAddress) external onlyOwner {
        offChainAddress = _offChainAddress;
        offchain = IOffchainZombie(offChainAddress);
    }

    /** 
     * @dev Set onchain zombiemice contract address and create an interface instance
     * @param _onChainAddress contract address
     */
    function setOnchainAddress(address _onChainAddress) external onlyOwner {
        onChainAddress = _onChainAddress;
        onchain = IOnchainZombie(onChainAddress);
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}

