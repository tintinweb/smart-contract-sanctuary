pragma solidity ^0.7.6;
import "./libraries/SafeMath.sol";

contract EvryTimelock {
  using SafeMath for uint;

  event NewAdmin(address indexed newAdmin);
  event NewPendingAdmin(address indexed newPendingAdmin);
  event NewDelay(uint indexed newDelay);
  event CancelTransaction(uint256 indexed txID, address indexed target, uint value, string signature, bytes data, uint eta);
  event ExecuteTransaction(uint256 indexed txID, address indexed target, uint value, string signature, bytes data, uint eta);
  event QueueTransaction(uint256 indexed txID, address indexed target, uint value, string signature, bytes data, uint eta);

  uint256 public minimumDelay;
  uint256 public maximumDelay;

  address public admin;
  address public pendingAdmin;

  struct TransactionData {
    address target;
    uint value;
    string signature;
    bytes data;
    uint eta;
  }
  mapping (uint256 => TransactionData) public pendingTransactions;
  bool[] transactionIndexs;

  constructor(address admin_, uint256 minimumDelay_, uint256 maximumDelay_) {
    require(minimumDelay_ <= maximumDelay_, "Timelock minimum delay must less than maximum delay");

    admin = admin_;
    minimumDelay = minimumDelay_;
    maximumDelay = maximumDelay_;
  }

  receive() external payable { }

  function pendingAdminConfirm() public {
    require(msg.sender == pendingAdmin, "Timelock pendingAdminConfirm must call from pendingAdmin");
    admin = msg.sender;
    pendingAdmin = address(0);

    emit NewAdmin(admin);
  }

  function setPendingAdmin(address pendingAdmin_) public {
    require(msg.sender == admin, "Timelock setPendingAdmin must come from admin");
    pendingAdmin = pendingAdmin_;

    emit NewPendingAdmin(pendingAdmin);
  }

  function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (uint256) {
    require(msg.sender == admin, "Timelock queue transaction must be call by admin");
    require(eta >= block.timestamp.add(minimumDelay), "Timelock queue transaction eta must be greater then minimum delay time");
    require(eta <= block.timestamp.add(maximumDelay), "Timelock queue transaction eta must be less then maximum delay time");

    TransactionData memory transactionData = TransactionData({
        target: target,
        value: value,
        signature: signature,
        data: data,
        eta: eta
    });
    uint256 id = transactionIndexs.length;
    transactionIndexs.push(true);
    pendingTransactions[id] = transactionData;

    emit QueueTransaction(id, target, value, signature, data, eta);
    return id;
  }

  function cancelTransaction(uint256 id) public {
    require(msg.sender == admin, "Timelock cancel transaction must come from admin");
    require(pendingTransactions[id].target != address(0), "Timelock cancel transaction ID is not valid");

    TransactionData memory transactionData = pendingTransactions[id];
    delete pendingTransactions[id];
    delete transactionIndexs[id];

    emit CancelTransaction(id, transactionData.target, transactionData.value, transactionData.signature, transactionData.data, transactionData.eta);
  }

  function executeTransaction( uint256 id ) public payable returns (bytes memory) {
    require(msg.sender == admin, "Timelock execute transaction must come from admin");
    require(pendingTransactions[id].target != address(0), "Timelock execute transaction ID is not valid");

    TransactionData memory transactionData = pendingTransactions[id];
    require(block.timestamp >= transactionData.eta, "Timelock execute transaction hasn't surpassed time lock");

    bytes memory callData = abi.encodePacked(bytes4(keccak256(bytes(transactionData.signature))), transactionData.data);
    (bool success, bytes memory returnData) = transactionData.target.call{value: transactionData.value}(callData);
    require(success, _getRevertMsg(returnData));

    delete pendingTransactions[id];
    delete transactionIndexs[id];

    emit ExecuteTransaction(id, transactionData.target, transactionData.value, transactionData.signature, transactionData.data, transactionData.eta);

    return returnData;
  }

  function getPendingTransactions() external view returns (uint256[] memory txIds) {
    uint256 pendingIndexLenght = 0;
    for (uint256 i = 0; i < transactionIndexs.length; i++) {
      if (transactionIndexs[i] == true){
        pendingIndexLenght++;
      }
    }

    txIds = new uint256[](pendingIndexLenght);
    uint256 txsIndex = 0;
    for (uint256 i = 0; i < transactionIndexs.length; i++) {
      if (transactionIndexs[i] == true){
        txIds[txsIndex] = i;
        txsIndex++;
      }
    }
  }

  function getBlockTimestamp() public view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

  function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) return "Transaction reverted silently";

    assembly {
        // Slice the sighash.
        _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string)); // All that remains is the revert string
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

