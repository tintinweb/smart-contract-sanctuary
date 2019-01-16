pragma solidity ^0.5;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/// @title Definition for a resource token used by upcity.
/// @author Lawrence Forman (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ee838bae838b9c85828b848b9c85c08d8183">[email&#160;protected]</a>)
interface IResourceToken {

	function transfer(address to, uint256 amt) external returns (bool);
	function mint(address to, uint256 amt) external;
	function burn(address from, uint256 amt) external;
	function totalSupply() external view returns (uint256);
	function balanceOf(address who) external view returns (uint256);
	function isAuthority(address addr) external view returns (bool);
	function decimals() external view returns (uint8);
}

/// @title Definition for a resource token used by upcity.
/// @author Lawrence Forman (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4c21290c21293e27202926293e27622f2321">[email&#160;protected]</a>)
interface IMarket {

	function getPrice(address resource) external view returns (uint256);
}

/// @title Base contract defining common error codes.
/// @author Lawrence Forman (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="573a32173a32253c3b323d32253c7934383a">[email&#160;protected]</a>)
contract Errors {

	string internal constant ERROR_MAX_HEIGHT = "MAX_HEIGHT";
	string internal constant ERROR_NOT_ALLOWED = "NOT_ALLOWED";
	string internal constant ERROR_ALREADY = "ALREADY";
	string internal constant ERROR_INSUFFICIENT = "INSUFFICIENT";
	string internal constant ERROR_RESTRICTED = "RESTRICTED";
	string internal constant ERROR_UNINITIALIZED = "UNINITIALIZED";
	string internal constant ERROR_TIME_TRAVEL = "TIME_TRAVEL";
	string internal constant ERROR_INVALID = "INVALID";
	string internal constant ERROR_NOT_FOUND = "NOT_FOUND";
	string internal constant ERROR_GAS = "GAS";
	string internal constant ERROR_TRANSFER_FAILED = "TRANSFER_FAILED";
}

/// @title Base for contracts that require a separate
/// initialization step beyond the constructor.
/// @author Lawrence Forman (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="264b43664b43544d4a434c43544d0845494b">[email&#160;protected]</a>)
/// @dev Deriving contracts should call super._init() in their initialization step
/// to initialize the contract.
contract Uninitialized is Errors {

	/// @dev Whether the contract is fully initialized.
	bool private _isInitialized;

	/// @dev Only callable when contract is initialized.
	modifier onlyInitialized() {
		require(_isInitialized, ERROR_UNINITIALIZED);
		_;
	}

	/// @dev Only callable when contract is uninitialized.
	modifier onlyUninitialized() {
		require(!_isInitialized, ERROR_UNINITIALIZED);
		_;
	}

	/// @dev initialize the contract.
	function _init() internal onlyUninitialized {
		_isInitialized = true;
	}

}

/// @title Base class for contracts that want to restrict access to privileged
/// functions to either the contract creator or a group of addresses.
/// @author Lawrence Forman (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="acc1c9ecc1c9dec7c0c9c6c9dec782cfc3c1">[email&#160;protected]</a>)
/// @dev Derived contracts should set isAuthority to true for each address
/// with privileged access to functions protected by the onlyAuthority modifier.
contract Restricted is Errors {

	/// @dev Creator of this contract.
	address internal _creator;
	/// @dev Addresses that can call onlyAuthority functions.
	mapping(address=>bool) public isAuthority;

	/// @dev Set the contract creator to the sender.
	constructor() public {
		_creator = msg.sender;
	}

	/// @dev Only callable by contract creator.
	modifier onlyCreator() {
		require(msg.sender == _creator, ERROR_RESTRICTED);
		_;
	}

	/// @dev Restrict calls to only from an authority
	modifier onlyAuthority() {
		require(isAuthority[msg.sender], ERROR_RESTRICTED);
		_;
	}
}

/// @title Base for contracts that don&#39;t want to hold ether.
/// @author Lawrence Forman (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="375a52775a52455c5b525d52455c1954585a">[email&#160;protected]</a>)
/// @dev Reverts in the fallback function.
contract Nonpayable is Errors {

	/// @dev Revert in the fallback function to prevent accidental
	/// transfer of funds to this contract.
	function() external payable {
		revert(ERROR_INVALID);
	}
}

