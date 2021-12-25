// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Base.sol";
import "./libs/BatchCounters.sol";
import "./interfaces/IDrawer.sol";

contract AtopiaApe is AtopiaBase {
	bool public initialized;
	using BatchCounters for BatchCounters.Counter;
	BatchCounters.Counter private _tokenIds;

	struct Token {
		address token;
		uint256 price;
		uint256 limit;
	}

	event TraitUpdated(uint256 tokenId, uint256 tokenTrait);

	uint256 public constant saleFee = 0.06 ether;
	uint256 public constant BLOCK_COUNT = 1000;

	mapping(address => bool) public memberships;
	mapping(address => uint256) public whitelists;
	Token[] public tokens;

	mapping(uint256 => string) names;

	mapping(uint256 => uint256) public tokenTraits;
	mapping(uint256 => mapping(uint256 => uint256)) public traitStore;
	uint256[] blockHashes;
	uint256 seed;

	IDrawer public drawer;

	uint8 public state;

	function initialize(address bucks) public virtual override {
		require(!initialized);
		initialized = true;
		AtopiaBase.initialize(bucks);
		seed = uint256(keccak256(abi.encodePacked(block.difficulty, block.coinbase, block.timestamp)));
	}

	function migrateV2(uint256[] memory tokenIds) public onlyOwner {
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			uint256 info = infos[tokenId];
			infos[tokenId] = (((info >> 192) + retiredGrow[tokenId]) << 192) | uint192(info);
			retiredGrow[tokenId] = 0;
		}
	}

	function totalTokens() external view returns (uint256) {
		return tokens.length;
	}

	function onlyState(uint8 _state) internal view {
		require(state >= _state, "Not Allowed");
	}

	function totalSupply() public view returns (uint256) {
		return _tokenIds.current();
	}

	function nextGenInfo(uint256 last) public pure returns (uint256, uint256) {
		if (last < 10_000) {
			return (10_000_000_000, 5 * apeYear); // 10k ABUCKS
		} else if (last < 20_000) {
			return (10_000_000_000, 3 * apeYear); // 10k ABUCKS
		} else if (last < 30_000) {
			return (15_000_000_000, 2 * apeYear); // 15k ABUCKS
		} else if (last < 40_000) {
			return (20_000_000_000, 1 * apeYear); // 20k ABUCKS
		} else {
			return (25_000_000_000, 1 * apeYear); // 25k ABUCKS
		}
	}

	function blockToken(uint16 blockIndex) public view returns (uint256) {
		uint256 blockHash = blockHashes[blockIndex];
		require(blockHash > 0);
		return (blockHash % BLOCK_COUNT) + 1 + blockIndex * BLOCK_COUNT;
	}

	function enter(
		address to,
		uint256 tokenId,
		uint256 _seed
	) internal {
		uint256 tokenTrait;
		uint256 drawerCounts = 0x00020009000a00040001000a000c000c000700070013;
		for (uint16 i = 0; i < 11; i++) {
			// 12 traits
			tokenTrait = (tokenTrait << 16) | ((_seed & 0xFFFF) % (drawerCounts & 0xFFFF));
			_seed = _seed >> 16;
			drawerCounts = drawerCounts >> 16;
		}

		tokenTraits[tokenId] = tokenTrait;
		_mint(to, tokenId);
	}

	function batch(
		address to,
		uint256 amount,
		uint256 age
	) internal {
		uint256 newSeed = seed;
		(uint256 start, uint256 end) = _tokenIds.increment(amount);
		uint256 info = ((block.timestamp - age) << 64) | uint64(block.timestamp);
		for (uint256 i = start; i <= end; i++) {
			infos[i] = info;

			newSeed = uint256(keccak256(abi.encodePacked(uint8(i), uint128(info), newSeed)));
			enter(to, i, newSeed);

			if (i % BLOCK_COUNT == 0) {
				blockHashes.push(newSeed);
			}
		}
		seed = newSeed;
	}

	function mint(uint256 amount) external payable {
		onlyState(2);
		require(amount <= 7);
		require(totalSupply() + amount <= 10_000);
		require(msg.value >= saleFee * amount);
		batch(msg.sender, amount, 5 * apeYear);
	}

	function mintPresale(uint256 amount) external payable {
		onlyState(1);
		require(whitelists[msg.sender] >= amount);
		whitelists[msg.sender] -= amount;
		require(totalSupply() + amount <= 10_000);
		require(msg.value >= saleFee * amount);
		batch(msg.sender, amount, 5 * apeYear);
	}

	function mintOG() external {
		onlyState(1);
		require(memberships[msg.sender]);
		delete memberships[msg.sender];
		require(totalSupply() < 10_000);
		batch(msg.sender, 1, 5 * apeYear);
	}

	function mintWithToken(uint256 index, uint256 amount) external {
		onlyState(1);
		require(amount <= (state == 1 ? 3 : 7));
		require(tokens[index].limit >= amount);
		tokens[index].limit -= amount;
		require(totalSupply() + amount <= 10_000);
		IBucks(tokens[index].token).transferFrom(msg.sender, admin, tokens[index].price * amount);
		batch(msg.sender, amount, 5 * apeYear);
	}

	function mintNextGen(uint256 amount) external {
		uint256 last = totalSupply();
		uint256 end = last + amount;
		require(end <= 50_000);
		require((last / 10_000) == (end / 10_000));
		(uint256 price, uint256 age) = nextGenInfo(end);
		bucks.burnFrom(msg.sender, price * amount);
		batch(msg.sender, amount, age);
	}

	function setName(uint256 tokenId, string memory name) external {
		onlyTokenOwner(tokenId);
		bucks.burnFrom(msg.sender, 10_000_000_000);
		names[tokenId] = name;
	}

	function placeItem(
		uint256 tokenId,
		uint16 traitType,
		uint256 traitId,
		bool isStore
	) internal {
		uint16 traitPos = (10 - traitType) * 16;
		uint256 tokenTrait = tokenTraits[tokenId];
		uint256 exchangeId = (tokenTrait >> traitPos) & 0xFFFF;

		if (isStore) {
			uint256 store = traitStore[tokenId][traitType];
			uint256 count = store & 0xFFFF;
			store = store >> 16;
			if (count == 0 && exchangeId > 0) {
				store = exchangeId;
				count = 1;
			}
			traitStore[tokenId][traitType] = (store << 32) | (traitId << 16) | (count + 1);
		}

		tokenTrait = ((tokenTrait ^ (exchangeId << traitPos)) ^ 0) | (traitId << traitPos);
		tokenTraits[tokenId] = tokenTrait;
		emit TraitUpdated(tokenId, tokenTrait);
	}

	function useItemFor(
		uint256 tokenId,
		uint256 itemInfo,
		uint256 amount
	) internal {
		// Min Age
		require(getAge(tokenId) >= itemInfo & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
		itemInfo = itemInfo >> 128;
		// Bonus Trait
		if (itemInfo & 0xFFFFFFFF > 0) {
			require(amount == 1);
			placeItem(tokenId, uint16((itemInfo >> 16) & 0xFFFF), uint16(itemInfo & 0xFFFF), true);
		}
		itemInfo = itemInfo >> 64;
		// Bonus Age
		useItemInternal(tokenId, itemInfo * amount);
	}

	function useItem(
		uint256 tokenId,
		uint256 itemId,
		uint256 amount
	) external {
		onlyTokenOwner(tokenId);
		IShop _shop = IShop(shop);
		uint256 itemInfo = _shop.itemInfo(itemId - 1);
		_shop.burn(msg.sender, itemId, amount);
		useItemFor(tokenId, itemInfo, amount);
	}

	function buyAndUseItem(uint256 tokenId, uint256 itemInfo) external {
		require(shop == msg.sender);
		useItemFor(tokenId, itemInfo, 1);
	}

	function makeup(
		uint256 tokenId,
		uint16 traitType,
		uint256 storeIndex
	) external {
		onlyTokenOwner(tokenId);
		uint256 store = traitStore[tokenId][traitType];
		uint256 count = store & 0xFFFF;
		require(storeIndex < count);
		placeItem(tokenId, traitType, (store >> ((storeIndex + 1) * 16)) & 0xFFFF, false);
	}

	function claimTraits(uint16 blockIndex) external {
		uint256 tokenId = blockToken(blockIndex);
		blockHashes[blockIndex] = 0;
		uint16 traitIndex = 0x000a + blockIndex;
		require(traitIndex < drawer.totalItems(5));
		placeItem(tokenId, 5, traitIndex, true);
		traitIndex = 0x0002 + blockIndex;
		require(traitIndex < drawer.totalItems(10));
		placeItem(tokenId, 10, traitIndex, false);
	}

	function setState(uint8 _state) external onlyOwner {
		state = _state;
	}

	function setDrawer(address _drawer) external onlyOwner {
		drawer = IDrawer(_drawer);
		emit DrawerUpdated(_drawer);
	}

	// function addMembership(address[] calldata members) public onlyOwner {
	// 	for (uint256 i = 0; i < members.length; i++) {
	// 		memberships[members[i]] = true;
	// 	}
	// }

	// function addWhitelists(address[] calldata members) public onlyOwner {
	// 	for (uint256 i = 0; i < members.length; i++) {
	// 		whitelists[members[i]] = 3;
	// 	}
	// }

	// function addToken(
	// 	address token,
	// 	uint256 price,
	// 	uint256 limit
	// ) public onlyOwner {
	// 	tokens.push(Token(token, price, limit));
	// }

	function withdraw() external onlyOwner {
		payable(admin).transfer(address(this).balance);
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		require(ownerOf[tokenId] != address(0), "Token Invalid");
		return drawer.tokenURI(tokenId, names[tokenId], tokenTraits[tokenId], uint16((getAge(tokenId) / apeYear)));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBucks {
	function mint(address account, uint256 amount) external;

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

	function transfer(address recipient, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITrait.sol";

interface IDrawer {
	function totalItems(uint256 traitId) external view returns (uint256);

	function tokenURI(
		uint256 tokenId,
		string memory name,
		uint256 tokenTrait,
		uint16 age
	) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IShop {
	function itemInfo(uint256 index) external view returns (uint256);

	function burn(
		address account,
		uint256 id,
		uint256 value
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrait {
	function name() external view returns (string memory);

	function itemCount() external view returns (uint256);

	function totalItems() external view returns (uint256);

	function getTraitName(uint16 traitId) external view returns (string memory);

	function getTraitContent(uint16 traitId) external view returns (string memory);

	function getTraitByAge(uint16 age) external view returns (uint16);

	function isOverEye(uint16 traitId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BatchCounters {
	struct Counter {
		uint256 _value; // default: 0
	}

	function current(Counter storage counter) internal view returns (uint256) {
		return counter._value;
	}

	function increment(Counter storage counter, uint256 amount) internal returns (uint256 start, uint256 end) {
		start = counter._value + 1;
		counter._value += amount;
		end = counter._value;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "../interfaces/IBucks.sol";
import "../interfaces/IShop.sol";

interface ISpace {
	function getLife(uint256 tokenId)
		external
		view
		returns (
			uint256 job,
			uint256 task,
			uint256 data
		);

	function totalCenters() external view returns (uint256);

	function addFeeAmount(uint256 centerId, uint256 amount) external;

	function grow(uint256 centerId, uint256 tokenId) external;

	function getGrowthAndFee(
		uint256 centerId,
		uint256 tokenId,
		uint256 growingReward
	) external view returns (uint256 grown, uint256 fee);
}

abstract contract AtopiaBase is ERC721 {
	uint256 constant apeYear = 365 days / 10;

	IBucks public bucks;
	address public shop;
	ISpace public space;

	mapping(uint256 => uint256) public infos;
	mapping(uint256 => uint256) public retiredGrow; // retire

	function initialize(address _bucks) public virtual {
		name = "Atopia Apes";
		symbol = "ATPAPE";
		bucks = IBucks(_bucks);
	}

	function getRewardsInternal(uint256 info, uint256 timestamp) internal pure returns (uint256) {
		if (info == 0) return 0;
		uint64 claims = uint64(info);
		uint256 duration = timestamp - claims;
		uint256 averageSpeed = (timestamp + claims) / 2 + uint64(info >> 192) - (uint128(info) >> 64);
		return (averageSpeed * duration * 20_000_000) / apeYear / 1 days;
	}

	function getAge(uint256 tokenId) public view returns (uint256) {
		uint256 info = infos[tokenId];
		return (block.timestamp - (uint128(info) >> 64)) + (info >> 192);
	}

	function getReward(uint256 tokenId)
		public
		view
		returns (
			uint256 reward,
			uint256 info,
			uint256 centerId,
			uint256 fee,
			uint256 grown
		)
	{
		(uint256 job, uint256 task, ) = space.getLife(tokenId);
		info = infos[tokenId];
		reward = uint64(info >> 128);
		uint256 growingReward = getRewardsInternal(info, block.timestamp);
		if (job > 0 && task == 0) {
			centerId = job;
			(grown, fee) = space.getGrowthAndFee(centerId, tokenId, growingReward);
		}
		reward += growingReward;
	}

	function getRewards(uint256[] memory tokenIds) external view returns (uint256 rewards) {
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			(uint256 reward, , , uint256 fee, ) = getReward(tokenId);
			rewards += (reward - fee);
		}
	}

	function onlyTokenOwner(uint256 tokenId) public view {
		require(ownerOf[tokenId] == msg.sender);
	}

	function claimRewards(uint256[] memory tokenIds) public {
		uint256 timestamp = block.timestamp;
		uint256 rewards;
		uint256[] memory fees = new uint256[](space.totalCenters());
		for (uint256 i = 0; i < tokenIds.length; i++) {
			uint256 tokenId = tokenIds[i];
			onlyTokenOwner(tokenId);
			(uint256 reward, uint256 info, uint256 centerId, uint256 fee, uint256 grown) = getReward(tokenId);
			if (fee > 0) {
				reward -= fee;
				fees[centerId - 1] += fee;
				space.grow(centerId, tokenId);
			}
			rewards += reward;
			infos[tokenId] = (((info >> 192) + grown) << 192) | ((uint128(info) >> 64) << 64) | uint64(timestamp);
		}
		for (uint256 i = 0; i < fees.length; i++) {
			uint256 fee = fees[i];
			if (fee > 0) {
				space.addFeeAmount(i + 1, fee);
			}
		}
		bucks.mint(msg.sender, rewards);
	}

	function useItemInternal(uint256 tokenId, uint256 bonusAge) internal {
		(uint256 centerId, uint256 task, ) = space.getLife(tokenId);
		uint256 timestamp = block.timestamp;
		uint256 info = infos[tokenId];
		uint256 growingReward = getRewardsInternal(info, timestamp);
		uint256 fee;
		uint256 grown;
		if (centerId > 0 && task == 0) {
			(grown, fee) = space.getGrowthAndFee(centerId, tokenId, growingReward);
			space.grow(centerId, tokenId);
			space.addFeeAmount(centerId, fee);
		}
		uint256 pending = growingReward + uint64(info >> 128) - fee;
		infos[tokenId] =
			(((info >> 192) + grown + bonusAge) << 192) |
			(pending << 128) |
			((uint128(info) >> 64) << 64) |
			uint64(timestamp);
	}

	function onlySpace() internal view {
		require(address(space) == msg.sender);
	}

	function claimGrowth(
		uint256 tokenId,
		uint256 grown,
		uint256 enjoyFee
	) external returns (uint256) {
		onlySpace();
		uint256 timestamp = block.timestamp;
		uint256 info = infos[tokenId];
		uint256 rewards = getRewardsInternal(info, timestamp);
		uint256 fee = (rewards * enjoyFee) / 10000;
		uint256 pending = rewards + uint64(info >> 128) - fee;
		infos[tokenId] =
			(((info >> 192) + grown) << 192) |
			(pending << 128) |
			((uint128(info) >> 64) << 64) |
			uint64(timestamp);
		return fee;
	}

	function addReward(uint256 tokenId, uint256 reward) external {
		onlySpace();
		uint256 info = infos[tokenId];
		uint256 pending = uint64(info >> 128) + reward;
		infos[tokenId] = ((info >> 192) << 192) | (pending << 128) | ((uint128(info) >> 64) << 64) | uint64(info);
	}

	function claimBucks(address user, uint256 amount) external {
		onlySpace();
		bucks.mint(user, amount);
	}

	function setShop(address _shop) external onlyOwner {
		shop = _shop;
		emit ShopUpdated(_shop);
	}

	function setSpace(address _space) external onlyOwner {
		space = ISpace(_space);
		emit SpaceUpdated(_space);
	}

	function _beforeTokenTransfer(
		address,
		address,
		uint256 tokenId
	) internal virtual override {
		uint256 timestamp = block.timestamp;
		(uint256 reward, uint256 info, uint256 centerId, uint256 fee, uint256 grown) = getReward(tokenId);
		if (fee > 0) {
			reward -= fee;
			space.addFeeAmount(centerId, fee);
			space.grow(centerId, tokenId);
		}
		infos[tokenId] = (((info >> 192) + grown) << 192) | ((uint128(info) >> 64) << 64) | uint64(timestamp);
		bucks.mint(ownerOf[tokenId], reward);
	}

	event DrawerUpdated(address drawer);
	event ShopUpdated(address shop);
	event SpaceUpdated(address space);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
	/*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

	event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	/*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

	address implementation_;
	address public admin;

	string public name;
	string public symbol;

	/*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

	mapping(address => uint256) public balanceOf;

	mapping(uint256 => address) public ownerOf;

	mapping(uint256 => address) public getApproved;

	mapping(address => mapping(address => bool)) public isApprovedForAll;

	/*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

	modifier onlyOwner() {
		require(msg.sender == admin);
		_;
	}

	function owner() external view returns (address) {
		return admin;
	}

	/*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

	function transfer(address to, uint256 tokenId) external {
		require(msg.sender == ownerOf[tokenId], "NOT_OWNER");

		_transfer(msg.sender, to, tokenId);
	}

	/*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

	function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
		supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
	}

	function approve(address spender, uint256 tokenId) external {
		address owner_ = ownerOf[tokenId];

		require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");

		getApproved[tokenId] = spender;

		emit Approval(owner_, spender, tokenId);
	}

	function setApprovalForAll(address operator, bool approved) external {
		isApprovedForAll[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public {
		require(
			msg.sender == from || msg.sender == getApproved[tokenId] || isApprovedForAll[from][msg.sender],
			"NOT_APPROVED"
		);

		_transfer(from, to, tokenId);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external {
		safeTransferFrom(from, to, tokenId, "");
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public {
		transferFrom(from, to, tokenId);

		if (to.code.length != 0) {
			// selector = `onERC721Received(address,address,uint,bytes)`
			(, bytes memory returned) = to.staticcall(
				abi.encodeWithSelector(0x150b7a02, msg.sender, from, tokenId, data)
			);

			bytes4 selector = abi.decode(returned, (bytes4));

			require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
		}
	}

	/*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		require(ownerOf[tokenId] == from);
		_beforeTokenTransfer(from, to, tokenId);

		balanceOf[from]--;
		balanceOf[to]++;

		delete getApproved[tokenId];

		ownerOf[tokenId] = to;
		emit Transfer(msg.sender, to, tokenId);
	}

	function _mint(address to, uint256 tokenId) internal {
		require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

		// This is safe because the sum of all user
		// balances can't exceed type(uint256).max!
		unchecked {
			balanceOf[to]++;
		}

		ownerOf[tokenId] = to;

		emit Transfer(address(0), to, tokenId);
	}

	function _burn(uint256 tokenId) internal {
		address owner_ = ownerOf[tokenId];

		require(owner_ != address(0), "NOT_MINTED");
		_beforeTokenTransfer(owner_, address(0), tokenId);

		balanceOf[owner_]--;

		delete ownerOf[tokenId];

		emit Transfer(owner_, address(0), tokenId);
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {}
}