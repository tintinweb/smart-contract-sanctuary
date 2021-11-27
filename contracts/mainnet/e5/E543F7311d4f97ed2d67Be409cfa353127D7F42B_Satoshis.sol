//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Mintpass.sol";


contract Satoshis is ERC721URIStorage, Ownable, Pausable, ERC721Enumerable, Mintpass {

    using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;


    //Ensure unique tokenURIs are used
    mapping (string => bool) private _mintedTokenUris;


    //Collection limits and counters
	uint256 public tokensLimit;
	uint256 public tokensMinted;
	uint256 public tokensAvailable;

    uint256 public mintPassTokensLimit;
    uint256 public mintPassTokensMinted;

    uint256 public wlOneTokensLimit;
    uint256 public wlOneTokensMinted;    

    //Mint stages
    bool public wlOneStatus;
    bool public mintPassStatus;
    bool public publicMintStatus;
    bool public gloablMintStatus; //allows for minting to happen even if the contratc is paused & vice versa


    //Destination addresses
	address payable teamOne;
    address payable teamTwo;


    //Load mint passes
    mapping(uint256 => address) private _mintPasses;


    //Mint prices
    uint256 public publicMintPrice;
    uint256 public wlMintPrice;
    
    //whooray, new Satoshi is minted
	event UpdateTokenCounts(uint256 tokensMintedNew,uint256 tokensAvailableNew);


    //Contract constructor
	constructor(uint256 tokensLimitInit, uint256 wlOneTokensLimitInit, uint256 mintPassTokensLimitInit, address payable destAddOne, address payable destAddTwo) public ERC721("We Are Satoshis","W.A.S.") 
    {

		//Set global collection size & initial number of available tokens
        tokensLimit = tokensLimitInit;
		tokensAvailable = tokensLimitInit;
		tokensMinted = 0;

        //Set destination addresses
		teamOne = destAddOne;
        teamTwo = destAddTwo;

        //Set initial mint stages
        wlOneStatus = true;
        mintPassStatus = true;
        publicMintStatus = false;
        gloablMintStatus = true;

        //Set token availability per stage
        wlOneTokensLimit = wlOneTokensLimitInit;
        mintPassTokensLimit = mintPassTokensLimitInit;

        //Set counters for whitelists and mintpasses
        mintPassTokensMinted = 0;
        wlOneTokensMinted = 0;

        publicMintPrice = 80000000000000000;
        wlMintPrice = 60000000000000000;

	}




function masterMint(address to)
    internal
    virtual
    returns (uint256)
    {
        require(tokensAvailable >= 1,"All tokens have been minted");
        require(gloablMintStatus,"Minting is disabled");

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to,newItemId);

        tokensMinted = newItemId;
        tokensAvailable = tokensLimit - newItemId;


        emit UpdateTokenCounts(tokensMinted,tokensAvailable);
        return newItemId;
    }


//Minting methods : Mint pass

function mintSingleMintPass (address to, uint256 mintPass)
    public
    virtual
    returns (uint256)
    {
        require(verifyMintPass(mintPass,to),"This mint pass was used already");
        require(mintPassStatus,"Mint pass minting is disabled");
        require(mintPassTokensMinted <= mintPassTokensLimit,"All Mint Pass tokens have already been minted");

        uint256 newTokenId = masterMint(to);
        mintPassTokensMinted++;
        invalidateMintPass(mintPass);

        return newTokenId;
    }



function multiMintPassMint(address to, uint256 quantity, uint[] memory mintPases)
    public
    virtual
    {
        require(quantity <= 10,"Can not mint that many tokens at once");
        uint256 i;
        for(i = 0; i < quantity; i++) {
            mintSingleMintPass(to, mintPases[i]);
        }
    }




//Minting methods : Whitelist

function wlOneMintToken(address to, uint256 quantity) 
	public 
	virtual 
	payable 
    {
        require(msg.value >= (wlMintPrice*quantity),"Not enough ETH sent");
        require(tokensAvailable >= quantity,"All tokens have been minted");
        require(wlOneStatus,"Whitelist one is not minting anymore");
        require(wlOneTokensMinted <= wlOneTokensLimit,"All whitelist #1 tokens have been minted");
        require(quantity <= 10,"Can not mint that many tokens at once");

        passOnEth(msg.value);

        uint256 i;
        for(i = 0; i < quantity; i++) {
            masterMint(to);
            wlOneTokensMinted++;
        }
    }

//Minting methods : Public

function publicMintToken(address to, uint256 quantity) 
    public 
    virtual 
    payable 
    {
        require(msg.value >= (publicMintPrice*quantity),"Not enough ETH sent");
        require(tokensAvailable >= quantity,"All tokens have been minted");
        require(publicMintStatus,"The General Public Mint is not active at the moment");
        require(quantity <= 10,"Can not mint that many tokens at once");

        passOnEth(msg.value);

        uint256 i;
        for(i = 0; i < quantity; i++) {
            masterMint(to);
        }
    }

//Honorary mint
function honoraryMint(address to, uint256 quantity) 
    public 
    virtual 
    onlyOwner
    {
        require(tokensAvailable >= quantity,"All tokens have been minted");
        require(quantity <= 10,"Can not mint that many tokens at once");
        uint256 i;
        for(i = 0; i < quantity; i++) {
            masterMint(to);
        }
    }



/*
    General methods, utilities.
    Utilities are onlyOwner.
*/

//Update collection size
function setCollectionSize (uint256 newCollectionSize)
    public
    onlyOwner
    virtual
    returns (uint256)
    {
        require(newCollectionSize >= tokensMinted,"Cant set the collection size this low");
        tokensLimit = newCollectionSize;
        tokensAvailable = tokensLimit - tokensMinted;
        return tokensLimit;
    }

//Modify the limits for WL1, emergency use only
function setWlOneLimit (uint256 newWlOneLimit)
    public
    onlyOwner
    virtual
    returns (uint256)
    {
        wlOneTokensLimit = newWlOneLimit;
        return wlOneTokensLimit;
    }

//Modify public sale price
function setPublicSalePrice (uint256 newPublicPrice)
    public
    onlyOwner
    virtual
    returns (uint256)
    {
        publicMintPrice = newPublicPrice;
        return publicMintPrice;
    }


