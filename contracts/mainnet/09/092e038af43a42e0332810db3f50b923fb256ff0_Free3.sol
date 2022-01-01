/**
 *Submitted for verification at Etherscan.io on 2022-01-01
*/

// SPDX-License-Identifier: CC0


/*
 /$$$$$$$$ /$$$$$$$  /$$$$$$$$ /$$$$$$$$        /$$$$$$
| $$_____/| $$__  $$| $$_____/| $$_____/       /$$__  $$
| $$      | $$  \ $$| $$      | $$            |__/  \ $$
| $$$$$   | $$$$$$$/| $$$$$   | $$$$$            /$$$$$/
| $$__/   | $$__  $$| $$__/   | $$__/           |___  $$
| $$      | $$  \ $$| $$      | $$             /$$  \ $$
| $$      | $$  | $$| $$$$$$$$| $$$$$$$$      |  $$$$$$/
|__/      |__/  |__/|________/|________/       \______/



 /$$
| $$
| $$$$$$$  /$$   /$$
| $$__  $$| $$  | $$
| $$  \ $$| $$  | $$
| $$  | $$| $$  | $$
| $$$$$$$/|  $$$$$$$
|_______/  \____  $$
           /$$  | $$
          |  $$$$$$/
           \______/
  /$$$$$$  /$$$$$$$$ /$$$$$$$$ /$$    /$$ /$$$$$$ /$$$$$$$$ /$$$$$$$
 /$$__  $$|__  $$__/| $$_____/| $$   | $$|_  $$_/| $$_____/| $$__  $$
| $$  \__/   | $$   | $$      | $$   | $$  | $$  | $$      | $$  \ $$
|  $$$$$$    | $$   | $$$$$   |  $$ / $$/  | $$  | $$$$$   | $$$$$$$/
 \____  $$   | $$   | $$__/    \  $$ $$/   | $$  | $$__/   | $$____/
 /$$  \ $$   | $$   | $$        \  $$$/    | $$  | $$      | $$
|  $$$$$$/   | $$   | $$$$$$$$   \  $/    /$$$$$$| $$$$$$$$| $$
 \______/    |__/   |________/    \_/    |______/|________/|__/


CC0 2021
*/


pragma solidity ^0.8.11;

 
interface IFree {
  function mint(uint256 collectionId, address to) external;
  function ownerOf(uint256 tokenId) external returns (address owner);
  function tokenIdToCollectionId(uint256 tokenId) external returns (uint256 collectionId);
  function appendAttributeToToken(uint256 tokenId, string memory attrKey, string memory attrValue) external;
}


contract Free3 {
  IFree public immutable free;

  struct Stake {
    uint256 firstStakeBlockNumber;
    uint256 secondStakeBlockNumber;
    uint256 mintBlockNumber;
    uint256 totalStaked;
  }

  mapping(address => Stake) public addressToStakes;
  mapping(uint256 => bool) public free0TokenIdUsed;

  address public administrator;
  uint256 public immutable stakePeriod;
  uint256 public immutable progressPeriodExpiration;

  constructor(address freeAddr, uint256 _stakePeriod, uint256 _progressPeriodExpiration) {
    free = IFree(freeAddr);
    stakePeriod = _stakePeriod;
    progressPeriodExpiration = _progressPeriodExpiration;
    administrator = msg.sender;
  }

  modifier onlyAdmin {
    require(msg.sender == administrator, 'Admin only');
    _;
  }

  function transferAdministratorship(address newAdministrator) public onlyAdmin {
    administrator = newAdministrator;
  }

  function firstStake() public payable {
    Stake storage stake = addressToStakes[msg.sender];
    require(stake.firstStakeBlockNumber == 0, 'You have already attempted a first stake');
    require(msg.value >= 0.25 ether, 'You must stake at least 0.25 ether');

    stake.firstStakeBlockNumber = block.number;
    stake.totalStaked += msg.value;
  }

  function secondStake() public payable {
    Stake storage stake = addressToStakes[msg.sender];
    require(stake.firstStakeBlockNumber != 0, 'You have not attempted a first stake');
    require(stake.secondStakeBlockNumber == 0, 'You have already attempted a second stake');
    require(
      block.number > stake.firstStakeBlockNumber + stakePeriod
      && block.number < stake.firstStakeBlockNumber + progressPeriodExpiration,
      'You must wait between 5000 and 5100 blocks to make your second stake'
    );
    require(msg.value >= 0.25 ether, 'You must stake at least 0.25 ether');

    stake.secondStakeBlockNumber = block.number;
    stake.totalStaked += msg.value;
  }

  function withdraw(address staker) public onlyAdmin {
    Stake storage stake = addressToStakes[staker];

    bool firstStakeFailed = block.number > stake.firstStakeBlockNumber + progressPeriodExpiration;
    bool secondStakeFailed = block.number > stake.secondStakeBlockNumber + progressPeriodExpiration;
    bool ethStillStaked = stake.totalStaked > 0;
    bool isMinted = stake.mintBlockNumber > 0;
    require(
      firstStakeFailed && secondStakeFailed && ethStillStaked && !isMinted,
      'Can only withdraw if one of two stakes have failed, eth is still staked, and token has not been minted'
    );

    payable(administrator).transfer(stake.totalStaked);
    stake.totalStaked = 0;
  }

  function claim(uint256 free0TokenId) public {
    Stake storage stake = addressToStakes[msg.sender];

    require(stake.mintBlockNumber == 0, 'You have already minted');
    require(
      block.number > stake.secondStakeBlockNumber + stakePeriod
      && block.number < stake.secondStakeBlockNumber + progressPeriodExpiration,
      'You must wait between 5000 and 5100 blocks to claim'
    );
    require(free.ownerOf(free0TokenId) == msg.sender, 'You must be the owner of this Free0');
    require(free.tokenIdToCollectionId(free0TokenId) == 0, 'Invalid Free0');
    require(!free0TokenIdUsed[free0TokenId], 'This Free0 has already been used to mint a Free3');
    free.appendAttributeToToken(free0TokenId, 'Used For Free3 Mint', 'true');

    free0TokenIdUsed[free0TokenId] = true;
    stake.mintBlockNumber = block.number;

    free.mint(3, msg.sender);
    payable(msg.sender).transfer(stake.totalStaked);
    stake.totalStaked = 0;
  }
}