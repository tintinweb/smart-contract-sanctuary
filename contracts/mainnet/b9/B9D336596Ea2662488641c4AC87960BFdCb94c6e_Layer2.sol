// https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/utils/Address.sol
pragma solidity ^0.5.12;

/**
 * Utility library of inline functions on addresses
 */
library Address {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

pragma solidity ^0.5.12;


library BMT {
  // TODO: remove recursive call
  function getRoot(bytes32[] memory level)
    internal
    view
    returns (bytes32)
  {
    if (level.length == 1) return level[0];

    bytes32[] memory nextLevel = new bytes32[]((level.length + 1) / 2);
    uint i;

    for (; i + 1 < level.length; i += 2) {
      nextLevel[i/2] = keccak256(abi.encodePacked(level[i], level[i+1]));
    }

    if (level.length % 2 == 1) {
      nextLevel[i/2] = keccak256(
        abi.encodePacked(level[level.length - 1], level[level.length - 1])
      );
    }

    return getRoot(nextLevel);
  }

  function checkMembership(
    bytes32 leaf,
    uint256 index,
    bytes32 rootHash,
    bytes memory proof
  )
    internal
    pure
    returns (bool)
  {
    require(proof.length % 32 == 0);

    uint256 numElements = proof.length / 32;
    require(numElements < 16);

    bytes32 proofElement;
    bytes32 computedHash = leaf;

    for (uint256 i = 32; i <= 32 * numElements; i += 32) {
      assembly {
        proofElement := mload(add(proof, i))
      }
      if (index % 2 == 0) {
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
      index = index / 2;
    }
    return computedHash == rootHash;
  }
}

pragma solidity ^0.5.12;


import "SafeMath.sol";
import "Math.sol";
import "RLP.sol";
import "RLPEncode.sol";
import "BMT.sol";

// import "PatriciaTree.sol"; // use binary merkle tree
import {RequestableI} from "RequestableI.sol";


library Data {
  using SafeMath for uint;
  using SafeMath for uint64;
  using Math for *;
  using RLP for *;
  using RLPEncode for *;
  using BMT for *;

  // solium-disable max-len
  bytes4 public constant APPLY_IN_CHILDCHAIN_SIGNATURE = bytes4(keccak256("applyRequestInChildChain(bool,uint256,address,bytes32,bytes)"));
  bytes4 public constant APPLY_IN_ROOTCHAIN_SIGNATURE = bytes4(keccak256("applyRequestInRootChain(bool,uint256,address,bytes32,bytes)"));
  // solium-enable max-len

  address public constant NA = address(0);
  uint public constant NA_TX_GAS_PRICE = 1e9;
  uint public constant NA_TX_GAS_LIMIT = 100000;

  // How many requests can be included in a single request block
  function MAX_REQUESTS() internal pure returns (uint) {
    // TODO: use 100 in production mode
    // return 1000;
    return 20;
  }

  // Timeout for URB submission
  function URE_TIMEOUT() internal pure returns (uint) {
    return 1 hours;
  }

  function decodePos(uint _pos) internal pure returns (uint v1, uint v2) {
    assembly {
      v1 := div(_pos, exp(2, 128))
      v2 := and(_pos, sub(exp(2, 128), 1))
    }
  }

  /**
   * highestFinalizedBlock
   * firstEpochNumber
   * blockToRenew               0 means no renew required
   * forkedBlock                forked block number due to URB submission
   *                            last finalized block is forkedBlockNumber - 1
   * urbEpochNumber
   * lastEpoch
   * lastBlock
   * lastFinalizedBlock
   * timestamp
   * firstEnterEpoch            epoch number of first enter request epoch
   * lastEnterEpoch             epoch number of last enter request epoch
   * nextBlockToRebase
   * rebased                    true if all blocks are rebased
   * epochs                     epochs in this fork
   * blocks                     blocks in this fork
   */
  struct Fork {
    // uint64 blockToRenew;
    uint64 forkedBlock; // TODO: change to forkedEpoch
    uint64 firstEpoch;
    uint64 lastEpoch;
    uint64 firstBlock;
    uint64 lastBlock;
    uint64 lastFinalizedEpoch;
    uint64 lastFinalizedBlock;
    uint64 timestamp;
    uint64 firstEnterEpoch;
    uint64 lastEnterEpoch;
    uint64 nextBlockToRebase;
    bool rebased;
    mapping (uint => Epoch) epochs;
    mapping (uint => PlasmaBlock) blocks;
  }

  function getForkedEpoch(Fork storage self) internal view returns (uint64) {
    require(self.forkedBlock != 0);
    return self.blocks[self.forkedBlock].epochNumber;
  }

  /**
   * @notice Insert a block (ORB / NRB) into the fork.
   */
  function insertBlock(
    Fork storage _f,
    bytes32 _statesRoot,
    bytes32 _transactionsRoot,
    bytes32 _receiptsRoot,
    bool _isRequest,
    bool _userActivated,
    bool _rebase
  )
    internal
    returns (uint epochNumber, uint blockNumber)
  {
    epochNumber = _f.lastEpoch;
    blockNumber = _f.lastBlock.add(1);

    Data.Epoch storage epoch = _f.epochs[epochNumber];

    if (blockNumber == epoch.endBlockNumber + 1) {
      epochNumber += 1;
      _f.lastEpoch = uint64(epochNumber);
      epoch = _f.epochs[epochNumber];
    }

    require(epoch.startBlockNumber <= blockNumber);
    require(_rebase || epoch.endBlockNumber >= blockNumber);

    require(epoch.isRequest == _isRequest);
    require(epoch.userActivated == _userActivated);

    Data.PlasmaBlock storage b = _f.blocks[blockNumber];

    b.epochNumber = uint64(epochNumber);
    b.statesRoot = _statesRoot;
    b.transactionsRoot = _transactionsRoot;
    b.receiptsRoot = _receiptsRoot;
    b.timestamp = uint64(block.timestamp);
    b.isRequest = _isRequest;
    b.userActivated = _userActivated;

    if (_isRequest) {
      b.requestBlockId = uint64(epoch.RE.firstRequestBlockId + blockNumber - epoch.startBlockNumber);
    }

    _f.lastBlock = uint64(blockNumber);
    return (epochNumber, blockNumber);
  }


  /**
   * TODO: implement insert rebased non-request epoch
   * @notice Insert non-request epoch into the fork.
   */
  function insertNRE(
    Fork storage _f,
    uint _epochNumber,
    bytes32 _epochStateRoot,
    bytes32 _epochTransactionsRoot,
    bytes32 _epochReceiptsRoot,
    uint _startBlockNumber,
    uint _endBlockNumber
  )
    internal
  {
    require(_f.lastEpoch.add(1) == _epochNumber);
    require(_f.lastBlock.add(1) == _startBlockNumber);

    Data.Epoch storage epoch = _f.epochs[_epochNumber];

    require(!epoch.isRequest);
    require(!epoch.userActivated);
    require(!epoch.rebase);

    require(epoch.startBlockNumber == _startBlockNumber);
    require(epoch.endBlockNumber == _endBlockNumber);

    epoch.NRE.epochStateRoot = _epochStateRoot;
    epoch.NRE.epochTransactionsRoot = _epochTransactionsRoot;
    epoch.NRE.epochReceiptsRoot = _epochReceiptsRoot;
    epoch.NRE.submittedAt = uint64(block.timestamp);

    _f.lastEpoch = uint64(_epochNumber);
    _f.lastBlock = uint64(_endBlockNumber);
  }

  function getLastEpochNumber(Fork storage _f, bool _isRequest) internal returns (uint) {
    if (_f.epochs[_f.lastEpoch].isRequest == _isRequest) {
      return _f.lastEpoch;
    }

    return _f.lastEpoch - 1;
  }

  // function getFirstNotFinalizedEpochNumber(Fork storage _f, bool _isRequest) internal returns (uint) {
  //   if (_f.epochs[_f.lastEpoch].isRequest == _isRequest) {
  //     return _f.lastEpoch;
  //   }

  //   return _f.lastEpoch - 1;
  // }

  /**
   * @notice Update nextBlockToRebase to next request block containing enter request.
   *         If all ORBs are rebased, return true.
   */
  function checkNextORBToRebase(
    Fork storage _cur,
    Fork storage _pre,
    RequestBlock[] storage _rbs
  ) internal returns (bool finished) {
    uint blockNumber = _cur.nextBlockToRebase;
    uint epochNumber = _pre.blocks[_cur.nextBlockToRebase].epochNumber;
    // uint lastEpochNumber = getLastEpochNumber(_pre, true);

    while (_pre.epochs[epochNumber].initialized) {
      // at the end of epoch
      if (_pre.epochs[epochNumber].endBlockNumber <= blockNumber) {
        epochNumber += 2;
        blockNumber = _pre.epochs[epochNumber].startBlockNumber;
      }

      // skip until epoch has enter request
      while (_pre.epochs[epochNumber].RE.numEnter == 0 && _pre.epochs[epochNumber].initialized) {
        epochNumber += 2;
        blockNumber = _pre.epochs[epochNumber].startBlockNumber;
      }

      // short circuit if all OREs are empty or has no enter
      if (!_pre.epochs[epochNumber].initialized) {
        return true;
      }

      // skip blocks without enter request
      uint endBlockNumber = _pre.epochs[epochNumber].endBlockNumber;
      while (blockNumber <= endBlockNumber) {
        if (_rbs[_pre.blocks[blockNumber].requestBlockId].numEnter > 0) {
          break;
        }
        blockNumber += 1;
      }

      // continue if there is no block containing enter request
      if (blockNumber > endBlockNumber) {
        epochNumber += 2;
        blockNumber = _pre.epochs[epochNumber].startBlockNumber;
        continue;
      }

      // target block number is found
      _cur.nextBlockToRebase = uint64(blockNumber);
      return false;
    }

    // ready to prepare NRE
    return true;
  }

  /**
   * @notice Update nextBlockToRebase to next non request block
   *         If all NRBs are rebased, return true.
   * TODO    What if no ORE' ?
   */
  function checkNextNRBToRebase(
    Fork storage _cur,
    Fork storage _pre
  ) internal returns (bool finished) {
    uint blockNumber = _cur.nextBlockToRebase;
    uint epochNumber = _pre.blocks[blockNumber].epochNumber;

    // at the end of epoch
    if (_pre.epochs[epochNumber].endBlockNumber <= blockNumber) {
      epochNumber += 2;
      blockNumber = _pre.epochs[epochNumber].startBlockNumber;
    } else {
      blockNumber += 1;
    }

    // short circit if all NRE's are rebased
    if (!_pre.epochs[epochNumber].initialized) {
      _cur.nextBlockToRebase = 0;
      return true;
    }

    // short circuit if block is not submitted
    if (_pre.blocks[blockNumber].timestamp == 0) {
      _cur.nextBlockToRebase = 0;
      return true;
    }

    _cur.nextBlockToRebase = uint64(blockNumber);
    return false;
  }

  /**
   *
   * startBlockNumber       first block number of the epoch.
   * endBlockNumber         last block number of the epoch. 0 if the epoch is ORE' / NRE' until ORE' is filled.
   * timestamp              timestamp when the epoch is initialized.
   *                        required for URB / ORB
   * epochStateRoot         merkle root of [block.stateRoot] for block in the epoch.
   * epochTransactionsRoot  merkle root of [block.transactionsRoot] for block in the epoch.
   * epochReceiptsRoot      merkle root of [block.receiptsRoot] for block in the epoch.
   * isEmpty                true if request epoch has no request block
   *                        also and requestStart == requestEnd == previousEpoch.RE.requestEnd
   *                        and startBlockNumber == endBlockNumber == previousEpoch.endBlockNumber
   *                        and firstRequestBlockId == previousEpoch.firstRequestBlockId
   * initialized            true if epoch is initialized
   * isRequest              true in case of URB / ORB
   * userActivated          true in case of URB
   * rebase                 true in case of ORE' or NRE'
   */
  struct Epoch {
    uint64 startBlockNumber;
    uint64 endBlockNumber;
    uint64 timestamp;
    bool isEmpty;
    bool initialized;
    bool isRequest;
    bool userActivated;
    bool rebase;
    RequestEpochMeta RE;
    NonRequestEpochMeta NRE;
  }

  struct NonRequestEpochMeta {
    bytes32 epochStateRoot;
    bytes32 epochTransactionsRoot;
    bytes32 epochReceiptsRoot;
    uint64 submittedAt;
    uint64 finalizedAt;
    bool finalized;
    bool challenging;
    bool challenged;
  }

  /**
   * requestStart           first request id.
   * requestEnd             last request id.
   * firstRequestBlockId    first id of RequestBlock[]
   *                        if epochs is ORE', copy from last request epoch in previous fork
   * numEnter               number of enter request
   * nextEnterEpoch         next request epoch including enter request
   * nextEpoch              next non-empty request epoch
   */
  struct RequestEpochMeta {
    uint64 requestStart;
    uint64 requestEnd;
    uint64 firstRequestBlockId;
    uint64 numEnter;
    uint64 nextEnterEpoch;
    uint64 nextEpoch;
  }

  // function noExit(Epoch storage self) internal returns (bool) {
  //   if (self.rebase) return true;
  //   return self.RE.requestEnd.sub64(self.RE.requestStart).add64(1) == self.RE.firstRequestBlockId;
  // }

  function getNumBlocks(Epoch storage _e) internal view returns (uint) {
    if (_e.isEmpty || _e.rebase && _e.endBlockNumber == 0) return 0;
    return _e.endBlockNumber + 1 - _e.startBlockNumber;
  }

  function getNumRequests(Epoch storage _e) internal view returns (uint) {
    if (_e.isEmpty || _e.rebase && _e.endBlockNumber == 0) return 0;
    return _e.RE.requestEnd + 1 - _e.RE.requestStart;
  }

  function calcNumBlock(uint _rs, uint _re) internal pure returns (uint) {
    return _re.sub(_rs).add(1).divCeil(MAX_REQUESTS());
  }

  /**
   * epochNumber
   * requestBlockId       id of RequestBlock[]
   * timestamp
   * referenceBlock       block number in previous fork
   * statesRoot
   * transactionsRoot
   * receiptsRoot
   * isRequest            true in case of URB & OR
   * userActivated        true in case of URB
   * challenged           true if it is challenge
   * challenging          true if it is being challenged
   * finalized            true if it is successfully finalize
   */
  struct PlasmaBlock {
    uint64 epochNumber;
    uint64 requestBlockId;
    uint64 timestamp;
    uint64 finalizedAt;
    uint64 referenceBlock;
    bytes32 statesRoot;
    bytes32 transactionsRoot;
    bytes32 receiptsRoot;
    bool isRequest;
    bool userActivated;
    bool challenged;
    bool challenging;
    bool finalized;
  }

  /**
   *
   * timestamp
   * isExit
   * isTransfer
   * finalized         true if request is finalized
   * challenged
   * value             ether amount in wei
   * requestor
   * to                requestable contract in root chain
   * trieKey
   * trieValue
   * hash              keccak256 hash of request transaction (in plasma chain)
   */
  struct Request {
    uint64 timestamp;
    bool isExit;
    bool isTransfer;
    bool finalized;
    bool challenged;
    uint128 value;
    address payable requestor;
    address to;
    bytes32 trieKey;
    bytes32 hash;
    bytes trieValue;
  }

  function applyRequestInRootChain(
    Request memory self,
    uint _requestId
  )
    internal
    returns (bool)
  {
    require(gasleft() > NA_TX_GAS_LIMIT + 5000);

    return RequestableI(self.to).applyRequestInRootChain(
      self.isExit,
      _requestId,
      self.requestor,
      self.trieKey,
      self.trieValue
    );
  }

  function toChildChainRequest(
    Request memory self,
    address _to
  )
    internal
    pure
    returns (Request memory out)
  {
    out.isExit = self.isExit;
    out.isTransfer = self.isTransfer;
    out.requestor = self.requestor;

    // Enter request of EtherToken mints PETH to requestor.
    if (!self.isExit && self.isTransfer) {
      out.to = self.requestor;
      bytes memory b = self.trieValue;
      uint128 v;

      assembly {
        v := mload(add(b, 0x20))
      }

      require(v > 0);

      // no trieKey and trieValue for EtherToken enter
      out.value = uint128(v);
    } else {
      out.to = _to;
      out.value = self.value;
      out.trieKey = self.trieKey;
      out.trieValue = self.trieValue;
    }
  }

  /**
   * @notice return tx.data
   */
  function getData(
    Request memory self,
    uint _requestId,
    bool _rootchain
  )
    internal
    pure
    returns (bytes memory out)
  {
    if (self.isTransfer && !self.isExit) {
      return out;
    }

    bytes4 funcSig = _rootchain ? APPLY_IN_ROOTCHAIN_SIGNATURE : APPLY_IN_CHILDCHAIN_SIGNATURE;

    out = abi.encodePacked(
      funcSig,
      abi.encode(
        bytes32(uint(self.isExit ? 1 : 0)),
        _requestId,
        uint256(uint160(self.requestor)),
        self.trieKey,
        self.trieValue
      )
    );
  }

  /**
   * @notice convert Request to TX
   */
  function toTX(
    Request memory self,
    uint _requestId,
    bool _rootchain
  )
    internal
    pure
    returns (TX memory out)
  {
    out.gasPrice = NA_TX_GAS_PRICE;
    out.gasLimit = uint64(NA_TX_GAS_LIMIT);
    out.to = self.to;
    out.value = self.value;
    out.data = getData(self, _requestId, _rootchain);
  }

  /**
   * submitted      true if no more request can be inserted
   *                because epoch is initialized
   * epochNumber    non request epoch number where the request is created
   * requestStart   first request id
   * requestEnd     last request id
   * trie           patricia tree contract address
   */
  struct RequestBlock {
    bool submitted;
    uint64 numEnter;
    uint64 epochNumber;
    uint64 requestStart;
    uint64 requestEnd;
    address trie;
  }

  // function noExit(RequestBlock storage self) internal returns (bool) {
  //   return self.RE.requestEnd.sub64(self.RE.requestStart).add64(1) == self.RE.firstRequestBlockId;
  // }

  function init(RequestBlock storage self) internal {
    /* use binary merkle tree instead of patricia tree
    if (self.trie == address(0)) {
      self.trie = new PatriciaTree();
    }
     */
  }

  function addRequest(
    RequestBlock storage self,
    Request storage _rootchainRequest,  // request in root chain
    Request memory _childchainRequest,  // request in child chain
    uint _requestId
  ) internal {
    _rootchainRequest.hash = hash(toTX(_childchainRequest, _requestId, false));

    /* use binary merkle tree instead of patricia tree
    require(self.trie != address(0));

    uint txIndex = _requestId.sub(self.RE.requestStart);

    bytes memory key = txIndex.encodeUint();
    bytes memory value = toBytes(toTX(_request, _requestId, false));

    PatriciaTree(self.trie).insert(key, value);
    self.transactionsRoot = PatriciaTree(self.trie).getRootHash();
     */
  }

  /*
   * TX for Ethereum transaction
   */
  struct TX {
    uint64 nonce;
    uint256 gasPrice;
    uint64 gasLimit;
    address to;
    uint256 value;
    bytes data;
    uint256 v;
    uint256 r;
    uint256 s;
  }

  function isNATX(TX memory self) internal pure returns (bool) {
    return self.v == 0 && self.r == 0 && self.s == 0;
  }

  // function toTX(bytes memory self) internal pure returns (TX memory out) {
  //   RLP.RLPItem[] memory packArr = self.toRLPItem().toList(9);

  //   out.nonce = uint64(packArr[0].toUint());
  //   out.gasPrice = packArr[1].toUint();
  //   out.gasLimit = uint64(packArr[2].toUint());
  //   out.to = packArr[3].toAddress();
  //   out.value = packArr[4].toUint();
  //   out.data = packArr[5].toBytes();
  //   out.v = packArr[6].toUint();
  //   out.r = packArr[7].toUint();
  //   out.s = packArr[8].toUint();
  // }

  /**
   * @notice Convert TX to RLP-encoded bytes
   */
  function toBytes(TX memory self) internal pure returns (bytes memory out) {
    bytes[] memory packArr = new bytes[](9);

    packArr[0] = self.nonce.encodeUint();
    packArr[1] = self.gasPrice.encodeUint();
    packArr[2] = self.gasLimit.encodeUint();
    packArr[3] = self.to.encodeAddress();
    packArr[4] = self.value.encodeUint();
    packArr[5] = self.data.encodeBytes();
    packArr[6] = self.v.encodeUint();
    packArr[7] = self.r.encodeUint();
    packArr[8] = self.s.encodeUint();

    return packArr.encodeList();
  }

  function hash(TX memory self) internal pure returns (bytes32) {
    bytes memory txBytes = toBytes(self);
    return keccak256(txBytes);
  }

  /**
   * Transaction Receipt
   */

  struct Log {
    address contractAddress;
    bytes32[] topics;
    bytes data;
  }

  struct Receipt {
    uint64 status;
    uint64 cumulativeGasUsed;
    bytes bloom; // 2048 bloom bits, byte[256]
    Log[] logs;
  }

  function toReceipt(bytes memory self) internal pure returns (Receipt memory r) {
    RLP.RLPItem[] memory items = self.toRLPItem().toList(4);

    r.status = uint64(items[0].toUint());
    r.cumulativeGasUsed = uint64(items[1].toUint());
    r.bloom = items[2].toBytes();

    // TODO: parse Logs
    r.logs = new Log[](0);
  }

  function toReceiptStatus(bytes memory self) internal pure returns (uint) {
    RLP.RLPItem[] memory items = self.toRLPItem().toList(4);
    return items[0].toUint();
  }


  /**
   * Helpers
   */

  /**
   * @notice Checks transaction root of a request block
   */
  function _checkTxRoot(
    bytes32 _transactionsRoot,
    RequestBlock storage _rb,
    Request[] storage _rs,
    bool _skipExit
  ) internal {
    uint s = _rb.requestStart;
    uint e = _rb.requestEnd;
    uint n = _skipExit ? _rb.numEnter : e - s + 1;

    require(n > 0);

    bytes32[] memory hashes = new bytes32[](n);

    // TODO: optimize to reduce gas
    uint j = s;
    for (uint i = s; i <= e; i++) {
      if (!_skipExit || !_rs[i].isExit) {
        hashes[j - s] = _rs[i].hash;
        j++;
      }
    }

    require(hashes.getRoot() == _transactionsRoot);

    /* use binary merkle tree instead of patricia tree
    Data.RequestBlock storage ORB = ORBs[fork.blocks[blockNumber].requestBlockId];
    require(_transactionsRoot == ORB.transactionsRoot);
      */
  }
}

pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

import "SafeMath.sol";
import "Math.sol";
import "Data.sol";
import "Address.sol";
import "BMT.sol";
// import "PatriciaTreeFace.sol";

import "MapperRole.sol";
import "SubmitterRole.sol";

import "Layer2Storage.sol";
import "Layer2Event.sol";
import "Layer2Base.sol";


contract Layer2 is Layer2Storage, Layer2Event, Layer2Base, MapperRole, SubmitterRole {
  using SafeMath for uint;
  using SafeMath for uint64;
  using Math for *;
  using Data for *;
  using Address for address;
  using BMT for *;

  /*
   * Modifiers
   */
  modifier onlyOperator() {
    require(msg.sender == operator);
    _;
  }

  modifier onlyValidCost(uint _expected) {
    require(msg.value >= _expected);
    _;
  }

  modifier finalizeBlocks() {
    if (!development) {
      _finalizeBlock();
    }
    _;
  }

  modifier checkURBSubmission () {
    Data.Fork storage fork = forks[currentFork];
    if (fork.timestamp + Data.URE_TIMEOUT() < block.timestamp) {
      // TODO: reset fork
      fork.forkedBlock = 0;
    }
    _;
  }

  modifier onlyOperatorOrSeigManager () {
    require(msg.sender == operator || msg.sender == seigManager);
    _;
  }

  /*
   * Constructor
   */
  constructor(
    address _epochHandler,
    address _submitHandler,
    address _etherToken,
    bool _development,
    uint _NRELength,

    // genesis block state
    bytes32 _statesRoot,
    bytes32 _transactionsRoot,
    bytes32 _receiptsRoot
  )
    public
  {
    require(_epochHandler.isContract());
    require(_submitHandler.isContract());
    require(_etherToken.isContract());

    epochHandler = _epochHandler;
    submitHandler = _submitHandler;
    etherToken = _etherToken;

    development = _development;
    operator = msg.sender;
    NRELength = _NRELength;

    Data.Fork storage fork = forks[currentFork];
    Data.PlasmaBlock storage genesis = fork.blocks[0];
    genesis.statesRoot = _statesRoot;
    genesis.transactionsRoot = _transactionsRoot;
    genesis.receiptsRoot = _receiptsRoot;

    // set up the genesis epoch
    fork.epochs[0].timestamp = uint64(block.timestamp);
    fork.epochs[0].initialized = true;

    // prepare ORE#2
    fork.epochs[2].isEmpty = true;
    fork.epochs[2].isRequest = true;

    _doFinalizeBlock(fork, genesis, 0);
    _doFinalizeNRE(fork, 0);

    _delegatePrepareNRE();
  }

  /*
   * External Functions
   */

  function changeOperator(address _operator) external onlyOperatorOrSeigManager {
    operator = _operator;
    emit OperatorChanged(_operator);
  }

  function addSubmitter(address account) public onlyOperator {
    _addSubmitter(account);
  }

  function addMapper(address account) public onlyOperator {
    _addMapper(account);
  }

  function setSeigManager(address account) public onlyOperatorOrSeigManager {
    seigManager = account;
  }

  /**
   * @notice map requestable contract in child chain
   * NOTE: only operator?
   */
  function mapRequestableContractByOperator(address _layer2, address _childchain)
    external
    onlyMapper
    returns (bool success)
  {
    require(_layer2.isContract());
    require(requestableContracts[_layer2] == address(0));

    requestableContracts[_layer2] = _childchain;

    emit RequestableContractMapped(_layer2, _childchain);
    return true;
  }

  function getNumEROs() external view returns (uint) {
    return EROs.length;
  }

  function getNumORBs() external view returns (uint) {
    return ORBs.length;
  }

  function getEROBytes(uint _requestId) public view returns (bytes memory out) {
    Data.Request storage ERO = EROs[_requestId];

    return ERO.toChildChainRequest(requestableContracts[ERO.to])
      .toTX(_requestId, false)
      .toBytes();
  }

  /**
   * @notice Declare to submit URB.
   */
  function prepareToSubmitURB()
    public
    payable
    onlyValidCost(COST_URB_PREPARE)
    // finalizeBlocks
  {
    // TODO: change to continuous rebase scheme.
    // disable UAF.
    revert();
    // return false;
    // Layer2Base.prepareToSubmitURB();
  }

  function submitNRE(
    uint _pos1, // forknumber + epochNumber
    uint _pos2, // startBlockNumber + endBlockNumber
    bytes32 _epochStateRoot,
    bytes32 _epochTransactionsRoot,
    bytes32 _epochReceiptsRoot
  )
    external
    payable
    onlySubmitter
    onlyValidCost(COST_NRB)
    finalizeBlocks
    returns (bool success)
  {
    return Layer2Base._delegateSubmitNRE(
      _pos1,
      _pos2,
      _epochStateRoot,
      _epochTransactionsRoot,
      _epochReceiptsRoot
    );
  }

  function submitORB(
    uint _pos,
    bytes32 _statesRoot,
    bytes32 _transactionsRoot,
    bytes32 _receiptsRoot
  )
    external
    payable
    onlySubmitter
    onlyValidCost(COST_NRB)
    finalizeBlocks
    returns (bool success)
  {
    return Layer2Base._delegateSubmitORB(
      _pos,
      _statesRoot,
      _transactionsRoot,
      _receiptsRoot
    );
  }

  function submitURB(
    uint _pos,
    bytes32 _statesRoot,
    bytes32 _transactionsRoot,
    bytes32 _receiptsRoot
  )
    external
    payable
    onlyValidCost(COST_URB)
    returns (bool success)
  {
    // TODO: change to continuous rebase scheme.
    // disable UAF.
    revert();
    return false;

    // return Layer2Base._delegateSubmitURB(
    //   _pos,
    //   _statesRoot,
    //   _transactionsRoot,
    //   _receiptsRoot
    // );
  }

  function finalizeBlock() external returns (bool success) {
    require(_finalizeBlock());
    return true;
  }

  /**
   * @notice Computation verifier contract reverts the block in case of wrong
   *         computation.
   */
  /* function revertBlock(uint _forkNumber, uint _blockNumber) external {
    // TODO: make a new fork?
  } */

  function challengeExit(
    uint _forkNumber,
    uint _blockNumber,
    uint _index,
    bytes calldata _receiptData,
    bytes calldata _proof
  ) external {
    Data.Fork storage fork = forks[_forkNumber];
    Data.PlasmaBlock storage pb = fork.blocks[_blockNumber];

    require(pb.isRequest);
    require(pb.finalized);

    uint requestId;
    bool userActivated = pb.userActivated;

    if (userActivated) {
      requestId = _doChallengeExit(pb, URBs[pb.requestBlockId], ERUs, _index, _receiptData, _proof);
      // TODO: dynamic cost for ERU
      msg.sender.transfer(COST_ERU);
    } else {
      requestId = _doChallengeExit(pb, ORBs[pb.requestBlockId], EROs,_index, _receiptData, _proof);
      msg.sender.transfer(COST_ERO);
    }

    emit RequestChallenged(requestId, userActivated);
  }

  function _doChallengeExit(
    Data.PlasmaBlock storage _pb,
    Data.RequestBlock storage _rb,
    Data.Request[] storage _rs,
    uint _index,
    bytes memory _receiptData,
    bytes memory _proof
  )
    internal
    returns (uint requestId)
  {
    requestId = _rb.requestStart + _index;
    require(requestId <= _rb.requestEnd);

    Data.Request storage r = _rs[requestId];

    require(_pb.finalizedAt + CP_EXIT > block.timestamp);
    require(_pb.finalized);
    require(!r.challenged);
    require(!r.finalized);

    bytes32 leaf = keccak256(_receiptData);

    require(_receiptData.toReceiptStatus() == 0);
    if (!development) {
      require(BMT.checkMembership(leaf, _index, _pb.receiptsRoot, _proof));
    }

    r.challenged = true;

    return requestId;
  }

  /**
   * @notice It challenges on NRBs containing null address transaction.
   */
  function challengeNullAddress(
    uint _blockNumber,
    bytes calldata _key,
    bytes calldata _txByte, // RLP encoded transaction
    uint _branchMask,
    bytes32[] calldata  _siblings
  ) external {
    Data.Fork storage fork = forks[currentFork];
    Data.PlasmaBlock storage pb = fork.blocks[_blockNumber];

    // check if the plasma block is NRB
    require(!pb.isRequest);

    // check if challenge period does not end yet
    require(pb.timestamp + CP_COMPUTATION > block.timestamp);

    // PatriciaTreeFace trie;
    // if (pb.userActivated) {
    //   trie = PatriciaTreeFace(URBs[pb.requestBlockId].trie);
    // } else {
    //   trie = PatriciaTreeFace(ORBs[pb.requestBlockId].trie);
    // }

    // Data.TX memory txData = Data.toTX(_txByte);
    // require(txData.isNATX());

    // TODO: use patricia verify library
    // require(trie.verifyProof(pb.transactionsRoot, _key, _txByte, _branchMask, _siblings));

    // TODO: fork? penalize?
  }

  /*
   * Public Functions
   */
  function startExit(
    address _to,
    bytes32 _trieKey,
    bytes memory _trieValue
  )
    public
    payable
    onlyValidCost(COST_ERO)
    returns (bool success)
  {
    uint requestId;
    requestId = _storeRequest(EROs, ORBs, _to, 0, _trieKey, _trieValue, true, false);

    emit RequestCreated(requestId, msg.sender, _to, 0, _trieKey, _trieValue, true, false);
    return true;
  }

  function startEnter(
    address _to,
    bytes32 _trieKey,
    bytes memory _trieValue
  )
    public
    payable
    returns (bool success)
  {
    uint requestId;
    uint weiAmount = msg.value;
    requestId = _storeRequest(EROs, ORBs, _to, weiAmount, _trieKey, _trieValue, false, false);
    numEnterForORB += 1;

    Data.Fork storage fork = forks[currentFork];

    emit RequestApplied(requestId, false);
    emit RequestCreated(requestId, msg.sender, _to, weiAmount, _trieKey, _trieValue, false, false);
    return true;
  }

  function makeERU(
    address _to,
    bytes32 _trieKey,
    bytes memory _trieValue
  )
    public
    payable
    onlyValidCost(COST_ERU)
    returns (bool success)
  {
    uint requestId;
    requestId = _storeRequest(ERUs, URBs, _to, 0, _trieKey, _trieValue, true, true);

    emit RequestCreated(requestId, msg.sender, _to, 0, _trieKey, _trieValue, true, true);
    return true;
  }

  /**
   * @notice Finalize a request if request block including it
   *         is finalized.
   * TODO: refactor implementation
   */
  function finalizeRequest() public returns (bool success) {
    uint requestId;
    Data.Fork storage fork = forks[lastAppliedForkNumber];
    uint epochNumber = lastAppliedEpochNumber;

    require(lastAppliedBlockNumber <= fork.lastBlock);

    Data.PlasmaBlock storage pb = fork.blocks[lastAppliedBlockNumber];
    Data.Epoch storage epoch = fork.epochs[epochNumber];

    // TODO: execute after finding next request block
    // find next fork
    if (fork.forkedBlock != 0 && lastAppliedBlockNumber >= fork.forkedBlock) {
      lastAppliedForkNumber += 1;
      fork = forks[lastAppliedForkNumber];

      epochNumber = fork.firstEpoch;
      epoch = fork.epochs[epochNumber];

      lastAppliedBlockNumber = fork.firstBlock;
      lastAppliedEpochNumber = epochNumber;

      pb = fork.blocks[lastAppliedBlockNumber];
    }

    // find next request block
    if (!pb.isRequest) {
      if (epochNumber == 0) {
        epochNumber = firstNonEmptyRequestEpoch[lastAppliedForkNumber];
      } else {
        epochNumber = fork.epochs[epochNumber].RE.nextEpoch;
      }
      require(epochNumber != 0);

      epoch = fork.epochs[epochNumber];
      lastAppliedBlockNumber = epoch.startBlockNumber;
      pb = fork.blocks[lastAppliedBlockNumber];
    } else {
      epochNumber = pb.epochNumber;
      epoch = fork.epochs[epochNumber];
    }

    lastAppliedEpochNumber = epochNumber;

    require(!epoch.isEmpty);
    require(epoch.isRequest);
    require(pb.isRequest);
    require(pb.finalized);
    require(pb.finalizedAt + CP_EXIT <= block.timestamp);

    // apply ERU
    if (pb.userActivated) {
      requestId = ERUIdToFinalize;

      require(ERUs.length > requestId);

      Data.Request storage ERU = ERUs[requestId];
      Data.RequestBlock storage URB = URBs[pb.requestBlockId];

      require(URB.requestStart <= requestId && requestId <= URB.requestEnd);

      // check next block
      if (requestId == URB.requestEnd) {
        if (fork.forkedBlock > 0 && lastAppliedBlockNumber == fork.forkedBlock - 1) {
          lastAppliedForkNumber += 1;
        }

        lastAppliedBlockNumber += 1;
      }

      ERUIdToFinalize = requestId + 1;

      if (ERU.isExit && !ERU.challenged) {
        // NOTE: do not check it reverted or not?
        ERU.applyRequestInRootChain(requestId);
        // TODO: dynamic cost and bond release period
        ERU.requestor.transfer(COST_ERU);
        emit RequestApplied(requestId, true);
      }
      ERU.finalized = true;

      emit RequestFinalized(requestId, true);
      return true;
    }

    // apply ERO
    requestId = EROIdToFinalize;

    require(EROs.length > requestId);

    Data.RequestBlock storage ORB = ORBs[pb.requestBlockId];

    require(ORB.requestStart <= requestId && requestId <= ORB.requestEnd);

    // check next block
    if (requestId == ORB.requestEnd) {
      // TODO: iterator blocks by NRE length for NRE'
      if (fork.forkedBlock > 0 && lastAppliedBlockNumber == fork.forkedBlock - 1) {
        lastAppliedForkNumber += 1;
      }

      lastAppliedBlockNumber += 1;
    }

    Data.Request storage ERO = EROs[requestId];
    EROIdToFinalize = requestId + 1;
    ERO.finalized = true;

    if (ERO.isExit && !ERO.challenged) {
      ERO.applyRequestInRootChain(requestId);
      ERO.requestor.transfer(COST_ERO);
      emit RequestApplied(requestId, false);
    }

    emit RequestFinalized(requestId, false);
    return true;
  }

  function finalizeRequests(uint n) external returns (bool success) {
    for (uint i = 0; i < n; i++) {
      require(finalizeRequest());
    }

    return true;
  }

  /**
   * @notice return the max number of request
   */
  function MAX_REQUESTS() external pure returns (uint maxRequests) {
    return Data.MAX_REQUESTS();
  }

  function lastBlock(uint forkNumber) public view returns (uint lastBlock) {
    return forks[forkNumber].lastBlock;
  }

  function lastEpoch(uint forkNumber) public view returns (uint lastBlock) {
    return forks[forkNumber].lastEpoch;
  }

  function getEpoch(
    uint forkNumber,
    uint epochNumber
  ) external view returns (
    Data.Epoch memory epoch
  ) {
    return forks[forkNumber].epochs[epochNumber];
  }

  function getLastEpoch() public view returns (Data.Epoch memory) {
    return forks[currentFork].epochs[forks[currentFork].lastEpoch];
  }

  function getBlock(
    uint forkNumber,
    uint blockNumber
  ) public view returns (Data.PlasmaBlock memory) {
    return forks[forkNumber].blocks[blockNumber];
  }

  function getBlockFinalizedAt(
    uint forkNumber,
    uint blockNumber
  ) public view returns (uint) {
    return forks[forkNumber].blocks[blockNumber].finalizedAt;
  }

  function getLastFinalizedBlock(uint forkNumber) public view returns (uint) {
    return forks[forkNumber].lastFinalizedBlock;
  }

  function getLastFinalizedEpoch(uint forkNumber) public view returns (uint) {
    return forks[forkNumber].lastFinalizedEpoch;
  }

  /**
   * @notice return true if the chain is forked by URB
   */
  function forked(uint _forkNumber) public view returns (bool result) {
    return _forkNumber != currentFork;
  }

  /**
   * @notice return true if the request is finalized
   */
  function getRequestFinalized(uint _requestId, bool _userActivated) public view returns (bool finalized) {
    if (_userActivated) {
      ERUs[_requestId].finalized;
    }

    return EROs[_requestId].finalized;
  }

  /*
   * Internal Functions
   */
  function _storeRequest(
    Data.Request[] storage _requests,
    Data.RequestBlock[] storage _rbs,
    address _to,
    uint _weiAmount,
    bytes32 _trieKey,
    bytes memory _trieValue,
    bool _isExit,
    bool _userActivated
  )
    internal
    returns (uint requestId)
  {
    // trieValue cannot be longer than 1KB.
    require(_trieValue.length <= 1024);

    bool isTransfer = _to == etherToken;

    // check parameters for simple ether transfer and message-call
    require(isTransfer && !_isExit || (requestableContracts[_to] != address(0)));

    requestId = _requests.length++;
    Data.Request storage r = _requests[requestId];

    r.requestor = msg.sender;
    r.to = _to;
    r.timestamp = uint64(block.timestamp);
    r.isExit = _isExit;
    r.isTransfer = isTransfer;
    r.value = uint128(_weiAmount);
    r.trieKey = _trieKey;
    r.trieValue = _trieValue;

    // apply message-call in case of enter request.
    if (!_isExit) {
      require(r.applyRequestInRootChain(requestId));
    }

    uint requestBlockId = _rbs.length == 0 ? _rbs.length++ : _rbs.length - 1;

    Data.RequestBlock storage rb = _rbs[requestBlockId];

    // make a new RequestBlock.
    if (rb.submitted || rb.requestEnd - rb.requestStart + 1 == Data.MAX_REQUESTS()) {
      rb.submitted = true;
      rb = _rbs[_rbs.length++];
      rb.requestStart = uint64(requestId);
    }

    rb.init();

    rb.requestEnd = uint64(requestId);
    if (!_isExit) {
      rb.numEnter += 1;
    }

    if (isTransfer && !_isExit) {
      rb.addRequest(r, r.toChildChainRequest(msg.sender), requestId);
    } else {
      rb.addRequest(r, r.toChildChainRequest(requestableContracts[_to]), requestId);
    }
  }

  /**
   * @notice finalize a block if possible.
   */
  function _finalizeBlock() internal returns (bool) {
    Data.Fork storage fork = forks[currentFork];

    // short circuit if waiting URBs
    if (fork.forkedBlock != 0) {
      return false;
    }

    uint blockNumber = Math.max(fork.firstBlock, fork.lastFinalizedBlock + 1);

    // short circuit if all blocks are submitted yet
    if (blockNumber > fork.lastBlock) {
      return false;
    }

    Data.PlasmaBlock storage pb = fork.blocks[blockNumber];

    // short circuit if the block is under challenge
    if (pb.challenging) {
      return false;
    }

    // 1. finalize request block
    if (pb.isRequest) {
      // short circuit if challenge period doesn't end
      if (pb.timestamp + CP_COMPUTATION > block.timestamp) {
        return false;
      }

      // finalize block
      _doFinalizeBlock(fork, pb, blockNumber);
      return true;
    }

    // 2. finalize non request epoch
    uint nextEpochNumber = fork.lastFinalizedEpoch + 1;
    while (fork.epochs[nextEpochNumber].isRequest) {
      nextEpochNumber += 1;
    }

    // if the first block of the next request epoch is finalized, finalize all
    // blocks of the current non request epoch.
    if (_checkFinalizableNRE(fork, nextEpochNumber)) {
      _doFinalizeNRE(fork, nextEpochNumber);
      return true;
    }

    return false;
  }

  /**
   * @notice return true if NRE can be finalized.
   */
  function _checkFinalizableNRE(Data.Fork storage fork, uint _epochNumber) internal view returns (bool) {
    // short circuit if epoch is not submitted yet
    if (_epochNumber > fork.lastEpoch) {
      return false;
    }

    Data.Epoch storage epoch = fork.epochs[_epochNumber];

    // short circuit if epoch is not initialized
    if (!epoch.initialized) {
      return false;
    }

    // short circuit if epoch is not NRE
    if (epoch.isRequest) {
      return false;
    }

    // short circuit if epoch is challenged or under challenge
    if (epoch.NRE.challenging || epoch.NRE.challenged) {
      return false;
    }

    // return if challenge period end
    return epoch.NRE.submittedAt + CP_WITHHOLDING <= block.timestamp;
    // return true;
  }

  /**
   * @notice finalize a block
   */
  function _doFinalizeBlock(
    Data.Fork storage _f,
    Data.PlasmaBlock storage _pb,
    uint _blockNumber
  ) internal {
    _pb.finalized = true;
    _pb.finalizedAt = uint64(block.timestamp);

    _f.lastFinalizedBlock = uint64(_blockNumber);
    _f.lastFinalizedEpoch = uint64(_pb.epochNumber);

    emit BlockFinalized(currentFork, _blockNumber);
  }

  /**
   * @notice finalize all blocks in the non request epoch
   */
  function _doFinalizeNRE(
    Data.Fork storage _f,
    uint _epochNumber
  ) internal {
    Data.Epoch storage epoch = _f.epochs[_epochNumber];

    epoch.NRE.finalized = true;
    epoch.NRE.finalizedAt = uint64(block.timestamp);

    _f.lastFinalizedBlock = uint64(epoch.endBlockNumber);
    _f.lastFinalizedEpoch = uint64(_epochNumber);

    // a single EpochFinalized event replaces lots of BlockFinalized events.
    emit EpochFinalized(currentFork, _epochNumber, epoch.startBlockNumber, epoch.endBlockNumber);

    return;
  }
}

pragma solidity ^0.5.12;

import "Layer2Storage.sol";
import "Layer2Event.sol";

/**
 * @notice Layer2Base provides functions to be delegated to other handlers,
 *         EpochHandler, SubmitHandler.
 */
contract Layer2Base is Layer2Storage, Layer2Event {
  /**
   * Constants
   */

  // solium-disable mixedcase
  // EpochHandler functions
  bytes4 constant PREPARE_TO_SUTMIBT_ORB_SIG = bytes4(keccak256("prepareORE()"));
  bytes4 constant PREPARE_TO_SUTMIBT_NRB_SIG = bytes4(keccak256("prepareNRE()"));
  bytes4 constant PREPARE_TO_SUTMIBT_URB_SIG = bytes4(keccak256("prepareToSubmitURB()"));
  bytes4 constant PREPARE_ORE_AFTER_URE_SIG = bytes4(keccak256("prepareOREAfterURE()"));
  bytes4 constant PREPARE_NRE_AFTER_URE_SIG = bytes4(keccak256("prepareNREAfterURE()"));

  // SubmitHandler functions
  bytes4 constant SUBMIT_NRE_SIG = bytes4(keccak256("submitNRE(uint256,uint256,bytes32,bytes32,bytes32)"));
  bytes4 constant SUBMIT_ORB_SIG = bytes4(keccak256("submitORB(uint256,bytes32,bytes32,bytes32)"));
  bytes4 constant SUBMIT_URB_SIG = bytes4(keccak256("submitURB(uint256,bytes32,bytes32,bytes32)"));
  // solium-endable mixedcase

  /**
   * Functions
   */
  // delegate to epoch handler
  function _delegatePrepareORE() internal {
    // solium-disable-next-line security/no-low-level-calls, max-len, no-unused-vars
    (bool success, bytes memory returnData) = epochHandler.delegatecall(abi.encodeWithSelector(PREPARE_TO_SUTMIBT_ORB_SIG));
    require(success);
  }

  // delegate to epoch handler
  function _delegatePrepareNRE() internal {
    // solium-disable-next-line security/no-low-level-calls, max-len, no-unused-vars
    (bool success, bytes memory returnData) = epochHandler.delegatecall(abi.encodeWithSelector(PREPARE_TO_SUTMIBT_NRB_SIG));
    // (bool success, bytes memory returnData) = epochHandler.delegatecall(abi.encodeWithSelector(PREPARE_TO_SUTMIBT_NRB_SIG));
    require(success);
  }

  // delegate to epoch handler
  function _delegatePrepareToSubmitURB() internal {
    // solium-disable-next-line security/no-low-level-calls, max-len, no-unused-vars
    (bool success, bytes memory returnData) = epochHandler.delegatecall(abi.encodeWithSelector(PREPARE_TO_SUTMIBT_URB_SIG));
    // (bool success, bytes memory returnData) = epochHandler.delegatecall(abi.encodeWithSelector(PREPARE_TO_SUTMIBT_NRB_SIG));
    require(success);
  }

  // delegate to epoch handler
  function _delegatePrepareOREAfterURE() internal {
    // solium-disable-next-line security/no-low-level-calls, max-len, no-unused-vars
    (bool success, bytes memory returnData) = epochHandler.delegatecall(abi.encodeWithSelector(PREPARE_ORE_AFTER_URE_SIG));
    require(success);
  }

  // delegate to epoch handler
  function _delegatePrepareNREAfterURE() internal {
    // solium-disable-next-line security/no-low-level-calls, max-len, no-unused-vars
    (bool success, bytes memory returnData) = epochHandler.delegatecall(abi.encodeWithSelector(PREPARE_NRE_AFTER_URE_SIG));
    require(success);
  }

  // delegate to submit handler
  function _delegateSubmitNRE(
    uint _pos1, // forknumber + epochNumber
    uint _pos2, // startBlockNumber + endBlockNumber
    bytes32 _epochStateRoot,
    bytes32 _epochTransactionsRoot,
    bytes32 _epochReceiptsRoot
  )
    internal
    returns (bool success)
  {
    // solium-disable-next-line security/no-low-level-calls, max-len, no-unused-vars
    (bool success, bytes memory returnData) = submitHandler.delegatecall(abi.encodeWithSelector(
      SUBMIT_NRE_SIG,
      _pos1,
      _pos2,
      _epochStateRoot,
      _epochTransactionsRoot,
      _epochReceiptsRoot
    ));
    require(success);
    return true;
  }

  // delegate to submit handler
  function _delegateSubmitORB(
    uint _pos,
    bytes32 _statesRoot,
    bytes32 _transactionsRoot,
    bytes32 _receiptsRoot
  )
    internal
    returns (bool success)
  {
    // solium-disable-next-line security/no-low-level-calls, max-len, no-unused-vars
    (bool success, bytes memory returnData) = submitHandler.delegatecall(abi.encodeWithSelector(
      SUBMIT_ORB_SIG,
      _pos,
      _statesRoot,
      _transactionsRoot,
      _receiptsRoot
    ));
    require(success);
    return true;
  }

  // delegate to submit handler
  function _delegateSubmitURB(
    uint _pos,
    bytes32 _statesRoot,
    bytes32 _transactionsRoot,
    bytes32 _receiptsRoot
  )
    internal
    returns (bool success)
  {
    // solium-disable-next-line security/no-low-level-calls, max-len, no-unused-vars
    (bool success, bytes memory returnData) = submitHandler.delegatecall(abi.encodeWithSelector(
      SUBMIT_URB_SIG,
      _pos,
      _statesRoot,
      _transactionsRoot,
      _receiptsRoot
    ));
    require(success);
    return true;
  }
}

pragma solidity ^0.5.12;

import "Data.sol";


contract Layer2Event {
  event OperatorChanged(address _newOperator);

  event SessionTimeout(bool userActivated);

  event Forked(uint newFork, uint epochNumber, uint forkedBlockNumber);

  /**
   * epochNumber          the number of prepared epoch
   * startBlockNumber     first block number of the epoch.
   * endBlockNumber       last block number of the epoch. It is 0 for ORE' and NRE'.
   * requestStart         first request id of the epoch.
   * requestEnd           last request id of the epoch.
   * epochIsEmpty         true if epoch doesn't have block.
   * isRequest            true for ORE and URE.
   * userActivated        true for URE.
   */
  event EpochPrepared(
    uint forkNumber,
    uint epochNumber,
    uint startBlockNumber,
    uint endBlockNumber,
    uint requestStart,
    uint requestEnd,
    bool epochIsEmpty,
    bool isRequest,
    bool userActivated,
    bool rebase
  );

  event EpochFilling(
    uint forkNumber,
    uint epochNumber
  );

  event EpochFilled(
    uint forkNumber,
    uint epochNumber
  );

  event EpochRebased(
    uint forkNumber,
    uint epochNumber,
    uint startBlockNumber,
    uint endBlockNumber,
    uint requestStart,
    uint requestEnd,
    bool epochIsEmpty,
    bool isRequest,
    bool userActivated
  );

  event BlockSubmitted(
    uint fork,
    uint epochNumber,
    uint blockNumber,
    bool isRequest,
    bool userActivated
  );

  event RequestCreated(
    uint requestId,
    address requestor,
    address to,
    uint weiAmount,
    bytes32 trieKey,
    bytes trieValue,
    bool isExit,
    bool userActivated
  );
  event ERUCreated(
    uint requestId,
    address requestor,
    address to,
    bytes trieKey,
    bytes32 trieValue
  );

  event BlockFinalized(uint forkNumber, uint blockNumber);
  event EpochFinalized(
    uint forkNumber,
    uint epochNumber,
    uint startBlockNumber,
    uint endBlockNumber
  );

  // emit when exit is finalized. _userActivated is true for ERU
  event RequestFinalized(uint requestId, bool userActivated);
  event RequestApplied(uint requestId, bool userActivated);
  event RequestChallenged(uint requestId, bool userActivated);

  event RequestableContractMapped(address contractInRootchain, address contractInChildchain);
}

pragma solidity ^0.5.12;

import "Data.sol";


contract Layer2Storage {
  /*
   * Storage
   */
  bool public development; // dev mode
  address public operator;
  address public epochHandler;
  address public submitHandler;
  address public etherToken;
  address public seigManager;

  // 1 epoch = N NRBs or k URBs or k ORBs.
  // N consecutive NRBs must be submitted in an epoch. In case of request block,
  // massive requests can be included in k ORBs, and k is determined when
  // N NRBs are submitted or when preparing URBs submission.
  uint public NRELength;

  // Increase for each URB
  uint public currentFork;

  // First not-empty request epochs of a fork
  mapping (uint => uint) public firstFilledORENumber;

  mapping (uint => Data.Fork) public forks;

  // Enter & Exit requests for ORB / URB
  Data.Request[] public EROs;
  Data.Request[] public ERUs;

  // Consecutive request block. The fork where they are in is defined in Data.PlasmaBlock
  Data.RequestBlock[] public ORBs;
  Data.RequestBlock[] public URBs;

  // count enter requests for epoch
  uint public numEnterForORB;

  // epoch number of last non-empty request epoch.
  mapping(uint => uint) public lastNonEmptyRequestEpoch;

  // epoch number of first non-empty request epoch.
  mapping(uint => uint) public firstNonEmptyRequestEpoch;

  // Last applied request
  uint public lastAppliedForkNumber;
  uint public lastAppliedEpochNumber;
  uint public lastAppliedBlockNumber;

  // solium-disable mixedcase
  uint public EROIdToFinalize;
  uint public ERUIdToFinalize;
  // solium-enable mixedcase

  // uint public finalizableEROId = 2^256 - 1;
  // uint public finalizableERUId = 2^256 - 1;

  // Requestable contract address in child chain
  mapping (address => address) public requestableContracts;

  /*
   * Constant
   */
  address constant public NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

  // Cost parameters for development and test
  uint public constant COST_ERO = 0;
  uint public constant COST_ERU = 0;
  uint public constant COST_URB_PREPARE = 0;
  uint public constant COST_URB = 0;
  uint public constant COST_ORB = 0;
  uint public constant COST_NRB = 0;
  uint public constant PREPARE_TIMEOUT = 60; // 60 sec for dev

  // Challenge periods for computation and withholding
  uint public constant CP_COMPUTATION = 15; // 15 sec for dev
  uint public constant CP_WITHHOLDING = 20; // 20 sec for dev
  uint public constant CP_EXIT = 10; // 10 sec for dev

  // TODO: develop more concrete cost model
  // Cost parameters for production
  // uint public constant COST_ERO = 0.1 ether;         // cost for invalid exit
  // uint public constant COST_ERU = 0.2 ether;         // cost for fork & rebase
  // uint public constant COST_URB_PREPARE = 0.1 ether; // cost for URB prepare
  // uint public constant COST_URB = 0.9 ether;         // cost for fork & rebase
  // uint public constant COST_ORB = 0.1 ether;         // cost for invalid computation
  // uint public constant COST_NRB = 0.1 ether;         // cost for invalid computation
  // uint public constant PREPARE_TIMEOUT = 1 hours;

  // // Challenge periods for computation and withholding
  // uint public constant CP_COMPUTATION = 1 days;
  // uint public constant CP_WITHHOLDING = 7 days;
  // uint public constant CP_EXIT = 1 days;


  // Gas limit for request trasaction
  uint public constant REQUEST_GAS = 100000;

  bool public constant isLayer2 = true;
}

pragma solidity ^0.5.12;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
  }

  // return ceil(n/d)
  function divCeil(uint256 n, uint256 d) internal pure returns (uint256) {
    return n % d == 0 ? n / d : n / d + 1;
  }
}

