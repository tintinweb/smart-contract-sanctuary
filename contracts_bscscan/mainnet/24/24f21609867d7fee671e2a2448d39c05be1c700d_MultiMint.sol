/**
 *Submitted for verification at BscScan.com on 2021-10-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IMysteriousCrates {
    function mintCrate(address user, uint[] memory cardIds) external;
}

interface ILandCrates {
    function mintCrateTeam(uint16 numCrates, uint8 _crateType) external;
    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function balanceOf(address owner) external view returns (uint balance);
}

contract MultiMint is Auth {
    IMysteriousCrates public samuraiCrates;
    ILandCrates public landCrates;
    
    enum CrateType { Hill, Mountain, Coast }
    
    event SamuraiCrateMinted(address indexed user, uint crateStars, uint numCrates);
    event LandCrateMinted(address indexed user, CrateType crateType, uint numCrates);
    
    constructor(address _samuraiCrates, address _landCrates) Auth(msg.sender) {
		samuraiCrates = IMysteriousCrates(_samuraiCrates);
		landCrates = ILandCrates(_landCrates);
	}
    
    function multiMintSamurai(address user, uint crateStars, uint numCrates) external authorized {
        require(numCrates <= 50, "too many at once");
        require(crateStars <= 3 && crateStars >= 0, "invalid star count");
        
        uint[] memory cardIds = new uint[](3);
        
        if (crateStars == 0) {
            cardIds[0] = 5000;
            cardIds[1] = 5000;
            cardIds[2] = 5000;
        } else if (crateStars == 1) {
            cardIds[0] = 5000;
            cardIds[1] = 5000;
            cardIds[2] = 1;
        } else if (crateStars == 2) {
            cardIds[0] = 5000;
            cardIds[1] = 1;
            cardIds[2] = 1;
        } else {
            cardIds[0] = 1;
            cardIds[1] = 1;
            cardIds[2] = 1;
        }
        
        for (uint i = 0; i < numCrates; i++) {
            samuraiCrates.mintCrate(user, cardIds);
        }
        
        emit SamuraiCrateMinted(user, crateStars, numCrates);
    }
    
    function multiMintLand(address user, CrateType crateType, uint16 numCrates) external authorized {
        require(numCrates < 50, "too many at once");
        require(landCrates.balanceOf(address(this)) == 0, "landcrate balance must be 0");
        
        landCrates.mintCrateTeam(numCrates, uint8(crateType));
        
        for (uint i = 0; i < numCrates; i++) {
            landCrates.safeTransferFrom(
                address(this),
                user,
                landCrates.tokenOfOwnerByIndex(address(this), i)
            );
        }
        
        emit LandCrateMinted(user, crateType, numCrates);
    }
}