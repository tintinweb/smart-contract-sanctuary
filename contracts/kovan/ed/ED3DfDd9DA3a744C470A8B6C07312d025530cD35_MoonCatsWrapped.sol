// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


import "./Counters.sol";
import "./Strings.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./Address.sol";
import "./IERC165.sol";
import "./ERC165.sol";
import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./Context.sol";
import "./ERC721.sol";

// File: browser/MoonCatsWrapped.sol

interface MoonCatsRescue {
    struct AdoptionOffer {
        bool exists;
        bytes5 catId;
        address seller;
        uint price;
        address onlyOfferTo;
    }

    function acceptAdoptionOffer(bytes5 catId) external payable;
    function giveCat(bytes5 catId, address to) external;
    function adoptionOffers(bytes5 catId) external returns (AdoptionOffer memory);
}

contract MoonCatsWrapped is ERC721 {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    MoonCatsRescue public _moonCats = MoonCatsRescue(0x7A00B19eDc00fa5fB65F32B4D263CE753Df8f651);

    mapping(bytes5 => uint) public _catIDToTokenID;
    mapping(uint => bytes5) public  _tokenIDToCatID;
    string private _baseTokenURI;
    address public _owner = 0xaF826434ac09C398654670f78E7024AC276ff22B;


    event Wrapped(bytes5 indexed catId, uint tokenID);
    event Unwrapped(bytes5 indexed catId, uint tokenID);

    constructor() public ERC721("Wrapped MoonCatsRescue", "WMCR") {
//        _owner = _msgSender();
    }

    function setBaseURI(string memory _newBaseURI) public {
        require(_msgSender() == _owner);
        _baseTokenURI = _newBaseURI;
    }

    function renounceOwnership() public {
        require(_msgSender() == _owner);
        _owner = address(0x0);
    }


    function _baseURI() public view virtual returns (string memory) {
        return _baseTokenURI;
    }


    function wrap(bytes5 catId) public {
        MoonCatsRescue.AdoptionOffer memory offer = _moonCats.adoptionOffers(catId);
        require(offer.seller == _msgSender()); //only owner can wrap
        _moonCats.acceptAdoptionOffer(catId);


        //check if it was previously assigned
        uint tokenID = _catIDToTokenID[catId];
        uint tokenIDToAssign = tokenID;

        if (tokenID == 0) {
            tokenIDToAssign = _tokenIdTracker.current();
            _tokenIdTracker.increment();
            _catIDToTokenID[catId] = tokenIDToAssign;
            _tokenIDToCatID[tokenIDToAssign] = catId;
        }
        _mint(_msgSender(), tokenIDToAssign);
        emit Wrapped(catId, tokenIDToAssign);

    }

    function unwrap(uint256 tokenID) public {
        bytes5 catId = _tokenIDToCatID[tokenID];
        address owner = ownerOf(tokenID);
        require(owner == _msgSender()); //only owner can unwrap
        _moonCats.giveCat(catId, owner);
        _burn(tokenID);
        emit Unwrapped(catId, tokenID);
    }

}