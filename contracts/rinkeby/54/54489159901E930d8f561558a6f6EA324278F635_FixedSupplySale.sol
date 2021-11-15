// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../token/AiPersonalityERC721.sol";
import "../token/AletheaNFT.sol";
import "./IntelligentNFTv2.sol";
import "../utils/AccessControl.sol";

/**
 * @title Fixed Supply Sale
 *
 * @notice Fixed Supply Sale sales fixed amount of iNFTs for a fixed price in a fixed period of time;
 *      underlying NFTs and AI Personalities are being minted as well as a part of the sale process
 *
 * @dev Technically, all the "fixed" parameters can be changed on the go after smart contract is deployed
 *      and operational, but this ability is reserved for quick fix-like adjustments, and to provide
 *      an ability to restart and run a similar sale after the previous one ends
 *
 * @dev When buying an iNFT from this smart contract:
 *      1) next NFT is minted to the transaction sender address
 *      2) next AI Personality is minted directly to iNFT smart contract for further locking
 *      3) next iNFT is created, bound to an NFT minted in step (1)
 *         and locking the AI Personality minted in step (2)
 *      4) no ALI tokens are minted, no ALI tokens are locked or consumed in the process
 *
 * @dev Deployment and setup:
 *      1. Deploy smart contract, specify smart contract addresses during the deployment
 *         - iNFT deployed instance address
 *         - NFT deployed instance address
 *         - AI Personality deployed instance address
 *      2. Execute `initialize` function and set up the sale parameters;
 *         sale is not active until it's initialized
 *
 * @author Basil Gorin
 */
