// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721Enumerable.sol";

import "./utils/Address.sol";
import "./utils/Context.sol";
import "./utils/Strings.sol";
import "./utils/Counters.sol";

import "./ERC165.sol";

import "./SafeBEP20.sol";       // For withdrawal function



// TODO - test withddraw the erc20 token withdraw
// TODO - test withdraw the NFT token withdraw test
    

contract NIPnftFactory is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {

    using Strings for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter private tokenIDs;
    mapping (uint256 => string) private tokenURIs; // Optional mapping for token URIs

    string private nameOfToken;
    string private symbolOfToken;

    address private previousOwnerOfContract; 
    address private ownerOfContract;

    bool public isNFTfactoryEnabled;

    address public teamWalletAddr;
    address public previousTeamWalletAddr;

    
    mapping (uint256 => address) private ownersOfNFT;       // Mapping from token ID to owner address
    mapping (address => uint256) private balancesOfNFT;     // Mapping owner address to token count
    mapping (uint256 => address) private tokenApprovals;       // Mapping from token ID to approved address
    mapping (address => mapping (address => bool)) private operatorApprovals;       // Mapping from owner to operator approvals

 
    // Enumeration 
    mapping(address => mapping(uint256 => uint256)) private ownedTokens;       // Mapping from owner to list of owned token IDs
    mapping(uint256 => uint256) private ownedTokensIndex;  // Mapping from token ID to index of the owner tokens list
    uint256[] private allTokens;   // Array with all token ids, used for enumeration
    mapping(uint256 => uint256) private allTokensIndex;    // Mapping from token id to position in the allTokens array



    // NFT creating checks
    mapping(address => uint256) public numberOfNFTsCreated;


    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NFTcreated(address indexed creatorAddress, address indexed receiverAddress, uint256 indexed newItemID, string inputTokenURI);
    event FactoryEnabled();
    event FactoryDisabled();
    event TeamWalletAddressChanged(address indexed newTeamWalletAddress, address indexed previousTeamWalletAddr);

    

    

    constructor(){
        nameOfToken = "NIPtestNFT";
        symbolOfToken = "NTN";

        previousTeamWalletAddr = address(0);
        teamWalletAddr = 0x8809687eD3E675eb7E3953099555A07CbDBDD9C5;    // CHANGEIT - Make sure it's the right Team Wallet Address, should be the Gnosis Safe

        address msgSender = _msgSender();
        previousOwnerOfContract = address(0);
        ownerOfContract = msgSender;
        emit OwnershipTransferred(previousOwnerOfContract, msgSender);

        isNFTfactoryEnabled = true;
    }




    /////////////////////////////////Info Functions/////////////////////////////////
    function name() public view virtual override returns (string memory) {
        return nameOfToken;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbolOfToken;
    }

    function balanceOf(address ownerAddress) public view virtual override returns (uint256) {
        require(ownerAddress != address(0), "ERC721: balance query for the zero address");
        return balancesOfNFT[ownerAddress];
    }

    function ownerOf(uint256 tokenID) public view virtual override returns (address) {
        address ownerAddress = ownersOfNFT[tokenID];
        require(ownerAddress != address(0), "ERC721: owner query for nonexistent token");
        return ownerAddress;
    }

    function tokenOfOwnerByIndex(address ownerAddress, uint256 index) public view virtual override returns (uint256) {
        require(index < balanceOf(ownerAddress), "ERC721Enumerable: owner index out of bounds");
        return ownedTokens[ownerAddress][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return allTokens.length;
    }

 
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return allTokens[index];
    }
    /////////////////////////////////Info Functions/////////////////////////////////




    /////////////////////////////////Owner Functions/////////////////////////////////
    function owner() public view virtual returns (address) {
        return ownerOfContract;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        previousOwnerOfContract = ownerOfContract;
        ownerOfContract = newOwner;
        emit OwnershipTransferred(previousOwnerOfContract, ownerOfContract);
    }
    /////////////////////////////////Owner Functions/////////////////////////////////

    

    /////////////////////////////////Token URI functions/////////////////////////////////
    function tokenURI(uint256 tokenID) public view virtual override returns (string memory) {
        // gets the URI for a tokenID, in our case they should all be the same structure.

        require(exists(tokenID), "ERC721URIStorage: URI query for nonexistent token");

        string memory currentTokenURI = tokenURIs[tokenID];
        string memory baseURI = getBaseURI();

        if (bytes(baseURI).length == 0) {       // If there is no base URI, return the token URI.
            return currentTokenURI;
        }

        if (bytes(currentTokenURI).length > 0) {      // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
            return string(abi.encodePacked(baseURI, currentTokenURI));
        }

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : '';
    }

    function setTokenURI(uint256 tokenID, string memory currentTokenURI) internal virtual {
        require(exists(tokenID), "ERC721URIStorage: URI set of nonexistent token");
        tokenURIs[tokenID] = currentTokenURI;
    }

    function getBaseURI() internal view virtual returns (string memory) {
        return "";
    }
    /////////////////////////////////Token URI functions/////////////////////////////////



    /////////////////////////////////Burn Functions/////////////////////////////////
    function burn(uint256 tokenID) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721Burnable: caller is not owner nor approved");
        burnInternal(tokenID);
    }

    function burnInternal(uint256 tokenID) internal virtual {
        address ownerAddress = ownerOf(tokenID);

        beforeTokenTransfer(ownerAddress, address(0), tokenID);

        _approve(address(0), tokenID);  // Clear approvals

        balancesOfNFT[ownerAddress] -= 1;
        delete ownersOfNFT[tokenID];

        emit Transfer(ownerAddress, address(0), tokenID);

        if (bytes(tokenURIs[tokenID]).length != 0) {
            delete tokenURIs[tokenID];
        }
    }
    /////////////////////////////////Burn Functions/////////////////////////////////




    /////////////////////////////////Approval Functions/////////////////////////////////
    function approve(address to, uint256 tokenId) public virtual override {
        address ownerAddress = ownerOf(tokenId);
        require(to != ownerAddress, "ERC721: approval to current owner");

        require(_msgSender() == ownerAddress || isApprovedForAll(ownerAddress, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(exists(tokenId), "ERC721: approved query for nonexistent token");

        return tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address ownerAddress, address operator) public view virtual override returns (bool) {
        return operatorApprovals[ownerAddress][operator];
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(exists(tokenId), "ERC721: operator query for nonexistent token");
        address ownerAddress = ownerOf(tokenId);
        return (spender == ownerAddress || getApproved(tokenId) == spender || isApprovedForAll(ownerAddress, spender));
    }
    /////////////////////////////////Approval Functions/////////////////////////////////



    /////////////////////////////////Transfer Functions/////////////////////////////////

    function transfer(address _to, uint256 _value) public {
            safeTransferFrom(_msgSender(), _to, _value);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(address fromAddress, address toAddress, uint256 tokenID) internal virtual {
        require(ownerOf(tokenID) == fromAddress, "ERC721: transfer of token that is not own");
        require(toAddress != address(0), "ERC721: transfer to the zero address");

        beforeTokenTransfer(fromAddress, toAddress, tokenID);

        _approve(address(0), tokenID);  // Clear approvals from the previous owner

        balancesOfNFT[fromAddress] -= 1;
        balancesOfNFT[toAddress] += 1;
        ownersOfNFT[tokenID] = toAddress;

        emit Transfer(fromAddress, toAddress, tokenID);
    }
    /////////////////////////////////Transfer Functions/////////////////////////////////



    /////////////////////////////////Minting Functions/////////////////////////////////
    function safeMintNoData(address toAddress, uint256 tokenID) internal virtual {
        safeMint(toAddress, tokenID, "");
    }

    function safeMint(address toAddress, uint256 tokenID, bytes memory _data) internal virtual {
        mintInternal(toAddress, tokenID);
        require(_checkOnERC721Received(address(0), toAddress, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function mintInternal(address toAddress, uint256 tokenID) internal virtual {
        require(toAddress != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenID), "ERC721: token already minted");

        beforeTokenTransfer(address(0), toAddress, tokenID);

        balancesOfNFT[toAddress] += 1;
        ownersOfNFT[tokenID] = toAddress;

        emit Transfer(address(0), toAddress, tokenID);
    }
    /////////////////////////////////Minting Functions/////////////////////////////////



    /////////////////////////////////Check Functions/////////////////////////////////
    function exists(uint256 tokenId) internal view virtual returns (bool) {
        return ownersOfNFT[tokenId] != address(0);      
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } 
            catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } 
                else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } 
        else {
            return true;
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId 
            || interfaceId == type(IERC721Metadata).interfaceId 
            || interfaceId == type(IERC721Enumerable).interfaceId 
            || super.supportsInterface(interfaceId);
    }
    /////////////////////////////////Check Functions/////////////////////////////////





    /////////////////////////////////The remove or add before token transfer functions/////////////////////////////////
    function beforeTokenTransfer(address fromAddress, address toAddress, uint256 tokenID) internal virtual {

        // Hook that is called before any token transfer. This includes minting and burning.
        if (fromAddress == address(0)) {
            addTokenToAllTokensEnumeration(tokenID);
        } 
        else if (fromAddress != toAddress) {
            removeTokenFromOwnerEnumeration(fromAddress, tokenID);
        }

        if (toAddress == address(0)) {
            removeTokenFromAllTokensEnumeration(tokenID);
        } 
        else if (toAddress != fromAddress) {
            addTokenToOwnerEnumeration(toAddress, tokenID);
        }
    }

    function addTokenToOwnerEnumeration(address toAddress, uint256 tokenID) private {
        uint256 length = balanceOf(toAddress);
        ownedTokens[toAddress][length] = tokenID;      // Private function to add a token to this extension's ownership-tracking data structures.
        ownedTokensIndex[tokenID] = length;
    }

    function addTokenToAllTokensEnumeration(uint256 tokenID) private {
        allTokensIndex[tokenID] = allTokens.length; // Private function to add a token to this extension's token tracking data structures.
        allTokens.push(tokenID);
    }

    function removeTokenFromOwnerEnumeration(address fromAddress, uint256 tokenID) private {
        // Private function to remove a token from this extension's ownership-tracking data structures. Note that
        // while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
        // gas optimizations e.g. when performing a transfer operation (avoiding double writes).
        // This has O(1) time complexity, but alters the order of the _ownedTokens array.

        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(fromAddress) - 1;
        uint256 tokenIndex = ownedTokensIndex[tokenID];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ownedTokens[fromAddress][lastTokenIndex];
            ownedTokens[fromAddress][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ownedTokensIndex[tokenID];
        delete ownedTokens[fromAddress][lastTokenIndex];
    }

    function removeTokenFromAllTokensEnumeration(uint256 tokenID) private {
        // Private function to remove a token from this extension's token tracking data structures.
        // This has O(1) time complexity, but alters the order of the _allTokens array.
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = allTokens.length - 1;
        uint256 tokenIndex = allTokensIndex[tokenID];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenID = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastTokenID; // Move the last token to the slot of the to-delete token
        allTokensIndex[lastTokenID] = tokenIndex; // Update the moved token's index

        delete allTokensIndex[tokenID];     // This also deletes the contents at the last position of the array
        allTokens.pop();
    }
    /////////////////////////////////The remove or add before token transfer functions/////////////////////////////////





    /////////////////////////////////Withdraw From Contract Functions/////////////////////////////////

    function payableTeamWalletAddr() internal view returns (address payable) {   // gets the sender of the payable address
        address payable payableMsgSender = payable(address(teamWalletAddr));
        return payableMsgSender;
    }

    function withdrawBNBSentToContractAddress() external onlyOwner  {   
        payableTeamWalletAddr().transfer(address(this).balance);        // TODO - does this balance work?
    }

    using SafeBEP20 for IBEP20;

    function withdrawBEP20SentToContractAddress(IBEP20 tokenToWithdraw) external onlyOwner {
        tokenToWithdraw.safeTransfer(payableTeamWalletAddr(), tokenToWithdraw.balanceOf(address(this)));    // TODO - I don't think this balance of is going to work...
    }


    function changeTeamWalletAddress(address newTeamWalletAddress) external onlyOwner{
        previousTeamWalletAddr = teamWalletAddr;
        teamWalletAddr = newTeamWalletAddress;
        emit TeamWalletAddressChanged(teamWalletAddr, previousTeamWalletAddr);
    }
    /////////////////////////////////Withdraw From Contract Functions/////////////////////////////////
    



    /////////////////////////////////Security Mechanisms/////////////////////////////////
    // TODO - 
    function hash(string memory _text, uint _num, address _addr) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_text, _num, _addr));
    }

    // Example of hash collision
    // Hash collision can occur when you pass more than one dynamic data type
    // to abi.encodePacked. In such case, you should use abi.encode instead.
    function collision(string memory _text, string memory _anotherText) public pure returns (bytes32)
    {
        // encodePacked(AAA, BBB) -> AAABBB
        // encodePacked(AA, ABBB) -> AAABBB
        return keccak256(abi.encodePacked(_text, _anotherText));
    }

    bytes32 public answer = 0x60298f78cc0b47170ba79c10aa3851d7648bd96f2f8e46a19dbc777c36fb0c00; // word is Solidity
    function guess(string memory _word) public view returns (bool) {
        return keccak256(abi.encodePacked(_word)) == answer;            // TODO - will they be able to see "Word"
    }
    /////////////////////////////////Security Mechanisms/////////////////////////////////



    /////////////////////////////////NFT Factory Functions/////////////////////////////////
    function createNFT(address receiverAddress, string memory inputTokenURI, string memory password) public returns (uint256) {

        require(isNFTfactoryEnabled, "NFT Factory is not enabled thus NFTs cannot be created.");
        require(guess(password), "incorrect pass");

        address creatorAddress = _msgSender();

        // if you want to limit an address from printing a certain amount of NFTs, uncomment these below, depending on what limits you want
        // require(balanceOf(creatorAddress) == 0, "Your Balance is not correct. You must have 0 NFTs ");   
        // require(numberOfNFTsCreated[creatorAddress] == 0, "You are only allowed to create 1 NFT, you must have created 0 NFTs");   
        // require(balanceOf(receiverAddress) == 0, "Receiver Balance is not correct. They must have 0 NFTs ");   
        // require(numberOfNFTsCreated[receiverAddress] == 0, "Receiver is only allowed to own 1 NFT, they have created an NFT in the past.");   

        tokenIDs.increment();

        uint256 newItemID = tokenIDs.current();
        safeMintNoData(receiverAddress, newItemID);
        setTokenURI(newItemID, inputTokenURI);

        numberOfNFTsCreated[creatorAddress]++;
        
        emit NFTcreated(creatorAddress, receiverAddress, newItemID, inputTokenURI);

        return newItemID;
    }


    function enableNFTfactory() public onlyOwner {
        isNFTfactoryEnabled = true;
        emit FactoryEnabled();
    }

    function disableNFTfactory() public onlyOwner {
        isNFTfactoryEnabled = false;
        emit FactoryDisabled();
    }



    




    /////////////////////////////////NFT Factory Functions/////////////////////////////////



// TODO - why can't i send nft tokens ot the contract?
// TODO - can't send eth to nft token contract
// TODO - figure out way to update IPFS data if it ever goes away? Do I need to do that on this side? 
//         Need to implement a function of how to change the NFTS
//             maybe I need to even make this a proxy?

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC721.sol";

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

pragma solidity ^0.8.4;

import "./IERC721.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.4;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./interfaces/IERC165.sol";

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
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol
// this has been slightly modified to incorporate BEP20 naming conventions as well as inhereting contracts in different places

pragma solidity ^0.8.4;

import "./interfaces/IBEP20.sol";
import "./utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
// https://github.com/binance-chain/bsc-genesis-contract/blob/master/contracts/bep20_template/BEP20Token.template
// https://docs.binance.org/smart-chain/developer/BEP20.html

pragma solidity ^0.8.4;


interface IBEP20 {

    // Functions
    
    function totalSupply() external view returns (uint256);     // Returns the amount of tokens in existence.

    function decimals() external view returns (uint8);  // Returns the token decimals.

    function symbol() external view returns (string memory); // Returns the token symbol.

    function name() external view returns (string memory); // Returns the token name.

    function getOwner() external view returns (address); // Returns the bep token owner.

    function balanceOf(address account) external view returns (uint256);   // Returns the amount of tokens owned by `account`
    
    function transfer(address recipient, uint256 amount) external returns (bool);  // transfer tokens to addr, Emits a {Transfer} event.

    function allowance(address _owner, address spender) external view returns (uint256); // Returns remaining tokens that spender is allowed during {approve} or {transferFrom} 

    function approve(address spender, uint256 amount) external returns (bool); // sets amount of allowance, emits approval event

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); // move amount, then reduce allowance, emits a transfer event


    // Events

    event Transfer(address indexed from, address indexed to, uint256 value);    // emitted when value tokens moved, value can be zero

    event Approval(address indexed owner, address indexed spender, uint256 value);  // emits when allowance of spender for owner is set by a call to approve. value is new allowance

}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}