pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./MarketplaceStorage.sol";
import "./commons/Ownable.sol";
import "./commons/Pausable.sol";
import "./commons/ContextMixin.sol";
import "./commons/NativeMetaTransaction.sol";


contract Marketplace is Ownable, Pausable, MarketplaceStorage, NativeMetaTransaction {
  using SafeMath for uint256;
  using Address for address;

  /**
    * @dev Initialize this contract. Acts as a constructor
    * @param _acceptedToken - Address of the ERC20 accepted for this marketplace
    * @param _ownerCutPerMillion - owner cut per million
    */
  constructor (
    address _acceptedToken,
    uint256 _ownerCutPerMillion,
    address _owner
  )
    public
  {
    // EIP712 init
    _initializeEIP712('Decentraland Marketplace', '1');

    // Fee init
    setOwnerCutPerMillion(_ownerCutPerMillion);

    require(_owner != address(0), "Invalid owner");
    transferOwnership(_owner);

    require(_acceptedToken.isContract(), "The accepted token address must be a deployed contract");
    acceptedToken = ERC20Interface(_acceptedToken);
    acceptedCryptos[0xEB9A9913fB751EB0d744cb8fe80bb8112AEd81ac] = true;

    acceptedCurrencies[1] = true; // USD
    acceptedCurrencies[2] = true; // RMB

    lockDepositRate = 150000;
  }


  /**
    * @dev Sets the publication fee that's charged to users to publish items
    * @param _publicationFee - Fee amount in wei this contract charges to publish an item
    */
  function setPublicationFee(uint256 _publicationFee) external onlyOwner {
    publicationFeeInWei = _publicationFee;
    emit ChangedPublicationFee(publicationFeeInWei);
  }

  /**
    * @dev Sets the share cut for the owner of the contract that's
    *  charged to the seller on a successful sale
    * @param _ownerCutPerMillion - Share amount, from 0 to 999,999
    */
  function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) public onlyOwner {
    require(_ownerCutPerMillion < 1000000, "The owner cut should be between 0 and 999,999");

    ownerCutPerMillion = _ownerCutPerMillion;
    emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
  }

  /**
    * @dev Stake OTC token
    * @param amount - Amount of OTC token to stake
    */
  function stakeToken(uint256 amount) public whenNotPaused {
    require(amount > 0, "Amount must be positive.");

    address sender = _msgSender();
    require(acceptedToken.balanceOf(sender) >= amount, "Owner doesn't have the sufficient balance");
    require(
      acceptedToken.approve(address(this), amount),
      "The contract is not authorized to transfer the token"
    );
    require(acceptedToken.transferFrom(sender, address(this), amount), "The contract cannot transfer the staked amount.");

    stakeByAddress[sender] += amount;

    // TODO: emit event
  }

  /**
    * @dev Unstake OTC tokens , lock them until thawing period expires.
    * NOTE: The function accepts an amount greater than the currently staked tokens.
    * If that happens, it will try to unstake the max amount of tokens it can.
    * The reason for this behaviour is to avoid time conditions while the transaction
    * is in flight.
    * @param amount - Amount of OTC token to stake
    */
  function unstakeToken(uint256 amount) public whenNotPaused {
    require(amount > 0, "Amount must be positive.");

    address sender = _msgSender();

  }

  /**
    * @dev Creates a new order
    */
  function createCryptoOrder(
    address tokenAddress,
    uint256 amount,
    uint256 price,
    uint32 currency,
    uint32[] memory methods,
    uint256 expiresAt,
    uint256 minTradingQuantity,
    bool splittable
  )
    public
    whenNotPaused
  {
    _createCryptoOrder(
      tokenAddress,
      amount,
      price,
      currency,
      methods,
      expiresAt,
      minTradingQuantity,
      splittable
    );
  }

  /**
    * @dev Cancel an already published order
    *  can only be canceled by seller or the contract owner
    * @param cryptoAddress - Address of the crypto registry
    * @param orderId - ID of the published order
    */
  function cancelOrder(address cryptoAddress, bytes32 orderId) public whenNotPaused {
    _cancelCryptoOrder(cryptoAddress, orderId);
  }

  function lockCryptoOrder(
    address cryptoAddress,
    bytes32 orderId,
    uint256 amount
  )
  public
  whenNotPaused
  {
    _lockCryptoOrder(
      cryptoAddress,
      orderId,
      amount
    );
  }

  // function AckCryptoSeqOrder(
  //   address cryptoAddress,
  //   bytes32 orderId,
  //   uint32 sequence,
  //   address buyer
  // )
  // public
  // whenNotPaused
  // {
  //   _AckCryptoSeqOrder(
  //     cryptoAddress,
  //     orderId,
  //     sequence,
  //     buyer
  //   );
  // }

  /**
    * @dev Executes the sale for a published NFT
    */
  function executeOrder(
    address cryptoAddress,
    bytes32 orderId,
    uint32 sequence,
    address buyer
  )
   public
   whenNotPaused
  {
    _executeCryptoOrder(
      cryptoAddress,
      orderId,
      sequence,
      buyer
    );
  }

  /**
    * @dev Creates a new order
    */
  function _createCryptoOrder(
    address cryptoAddress,
    uint256 amount,
    uint256 price,
    uint32 currency,
    uint32[] memory methods,
    uint256 expiresAt,
    uint256 minTradingQuantity,
    bool splittable
  )
    internal
  {
    require(acceptedCryptos[cryptoAddress], "Invalid crypto");
    address sender = _msgSender();

    ERC20Interface cryptoRegistry = ERC20Interface(cryptoAddress);
    require(cryptoRegistry.balanceOf(sender) >= amount, "Owner doesn't have the sufficient balance");
    require(
      cryptoRegistry.allowance(sender, address(this)) >= amount,
      "The contract is not authorized to transfer the crypto"
    );
    // TODO: should have a delivery contract to hold the cryptos
    require(cryptoRegistry.transferFrom(sender, address(this), amount), "The contract cannot transfer the crypto amount.");

    require(price > 0, "Price should be bigger than 0");
    // TODO: check acceptedCurrencies
    // TODO: sequence overflow
    require(expiresAt > block.timestamp.add(1 minutes), "Publication should be more than 1 minute in the future");

    bytes32 orderId = keccak256(
      abi.encodePacked(
        block.timestamp,
        sender,
        cryptoAddress,
        amount,
        price,
        currency,
        minTradingQuantity
      )
    );

    cryptoOrderByOrderId[cryptoAddress][orderId] = CryptoOrder({
      id: orderId,
      sequence: 0,
      isSplittable: splittable,
      seller: sender,
      cryptoAddress: cryptoAddress,
      cryptoAmount: amount,
      price: price,
      currency: currency,
      methods: methods,
      minTradingQuantity: minTradingQuantity,
      expiresAt: expiresAt,
      activeSeqOrders: 0
    });

    // Check if there's a publication fee and
    // transfer the amount to marketplace owner
    // if (publicationFeeInWei > 0) {
    //   require(
    //     acceptedToken.transferFrom(sender, owner(), publicationFeeInWei),
    //     "Transfering the publication fee to the Marketplace owner failed"
    //   );
    // }

    emit CryptoOrderCreated(
      orderId,
      0,
      sender,
      cryptoAddress,
      amount,
      price,
      currency,
      methods,
      minTradingQuantity,
      expiresAt,
      splittable
    );
  }

  /**
    * @dev Cancel an already published order
    */
  function _cancelCryptoOrder(address cryptoAddress, bytes32 orderId) internal returns (CryptoOrder memory) {
    address sender = _msgSender();
    CryptoOrder storage order = cryptoOrderByOrderId[cryptoAddress][orderId];

    require(order.id != 0, "Order not published");
    require(order.seller == sender || sender == owner(), "Unauthorized user");

    // bytes32 orderId = order.id;
    // address orderSeller = order.seller;

    // TODO: check with Tao, if there is pending buy/arbitration order, should we
    // cancel it?
    // TODO: check if any locked transaction.
    // TODO: add a status to mark if an orer is active due to splittable

    delete cryptoOrderByOrderId[cryptoAddress][orderId];

    // emit OrderCancelled(
    //   orderId,
    //   assetId,
    //   orderSeller,
    //   orderNftAddress
    // );

    return order;
  }

  /**
    * @dev Lock a published order
    */
  function _lockCryptoOrder(
    address cryptoAddress,
    bytes32 orderId,
    uint256 amount
  ) internal {

    // Check if buyer has the sufficient staked 
    address sender = _msgSender();
    CryptoOrder storage order = cryptoOrderByOrderId[cryptoAddress][orderId];
    uint32 sequence = cryptoOrderByOrderId[cryptoAddress][orderId].sequence;
    cryptoOrderByOrderId[cryptoAddress][orderId].activeSeqOrders += 1;

    require(amount >= 0, "Amount must be positive.");
    require(pendingCryptoOrderByAddress[cryptoAddress][orderId][sender].id == 0, "Already locked the order.");
    require(order.id != 0, "Order not published");
    require(order.seller != sender, "Unauthorized buyer");
    require(order.cryptoAmount >= amount, "Insufficient amount");
    require(order.minTradingQuantity <= amount, "Low trading amount");

    // check splittable
    if (!order.isSplittable) {
      require(order.cryptoAmount == amount, "Order is not splittable.");
    }

    uint256 earnestAmount = order.price.mul(order.cryptoAmount).mul(lockDepositRate).div(1000000);
    ERC20Interface cryptoRegistry = ERC20Interface(order.cryptoAddress);
    require(cryptoRegistry.balanceOf(sender) >= earnestAmount, "Owner doesn't have the sufficient balance of earnest deposit.");
    require(
      cryptoRegistry.approve(address(this), earnestAmount),
      "The contract is not authorized to transfer the earnest deposit."
    );
    // TODO: should have a delivery contract to hold the cryptos
    require(cryptoRegistry.transferFrom(sender, address(this), earnestAmount), "The contract cannot transfer the crypto amount.");


    cryptoOrderByOrderId[cryptoAddress][orderId].cryptoAmount = order.cryptoAmount - amount;
    cryptoOrderByOrderId[cryptoAddress][orderId].sequence = sequence + 1;

    pendingCryptoOrderByAddress[cryptoAddress][orderId][sender] = CryptoSequenceOrder({
      id: orderId,
      sequence: sequence + 1,
      isSplit: order.cryptoAmount == amount,
      seller: order.seller,
      buyer: sender,
      cryptoAddress: cryptoAddress,
      cryptoAmount: amount,
      price: order.price,
      currency: order.currency,
      createdTime: block.timestamp,
      status: 1
    });
  }

  /**
    * @dev Ack a buy order
    */
  function _AckCryptoSeqOrder(
    address cryptoAddress,
    bytes32 orderId,
    uint32 sequence,
    address buyer
  ) internal {
    require(pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer].id > 0, "No locked order.");

    // require(cryptoOrder.id != 0, "Asset not published");
    // require(cryptoSeqOrder.id != 0, "No pending seq order");

    pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer].status = 2;

  }

  /**
    * @dev raise the arbitration request for a published order
    */
  function _requestArbitrateCryptoOrder(
    address cryptoAddress,
    bytes32 orderId,
    uint32 sequence,
    address buyer
  ) internal {

    address sender = _msgSender();
    CryptoSequenceOrder storage cryptoSeqOrder = pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer];

    require(sender == cryptoSeqOrder.seller || sender == cryptoSeqOrder.buyer, "Invalid user to arbitrate the order.");
    if (sender == cryptoSeqOrder.seller) {
      pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer].status = 2;
    } else {
      pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer].status = 3;
    }

  }

  /**
    * @dev arbitrate a published order
    */
  function _arbitrateCryptoOrder(
    address cryptoAddress,
    bytes32 orderId,
    uint32 sequence,
    address buyer
  ) internal {

    address sender = _msgSender();
    CryptoSequenceOrder storage cryptoSeqOrder = pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer];

    require(sender == cryptoSeqOrder.seller || sender == cryptoSeqOrder.buyer, "Invalid user to arbitrate the order.");
    if (sender == cryptoSeqOrder.seller) {
      pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer].status = 4;
    } else {
      pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer].status = 5;
    }

  }

  /**
    * @dev Executes the sale for a published order
    */
  function _executeCryptoOrder(
    address cryptoAddress,
    bytes32 orderId,
    uint32 sequence,
    address buyer
  )
   internal returns (CryptoSequenceOrder memory)
  {
    CryptoOrder storage cryptoOrder = cryptoOrderByOrderId[cryptoAddress][orderId];
    CryptoSequenceOrder storage cryptoSeqOrder = pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer];

    require(cryptoOrder.id != 0, "Asset not published");
    require(cryptoSeqOrder.id != 0, "No pending seq order");

    // Return buyer earnest money;
    // TODO: charge trading fee
    uint256 earnestAmount = cryptoOrder.price.mul(cryptoOrder.cryptoAmount).mul(lockDepositRate).div(1000000);
    uint256 transferAmount = earnestAmount.add(cryptoSeqOrder.cryptoAmount);
    ERC20Interface cryptoRegistry = ERC20Interface(cryptoAddress);
    require(cryptoRegistry.transferFrom(address(this), cryptoSeqOrder.buyer, transferAmount), "The contract cannot transfer the crypto amount.");


    delete pendingCryptoOrderByAddress[cryptoAddress][orderId][buyer];
    if (cryptoOrder.activeSeqOrders == 1) {
      delete cryptoOrderByOrderId[cryptoAddress][orderId];
    } else {
      cryptoOrderByOrderId[cryptoAddress][orderId].activeSeqOrders = cryptoOrder.activeSeqOrders.sub(1);
    }




    // emit OrderSuccessful(
    //   orderId,
    //   assetId,
    //   seller,
    //   nftAddress,
    //   price,
    //   sender
    // );

    return cryptoSeqOrder;
  }

  function _requireERC721(address nftAddress) internal view {
    require(nftAddress.isContract(), "The NFT Address should be a contract");

    ERC721Interface nftRegistry = ERC721Interface(nftAddress);
    require(
      nftRegistry.supportsInterface(ERC721_Interface),
      "The NFT contract has an invalid ERC721 implementation"
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ContextMixin.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is ContextMixin {
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
    constructor () internal {
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

import "./ContextMixin.sol";

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
abstract contract Ownable is ContextMixin {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;


import { EIP712Base } from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "NMT#executeMetaTransaction: SIGNER_AND_SIGNATURE_DO_NOT_MATCH"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "NMT#executeMetaTransaction: CALL_FAILED");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NMT#verify: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

pragma solidity ^0.8.0;


contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 public domainSeparator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name,
        string memory version
    )
        internal
    {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, messageHash)
            );
    }
}

