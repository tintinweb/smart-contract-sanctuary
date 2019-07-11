/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.5.5;
pragma experimental ABIEncoderV2;

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
  */
  function mul(uint a, uint b) internal pure returns (uint) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) return 0;
    uint c = a * b;
    require(c / a == b, "SM: mul error");
    return c;
  }

  /**
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint a, uint b) internal pure returns (uint) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SM: div error");
    uint c = a / b;
    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a, "SM: sub error");
    uint c = a - b;
    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, "SM: add error");
    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint a, uint b) internal pure returns (uint) {
    require(b != 0);
    return a % b;
  }
}
interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller&#39;s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller&#39;s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender&#39;s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller&#39;s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
library DaoLib {
  struct Daoist {
    address daoist;
    uint64 shares;
  }

  struct DaoistOutput {
    address daoist;
    uint64 shares;
    uint248 index;
  }

  struct TokenValue {
    address tokenAddress;
    uint256 value;
  }

  struct Application {
    bytes32 metaHash;
    uint256 weiTribute;
    address applicant;
    address[] tokenTributes;
    uint256[] tokenTributeValues;
    uint64 shares;
  }
}

library Indices {
  struct Index {
    bool exists;
    uint248 index;
  }
}

/**
 * @title BaseDAOStorage
 * @author Dillon Kellar, Raymond Pulver
 * @dev Storage and getters for BaseDao.sol
 * @notice Makes the contract less cluttered by separating getters and storage setup into a separate contract.
 */
contract BaseDAOStorage {
  using SafeMath for uint64;
  using SafeMath for uint256;

  uint256 internal _multiplier = 2 finney;
  uint64 internal _totalShares;
  DaoLib.Daoist[] internal _daoists;
  mapping(address => Indices.Index) internal _daoistIndices;
  IERC20[] internal _tokens;
  mapping(address => Indices.Index) internal _tokenIndices;

  function getTotalShares() external view returns (uint64 totalShares) {
    totalShares = _totalShares;
  }

  function getDaoist(address daoistAddress) public view returns (DaoLib.DaoistOutput memory daoist) {
    Indices.Index memory index = _daoistIndices[daoistAddress];
    require(index.exists, "ExeDAO: Daoist not found");
    DaoLib.Daoist memory _daoist = _daoists[index.index];
    daoist = DaoLib.DaoistOutput(_daoist.daoist, _daoist.shares, index.index);
  }

  function getDaoists() external view returns (DaoLib.Daoist[] memory daoists) {
    uint256 size = _daoists.length;
    daoists = new DaoLib.Daoist[](size);
    for (uint256 i = 0; i < size; i++) daoists[i] = _daoists[i];
  }

  function getToken(address tokenAddress) external view returns (DaoLib.TokenValue memory tokenValue) {
    IERC20 _token = _getToken(tokenAddress);
    uint256 balance = _token.balanceOf(address(this));
    tokenValue = DaoLib.TokenValue(address(_token), balance);
  }

  function getTokens() external view returns (DaoLib.TokenValue[] memory tokenBalances) {
    uint256 size = _tokens.length;
    tokenBalances = new DaoLib.TokenValue[](size);
    for (uint256 i = 0; i < size; i++) {
      uint256 balance = _tokens[i].balanceOf(address(this));
      tokenBalances[i] = DaoLib.TokenValue(address(_tokens[i]), balance);
    }
  }

  function _getToken(address tokenAddress) internal view returns (IERC20 token) {
    Indices.Index memory index = _tokenIndices[tokenAddress];
    require(index.exists, "ExeDAO: Token not found");
    token = _tokens[index.index];
  }
}

interface IBaseDAO {
  function getDaoist(address daoistAddress) external view returns (DaoLib.DaoistOutput memory daoist);
  function getDaoists() external view returns (DaoLib.Daoist[] memory daoists);
  function getToken(address tokenAddress) external view returns (DaoLib.TokenValue memory token);
  function getTokens() external view returns (DaoLib.TokenValue[] memory tokens);
  function burnShares(uint64 amount) external returns(uint256 weiValue, DaoLib.TokenValue[] memory tokenBurnValues);
}

