// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

abstract contract CattoKatsuInterface {
  function balanceOf(address owner) public view virtual returns (uint256);
  function getOwnerTokenIDs(address _owner) public view virtual returns (uint256[] memory);
  function migrateTreasury() external virtual;
}

contract CattoKatsuTreasuryVote is Ownable, ReentrancyGuard {

  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;

  CattoKatsuInterface private CattoKatsuContract;

  Counters.Counter private positives; // tracks 'for' votes
  Counters.Counter private negatives; // tracks 'against' votes

  address public CattoKatsuAddr = address(0);
  address public ProposedNewContract = address(0); // proposed upgraded contract to transfer treasury funds to
  bool public VotingIsOpen = false;
  uint256 public VotingEndTimestamp = 0;
  address[] private votedWallets;
  mapping(address => bool) private walletVoteMapping; // track wallets that have voted
  uint256[] private votedTokens;
  mapping(uint256 => bool) private votedTokensMapping;

  constructor(address _contractAddr) {
    require(_contractAddr.isContract(), "Address given must be a contract");
    CattoKatsuAddr = _contractAddr;
    CattoKatsuContract = CattoKatsuInterface(_contractAddr);
  }

  /**
   * @dev Function to initiate voting
   */
  function initiateVoting(address _proposedContractAddr) external onlyOwner {
    require(!VotingIsOpen, "There is an ongoing vote");

    VotingIsOpen = true;
    VotingEndTimestamp = block.timestamp.add(432000);
    ProposedNewContract = _proposedContractAddr;
  }

  /**
   * @dev Function to allow reset states to allow reuse of voting contract
   */
  function resetVoteStates() external onlyOwner {
    VotingIsOpen = false;
    VotingEndTimestamp = 0;
    ProposedNewContract = address(0);
    positives.reset();
    negatives.reset();

    for (uint256 i = 0; i < votedTokens.length; i++) {
      votedTokensMapping[votedTokens[i]] = false;
    }

    for (uint256 i = 0; i < votedWallets.length; i++) {
      walletVoteMapping[votedWallets[i]] = false;
    }

    delete votedTokens;
    delete votedWallets;
  }

  function castVote(bool vote) external nonReentrant {
    require(VotingIsOpen, "No ongoing vote");
    require(block.timestamp < VotingEndTimestamp, "Vote has already ended");
    require(!_msgSender().isContract(), "Cannot vote via contract");

    uint256 __balanceCatto = CattoKatsuContract.balanceOf(_msgSender());
    require(__balanceCatto > 0, "Not a token holder, not eligible to vote");

    uint256[] memory __voterTokens = CattoKatsuContract.getOwnerTokenIDs(_msgSender());

    for (uint256 i = 0; i < __voterTokens.length; i++) {
      if (votedTokensMapping[__voterTokens[i]]) {
        continue;
      }

      uint256 __tokenID = __voterTokens[i];

      votedTokensMapping[__tokenID] = true;
      votedTokens.push(__tokenID);

      if (vote) {
        positives.increment();
      } else {
        negatives.increment();
      }
    }

    if (!walletVoteMapping[_msgSender()]) {
      walletVoteMapping[_msgSender()] = true;
      votedWallets.push(_msgSender());
    }
  }

  /**
   * @dev Returns number of positives & negatives, total valid votes, and total wallet participation
   */
  function getVotingResults() public view returns (uint256, uint256, uint256, uint256) {
    return (positives.current(), negatives.current(), votedTokens.length, votedWallets.length);
  }

  function invokeTreasuryTransfer() external onlyOwner {
    require(block.timestamp >= VotingEndTimestamp, "Vote is still in progress");
    require(positives.current() > negatives.current(), "Vote result did not pass majority");
    CattoKatsuContract.migrateTreasury();
  }

  function withdraw() external onlyOwner {
    (bool success,) = _msgSender().call{value: address(this).balance}("");
    require(success, "Withdraw failed.");
  }

  receive() external payable {}

}