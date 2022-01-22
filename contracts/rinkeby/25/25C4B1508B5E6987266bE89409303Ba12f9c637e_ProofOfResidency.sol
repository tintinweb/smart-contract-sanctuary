// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import './ERC721.sol';

/// @custom:security-contact [email protected]
contract ProofOfResidency is ERC721Enumerable {
  uint256 private constant BASE_PRICE = (1 ether * 5) / 1000;
  uint256 private constant LOCATION_MULTIPLIER = 1e15;

  uint256 public mintPrice;

  address private immutable _treasury;

  address private _committer;
  address private _owner;

  /// @notice The struct to represent commitments to an address
  struct Commitment {
    uint256 invalidAt;
    bytes32 commitment;
  }

  mapping(address => Commitment) private _commitments;
  mapping(uint256 => uint256) private _countriesTokenCounts;

  uint256 private _totalContribution;
  uint256 private _totalWithdrawn;

  bool public isPaused;

  event CommitmentCreated(address indexed _to, bytes32 _commitment);

  // slither-disable-next-line missing-zero-check
  constructor(
    address owner,
    address committer,
    address treasury
  ) ERC721('Proof of Residency', 'POR') {
    _owner = owner;
    _committer = committer;
    _treasury = treasury;

    mintPrice = BASE_PRICE;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == msg.sender, 'Caller is not the owner');
    _;
  }

  /**
   * @dev Throws if the contract has been marked paused by the owner.
   */
  modifier notPaused() {
    require(!isPaused, 'The contract is currently paused');
    _;
  }

  /**
   * @notice Contract URI for OpenSea and other NFT services.
   */
  function contractURI() external pure returns (string memory) {
    return string(abi.encodePacked(_baseURI(), 'contract'));
  }

  /**
   * @notice Toggles the isPaused state.
   */
  function toggleIsPaused() external onlyOwner {
    isPaused = !isPaused;
  }

  /**
   * @notice  Sets the committer for the contract.
   */
  function setCommitter(address committer) external onlyOwner {
    // slither-disable-next-line missing-zero-check
    _committer = committer;
  }

  /**
   * @notice Sets the value required to mint an NFT. Deliberately as low as possible,
   * this may be changed to be higher/lower.
   */
  function setPrice(uint256 price) external onlyOwner {
    require(price >= BASE_PRICE, 'Cannot set below base price');
    mintPrice = price;
  }

  /**
   * @notice Mints a new NFT for the given country/secret.
   */
  function mint(uint256 country, string memory secret)
    external
    payable
    notPaused
    returns (uint256)
  {
    Commitment storage existingCommitment = _commitments[msg.sender];

    require(msg.value == mintPrice, 'Incorrect ETH sent');
    require(
      existingCommitment.commitment == keccak256(abi.encode(msg.sender, country, secret)),
      'Commitment is incorrect'
    );
    // slither-disable-next-line timestamp
    require(block.timestamp <= existingCommitment.invalidAt, 'Time limit reached');

    _totalContribution += msg.value;

    _countriesTokenCounts[country] += 1; // increment before minting so count starts at 1
    uint256 tokenId = country * LOCATION_MULTIPLIER + _countriesTokenCounts[country];

    _safeMint(msg.sender, tokenId);

    return tokenId;
  }

  /**
   * @notice Commits an address to a country.
   */
  function commitAddress(address to, bytes32 commitment) external notPaused {
    require(_committer == msg.sender, 'Caller is not the committer');

    Commitment storage existingCommitment = _commitments[to];

    // slither-disable-next-line timestamp
    require(
      existingCommitment.commitment == 0 || block.timestamp > existingCommitment.invalidAt,
      'Address has existing commitment'
    );

    existingCommitment.invalidAt = block.timestamp + 12 weeks;
    existingCommitment.commitment = commitment;

    emit CommitmentCreated(to, commitment);
  }

  /**
   * @dev Withdraws a specified amount of funds from the contract to the treasury.
   */
  function withdraw(uint256 amount) external onlyOwner {
    require((_totalContribution - _totalWithdrawn) >= amount, 'Withdrawal amount not available');

    _totalWithdrawn += amount;

    // slither-disable-next-line low-level-calls
    (bool success, ) = _treasury.call{ value: amount }('');
    require(success, 'Unable to withdraw');
  }

  function currentCountryCount(uint256 country) external view returns (uint256) {
    return _countriesTokenCounts[country];
  }

  function _baseURI() internal pure override returns (string memory) {
    return 'ipfs://bafybeihrbi6ghrxckdzlitupwnxzicocrfeuqqoavktxp7oruw2bbejdhu/';
  }
}