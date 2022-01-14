/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.1;

interface IMoonCatAcclimator {
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address _owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface IMoonCatRescue {
    function rescueOrder(uint256 tokenId) external view returns (bytes5);
    function catOwners(bytes5 catId) external view returns (address);
    function catNames(bytes5 catId) external view returns (bytes32);
}

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IMoonCatReference {
    function doc (address contractAddress) external view returns (string memory name, string memory description, string memory details);
    function setDoc (address contractAddress, string calldata name, string calldata description) external;
}

/**
 * @title MoonCatTraits
 * @notice On Chain MoonCat Trait Parsing
 * @dev Provides On Chain Reference for the MoonCat Traits
 */
contract MoonCatTraits {

    /* Human-friendly trait names */

    string[2] public facingNames = ["left", "right"];
    string[4] public expressionNames = ["smiling", "grumpy", "pouting", "shy"];
    string[4] public patternNames = ["pure", "tabby", "spotted", "tortie"];
    string[4] public poseNames = ["standing", "sleeping", "pouncing", "stalking"];

    /* External Contracts */

    IMoonCatRescue MCR = IMoonCatRescue(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6);
    IMoonCatReference MoonCatReference;

    /* Traits */

    /**
     * @dev For a given MoonCat rescue order, return the calendar year it was rescued in.
     */
    function rescueYearOf (uint256 rescueOrder) public pure returns (uint16) {
        if (rescueOrder <= 3364) {
            return 2017;
        } else if (rescueOrder <= 5683) {
            return 2018;
        } else if (rescueOrder <= 5754) {
            return 2019;
        } else if (rescueOrder <= 5757) {
            return 2020;
        } else {
            return 2021;
        }
    }

    /**
     * @dev For a given MoonCat hex ID, extract the trait data from the "K" byte.
     */
    function kTraitsOf (bytes5 catId) public pure returns
        (bool genesis,
         bool pale,
         uint8 facing,
         uint8 expression,
         uint8 pattern,
         uint8 pose)
    {
        uint40 c = uint40(catId);
        uint8 classification = uint8(c >> 32);
        require(classification == 0 || classification == 255, "Invalid Classification");

        genesis = (classification == 255);

        uint8 r = uint8(c >> 16);
        uint8 g = uint8(c >> 8);
        uint8 b = uint8(c);

        require(!genesis || (r == 0 && g == 12 && b == 167), "Invalid Genesis Id");

        pale = ((c >> 31) & 1) == 1;
        if (genesis) {
            uint8 k = uint8(c >> 24);
            bool even_k = k % 2 == 0;
            pale = (even_k && pale) || (!even_k && !pale);
        }

        facing = uint8((c >> 30) & 1);
        expression = uint8((c >> 28) & 3);
        pattern = uint8((c >> 26) & 3);
        pose = uint8((c >> 24) & 3);
    }

    /**
     * @dev For a given MoonCat rescue order, extract the trait data from the "K" byte.
     */
    function kTraitsOf (uint256 rescueOrder) public view returns
        (bool genesis,
         bool pale,
         uint8 facing,
         uint8 expression,
         uint8 pattern,
         uint8 pose)
    {
        require(rescueOrder < 25440, "Invalid Rescue Order");
        return kTraitsOf(MCR.rescueOrder(rescueOrder));
    }

    /**
     * @dev For a given MoonCat hex ID, extract the trait data in a human-friendly format.
     */
    function traitsOf (bytes5 catId) public view returns
        (bool genesis,
         bool pale,
         string memory facing,
         string memory expression,
         string memory pattern,
         string memory pose)
    {
        (bool genesisBool, bool paleBool, uint8 facingInt, uint8 expressionInt, uint8 patternInt, uint8 poseInt) = kTraitsOf(catId);
        return (
            genesisBool,
            paleBool,
            facingNames[facingInt],
            expressionNames[expressionInt],
            patternNames[patternInt],
            poseNames[poseInt]
        );
    }

    /**
     * @dev For a given MoonCat rescue order, extract the trait data in a human-friendly format.
     */
    function traitsOf (uint256 rescueOrder) public view returns
        (bool genesis,
         bool pale,
         string memory facing,
         string memory expression,
         string memory pattern,
         string memory pose,
         bytes5 catId,
         uint16 rescueYear,
         bool isNamed
         )
    {
        require(rescueOrder < 25440, "Invalid Rescue Order");
        catId = MCR.rescueOrder(rescueOrder);
        (genesis, pale, facing, expression, pattern, pose) = traitsOf(catId);
        rescueYear = rescueYearOf(rescueOrder);
        isNamed = (uint256(MCR.catNames(catId)) > 0);
    }


    mapping (address => bool) ERC721ProxyOwnership;

    /**
     * @dev Iterating function to find the final owner of a MoonCat (looping through any ERC721 wrappers).
     */
    function proxyOwner (uint256 rescueOrder, address ownerAddress) internal view returns (address) {
        if (ERC721ProxyOwnership[ownerAddress]) {
            return proxyOwner(rescueOrder, IERC721(ownerAddress).ownerOf(rescueOrder));
        } else {
            return ownerAddress;
        }
    }

    /**
     * @dev For a given MoonCat rescue order, return who owns that MoonCat.
     */
    function ownerOf (uint256 rescueOrder) public view returns (address) {
        require(rescueOrder < 25440, "Invalid Rescue Order");
        bytes5 catId = MCR.rescueOrder(rescueOrder);
        return proxyOwner(rescueOrder, MCR.catOwners(catId));
    }

    /**
     * @dev For a given MoonCat rescue order, return the hex ID of that MoonCat.
     */
    function catIdOf (uint256 rescueOrder) public view returns (bytes5) {
        require(rescueOrder < 25440, "Invalid Rescue Order");
        return MCR.rescueOrder(rescueOrder);
    }

    /**
     * @dev For a given MoonCat hex ID, return the recorded name of that MoonCat.
     */
    function nameOf (bytes5 catId) public view returns (string memory) {
        bytes32 nameRaw = MCR.catNames(catId);
        uint8 i = 0;
        while(i < 32 && nameRaw[i] != 0) {
            i++;
        }
        bytes memory nameBytes = new bytes(i);
        for (i = 0; i < 32 && nameRaw[i] != 0; i++) {
            nameBytes[i] = nameRaw[i];
        }
        return string(nameBytes);
    }

    /**
     * @dev For a given MoonCat rescue order, return the recorded name of that MoonCat.
     */
    function nameOf (uint256 rescueOrder) public view returns (string memory) {
        require(rescueOrder < 25440, "Invalid Rescue Order");
        return nameOf(MCR.rescueOrder(rescueOrder));
    }

    /* General */

    /**
     * @dev Get documentation about this contract.
     */
    function doc() public view returns (string memory name, string memory description, string memory details) {
        return MoonCatReference.doc(address(this));
    }

    constructor (address MoonCatReferenceAddress) {
        owner = payable(msg.sender);
        // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
        IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148).claim(msg.sender);
        ERC721ProxyOwnership[0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69] = true;
        MoonCatReference = IMoonCatReference(MoonCatReferenceAddress);
    }

    address payable public owner;

    modifier onlyOwner () {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    /**
     * @dev Allow current `owner` to transfer ownership to another address.
     */
    function transferOwnership (address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    /**
     * @dev Update the ERC721 registry for a given address.
     */
    function setERC721Proxy (address proxyAddress, bool isProxy) public onlyOwner {
        ERC721ProxyOwnership[proxyAddress] = isProxy;
    }

    /**
     * @dev Update the location of the Reference Contract.
     */
    function setReferenceContract (address referenceContract) public onlyOwner {
        MoonCatReference = IMoonCatReference(referenceContract);
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), owner, tokenId);
    }


}