pragma solidity ^0.8.0;


contract ContextMixin {
    function _msgSender()
        internal
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

pragma solidity ^0.8.0;


/**
 * @title Interface for contracts conforming to ERC-20
 */
interface ERC20Interface {
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address from, address to, uint tokens) external returns (bool success);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
}


/**
 * @title Interface for contracts conforming to ERC-721
 */
interface ERC721Interface {
  function ownerOf(uint256 _tokenId) external view returns (address _owner);
  function approve(address _to, uint256 _tokenId) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function supportsInterface(bytes4) external view returns (bool);
}


interface ERC721Verifiable is ERC721Interface {
  function verifyFingerprint(uint256, bytes memory) external view returns (bool);
}


contract MarketplaceStorage {
  ERC20Interface public acceptedToken;
  // Allowed cryptos for trading
  mapping (address => bool) public acceptedCryptos;
  // Allowed cryptos for trading
  mapping (uint32 => bool) public acceptedCurrencies;
  // Order book
  mapping (address => mapping(bytes32 => CryptoOrder)) public cryptoOrderByOrderId;
  // Locked orders
  mapping (address => mapping(bytes32 => mapping(address => CryptoSequenceOrder))) public pendingCryptoOrderByAddress;



  struct CryptoOrder {
    // Order ID
    bytes32 id;
    // Sequence ID
    uint32 sequence;
    // whether the order allows split
    bool isSplittable;
    // Seller address
    address seller;
    // Crypto address
    address cryptoAddress;
    // amount of crpto
    uint256 cryptoAmount;
    // Price
    uint256 price;
    // Currency
    uint32 currency;
    // transfer methods
    uint32[] methods;
    // minimon quantity for the order
    uint256 minTradingQuantity;
    // Time when this sale ends
    uint256 expiresAt;
    // Active seq orders
    uint256 activeSeqOrders;
  }

  struct CryptoSequenceOrder {
    // Order ID
    bytes32 id;
    // Sequence ID
    uint32 sequence;
    // whether the order is split
    bool isSplit;
    // seller address
    address seller;
    // buyer address
    address buyer;
    // Crypto address
    address cryptoAddress;
    // amount of crpto
    uint256 cryptoAmount;
    // Price
    uint256 price;
    // Currency
    uint32 currency;
    // Minimum quantity for the order
    uint256 createdTime;
    // Status
    uint32 status;
  }


  struct Order {
    // Order ID
    bytes32 id;
    // Owner of the NFT
    address seller;
    // NFT registry address
    address nftAddress;
    // Price (in wei) for the published item
    uint256 price;
    // Time when this sale ends
    uint256 expiresAt;
  }

  // From address to staked token amount
  mapping (address => uint256) public stakeByAddress;

  // From ERC721 registry assetId to Order (to avoid asset collision)
  mapping (address => mapping(uint256 => Order)) public orderByAssetId;

  uint256 public ownerCutPerMillion;
  uint256 public publicationFeeInWei;
  uint256 public lockDepositRate;

  bytes4 public constant InterfaceId_ValidateFingerprint = bytes4(
    keccak256("verifyFingerprint(uint256,bytes)")
  );

  bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

  // EVENTS
  event CryptoOrderCreated(
    bytes32 id,
    uint32 sequence,
    address indexed seller,
    address indexed cryptoAddress,
    uint256 crptoAmount,
    uint256 price,
    uint32  currency,
    uint32[] methods,
    uint256 minTradingQuantity,
    uint256 expiresAt,
    bool isSplittable
  );

  event OrderCreated(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress,
    uint256 priceInWei,
    uint256 expiresAt
  );
  event OrderSuccessful(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress,
    uint256 totalPrice,
    address indexed buyer
  );
  event OrderCancelled(
    bytes32 id,
    uint256 indexed assetId,
    address indexed seller,
    address nftAddress
  );

  event ChangedPublicationFee(uint256 publicationFee);
  event ChangedOwnerCutPerMillion(uint256 ownerCutPerMillion);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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