contract FixedSupplySale is AccessControl {
	// ----- SLOT.1 (256/256)
	/**
	 * @notice Price of a single iNFT minted (with the underlying NFT and AI Personality minted)
	 *      When buying several iNFTs at once the price accumulates accordingly, with no discount
	 *
	 * @dev Maximum item price is ~18.44 ETH
	 */
	uint64 public itemPrice;

	/**
	 * @dev Next iNFT / bound NFT / AI Personality ID to mint;
	 *      initially this is the first "free" ID which can be minted;
	 *      at any point in time this should point to a free, mintable ID
	 *      for iNFT / bound NFT / AI Personality
	 *
	 * @dev `nextId` cannot be zero, we do not ever mint NFTs with zero IDs
	 */
	uint32 public nextId = 1;

	/**
	 * @dev Last iNFT / bound NFT / AI Personality ID to mint;
	 *      once `nextId` exceeds `finalId` the sale pauses
	 */
	uint32 public finalId;

	/**
	 * @notice Sale start unix timestamp; the sale is active after the start (inclusive)
	 */
	uint32 public saleStart;

	/**
	 * @notice Sale end unix timestamp; the sale is active before the end (exclusive)
	 */
	uint32 public saleEnd;

	/**
	 * @notice Once set, limits the amount of iNFTs one can buy in a single transaction;
	 *       When unset (zero) the amount of iNFTs is limited only by block size and
	 *       amount of iNFTs left for sale
	 */
	uint32 public batchLimit;

	/**
	 * @notice Counter of the iNFTs sold (minted) by this sale smart contract
	 */
	uint32 public soldCounter;

	// ----- NON-SLOTTED
	/**
	 * @dev ALI ERC20 contract address to transfer tokens and bind to iNFTs created,
	 *      should match with `iNftContract.aliContract`
	 */
	address public immutable aliContract;

	/**
	 * @dev NFT ERC721 contract address to mint NFTs from and bind to iNFTs created
	 */
	address public immutable nftContract;

	/**
	 * @dev AI Personality ERC721 contract address to mint and lock into iNFTs created
	 */
	address public immutable personalityContract;

	/**
	 * @dev iNFT contract address used to create iNFTs
	 */
	address public immutable iNftContract;

	// ----- SLOT.2
	/**
	 * @dev iNFTs may get created with the ALI tokens bound to them.
	 *      The tokens are transferred from the address specified.
	 *      The address specified has to approve the sale to spend tokens.
	 *
	 * @dev Both `aliSource` and `aliValue` must be set in order to bind tokens
	 *      to iNFTs sold
	 *
	 * @dev Both `aliSource` and `aliValue` can be either set or unset
	 */
	address public aliSource;

	/**
	 * @dev iNFTs may get created with the ALI tokens bound to them.
	 *      Specified amount of tokens is transferred from the address specified above
	 *      for each iNFT created, and is bound within the iNFT
	 *      The address specified above has to approve the sale to spend tokens.
	 *
	 * @dev Both `aliSource` and `aliValue` must be set in order to bind tokens
	 *      to iNFTs sold
	 *
	 * @dev Both `aliSource` and `aliValue` can be either set or unset
	 */
	uint96 public aliValue;

	/**
	 * @notice Sale manager is responsible for managing properties of the sale,
	 *      such as sale price, amount, start/end dates, etc.
	 *
	 * @dev Role ROLE_SALE_MANAGER allows updating sale properties via initialize() function
	 */
	uint32 public constant ROLE_SALE_MANAGER = 0x0001_0000;

	/**
	 * @notice Withdrawal manager is responsible for withdrawing ETH obtained in sale
	 *      from the sale smart contract
	 *
	 * @dev Role ROLE_WITHDRAWAL_MANAGER allows ETH withdrawals:
	 *      - withdraw()
	 *      - withdrawTo()
	 */
	uint32 public constant ROLE_WITHDRAWAL_MANAGER = 0x0002_0000;

	/**
	 * @dev Fired in initialize()
	 *
	 * @param _by an address which executed the initialization
	 * @param _itemPrice price of one iNFT created
	 * @param _nextId next ID of the iNFT, NFT, and AI Pod to mint
	 * @param _finalId final ID of the iNFT, NFT, and AI Pod to mint
	 * @param _saleStart start of the sale, unix timestamp
	 * @param _saleEnd end of the sale, unix timestamp
	 * @param _batchLimit how many iNFTs is allowed to buy in a single transaction
	 * @param _aliSource an address to transfer ALI tokens from to bind to iNFTs created
	 * @param _aliValue an amount of ALI tokens to transfer and bind for each iNFT created
	 */
	event Initialized(
		address indexed _by,
		uint64 _itemPrice,
		uint32 _nextId,
		uint32 _finalId,
		uint32 _saleStart,
		uint32 _saleEnd,
		uint32 _batchLimit,
		address _aliSource,
		uint96 _aliValue
	);

	/**
	 * @dev Fired in buy(), buyTo(), buySingle(), and buySingleTo()
	 *
	 * @param _by an address which executed and payed the transaction, probably a buyer
	 * @param _to an address which received token(s) and iNFT(s) minted
	 * @param _amount number of tokens and iNFTs minted
	 * @param _aliValue number of ALI tokens transferred
	 * @param _value ETH amount charged
	 */
	event Bought(address indexed _by, address indexed _to, uint256 _amount, uint256 _aliValue, uint256 _value);

	/**
	 * @dev Fired in withdraw() and withdrawTo()
	 *
	 * @param _by an address which executed the withdrawal
	 * @param _to an address which received the ETH withdrawn
	 * @param _value ETH amount withdrawn
	 */
	event Withdrawn(address indexed _by, address indexed _to, uint256 _value);

	/**
	 * @dev Creates/deploys FixedSupplySale and binds it to NFT, AI Personality, and iNFT
	 *      smart contracts on construction
	 *
	 * @param _ali deployed ALI ERC20 smart contract address; sale may bind tokens to iNFTs created
	 * @param _iNft deployed iNFT smart contract address; sale will create iNFTs of that type
	 * @param _nft deployed NFT smart contract address; sale will mint NFTs of that type
	 *      and bind created iNFT to these NFTs
	 * @param _personality deployed AI Personality smart contract; sale will mint AI Personality
	 *      tokens of that type and lock them within iNFTs
	 */
	constructor(address _ali, address _nft, address _personality, address _iNft) {
		// verify the inputs are set
		require(_ali != address(0), "ALI Token contract is not set");
		require(_nft != address(0), "NFT contract is not set");
		require(_personality != address(0), "AI Personality contract is not set");
		require(_iNft != address(0), "iNFT contract is not set");

		// verify inputs are valid smart contracts of the expected interfaces
		require(ERC165(_ali).supportsInterface(type(ERC20).interfaceId), "unexpected ALI Token type");
		require(ERC165(_nft).supportsInterface(type(ERC721).interfaceId), "unexpected NFT type");
		require(ERC165(_personality).supportsInterface(type(ERC721).interfaceId), "unexpected AI Personality type");
		require(ERC165(_iNft).supportsInterface(type(IntelligentNFTv2Spec).interfaceId), "unexpected iNFT type");

		// assign the addresses
		aliContract = _ali;
		nftContract = _nft;
		personalityContract = _personality;
		iNftContract = _iNft;
	}

	/**
	 * @notice Number of iNFTs left on sale
	 *
	 * @dev Doesn't take into account if sale is active or not, throws if
	 *      `nextId - finalId < 1`
	 *
	 * @return number of iNFTs left on sale
	 */
	function itemsOnSale() public view returns(uint32) {
		// calculate items left on sale, taking into account that
		// finalId is on sale (inclusive bound)
		return finalId + 1 - nextId;
	}

	/**
	 * @notice Number of iNFTs available on sale
	 *
	 * @dev Takes into account if sale is active or not, doesn't throw,
	 *      returns zero if sale is inactive
	 *
	 * @return number of iNFTs available on sale
	 */
	function itemsAvailable() public view returns(uint32) {
		// delegate to itemsOnSale() if sale is active, return zero otherwise
		return isActive()? itemsOnSale(): 0;
	}

	/**
	 * @notice Active sale is an operational sale capable of minting and selling
	 *      iNFTs (together with minting the underlying assets - NFTs and AI Personalities)
	 *
	 * @dev The sale is active when all the requirements below are met:
	 *      1. Price is set (`itemPrice` is not zero)
	 *      2. `finalId` is not reached (`nextId <= finalId`)
	 *      3. current timestamp is between `saleStart` (inclusive) and `saleEnd` (exclusive)
	 *
	 * @dev Function is marked as virtual to be overridden in the helper test smart contract (mock)
	 *      in order to test how it affects the sale process
	 *
	 * @return true if sale is active (operational) and can sell iNFTs, false otherwise
	 */
	function isActive() public view virtual returns(bool) {
		// evaluate sale state based on the internal state variables and return
		return itemPrice > 0 && nextId <= finalId && saleStart <= now256() && saleEnd > now256();
	}

	/**
	 * @dev Restricted access function to set up sale parameters, all at once,
	 *      or any subset of them
	 *
	 * @dev To skip parameter initialization, set it to `-1`,
	 *      that is a maximum value for unsigned integer of the corresponding type;
	 *      `_aliSource` and `_aliValue` must both be either set or skipped
	 *
	 * @dev Example: following initialization will update only _itemPrice and _batchLimit,
	 *      leaving the rest of the fields unchanged
	 *      initialize(
	 *          100000000000000000,
	 *          0xFFFFFFFF,
	 *          0xFFFFFFFF,
	 *          0xFFFFFFFF,
	 *          0xFFFFFFFF,
	 *          10,
	 *          0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF,
	 *          0xFFFFFFFFFFFFFFFFFFFFFFFF
	 *      )
	 *
	 * @dev Requires next ID to be greater than zero (strict): `_nextId > 0`
	 * @dev Requires ALI source/value to be both either set or unset (zero);
	 *      if set, ALI value must not be less than 1e12 (0.000001 ALI)
	 *
	 * @dev Requires transaction sender to have `ROLE_SALE_MANAGER` role
	 *
	 * @param _itemPrice price of one iNFT created (with NFT and AI Personality also minted);
	 *      setting the price to zero deactivates the sale
	 * @param _nextId next ID of the iNFT, NFT, and AI Pod to mint, will be increased
	 *      in smart contract storage after every successful buy
	 * @param _finalId final ID of the iNFT, NFT, and AI Pod to mint; sale is capable of producing
	 *      `_finalId - _nextId + 1` iNFTs
	 * @param _saleStart start of the sale, unix timestamp
	 * @param _saleEnd end of the sale, unix timestamp; sale is active only
	 *      when current time is within _saleStart (inclusive) and _saleEnd (exclusive)
	 * @param _batchLimit how many iNFTs is allowed to buy in a single transaction,
	 *      set to zero to disable the limit
	 * @param _aliSource an address to transfer ALI tokens from to bind to iNFTs created
	 * @param _aliValue an amount of ALI tokens to transfer and bind for each iNFT created
	 */
	function initialize(
		uint64 _itemPrice,	// <<<--- keep type in sync with the body type(uint64).max !!!
		uint32 _nextId,	// <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _finalId,	// <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _saleStart,	// <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _saleEnd,	// <<<--- keep type in sync with the body type(uint32).max !!!
		uint32 _batchLimit,	// <<<--- keep type in sync with the body type(uint32).max !!!
		address _aliSource,		// <<<--- keep that in sync with the body type(uint160).max !!!
		uint96 _aliValue	// <<<--- keep type in sync with the body type(uint96).max !!!
	) public {
		// check the access permission
		require(isSenderInRole(ROLE_SALE_MANAGER), "access denied");

		// verify the inputs
		require(_nextId > 0, "zero nextId");
		// ALI source/value should be either both set or both unset
		// ALI value must not be too low if set
		require(_aliSource == address(0) && _aliValue == 0 || _aliSource != address(0) && _aliValue >= 1e12, "invalid ALI source/value");

		// no need to verify extra parameters - "incorrect" values will deactivate the sale

		// initialize contract state based on the values supplied
		// take into account our convention that value `-1` means "do not set"
		// 0xFFFFFFFFFFFFFFFF, 64 bits
		if(_itemPrice != type(uint64).max) {
			itemPrice = _itemPrice;
		}
		// 0xFFFFFFFF, 32 bits
		if(_nextId != type(uint32).max) {
			nextId = _nextId;
		}
		// 0xFFFFFFFF, 32 bits
		if(_finalId != type(uint32).max) {
			finalId = _finalId;
		}
		// 0xFFFFFFFF, 32 bits
		if(_saleStart != type(uint32).max) {
			saleStart = _saleStart;
		}
		// 0xFFFFFFFF, 32 bits
		if(_saleEnd != type(uint32).max) {
			saleEnd = _saleEnd;
		}
		// 0xFFFFFFFF, 32 bits
		if(_batchLimit != type(uint32).max) {
			batchLimit = _batchLimit;
		}
		// 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF and 0xFFFFFFFFFFFFFFFFFFFFFFFF, 160 and 96 bits
		if(uint160(_aliSource) != type(uint160).max && _aliValue != type(uint96).max) {
			aliSource = _aliSource;
			aliValue = _aliValue;
		}

		// emit an event - read values from the storage since not all of them might be set
		emit Initialized(
			msg.sender,
			itemPrice,
			nextId,
			finalId,
			saleStart,
			saleEnd,
			batchLimit,
			aliSource,
			aliValue
		);
	}

	/**
	 * @notice Buys several (at least two) iNFTs in a batch.
	 *      Accepts ETH as payment and creates iNFT with minted bound NFT and minted linked AI Personality
	 *
	 * @param _amount amount of iNFTs to create (same amount of NFTs and AI Personalities
	 *      will be created and bound/locked to iNFT), two or bigger
	 */
	function buy(uint32 _amount) public payable {
		// delegate to `buyTo` with the transaction sender set to be a recipient
		buyTo(msg.sender, _amount);
	}

	/**
	 * @notice Buys several (at least two) iNFTs in a batch to an address specified.
	 *      Accepts ETH as payment and creates iNFT with minted bound NFT and minted linked AI Personality
	 *
	 * @param _to address to mint tokens and iNFTs to
	 * @param _amount amount of iNFTs to create (same amount of NFTs and AI Personalities
	 *      will be created and bound/locked to iNFT), two or bigger
	 */
	function buyTo(address _to, uint32 _amount) public payable {
		// verify the inputs
		require(_to != address(0), "recipient not set");
		require(_amount > 1 && (batchLimit == 0 || _amount <= batchLimit), "incorrect amount");

		// verify sale is in active state
		require(isActive(), "inactive sale");

		// calculate the total price required and validate the transaction value
		uint256 totalPrice = uint256(itemPrice) * _amount;
		require(msg.value >= totalPrice, "not enough funds");

		// based on ALI value set on the contract and amount of iNFTs to create
		// calculate the cumulative ALI value to be sent to iNFT
		// note: cumulative ALI value may overflow uint96, store it into uint256 on stack
		uint256 _aliValue = uint256(aliValue) * _amount;
		// if it's not zero (that is if ALI token binding is enabled)
		if(_aliValue != 0) {
			// transfer ALI amount required to iNFT smart contract
			ERC20(aliContract).transferFrom(aliSource, iNftContract, _aliValue);
		}

		// mint NFTs to the recipient
		AletheaNFT(nftContract).safeMintBatch(_to, nextId, _amount);

		// mint AI Personality directly to iNFT smart contract
		AiPersonalityERC721(personalityContract).mintBatch(iNftContract, nextId, _amount);

		// create iNFT bound to NFT minted and locking the AI Personality minted
		IntelligentNFTv2(iNftContract).mintBatch(
			nextId, // first recordId
			aliValue, // ALI value
			personalityContract, // AI Personality contract address
			nextId, // first AI Personality ID
			nftContract, // NFT contract address
			nextId, // first target NFT ID
			_amount // amount of iNFTs to create
		);

		// increment `nextId`
		nextId += _amount;
		// increment `soldCounter`
		soldCounter += _amount;

		// if ETH amount supplied exceeds the price
		if(msg.value > totalPrice) {
			// send excess amount back to sender
			payable(msg.sender).transfer(msg.value - totalPrice);
		}

		// emit en event
		emit Bought(msg.sender, _to, _amount, _aliValue, totalPrice);
	}

	/**
	 * @notice Buys single iNFTs.
	 *      Accepts ETH as payment and creates iNFT with minted bound NFT and minted linked AI Personality
	 */
	function buySingle() public payable {
		buySingleTo(msg.sender);
	}

	/**
	 * @notice Buys single iNFTs to an address specified.
	 *      Accepts ETH as payment and creates iNFT with minted bound NFT and minted linked AI Personality
	 *
	 * @param _to address to mint tokens and iNFT to
	 */
	function buySingleTo(address _to) public payable {
		// verify the inputs and transaction value
		require(_to != address(0), "recipient not set");
		require(msg.value >= itemPrice, "not enough funds");

		// verify sale is in active state
		require(isActive(), "inactive sale");

		// if ALI token binding is enabled
		if(aliValue != 0) {
			// transfer ALI amount required to iNFT smart contract
			ERC20(aliContract).transferFrom(aliSource, iNftContract, aliValue);
		}
		// mint NFT to the recipient
		AletheaNFT(nftContract).safeMint(_to, nextId);
		// mint AI Personality directly to iNFT smart contract
		AiPersonalityERC721(personalityContract).mint(iNftContract, nextId);
		// create iNFT bound to NFT minted and locking the AI Personality minted
		IntelligentNFTv2(iNftContract).mint(nextId, aliValue, personalityContract, nextId, nftContract, nextId);

		// increment `nextId`
		nextId++;
		// increment `soldCounter`
		soldCounter++;

		// if ETH amount supplied exceeds the price
		if(msg.value > itemPrice) {
			// send excess amount back to sender
			payable(msg.sender).transfer(msg.value - itemPrice);
		}

		// emit en event
		emit Bought(msg.sender, _to, 1, aliValue, itemPrice);
	}

	/**
	 * @dev Restricted access function to withdraw ETH on the contract balance,
	 *      sends ETH back to transaction sender
	 */
	function withdraw() public {
		// delegate to `withdrawTo`
		withdrawTo(msg.sender);
	}

	/**
	 * @dev Restricted access function to withdraw ETH on the contract balance,
	 *      sends ETH to the address specified
	 *
	 * @param _to an address to send ETH to
	 */
	function withdrawTo(address _to) public {
		// check the access permission
		require(isSenderInRole(ROLE_WITHDRAWAL_MANAGER), "access denied");

		// verify withdrawal address is set
		require(_to != address(0), "address not set");

		// ETH value to send
		uint256 _value = address(this).balance;

		// verify sale balance is positive (non-zero)
		require(_value > 0, "zero balance");

		// send the entire balance to the transaction sender
		payable(_to).transfer(_value);

		// emit en event
		emit Withdrawn(msg.sender, _to, _value);
	}

	/**
	 * @dev Testing time-dependent functionality may be difficult;
	 *      we override time in the helper test smart contract (mock)
	 *
	 * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
	 */
	function now256() public view virtual returns (uint256) {
		// return current block timestamp
		return block.timestamp;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./TinyERC721.sol";

/**
 * @title AI Personality
 *
 * @notice AI Personality replaces AI Pod in version 2 release, it doesn't
 *      store any metadata on-chain, all the token related data except URI
 *      (rarity, traits, etc.) is expected to be stored off-chain
 *
 * @dev AI Personality is a Tiny ERC721, it supports minting and burning,
 *      its token ID space is limited to 32 bits
 *
 * @author Basil Gorin
 */
contract AiPersonalityERC721 is TinyERC721 {
	/**
	 * @inheritdoc TinyERC721
	 */
	uint256 public constant override TOKEN_UID = 0xd9b5d3b66c60255ffa16c57c0f1b2db387997fa02af673da5767f1acb0f345af;

	/**
	 * @dev Constructs/deploys AI Personality instance
	 *      with the name and symbol defined during the deployment
	 */
	constructor(string memory _name, string memory _symbol) TinyERC721(_name, _symbol) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./TinyERC721.sol";

/**
 * @title Althea NFT
 *
 * @notice Alethea NFT is an ERC721 token used as a target NFT for iNFT protocol
 *
 * @dev Alethea NFT is a Tiny ERC721, it supports minting and burning,
 *      its token ID space is limited to 32 bits
 *
 * @author Basil Gorin
 */
contract AletheaNFT is TinyERC721 {
	/**
	 * @inheritdoc TinyERC721
	 */
	uint256 public constant override TOKEN_UID = 0x275ee64af649fe998ccbaec4f443dc216eef3bab6f11080eeeedfbdd303c59a6;

	/**
	 * @dev Constructs/deploys AI Personality instance
	 *      with the name and symbol defined during the deployment
	 */
	constructor(string memory _name, string memory _symbol) TinyERC721(_name, _symbol) {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC20Spec.sol";
import "../interfaces/ERC721Spec.sol";
import "../lib/StringUtils.sol";
import "../utils/AccessControl.sol";

/**
 * @title Intelligent NFT Interface
 *        Version 2
 *
 * @notice External interface of IntelligentNFTv2 declared to support ERC165 detection.
 *      Despite some similarity with ERC721 interfaces, iNFT is not ERC721, any similarity
 *      should be treated as coincidental. Client applications may benefit from this similarity
 *      to reuse some of the ERC721 client code for display/reading.
 *
 * @dev See Intelligent NFT documentation below.
 *
 * @author Basil Gorin
 */
interface IntelligentNFTv2Spec {
	/**
	 * @dev ERC20/ERC721 like name - Intelligent NFT
	 *
	 * @return "Intelligent NFT"
	 */
	function name() external view returns (string memory);

	/**
	 * @dev ERC20/ERC721 like symbol - iNFT
	 *
	 * @return "iNFT"
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev ERC721 like link to the iNFT metadata
	 *
	 * @param recordId iNFT ID to get metadata URI for
	 */
	function tokenURI(uint256 recordId) external view returns (string memory);

	/**
	 * @dev ERC20/ERC721 like counter of the iNFTs in existence (upper bound),
	 *      some (or all) of which may not exist due to target NFT destruction
	 *
	 * @return amount of iNFT tracked by this smart contract
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Check if iNFT binding with the given ID exists
	 *
	 * @return true if iNFT binding exist, false otherwise
	 */
	function exists(uint256 recordId) external view returns (bool);

	/**
	 * @dev ERC721 like function to get owner of the iNFT, which is by definition
	 *      an owner of the underlying NFT
	 */
	function ownerOf(uint256 recordId) external view returns (address);
}

/**
 * @title Intelligent NFT (iNFT)
 *        Version 2
 *
 * @notice Intelligent NFT (iNFT) represents an enhancement to an existing NFT
 *      (we call it a "target" or "target NFT"), it binds a GPT-3 prompt (a "personality prompt",
 *      delivered as an AI Personality ERC721 token bound to iNFT)
 *      to the target to embed intelligence, is controlled and belongs to the owner of the target.
 *
 * @notice iNFT stores AI Personality and some amount of ALI tokens locked, available for
 *      unlocking when iNFT is destroyed
 *
 * @notice iNFT is not an ERC721 token, but it has some very limited similarity to an ERC721:
 *      every record is identified by ID and this ID has an owner, which is effectively the target NFT owner;
 *      still, it doesn't store ownership information itself and fully relies on the target ownership instead
 *
 * @dev Internally iNFTs consist of:
 *      - target NFT - smart contract address and ID of the NFT the iNFT is bound to
 *      - AI Personality - smart contract address and ID of the AI Personality used to produce given iNFT,
 *        representing a "personality prompt", and locked within an iNFT
 *      - ALI tokens amount - amount of the ALI tokens used to produce given iNFT, also locked
 *
 * @dev iNFTs can be
 *      - created, this process requires an AI Personality and ALI tokens to be locked
 *      - destroyed, this process releases an AI Personality and ALI tokens previously locked
 *
 * @author Basil Gorin
 */
contract IntelligentNFTv2 is IntelligentNFTv2Spec, AccessControl, ERC165 {
	/**
	 * @inheritdoc IntelligentNFTv2Spec
	 */
	string public override name = "Intelligent NFT";

	/**
	 * @inheritdoc IntelligentNFTv2Spec
	 */
	string public override symbol = "iNFT";

	/**
	 * @dev Each intelligent token, represented by its unique ID, is bound to the target NFT,
	 *      defined by the pair of the target NFT smart contract address and unique token ID
	 *      within the target NFT smart contract
	 *
	 * @dev Effectively iNFT is owned by the target NFT owner
	 *
	 * @dev Additionally, each token holds an AI Personality and some amount of ALI tokens bound to it
	 *
	 * @dev `IntelliBinding` keeps all the binding information, including target NFT coordinates,
	 *      bound AI Personality ID, and amount of ALI ERC20 tokens bound to the iNFT
	 */
	struct IntelliBinding {
		// Note: structure members are reordered to fit into less memory slots, see EVM memory layout
		// ----- SLOT.1 (256/256)
		/**
		 * @dev Specific AI Personality is defined by the pair of AI Personality smart contract address
		 *       and AI Personality ID
		 *
		 * @dev Address of the AI Personality smart contract
		 */
		address personalityContract;

		/**
		 * @dev AI Personality ID within the AI Personality smart contract
		 */
		uint96 personalityId;

		// ----- SLOT.2 (256/256)
		/**
		 * @dev Amount of an ALI ERC20 tokens bound to (owned by) the iNFTs
		 *
		 * @dev ALI ERC20 smart contract address is defined globally as `aliContract` constant
		 */
		uint96 aliValue;

		/**
		 * @dev Address of the target NFT deployed smart contract,
		 *      this is a contract a particular iNFT is bound to
		 */
		address targetContract;

		// ----- SLOT.3 (256/256)
		/**
		 * @dev Target NFT ID within the target NFT smart contract,
		 *      effectively target NFT ID and contract address define the owner of an iNFT
		 */
		uint256 targetId;
	}

	/**
	 * @notice iNFT binding storage, stores binding information for each existing iNFT
	 * @dev Maps iNFT ID to its binding data, which includes underlying NFT data
	 */
	mapping(uint256 => IntelliBinding) public bindings;

	/**
	 * @notice Reverse iNFT binding allows to find iNFT bound to a particular NFT
	 * @dev Maps target NFT (smart contract address and unique token ID) to the iNFT ID:
	 *      NFT Contract => NFT ID => iNFT ID
	 */
	mapping(address => mapping(uint256 => uint256)) public reverseBindings;

	/**
	 * @notice Ai Personality to iNFT binding allows to find iNFT bound to a particular Ai Personality
	 * @dev Maps Ai Personality NFT (unique token ID) to the linked iNFT:
	 *      AI Personality Contract => AI Personality ID => iNFT ID
	 */
	mapping(address => mapping(uint256 => uint256)) public personalityBindings;

	/**
	 * @notice Total amount (maximum value estimate) of iNFT in existence.
	 *       This value can be higher than number of effectively accessible iNFTs
	 *       since when underlying NFT gets burned this value doesn't get updated.
	 */
	uint256 public override totalSupply;

	/**
	 * @notice Each iNFT holds some ALI tokens, which are tracked by the ALI token ERC20 smart contract defined here
	 */
	address public immutable aliContract;

	/**
	 * @notice ALI token balance the contract is aware of, cumulative ALI obligation,
	 *      i.e. sum of all iNFT locked ALI balances
	 *
	 * @dev Sum of all `IntelliBinding.aliValue` for each iNFT in existence
	 */
	uint256 public aliBalance;

	/**
	 * @dev Base URI is used to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 *
	 * @dev If token URI is set with `setTokenURI()` it will be returned as is via `tokenURI()`
	 */
	string public baseURI = "";

	/**
	 * @dev Optional mapping for token URIs to be returned as is when `tokenURI()`
	 *      is called; if mapping doesn't exist for token, the URI is constructed
	 *      as `base URI + token ID`, where plus (+) denotes string concatenation
	 */
	mapping(uint256 => string) internal _tokenURIs;

	/**
	 * @notice Minter is responsible for creating (minting) iNFTs
	 *
	 * @dev Role ROLE_MINTER allows minting iNFTs (calling `mint` function)
	 */
	uint32 public constant ROLE_MINTER = 0x0001_0000;

	/**
	 * @notice Burner is responsible for destroying (burning) iNFTs
	 *
	 * @dev Role ROLE_BURNER allows burning iNFTs (calling `burn` function)
	 */
	uint32 public constant ROLE_BURNER = 0x0002_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      part of the token URI ERC721Metadata interface
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0010_0000;

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string oldVal, string newVal);

	/**
	 * @dev Fired in setTokenURI()
	 *
	 * @param _by an address which executed update
	 * @param tokenId token ID which URI was updated
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event TokenURIUpdated(address indexed _by, uint256 tokenId, string oldVal, string newVal);

	/**
	 * @dev Fired in mint() when new iNFT is created
	 *
	 * @param by an address which executed the mint function
	 * @param owner current owner of the NFT
	 * @param recordId ID of the iNFT minted (created, bound)
	 * @param aliValue amount of ALI tokens locked within newly created iNFT
	 * @param personalityContract AI Personality smart contract address
	 * @param personalityId ID of the AI Personality locked within newly created iNFT
	 * @param targetContract target NFT smart contract address
	 * @param targetId target NFT ID (where this iNFT binds to and belongs to)
	 */
	event Minted(
		address indexed by,
		address owner,
		uint256 recordId,
		uint96 aliValue,
		address personalityContract,
		uint96 personalityId,
		address targetContract,
		uint256 targetId
	);

	/**
	 * @dev Fired in burn() when an existing iNFT gets destroyed
	 *
	 * @param by an address which executed the burn function
	 * @param recordId ID of the iNFT burnt (destroyed, unbound)
	 * @param recipient and address which received unlocked AI Personality and ALI tokens
	 * @param aliValue amount of ALI tokens transferred from the destroyed iNFT
	 * @param personalityContract AI Personality smart contract address
	 * @param personalityId ID of the AI Personality transferred from the destroyed iNFT
	 * @param targetContract target NFT smart contract
	 * @param targetId target NFT ID (where this iNFT was bound to and belonged to)
	 */
	event Burnt(
		address indexed by,
		uint256 recordId,
		address recipient,
		uint96 aliValue,
		address personalityContract,
		uint96 personalityId,
		address targetContract,
		uint256 targetId
	);

	/**
	 * @dev Creates/deploys an iNFT instance bound to already ALI token instance
	 *
	 * @param _ali address of the deployed ALI ERC20 Token instance the iNFT is bound to
	 */
	constructor(address _ali) {
		// verify the inputs are set
		require(_ali != address(0), "ALI Token addr is not set");

		// verify _ali is a valid ERC20
		require(ERC165(_ali).supportsInterface(type(ERC20).interfaceId), "unexpected ALI Token type");

		// setup smart contract internal state
		aliContract = _ali;
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
		// reconstruct from current interface and super interface
		return interfaceId == type(IntelligentNFTv2Spec).interfaceId;
	}

	/**
	 * @dev Restricted access function which updates base URI used to construct
	 *      ERC721Metadata.tokenURI
	 *
	 * @param _baseURI new base URI to set
	 */
	function setBaseURI(string memory _baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, _baseURI);

		// and update base URI
		baseURI = _baseURI;
	}

	/**
	 * @dev Returns token URI if it was previously set with `setTokenURI`,
	 *      otherwise constructs it as base URI + token ID
	 *
	 * @param _recordId iNFT ID to query metadata link URI for
	 * @return URI link to fetch iNFT metadata from
	 */
	function tokenURI(uint256 _recordId) public view override returns (string memory) {
		// verify token exists
		require(exists(_recordId), "iNFT doesn't exist");

		// read the token URI for the token specified
		string memory _tokenURI = _tokenURIs[_recordId];

		// if token URI is set
		if(bytes(_tokenURI).length > 0) {
			// just return it
			return _tokenURI;
		}

		// if base URI is not set
		if(bytes(baseURI).length == 0) {
			// return an empty string
			return "";
		}

		// otherwise concatenate base URI + token ID
		return StringUtils.concat(baseURI, StringUtils.itoa(_recordId, 10));
	}

	/**
	 * @dev Sets the token URI for the token defined by its ID
	 *
	 * @param _tokenId an ID of the token to set URI for
	 * @param _tokenURI token URI to set
	 */
	function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// we do not verify token existence: we want to be able to
		// preallocate token URIs before tokens are actually minted

		// emit an event first - to log both old and new values
		emit TokenURIUpdated(msg.sender, _tokenId, _tokenURIs[_tokenId], _tokenURI);

		// and update token URI
		_tokenURIs[_tokenId] = _tokenURI;
	}

	/**
	 * @notice Verifies if given iNFT exists
	 *
	 * @param recordId iNFT ID to verify existence of
	 * @return true if iNFT exists, false otherwise
	 */
	function exists(uint256 recordId) public view override returns (bool) {
		// verify if biding exists for that tokenId and return the result
		return bindings[recordId].targetContract != address(0);
	}

	/**
	 * @notice Returns an owner of the given iNFT.
	 *      By definition iNFT owner is an owner of the target NFT
	 *
	 * @param recordId iNFT ID to query ownership information for
	 * @return address of the given iNFT owner
	 */
	function ownerOf(uint256 recordId) public view override returns (address) {
		// read the token binding
		IntelliBinding memory binding = bindings[recordId];

		// verify the binding exists and throw standard Zeppelin message if not
		require(binding.targetContract != address(0), "iNFT doesn't exist");

		// delegate `ownerOf` call to the target NFT smart contract
		return ERC721(binding.targetContract).ownerOf(binding.targetId);
	}

	/**
	 * @dev Restricted access function which creates an iNFT, binding it to the specified
	 *      NFT, locking the AI Personality specified, and funded with the amount of ALI specified
	 *
	 * @dev Locks AI Personality defined by its ID within iNFT smart contract;
	 *      AI Personality is expected to be already transferred to the iNFT smart contract
	 *      prior to calling the `mint`
	 *
	 * @dev Locks specified amount of ALI token within iNFT smart contract;
	 *      ALI token amount is expected to be already transferred to the iNFT smart contract
	 *      prior to calling the `mint`
	 *
	 * @dev The NFT to be linked to is not required to owned by the funder, but it must exist;
	 *      throws if target NFT doesn't exist
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to mint (create, bind)
	 * @param aliValue amount of ALI tokens to bind to newly created iNFT
	 * @param personalityContract AI Personality contract address
	 * @param personalityId ID of the AI Personality to bind to newly created iNFT
	 * @param targetContract target NFT smart contract
	 * @param targetId target NFT ID (where this iNFT binds to and belongs to)
	 */
	function mint(
		uint256 recordId,
		uint96 aliValue,
		address personalityContract,
		uint96 personalityId,
		address targetContract,
		uint256 targetId
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_MINTER), "access denied");

		// verify personalityContract is a valid ERC721
		require(ERC165(personalityContract).supportsInterface(type(ERC721).interfaceId), "personality is not ERC721");

		// verify targetContract is a valid ERC721
		require(ERC165(targetContract).supportsInterface(type(ERC721).interfaceId), "target NFT is not ERC721");

		// verify this iNFT is not yet minted
		require(!exists(recordId), "iNFT already exists");

		// verify target NFT is not yet bound to
		require(reverseBindings[targetContract][targetId] == 0, "NFT is already bound");

		// verify AI Personality is not yet locked
		require(personalityBindings[personalityContract][personalityId] == 0, "personality already linked");

		// verify if AI Personality is already transferred to iNFT
		require(ERC721(personalityContract).ownerOf(personalityId) == address(this), "personality is not yet transferred");

		// retrieve NFT owner and verify if target NFT exists
		address owner = ERC721(targetContract).ownerOf(targetId);
		// Note: we do not require funder to be NFT owner,
		// if required this constraint should be added by the caller (iNFT Linker)
		require(owner != address(0), "target NFT doesn't exist");

		// in case when ALI tokens are expected to be locked within iNFT
		if(aliValue > 0) {
			// verify ALI tokens are already transferred to iNFT
			require(aliBalance + aliValue <= ERC20(aliContract).balanceOf(address(this)), "ALI tokens not yet transferred");

			// update ALI balance on the contract
			aliBalance += aliValue;
		}

		// bind AI Personality transferred and ALI ERC20 value transferred to an NFT specified
		bindings[recordId] = IntelliBinding({
			personalityContract : personalityContract,
			personalityId : personalityId,
			aliValue : aliValue,
			targetContract : targetContract,
			targetId : targetId
		});

		// fill in the reverse binding
		reverseBindings[targetContract][targetId] = recordId;

		// fill in the AI Personality to iNFT binding
		personalityBindings[personalityContract][personalityId] = recordId;

		// increase total supply counter
		totalSupply++;

		// emit an event
		emit Minted(
			msg.sender,
			owner,
			recordId,
			aliValue,
			personalityContract,
			personalityId,
			targetContract,
			targetId
		);
	}

	/**
	 * @dev Restricted access function which creates several iNFTs, binding them to the specified
	 *      NFTs, locking the AI Personalities specified, each funded with the amount of ALI specified
	 *
	 * @dev Locks AI Personalities defined by their IDs within iNFT smart contract;
	 *      AI Personalities are expected to be already transferred to the iNFT smart contract
	 *      prior to calling the `mintBatch`
	 *
	 * @dev Locks specified amount of ALI token within iNFT smart contract for each iNFT minted;
	 *      ALI token amount is expected to be already transferred to the iNFT smart contract
	 *      prior to calling the `mint`
	 *
	 * @dev The NFTs to be linked to are not required to owned by the funder, but they must exist;
	 *      throws if target NFTs don't exist
	 *
	 * @dev iNFT IDs to be minted: [recordId, recordId + n)
	 * @dev AI Personality IDs to be locked: [personalityId, personalityId + n)
	 * @dev NFT IDs to be bound to: [targetId, targetId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the first iNFT to mint (create, bind)
	 * @param aliValue amount of ALI tokens to bind to each newly created iNFT
	 * @param personalityContract AI Personality contract address
	 * @param personalityId ID of the first AI Personality to bind to newly created iNFT
	 * @param targetContract target NFT smart contract
	 * @param targetId first target NFT ID (where this iNFT binds to and belongs to)
	 * @param n how many iNFTs to mint, sequentially increasing the recordId, personalityId, and targetId
	 */
	function mintBatch(
		uint256 recordId,
		uint96 aliValue,
		address personalityContract,
		uint96 personalityId,
		address targetContract,
		uint256 targetId,
		uint96 n
	) public {
		// verify the access permission
		require(isSenderInRole(ROLE_MINTER), "access denied");

		// verify n is set properly
		require(n > 1, "n is too small");

		// verify personalityContract is a valid ERC721
		require(ERC165(personalityContract).supportsInterface(type(ERC721).interfaceId), "personality is not ERC721");

		// verify targetContract is a valid ERC721
		require(ERC165(targetContract).supportsInterface(type(ERC721).interfaceId), "target NFT is not ERC721");

		// verifications: for each iNFT in a batch
		for(uint96 i = 0; i < n; i++) {
			// verify this token ID is not yet bound
			require(!exists(recordId + i), "iNFT already exists");

			// verify the AI Personality is not yet bound
			require(personalityBindings[personalityContract][personalityId + i] == 0, "personality already linked");

			// verify if AI Personality is already transferred to iNFT
			require(ERC721(personalityContract).ownerOf(personalityId + i) == address(this), "personality is not yet transferred");

			// retrieve NFT owner and verify if target NFT exists
			address owner = ERC721(targetContract).ownerOf(targetId + i);
			// Note: we do not require funder to be NFT owner,
			// if required this constraint should be added by the caller (iNFT Linker)
			require(owner != address(0), "target NFT doesn't exist");

			// emit an event - we log owner for each iNFT
			// and its convenient to do it here when we have the owner inline
			emit Minted(
				msg.sender,
				owner,
				recordId + i,
				aliValue,
				personalityContract,
				personalityId + i,
				targetContract,
				targetId + i
			);
		}

		// cumulative ALI value may overflow uint96, store it into uint256 on stack
		uint256 _aliValue = uint256(aliValue) * n;

		// in case when ALI tokens are expected to be locked within iNFT
		if(_aliValue > 0) {
			// verify ALI tokens are already transferred to iNFT
			require(aliBalance + _aliValue <= ERC20(aliContract).balanceOf(address(this)), "ALI tokens not yet transferred");
			// update ALI balance on the contract
			aliBalance += _aliValue;
		}

		// minting: for each iNFT in a batch
		for(uint96 i = 0; i < n; i++) {
			// bind AI Personality transferred and ALI ERC20 value transferred to an NFT specified
			bindings[recordId + i] = IntelliBinding({
				personalityContract : personalityContract,
				personalityId : personalityId + i,
				aliValue : aliValue,
				targetContract : targetContract,
				targetId : targetId + i
			});

			// fill in the AI Personality to iNFT binding
			personalityBindings[personalityContract][personalityId + i] = recordId + i;

			// fill in the reverse binding
			reverseBindings[targetContract][targetId + i] = recordId + i;
		}

		// increase total supply counter
		totalSupply += n;
	}

	/**
	 * @dev Restricted access function which destroys an iNFT, unbinding it from the
	 *      linked NFT, releasing an AI Personality, and ALI tokens locked in the iNFT
	 *
	 * @dev Transfers an AI Personality locked in iNFT to its owner via ERC721.safeTransferFrom;
	 *      owner must be an EOA or implement ERC721Receiver.onERC721Received properly
	 * @dev Transfers ALI tokens locked in iNFT to its owner
	 * @dev Since iNFT owner is determined as underlying NFT owner, this underlying NFT must
	 *      exist and its ownerOf function must not throw and must return non-zero owner address
	 *      for the underlying NFT ID
	 *
	 * @dev Doesn't verify if it's safe to send ALI tokens to the NFT owner, this check
	 *      must be handled by the transaction executor
	 *
	 * @dev This is a restricted function which is accessed by iNFT Linker
	 *
	 * @param recordId ID of the iNFT to burn (destroy, unbind)
	 */
	function burn(uint256 recordId) public {
		// verify the access permission
		require(isSenderInRole(ROLE_BURNER), "access denied");

		// decrease total supply counter
		totalSupply--;

		// read the token binding
		IntelliBinding memory binding = bindings[recordId];

		// verify binding exists
		require(binding.targetContract != address(0), "not bound");

		// destroy binding first to protect from any reentrancy possibility
		delete bindings[recordId];

		// free the reverse binding
		delete reverseBindings[binding.targetContract][binding.targetId];

		// free the AI Personality binding
		delete personalityBindings[binding.personalityContract][binding.personalityId];

		// determine an owner of the underlying NFT
		address owner = ERC721(binding.targetContract).ownerOf(binding.targetId);

		// verify that owner address is set (not a zero address)
		require(owner != address(0), "no such NFT");

		// transfer the AI Personality to the NFT owner
		// using safe transfer since we don't know if owner address can accept the AI Personality right now
		ERC721(binding.personalityContract).safeTransferFrom(address(this), owner, binding.personalityId);

		// in case when ALI tokens were locked within iNFT
		if(binding.aliValue > 0) {
			// update ALI balance on the contract prior to token transfer (reentrancy style)
			aliBalance -= binding.aliValue;

			// transfer the ALI tokens to the NFT owner
			ERC20(aliContract).transfer(owner, binding.aliValue);
		}

		// emit an event
		emit Burnt(
			msg.sender,
			recordId,
			owner,
			binding.aliValue,
			binding.personalityContract,
			binding.personalityId,
			binding.targetContract,
			binding.targetId
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @author Basil Gorin
 */
contract AccessControl {
	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @notice Creates an access control instance,
	 *      setting contract creator to have full privileges
	 */
	constructor() {
		// contract creator has full privileges
		userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ERC721Spec.sol";
import "../interfaces/AletheaERC721Spec.sol";
import "../utils/AccessControl.sol";
import "../lib/AddressUtils.sol";
import "../lib/ArrayUtils.sol";
import "../lib/StringUtils.sol";
import "../lib/ECDSA.sol";

/**
 * @title Tiny ERC721
 *
 * @notice Tiny ERC721 defines an NFT with a very small (up to 32 bits) ID space.
 *      ERC721 enumeration support requires additional writes to the storage:
 *      - when transferring a token in order to update the NFT collections of
 *        the previous and next owners,
 *      - when minting/burning a token in order to update global NFT collection
 *
 * @notice Reducing the NFT ID space to 48 bits allows to eliminate the need to have
 *      and to write to two additional storage mappings
 * @notice Further reducing NFT ID space to 32 bits allows for batch minting optimization
 *      by writing 8 tokens instead of 5 at once into global/local collections
 *
 * @notice This smart contract is designed to be inherited by concrete implementations,
 *      which are expected to define token metadata, auxiliary functions to access the metadata,
 *      and explicitly define token minting interface, which should be built on top
 *      of current smart contract internal interface
 *
 * @notice Fully ERC721-compatible with all optional interfaces implemented (metadata, enumeration),
 *      see https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev ERC721: contract has passed adopted OpenZeppelin ERC721 tests
 *        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC721/ERC721.behavior.js
 *        https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/test/token/ERC721/extensions/ERC721URIStorage.test.js
 *
 * @dev A note on token URI: there are major differences on how token URI behaves comparing to Zeppelin impl:
 *      1. A token URI can be set for non-existing token for pre-allocation purposes,
 *         still the URI will be deleted once token is burnt
 *      2. If token URI is set, base URI has no affect on the token URI, the two are not concatenated,
 *         base URI is used to construct the token URI only if the latter was not explicitly set
 *
 * @dev Supports EIP-712 powered permits - permit() - approve() with signature.
 *      Supports EIP-712 powered operator permits - permitForAll() - setApprovalForAll() with signature.
 *
 * @dev EIP712 Domain:
 *      name: AliERC721v1
 *      version: not in use, omitted (name already contains version)
 *      chainId: EIP-155 chain id
 *      verifyingContract: deployed contract address
 *      salt: permitNonces[owner], where owner is an address which allows operation on their tokens
 *
 * @dev Permit type:
 *      owner: address
 *      operator: address
 *      tokenId: uint256
 *      nonce: uint256
 *      deadline: uint256
 *
 * @dev Permit typeHash:
 *        keccak256("Permit(address owner,address operator,uint256 tokenId,uint256 nonce,uint256 deadline)")
 *
 * @dev PermitForAll type:
 *      owner: address
 *      operator: address
 *      approved: bool
 *      nonce: uint256
 *      deadline: uint256
 *
 * @dev PermitForAll typeHash:
 *        keccak256("PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)")
 *
 * @dev See https://eips.ethereum.org/EIPS/eip-712
 * @dev See usage examples in tests: erc721_permits.js
 *
 * @author Basil Gorin
 */
abstract contract TinyERC721 is ERC721Enumerable, ERC721Metadata, MintableERC721, BurnableERC721, AccessControl {
	// enable push32 optimization for uint32[]
	using ArrayUtils for uint32[];

	/**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 * @dev Example value: 0xdbdd2b4ff38a8516da0b8e7ae93288b5e2fed0c92fb051cee90ccf4e4ec9736e
	 */
	function TOKEN_UID() external view virtual returns(uint256);

	/**
	 * @notice ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 *
	 * @inheritdoc ERC721Metadata
	 */
	string public override name;

	/**
	 * @notice ERC-20 compatible abbreviated name for a collection of NFTs in this contract
	 *
	 * @inheritdoc ERC721Metadata
	 */
	string public override symbol;

	/**
	 * @notice Current implementation includes a function `decimals` that returns uint8(0)
	 *      to be more compatible with ERC-20
	 *
	 * @dev ERC20 compliant token decimals is equal to zero since ERC721 token is non-fungible
	 *      and therefore non-divisible
	 */
	uint8 public constant decimals = 0;

	/**
	 * @notice Ownership information for all the tokens in existence
	 *
	 * @dev Maps `Token ID => Token ID Global Index | Token ID Local Index | Token Owner Address`, where
	 *      - Token ID Global Index denotes Token ID index in the array of all the tokens,
	 *      - Token ID Local Index denotes Token ID index in the array of all the tokens owned by the owner,
	 *      - Token ID indexes are 32 bits long,
	 *      - `|` denotes bitwise concatenation of the values
	 * @dev Token Owner Address for a given Token ID is lower 160 bits of the mapping value
	 */
	mapping(uint256 => uint256) internal tokens;

	/**
	 * @notice Enumerated collections of the tokens owned by particular owners
	 *
	 * @dev We call these collections "Local" token collections
	 *
	 * @dev Maps `Token Owner Address => Owned Token IDs Array`
	 *
	 * @dev Token owner balance is the length of their token collection:
	 *      `balanceOf(owner) = collections[owner].length`
	 */
	mapping(address => uint32[]) internal collections;

	/**
	 * @notice An array of all the tokens in existence
	 *
	 * @dev We call this collection "Global" token collection
	 *
	 * @dev Array with all Token IDs, used for enumeration
	 *
	 * @dev Total token supply `tokenSupply` is the length of this collection:
	 *      `totalSupply() = allTokens.length`
	 */
	uint32[] internal allTokens;

	/**
	 * @notice Addresses approved by token owners to transfer their tokens
	 *
	 * @dev `Maps Token ID => Approved Address`, where
	 *      Approved Address is an address allowed transfer ownership for the token
	 *      defined by Token ID
	 */
	mapping(uint256 => address) internal approvals;

	/**
	 * @notice Addresses approved by token owners to transfer all their tokens
	 *
	 * @dev Maps `Token Owner Address => Operator Address => Approval State` - true/false (approved/not), where
	 *      - Token Owner Address is any address which may own tokens or not,
	 *      - Operator Address is any other address which may own tokens or not,
	 *      - Approval State is a flag indicating if Operator Address is allowed to
	 *        transfer tokens owned by Token Owner Address o their behalf
	 */
	mapping(address => mapping(address => bool)) internal approvedOperators;

	/**
	 * @dev A record of nonces for signing/validating signatures in EIP-712 based
	 *      `permit` and `permitForAll` functions
	 *
	 * @dev Each time the nonce is used, it is increased by one, meaning reordering
	 *      of the EIP-712 transactions is not possible
	 *
	 * @dev Inspired by EIP-2612 extension for ERC20 token standard
	 *
	 * @dev Maps token owner address => token owner nonce
	 */
	mapping(address => uint256) public permitNonces;

	/**
	 * @dev Base URI is used to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 *
	 * @dev If token URI is set with `setTokenURI()` it will be returned as is via `tokenURI()`
	 */
	string public baseURI = "";

	/**
	 * @dev Optional mapping for token URIs to be returned as is when `tokenURI()`
	 *      is called; if mapping doesn't exist for token, the URI is constructed
	 *      as `base URI + token ID`, where plus (+) denotes string concatenation
	 */
	mapping(uint256 => string) internal _tokenURIs;

	/**
	 * @dev 32 bit token ID space is optimal for batch minting in batches of size 8
	 *      8 * 32 = 256 - single storage slot in global/local collection(s)
	 */
	uint8 public constant BATCH_SIZE_MULTIPLIER = 8;

	/**
	 * @notice Enables ERC721 transfers of the tokens
	 *      (transfer by the token owner himself)
	 * @dev Feature FEATURE_TRANSFERS must be enabled in order for
	 *      `transferFrom()` function to succeed when executed by token owner
	 */
	uint32 public constant FEATURE_TRANSFERS = 0x0000_0001;

	/**
	 * @notice Enables ERC721 transfers on behalf
	 *      (transfer by someone else on behalf of token owner)
	 * @dev Feature FEATURE_TRANSFERS_ON_BEHALF must be enabled in order for
	 *      `transferFrom()` function to succeed whe executed by approved operator
	 * @dev Token owner must call `approve()` or `setApprovalForAll()`
	 *      first to authorize the transfer on behalf
	 */
	uint32 public constant FEATURE_TRANSFERS_ON_BEHALF = 0x0000_0002;

	/**
	 * @notice Enables token owners to burn their own tokens
	 *
	 * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
	 *      `burn()` function to succeed when called by token owner
	 */
	uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

	/**
	 * @notice Enables approved operators to burn tokens on behalf of their owners
	 *
	 * @dev Feature FEATURE_BURNS_ON_BEHALF must be enabled in order for
	 *      `burn()` function to succeed when called by approved operator
	 */
	uint32 public constant FEATURE_BURNS_ON_BEHALF = 0x0000_0010;

	/**
	 * @notice Enables approvals on behalf (permits via an EIP712 signature)
	 * @dev Feature FEATURE_PERMITS must be enabled in order for
	 *      `permit()` function to succeed
	 */
	uint32 public constant FEATURE_PERMITS = 0x0000_0200;

	/**
	 * @notice Enables operator approvals on behalf (permits for all via an EIP712 signature)
	 * @dev Feature FEATURE_OPERATOR_PERMITS must be enabled in order for
	 *      `permitForAll()` function to succeed
	 */
	uint32 public constant FEATURE_OPERATOR_PERMITS = 0x0000_0400;

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (calling `mint` function)
	 */
	uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

	/**
	 * @notice Token destroyer is responsible for destroying (burning)
	 *      tokens owned by an arbitrary address
	 * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
	 *      (calling `burn` function)
	 */
	uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      part of the token URI ERC721Metadata interface
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0010_0000;

	/**
	 * @notice EIP-712 contract's domain typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 *
	 * @dev Note: we do not include version into the domain typehash/separator,
	 *      it is implied version is concatenated to the name field, like "AliERC721v1"
	 */
	// keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 public constant DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	/**
	 * @notice EIP-712 contract's domain separator,
	 *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
	 */
	bytes32 public immutable DOMAIN_SEPARATOR;

	/**
	 * @notice EIP-712 permit (EIP-2612) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("Permit(address owner,address operator,uint256 tokenId,uint256 nonce,uint256 deadline)")
	bytes32 public constant PERMIT_TYPEHASH = 0xee2282d7affd5a432b221a559e429129347b0c19a3f102179a5fb1859eef3d29;

	/**
	 * @notice EIP-712 permitForAll (EIP-2612) struct typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 */
	// keccak256("PermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)")
	bytes32 public constant PERMIT_FOR_ALL_TYPEHASH = 0x47ab88482c90e4bb94b82a947ae78fa91fb25de1469ab491f4c15b9a0a2677ee;

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string oldVal, string newVal);

	/**
	 * @dev Fired in setTokenURI()
	 *
	 * @param _by an address which executed update
	 * @param tokenId token ID which URI was updated
	 * @param oldVal old _baseURI value
	 * @param newVal new _baseURI value
	 */
	event TokenURIUpdated(address indexed _by, uint256 tokenId, string oldVal, string newVal);

	/**
	 * @dev Constructs/deploys ERC721 instance with the name and symbol specified
	 *
	 * @param _name name of the token to be accessible as `name()`,
	 *      ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 * @param _symbol token symbol to be accessible as `symbol()`,
	 *      ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 */
	constructor(string memory _name, string memory _symbol) {
		// set the name
		name = _name;

		// set the symbol
		symbol = _symbol;

		// build the EIP-712 contract domain separator, see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
		// note: we specify contract version in its name
		DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("AliERC721v1")), block.chainid, address(this)));
	}

	/**
	 * @dev Verifies if token is transferable (i.e. can change ownership, allowed to be transferred);
	 *      The default behaviour is to always allow transfer if token exists
	 *
	 * @dev Implementations may modify the default behaviour based on token metadata
	 *      if required
	 *
	 * @param _tokenId ID of the token to check if it's transferable
	 * @return true if token is transferable, false otherwise
	 */
	function isTransferable(uint256 _tokenId) public view virtual returns(bool) {
		// validate token existence
		require(exists(_tokenId), "token doesn't exist");

		// generic implementation returns true if token exists
		return true;
	}

	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) public view returns(bool) {
		// read ownership information and return a check if it's not zero (set)
		return tokens[_tokenId] != 0;
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		// construct the interface support from required and optional ERC721 interfaces
		return interfaceId == type(ERC165).interfaceId
			|| interfaceId == type(ERC721).interfaceId
			|| interfaceId == type(ERC721Metadata).interfaceId
			|| interfaceId == type(ERC721Enumerable).interfaceId
			|| interfaceId == type(MintableERC721).interfaceId
			|| interfaceId == type(BurnableERC721).interfaceId;
	}

	// ===== Start: ERC721 Metadata =====

	/**
	 * @dev Restricted access function which updates base URI used to construct
	 *      ERC721Metadata.tokenURI
	 *
	 * @dev Requires executor to have ROLE_URI_MANAGER permission
	 *
	 * @param _baseURI new base URI to set
	 */
	function setBaseURI(string memory _baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, _baseURI);

		// and update base URI
		baseURI = _baseURI;
	}

	/**
	 * @dev Returns token URI if it was previously set with `setTokenURI`,
	 *      otherwise constructs it as base URI + token ID
	 *
	 * @inheritdoc ERC721Metadata
	 */
	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		// verify token exists
		require(exists(_tokenId), "token doesn't exist");

		// read the token URI for the token specified
		string memory _tokenURI = _tokenURIs[_tokenId];

		// if token URI is set
		if(bytes(_tokenURI).length > 0) {
			// just return it
			return _tokenURI;
		}

		// if base URI is not set
		if(bytes(baseURI).length == 0) {
			// return an empty string
			return "";
		}

		// otherwise concatenate base URI + token ID
		return StringUtils.concat(baseURI, StringUtils.itoa(_tokenId, 10));
	}

	/**
	 * @dev Sets the token URI for the token defined by its ID
	 *
	 * @param _tokenId an ID of the token to set URI for
	 * @param _tokenURI token URI to set
	 */
	function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// we do not verify token existence: we want to be able to
		// preallocate token URIs before tokens are actually minted

		// emit an event first - to log both old and new values
		emit TokenURIUpdated(msg.sender, _tokenId, _tokenURIs[_tokenId], _tokenURI);

		// and update token URI
		_tokenURIs[_tokenId] = _tokenURI;
	}

	// ===== End: ERC721 Metadata =====

	// ===== Start: ERC721, ERC721Enumerable Getters (view functions) =====

	/**
	 * @inheritdoc ERC721
	 */
	function balanceOf(address _owner) public view override returns (uint256) {
		// check `_owner` address is set
		require(_owner != address(0), "zero address");

		// derive owner balance for the their owned tokens collection
		// as the length of that collection
		return collections[_owner].length;
	}

	/**
	 * @inheritdoc ERC721
	 */
	function ownerOf(uint256 _tokenId) public view override returns (address) {
		// derive ownership information of the token from the ownership mapping
		// by extracting lower 160 bits of the mapping value as an address
		address owner = address(uint160(tokens[_tokenId]));

		// verify owner/token exists
		require(owner != address(0), "token doesn't exist");

		// return owner address
		return owner;
	}

	/**
	 * @inheritdoc ERC721Enumerable
	 */
	function totalSupply() public view override returns (uint256) {
		// derive total supply value from the array of all existing tokens
		// as the length of this array
		return allTokens.length;
	}

	/**
	 * @inheritdoc ERC721Enumerable
	 */
	function tokenByIndex(uint256 _index) public view override returns (uint256) {
		// index out of bounds check
		require(_index < totalSupply(), "index out of bounds");

		// find the token ID requested and return
		return allTokens[_index];
	}

	/**
	 * @inheritdoc ERC721Enumerable
	 */
	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view override returns (uint256) {
		// index out of bounds check
		require(_index < balanceOf(_owner), "index out of bounds");

		// find the token ID requested and return
		return collections[_owner][_index];
	}

	/**
	 * @inheritdoc ERC721
	 */
	function getApproved(uint256 _tokenId) public view override returns (address) {
		// verify token specified exists
		require(exists(_tokenId), "token doesn't exist");

		// read the approval value and return
		return approvals[_tokenId];
	}

	/**
	 * @inheritdoc ERC721
	 */
	function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
		// read the approval state value and return
		return approvedOperators[_owner][_operator];
	}

	// ===== End: ERC721, ERC721Enumerable Getters (view functions) =====

	// ===== Start: ERC721 mutative functions (transfers, approvals) =====

	/**
	 * @inheritdoc ERC721
	 */
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
		// delegate call to unsafe transfer on behalf `transferFrom()`
		transferFrom(_from, _to, _tokenId);

		// if receiver `_to` is a smart contract
		if(AddressUtils.isContract(_to)) {
			// check it supports ERC721 interface - execute onERC721Received()
			bytes4 response = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);

			// expected response is ERC721TokenReceiver(_to).onERC721Received.selector
			// bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
			require(response == ERC721TokenReceiver(_to).onERC721Received.selector, "invalid onERC721Received response");
		}
	}

	/**
	 * @inheritdoc ERC721
	 */
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
		// delegate call to overloaded `safeTransferFrom()`, set data to ""
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	/**
	 * @inheritdoc ERC721
	 */
	function transferFrom(address _from, address _to, uint256 _tokenId) public override {
		// if `_from` is equal to sender, require transfers feature to be enabled
		// otherwise require transfers on behalf feature to be enabled
		require(_from == msg.sender && isFeatureEnabled(FEATURE_TRANSFERS)
		     || _from != msg.sender && isFeatureEnabled(FEATURE_TRANSFERS_ON_BEHALF),
		        _from == msg.sender? "transfers are disabled": "transfers on behalf are disabled");

		// validate destination address is set
		require(_to != address(0), "zero address");

		// validate token ownership, which also
		// validates token existence under the hood
		require(_from == ownerOf(_tokenId), "access denied");

		// verify operator (transaction sender) is either token owner,
		// or is approved by the token owner to transfer this particular token,
		// or is approved by the token owner to transfer any of his tokens
		require(_from == msg.sender || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender), "access denied");

		// transfer is not allowed for a locked token
		require(isTransferable(_tokenId), "locked token");

		// if required, move token ownership,
		// update old and new owner's token collections accordingly:
		if(_from != _to) {
			// remove token from old owner's collection (also clears approval)
			__removeLocal(_tokenId);
			// add token to the new owner's collection
			__addLocal(_tokenId, _to);
		}
		// even if no real changes are required, approval needs to be erased
		else {
			// clear token approval (also emits an Approval event)
			__clearApproval(_from, _tokenId);
		}

		// fire ERC721 transfer event
		emit Transfer(_from, _to, _tokenId);
	}

	/**
	 * @inheritdoc ERC721
	 */
	function approve(address _approved, uint256 _tokenId) public override {
		// make an internal approve - delegate to `__approve`
		__approve(msg.sender, _approved, _tokenId);
	}

	/**
	 * @dev Powers the meta transaction for `approve` - EIP-712 signed `permit`
	 *
	 * @dev Approves address called `_operator` to transfer token `_tokenId`
	 *      on behalf of the `_owner`
	 *
	 * @dev Zero `_operator` address indicates there is no approved address,
	 *      and effectively removes an approval for the token specified
	 *
	 * @dev `_owner` must own token `_tokenId` to grant the permission
	 * @dev Throws if `_operator` is a self address (`_owner`),
	 *      or if `_tokenId` doesn't exist
	 *
	 * @param _owner owner of the token `_tokenId` to set approval on behalf of
	 * @param _operator an address approved by the token owner
	 *      to spend token `_tokenId` on its behalf
	 * @param _tokenId token ID operator `_approved` is allowed to
	 *      transfer on behalf of the token owner
	 */
	function __approve(address _owner, address _operator, uint256 _tokenId) private {
		// get token owner address
		address owner = ownerOf(_tokenId);

		// approving owner address itself doesn't make sense and is not allowed
		require(_operator != owner, "self approval");

		// only token owner or/and approved operator can set the approval
		require(_owner == owner || isApprovedForAll(owner, _owner), "access denied");

		// update the approval
		approvals[_tokenId] = _operator;

		// emit an event
		emit Approval(owner, _operator, _tokenId);
	}

	/**
	 * @inheritdoc ERC721
	 */
	function setApprovalForAll(address _operator, bool _approved) public override {
		// make an internal approve - delegate to `__approveForAll`
		__approveForAll(msg.sender, _operator, _approved);
	}

	/**
	 * @dev Powers the meta transaction for `setApprovalForAll` - EIP-712 signed `permitForAll`
	 *
	 * @dev Approves address called `_operator` to transfer any tokens
	 *      on behalf of the `_owner`
	 *
	 * @dev `_owner` must not necessarily own any tokens to grant the permission
	 * @dev Throws if `_operator` is a self address (`_owner`)
	 *
	 * @param _owner owner of the tokens to set approval on behalf of
	 * @param _operator an address to add to the set of authorized operators, i.e.
	 *      an address approved by the token owner to spend tokens on its behalf
	 * @param _approved true if the operator is approved, false to revoke approval
	 */
	function __approveForAll(address _owner, address _operator, bool _approved) private {
		// approving tx sender address itself doesn't make sense and is not allowed
		require(_operator != _owner, "self approval");

		// update the approval
		approvedOperators[_owner][_operator] = _approved;

		// emit an event
		emit ApprovalForAll(_owner, _operator, _approved);
	}

	/**
	 * @dev Clears approval for a given token owned by a given owner,
	 *      emits an Approval event
	 *
	 * @dev Unsafe: doesn't check the validity of inputs (must be kept private),
	 *      assuming the check is done by the caller
	 *      - token existence
	 *      - token ownership
	 *
	 * @param _owner token owner to be logged into Approved event as is
	 * @param _tokenId token ID to erase approval for and to log into Approved event as is
	 */
	function __clearApproval(address _owner, uint256 _tokenId) internal {
		// clear token approval
		delete approvals[_tokenId];
		// emit an ERC721 Approval event:
		// "When a Transfer event emits, this also indicates that the approved
		// address for that NFT (if any) is reset to none."
		emit Approval(_owner, address(0), _tokenId);
	}

	// ===== End: ERC721 mutative functions (transfers, approvals) =====

	// ===== Start: Meta-transactions Support =====

	/**
	 * @notice Change or reaffirm the approved address for an NFT on behalf
	 *
	 * @dev Executes approve(_operator, _tokenId) on behalf of the token owner
	 *      who EIP-712 signed the transaction, i.e. as if transaction sender is the EIP712 signer
	 *
	 * @dev Sets the `_tokenId` as the allowance of `_operator` over `_owner` token,
	 *      given `_owner` EIP-712 signed approval
	 *
	 * @dev Emits `Approval` event in the same way as `approve` does
	 *
	 * @dev Requires:
	 *     - `_operator` to be non-zero address
	 *     - `_exp` to be a timestamp in the future
	 *     - `v`, `r` and `s` to be a valid `secp256k1` signature from `_owner`
	 *        over the EIP712-formatted function arguments.
	 *     - the signature to use `_owner` current nonce (see `permitNonces`).
	 *
	 * @dev For more information on the signature format, see the
	 *      https://eips.ethereum.org/EIPS/eip-2612#specification
	 *
	 * @param _owner owner of the token to set approval on behalf of,
	 *      an address which signed the EIP-712 message
	 * @param _operator new approved NFT controller
	 * @param _tokenId token ID to approve
	 * @param _exp signature expiration time (unix timestamp)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function permit(address _owner, address _operator, uint256 _tokenId, uint256 _exp, uint8 v, bytes32 r, bytes32 s) public {
		// verify permits are enabled
		require(isFeatureEnabled(FEATURE_PERMITS), "permits are disabled");

		// derive signer of the EIP712 Permit message, and
		// update the nonce for that particular signer to avoid replay attack!!! ----------->>> ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
		address signer = __deriveSigner(abi.encode(PERMIT_TYPEHASH, _owner, _operator, _tokenId, permitNonces[_owner]++, _exp), v, r, s);

		// perform message integrity and security validations
		require(signer == _owner, "invalid signature");
		require(block.timestamp < _exp, "signature expired");

		// delegate call to `__approve` - execute the logic required
		__approve(_owner, _operator, _tokenId);
	}

	/**
	 * @notice Enable or disable approval for a third party ("operator") to manage
	 *      all of owner's assets - on behalf
	 *
	 * @dev Executes setApprovalForAll(_operator, _approved) on behalf of the owner
	 *      who EIP-712 signed the transaction, i.e. as if transaction sender is the EIP712 signer
	 *
	 * @dev Sets the `_operator` as the token operator for `_owner` tokens,
	 *      given `_owner` EIP-712 signed approval
	 *
	 * @dev Emits `ApprovalForAll` event in the same way as `setApprovalForAll` does
	 *
	 * @dev Requires:
	 *     - `_operator` to be non-zero address
	 *     - `_exp` to be a timestamp in the future
	 *     - `v`, `r` and `s` to be a valid `secp256k1` signature from `_owner`
	 *        over the EIP712-formatted function arguments.
	 *     - the signature to use `_owner` current nonce (see `permitNonces`).
	 *
	 * @dev For more information on the signature format, see the
	 *      https://eips.ethereum.org/EIPS/eip-2612#specification
	 *
	 * @param _owner owner of the tokens to set approval on behalf of,
	 *      an address which signed the EIP-712 message
	 * @param _operator an address to add to the set of authorized operators, i.e.
	 *      an address approved by the token owner to spend tokens on its behalf
	 * @param _approved true if the operator is approved, false to revoke approval
	 * @param _exp signature expiration time (unix timestamp)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function permitForAll(address _owner, address _operator, bool _approved, uint256 _exp, uint8 v, bytes32 r, bytes32 s) public {
		// verify permits are enabled
		require(isFeatureEnabled(FEATURE_OPERATOR_PERMITS), "operator permits are disabled");

		// derive signer of the EIP712 PermitForAll message, and
		// update the nonce for that particular signer to avoid replay attack!!! --------------------->>> ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
		address signer = __deriveSigner(abi.encode(PERMIT_FOR_ALL_TYPEHASH, _owner, _operator, _approved, permitNonces[_owner]++, _exp), v, r, s);

		// perform message integrity and security validations
		require(signer == _owner, "invalid signature");
		require(block.timestamp < _exp, "signature expired");

		// delegate call to `__approve` - execute the logic required
		__approveForAll(_owner, _operator, _approved);
	}

	/**
	 * @dev Auxiliary function to verify structured EIP712 message signature and derive its signer
	 *
	 * @param abiEncodedTypehash abi.encode of the message typehash together with all its parameters
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function __deriveSigner(bytes memory abiEncodedTypehash, uint8 v, bytes32 r, bytes32 s) private view returns(address) {
		// build the EIP-712 hashStruct of the message
		bytes32 hashStruct = keccak256(abiEncodedTypehash);

		// calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

		// recover the address which signed the message with v, r, s
		address signer = ECDSA.recover(digest, v, r, s);

		// return the signer address derived from the signature
		return signer;
	}

	// ===== End: Meta-transactions Support =====

	// ===== Start: mint/burn support =====

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) public override {
		// delegate to unsafe mint
		mint(_to, _tokenId);

		// make it safe: execute `onERC721Received`

		// if receiver `_to` is a smart contract
		if(AddressUtils.isContract(_to)) {
			// check it supports ERC721 interface - execute onERC721Received()
			bytes4 response = ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId, _data);

			// expected response is ERC721TokenReceiver(_to).onERC721Received.selector
			// bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
			require(response == ERC721TokenReceiver(_to).onERC721Received.selector, "invalid onERC721Received response");
		}
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) public override {
		// delegate to `safeMint` with empty data
		safeMint(_to, _tokenId, "");
	}

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) public override {
		// delegate to unsafe mint
		mintBatch(_to, _tokenId, n);

		// make it safe: execute `onERC721Received`

		// if receiver `_to` is a smart contract
		if(AddressUtils.isContract(_to)) {
			// onERC721Received: for each token minted
			for(uint256 i = 0; i < n; i++) {
				// check it supports ERC721 interface - execute onERC721Received()
				bytes4 response = ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId + i, _data);

				// expected response is ERC721TokenReceiver(_to).onERC721Received.selector
				// bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
				require(response == ERC721TokenReceiver(_to).onERC721Received.selector, "invalid onERC721Received response");
			}
		}
	}

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) public override {
		// delegate to `safeMint` with empty data
		safeMintBatch(_to, _tokenId, n, "");
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) public override {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// verify the inputs

		// verify destination address is set
		require(_to != address(0), "zero address");
		// verify the token ID is "tiny" (32 bits long at most)
		require(uint32(_tokenId) == _tokenId, "token ID overflow");

		// verify token doesn't yet exist
		require(!exists(_tokenId), "already minted");

		// create token ownership record,
		// add token to `allTokens` and new owner's collections
		// add token to both local and global collections (enumerations)
		__addToken(_tokenId, _to);

		// fire ERC721 transfer event
		emit Transfer(address(0), _to, _tokenId);
	}

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) public override {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// verify the inputs

		// verify destination address is set
		require(_to != address(0), "zero address");
		// verify n is set properly
		require(n > 1, "n is too small");
		// verify the token ID is "tiny" (32 bits long at most)
		require(uint32(_tokenId) == _tokenId, "token ID overflow");
		require(uint32(_tokenId + n - 1) == _tokenId + n - 1, "n-th token ID overflow");

		// verification: for each token to be minted
		for(uint256 i = 0; i < n; i++) {
			// verify token doesn't yet exist
			require(!exists(_tokenId + i), "already minted");
		}

		// create token ownership records,
		// add tokens to `allTokens` and new owner's collections
		// add tokens to both local and global collections (enumerations)
		__addTokens(_to, _tokenId, n);

		// events: for each token minted
		for(uint256 i = 0; i < n; i++) {
			// fire ERC721 transfer event
			emit Transfer(address(0), _to, _tokenId + i);
		}
	}

	/**
	 * @dev Destroys the token with token ID specified
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_DESTROYER` permission
	 *      or FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features to be enabled
	 *
	 * @dev Can be disabled by the contract creator forever by disabling
	 *      FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features and then revoking
	 *      its own roles to burn tokens and to enable burning features
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) public override {
		// read token owner data
		// verifies token exists under the hood
		address _from = ownerOf(_tokenId);

		// check if caller has sufficient permissions to burn tokens
		// and if not - check for possibility to burn own tokens or to burn on behalf
		if(!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
			// if `_from` is equal to sender, require own burns feature to be enabled
			// otherwise require burns on behalf feature to be enabled
			require(_from == msg.sender && isFeatureEnabled(FEATURE_OWN_BURNS)
			     || _from != msg.sender && isFeatureEnabled(FEATURE_BURNS_ON_BEHALF),
			        _from == msg.sender? "burns are disabled": "burns on behalf are disabled");

			// verify sender is either token owner, or approved by the token owner to burn tokens
			require(_from == msg.sender || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender), "access denied");
		}

		// remove token ownership record (also clears approval),
		// remove token from both local and global collections
		__removeToken(_tokenId);

		// delete token URI mapping
		delete _tokenURIs[_tokenId];

		// fire ERC721 transfer event
		emit Transfer(_from, address(0), _tokenId);
	}

	// ===== End: mint/burn support =====

	// ----- Start: auxiliary internal/private functions -----

	/**
	 * @dev Adds token to the new owner's collection (local),
	 *      used internally to transfer existing tokens, to mint new
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to add
	 * @param _to new owner address to add token to
	 */
	function __addLocal(uint256 _tokenId, address _to) internal virtual {
		// get a reference to the collection where token goes to
		uint32[] storage destination = collections[_to];

		// update local index and ownership, do not change global index
		tokens[_tokenId] = tokens[_tokenId]
			//  |unused |global | local | ownership information (address)      |
			& 0x00000000FFFFFFFF000000000000000000000000000000000000000000000000
			| uint192(destination.length) << 160 | uint160(_to);

		// push token into the local collection
		destination.push(uint32(_tokenId));
	}

	/**
	 * @dev Add token to both local and global collections (enumerations),
	 *      used internally to mint new tokens
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to add
	 * @param _to new owner address to add token to
	 */
	function __addToken(uint256 _tokenId, address _to) internal virtual {
		// get a reference to the collection where token goes to
		uint32[] storage destination = collections[_to];

		// update token global and local indexes, ownership
		tokens[_tokenId] = uint224(allTokens.length) << 192 | uint192(destination.length) << 160 | uint160(_to);

		// push token into the collection
		destination.push(uint32(_tokenId));

		// push it into the global `allTokens` collection (enumeration)
		allTokens.push(uint32(_tokenId));
	}

	/**
	 * @dev Add tokens to both local and global collections (enumerations),
	 *      used internally to mint new tokens in batches
	 *
	 * @dev Token IDs to be added: [_tokenId, _tokenId + n)
	 *      n is expected to be bigger or equal 2, but this is not checked
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _to new owner address to add token to
	 * @param _tokenId first token ID to add
	 * @param n how many tokens to add, sequentially increasing the _tokenId
	 */
	function __addTokens(address _to, uint256 _tokenId, uint256 n) internal virtual {
		// get a reference to the collection where tokens go to
		uint32[] storage destination = collections[_to];

		// for each token to be added
		for(uint256 i = 0; i < n; i++) {
			// update token global and local indexes, ownership
			tokens[_tokenId + i] = uint224(allTokens.length + i) << 192 | uint192(destination.length + i) << 160 | uint160(_to);
		}

		// push tokens into the local collection
		destination.push32(uint32(_tokenId), uint32(n));
		// push tokens into the global `allTokens` collection (enumeration)
		allTokens.push32(uint32(_tokenId), uint32(n));
	}

	/**
	 * @dev Removes token from owner's local collection,
	 *      used internally to transfer or burn existing tokens
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to remove
	 */
	function __removeLocal(uint256 _tokenId) internal virtual {
		// read token data, containing global and local indexes, owner address
		uint256 token = tokens[_tokenId];

		// get a reference to the token's owner collection (local)
		uint32[] storage source = collections[address(uint160(token))];

		// token index within the collection
		uint32 i = uint32(token >> 160);

		// get an ID of the last token in the collection
		uint32 sourceId = source[source.length - 1];

		// if the token we're to remove from the collection is not the last one,
		// we need to move last token in the collection into index `i`
		if(i != source.length - 1) {
			// we put the last token in the collection to the position released

			// update last token local index to point to proper place in the collection
			// preserve global index and ownership info
			tokens[sourceId] = tokens[sourceId]
				//  |unused |global | local | ownership information (address)      |
				& 0x00000000FFFFFFFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
				| uint192(i) << 160;

			// put it into the position `i` within the collection
			source[i] = sourceId;
		}

		// trim the collection by removing last element
		source.pop();

		// clear token approval (also emits an Approval event)
		__clearApproval(address(uint160(token)), _tokenId);
	}

	/**
	 * @dev Removes token from both local and global collections (enumerations),
	 *      used internally to burn existing tokens
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to remove
	 */
	function __removeToken(uint256 _tokenId) internal virtual {
		// remove token from owner's (local) collection first
		__removeLocal(_tokenId);

		// token index within the global collection
		uint32 i = uint32(tokens[_tokenId] >> 192);

		// delete the token
		delete tokens[_tokenId];

		// get an ID of the last token in the collection
		uint32 lastId = allTokens[allTokens.length - 1];

		// if the token we're to remove from the collection is not the last one,
		// we need to move last token in the collection into index `i`
		if(i != allTokens.length - 1) {
			// we put the last token in the collection to the position released

			// update last token global index to point to proper place in the collection
			// preserve local index and ownership info
			tokens[lastId] = tokens[lastId]
				//  |unused |global | local | ownership information (address)      |
				& 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
				| uint224(i) << 192;

			// put it into the position `i` within the collection
			allTokens[i] = lastId;
		}

		// trim the collection by removing last element
		allTokens.pop();
	}

	// ----- End: auxiliary internal/private functions -----
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC165Spec.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev Solidity issue #3412: The ERC721 interfaces include explicit mutability guarantees for each function.
 *      Mutability guarantees are, in order weak to strong: payable, implicit nonpayable, view, and pure.
 *      Implementation MUST meet the mutability guarantee in this interface and MAY meet a stronger guarantee.
 *      For example, a payable function in this interface may be implemented as nonpayable
 *      (no state mutability specified) in implementing contract.
 *      It is expected a later Solidity release will allow stricter contract to inherit from this interface,
 *      but current workaround is that we edit this interface to add stricter mutability before inheriting:
 *      we have removed all "payable" modifiers.
 *
 * @dev The ERC-165 identifier for this interface is 0x80ac58cd.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721 is ERC165 {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 _tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external /*payable*/;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function transferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) external /*payable*/;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 _tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `transfer`. This function MAY throw to revert and reject the
	///  transfer. Return of other than the magic value MUST result in the
	///  transaction being reverted.
	///  Note: the contract address is always the message sender.
	/// @param _operator The address which called `safeTransferFrom` function
	/// @param _from The address which previously owned the token
	/// @param _tokenId The NFT identifier which is being transferred
	/// @param _data Additional data with no specified format
	/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	///  unless throwing
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x5b5e139f.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Metadata is ERC721 {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory _name);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory _symbol);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x780e9d63.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Enumerable is ERC721 {
	/// @notice Count NFTs tracked by this contract
	/// @return A count of valid NFTs tracked by this contract, where each one of
	///  them has an assigned and queryable owner not equal to the zero address
	function totalSupply() external view returns (uint256);

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index) external view returns (uint256);

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Alethea Mintable ERC721
 *
 * @notice Defines mint capabilities for Alethea ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 *
 * @author Basil Gorin
 */
