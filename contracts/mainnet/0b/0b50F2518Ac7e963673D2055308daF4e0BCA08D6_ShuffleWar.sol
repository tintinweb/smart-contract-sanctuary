// SPDX-License-Identifier: MIT
/*
                                                                ,.                                  
                    @@@                                       ,@@@@@@@@@@@@@                        
                  @@@@@@@                                    @@   @@@@@#  (@@@@@*     %@@(          
                  @@@@@@@                               @@@@@[email protected]               @@@@@@@@@@@@@&        
                  @@@@@@@                              %@@@@@@@ @@,,  @@,      [email protected]@@@@@@@@@@@@       
             @@@@@@@@@@@@@@@                            @@@@@@@@      [email protected]@@@@   &@@@@@@@@@@@@@       
          #@@     @@@@@@@   @@*                           @@@@&              @@@@@@@@@@@@@@@&       
        @@#                   &@@                           *@@@         [email protected]@@@@@@@@@@@@@@@@         
        @@#                   &@@                            @@             @@@@@@@                 
        @@#                   &@@       /@   @@ @%@@@.       (@&              @@@@@@@                
     @@@                      &@@       /@   @@  @&.        @@                %@@@@@                
     @@@     @@%         ,@@  &@@        @@ @@     @@      @@                  @@@@ .               
     @@@@@#                   &@@         @@@   @@@@       @@                 @@@@                 
        @@#                   &@@                           @@              (@@@@@@                 
        @@#         ,@@       &@@                             @@@@@@@@@@@@@@@@@@@@@,                
        @@#              ,@@@@@@@@@@@@@@                               * @@@@@@@@@@@                
        @@#                             @@@                         &.,/@@@@@@@@@@@@(  ,            
          %@@            ,@@@@@@@@@@@@@@                         %    @@@@@@@@@@@@ ,      @         
          %@@            ,@@                                   @@@@ (&@@@@@@@@@/  ,  * @@@@@@@@@    
          %@@     @@@@@@@@                                    @@@   *(@@@@@@@  ..     ,@@@@@@@@@@   
          %@@       ,@@                                       @@@      @@@@/  ,,    ,@@@@@@@@@@@@@  
          %@@       ,@@                                      @@@@@   @  @    @    (@@@@@@@@@@@@@@@@ 

*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Puzzle.sol";

contract ShuffleWar is ERC721, Puzzle, Ownable {

  using Strings for uint256;

  string public baseURI;
  bool public isBaseURIset = false;

  uint256 public mintPrice = 20000000000000000;
  uint256 public editPrice = 0;

  uint16 constant MAX_TOKEN_ID = 9999;

  uint256 public earlyAccessWindowOpens = 1641916800;
  uint256 public gameStartWindowOpens  = 1641920400;

  uint16 public freeMintCount = 1000;
  uint8 public maxBatchMintCount = 20;

  bool public paused = false;

  uint16 public apeTotal;
  uint16 public punkTotal;

  struct TokenInfo {
      uint8 tokenType;
      bool editAllowed;
      uint16 shuffleTokenId;
      uint256[] movesData;
  }

  mapping (uint16 => TokenInfo) public tokenInfo;
  event NftMinted(address sender, uint16 tokenId);

  constructor() ERC721("punksVSapes", "PvsA") {}

  function _baseURI() override internal view virtual returns (string memory) {
      return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      string memory _base = _baseURI();
      return bytes(_base).length > 0 ? string(abi.encodePacked(_base, uint(tokenInfo[uint16(tokenId)].tokenType).toString(), "/", tokenId.toString())) : "";
  }

  function totalSupply() external view returns (uint16) {
    return getTotalMintedCount();
  }

  function getTotalMintedCount() public view returns (uint16) {
    return apeTotal + punkTotal;
 }

  function getMintPrice(uint8 count) public view returns (uint) {
    if (getTotalMintedCount() > freeMintCount) {
        return mintPrice * count;
    } else if (getTotalMintedCount() + count < freeMintCount) {
      return 0;
    } else {
      return (getTotalMintedCount() + count - freeMintCount) * mintPrice;
    }
  }
 
 function getTotalMintedCountForType() external view returns (uint16, uint16) {
   return (apeTotal, punkTotal);
 }

  function getOwnerInfoForToken(uint16 tokenId) external view returns (uint8, address) {
    TokenInfo memory info = tokenInfo[tokenId];
    return (info.tokenType, ownerOf(tokenId));
  }

   function isAvailableForSale(uint16 tokenId) external view returns (bool) {
    return !(_exists(tokenId));
  }

  function getGameStartWindows() external view returns (uint256, uint256) {
    return (earlyAccessWindowOpens, gameStartWindowOpens);
  }

   function getShuffledNumbersForToken(uint16 tokenId) public view returns (uint8[9] memory shuffledOrder, uint16 shuffleIteration) {
        uint16 shuffleTokenId = tokenInfo[tokenId].shuffleTokenId;
        if (shuffleTokenId != 0) {
          return _getShuffledNumbersForToken(shuffleTokenId);
        } else {
          return _getShuffledNumbersForToken(tokenId);
        }
    }

  function getOwnerInfoForTokens(uint16[] memory tokenIds) external view returns (uint8[] memory) {
      uint totalCount = tokenIds.length;
      uint8[] memory ownerInfo = new uint8[](totalCount);

      for (uint16 i=0; i < totalCount; i++) {
        TokenInfo memory info = tokenInfo[tokenIds[i]];

        bool available = !_exists(tokenIds[i]);
        uint8 tokenType = info.tokenType;
        
        if (available) {
            ownerInfo[i] = 1;
        } else {
            if (tokenType == 0) {
              ownerInfo[i] = 2;
            } else {
              ownerInfo[i] = 3;
            }
        }
      }
      return ownerInfo;
  }

   function getMovesForToken(uint16 tokenId) external view returns (uint256[] memory) {
    return tokenInfo[uint16(tokenId)].movesData;
   }

/*
tokenType - 0 (ape), 1 (punk)
only 1 type can be minted for a tokenId
eg. if someone mints 80 for ape, then 80 can't be minted for punk

@dev

There are two parameters for moves data, bytes moves is optimised for verification of moves
and uint256[] movesData is optimised for storage

All moves of the user are replayed on the original shuffle order for that tokenId (also generated from contract) and the final order
order is verified to make sure user actually solved the puzzle

_movesData is a compressed array of uint256 representing the user's moves. Each move on the puzzle is recorded as a up,down,left,right action
(as 1,2,3,4 in this data, represented as base5). These moves are then converted to base10 and split into multiple uint256 each having 76 digits.
Around 104 moves can be stored in a single uint256 in 76 digits after changing the base from 5 to 10.
Effectively - 300 moves can be packed into an array of 3 uint256
*/

  function verifyAndMintItem(uint16 tokenId, 
        uint8 tokenType, 
        bytes memory moves, 
        uint256[] memory _movesData,
        uint16 shuffleIterationCount,
        uint16[] memory batchMintTokens)
      external
      payable
  {

      require(!paused, "Minting paused");

      require(block.timestamp >= earlyAccessWindowOpens, "Game not started");
      require(block.timestamp >= gameStartWindowOpens || getTotalMintedCount() < freeMintCount, "EA limit reached");

      uint8 totalMintCount = uint8(batchMintTokens.length) + 1;
      require(msg.value == getMintPrice(totalMintCount), "Incorrect payment");

      require(!(_exists(tokenId)), "Already minted");
      require(tokenId > 0 && tokenId <= MAX_TOKEN_ID, "Invalid tokenId");
      require(tokenType == 0 || tokenType == 1, "Invalid tokenType");

      require(batchMintTokens.length <= maxBatchMintCount, "Token limit exceeded");

      require (verifyMoves(tokenId, moves, shuffleIterationCount), "Puzzle not solved, unable to verify moves");

      for (uint8 i = 0; i < batchMintTokens.length; i++) {
          uint16 nextMintTokenId = batchMintTokens[i];
          require(!(_exists(nextMintTokenId)), "Already minted");
          require(nextMintTokenId > 0 && nextMintTokenId <= MAX_TOKEN_ID, "Invalid tokenId");
          tokenInfo[nextMintTokenId] = TokenInfo(tokenType, false, tokenId, _movesData);
          _safeMint(msg.sender, nextMintTokenId);
          emit NftMinted(msg.sender, nextMintTokenId);
      }

      tokenInfo[tokenId] = TokenInfo(tokenType, false, 0, _movesData);
      _safeMint(msg.sender, tokenId);
      emit NftMinted(msg.sender, tokenId);

      if (tokenType == 0) {
          apeTotal += totalMintCount;
      } else {
          punkTotal += totalMintCount;
      }
  }


  function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._transfer( from, to, tokenId);
        // @dev
        // once a transfer happens, the new owner is allowed to solve the puzzle again and
        // will be able to edit their moves once
        tokenInfo[uint16(tokenId)].editAllowed = true;
    }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    require(!isBaseURIset, "Base URI is locked");
    baseURI = _newBaseURI;
  }

  function lockBaseURI() external onlyOwner {
     isBaseURIset = true;
  }

  function setMintPrice(uint256 newMintPrice) external onlyOwner {
    mintPrice = newMintPrice;
  }

  function setEditPrice(uint256 newEditPrice) external onlyOwner {
    editPrice = newEditPrice;
  }

  function setFreeMintCount(uint16 count) external onlyOwner {
    freeMintCount = count;
  }

  function setMaxBatchMintCount(uint8 count) external onlyOwner {
    maxBatchMintCount = count;
  }

  function pause(bool _state) external onlyOwner {
    paused = _state;
  }

  function editStartWindows(
        uint256 _earlyAccessWindowOpens,
        uint256 _gameStartWindowOpens
    ) external onlyOwner {
        require(
            _gameStartWindowOpens > _earlyAccessWindowOpens,
            "window combination not allowed"
        );
        gameStartWindowOpens = _gameStartWindowOpens;
        earlyAccessWindowOpens = _earlyAccessWindowOpens;
  }

   function getShuffledNumbersForEditMoves(uint16 tokenId) public pure returns (uint8[9] memory shuffledOrder, uint16 shuffleIteration) {
       return _getShuffledNumbersForToken(tokenId);
    }

  function editMoves(
        uint16 tokenId, 
        uint8 tokenType, 
        bytes memory moves, 
        uint256[] memory _movesData, 
        uint16 shuffleIterationCount
    ) external payable {

    require(_exists(tokenId), "EditMoves: TokenId doesn't exist");
    require(tokenInfo[uint16(tokenId)].editAllowed, "EditMoves: Not allowed to edit moves");
    require(msg.sender == ownerOf(tokenId), "Not authorised to edit token type");
    require(msg.value == editPrice, "Incorrect payment");
    require(tokenType == 0 || tokenType == 1, "Invalid tokenType");
    require (verifyMoves(tokenId, moves, shuffleIterationCount), "Puzzle not solved, unable to verify moves");

    tokenInfo[tokenId] = TokenInfo(tokenType, false, 0, _movesData);
  }

  function releaseFunds() public onlyOwner {
    (bool success, ) = payable(0x54caD98D0EFF87A31fB0BF046e2912e836fa832B).call{value: address(this).balance}("");
    require(success);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
        _setApprovalForAll(_msgSender(), operator, approved);
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
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Puzzle {

    function _getShuffledNumbersForToken(uint16 tokenId) internal pure returns (uint8[9] memory shuffledOrder, uint16 shuffleIteration) {
        return _getShuffledNumbersForToken(tokenId, 0, false);
    }

    function _getShuffledNumbersForToken(uint16 tokenId, uint16 shuffleIterationCount, bool skipCheckSolvable) private pure returns (uint8[9] memory shuffledOrder, uint16 shuffleIteration) {
        return _shuffleNumbers(tokenId, shuffleIterationCount, skipCheckSolvable);
    }

    function _shuffleNumbers(uint16 tokenId, uint16 shuffleIteration, bool skipCheckSolvable) private pure returns (uint8[9] memory, uint16 shuffleIterationCount) {
        uint8[9] memory _numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8];

        uint16 shuffledTokenId = tokenId + shuffleIteration;

        for (uint8 i = 0; i < _numbers.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(shuffledTokenId))) % (_numbers.length - i);
            uint8 temp = _numbers[n];
            _numbers[n] = _numbers[i];
            _numbers[i] = temp;
        }
        // the order created based on a tokenId might not be solvable, check if this order is solvable in a 3x3 puzzle else
        // create another shuffle order based on next tokenId.
        // The shuffleIterations required to get a solvable shuffled order (generally 0 or 1) is also passed in return so that 
        // we can skip the isSolvable checks in actual minting to prevent gas
        if (skipCheckSolvable || _checkSolvable(_numbers)) {
            return (_numbers, shuffleIteration);
        } else {
            return _shuffleNumbers(tokenId, shuffleIteration + 1, skipCheckSolvable);
        }
    }

    function verifyMoves(uint16 tokenId, bytes memory moves, uint16 shuffleIterationCount) public pure returns (bool) {

        (uint8[9] memory shuffledOrder, ) = _getShuffledNumbersForToken(tokenId, shuffleIterationCount, true);

        bytes1 indexOf1 = 0;
        bytes1 indexOf2 = 0;
        bytes1 indexOf3 = 0;
        bytes1 indexOf4 = 0;
        bytes1 indexOf5 = 0;
        bytes1 indexOf6 = 0;
        bytes1 indexOf7 = 0;
        bytes1 indexOf8 = 0;
        bytes1 indexOf0 = 0;

        
        for (uint8 i=0; i < shuffledOrder.length; i++) {
            uint8 order = shuffledOrder[i];
            if (order == 0) {
                indexOf0 = bytes1(i);
            } else if (order == 1) {
                indexOf1 = bytes1(i);
            } else if (order == 2) {
                indexOf2 = bytes1(i);
            } else if (order == 3) {
                indexOf3 = bytes1(i);
            } else if (order == 4) {
                indexOf4 = bytes1(i);
            } else if (order == 5) {
                indexOf5 = bytes1(i);
            } else if (order == 6) {
                indexOf6 = bytes1(i);
            } else if (order == 7) {
                indexOf7 = bytes1(i);
            } else if (order == 8) {
                indexOf8 = bytes1(i);
            }
        }

        for (uint16 i=0; i < moves.length; i++) {

            bytes1 move = moves[i];

            if (move == 0x01) {
                (indexOf0, indexOf1) = (indexOf1, indexOf0);
            } else if (move == 0x02) {
                (indexOf0, indexOf2) = (indexOf2, indexOf0);
            } else if (move == 0x03) {
                (indexOf0, indexOf3) = (indexOf3, indexOf0);
            } else if (move == 0x04) {
                (indexOf0, indexOf4) = (indexOf4, indexOf0);
            } else if (move == 0x05) {
                (indexOf0, indexOf5) = (indexOf5, indexOf0);
            } else if (move == 0x06) {
                (indexOf0, indexOf6) = (indexOf6, indexOf0);
            } else if (move == 0x07) {
                (indexOf0, indexOf7) = (indexOf7, indexOf0);
            } else if (move == 0x08) {
                (indexOf0, indexOf8) = (indexOf8, indexOf0);
            }
        }

        // final array should be 1,2,3,4,5,6,7,8,0
        return indexOf1 == 0 && indexOf2 == 0x01 && indexOf3 == 0x02 && indexOf4 == 0x03
                && indexOf5 == 0x04 && indexOf6 == 0x05 && indexOf7 == 0x06 && indexOf8 == 0x07
                && indexOf0 == 0x08;
    }

    function _checkSolvable(uint8[9] memory puzzle) private pure returns (bool) {

        uint16 parity = 0;
        uint8 gridWidth = 3;
        uint8 row = 0; 
        uint8 blankRow = 0;

        for (uint16 i = 0; i < puzzle.length; i++)
        {
            if (i % gridWidth == 0) { 
                row++;
            }
            if (puzzle[i] == 0) { 
                blankRow = row;
                continue;
            }
            for (uint16 j = i + 1; j < puzzle.length; j++)
            {
                if (puzzle[i] > puzzle[j] && puzzle[j] != 0)
                {
                    parity++;
                }
            }
        }

        if (gridWidth % 2 == 0) {
            if (blankRow % 2 == 0) {
                return parity % 2 == 0;
            } else { 
                return parity % 2 != 0;
            }
        } else {
            return parity % 2 == 0;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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