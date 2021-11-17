/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// ERC-721 Helper v0.9.2.test
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to Rinkeby 0x70675B00d0EA2f34095630AD9b4D1cF81E6235EF
//
// SPDX-License-Identifier: MIT
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2021. The MIT Licence.
// ----------------------------------------------------------------------------

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721Metadata is ERC721 {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface ERC721Enumerable is ERC721 {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


contract ERC721Helper {
    
    bytes4 private constant ERC721_INTERFACE = 0x80ac58cd;
    bytes4 private constant ERC721METADATA_INTERFACE = 0x5b5e139f;
    bytes4 private constant ERC721ENUMERABLE_INTERFACE = 0x780e9d63;

    uint public constant ISERC721 = 2**0;
    uint public constant ISERC721METADATA = 2**1;
    uint public constant ISERC721ENUMERABLE = 2**2;

    
    function tokenInfo(address[] memory tokens) external view returns(uint[] memory statuses, string[] memory symbols, string[] memory names, uint[] memory totalSupplys) {
        statuses = new uint[](tokens.length);
        symbols = new string[](tokens.length);
        names = new string[](tokens.length);
        totalSupplys = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint status = 0;
            try ERC165(token).supportsInterface(ERC721_INTERFACE) returns (bool isERC721) {
                if (isERC721) {
                    status |= ISERC721;

                    try ERC165(token).supportsInterface(ERC721METADATA_INTERFACE) returns (bool isERC721Metadata) {
                        if (isERC721Metadata) {
                            status |= ISERC721METADATA;
                            try ERC721Metadata(token).symbol() returns (string memory s) {
                                symbols[i] = s;
                            } catch {
                            }
                            try ERC721Metadata(token).name() returns (string memory n) {
                                names[i] = n;
                            } catch {
                            }
                        }
                    } catch {
                    }
                    try ERC165(token).supportsInterface(ERC721ENUMERABLE_INTERFACE) returns (bool isERC721Enumerable) {
                        if (isERC721Enumerable) {
                            status |= ISERC721ENUMERABLE;
                            try ERC721Enumerable(token).totalSupply() returns (uint256 ts) {
                                totalSupplys[i] = ts;
                            } catch {
                            }
                        }
                    } catch {
                    }
                }
                statuses[i] = status;            
            } catch {
            }
        }
    }

    function tokenURIsByTokenIds(address token, uint[] memory tokenIds) external view returns(bool[] memory successes, string[] memory tokenURIs) {
        tokenURIs = new string[](tokenIds.length);
        successes = new bool[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            try ERC721Metadata(token).tokenURI(tokenIds[i]) returns (string memory s) {
                tokenURIs[i] = s;
                successes[i] = true;
            } catch {
            }
        }
    }

    function ownersByTokenIds(address token, uint[] memory tokenIds) external view returns(bool[] memory successes, address[] memory owners) {
        owners = new address[](tokenIds.length);
        successes = new bool[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++) {
            try ERC721(token).ownerOf(tokenIds[i]) returns (address a) {
                owners[i] = a;
                successes[i] = true;
            } catch {
            }
        }
    }

    function tokenURIsByEnumerableIndex(address token, uint from, uint to) external view returns(uint[] memory tokenIds, string[] memory tokenURIs) {
        require(from < to);
        tokenIds = new uint[](to - from);
        tokenURIs = new string[](to - from);
        uint i = 0;
        for (uint index = from; index < to; index++) {
            try ERC721Enumerable(token).tokenByIndex(index) returns (uint256 tokenId) {
                tokenIds[i] = tokenId;
                try ERC721Metadata(token).tokenURI(tokenId) returns (string memory s) {
                    tokenURIs[i] = s;
                } catch {
                }
            } catch {
            }
            i++;
        }
    }

    function ownersByEnumerableIndex(address token, uint from, uint to) external view returns(uint[] memory tokenIds, address[] memory owners) {
        require(from < to);
        tokenIds = new uint[](to - from);
        owners = new address[](to - from);
        uint i = 0;
        for (uint index = from; index < to; index++) {
            try ERC721Enumerable(token).tokenByIndex(index) returns (uint256 tokenId) {
                tokenIds[i] = tokenId;
                try ERC721(token).ownerOf(tokenId) returns (address a) {
                    owners[i] = a;
                } catch {
                }
            } catch {
            }
            i++;
        }
    }
}