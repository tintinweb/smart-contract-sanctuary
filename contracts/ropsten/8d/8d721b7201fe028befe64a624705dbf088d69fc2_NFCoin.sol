// SPDX-License-Identifier: GPL3.0
pragma solidity ^0.8.0;

import "./ERC721.sol";

/// @title Implement the ERC-721 Non-Fungible Token Standard
/// @author HUST Blockchain Research Group
///  Note: Blockchain course assignment code, Group ID 7
contract NFCoin is ERC721 {
    /// @dev NFT structure
    struct asset {
        // the id number of the token
        uint256 tokenId;
        // The owner of the token
        address owner;
        // Has been granted access
        address approver;
        // Store the data bytes
        bytes data;
        // Store the timestamp when the asset is changing
        uint256 timestamp;
        // bool isAllAuthorized;
    }
    
    /// @dev Only the talents of the foundation can set up assets
    address private fundation;
    modifier onlyFundation() {
        require(msg.sender == fundation);
        _;
    }
    constructor() {
        fundation = msg.sender;
    }
    
    /// @dev This variable is used to get the balance
    mapping(address => uint256) balance;
    
    /// @dev This variable is used to get the address of the token holder
    mapping(uint256 => asset) tokens;
    
    /// @dev The caller grants the right of a certain token to an account
    // mapping(address => mapping(address => uint256)) approvedToken;
    
    /// @dev Authorized address of a certain token
    // mapping(uint256 => address) approvedAddress;
    
    /// @dev Whether the storage account is authorized of all tokens
    mapping(address => mapping(address => bool)) isAllAuthorized;
    
    /// @param number is the parameter which user should input
    function setAsset(uint256 number, address owner, bytes memory data) onlyFundation public returns (asset memory){
        require(owner != address(0));
        uint256 _tokenId = uint256(keccak256(abi.encodePacked(number, owner, msg.sender, block.timestamp)));
        require(tokens[_tokenId].tokenId != _tokenId);
        asset memory newAsset = asset(_tokenId, owner, address(0), data, block.timestamp);
        tokens[_tokenId] = newAsset;
        balance[owner] += 1;
        return tokens[_tokenId];
    }
    
    /// @dev Returns the number of NFTs held by _owner
    function balanceOf(address _owner) override external view returns (uint256) {
        /// @dev Determine that the address is not zero
        require(_owner != address(0));
        return balance[_owner];
    }
    
    /// @dev Returns the address of the token holder of the tokenId
    function ownerOf(uint256 _tokenId) override external view returns (address) {
        require(_tokenId != 0);
        return tokens[_tokenId].owner;
    }
    
    /// @dev Authorize an account to have the right to transfer a certain token
    function approve(address _approved, uint256 _tokenId) override external payable {
        require(tokens[_tokenId].owner == msg.sender);
        require(_tokenId != 0);
        // approvedToken[msg.sender][_approved] = _tokenId;
        tokens[_tokenId].approver = _approved;
    }
    
    /// @dev Grant address _operator to have control of all tokens
    function setApprovalForAll(address _operator, bool _approved) override external {
        require(_operator != address(0));
        require(isAllAuthorized[msg.sender][_operator] != _approved);
        isAllAuthorized[msg.sender][_operator] = _approved;
    }

    /// @dev Obtain authorization address based on TokenId
    function getApproved(uint256 _tokenId) override external view returns (address) {
        require(_tokenId != 0);
        return tokens[_tokenId].approver;
    }
    
    /// @dev Determine whether an address has control of all tokens
    function isApprovedForAll(address _owner, address _operator) override external view returns (bool) {
        require(_owner != address(0) && _operator != address(0));
        return isAllAuthorized[_owner][_operator];
    }
    
    /// @dev Transfer with security check and data
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) override external payable {
        require(_from != address(0) && _to != address(0) && _tokenId != 0);
        require(isContract(_to) == false);
        require(tokens[_tokenId].owner == _from);
        require(msg.sender == _from || tokens[_tokenId].approver == msg.sender || isAllAuthorized[_from][_to]);
        // Asset transfer
        tokens[_tokenId].owner = _to;
        // Approver reset
        tokens[_tokenId].approver = address(0);
        tokens[_tokenId].timestamp = block.timestamp;
        tokens[_tokenId].data = data;
        // Adjust the balance to complete the data transfer
        balance[_from] -= 1;
        balance[_to] += 1;
    }
    
    /// @dev Transfer with security check
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable {
        require(_from != address(0) && _to != address(0) && _tokenId != 0);
        require(isContract(_to) == false);
        require(tokens[_tokenId].owner == _from);
        require(msg.sender == _from || tokens[_tokenId].approver == msg.sender || isAllAuthorized[_from][_to]);
        // Asset transfer
        tokens[_tokenId].owner = _to;
        // Approver reset
        tokens[_tokenId].approver = address(0);
        tokens[_tokenId].timestamp = block.timestamp;
        // Adjust the balance to complete the data transfer
        balance[_from] -= 1;
        balance[_to] += 1;
    }
    
    /// @dev Can transfer money to smart contract
    function transferFrom(address _from, address _to, uint256 _tokenId) override external payable {
        require(_from != address(0) && _to != address(0) && _tokenId != 0);
        require(tokens[_tokenId].owner == _from);
        require(msg.sender == _from || tokens[_tokenId].approver == msg.sender || isAllAuthorized[_from][_to]);
        // Asset transfer
        tokens[_tokenId].owner = _to;
        // Approver reset
        tokens[_tokenId].approver = address(0);
        tokens[_tokenId].timestamp = block.timestamp;
        // Adjust the balance to complete the data transfer
        balance[_from] -= 1;
        balance[_to] += 1;
    }
    
    /// @dev Determine whether it is a smart contract
    function isContract(address _contract) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_contract)
        }
        return size > 0;
    }
}