// SPDX-License-Identifier: MIT
// VERSION: 20211124B
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import './IDividendToken.sol';
import "./IFSCToken.sol";


// once a contentBond is challenged, the bonder can no longer withdraw his contentBond, until the end of the adjudication.


contract FSCAdjudicator is AccessControl, VRFConsumerBase {

  event QuorumUpdated(uint16 oldPoolSize, uint16 oldQuorum, uint16 newPoolSize, uint16 newQuorum);
  event FreeSpeechBiasUpdated(uint256  oldFreeSpeechBiasPct, uint256  newFreeSpeechBiasPct);
  event RandMaintenanceFeeUpdated(uint256   oldRandMaintenanceFee,  uint256 newRandMaintenanceFee);
  event SwarmMaintenanceFeeUpdated(uint256  oldSwarmMaintenanceFee, uint256 newSwarmMaintenanceFee);
  event AllowReadjudicationUpdated(bool oldAllowReadjudication, bool newAllowReadjudication);
  event AdjudicationAmountsUpdated(uint256 oldContentBondAmount, uint256 oldChallengeBondAmount, uint256 oldVindicationAward,  uint256 oldChallengeAward,
				   uint256 oldVoteWagerAmount,   uint256 oldVoteAward, uint256 oldVoteLotteryAward,
				   uint256 newContentBondAmount, uint256 newChallengeBondAmount, uint256 newVindicationAward,  uint256 newChallengeAward,
				   uint256 newVoteWagerAmount,   uint256 newVoteAward, uint256 newVoteLotteryAward);

  // Manager can collect swarm and link fees
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
  bytes32 public constant MANAGER_ADMIN_ROLE = keccak256("MANAGER_ADMIN_ROLE");
  // FSD Governor (DAO) may modify operating parameters
  bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
  bytes32 public constant GOVERNOR_ADMIN_ROLE = keccak256("GOVERNOR_ADMIN_ROLE");

  uint8   public constant NOT_BONDED              = 0x00;
  uint8   public constant PROVISIONALLY_BONDED    = 0x01;
  uint8   public constant IS_BONDED               = 0x02;

  uint8   public constant VERDICT_UNADJUDICATED   = 0x00;
  uint8   public constant VERDICT_CHALLENGED      = 0x01;
  uint8   public constant VERDICT_PENDING         = 0x02;
  uint8   public constant VERDICT_FREE_SPEECH     = 0x03;
  uint8   public constant VERDICT_NOT_FREE_SPEECH = 0x04;


  // default values assume 100 voters
  // swarmMaintenanceFee is to pay for BZZ; it is paid either the first time content is bonded, or when unbonded content is challenged.
  // since it may be paid irrespective of any adjudication, it is not included in contentBondAmount or challengeBondAmount.
  // randMaintenanceFee is to pay for LINK. it is deducted when adjudication is initiated
  // adjudication cost (is free speech):  100 * 0.2 + 10 + 10 + 0.1 + = 40.1 ether
  // adjudication cost (not free speech): 100 * 0.2 + 10 + 25 + 0.1 + = 55.1 ether
  // dividend: 4.9 ether
  uint256 public contentBondAmount   = 60 ether;
  uint256 public challengeBondAmount = 45 ether;
  uint256 public vindicationAward    = 10 ether;
  uint256 public challengeAward      = 25 ether;
  uint256 public randMaintenanceFee  = (100 * 10**6) * 1 gwei;
  uint256 public swarmMaintenanceFee = (100 * 10**6) * 1 gwei;
  uint256 public voteWagerAmount     = (200 * 10**6) * 1 gwei;
  uint256 public voteAward           = (200 * 10**6) * 1 gwei;
  uint256 public voteLotteryAward    = 10 ether;
  uint256 public freeSpeechBiasPct   = 80;
  uint16  public juryPoolSize        = 200;
  uint16  public juryQuorum          = 100;
  bool    public allowReadjudication = false;
  // interface to VRF
  uint256 public linkFee = (100 * 10**6) * 1 gwei;
  bytes32 public linkKeyHash;

  mapping (address => uint256) public contentBonds;
  mapping (address => uint256) public contentBondsInAdjudication;
  mapping (uint256 => Content) public contents;
  mapping (address => Bonder)  public bonders;
  IFSCToken      public immutable fscToken;
  IDividendToken public immutable dividendToken;
  uint256        public accumulatedDividends;
  uint256        public accumulatedFees;

  // this is to recover contentHash from a VRF request ID
  mapping (bytes32 => uint256) public vrfReqIdToContent;

  struct Bonder {
    uint256 freeBondAmount;
    uint256 inAdjudicationAmount;
  }
  struct ContentBond {
    address nextAddr;
    address prevAddr;
    address bonderAddr;
  }
  struct Juror {
    uint8 vote;
    uint16 idx;
    uint256 wagerAmount;
    uint256 voteBlock;
  }
  struct Content {
    uint8   verdict;
    uint16  isFreeVoteCount;
    uint16  notFreeVoteCount;
    uint16  lotterySelector;
    address lastBonderAddr;
    address firstBonderAddr;
    address activeBonderAddr;
    address challenger;
    uint256 juryKey;
    uint256 contentHash;
    uint256 challengeBlock;
    uint256 holdoverAmount;
    mapping (address => Juror) jurors;
    mapping (address => ContentBond) contentBonds;
  }


  // after construction, set the governor role to the (timelock) governor contract.
  // eventually it should be possible to revoke the GOVERNOR_ADMIN_ROLE, and finally
  // the DEFAULT_ADMIN_ROLE.
  constructor(address _fscTokenAddr, address dividendTokenAddr, address vrfCoordinatorAddr, address linkTokenAddr, bytes32 _linkKeyHash)
    VRFConsumerBase(vrfCoordinatorAddr, linkTokenAddr)
  {
    linkKeyHash = _linkKeyHash;
    fscToken = IFSCToken(_fscTokenAddr);
    dividendToken = IDividendToken(dividendTokenAddr);
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MANAGER_ADMIN_ROLE, _msgSender());
    _setupRole(GOVERNOR_ADMIN_ROLE, _msgSender());
    _setRoleAdmin(MANAGER_ROLE, MANAGER_ADMIN_ROLE);
    _setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ADMIN_ROLE);
  }


  // provisionally-bonded content has one or more bonders who have bonds that are currently in adjudication
  // (presumably for other content). in that case isBonded is set to PROVISIONALLY_BONDED, and bonderAddr is zero.
  function isContentBonded(uint256 contentHash)
    external
    view
    returns(address bonderAddr, uint8 isBonded)
  {
    Content storage _content = contents[contentHash];
    bonderAddr = _content.firstBonderAddr;
    while (bonderAddr != address(0)) {
      Bonder storage _bonder = bonders[bonderAddr];
      if (_bonder.freeBondAmount >= contentBondAmount) {
	isBonded = IS_BONDED;
	break;
      }
      if (_bonder.inAdjudicationAmount >= contentBondAmount)
	isBonded = PROVISIONALLY_BONDED;
      ContentBond storage _contentBond = _content.contentBonds[bonderAddr];
      bonderAddr = _contentBond.nextAddr;
    }
  }

  function isContentChallenged(uint256 contentHash)
    external
    view
    returns(bool isChallenged)
  {
    Content storage _content = contents[contentHash];
    isChallenged = _content.challenger != address(0);
  }

  function getContentVerdict(uint256 contentHash)
    external
    view
    returns(uint8 verdict)
  {
    Content storage _content = contents[contentHash];
    verdict = _content.verdict;
  }


  // a bonder can increase his bond amount here, without committing it to any specific content,
  function _postBond(Bonder memory _bonder, uint256 amount)
    internal
  {
    require(fscToken.transferFrom(msg.sender, address(this), amount), "failed to xfer bond");
    _bonder.freeBondAmount += amount;
  }

  // a bonder can increase his bond amount here, without committing it to any specific content,
  function postBond(uint256 amount)
    public
  {
    Bonder storage _bonder = bonders[msg.sender];
    _postBond(_bonder, amount);
  }

  // a bonder can commit his bond amount to the specified content, and optionally increase his bond amount
  // here. a single content can be bonded by multiple bonders, organized in a liked list which is unique to
  // each content.
  // note: swarm maintenance fee is due the first time content is specified; paid in addition to contentBondAmount
  function postContentBond(uint256 contentHash, uint256 amount)
    public
  {
    Content storage _content = contents[contentHash];
    Bonder storage _bonder = bonders[msg.sender];
    _postBond(_bonder, amount);
    // iff this is the first bonder, then deduct maintenance fee for posting to SWARM
    if (_content.firstBonderAddr == address(0)) {
      _bonder.freeBondAmount -= swarmMaintenanceFee;
      accumulatedFees += swarmMaintenanceFee;
    }
    require(_bonder.freeBondAmount + _bonder.inAdjudicationAmount >= contentBondAmount, "insufficient bond amount");
    ContentBond storage _contentBond = _content.contentBonds[msg.sender];
    if (_contentBond.bonderAddr == address(0)) {
      // new bonder for this content. link him to the current end of the list
      _contentBond.bonderAddr = msg.sender;
      address _prevAddr = _content.lastBonderAddr;
      if (_prevAddr != address(0)) {
	ContentBond storage _prevContentBond = _content.contentBonds[_prevAddr];
	_prevContentBond.nextAddr = msg.sender;
	_contentBond.prevAddr = _prevAddr;
      }
      // and since this guy is new, he's now at the end of the list
      _content.lastBonderAddr = msg.sender;
      // iff this is the first bonder, then he goes to the front of the list
      if (_content.firstBonderAddr == address(0))
	_content.firstBonderAddr = msg.sender;
    }
  }

  // same as postBond, but approval provided via draft-IERC20Permit
  function postBondAuthorized(uint256 amount,
			      uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    external
  {
    fscToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
    postBond(amount);
  }

  // same as postContentBond, but approval provided via draft-IERC20Permit
  function postContentBondAuthorized(uint256 contentHash, uint256 amount,
				     uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    external
  {
    fscToken.permit(msg.sender, address(this), amount, deadline, v, r, s);
    postContentBond(contentHash, amount);
  }

  // a bonder can decrease his bond amount here, or can un-commit his bond amount to the specified content,
  // or both simultaniously. note that if contentHash is zero, and a bonder decreases his bond amount to zero,
  // then that bonder remains in the content's linked list.
  function withdrawContentBond(uint256 contentHash, uint256 amount)
    external
  {
    Bonder storage _bonder = bonders[msg.sender];
    if (contentHash != 0) {
      Content storage _content = contents[contentHash];
      ContentBond storage _contentBond = _content.contentBonds[msg.sender];
      if (_contentBond.bonderAddr != address(0)) {
	// remove this bonder from the linked list
	address _prevAddr = _contentBond.prevAddr;
	address _nextAddr = _contentBond.nextAddr;
	if (_prevAddr != address(0)) {
	  ContentBond storage _prevContentBond = _content.contentBonds[_prevAddr];
	  _prevContentBond.nextAddr = _nextAddr;
	}
	if (_nextAddr != address(0)) {
	  ContentBond storage _nextContentBond = _content.contentBonds[_nextAddr];
	  _nextContentBond.prevAddr = _prevAddr;
	}
	// invalidate this contentBond
	_contentBond.bonderAddr = address(0);
      }
    }
    if (amount > 0) {
      // throws on underflow
      _bonder.freeBondAmount -= amount;
      require(fscToken.transfer(msg.sender, amount), "failed to xfer bond");
    }
  }


  // post a challenge-bond against the specified content bond
  // a prospective challenger can discover the bonderAddr by calling the view fcn isContentBonded. if bonderAddr is
  // zero, then initiate a challenge w/o a bonder. in that case the challenger will never get a reward.
  // note: if posting a challenge to unbonded content, then bond must be increased to pay swarm fees
  function postChallengeBond(uint256 contentHash, address bonderAddr)
    public
  {
    Content storage _content = contents[contentHash];
    if (_content.verdict == VERDICT_NOT_FREE_SPEECH && allowReadjudication) {
      _content.activeBonderAddr = _content.challenger = address(0);
      _content.isFreeVoteCount = _content.notFreeVoteCount = 0;
      _content.verdict == VERDICT_UNADJUDICATED;
    } else {
      require(_content.verdict == VERDICT_UNADJUDICATED, "content already adjudicated");
      require(_content.challenger == address(0), "content is already challenged");
    }
    uint256 _xferAmount = challengeBondAmount;
    if (bonderAddr == address(0)) {
      // direct call for adjudication; if unbonded content. pay swarm fees
      if (_content.firstBonderAddr == address(0)) {
	accumulatedFees += swarmMaintenanceFee;
	_xferAmount += swarmMaintenanceFee;
      }
    } else {
      ContentBond storage _contentBond = _content.contentBonds[bonderAddr];
      require(_contentBond.bonderAddr == bonderAddr, "incorrect bonder");
      Bonder storage _bonder = bonders[bonderAddr];
      // throw on underflow
      _bonder.freeBondAmount -= contentBondAmount;
      _bonder.inAdjudicationAmount += contentBondAmount;
      _content.activeBonderAddr = bonderAddr;
    }
    require(fscToken.transferFrom(msg.sender, address(this), _xferAmount), "failed to xfer bond");
    accumulatedFees += randMaintenanceFee;
    _content.holdoverAmount += (challengeBondAmount - randMaintenanceFee);
    _content.challenger = msg.sender;
    _content.challengeBlock = block.number;
    _content.verdict = VERDICT_CHALLENGED;
    // fulfillRandomness will initiate the adjudication
    bytes32 _requestId = getRandomNumber();
    vrfReqIdToContent[_requestId] = contentHash;
  }

  // same as postContentBond, but approval provided via draft-IERC20Permit
  function postChallengeBondAuthorized(uint256 contentHash, address bonderAddr,
				       uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    external
  {
    fscToken.permit(msg.sender, address(this), challengeBondAmount, deadline, v, r, s);
    postChallengeBond(contentHash, bonderAddr);
  }


  // called from VRF fulfillRandomness
  function _initiateAdjudication(Content storage content, uint256 randomness)
    internal
  {
    fscToken.calcJuryParms(content.contentHash, randomness, juryPoolSize);
    // jury is now in deliberation!
    content.verdict = VERDICT_PENDING;
  }


  function vote(uint256 contentHash, address jurorAddr, uint8 jurorVote)
    external
  {
    Content storage _content = contents[contentHash];
    Juror storage _juror = _content.jurors[msg.sender];
    require(_content.verdict == VERDICT_PENDING, "adjudication not in progress");
    require(_juror.vote == VERDICT_UNADJUDICATED || _juror.voteBlock < _content.challengeBlock, "already voted");
    require(jurorVote == VERDICT_FREE_SPEECH || jurorVote == VERDICT_NOT_FREE_SPEECH, "invalid vote");
    require(fscToken.isSelectedForJury(contentHash, jurorAddr), "not eligible to vote");
    require(fscToken.transferFrom(jurorAddr, address(this), voteWagerAmount), "failed to xfer vote wager");
    _content.holdoverAmount += voteWagerAmount;
    _juror.vote = jurorVote;
    _juror.voteBlock = block.number;
    if (jurorVote == VERDICT_FREE_SPEECH)
      _juror.idx = _content.isFreeVoteCount++;
    else
      _juror.idx = _content.notFreeVoteCount++;
    if (_content.isFreeVoteCount + _content.notFreeVoteCount >= juryQuorum)
      _setFreeSpeechProtected(contentHash);
  }


  function _setFreeSpeechProtected(uint256 contentHash)
    internal
  {
    uint256 _voterRewardReserve = 0;
    Content storage _content = contents[contentHash];
    _content.verdict = ((uint256)(_content.notFreeVoteCount) * 100 / juryQuorum > freeSpeechBiasPct) ? VERDICT_NOT_FREE_SPEECH : VERDICT_FREE_SPEECH;
    if (_content.verdict == VERDICT_FREE_SPEECH) {
      if (_content.activeBonderAddr != address(0)) {
	_content.holdoverAmount -= vindicationAward;
	require(fscToken.transfer(_content.activeBonderAddr, vindicationAward), "failed to xfer vindication award");
	Bonder storage _bonder = bonders[_content.activeBonderAddr];
	_bonder.inAdjudicationAmount -= contentBondAmount;
	_bonder.freeBondAmount += contentBondAmount;
	_voterRewardReserve += _content.isFreeVoteCount * (voteWagerAmount + voteAward);
	if (_content.isFreeVoteCount == 0)
	  _content.lotterySelector = 0xffff;
      }
    } else {
      if (_content.activeBonderAddr != address(0)) {
	Bonder storage _bonder = bonders[_content.activeBonderAddr];
	_bonder.inAdjudicationAmount -= contentBondAmount;
	_content.holdoverAmount	+= contentBondAmount;
	uint256 _challengerAmount = challengeBondAmount + challengeAward;
	require(fscToken.transfer(_content.challenger, _challengerAmount), "failed to xfer challenger award");
	_content.holdoverAmount -= _challengerAmount;
	_voterRewardReserve += _content.notFreeVoteCount * (voteWagerAmount + voteAward);
	if (_content.notFreeVoteCount == 0)
	  _content.lotterySelector = 0xffff;
      }
    }
    // if we need to award a lottery prize
    if (_content.lotterySelector == 0) {
      bytes32 _requestId = getRandomNumber();
      vrfReqIdToContent[_requestId] = contentHash;
      _voterRewardReserve += voteLotteryAward;
    }
    uint256 _dividendAmount = _content.holdoverAmount - _voterRewardReserve;
    accumulatedDividends += _dividendAmount;

  }


  // called from VRF fulfillRandomness
  function _awardLotteryPrize(Content storage content, uint256 randomness)
    internal
  {
    // verdict is in. just need to select the lucky lottery winner
    uint256 lotterySize = (content.verdict == VERDICT_FREE_SPEECH) ? content.isFreeVoteCount : content.notFreeVoteCount;
    content.lotterySelector = (uint16)(randomness % lotterySize) + 1;
  }


  function claimJurorAward(uint256 contentHash)
    external
  {
    Content storage _content = contents[contentHash];
    require(_content.verdict == VERDICT_FREE_SPEECH || _content.verdict == VERDICT_NOT_FREE_SPEECH, "no verdict");
    require(_content.lotterySelector != 0, "wait for lottery result");
    Juror storage _juror = _content.jurors[msg.sender];
    require(_juror.vote == _content.verdict, "no reward");
    uint256 _amount = voteWagerAmount + voteAward;
    if (_juror.idx + 1 == _content.lotterySelector)
      _amount += voteLotteryAward;
    require(fscToken.transfer(msg.sender, _amount), "failed to xfer juror award");
    _content.holdoverAmount -= _amount;
    // prevent duplicate claim
    _juror.vote = VERDICT_UNADJUDICATED;
  }


  // withdraw maintenance fees
  function withdrawFees()
    external
    onlyRole(MANAGER_ROLE)
  {
    uint _feeAmount = accumulatedFees;
    accumulatedFees = 0;
    require(fscToken.transfer(msg.sender, _feeAmount), "failed to xfer fees");
  }

  // withdraw dividends to the dividend contract
  // anyone can call this
  function withdrawDividends()
    external
  {
    uint _dividendAmount = accumulatedDividends;
    accumulatedDividends = 0;
    require(fscToken.approve(address(dividendToken), _dividendAmount), "failed to xfer dividends");
    dividendToken.payDividend(_dividendAmount);
  }


  // --------------------------------------------------------------------------------------------------------
  // VRF functions
  // --------------------------------------------------------------------------------------------------------
  // Request randomness from VRF Coordinator
  function getRandomNumber()
    public
    returns (bytes32 requestId)
  {
    require(LINK.balanceOf(address(this)) >= linkFee, "Not enough LINK");
    return requestRandomness(linkKeyHash, linkFee);
  }


  // Callback function used by VRF Coordinator
  // note: max 200k gas
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal
    override
  {
    uint256 _contentHash = vrfReqIdToContent[requestId];
    Content storage _content = contents[_contentHash];
    if (_content.verdict == VERDICT_CHALLENGED) {
      _initiateAdjudication(_content, randomness);
    } else {
      _awardLotteryPrize(_content, randomness);
    }
  }


  // --------------------------------------------------------------------------------------------------------
  // parameters that can be set via FSD DAO
  // --------------------------------------------------------------------------------------------------------
  function setFSCQuorum(uint16 newJuryPoolSize, uint16 newJuryQuorum)
    public
    onlyRole(GOVERNOR_ROLE)
  {
    emit QuorumUpdated(juryPoolSize, newJuryPoolSize, juryQuorum, newJuryQuorum);
    juryPoolSize = newJuryPoolSize;
    juryQuorum = newJuryQuorum;
  }

  function setFreeSpeechBias(uint256 _freeSpeechBiasPct) public onlyRole(GOVERNOR_ROLE) {
    emit FreeSpeechBiasUpdated(freeSpeechBiasPct, _freeSpeechBiasPct);
    freeSpeechBiasPct = _freeSpeechBiasPct;
  }

  function setRandMaintenanceFee(uint256 _randMaintenanceFee) public onlyRole(GOVERNOR_ROLE) {
    emit RandMaintenanceFeeUpdated(randMaintenanceFee, _randMaintenanceFee);
    randMaintenanceFee = _randMaintenanceFee;
  }

  function setSwarmMaintenanceFee(uint256 _swarmMaintenanceFee) public onlyRole(GOVERNOR_ROLE) {
    emit SwarmMaintenanceFeeUpdated(swarmMaintenanceFee, _swarmMaintenanceFee);
    swarmMaintenanceFee = _swarmMaintenanceFee;
  }

  function setAllowReadjudication(bool _allowReadjudication) public onlyRole(GOVERNOR_ROLE) {
    emit AllowReadjudicationUpdated(allowReadjudication, _allowReadjudication);
    allowReadjudication = _allowReadjudication;
  }

  function setAdjudicationAmounts(uint256 _contentBondAmount, uint256 _challengeBondAmount, uint256 _vindicationAward,  uint256 _challengeAward,
				  uint256 _voteWagerAmount,   uint256 _voteAward, uint256 _voteLotteryAward) public onlyRole(GOVERNOR_ROLE) {
    emit AdjudicationAmountsUpdated(contentBondAmount,  challengeBondAmount, vindicationAward,   challengeAward,
				    voteWagerAmount,    voteAward, voteLotteryAward,
				    _contentBondAmount, _challengeBondAmount, _vindicationAward,  _challengeAward,
				    _voteWagerAmount,   _voteAward, _voteLotteryAward);
    contentBondAmount   = _contentBondAmount;
    challengeBondAmount = _challengeBondAmount;
    vindicationAward    = _vindicationAward;
    challengeAward      = _challengeAward;
    voteWagerAmount     = _voteWagerAmount;
    voteAward           = _voteAward;
    voteLotteryAward    = _voteLotteryAward;
  }

  function setLinkFee(uint256 fee) public onlyRole(GOVERNOR_ROLE) {
    linkFee = fee;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// contracts/IDividendToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interface for token that accepts dividends
interface IDividendToken {
  function payDividend(uint256 amount) external;
  function withdrawDividend() external returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
// VERSION: 20211124A
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

interface IFSCToken is IERC20, IERC20Permit {

  // set internal parameters for tracking which token-holders are selected for a jury vote
  function calcJuryParms(uint256 juryId, uint256 juryKey, uint256 juryPoolSize) external;

  // is this address selected for jury duty
  function isSelectedForJury(uint256 juryId, address jurorAddr) external view returns(bool isSelected);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}