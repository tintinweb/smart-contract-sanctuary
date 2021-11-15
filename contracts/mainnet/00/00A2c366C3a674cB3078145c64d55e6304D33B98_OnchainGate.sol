// contracts/OnchainGate.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOffchainZombie.sol";
import "./IOnchainZombie.sol";

contract OnchainGate {

    // Bool
    bool public _gateOpened;

    // Mappings

    mapping(uint => address) offchainIdToOwner;

    // Addresses

    address public offChainAddress;
    address public onChainAddress;
    address _owner;

    // Constructor

    constructor() {
        _owner = msg.sender;
    }

    // Claim functions

    /** 
     * @dev Claim onchain zombiemouse for the offchain
     * @param _offchain_uid Offhchain mouse ID used to claim
     */
    function claimOnchainMouse(
        uint _offchain_uid
    ) 
        external 
        gateOpened 
    {
        require(IOffchainZombie(offChainAddress).ownerOf(_offchain_uid)==msg.sender, "You are not the mice owner");
        offchainIdToOwner[_offchain_uid]=msg.sender;
        IOffchainZombie(offChainAddress).transferFrom(msg.sender, address(this), _offchain_uid);
        IOnchainZombie(onChainAddress).claimMouse(msg.sender);
    }

    /** 
     * @dev Claim several onchain zombiemice for the offchain
     * @param _offchain_uids_ Offhchain mice IDs used to claim
     */
    function claimOnchainMice(
        uint[] memory _offchain_uids_
    ) 
        external 
        gateOpened 
    {
        for (uint8 i =0;i<_offchain_uids_.length;i++)
        {
            require(IOffchainZombie(offChainAddress).ownerOf(_offchain_uids_[i])==msg.sender, "You are not the offchain mice owner");

            offchainIdToOwner[_offchain_uids_[i]]=msg.sender;
            IOffchainZombie(offChainAddress).transferFrom(msg.sender, address(this), _offchain_uids_[i]);
        }
        IOnchainZombie(onChainAddress).claimMice(msg.sender, _offchain_uids_.length);
    }

    // Public functions

    /** 
     * @dev Get address of who claimed the mouse by ID
     * @param _offchain_uid_ Offhchain mice IDs used to claim
     */
    function getClaimedOwner(
        uint _offchain_uid_
    ) 
        external 
        view 
        returns(address) 
    {
        return offchainIdToOwner[_offchain_uid_];
    }

    // Owner only functions
    // Contracts linking

    /** 
     * @dev Set offchain zombiemice contract address and create an interface instance
     * @param _offChainAddress contract address
     */
    function setOffchainAddress(
        address _offChainAddress
    ) 
        external 
        onlyOwner 
    {
        offChainAddress = _offChainAddress;
    }

    /** 
     * @dev Set onchain zombiemice contract address and create an interface instance
     * @param _onChainAddress contract address
     */
    function setOnchainAddress(
        address _onChainAddress
    ) 
        external 
        onlyOwner 
    {
        onChainAddress = _onChainAddress;
    }

    /** 
     * @dev Opens and closes the Gate for claim
     * @param state new Gate state
     */
    function setGateState(
        bool state
    ) 
        public 
        onlyOwner 
    {
        _gateOpened=state;
    }
    
    modifier gateOpened() {
        require(_gateOpened);
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }
}

// contracts/OnchainGate.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOffchainZombie {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

// contracts/IOnchainZombie.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnchainZombie {
    function claimMouse(address _claimer) external;
    function claimMice(address _claimer, uint _num) external;
}