pragma solidity ^0.5.12;

/**
 * @title RLPReader
 * @dev RLPReader is used to read and parse RLP encoded data in memory.
 * @author Andreas Olofsson ([email protected])
 */


library RLP {
    uint constant DATA_SHORT_START = 0x80;
    uint constant DATA_LONG_START = 0xB8;
    uint constant LIST_SHORT_START = 0xC0;
    uint constant LIST_LONG_START = 0xF8;

    uint constant DATA_LONG_OFFSET = 0xB7;
    uint constant LIST_LONG_OFFSET = 0xF7;



    struct RLPItem {
        uint _unsafeMemPtr;    // Pointer to the RLP-encoded bytes.
        uint _unsafeLength;    // Number of bytes. This is the full length of the string.
    }

    struct Iterator {
        RLPItem _unsafeItem;   // Item that's being iterated over.
        uint _unsafeNextPtr;   // Position of the next item in the list.
    }

    /* RLPItem */

    /// @dev Creates an RLPItem from an array of RLP encoded bytes.
    /// @param self The RLP encoded bytes.
    /// @return An RLPItem
    function toRLPItem(bytes memory self) internal pure returns (RLPItem memory) {
        uint len = self.length;
        uint memPtr;
        assembly {
            memPtr := add(self, 0x20)
        }
        return RLPItem(memPtr, len);
    }

    /// @dev Get the list of sub-items from an RLP encoded list.
    /// Warning: This requires passing in the number of items.
    /// @param self The RLP item.
    /// @return Array of RLPItems.
    function toList(RLPItem memory self, uint256 numItems) internal pure returns (RLPItem[] memory list) {
        list = new RLPItem[](numItems);
        Iterator memory it = iterator(self);
        uint idx;
        while (idx < numItems) {
            list[idx] = next(it);
            idx++;
        }
    }

    /// @dev Decode an RLPItem into a uint. This will not work if the
    /// RLPItem is a list.
    /// @param self The RLPItem.
    /// @return The decoded string.
    function toUint(RLPItem memory self) internal pure returns (uint data) {
        (uint rStartPos, uint len) = _decode(self);
        assembly {
            data := div(mload(rStartPos), exp(256, sub(32, len)))
        }
    }

    /// @dev Decode an RLPItem into an address. This will not work if the
    /// RLPItem is a list.
    /// @param self The RLPItem.
    /// @return The decoded string.
    function toAddress(RLPItem memory self)
    internal
    pure
    returns (address data)
    {
        (uint rStartPos,) = _decode(self);
        assembly {
            data := div(mload(rStartPos), exp(256, 12))
        }
    }

    /// @dev Create an iterator.
    /// @param self The RLP item.
    /// @return An 'Iterator' over the item.
    function iterator(RLPItem memory self) private pure returns (Iterator memory it) {
        uint ptr = self._unsafeMemPtr + _payloadOffset(self);
        it._unsafeItem = self;
        it._unsafeNextPtr = ptr;
    }

    /* Iterator */
    function next(Iterator memory self) private pure returns (RLPItem memory subItem) {
        uint ptr = self._unsafeNextPtr;
        uint itemLength = _itemLength(ptr);
        subItem._unsafeMemPtr = ptr;
        subItem._unsafeLength = itemLength;
        self._unsafeNextPtr = ptr + itemLength;
    }

    function hasNext(Iterator memory self) private pure returns (bool) {
        RLPItem memory item = self._unsafeItem;
        return self._unsafeNextPtr < item._unsafeMemPtr + item._unsafeLength;
    }

    // Get the payload offset.
    function _payloadOffset(RLPItem memory self)
    private
    pure
    returns (uint)
    {
        uint b0;
        uint memPtr = self._unsafeMemPtr;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START)
            return 0;
        if (b0 < DATA_LONG_START || (b0 >= LIST_SHORT_START && b0 < LIST_LONG_START))
            return 1;
        if (b0 < LIST_SHORT_START)
            return b0 - DATA_LONG_OFFSET + 1;
        return b0 - LIST_LONG_OFFSET + 1;
    }

    // Get the full length of an RLP item.
    function _itemLength(uint memPtr)
    private
    pure
    returns (uint len)
    {
        uint b0;
        assembly {
            b0 := byte(0, mload(memPtr))
        }
        if (b0 < DATA_SHORT_START)
            len = 1;
        else if (b0 < DATA_LONG_START)
            len = b0 - DATA_SHORT_START + 1;
    }

    // Get start position and length of the data.
    function _decode(RLPItem memory self)
    private
    pure
    returns (uint memPtr, uint len)
    {
        uint b0;
        uint start = self._unsafeMemPtr;
        assembly {
            b0 := byte(0, mload(start))
        }
        if (b0 < DATA_SHORT_START) {
            memPtr = start;
            len = 1;
            return (memPtr, len);
        }
        if (b0 < DATA_LONG_START) {
            len = self._unsafeLength - 1;
            memPtr = start + 1;
        } else {
            uint bLen;
            assembly {
                bLen := sub(b0, 0xB7) // DATA_LONG_OFFSET
            }
            len = self._unsafeLength - 1 - bLen;
            memPtr = start + bLen + 1;
        }
        return (memPtr, len);
    }

    /// @dev Return the RLP encoded bytes.
    /// @param self The RLPItem.
    /// @return The bytes.
    function toBytes(RLPItem memory self)
    internal
    pure
    returns (bytes memory bts)
    {
        uint len = self._unsafeLength;
        if (len == 0)
            return bts;
        bts = new bytes(len);
        _copyToBytes(self._unsafeMemPtr, bts, len);
    }

    // Assumes that enough memory has been allocated to store in target.
    function _copyToBytes(uint btsPtr, bytes memory tgt, uint btsLen)
    private
    pure
    {
        // Exploiting the fact that 'tgt' was the last thing to be allocated,
        // we can write entire words, and just overwrite any excess.
        assembly {
            {
            // evm operations on words
                let words := div(add(btsLen, 31), 32)
                let rOffset := btsPtr
                let wOffset := add(tgt, 0x20)
                for
                { let i := 0 } // start at arr + 0x20 -> first byte corresponds to length
                lt(i, words)
                { i := add(i, 1) }
                {
                    let offset := mul(i, 0x20)
                    mstore(add(wOffset, offset), mload(add(rOffset, offset)))
                }
                mstore(add(tgt, add(0x20, mload(tgt))), 0)
            }
        }

    }

}