/**
 * @title BaseDAO
 * @author Dillon Kellar, Raymond Pulver
 * @notice Keeps track of who owns shares in a DAO and provides a method for burning shares in exchange for ether owned by the contract.
 * @dev Does not expose any external methods for giving shares, must be handled by child
 */
contract BaseDAO is IBaseDAO, BaseDAOStorage {
  event SharesBurned(address indexed daoist, uint64 shares);
  event SharesMinted(address indexed daoist, uint64 shares);
  event TokenAdded(address indexed tokenAddress);
  event TokenRemoved(address indexed tokenAddress);
  event TokenTransferred(address indexed tokenAddress, address indexed recipient, uint256 amount);
  event TokenReceived(address indexed tokenAddress, address indexed sender, uint256 amount);


  constructor(uint64 shares) public payable {
    _mintShares(msg.sender, shares);
  }

  /**
   * @dev Returns the number of shares owned by the sender. Reverts if the user has no shares.
   */
  function _getShares() internal view returns (uint64 shares) {
    shares = getDaoist(msg.sender).shares;
    require(shares > 0, "ExeDAO: Not a daoist");
  }

  function burnShares(uint64 amount) external
  returns(uint256 weiValue, DaoLib.TokenValue[] memory tokenBurnValues) {
    DaoLib.DaoistOutput memory _daoist = getDaoist(msg.sender);
    require(_daoist.shares >= amount, "Not enough shares");
    // use large multiplier to avoid rounding errors
    uint256 relativeShare = _multiplier.mul(amount).div(_totalShares);
    // subtract shares prior to sending anything to prevent reentrance
    _daoists[_daoist.index].shares = uint64(_daoist.shares.sub(amount));
    _totalShares = uint64(_totalShares.sub(amount));
    uint256 numTokens = _tokens.length;
    tokenBurnValues = new DaoLib.TokenValue[](numTokens);
    uint256 shareValue;
    uint256 balance;
    for (uint256 i = 0; i < numTokens; i++) {
      IERC20 token = _tokens[i];
      balance = token.balanceOf(address(this));
      shareValue = relativeShare.mul(balance).div(_multiplier);
      token.transfer(msg.sender, shareValue);
      tokenBurnValues[i] = DaoLib.TokenValue(address(token), shareValue);
    }
    weiValue = address(this).balance.mul(relativeShare).div(_multiplier);
    msg.sender.transfer(weiValue);
    emit SharesBurned(msg.sender, amount);
  }

  function _mintShares(address recipient, uint64 amount) internal {
    Indices.Index memory index = _daoistIndices[recipient];
    if (!index.exists) {
      _daoistIndices[recipient] = Indices.Index(true, uint248(_daoists.length));
      _daoists.push(DaoLib.Daoist(recipient, amount));
    } else {
      _daoists[index.index].shares = uint64(_daoists[index.index].shares.add(amount));
    }
    _totalShares = uint64(_totalShares.add(amount));
    emit SharesMinted(recipient, amount);
  }

  function _addToken(address tokenAddress) internal {
    Indices.Index memory index = _tokenIndices[tokenAddress];
    require(!index.exists, "ExeDAO: Token already exists");
    _tokenIndices[tokenAddress] = Indices.Index(true, uint248(_tokens.length));
    _tokens.push(IERC20(tokenAddress));
    emit TokenAdded(tokenAddress);
  }

  function _removeToken(address tokenAddress) internal {
    Indices.Index memory index = _tokenIndices[tokenAddress];
    require(index.exists, "ExeDAO: Token not found");
    delete _tokenIndices[tokenAddress];
    delete _tokens[index.index];
    emit TokenRemoved(tokenAddress);
  }

  function _approveTokenTransfer(address tokenAddress, address spender, uint256 amount) internal {
    IERC20 token = _getToken(tokenAddress);
    require(token.approve(spender, amount), "ExeDAO: Approve transfer failed");
  }

  function _receiveToken(address tokenAddress, address sender, uint256 amount) internal {
    IERC20 token = _getToken(tokenAddress);
    require(token.transferFrom(sender, address(this), amount), "exeDAO: transferFrom failed.");
    emit TokenReceived(tokenAddress, sender, amount);
  }

  function _transferToken(address tokenAddress, address recipient, uint256 amount) internal {
    IERC20 token = _getToken(tokenAddress);
    require(token.transfer(recipient, amount), "ExeDAO: Transfer failed");
    emit TokenTransferred(tokenAddress, recipient, amount);
  }
}

