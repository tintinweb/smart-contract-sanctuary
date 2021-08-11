// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./PrizePoolManager.sol";
import "./StateManager.sol";
import "../interfaces/IGachapon.sol";
import "../interfaces/ITreasuryManager.sol";
import "../interfaces/IOracleManager.sol";

/// @author KirienzoEth for DokiDoki
contract Gachapon is PrizePoolManager, StateManager, IGachapon, VRFConsumerBase {
  uint256 constant private MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  /// @dev Get the round from its oracle request ID
  mapping(bytes32 => IGachapon.Round) private _rounds;
  /// @dev the number of rounds that were initialized but didn't receive an answer from the oracle yet
  uint256 private _pendingRoundsAmount;
  /// @dev The currency used by the oracle
  address private immutable _oracleCurrency;
  /// @notice The currency used by the machine
  address public immutable override currency;

  constructor(string memory _gachaponTitle, address _currency, address _deployer) 
  StateManager(_deployer) 
  VRFConsumerBase(IOracleManager(_deployer).oracleVRFCoordinator(), IOracleManager(_deployer).oracleToken()) 
  {
    title = _gachaponTitle;
    currency = _currency;
    _oracleCurrency = IOracleManager(_deployer).oracleToken();
  }

  /// @inheritdoc IGachapon
  function play(uint8 _times) external override {
    require(!isBanned && !isLocked && !isLockedForever, "This gachapon cannot be played right now");
    require(_times > 0 && _times <= 10, "You can only play between 1 and 10 times");
    require(_times <= getRemaningPrizesAmount(), "Not enough NFTs left to play");
    require(LINK.balanceOf(address(this)) >= IOracleManager(deployer).oracleFee(), "Not enough tokens to pay the oracle");
    
    _transferTokens(playOncePrice * _times);
    _startRound(msg.sender, _times);
  }

  /// @dev Start a new round
  /// @param _player The address that will receive the prizes
  /// @param _times The number of prizes the round should contain
  function _startRound(address _player, uint8 _times) private {
    // Contact the oracle to request a random number
    bytes32 _requestId = requestRandomness(IOracleManager(deployer).oracleKeyHash(), IOracleManager(deployer).oracleFee());

    // Initialize round
    _rounds[_requestId].id = _requestId;
    _rounds[_requestId].player = _player;
    _rounds[_requestId].status = RoundStatus.Pending;
    _rounds[_requestId].times = _times;
    _pendingRoundsAmount += _times;

    emit RoundStarted(_rounds[_requestId].id, _rounds[_requestId].player, _times);
  }

  /// @inheritdoc VRFConsumerBase
  function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
    require(_rounds[_requestId].status == RoundStatus.Pending, "The callback was already called for this round");
    uint256[10] memory _tempPrizes;
    // Loop as many times as what was paid for
    for (uint8 _i = 0; _i < _rounds[_requestId].times; _i++) {
      // Get a new random number for this loop
      uint256 _randomNumber = _expandRandomNumber(_randomness, _prizePoolSize - _i);
      // Pull a prize for this loop
      _tempPrizes[_i] = _prizePool[_randomNumber];
      // Reduce by 1 the number of copies for the pulled nft 
      nfts[_prizePool[_randomNumber]].amount--;
      // Remove the nft from the prize pool by overwriting it with the last nft in the prize pool
      _prizePool[_randomNumber] = _prizePool[_prizePoolSize - 1 - _i];
    }

    // Store prizes in the round
    _rounds[_requestId].prizes = _tempPrizes;
    // Decrease the proize pool size by the number of times played
    _prizePoolSize -= _rounds[_requestId].times;
    // Update round status
    _rounds[_requestId].status = RoundStatus.Unclaimed;
    // Update round status
    _pendingRoundsAmount -= _rounds[_requestId].times;
    emit RoundCompleted(_requestId, _rounds[_requestId].player, _rounds[_requestId].times, _rounds[_requestId].prizes);
  }

  function _expandRandomNumber(uint _randomNumber, uint _remainingNftsAmount) private pure returns (uint) {
    // Expand random number
    uint _expandedRandomNumber = uint(keccak256(abi.encode(_randomNumber, _remainingNftsAmount)));

    // Handle modulo bias, if _expandedRandomNumber is in the biased range, reroll it until it isn't
    while (_expandedRandomNumber >= MAX_UINT - (MAX_UINT % _remainingNftsAmount)) {
      // Re-generate random number
      _expandedRandomNumber = uint(keccak256(abi.encode(_randomNumber, _expandedRandomNumber)));
    }

    // Return key to the prize
    return _expandedRandomNumber % _remainingNftsAmount;
  }

  /// @dev Distribute tokens to all the recipent
  function _transferTokens(uint256 amount) private {
    uint256 _artistShare = amount * artistRate / 1000;
    uint256 _tokenomicsShare = amount * tokenomicsRate / 1000;
    uint256 _daoShare = amount * daoRate / 1000;
    uint256 _teamTreasuryShare = amount - _artistShare - _tokenomicsShare - _daoShare;

    // Distribute tokens to artist's profit addresses
    if (_artistShare > 0) {
      uint256 _dust = _distributeTokensToArtistProfitsAddresses(_artistShare);
      _teamTreasuryShare += _dust;
    }

    // Distribute tokens to the address in charge of token mechanics
    if (_tokenomicsShare > 0) {
      IERC20(currency).transferFrom(msg.sender, ITreasuryManager(deployer).tokenomicsManagerAddress(), _tokenomicsShare);
    }

    // Distribute tokens to the address of the DAO's treasury
    if (_daoShare > 0) {
      IERC20(currency).transferFrom(msg.sender, ITreasuryManager(deployer).daoTreasuryAddress(), _daoShare);
    }

    // Distribute tokens to the address of the team's treasury
    if (_teamTreasuryShare > 0) {
      IERC20(currency).transferFrom(msg.sender, ITreasuryManager(deployer).teamTreasuryAddress(), _teamTreasuryShare);
    }
  }

  /// @dev Will send their share of the profits to every addresses in 'artistProfitsAddresses'
  function _distributeTokensToArtistProfitsAddresses(uint256 _tokenAmounts) private returns(uint256) {
    // If there are no profit addresses set, send everything to the artist's address
    if (artistProfitsAddresses.length == 0) {
      IERC20(currency).transferFrom(msg.sender, artist, _tokenAmounts);
      return 0;
    }

    uint256 _remaining = _tokenAmounts;
    // For each address, send its share of the tokens
    for(uint8 _i = 0; _i < artistProfitsAddresses.length; _i++) {
      uint256 _addressShare = _tokenAmounts * artistProfitsSharePerAddress[artistProfitsAddresses[_i]] / 1000;
      IERC20(currency).transferFrom(msg.sender, artistProfitsAddresses[_i], _addressShare);
      _remaining -= _addressShare;
    }

    // Return the dust
    return _remaining;
  }

  /// @notice Transfer the ownership of the gachapon to the artist
  function transferOwnership(address _newOwner) public override(IGachapon, Ownable) onlyOwner {
    setArtistAddress(_newOwner);
    super.transferOwnership(_newOwner);
  }

  /// @inheritdoc IGachapon
  function claimPrizes(bytes32 _requestId) external override {
    require(_rounds[_requestId].status == RoundStatus.Unclaimed, "This round is not ready to be claimed");

    // Loop for each time played
    for (uint i = 0; i < _rounds[_requestId].times; i++) {
    // Send every nft to the player
      IERC1155(nfts[_rounds[_requestId].prizes[i]].collection).safeTransferFrom(address(this), _rounds[_requestId].player, nfts[_rounds[_requestId].prizes[i]].id, 1, '0x');
    }

    // Update round's status
    _rounds[_requestId].status = RoundStatus.Completed;
    emit PrizesClaimed(_requestId);
  }

  /// @inheritdoc IGachapon
  function getRound(bytes32 _roundId) external view override returns (Round memory) {
    return _rounds[_roundId];
  }
  
  /// @inheritdoc IGachapon
  function getNft(uint256 _index) external view override returns(Nft memory) {
    return nfts[_index];
  }

  /// @inheritdoc IGachapon
  function getRemaningPrizesAmount() public view override returns(uint256) {
    return _prizePoolSize - _pendingRoundsAmount;
  }

  /// @inheritdoc StateManager
  function withdrawOracleTokens() external override onlyFromControlTower {
    IERC20(_oracleCurrency).transfer(ITreasuryManager(deployer).teamTreasuryAddress(), IERC20(_oracleCurrency).balanceOf(address(this)));
  }

  /// @inheritdoc StateManager
  function retryRound(bytes32 _requestId) external override onlyFromControlTower {
    require(_rounds[_requestId].status == RoundStatus.Pending, "Only pending rounds can be retried");
    _rounds[_requestId].status = RoundStatus.Cancelled;
    _pendingRoundsAmount -= _rounds[_requestId].times;
    
    emit RoundCancelled(_requestId);
    _startRound(_rounds[_requestId].player, _rounds[_requestId].times);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../gachapon/Gachapon.sol";
import "../interfaces/IGachapon.sol";
import "../interfaces/IGachaponFactory.sol";
import "../interfaces/IOracleManager.sol";

contract GachaponFactory is IGachaponFactory {
  /// @notice The control tower contract that can use this factory
  address public gachaponControlTower;

  constructor(address _gachaponControlTower) {
    gachaponControlTower = _gachaponControlTower;
  }

  /// @inheritdoc IGachaponFactory
  function createGachapon(string memory _machineTitle, address _currency) override external returns (IGachapon) {
    require(address(gachaponControlTower) == address(msg.sender), "Unauthorized");

    // Deploy the smart contract
    Gachapon _gachapon = new Gachapon(
      _machineTitle,
      _currency,
      gachaponControlTower
    );

    // Transfer ownership to deployer
    _gachapon.transferOwnership(msg.sender);

    return IGachapon(_gachapon);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @author KirienzoEth for DokiDoki
/// @title Contract managing the prize pool of the gachapon
contract PrizePoolManager is Ownable, IERC1155Receiver {
  using ERC165Checker for address;

  struct Nft {
    address collection;
    uint256 id;
    uint256 amount;
  }

  /// @dev Interface id of the IERC1155 interface for the ERC165Checker
  bytes4 constant private INTERFACE_ID_ERC1155 = 0xd9b67a26;
  /// @dev All the nfts that were ever added to this gachapon
  mapping(uint => Nft) internal nfts;
  /// @notice The number of different nfts in the gachapon
  uint public nftsAmount;
  /// @notice Is the gachapon locked forever
  /// @dev This is set to true whenever the owner removes NFTs from the prize pool
  bool public isLockedForever = false;

  /// @dev Contains every nft available as a prize, anything above the index '_prizePoolSize - 1' is invalid
  mapping(uint => uint) internal _prizePool;
  /// @notice The number prizes remaining
  uint internal _prizePoolSize;
  /// @dev Get the index of the nft from its collection and tokenId
  mapping(address => mapping(uint => uint)) internal _collectionToTokenIdToIndex;

  EnumerableSet.AddressSet internal _collectionsSet;

  event NftAdded(address indexed _collection, uint _id, uint _amount);
  event NftsAdded(address indexed _collection, uint[] _ids, uint[] _amounts);
  event NftRemoved(address indexed _collection, uint _id, uint _amount);

  function registerNft(address _collection, uint _id, uint _amount) private {
    require(!isLockedForever, "You cannot add more NFTs to an unusable machine");
    require(EnumerableSet.contains(_collectionsSet, _collection) || EnumerableSet.length(_collectionsSet) == 0, "Gachapon only support one collection");

    EnumerableSet.add(_collectionsSet, _collection);
    // If the nft was never previously added
    if (_prizePoolSize == 0 || nfts[_collectionToTokenIdToIndex[_collection][_id]].id != _id) {
      // Store the index of the nft in the nfts array
      _collectionToTokenIdToIndex[_collection][_id] = nftsAmount;
      // Store the reference to the nft
      nfts[nftsAmount] = Nft(_collection, _id, _amount);
      // Increase the number of nfts in the machine
      nftsAmount++;
    } else {
      // Increase the amount of copies of the nft present in the machine
      nfts[_collectionToTokenIdToIndex[_collection][_id]].amount += _amount;
    }

    // Add all the copies to the prize pool
    for (uint _i = 0; _i < _amount; _i++) {
      _prizePool[_i + _prizePoolSize] = _collectionToTokenIdToIndex[_collection][_id];
    }
    
    // Increase the number of nft in the prize pool
    _prizePoolSize += _amount;
  }

  /// @notice Remove `_amount` of token ID `_id`, doing this will lock the gachapon forever
  /// @dev Doing this will put the prize pool in an invalid state
  function removeNft(address _collection, uint _id, uint _amount) external onlyOwner {
    require(_amount > 0, "You need to remove at least 1 nft");
    require(EnumerableSet.contains(_collectionsSet, _collection), "This collection is not in the gachapon");
    require(_prizePoolSize > 0 && nfts[_collectionToTokenIdToIndex[_collection][_id]].id == _id, "This token ID is not in the gachapon");
    require(nfts[_collectionToTokenIdToIndex[_collection][_id]].amount >= _amount , "There is not enough of this nft in the gachapon");

    // Make the gachapon unusable
    isLockedForever = true;
    // Reduce the supply of said nft
    nfts[_collectionToTokenIdToIndex[_collection][_id]].amount -= _amount;
    // Reduce the number of remaining prizes
    _prizePoolSize -= _amount;
    // Send nfts to the owner
    IERC1155(_collection).safeTransferFrom(address(this), msg.sender, _id, _amount, "");

    emit NftRemoved(_collection, _id, _amount);
  }

  /// @inheritdoc IERC1155Receiver
  function onERC1155Received(
      address,
      address _from,
      uint256 _id,
      uint256 _value,
      bytes calldata
  ) override external returns (bytes4) {
    require(msg.sender.supportsInterface(INTERFACE_ID_ERC1155), "Only accessible with method safeTransferFrom from your ERC1155 collection");
    require(_from == owner(), "Only the owner can add nfts");

    registerNft(msg.sender, _id, _value);
    emit NftAdded(msg.sender, _id, _value);

    return this.onERC1155Received.selector;
  }

  /// @inheritdoc IERC1155Receiver
  function onERC1155BatchReceived(
      address,
      address _from,
      uint256[] calldata _ids,
      uint256[] calldata _values,
      bytes calldata
  ) override external returns (bytes4) {
    require(msg.sender.supportsInterface(INTERFACE_ID_ERC1155), "Only accessible with method safeBatchTransferFrom from your ERC1155 collection");
    require(_from == owner(), "Only the owner can add nfts");

    // For each token id in the batch
    for (uint _i = 0; _i < _ids.length; _i++) {
      registerNft(msg.sender, _ids[_i], _values[_i]);
    }
    
    emit NftsAdded(msg.sender, _ids, _values);

    return this.onERC1155BatchReceived.selector;
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) override external pure returns (bool) {
    return interfaceId == INTERFACE_ID_ERC1155;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IDeployerControlledState.sol";

/// @title Contract that 
/// @author KirienzoEth for DokiDoki
abstract contract StateManager is Ownable, IDeployerControlledState {
  /// @notice Get the title of the gachapon
  string public title;
  /// @notice Get the description of the gachapon
  string public description;
  
  /// @notice Is the gachapon locked
  /// @dev A locked gachapon can't be played, the owner can lock and unlock at will
  bool public isLocked = true;
  /// @notice Is the gachapon banned
  /// @dev A banned gachapon can't be played, and can only be unbanned by an admin
  bool public isBanned = false;
  /// @notice Get the price for one play
  uint256 public playOncePrice;
  /// @notice Get the address of the artist
  address public artist;
  /// @dev the address of the controle tower that deployed this gachapon
  address public immutable deployer;

  /// @notice Get the percentage allocated to the artist
  uint16 public artistRate = 700;
  /// @notice Get the percentage allocated to the token mechanics
  uint16 public tokenomicsRate = 150;
  /// @notice Get the percentage allocated to the dao
  uint16 public daoRate = 0;

  mapping(address => uint16) public artistProfitsSharePerAddress;
  address[] public artistProfitsAddresses;
  uint256 public artistProfitsAddressesAmount;
  
  event PlayOncePriceChanged(uint _price);
  event TitleChanged(string _title);
  event DescriptionChanged(string _description);
  event LockStatusChanged(bool _isLocked);
  event ArtistAddressChanged(address _address);

  constructor(address _deployer) {
    deployer = _deployer;
  }

  /// @notice Set price to `_price` WEI
  function setPlayOncePrice(uint256 _newPrice) external onlyOwner {
    playOncePrice = _newPrice;

    emit PlayOncePriceChanged(_newPrice);
  }

  /// @notice Set artist address to `_address`
  function setArtistAddress(address _address) public onlyOwner {
    artist = _address;

    emit ArtistAddressChanged(_address);
  }

  /// @notice Lock the gachapon
  function lock() external onlyOwner {
    isLocked = true;
    emit LockStatusChanged(isLocked);
  }

  /// @notice Unlock the gachapon
  function unlock() external onlyOwner {
    isLocked = false;
    emit LockStatusChanged(isLocked);
  }

  /// @notice Set `_title` as the title of the gachapon
  function setTitle(string memory _title) external onlyOwner {
    title = _title;
    
    emit TitleChanged(_title);
  }

  /// @notice Set `_description` as the description of the gachapon
  function setDescription(string memory _description) external onlyOwner {
    description = _description;
    
    emit DescriptionChanged(_description);
  }

  /// @inheritdoc IDeployerControlledState
  function ban() external override onlyFromControlTower {
    isBanned = true;
    emit BanStatusChanged(isBanned);
  }

  /// @inheritdoc IDeployerControlledState
  function unban() external override onlyFromControlTower {
    isBanned = false;
    emit BanStatusChanged(isBanned);
  }

  /// @inheritdoc IDeployerControlledState
  function setArtistProfitsSharing(address[] memory _addresses, uint16[] memory _rates) external override onlyFromControlTower {
    require(_addresses.length == _rates.length, "The number of addresses should be equal to the number of rates");
    require(_addresses.length <= 10, "You can't set more than 10 addresses");

    // Keep track of the sum of all the rates
    uint16 _sumOfRates = 0;
    // Create an array to check for duplicates
    address[10] memory _addedAddresses;
    // Update the profits addresses
    artistProfitsAddresses = _addresses;
    // Update the profits addresses amount
    artistProfitsAddressesAmount = artistProfitsAddresses.length;
    // For each address provided
    for(uint _i = 0; _i < artistProfitsAddressesAmount; _i++) {
      // Store its rate
      artistProfitsSharePerAddress[_addresses[_i]] = _rates[_i];
      // Check if there is no duplicate in the array of addresses
      for(uint _j = 0; _j < _addresses.length; _j++) {
        require(_addedAddresses[_j] != _addresses[_i], "All the addresses in the array should be unique");
      }
      // Add the rate to the sum of all the rates
      _sumOfRates += _rates[_i];
      // Add the address to the array for checking duplicates
      _addedAddresses[_i] = _addresses[_i];
    }

    require(_sumOfRates == 1000, "The sum of all the rates must equal 1000");

    emit ArtistProfitsSharingChanged(_addresses, _rates);
  }

  /// @inheritdoc IDeployerControlledState
  function setArtistRate(uint16 _rate) external override onlyFromControlTower {
    require(tokenomicsRate + daoRate + _rate <= 1000, "Rate is too high");
    artistRate = _rate;
    emit ArtistRateChanged(_rate);
  }

  /// @inheritdoc IDeployerControlledState
  function setTokenomicsRate(uint16 _rate) external override onlyFromControlTower {
    require(artistRate + daoRate + _rate <= 1000, "Rate is too high");
    tokenomicsRate = _rate;
    emit TokenomicsRateChanged(_rate);
  }

  /// @inheritdoc IDeployerControlledState
  function setDaoRate(uint16 _rate) external override onlyFromControlTower {
    require(artistRate + tokenomicsRate + _rate <= 1000, "Rate is too high");
    daoRate = _rate;
    emit DaoRateChanged(_rate);
  }

  /// @inheritdoc IDeployerControlledState
  function withdrawOracleTokens() external virtual override;

  /// @inheritdoc IDeployerControlledState
  function retryRound(bytes32) external virtual override;

  /// @dev Only authorize the deployer contract to interact with those methods
  modifier onlyFromControlTower() {
    require(address(msg.sender) == deployer, "Only for deployer");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title Interface exposing the gachapon methods that are only callable from the GachaponControlTower
/// @author KirienzoEth for DokiDoki
interface IDeployerControlledState {
  /// @notice Ban the gachapon
  function ban() external;
  /// @notice Unban the gachapon
  function unban() external;

  /// @notice Set the cut of the artist to `_rate` / 1000, the sum of all the rates can't exceed 1000
  function setArtistRate(uint16 _rate) external;
  /// @notice Set the cut of the token mechanics to `_rate` / 1000, the sum of all the rates can't exceed 1000
  function setTokenomicsRate(uint16 _rate) external;
  /// @notice Set the cut of the DAO to `_rate` / 1000, the sum of all the rates can't exceed 1000
  function setDaoRate(uint16 _rate) external;
  /// @notice Set the addresses and rate of their respective shares of the artist's profits / 1000
  /// @param _addresses Array of addresses that will receive a share of the artsit's profits, must be unique
  /// @param _rates Rates for each address, must be equal to 1000
  function setArtistProfitsSharing(address[] memory _addresses, uint16[] memory _rates) external;
  /// @notice Will send all the oracle tokens in the gachapon to the treasury address
  function withdrawOracleTokens() external;
  /// @dev Only use this when the oracle failed to answer for a request ID
  /// @dev NEVER USE OUTSIDE OF THIS SCENARIO
  function retryRound(bytes32) external;

  event ArtistRateChanged(uint16 _rate);
  event ArtistProfitsSharingChanged(address[] _addresses, uint16[] _rates);
  event TokenomicsRateChanged(uint16 _rate);
  event DaoRateChanged(uint16 _rate);
  event BanStatusChanged(bool _isBanned);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../gachapon/PrizePoolManager.sol";

/// @title Interface implemented by all gachapons created by the GachaponControlTower
/// @author KirienzoEth for DokiDoki
interface IGachapon {
  /// @dev Undefined = Round doesn't exist, Pending = waiting for oracle response, Unclaimed = oracle answered, Completed = Prizes were withdrawn
  enum RoundStatus { Undefined, Pending, Unclaimed, Completed, Cancelled }
  struct Round {
    bytes32 id; // request id.
    address player; // address of player.
    RoundStatus status; // status of the round.
    uint8 times; // how many times of this round;
    uint256[10] prizes; // Prizes obtained in this round.
  }

  /// @notice Get the state of a round
  function getRound(bytes32 _roundId) external returns (Round memory);
  /// @notice Get the token address of the currency used by this gachapon
  function currency() external returns (address);
  /// @notice Play the gachapon `_times` times
  function play(uint8 _times) external;
  /// @notice Claim the prizes won in a round
  function claimPrizes(bytes32 _roundId) external;
  /// @notice Transferring ownership also change the artist's address
  function transferOwnership(address _newOwner) external;
  /// @notice Get the nft at index `_index`
  function getNft(uint256 _index) external returns(PrizePoolManager.Nft memory);
  /// @notice Return the number of prizes that are still available
  function getRemaningPrizesAmount() external returns(uint256);

  /// @dev Player paid and oracle was contacted, refer to plays(_playId) to check if the prizes were distributed or not
  event RoundStarted(bytes32 indexed _requestId, address indexed _player, uint8 _times);
  /// @dev Oracle answered and the drawn prizes were stored, numbers in _prizes are indexes of the variable 'nfts'
  event RoundCompleted(bytes32 indexed _requestId, address indexed _player, uint8 _times, uint256[10] _prizes);
  /// @dev Oracle didn't answer and we need to try again
  event RoundCancelled(bytes32 _requestId);
  /// @dev Stored prizes were sent to the user
  event PrizesClaimed(bytes32 indexed _requestId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IGachapon.sol";

interface IGachaponFactory {
  /// @notice Deploy a new Gachapon contract and returns its address
  /// @dev Deployed gachapon will always implement the IGachapon interface
  function createGachapon(string memory _machineTitle, address _currency) external returns (IGachapon);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IOracleManager {
  /// @notice Get the oracle key hash
  function oracleKeyHash() external returns(bytes32);
  /// @notice Get how much a call tro the VRF oracle costs in WEI
  function oracleFee() external returns(uint256);
  /// @notice Get the oracle currency address
  function oracleToken() external returns(address);
  /// @notice Get the address of the VRF coordinator
  function oracleVRFCoordinator() external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ITreasuryManager {
  /// @notice Address of the wallet of the doki team funds
  function teamTreasuryAddress() external returns(address);
  /// @notice Address of the wallet of the DAO treasury
  function daoTreasuryAddress() external returns(address);
  /// @notice Address of the wallet managing buybacks\burns
  function tokenomicsManagerAddress() external returns(address);
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
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

/*
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

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165(account).supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}