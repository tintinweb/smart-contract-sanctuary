// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Mint.sol";

contract ERC1155Burnable is ERC1155Mint {
  constructor(
    string memory name,
    string memory symbol,
    string memory description
  ) ERC1155(name, symbol, description) {}

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) public virtual {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );

    _burn(account, id, value);
  }

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory values
  ) public virtual {
    require(
      account == _msgSender() || isApprovedForAll(account, _msgSender()),
      "ERC1155: caller is not owner nor approved"
    );

    _burnBatch(account, ids, values);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC1155Supply.sol";
import "../../libraries/Counters.sol";
import "../../libraries/Context.sol";

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  // constructor() internal {
  //   address msgSender = _msgSender();
  //   _owner = msgSender;
  //   emit OwnershipTransferred(address(0), msgSender);
  // }

  // function owner() public view returns (address) {
  //   return _owner;
  // }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  // function renounceOwnership() public virtual onlyOwner {
  //   emit OwnershipTransferred(_owner, address(0));
  //   _owner = address(0);
  // }

  // function transferOwnership(address newOwner) public virtual onlyOwner {
  //   require(newOwner != address(0), "Ownable: new owner is the zero address");
  //   emit OwnershipTransferred(_owner, newOwner);
  //   _owner = newOwner;
  // }
}