library Proposals {
  struct Proposal {
    bytes32 proposalHash;
    uint64 votes;
    uint64 expiryBlock;
    mapping(address => bool) voters;
  }

  struct ProposalOutput {
    bytes32 proposalHash;
    bytes32 metaHash;
    uint64 votes;
    uint64 expiryBlock;
    uint256 proposalIndex;
  }

  function votesRemaining (uint64 totalShares, uint64 votes, uint8 approvalRequirement)
  internal pure returns (uint64) {
    uint64 totalNeeded = totalShares * approvalRequirement / 100;
    if (votes >= totalNeeded) return 0;
    else return totalNeeded - votes;
  }
}

/**
 * @title PermissionedStorage
 * @author Dillon Kellar, Raymond Pulver
 * @dev Storage and getters for Permissioned.sol
 * @notice Makes the contract less cluttered by separating getters and storage setup into a separate contract.
 */
contract PermissionedStorage {
  uint64 internal _proposalDuration;
  Indices.Index internal _lastExpiredProposal;
  Proposals.Proposal[] internal _proposals;
  mapping(bytes32 => Indices.Index) internal _proposalIndices;
  mapping(bytes4 => uint8) internal _approvalRequirements;
  mapping(bytes32 => bytes32) internal _proposalMetaHashes;
  // mapping(address => mapping(uint256 => bool)) internal _offlineNonces;

  function getApprovalRequirement(bytes4 funcSig) external view returns (uint8 requirement) {
    requirement = _approvalRequirements[funcSig];
  }

  function getApprovalRequirements(bytes4[] calldata funcSigs) external view
  returns (uint8[] memory requirements) {
    uint256 size = funcSigs.length;
    requirements = new uint8[](size);
    for (uint256 i = 0; i < size; i++) requirements[i] = _approvalRequirements[funcSigs[i]];
  }

  /** @dev allows clients to retrieve index and proposal data in one call */
  function getProposal(bytes32 proposalHash) external view
  returns (Proposals.ProposalOutput memory ret) {
    Indices.Index memory index = _proposalIndices[proposalHash];
    require(index.exists, "ExeDAO: Proposal not found");
    Proposals.Proposal memory proposal = _proposals[index.index];
    ret = Proposals.ProposalOutput(
      proposalHash, _proposalMetaHashes[proposalHash],
      proposal.votes, proposal.expiryBlock, index.index
    );
  }

  function getOpenProposals() external view
  returns (Proposals.ProposalOutput[] memory proposals) {
    Indices.Index memory lastExpired = _lastExpiredProposal;
    uint256 startIndex = lastExpired.exists ? lastExpired.index + 1 : 0;
    uint256 size = _proposals.length - startIndex;
    proposals = new Proposals.ProposalOutput[](size);
    for (uint256 i = 0; i < size; i++) {
      uint256 index = startIndex + i;
      Proposals.Proposal memory proposal = _proposals[index];
      bytes32 proposalHash = proposal.proposalHash;
      proposals[i] = Proposals.ProposalOutput(
        proposalHash, _proposalMetaHashes[proposalHash],
        proposal.votes, proposal.expiryBlock, index
      );
    }
  }

  function getProposalMetaHash(bytes32 proposalHash)
  external view returns(bytes32 metaHash) {
    return _proposalMetaHashes[proposalHash];
  }
}

