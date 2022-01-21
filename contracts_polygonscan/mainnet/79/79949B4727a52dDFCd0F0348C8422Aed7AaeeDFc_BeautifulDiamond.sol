// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./Counters.sol";
import "./GemFiERC721.sol";

contract BeautifulDiamond is GemFiERC721, Ownable {
    
    using Counters for Counters.Counter;
    
    
    struct FissionInfo {
        // 0:default, 1:multiple
        uint8 fissionType;  
        address fissionOwner;
        uint256 firstBeautifulDiamondId;
        uint256 secondBeautifulDiamondId;
        uint256 firstBeautifulDiamondFissionMumber;
        uint256 secondBeautifulDiamondFissionMumber;
        uint256[] fissionBeautifulDiamondIds;
        uint256[] fissionBeautifulDiamondFissionMumber;
        uint256 mintBeautifulDiamondId;
        uint256 beautifulDiamondBlockLock;
        bytes32 proofHash;
        bool isMint;
    }
    
    struct FusionInfo {
        // 0:default, 1:multiple
        uint8 fusionType;  
        address fusionOwner;
        uint256 firstBeautifulDiamondId;
        uint256 secondBeautifulDiamondId;
        uint256[] fusionBeautifulDiamondIds;
        uint256 mintBeautifulDiamondId;
        bytes32 proofHash;
        bool isMint;
    }
    
    struct MintInfo {
        address mintOwner;
        uint256 mintBeautifulDiamondId;
        bytes32 proofHash;
    }
    
    
    event FissionEvent(uint8 fissionType, address indexed fissionOwner, uint256 firstBeautifulDiamondId, uint256 secondBeautifulDiamondId, 
    uint256[] fissionBeautifulDiamondIds, uint256 indexed mintBeautifulDiamondId, bytes32 indexed proofHash);
   
    event FusionEvent(uint8 fusionType, address indexed fusionOwner, uint256 firstBeautifulDiamondId, 
    uint256 secondBeautifulDiamondId, uint256[] fusionBeautifulDiamondIds, uint256 indexed mintBeautifulDiamondId, bytes32 indexed proofHash);
    
    event MintEvent(address indexed mintOwner, uint256 indexed mintBeautifulDiamondId, bytes32 indexed proofHash);
    
    
    Counters.Counter private beautifulDiamondIdCounter;
    
    address private projectPartyAddress;
    
    uint256[] public allGenesisBeautifulDiamond;
    
    uint256 private genesisIssueNumber = 33;
    
    uint256 private constant genesisIssueTotalNumber = 999999;
    
    // Polygon here uses timestamps instead of blocks ！
    uint256 private constant fissionBlockLock = 86400;
    
    // 0~5 A total of not more than 6 times, starting from subscript 0
    uint256 private constant fissionMumber = 5;
    
    // Mapping from BeautifulDiamond locking Block
    mapping(uint256 => uint256) private beautifulDiamondLocking;
    
    mapping(uint256 => uint256) private beautifulDiamondFissionMumber;
    
    mapping (bytes32 => FissionInfo) public fissionInfoMap;
    
    mapping (bytes32 => FusionInfo) public fusionInfoMap;
    
    mapping (bytes32 => MintInfo) public mintInfoMap;
    
    mapping (uint256 => bytes32) public fissionHashMap;
    
    mapping (uint256 => bytes32) public fusionHashMap;
    
    mapping (uint256 => bytes32) public mintHashMap;
    
    mapping (bytes32 => bool) public fissionIngMap;
    
    
    constructor(address projectPartyAccount) GemFiERC721("GemFi.vip", "DIA", "https://nft.gemfi.vip/static/nft/MATIC/") {
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
        require(firstTokenIdOwner == msg.sender, "BeautifulDiamond: This token does not belong to you");
        super._burn(tokenId);
    }
    
    
    function batchBurn(uint256[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            address firstTokenIdOwner = super.ownerOf(tokenIds[i]);
            require(firstTokenIdOwner == msg.sender, "BeautifulDiamond: This token does not belong to you");
            super._burn(tokenIds[i]);
        }
    }
    
    
    function issue() external {
        uint256 tokenCount = super.balanceOf(projectPartyAddress);
        require(tokenCount == 0, "BeautifulDiamond: The project party still owns diamonds and cannot be issued");
        require(allGenesisBeautifulDiamond.length < genesisIssueTotalNumber, "Genesis issuance has reached the upper limit and cannot be continued");
        
        for (uint i = 0; i < genesisIssueNumber; i++) {
            if (allGenesisBeautifulDiamond.length < genesisIssueTotalNumber) {
                beautifulDiamondIdCounter.increment();
                uint256 _beautifulDiamondId = beautifulDiamondIdCounter.current();
                
                super._mint(projectPartyAddress, _beautifulDiamondId);
                allGenesisBeautifulDiamond.push(_beautifulDiamondId);
            }
        }
    }
    
    
    function fission(uint256 firstBeautifulDiamondId, uint256 secondBeautifulDiamondId, uint256 blockLock, bytes32 proofHash) external {
        address firstTokenIdOwner = super.ownerOf(firstBeautifulDiamondId);
        address secondTokenIdOwner = super.ownerOf(secondBeautifulDiamondId);
        require(firstTokenIdOwner == msg.sender, "BeautifulDiamond: This token does not belong to you");
        require(secondTokenIdOwner == msg.sender, "BeautifulDiamond: This token does not belong to you");
        
        bytes32 fissionIngHash = keccak256(abi.encodePacked(firstBeautifulDiamondId, secondBeautifulDiamondId));
        require(!fissionIngMap[fissionIngHash], "BeautifulDiamond: two diamonds are already undergoing fission, please do not submit repeatedly!");
        
        if (fissionBlockLock > blockLock) {
            blockLock = fissionBlockLock;
        }
        uint256 beautifulDiamondBlockLock = block.timestamp + blockLock;
        // block lock beautiful diamond
        setBlockLock(firstBeautifulDiamondId, beautifulDiamondBlockLock);
        setBlockLock(secondBeautifulDiamondId, beautifulDiamondBlockLock);
        
        
        uint256 firstBeautifulDiamondFissionMumber = getBeautifulDiamondFissionMumber(firstBeautifulDiamondId);
        uint256 secondBeautifulDiamondFissionMumber = getBeautifulDiamondFissionMumber(secondBeautifulDiamondId);
        
        bytes32 hash = keccak256(abi.encodePacked(firstBeautifulDiamondId, secondBeautifulDiamondId, 
        firstBeautifulDiamondFissionMumber, secondBeautifulDiamondFissionMumber));
        
        uint256[] memory fissionBeautifulDiamondIds;
        uint256[] memory fissionBeautifulDiamondFissionMumber;
        uint256 mintBeautifulDiamondId;
        
        fissionIngMap[fissionIngHash] = true;
        fissionInfoMap[hash] = FissionInfo(0, msg.sender, firstBeautifulDiamondId, secondBeautifulDiamondId, 
        firstBeautifulDiamondFissionMumber, secondBeautifulDiamondFissionMumber, fissionBeautifulDiamondIds, 
        fissionBeautifulDiamondFissionMumber, mintBeautifulDiamondId, beautifulDiamondBlockLock, proofHash, false);
    }
    
    
    function fissionMultiple(uint256[] memory beautifulDiamondIds, uint256 blockLock, bytes32 proofHash) external {
        uint256[] memory fissionBeautifulDiamondFissionMumber = new uint256[](beautifulDiamondIds.length);
        
        if (fissionBlockLock > blockLock) {
            blockLock = fissionBlockLock;
        }
        uint256 beautifulDiamondBlockLock = block.timestamp + blockLock;
        
        for (uint i = 0; i < beautifulDiamondIds.length; i++) {
            address tokenIdOwner = super.ownerOf(beautifulDiamondIds[i]);
                
            require(tokenIdOwner == msg.sender, "BeautifulDiamond: This token does not belong to you");
                
            fissionBeautifulDiamondFissionMumber[i] = getBeautifulDiamondFissionMumber(beautifulDiamondIds[i]);
                
            setBlockLock(beautifulDiamondIds[i], beautifulDiamondBlockLock);
        }
        
        bytes32 hash = keccak256(abi.encodePacked(beautifulDiamondIds, fissionBeautifulDiamondFissionMumber));
        uint256 firstBeautifulDiamondId;
        uint256 secondBeautifulDiamondId;
        uint256 firstBeautifulDiamondFissionMumber;
        uint256 secondBeautifulDiamondFissionMumber;
        uint256 mintBeautifulDiamondId;
        
        fissionInfoMap[hash] = FissionInfo(1, msg.sender, firstBeautifulDiamondId, secondBeautifulDiamondId, 
        firstBeautifulDiamondFissionMumber, secondBeautifulDiamondFissionMumber, beautifulDiamondIds, 
        fissionBeautifulDiamondFissionMumber, mintBeautifulDiamondId, beautifulDiamondBlockLock, proofHash, false);
    }
    
    
    function fissionFinish(bytes32 fissionHash) external {
        FissionInfo storage _fissionInfo = fissionInfoMap[fissionHash];
        
        uint8 _fissionType = _fissionInfo.fissionType;
        uint256 _firstBeautifulDiamondId = _fissionInfo.firstBeautifulDiamondId;
        uint256 _secondBeautifulDiamondId = _fissionInfo.secondBeautifulDiamondId;
        address _fissionOwner = _fissionInfo.fissionOwner;
        uint256[] memory _fissionBeautifulDiamondIds = _fissionInfo.fissionBeautifulDiamondIds;
        
        require(!_fissionInfo.isMint, "BeautifulDiamond: fission completed");
        
        if (_fissionType == 0) {
            address firstTokenIdOwner = super.ownerOf(_firstBeautifulDiamondId);
            address secondTokenIdOwner = super.ownerOf(_secondBeautifulDiamondId);
            
            require(firstTokenIdOwner == _fissionOwner, "BeautifulDiamond: This token does not belong to you");
            require(secondTokenIdOwner == _fissionOwner, "BeautifulDiamond: This token does not belong to you");
            require(getBeautifulDiamondLockBlock(_firstBeautifulDiamondId) < block.timestamp, 
            "BeautifulDiamond: The fission has not been completed, please wait for the fission to complete and call again");
            
            addFissionMumber(_firstBeautifulDiamondId);
            addFissionMumber(_secondBeautifulDiamondId);
        } else {
            for (uint i = 0; i < _fissionBeautifulDiamondIds.length; i++) {
                address tokenIdOwner = super.ownerOf(_fissionBeautifulDiamondIds[i]);
                
                require(tokenIdOwner == _fissionOwner, "BeautifulDiamond: This token does not belong to you");
                require(getBeautifulDiamondLockBlock(_fissionBeautifulDiamondIds[i]) < block.timestamp, 
                "BeautifulDiamond: The fission has not been completed, please wait for the fission to complete and call again");
                
                addFissionMumber(_fissionBeautifulDiamondIds[i]);
            }
        }
        
        beautifulDiamondIdCounter.increment();
        uint256 _beautifulDiamondId = beautifulDiamondIdCounter.current();
        
        super._mint(_fissionOwner, _beautifulDiamondId);
        
        _fissionInfo.isMint = true;
        _fissionInfo.mintBeautifulDiamondId = _beautifulDiamondId;
        fissionHashMap[_beautifulDiamondId] = fissionHash;
        
        bytes32 fissionIngHash = keccak256(abi.encodePacked(_firstBeautifulDiamondId, _secondBeautifulDiamondId));
        fissionIngMap[fissionIngHash] = false;
        
        emit FissionEvent(_fissionInfo.fissionType, _fissionInfo.fissionOwner, _fissionInfo.firstBeautifulDiamondId, 
        _fissionInfo.secondBeautifulDiamondId, _fissionInfo.fissionBeautifulDiamondIds, _fissionInfo.mintBeautifulDiamondId, _fissionInfo.proofHash);
    }
    
    
    function fusion(uint256 firstBeautifulDiamondId, uint256 secondBeautifulDiamondId, bytes32 proofHash) external {
        address firstTokenIdOwner = super.ownerOf(firstBeautifulDiamondId);
        address secondTokenIdOwner = super.ownerOf(secondBeautifulDiamondId);
        
        require(firstTokenIdOwner == msg.sender, "BeautifulDiamond: This token does not belong to you");
        require(secondTokenIdOwner == msg.sender, "BeautifulDiamond: This token does not belong to you");
        
        super._burn(firstBeautifulDiamondId);
        super._burn(secondBeautifulDiamondId);
        
        beautifulDiamondIdCounter.increment();
        uint256 mintBeautifulDiamondId = beautifulDiamondIdCounter.current();
        
        super._mint(msg.sender, mintBeautifulDiamondId);
        
        bytes32 hash = keccak256(abi.encodePacked(firstBeautifulDiamondId, secondBeautifulDiamondId));
        uint256[] memory fusionBeautifulDiamondIds;
        
        fusionInfoMap[hash] = FusionInfo(0, msg.sender, firstBeautifulDiamondId, secondBeautifulDiamondId, 
        fusionBeautifulDiamondIds, mintBeautifulDiamondId, proofHash, true);
        
        fusionHashMap[mintBeautifulDiamondId] = hash;
        
        emit FusionEvent(0, msg.sender, firstBeautifulDiamondId, secondBeautifulDiamondId, fusionBeautifulDiamondIds, mintBeautifulDiamondId, proofHash);
    }
    
    
    function fusionMultiple(uint256[] memory beautifulDiamondIds, bytes32 proofHash) external {
        for (uint i = 0; i < beautifulDiamondIds.length; i++) {
            address tokenIdOwner = super.ownerOf(beautifulDiamondIds[i]);
            require(tokenIdOwner == msg.sender, "BeautifulDiamond: This token does not belong to you");
                
            super._burn(beautifulDiamondIds[i]);
        }
        
        beautifulDiamondIdCounter.increment();
        uint256 mintBeautifulDiamondId = beautifulDiamondIdCounter.current();
        super._mint(msg.sender, mintBeautifulDiamondId);
        
        uint256 firstBeautifulDiamondId;
        uint256 secondBeautifulDiamondId;
        bytes32 hash = keccak256(abi.encodePacked(beautifulDiamondIds));
        
        fusionInfoMap[hash] = FusionInfo(1, msg.sender, firstBeautifulDiamondId, secondBeautifulDiamondId, 
        beautifulDiamondIds, mintBeautifulDiamondId, proofHash, true);
        
        fusionHashMap[mintBeautifulDiamondId] = hash;
        
        emit FusionEvent(1, msg.sender, firstBeautifulDiamondId, secondBeautifulDiamondId, beautifulDiamondIds, mintBeautifulDiamondId, proofHash);
    }
    
    
    function meetTheConditionMint(bytes32 proofHash) external {
        beautifulDiamondIdCounter.increment();
        uint256 mintBeautifulDiamondId = beautifulDiamondIdCounter.current();
        
        super._mint(msg.sender, mintBeautifulDiamondId);
        
        mintHashMap[mintBeautifulDiamondId] = proofHash;
        mintInfoMap[proofHash] = MintInfo(msg.sender, mintBeautifulDiamondId, proofHash);
        
        emit MintEvent(msg.sender, mintBeautifulDiamondId, proofHash);
    }
    
    
    /**
     * get token lock Block
     * 20blocks = 5 mins in Etherium.
     */
    function getBeautifulDiamondLockBlock(uint256 beautifulDiamondId) public view virtual returns (uint256) {
        return beautifulDiamondLocking[beautifulDiamondId];
    }
    
    
    function getBeautifulDiamondFissionMumber(uint256 beautifulDiamondId) public view virtual returns (uint256) {
        return beautifulDiamondFissionMumber[beautifulDiamondId];
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
    
    
    function setBlockLock(uint256 beautifulDiamondId, uint256 lockBlockNumber) internal virtual {
        require(lockBlockNumber > block.timestamp, "BeautifulDiamond: The locked block must be larger than the current block");
        beautifulDiamondLocking[beautifulDiamondId] = lockBlockNumber;
    }
    
    
    function addFissionMumber(uint256 beautifulDiamondId) internal virtual {
        if (beautifulDiamondFissionMumber[beautifulDiamondId] < fissionMumber) {
            beautifulDiamondFissionMumber[beautifulDiamondId] = beautifulDiamondFissionMumber[beautifulDiamondId] + 1;
        }else {
            super._burn(beautifulDiamondId);
        }
    }
    
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(getBeautifulDiamondLockBlock(tokenId) < block.timestamp, "BeautifulDiamond: beautifulDiamond locked");
    }
    
}