pragma solidity ^0.5.12;

/**
 * @title A simple RLP encoding library
 * @author Bakaoh
 */
library RLPEncode {

    uint8 constant STRING_OFFSET = 0x80;
    uint8 constant LIST_OFFSET = 0xc0;

    /**
     * @notice Encode string item
     * @param self The string (ie. byte array) item to encode
     * @return The RLP encoded string in bytes
     */
    function encodeBytes(bytes memory self) internal pure returns (bytes memory) {
        if (self.length == 1 && self[0] <= 0x7f) {
            return self;
        }
        return mergeBytes(encodeLength(self.length, STRING_OFFSET), self);
    }

    /**
     * @notice Encode address
     * @param self The address to encode
     * @return The RLP encoded address in bytes
     */
    function encodeAddress(address self) internal pure returns (bytes memory) {
        bytes memory b;
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, self))
            mstore(0x40, add(m, 52))
            b := m
        }
        return encodeBytes(b);
    }

    /**
     * @notice Encode uint
     * @param self The uint to encode
     * @return The RLP encoded uint in bytes
     */
    function encodeUint(uint self) internal pure returns (bytes memory) {
        return encodeBytes(toBinary(self));
    }

    /**
     * @notice Encode int
     * @param self The int to encode
     * @return The RLP encoded int in bytes
     */
    function encodeInt(int self) internal pure returns (bytes memory) {
        return encodeUint(uint(self));
    }

    /**
     * @notice Encode bool
     * @param self The bool to encode
     * @return The RLP encoded bool in bytes
     */
    function encodeBool(bool self) internal pure returns (bytes memory) {
        bytes memory rs = new bytes(1);
        if (self) {
            rs[0] = bytes1(uint8(1));
        }
        return rs;
    }

    /**
     * @notice Encode list of items
     * @param self The list of items to encode, each item in list must be already encoded
     * @return The RLP encoded list of items in bytes
     */
    function encodeList(bytes[] memory self) internal pure returns (bytes memory) {
        bytes memory payload = new bytes(0);
        for (uint i = 0; i < self.length; i++) {
            payload = mergeBytes(payload, self[i]);
        }
        return mergeBytes(encodeLength(payload.length, LIST_OFFSET), payload);
    }

    /**
     * @notice Concat two bytes arrays
     * @dev This should be optimize with assembly to save gas costs
     * @param param1 The first bytes array
     * @param param2 The second bytes array
     * @return The merged bytes array
     */
    function mergeBytes(bytes memory param1, bytes memory param2) internal pure returns (bytes memory) {
        bytes memory merged = new bytes(param1.length + param2.length);
        uint k = 0;
        uint i;
        for (i = 0; i < param1.length; i++) {
            merged[k] = param1[i];
            k++;
        }

        for (i = 0; i < param2.length; i++) {
            merged[k] = param2[i];
            k++;
        }
        return merged;
    }

    /**
     * @notice Encode the first byte, followed by the `length` in binary form if `length` is more than 55.
     * @param length The length of the string or the payload
     * @param offset `STRING_OFFSET` if item is string, `LIST_OFFSET` if item is list
     * @return RLP encoded bytes
     */
    function encodeLength(uint length, uint offset) internal pure returns (bytes memory) {
        require(length < 256**8, "input too long");
        bytes memory rs = new bytes(1);
        if (length <= 55) {
            rs[0] = byte(uint8(length + offset));
            return rs;
        }
        bytes memory bl = toBinary(length);
        rs[0] = byte(uint8(bl.length + offset + 55));
        return mergeBytes(rs, bl);
    }

    /**
     * @notice Encode integer in big endian binary form with no leading zeroes
     * @dev This should be optimize with assembly to save gas costs
     * @param x The integer to encode
     * @return RLP encoded bytes
     */
    function toBinary(uint x) internal pure returns (bytes memory) {
        uint i;
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
        for (i = 0; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }
        bytes memory rs = new bytes(32 - i);
        for (uint j = 0; j < rs.length; j++) {
            rs[j] = b[i++];
        }
        return rs;
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/67bca85/contracts/access/Roles.sol
pragma solidity ^0.5.12;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev Give an account access to this role.
   */
  function add(Role storage role, address account) internal {
    require(!has(role, account));
    role.bearer[account] = true;
  }

  /**
   * @dev Remove an account's access to this role.
   */
  function remove(Role storage role, address account) internal {
    require(has(role, account));
    role.bearer[account] = false;
  }

  /**
   * @dev Check if an account has this role.
   * @return bool
   */
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0));
    return role.bearer[account];
  }
}