contract IPermissioned is IBaseDAO {
  function transferEther(address payable recipient, uint256 weiToSend) external;
  function getApprovalRequirement(bytes4 funcSig) external view returns (uint8 requirement);
  function getApprovalRequirements(bytes4[] calldata funcSigs) external view returns (uint8[] memory requirements);
  function getOpenProposals() external view returns (Proposals.ProposalOutput[] memory proposals);
  function getProposal(bytes32 proposalHash) external view returns (Proposals.ProposalOutput memory ret);
  function setProposalDuration(uint64 duration) external;
  function mintShares(address recipient, uint64 amount) external;
  function setApprovalRequirement(bytes4 funcSig, uint8 approvalRequirement) external;
  function submitOrVote(bytes32 proposalHash) external returns(uint, uint);
  function submitWithMetaHash(bytes32 proposalHash, bytes32 metaHash) external returns(uint256 index);
  function closeProposal(bytes32 proposalHash) external;
  /* function supplyOfflineVotesWithCall(
    bytes calldata wrappedCalldata,
    bytes[] calldata sigs,
    uint256[] calldata nonces,
    bytes32[] calldata proposalHashes
  ) external returns (bytes memory); */
  function addToken(address tokenAddress) external;
  function removeToken(address tokenAddress) external;
  function approveTokenTransfer(address tokenAddress, address spender, uint256 amount) external;
  function transferToken(address tokenAddress, address recipient, uint256 amount) external;
  function receiveToken(address tokenAddress, address sender, uint256 amount) external;
}

/**
 * @title Permissioned
 * @notice Generic contract for creating, cancelling and processing _proposals to execute functions.
 * @dev Approval requirements are set per function signature.
 */
