// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import './MintableBoxConfigHandler.sol';
import './MintableBoxOpeningHandler.sol';
import './MintableBoxMintingHandler.sol';

contract MintableBox is MintableBoxOpeningHandler, MintableBoxMintingHandler, IMintableBox {
  constructor(InitialConfig memory _initialConfig)
    MintableBoxConfigHandler(_initialConfig)
    MintableBoxERC721Handler(_initialConfig)
    MintableBoxOpeningHandler(_initialConfig)
  {}

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(MintableBoxOpeningHandler, ERC721Enumerable, IERC165)
    returns (bool)
  {
    return MintableBoxOpeningHandler.supportsInterface(_interfaceId);
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal override(MintableBoxOpeningHandler, ERC721Enumerable) {
    MintableBoxOpeningHandler._beforeTokenTransfer(_from, _to, _tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IMintableBox.sol';

abstract contract MintableBoxConfigHandler is Ownable, IMintableBoxConfigHandler {
  /// @inheritdoc IMintableBoxConfigHandler
  uint16 public constant MAX_DEV_FEE = 10000; // Represents 100%
  /// @inheritdoc IMintableBoxConfigHandler
  uint32 public activationDate;
  /// @inheritdoc IMintableBoxConfigHandler
  address public devAddress;
  /// @inheritdoc IMintableBoxConfigHandler
  address public rewardPool;
  /// @inheritdoc IMintableBoxConfigHandler
  uint16 public devFee;
  /// @inheritdoc IMintableBoxConfigHandler
  mapping(string => uint256) public mintPriceInUSD; // Will use 8 decimals
  /// @inheritdoc IMintableBoxConfigHandler
  AggregatorV3Interface public priceOracle;
  /// @inheritdoc IMintableBoxConfigHandler
  string public baseURI;
  /// @inheritdoc IMintableBoxConfigHandler
  IERC20Metadata public paymentToken;
  /// @inheritdoc IMintableBoxConfigHandler
  uint32 public maxDelay;
  /// @inheritdoc IMintableBoxConfigHandler
  IRPSNFT public nftMintingContract;

  constructor(IMintableBox.InitialConfig memory _initialConfig) {
    if (
      _initialConfig.rewardPool == address(0) ||
      _initialConfig.devAddress == address(0) ||
      address(_initialConfig.priceOracle) == address(0) ||
      address(_initialConfig.paymentToken) == address(0) ||
      address(_initialConfig.nftMintingContract) == address(0)
    ) revert ZeroAddress();
    if (_initialConfig.devFee > MAX_DEV_FEE) revert DevFeeTooHigh();
    if (_initialConfig.mintPrices.length == 0) revert ZeroMintPrice();
    if (bytes(_initialConfig.baseURI).length == 0) revert EmptyBaseURI();
    if (_initialConfig.maxDelay == 0) revert ZeroMaxDelay();
    activationDate = _initialConfig.activationDate;
    rewardPool = _initialConfig.rewardPool;
    devAddress = _initialConfig.devAddress;
    devFee = _initialConfig.devFee;
    priceOracle = _initialConfig.priceOracle;
    baseURI = _initialConfig.baseURI;
    paymentToken = _initialConfig.paymentToken;
    for (uint256 i; i < _initialConfig.mintPrices.length; i++) {
      MintPrice memory _mintPrice = _initialConfig.mintPrices[i];
      if (_mintPrice.mintPriceInUSD == 0) revert ZeroMintPrice();
      mintPriceInUSD[_mintPrice.nftType] = _mintPrice.mintPriceInUSD;
    }
    maxDelay = _initialConfig.maxDelay;
    nftMintingContract = _initialConfig.nftMintingContract;
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setActivationDate(uint32 _newDate) external onlyOwner {
    activationDate = _newDate;
    emit NewActivationDate(_newDate);
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setRewardPool(address _newRewardPool) external onlyOwner {
    if (_newRewardPool == address(0)) revert ZeroAddress();
    rewardPool = _newRewardPool;
    emit NewRewardPool(_newRewardPool);
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setDevAddress(address _newDevAddress) external onlyOwner {
    if (_newDevAddress == address(0)) revert ZeroAddress();
    devAddress = _newDevAddress;
    emit NewDevAddress(_newDevAddress);
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setDevFee(uint16 _devFee) external onlyOwner {
    if (_devFee > MAX_DEV_FEE) revert DevFeeTooHigh();
    devFee = _devFee;
    emit NewDevFee(_devFee);
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setMintPriceInUSD(string calldata _type, uint256 _mintPrice) external onlyOwner {
    mintPriceInUSD[_type] = _mintPrice;
    emit NewMintPrice(_type, _mintPrice);
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setPriceOracle(AggregatorV3Interface _newPriceOracle) external onlyOwner {
    if (address(_newPriceOracle) == address(0)) revert ZeroAddress();
    priceOracle = _newPriceOracle;
    emit NewPriceOracle(_newPriceOracle);
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setBaseURI(string calldata _newBaseURI) external onlyOwner {
    if (bytes(_newBaseURI).length == 0) revert EmptyBaseURI();
    baseURI = _newBaseURI;
    emit NewBaseURI(_newBaseURI);
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setPaymentToken(IERC20Metadata _newPaymentToken) external onlyOwner {
    if (address(_newPaymentToken) == address(0)) revert ZeroAddress();
    paymentToken = _newPaymentToken;
    emit NewPaymentToken(_newPaymentToken);
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setMaxDelay(uint32 _newMaxDelay) external onlyOwner {
    if (_newMaxDelay == 0) revert ZeroMaxDelay();
    maxDelay = _newMaxDelay;
    emit NewMaxDelay(_newMaxDelay);
  }

  /// @inheritdoc IMintableBoxConfigHandler
  function setNFTMintingContract(IRPSNFT _netMintingContract) external onlyOwner {
    if (address(_netMintingContract) == address(0)) revert ZeroAddress();
    nftMintingContract = _netMintingContract;
    emit NewMintingContract(_netMintingContract);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import './MintableBoxERC721Handler.sol';
import '../RandomNumberGeneration/RandomNumberConsumer.sol';

abstract contract MintableBoxOpeningHandler is MintableBoxERC721Handler, RandomNumberConsumer, IMintableBoxOpeningHandler {
  /// @inheritdoc IMintableBoxOpeningHandler
  mapping(uint256 => uint16) public requestByToken; // tokenId => requestId
  /// @inheritdoc IMintableBoxOpeningHandler
  mapping(uint16 => uint256) public tokenByRequest; // requestId => tokenId

  constructor(IMintableBox.InitialConfig memory _initialConfig) RandomNumberConsumer(_initialConfig.generator) {}

  /// @inheritdoc IMintableBoxOpeningHandler
  function openBox(uint256 _tokenId) external {
    address _owner = ownerOf(_tokenId);
    if (_owner != msg.sender) revert OnlyOwnerCanOpenBox();
    if (_isBoxBeingOpened(_tokenId)) revert BoxIsAlreadyBeingOpened();

    uint16 _requestId = _requestRandomNumber();
    requestByToken[_tokenId] = _requestId;
    tokenByRequest[_requestId] = _tokenId;
    emit OpeningRequested(_tokenId);
  }

  /// @inheritdoc IMintableBoxOpeningHandler
  function revertBoxOpenings(uint256[] calldata _tokenIds) external onlyOwner {
    // Note: when a user starts the opening process, they can't start it again, nor can they transfer the token. Since we rely on
    // an external actor to finish the opening process, something might fail along the way. In order to get our of this situation, the
    // contract owner has the ability to revert the opening of boxes. By doing so, the owner will be able to open it again,
    // or transfer/sell the box.
    for (uint256 i; i < _tokenIds.length; i++) {
      uint16 _requestId = requestByToken[_tokenIds[i]];
      if (_requestId == 0) revert BoxIsNotBeingOpened();
      delete requestByToken[_tokenIds[i]];
      delete tokenByRequest[_requestId];
    }
    emit OpeningsReverted(_tokenIds);
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721Enumerable, RandomNumberConsumer, IERC165) returns (bool) {
    return ERC721Enumerable.supportsInterface(_interfaceId) || RandomNumberConsumer.supportsInterface(_interfaceId);
  }

  function _isBoxBeingOpened(uint256 _tokenId) internal view returns (bool) {
    return requestByToken[_tokenId] > 0;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override(ERC721Enumerable) {
    // When a user wants to open a box, we need to request a random number from the generator. The random number will be returned
    // if a different tx, so someone could try to transfer/sell the box in the few blocks between request and response. We
    // don't want someone to buy a box and receive an already opened NFT, so we won't allow the transfer of boxes that are in the
    // middle of being opened.

    if (_from != address(0) && _to != address(0) && _isBoxBeingOpened(_tokenId)) revert CannotTransferUntilBoxIsOpened();
    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  function _consumeRandomNumber(uint16 _requestId, uint256 _randomness) internal override {
    uint256 _tokenId = tokenByRequest[_requestId];
    if (_tokenId == 0) revert BoxIsNotBeingOpened();

    address _owner = ownerOf(_tokenId);
    string memory _nftType = _tokenType[_tokenId];
    nftMintingContract.mint(_nftType, _owner, _randomness);

    // Burn box and do some clean up
    delete requestByToken[_tokenId];
    delete tokenByRequest[_requestId];
    _burn(_tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './MintableBoxERC721Handler.sol';

abstract contract MintableBoxMintingHandler is MintableBoxERC721Handler, IMintableBoxMintingHandler {
  using SafeERC20 for IERC20Metadata;

  /// @inheritdoc IMintableBoxMintingHandler
  function purchaseBox(string calldata _type, address _owner) external returns (uint256) {
    if (activationDate > block.timestamp) revert PurchasingNotAllowedYet();

    // Note: load to memory to avoid reading storage multiple times
    IERC20Metadata _paymentToken = paymentToken;

    // Get amount that needs to be payed, in `paymentToken`
    uint256 _amountRequired = _getPriceInToken(_type, _paymentToken);
    uint256 _amountForDev = (_amountRequired * devFee) / MAX_DEV_FEE;

    if (_amountForDev > 0) {
      _paymentToken.safeTransferFrom(msg.sender, devAddress, _amountForDev);
    }
    if (_amountForDev < _amountRequired) {
      _paymentToken.safeTransferFrom(msg.sender, rewardPool, _amountRequired - _amountForDev);
    }

    return _mint(_owner, _type);
  }

  /// @inheritdoc IMintableBoxMintingHandler
  function airdropMany(Airdrop[] calldata _airdrops) external onlyOwner {
    for (uint256 i; i < _airdrops.length; i++) {
      Airdrop memory _airdrop = _airdrops[i];
      for (uint256 j; j < _airdrop.boxes.length; j++) {
        for (uint256 k; k < _airdrop.boxes[j].amount; k++) {
          _mint(_airdrop.recipient, _airdrop.boxes[j].nftType);
        }
      }
    }
  }

  /// @inheritdoc IMintableBoxMintingHandler
  function airdrop(string calldata _nftType, address _recipient) external onlyOwner {
    _mint(_recipient, _nftType);
  }

  // Note: overridable for tests
  function _getPriceInToken(string calldata _nftType, IERC20Metadata _paymentToken) internal view virtual returns (uint256) {
    uint256 _priceInUSD = mintPriceInUSD[_nftType];
    if (_priceInUSD == 0) revert UnsupportedNFTType();

    (, int256 _answer, , uint256 _updatedAt, ) = priceOracle.latestRoundData();

    if (_answer <= 0) revert InvalidPriceFromOracle();
    if (block.timestamp >= maxDelay && _updatedAt <= block.timestamp - maxDelay) revert OutdatedPriceFromOracle();

    return (_priceInUSD * (10**_paymentToken.decimals())) / uint256(_answer);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './IRandomNumberConsumer.sol';
import './IRandomNumberGenerator.sol';
import './IRPSNFT.sol';
import './IShared.sol';

/// @notice Handles all configuration of the mintable box
interface IMintableBoxConfigHandler {
  struct MintPrice {
    string nftType;
    uint256 mintPriceInUSD; // Will use 8 decimals
  }

  /// @notice Emitted when a new activation date is set
  /// @param newActivationDate The new activation date
  event NewActivationDate(uint32 newActivationDate);

  /// @notice Emitted when a new reward pool address is set
  /// @param newRewardPool The address of the reward pool
  event NewRewardPool(address newRewardPool);

  /// @notice Emitted when a new dev address is set
  /// @param newDevAddress The dev address
  event NewDevAddress(address newDevAddress);

  /// @notice Emitted when a new dev fee is set
  /// @param newDevFee The dev fee
  event NewDevFee(uint16 newDevFee);

  /// @notice Emitted when a new mint price is set
  /// @param nftType The type of NFT
  /// @param newMintPrice The new mint price
  event NewMintPrice(string nftType, uint256 newMintPrice);

  /// @notice Emitted when a new price oracle is set
  /// @param newPriceOracle The new price oracle
  event NewPriceOracle(AggregatorV3Interface newPriceOracle);

  /// @notice Emitted when a new payment token is set
  /// @param newPaymentToken The new token used for payment
  event NewPaymentToken(IERC20Metadata newPaymentToken);

  /// @notice Emitted when a new base for the URI is set
  /// @param newBaseURI The new base
  event NewBaseURI(string newBaseURI);

  /// @notice Emitted when a new max delay for the oracle price is set
  /// @param newMaxDelay The new max delay
  event NewMaxDelay(uint32 newMaxDelay);

  /// @notice Emitted when a new minting contract is set
  /// @param newMintingContract The new minting contract
  event NewMintingContract(IRPSNFT newMintingContract);

  /// @notice Thrown when trying to set a dev fee higher than the allowed
  error DevFeeTooHigh();

  /// @notice Thrown when trying to set zero as the mint price
  error ZeroMintPrice();

  /// @notice Thrown when the max delay is zero
  error ZeroMaxDelay();

  /// @notice Returns the date when the minting can start
  /// @return The date (in seconds) when minting will be activated
  function activationDate() external view returns (uint32);

  /// @notice Returns the address of the reward pool
  /// @return The address of the reward pool
  function rewardPool() external view returns (address);

  /// @notice Returns the dev address
  /// @return The dev address
  function devAddress() external view returns (address);

  /// @notice Returns the maximum possible dev fee
  /// @dev Cannot be modified
  /// @return The maximum possible dev fee
  // solhint-disable-next-line func-name-mixedcase
  function MAX_DEV_FEE() external view returns (uint16);

  /// @notice Returns the dev fee
  /// @return The dev fee
  function devFee() external view returns (uint16);

  /// @notice Returns the mint price in usd for the given type
  /// @param nftType The type of NFT
  /// @return The mint price (using 8 decimals)
  function mintPriceInUSD(string calldata nftType) external view returns (uint256);

  /// @notice Returns the address of the price oracle
  /// @return The address of the price oracle
  function priceOracle() external view returns (AggregatorV3Interface);

  /// @notice Returns the base for the URI
  /// @return The base for the URI
  function baseURI() external view returns (string memory);

  /// @notice Returns the address of the payment token
  /// @return The payment token
  function paymentToken() external view returns (IERC20Metadata);

  /// @notice Returns how old the last price update can be before the oracle reverts by considering it too old
  /// @return How old the last price update can be in seconds
  function maxDelay() external view returns (uint32);

  /// @notice Returns the address of the contract that will mint the NFTs when the box is opened
  /// @return The address of the contract
  function nftMintingContract() external view returns (IRPSNFT);

  /// @notice Sets a new date for when the minting can be executed
  /// @param newDate The new activation date
  function setActivationDate(uint32 newDate) external;

  /// @notice Sets a new address for the reward pool
  /// @dev Will revert with `ZeroAddress` if the zero address is passed
  /// @param newRewardPool The address for the reward pool
  function setRewardPool(address newRewardPool) external;

  /// @notice Sets a new dev address
  /// @dev Will revert with `ZeroAddress` if the zero address is passed
  /// @param newDevAddress The new dev address
  function setDevAddress(address newDevAddress) external;

  /// @notice Sets a new value for the dev fee
  /// @dev Will revert with `DevFeeTooHigh` is the given fee is higher than `MAX_DEV_FEE`
  /// @param devFee The new dev fee
  function setDevFee(uint16 devFee) external;

  /// @notice Sets a mint price in usd for a given type (will use 8 decimals)
  /// @dev You can set `mintPrice` to 0 to prohibit the minting of a certain type of NFT
  /// @param nftType The type of NFT
  /// @param mintPrice The new mint price
  function setMintPriceInUSD(string calldata nftType, uint256 mintPrice) external;

  /// @notice Sets a new address for the price oracle
  /// @dev Will revert with `ZeroAddress` if the zero address is passed
  /// @param newPriceOracle The address for the new price oracle
  function setPriceOracle(AggregatorV3Interface newPriceOracle) external;

  /// @notice Sets a new string to use as base for the URI
  /// @dev Will revert with `EmptyBaseURI` if an empty string is passed
  /// @param baseURI The new base
  function setBaseURI(string calldata baseURI) external;

  /// @notice Sets a new address for the payment token
  /// @dev Will revert with `ZeroAddress` if the zero address is passed
  /// @param newPaymentToken The address for the new payment token
  function setPaymentToken(IERC20Metadata newPaymentToken) external;

  /// @notice Sets how old the last price update can be before the oracle reverts by considering it too old
  /// @param newDelay The new maximum delay
  function setMaxDelay(uint32 newDelay) external;

  /// @notice Sets the address of the contract that will mint the NFTs when the box is opened
  /// @dev Will revert with `ZeroAddress` if the zero address is passed
  /// @param newContract The address of the contract
  function setNFTMintingContract(IRPSNFT newContract) external;
}

/// @notice Handles everything in regard to the NFT part of the box
interface IMintableBoxERC721Handler is IERC721Enumerable {
  /// @notice Returns the type of the token with the given id
  /// @dev Will revert with `InexistentToken` if there is no token with the given id
  /// @return The type of the box with the given id
  function tokenType(uint256 tokenId) external view returns (string memory);
}

/// @notice Handles the opening of the NFT box
interface IMintableBoxOpeningHandler is IRandomNumberConsumer {
  /// @notice Emitted when a user requests to open their box
  /// @param tokenId The id of the box being opened
  event OpeningRequested(uint256 tokenId);

  /// @notice Emitted when the opening of certain boxes is reverted
  /// @param tokenIds The ids of the boxes that were reverted
  event OpeningsReverted(uint256[] tokenIds);

  /// @notice Thrown when a user tries to open a box that they don't own
  error OnlyOwnerCanOpenBox();

  /// @notice Thrown when a user tries to open a box that is already being opened
  error BoxIsAlreadyBeingOpened();

  /// @notice Thrown when a user tried to transfer a box that is still being opened
  error CannotTransferUntilBoxIsOpened();

  /// @notice Thrown when trying to finish the opening process of a box that is was not being opened
  error BoxIsNotBeingOpened();

  /// @notice Returns the id of the request made to the random number generator
  /// @dev Will return `0` if there is no request in progress
  /// @return The id of the request in progress
  function requestByToken(uint256 tokenId) external view returns (uint16);

  /// @notice Returns the token that has a request in progress with the given id
  /// @dev Will return `0` if there is no request with that id
  /// @return The id of the token that originated the request
  function tokenByRequest(uint16 tokenId) external view returns (uint256);

  /// @notice Opens the box with the given id
  /// @dev This action will not generate the NFT directly, but it will request a random number from our
  /// random number generator. Once the generator provides the number (in a separate transaction), then
  /// the box will be burned, and the NFT will be minted.
  /// Will revert with:
  /// `OnlyOwnerCanOpenBox` if the calles is not the box's owner
  /// `BoxIsAlreadyBeingOpened` if the box is already being opened
  /// @param tokenId The id of the box to open
  function openBox(uint256 tokenId) external;

  /// @notice Reverts the opening of boxes so that they can be opened again, or transfered/sold
  /// @dev Will revert with `BoxIsNotBeingOpened` if one of the given ids is not being opened
  /// @param tokenIds The ids of the boxes that are being opened
  function revertBoxOpenings(uint256[] calldata tokenIds) external;
}

/// @notice Handles the minting/purchasing of the NFT box
interface IMintableBoxMintingHandler {
  /// @notice An airdrop of different boxes to one recipient
  struct Airdrop {
    address recipient;
    AirdropBoxes[] boxes;
  }

  /// @notice An airdrop of boxes of the same type
  struct AirdropBoxes {
    string nftType;
    uint16 amount;
  }

  /// @notice Thrown when a user tries to purchase a box before the activation date
  error PurchasingNotAllowedYet();

  /// @notice Thrown when the oracle returns an invalid price
  error InvalidPriceFromOracle();

  /// @notice Thrown when the oracle's price is outdated
  error OutdatedPriceFromOracle();

  /// @notice Mints a new box with the given type and the given address as owner
  /// @dev Will revert with:
  /// `PurchasingNotAllowedYet` if the activation date has not passed yet
  /// `UnsupportedNFTType` if the given `nftType` is not supported
  /// @param nftType The type of the box
  /// @param owner The address that will own the box
  /// @return The id of the newly created box
  function purchaseBox(string calldata nftType, address owner) external returns (uint256);

  /// @notice Airdrops boxes to many different users
  /// @param airdrops The different boxes that will be airdropped
  function airdropMany(Airdrop[] calldata airdrops) external;

  /// @notice Airdrops a box to one user
  /// @param nftType The type of the new box
  /// @param recipient The recipient of the new box
  function airdrop(string calldata nftType, address recipient) external;
}

interface IMintableBox is IMintableBoxConfigHandler, IMintableBoxERC721Handler, IMintableBoxOpeningHandler, IMintableBoxMintingHandler {
  struct InitialConfig {
    uint32 activationDate;
    address devAddress;
    address rewardPool;
    uint16 devFee;
    MintPrice[] mintPrices;
    string nftName;
    string nftSymbol;
    IRandomNumberGenerator generator;
    AggregatorV3Interface priceOracle;
    string baseURI;
    IERC20Metadata paymentToken;
    uint32 maxDelay;
    IRPSNFT nftMintingContract;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './IRandomNumberGenerator.sol';
import './IShared.sol';

/// @notice This interface is meant to be used by contracts that need to consume random numbers in some way
interface IRandomNumberConsumer is IERC165 {
  /// @notice Emitted when a new generator is set
  /// @param newGenerator The new generator
  event NewGenerator(IRandomNumberGenerator newGenerator);

  /// @notice Thrown when someone who is not the generator tries to send a random number
  error InvalidSender();

  /// @notice Returns the address of the random number generator
  /// @return The random number generator
  function generator() external view returns (IRandomNumberGenerator);

  /// @notice Sets a new address for the random number generator
  /// @dev Will revert with `IRandomNumberGenerator` if the zero address is given
  /// @param newGenerator The new address of the generator
  function setGenerator(IRandomNumberGenerator newGenerator) external;

  /// @notice Consumes a random number in some way, after having requested it to the generator
  /// @dev Will revert with `InvalidSender` if the caller is not the generator
  /// @param requestId The id of the request
  /// @param randomNumber The random number
  function consumeRandomNumber(uint16 requestId, uint256 randomNumber) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import './IRandomNumberConsumer.sol';

/// @notice The contract will take requests for random numbers, forward them to Chainlink, and return the result to the caller
interface IRandomNumberGenerator {
  /// @notice Emitted when permissions are modified for a set of addresses
  /// @param addresses The set of addresses that will have their permissions modified
  /// @param permissions Whether the given addresses will be able to request random numbers or not
  event PermissionsChanged(address[] addresses, bool[] permissions);

  /// @notice Emitted when a request is forwarded to Chainlink
  event RequestForwarded();

  /// @notice Emitted when the requested random numbers are sent to the consumers
  /// @param consumers The consumers that will receive the random numbers
  event RandomnessFulfilled(address[] consumers);

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when trying to give permissions to an address that does not implement `IRandomNumberConsumer`
  error AddressNotAConsumer();

  /// @notice Thrown when a caller that is not whitelisted tries to request a random number
  error CallerCannotRequestNumber();

  /// @notice Thrown when invalid parameters are sent
  error InvalidParameters();

  /// @notice Returns whether a specific address can request a random number or not
  /// @param _address The address to check
  /// @return Whether the address can request a random number
  function canRequestRandomNumber(address _address) external view returns (bool);

  /// @notice Returns a list of all addresses that are waiting for a callback
  /// @dev The same address could appear more than once if they have made multiple requests
  /// @return The list of addresses waiting for random number
  function waitingForCallback() external view returns (address[] memory);

  /// @notice Requests a random number, and returns a request id
  /// @return requestId An id so that the caller can link response to request
  function requestRandomNumber() external returns (uint16 requestId);

  /// @notice Sets whether the given addresses can request random numbers or not
  /// @dev Will revert with `InvalidParameters` if the length of the arrays is not the same
  /// @param addresses The addresses to modify permissions for
  /// @param permissions Whether the given addresses should be able to request random numbers or not
  function setAddressesPermissions(address[] calldata addresses, bool[] calldata permissions) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import './IShared.sol';

/// @notice Handles all configuration of the NFT
interface IRPSNFTConfigHandler {
  struct HandChances {
    uint16 rarity;
    uint16 chances;
  }

  struct WearableChances {
    string subtype;
    uint16 chances;
  }

  /// @notice Emitted when a new base for the URI is set
  /// @param newBaseURI The new base
  event NewBaseURI(string newBaseURI);

  /// @notice Emitted when permissions are modified for an address
  /// @param _address The address that will have their mint permissions modified
  /// @param permission Whether the given address will be able to mint new NFTs or not
  event MintPermissionChanged(address _address, bool permission);

  /// @notice Emitted when wearable chances are modified
  /// @param newChances The new minting chances
  event NewWearableChances(WearableChances[] newChances);

  /// @notice Emitted when hand chances are modified
  /// @param newChances The new minting chances
  event NewHandChances(HandChances[] newChances);

  /// @notice Thrown when an empty list of chances is given
  error EmptyChances();

  /// @notice Thrown when the total chances do not cover the entire spectrum
  error InvalidChancesDistribution();

  /// @notice Returns the base for the URI
  /// @return The base for the URI
  function baseURI() external view returns (string memory);

  /// @notice Returns whether a specific address can mint new NFTs
  /// @param _address The address to check
  /// @return Whether the given address can mint new NFTs
  function canAddressMint(address _address) external view returns (bool);

  /// @notice Returns how wearable minting chances are distributed across different types
  /// @return How chances are distributed
  function wearableChances() external view returns (WearableChances[] memory);

  /// @notice Returns how hand minting chances are distributed across different rarities
  /// @return How chances are distributed
  function handChances() external view returns (HandChances[] memory);

  /// @notice Sets a new string to use as base for the URI
  /// @dev Will revert with `EmptyBaseURI` if an empty string is passed
  /// @param baseURI The new base
  function setBaseURI(string calldata baseURI) external;

  /// @notice Sets whether the given address mint new NFTs or not
  /// @param _address The address to modify permissions for
  /// @param permission Whether the given address should be able to mint new NFTs or not
  function setAddressPermission(address _address, bool permission) external;

  /// @notice Sets new wearable minting chances
  /// @param chances The new wearable minting chances
  function setWearableChances(WearableChances[] calldata chances) external;

  /// @notice Sets new hand minting chances
  /// @param chances The new hand minting chances
  function setHandChances(HandChances[] calldata chances) external;
}

/// @notice Handles everything in regard to the ERC721 part of the NFT
interface IRPSNFTERC721Handler is IERC721Enumerable {
  /// @notice Represent the metadata about a specific token
  struct TokenMetadata {
    string nftType;
    string nftSubtype;
    uint16 rarity;
  }

  /// @notice Returns the metadata of the token with the given id
  /// @dev Will revert with `InexistentToken` if there is no token with the given id
  /// @return The metadata of the NFT with the given id
  function tokenMetadata(uint256 tokenId) external view returns (TokenMetadata memory);
}

interface IRPSNFTMintingHandler {
  /// @notice Thrown when a user calls `mint` but they don't have permissions to do so
  error CallerCannotMint();

  /// @notice Mints one or more NFTs of the given type
  /// @dev Will revert with:
  /// `CallerCannotMint` if the caller doesn't have permissions to mint
  /// `UnsupportedNFTType` if the `nftType` is not supported
  /// @param nftType The type of the NFT
  /// @param owner The owner of the minted NFTs
  /// @param randomness The seed to use for randomness
  function mint(
    string calldata nftType,
    address owner,
    uint256 randomness
  ) external;
}

interface IRPSNFT is IRPSNFTConfigHandler, IRPSNFTERC721Handler, IRPSNFTMintingHandler {
  struct InitialConfig {
    WearableChances[] wearableChances;
    HandChances[] handChances;
    string baseURI;
    string nftName;
    string nftSymbol;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

/// @notice Thrown when one of the parameters is a zero address
error ZeroAddress();

/// @notice Thrown when trying to set an empty string as a base for the URI
error EmptyBaseURI();

/// @notice Thrown when trying to perform an action or query with a token id that does not exist
error InexistentToken();

/// @notice Thrown when a user tries to use an unsupported NFT type
error UnsupportedNFTType();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import './MintableBoxConfigHandler.sol';

abstract contract MintableBoxERC721Handler is MintableBoxConfigHandler, ERC721Enumerable, IMintableBoxERC721Handler {
  using Strings for uint256;

  mapping(uint256 => string) internal _tokenType;

  constructor(IMintableBox.InitialConfig memory _initialConfig) ERC721(_initialConfig.nftName, _initialConfig.nftSymbol) {}

  /// @inheritdoc IMintableBoxERC721Handler
  function tokenType(uint256 _tokenId) public view returns (string memory) {
    if (!_exists(_tokenId)) revert InexistentToken();
    return _tokenType[_tokenId];
  }

  /// @inheritdoc ERC721
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    string memory _type = tokenType(_tokenId);
    return string(abi.encodePacked(baseURI, '/', _type));
  }

  function _mint(address _to, string memory _type) internal returns (uint256 _tokenId) {
    if (mintPriceInUSD[_type] == 0) revert UnsupportedNFTType();
    _tokenId = totalSupply() + 1;
    _safeMint(_to, _tokenId);
    _tokenType[_tokenId] = _type;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '../interfaces/IRandomNumberGenerator.sol';
import '../interfaces/IRandomNumberConsumer.sol';

abstract contract RandomNumberConsumer is Ownable, ERC165, IRandomNumberConsumer {
  /// @inheritdoc IRandomNumberConsumer
  IRandomNumberGenerator public generator;

  constructor(IRandomNumberGenerator _generator) {
    if (address(_generator) == address(0)) revert ZeroAddress();
    generator = _generator;
  }

  /// @inheritdoc IRandomNumberConsumer
  function setGenerator(IRandomNumberGenerator _newGenerator) external onlyOwner {
    if (address(_newGenerator) == address(0)) revert ZeroAddress();
    generator = _newGenerator;
    emit NewGenerator(_newGenerator);
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return _interfaceId == type(IRandomNumberConsumer).interfaceId || super.supportsInterface(_interfaceId);
  }

  /// @inheritdoc IRandomNumberConsumer
  function consumeRandomNumber(uint16 _requestId, uint256 _randomNumber) external {
    if (msg.sender != address(generator)) revert InvalidSender();
    _consumeRandomNumber(_requestId, _randomNumber);
  }

  /// @notice Requests a random number from the generator
  /// @return _requestId A request id so that the caller can link response to request
  function _requestRandomNumber() internal returns (uint16 _requestId) {
    _requestId = generator.requestRandomNumber();
  }

  /// @notice Consumes a random number in some way, after having requested it to the generator
  /// @param requestId The id of the request
  /// @param randomNumber The random number
  function _consumeRandomNumber(uint16 requestId, uint256 randomNumber) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}