abstract contract ERC1155Mint is Ownable, ERC1155Supply {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  function mintToken(
    address owner,
    uint256 amount,
    string memory metadataURI
  ) public returns (uint256) {
    _tokenIds.increment();

    uint256 id = _tokenIds.current();
    _mint(owner, id, amount, "");
    _setTokenURI(id, metadataURI);

    return id;
  }

  function uri(uint256 _tokenId)
    public
    view
    override
    returns (string memory _uri)
  {
    return _tokenURI(_tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";

abstract contract ERC1155Supply is ERC1155 {
  mapping(uint256 => uint256) private _totalSupply;

  function totalSupply(uint256 id) public view virtual returns (uint256) {
    return _totalSupply[id];
  }

  function exists(uint256 id) public view virtual returns (bool) {
    return ERC1155Supply.totalSupply(id) > 0;
  }

  function _mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual override {
    super._mint(account, id, amount, data);
    _totalSupply[id] += amount;
  }

  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._mintBatch(to, ids, amounts, data);
    for (uint256 i = 0; i < ids.length; ++i) {
      _totalSupply[ids[i]] += amounts[i];
    }
  }

  function _burn(
    address account,
    uint256 id,
    uint256 amount
  ) internal virtual override {
    super._burn(account, id, amount);
    _totalSupply[id] -= amount;
  }

  function _burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual override {
    super._burnBatch(account, ids, amounts);
    for (uint256 i = 0; i < ids.length; ++i) {
      _totalSupply[ids[i]] -= amounts[i];
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Counters {
  struct Counter {
    uint256 _value;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

import "./interfaces/IERC1155.sol";
import "./interfaces/IERC1155Receiver.sol";
import "./interfaces/IERC1155MetadataURI.sol";
import "../../libraries/Address.sol";
import "../../libraries/Context.sol";
import "../ERC165/ERC165.sol";

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
  using Address for address;

  mapping(uint256 => mapping(address => uint256)) private _balances;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  mapping(uint256 => string) private _tokenURIs;

  string public name;
  string public symbol;
  string public description;

  string private _uri;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _description
  ) {
    _setURI("ipfs://");
    name = _name;
    symbol = _symbol;
    description = _description;
  }

  function _tokenURI(uint256 tokenId) internal view returns (string memory) {
    return _tokenURIs[tokenId];
  }

  function _setTokenURI(uint256 tokenId, string memory tokenUri)
    internal
    virtual
  {
    _tokenURIs[tokenId] = tokenUri;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC1155MetadataURI).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function uri(uint256) public view virtual override returns (string memory) {
    return _uri;
  }

  function balanceOf(address account, uint256 id)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(
      account != address(0),
      "ERC1155: balance query for the zero address"
    );
    return _balances[id][account];
  }

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    override
    returns (uint256[] memory)
  {
    require(
      accounts.length == ids.length,
      "ERC1155: accounts and ids length mismatch"
    );

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i = 0; i < accounts.length; ++i) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    require(
      _msgSender() != operator,
      "ERC1155: setting approval status for self"
    );

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address account, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[account][operator];
  }

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

  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(
      operator,
      from,
      to,
      _asSingletonArray(id),
      _asSingletonArray(amount),
      data
    );

    uint256 fromBalance = _balances[id][from];
    require(
      fromBalance >= amount,
      "ERC1155: insufficient balance for transfer"
    );
    unchecked {
      _balances[id][from] = fromBalance - amount;
    }
    _balances[id][to] += amount;

    emit TransferSingle(operator, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
  }

  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(
      ids.length == amounts.length,
      "ERC1155: ids and amounts length mismatch"
    );
    require(to != address(0), "ERC1155: transfer to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _balances[id][from];
      require(
        fromBalance >= amount,
        "ERC1155: insufficient balance for transfer"
      );
      unchecked {
        _balances[id][from] = fromBalance - amount;
      }
      _balances[id][to] += amount;
    }

    emit TransferBatch(operator, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
  }

  function _setURI(string memory newuri) internal virtual {
    _uri = newuri;
  }

  function _mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(account != address(0), "ERC1155: mint to the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(
      operator,
      address(0),
      account,
      _asSingletonArray(id),
      _asSingletonArray(amount),
      data
    );

    _balances[id][account] += amount;
    emit TransferSingle(operator, address(0), account, id, amount);

    _doSafeTransferAcceptanceCheck(
      operator,
      address(0),
      account,
      id,
      amount,
      data
    );
  }

  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(
      ids.length == amounts.length,
      "ERC1155: ids and amounts length mismatch"
    );

    address operator = _msgSender();

    _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      _balances[ids[i]][to] += amounts[i];
    }

    emit TransferBatch(operator, address(0), to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(
      operator,
      address(0),
      to,
      ids,
      amounts,
      data
    );
  }

  function _burn(
    address account,
    uint256 id,
    uint256 amount
  ) internal virtual {
    require(account != address(0), "ERC1155: burn from the zero address");

    address operator = _msgSender();

    _beforeTokenTransfer(
      operator,
      account,
      address(0),
      _asSingletonArray(id),
      _asSingletonArray(amount),
      ""
    );

    uint256 accountBalance = _balances[id][account];
    require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
      _balances[id][account] = accountBalance - amount;
    }

    emit TransferSingle(operator, account, address(0), id, amount);
  }

  function _burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(account != address(0), "ERC1155: burn from the zero address");
    require(
      ids.length == amounts.length,
      "ERC1155: ids and amounts length mismatch"
    );

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
      try
        IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data)
      returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
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
      try
        IERC1155Receiver(to).onERC1155BatchReceived(
          operator,
          from,
          ids,
          amounts,
          data
        )
      returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          revert("ERC1155: ERC1155Receiver rejected tokens");
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _asSingletonArray(uint256 element)
    private
    pure
    returns (uint256[] memory)
  {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../ERC165/interfaces/IERC165.sol";

interface IERC1155 is IERC165 {
  event TransferSingle(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  event ApprovalForAll(
    address indexed account,
    address indexed operator,
    bool approved
  );
  event URI(string value, uint256 indexed id);

  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);

  function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
    external
    view
    returns (uint256[] memory);

  function setApprovalForAll(address operator, bool approved) external;

  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

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

import "../../ERC165/interfaces/IERC165.sol";

interface IERC1155Receiver is IERC165 {
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

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

import "./IERC1155.sol";

interface IERC1155MetadataURI is IERC1155 {
  function uri(uint256 id) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    (bool success, bytes memory returndata) = target.staticcall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  function verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) internal pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC165.sol";

abstract contract ERC165 is IERC165 {
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return interfaceId == type(IERC165).interfaceId;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