contract Permissioned is IPermissioned, BaseDAO, PermissionedStorage {
  // using SignatureUnpack for bytes;

  event ProposalSubmission(address indexed submitter, bytes32 indexed proposalHash, bytes32 metaHash, uint64 votesCast);
  event ProposalVote(address indexed voter, bytes32 indexed proposalHash, uint64 votesCast);
  event ProposalApproval(address indexed voter, bytes32 indexed proposalHash);
  event ProposalExpiration(bytes32 indexed proposalHash);

  constructor(
    uint64 shares, uint64 proposalDuration,
    bytes4[] memory funcSigs, uint8[] memory requirements
  ) public payable BaseDAO(shares) {
    require(funcSigs.length == requirements.length, "Inconsistent inputs");
    for (uint256 i = 0; i < funcSigs.length; i++) {
      uint8 approvalRequirement = requirements[i];
      require(
        approvalRequirement < 101 || approvalRequirement == 255,
        "Can not set empty requirement"
      );
      _approvalRequirements[funcSigs[i]] = approvalRequirement;
    }
    _proposalDuration = proposalDuration;
  }

  function setProposalDuration(uint64 duration) external {
    if (_voteAndContinue()) _proposalDuration = duration;
  }

  function mintShares(address recipient, uint64 amount) external {
    if (_voteAndContinue()) _mintShares(recipient, amount);
  }

  function addToken(address tokenAddress) external {
    if (_voteAndContinue()) _addToken(tokenAddress);
  }

  function removeToken(address tokenAddress) external {
    if (_voteAndContinue()) _removeToken(tokenAddress);
  }

  function approveTokenTransfer(address tokenAddress, address spender, uint256 amount) external {
    if (_voteAndContinue()) _approveTokenTransfer(tokenAddress, spender, amount);
  }

  function transferToken(address tokenAddress, address recipient, uint256 amount) external {
    if (_voteAndContinue()) _transferToken(tokenAddress, recipient, amount);
  }

  function receiveToken(address tokenAddress, address sender, uint256 amount) external {
    if (_voteAndContinue()) _receiveToken(tokenAddress, sender, amount);
  }

  function transferEther(address payable recipient, uint256 weiToSend) external {
    if (_voteAndContinue()) recipient.transfer(weiToSend);
  }

  /**
   * @dev Set the requirement for execution of a function.
   * @param funcSig The signature of the function which approval is being set for.
   * funcSig can not be the signature for setApprovalRequirement.
   * @param approvalRequirement Percentage of shares which must be met for an approval to be accepted.
   * If approvalRequirement is 0, the function can not be called by anyone. If it is 255, it does not require approval.
   */
  function setApprovalRequirement(bytes4 funcSig, uint8 approvalRequirement) external {
    require(funcSig != msg.sig, "ExeDAO: Can not modify requirement for setApprovalRequirement");
    require(approvalRequirement < 101 || approvalRequirement == 255, "ExeDAO: Bad approvalRequirement");
    if (_voteAndContinue()) _approvalRequirements[funcSig] = approvalRequirement;
  }

  function submitOrVote(bytes32 proposalHash) external returns(uint, uint) {
    uint64 shares = _getShares();
    Indices.Index memory index = _proposalIndices[proposalHash];
    _submitOrVote(msg.sender, proposalHash, shares, index);
    Proposals.Proposal memory proposal = _proposals[index.index];
    return(proposal.votes, proposal.expiryBlock);
  }

  /**
   * @notice Create a proposal and set an ipfs hash for finding data about it.
   * @dev The calldata for a proposal can be uploaded to IPFS with keccak-sha256 as the hash algorithm.
   * For proposals to execute code or add extensions, it is useful to be able to share the raw code which compiles
   * to the contract bytecode for easy verification of what is being executed without needing to audit the bytecode.
   * For private proposals, the IPFS hash could point to ciphertext which only daoists can decrypt via some key exchange.
   */
  function submitWithMetaHash(bytes32 proposalHash, bytes32 metaHash) external returns(uint256 index) {
    uint64 shares = _getShares();
    Indices.Index memory _index = _proposalIndices[proposalHash];
    require(!_index.exists, "ExeDAO: Proposal already exists");
    index = _index.index;
    _submitOrVote(msg.sender, proposalHash, shares, _index);
    _proposalMetaHashes[proposalHash] = metaHash;
  }

  /** @dev Cancel a proposal if it has expired. */
  function closeProposal(bytes32 proposalHash) external {
    Indices.Index memory index = _proposalIndices[proposalHash];
    Proposals.Proposal memory proposal = _proposals[index.index];
    if (proposal.expiryBlock <= block.number) {
      delete _proposals[index.index];
      delete _proposalIndices[proposalHash];
      if (_proposalMetaHashes[proposalHash] != 0) delete _proposalMetaHashes[proposalHash];
      if (index.index > _lastExpiredProposal.index) _lastExpiredProposal = index;
      emit ProposalExpiration(proposalHash);
    }
  }

  /* function supplyOfflineVotesWithCall(
    bytes calldata wrappedCalldata,
    bytes[] calldata sigs,
    uint256[] calldata nonces,
    bytes32[] calldata proposalHashes
  ) external returns (bytes memory) {
    for (uint256 i = 0; i < sigs.length; i++) {
      address voter = sigs[i].recoverOffline(nonces[i], proposalHashes[i]);
      require(!_offlineNonces[voter][nonces[i]], "ExeDAO: Nonce already used");
      _offlineNonces[voter][nonces[i]] = true;
      DaoLib.DaoistOutput memory daoist = getDaoist(voter);
      require(daoist.shares > 0, "ExeDAO: Signature supplied from non-daoist");
      uint64 shares = daoist.shares;
      Indices.Index memory index = _proposalIndices[proposalHashes[i]];
      _submitOrVote(voter, proposalHashes[i], shares, index);
    }
    (, bytes memory retval) = address(this).delegatecall(wrappedCalldata);
    // if this call throws it doesn&#39;t matter, allow anyone to pay the gas to submit offline signatures even in the absence of valid calldata
    return retval;
  } */

  /**
   * @dev Call _submitOrVote() and return true if the proposal is approved, false if not.
   */
  function _voteAndContinue() internal returns (bool) {
    bytes32 proposalHash = keccak256(msg.data);
    (uint64 shares, Indices.Index memory index, bool approved) = _preProcessProposal(proposalHash);
    if (approved) {
      if (index.exists) {
        delete _proposals[index.index];
        delete _proposalIndices[proposalHash];
        if (_proposalMetaHashes[proposalHash] != 0) delete _proposalMetaHashes[proposalHash];
      }
      emit ProposalApproval(msg.sender, proposalHash);
    } else _submitOrVote(msg.sender, proposalHash, shares, index);
    return approved;
  }

  /**
   * @dev Determines whether a proposal would be accepted given the caller&#39;s votes.
   */
  function _preProcessProposal(bytes32 proposalHash) internal view
  returns (uint64 shares, Indices.Index memory index, bool approved) {
    uint8 approvalRequirement = _approvalRequirements[msg.sig];
    index = _proposalIndices[proposalHash];
    if (approvalRequirement == 255) return (0, index, true);
    shares = _getShares();
    uint64 totalNeeded = Proposals.votesRemaining(_totalShares, 0, approvalRequirement);
    if (!index.exists) approved = shares >= totalNeeded;
    else {
      uint64 votes = _proposals[index.index].votes;
      if (votes >= totalNeeded) approved = true;
      else approved = shares >= (totalNeeded - votes);
    }
  }

  /**
   * @dev Create a proposal if it does not exist, vote on it otherwise.
   */
  function _submitOrVote(address voter, bytes32 proposalHash, uint64 shares, Indices.Index memory index) internal {
    if (!index.exists) {
      Indices.Index memory _index = Indices.Index(true, uint248(_proposals.length));
      _proposalIndices[proposalHash] = _index;
      _proposals.push(Proposals.Proposal(proposalHash, shares, uint64(block.number + _proposalDuration)));
      _proposals[_index.index].voters[voter] = true;
      emit ProposalSubmission(voter, proposalHash, _proposalMetaHashes[proposalHash], shares);
    } else {
      Proposals.Proposal storage proposal = _proposals[index.index];
      require(proposal.expiryBlock > block.number, "ExeDAO: Proposal expired");
      if (!proposal.voters[voter]) {
        proposal.voters[voter] = true;
        proposal.votes = uint64(proposal.votes.add(shares));
        emit ProposalVote(voter, proposalHash, shares);
      }
    }
  }
}

