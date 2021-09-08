//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";

contract Hedgiez is ERC721, Ownable, ERC721Burnable, ERC721Enumerable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bool isMintingLive = false;
    uint[] public deployedHedgiez;
    mapping(address => bool) private admins;
    mapping(address => bool) private superAdmins;
    mapping(address => uint[]) private minterTokenIds;


    uint public maxHedgiez = 10000;

    modifier restricted() {
        require(admins[msg.sender]);
        _;
    }

    modifier superRestricted() {
        require(superAdmins[msg.sender]);
        _;
    }

    modifier mintingLive() {
        require(isMintingLive == true);
        _;
    }


    constructor() ERC721("Hedgiez", "HDZ") {
        superAdmins[msg.sender] = true;
        admins[msg.sender] = true;
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function addAdmin(address newAdmin) public superRestricted {
        admins[newAdmin] = true;
    }

    function removeAdmin(address admin) public superRestricted {
        admins[admin] = false;
    }

    function addSuperAdmin(address newSuperAdmin) public superRestricted {
        superAdmins[newSuperAdmin] = true;
    }

    function removeSuperAdmin(address superAdmin) public superRestricted {
        superAdmins[superAdmin] = false;
    }

    function withdraw() public payable superRestricted {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function isAdmin() public view returns (bool) {
        return admins[msg.sender];
    }

    function isSuperAdmin() public view returns (bool) {
        return superAdmins[msg.sender];
    }

    function getRemainingHedgiez() public view returns (uint) {
        return maxHedgiez - deployedHedgiez.length;
    }

    function getBalance() public restricted view returns (uint) {
        return address(this).balance;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://api.hedgiez.io/metadata/";
    }

    function createHedgie(uint quantity) public mintingLive payable {
        require(quantity <= 20);
        uint totalCost = quantity * 60000000000000000;
        require(msg.value >= totalCost);
        require((maxHedgiez - _tokenIds.current()) >= quantity);

        for(uint i = 0; i < quantity; i++) {
            _tokenIds.increment();
            uint tokenId = _tokenIds.current();
            _mint(msg.sender, tokenId);
            tokenURI(tokenId);
            addTokenId(tokenId);
            deployedHedgiez.push(tokenId);
        }

    }

    function toggleMintingLive() public restricted {
        isMintingLive = !isMintingLive;
    }

    function createCustomHedgie(address newOwner) public restricted {
        require((maxHedgiez - _tokenIds.current()) >= 1);
        _tokenIds.increment();
        uint tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        tokenURI(tokenId);
        uint[] storage hedgieTokenIds = minterTokenIds[newOwner];
        hedgieTokenIds.push(tokenId);
        deployedHedgiez.push(tokenId);
    }



    function addTokenId(uint tokenId) private {
        uint[] storage hedgieTokenIds = minterTokenIds[msg.sender];
        hedgieTokenIds.push(tokenId);

    }

    function getMinterTokenIds() public view returns (uint[] memory) {
        return minterTokenIds[msg.sender];
    }

    function getDeployedHedgiez() public view returns (uint[] memory) {
        return deployedHedgiez;
    }
}