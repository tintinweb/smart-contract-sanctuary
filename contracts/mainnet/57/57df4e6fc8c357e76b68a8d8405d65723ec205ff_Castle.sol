/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

pragma solidity 0.8.7;


// SPDX-License-Identifier: Unlicense
interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IDogewood {
    // struct to store each token's traits
    struct Doge {
        uint8 head;
        uint8 breed;
        uint8 color;
        uint8 class;
        uint8 armor;
        uint8 offhand;
        uint8 mainhand;
        uint16 level;
    }

    function getTokenTraits(uint256 tokenId) external view returns (Doge memory);
    function getGenesisSupply() external view returns (uint256);
    function pull(address owner, uint256[] calldata ids) external;
    function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level) external;
    function transfer(address to, uint256 tokenId) external;
    // function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
}

// interface DogeLike {
//     function pull(address owner, uint256[] calldata ids) external;
//     function manuallyAdjustDoge(uint256 id, uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level) external;
//     function transfer(address to, uint256 tokenId) external;
//     function doges(uint256 id) external view returns(uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
interface PortalLike {
    function sendMessage(bytes calldata message_) external;
}

interface CastleLike {
    function pullCallback(address owner, uint256[] calldata ids) external;
}

// interface DogewoodLike {
//     function ownerOf(uint256 id) external view returns (address owner_);
//     function activities(uint256 id) external view returns (address owner, uint88 timestamp, uint8 action);
//     function doges(uint256 dogeId) external view returns (uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
// }
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

/// @dev A simple contract to orchestrate comings and going from the DogewoodPortal
contract Castle {

    address implementation_;
    address public admin;
    
    address public portal;
    address public dogewood;
    address public treat;

    mapping (address => address) public reflection;
    mapping (uint256 => address) public dogeOwner;

    function initialize(address portal_, address dogewood_, address treat_) external {
        require(msg.sender == admin);
        portal = portal_;
        dogewood   = dogewood_;
        treat = treat_;
    }

    function setReflection(address key_, address reflection_) external {
        require(msg.sender == admin);
        reflection[key_] = reflection_;
        reflection[reflection_] = key_;
    }

    /// @dev Send Doges and tokens to PolyLand
    function travel(uint256[] calldata dogeIds, uint256 treatAmount) external {
        address target = reflection[address(this)];

        uint256 dogesLen   = dogeIds.length;
        uint256 currIndex = 0;

        bytes[] memory calls = new bytes[]((dogesLen > 0 ? dogesLen + 1 : 0) + (treatAmount > 0 ? 1 : 0));

        if (dogesLen > 0) {
            _pullIds(dogewood, dogeIds);

            // This will create doges exactly as they exist in this chain
            for (uint256 i = 0; i < dogeIds.length; i++) {
                calls[i] = _buildData(dogeIds[i]);
            }

            calls[dogesLen] = abi.encodeWithSelector(this.unstakeMany.selector,reflection[dogewood], msg.sender,  dogeIds);
            currIndex += dogesLen + 1;
        }

        if (treatAmount > 0) {
            ERC20Like(treat).burn(msg.sender, treatAmount);
            calls[currIndex] = abi.encodeWithSelector(this.mintToken.selector, reflection[address(treat)], msg.sender, treatAmount);
            currIndex++;
        }

        PortalLike(portal).sendMessage(abi.encode(target, calls));
    }

    function callDogewood(bytes calldata data) external {
        _onlyPortal();

        (bool succ, ) = dogewood.call(data);
        require(succ);
    }

    event D(uint tt);
    event DAD(address al);

    function unstakeMany(address token, address owner, uint256[] calldata ids) external {
        _onlyPortal();

        emit DAD(token);

        for (uint256 i = 0; i < ids.length; i++) {  
            emit D(ids[i]);
            if (token == dogewood)   delete dogeOwner[ids[i]];
            ERC721Like(token).transfer(owner, ids[i]);
        }
    }

    function mintToken(address token, address to, uint256 amount) external { 
        _onlyPortal();

        ERC20Like(token).mint(to, amount);
    }

    function _pullIds(address token, uint256[] calldata ids) internal {
        // The ownership will be checked to the token contract
        IDogewood(token).pull(msg.sender, ids);
    }

    function pullCallback(address owner, uint256[] calldata ids) external {
        require(msg.sender == dogewood);
        for (uint256 i = 0; i < ids.length; i++) {
            _stake(msg.sender, ids[i], owner);
        }
    }

    function _buildData(uint256 id) internal view returns (bytes memory data) {
        // (uint8 head, uint8 breed, uint8 color, uint8 class, uint8 armor, uint8 offhand, uint8 mainhand, uint16 level);
        IDogewood.Doge memory doge_ = IDogewood(dogewood).getTokenTraits(id);
        data = abi.encodeWithSelector(this.callDogewood.selector, abi.encodeWithSelector(IDogewood.manuallyAdjustDoge.selector, id, doge_.head, doge_.breed, doge_.color, doge_.class, doge_.armor, doge_.offhand, doge_.mainhand, doge_.level));
    }

    function _stake(address token, uint256 id, address owner) internal {
        require(dogeOwner[id] == address(0), "already staked");
        require(msg.sender == token, "not dogewood contract");
        require(ERC721Like(token).ownerOf(id) == address(this), "doge not transferred");

        if (token == dogewood)   dogeOwner[id]  = owner;
    }

    function _onlyPortal() view internal {
        require(msg.sender == portal, "not portal");
    } 
}