library ExeLib {
  struct Extension {
    bytes32 metaHash; // used to share abi and function descriptions
    address extensionAddress;
    bool useDelegate;
    bytes bytecode;
    bytes4[] functionSignatures;
  }

  function isPermissible (bytes memory bytecode)
  internal pure returns (bool) {
    uint256 size = bytecode.length;
    uint256 permissible = 1;
    assembly {
      let ptr := add(bytecode, 0x20)
      for { let i := 0 } and(lt(i, size), permissible) { i := add(i, 0x1) } {
        let op := shr(0xf8, mload(add(ptr, i)))
        switch op
        case 0xf2 { permissible := 0 } // callcode
        case 0xf4 { permissible := 0 } // delegatecall
        case 0x55 { permissible := 0 } // sstore
        case 0xff { permissible := 0 } // selfdestruct
        default {
          let isPush := and(lt(op, 0x80), gt(op, 0x5f))
          if eq(isPush, 0x1) { i := add(i, sub(op, 0x5f)) }
        }
      }
    }
    return permissible == 1;
  }

  function deploy(bytes memory bytecode) internal returns (address extAddress) {
    uint256 size = bytecode.length;
    assembly {
      let start := add(bytecode, 0x20)
      extAddress := create(0, start, size)
    }
  }

  function delegateExecute(bytes memory bytecode) internal {
    uint256 size = bytecode.length;
    assembly {
      let retptr := mload(0x40)
      let start := add(bytecode, 0x20)
      let delegateTo := create(0, start, size)
      if iszero(delegateTo) {
        returndatacopy(retptr, 0, returndatasize)
        revert(retptr, returndatasize)
      }
      let delegateSuccess := delegatecall(gas, delegateTo, 0, 0, retptr, 0)
      returndatacopy(retptr, 0, returndatasize)
      if iszero(delegateSuccess) { revert(retptr, returndatasize) }
      return (retptr, returndatasize)
    }
  }

  function delegateExecute(address delegateTo) internal {
    assembly {
      let startCalldata := mload(0x40)
      calldatacopy(startCalldata, 0, calldatasize)
      let retptr := add(startCalldata, calldatasize)
      let delegateSuccess := delegatecall(gas, delegateTo, startCalldata, calldatasize, retptr, 0)
      returndatacopy(retptr, 0, returndatasize)
      if delegateSuccess { return (retptr, returndatasize) }
      revert(retptr, returndatasize)
    }
  }

  function doCall(address callAddress) internal {
    assembly {
      let startCalldata := mload(0x40)
      calldatacopy(startCalldata, 0, calldatasize)
      let retptr := add(startCalldata, calldatasize)
      let callSuccess := call(gas, callAddress, callvalue, startCalldata, calldatasize, retptr, 0)
      returndatacopy(retptr, 0, returndatasize)
      if callSuccess { return (retptr, returndatasize) }
      revert(retptr, returndatasize)
    }
  }
}