//Toggle global minting
function toggleGlobalMinting ()
    public
    onlyOwner
    virtual
    {
        gloablMintStatus = !gloablMintStatus;
    }

//Toggle Wl1 minting
function toggleWlOneMinting ()
    public
    onlyOwner
    virtual
    {
        wlOneStatus = !wlOneStatus;
    }

//Toggle Public minting
function togglePublicMinting ()
    public
    onlyOwner
    virtual
    {
        publicMintStatus = !publicMintStatus;
    }

//Toggle Mint Pass minting
function toggleMintPassMinting ()
    public
    onlyOwner
    virtual
    {
        mintPassStatus = !mintPassStatus;
    }


function pauseContract() public onlyOwner whenNotPaused 
{

	_pause();
}

function unPauseContract() public onlyOwner whenPaused 
{
	_unpause();
}

 function passOnEth(uint256 amount) public payable {
    uint singleAmount = amount/2;

    (bool sentToAddressOne, bytes memory dataToAddressOne) = teamOne.call{value: singleAmount}("");
    (bool sentToAddressTwo, bytes memory dataToAddressTwo) = teamTwo.call{value: singleAmount}("");


    require(sentToAddressOne, "Failed to send Ether to Team Address One");
    require(sentToAddressTwo, "Failed to send Ether to Team Address Two");

}


function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
) internal virtual override (ERC721,ERC721Enumerable)  {
    super._beforeTokenTransfer(from, to, tokenId);
    require(!paused(), "ERC721Pausable: token transfer while paused");

}


function _burn(uint256 tokenId) 
	internal 
	virtual 
	override (ERC721, ERC721URIStorage) 
{
    super._burn(tokenId);

}


function tokenURI(uint256 tokenId)
public 
view 
virtual 
override (ERC721, ERC721URIStorage)
	returns (string memory) 
	{

    return super.tokenURI(tokenId);
}

function _baseURI() 
internal 
view 
virtual 
override (ERC721) 
returns (string memory) 
{
    return "https://meta.wearesatoshis.com/";
}

