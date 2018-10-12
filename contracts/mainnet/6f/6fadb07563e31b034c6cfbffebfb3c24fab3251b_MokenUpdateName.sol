pragma solidity 0.4.24;
pragma experimental "v0.5.0";
/******************************************************************************\
* Author: Nick Mudge, <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="07696e646c476a686c626974296e68">[email&#160;protected]</a>
* Mokens
* Copyright (c) 2018
*
* Update the name of a moken.
/******************************************************************************/
///////////////////////////////////////////////////////////////////////////////////
//Storage contracts
////////////
//Some delegate contracts are listed with storage contracts they inherit.
///////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////
//Mokens
///////////////////////////////////////////////////////////////////////////////////
contract Storage0 {
    // funcId => delegate contract
    mapping(bytes4 => address) internal delegates;
}
///////////////////////////////////////////////////////////////////////////////////
//MokenUpdates
//MokenOwner
//QueryMokenDelegates
///////////////////////////////////////////////////////////////////////////////////
contract Storage1 is Storage0 {
    address internal contractOwner;
    bytes[] internal funcSignatures;
    // signature => index+1
    mapping(bytes => uint256) internal funcSignatureToIndex;
}
///////////////////////////////////////////////////////////////////////////////////
//MokensSupportsInterfaces
///////////////////////////////////////////////////////////////////////////////////
contract Storage2 is Storage1 {
    mapping(bytes4 => bool) internal supportedInterfaces;
}
///////////////////////////////////////////////////////////////////////////////////
//MokenRootOwnerOf
//MokenERC721Metadata
///////////////////////////////////////////////////////////////////////////////////
contract Storage3 is Storage2 {
    struct Moken {
        string name;
        uint256 data;
        uint256 parentTokenId;
    }
    //tokenId => moken
    mapping(uint256 => Moken) internal mokens;
    uint256 internal mokensLength;
    // child address => child tokenId => tokenId+1
    mapping(address => mapping(uint256 => uint256)) internal childTokenOwner;
}
///////////////////////////////////////////////////////////////////////////////////
//MokenERC721Enumerable
//MokenLinkHash
///////////////////////////////////////////////////////////////////////////////////
contract Storage4 is Storage3 {
    // root token owner address => (tokenId => approved address)
    mapping(address => mapping(uint256 => address)) internal rootOwnerAndTokenIdToApprovedAddress;
    // token owner => (operator address => bool)
    mapping(address => mapping(address => bool)) internal tokenOwnerToOperators;
    // Mapping from owner to list of owned token IDs
    mapping(address => uint32[]) internal ownedTokens;
}
///////////////////////////////////////////////////////////////////////////////////
//MokenERC998ERC721TopDown
//MokenERC998ERC721TopDownBatch
//MokenERC721
//MokenERC721Batch
///////////////////////////////////////////////////////////////////////////////////
contract Storage5 is Storage4 {
    // tokenId => (child address => array of child tokens)
    mapping(uint256 => mapping(address => uint256[])) internal childTokens;
    // tokenId => (child address => (child token => child index)
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) internal childTokenIndex;
    // tokenId => (child address => contract index)
    mapping(uint256 => mapping(address => uint256)) internal childContractIndex;
    // tokenId => child contract
    mapping(uint256 => address[]) internal childContracts;
}
///////////////////////////////////////////////////////////////////////////////////
//MokenERC998ERC20TopDown
//MokenStateChange
///////////////////////////////////////////////////////////////////////////////////
contract Storage6 is Storage5 {
    // tokenId => token contract
    mapping(uint256 => address[]) internal erc20Contracts;
    // tokenId => (token contract => token contract index)
    mapping(uint256 => mapping(address => uint256)) erc20ContractIndex;
    // tokenId => (token contract => balance)
    mapping(uint256 => mapping(address => uint256)) internal erc20Balances;
}
///////////////////////////////////////////////////////////////////////////////////
//MokenERC998ERC721BottomUp
//MokenERC998ERC721BottomUpBatch
///////////////////////////////////////////////////////////////////////////////////
contract Storage7 is Storage6 {
    // parent address => (parent tokenId => array of child tokenIds)
    mapping(address => mapping(uint256 => uint32[])) internal parentToChildTokenIds;
    // tokenId => position in childTokens array
    mapping(uint256 => uint256) internal tokenIdToChildTokenIdsIndex;
}
///////////////////////////////////////////////////////////////////////////////////
//MokenMinting
//MokenMintContractManagement
//MokenEras
//QueryMokenData
///////////////////////////////////////////////////////////////////////////////////
contract Storage8 is Storage7 {
    // index => era
    mapping(uint256 => bytes32) internal eras;
    uint256 internal eraLength;
    // era => index+1
    mapping(bytes32 => uint256) internal eraIndex;
    uint256 internal mintPriceOffset; // = 0 szabo;
    uint256 internal mintStepPrice; // = 500 szabo;
    uint256 internal mintPriceBuffer; // = 5000 szabo;
    address[] internal mintContracts;
    mapping(address => uint256) internal mintContractIndex;
    //moken name => tokenId+1
    mapping(string => uint256) internal tokenByName_;
}
contract MokenUpdateName is Storage8 {

    event MokenNameChange(
        uint256 indexed tokenId,
        string mokenName
    );

    function updateMokenName(uint256 _tokenId, string _newName) external {
        require(msg.sender == contractOwner, "Must own Mokens contract.");
        string memory currentName = mokens[_tokenId].name;
        require(bytes(currentName).length != 0, "The tokenId does not exist.");
        delete tokenByName_[validateAndLower(currentName)];
        mokens[_tokenId].name = _newName;
        tokenByName_[validateAndLower(_newName)] = _tokenId +1;
        emit MokenNameChange(_tokenId, _newName);
    }

    function validateAndLower(string _s) internal pure returns (string mokenName) {
        assembly {
        // get length of _s
            let len := mload(_s)
        // get position of _s
            let p := add(_s, 0x20)
        // _s cannot be 0 characters
            if eq(len, 0) {
                revert(0, 0)
            }
        // _s cannot be more than 100 characters
            if gt(len, 100) {
                revert(0, 0)
            }
        // get first character
            let b := byte(0, mload(add(_s, 0x20)))
        // first character cannot be whitespace/unprintable
            if lt(b, 0x21) {
                revert(0, 0)
            }
        // get last character
            b := byte(0, mload(add(p, sub(len, 1))))
        // last character cannot be whitespace/unprintable
            if lt(b, 0x21) {
                revert(0, 0)
            }
        // loop through _s and lowercase uppercase characters
            for {let end := add(p, len)}
            lt(p, end)
            {p := add(p, 1)}
            {
                b := byte(0, mload(p))
                if lt(b, 0x5b) {
                    if gt(b, 0x40) {
                        mstore8(p, add(b, 32))
                    }
                }
            }
        }
        return _s;
    }
}