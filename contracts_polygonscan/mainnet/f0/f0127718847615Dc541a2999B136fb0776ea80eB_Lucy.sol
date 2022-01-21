// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./GemFiERC721.sol";

contract Lucy is GemFiERC721, Ownable {

    using Counters for Counters.Counter;
    
    struct ReproduceInfo {
        address reproduceOwner;
        uint256 reproduceParticipationRoleId;
        uint256 reproduceParticipationMumber;
        uint256 reproduceRoleId;
        uint256 reproduceBlockLock;
        bytes32 proofHash;
        bool canReproduce;
        bool isMint;
    }
    
    
    event ReproduceEvent(address indexed reproduceOwner, uint256 reproduceParticipationRoleId, uint256 indexed reproduceRoleId, bytes32 indexed proofHash);
    
    
    Counters.Counter private roleIdCounter;
    
    address private projectPartyAddress;
    
    uint256[] public allGenesisRoleId;
    
    uint256 private genesisIssueNumber = 66;
    
    uint256 private constant genesisIssueTotalNumber = 59994;
    
    // Polygon here uses timestamps instead of blocks ！
    uint256 private constant reproduceBlockLock = 259200;
    
    // 0~5 A total of not more than 6 times, starting from subscript 0
    uint256 private constant reproduceMumber = 8;
    
    // Mapping from Lucy locking Block
    mapping(uint256 => uint256) private reproduceLocking;
    
    mapping(uint256 => uint256) private roolReproduceMumber;
    
    mapping (bytes32 => ReproduceInfo) public reproduceInfoMap;
    
    mapping (uint256 => bytes32) public reproduceHashMap;
    
    mapping (bytes32 => bool) public reproduceIngMap;

    mapping (uint256 => bool) public canReproduceMap;
    
    
    constructor(address projectPartyAccount) GemFiERC721("GemFi.vip", "MUA", "https://nft.gemfi.vip/static/nft/MATIC/") {
        projectPartyAddress = projectPartyAccount;
    }
    
    
    function setGenesisIssueNumber(uint256 issueNumber) external onlyOwner {
        if (issueNumber > 100) {
            issueNumber = 100;
        }
        
        if (issueNumber < 6) {
            issueNumber = 6;
        }
        genesisIssueNumber = issueNumber;
    }


    function burn(uint256 tokenId) external {
        address firstTokenIdOwner = super.ownerOf(tokenId);
        require(firstTokenIdOwner == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(firstTokenIdOwner, msg.sender), "Lucy: You do not have permission to operate this role");

        super._burn(tokenId);
    }
    
    
    function issue() external {
        require(allGenesisRoleId.length < genesisIssueTotalNumber, "Lucy: Genesis issuance has reached the upper limit and cannot be continued");
        
        for (uint i = 0; i < genesisIssueNumber; i++) {
            if (allGenesisRoleId.length < genesisIssueTotalNumber) {
                roleIdCounter.increment();
                uint256 _roleId = roleIdCounter.current();
                
                super._mint(projectPartyAddress, _roleId);

                if (_roleId % 2 == 0) {
                    canReproduceMap[_roleId] = true;
                } else {
                    canReproduceMap[_roleId] = false;
                }
                
                allGenesisRoleId.push(_roleId);
            }
        }
    }
    
    
    function reproduce(uint256 reproduceRoleId, uint256 blockLock, bool canReproduce, bytes32 proofHash) external {
        address tokenIdOwner = super.ownerOf(reproduceRoleId);
        require(tokenIdOwner == msg.sender, "Lucy: This token does not belong to you");
        
        require(canReproduceMap[reproduceRoleId], "Lucy: This character cannot be reproduced");
        bytes32 reproduceIngHash = keccak256(abi.encodePacked(reproduceRoleId));
        require(!reproduceIngMap[reproduceIngHash], "Lucy: The character is being reproduced, please do not submit it repeatedly!");
        
        if (reproduceBlockLock > blockLock) {
            blockLock = reproduceBlockLock;
        }
        uint256 roleIdBlockLock = block.timestamp + blockLock;
        // block lock beautiful diamond
        setBlockLock(reproduceRoleId, roleIdBlockLock);
        
        uint256 roleReproduceMumber = getRoleReproduceMumber(reproduceRoleId);
        
        bytes32 hash = keccak256(abi.encodePacked(reproduceRoleId, roleReproduceMumber));
        
        uint256 mintLucyId;
        
        reproduceIngMap[reproduceIngHash] = true;
        reproduceInfoMap[hash] = ReproduceInfo(msg.sender, reproduceRoleId, roleReproduceMumber, mintLucyId, roleIdBlockLock, proofHash, canReproduce, false);
    }
    
    
    
    function reproduceFinish(bytes32 reproduceHash) external {
        ReproduceInfo storage _reproduceInfo = reproduceInfoMap[reproduceHash];
        
        uint256 _reproduceParticipationRoleId = _reproduceInfo.reproduceParticipationRoleId;
        address _reproduceOwner = _reproduceInfo.reproduceOwner;
        bool canReproduce = _reproduceInfo.canReproduce;
        
        require(!_reproduceInfo.isMint, "Lucy: reproduce completed");
        
        address firstTokenIdOwner = super.ownerOf(_reproduceParticipationRoleId);
        
        require(firstTokenIdOwner == _reproduceOwner, "Lucy: This token does not belong to you");
        require(getRoleLockBlock(_reproduceParticipationRoleId) < block.timestamp, 
        "Lucy: The reproduction has not been completed, please wait for the reproduction to complete before calling!");
        
        addReproduceMumber(_reproduceParticipationRoleId);
        
        roleIdCounter.increment();
        uint256 _roleId = roleIdCounter.current();
        
        super._mint(_reproduceOwner, _roleId);
        canReproduceMap[_roleId] = canReproduce;
        
        _reproduceInfo.isMint = true;
        _reproduceInfo.reproduceRoleId = _roleId;
        reproduceHashMap[_roleId] = reproduceHash;
        
        bytes32 reproduceIngHash = keccak256(abi.encodePacked(_reproduceParticipationRoleId));
        reproduceIngMap[reproduceIngHash] = false;
        
        emit ReproduceEvent(_reproduceInfo.reproduceOwner, _reproduceInfo.reproduceParticipationRoleId, _roleId, _reproduceInfo.proofHash);
    }
    

    function getRoleLockBlock(uint256 roleId) public view virtual returns (uint256) {
        return reproduceLocking[roleId];
    }
    
    
    function getRoleReproduceMumber(uint256 roleId) public view virtual returns (uint256) {
        return roolReproduceMumber[roleId];
    }
    
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = super.balanceOf(_owner);
        
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);

            // We count on the fact that all cats have IDs starting at 1 and increasing
            // sequentially up to the totalCat count.
            uint256 catId;

            for (catId = 0; catId < tokenCount; catId++) {
                result[catId] = super.tokenOfOwnerByIndex(_owner, catId);
            }

            return result;
        }
    }
    
    
    function setBlockLock(uint256 reproduceRoleId, uint256 lockBlockNumber) internal virtual {
        require(lockBlockNumber > block.timestamp, "Lucy: The locked block must be larger than the current block");
        reproduceLocking[reproduceRoleId] = lockBlockNumber;
    }
    
    
    function addReproduceMumber(uint256 reproduceRoleId) internal virtual {
        if (roolReproduceMumber[reproduceRoleId] < reproduceMumber) {
            roolReproduceMumber[reproduceRoleId] = roolReproduceMumber[reproduceRoleId] + 1;
        }else {
            super._burn(reproduceRoleId);
        }
    }
    
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(getRoleLockBlock(tokenId) < block.timestamp, "Lucy: Role locked");
    }

}