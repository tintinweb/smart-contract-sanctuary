// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "mintpress/contracts/Mintpress.sol";

contract LUSCCollection is Mintpress
{
  /**
   * @dev Constructor function
   */
  constructor (
    string memory _name, 
    string memory _symbol, 
    string memory _baseTokenURI, 
    string memory _contractURI
  ) Mintpress(_name, _symbol, _baseTokenURI, _contractURI) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//implementation of ERC721
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//implementation of ERC721 where tokens can be irreversibly 
//burned (destroyed).
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
//abstract of cross compliant royalties in multi classes
import "./Mintpress/abstractions/MintpressChargable.sol";
//abstract that allows tokens to be listed and exchanged considering 
//royalty fees in multi classes
import "./Mintpress/abstractions/MintpressExchangable.sol";
//abstract defines common publicly accessable contract methods
import "./Mintpress/abstractions/MintpressInformable.sol";
//abstract that opens the order book methods
import "./Mintpress/abstractions/MintpressListable.sol";
//abstract that opens up various minting methods
import "./Mintpress/abstractions/MintpressMintable.sol";
//opens up the pausible methods
import "./Mintpress/abstractions/MintpressPausable.sol";
//passes multi class methods to Mintpress
import "./Mintpress/abstractions/MintpressSortable.sol";
//abstract of a BEP721 that pre defines total supply
import "./BEP721/BEP721.sol";
//rarible royalties v2 library
import "./Rarible/LibRoyaltiesV2.sol";

contract Mintpress is
  ERC721,
  BEP721,
  MintpressSortable,
  MintpressMintable,
  MintpressListable,
  MintpressChargable,
  MintpressPausable,
  MintpressExchangable,
  MintpressInformable,
  ERC721Burnable
{
  /**
   * @dev Constructor function
   */
  constructor (
    string memory _name, 
    string memory _symbol, 
    string memory _baseTokenURI, 
    string memory _contractURI
  ) 
    ERC721(_name, _symbol)
    MintpressInformable(_baseTokenURI, _contractURI)
  {}

  /**
   * @dev override; super defined in MultiClass; Returns the class 
   *      given `tokenId`
   */
  function classOf(uint256 tokenId) 
    public 
    virtual 
    view 
    override(MintpressInformable, MultiClass, MultiClassFees) 
    returns(uint256) 
  {
    return super.classOf(tokenId);
  }

  /**
   * @dev override; super defined in MultiClassSupply; Returns true if 
   *      `classId` supply and size are equal
   */
  function classFilled(uint256 classId) 
    public 
    view 
    virtual 
    override(MintpressMintable, MultiClassSupply) 
    returns(bool)
  {
    return super.classFilled(classId);
  }

  /**
   * @dev override; super defined in MultiClassSupply; Returns the  
   *      total possible supply size of `classId`
   */
  function classSize(uint256 classId) 
    public 
    view 
    virtual 
    override(MintpressMintable, MultiClassSupply) 
    returns(uint256)
  {
    return super.classSize(classId);
  }

  /**
   * @dev override; super defined in MultiClassSupply; Returns the  
   *      current supply size of `classId`
   */
  function classSupply(uint256 classId) 
    public 
    view 
    virtual 
    override(MintpressMintable, MultiClassSupply) 
    returns(uint256)
  {
    return super.classSupply(classId);
  }

  /**
   * @dev override; super defined in MultiClassURIStorage; Returns the 
   *      data of `classId`
   */
  function classURI(uint256 classId) 
    public 
    virtual 
    view 
    override(MintpressInformable, MultiClassURIStorage) 
    returns(string memory) 
  {
    return super.classURI(classId);
  }

  /**
   * @dev override; super defined in MultiClassOrderBook; Returns the 
   *      amount a `tokenId` is being offered for.
   */
  function listingOf(uint256 tokenId) 
    public 
    view 
    virtual 
    override(MultiClassOrderBook, MintpressExchangable) 
    returns(uint256) 
  {
    return super.listingOf(tokenId);
  }

  /**
   * @dev override; super defined in ERC721; Specifies the name by 
   *      which other contracts will recognize the BEP-721 token 
   */
  function name() 
    public virtual view override(IBEP721, ERC721) returns(string memory) 
  {
    return super.name();
  }
  
  /**
   * @dev override; super defined in ERC721; Returns the owner of 
   *      a `tokenId`
   */
  function ownerOf(uint256 tokenId) 
    public 
    view 
    virtual 
    override(IERC721, ERC721, MultiClassOrderBook, MintpressExchangable) 
    returns(address) 
  {
    return super.ownerOf(tokenId);
  }

  /**
   * @dev References `classId` to `data` and `size`
   */
  function register(uint256 classId, uint256 size, string memory uri)
    external virtual onlyOwner
  {
    _setClassURI(classId, uri);
    //if size was set, fix it. Setting a zero size means no limit.
    if (size > 0) {
      _fixClassSize(classId, size);
    }
  }

  /**
   * @dev Rarible support interface
   */
  function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC721, IERC165) returns(bool)
  {
    if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }

    if (interfaceId == MintpressChargable._INTERFACE_ID_ERC2981) {
      return true;
    }

    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev override; super defined in ERC721; A concise name for the token, 
   *      comparable to a ticker symbol 
   */
  function symbol() 
    public 
    virtual 
    view 
    override(IBEP721, ERC721) returns(string memory) 
  {
    return super.symbol();
  }

  /**
   * @dev override; super defined in MintpressInformable; Returns the 
   *      URI of the given `tokenId`. Example Format:
   *      {
   *        "description": "Friendly OpenSea Creature", 
   *        "external_url": "https://mywebsite.com/3", 
   *        "image": "https://mywebsite.com/3.png", 
   *        "name": "My NFT",
   *        "attributes": {
   *          "background_color": "#000000",
   *          "animation_url": "",
   *          "youtube_url": ""
   *        } 
   *      }
   */
  function tokenURI(uint256 tokenId) 
    public 
    view 
    virtual 
    override(ERC721, MintpressInformable)
    returns(string memory) 
  {
    return super.tokenURI(tokenId);
  }

  /**
   * @dev override; super defined in MultiClassSupply; Increases the  
   *      supply of `classId` by `amount`
   */
  function _addClassSupply(uint256 classId, uint256 amount) 
    internal virtual override(MintpressMintable, MultiClassSupply)
  {
    super._addClassSupply(classId, amount);
  }

  /**
   * @dev override; super defined in BEP721; Adds to the overall amount 
   *      of tokens generated in the contract
   */
  function _addSupply(uint256 supply) 
    internal virtual override(BEP721, MintpressMintable)
  {
    super._addSupply(supply);
  }

  /**
   * @dev Resolves duplicate _beforeTokenTransfer method definition
   * between ERC721 and ERC721Pausable
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override(ERC721, ERC721Pausable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  /**
   * @dev override; super defined in MultiClass; Maps `tokenId` 
   *      to `classId`
   */
  function _classify(uint256 tokenId, uint256 classId) 
    internal virtual override(MintpressMintable, MultiClass)
  {
    super._classify(tokenId, classId);
  }
  
  /**
   * @dev override; super defined in MultiClassListings; Removes 
   *      `tokenId` from the order book.
   */
  function _delist(uint256 tokenId) 
    internal 
    virtual 
    override(MintpressExchangable, MultiClassOrderBook) 
  {
    return super._delist(tokenId);
  }
  
  /**
   * @dev Pays the amount to the recipients
   */
  function _escrowFees(uint256 tokenId, uint256 amount)
    internal 
    virtual 
    override(MintpressExchangable, MultiClassFees) 
    returns(uint256) 
  {
    return super._escrowFees(tokenId, amount);
  }

  /**
   * @dev override; super defined in Context; Returns the address of  
   *      the method caller
   */
  function _msgSender() 
    internal 
    view 
    virtual 
    override(Context, MultiClassOrderBook, MintpressExchangable) 
    returns(address) 
  {
    return super._msgSender();
  }
    
  /**
   * @dev override; super defined in ERC721; Same as `_safeMint()`, 
   *      with an additional `data` parameter which is forwarded in 
   *      {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(address to, uint256 tokenId) 
    internal virtual override(ERC721, MintpressMintable)
  {
    super._safeMint(to, tokenId);
  }
  
  /**
   * @dev override; super defined in ERC721; Transfers `tokenId` 
   *      from `from` to `to`.
   */
  function _transfer(address from, address to, uint256 tokenId) 
    internal virtual override(ERC721, MintpressExchangable) 
  {
    return super._transfer(from, to, tokenId);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
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

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//labels contract owner only methods
import "@openzeppelin/contracts/access/Ownable.sol";
//interface of an ERC2981 compliant contract
import "../../ERC2981/IERC2981.sol";
//interface of a Rarible Royalties v2 compliant contract
import "../../Rarible/RoyaltiesV2.sol";
//abstract that considers royalty fees in multi classes
import "../../MultiClass/abstractions/MultiClassFees.sol";

/**
 * @dev Abstract of cross compliant royalties in multi classes
 */
abstract contract MintpressChargable is 
  MultiClassFees, 
  RoyaltiesV2, 
  Ownable 
{
  /*
   * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
   */
  bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  /**
   * @dev Sets a fee that will be collected during the exchange method
   */
  function allocate(uint256 classId, address recipient, uint96 fee)
    external virtual onlyOwner
  {
    _allocateFee(classId, recipient, fee);
  }

  /**
   * @dev Removes a fee
   */
  function deallocate(uint256 classId, address recipient)
    external virtual onlyOwner
  {
    _deallocateFee(classId, recipient);
  }
  
  /**
   * @dev implements Rari getRaribleV2Royalties()
   */
  function getRaribleV2Royalties(uint256 tokenId) 
    external view virtual returns(LibPart.Part[] memory) 
  {
    uint256 classId = classOf(tokenId);
    uint256 size = _recipients[classId].length;
    //this is how to set the size of an array in memory
    LibPart.Part[] memory royalties = new LibPart.Part[](size);
    for (uint i = 0; i < size; i++) {
      address recipient = _recipients[classId][i];
      royalties[i] = LibPart.Part(
        payable(recipient), 
        _fee[classId][recipient]
      );
    }

    return royalties;
  }

  /**
   * @dev implements ERC2981 `royaltyInfo()`
   */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) 
    external 
    view 
    virtual 
    returns(address receiver, uint256 royaltyAmount) 
  {
    uint256 classId = classOf(_tokenId);
    if (_recipients[classId].length == 0) {
      return (address(0), 0);
    }

    address recipient = _recipients[classId][0];
    return (
      payable(recipient), 
      (_salePrice * _fee[classId][recipient]) / 10000
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Abstract that allows tokens to be listed
 * and exchanged considering royalty fees in multi classes
 */
abstract contract MintpressExchangable {
  // manual ReentrancyGuard
  bool private _exchanging = false;

  /**
   * @dev abstract; defined in MultiClassOrderBook; Returns the 
   *      amount a `tokenId` is being offered for.
   */
  function listingOf(uint256 tokenId) 
    public view virtual returns(uint256);
  
  /**
   * @dev abstract; defined in ERC721; Returns the owner of a `tokenId`
   */
  function ownerOf(uint256 tokenId) 
    public view virtual returns(address);

  /**
   * @dev abstract; defined in MultiClassOrderBook; Removes `tokenId` 
   *      from the order book.
   */
  function _delist(uint256 tokenId) internal virtual;
  
  /**
   * @dev abstract; defined in MultiClassOrderBook; Pays the amount 
   *      to the recipients
   */
  function _escrowFees(uint256 tokenId, uint256 amount)
    internal virtual returns(uint256);
  
  /**
   * @dev abstract; defined in Context; Returns the address of the 
   *      method caller
   */
  function _msgSender() internal view virtual returns(address);
  
  /**
   * @dev abstract; defined in ERC721; Transfers `tokenId` from 
   *      `from` to `to`.
   */
  function _transfer(address from, address to, uint256 tokenId) 
    internal virtual;
  
  /**
   * @dev Allows for a sender to exchange `tokenId` for the listed amount
   */
  function exchange(uint256 tokenId) 
    external virtual payable 
  {
    //get listing
    uint256 listing = listingOf(tokenId);
    //should be a valid listing
    require(listing > 0, "Token is not listed");
    //value should equal the listing amount
    require(
      msg.value == listing,
      "Amount sent does not match the listing amount"
    );
    // manual ReentrancyGuard
    require(!_exchanging, "reentrant call");
    _exchanging = true;

    //payout the fees
    uint256 remainder = _escrowFees(tokenId, msg.value);
    //get the token owner
    address payable tokenOwner = payable(ownerOf(tokenId));
    //send the remainder to the token owner
    tokenOwner.transfer(remainder);
    //transfer token from owner to buyer
    _transfer(tokenOwner, _msgSender(), tokenId);
    //now that the sender owns it, delist it
    _delist(tokenId);

    _exchanging = false;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract of an OpenSea compliant contract
import "../../OpenSea/ERC721OpenSea.sol";

/**
 * @dev Abstract defines common publicly accessable contract methods
 */
abstract contract MintpressInformable is ERC721OpenSea {
  /**
   * @dev abstract; defined in MultiClass; Returns the class 
   *      given `tokenId`
   */
  function classOf(uint256 tokenId) 
    public virtual view returns(uint256);

  /**
   * @dev abstract; defined in MultiClassURIStorage; Returns the 
   *      data of `classId`
   */
  function classURI(uint256 classId) 
    public virtual view returns(string memory);

  /**
   * @dev Constructor function
   */
  constructor (string memory _baseTokenURI, string memory _contractURI) 
    ERC721OpenSea(_baseTokenURI, _contractURI)
  {}

  /**
   * @dev Returns the URI of the given `tokenId`
   *      Example Format:
   *      {
   *        "description": "Friendly OpenSea Creature.", 
   *        "external_url": "https://mywebsite.com/3", 
   *        "image": "https://mywebsite.com/3.png", 
   *        "name": "My NFT",
   *        "attributes": {
   *          "background_color": "#000000",
   *          "animation_url": "",
   *          "youtube_url": ""
   *        } 
   *      }
   */
  function tokenURI(uint256 tokenId) 
    public 
    view 
    virtual 
    returns(string memory) 
  {
    uint256 classId = classOf(tokenId);

    require(
      classId > 0, 
      "Token is not apart of a multiclass"
    ); 
    
    return classURI(classId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract that allows tokens to be listed in an order book
import "../../MultiClass/abstractions/MultiClassOrderBook.sol";

/**
 * @dev Abstract that opens the order book methods
 */
abstract contract MintpressListable is MultiClassOrderBook {
  /**
   * @dev Removes `tokenId` from the order book.
   */
  function delist(uint256 tokenId) external virtual {
    _delist(tokenId);
  }

  /**
   * @dev Lists `tokenId` on the order book for `amount` in wei.
   */
  function list(uint256 tokenId, uint256 amount) 
    external virtual 
  {
    _list(tokenId, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//labels contract owner only methods
import "@openzeppelin/contracts/access/Ownable.sol";
//for verifying messages in lazyMint
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
//provably fair library for `mintPack()`
import "../generators/ProvablyFair.sol";
//random prize picker for `mintPack()`
import "../generators/RandomPrize.sol";

/**
 * @dev Abstract that opens up various minting methods
 */
abstract contract MintpressMintable is Ownable {
  // manual ReentrancyGuard
  bool private _minting = false;

  /**
   * @dev abstract; defined in MultiClassSupply; Returns true if 
   *      `classId` supply and size are equal
   */
  function classFilled(uint256 classId) 
    public view virtual returns(bool);

  /**
   * @dev abstract; defined in MultiClassSupply; Returns the total 
   *      possible supply size of `classId`
   */
  function classSize(uint256 classId) 
    public view virtual returns(uint256);

  /**
   * @dev abstract; defined in MultiClassSupply; Returns the current 
   *      supply size of `classId`
   */
  function classSupply(uint256 classId) 
    public view virtual returns(uint256);

  /**
   * @dev abstract; defined in MultiClassSupply; Increases the supply 
   *      of `classId` by `amount`
   */
  function _addClassSupply(uint256 classId, uint256 amount) 
    internal virtual;

  /**
   * @dev abstract; defined in BEP721; Adds to the overall amount 
   *      of tokens generated in the contract
   */
  function _addSupply(uint256 supply) internal virtual;

  /**
   * @dev abstract; defined in MultiClass; Maps `tokenId` to `classId`
   */
  function _classify(uint256 tokenId, uint256 classId) 
    internal virtual;
    
  /**
   * @dev abstract; defined in ERC721; Same as `_safeMint()`, with an 
   *      additional `data` parameter which is forwarded in 
   *      {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(address to, uint256 tokenId) 
    internal virtual;
  
  /**
   * @dev Allows anyone to self mint a token
   */
  function lazyMint(
    uint256 classId,
    uint256 tokenId,
    address recipient,
    bytes calldata proof
  ) external virtual {
    //check size
    require(!classFilled(classId), "Class filled.");
    //make sure the admin signed this off
    require(
      ECDSA.recover(
        ECDSA.toEthSignedMessageHash(
          keccak256(
            abi.encodePacked(classId, tokenId, recipient)
          )
        ),
        proof
      ) == owner(),
      "Invalid proof."
    );
    // manual ReentrancyGuard
    require(!_minting, "reentrant call");
    _minting = true;

    //mint first and wait for errors
    _safeMint(recipient, tokenId);
    //then classify it
    _classify(tokenId, classId);
    //then increment supply
    _addClassSupply(classId, 1);
    //add to supply
    _addSupply(1);

    _minting = false;
  }

  /**
   * @dev Mints `tokenId`, classifies it as `classId` and 
   *      transfers to `recipient`
   */
  function mint(uint256 classId, uint256 tokenId, address recipient)
    public virtual onlyOwner
  {
    //check size
    require(!classFilled(classId), "Class filled.");
    //mint first and wait for errors
    _safeMint(recipient, tokenId);
    //then classify it
    _classify(tokenId, classId);
    //then increment supply
    _addClassSupply(classId, 1);
    //add to supply
    _addSupply(1);
  }

  /**
   * @dev Randomly assigns a set of NFTs to a `recipient`
   */
  function mintPack(
    uint256[] memory classIds, 
    uint256 fromTokenId,
    address recipient, 
    uint8 tokensInPack,
    uint256 defaultSize,
    string memory seed
  ) external virtual onlyOwner {
    require(defaultSize > 0, "Missing default size");
    uint256[] memory rollToPrizeMap = new uint256[](classIds.length);
    uint256 size;
    uint256 supply;
    //loop through classIds
    for (uint8 i = 0; i < classIds.length; i++) {
      //get the class size
      size = classSize(classIds[i]);
      //if the class size is no limits
      if (size == 0) {
        //use the default size
        size = defaultSize;
      }
      //get the supply
      supply = classSupply(classIds[i]);
      //if the supply is greater than the size
      if (supply >= size) {
        //then we should zero out the 
        rollToPrizeMap[i] = 0;
        continue;
      }
      //determine the roll range for this class
      rollToPrizeMap[i] = size - supply;
      //to make it really a range we need 
      //to append the the last class range
      if (i > 0) {
        rollToPrizeMap[i] += rollToPrizeMap[i - 1];
      }
    }

    //figure out the max roll value 
    //(which should be the last value in the roll to prize map)
    uint256 maxRollValue = rollToPrizeMap[rollToPrizeMap.length - 1];
    //max roll value is also the total available tokens that can be 
    //minted if the tokens in pack is more than that, then we should 
    //error
    require(
      tokensInPack <= maxRollValue, 
      "Not enough tokens to make a mint pack"
    );

    //now we can create a prize pool
    RandomPrize.PrizePool memory pool = RandomPrize.PrizePool(
      ProvablyFair.RollState(
        maxRollValue, 0, 0, blockhash(block.number - 1)
      ), 
      classIds, 
      rollToPrizeMap
    );

    // manual ReentrancyGuard
    require(!_minting, "reentrant call");
    _minting = true;

    uint256 classId;
    // for each token in the pack
    for (uint8 i = 0; i < tokensInPack; i++) {
      //figure out what the winning class id is
      classId = RandomPrize.roll(pool, seed, (i + 1) < tokensInPack);
      //if there is a class id
      if (classId > 0) {
        //then lets mint it
        mint(classId, fromTokenId + i, recipient);
      }
    }

    _minting = false;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//labels contract owner only methods
import "@openzeppelin/contracts/access/Ownable.sol";
//implementation of ERC721 where transers can be paused
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";

/**
 * @dev Opens up the pausible methods
 */
abstract contract MintpressPausable is ERC721Pausable, Ownable {
  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual onlyOwner {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//abstract implementation of a multi class token factory
import "../../MultiClass/abstractions/MultiClass.sol";
//abstract implementation of managing token supplies in multi classes
import "../../MultiClass/abstractions/MultiClassSupply.sol";
//abstract implementation of attaching URIs in token classes
import "../../MultiClass/abstractions/MultiClassURIStorage.sol";

/**
 * @dev Passes multi class methods to Mintpress
 */
abstract contract MintpressSortable is 
  MultiClass, 
  MultiClassSupply, 
  MultiClassURIStorage
{
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//interface of a BEP721 compliant contract
import "./interfaces/IBEP721.sol";

/**
 * @dev Abstract of a BEP721 that pre defines total supply
 */
abstract contract BEP721 is IBEP721 {
  //for total supply
  uint256 private _supply = 0;

  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalSupply() public virtual view returns (uint256) {
    return _supply;
  }

  /**
   * @dev Adds to the overall amount of tokens generated in the contract
   */
  function _addSupply(uint256 supply) internal virtual {
    _supply += supply;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibRoyaltiesV2 {
  /*
   * bytes4(keccak256('getRaribleV2Royalties(uint256)')) == 0xcad96cca
   */
  bytes4 constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
        return msg.data;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//interface of an ERC165 compliant contract
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
  /** 
   * @dev ERC165 bytes to add to interface array - set in parent contract
   *  implementing this standard
   * 
   *  bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
   *  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
   *  _registerInterface(_INTERFACE_ID_ERC2981);
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view returns (
    address receiver,
    uint256 royaltyAmount
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LibPart.sol";

interface RoyaltiesV2 {
  event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

  function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//interface of a MultiClassFees compliant contract
import "./../interfaces/IMultiClassFees.sol";

/**
 * @dev Abstract that considers royalty fees in multi classes
 */
abstract contract MultiClassFees is IMultiClassFees {
  //10000 means 100.00%
  uint256 private constant TOTAL_ALLOWABLE_FEES = 10000;
  //mapping of `classId` to total fees (could be problematic if not synced)
  mapping(uint256 => uint96) private _fees;
  //mapping of `classId` to `recipient` fee
  mapping(uint256 => mapping(address => uint96)) internal _fee;
  //index mapping of `classId` to recipients (so we can loop the map)
  mapping(uint256 => address[]) internal _recipients;

  /**
   * @dev Returns the class given `tokenId`
   */
  function classOf(uint256 tokenId) 
    public view virtual returns(uint256);

  /**
   * @dev Returns the fee of a `recipient` in `classId`
   */
  function classFeeOf(uint256 classId, address recipient)
    public view virtual returns(uint256)
  {
    return _fee[classId][recipient];
  }

  /**
   * @dev returns the total fees of `classId`
   */
  function classFees(uint256 classId) 
    public view virtual returns(uint256) 
  {
    return _fees[classId];
  }

  /**
   * @dev Sets a fee that will be collected during the exchange method
   */
  function _allocateFee(uint256 classId, address recipient, uint96 fee)
    internal virtual
  {
    require(
      fee > 0,
      "Fee should be more than 0"
    );

    //if no recipient
    if (_fee[classId][recipient] == 0) {
      //add recipient
      _recipients[classId].push(recipient);
      //map fee
      _fee[classId][recipient] = fee;
      //add to total fee
      _fees[classId] += fee;
    //else there"s already an existing recipient
    } else {
      //remove old fee from total fee
      _fees[classId] -= _fee[classId][recipient];
      //map fee
      _fee[classId][recipient] = fee;
      //add to total fee
      _fees[classId] += fee;
    }

    //safe check
    require(
      _fees[classId] <= TOTAL_ALLOWABLE_FEES,
      "Exceeds allowable fees"
    );
  }

  /**
   * @dev Removes a fee
   */
  function _deallocateFee(uint256 classId, address recipient) internal virtual {
    //this is for the benefit of the sender so they
    //dont have to pay gas on things that dont matter
    require(
      _fee[classId][recipient] != 0,
      "Recipient has no fees"
    );
    //deduct total fees
    _fees[classId] -= _fee[classId][recipient];
    //remove fees from the map
    delete _fee[classId][recipient];
    //Tricky logic to remove an element from an array...
    //if there are at least 2 elements in the array,
    if (_recipients[classId].length > 1) {
      //find the recipient
      for (uint i = 0; i < _recipients[classId].length; i++) {
        if(_recipients[classId][i] == recipient) {
          //move the last element to the deleted element
          uint last = _recipients[classId].length - 1;
          _recipients[classId][i] = _recipients[classId][last];
          break;
        }
      }
    }

    //either way remove the last element
    _recipients[classId].pop();
  }

  /**
   * @dev Pays the amount to the recipients
   */
  function _escrowFees(uint256 tokenId, uint256 amount)
    internal virtual returns(uint256)
  {
    //get class from token
    uint256 classId = classOf(tokenId);
    require(classId != 0, "Class does not exist");

    //placeholder for recipient in the loop
    address recipient;
    //release payments to recipients
    for (uint i = 0; i < _recipients[classId].length; i++) {
      //get the recipient
      recipient = _recipients[classId][i];
      // (10 eth * 2000) / 10000 =
      payable(recipient).transfer(
        (amount * _fee[classId][recipient]) / TOTAL_ALLOWABLE_FEES
      );
    }

    //determine the remaining fee percent
    uint256 remainingFee = TOTAL_ALLOWABLE_FEES - _fees[classId];
    //return the remainder amount
    return (amount * remainingFee) / TOTAL_ALLOWABLE_FEES;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
  bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

  struct Part {
    address payable account;
    uint96 value;
  }

  function hash(Part memory part) internal pure returns (bytes32) {
    return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an MultiClassFees compliant contract.
 */
interface IMultiClassFees {
  /**
   * @dev Returns the fee of a `recipient` in `classId`
   */
  function classFeeOf(uint256 classId, address recipient)
    external view returns(uint256);

  /**
   * @dev returns the total fees of `classId`
   */
  function classFees(uint256 classId)
    external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//interface of a OpenSea compliant contract
import "./interfaces/IERC721OpenSea.sol";

/**
 * @dev Abstract of an OpenSea compliant contract
 */
abstract contract ERC721OpenSea is IERC721OpenSea {
  string private _baseTokenURI;
  string private _contractURI;

  /**
   * @dev Constructor function
   */
  constructor (string memory baseTokenURI_, string memory contractURI_) {
    _contractURI = contractURI_;
    _baseTokenURI = baseTokenURI_;
  }

  /**
   * @dev The base URI for token data ex. https://creatures-api.opensea.io/api/creature/
   * Example Usage: 
   *  Strings.strConcat(baseTokenURI(), Strings.uint2str(tokenId))
   */
  function baseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @dev The URI for contract data ex. https://creatures-api.opensea.io/contract/opensea-creatures
   * Example Format:
   * {
   *   "name": "OpenSea Creatures",
   *   "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
   *   "image": "https://openseacreatures.io/image.png",
   *   "external_link": "https://openseacreatures.io",
   *   "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
   *   "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
   * }
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//interface of an ERC721 compliant contract
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev see: https://docs.opensea.io/docs/1-structuring-your-smart-contract
 *      see: https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/ERC721Tradable.sol#L70-L86
 */
interface IERC721OpenSea is IERC721 {
  /**
   * @dev The base URI for token data ex. https://creatures-api.opensea.io/api/creature/
   * Example Usage: 
   *  Strings.strConcat(baseTokenURI(), Strings.uint2str(tokenId))
   */
  function baseTokenURI() external view returns (string memory);

  /**
   * @dev The URI for contract data ex. https://creatures-api.opensea.io/contract/opensea-creatures/contract.json
   * Example Format:
   * {
   *   "name": "OpenSea Creatures",
   *   "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
   *   "image": "https://openseacreatures.io/image.png",
   *   "external_link": "https://openseacreatures.io",
   *   "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
   *   "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
   * }
   */
  function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//interface of a MultiClassOrderBook compliant contract
import "./../interfaces/IMultiClassOrderBook.sol";

/**
 * @dev Abstract that allows tokens to be listed in an order book
 */
abstract contract MultiClassOrderBook is IMultiClassOrderBook {
  // mapping of `tokenId` to amount
  // amount defaults to 0 and is in wei
  // apparently the data type for ether units is uint256 so we can interact
  // with it the same
  // see: https://docs.soliditylang.org/en/v0.7.1/units-and-global-variables.html
  mapping (uint256 => uint256) private _book;

  /**
   * @dev abstract; defined in ERC721; See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) 
    public view virtual returns (address);

  /**
   * @dev abstract; defined in Context; Returns the caller of 
   *      a contract method
   */
  function _msgSender() internal view virtual returns (address);

  /**
   * @dev Returns the amount a `tokenId` is being offered for.
   */
  function listingOf(uint256 tokenId) 
    public view virtual returns(uint256) 
  {
    return _book[tokenId];
  }

  /**
   * @dev Lists `tokenId` on the order book for `amount` in wei.
   */
  function _list(uint256 tokenId, uint256 amount) internal virtual {
    //error if the sender is not the owner
    // even the contract owner cannot list a token
    require(
      ownerOf(tokenId) == _msgSender(),
      "Only the token owner can list a token"
    );
    //disallow free listings because solidity defaults amounts to zero
    //so it's impractical to determine a free listing from an unlisted one
    require(
      amount > 0,
      "Listing amount should be more than 0"
    );
    //add the listing
    _book[tokenId] = amount;
    //emit that something was listed
    emit Listed(_msgSender(), tokenId, amount);
  }

  /**
   * @dev Removes `tokenId` from the order book.
   */
  function _delist(uint256 tokenId) internal virtual {
    address owner = ownerOf(tokenId);
    //error if the sender is not the owner
    // even the contract owner cannot delist a token
    require(
      owner == _msgSender(),
      "Only the token owner can delist a token"
    );
    //this is for the benefit of the sender so they
    //dont have to pay gas on things that dont matter
    require(
      _book[tokenId] != 0,
      "Token is not listed"
    );
    //remove the listing
    delete _book[tokenId];
    //emit that something was delisted
    emit Delisted(owner, tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an MultiClassOrderBook compliant contract.
 */
interface IMultiClassOrderBook {
  /**
   * @dev Emitted when `owner` books their `tokenId` to
   *      be sold for `amount` in wei.
   */
  event Listed(
    address indexed owner,
    uint256 indexed tokenId,
    uint256 indexed amount
  );

  /**
   * @dev Emitted when `owner` removes their `tokenId` from the 
   *      order book.
   */
  event Delisted(address indexed owner, uint256 indexed tokenId);

  /**
   * @dev Returns the amount a `tokenId` is being offered for.
   */
  function listingOf(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Implementation of a provably fair library
 */
library ProvablyFair {
  /**
   * @dev Pattern to manage the roll settings
   */
  struct RollState {
    uint256 max;
    uint256 min;
    uint256 nonce;
    bytes32 seed;
  }

  /**
   * @dev Helper to expose the hashed version of the server seed
   */
  function serverSeed(RollState memory state) 
    internal pure returns(bytes32) 
  {
    require(
      state.seed.length != 0, 
      "Missing server seed."
    );
    return keccak256(abi.encodePacked(state.seed));
  }

  /**
   * @dev rolls the dice and makes it relative to the range
   */
  function roll(
    RollState memory state, 
    string memory seed, 
    bool saveSeed
  ) internal view returns(uint256) {
    require(
      state.seed.length != 0, 
      "Missing server seed."
    );

    require(
      state.min < state.max, 
      "Minimum is greater than maximum."
    );

    //roll the dice
    uint256 results = uint256(
      keccak256(
        abi.encodePacked(
          state.seed, 
          msg.sender, 
          seed, 
          state.nonce
        )
      )
    ) + state.min;

    //increase nonce
    state.nonce += 1;

    if (!saveSeed) {
      //reset server seed
      state.seed = "";
    }

    //if there is a max
    if (state.max > 0) {
      //cap the results
      return results % state.max;  
    }

    return results;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//provably fair library used as the prize roller
import "./ProvablyFair.sol";

/**
 * @dev Random prize roller 
 */
library RandomPrize {
  /**
   * @dev Pattern to manage prize pool and roll to prize map
   */
  struct PrizePool {
    ProvablyFair.RollState state;
    uint256[] prizes;
    uint256[] rollToPrizeMap;
  }

  /**
   * @dev rolls the dice and assigns the prize
   */
  function roll(
    PrizePool memory pool, 
    string memory clientSeed, 
    bool saveSeed
  ) internal view returns(uint256) {
    // provably fair roller
    uint256 _roll = ProvablyFair.roll(pool.state, clientSeed, saveSeed);
    //this is the determined prize
    uint256 prize;
    for (uint8 i = 0; i < pool.rollToPrizeMap.length; i++) {
      // if the roll value is not zero 
      // and the roll is less than the roll value
      if (prize == 0 
        && pool.rollToPrizeMap[i] > 0 
        && _roll <= pool.rollToPrizeMap[i]
      ) {
        //set the respective prize
        prize = pool.prizes[i];
        //less the max in the state
        pool.state.max -= 1;
      }
      //if we have a prize, then we should just less the map range
      if (prize > 0 && pool.rollToPrizeMap[i] > 0) {
        pool.rollToPrizeMap[i] -= 1;
      }
    }
    return prize;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
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

//interface of a MultiClass compliant contract
import "./../interfaces/IMultiClass.sol";

/**
 * @dev Abstract implementation of a multi class token factory
 */
abstract contract MultiClass is IMultiClass {
  //mapping of token id to class
  mapping(uint256 => uint256) private _tokens;

  /**
   * @dev Returns the class given `tokenId`
   */
  function classOf(uint256 tokenId) 
    public view virtual returns(uint256) 
  {
    return _tokens[tokenId];
  }

  /**
   * @dev Maps `tokenId` to `classId`
   */
  function _classify(uint256 tokenId, uint256 classId) 
    internal virtual 
  {
    require(
      _tokens[tokenId] == 0,
      "Token is already classified"
    );
    _tokens[tokenId] = classId;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//interface of a MultiClassSupply compliant contract
import "./../interfaces/IMultiClassSupply.sol";

/**
 * @dev Abstract implementation of managing token supplies 
 *      in multi classes
 */
abstract contract MultiClassSupply is IMultiClassSupply {
  //index mapping of classId to current supply size
  mapping(uint256 => uint256) private _supply;
  //mapping of classId to total supply size
  mapping(uint256 => uint256) private _size;

  /**
   * @dev Returns true if `classId` supply and size are equal
   */
  function classFilled(uint256 classId) 
    public view virtual returns(bool) 
  {
    return _size[classId] != 0 && _supply[classId] == _size[classId];
  }

  /**
   * @dev Returns the total possible supply size of `classId`
   */
  function classSize(uint256 classId) 
    public view virtual returns(uint256) 
  {
    return _size[classId];
  }

  /**
   * @dev Returns the current supply size of `classId`
   */
  function classSupply(uint256 classId) 
    public view virtual returns(uint256) 
  {
    return _supply[classId];
  }

  /**
   * @dev Sets an immutable fixed `size` to `classId`
   */
  function _fixClassSize(uint256 classId, uint256 size) 
    internal virtual 
  {
    require (
      _size[classId] == 0,
      "Class is already sized."
    );
    _size[classId] = size;
  }

  /**
   * @dev Increases the supply of `classId` by `amount`
   */
  function _addClassSupply(uint256 classId, uint256 amount) 
    internal virtual 
  {
    uint256 size = _supply[classId] + amount;
    require(
      _size[classId] == 0 || size <= _size[classId],
      "Amount overflows class size."
    );
    _supply[classId] = size;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//interface of a MultiClassURIStorage compliant contract
import "./../interfaces/IMultiClassURIStorage.sol";

/**
 * @dev Abstract implementation of attaching URIs in token classes
 */
abstract contract MultiClassURIStorage is IMultiClassURIStorage {
  //mapping of `classId` to `data`
  mapping(uint256 => string) private _classURIs;

  /**
   * @dev Returns the reference of `classId`
   */
  function classURI(uint256 classId)
    public view virtual returns(string memory)
  {
    return _classURIs[classId];
  }

  /**
   * @dev References `data` to `classId`
   */
  function _setClassURI(uint256 classId, string memory data)
    internal virtual
  {
    require(
      bytes(_classURIs[classId]).length == 0,
      "Class is already referenced"
    );
    _classURIs[classId] = data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an MultiClass compliant contract.
 */
interface IMultiClass {
  /**
   * @dev Returns the class given `tokenId`
   */
  function classOf(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an MultiClassSupply compliant contract.
 */
interface IMultiClassSupply {
  /**
   * @dev Returns the total possible supply size of `classId`
   */
  function classSize(uint256 classId) external view returns(uint256);

  /**
   * @dev Returns true if `classId` supply and size are equal
   */
  function classFilled(uint256 classId) external view returns(bool);

  /**
   * @dev Returns the current supply size of `classId`
   */
  function classSupply(uint256 classId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an MultiClassURIStorage compliant contract.
 */
interface IMultiClassURIStorage {
  /**
   * @dev Returns the data of `classId`
   */
  function classURI(uint256 classId) 
    external view returns(string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//interface of an ERC721 compliant contract
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Required interface of an BEP721 compliant contract.
 */
interface IBEP721 is IERC721 {
  /**
   * @dev Specifies the name by which other contracts will recognize 
   *      the BEP-721 token 
   */
  function name() external view returns (string memory);

  /**
   * @dev A concise name for the token, comparable to a ticker symbol 
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Shows the overall amount of tokens generated
   */
  function totalSupply() external view returns (uint256);
}