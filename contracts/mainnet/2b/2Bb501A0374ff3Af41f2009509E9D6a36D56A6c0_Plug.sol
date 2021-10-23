// SPDX-License-Identifier: MIT
/*
 * Plug.sol
 *
 * Author: Jack Kasbeer
 * Created: August 3, 2021
 *
 * Price: 0.0888 ETH
 * Rinkeby: 0xf9d798514eb5eA645C90D8633FcC3DA17da8288e
 *
 * Description: An ERC-721 token that will change based on (1) time held by a single owner and
 * 				(2) trades between owners; the different versions give you access to airdrops.
 *
 *  - As long as the owner remains the same, every 60 days, the asset will acquire more "juice" 
 * 	  not only updating the asset, but allowing the owner to receive more airdrops from other 
 *    artists.  This means after a year, the final asset (and most valuable) will now be in the 
 *    owner's wallet (naturally each time, the previous asset is replaced).
 *  - If the NFT changes owners, the initial/day 0 asset is now what will be seen by the owner,
 *    and they'll have to wait a full cycle "final asset status" (gold)
 *  - If a Plug is a Alchemist (final state), it means that it will never lose juice again,
 *    even if it is transferred.
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Kasbeer721.sol";

//@title The Plug
//@author Jack Kasbeer (gh:@jcksber, tw:@satoshigoat)
contract Plug is Kasbeer721 {

	using Counters for Counters.Counter;
	using SafeMath for uint256;

	//@dev Emitted when token is transferred
	event PlugTransferred(address indexed from, address indexed to);

	//@dev How we keep track of how many days a person has held a Plug
	mapping(uint256 => uint) internal _birthdays; //tokenID -> UTCTime

	constructor() Kasbeer721("the Plug", "PLUG") {
		whitelistActive = true;
		contractUri = "ipfs://QmYUDei8kuEHrPTyEMrWDQSLEtQwzDS16bpFwZab6RZN5j";
		payoutAddress = 0x6b8C6E15818C74895c31A1C91390b3d42B336799;//logik
		_squad[payoutAddress] = true;
		addToWhitelist(payoutAddress);
	}

	// -----------
	// RESTRICTORS
	// -----------

	modifier batchLimit(uint256 numToMint)
	{
		require(1 <= numToMint && numToMint <= 8, "Plug: mint between 1 and 8");
		_;
	}

	modifier plugsAvailable(uint256 numToMint)
	{
		require(_tokenIds.current() + numToMint <= MAX_NUM_TOKENS, 
			"Plug: not enough Plugs remaining to mint");
		_;
	}

	modifier tokenExists(uint256 tokenId)
	{
		require(_exists(tokenId), "Plug: nonexistent token");
		_;
	}

	// ----------
	// PLUG MAGIC
	// ----------

	//@dev Override 'tokenURI' to account for asset/hash cycling
	function tokenURI(uint256 tokenId) 
		tokenExists(tokenId) public view virtual override returns (string memory) 
	{	
		string memory baseURI = _baseURI();
		string memory hash = _tokenHash(tokenId);
		
		return string(abi.encodePacked(baseURI, hash));
	}

	//@dev Based on the number of days that have passed since the last transfer of
	// ownership, this function returns the appropriate IPFS hash
	function _tokenHash(uint256 tokenId) 
		internal virtual view 
		returns (string memory)
	{
		if (!_exists(tokenId)) {
			return "";//not a require statement to avoid errors being thrown
		}

		// Calculate days gone by for this particular token 
		uint daysPassed = countDaysPassed(tokenId);

		// Based on the number of days that have gone by, return the appropriate state of the Plug
		if (daysPassed >= 557) {
			if (tokenId <= 176) {
				return chiHashes[7];
			} else if (tokenId % 88 == 0) {
				return stlHashes[7];
			} else {
				return normHashes[7];
			}
		} else if (daysPassed >= 360) {
			if (tokenId <= 176) {
				return chiHashes[6];
			} else if (tokenId % 88 == 0) {
				return stlHashes[6];
			} else {
				return normHashes[6];
			}
		} else if (daysPassed >= 300) {
			if (tokenId <= 176) {
				return chiHashes[5];
			} else if (tokenId % 88 == 0) {
				return stlHashes[5];
			} else {
				return normHashes[5];
			}
		} else if (daysPassed >= 240) {
			if (tokenId <= 176) {
				return chiHashes[4];
			} else if (tokenId % 88 == 0) {
				return stlHashes[4];
			} else {
				return normHashes[4];
			}
		} else if (daysPassed >= 180) {
			if (tokenId <= 176) {
				return chiHashes[3];
			} else if (tokenId % 88 == 0) {
				return stlHashes[3];
			} else {
				return normHashes[3];
			}
		} else if (daysPassed >= 120) {
			if (tokenId <= 176) {
				return chiHashes[2];
			} else if (tokenId % 88 == 0) {
				return stlHashes[2];
			} else {
				return normHashes[2];
			}
		} else if (daysPassed >= 60) {
			if (tokenId <= 176) {
				return chiHashes[1];
			} else if (tokenId % 88 == 0) {
				return stlHashes[1];
			} else {
				return normHashes[1];
			}
		} else { //if 60 days haven't passed, the initial asset/Plug is returned
			if (tokenId <= 176) {
				return chiHashes[0];
			} else if (tokenId % 88 == 0) {
				return stlHashes[0];
			} else {
				return normHashes[0];
			}
		}
	}

	//@dev Any Plug transfer this will be called beforehand (updating the transfer time)
	// If a Plug is now an Alchemist, it's timestamp won't be updated so that it never loses juice
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
		internal virtual override
    {
    	// If the "1.5 years" have passed, don't change birthday
    	if (_exists(tokenId) && countDaysPassed(tokenId) < 557) {
    		_setBirthday(tokenId);
    	}
    	emit PlugTransferred(from, to);
    }

    //@dev Set the last transfer time for a tokenId
	function _setBirthday(uint256 tokenId) 
		private
	{
		_birthdays[tokenId] = block.timestamp;
	}

	//@dev List the owners for a certain level (determined by _assetHash)
	// We'll need this for airdrops and benefits
	function listPlugOwnersForHash(string memory assetHash) 
		public view returns (address[] memory)
	{
		require(_hashExists(assetHash), "Plug: nonexistent hash");

		address[] memory levelOwners = new address[](MAX_NUM_TOKENS);

		uint16 tokenId;
		uint16 counter;
		for (tokenId = 1; tokenId <= _tokenIds.current(); tokenId++) {
			if (_stringsEqual(_tokenHash(tokenId), assetHash)) {
				levelOwners[counter] = ownerOf(tokenId);
				counter++;
			}
		}
		return levelOwners;
	}

	//@dev List the owners of a category of the Plug (Nomad, Chicago, or St. Louis)
	function listPlugOwnersForType(uint8 group)
		groupInRange(group) public view returns (address[] memory)
	{
		address[] memory typeOwners = new address[](MAX_NUM_TOKENS);

		uint16 tokenId;
		uint16 counter;
		if (group == 0) {
			//nomad
			for (tokenId = 177; tokenId <= MAX_NUM_TOKENS; tokenId++) {
				if (tokenId % 88 != 0 && _exists(tokenId)) {
					typeOwners[counter] = ownerOf(tokenId);
					counter++;
				}
			}
		} else if (group == 1) {
			//chicago
			for (tokenId = 1; tokenId <= 176; tokenId++) {
				if (_exists(tokenId)) {
					typeOwners[counter] = ownerOf(tokenId);
					counter++;
				}
			}
		} else {
			//st. louis
			for (tokenId = 177; tokenId <= MAX_NUM_TOKENS; tokenId++) {
				if (tokenId % 88 == 0 && _exists(tokenId)) {
					typeOwners[counter] = ownerOf(tokenId);
					counter++;
				}
			}
		}
		return typeOwners;
	}

    // --------------------
    // MINTING & PURCHASING
    // --------------------

    //@dev Allows owners to mint for free
    function mint(address to) 
    	isSquad public virtual override returns (uint256)
    {
    	return _mintInternal(to);
    }

	//@dev Purchase & mint multiple Plugs
    function purchase(
    	address payable to, 
    	uint256 numToMint
    ) whitelistDisabled batchLimit(numToMint) plugsAvailable(numToMint) 
      public payable 
      returns (bool)
    {
    	require(msg.value >= numToMint * TOKEN_WEI_PRICE, "Plug: not enough ether");
    	//send change if too much was sent
        if (msg.value > 0) {
	    	uint256 diff = msg.value.sub(TOKEN_WEI_PRICE * numToMint);
    		if (diff > 0) {
    	    	to.transfer(diff);
    		}
      	}
    	uint8 i;//mint `numToMint` Plugs to address `to`
    	for (i = 0; i < numToMint; i++) {
    		_mintInternal(to);
    	}
    	return true;
    }

    //@dev A whitelist controlled version of `purchaseMultiple`
    function whitelistPurchase(
    	address payable to, 
    	uint256 numToMint
    ) whitelistEnabled onlyWhitelist(to) batchLimit(numToMint) plugsAvailable(numToMint)
      public payable 
      returns (bool)
    {
    	require(msg.value >= numToMint * TOKEN_WEI_PRICE, "Plug: not enough ether");
    	//send change if too much was sent
        if (msg.value > 0) {
	    	uint256 diff = msg.value.sub(TOKEN_WEI_PRICE * numToMint);
    		if (diff > 0) {
    	    	to.transfer(diff);
    		}
      	}
    	uint8 i;//mint `_num` Plugs to address `_to`
    	for (i = 0; i < numToMint; i++) {
    		_mintInternal(to);
    	}
    	return true;
    }

	//@dev Mints a single Plug & sets up the initial birthday 
	function _mintInternal(address to) 
		plugsAvailable(1) internal virtual returns (uint256)
	{
		_tokenIds.increment();
		uint256 newId = _tokenIds.current();
		_safeMint(to, newId);
		_setBirthday(newId);
		emit ERC721Minted(newId);

		return newId;
	}
	
	// ----
	// TIME
	// ----

	//@dev Returns number of days that have passed since transfer/mint
	function countDaysPassed(uint256 tokenId) 
		tokenExists(tokenId) public view returns (uint256) 
	{
		return uint256((block.timestamp - _birthdays[tokenId]) / 1 days);
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
/*
 * Kasbeer721.sol
 *
 * Author: Jack Kasbeer
 * Created: August 21, 2021
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./KasbeerStorage.sol";
import "./KasbeerAccessControl.sol";
import "./LibPart.sol";


//@title Kasbeer Made Contract for an ERC721
//@author Jack Kasbeer (git:@jcksber, tw:@satoshigoat)
contract Kasbeer721 is ERC721, KasbeerAccessControl, KasbeerStorage {

	using Counters for Counters.Counter;
	using SafeMath for uint256;

	event ERC721Minted(uint256 indexed tokenId);
	event ERC721Burned(uint256 indexed tokenId);
	
	constructor(string memory temp_name, string memory temp_symbol) 
		ERC721(temp_name, temp_symbol)
	{
		// Add my personal address & sender
		_squad[msg.sender] = true;
		_squad[0xB9699469c0b4dD7B1Dda11dA7678Fa4eFD51211b] = true;
		addToWhitelist(0xB9699469c0b4dD7B1Dda11dA7678Fa4eFD51211b);
	}

	// -----------
	// RESTRICTORS
	// -----------

	modifier hashIndexInRange(uint8 idx)
	{
		require(0 <= idx && idx < NUM_ASSETS, "Kasbeer721: index OOB");
		_;
	}
	
	modifier groupInRange(uint8 group)
	{
		require(0 <= group && group <= 2, "Kasbeer721: group OOB");
		_;// 0:nomad, 1:chicago, 2:st.louis
	}

	modifier onlyValidTokenId(uint256 tokenId)
	{
		require(1 <= tokenId && tokenId <= MAX_NUM_TOKENS, "KasbeerMade721: tokenId OOB");
		_;
	}

	// ------
	// ERC721 
	// ------

	//@dev All of the asset's will be pinned to IPFS
	function _baseURI() 
		internal view virtual override returns (string memory)
	{
		return "ipfs://";//NOTE: per OpenSea recommendations
	}

	//@dev This is here as a reminder to override for custom transfer functionality
	function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
		internal virtual override 
	{ 
		super._beforeTokenTransfer(from, to, tokenId); 
	}

	//@dev Allows owners to mint for free
    function mint(address to) 
    	isSquad public virtual returns (uint256)
    {
    	_tokenIds.increment();

		uint256 newId = _tokenIds.current();
		_safeMint(to, newId);
		emit ERC721Minted(newId);

		return newId;
    }

	//@dev Custom burn function - nothing special
	function burn(uint256 tokenId) 
		public virtual
	{
		require(isInSquad(msg.sender) || msg.sender == ownerOf(tokenId), 
			"Kasbeer721: not owner or in squad.");
		_burn(tokenId);
		emit ERC721Burned(tokenId);
	}

	function supportsInterface(bytes4 interfaceId) 
		public view virtual override returns (bool)
	{
		return interfaceId == _INTERFACE_ID_ERC165
        || interfaceId == _INTERFACE_ID_ROYALTIES
        || interfaceId == _INTERFACE_ID_ERC721
        || interfaceId == _INTERFACE_ID_ERC721_METADATA
        || interfaceId == _INTERFACE_ID_ERC721_ENUMERABLE
        || interfaceId == _INTERFACE_ID_EIP2981
        || super.supportsInterface(interfaceId);
	}

    // ----------------------
    // IPFS HASH MANIPULATION
    // ----------------------

    //@dev Get the hash stored at `idx` for `group` 
	function getHashByIndex(
		uint8 group, 
		uint8 idx
	) groupInRange(group) hashIndexInRange(idx) public view 
	  returns (string memory)
	{
		if (group == 0) {
			return normHashes[idx];
		} else if (group == 1) {
			return chiHashes[idx];
		} else {
			return stlHashes[idx];
		}
	}

	//@dev Allows us to update the IPFS hash values (one at a time)
	function updateHash(
		uint8 group, 
		uint8 hashNum, 
		string memory str
	) isSquad groupInRange(group) hashIndexInRange(hashNum) public
	{
		if (group == 0) {
			normHashes[hashNum] = str;
		} else if (group == 1) {
			chiHashes[hashNum] = str;
		} else {
			stlHashes[hashNum] = str;
		}
	}

	//@dev Determine if '_assetHash' is one of the IPFS hashes in asset hashes
	function _hashExists(string memory assetHash) 
		internal view returns (bool) 
	{
		uint8 i;
		for (i = 0; i < NUM_ASSETS; i++) {
			if (_stringsEqual(assetHash, normHashes[i]) || 
				_stringsEqual(assetHash, chiHashes[i]) ||
				_stringsEqual(assetHash, stlHashes[i])) {
				return true;
			}
		}
		return false;
	}

	// ------
	// USEFUL
	// ------

	//@dev Returns the current token id (number minted so far)
	function getCurrentId() 
		public view returns (uint256)
	{
		return _tokenIds.current();
	}

	//@dev Allows us to withdraw funds collected
	function withdraw(address payable wallet, uint256 amount)
		isSquad public
	{
		require(amount <= address(this).balance,
			"Kasbeer721: Insufficient funds to withdraw");
		wallet.transfer(amount);
	}

	//@dev Destroy contract and reclaim leftover funds
    function kill() 
    	onlyOwner public 
    {
        selfdestruct(payable(msg.sender));
    }

    // ------------
	// CONTRACT URI
	// ------------

	//@dev Controls the contract-level metadata to include things like royalties
	function contractURI()
		public view returns(string memory)
	{
		return contractUri;
	}

	//@dev Ability to change the contract URI
	function updateContractUri(string memory updatedContractUri) 
		isSquad public
	{
        contractUri = updatedContractUri;
    }
	
    // -----------------
    // SECONDARY MARKETS
	// -----------------

	//@dev Rarible Royalties V2
    function getRaribleV2Royalties(uint256 id) 
    	onlyValidTokenId(id) external view returns (LibPart.Part[] memory) 
    {
        LibPart.Part[] memory royalties = new LibPart.Part[](1);
        royalties[0] = LibPart.Part({
            account: payable(payoutAddress),
            value: uint96(royaltyFeeBps)
        });

        return royalties;
    }

    //@dev EIP-2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view onlyValidTokenId(tokenId) returns (address receiver, uint256 amount) {
        uint256 ourCut = SafeMath.div(SafeMath.mul(salePrice, royaltyFeeBps), 10000);
        return (payoutAddress, ourCut);
    }

    // -------
    // HELPERS
    // -------

	//@dev Determine if two strings are equal using the length + hash method
	function _stringsEqual(string memory a, string memory b) 
		internal pure returns (bool)
	{
		bytes memory A = bytes(a);
		bytes memory B = bytes(b);

		if (A.length != B.length) {
			return false;
		} else {
			return keccak256(A) == keccak256(B);
		}
	}
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
/*
 * KasbeerStorage.sol
 *
 * Author: Jack Kasbeer
 * Created: August 21, 2021
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";

//@title A storage contract for relevant data
//@author Jack Kasbeer (@jcksber, @satoshigoat)
contract KasbeerStorage {

	//@dev These take care of token id incrementing
	using Counters for Counters.Counter;
	Counters.Counter internal _tokenIds;

	uint256 constant public royaltyFeeBps = 1500; // 15%
    bytes4 internal constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 internal constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 internal constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 internal constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 internal constant _INTERFACE_ID_EIP2981 = 0x2a55205a;
    bytes4 internal constant _INTERFACE_ID_ROYALTIES = 0xcad96cca;

	//@dev Important numbers
	uint constant NUM_ASSETS = 8;
	uint constant MAX_NUM_TOKENS = 888;
	uint constant TOKEN_WEI_PRICE = 88800000000000000;//0.0888 ETH

	//@dev Properties
	string internal contractUri;
	address public payoutAddress;

	//@dev Initial production hashes
	//Our list of IPFS hashes for each of the "Nomad" 8 Plugs (varying juice levels)
	string [NUM_ASSETS] normHashes = ["QmZzB15bPgTqyHzULMFK1jNdbbDGVGCX4PJNbyGGMqLCjL",
									  "QmeXZGeywxRRDK5mSBHNVnUzGv7Kv2ATfLHydPfT5LpbZr",
									  "QmYTf2HE8XycQD9uXshiVtXqNedS83WycJvS2SpWAPfx5b",
									  "QmYXjEkeio2nbMqy3DA7z2LwYFDyq1itbzdujGSoCsFwpN",
									  "QmWmvRqpT59QU9rDT28fiKgK6g8vUjRD2TSSeeBPr9aBNm",
									  "QmWtMb73QgSgkL7mY8PQEt6tgufMovXWF8ecurp2RD7X6R",
									  "Qmbd4uEwtPBfw1XASkgPijqhZDL2nZcRwPbueYaETuAfGt",
									  "QmayAeQafrWUHV3xb8DnXTGLn97xnh7X2Z957Ss9AtfkAD"];
	//Our list of IPFS hashes for each of the "Chicago" 8 Plugs (varying juice levels)
	string [NUM_ASSETS] chiHashes = ["QmNsSUji2wX4E8xmv8vynmSUCACPdCh7NznVSGMQ3hwLC3",
									 "QmYPq4zFLyREaZsPwZzXB3w94JVYdgFHGgRAuM6CK6PMes",
									 "QmbrATHXTkiyNijkfQcEMGT7ujpunsoLNTaupMYW922jp3",
									 "QmWaj5VHcBXgAQnct88tbthVmv1ecX7ft2aGGqMAt4N52p",
									 "QmTyFgbJXX2vUCZSjraKubXfE4NVr4nVrKtg3GK4ysscDX",
									 "QmQxQoAe47CUXtGY9NTA6dRgTJuDtM4HDqz9kW2UK1VHtU",
									 "QmaXYexRBrbr6Uv89cGyWXWCbyaoQDhy3hHJuktSTWFXtJ",
									 "QmeSQdMYLECcSfCSkMenPYuNL2v42YQEEA4HJiP36Zn7Z6"];
	//Our list of IPFS hashes for each of the "Chicago" 8 Plugs (varying juice levels)
	string [NUM_ASSETS] stlHashes = ["QmcB5AqhpNA8o5RT3VTeDsqNBn6VGEaXzeTKuomakTNueM",
									 "QmcjP9d54RcmPXgGt6XxNavr7dtQDAhAnatKjJ5a1Bqbmc",
									 "QmV3uFvGgGQdN4Ub81LWVnp3qjwMpKDvVwQmBzBNzAjWxB",
									 "Qmc3fWuQTxAgsBYK2g4z5VrK47nvfCrWHFNa5zA8DDoUbs",
									 "QmWRPStH4RRMrFzAJcTs2znP7hbVctbLHPUvEn9vXWSTfk",
									 "QmVobnLvtSvgrWssFyWAPCUQFvKsonRMYMYRQPsPSaQHTK",
									 "QmQvGuuRgKxqTcAA7xhGdZ5u2EzDKvWGYb1dMXz2ECwyZi",
									 "QmdurJn1GYVz1DcNgqbMTqnCKKFxpjsFuhoS7bnfBp2YGk"];
}

// SPDX-License-Identifier: MIT
/*
 * KasbeerAccessControl.sol
 *
 * Author: Jack Kasbeer
 * Created: October 14, 2021
 *
 * This is an extension of `Ownable` to allow a larger set of addresses to have
 * certain control in the inheriting contracts.
 */