interface MintableERC721 {
	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) external;
}

/**
 * @title Alethea Burnable ERC721
 *
 * @notice Defines burn capabilities for Alethea ERC721 tokens.
 *      This interface should be treated as a definition of what burnable means for ERC721
 *
 * @author Basil Gorin
 */
interface BurnableERC721 {
	/**
	 * @notice Destroys the token with token ID specified
	 *
	 * @dev Should be accessible publicly by token owners.
	 *      May have a restricted access handled by the implementation
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Address Utils
 *
 * @dev Utility library of inline functions on addresses
 *
 * @author Basil Gorin
 */
library AddressUtils {

	/**
	 * @notice Checks if the target address is a contract
	 *
	 * @dev It is unsafe to assume that an address for which this function returns
	 *      false is an externally-owned account (EOA) and not a contract.
	 *
	 * @dev Among others, `isContract` will return false for the following
	 *      types of addresses:
	 *        - an externally-owned account
	 *        - a contract in construction
	 *        - an address where a contract will be created
	 *        - an address where a contract lived, but was destroyed
	 *
	 * @param addr address to check
	 * @return whether the target address is a contract
	 */
	function isContract(address addr) internal view returns (bool) {
		// a variable to load `extcodesize` to
		uint256 size = 0;

		// XXX Currently there is no better way to check if there is a contract in an address
		// than to check the size of the code at that address.
		// See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
		// TODO: Check this again before the Serenity release, because all addresses will be contracts.
		// solium-disable-next-line security/no-inline-assembly
		assembly {
			// retrieve the size of the code at address `addr`
			size := extcodesize(addr)
		}

		// positive size indicates a smart contract address
		return size > 0;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Array Utils
 *
 * @notice Solidity doesn't always work with arrays in an optimal way.
 *      This library collects functions helping to optimize gas usage
 *      when working with arrays in Solidity.
 *
 * @dev One of the most important use cases for arrays is "tight" arrays -
 *      arrays which store values significantly less than 256-bits numbers
 *
 * @author Basil Gorin
 */
library ArrayUtils {
	/**
	 * @dev Pushes `n` 32-bits values sequentially into storage allocated array `data`
	 *      starting from the 32-bits value `v0`
	 *
	 * @dev Optimizations comparing to non-assembly implementation:
	 *      - reads+writes to array size slot only once (instead of `n` times)
	 *      - reads from the array data slots only once (instead of `7n/8` times)
	 *      - writes into array data slots `n/8` times (instead of `n` times)
	 *
	 * @dev Maximum gas saving estimate: ~3n sstore, or 15,000 * n
	 *
	 * @param data storage array pointer to an array of 32-bits elements
	 * @param v0 first number to push into the array
	 * @param n number of values to push, pushes [v0, ..., v0 + n - 1]
	 */
	function push32(uint32[] storage data, uint32 v0, uint32 n) internal {
		// we're going to write 32-bits values into 256-bits storage slots of the array
		// each 256-slot can store up to 8 32-bits sub-blocks, it can also be partially empty
		assembly {
			// for dynamic arrays their slot (array.slot) contains the array length
			// array data is stored separately in consequent storage slots starting
			// from the slot with the address keccak256(array.slot)

			// read the array length into `len` and increase it by `n`
			let len := sload(data.slot)
			sstore(data.slot, add(len, n))

			// find where to write elements and store this location into `loc`
			// load array storage slot number into memory onto position 0,
			// calculate the keccak256 of the slot number (first 32 bytes at position 0)
			// - this will point to the beginning of the array,
			// so we add array length divided by 8 to point to the last array slot
			mstore(0, data.slot)
			let loc := add(keccak256(0, 32), div(len, 8))

			// if we start writing data into already partially occupied slot (`len % 8 != 0`)
			let offset := mod(len, 8)
			if not(iszero(offset)) {
				// how many 32-bits sub-blocks left in the slot
				let left := sub(8, offset)
				// update the `left` value not to exceed `n`
				if gt(left, n) { left := n }
				// load the contents of the first slot (partially occupied)
				let v256 := sload(loc)
				// write the slot in 32-bits sub-blocks
				for { let j := 0 } lt(j, left) { j := add(j, 1) } {
					// write sub-block `j` at offset: `(j + offset) * 32` bits, length: 32-bits
					// v256 |= (v0 + j) << (j + offset) * 32
					v256 := or(v256, shl(mul(add(j, offset), 32), add(v0, j)))
				}
				// write first slot back, it can be still partially occupied, it can also be full
				sstore(loc, v256)
				// update `loc`: move to the next slot
				loc := add(loc, 1)
				// update `v0`: increment by number of values pushed
				v0 := add(v0, left)
				// update `n`: decrement by number of values pushed
				n := sub(n, left)
			}

			// write the array in 256-bits (8x32) slots
			// `i` iterates [0, n) with the 256-bits step, which is 8 taken `n` is 32-bits long
			for { let i := 0 } lt(i, n) { i := add(i, 8) } {
				// how many 32-bits sub-blocks left in the slot
				let left := 8
				// update the `left` value not to exceed `n`
				if gt(left, n) { left := n }
				// init the 256-bits slot value
				let v256 := 0
				// write the slot in 32-bits sub-blocks
				for { let j := 0 } lt(j, left) { j := add(j, 1) } {
					// write sub-block `j` at offset: `j * 32` bits, length: 32-bits
					// v256 |= (v0 + i + j) << j * 32
					v256 := or(v256, shl(mul(j, 32), add(v0, add(i, j))))
				}
				// write slot `i / 8`
				sstore(add(loc, div(i, 8)), v256)
			}
		}
	}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title String Utils Library
 *
 * @dev Library for working with strings, primarily converting
 *      between strings and integer types
 *
 * @author Basil Gorin
 */
library StringUtils {
	/**
	 * @dev Converts a string to unsigned integer using the specified `base`
	 * @dev Throws on invalid input
	 *      (wrong characters for a given `base`)
	 * @dev Throws if given `base` is not supported
	 * @param a string to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return i a number representing given string
	 */
	function atoi(string memory a, uint8 base) internal pure returns (uint256 i) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// convert string into bytes for convenient iteration
		bytes memory buf = bytes(a);

		// iterate over the string (bytes buffer)
		for(uint256 p = 0; p < buf.length; p++) {
			// extract the digit
			uint8 digit = uint8(buf[p]) - 0x30;

			// if digit is greater then 10 - mind the gap
			// see `itoa` function for more details
			if(digit > 10) {
				// remove the gap
				digit -= 7;
			}

			// check if digit meets the base
			require(digit < base);

			// move to the next digit slot
			i *= base;

			// add digit to the result
			i += digit;
		}

		// return the result
		return i;
	}

	/**
	 * @dev Converts a integer to a string using the specified `base`
	 * @dev Throws if given `base` is not supported
	 * @param i integer to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return a a string representing given integer
	 */
	function itoa(uint256 i, uint8 base) internal pure returns (string memory a) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// for zero input the result is "0" string for any base
		if (i == 0) {
			return "0";
		}

		// bytes buffer to put ASCII characters into
		bytes memory buf = new bytes(256);

		// position within a buffer to be used in cycle
		uint256 p = 0;

		// extract digits one by one in a cycle
		while (i > 0) {
			// extract current digit
			uint8 digit = uint8(i % base);

			// convert it to an ASCII code
			// 0x20 is " "
			// 0x30-0x39 is "0"-"9"
			// 0x41-0x5A is "A"-"Z"
			// 0x61-0x7A is "a"-"z" ("A"-"Z" XOR " ")
			uint8 ascii = digit + 0x30;

			// if digit is greater then 10,
			// fix the 0x3A-0x40 gap of punctuation marks
			// (7 characters in ASCII table)
			if(digit >= 10) {
				// jump through the gap
				ascii += 7;
			}

			// write character into the buffer
			buf[p++] = bytes1(ascii);

			// move to the next digit
			i /= base;
		}

		// `p` contains real length of the buffer now,
		// allocate the resulting buffer of that size
		bytes memory result = new bytes(p);

		// copy the buffer in the reversed order
		for(p = 0; p < result.length; p++) {
			// copy from the beginning of the original buffer
			// to the end of resulting smaller buffer
			result[result.length - p - 1] = buf[p];
		}

		// construct string and return
		return string(result);
	}

	/**
	 * @dev Concatenates two strings `s1` and `s2`, for example, if
	 *      `s1` == `foo` and `s2` == `bar`, the result `s` == `foobar`
	 * @param s1 first string
	 * @param s2 second string
	 * @return s concatenation result s1 + s2
	 */
	function concat(string memory s1, string memory s2) internal pure returns (string memory s) {
		// an old way of string concatenation (Solidity 0.4) is commented out
/*
		// convert s1 into buffer 1
		bytes memory buf1 = bytes(s1);
		// convert s2 into buffer 2
		bytes memory buf2 = bytes(s2);
		// create a buffer for concatenation result
		bytes memory buf = new bytes(buf1.length + buf2.length);

		// copy buffer 1 into buffer
		for(uint256 i = 0; i < buf1.length; i++) {
			buf[i] = buf1[i];
		}

		// copy buffer 2 into buffer
		for(uint256 j = buf1.length; j < buf2.length; j++) {
			buf[j] = buf2[j - buf1.length];
		}

		// construct string and return
		return string(buf);
*/

		// simply use built in function
		return string(abi.encodePacked(s1, s2));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 *
 * @dev Copy of the Zeppelin's library:
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/b0cf6fbb7a70f31527f36579ad644e1cf12fdf4e/contracts/utils/cryptography/ECDSA.sol
 */
library ECDSA {
	/**
	 * @dev Returns the address that signed a hashed message (`hash`) with
	 * `signature`. This address can then be used for verification purposes.
	 *
	 * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
	 * this function rejects them by requiring the `s` value to be in the lower
	 * half order, and the `v` value to be either 27 or 28.
	 *
	 * IMPORTANT: `hash` _must_ be the result of a hash operation for the
	 * verification to be secure: it is possible to craft signatures that
	 * recover to arbitrary addresses for non-hashed data. A safe way to ensure
	 * this is by receiving a hash of the original message (which may otherwise
	 * be too long), and then calling {toEthSignedMessageHash} on it.
	 *
	 * Documentation for signature generation:
	 * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
	 * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
	 */
	function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
		// Divide the signature in r, s and v variables
		bytes32 r;
		bytes32 s;
		uint8 v;

		// Check the signature length
		// - case 65: r,s,v signature (standard)
		// - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
		if (signature.length == 65) {
			// ecrecover takes the signature parameters, and the only way to get them
			// currently is to use assembly.
			assembly {
				r := mload(add(signature, 0x20))
				s := mload(add(signature, 0x40))
				v := byte(0, mload(add(signature, 0x60)))
			}
		} else if (signature.length == 64) {
			// ecrecover takes the signature parameters, and the only way to get them
			// currently is to use assembly.
			assembly {
				let vs := mload(add(signature, 0x40))
				r := mload(add(signature, 0x20))
				s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
				v := add(shr(255, vs), 27)
			}
		} else {
			revert("invalid signature length");
		}

		return recover(hash, v, r, s);
	}

	/**
	 * @dev Overload of {ECDSA-recover} that receives the `v`,
	 * `r` and `s` signature fields separately.
	 */
	function recover(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal pure returns (address) {
		// EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
		// unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
		// the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
		// signatures from current libraries generate a unique signature with an s-value in the lower half order.
		//
		// If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
		// with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
		// vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
		// these malleable signatures as well.
		require(
			uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
			"invalid signature 's' value"
		);
		require(v == 27 || v == 28, "invalid signature 'v' value");

		// If the signature is valid (and not malleable), return the signer address
		address signer = ecrecover(hash, v, r, s);
		require(signer != address(0), "invalid signature");

		return signer;
	}

	/**
	 * @dev Returns an Ethereum Signed Message, created from a `hash`. This
	 * produces hash corresponding to the one signed with the
	 * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
	 * JSON-RPC method as part of EIP-191.
	 *
	 * See {recover}.
	 */
	function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
		// 32 is the length in bytes of hash,
		// enforced by the type signature above
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
	}

	/**
	 * @dev Returns an Ethereum Signed Typed Data, created from a
	 * `domainSeparator` and a `structHash`. This produces hash corresponding
	 * to the one signed with the
	 * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
	 * JSON-RPC method as part of EIP-712.
	 *
	 * See {recover}.
	 */
	function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title EIP-20: ERC-20 Token Standard
 *
 * @notice The ERC-20 (Ethereum Request for Comments 20), proposed by Fabian Vogelsteller in November 2015,
 *      is a Token Standard that implements an API for tokens within Smart Contracts.
 *
 * @notice It provides functionalities like to transfer tokens from one account to another,
 *      to get the current token balance of an account and also the total supply of the token available on the network.
 *      Besides these it also has some other functionalities like to approve that an amount of
 *      token from an account can be spent by a third party account.
 *
 * @notice If a Smart Contract implements the following methods and events it can be called an ERC-20 Token
 *      Contract and, once deployed, it will be responsible to keep track of the created tokens on Ethereum.
 *
 * @notice See https://ethereum.org/en/developers/docs/standards/tokens/erc-20/
 * @notice See https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
	/**
	 * @dev Fired in transfer(), transferFrom() to indicate that token transfer happened
	 *
	 * @param from an address tokens were consumed from
	 * @param to an address tokens were sent to
	 * @param value number of tokens transferred
	 */
	event Transfer(address indexed from, address indexed to, uint256 value);

	/**
	 * @dev Fired in approve() to indicate an approval event happened
	 *
	 * @param owner an address which granted a permission to transfer
	 *      tokens on its behalf
	 * @param spender an address which received a permission to transfer
	 *      tokens on behalf of the owner `_owner`
	 * @param value amount of tokens granted to transfer on behalf
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/**
	 * @return name of the token (ex.: USD Coin)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function name() external view returns (string memory);

	/**
	 * @return symbol of the token (ex.: USDC)
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function symbol() external view returns (string memory);

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 *      For example, if `decimals` equals `2`, a balance of `505` tokens should
	 *      be displayed to a user as `5,05` (`505 / 10 ** 2`).
	 *
	 * @dev Tokens usually opt for a value of 18, imitating the relationship between
	 *      Ether and Wei. This is the value {ERC20} uses, unless this function is
	 *      overridden;
	 *
	 * @dev NOTE: This information is only used for _display_ purposes: it in
	 *      no way affects any of the arithmetic of the contract, including
	 *      {IERC20-balanceOf} and {IERC20-transfer}.
	 *
	 * @return token decimals
	 */
	// OPTIONAL - This method can be used to improve usability,
	// but interfaces and other contracts MUST NOT expect these values to be present.
	// function decimals() external view returns (uint8);

	/**
	 * @return the amount of tokens in existence
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @notice Gets the balance of a particular address
	 *
	 * @param _owner the address to query the the balance for
	 * @return balance an amount of tokens owned by the address specified
	 */
	function balanceOf(address _owner) external view returns (uint256 balance);

	/**
	 * @notice Transfers some tokens to an external address or a smart contract
	 *
	 * @dev Called by token owner (an address which has a
	 *      positive token balance tracked by this smart contract)
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * self address or
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transfer(address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Transfers some tokens on behalf of address `_from' (token owner)
	 *      to some other address `_to`
	 *
	 * @dev Called by token owner on his own or approved address,
	 *      an address approved earlier by token owner to
	 *      transfer some amount of tokens on its behalf
	 * @dev Throws on any error like
	 *      * insufficient token balance or
	 *      * incorrect `_to` address:
	 *          * zero address or
	 *          * same as `_from` address (self transfer)
	 *          * smart contract which doesn't support ERC20
	 *
	 * @param _from token owner which approved caller (transaction sender)
	 *      to transfer `_value` of tokens on its behalf
	 * @param _to an address to transfer tokens to,
	 *      must be either an external address or a smart contract,
	 *      compliant with the ERC20 standard
	 * @param _value amount of tokens to be transferred,, zero
	 *      value is allowed
	 * @return success true on success, throws otherwise
	 */
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

	/**
	 * @notice Approves address called `_spender` to transfer some amount
	 *      of tokens on behalf of the owner (transaction sender)
	 *
	 * @dev Transaction sender must not necessarily own any tokens to grant the permission
	 *
	 * @param _spender an address approved by the caller (token owner)
	 *      to spend some tokens on its behalf
	 * @param _value an amount of tokens spender `_spender` is allowed to
	 *      transfer on behalf of the token owner
	 * @return success true on success, throws otherwise
	 */
	function approve(address _spender, uint256 _value) external returns (bool success);

	/**
	 * @notice Returns the amount which _spender is still allowed to withdraw from _owner.
	 *
	 * @dev A function to check an amount of tokens owner approved
	 *      to transfer on its behalf by some other address called "spender"
	 *
	 * @param _owner an address which approves transferring some tokens on its behalf
	 * @param _spender an address approved to transfer some tokens on behalf
	 * @return remaining an amount of tokens approved address `_spender` can transfer on behalf
	 *      of token owner `_owner`
	 */
	function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