/// @title Constants, types, and helpers for UpCityGame
/// @author Lawrence Forman (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="97faf2d7faf2e5fcfbf2fdf2e5fcb9f4f8fa">[email&#160;protected]</a>)
contract UpcityBase {

	// Tile data.
	struct Tile {
		// Deterministic ID of the tile. Will be 0x0 if tile does not exist.
		bytes16 id;
		// Right-aligned, packed representation of blocks,
		// where 0x..FF is empty.
		bytes16 blocks;
		// How many times the tile has been bought. Always >= 1.
		uint32 timesBought;
		// When the tile was last collected.
		uint64 lastTouchTime;
		// The x coordinate of the tile.
		int32 x;
		// The y coordinate of the tile.
		int32 y;
		// The height of the tower on the tile (length of blocks).
		uint8 height;
		// NUM_NEIGHBORS + the height of each neighbor&#39;s tower.
		uint8 neighborCloutsTotal;
		// The name of the tile.
		bytes12 name;
		// The current owner of the tile.
		address owner;
		// The "base" price of a tile, NOT including neighborhood bonus,
		// resource costs, and seasonal bonus. This goes up every time a
		// tile is bought.
		uint256 basePrice;
		// The aggregated shared resources from neighbor tiles after
		// they do a collect().
		uint256[NUM_RESOURCES] sharedResources;
		// The aggregated shared ether from neighbor tiles. after they
		// do a collect().
		uint256 sharedFunds;
	}

	// Global metrics, for a specific resource;
	struct BlockStats {
		// The total number of blocks of this resource, across all tiles.
		uint64 count;
		// The global production daily limit for this resource, expressed in PPM.
		// Note that this is a "soft" limit, as tiles in season produce bonus
		// resources defined by SEASON_YIELD_BONUS.
		uint64 production;
		// The total "score" of blocks of this resource, across all tiles.
		// Score for a block depends on its height.
		uint128 score;
	}

	// solhint-disable
	// Zero address (0x0).
	address internal constant ZERO_ADDRESS = address(0x0);
	// Number of decimals for all resource tokens and ether (18).
	uint8 internal constant DECIMALS = 18;
	// 100%, or 1.0, in parts per million.
	uint64 internal constant PPM_ONE = uint64(1000000);
	// The number of wei in one token (10**18).
	uint256 internal constant ONE_TOKEN = 1000000000000000000;
	// The number of seconds in one day.
	uint256 internal constant ONE_DAY = 86400;
	// The number of resource types.
	uint8 internal constant NUM_RESOURCES = 3;
	// The number of neighbors for each tile.
	uint8 internal constant NUM_NEIGHBORS = 6;
	// The maximum number of blocks that can be built on a tile.
	uint8 internal constant MAX_HEIGHT = 16;
	// Packed representation of an empty tower.
	bytes16 internal constant EMPTY_BLOCKS = 0xffffffffffffffffffffffffffffffff;
	// The ratio of collected resources to share with neighbors, in ppm.
	uint64 internal constant TAX_RATE = 166667;
	// The minimum tile price.
	uint256 internal constant MINIMUM_TILE_PRICE = 25000000000000000;
	// How much to increase the base tile price every time it&#39;s bought, in ppm.
	uint64 internal constant PURCHASE_MARKUP = 1250000;
	// Scaling factor for global production limits.
	uint64 internal constant PRODUCTION_ALPHA = 1500000;
	// The number of seasons.
	uint64 internal constant NUM_SEASONS = 8;
	// The length of each season, in seconds.
	uint64 internal constant SEASON_DURATION = 1314900;
	// The start of the season calendar, in unix time.
	uint64 internal constant CALENDAR_START = 1546318800;
	// Multiplier for the total price of a tile when it is in season, in ppm.
	uint64 internal constant SEASON_PRICE_BONUS = 1500000;
	// Multiplier for to resources generated when a tile is in season, in ppm.
	uint64 internal constant SEASON_YIELD_BONUS = 1250000;
	// The building cost multiplier for any block at a certain height, in ppm.
	uint64[MAX_HEIGHT] internal BLOCK_HEIGHT_PREMIUM = [
		uint64(1000000),
		uint64(1096825),
		uint64(1203025),
		uint64(1319508),
		uint64(1447269),
		uint64(1587401),
		uint64(1741101),
		uint64(1909683),
		uint64(2094588),
		uint64(2297397),
		uint64(2519842),
		uint64(2763826),
		uint64(3031433),
		uint64(3324952),
		uint64(3646890),
		uint64(4000000)
	];
	// The yield multiplier for any block at a certain height, in ppm.
	uint64[MAX_HEIGHT] internal BLOCK_HEIGHT_BONUS = [
		uint64(1000000),
		uint64(1047294),
		uint64(1096825),
		uint64(1148698),
		uint64(1203025),
		uint64(1259921),
		uint64(1319508),
		uint64(1381913),
		uint64(1447269),
		uint64(1515717),
		uint64(1587401),
		uint64(1662476),
		uint64(1741101),
		uint64(1823445),
		uint64(1909683),
		uint64(2000000)
	];
	// The linear rate at which each block&#39;s costs increase with the total
	// blocks built, in ppm.
	uint64[NUM_RESOURCES] internal RESOURCE_ALPHAS =
		[50000, 250000, 660000];
	// Recipes for each block type, as whole tokens.
	uint256[NUM_RESOURCES][NUM_RESOURCES] internal RECIPES = [
		[3, 1, 1],
		[1, 3, 1],
		[1, 1, 3]
	];
	// solhint-enable

	/// @dev Given an amount, subtract taxes from it.
	function _toTaxed(uint256 amount) internal pure returns (uint256) {
		return amount - (amount * TAX_RATE) / PPM_ONE;
	}

	/// @dev Given an amount, get the taxed quantity.
	function _toTaxes(uint256 amount) internal pure returns (uint256) {
		return (amount * TAX_RATE) / PPM_ONE;
	}

	/// @dev Given a tile coordinate, return the tile id.
	function _toTileId(int32 x, int32 y) internal view returns (bytes16) {
		return bytes16(keccak256(abi.encodePacked(x, y, address(this))));
	}

	/// @dev Check if a block ID number is valid.
	function _isValidBlock(uint8 _block) internal pure returns (bool) {
		return _block <= 2;
	}

	/// @dev Check if a tower height is valid.
	function _isValidHeight(uint8 height) internal pure returns (bool) {
		return height <= MAX_HEIGHT;
	}

	/// @dev Insert packed representation of a tower `b` into `a`.
	/// @param a Packed represenation of the current tower.
	/// @param b Packed represenation of blocks to append.
	/// @param idx The index in `a` to insert the new blocks.
	/// @param count The length of `b`.
	function _assignBlocks(bytes16 a, bytes16 b, uint8 idx, uint8 count)
			internal pure returns (bytes16) {

		uint128 mask = ((uint128(1) << (count*8)) - 1) << (idx*8);
		uint128 v = uint128(b) << (idx*8);
		return bytes16((uint128(a) & ~mask) | (v & mask));
	}

	/// @dev Get the current season.
	function _getSeason() private view returns (uint128) {
		return ((uint64(block.timestamp) - CALENDAR_START) / SEASON_DURATION) % NUM_SEASONS;
	}

	/// @dev Check if a tile is in season (has a bonus in effect).
	/// @param tile The tile to check.
	/// @return true if tile is in season.
	function _isTileInSeason(Tile storage tile) internal view returns (bool) {
		return uint128(tile.id) % NUM_SEASONS == _getSeason();
	}

	/// @dev Estimate the sqrt of an integer n, returned in ppm, using small
	/// steps of the Babylonian method.
	/// @param n The integer whose sqrt is to the found, NOT in ppm.
	/// @param hint A number close to the sqrt, in ppm.
	/// @return sqrt(n) in ppm
	function _estIntegerSqrt(uint64 n, uint64 hint)
			internal pure returns (uint64) {

		if (n == 0)
			return 0;
		if (n == 1)
			return PPM_ONE;
		uint256 _n = uint256(n) * PPM_ONE;
		uint256 _n2 = _n * PPM_ONE;
		uint256 r = hint == 0 ? ((uint256(n)+1) * PPM_ONE) / 2 : hint;
		r = (r + _n2 / r) / 2;
		r = (r + _n2 / r) / 2;
		return uint64(r);
	}

}