/**
 * @title ExtendableStorage
 * @author Dillon Kellar, Raymond Pulver
 * @dev Storage and getters for Extendable.sol
 * @notice Makes the contract less cluttered by separating getters and storage setup into a separate contract.
 */
contract ExtendableStorage {
  using ExeLib for address;
  using ExeLib for bytes;

  ExeLib.Extension[] internal _extensions;
  mapping(bytes4 => Indices.Index) internal _extensionFor;

  function getExtension(uint256 index) external view returns (ExeLib.Extension memory) {
    return _extensions[index];
  }

  function getExtensions() external view
  returns (ExeLib.Extension[] memory) { return _extensions; }

  function getExtensionFor(bytes4 funcSig) external view
  returns (ExeLib.Extension memory extension) {
    Indices.Index memory index = _extensionFor[funcSig];
    require(index.exists, "ExeDAO: Extension not found");
    return _extensions[index.index];
  }
}

contract IExtendable is IPermissioned {
  function getExtension(uint256 index) external view returns (ExeLib.Extension memory);
  function getExtensionFor(bytes4 funcSig) external view returns (ExeLib.Extension memory extension);
  function getExtensions() external view returns (ExeLib.Extension[] memory);
  function removeExtension(uint256 extIndex) external;
  function addExtension(ExeLib.Extension memory extension) public;
}

contract Extendable is IExtendable, Permissioned, ExtendableStorage {
  event ExtensionAdded(uint256 extensionIndex, bytes32 metaHash);

  constructor(
    uint64 shares, uint64 _proposalDuration,
    bytes4[] memory funcSigs, uint8[] memory requirements
  ) public payable Permissioned(shares, _proposalDuration, funcSigs, requirements) {}

  function () external payable {
    Indices.Index memory index = _extensionFor[msg.sig];
    if (index.exists) {
      if (_voteAndContinue()) {
        ExeLib.Extension memory extension = _extensions[index.index];
        if (extension.useDelegate) extension.extensionAddress.delegateExecute();
        else extension.extensionAddress.doCall();
      }
    }
  }

  function removeExtension(uint256 extIndex) external {
    if (_voteAndContinue()) {
      ExeLib.Extension memory ext = _extensions[extIndex];
      for (uint256 i = 0; i < ext.functionSignatures.length; i++) {
        bytes4 funcSig = ext.functionSignatures[i];
        delete _extensionFor[funcSig];
        if (_approvalRequirements[funcSig] != 0) delete _approvalRequirements[funcSig];
      }
      delete _extensions[extIndex];
    }
  }

  function addExtension(ExeLib.Extension memory extension) public {
    if (extension.useDelegate) require(
      extension.bytecode.length > 0 && extension.bytecode.isPermissible(),
      "ExeDAO: Bytecode not allowed"
    );
    if (_voteAndContinue()) {
      if (extension.useDelegate) {
        extension.extensionAddress = extension.bytecode.deploy();
        delete extension.bytecode;
      }
      uint256 index = _extensions.length;
      _extensions.push(extension);
      bytes4[] memory funcSigs = extension.functionSignatures;
      for (uint256 i = 0; i < funcSigs.length; i++) {
        require(!_extensionFor[funcSigs[i]].exists, "ExeDAO: Approval already set for function");
        _extensionFor[funcSigs[i]] = Indices.Index(true, uint248(index));
      }
      emit ExtensionAdded(index, extension.metaHash);
    }
  }
}

contract ExeDAOStorage {
  uint256 internal _minimumTribute;
  Indices.Index internal _lastExpiredApplication;
  DaoLib.Application[] internal _applications;
  mapping(address => Indices.Index) internal _applicationIndices;

  function getMinimumTribute() external view returns (uint256 minimum) {
    minimum = _minimumTribute;
  }

  function getApplication(address applicant) external view
  returns (DaoLib.Application memory application) {
    Indices.Index memory index = _applicationIndices[applicant];
    require(index.exists, "ExeDAO: Application not found");
    return _applications[index.index];
  }

  function getOpenApplications() external view
  returns (DaoLib.Application[] memory applications) {
    Indices.Index memory lastExpired = _lastExpiredApplication;
    uint256 startIndex = lastExpired.exists ? lastExpired.index + 1 : 0;
    uint256 size = _applications.length - startIndex;
    applications = new DaoLib.Application[](size);
    for (uint256 i = 0; i < size; i++) {
      uint256 index = startIndex + i;
      applications[i] = _applications[index];
    }
  }
}

