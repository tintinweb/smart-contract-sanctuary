//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Strings.sol";


contract OortERC1155 is ERC1155Upgradeable,OwnableUpgradeable{
    //contract name
    string public name;
    //contract symbol
    string public symbol;

    struct AirdropUserInfo {
        //the count can claim
        uint canClaimCount;
        //the count of claimed
        uint claimedCount;
    }

    //Mapping from clan to airdrop info
    mapping(uint => mapping(address => AirdropUserInfo)) public airdropUserInfoMap;
    //Mapping from clan to tokenId
    mapping(uint => uint256) public tokenIdMap;
    //Mapping from clan to ipfs folder hash
    mapping(uint => string) public ipfsFolderMap;

    function initialize(string memory _name, string memory _symbol, string memory baseURI) public initializer {
        name = _name;
        symbol = _symbol;
        __ERC1155_init(baseURI);
        __Ownable_init();
    }

    function importWhiteList(uint clan,address[] memory users, uint[] memory counts,uint256 startTokenId,string memory ipfsFolder) public onlyOwner{
        require(users.length == counts.length,"users'length and counts'length don't match");

        tokenIdMap[clan] = startTokenId;
        ipfsFolderMap[clan] = ipfsFolder;

        //record airdrop user's level
        for (uint i = 0; i < users.length; i++) {
            AirdropUserInfo memory user = AirdropUserInfo(counts[i], 0);
            airdropUserInfoMap[clan][users[i]] = user;
        }
    }

    //mint heroes
    function mintHeroes(uint clan) public returns(uint256[] memory){
        uint canClaimCount = airdropUserInfoMap[clan][msg.sender].canClaimCount;
        require(canClaimCount > 0, "You don't have NFT to claim");
        require(canClaimCount > airdropUserInfoMap[clan][msg.sender].claimedCount, "You've got all nft");

        uint256[] memory tokenIds = new uint256[](canClaimCount);
        uint[] memory amounts = new uint[](canClaimCount);
        for (uint i = 0; i < canClaimCount; i++) {
            tokenIds[i] = tokenIdMap[clan];
            amounts[i] = 1;
            tokenIdMap[clan]++;
        }

        _mintBatch(msg.sender, tokenIds, amounts, '');

        airdropUserInfoMap[clan][msg.sender].claimedCount = canClaimCount;

        return tokenIds;
    }

    //to solve the problem that opensea unable to parse the metadata normally
    function uri(uint256 _id) public view override returns (string memory) {
        uint clan = 0;
        while(tokenIdMap[clan + 1] > 0 && tokenIdMap[clan + 1] < _id){
            clan++;
        }
        string memory path = Strings.strConcat(_uri,ipfsFolderMap[clan]);
        return Strings.strConcat(path,Strings.uint2str(_id));
    }

    //change folder hash of ipfs
    function changeFolder(uint clan,string memory folder) public onlyOwner{
        ipfsFolderMap[clan] = folder;
    }
}