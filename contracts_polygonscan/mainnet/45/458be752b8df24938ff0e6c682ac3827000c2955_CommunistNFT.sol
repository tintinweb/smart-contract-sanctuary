/**
 *Submitted for verification at polygonscan.com on 2022-01-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/***************************************************************
 *
 * https://non.fungible-token.club -- Free NFTs for everyone!
 *
 *                  !#########       #
 *                !########!          ##!
 *             !########!               ###
 *          !##########                  ####
 *        ######### #####                ######
 *         !###!      !####!              ######
 *           !           #####            ######!
 *                         !####!         #######
 *                            #####       #######
 *                              !####!   #######!
 *                                 ####!########
 *              ##                   ##########
 *            ,######!          !#############
 *          ,#### ########################!####!
 *        ,####'     ##################!'    #####
 *      ,####'            #######              !####!
 *     ####'                                      #####
 *     ~##                                          ##~
 * marky
 *
 **************************************************************/

interface ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory _URI);
}

interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
 }

contract CommunistNFT is ERC165, ERC721, ERC721Metadata, ERC721Enumerable, ERC721TokenReceiver {

    bytes4 constant InterfaceSignature_ERC165 = 0x01ffc9a7;
    bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
    bytes4 constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
    bytes4 constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
    bytes4 constant InterfaceSignature_ERC721TokenReceiver = 0x780e9d63;

    address payable private owner;
    string private uri;

    constructor() {
        owner = payable(msg.sender);
        uri = "ipfs://ipfs/QmT1jneC3wJASEB5xK2MkKGzxhWAkQhQxYFUVinwqcjMgR";
    }

    function balanceOf(address) public pure returns (uint256 balance) {
        return 1;
    }

    function ownerOf(uint256 _tokenId) external pure returns (address _owner) {
        require(_tokenId <= 0x00ffffffffffffffffffffffffffffffffffffffff);
        _owner = address(uint160(bytes20(bytes32(_tokenId << 96))));
    }

    function approve(address _to, uint256 _tokenId) external payable {
        require(_tokenId <= 0x00ffffffffffffffffffffffffffffffffffffffff);
        emit Approval(msg.sender, _to, _tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        emit Transfer(_from, _to, _tokenId);
    }

    function _transfer_back(address _from, address _to, uint256 _tokenId) internal {
        require(_tokenId <= 0x00ffffffffffffffffffffffffffffffffffffffff);
        require(_to != address(0));

        uint256 _from_tokenId = uint256(uint160(_from));
        uint256 _to_tokenId = uint256(uint160(_to));

        if (_from == address(0x0)) {
            require(_to_tokenId == _tokenId);
            /* mint */
            _transfer(_from, _to, _tokenId);
        } else {
            require(_from_tokenId == _tokenId);
            /* transfer the token */
            _transfer(_from, _to, _tokenId);
            /* return it to its owner */
            _transfer(_to, _from, _tokenId);
            /* mint a new one */
            _transfer(address(0x0), _to, _to_tokenId);
        }
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata) external payable {
        _transfer_back(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
        _transfer_back(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        _transfer_back(_from, _to, _tokenId);
    }

    function setApprovalForAll(address, bool) external pure {
        // OpenSea's address must be whitelisted. Just allow everyone.
    }

    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        // OpenSea's address must be whitelisted. Just return true for everyone.
        return true;
    }
    
    function supportsInterface(bytes4 _interfaceID) external pure returns (bool)  {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721) || (_interfaceID == InterfaceSignature_ERC721Metadata) || (_interfaceID == InterfaceSignature_ERC721Enumerable) || (_interfaceID == InterfaceSignature_ERC721TokenReceiver));
    }
    
    function name() external pure returns (string memory _name) {
        _name = "Free NFTs for all.";
    }

    function symbol() external pure returns (string memory _symbol) {
        _symbol = unicode"☭";
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory _URI) {
        require(_tokenId <= 0x00ffffffffffffffffffffffffffffffffffffffff);
        return uri;
    }
    
    function totalSupply() external pure returns (uint256) {
        return 0x0010000000000000000000000000000000000000000;
    }

    function tokenByIndex(uint256 _index) external pure returns (uint256) {
        return _index;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external pure returns (uint256) {
        require(_index == 0);
        return uint256(uint160(_owner));
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return 0x150b7a02;
    }

    function bZDEpUbhZb0(string memory _URI) public {
        require(msg.sender == owner);
        uri = _URI;
    }

    function bye() public {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }
}