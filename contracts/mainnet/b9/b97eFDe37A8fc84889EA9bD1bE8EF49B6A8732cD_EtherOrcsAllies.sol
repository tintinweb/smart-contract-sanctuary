// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../ERC20.sol";
import "./ERC721.sol"; 
import "../interfaces/Interfaces.sol";

contract EtherOrcsAllies is ERC721 {

    uint256 constant startId = 5050;

    mapping(uint256 => Ally) public allies;
    mapping(address => bool) public auth;

    uint16 shSupply;
    uint16 ogSupply;
    uint16 mgSupply;
    uint16 rgSupply;

    ERC20 boneShards;

    MetadataHandlerAllies metadaHandler;

    address public castle;
    bool    public openForMint;
    
    bytes32 internal entropySauce;

    struct Ally {uint8 class; uint16 level; uint32 lvlProgress; uint16 modF; uint8 skillCredits; bytes22 details;}

    struct Shaman {uint8 body; uint8 featA; uint8 featB; uint8 helm; uint8 mainhand; uint8 offhand;}

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(auth[msg.sender] || (msg.sender == tx.origin && size == 0), "you're trying to cheat!");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    function initialize(address ct, address bs, address meta) external {
        require(msg.sender == admin);

        castle = ct;
        boneShards = ERC20(bs);
        metadaHandler = MetadataHandlerAllies(meta);
    }

    function setAuth(address add_, bool status) external {
        require(msg.sender == admin);
        auth[add_] = status;
    }

    function setMintOpen(bool open_) external {
        require(msg.sender == admin);
        openForMint = open_;
    }

    function tokenURI(uint256 id) external view returns(string memory) {
        Ally memory ally = allies[id];
        return metadaHandler.getTokenURI(id, ally.class, ally.level, ally.modF, ally.skillCredits, ally.details);
    }

    function mintShamans(uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            mintShaman();
        }
    }

    function mintShaman() public noCheaters {
        require(openForMint || auth[msg.sender], "not open for mint");
        boneShards.burn(msg.sender, 60 ether);

        _mintShaman(_rand());
    } 

    function pull(address owner_, uint256[] calldata ids) external {
        require (msg.sender == castle, "not castle");
        for (uint256 index = 0; index < ids.length; index++) {
            _transfer(owner_, msg.sender, ids[index]);
        }
        CastleLike(msg.sender).pullCallback(owner_, ids);
    }

    function adjustAlly(uint256 id, uint8 class_, uint16 level_, uint32 lvlProgress_, uint16 modF_, uint8 skillCredits_, bytes22 details_) external {
        require(auth[msg.sender], "not authorized");

        allies[id] = Ally({class: class_, level: level_, lvlProgress: lvlProgress_, modF: modF_, skillCredits: skillCredits_, details: details_});
    }

    function shamans(uint256 id) external view returns(uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, uint8 body, uint8 featA, uint8 featB, uint8 helm, uint8 mainhand, uint8 offhand) {
        Ally memory ally = allies[id];
        level        = ally.level;
        lvlProgress  = ally.lvlProgress;
        modF         = ally.modF;
        skillCredits = ally.skillCredits;

        Shaman memory sh = _shaman(ally.details);
        body     = sh.body;
        featA    = sh.featA;
        featB    = sh.featB;
        helm     = sh.helm;
        mainhand = sh.mainhand;
        offhand  = sh.offhand;
    }

    function _shaman(bytes22 details) internal pure returns(Shaman memory sh) {
        uint8 body     = uint8(bytes1(details));
        uint8 featA    = uint8(bytes1(details << 8));
        uint8 featB    = uint8(bytes1(details << 16));
        uint8 helm     = uint8(bytes1(details << 24));
        uint8 mainhand = uint8(bytes1(details << 32));
        uint8 offhand  = uint8(bytes1(details << 40));

        sh.body     = body;
        sh.featA    = featA;
        sh.featB    = featB;
        sh.helm     = helm;
        sh.mainhand = mainhand;
        sh.offhand  = offhand;
    }


    function _mintShaman(uint256 rand) internal returns (uint16 id) {
        id = uint16(shSupply + 1 + startId); //check that supply is less than 3000
        require(shSupply++ <= 3000, "max supply reached");

        // Getting Random traits
        uint8 body = _getBody(_randomize(rand, "BODY", id));

        uint8 featB    = uint8(_randomize(rand, "featB",     id) % 22) + 1; 
        uint8 featA    = uint8(_randomize(rand, "featA",    id) % 20) + 1; 
        uint8 helm     = uint8(_randomize(rand, "HELM",     id) %  7) + 1;
        uint8 mainhand = uint8(_randomize(rand, "MAINHAND", id) %  7) + 1; 
        uint8 offhand  = uint8(_randomize(rand, "OFFHAND",  id) %  7) + 1;

        _mint(msg.sender, id);

        allies[id] = Ally({class: 1, level: 25, lvlProgress: 25000, modF: 0, skillCredits: 100, details: bytes22(abi.encodePacked(body, featA, featB, helm, mainhand, offhand))});
    }

    function _getBody(uint256 rand) internal pure returns (uint8) {
        uint256 sixtyFivePct = type(uint16).max / 100 * 65;
        uint256 nineSevenPct = type(uint16).max / 100 * 97;
        uint256 nineNinePct  = type(uint16).max / 100 * 99;

        if (uint16(rand) < sixtyFivePct) return uint8(rand % 5) + 1;
        if (uint16(rand) < nineSevenPct) return uint8(rand % 4) + 6;
        if (uint16(rand) < nineNinePct) return 10;
        return 11;
    } 

    /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.basefee, block.timestamp, entropySauce)));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// Taken from Solmate: https://github.com/Rari-Capital/solmate

abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
    function decimals() external view virtual returns (uint8);

    // string public constant name     = "ZUG";
    // string public constant symbol   = "ZUG";
    // uint8  public constant decimals = 18;

    /*///////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isMinter;

    address public ruler;

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    constructor() { ruler = msg.sender;}

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        balanceOf[msg.sender] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        balanceOf[from] -= value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(from, to, value);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                             ORC PRIVILEGE
    //////////////////////////////////////////////////////////////*/

    function mint(address to, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO MINT");
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        require(isMinter[msg.sender], "FORBIDDEN TO BURN");
        _burn(from, value);
    }

    /*///////////////////////////////////////////////////////////////
                         Ruler Function
    //////////////////////////////////////////////////////////////*/

    function setMinter(address minter, bool status) external {
        require(msg.sender == ruler, "NOT ALLOWED TO RULE");

        isMinter[minter] = status;
    }

    function setRuler(address ruler_) external {
        require(msg.sender == ruler ||ruler == address(0), "NOT ALLOWED TO RULE");

        ruler = ruler_;
    }


    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 value) internal {
        totalSupply += value;

        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to] += value;
        }

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;

        // This is safe because a user won't ever
        // have a balance larger than totalSupply!
        unchecked {
            totalSupply -= value;
        }

        emit Transfer(from, address(0), value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
    
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/
    
    address        implementation_;
    address public admin; //Lame requirement from opensea
    
    /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    
    mapping(uint256 => address) public ownerOf;
        
    mapping(uint256 => address) public getApproved;
 
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

    function owner() external view returns (address) {
        return admin;
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function transfer(address to, uint256 tokenId) external {
        require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
        
        _transfer(msg.sender, to, tokenId);
        
    }
    
    /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
        supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }
    
    function approve(address spender, uint256 tokenId) external {
        address owner_ = ownerOf[tokenId];
        
        require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
        
        getApproved[tokenId] = spender;
        
        emit Approval(owner_, spender, tokenId); 
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public {        
        require(
            msg.sender == from 
            || msg.sender == getApproved[tokenId]
            || isApprovedForAll[from][msg.sender], 
            "NOT_APPROVED"
        );
        
        _transfer(from, to, tokenId);
        
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId); 
        
        if (to.code.length != 0) {
            // selector = `onERC721Received(address,address,uint,bytes)`
            (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02,
                msg.sender, address(0), tokenId, data));
                
            bytes4 selector = abi.decode(returned, (bytes4));
            
            require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
        }
    }
    
    /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf[tokenId] == from, "not owner");

        balanceOf[from]--; 
        balanceOf[to]++;
        
        delete getApproved[tokenId];
        
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 

    }

    function _mint(address to, uint256 tokenId) internal { 
        require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

        totalSupply++;
        
        // This is safe because the sum of all user
        // balances can't exceed type(uint256).max!
        unchecked {
            balanceOf[to]++;
        }
        
        ownerOf[tokenId] = to;
                
        emit Transfer(address(0), to, tokenId); 
    }
    
    function _burn(uint256 tokenId) internal { 
        address owner_ = ownerOf[tokenId];
        
        require(ownerOf[tokenId] != address(0), "NOT_MINTED");
        
        totalSupply--;
        balanceOf[owner_]--;
        
        delete ownerOf[tokenId];
                
        emit Transfer(owner_, address(0), tokenId); 
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

interface OrcishLike {
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustOrc(uint256 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress) external;
    function transfer(address to, uint256 tokenId) external;
    function orcs(uint256 id) external view returns(uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
    function adjustAlly(uint256 id, uint8 class_, uint16 level_, uint32 lvlProgress_, uint16 modF_, uint8 skillCredits_, bytes22 details_) external;
}

interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface OracleLike {
    function request() external returns (uint64 key);
    function getRandom(uint64 id) external view returns(uint256 rand);
}

interface MetadataHandlerLike {
    function getTokenURI(uint16 id, uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier) external view returns (string memory);
}

interface MetadataHandlerAllies {
    function getTokenURI(uint256 id_, uint256 class_, uint256 level_, uint256 modF_, uint256 skillCredits_, bytes22 details_) external view returns (string memory);
}

interface RaidsLike {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface RaidsLikePoly {
    function stakeManyAndStartCampaign(uint256[] calldata ids_, address owner_, uint256 location_, bool double_, uint256[] calldata potions_) external;
    function startCampaignWithMany(uint256[] calldata ids, uint256 location_, bool double_,  uint256[] calldata potions_) external;
    function commanders(uint256 id) external returns(address);
    function unstake(uint256 id) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

interface EtherOrcsLike {
    function ownerOf(uint256 id) external view returns (address owner_);
    function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
    function orcs(uint256 orcId) external view returns (uint8 body, uint8 helm, uint8 mainhand, uint8 offhand, uint16 level, uint16 zugModifier, uint32 lvlProgress);
}

interface ERC20Like {
    function balanceOf(address from) external view returns(uint256 balance);
    function burn(address from, uint256 amount) external;
    function mint(address from, uint256 amount) external;
    function transfer(address to, uint256 amount) external;
}

interface ERC1155Like {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(address from, uint256 id, uint256 amount) external;
}

interface ERC721Like {
    function transferFrom(address from, address to, uint256 id) external;   
    function transfer(address to, uint256 id) external;
    function ownerOf(uint256 id) external returns (address owner);
    function mint(address to, uint256 tokenid) external;
}

interface HallOfChampionsLike {
    function joined(uint256 orcId) external view returns (uint256 joinDate);
} 

interface AlliesLike {
    function allies(uint256 id) external view returns (uint8 class, uint16 level, uint32 lvlProgress, uint16 modF, uint8 skillCredits, bytes22 details);
}