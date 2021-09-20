/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface rarity {
    function next_summoner() external view returns (uint);
    function level(uint) external view returns (uint);
    function getApproved(uint) external view returns (address);
    function ownerOf(uint) external view returns (address);
    function adventure(uint _summoner) external;
    function spend_xp(uint _summoner, uint _xp) external;
    function level_up(uint _summoner) external;
    function summon(uint _class) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract RarityTool is IERC721Receiver {
    
    rarity private rm; //0xd20c5771dB9977266C7bcA4250b0ebd475B64CA7
    uint constant DAY = 1 days;
    
    struct Bundle {
        uint start_id;
        uint end_id;
        uint class_id;
        uint log;
    }
    
    mapping(address => Bundle[]) private ownedBundle;
    
    constructor(address _rarity_address) {
        rm = rarity(_rarity_address);
    }
    
    function bundleBalanceOf(address _owner) public view returns (uint256) {
        return ownedBundle[_owner].length;
    }
    
    function rarityBalanceWithIndex(address _owner, uint256 _bundle_index) public view returns (uint256) {
        require(_bundle_index < ownedBundle[_owner].length);
        return ownedBundle[_owner][_bundle_index].end_id - ownedBundle[_owner][_bundle_index].start_id + 1;
    }
    
    function rarityBalanceOf(address _owner) public view returns (uint256 balance) {
        balance = 0;
        for (uint i = 0; i < ownedBundle[_owner].length; i++) {
            balance += rarityBalanceWithIndex(_owner, i);
        }
    }
    
    function summon(uint _class_id, uint _count) public {
        uint next_summoner_id = rm.next_summoner();
        for (uint i = 0; i < _count; i++) {
            rm.summon(_class_id);
        }
        ownedBundle[msg.sender].push(Bundle(next_summoner_id, next_summoner_id + _count - 1, _class_id, 0));
    }
    
    function adventureWithIndex(uint _bundle_index) public {
        require(_bundle_index < ownedBundle[msg.sender].length);
        require(block.timestamp > ownedBundle[msg.sender][_bundle_index].log);
        ownedBundle[msg.sender][_bundle_index].log = block.timestamp + DAY;
        for (uint i = ownedBundle[msg.sender][_bundle_index].start_id; i <= ownedBundle[msg.sender][_bundle_index].end_id; i++) {
            rm.adventure(i);
        }
    }
    
    function adventure() public {
        require(ownedBundle[msg.sender].length > 0);
        for (uint i = 0; i< ownedBundle[msg.sender].length; i++) {
            adventureWithIndex(i);
        }
    }
    
    function safeTransferAllRarity(address _to) public {
        for (uint i = ownedBundle[msg.sender].length; i > 0; i--) {
            safeTrasferAllRarityOfBundle(_to, i);
        }
    }
    
    function safeTrasferAllRarityOfBundle(address _to, uint _bundle_index) public {
        safeTransferRarityOfBundle(_to, _bundle_index, rarityBalanceWithIndex(msg.sender, _bundle_index));
    }
    
    function safeTransferRarityOfBundle(address _to, uint _bundle_index, uint _count) public {
        require(_to != address(0));
        require(_bundle_index < ownedBundle[msg.sender].length);
        require(_count <= ownedBundle[msg.sender][_bundle_index].end_id - ownedBundle[msg.sender][_bundle_index].start_id + 1);
        
        _transferRarityOfBundle(msg.sender, _to, _bundle_index, _count);
    }
    
    function _transferRarityOfBundle(address _from, address _to, uint _bundle_index, uint _count) internal {
        Bundle memory bundle = ownedBundle[_from][_bundle_index];
        
        for (uint i = 0; i < _count; i++) {
            rm.transferFrom(address(this), _to, bundle.end_id - i);
        }
        
        if (_count == bundle.end_id - bundle.start_id + 1) {
            uint256 _last_bundle_index = ownedBundle[_from].length - 1;
            if (_bundle_index != _last_bundle_index) {
                ownedBundle[_from][_bundle_index] = ownedBundle[_from][_last_bundle_index];                
            }
            delete ownedBundle[_from][_last_bundle_index];
        }
    }
    
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    
}