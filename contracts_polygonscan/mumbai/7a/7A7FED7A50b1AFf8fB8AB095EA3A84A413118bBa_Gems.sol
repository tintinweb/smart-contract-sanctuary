// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './String.sol';
import './GetMetadata.sol';

// confirm visibilities
// test native standard functions (batch transfer..)

contract Gems is ERC1155, Ownable {
  // Minting state
  uint256 public nextId = 1000;
  uint256 public currentAmount = 0;
  bool public saleIsActive = false;
  bool public isMintCapLocked = false;
  uint256 public mintCap = 10;
  uint256 public mintPrice = 1 ether;
  uint256 public limitPerTransaction = 5;

  // Crafting state
  bool public isCraftingLocked = false;
  bool public craftingIsActive = false;

  // Crafting rules
  bool public isRulesLocked = false;
  uint256 public createGemDustCost = 5;
  uint256 public salvageToDustRatio = 2;
  uint256 public changeColorDustCost = 3;
  uint256 public upgradeGemCost = 3;

  // Constants
  uint256 public constant LEVEL_MIN = 1;
  uint256 public constant LEVEL_MAX = 5;
  uint256 public constant DUST = 0;

  struct Gem {
    uint256 color;
    uint256 level;
  }

  mapping(uint256 => Gem) private _gemDetails;

  constructor(string memory _uri) ERC1155(_uri) {
  }

  function mintMany(uint256 amount) public payable {
    require(saleIsActive, 'Sale is currently closed.');
    require(amount <= limitPerTransaction, 'Can not mint so many at a time.');

    uint256 totalPrice = (amount * mintPrice);
    require(msg.value == totalPrice, 'Paid amount incorrect.');

    safeMintMany(amount);
  }

  function safeMintMany(uint256 amount) internal {
    uint256 newAmount = currentAmount + amount;
    require(newAmount <= mintCap, 'Minting would go over remaining supply.');

    for (uint256 i = 0; i < amount; i++) {
      uint256 level = getRandomLevel(nextId);
      uint256 color = getRandomColor(nextId);
      mintGem(color, level);
    }

    currentAmount = newAmount;
  }

  function mintGem(uint256 color, uint256 level) public { // FIXME: not public!!!
    _gemDetails[nextId] = Gem(color, level);
    _mint(msg.sender, nextId, 1, '');
    nextId++;
  }

  function salvage(uint256 tokenId) public {
    require(craftingIsActive, 'Crafting disabled.');
    require(tokenId >= 1000, 'Wrong token type');

    uint256 multiplier = 1;

    if (_gemDetails[tokenId].color == 9) {
      multiplier = 8;
    }

    _burn(msg.sender, tokenId, 1);
    _mint(
      msg.sender,
      DUST,
      salvageToDustRatio * _gemDetails[tokenId].level * upgradeGemCost * multiplier,
      ''
    );
  }

  function createFromDust() public {
    require(craftingIsActive, 'Crafting disabled.');

    uint256 color = getRandomColor(nextId);
    _burn(msg.sender, DUST, createGemDustCost);
    mintGem(color, LEVEL_MIN);
  }

  function changeColor(uint256 tokenId) public {
    require(craftingIsActive, 'Crafting disabled.');
    require(_gemDetails[tokenId].color != 8, 'Cannot change the ultimate color.');

    uint256 newColor = _gemDetails[tokenId].color + 1;

    if (newColor > 7) {
      newColor = 1;
    }

    _burn(msg.sender, DUST, changeColorDustCost * _gemDetails[tokenId].level);
    _burn(msg.sender, tokenId, 1);
    mintGem(newColor, _gemDetails[tokenId].level);
  }

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getRandomLevel(uint256 tokenId) private pure returns (uint256) {
    uint256 randLevel = random(
      string(abi.encodePacked('LEVEL', String.toString(tokenId)))
    );
    uint256 level = (randLevel % 100) + 1;

    if (level > 95) {
      level = 5;
    } else if (level > 88) {
      level = 4;
    } else if (level > 77) {
      level = 3;
    } else if (level > 62) {
      level = 2;
    } else {
      level = 1;
    }

    return level;
  }

  function getRandomColor(uint256 tokenId) private pure returns (uint256) {
    uint256 randColor = random(
      string(abi.encodePacked('COLOR', String.toString(tokenId)))
    );
    uint256 color = (randColor % 7) + 1;
    return color;
  }

  function upgradeFromThree(
    uint256 firstTokenId,
    uint256 secondTokenId,
    uint256 thirdTokenId
  ) public {
    require(craftingIsActive, 'Crafting disabled.');

    require(
      _gemDetails[firstTokenId].level == _gemDetails[secondTokenId].level && _gemDetails[secondTokenId].level == _gemDetails[thirdTokenId].level,
      'Level mismatch'
    );

    require(
      _gemDetails[firstTokenId].color == _gemDetails[secondTokenId].color && _gemDetails[secondTokenId].color == _gemDetails[thirdTokenId].color,
      'Color mismatch'
    );

    uint256 nextLevel = _gemDetails[firstTokenId].level + 1;
    require(nextLevel <= LEVEL_MAX, 'Level already at maximum.');

    _burn(msg.sender, firstTokenId, 1);
    _burn(msg.sender, secondTokenId, 1);
    _burn(msg.sender, thirdTokenId, 1);
    mintGem(_gemDetails[firstTokenId].color, nextLevel);
  }

  function combineAllColors(
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) public {
    require(craftingIsActive, 'Crafting disabled.');

    uint256 refLevel = _gemDetails[_ids[0]].level;
    uint256 refColor = _gemDetails[_ids[0]].color;

    require(
      _gemDetails[_ids[1]].level == refLevel && _gemDetails[_ids[2]].level == refLevel && _gemDetails[_ids[3]].level == refLevel && _gemDetails[_ids[4]].level == refLevel && _gemDetails[_ids[5]].level == refLevel && _gemDetails[_ids[6]].level == refLevel,
      'Level mismatch'
    );

    require(
      _gemDetails[_ids[1]].color != refColor && _gemDetails[_ids[2]].color != refColor && _gemDetails[_ids[3]].color != refColor && _gemDetails[_ids[4]].color != refColor && _gemDetails[_ids[5]].color != refColor && _gemDetails[_ids[6]].color != refColor,
      'Colors must be different'
    );

    _burnBatch(msg.sender, _ids, _amounts);
    mintGem(8, refLevel);
  }

  function getGemDetails(uint256 tokenId) public view returns (Gem memory) {
    return _gemDetails[tokenId];
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function setRules(
    uint256 createCost,
    uint256 salvageCost,
    uint256 changeCost
  ) public onlyOwner {
    require(!isRulesLocked, 'Rules have been locked forever.');

    createGemDustCost = createCost;
    salvageToDustRatio = salvageCost;
    changeColorDustCost = changeCost;
  }

  function lockRules() public onlyOwner {
    if (!isRulesLocked) {
      isRulesLocked = true;
    }
  }

  function flipCraftingState() public onlyOwner {
    require(!isCraftingLocked, 'Crafting has been locked forever.');
    craftingIsActive = !craftingIsActive;
  }

  function lockCraftingState() public onlyOwner {
    if (!isCraftingLocked) {
      isCraftingLocked = true;
    }
  }

  function setMintCap(uint256 amount) public onlyOwner {
    require(!isMintCapLocked, 'Mint cap has been locked forever.');
    mintCap = amount;
  }

  function lockMintCap() public onlyOwner {
    if (!isMintCapLocked) {
      isMintCapLocked = true;
    }
  }

  function setMintPrice(uint256 amount) public onlyOwner {
    mintPrice = amount;
  }


  function setLimitPerTransaction(uint256 amount) public onlyOwner {
    limitPerTransaction = amount;
  }

  function reserveGems(uint256 amount) public onlyOwner {
    safeMintMany(amount);
  }

  function withdraw(address payable _to) public onlyOwner {
      (bool sent, ) = _to.call{value: address(this).balance}("");
     require(sent, "Failed to send Ether");
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    uint256 color = _gemDetails[tokenId].color;
    uint256 level = _gemDetails[tokenId].level;
    return GetMetadata.getMetadata(tokenId, color, level);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library String {
  function toString(uint256 value) internal pure returns (string memory) {

    if (value == 0) {
      return '0';
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './base64.sol';
import './String.sol';

library GetMetadata {
  function getMetadata(
    uint256 tokenId,
    uint256 color,
    uint256 level
  ) external pure returns (string memory) {
    string[5] memory parts;

    parts[
      0
    ] = '<svg width="512" height="512" viewBox="0 0 512 512" fill="none" xmlns="http://www.w3.org/2000/svg">';

    if (level == 1) {
      parts[
        1
      ] = '<path d="M174.32 0L0.690918 300.762H347.968L174.32 0Z" fill="';
      parts[
        3
      ] = '"/><path d="M174.32 0L0.690918 300.762H347.968L174.32 0Z" stroke="black"/><path d="M174.32 116.617L101.668 242.462H246.973L174.32 116.617Z" fill="url(#paint0_linear_0_1)" fill-opacity="0.3"/><path d="M174.32 116.617V0L347.968 300.762L246.972 242.463L210.646 179.549L174.32 116.617Z" fill="white" fill-opacity="0.5"/><path d="M0.690918 300.762L101.668 242.463H246.973L347.968 300.762H0.690918Z" fill="url(#paint1_linear_0_1)" fill-opacity="0.6"/><path d="M0.690918 300.762L174.32 0V116.617L101.668 242.463L0.690918 300.762Z" fill="url(#paint2_linear_0_1)" fill-opacity="0.4"/><defs><linearGradient id="paint0_linear_0_1" x1="174.32" y1="116.617" x2="174.32" y2="242.462" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_0_1" x1="174.329" y1="242.463" x2="174.329" y2="300.762" gradientUnits="userSpaceOnUse"><stop stop-opacity="0.75"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_0_1" x1="174.021" y1="-55.7183" x2="-9.28316" y2="-64.3372" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-color="#E2E2E2" stop-opacity="0"/></linearGradient></defs>';
    } else if (level == 2) {
      parts[
        1
      ] = '<path d="M385 192.713L192.705 0.411865L0.410549 192.713L192.705 385.013L385 192.713Z" fill="';
      parts[
        3
      ] = '"/><path d="M285.352 192.723L192.705 100.074L100.059 192.723L192.705 285.373L285.352 192.723Z" fill="url(#paint0_linear_0_1)" fill-opacity="0.3"/><path d="M192.714 100.07V0.426514L384.993 192.726H285.352L192.714 100.07Z" fill="white" fill-opacity="0.6"/><path d="M285.352 192.727H384.993L192.714 385.011V285.367L285.352 192.727Z" fill="url(#paint1_linear_0_1)" fill-opacity="0.4"/><path d="M192.714 285.367V385.011L0.42041 192.727H100.061L192.714 285.367Z" fill="url(#paint2_linear_0_1)" fill-opacity="0.6"/><path d="M100.061 192.726H0.420166L192.714 0.426147V100.07L100.061 192.726Z" fill="url(#paint3_linear_0_1)" fill-opacity="0.4"/><defs><linearGradient id="paint0_linear_0_1" x1="239.029" y1="146.399" x2="146.379" y2="239.045" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_0_1" x1="176" y1="349" x2="297" y2="193" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_0_1" x1="96.5674" y1="192.727" x2="96.5674" y2="385.011" gradientUnits="userSpaceOnUse"><stop stop-opacity="0.75"/><stop offset="1"/></linearGradient><linearGradient id="paint3_linear_0_1" x1="96.5671" y1="0.42615" x2="248.69" y2="72.1933" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    } else if (level == 3) {
      parts[
        1
      ] = '<path d="M186.581 0.4375L0.179688 135.875L71.3792 355.026H301.784L373 135.875L186.581 0.4375Z" fill="';
      parts[
        3
      ] = '"/><path d="M186.581 86.725L82.2209 162.538L122.081 285.228H251.082L290.942 162.538L186.581 86.725Z" fill="url(#paint0_linear_0_1)" fill-opacity="0.4"/><path d="M186.582 0.4375V86.725L290.942 162.538L373 135.875L186.582 0.4375Z" fill="white" fill-opacity="0.6"/><path d="M0.179688 135.875L82.2212 162.538L186.581 86.725V0.4375L0.179688 135.875Z" fill="url(#paint1_linear_0_1)" fill-opacity="0.4"/><path d="M373 135.875L290.942 162.538L251.082 285.228L301.784 355.026L373 135.875Z" fill="url(#paint2_linear_0_1)" fill-opacity="0.4"/><path d="M301.784 355.026L251.082 285.228H122.081L71.3794 355.026H301.784Z" fill="black" fill-opacity="0.45"/><path d="M71.3792 355.026L122.081 285.228L82.2212 162.538L0.179688 135.875L71.3792 355.026Z" fill="black" fill-opacity="0.3"/><defs><linearGradient id="paint0_linear_0_1" x1="186.581" y1="86.725" x2="186.581" y2="285.228" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_0_1" x1="93.3806" y1="0.437502" x2="232.668" y2="76.0026" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_0_1" x1="312.041" y1="135.875" x2="361.275" y2="254.088" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient></defs>';
    } else if (level == 4) {
      parts[
        1
      ] = '<path d="M295.669 108.671V325.994L147.834 434.665L0 325.994V108.671L147.834 0L295.669 108.671Z" fill="';
      parts[
        3
      ] = '"/><path d="M235.78 152.681V281.984L147.834 346.626L59.8887 281.984V152.681L147.834 88.0386L235.78 152.681Z" fill="url(#paint0_linear_0_1)" fill-opacity="0.4"/><path d="M147.834 88.0386V0L295.669 108.671L235.78 152.681L147.834 88.0386Z" fill="white" fill-opacity="0.6"/><path d="M235.78 281.984L295.669 325.994V108.671L235.78 152.681V281.984Z" fill="url(#paint1_linear_0_1)" fill-opacity="0.4"/><path d="M147.834 346.626L235.78 281.984L295.669 325.994L147.834 434.665V346.626Z" fill="url(#paint2_linear_0_1)" fill-opacity="0.4"/><path d="M59.8709 281.984L147.834 346.626V434.665L0 325.994L59.8709 281.984Z" fill="black" fill-opacity="0.4"/><path d="M59.8709 152.681V281.984L0 325.994V108.671L59.8709 152.681Z" fill="black" fill-opacity="0.3"/><path d="M147.834 0V88.0386L59.8709 152.681L0 108.671L147.834 0Z" fill="url(#paint3_linear_0_1)" fill-opacity="0.4"/><defs><linearGradient id="paint0_linear_0_1" x1="147.834" y1="88.0386" x2="147.834" y2="346.626" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_0_1" x1="255" y1="326" x2="155.328" y2="231.966" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_0_1" x1="221.752" y1="281.984" x2="243.626" y2="373.393" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint3_linear_0_1" x1="73.9171" y1="1.79973e-06" x2="192.213" y2="54.0385" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    } else if (level == 5) {
      parts[
        1
      ] = '<path d="M169.81 0L305.95 159.9L339.64 307.42L279.83 408.35L169.81 442.8L59.81 408.37L0 307.42L33.64 159.9L169.81 0Z" fill="';
      parts[
        3
      ] = '"/><g style="mix-blend-mode:multiply"><path fill-rule="evenodd" clip-rule="evenodd" d="M169.81 136.04L97.1797 221.31L79.2397 299.92L111.15 353.8L169.82 372.14L228.49 353.8L260.39 299.96L242.46 221.35L169.81 136.06V136.04Z" fill="url(#paint0_linear_0_1)"/></g><path d="M169.81 0V136.04L242.46 221.33L305.96 159.9L169.81 0Z" fill="white" fill-opacity="0.6"/><path d="M242.46 221.33L305.96 159.9L339.63 307.41L260.39 299.94L242.46 221.33Z" fill="url(#paint1_linear_0_1)" fill-opacity="0.4"/><path d="M228.49 353.78L260.39 299.94L339.63 307.41L279.83 408.35L228.49 353.78Z" fill="url(#paint2_linear_0_1)" fill-opacity="0.4"/><g style="mix-blend-mode:multiply"><path d="M169.82 372.15L169.81 442.77L279.83 408.35L228.49 353.78L169.82 372.15Z" fill="#9F9F9F"/></g><path d="M111.15 353.81L59.8101 408.35L169.81 442.77L169.82 372.15L111.15 353.81Z" fill="black" fill-opacity="0.5"/><g style="mix-blend-mode:multiply"><path d="M79.24 299.91L0 307.41L59.81 408.35L111.15 353.81L79.24 299.91Z" fill="#979797"/></g><path d="M33.68 159.9L0 307.41L79.24 299.91L97.18 221.31L33.68 159.9Z" fill="black" fill-opacity="0.3"/><path d="M169.81 0L33.6802 159.9L97.1802 221.31L169.81 136.04V0Z" fill="url(#paint3_linear_0_1)" fill-opacity="0.4"/><defs><linearGradient id="paint0_linear_0_1" x1="196" y1="94" x2="140" y2="372" gradientUnits="userSpaceOnUse"><stop stop-color="#838383"/><stop offset="1" stop-color="white"/></linearGradient><linearGradient id="paint1_linear_0_1" x1="291" y1="338" x2="276.51" y2="146.996" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint2_linear_0_1" x1="354" y1="262" x2="332.759" y2="433.012" gradientUnits="userSpaceOnUse"><stop/><stop offset="1" stop-opacity="0"/></linearGradient><linearGradient id="paint3_linear_0_1" x1="-9.00001" y1="141" x2="154.447" y2="47.2632" gradientUnits="userSpaceOnUse"><stop stop-opacity="0"/><stop offset="1"/></linearGradient></defs>';
    }

    if (color == 1) {
      parts[2] = '#00FF00';
    } else if (color == 2) {
      parts[2] = '#00A3FF';
    } else if (color == 3) {
      parts[2] = '#FF0000';
    } else if (color == 4) {
      parts[2] = '#FFFF00';
    } else if (color == 5) {
      parts[2] = '#D331D7';
    } else if (color == 6) {
      parts[2] = '#FF8A00';
    } else if (color == 7) {
      parts[2] = '#00F0FF';
    } else if (color == 8) {
      parts[2] = '#FFFFFF';
    } else {
      parts[2] = '';
    }

    if (tokenId == 0) {
      parts[
        1
      ] = '<path d="M232.974 78.9771L233.058 148.26L293.017 182.974L223.734 183.058L189.02 243.017L188.936 173.734L128.977 139.02L198.26 138.936L232.974 78.9771Z" fill="white"/><path d="M377.74 203.447L377.81 261.602L428.139 290.74L369.984 290.81L340.846 341.139L340.775 282.984L290.447 253.846L348.602 253.775L377.74 203.447Z" fill="white"/><path d="M216.592 304.758L216.648 351.281L256.911 374.592L210.387 374.648L187.076 414.911L187.02 368.387L146.758 345.077L193.281 345.02L216.592 304.758Z" fill="white"/>';
      parts[2] = '';
      parts[3] = '';
    }

    parts[4] = '</svg>';

    string memory output = string(
      abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
    );

    string memory name;
    string memory colorString;
    string memory description;
    string memory jsonString;

    if (tokenId == 0) {
      name = 'Gem dust';
      description = 'Used to craft gems.';

      jsonString = string(abi.encodePacked(
        '{"name": "',
        name,
        '", "description": "',
        description,
        '", "background_color" : "101922", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(output)),
        '"}'
      ));
    } else {
      name = string(abi.encodePacked('Gem #', String.toString(tokenId)));

      if (color == 8 && level == 5) {
        description = 'The rarest gem in existence.';
      } else if (color == 8) {
        description = 'A rare gem obtained only by the worthy.';
      } else {
        description = 'A beautiful gem.';
      }

      if (color == 1) {
        colorString = 'Green'; // Emerald
      } else if (color == 2) {
        colorString = 'Blue'; // Sapphire
      } else if (color == 3) {
        colorString = 'Red'; // Ruby
      } else if (color == 4) {
        colorString = 'Yellow'; // Topaz
      } else if (color == 5) {
        colorString = 'Purple'; // Amethyst
      } else if (color == 6) {
        colorString = 'Orange'; // Amber
      } else if (color == 7) {
        colorString = 'Teal'; // Aquamarine
      } else if (color == 8) {
        colorString = 'White'; // Diamond
      }

      jsonString = string(abi.encodePacked(
        '{"name": "',
        name,
        '", "attributes": [ { "trait_type": "Level",  "value": ',
        String.toString(level),
        ' }, { "trait_type": "Color",  "value": "',
        colorString,
        '" } ], "description": "',
        description,
        '", "background_color" : "101922", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(output)),
        '"}'
      ));
    }

    string memory json = Base64.encode(bytes(jsonString));
    output = string(abi.encodePacked('data:application/json;base64,', json));
    return output;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}