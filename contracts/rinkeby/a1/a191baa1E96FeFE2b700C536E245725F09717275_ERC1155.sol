// SPDX-License-Identifier: MIT

import './ERC1155Base.sol';

contract ERC1155 is ERC1155Base {
  function mint (
    address account,
    uint id,
    uint amount,
    bytes memory data
  ) external {
    _mint(account, id, amount, data);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// TODO: remove ERC165

import './IERC1155.sol';
import './IERC1155Receiver.sol';
import './ERC1155BaseStorage.sol';
import '../../introspection/ERC165.sol';
import '../../utils/AddressUtils.sol';

abstract contract ERC1155Base is IERC1155, ERC165 {
  using AddressUtils for address;

  function balanceOf (
    address account,
    uint id
  ) override public view returns (uint) {
    require(account != address(0), 'ERC1155: balance query for the zero address');
    return ERC1155BaseStorage.layout().balances[id][account];
  }

  function balanceOfBatch (
    address[] memory accounts,
    uint[] memory ids
  ) override public view returns (uint[] memory) {
    require(accounts.length == ids.length, 'ERC1155: accounts and ids length mismatch');

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    uint[] memory batchBalances = new uint[](accounts.length);

    for (uint i; i < accounts.length; i++) {
      require(accounts[i] != address(0), 'ERC1155: batch balance query for the zero address');
      batchBalances[i] = balances[ids[i]][accounts[i]];
    }

    return batchBalances;
  }

  function isApprovedForAll (
    address account,
    address operator
  ) override public view returns (bool) {
    return ERC1155BaseStorage.layout().operatorApprovals[account][operator];
  }

  function setApprovalForAll (
    address operator,
    bool status
  ) override public {
    require(msg.sender != operator, 'ERC1155: setting approval status for self');
    ERC1155BaseStorage.layout().operatorApprovals[msg.sender][operator] = status;
    emit ApprovalForAll(msg.sender, operator, status);
  }

  function safeTransferFrom (
    address from,
    address to,
    uint id,
    uint amount,
    bytes memory data
  ) override public {
    require(to != address(0), 'ERC1155: transfer to the zero address');
    require(from == msg.sender || isApprovedForAll(from, msg.sender), 'ERC1155: calleris not owner nor approved');

    _beforeTokenTransfer(msg.sender, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

    mapping (address => uint) storage balances = ERC1155BaseStorage.layout().balances[id];
    // TODO: error message
    // balances[from] = balances[from].sub(amount, 'ERC1155: insufficient balance for transfer');
    balances[from] -= amount;
    balances[to] += amount;

    emit TransferSingle(msg.sender, from, to, id, amount);

    _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
  }

  function safeBatchTransferFrom (
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) override public {
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');
    require(to != address(0), 'ERC1155: transfer to the zero address');
    require(from == msg.sender || isApprovedForAll(from, msg.sender), 'ERC1155: caller is not owner nor approved');

    _beforeTokenTransfer(msg.sender, from, to, ids, amounts, data);

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    for (uint i; i < ids.length; i++) {
      uint id = ids[i];
      uint amount = amounts[i];

      // TODO: error message
      // balances[id][from] = balances[id][from].sub(amount, 'ERC1155: insufficient balances for transfer');
      balances[id][from] -= amount;
      balances[id][to] += amount;
    }

    emit TransferBatch(msg.sender, from, to, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
  }

  function _mint (
    address account,
    uint id,
    uint amount,
    bytes memory data
  ) internal {
    require(account != address(0), 'ERC1155: mint to the zero address');

    _beforeTokenTransfer(msg.sender, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

    mapping (address => uint) storage balances = ERC1155BaseStorage.layout().balances[id];
    balances[account] += amount;

    emit TransferSingle(msg.sender, address(0), account, id, amount);

    _doSafeTransferAcceptanceCheck(msg.sender, address(0), account, id, amount, data);
  }

  function _mintBatch (
    address account,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) internal {
    require(account != address(0), 'ERC1155: mint to the zero address');
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    _beforeTokenTransfer(msg.sender, address(0), account, ids, amounts, data);

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    for (uint i; i < ids.length; i++) {
      uint id = ids[i];
      balances[id][account] += amounts[i];
    }

    emit TransferBatch(msg.sender, address(0), account, ids, amounts);

    _doSafeBatchTransferAcceptanceCheck(msg.sender, address(0), account, ids, amounts, data);
  }

  function _burn (
    address account,
    uint id,
    uint amount
  ) internal {
    require(account != address(0), 'ERC1155: burn from the zero address');

    _beforeTokenTransfer(msg.sender, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), '');

    mapping (address => uint) storage balances = ERC1155BaseStorage.layout().balances[id];
    require(balances[account] >= amount, 'ERC1155: burn amount exceeds balances');
    balances[account] -= amount;

    emit TransferSingle(msg.sender, account, address(0), id, amount);
  }

  function _burnBatch (
    address account,
    uint[] memory ids,
    uint[] memory amounts
  ) internal {
    require(account != address(0), 'ERC1155: burn from the zero address');
    require(ids.length == amounts.length, 'ERC1155: ids and amounts length mismatch');

    _beforeTokenTransfer(msg.sender, account, address(0), ids, amounts, '');

    mapping (uint => mapping (address => uint)) storage balances = ERC1155BaseStorage.layout().balances;

    for (uint i; i < ids.length; i++) {
      uint id = ids[i];
      require(balances[id][account] >= amounts[i], 'ERC1155: burn amount exceeds balance');
      balances[id][account] -= amounts[i];
    }

    emit TransferBatch(msg.sender, account, address(0), ids, amounts);
  }

  function _asSingletonArray (
    uint element
  ) private pure returns (uint[] memory) {
    uint[] memory array = new uint[](1);
    array[0] = element;
    return array;
  }

  function _doSafeTransferAcceptanceCheck (
    address operator,
    address from,
    address to,
    uint id,
    uint amount,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155Receiver(to).onERC1155Received.selector) {
          revert('ERC1155: ERC1155Receiver rejected tokens');
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert('ERC1155: transfer to non ERC1155Receiver implementer');
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck (
    address operator,
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) private {
    if (to.isContract()) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
        if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
          revert('ERC1155: ERC1155Receiver rejected tokens');
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert('ERC1155: transfer to non ERC1155Receiver implementer');
      }
    }
  }

  function _beforeTokenTransfer (
    address operator,
    address from,
    address to,
    uint[] memory ids,
    uint[] memory amounts,
    bytes memory data
  ) virtual internal {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../introspection/IERC165.sol';

interface IERC1155 is IERC165 {
  event TransferSingle (
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 id,
    uint256 value
  );

  event TransferBatch (
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );

  event ApprovalForAll (
    address indexed account,
    address indexed operator,
    bool approved
  );

  event URI (
    string value,
    uint256 indexed id
  );

  function balanceOf (
    address account,
    uint256 id
  ) external view returns (uint256);

  function balanceOfBatch (
    address[] calldata accounts,
    uint256[] calldata ids
  ) external view returns (uint256[] memory);

  function setApprovalForAll (
    address operator,
    bool approved
  ) external;

  function isApprovedForAll (
    address account,
    address operator
  ) external view returns (bool);

  function safeTransferFrom (
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data
  ) external;

  function safeBatchTransferFrom (
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../../introspection/IERC165.sol';

interface IERC1155Receiver is IERC165 {
  function onERC1155Received (
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns(bytes4);

  function onERC1155BatchReceived (
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC1155BaseStorage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC1155Base'
  );

  struct Layout {
    mapping (uint => mapping (address => uint)) balances;
    mapping (address => mapping (address => bool)) operatorApprovals;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IERC165.sol';
import './ERC165Storage.sol';

abstract contract ERC165 is IERC165 {
  using ERC165Storage for ERC165Storage.Layout;

  function supportsInterface (bytes4 interfaceId) override public view returns (bool) {
    return ERC165Storage.layout().isSupportedInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressUtils {
  function toString (address account) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(account)));
    bytes memory alphabet = '0123456789abcdef';
    bytes memory chars = new bytes(42);

    chars[0] = '0';
    chars[1] = 'x';

    for (uint256 i = 0; i < 20; i++) {
      chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
      chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
    }

    return string(chars);
  }

  function isContract (address account) internal view returns (bool) {
    // TODO: validate against extcodehash method used by OpenZeppelin
    uint size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }

  function sendValue (address payable account, uint amount) internal {
    (bool success, ) = account.call{ value: amount }('');
    require(success, 'AddressUtils: failed to send value');
  }

  function functionCall (address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'AddressUtils: failed low-level call');
  }

  function functionCall (address target, bytes memory data, string memory error) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, error);
  }

  function functionCallWithValue (address target, bytes memory data, uint value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'AddressUtils: failed low-level call with value');
  }

  function functionCallWithValue (address target, bytes memory data, uint value, string memory error) internal returns (bytes memory) {
    require(address(this).balance >= value, 'AddressUtils: insufficient balance for call');
    return _functionCallWithValue(target, data, value, error);
  }

  function _functionCallWithValue (address target, bytes memory data, uint value, string memory error) private returns (bytes memory) {
    require(isContract(target), 'AddressUtils: function call to non-contract');

    (bool success, bytes memory returnData) = target.call{ value: value }(data);

    if (success) {
      return returnData;
    } else if (returnData.length > 0) {
      assembly {
        let returnData_size := mload(returnData)
        revert(add(32, returnData), returnData_size)
      }
    } else {
      revert(error);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
  function supportsInterface (
    bytes4 interfaceId
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
  bytes32 internal constant STORAGE_SLOT = keccak256(
    'solidstate.contracts.storage.ERC165'
  );

  struct Layout {
    // TODO: use EnumerableSet to allow post-diamond-cut auditing
    mapping (bytes4 => bool) supportedInterfaces;
  }

  function layout () internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly { l.slot := slot }
  }

  function isSupportedInterface (
    Layout storage l,
    bytes4 interfaceId
  ) internal view returns (bool) {
    return l.supportedInterfaces[interfaceId];
  }

  function setSupportedInterface (
    Layout storage l,
    bytes4 interfaceId,
    bool status
  ) internal {
    require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
    l.supportedInterfaces[interfaceId] = status;
  }
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