/// @title Game contract for upcity.app
contract UpcityGame is
		UpcityBase,
		Uninitialized,
		Nonpayable,
		Restricted {
	using SafeMath for uint256;

	/// @dev Payments to individual players when someone buys their tile.
	/// Can be pulled vial collectCredits().
	mapping(address=>uint256) public credits;
	/// @dev Fees collected.
	/// These are funds that have been shared to unowned tiles as well as
	/// funds paid to buy unowned tiles.
	/// An authority may call collectFees() to withdraw these fees.
	uint256 public fees = 0;
	// Global block stats for each resource.
	BlockStats[NUM_RESOURCES] private _blockStats;
	// Tokens for each resource.
	IResourceToken[NUM_RESOURCES] private _tokens;
	// The market for all resources.
	IMarket private _market;
	// Tiles by ID.
	mapping(bytes16=>Tile) private _tiles;

	/// @dev Raised whenever a tile is bought.
	event Bought(bytes16 indexed id, address indexed from, address indexed to, uint256 price);
	/// @dev Raised whenever a tile&#39;s resources/funds are collected.
	event Collected(bytes16 indexed id, address indexed owner);
	/// @dev Raised whenever credited funds (ether) are collected.
	event CreditsCollected(address indexed from, address indexed to, uint256 amount);
	/// @dev Raised whenever a block is built on a tile.
	event Built(bytes16 indexed id, address indexed owner, bytes16 blocks);
	/// @dev Raised whenever a player is credited some funds to be collected via
	/// collectCredits().
	event Credited(address indexed to, uint256 amount);
	/// @dev Raised whenever amn authority claims fees through collectFees().
	event FeesCollected(address indexed to, uint256 amount);

	/// @dev Doesn&#39;t really do anything.
	/// init() needs to be called by the creator before this contract
	/// can be interacted with. All transactional functions will revert if
	/// init() has not been called first.
	constructor() public { /* NOOP */ }

	/// @dev Initialize this contract.
	/// All transactional functions will revert if this has not been called
	/// first by the the contract creator. This cannot be called twice.
	/// @param tokens Each resource&#39;s UpcityResourceToken addresses.
	/// @param market The UpcityMarket address.
	/// @param authorities Array of addresses allowed to call collectFees().
	/// @param genesisPlayer The owner of the genesis tile, at <0,0>.
	function init(
			address[NUM_RESOURCES] calldata tokens,
			address market,
			address genesisPlayer,
			address[] calldata authorities)
			external onlyCreator onlyUninitialized {

		require(tokens.length == NUM_RESOURCES, ERROR_INVALID);
		for (uint256 i = 0; i < authorities.length; i++)
			isAuthority[authorities[i]] = true;
		for (uint256 i = 0; i < NUM_RESOURCES; i++)
			_tokens[i] = IResourceToken(tokens[i]);
		_market = IMarket(market);

		// Create the genesis tile and its neighbors.
		Tile storage tile = _createTileAt(0, 0);
		tile.owner = genesisPlayer;
		tile.timesBought = 1;
		_createNeighbors(tile.x, tile.y);
		_init();
	}

	/// @dev Get global stats for every resource type.
	/// @return A tuple of:
	/// array of the total number of blocks for each resource,
	/// array of the total scores for each resource, in ppm.
	/// array of the daily production limit for each resource, in tokens, in ppm.
	function getBlockStats()
			external view returns (
				uint64[NUM_RESOURCES] memory counts,
				uint64[NUM_RESOURCES] memory productions,
				uint128[NUM_RESOURCES] memory scores) {

		counts[0] = _blockStats[0].count;
		scores[0] = _blockStats[0].score;
		productions[0] = _blockStats[0].production;
		counts[1] = _blockStats[1].count;
		scores[1] = _blockStats[1].score;
		productions[1] = _blockStats[1].production;
		counts[2] = _blockStats[2].count;
		scores[2] = _blockStats[2].score;
		productions[2] = _blockStats[2].production;
	}

	/// @dev Gets the resource and ether balance of a player.
	/// Note that this does not include credits (see &#39;credits&#39; field).
	/// @param player The player&#39;s address.
	/// @return A tuple of:
	/// ether balance,
	/// array of balance for each resource.
	function getPlayerBalance(address player)
			external view returns (
				uint256 funds,
				uint256[NUM_RESOURCES] memory resources) {

		funds = player.balance;
		resources[0] = _tokens[0].balanceOf(player);
		resources[1] = _tokens[1].balanceOf(player);
		resources[2] = _tokens[2].balanceOf(player);
	}

	/// @dev Get detailed information about a tile.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	/// @return A tuple of details.
	function describeTile(int32 x, int32 y) external view
			returns (
				/// @dev The id of the tile. This will be 0x0 if the tile does not
				/// exist.
				bytes16 id,
				/// @dev The name of the tile. Zero-terminated UTF-8 string.
				bytes12 name,
				/// @dev The number of times the tile was bought.
				uint32 timesBought,
				/// @dev The number of times the tile was bought (0 of unowned).
				uint64 lastTouchTime,
				/// @dev The current owner of the tile (0x0 if unowned).
				address owner,
				// Right-aligned, packed representation of blocks,
				// where 0x..FF is empty.
				bytes16 blocks,
				/// @dev The current price of the tile.
				uint256 price,
				/// @dev The number of each resource available to collect()
				/// (including tax).
				uint256[NUM_RESOURCES] memory resources,
				/// @dev The amount ether available to collect()
				/// (including tax).
				uint256 funds,
				/// @dev Whether or not this tile is in season.
				/// Tiles in season yield more resources and have higher prices.
				bool inSeason) {

		Tile storage tile = _getTileAt(x, y);
		id = tile.id;
		timesBought = tile.timesBought;
		name = tile.name;
		owner = tile.owner;
		lastTouchTime = tile.lastTouchTime;
		blocks = tile.blocks;
		if (id != 0x0) {
			price = _getTilePrice(tile);
			resources = _getTileYield(tile);
			inSeason = _isTileInSeason(tile);
			funds = _toTaxed(tile.sharedFunds);
		}
		else {
			assert(owner == address(0x0));
			name = 0x0;
			price = 0;
			resources = [uint256(0), uint256(0), uint256(0)];
			inSeason = false;
			funds = 0;
		}
	}

	/// @dev Buy a tile.
	/// Ether equivalent to the price of the tile must be attached to this call.
	/// Any excess ether (overpayment) will be transfered back to the caller.
	/// The caller will be the new owner.
	/// This will first do a collect(), so the previous owner will be paid
	/// any resources/ether held by the tile. The buyer does not inherit
	/// existing funds/resources. Only the tile and its tower.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	function buy(int32 x, int32 y) external payable onlyInitialized {
		collect(x, y);
		Tile storage tile = _getExistingTileAt(x, y);
		require(tile.owner != msg.sender, ERROR_ALREADY);
		uint256 price = _getTilePrice(tile);
		require(msg.value >= price, ERROR_INSUFFICIENT);
		address oldOwner = tile.owner;
		tile.owner = msg.sender;
		tile.timesBought += 1;
		// Base price increases every time a tile is bought.
		tile.basePrice = (tile.basePrice * PURCHASE_MARKUP) / PPM_ONE;
		// Create the neighboring tiles.
		_createNeighbors(tile.x, tile.y);
		// Share with neighbors.
		_share(tile, price, [uint256(0), uint256(0), uint256(0)]);
		// Pay previous owner.
		_creditTo(oldOwner, _toTaxed(price));
		// Refund any overpayment.
		if (msg.value > price)
			_transferTo(msg.sender, msg.value - price);
		emit Bought(tile.id, oldOwner, tile.owner, price);
	}

	/// @dev Build, by appending, blocks on a tile.
	/// This will first do a collect().
	/// Empty blocks, or building beyond MAX_HEIGHT will revert.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	/// @param blocks Right-aligned, packed representation of blocks to append.
	function buildBlocks(int32 x, int32 y, bytes16 blocks)
			external onlyInitialized {

		collect(x, y);
		Tile storage tile = _getExistingTileAt(x, y);
		// Must be owned by caller.
		require(tile.owner == msg.sender, ERROR_NOT_ALLOWED);
		// Get the costs and count of the new blocks.
		(uint256[NUM_RESOURCES] memory cost, uint8 count) =
			_getBuildCostAndCount(tile, blocks);
		// Empty blocks aren&#39;t allowed.
		require(count > 0, ERROR_INVALID);
		// Building beyond the maximum height is not allowed.
		require(_isValidHeight(tile.height + count), ERROR_MAX_HEIGHT);
		// Burn the costs.
		_burn(msg.sender, cost);
		tile.blocks = _assignBlocks(tile.blocks, blocks, tile.height, count);
		tile.height += count;
		// Increase clout total for each neighbor.
		for (uint8 i = 0; i < NUM_NEIGHBORS; i++) {
			(int32 ox, int32 oy) = (((int32(i)%3)-1), (1-int32(i)/2));
			Tile storage neighbor = _getTileAt(tile.x + ox, tile.y + oy);
			neighbor.neighborCloutsTotal += count;
		}
		_incrementBlockStats(blocks, count);
		emit Built(tile.id, tile.owner, tile.blocks);
	}

	/// @dev Rename a tile.
	/// Only the owner of the tile may call this.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	/// @param name Name to give the tile (UTF-8, zero-terminated).
	function rename(int32 x, int32 y, bytes12 name) external onlyInitialized {
		Tile storage tile = _getExistingTileAt(x, y);
		// Must be owned by caller.
		require(tile.owner == msg.sender, ERROR_NOT_ALLOWED);
		tile.name = name;
	}

	/// @dev Transfer fees (ether) collected to an address.
	/// May only be called by an authority set in init().
	/// @param to Recipient.
	function collectFees(address to) external onlyInitialized onlyAuthority {
		assert(fees <= address(this).balance);
		if (fees > 0) {
			uint256 amount = fees;
			fees = 0;
			_transferTo(to, amount);
			emit FeesCollected(to, amount);
		}
	}

	/// @dev Collect funds (ether) credited to the caller.
	/// Credits come from someone buying an owned tile, or when someone
	/// other than the owner of a tile (holding ether) calls collect().
	/// @param to Recipient.
	function collectCredits(address to) external {
		uint256 amount = credits[msg.sender];
		if (amount > 0) {
			credits[msg.sender] = 0;
			_transferTo(to, amount);
			emit CreditsCollected(msg.sender, to, amount);
		}
	}

	/// @dev Collect the resources from a tile.
	/// The caller need not be the owner of the tile.
	/// Calling this on unowned tiles is a no-op since unowned tiles cannot hold
	/// resources/funds.
	/// If the tile is holding resources, they will be immediately minted to
	/// the owner of the tile, with a portion (1/TAX_RATE) shared to its neighbors.
	/// If the tile has funds (ether), they will be credited to the tile owner
	/// (who can later redeem them via collectCredits()), and a portion
	/// (1/TAX_RATE) will be shared to its neighbors.
	/// If the caller is the owner, funds/ether will be directly transfered to the
	/// owner, rather than merely credited (push rather than pull).
	/// The exact proportion of resources and funds each neighbor receives will
	/// depend on its tower height relative to the tile&#39;s other immediate
	/// neighbors.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	function collect(int32 x, int32 y) public onlyInitialized {
		Tile storage tile = _getExistingTileAt(x, y);
		// If tile is unowned, it cannot yield or hold anything.
		if (tile.owner == ZERO_ADDRESS)
			return;

		uint256[NUM_RESOURCES] memory produced = _getTileYield(tile);
		uint256 funds = tile.sharedFunds;

		tile.lastTouchTime = uint64(block.timestamp);
		tile.sharedResources = [uint256(0), uint256(0), uint256(0)];
		tile.sharedFunds = 0;

		// Share to neighbors.
		_share(tile, funds, produced);
	/// @dev Claims funds and resources from a tile to its owner.
	/// The amount minted/transfered/credited will be minus the tax.
	/// Resources are immediately minted to the tile owner.
	/// Funds (ether) are credited (pull pattern) to the tile owner unless
	/// the caller is also the tile owner, in which case it will be transfered
	/// immediately.
		_claim(tile, funds, produced);
		emit Collected(tile.id, tile.owner);
	}

	/// @dev Convert a tile position to its ID.
	/// The ID is deterministic, and depends on the instance of this contract.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	/// @return A bytes16 unique ID of the tile.
	function toTileId(int32 x, int32 y) public view returns (bytes16) {
		return _toTileId(x, y);
	}

	/// @dev Get the build cost (in resources) to build a sequence of blocks on
	/// a tile.
	/// This will revert if the number of blocks would exceed the height limit
	/// or the tile does not exist.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	/// @param blocks Right-aligned, packed representation of blocks to append.
	function getBuildCost(int32 x, int32 y, bytes16 blocks)
			public view returns (uint256[NUM_RESOURCES] memory cost) {

		Tile storage tile = _getExistingTileAt(x, y);
		(cost,) = _getBuildCostAndCount(tile, blocks);
	}

	/// @dev Get the build cost (in resources) to build a sequence of blocks on
	/// a tile and the count of those blocks.
	/// @param tile The tile info structure.
	/// @param blocks Right-aligned, packed representation of blocks to append.
	/// @return A tuple of:
	/// The cost per-resource,
	/// The count of the blocks passed.
	function _getBuildCostAndCount(Tile storage tile, bytes16 blocks)
			private view returns (uint256[NUM_RESOURCES] memory, uint8) {

		assert(tile.id != 0x0);
		uint256[NUM_RESOURCES] memory cost = [uint256(0), uint256(0), uint256(0)];
		// The global block totals. We will increment this for each block to get
		// the accurate/integrated cost.
		uint64[NUM_RESOURCES] memory blockTotals =
			[_blockStats[0].count, _blockStats[1].count, _blockStats[2].count];
		uint8 count = 0;
		for (; count < MAX_HEIGHT; count++) {
			uint8 b = uint8(uint128(blocks));
			blocks = blocks >> 8;
			if (!_isValidBlock(b))
				break;
			require(_isValidHeight(tile.height + count + 1), ERROR_MAX_HEIGHT);
			uint256[NUM_RESOURCES] memory bc = _getBlockCost(
				b, blockTotals[b], tile.height + count);
			cost[0] = cost[0].add(bc[0]);
			cost[1] = cost[1].add(bc[1]);
			cost[2] = cost[2].add(bc[2]);
			blockTotals[b] += 1;
		}
		return (cost, count);
	}

	/// @dev Get the amount resources held by a tile at the current time.
	/// This will include shared resources from neighboring tiles.
	/// The resources held by a tile is an aggregate of the production rate
	/// of the blocks on it (multiplied by a seasonal bonus if the tile is in
	/// season) plus resources shared from neighboring tiles.
	/// @param tile The tile info structure.
	/// @return The amount of each resource produced.
	function _getTileYield(Tile storage tile)
			private view returns (uint256[NUM_RESOURCES] memory produced) {

		assert(tile.id != 0x0);
		require(uint64(block.timestamp) >= tile.lastTouchTime, ERROR_TIME_TRAVEL);
		uint64 seasonBonus = _isTileInSeason(tile) ? SEASON_YIELD_BONUS : PPM_ONE;
		uint64 dt = uint64(block.timestamp) - tile.lastTouchTime;
		// Geneerate resources on top of what&#39;s been shared to this tile.
		produced = tile.sharedResources;
		bytes16 blocks = tile.blocks;
		for (uint8 height = 0; height < tile.height; height++) {
			// Pop each block off the tower.
			uint8 b = uint8(uint128(blocks));
			blocks = blocks >> 8;
			uint256 amt = ONE_TOKEN * _blockStats[b].production;
			amt *= dt;
			amt *= BLOCK_HEIGHT_BONUS[height];
			amt *= seasonBonus;
			amt /= (_blockStats[b].score) * 86400000000000000000000;
			produced[b] = produced[b].add(amt);
		}
	}

	/// @dev Get the resource costs to build a block at a height.
	/// @param _block The block ID number.
	/// @param globalTotal The total number of the same block type in existence.
	/// @param height The height of the block in the tower.
	/// @return The amount of each resource it would take to build this block.
	function _getBlockCost(uint8 _block, uint64 globalTotal, uint8 height)
			private view returns (uint256[NUM_RESOURCES] memory) {

		assert(_isValidBlock(_block) && _isValidHeight(height));
		uint256 c = ((globalTotal) >= (1) ? (globalTotal) : (1));
		uint256 a = RESOURCE_ALPHAS[_block];
		uint256 s = BLOCK_HEIGHT_PREMIUM[height] * ((c*a) >= (PPM_ONE) ? (c*a) : (PPM_ONE));
		uint256[NUM_RESOURCES] memory cost = [uint256(0), uint256(0), uint256(0)];
		cost[0] = (ONE_TOKEN * RECIPES[_block][0] * s) / 1000000000000;
		cost[1] = (ONE_TOKEN * RECIPES[_block][1] * s) / 1000000000000;
		cost[2] = (ONE_TOKEN * RECIPES[_block][2] * s) / 1000000000000;
		return cost;
	}

	/// @dev Create a tile at a position.
	/// This will initalize the id, price, blocks, and neighbor clouts.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	/// @return The created Tile (storage) instance.
	function _createTileAt(int32 x, int32 y) private returns (Tile storage) {
		bytes16 id = _toTileId(x, y);
		Tile storage tile = _tiles[id];
		if (tile.id == 0x0) {
			tile.id = id;
			tile.x = x;
			tile.y = y;
			tile.blocks = EMPTY_BLOCKS;
			// No need to iterate over neighbors to get accurate clouts since we know
			// tiles are only created when an unowned edge tile is bought, so its
			// only existing neighbor should be empty.
			tile.neighborCloutsTotal = NUM_NEIGHBORS;
			tile.basePrice = MINIMUM_TILE_PRICE;
		}
		return tile;
	}

	/// @dev Create neighbors for a tile at a position.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	function _createNeighbors(int32 x, int32 y) private {
		for (uint8 i = 0; i < NUM_NEIGHBORS; i++) {
			(int32 ox, int32 oy) = (((int32(i)%3)-1), (1-int32(i)/2));
			_createTileAt(x + ox, y + oy);
		}
	}

	/// @dev Get the Tile storage object at a position.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	/// @return The tile storage object at that position.
	function _getTileAt(int32 x, int32 y)
			private view returns (Tile storage) {

		return _tiles[_toTileId(x, y)];
	}

	/// @dev Get the Tile storage object at a position.
	/// Reverts if it does not exist.
	/// @param x The x position of the tile.
	/// @param y The y position of the tile.
	/// @return The tile storage object at that position.
	function _getExistingTileAt(int32 x, int32 y)
			private view returns (Tile storage) {

		bytes16 id = _toTileId(x, y);
		Tile storage tile = _tiles[id];
		require(tile.id == id, ERROR_NOT_FOUND);
		return tile;
	}

	/// @dev Increment the global block stats for all blocks passed.
	/// This will adjust the total counts, production rates, and total scores.
	/// @param blocks Right-aligned, packed representation of blocks to append.
	/// @param count The number of blocks packed in &#39;blocks&#39;.
	function _incrementBlockStats(bytes16 blocks, uint8 count) private {
		for (uint8 h = 0; h < count; h++) {
			// Pop each block off the tower.
			uint8 b = uint8(uint128(blocks));
			blocks = blocks >> 8;
			BlockStats storage bs = _blockStats[b];
			bs.score += BLOCK_HEIGHT_BONUS[h];
			bs.count += 1;
			// Incrementally compute the production limit.
			uint64 production = (PPM_ONE * bs.production) / PRODUCTION_ALPHA;
			production = _estIntegerSqrt(bs.count, production);
			production = (production * PRODUCTION_ALPHA) / PPM_ONE;
			bs.production = production;
		}
	}

	/// @dev Share funds and resources from a tile to its immediate neighbors.
	/// The total amount distributed to all neighbors is defined by the TAX_RATE.
	/// The amount each neighbor actually receives depends on its relative
	/// &#39;clout&#39;, which is the height of its tower against all combined heights
	/// of all the towers of the tile&#39;s neighbors, so the tallest tower will
	/// receive the largest share.
	/// If a neighbor is unowned, its share of resources are discarded, but the
	/// funds are added to the &#39;fees&#39; collected by this contract.
	/// @param tile The tile object sharing its funds/resources.
	/// @param funds The (untaxed) funds to share.
	/// @param resources The (untaxed) resources to share.
	function _share(
			Tile storage tile,
			uint256 funds,
			uint256[NUM_RESOURCES] memory resources)
			private {

		// Compute how much each neighbor is entitled to.
		uint256 sharedFunds = _toTaxes(funds);
		uint256[NUM_RESOURCES] memory sharedResources =
			[_toTaxes(resources[0]), _toTaxes(resources[1]), _toTaxes(resources[2])];
		// Share with neighbors.
		for (uint8 i = 0; i < NUM_NEIGHBORS; i++) {
			(int32 ox, int32 oy) = (((int32(i)%3)-1), (1-int32(i)/2));
			Tile storage neighbor = _getExistingTileAt(tile.x + ox, tile.y + oy);
			// Normalization factor so that taller towers receive more.
			uint64 clout = ((neighbor.height + 1) * PPM_ONE)
				/ tile.neighborCloutsTotal;
			// If the tile is owned, share resources and funds.
			if (neighbor.owner != ZERO_ADDRESS) {
				neighbor.sharedResources[0] =
					neighbor.sharedResources[0].add(
						(clout * sharedResources[0]) / PPM_ONE);
				neighbor.sharedResources[1] =
					neighbor.sharedResources[1].add(
						(clout * sharedResources[1]) / PPM_ONE);
				neighbor.sharedResources[2] =
					neighbor.sharedResources[2].add(
						(clout * sharedResources[2]) / PPM_ONE);
				neighbor.sharedFunds = neighbor.sharedFunds.add(sharedFunds);
			} else {
				// If the tile is unowned, keep the funds as fees.
				fees = fees.add(
					(clout * sharedFunds) / PPM_ONE);
			}
		}
	}

	/// @dev Claims funds and resources from a tile to its owner.
	/// The amount minted/transfered/credited will be minus the tax.
	/// Resources are immediately minted to the tile owner.
	/// Funds (ether) are credited (pull pattern) to the tile owner unless
	/// the caller is also the tile owner, in which case it will be transfered
	/// immediately.
	/// @param tile The tile object.
	/// @param funds The funds (ether) held by the tile.
	/// @param resources The resources held by the tile.
	function _claim(
			Tile storage tile,
			uint256 funds,
			uint256[NUM_RESOURCES] memory resources)
			private {

		require(tile.owner != ZERO_ADDRESS, ERROR_INVALID);
		_mintTo(tile.owner, 0, _toTaxed(resources[0]));
		_mintTo(tile.owner, 1, _toTaxed(resources[1]));
		_mintTo(tile.owner, 2, _toTaxed(resources[2]));
		// If caller is not the owner, only credit funds.
		if (tile.owner != msg.sender)
			_creditTo(tile.owner, _toTaxed(funds));
		else // Otherwise try to transfer the funds synchronously.
			_transferTo(tile.owner, _toTaxed(funds));
	}

	/// @dev Get the full price for a tile.
	/// This is the isolated tile price plus seasonal bonuses,
	/// and neighborhood bonus.
	/// @param tile The tile object.
	/// @return The ether price, in wei.
	function _getTilePrice(Tile storage tile) private view
			returns (uint256 price) {

		uint256[NUM_RESOURCES] memory marketPrices = _getMarketPrices();
		price = _getIsolatedTilePrice(tile, marketPrices);
		/// Get the aggregate of neighbor prices.
		uint256 neighborPrices = 0;
		for (uint8 i = 0; i < NUM_NEIGHBORS; i++) {
			(int32 ox, int32 oy) = (((int32(i)%3)-1), (1-int32(i)/2));
			Tile storage neighbor = _getTileAt(tile.x + ox, tile.y + oy);
			if (neighbor.id != 0x0)
				neighborPrices = neighborPrices.add(
					_getIsolatedTilePrice(neighbor, marketPrices));
		}
		// Add the average of the neighbor prices.
		price = price.add(neighborPrices / NUM_NEIGHBORS);
		// If the tile is in season, it has a price bonus.
		if (_isTileInSeason(tile))
			price = price.mul(SEASON_PRICE_BONUS) / PPM_ONE;
	}

	/// @dev Get the isolated price for a tile.
	/// This is a sum of the base price for a tile (which increases
	/// with every purchase of the tile) and the materials costs of each block
	/// built on the tile at current market prices.
	function _getIsolatedTilePrice(
			Tile storage tile,
			uint256[NUM_RESOURCES] memory marketPrices)
			private view returns (uint256) {

		uint256 price = tile.basePrice;
		bytes16 blocks = tile.blocks;
		for (uint8 h = 0; h < tile.height; h++) {
			// Pop each block off the tower.
			uint8 b = uint8(uint128(blocks));
			blocks = blocks >> 8;
			uint256[NUM_RESOURCES] memory bc =
				_getBlockCost(b, _blockStats[b].count, h);
			price = price.add(marketPrices[0].mul(bc[0]) / ONE_TOKEN);
			price = price.add(marketPrices[1].mul(bc[1]) / ONE_TOKEN);
			price = price.add(marketPrices[2].mul(bc[2]) / ONE_TOKEN);
		}
		return price;
	}

	/// @dev Do a direct transfer of ether to someone.
	/// This is like address.transfer() but with some key differences:
	/// The transfer will forward all remaining gas to the recipient and
	/// will revert with an ERROR_TRANSFER_FAILED on failure.
	/// Transfers to the zero address (0x0), will simply add to the fees
	/// collected.
	/// @param to Recipient address.
	/// @param amount Amount of ether (in wei) to transfer.
	function _transferTo(address to, uint256 amount) private {
		if (amount > 0) {
			if (to == ZERO_ADDRESS) {
				fees = fees.add(amount);
				return;
			}
			// Use fallback function and forward all remaining gas.
			//solhint-disable-next-line
			(bool success,) = to.call.value(amount)("");
			require(success, ERROR_TRANSFER_FAILED);
		}
	}

	/// @dev Credit someone some ether to be pulled via collectCredits() later.
	/// Transfers to the zero address (0x0), will simply add to the fees
	/// collected.
	/// @param to Recipient address.
	/// @param amount Amount of ether (in wei) to transfer.
	function _creditTo(address to, uint256 amount) private {
		if (amount > 0) {
			// Payments to zero address are just fees collected.
			if (to == ZERO_ADDRESS) {
				fees = fees.add(amount);
				return;
			}
			// Just credit the player. She can collect it later through
			// collectCredits().
			credits[to] = credits[to].add(amount);
			emit Credited(to, amount);
		}
	}

	/// @dev Mint some resource tokens to someone.
	/// @param recipient The recipient.
	/// @param resource The resource ID number.
	/// @param amount The amount of tokens to mint (in wei).
	function _mintTo(
			address recipient, uint8 resource, uint256 amount) private {

		if (amount > 0)
			_tokens[resource].mint(recipient, amount);
	}

	/// @dev Burn some resource tokens from someone.
	/// @param spender The owner of the tokens.
	/// @param resources Amount of each resource to burn.
	function _burn(
			address spender,
			uint256[NUM_RESOURCES] memory resources) private {

		assert(spender != ZERO_ADDRESS);
		if (resources[0] > 0)
			_tokens[0].burn(spender, resources[0]);
		if (resources[1] > 0)
			_tokens[1].burn(spender, resources[1]);
		if (resources[2] > 0)
			_tokens[2].burn(spender, resources[2]);
	}

	/// @dev Get the current market price of each resource token.
	/// @return The ether market price of each token, in wei.
	function _getMarketPrices() private view
			returns (uint256[NUM_RESOURCES] memory prices) {

		prices[0] = _market.getPrice(address(_tokens[0]));
		prices[1] = _market.getPrice(address(_tokens[1]));
		prices[2] = _market.getPrice(address(_tokens[2]));
	}

}