/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.1;

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

/**
 * @title MoonCatsOnChain
 * @notice On Chain Reference for Offical MoonCat Projects
 * @dev Maintains a mapping of contract addresses to documentation/description strings
 */
contract MoonCatReference {

    /* Original MoonCat Rescue Contract */

    address constant public MoonCatRescue = 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6;

    /* Documentation */

    address[] internal ContractAddresses;

    struct Doc {
        string name;
        string description;
        string details;
    }

    mapping (address => Doc) internal Docs;

    /**
     * @dev How many Contracts does this Reference contract have documentation for?
     */
    function totalContracts () public view returns (uint256) {
        return ContractAddresses.length;
    }

    /**
     * @dev Iterate through the addresses this Reference contract has documentation for.
     */
    function contractAddressByIndex (uint256 index) public view returns (address) {
        require(index < ContractAddresses.length, "Index Out of Range");
        return ContractAddresses[index];
    }

    /**
     * @dev For a specific address, get the details this Reference contract has for it.
     */
    function doc (address _contractAddress) public view returns (string memory name, string memory description, string memory details) {
        Doc storage data = Docs[_contractAddress];
        return (data.name, data.description, data.details);
    }

    /**
     * @dev Iterate through the addresses this Reference contract has documentation for, returning the details stored for that contract.
     */
    function doc (uint256 index) public view returns (string memory name, string memory description, string memory details, address contractAddress) {
        require(index < ContractAddresses.length, "Index Out of Range");
        contractAddress = ContractAddresses[index];
        (name, description, details) = doc(contractAddress);
    }

    /**
     * @dev Get documentation about this contract.
     */
    function doc () public view returns (string memory name, string memory description, string memory details) {
        return doc(address(this));
    }

    address payable public owner;

    modifier onlyOwner () {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    /**
     * @dev Update the stored details about a specific Contract.
     */
    function setDoc (address contractAddress, string memory name, string memory description, string memory details) public onlyOwner {
        require(bytes(name).length > 0, "Name cannot be blank");
        Doc storage data = Docs[contractAddress];
        if (bytes(data.name).length == 0) {
            ContractAddresses.push(contractAddress);
        }
        data.name = name;
        data.description = description;
        data.details = details;
    }

    /**
     * @dev Update the name and description about a specific Contract.
     */
    function setDoc (address contractAddress, string memory name, string memory description) public {
        setDoc(contractAddress, name, description, "");
    }

    /**
     * @dev Update the details about a specific Contract.
     */
    function updateDetails (address contractAddress, string memory details) public onlyOwner {
        Doc storage data = Docs[contractAddress];
        require(bytes(data.name).length == 0, "Doc not found");
        data.details = details;
    }

    /**
     * @dev Update the details for multiple Contracts at once.
     */
    function batchSetDocs (address[] calldata contractAddresses, Doc[] calldata docs) public onlyOwner {
        for ( uint256 i = 0; i < docs.length; i++) {
            Doc memory data = docs[i];
            setDoc(contractAddresses[i], data.name, data.description, data.details);
        }
    }

    /**
     * @dev Allow current `owner` to transfer ownership to another address
     */
    function transferOwnership (address payable newOwner) public onlyOwner {
        owner = newOwner;
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20 (address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721 (address tokenContract, uint256 tokenId) public onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), owner, tokenId);
    }


    constructor () {
        owner = payable(msg.sender);

        // https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
        IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148).claim(msg.sender);

        setDoc(0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6, "MoonCatRescue", "Original 2017 MoonCatRescue user-discoverable blockchain collectible.", "");
    }
}