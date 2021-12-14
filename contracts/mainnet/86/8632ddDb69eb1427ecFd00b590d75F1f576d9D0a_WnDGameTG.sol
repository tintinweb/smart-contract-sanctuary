// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IWnDGame.sol";
import "./interfaces/ITrainingGrounds.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/IGP.sol";
import "./interfaces/IWnD.sol";
import "./interfaces/ISacrificialAlter.sol";


contract WnDGameTG is IWnDGame, Ownable, ReentrancyGuard, Pausable {

  struct MintCommit {
    address recipient;
    bool stake;
    uint16 amount;
  }

  struct TrainingCommit {
    address tokenOwner;
    uint16 tokenId;
    bool isAdding; // If false, the commit is for claiming rewards
    bool isUnstaking; // If !isAdding, this will determine if user is unstaking
    bool isTraining; // If !isAdding, this will define where the staked token is (only necessary for wizards)
  }

  uint256 public constant TREASURE_CHEST = 5;
  // max $GP cost 
  uint256 private maxGpCost = 72000 ether;

  /** =========== MINTING COMMIT AND REVEAL VARIABLES =========== */
  // commitId -> array of all pending commits
  mapping(uint16 => MintCommit[]) private commitQueueMints;
  // Track when a commitId started accepting commits
  mapping(uint16 => uint256) private commitIdStartTimeMints;
  mapping(address => uint16) private pendingMintCommitsForAddr;
  // Tracks the current commitId batch to put new commits into
  uint16 private _commitIdCurMints = 1;
  // tracks the oldest commitId that has commits needing to be revealed
  uint16 private _commitIdPendingMints = 0;
  /** =========== TRAINING COMMIT AND REVEAL VARIABLES =========== */
  // commitId -> array of all pending commits
  mapping(uint16 => TrainingCommit[]) private commitQueueTraining;
  // Track when a commitId started accepting commits
  mapping(uint16 => uint256) private commitIdStartTimeTraining;
  mapping(address => uint16) private pendingTrainingCommitsForAddr;
  mapping(uint256 => bool) private tokenHasPendingCommit;
  // Tracks the current commitId batch to put new commits into
  uint16 private _commitIdCurTraining = 1;
  // tracks the oldest commitId that has commits needing to be revealed
  uint16 private _commitIdPendingTraining = 0;

  // Time from starting a commit batch to allow new commits to enter
  uint64 private timePerCommitBatch = 5 minutes;
  // Time from starting a commit batch to allow users to reveal these in exchange for $GP
  uint64 private timeToAllowArb = 1 hours;
  uint16 private pendingMintAmt;
  bool public allowCommits = true;

  uint256 private revealRewardAmt = 36000 ether;
  uint256 private stakingCost = 8000 ether;

  // reference to the TrainingGrounds
  ITrainingGrounds public trainingGrounds;
  // reference to $GP for burning on mint
  IGP public gpToken;
  // reference to Traits
  ITraits public traits;
  // reference to NFT collection
  IWnD public wndNFT;
  // reference to alter collection
  ISacrificialAlter public alter;

  constructor() {
    _pause();
  }

  /** CRITICAL TO SETUP */

  modifier requireContractsSet() {
      require(address(gpToken) != address(0) && address(traits) != address(0) 
        && address(wndNFT) != address(0) && address(alter) != address(0)
         && address(trainingGrounds) != address(0)
        , "Contracts not set");
      _;
  }

  function setContracts(address _gp, address _traits, address _wnd, address _alter, address _trainingGrounds) external onlyOwner {
    gpToken = IGP(_gp);
    traits = ITraits(_traits);
    wndNFT = IWnD(_wnd);
    alter = ISacrificialAlter(_alter);
    trainingGrounds = ITrainingGrounds(_trainingGrounds);
  }

  /** EXTERNAL */

  function getPendingMintCommits(address addr) external view returns (uint16) {
    return pendingMintCommitsForAddr[addr];
  }
  function getPendingTrainingCommits(address addr) external view returns (uint16) {
    return pendingTrainingCommitsForAddr[addr];
  }
  function isTokenPendingReveal(uint256 tokenId) external view returns (bool) {
    return tokenHasPendingCommit[tokenId];
  }
  function hasStaleMintCommit() external view returns (bool) {
    uint16 pendingId = _commitIdPendingMints;
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueMints[pendingId].length == 0 && pendingId < _commitIdCurMints) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      pendingId += 1;
    }
    return commitIdStartTimeMints[pendingId] < block.timestamp - timeToAllowArb && commitQueueMints[pendingId].length > 0;
  }
  function hasStaleTrainingCommit() external view returns (bool) {
    uint16 pendingId = _commitIdPendingTraining;
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueTraining[pendingId].length == 0 && pendingId < _commitIdCurTraining) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      pendingId += 1;
    }
    return commitIdStartTimeTraining[pendingId] < block.timestamp - timeToAllowArb && commitQueueTraining[pendingId].length > 0;
  }

  /** Allow users to reveal the oldest commit for GP. Mints commits must be stale to be able to be revealed this way */
  function revealOldestMint() external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");

    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueMints[_commitIdPendingMints].length == 0 && _commitIdPendingMints < _commitIdCurMints) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingMints += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    require(commitIdStartTimeMints[_commitIdPendingMints] < block.timestamp - timeToAllowArb && commitQueueMints[_commitIdPendingMints].length > 0, "No stale commits to reveal");
    // If the pending batch is old enough to be revealed and has stuff in it, mine one.
    MintCommit memory commit = commitQueueMints[_commitIdPendingMints][commitQueueMints[_commitIdPendingMints].length - 1];
    commitQueueMints[_commitIdPendingMints].pop();
    revealMint(commit);
    gpToken.mint(_msgSender(), revealRewardAmt * commit.amount);
  }

  /** Allow users to reveal the oldest commit for GP. Mints commits must be stale to be able to be revealed this way */
  function skipOldestMint() external onlyOwner {
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueMints[_commitIdPendingMints].length == 0 && _commitIdPendingMints < _commitIdCurMints) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingMints += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    require(commitQueueMints[_commitIdPendingMints].length > 0, "No stale commits to reveal");
    // If the pending batch is old enough to be revealed and has stuff in it, mine one.
    commitQueueMints[_commitIdPendingMints].pop();
    // Do not reveal the commit, only pop it from the queue and move on.
    // revealMint(commit);
  }

  function revealOldestTraining() external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");

    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueTraining[_commitIdPendingTraining].length == 0 && _commitIdPendingTraining < _commitIdCurTraining) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingTraining += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    require(commitIdStartTimeTraining[_commitIdPendingTraining] < block.timestamp - timeToAllowArb && commitQueueTraining[_commitIdPendingTraining].length > 0, "No stale commits to reveal");
    // If the pending batch is old enough to be revealed and has stuff in it, mine one.
    TrainingCommit memory commit = commitQueueTraining[_commitIdPendingTraining][commitQueueTraining[_commitIdPendingTraining].length - 1];
    commitQueueTraining[_commitIdPendingTraining].pop();
    revealTraining(commit);
    gpToken.mint(_msgSender(), revealRewardAmt);
  }

  function skipOldestTraining() external onlyOwner {
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueTraining[_commitIdPendingTraining].length == 0 && _commitIdPendingTraining < _commitIdCurTraining) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingTraining += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    require(commitQueueTraining[_commitIdPendingTraining].length > 0, "No stale commits to reveal");
    // If the pending batch is old enough to be revealed and has stuff in it, mine one.
    TrainingCommit memory commit = commitQueueTraining[_commitIdPendingTraining][commitQueueTraining[_commitIdPendingTraining].length - 1];
    commitQueueTraining[_commitIdPendingTraining].pop();
    // Do not reveal the commit, only pop it from the queue and move on.
    // revealTraining(commit);
    tokenHasPendingCommit[commit.tokenId] = false;
  }

  /** Initiate the start of a mint. This action burns $GP, as the intent of committing is that you cannot back out once you've started.
    * This will add users into the pending queue, to be revealed after a random seed is generated and assigned to the commit id this
    * commit was added to. */
  function mintCommit(uint256 amount, bool stake) external whenNotPaused nonReentrant {
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    uint16 minted = wndNFT.minted();
    uint256 maxTokens = wndNFT.getMaxTokens();
    require(minted + pendingMintAmt + amount <= maxTokens, "All tokens minted");
    require(amount > 0 && amount <= 10, "Invalid mint amount");
    if(commitIdStartTimeMints[_commitIdCurMints] == 0) {
      commitIdStartTimeMints[_commitIdCurMints] = block.timestamp;
    }

    // Check if current commit batch is past the threshold for time and increment commitId if so
    if(commitIdStartTimeMints[_commitIdCurMints] < block.timestamp - timePerCommitBatch) {
      // increment commitId to start a new batch
      _commitIdCurMints += 1;
      commitIdStartTimeMints[_commitIdCurMints] = block.timestamp;
    }

    // Add this mint request to the commit queue for the current commitId
    uint256 totalGpCost = 0;
    // Loop through the amount of 
    for (uint i = 1; i <= amount; i++) {
      // Add N number of commits to the queue. This is so people reveal the same number of commits as they added.
      commitQueueMints[_commitIdCurMints].push(MintCommit(_msgSender(), stake, 1));
      totalGpCost += mintCost(minted + pendingMintAmt + i, maxTokens);
    }
    if (totalGpCost > 0) {
      gpToken.burn(_msgSender(), totalGpCost);
      gpToken.updateOriginAccess();
    }
    uint16 amt = uint16(amount);
    pendingMintCommitsForAddr[_msgSender()] += amt;
    pendingMintAmt += amt;

    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueMints[_commitIdPendingMints].length == 0 && _commitIdPendingMints < _commitIdCurMints) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingMints += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    if(commitIdStartTimeMints[_commitIdPendingMints] < block.timestamp - timePerCommitBatch && commitQueueMints[_commitIdPendingMints].length > 0) {
      // If the pending batch is old enough to be revealed and has stuff in it, mine the number that was added to the queue.
      for (uint256 i = 0; i < amount; i++) {
        // First iteration is guaranteed to have 1 commit to mine, so we can always retroactively check that we can continue to reveal after
        MintCommit memory commit = commitQueueMints[_commitIdPendingMints][commitQueueMints[_commitIdPendingMints].length - 1];
        commitQueueMints[_commitIdPendingMints].pop();
        revealMint(commit);
        // Check to see if we are able to continue mining commits
        if(commitQueueMints[_commitIdPendingMints].length == 0 && _commitIdPendingMints < _commitIdCurMints) {
          _commitIdPendingMints += 1;
          if(commitIdStartTimeMints[_commitIdPendingMints] > block.timestamp - timePerCommitBatch 
            || commitQueueMints[_commitIdPendingMints].length == 0
            || _commitIdPendingMints == _commitIdCurMints)
          {
            // If there are no more commits to reveal, exit
            break;
          }
        }
      }
    }
  }

  function revealMint(MintCommit memory commit) internal {
    uint16 minted = wndNFT.minted();
    pendingMintAmt -= commit.amount;
    uint16[] memory tokenIds = new uint16[](commit.amount);
    uint16[] memory tokenIdsToStake = new uint16[](commit.amount);
    uint256 seed = uint256(keccak256(abi.encode(commit.recipient, minted, commitIdStartTimeMints[_commitIdPendingMints])));
    for (uint k = 0; k < commit.amount; k++) {
      minted++;
      // scramble the random so the steal / treasure mechanic are different per mint
      seed = uint256(keccak256(abi.encode(seed, commit.recipient)));
      address recipient = selectRecipient(seed, commit.recipient);
      if(recipient != commit.recipient && alter.balanceOf(commit.recipient, TREASURE_CHEST) > 0) {
        // If the mint is going to be stolen, there's a 50% chance 
        //  a dragon will prefer a treasure chest over it
        if(seed & 1 == 1) {
          alter.safeTransferFrom(commit.recipient, recipient, TREASURE_CHEST, 1, "");
          recipient = commit.recipient;
        }
      }
      tokenIds[k] = minted;
      if (!commit.stake || recipient != commit.recipient) {
        wndNFT.mint(recipient, seed);
      } else {
        wndNFT.mint(address(trainingGrounds), seed);
        tokenIdsToStake[k] = minted;
      }
    }
    wndNFT.updateOriginAccess(tokenIds);
    if(commit.stake) {
      trainingGrounds.addManyToTowerAndFlight(commit.recipient, tokenIdsToStake);
    }
    pendingMintCommitsForAddr[commit.recipient] -= commit.amount;
  }

  function addToTower(uint16[] calldata tokenIds) external whenNotPaused {
    require(_msgSender() == tx.origin, "Only EOA");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(!tokenHasPendingCommit[tokenIds[i]], "token has pending commit");
    }
    trainingGrounds.addManyToTowerAndFlight(tx.origin, tokenIds);
  }

  function addToTrainingCommit(uint16[] calldata tokenIds) external whenNotPaused {
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    if(commitIdStartTimeTraining[_commitIdCurTraining] == 0) {
      commitIdStartTimeTraining[_commitIdCurTraining] = block.timestamp;
    }

    // Check if current commit batch is past the threshold for time and increment commitId if so
    if(commitIdStartTimeTraining[_commitIdCurTraining] < block.timestamp - timePerCommitBatch) {
      // increment commitId to start a new batch
      _commitIdCurTraining += 1;
      commitIdStartTimeTraining[_commitIdCurTraining] = block.timestamp;
    }
    // Loop through the amount of tokens being added
    uint16 numDragons;
    for (uint i = 0; i < tokenIds.length; i++) {
      require(address(trainingGrounds) != wndNFT.ownerOf(tokenIds[i]), "token already staked");
      require(!tokenHasPendingCommit[tokenIds[i]], "token has pending commit");
      require(_msgSender() == wndNFT.ownerOf(tokenIds[i]), "token already staked");
      uint64 lastTokenWrite = wndNFT.getTokenWriteBlock(tokenIds[i]);
      // Must check this, as getTokenTraits will be allowed since this contract is an admin
      require(lastTokenWrite < block.number, "hmmmm what doing?");
      if(!wndNFT.isWizard(tokenIds[i])) {
        numDragons += 1;
      }
      tokenHasPendingCommit[tokenIds[i]] = true;
      // Add N number of commits to the queue. This is so people reveal the same number of commits as they added.
      commitQueueTraining[_commitIdCurTraining].push(TrainingCommit(_msgSender(), tokenIds[i], true, false, true));
    }
    gpToken.burn(_msgSender(), stakingCost * (tokenIds.length - numDragons)); // Dragons are free to stake
    gpToken.updateOriginAccess();
    pendingTrainingCommitsForAddr[_msgSender()] += uint16(tokenIds.length);
    tryRevealTraining(tokenIds.length);
  }

  function claimTrainingsCommit(uint16[] calldata tokenIds, bool isUnstaking, bool isTraining) external whenNotPaused {
    require(allowCommits, "adding commits disallowed");
    require(tx.origin == _msgSender(), "Only EOA");
    if(commitIdStartTimeTraining[_commitIdCurTraining] == 0) {
      commitIdStartTimeTraining[_commitIdCurTraining] = block.timestamp;
    }

    // Check if current commit batch is past the threshold for time and increment commitId if so
    if(commitIdStartTimeTraining[_commitIdCurTraining] < block.timestamp - timePerCommitBatch) {
      // increment commitId to start a new batch
      _commitIdCurTraining += 1;
      commitIdStartTimeTraining[_commitIdCurTraining] = block.timestamp;
    }
    // Loop through the amount of tokens being added
    for (uint i = 0; i < tokenIds.length; i++) {
      require(!tokenHasPendingCommit[tokenIds[i]], "token has pending commit");
      require(trainingGrounds.isTokenStaked(tokenIds[i], isTraining) && trainingGrounds.ownsToken(tokenIds[i])
      , "Token not in staking pool");
      uint64 lastTokenWrite = wndNFT.getTokenWriteBlock(tokenIds[i]);
      // Must check this, as getTokenTraits will be allowed since this contract is an admin
      require(lastTokenWrite < block.number, "hmmmm what doing?");
      if(isUnstaking && wndNFT.isWizard(tokenIds[i])) {
        // Check to see if the wizard has earned enough to withdraw.
        // If emissions run out, allow them to attempt to withdraw anyways.
        if(isTraining) {
          require(trainingGrounds.curWhipsEmitted() >= 16000
            || trainingGrounds.calculateErcEmissionRewards(tokenIds[i]) > 0, "can't unstake wizard yet");
        }
        else {
          require(trainingGrounds.totalGPEarned() > 500000000 ether - 4000 ether
            || trainingGrounds.calculateGpRewards(tokenIds[i]) >= 4000 ether, "can't unstake wizard yet");
        }
      }
      tokenHasPendingCommit[tokenIds[i]] = true;
      // Add N number of commits to the queue. This is so people reveal the same number of commits as they added.
      commitQueueTraining[_commitIdCurTraining].push(TrainingCommit(_msgSender(), tokenIds[i], false, isUnstaking, isTraining));
    }
    gpToken.burn(_msgSender(), stakingCost * tokenIds.length);
    gpToken.updateOriginAccess();
    pendingTrainingCommitsForAddr[_msgSender()] += uint16(tokenIds.length);
    tryRevealTraining(tokenIds.length);
  }

  function tryRevealTraining(uint256 amount) internal {
    // Check if the revealable commitId has anything to commit and increment it until it does, or is the same as the current commitId
    while(commitQueueTraining[_commitIdPendingTraining].length == 0 && _commitIdPendingTraining < _commitIdCurTraining) {
      // Only iterate if the commit pending is empty and behind the current id.
      // This is to prevent it from being in front of the current id and missing commits.
      _commitIdPendingTraining += 1;
    }
    // Check if there is a commit in a revealable batch and pop/reveal it
    if(commitIdStartTimeTraining[_commitIdPendingTraining] < block.timestamp - timePerCommitBatch && commitQueueTraining[_commitIdPendingTraining].length > 0) {
      // If the pending batch is old enough to be revealed and has stuff in it, mine the number that was added to the queue.
      for (uint256 i = 0; i < amount; i++) {
        // First iteration is guaranteed to have 1 commit to mine, so we can always retroactively check that we can continue to reveal after
        TrainingCommit memory commit = commitQueueTraining[_commitIdPendingTraining][commitQueueTraining[_commitIdPendingTraining].length - 1];
        commitQueueTraining[_commitIdPendingTraining].pop();
        revealTraining(commit);
        // Check to see if we are able to continue mining commits
        if(commitQueueTraining[_commitIdPendingTraining].length == 0 && _commitIdPendingTraining < _commitIdCurTraining) {
          _commitIdPendingTraining += 1;
          if(commitIdStartTimeTraining[_commitIdPendingTraining] > block.timestamp - timePerCommitBatch 
            || commitQueueTraining[_commitIdPendingTraining].length == 0
            || _commitIdPendingTraining == _commitIdCurTraining)
          {
            // If there are no more commits to reveal, exit
            break;
          }
        }
      }
    }
  }

  function revealTraining(TrainingCommit memory commit) internal {
    uint16[] memory idSingle = new uint16[](1);
    idSingle[0] = commit.tokenId;
    tokenHasPendingCommit[commit.tokenId] = false;
    if(commit.isAdding) {
      if(wndNFT.ownerOf(commit.tokenId) != commit.tokenOwner) {
        // The owner has transferred their token and can no longer be staked. We can simply skip this reveal.
        return;
      }
      if(wndNFT.isWizard(commit.tokenId)) {
        // Add to training since tower staking doesn't need C+R
        uint256 seed = random(commit.tokenId, commitIdStartTimeTraining[_commitIdPendingTraining], commit.tokenOwner);
        try trainingGrounds.addManyToTrainingAndFlight(seed, commit.tokenOwner, idSingle) {
          // Do nothing. It worked.
        } catch {
          // Return instead of reverting so that the queue can process this.
          return;
        }
      }
      else {
        // Dragons go to the tower but really they are in both pools. This just avoids the stealing logic.
        try trainingGrounds.addManyToTowerAndFlight(commit.tokenOwner, idSingle) {
          // Do nothing. It worked.
        } catch {
          // Return instead of reverting so that the queue can process this.
          return;
        }
      }
    }
    else {
      if(!trainingGrounds.isTokenStaked(commit.tokenId, commit.isTraining)) {
        // Skip reveals if the token has already been claimed since committing to this tx (like claiming multiple times unknowingly)
        return;
      }
      if(commit.isTraining) {
        uint256 seed = random(commit.tokenId, commitIdStartTimeTraining[_commitIdPendingTraining], commit.tokenOwner);
        try trainingGrounds.claimManyFromTrainingAndFlight(seed, commit.tokenOwner, idSingle, commit.isUnstaking) {
          // Do nothing. It worked.
        } catch {
          // Return instead of reverting so that the queue can process this.
          return;
        }
      }
      else {
        try trainingGrounds.claimManyFromTowerAndFlight(commit.tokenOwner, idSingle, commit.isUnstaking) {
          // Do nothing. It worked.
        } catch {
          // Return instead of reverting so that the queue can process this.
          return;
        }
      }
    }
    pendingTrainingCommitsForAddr[commit.tokenOwner] -= 1;
  }

  /** Deterministically random. This assumes the call was a part of commit+reveal design 
   * that disallowed the benefactor of this outcome to make this call */
  function random(uint16 tokenId, uint256 time, address owner) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
      owner,
      tokenId,
      time
    )));
  }

  /** 
   * @param tokenId the ID to check the cost of to mint
   * @return the cost of the given token ID
   */
  function mintCost(uint256 tokenId, uint256 maxTokens) public view returns (uint256) {
    if (tokenId <= maxTokens * 8 / 20) return 24000 ether;
    if (tokenId <= maxTokens * 11 / 20) return 36000 ether;
    if (tokenId <= maxTokens * 14 / 20) return 48000 ether;
    if (tokenId <= maxTokens * 17 / 20) return 60000 ether; 
    // if (tokenId > maxTokens * 17 / 20)
    return maxGpCost;
  }

  function makeTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    // $GP exchange amount handled within alter contract
    // Will fail if sender doesn't have enough $GP
    // Transfer does not need approved,
    //  as there is established trust between this contract and the alter contract 
    alter.mint(TREASURE_CHEST, qty, _msgSender());
  }

  function sellTreasureChests(uint16 qty) external whenNotPaused {
    require(tx.origin == _msgSender(), "Only EOA");
    // $GP exchange amount handled within alter contract
    alter.burn(TREASURE_CHEST, qty, _msgSender());
  }

  /** INTERNAL */

  /**
   * the first 25% (ETH purchases) go to the minter
   * the remaining 80% have a 10% chance to be given to a random staked dragon
   * @param seed a random value to select a recipient from
   * @return the address of the recipient (either the minter or the Dragon thief's owner)
   */
  function selectRecipient(uint256 seed, address committer) internal view returns (address) {
    if (((seed >> 245) % 10) != 0) return committer; // top 10 bits haven't been used
    address thief = trainingGrounds.randomDragonOwner(seed >> 144); // 144 bits reserved for trait selection
    if (thief == address(0x0)) return committer;
    return thief;
  }

  /** ADMIN */

  /**
   * enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyOwner {
    if (_paused) _pause();
    else _unpause();
  }

  function setMaxGpCost(uint256 _amount) external requireContractsSet onlyOwner {
    maxGpCost = _amount;
  }

  function setAllowCommits(bool allowed) external onlyOwner {
    allowCommits = allowed;
  }

  function setRevealRewardAmt(uint256 rewardAmt) external onlyOwner {
    revealRewardAmt = rewardAmt;
  }

  /** Allow the contract owner to set the pending mint amount.
    * This allows any long-standing pending commits to be overwritten, say for instance if the max supply has been 
    *  reached but there are many stale pending commits, it could be used to free up those spaces if needed/desired by the community.
    * This function should not be called lightly, this will have negative consequences on the game. */
  function setPendingMintAmt(uint256 pendingAmt) external onlyOwner {
    pendingMintAmt = uint16(pendingAmt);
  }

  /**
   * allows owner to withdraw funds from minting
   */
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IWnDGame {
  
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ITrainingGrounds {
  function addManyToTowerAndFlight(address tokenOwner, uint16[] calldata tokenIds) external;
  function claimManyFromTowerAndFlight(address tokenOwner, uint16[] calldata tokenIds, bool unstake) external;
  function addManyToTrainingAndFlight(uint256 seed, address tokenOwner, uint16[] calldata tokenIds) external;
  function claimManyFromTrainingAndFlight(uint256 seed, address tokenOwner, uint16[] calldata tokenIds, bool unstake) external;
  function randomDragonOwner(uint256 seed) external view returns (address);
  function isTokenStaked(uint256 tokenId, bool isTraining) external view returns (bool);
  function ownsToken(uint256 tokenId) external view returns (bool);
  function calculateGpRewards(uint256 tokenId) external view returns (uint256 owed);
  function calculateErcEmissionRewards(uint256 tokenId) external view returns (uint256 owed);
  function curWhipsEmitted() external view returns (uint16);
  function curMagicRunesEmitted() external view returns (uint16);
  function totalGPEarned() external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE 

pragma solidity ^0.8.0;

interface ITraits {
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IGP {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function updateOriginAccess() external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IWnD is IERC721Enumerable {

    // game data storage
    struct WizardDragon {
        bool isWizard;
        uint8 body;
        uint8 head;
        uint8 spell;
        uint8 eyes;
        uint8 neck;
        uint8 mouth;
        uint8 wand;
        uint8 tail;
        uint8 rankIndex;
    }

    function minted() external returns (uint16);
    function updateOriginAccess(uint16[] memory tokenIds) external;
    function mint(address recipient, uint256 seed) external;
    function burn(uint256 tokenId) external;
    function getMaxTokens() external view returns (uint256);
    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (WizardDragon memory);
    function getTokenWriteBlock(uint256 tokenId) external view returns(uint64);
    function isWizard(uint256 tokenId) external view returns(bool);
  
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ISacrificialAlter {
    function mint(uint256 typeId, uint16 qty, address recipient) external;
    function burn(uint256 typeId, uint16 qty, address burnFrom) external;
    function updateOriginAccess() external;
    function balanceOf(address account, uint256 id) external returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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