pragma solidity ^0.5.12;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul64(uint64 a, uint64 b) internal pure returns (uint64) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint64 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div64(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint64 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub64(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b <= a);
    uint64 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add64(uint64 a, uint64 b) internal pure returns (uint64) {
    uint64 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod64(uint64 a, uint64 b) internal pure returns (uint64) {
    require(b != 0);
    return a % b;
  }
}

pragma solidity ^0.5.12;

interface RequestableI {
  function applyRequestInRootChain(
    bool isExit,
    uint256 requestId,
    address requestor,
    bytes32 trieKey,
    bytes calldata trieValue
  ) external returns (bool success);

  function applyRequestInChildChain(
    bool isExit,
    uint256 requestId,
    address requestor,
    bytes32 trieKey,
    bytes calldata trieValue
  ) external returns (bool success);
}

pragma solidity ^0.5.12;

import "Roles.sol";


contract MapperRole {
  using Roles for Roles.Role;

  event MapperAdded(address indexed account);
  event MapperRemoved(address indexed account);

  Roles.Role private _mappers;

  constructor () internal {
    _addMapper(msg.sender);
  }

  modifier onlyMapper() {
    require(isMapper(msg.sender));
    _;
  }

  function isMapper(address account) public view returns (bool) {
    return _mappers.has(account);
  }

  function addMapper(address account) public onlyMapper {
    _addMapper(account);
  }

  function renounceMapper() public {
    _removeMapper(msg.sender);
  }

  function _addMapper(address account) internal {
    _mappers.add(account);
    emit MapperAdded(account);
  }

  function _removeMapper(address account) internal {
    _mappers.remove(account);
    emit MapperRemoved(account);
  }
}

pragma solidity ^0.5.12;

import "Roles.sol";


contract SubmitterRole {
  using Roles for Roles.Role;

  event SubmitterAdded(address indexed account);
  event SubmitterRemoved(address indexed account);

  Roles.Role private _submitters;

  constructor () internal {
    _addSubmitter(msg.sender);
  }

  modifier onlySubmitter() {
    require(isSubmitter(msg.sender));
    _;
  }

  function isSubmitter(address account) public view returns (bool) {
    return _submitters.has(account);
  }

  function addSubmitter(address account) public onlySubmitter {
    _addSubmitter(account);
  }

  function renounceSubmitter() public {
    _removeSubmitter(msg.sender);
  }

  function _addSubmitter(address account) internal {
    _submitters.add(account);
    emit SubmitterAdded(account);
  }

  function _removeSubmitter(address account) internal {
    _submitters.remove(account);
    emit SubmitterRemoved(account);
  }
}