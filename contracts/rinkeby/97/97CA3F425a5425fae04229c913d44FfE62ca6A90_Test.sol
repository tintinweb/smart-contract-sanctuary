// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./ERC1155.sol";

contract Test is ERC1155 {
    address payable public admin;
    // uint256 public tokenId;
    uint256 public maxLimitCopies;
    uint256 public maxEditionPerCreator;
    // string[] public categories;

    struct creatorTokenIds {
        uint256[] tokenIds;
    }

    struct creators {
        address minter;
        address coCreator;
    }

    mapping(address => bool) public isApproved;
    mapping(uint256 => string) public tokenURI;
    mapping(uint256 => creators) public owner;
    mapping(address => uint256) public maxEditions;
    mapping(address => creatorTokenIds) private creatorIds;

    constructor(address payable _admin) ERC1155("") {
        admin = _admin;
        isApproved[admin] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only Owner can call this function");
        _;
    }

    function changeAdmin(address payable _admin) external onlyAdmin {
        admin = _admin;
    }

    function setMaxLimitCopies(uint256 _amount) external onlyAdmin {
        maxLimitCopies = _amount;
    }

    function setMaxEditions(uint256 _max) external onlyAdmin {
        require(_max > 0, "Zero max editions");
        maxEditionPerCreator = _max;
    }

    function approveCreator(address _creator) external onlyAdmin {
        require(!isApproved[_creator], "Already approved");
        isApproved[_creator] = true;
    }

    //approve creators in bulk
    function approveCreators(address[] memory _creators) external onlyAdmin {
        for (uint256 i = 0; i < _creators.length; i++) {
            isApproved[_creators[i]] = true;
        }
    }

    function disableCreator(address _creator) external onlyAdmin {
        require(isApproved[_creator], "Creator is not approved");
        isApproved[_creator] = false;
    }

    function disableCreators(address[] memory _creators) external onlyAdmin {
        for (uint256 i = 0; i < _creators.length; i++) {
            isApproved[_creators[i]] = false;
        }
    }

    function ownerOf(uint256 tokenId) public view returns (address, address) {
        return (owner[tokenId].minter, owner[tokenId].coCreator);
    }

    // Need to add ID from the front end;
    //add a check for tokenId
    //require(ownerOf(tokenId) != (address(0), address(0)), "Id exists");

    function mintEditionToken(
        address coCreator,
        uint256 tokenId,
        string memory _tokenURI
    ) external returns (bool) {
        address from = msg.sender;
        (address minter, ) = ownerOf(tokenId);
        require(minter == address(0), "Id exists");
        // require(_tokenURI != "", "Token URI not found");
        require(isApproved[from], "Only approved users can mint");
        if (from != admin) {
            require(
                maxEditions[from] <= maxEditionPerCreator,
                "Can't mint more than allowed editions"
            );
        }
        _mint(from, tokenId, 1, "");
        tokenURI[tokenId] = _tokenURI;
        creatorIds[from].tokenIds.push(tokenId);
        owner[tokenId] = creators(from, coCreator);
        tokenId++;
        maxEditions[from]++;
        return true;
    }

    function adminMint(
        string memory _tokenURI,
        uint256 tokenId,
        address _owner,
        uint256 _amount
    ) external onlyAdmin returns (bool) {
        require(_owner != address(0), "Zero address");
        (address minter, ) = ownerOf(tokenId);
        require(minter == address(0), "Id exists");
        // require(_owner != admin)
        _mint(_owner, tokenId, _amount, "");
        tokenURI[tokenId] = _tokenURI;
        creatorIds[_owner].tokenIds.push(tokenId);
        owner[tokenId] = creators(_owner, admin);
        tokenId++;
        return true;
    }

    function viewCreatorTokenIds(address _creator)
        external
        view
        returns (uint256[] memory)
    {
        return (creatorIds[_creator].tokenIds);
    }

    function mintTokenCopies(
        uint256 _amount,
        uint256 tokenId,
        address coCreator,
        string memory _tokenURI
    ) external returns (bool) {
        address from = msg.sender;
        (address minter, ) = ownerOf(tokenId);
        require(minter == address(0), "Id exists");
        require(_amount > 1, "Amount should be greater than one");
        if (from != admin) {
            require(
                _amount <= maxLimitCopies,
                "Can't mint more copies than allowed"
            );
            require(
                maxEditions[from] <= maxEditionPerCreator,
                "Can't mint more than allowed editions"
            );
        }
        require(isApproved[from], "Only approved users can mint");
        _mint(from, tokenId, _amount, "");
        tokenURI[tokenId] = _tokenURI;
        creatorIds[from].tokenIds.push(tokenId);
        owner[tokenId] = creators(from, coCreator);
        tokenId++;
        maxEditions[from]++;
        return true;
    }

    function burnToken(uint256 _id, uint256 _amount) external returns (bool) {
        address from = msg.sender;
        _burn(from, _id, _amount);
        delete owner[_id];
        return true;
    }
}