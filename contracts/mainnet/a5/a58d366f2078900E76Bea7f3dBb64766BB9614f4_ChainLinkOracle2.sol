/**
 *Submitted for verification at Etherscan.io on 2021-03-20
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;


interface ITrollbox {
    function withdrawWinnings(uint voterId) external;
    function updateAccount(uint voterId, uint tournamentId, uint roundId) external;
    function isSynced(uint voterId, uint tournamentId, uint roundId) external view returns (bool);
    function roundAlreadyResolved(uint tournamentId, uint roundId) external view returns (bool);
    function resolveRound(uint tournamentId, uint roundId, uint winningOption) external;
    function getCurrentRoundId(uint tournamentId) external view returns (uint);
}


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface KeeperCompatibleInterface {

  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );
  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

contract ChainLinkOracle2 is KeeperCompatibleInterface {

    struct Proposal {
        uint id;
        uint time;
        bool confirmed;
        uint roundId;
        uint winnerIndex;
        uint challengeWinnerIndex;
        address challenger;
        bytes32 challengeEvidence;
        bytes32 confirmationEvidence;
    }

    mapping (bytes32 => address) public feedMap; // ticker symbol => price aggregator address
    mapping (bytes32 => int) public prices; // symbol => price
    mapping (uint => Proposal) public proposals;

    address public management;
    ITrollbox public trollbox;
    IERC20 public token;

    int constant public PRECISION = 1000000;
    uint public numProposals = 0;
    uint public challengeDeposit = 0;
    uint public challengePeriodSeconds = 60 * 60 * 24;
    uint public tournamentId = 1;
    uint public startingRoundId = 0;

    bytes32[] public tickerSymbols;

    // mgmt events
    event FeedUpdated(bytes32 indexed key, address indexed feedAddr);
    event ManagementUpdated(address oldManagement, address newManagement);
    event DepositUpdated(uint oldDeposit, uint newDeposit);
    event ChallengePeriodUpdated(uint oldPeriod, uint newPeriod);
    event TickerSymbolsUpdated(bytes32[] oldKeys, bytes32[] newKeys, int[] newPrices);

    // winner events
    event WinnerProposed(uint indexed roundId, uint indexed proposalId, uint winnerIndex, int[] prices);
    event WinnerConfirmed(uint indexed roundId, uint indexed proposalId, int[] prices);

    // challenger events
    event ChallengeMade(uint indexed proposalId, address indexed challenger, uint indexed claimedWinner, bytes32 evidence);
    event ChallengerSlashed(uint indexed proposalId, address indexed challenger, uint indexed slashAmount, bytes32 evidence);
    event ChallengerVindicated(uint indexed proposalId, address indexed challenger, bytes32 evidence);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    modifier latestProposalConfirmed() {
        require (proposals[numProposals].confirmed == true || numProposals == 0, 'Unconfirmed proposal present');
        _;
    }

    constructor(address mgmt, address trollboxAddr, address tokenAddr, uint tournament, uint roundId, bytes32[] memory initialSymbols, int[] memory initialPrices) {
        management = mgmt;
        trollbox = ITrollbox(trollboxAddr);
        token = IERC20(tokenAddr);
        tournamentId = tournament;
        startingRoundId = roundId;
        tickerSymbols = initialSymbols;
        setPricesInternal(initialPrices);
    }

    function setManagement(address newMgmt) public managementOnly {
        address oldMgmt = management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    function setChallengeDeposit(uint newDeposit) public managementOnly latestProposalConfirmed {
        uint oldDeposit = challengeDeposit;
        challengeDeposit = newDeposit;
        emit DepositUpdated(oldDeposit, newDeposit);
    }

    function setChallengePeriod(uint newPeriod) public managementOnly latestProposalConfirmed {
        uint oldPeriod = challengePeriodSeconds;
        challengePeriodSeconds = newPeriod;
        emit ChallengePeriodUpdated(oldPeriod, newPeriod);
    }

    function setPricesInternal(int[] memory newPrices) internal {
        for (uint i = 0; i < tickerSymbols.length; i++) {
            prices[tickerSymbols[i]] = newPrices[i];
        }
    }

    function getTickerSymbols() public view returns (bytes32[] memory) {
        return tickerSymbols;
    }

    function getCurrentRoundId() public view returns (uint) {
        if (numProposals == 0) {
            return startingRoundId;
        } else {
            return proposals[numProposals].roundId;
        }
    }

    function setTickerSymbols(bytes32[] memory newKeys, int[] memory newPrices) public managementOnly latestProposalConfirmed {
        bytes32[] memory oldKeys = tickerSymbols;
        tickerSymbols = newKeys;
        setPricesInternal(newPrices);
        // test that this function does not fail before setting
        getWinner();
        emit TickerSymbolsUpdated(oldKeys, newKeys, newPrices);
    }

    function addFeed(bytes32 key, address feedAddr) public managementOnly {
        feedMap[key] = feedAddr;
        emit FeedUpdated(key, feedAddr);
    }

    function getWinner() public view returns (int[] memory, uint) {
        int256 maxPriceDiff = -100 * PRECISION;
        uint winnerIndex = 0;
        int[] memory pricesLocal = new int[](tickerSymbols.length);
        for (uint i = 0; i < tickerSymbols.length; i++) {
            bytes32 key = tickerSymbols[i];
            int priceBefore = prices[key];
            address feedAddr = feedMap[key];
            require(feedAddr != address(0), 'Must set feed for all ticker symbols');
            AggregatorV3Interface chainlink = AggregatorV3Interface(feedAddr);
            (,int256 priceNow,,,) = chainlink.latestRoundData();
            pricesLocal[i] = priceNow;
            int256 priceDiff = ((priceNow - priceBefore) * PRECISION) / priceBefore;
            if (priceDiff > maxPriceDiff) {
                maxPriceDiff = priceDiff;
                // add one to index to account for 1 based indexing on Trollbox contract
                winnerIndex = i + 1;
            }
        }
        return (pricesLocal, winnerIndex);
    }

    function proposeWinner() public latestProposalConfirmed {
        uint roundId = getCurrentRoundId() + 1;
        require(trollbox.roundAlreadyResolved(tournamentId, roundId) == false, 'Round already resolve');
        require(trollbox.getCurrentRoundId(tournamentId) > roundId + 1, 'Round not ready to resolve');
        Proposal storage proposal = proposals[++numProposals];
        proposal.id = numProposals;
        proposal.time = block.timestamp;
        proposal.roundId = roundId;
        (int[] memory newPrices, uint winnerIndex) = getWinner();
        setPricesInternal(newPrices);
        proposal.winnerIndex = winnerIndex;
        emit WinnerProposed(roundId, numProposals, proposal.winnerIndex, newPrices);
    }

    function challengeWinner(uint claimedWinner, bytes32 evidence) public {
        token.transferFrom(msg.sender, address(this), challengeDeposit);
        Proposal storage proposal = proposals[numProposals];
        require(proposal.challenger == address(0), 'Proposal already challenged');
        require(claimedWinner != proposal.winnerIndex, 'Must claim different winner than proposed winner');
        require(block.timestamp - proposal.time < challengePeriodSeconds, 'Challenge period has passed');
        proposal.challenger = msg.sender;
        proposal.challengeWinnerIndex = claimedWinner;
        proposal.challengeEvidence = evidence;
        emit ChallengeMade(numProposals, msg.sender, claimedWinner, evidence);
    }

    function confirmWinnerUnchallenged() public {
        Proposal memory proposal = proposals[numProposals];
        require(proposal.challenger == address(0), 'Proposal has been challenged');
        require(block.timestamp - proposal.time > challengePeriodSeconds, 'Challenge period has not passed');
        confirmWinnerInternal();
    }

    function confirmWinnerChallenged(uint chosenWinnerIndex, int[] memory localPrices, bytes32 evidence) public managementOnly {
        Proposal storage proposal = proposals[numProposals];
        require(proposal.challenger != address(0), 'Proposal has not been challenged');
        require(chosenWinnerIndex <= tickerSymbols.length, 'Winner index out of range');
        require(chosenWinnerIndex > 0, 'Winner index must be positive');
        require(localPrices.length == tickerSymbols.length, 'Must specify prices for all ticker symbols');

        // set official winner
        proposal.winnerIndex = chosenWinnerIndex;
        proposal.confirmationEvidence = evidence;

        // record prices
        setPricesInternal(localPrices);

        confirmWinnerInternal();

        // if challenger failed, slash their deposit
        if (chosenWinnerIndex != proposal.challengeWinnerIndex) {
            token.transfer(address(0), challengeDeposit);
            emit ChallengerSlashed(numProposals, proposal.challenger, challengeDeposit, evidence);
        // else send it back to them
        } else {
            token.transfer(proposal.challenger, challengeDeposit);
            emit ChallengerVindicated(numProposals, proposal.challenger, evidence);
        }
    }

    function confirmWinnerInternal() internal {
        Proposal storage proposal = proposals[numProposals];
        require(proposal.id == numProposals, 'Invalid proposalId');
        require(proposal.confirmed == false, 'Already confirmed proposal');
        proposal.confirmed = true;
        int[] memory pricesLocal = new int[](tickerSymbols.length);
        for (uint i = 0; i < tickerSymbols.length; i++) {
            pricesLocal[i] = prices[tickerSymbols[i]];
        }
        emit WinnerConfirmed(proposal.roundId, proposal.id, pricesLocal);
        trollbox.resolveRound(tournamentId, proposal.roundId, proposal.winnerIndex);
    }

    // K3PR functions
    function checkUpkeep(bytes calldata checkData) external view override returns (bool, bytes memory) {
        Proposal storage currentProposal = proposals[numProposals];
        // if it's confirmed, we may need to propose a new one
        if (currentProposal.confirmed || numProposals == 0) {
            uint roundId = getCurrentRoundId() + 1;
            bool roundAlreadyResolved = trollbox.roundAlreadyResolved(tournamentId, roundId);
            bool roundResolvable = trollbox.getCurrentRoundId(tournamentId) > roundId + 1;
            return (!roundAlreadyResolved && roundResolvable, abi.encode(false));
        // otherwise if there is no challenger
        } else {
            bool unchallenged = currentProposal.challenger == address(0);
            bool pastChallengePeriod = block.timestamp - currentProposal.time > challengePeriodSeconds;
            return (unchallenged && pastChallengePeriod, abi.encode(true));
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        bool confirm = abi.decode(performData, (bool));
        // confirm
        if (confirm) {
            confirmWinnerUnchallenged();
        // propose
        } else {
            proposeWinner();
        }
    }
}