pragma solidity 0.4.24;
pragma experimental "v0.5.0";
/******************************************************************************\
* Author: Nick Mudge, <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="741a1d171f34191b1f111a075a1d1b">[email&#160;protected]</a>
* Mokens
* Copyright (c) 2018
*
* Minting functions and mint price functions.
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
contract MokenMintingOneFree is Storage8 {

    uint256 constant MAX_MOKENS = 4294967296;
    uint256 constant MAX_OWNER_MOKENS = 65536;
    uint256 constant MOKEN_LINK_HASH_MASK = 0xffffffffffffffff000000000000000000000000000000000000000000000000;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Mint(
        address indexed mintContract,
        address indexed owner,
        bytes32 indexed era,
        string mokenName,
        bytes32 data,
        uint256 tokenId,
        bytes32 currencyName,
        uint256 price
    );

    event MintPriceChange(
        uint256 mintPrice
    );

    event MintPriceConfigurationChange(
        uint256 mintPrice,
        uint256 mintStepPrice,
        uint256 mintPriceOffset,
        uint256 mintPriceBuffer
    );

    event NewEra(
        uint256 index,
        bytes32 name,
        uint256 startTokenId
    );

    function setMintPrice(uint256 _mintPrice) external returns (uint256 mintPrice) {
        require(msg.sender == contractOwner, "Must own Mokens contract.");
        mintPriceBuffer = _mintPrice;
        mintStepPrice = 0;
        mintPriceOffset = 0;
        emit MintPriceConfigurationChange(_mintPrice, 0, 0, 0);
        emit MintPriceChange(_mintPrice);
        return _mintPrice;
    }

    function startNextEra_(bytes32 _eraName) internal returns (uint256 index, uint256 startTokenId) {
        require(_eraName != 0, "eraName is empty string.");
        require(eraIndex[_eraName] == 0, "Era name already exists.");
        startTokenId = mokensLength;
        index = eraLength++;
        eras[index] = _eraName;
        eraIndex[_eraName] = index + 1;
        emit NewEra(index, _eraName, startTokenId);
        return (index, startTokenId);
    }

    // It is predicted that often a new era comes with a mint price change
    function startNextEra(bytes32 _eraName, uint256 _mintPrice) external
    returns (uint256 index, uint256 startTokenId, uint256 mintPrice) {
        require(msg.sender == contractOwner, "Must own Mokens contract.");
        mintPriceBuffer = _mintPrice;
        mintStepPrice = 0;
        mintPriceOffset = 0;
        emit MintPriceConfigurationChange(_mintPrice, 0, 0, 0);
        emit MintPriceChange(_mintPrice);
        (index, startTokenId) = startNextEra_(_eraName);
        return (index, startTokenId, _mintPrice);
    }

    function mintData() external view returns (uint256 mokensLength_, uint256 mintStepPrice_, uint256 mintPriceOffset_) {
        return (mokensLength, 0, 0);
    }

    function mintPrice() external view returns (uint256) {
        return mintPriceBuffer;
    }

    function mint(address _tokenOwner, string _mokenName, bytes32 _linkHash) external payable returns (uint256 tokenId) {

        require(_tokenOwner != address(0), "Owner cannot be the 0 address.");

        tokenId = mokensLength++;
        // prevents 32 bit overflow
        require(tokenId < MAX_MOKENS, "Only 4,294,967,296 mokens can be created.");

        //Was enough ether passed in?
        uint256 currentMintPrice = mintPriceBuffer;
        uint256 ownedTokensIndex = ownedTokens[_tokenOwner].length;
        uint256 pricePaid;
        if(ownedTokensIndex == 0) {
            pricePaid = 0;
        }
        else {
            pricePaid = currentMintPrice;
            require(msg.value >= currentMintPrice, "Paid ether is lower than mint price.");
        }

        string memory lowerMokenName = validateAndLower(_mokenName);
        require(tokenByName_[lowerMokenName] == 0, "Moken name already exists.");

        uint256 eraIndex_ = eraLength - 1;

        // prevents 16 bit overflow
        require(ownedTokensIndex < MAX_OWNER_MOKENS, "An single owner address cannot possess more than 65,536 mokens.");

        // adding the current era index, ownedTokenIndex and owner address to data
        // this saves gas for each mint.
        uint256 data = uint256(_linkHash) & MOKEN_LINK_HASH_MASK | eraIndex_ << 176 | ownedTokensIndex << 160 | uint160(_tokenOwner);

        // create moken
        mokens[tokenId].name = _mokenName;
        mokens[tokenId].data = data;
        tokenByName_[lowerMokenName] = tokenId + 1;

        //add moken to the specific owner
        ownedTokens[_tokenOwner].push(uint32(tokenId));

        //emit events
        emit Transfer(address(0), _tokenOwner, tokenId);
        emit Mint(this, _tokenOwner, eras[eraIndex_], _mokenName, bytes32(data), tokenId, "Ether", pricePaid);

        //send minter the change if any
        if (msg.value > pricePaid) {
            msg.sender.transfer(msg.value - pricePaid);
        }

        return tokenId;
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