pragma solidity >=0.5.16 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract KasbeerAccessControl is Ownable {
	
	// -----
	// SQUAD
	// -----

	//@dev Ownership - list of squad members (owners)
	mapping (address => bool) internal _squad;

	//@dev Custom "approved" modifier because I don't like that language
	modifier isSquad()
	{
		require(isInSquad(msg.sender), "KasbeerAccessControl: Caller not part of squad.");
		_;
	}

	//@dev Determine if address `a` is an approved owner
	function isInSquad(address a) 
		public view returns (bool) 
	{
		return _squad[a];
	}

	//@dev Add `a` to the squad
	function addToSquad(address a)
		onlyOwner public
	{
		require(!isInSquad(a), "KasbeerAccessControl: Address already in squad.");
		_squad[a] = true;
	}

	//@dev Remove `a` from the squad
	function removeFromSquad(address a)
		onlyOwner public
	{
		require(isInSquad(a), "KasbeerAccessControl: Address already not in squad.");
		_squad[a] = false;
	}

	// ---------
	// WHITELIST
	// ---------

	//@dev Whitelist mapping for client addresses
	mapping (address => bool) internal _whitelist;

	//@dev Whitelist flag for active/inactive states
	bool whitelistActive;

	//@dev Determine if someone is in the whitelsit
	modifier onlyWhitelist(address a)
	{
		require(isInWhitelist(a));
		_;
	}

	//@dev Prevent non-whitelist minting functions from being used 
	// if `whitelistActive` == 1
	modifier whitelistDisabled()
	{
		require(whitelistActive == false, "KasbeerAccessControl: whitelist still active");
		_;
	}

	//@dev Require that the whitelist is currently enabled
	modifier whitelistEnabled() 
	{
		require(whitelistActive == true, "KasbeerAccessControl: whitelist not active");
		_;
	}

	//@dev Turn the whitelist on
	function activateWhitelist()
		isSquad whitelistDisabled public
	{
		whitelistActive = true;
	}

	//@dev Turn the whitelist off
	function deactivateWhitelist()
		isSquad whitelistEnabled public
	{
		whitelistActive = false;
	}

	//@dev Prove that one of our whitelist address owners has been approved
	function isInWhitelist(address a) 
		public view returns (bool)
	{
		return _whitelist[a];
	}

	//@dev Add a single address to whitelist
	function addToWhitelist(address a) 
		isSquad public
	{
		require(!isInWhitelist(a), "KasbeerAccessControl: already whitelisted"); 
		//here we care if address already whitelisted to save on gas fees
		_whitelist[a] = true;
	}

	//@dev Remove a single address from the whitelist
	function removeFromWhitelist(address a)
		isSquad public
	{
		require(isInWhitelist(a), "KasbeerAccessControl: not in whitelist");
		_whitelist[a] = false;
	}

	//@dev Add a list of addresses to the whitelist
	function bulkAddToWhitelist(address[] memory addys) 
		isSquad public
	{
		require(addys.length > 1, "KasbeerAccessControl: use `addToWhitelist` instead");
		uint8 i;
		for (i = 0; i < addys.length; i++) {
			if (!_whitelist[addys[i]]) {
				_whitelist[addys[i]] = true;
			}
		}
	}
}

// SPDX-License-Identifier: MIT
/*
 * LibPart.sol
 *
 * Author: Jack Kasbeer (token from 'dot')
 * Created: October 20, 2021
 */

pragma solidity >=0.5.16 <0.9.0;

//@dev We need this libary for Rarible
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