contract IExeDAO is IExtendable {
  function getApplication(address applicant) external view returns (DaoLib.Application memory application);
  function getOpenApplications() external view returns (DaoLib.Application[] memory applications);
  function getMinimumTribute() external view returns (uint256 minimum);
  function setMinimumTribute(uint256 minimum) external;
  function safeExecute(bytes calldata bytecode) external;
  function submitApplication(bytes32 metaHash, uint64 shares, DaoLib.TokenValue[] calldata tokenTributes) external payable;
  function executeApplication(address applicant) external;
}

contract ExeDAO is IExeDAO, Extendable, ExeDAOStorage {
  event ApplicationAdded(address applicant, uint64 shares);
  event ApplicationCanceled(address applicant);

  constructor(
    uint64 shares, uint64 _proposalDuration,
    bytes4[] memory funcSigs, uint8[] memory requirements
  ) public payable Extendable(shares, _proposalDuration, funcSigs, requirements) {}

  function setMinimumTribute(uint256 minimum) external {
    if (_voteAndContinue()) _minimumTribute = minimum;
  }

  function safeExecute(bytes calldata bytecode) external {
    require(bytecode.isPermissible(), "ExeDAO: Bytecode not allowed");
    if (_voteAndContinue()) bytecode.delegateExecute();
  }

  /**
   * @dev Apply to join the DAO and lock some wei/tokens.
   */
  function submitApplication(bytes32 metaHash, uint64 shares, DaoLib.TokenValue[] calldata tokenTributes) external payable {
    require(!_daoistIndices[msg.sender].exists, "ExeDAO: Already a daoist");
    Indices.Index memory index = _applicationIndices[msg.sender];
    require(!index.exists, "ExeDAO: Application pending");
    require(shares > 0, "ExeDAO: Can not apply for 0 shares");
    require(msg.value >= _minimumTribute, "ExeDAO: Insufficient wei tribute for application");
    uint256 tokenCount = tokenTributes.length;
    address[] memory lockedTokens = new address[](tokenCount);
    uint256[] memory lockedTokenValues = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      DaoLib.TokenValue memory tokenTribute = tokenTributes[i];
      _receiveToken(tokenTribute.tokenAddress, msg.sender, tokenTribute.value);
      lockedTokens[i] = tokenTribute.tokenAddress;
      lockedTokenValues[i] = tokenTribute.value;
    }
    DaoLib.Application memory application = DaoLib.Application(metaHash, msg.value, msg.sender, lockedTokens, lockedTokenValues, shares);
    index = Indices.Index(true, uint248(_applications.length));
    _applicationIndices[msg.sender] = index;
    _applications.push(application);
    emit ApplicationAdded(msg.sender, shares);
  }

  /**
   * @dev For buyer, cancel the offer and reclaim wei if a proposal has not been
   * started by a daoist or has expired. For daoists, vote to accept the offer.
   */
  function executeApplication(address applicant) external {
    Indices.Index memory index = _applicationIndices[applicant];
    require(index.exists, "ExeDAO: Application not found");
    DaoLib.Application memory application = _applications[index.index];
    if (msg.sender == applicant) {
      Indices.Index memory proposalIndex = _proposalIndices[keccak256(msg.data)];
      if (proposalIndex.exists) {
        require(
          block.number >= _proposals[index.index].expiryBlock,
          "ExeDAO: Must wait for proposal to finish"
        );
        if (index.index > _lastExpiredApplication.index) _lastExpiredApplication = index;
      }
      delete _applications[index.index];
      delete _applicationIndices[applicant];
      emit ApplicationCanceled(applicant);
      msg.sender.transfer(application.weiTribute);
      for (uint256 i = 0; i < application.tokenTributes.length; i++) {
        _transferToken(application.tokenTributes[i], msg.sender, application.tokenTributeValues[i]);
      }
    }
    else if (_voteAndContinue()) {
      delete _applications[index.index];
      delete _applicationIndices[applicant];
      _mintShares(applicant, application.shares);
    }
  }
}