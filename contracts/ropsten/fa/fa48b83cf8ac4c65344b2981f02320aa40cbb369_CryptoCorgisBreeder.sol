//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./FactoryERC1155.sol";

contract CryptoCorgisBreeder is Ownable, FactoryERC1155, ERC1155 {
  using SafeMath for uint256;

  event CorgiSold(uint256 corgiNumber, uint256 blockNumber, uint8 mutantCorgiId, address owner);

  uint256 public constant MAX_INT_256 = 2**256 - 1;
  uint256 public constant MAX_CORGIS_MINTED = 10000;
  uint256 public constant CORGI_LIFESPAN_BLOCKS = 256;
  uint256 public constant FIRST_CORGI_PRICE_ETH = 1e16;
  uint256 public constant INCREMENTAL_PRICE_ETH = 1e14;
  uint256 public constant NUMBER_MUTANT_CORGIS = 31;
  // Each mutant corgi has a probability of 6/2^16 of being born.
  uint256 public constant MUTANT_CORGI_PROBABILITY = NUMBER_MUTANT_CORGIS * 6;

  address payable public treasuryAddress;
  uint256 public corgisMinted = 0;

  mapping(uint256 => uint256) public corgiNumberToBlockNumber;
  mapping(uint256 => uint256) public blockNumberToCorgiNumber;
  mapping(uint8 => uint256) public mutantCorgiIdToBlockNumber;
  mapping(uint256 => string) public corgiIdToName;

  string private contractDataURI;

  constructor(
    string memory _metadataURI,
    string memory _contractDataURI,
    address payable _treasuryAddress
  ) ERC1155(_metadataURI) {//eg: IPFS :https://ipfs.io/ipfs/      other:  https://img.cryptocorgis.co/
    contractDataURI = _contractDataURI;//项目介绍
    treasuryAddress = _treasuryAddress;//收益地址
  }

  /// @dev https://docs.opensea.io/docs/2-custom-sale-contract-viewing-your-sale-assets-on-opensea
  function name() external pure override returns (string memory) {
    return "Crypto Corgis Breeder";
  }

  function symbol() external pure override returns (string memory) {
    return "CORGI";
  }

  function numOptions() external pure override returns (uint256) {
    return MAX_INT_256;
  }

  /**
   * Indicates that this is a factory contract.
   */
  function supportsFactoryInterface() external pure override returns (bool) {
    return true;
  }

  /**
   * Indicates the Wyvern schema name for assets in this factory, e.g. "ERC1155"
   */
  function factorySchemaName() external pure override returns (string memory) {
    return "ERC1155";
  }

  function getClaimedCorgis() external view returns (uint256[] memory) {
    uint256[] memory blockNumbers = new uint256[](corgisMinted);
    for (uint256 i = 0; i < corgisMinted; i++) {
      blockNumbers[i] = corgiNumberToBlockNumber[i + 1];
    }
    return blockNumbers;
  }

  /// @dev can only can a corgi once and only if you own it.
  function nameCorgi(uint256 id, string memory name) public {
    require(balanceOf(msg.sender, id) == 1, "CryptoCorgisBreeder: Cannot name a corgi you do not own");
    require(bytes(name).length > 0, "CryptoCorgisBreeder: Cannot erase a corgi name");
    require(bytes(corgiIdToName[id]).length == 0, "CryptoCorgisBreeder: Can only name a corgi once");
    corgiIdToName[id] = name;
  }

  /// @dev https://docs.opensea.io/docs/contract-level-metadata
  function contractURI() public view returns (string memory) {
    return contractDataURI;
  }

  /// @dev Allow the deployer to change the smart contract meta-data.
  function setContractDataURI(string memory _contractDataURI) public onlyOwner {
    contractDataURI = _contractDataURI;
  }

  // @dev Allow the deployer to change the ERC-1155 URI
  function setURI(string memory _uri) public onlyOwner {
    _setURI(_uri);
  }

  function dnaForBlockNumber(uint256 _blockNumber) external pure returns (bytes32) {
    return keccak256(abi.encodePacked(_blockNumber));
  }

  /**
   * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
   * restrict a total supply per option ID (or overall).
   */
  function canMint(uint256 _blockNumber, uint256 _amount) public view override returns (bool) {
    (bool _, uint256 subResult) = block.number.trySub(CORGI_LIFESPAN_BLOCKS);
    if (_blockNumber > block.number || _blockNumber < subResult || _amount > 1) {
      return false;
    }
    return blockNumberToCorgiNumber[_blockNumber] == 0;
  }

  function priceForCorgi(uint256 _corgiNumber) public pure returns (uint256) {
    return FIRST_CORGI_PRICE_ETH.add(INCREMENTAL_PRICE_ETH.mul(_corgiNumber.sub(1)));
  }

  function isMutantCorgi(uint256 _blockNumber) public pure returns (bool, uint8) {
    return isMutantCorgi(keccak256(abi.encodePacked(_blockNumber)));
  }

  /// @dev Return whether a corgi with this DNA is a mutant, and what mutation ID it has.
  function isMutantCorgi(bytes32 _corgiDna) public pure returns (bool, uint8) {
    uint256 corgiDnaNum = uint256(_corgiDna);
    uint16 lastTwoBytesValue = uint16(corgiDnaNum);
    if (lastTwoBytesValue < MUTANT_CORGI_PROBABILITY) {
      return (true, uint8(lastTwoBytesValue / 6) + 1);
    }
    return (false, 0);
  }

  function mint(uint256 _blockNumber, bytes calldata _data) public payable {
    mint(_blockNumber, msg.sender, 1, msg.sender, _data);
  }

  function mint(
    uint256 _blockNumber,
    address _toAddress,
    uint256 _amount,
    bytes calldata _data
  ) public payable override {
    mint(_blockNumber, _toAddress, _amount, msg.sender, _data);
  }

  function mint(
    uint256 _blockNumber,
    address _toAddress,
    uint256 _amount,
    address payable _refundAddress,
    bytes calldata _data
  ) public payable {
    require(corgisMinted < MAX_CORGIS_MINTED, "CryptoCorgisBreeder: Cannot mint any more Crypto Corgis");
    require(canMint(_blockNumber, _amount), "CryptoCorgisBreeder: Not allowed to mint for that block number");
    uint256 nextCorgiId = corgisMinted + 1;
    uint256 price = priceForCorgi(nextCorgiId);
    require(msg.value >= price, "CryptoCorgisBreeder: Insufficient funds to mint a Crypto Corgi");
    treasuryAddress.transfer(price);
    _refundAddress.transfer(msg.value.sub(price));
    bytes32 corgiDna = keccak256(abi.encodePacked(_blockNumber));
    (bool isMutant, uint8 mutantId) = isMutantCorgi(corgiDna);
    if (isMutant) {
      require(mutantCorgiIdToBlockNumber[mutantId] == 0, "CryptoCorgisBreeder: Crypto Corgi mutant already claimed");
      mutantCorgiIdToBlockNumber[mutantId] = _blockNumber;
    }
    corgiNumberToBlockNumber[nextCorgiId] = _blockNumber;
    blockNumberToCorgiNumber[_blockNumber] = nextCorgiId;
    // Use _blockNumber as ID.
    _mint(_toAddress, _blockNumber, 1, _data);
    corgisMinted = nextCorgiId;
    emit CorgiSold(nextCorgiId, _blockNumber, mutantId, _toAddress);
  }
}