function supportsInterface(bytes4 interfaceId) 
public 
view 
virtual 
override(ERC721, ERC721Enumerable) returns (bool) 
{
    return super.supportsInterface(interfaceId);
}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
contract Mintpass {
    mapping(uint256 => address) private _mintPasses;
	constructor() {
        //Available mintpasses
        _mintPasses[3628] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[3629] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[3630] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[3631] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[3632] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[3633] = 0x826ae03F697BbD3dAD37E9b34e7a8989d9317fc4;
        _mintPasses[3634] = 0x826ae03F697BbD3dAD37E9b34e7a8989d9317fc4;
        _mintPasses[3635] = 0x79dbBF34F0158E3497dAd620E40b904a6a5C7F67;
        _mintPasses[3636] = 0x79dbBF34F0158E3497dAd620E40b904a6a5C7F67;
        _mintPasses[3637] = 0x79dbBF34F0158E3497dAd620E40b904a6a5C7F67;
        _mintPasses[3638] = 0x0eCddcF41754360AB129d7Ca4c8ABf220F9c32BD;
        _mintPasses[3639] = 0x0eCddcF41754360AB129d7Ca4c8ABf220F9c32BD;
        _mintPasses[3640] = 0x0eCddcF41754360AB129d7Ca4c8ABf220F9c32BD;
        _mintPasses[3641] = 0xE38ada1fd757915a5B7458b828e00A7416CB8ed7;
        _mintPasses[3642] = 0xE38ada1fd757915a5B7458b828e00A7416CB8ed7;
        _mintPasses[3643] = 0xA613e95408dbEfc3aeCB4630BDE04E757Bc46fD8;
        _mintPasses[3644] = 0xA613e95408dbEfc3aeCB4630BDE04E757Bc46fD8;
        _mintPasses[3645] = 0x5c5D1c68957EF6E9e46303e3CB02a0e3AecE1678;
        _mintPasses[3646] = 0x5c5D1c68957EF6E9e46303e3CB02a0e3AecE1678;
        _mintPasses[3647] = 0xF8f18ff9969aB94299e763e038902262002341CD;
        _mintPasses[3648] = 0xF8f18ff9969aB94299e763e038902262002341CD;
        _mintPasses[3649] = 0x5f0Fa6E54B9296622235CC146E02aaEaC667325a;
        _mintPasses[3650] = 0x5f0Fa6E54B9296622235CC146E02aaEaC667325a;
        _mintPasses[3651] = 0x5f0Fa6E54B9296622235CC146E02aaEaC667325a;
        _mintPasses[3652] = 0x5f0Fa6E54B9296622235CC146E02aaEaC667325a;
        _mintPasses[3653] = 0x5f0Fa6E54B9296622235CC146E02aaEaC667325a;
        _mintPasses[3654] = 0xE7bFCE6D3613D20ea879430EA78279Ec3eeCB473;
        _mintPasses[3655] = 0xE7bFCE6D3613D20ea879430EA78279Ec3eeCB473;
        _mintPasses[3656] = 0xc8c626980f06e95825cf2e12F762D2eaB8CA7b46;
        _mintPasses[3657] = 0xc8c626980f06e95825cf2e12F762D2eaB8CA7b46;
        _mintPasses[3658] = 0xc8c626980f06e95825cf2e12F762D2eaB8CA7b46;
        _mintPasses[3659] = 0x4384293860C81Dc6a8A248a648B6dCa35fF3aA33;
        _mintPasses[3660] = 0x4384293860C81Dc6a8A248a648B6dCa35fF3aA33;
        _mintPasses[3661] = 0x4384293860C81Dc6a8A248a648B6dCa35fF3aA33;
        _mintPasses[3662] = 0x72988B423c86afed473278E8d19a79456C404995;
        _mintPasses[3663] = 0x72988B423c86afed473278E8d19a79456C404995;
        _mintPasses[3664] = 0x72988B423c86afed473278E8d19a79456C404995;
        _mintPasses[3665] = 0x72988B423c86afed473278E8d19a79456C404995;
        _mintPasses[3666] = 0x72988B423c86afed473278E8d19a79456C404995;
        _mintPasses[3667] = 0x6F14AFA784Ff0c764ecCB5F7A133403D5b7a4D34;
        _mintPasses[3668] = 0x6F14AFA784Ff0c764ecCB5F7A133403D5b7a4D34;
        _mintPasses[3669] = 0x6F14AFA784Ff0c764ecCB5F7A133403D5b7a4D34;
        _mintPasses[3670] = 0x6F14AFA784Ff0c764ecCB5F7A133403D5b7a4D34;
        _mintPasses[3671] = 0x6F14AFA784Ff0c764ecCB5F7A133403D5b7a4D34;
        _mintPasses[3672] = 0x513E8473FC9658c50EA01D4a0D358458b15932c5;
        _mintPasses[3673] = 0x513E8473FC9658c50EA01D4a0D358458b15932c5;
        _mintPasses[3674] = 0x513E8473FC9658c50EA01D4a0D358458b15932c5;
        _mintPasses[3675] = 0x513E8473FC9658c50EA01D4a0D358458b15932c5;
        _mintPasses[3676] = 0x513E8473FC9658c50EA01D4a0D358458b15932c5;
        _mintPasses[3677] = 0x399190C47dD486A553dEDCbD5465f811ab15C32B;
        _mintPasses[3678] = 0x399190C47dD486A553dEDCbD5465f811ab15C32B;
        _mintPasses[3679] = 0x399190C47dD486A553dEDCbD5465f811ab15C32B;
        _mintPasses[3680] = 0x399190C47dD486A553dEDCbD5465f811ab15C32B;
        _mintPasses[3681] = 0x399190C47dD486A553dEDCbD5465f811ab15C32B;
        _mintPasses[3682] = 0x72988B423c86afed473278E8d19a79456C404995;
        _mintPasses[3683] = 0x72988B423c86afed473278E8d19a79456C404995;
        _mintPasses[3684] = 0x6F14AFA784Ff0c764ecCB5F7A133403D5b7a4D34;
        _mintPasses[3685] = 0x6F14AFA784Ff0c764ecCB5F7A133403D5b7a4D34;
        _mintPasses[3686] = 0x5f0Fa6E54B9296622235CC146E02aaEaC667325a;
        _mintPasses[3687] = 0x5f0Fa6E54B9296622235CC146E02aaEaC667325a;
        _mintPasses[3688] = 0x822166Dc6A1ADc21ae1B7fbA3b700167cf0f0a6c;
        _mintPasses[3689] = 0x822166Dc6A1ADc21ae1B7fbA3b700167cf0f0a6c;
        _mintPasses[3691] = 0x822166Dc6A1ADc21ae1B7fbA3b700167cf0f0a6c;
        _mintPasses[3692] = 0x56E712FC5bc7B92aE2DD96585a5d4985913Bfd23;
        _mintPasses[3693] = 0x56E712FC5bc7B92aE2DD96585a5d4985913Bfd23;
        _mintPasses[3694] = 0x876b32129a32B21d86c82b0630fb3c6DDBB0e7B8;
        _mintPasses[3695] = 0x876b32129a32B21d86c82b0630fb3c6DDBB0e7B8;
        _mintPasses[3696] = 0x995418c315Ff98763dCe8e57695f1C05548b4eF5;
        _mintPasses[3697] = 0x995418c315Ff98763dCe8e57695f1C05548b4eF5;
        _mintPasses[3698] = 0x015732d3b7cda5826Ae3177a5A16ca0e271eA13F;
        _mintPasses[3699] = 0x015732d3b7cda5826Ae3177a5A16ca0e271eA13F;
        _mintPasses[3700] = 0x75AbF28b9CAe8edb0c1209efF172f9420CC63549;
        _mintPasses[3701] = 0x75AbF28b9CAe8edb0c1209efF172f9420CC63549;
        _mintPasses[3702] = 0x75AbF28b9CAe8edb0c1209efF172f9420CC63549;
        _mintPasses[3703] = 0xF8f18ff9969aB94299e763e038902262002341CD;
        _mintPasses[3704] = 0x56a68181A1358AF92C680610B5fD7e2d2cF6BF65;
        _mintPasses[3705] = 0x56a68181A1358AF92C680610B5fD7e2d2cF6BF65;
        _mintPasses[3706] = 0x56a68181A1358AF92C680610B5fD7e2d2cF6BF65;
        _mintPasses[3707] = 0x5A6bdC17B9F89Cb52b38dad319dF293b037a43d4;
        _mintPasses[3708] = 0x5A6bdC17B9F89Cb52b38dad319dF293b037a43d4;
        _mintPasses[3709] = 0x5A6bdC17B9F89Cb52b38dad319dF293b037a43d4;
        _mintPasses[3710] = 0x175F02F6473EcD2E87d450Ef33400C4eE673C387;
        _mintPasses[3711] = 0x175F02F6473EcD2E87d450Ef33400C4eE673C387;
        _mintPasses[3712] = 0xDF1e3abB229d42A182aD61ce8a63355a8A3EB0F8;
        _mintPasses[3713] = 0xDF1e3abB229d42A182aD61ce8a63355a8A3EB0F8;
        _mintPasses[3714] = 0xED721dC63328be92A08b6b7D677e11100C945eA9;
        _mintPasses[3715] = 0xED721dC63328be92A08b6b7D677e11100C945eA9;
        _mintPasses[3716] = 0xb6ddE9a985c77d7bC62B171582819D995a51C3bf;
        _mintPasses[3717] = 0xb6ddE9a985c77d7bC62B171582819D995a51C3bf;
        _mintPasses[3718] = 0xd469CD19CEFA18e4eb9112e57A47e09398d98766;
        _mintPasses[3719] = 0xd469CD19CEFA18e4eb9112e57A47e09398d98766;
        _mintPasses[3720] = 0x682ae71bae517bcc4179a1d66223fcDfFb186581;
        _mintPasses[3721] = 0x682ae71bae517bcc4179a1d66223fcDfFb186581;
        _mintPasses[3722] = 0x682ae71bae517bcc4179a1d66223fcDfFb186581;
        _mintPasses[3723] = 0xE495C36e756Ba677D5Ae8fb868f8c8A41cc51611;
        _mintPasses[3724] = 0xE495C36e756Ba677D5Ae8fb868f8c8A41cc51611;
        _mintPasses[3725] = 0xE495C36e756Ba677D5Ae8fb868f8c8A41cc51611;
        _mintPasses[3726] = 0xE495C36e756Ba677D5Ae8fb868f8c8A41cc51611;
        _mintPasses[3727] = 0xE495C36e756Ba677D5Ae8fb868f8c8A41cc51611;
        _mintPasses[3728] = 0x2eea4706F85b9A2D5DD9e9ff007F27C07443EAB1;
        _mintPasses[3729] = 0x2eea4706F85b9A2D5DD9e9ff007F27C07443EAB1;
        _mintPasses[3730] = 0xD77D92f3C97B5ce6430560bd1Ab298E82ed4E058;
        _mintPasses[3731] = 0xD77D92f3C97B5ce6430560bd1Ab298E82ed4E058;
        _mintPasses[3732] = 0xD77D92f3C97B5ce6430560bd1Ab298E82ed4E058;
        _mintPasses[3733] = 0x2c1a74debC7f797972EdbdA51554BE887594008F;
        _mintPasses[3734] = 0x2c1a74debC7f797972EdbdA51554BE887594008F;
        _mintPasses[3735] = 0x215867219e590352f50f5c3B8cE2587236138494;
        _mintPasses[3736] = 0x215867219e590352f50f5c3B8cE2587236138494;
        _mintPasses[3737] = 0xE57b245a1b403A56669f3F30b8db4ea94051E25D;
        _mintPasses[3738] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[3739] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[3740] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[3741] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[3742] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[3743] = 0x81083379a8c41501B39986D5C74428Dd618EB440;
        _mintPasses[3744] = 0x81083379a8c41501B39986D5C74428Dd618EB440;
        _mintPasses[3745] = 0x81083379a8c41501B39986D5C74428Dd618EB440;
        _mintPasses[3746] = 0x81083379a8c41501B39986D5C74428Dd618EB440;
        _mintPasses[3747] = 0x81083379a8c41501B39986D5C74428Dd618EB440;
        _mintPasses[3748] = 0x369DCD945f2ec96EFC489D9541b47cCa9594E9Fc;
        _mintPasses[3749] = 0x369DCD945f2ec96EFC489D9541b47cCa9594E9Fc;
        _mintPasses[3750] = 0x3C132E2d16f7452bdfAEFaE6C37b81e0FF83e749;
        _mintPasses[3751] = 0x3C132E2d16f7452bdfAEFaE6C37b81e0FF83e749;
        _mintPasses[3752] = 0x3C132E2d16f7452bdfAEFaE6C37b81e0FF83e749;
        _mintPasses[3753] = 0x5c5D1c68957EF6E9e46303e3CB02a0e3AecE1678;
        _mintPasses[3754] = 0x97874cf634457f07E7f1888C5C47D70DFAA542cb;
        _mintPasses[3755] = 0x97874cf634457f07E7f1888C5C47D70DFAA542cb;
        _mintPasses[3756] = 0xb261F055621fb3D19b86CD87d499b5aD9a561115;
        _mintPasses[3757] = 0xb261F055621fb3D19b86CD87d499b5aD9a561115;
        _mintPasses[3758] = 0xEd62B641dB277c9C6A2bA6D7246A1d76E483C11C;
        _mintPasses[3759] = 0xEd62B641dB277c9C6A2bA6D7246A1d76E483C11C;
        _mintPasses[3760] = 0x4384293860C81Dc6a8A248a648B6dCa35fF3aA33;
        _mintPasses[3761] = 0xec7dA9b90713B119969a8309607197e5A8606493;
        _mintPasses[3762] = 0xec7dA9b90713B119969a8309607197e5A8606493;
        _mintPasses[3763] = 0x0e0bDf28A0324dD3639520Cd189983F194132825;
        _mintPasses[3764] = 0x0e0bDf28A0324dD3639520Cd189983F194132825;
        _mintPasses[3765] = 0x0e0bDf28A0324dD3639520Cd189983F194132825;
        _mintPasses[3766] = 0x1e27F3175a52877CC8C4e3115B2669037381DeDc;
        _mintPasses[3767] = 0x1e27F3175a52877CC8C4e3115B2669037381DeDc;
        _mintPasses[3768] = 0x1e27F3175a52877CC8C4e3115B2669037381DeDc;
        _mintPasses[3769] = 0x1e27F3175a52877CC8C4e3115B2669037381DeDc;
        _mintPasses[3770] = 0x1e27F3175a52877CC8C4e3115B2669037381DeDc;
        _mintPasses[3771] = 0x1FC9aD1d4b2Ec8D78CfDA9FC35Cf729b9B49E7B6;
        _mintPasses[3772] = 0x1FC9aD1d4b2Ec8D78CfDA9FC35Cf729b9B49E7B6;
        _mintPasses[3773] = 0x1877e5A2B21dBC2EB73eC1b8838461e080932A9f;
        _mintPasses[3774] = 0x1877e5A2B21dBC2EB73eC1b8838461e080932A9f;
        _mintPasses[3775] = 0xA219F044dc6d726f61249c7279EcFa457D6Aaea2;
        _mintPasses[3776] = 0xA219F044dc6d726f61249c7279EcFa457D6Aaea2;
        _mintPasses[3777] = 0x0F683E30E71Ba4B5c1f610b675c8A48BB7cB1530;
        _mintPasses[3778] = 0x0F683E30E71Ba4B5c1f610b675c8A48BB7cB1530;
        _mintPasses[3779] = 0x2eE88422FBC9Ed5C4689089b05154887d737d76B;
        _mintPasses[3780] = 0x2eE88422FBC9Ed5C4689089b05154887d737d76B;
        _mintPasses[3781] = 0x2eE88422FBC9Ed5C4689089b05154887d737d76B;
        _mintPasses[3782] = 0xC294E0a06076EbB0ee3C4831e4a3C1C31A6A2484;
        _mintPasses[3783] = 0xC294E0a06076EbB0ee3C4831e4a3C1C31A6A2484;
        _mintPasses[3784] = 0xC294E0a06076EbB0ee3C4831e4a3C1C31A6A2484;
        _mintPasses[3785] = 0xC294E0a06076EbB0ee3C4831e4a3C1C31A6A2484;
        _mintPasses[3786] = 0xC294E0a06076EbB0ee3C4831e4a3C1C31A6A2484;
        _mintPasses[3787] = 0xb1D610fB451b5cdee4eADcA4538816122ad40E1d;
        _mintPasses[3788] = 0xb1D610fB451b5cdee4eADcA4538816122ad40E1d;
        _mintPasses[3791] = 0x4B9fC228C687f8Ae3C7889579c9723b65882Ebd9;
        _mintPasses[3792] = 0x635123F0a1e192B03F69b3d082e79C969A5eE9b0;
        _mintPasses[3793] = 0x635123F0a1e192B03F69b3d082e79C969A5eE9b0;
        _mintPasses[3794] = 0x635123F0a1e192B03F69b3d082e79C969A5eE9b0;
        _mintPasses[3795] = 0x635123F0a1e192B03F69b3d082e79C969A5eE9b0;
        _mintPasses[3796] = 0x635123F0a1e192B03F69b3d082e79C969A5eE9b0;
        _mintPasses[3797] = 0xeFf626B4beBBd3f26cbA77b47e9ae6C9326cfebB;
        _mintPasses[3798] = 0xeFf626B4beBBd3f26cbA77b47e9ae6C9326cfebB;
        _mintPasses[3799] = 0xeFf626B4beBBd3f26cbA77b47e9ae6C9326cfebB;
        _mintPasses[3800] = 0xeFf626B4beBBd3f26cbA77b47e9ae6C9326cfebB;
        _mintPasses[3801] = 0xeFf626B4beBBd3f26cbA77b47e9ae6C9326cfebB;
        _mintPasses[3802] = 0xE7bFCE6D3613D20ea879430EA78279Ec3eeCB473;
        _mintPasses[3804] = 0x6cb603c1967a32bb7b0726EcbCbB8c3A16b1c299;
        _mintPasses[3805] = 0x6cb603c1967a32bb7b0726EcbCbB8c3A16b1c299;
        _mintPasses[3806] = 0x6cb603c1967a32bb7b0726EcbCbB8c3A16b1c299;
        _mintPasses[3807] = 0x6cb603c1967a32bb7b0726EcbCbB8c3A16b1c299;
        _mintPasses[3808] = 0x6cb603c1967a32bb7b0726EcbCbB8c3A16b1c299;
        _mintPasses[3809] = 0x2BEa720a5fe5e7738d775e8BfD3a37Fa072Cd46c;
        _mintPasses[3810] = 0x2BEa720a5fe5e7738d775e8BfD3a37Fa072Cd46c;
        _mintPasses[3811] = 0x2BEa720a5fe5e7738d775e8BfD3a37Fa072Cd46c;
        _mintPasses[3812] = 0xe4b52ecE9903d8a1995dd4ebf1d16D1a5D51D58D;
        _mintPasses[3813] = 0xe4b52ecE9903d8a1995dd4ebf1d16D1a5D51D58D;
        _mintPasses[3814] = 0xe4b52ecE9903d8a1995dd4ebf1d16D1a5D51D58D;
        _mintPasses[3815] = 0xe4b52ecE9903d8a1995dd4ebf1d16D1a5D51D58D;
        _mintPasses[3816] = 0xe4b52ecE9903d8a1995dd4ebf1d16D1a5D51D58D;
        _mintPasses[3817] = 0xc564D44045a70646BeEf777469E7Aa4E4B6e692A;
        _mintPasses[3818] = 0xc564D44045a70646BeEf777469E7Aa4E4B6e692A;
        _mintPasses[3819] = 0x7255FE6f25ecaED72E85338c131D0daA60724Ecc;
        _mintPasses[3820] = 0x7255FE6f25ecaED72E85338c131D0daA60724Ecc;
        _mintPasses[3821] = 0x2ee963A7B3d9f14D9F748026055C15528fB87f30;
        _mintPasses[3822] = 0x2ee963A7B3d9f14D9F748026055C15528fB87f30;
        _mintPasses[3823] = 0x3908176C1802C43Cf5F481f53243145AcaA76bcc;
        _mintPasses[3824] = 0x3908176C1802C43Cf5F481f53243145AcaA76bcc;
        _mintPasses[3825] = 0x3f6a989786FD0FDAE539F356d99944e5aA4fBae1;
        _mintPasses[3826] = 0x3f6a989786FD0FDAE539F356d99944e5aA4fBae1;
        _mintPasses[3827] = 0x4d140380DE92396cE3Fa583393257a7024a2b653;
        _mintPasses[3828] = 0x4d140380DE92396cE3Fa583393257a7024a2b653;
        _mintPasses[3829] = 0x4d140380DE92396cE3Fa583393257a7024a2b653;
        _mintPasses[3830] = 0x4d140380DE92396cE3Fa583393257a7024a2b653;
        _mintPasses[3831] = 0x4d140380DE92396cE3Fa583393257a7024a2b653;
        _mintPasses[3832] = 0x64C9fb6C978f0f5dd46CB36325b56c04243bAB75;
        _mintPasses[3833] = 0x64C9fb6C978f0f5dd46CB36325b56c04243bAB75;
        _mintPasses[3834] = 0x64C9fb6C978f0f5dd46CB36325b56c04243bAB75;
        _mintPasses[3835] = 0xA01481b6fBE54BE00661290f1cE49e14E3Af82Ef;
        _mintPasses[3836] = 0xA01481b6fBE54BE00661290f1cE49e14E3Af82Ef;
        _mintPasses[3837] = 0xA01481b6fBE54BE00661290f1cE49e14E3Af82Ef;
        _mintPasses[3838] = 0xA01481b6fBE54BE00661290f1cE49e14E3Af82Ef;
        _mintPasses[3839] = 0xA01481b6fBE54BE00661290f1cE49e14E3Af82Ef;
        _mintPasses[6010] = 0xFeF49F32fB60ea475b8cf7193AC32C3DA8a05B7E;
        _mintPasses[6011] = 0xFeF49F32fB60ea475b8cf7193AC32C3DA8a05B7E;
        _mintPasses[6012] = 0x5c4668d494C6Af375a20782727Ec2084605DDB64;
        _mintPasses[6013] = 0x5c4668d494C6Af375a20782727Ec2084605DDB64;
        _mintPasses[6014] = 0xA613e95408dbEfc3aeCB4630BDE04E757Bc46fD8;
        _mintPasses[6019] = 0x7C8A576941E14934643Bb22f3f5eAD4771f7E3Af;
        _mintPasses[6020] = 0x7C8A576941E14934643Bb22f3f5eAD4771f7E3Af;
        _mintPasses[6021] = 0xA7bD22BcFC1eAE5f9944978d81ff71Bd5f5eAF42;
        _mintPasses[6022] = 0xA7bD22BcFC1eAE5f9944978d81ff71Bd5f5eAF42;
        _mintPasses[6023] = 0x1105bF50bE63cdaD34Ff7ac9425C1645e6275E1e;
        _mintPasses[6024] = 0x1105bF50bE63cdaD34Ff7ac9425C1645e6275E1e;
        _mintPasses[6025] = 0x0E54FD21F4eae61A9594393b237bA6de3eDb93D1;
        _mintPasses[6026] = 0x0E54FD21F4eae61A9594393b237bA6de3eDb93D1;
        _mintPasses[6027] = 0x2B7cD3Fec35fb21eFc8913E7383639adb088384B;
        _mintPasses[6028] = 0x2B7cD3Fec35fb21eFc8913E7383639adb088384B;
        _mintPasses[6029] = 0xa4D26fC0814a8dacef55A79166291DD0898a8194;
        _mintPasses[6030] = 0xa4D26fC0814a8dacef55A79166291DD0898a8194;
        _mintPasses[6031] = 0x79122374eCBaD9cbA0dDF0e0A5F1B676462677B4;
        _mintPasses[6032] = 0x79122374eCBaD9cbA0dDF0e0A5F1B676462677B4;
        _mintPasses[6033] = 0x79122374eCBaD9cbA0dDF0e0A5F1B676462677B4;
        _mintPasses[6034] = 0x79122374eCBaD9cbA0dDF0e0A5F1B676462677B4;
        _mintPasses[6036] = 0x79122374eCBaD9cbA0dDF0e0A5F1B676462677B4;
        _mintPasses[6037] = 0xaEabe7513BB61325E22c0D7Fd7B2804b3e2C9C28;
        _mintPasses[6038] = 0xaEabe7513BB61325E22c0D7Fd7B2804b3e2C9C28;
        _mintPasses[6039] = 0xaEabe7513BB61325E22c0D7Fd7B2804b3e2C9C28;
        _mintPasses[6040] = 0xDCC15c04963095154aBa0131462C5F4b5284b7c0;
        _mintPasses[6041] = 0xDCC15c04963095154aBa0131462C5F4b5284b7c0;
        _mintPasses[6042] = 0xDCC15c04963095154aBa0131462C5F4b5284b7c0;
        _mintPasses[6043] = 0x1215731ACF43E83E5dAbE1fe342eD79160e85366;
        _mintPasses[6044] = 0x1215731ACF43E83E5dAbE1fe342eD79160e85366;
        _mintPasses[6045] = 0xF2E81438e26FcE88cC8deBf8C178b80A506cE435;
        _mintPasses[6046] = 0xF2E81438e26FcE88cC8deBf8C178b80A506cE435;
        _mintPasses[6047] = 0xF2E81438e26FcE88cC8deBf8C178b80A506cE435;
        _mintPasses[6048] = 0x28e58A14A39c6BD994e4864119A0348f233992c0;
        _mintPasses[6049] = 0x28e58A14A39c6BD994e4864119A0348f233992c0;
        _mintPasses[6050] = 0x28e58A14A39c6BD994e4864119A0348f233992c0;
        _mintPasses[6051] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[6052] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[6053] = 0x826ae03F697BbD3dAD37E9b34e7a8989d9317fc4;
        _mintPasses[6055] = 0x0eCddcF41754360AB129d7Ca4c8ABf220F9c32BD;
        _mintPasses[6058] = 0x405EB35A58a0C88d9E193D4cB7e61c4Adf2fbcdF;
        _mintPasses[6059] = 0x405EB35A58a0C88d9E193D4cB7e61c4Adf2fbcdF;
        _mintPasses[6060] = 0xD39EbDa59a76EfF9df72C37F8260e53E073bd7BC;
        _mintPasses[6061] = 0xD39EbDa59a76EfF9df72C37F8260e53E073bd7BC;
        _mintPasses[6062] = 0xC93e7FEc09E54ECbbAE66754159989E44FB12aD2;
        _mintPasses[6063] = 0xC93e7FEc09E54ECbbAE66754159989E44FB12aD2;
        _mintPasses[6064] = 0x53851a72902197865EFA99Edc0f73d89990863A9;
        _mintPasses[6065] = 0x53851a72902197865EFA99Edc0f73d89990863A9;
        _mintPasses[6066] = 0x53851a72902197865EFA99Edc0f73d89990863A9;
        _mintPasses[6067] = 0x53851a72902197865EFA99Edc0f73d89990863A9;
        _mintPasses[6068] = 0x53851a72902197865EFA99Edc0f73d89990863A9;
        _mintPasses[6069] = 0xA14B8d5E0687e63F9991E85DC17287f17d858731;
        _mintPasses[6070] = 0xA14B8d5E0687e63F9991E85DC17287f17d858731;
        _mintPasses[6071] = 0xF2E81438e26FcE88cC8deBf8C178b80A506cE435;
        _mintPasses[6072] = 0x828cDcDc2a006E5EBCA06EEd673BFa8DF897852D;
        _mintPasses[6073] = 0x828cDcDc2a006E5EBCA06EEd673BFa8DF897852D;
        _mintPasses[6074] = 0x828cDcDc2a006E5EBCA06EEd673BFa8DF897852D;
        _mintPasses[6075] = 0x828cDcDc2a006E5EBCA06EEd673BFa8DF897852D;
        _mintPasses[6076] = 0x828cDcDc2a006E5EBCA06EEd673BFa8DF897852D;
        _mintPasses[6077] = 0x3723DDeC18A8F59CFC2bED4AEDe5e5Bebdf21712;
        _mintPasses[6078] = 0x3723DDeC18A8F59CFC2bED4AEDe5e5Bebdf21712;
        _mintPasses[6079] = 0x4A90601B49605B3998A5339833763931D9BD4918;
        _mintPasses[6080] = 0x4A90601B49605B3998A5339833763931D9BD4918;
        _mintPasses[6081] = 0x7358B3dD144332377c14D8A47844E05A1b6f50aC;
        _mintPasses[6082] = 0x7358B3dD144332377c14D8A47844E05A1b6f50aC;
        _mintPasses[6084] = 0x7358B3dD144332377c14D8A47844E05A1b6f50aC;
        _mintPasses[6085] = 0x7358B3dD144332377c14D8A47844E05A1b6f50aC;
        _mintPasses[6086] = 0x7358B3dD144332377c14D8A47844E05A1b6f50aC;
        _mintPasses[6087] = 0xDf3759cc2277aDcDB0a97b8AC1469a6EddBC6A8d;
        _mintPasses[6088] = 0xDf3759cc2277aDcDB0a97b8AC1469a6EddBC6A8d;
        _mintPasses[6089] = 0xDf3759cc2277aDcDB0a97b8AC1469a6EddBC6A8d;
        _mintPasses[6090] = 0xe29fb0952a8FA002B353e255dD7EE45527084240;
        _mintPasses[6091] = 0xe29fb0952a8FA002B353e255dD7EE45527084240;
        _mintPasses[6092] = 0x087e269f123F479aE3Cf441657A8739236d36aEe;
        _mintPasses[6093] = 0x087e269f123F479aE3Cf441657A8739236d36aEe;
        _mintPasses[6094] = 0x60F444A38d8792EeD42E6E091E64216F93ceEeb8;
        _mintPasses[6095] = 0x60F444A38d8792EeD42E6E091E64216F93ceEeb8;
        _mintPasses[6096] = 0x386c2f5aAB7392F86e5aF3de097673b7BFc4aE64;
        _mintPasses[6097] = 0x386c2f5aAB7392F86e5aF3de097673b7BFc4aE64;
        _mintPasses[6098] = 0x386c2f5aAB7392F86e5aF3de097673b7BFc4aE64;
        _mintPasses[6099] = 0x386c2f5aAB7392F86e5aF3de097673b7BFc4aE64;
        _mintPasses[6100] = 0x386c2f5aAB7392F86e5aF3de097673b7BFc4aE64;
        _mintPasses[6101] = 0x62182A2Ca7879E2440ca3f5c5c5E1EbdC4fC7c17;
        _mintPasses[6102] = 0x62182A2Ca7879E2440ca3f5c5c5E1EbdC4fC7c17;
        _mintPasses[6103] = 0x8Bf52d54578d06724A989906D47c7B021612E502;
        _mintPasses[6104] = 0x8Bf52d54578d06724A989906D47c7B021612E502;
        _mintPasses[6105] = 0x8EaC156f7df9245F360AE39c47879c2919317402;
        _mintPasses[6106] = 0x8EaC156f7df9245F360AE39c47879c2919317402;
        _mintPasses[6107] = 0x38c05b9B18f8B512CFDCE9bCFD0e57030344f602;
        _mintPasses[6108] = 0x38c05b9B18f8B512CFDCE9bCFD0e57030344f602;
        _mintPasses[6109] = 0xC15f55d4381473A51830196d0307c2987e9A39d9;
        _mintPasses[6110] = 0xC15f55d4381473A51830196d0307c2987e9A39d9;
        _mintPasses[6111] = 0xC15f55d4381473A51830196d0307c2987e9A39d9;
        _mintPasses[6112] = 0x8951A87Adf50b555034B47D103875A1613B003B6;
        _mintPasses[6113] = 0x8951A87Adf50b555034B47D103875A1613B003B6;
        _mintPasses[6114] = 0x4Cb18005A1586F3A743B59bcAc574A01B73B0a18;
        _mintPasses[6115] = 0x4Cb18005A1586F3A743B59bcAc574A01B73B0a18;
        _mintPasses[6116] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6117] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6118] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6119] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6120] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6121] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6122] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6123] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6124] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6125] = 0x8aF0B9A9B751E086122bC340188Bd9d99b8C7ec1;
        _mintPasses[6126] = 0xeb77045939E3FaFB19eCa0389f343fB19a052DFe;
        _mintPasses[6127] = 0xeb77045939E3FaFB19eCa0389f343fB19a052DFe;
        _mintPasses[6128] = 0x2A17068BC37705fA1710dC8bFd1EE49Bc0b432b0;
        _mintPasses[6129] = 0x2A17068BC37705fA1710dC8bFd1EE49Bc0b432b0;
        _mintPasses[6130] = 0x2A17068BC37705fA1710dC8bFd1EE49Bc0b432b0;
        _mintPasses[6131] = 0x2A17068BC37705fA1710dC8bFd1EE49Bc0b432b0;
        _mintPasses[6132] = 0x2A17068BC37705fA1710dC8bFd1EE49Bc0b432b0;
        _mintPasses[6133] = 0x554DDFABaB2524A229070E01e9FaaD627e4Ac513;
        _mintPasses[6134] = 0x554DDFABaB2524A229070E01e9FaaD627e4Ac513;
        _mintPasses[6135] = 0x554DDFABaB2524A229070E01e9FaaD627e4Ac513;
        _mintPasses[6136] = 0x554DDFABaB2524A229070E01e9FaaD627e4Ac513;
        _mintPasses[6137] = 0x554DDFABaB2524A229070E01e9FaaD627e4Ac513;
        _mintPasses[6138] = 0xbdF53Fe485928d2F269cb344864d539C5862AeAb;
        _mintPasses[6139] = 0xbdF53Fe485928d2F269cb344864d539C5862AeAb;
        _mintPasses[6140] = 0x03CCeA443bF78E52bB01c737A00A793CdB7e53d8;
        _mintPasses[6141] = 0x03CCeA443bF78E52bB01c737A00A793CdB7e53d8;
        _mintPasses[6142] = 0xF6d4A41579BF6069A369eA56a72C29fB7D710664;
        _mintPasses[6143] = 0xF6d4A41579BF6069A369eA56a72C29fB7D710664;
        _mintPasses[6144] = 0x9309F2Ed55De312FDf51368593db75dE39369173;
        _mintPasses[6145] = 0x9309F2Ed55De312FDf51368593db75dE39369173;
        _mintPasses[6148] = 0xE4324E43Ae3e8a611E927dF10795D3A20152aE4a;
        _mintPasses[6149] = 0xE4324E43Ae3e8a611E927dF10795D3A20152aE4a;
        _mintPasses[6150] = 0xC992c764a5dD14dd5Bd6F662a14377E1Cf7e31df;
        _mintPasses[6151] = 0xC992c764a5dD14dd5Bd6F662a14377E1Cf7e31df;
        _mintPasses[6152] = 0xC992c764a5dD14dd5Bd6F662a14377E1Cf7e31df;
        _mintPasses[6153] = 0xC992c764a5dD14dd5Bd6F662a14377E1Cf7e31df;
        _mintPasses[6154] = 0xC992c764a5dD14dd5Bd6F662a14377E1Cf7e31df;
        _mintPasses[6155] = 0x01C9a2bbb109a24E86535bB41007cd15a0177C11;
        _mintPasses[6156] = 0x01C9a2bbb109a24E86535bB41007cd15a0177C11;
        _mintPasses[6157] = 0x01C9a2bbb109a24E86535bB41007cd15a0177C11;
        _mintPasses[6158] = 0xbcD8F6a884efde5Da425A3DD5032b3681e3ec0D8;
        _mintPasses[6159] = 0xbcD8F6a884efde5Da425A3DD5032b3681e3ec0D8;
        _mintPasses[6160] = 0x208Eff61de4d585bf1983fdaA5eE9E6c0A92D938;
        _mintPasses[6161] = 0x208Eff61de4d585bf1983fdaA5eE9E6c0A92D938;
        _mintPasses[6162] = 0xdD4127C80F8E59b2a8a9A64dC9d62dd7caa5C339;
        _mintPasses[6163] = 0xdD4127C80F8E59b2a8a9A64dC9d62dd7caa5C339;
        _mintPasses[6164] = 0xdD4127C80F8E59b2a8a9A64dC9d62dd7caa5C339;
        _mintPasses[6165] = 0x8869583E848b60F934C84AB6BC157f9e02A65C4a;
        _mintPasses[6166] = 0x8869583E848b60F934C84AB6BC157f9e02A65C4a;
        _mintPasses[6167] = 0x004196E84C7320EbB2e90e8dC4e0a766d3aaC8Db;
        _mintPasses[6168] = 0x004196E84C7320EbB2e90e8dC4e0a766d3aaC8Db;
        _mintPasses[6169] = 0xA27E6a2e557587e9ca321351ac6Fa09892ec971E;
        _mintPasses[6170] = 0xA27E6a2e557587e9ca321351ac6Fa09892ec971E;
        _mintPasses[6171] = 0xA27E6a2e557587e9ca321351ac6Fa09892ec971E;
        _mintPasses[6226] = 0x01C9a2bbb109a24E86535bB41007cd15a0177C11;
        _mintPasses[6227] = 0x01C9a2bbb109a24E86535bB41007cd15a0177C11;
        _mintPasses[6228] = 0x87689C4e28200de1f0313A98080B4428490F7285;
        _mintPasses[6229] = 0xedE6D8113CF88bbA583a905241abdf23089b312D;
        _mintPasses[6230] = 0xedE6D8113CF88bbA583a905241abdf23089b312D;
        _mintPasses[6231] = 0xd9FCBf56aD6793E10181c28B6E418208656f21C2;
        _mintPasses[6232] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6233] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6234] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6235] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6236] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6237] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6238] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6239] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6240] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6241] = 0x59DC8eE69a7e57b42D25cd13C0Cd8d6665Aa70B2;
        _mintPasses[6242] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[6243] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[6244] = 0x4e1b83Dbc5F77faF3B3d450c2ea30BCD441d67b2;
        _mintPasses[6245] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[6246] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[6247] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[6248] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[6249] = 0x667B2a94Dd4053508C7440EA1F902694336B9814;
        _mintPasses[6250] = 0x298A8fF8128D8427781B44F7e64657548768E3D4;
        _mintPasses[6251] = 0x298A8fF8128D8427781B44F7e64657548768E3D4;
        _mintPasses[6252] = 0x298A8fF8128D8427781B44F7e64657548768E3D4;
        _mintPasses[6253] = 0x298A8fF8128D8427781B44F7e64657548768E3D4;
        _mintPasses[6254] = 0x298A8fF8128D8427781B44F7e64657548768E3D4;
        _mintPasses[6255] = 0x944266ac7c1BcE8b0bF307a060D42A1B9Baa6Ca9;
        _mintPasses[6256] = 0x944266ac7c1BcE8b0bF307a060D42A1B9Baa6Ca9;
        _mintPasses[6257] = 0x944266ac7c1BcE8b0bF307a060D42A1B9Baa6Ca9;
        _mintPasses[6258] = 0x944266ac7c1BcE8b0bF307a060D42A1B9Baa6Ca9;
        _mintPasses[6259] = 0x6DFaEA023567DF25E4b1f0E05EF5443aC5C26Ed9;
        _mintPasses[6260] = 0x6DFaEA023567DF25E4b1f0E05EF5443aC5C26Ed9;
        _mintPasses[6261] = 0x6DFaEA023567DF25E4b1f0E05EF5443aC5C26Ed9;
        _mintPasses[6262] = 0x6DFaEA023567DF25E4b1f0E05EF5443aC5C26Ed9;
        _mintPasses[6263] = 0x6DFaEA023567DF25E4b1f0E05EF5443aC5C26Ed9;
        _mintPasses[6264] = 0x6DFaEA023567DF25E4b1f0E05EF5443aC5C26Ed9;
	}

    function verifyMintPass(uint mintPass, address to) 
    internal 
    view
    returns (bool)
    {
        if (_mintPasses[mintPass] == to) {
            return true;
        } else {
            return false;
        }
    }

    function invalidateMintPass(uint mintPass) 
    internal
    {
        delete _mintPasses[mintPass];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}