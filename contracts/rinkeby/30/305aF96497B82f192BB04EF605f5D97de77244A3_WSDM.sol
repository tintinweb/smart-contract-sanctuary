// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


import "./Game.sol";
import "./Staking.sol";


interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

interface Router {
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
}

interface Factory {
	function getPair(address, address) external view returns (address);
	function createPair(address, address) external returns (address);
}

interface Pair {
	function token0() external view returns (address);
	function totalSupply() external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function allowance(address, address) external view returns (uint256);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
	function transfer(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
}

contract WSDM {

	uint256 constant private UINT_MAX = type(uint256).max;
	uint256 constant private TRANSFER_FEE = 1; // 1% per transfer

	string constant public name = "WSDM Token";
	string constant public symbol = "WSDM";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
		mapping(address => bool) toWhitelist;
		mapping(address => bool) fromWhitelist;
		address owner;
		Router router;
		Pair pair;
		bool weth0;
		Game g;
		Staking staking;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event WhitelistUpdated(address indexed user, bool fromWhitelisted, bool toWhitelisted);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor() {
		info.router = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		info.pair = Pair(Factory(info.router.factory()).createPair(info.router.WETH(), address(this)));
		info.weth0 = info.pair.token0() == info.router.WETH();
		info.owner = msg.sender;
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setWhitelisted(address _address, bool _fromWhitelisted, bool _toWhitelisted) external _onlyOwner {
		info.fromWhitelist[_address] = _fromWhitelisted;
		info.toWhitelist[_address] = _toWhitelisted;
		emit WhitelistUpdated(_address, _fromWhitelisted, _toWhitelisted);
	}

	function deploySetGame(Game _g) external {
		require(tx.origin == owner() && stakingAddress() == address(0x0));
		info.g = _g;
		info.staking = new Staking(info.g, info.pair);
		_approve(address(this), stakingAddress(), UINT_MAX);
	}


	function mint(address _receiver, uint256 _tokens) external {
		require(msg.sender == address(info.g));
		info.totalSupply += _tokens;
		info.users[_receiver].balance += _tokens;
		emit Transfer(address(0x0), _receiver, _tokens);
	}

	function burn(uint256 _tokens) external {
		require(balanceOf(msg.sender) >= _tokens);
		info.totalSupply -= _tokens;
		info.users[msg.sender].balance -= _tokens;
		emit Transfer(msg.sender, address(0x0), _tokens);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		return _approve(msg.sender, _spender, _tokens);
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		uint256 _allowance = allowance(_from, msg.sender);
		require(_allowance >= _tokens);
		if (_allowance != UINT_MAX) {
			info.users[_from].allowance[msg.sender] -= _tokens;
		}
		return _transfer(_from, _to, _tokens);
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external returns (bool) {
		uint256 _balanceBefore = balanceOf(_to);
		_transfer(msg.sender, _to, _tokens);
		uint256 _tokensReceived = balanceOf(_to) - _balanceBefore;
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokensReceived, _data));
		}
		return true;
	}
	

	function bullsGameAddress() public view returns (address) {
		return address(info.g);
	}

	function pairAddress() external view returns (address) {
		return address(info.pair);
	}

	function stakingAddress() public view returns (address) {
		return address(info.staking);
	}

	function owner() public view returns (address) {
		return info.owner;
	}

	function isFromWhitelisted(address _address) public view returns (bool) {
		return info.fromWhitelist[_address];
	}

	function isToWhitelisted(address _address) public view returns (bool) {
		return info.toWhitelist[_address];
	}
	
	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) external view returns (uint256 totalTokens, uint256 totalLPTokens, uint256 wethReserve, uint256 wsdmReserve, uint256 userAllowance, uint256 userBalance, uint256 userLPBalance) {
		totalTokens = totalSupply();
		totalLPTokens = info.pair.totalSupply();
		(uint256 _res0, uint256 _res1, ) = info.pair.getReserves();
		wethReserve = info.weth0 ? _res0 : _res1;
		wsdmReserve = info.weth0 ? _res1 : _res0;
		userAllowance = allowance(_user, bullsGameAddress());
		userBalance = balanceOf(_user);
		userLPBalance = info.pair.balanceOf(_user);
	}


	function _approve(address _owner, address _spender, uint256 _tokens) internal returns (bool) {
		info.users[_owner].allowance[_spender] = _tokens;
		emit Approval(_owner, _spender, _tokens);
		return true;
	}
	
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		uint256 _fee = 0;
		if (!(_from == stakingAddress() || _to == stakingAddress() || _to == bullsGameAddress() || isFromWhitelisted(_from) || isToWhitelisted(_to))) {
			_fee = _tokens * TRANSFER_FEE / 100;
			address _this = address(this);
			info.users[_this].balance += _fee;
			emit Transfer(_from, _this, _fee);
			info.staking.disburse(balanceOf(_this));
		}
		info.users[_to].balance += _tokens - _fee;
		emit Transfer(_from, _to, _tokens - _fee);
		return true;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Game.sol";
import "./WSDM.sol";

contract Staking {

	uint256 constant private FLOAT_SCALAR = 2**64;

	struct User {
		uint256 deposited;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalDeposited;
		uint256 scaledRewardsPerToken;
		uint256 pendingRewards;
		mapping(address => User) users;
		Game g;
		WSDM wsdm;
		Pair pair;
	}
	Info private info;


	event Deposit(address indexed user, uint256 amount);
	event Withdraw(address indexed user, uint256 amount);
	event Claim(address indexed user, uint256 amount);
	event Reward(uint256 amount);


	constructor(Game _g, Pair _pair) {
		info.g = _g;
		info.wsdm = WSDM(msg.sender);
		info.pair = _pair;
	}

	function disburse(uint256 _amount) external {
		if (_amount > 0) {
			info.wsdm.transferFrom(msg.sender, address(this), _amount);
			_disburse(_amount);
		}
	}

	function deposit(uint256 _amount) external {
		depositFor(_amount, msg.sender);
	}

	function depositFor(uint256 _amount, address _user) public {
		require(_amount > 0);
		_update();
		info.pair.transferFrom(msg.sender, address(this), _amount);
		info.totalDeposited += _amount;
		info.users[_user].deposited += _amount;
		info.users[_user].scaledPayout += int256(_amount * info.scaledRewardsPerToken);
		emit Deposit(_user, _amount);
	}

	function withdrawAll() external {
		uint256 _deposited = depositedOf(msg.sender);
		if (_deposited > 0) {
			withdraw(_deposited);
		}
	}

	function withdraw(uint256 _amount) public {
		require(_amount > 0 && _amount <= depositedOf(msg.sender));
		_update();
		info.totalDeposited -= _amount;
		info.users[msg.sender].deposited -= _amount;
		info.users[msg.sender].scaledPayout -= int256(_amount * info.scaledRewardsPerToken);
		info.pair.transfer(msg.sender, _amount);
		emit Withdraw(msg.sender, _amount);
	}

	function claim() external {
		_update();
		uint256 _rewards = rewardsOf(msg.sender);
		if (_rewards > 0) {
			info.users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
			info.wsdm.transfer(msg.sender, _rewards);
			emit Claim(msg.sender, _rewards);
		}
	}

	
	function totalDeposited() public view returns (uint256) {
		return info.totalDeposited;
	}

	function depositedOf(address _user) public view returns (uint256) {
		return info.users[_user].deposited;
	}
	
	function rewardsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledRewardsPerToken * depositedOf(_user)) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allInfoFor(address _user) external view returns (uint256 totalLPDeposited, uint256 totalLPTokens, uint256 wethReserve, uint256 wsdmReserve, uint256 userBalance, uint256 userAllowance, uint256 userDeposited, uint256 userRewards) {
		totalLPDeposited = totalDeposited();
		( , totalLPTokens, wethReserve, wsdmReserve, , , ) = info.wsdm.allInfoFor(address(this));
		userBalance = info.pair.balanceOf(_user);
		userAllowance = info.pair.allowance(_user, address(this));
		userDeposited = depositedOf(_user);
		userRewards = rewardsOf(_user);
	}

	function _update() internal {
		address _this = address(this);
		uint256 _balanceBefore = info.wsdm.balanceOf(_this);
		info.g.claim();
		_disburse(info.wsdm.balanceOf(_this) - _balanceBefore);
	}

	function _disburse(uint256 _amount) internal {
		if (_amount > 0) {
			if (totalDeposited() == 0) {
				info.pendingRewards += _amount;
			} else {
				info.scaledRewardsPerToken += (_amount + info.pendingRewards) * FLOAT_SCALAR / totalDeposited();
				info.pendingRewards = 0;
			}
			emit Reward(_amount);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./WSDM.sol";

interface MetadataInterface {
	function name() external view returns (string memory);
	function symbol() external view returns (string memory);
	function tokenURI(uint256 _tokenId) external view returns (string memory);
	function deploySetGame(Game _g) external;
}

contract Game {

	uint256 constant public ETH_MINTABLE_SUPPLY = 2000;
	uint256 constant public WHITELIST_ETH_MINTABLE_SUPPLY = 8000;
	uint256 constant public WSDM_MINTABLE_SUPPLY = 40000;
	uint256 constant public MAX_SUPPLY = ETH_MINTABLE_SUPPLY + WHITELIST_ETH_MINTABLE_SUPPLY + WSDM_MINTABLE_SUPPLY;
	uint256 constant public INITIAL_MINT_COST_ETH = 0.05 ether;
	uint256 constant public WSDM_PER_DAY_PER_BEAR = 1e22; // 10,000

	uint256 constant private WSDM_COST_ADD = 1e4;
	uint256 constant private WSDM_COST_EXPONENT = 3;
	uint256 constant private WSDM_COST_SCALER = 2e10;
	// WSDM minted tokens = 0, minting cost = 20,000
	// WSDM minted tokens = 40k, minting cost = 2,500,000

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private BULL_MODULUS = 10; // 1 in 10
	uint256 constant private BULLS_CUT = 20; // 20% of all yield
	uint256 constant private STAKING_CUT = 25; // 25% of minting costs
	uint256 constant private DEV_TOKENS = 50;
	uint256 constant private OPENING_DELAY = 2 hours;
	uint256 constant private WHITELIST_DURATION = 8 hours;

	struct User {
		uint256 balance;
		mapping(uint256 => uint256) list;
		mapping(address => bool) approved;
		mapping(uint256 => uint256) indexOf;
		uint256 rewards;
		uint256 lastUpdated;
		uint256 wsdmPerDay;
		uint256 bulls;
		int256 scaledPayout;
	}

	struct Token {
		address owner;
		address approved;
		bytes32 seed;
		bool isBull;
	}

	struct Info {
		uint256 totalSupply;
		uint256 totalBulls;
		uint256 ethMintedTokens;
		uint256 wsdmMintedTokens;
		uint256 scaledRewardsPerBull;
		uint256 openingTime;
		uint256 whitelistExpiry;
		mapping(uint256 => Token) list;
		mapping(address => User) users;
		mapping(uint256 => uint256) claimedBitMap;
		bytes32 merkleRoot;
		MetadataInterface metadata;
		address owner;
		WSDM wsdm;
		Staking staking;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;

	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	event Mint(address indexed owner, uint256 indexed tokenId, bytes32 seed, bool isBull);
	event ClaimFishermenRewards(address indexed user, uint256 amount);
	event ClaimBullRewards(address indexed user, uint256 amount);
	event Reward(address indexed user, uint256 amount);
	event BullsReward(uint256 amount);
	event StakingReward(uint256 amount);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor(MetadataInterface _metadata, WSDM _wsdm, bytes32 _merkleRoot) {
		info.metadata = _metadata;
		info.metadata.deploySetGame(this);
		info.wsdm = _wsdm;
		info.wsdm.deploySetGame(this);
		info.staking = Staking(info.wsdm.stakingAddress());
		info.wsdm.approve(stakingAddress(), type(uint256).max);
		info.merkleRoot = _merkleRoot;
		info.owner = 0x4324c35f21Cc6Ed3507F71Abd472Da4236A95b8e;
		info.openingTime = block.timestamp + OPENING_DELAY;
		info.whitelistExpiry = block.timestamp + OPENING_DELAY + WHITELIST_DURATION;

		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		supportsInterface[0x780e9d63] = true; // Enumerable

		for (uint256 i = 0; i < DEV_TOKENS; i++) {
			_mint(0x4324c35f21Cc6Ed3507F71Abd472Da4236A95b8e);
		}
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setMetadata(MetadataInterface _metadata) external _onlyOwner {
		info.metadata = _metadata;
	}

	function withdraw() external {
		address _this = address(this);
		require(_this.balance > 0);
		payable(0xFaDED72464D6e76e37300B467673b36ECc4d2ccF).transfer(_this.balance / 2); // 50% total
		payable(0x1cC79d49ce5b9519C912D810E39025DD27d1F033).transfer(_this.balance / 10); // 5% total
		payable(0xa1450E7D547b4748fc94C8C98C9dB667eaD31cF8).transfer(_this.balance); // 45% total
	}

	
	receive() external payable {
		mintManyWithETH(msg.value / INITIAL_MINT_COST_ETH);
	}
	
	function mintWithETH() external payable {
		mintManyWithETH(1);
	}

	function mintManyWithETH(uint256 _tokens) public payable {
		require(isOpen());
		require(_tokens > 0);
		if (whitelistExpired()) {
			require(totalSupply() - wsdmMintedTokens() + _tokens <= ETH_MINTABLE_SUPPLY + WHITELIST_ETH_MINTABLE_SUPPLY);
		} else {
			require(ethMintedTokens() + _tokens <= ETH_MINTABLE_SUPPLY);
		}
		uint256 _cost = _tokens * INITIAL_MINT_COST_ETH;
		require(msg.value >= _cost);
		info.ethMintedTokens += _tokens;
		for (uint256 i = 0; i < _tokens; i++) {
			_mint(msg.sender);
		}
		if (msg.value > _cost) {
			payable(msg.sender).transfer(msg.value - _cost);
		}
	}

	function mintWithProof(uint256 _index, address _account, bytes32[] calldata _merkleProof) external payable {
		require(isOpen());
		require(!whitelistExpired() && whitelistMintedTokens() < WHITELIST_ETH_MINTABLE_SUPPLY);
		require(msg.value >= INITIAL_MINT_COST_ETH);
		require(!proofClaimed(_index));
		bytes32 _node = keccak256(abi.encodePacked(_index, _account));
		require(_verify(_merkleProof, _node));
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		info.claimedBitMap[_claimedWordIndex] = info.claimedBitMap[_claimedWordIndex] | (1 << _claimedBitIndex);
		_mint(_account);
		if (msg.value > INITIAL_MINT_COST_ETH) {
			payable(msg.sender).transfer(msg.value - INITIAL_MINT_COST_ETH);
		}
	}

	function mint() external {
		mintMany(1);
	}

	function mintMany(uint256 _tokens) public {
		require(isOpen());
		require(_tokens > 0 && wsdmMintedTokens() + _tokens <= WSDM_MINTABLE_SUPPLY);
		uint256 _cost = calculateWsdmMintCost(_tokens);
		info.wsdm.transferFrom(msg.sender, address(this), _cost);
		uint256 _stakingReward = _cost * STAKING_CUT / 100;
		info.staking.disburse(_stakingReward);
		emit StakingReward(_stakingReward);
		info.wsdm.burn(info.wsdm.balanceOf(address(this)));
		info.wsdmMintedTokens += _tokens;
		for (uint256 i = 0; i < _tokens; i++) {
			_mint(msg.sender);
		}
	}

	function claim() external {
		claimFishermenRewards();
		claimBullRewards();
	}

	function claimFishermenRewards() public {
		_update(msg.sender);
		uint256 _rewards = info.users[msg.sender].rewards;
		if (_rewards > 0) {
			info.users[msg.sender].rewards = 0;
			info.wsdm.mint(msg.sender, _rewards);
			emit ClaimFishermenRewards(msg.sender, _rewards);
		}
	}

	function claimBullRewards() public {
		uint256 _rewards = bullRewardsOf(msg.sender);
		if (_rewards > 0) {
			info.users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
			info.wsdm.mint(msg.sender, _rewards);
			emit ClaimBullRewards(msg.sender, _rewards);
		}
	}
	
	function approve(address _approved, uint256 _tokenId) external {
		require(msg.sender == ownerOf(_tokenId));
		info.list[_tokenId].approved = _approved;
		emit Approval(msg.sender, _approved, _tokenId);
	}

	function setApprovalForAll(address _operator, bool _approved) external {
		info.users[msg.sender].approved[_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function transferFrom(address _from, address _to, uint256 _tokenId) external {
		_transfer(_from, _to, _tokenId);
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
		_transfer(_from, _to, _tokenId);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) == 0x150b7a02);
		}
	}


	function name() external view returns (string memory) {
		return info.metadata.name();
	}

	function symbol() external view returns (string memory) {
		return info.metadata.symbol();
	}

	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		return info.metadata.tokenURI(_tokenId);
	}

	function wsdmAddress() external view returns (address) {
		return address(info.wsdm);
	}

	function pairAddress() external view returns (address) {
		return info.wsdm.pairAddress();
	}

	function stakingAddress() public view returns (address) {
		return address(info.staking);
	}

	function merkleRoot() public view returns (bytes32) {
		return info.merkleRoot;
	}

	function openingTime() public view returns (uint256) {
		return info.openingTime;
	}

	function isOpen() public view returns (bool) {
		return block.timestamp > openingTime();
	}

	function whitelistExpiry() public view returns (uint256) {
		return info.whitelistExpiry;
	}

	function whitelistExpired() public view returns (bool) {
		return block.timestamp > whitelistExpiry();
	}

	function owner() public view returns (address) {
		return info.owner;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function ethMintedTokens() public view returns (uint256) {
		return info.ethMintedTokens;
	}

	function wsdmMintedTokens() public view returns (uint256) {
		return info.wsdmMintedTokens;
	}

	function whitelistMintedTokens() public view returns (uint256) {
		return totalSupply() - ethMintedTokens() - wsdmMintedTokens();
	}

	function totalBulls() public view returns (uint256) {
		return info.totalBulls;
	}

	function totalFishermen() public view returns (uint256) {
		return totalSupply() - totalBulls();
	}

	function totalWsdmPerDay() external view returns (uint256) {
		return totalFishermen() * WSDM_PER_DAY_PER_BEAR;
	}

	function currentWsdmMintCost() public view returns (uint256) {
		return wsdmMintCost(wsdmMintedTokens());
	}

	function wsdmMintCost(uint256 _wsdmMintedTokens) public pure returns (uint256) {
		return (_wsdmMintedTokens + WSDM_COST_ADD)**WSDM_COST_EXPONENT * WSDM_COST_SCALER;
	}

	function calculateWsdmMintCost(uint256 _tokens) public view returns (uint256 cost) {
		cost = 0;
		for (uint256 i = 0; i < _tokens; i++) {
			cost += wsdmMintCost(wsdmMintedTokens() + i);
		}
	}

	function fishermenRewardsOf(address _owner) public view returns (uint256) {
		uint256 _pending = 0;
		uint256 _last = info.users[_owner].lastUpdated;
		if (_last < block.timestamp) {
			uint256 _diff = block.timestamp - _last;
			_pending += ownerWsdmPerDay(_owner) * _diff * (100 - BULLS_CUT) / 8640000;
		}
		return info.users[_owner].rewards + _pending;
	}
	
	function bullRewardsOf(address _owner) public view returns (uint256) {
		return uint256(int256(info.scaledRewardsPerBull * bullsOf(_owner)) - info.users[_owner].scaledPayout) / FLOAT_SCALAR;
	}

	function balanceOf(address _owner) public view returns (uint256) {
		return info.users[_owner].balance;
	}

	function bullsOf(address _owner) public view returns (uint256) {
		return info.users[_owner].bulls;
	}

	function fishermenOf(address _owner) public view returns (uint256) {
		return balanceOf(_owner) - bullsOf(_owner);
	}

	function ownerOf(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].owner;
	}

	function getApproved(uint256 _tokenId) public view returns (address) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].approved;
	}

	function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
		return info.users[_owner].approved[_operator];
	}

	function getSeed(uint256 _tokenId) public view returns (bytes32) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].seed;
	}

	function getIsBull(uint256 _tokenId) public view returns (bool) {
		require(_tokenId < totalSupply());
		return info.list[_tokenId].isBull;
	}

	function tokenByIndex(uint256 _index) public view returns (uint256) {
		require(_index < totalSupply());
		return _index;
	}

	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
		require(_index < balanceOf(_owner));
		return info.users[_owner].list[_index];
	}

	function ownerWsdmPerDay(address _owner) public view returns (uint256 amount) {
		return info.users[_owner].wsdmPerDay;
	}

	function proofClaimed(uint256 _index) public view returns (bool) {
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		uint256 _claimedWord = info.claimedBitMap[_claimedWordIndex];
		uint256 _mask = (1 << _claimedBitIndex);
		return _claimedWord & _mask == _mask;
	}

	function getToken(uint256 _tokenId) public view returns (address tokenOwner, address approved, bytes32 seed, bool isBull) {
		return (ownerOf(_tokenId), getApproved(_tokenId), getSeed(_tokenId), getIsBull(_tokenId));
	}

	function getTokens(uint256[] memory _tokenIds) public view returns (address[] memory owners, address[] memory approveds, bytes32[] memory seeds, bool[] memory isBulls) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		seeds = new bytes32[](_length);
		isBulls = new bool[](_length);
		for (uint256 i = 0; i < _length; i++) {
			(owners[i], approveds[i], seeds[i], isBulls[i]) = getToken(_tokenIds[i]);
		}
	}

	function getTokensTable(uint256 _limit, uint256 _page, bool _isAsc) external view returns (uint256[] memory tokenIds, address[] memory owners, address[] memory approveds, bytes32[] memory seeds, bool[] memory isBulls, uint256 totalTokens, uint256 totalPages) {
		require(_limit > 0);
		totalTokens = totalSupply();

		if (totalTokens > 0) {
			totalPages = (totalTokens / _limit) + (totalTokens % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalTokens % _limit != 0) {
				_limit = totalTokens % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenByIndex(_isAsc ? _offset + i : totalTokens - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		(owners, approveds, seeds, isBulls) = getTokens(tokenIds);
	}

	function getOwnerTokensTable(address _owner, uint256 _limit, uint256 _page, bool _isAsc) external view returns (uint256[] memory tokenIds, address[] memory approveds, bytes32[] memory seeds, bool[] memory isBulls, uint256 totalTokens, uint256 totalPages) {
		require(_limit > 0);
		totalTokens = balanceOf(_owner);

		if (totalTokens > 0) {
			totalPages = (totalTokens / _limit) + (totalTokens % _limit == 0 ? 0 : 1);
			require(_page < totalPages);

			uint256 _offset = _limit * _page;
			if (_page == totalPages - 1 && totalTokens % _limit != 0) {
				_limit = totalTokens % _limit;
			}

			tokenIds = new uint256[](_limit);
			for (uint256 i = 0; i < _limit; i++) {
				tokenIds[i] = tokenOfOwnerByIndex(_owner, _isAsc ? _offset + i : totalTokens - _offset - i - 1);
			}
		} else {
			totalPages = 0;
			tokenIds = new uint256[](0);
		}
		( , approveds, seeds, isBulls) = getTokens(tokenIds);
	}

	function allMintingInfo() external view returns (uint256 ethMinted, uint256 whitelistMinted, uint256 wsdmMinted, uint256 currentwsdmCost, uint256 whitelistExpiryTime, bool hasWhitelistExpired, uint256 openTime, bool open) {
		return (ethMintedTokens(), whitelistMintedTokens(), wsdmMintedTokens(), currentWsdmMintCost(), whitelistExpiry(), whitelistExpired(), openingTime(), isOpen());
	}

	function allInfoFor(address _owner) external view returns (uint256 supply, uint256 bulls, uint256 ownerBalance, uint256 ownerBulls, uint256 ownerFishermenRewards, uint256 ownerBullRewards, uint256 ownerDailyWsdm) {
		return (totalSupply(), totalBulls(), balanceOf(_owner), bullsOf(_owner), fishermenRewardsOf(_owner), bullRewardsOf(_owner), ownerWsdmPerDay(_owner));
	}


	function _mint(address _receiver) internal {
		require(msg.sender == tx.origin);
		require(totalSupply() < MAX_SUPPLY);
		uint256 _tokenId = info.totalSupply++;
		Token storage _newToken = info.list[_tokenId];
		_newToken.owner = _receiver;
		bytes32 _seed = keccak256(abi.encodePacked(_tokenId, _receiver, blockhash(block.number - 1), gasleft()));
		_newToken.seed = _seed;
		_newToken.isBull = _tokenId < DEV_TOKENS || _tokenId % BULL_MODULUS == 0;

		if (_newToken.isBull) {
			info.totalBulls++;
			info.users[_receiver].bulls++;
			info.users[_receiver].scaledPayout += int256(info.scaledRewardsPerBull);
		} else {
			_update(_receiver);
			info.users[_receiver].wsdmPerDay += WSDM_PER_DAY_PER_BEAR;
		}
		uint256 _index = info.users[_receiver].balance++;
		info.users[_receiver].indexOf[_tokenId] = _index + 1;
		info.users[_receiver].list[_index] = _tokenId;
		emit Transfer(address(0x0), _receiver, _tokenId);
		emit Mint(_receiver, _tokenId, _seed, _newToken.isBull);
	}
	
	function _transfer(address _from, address _to, uint256 _tokenId) internal {
		address _owner = ownerOf(_tokenId);
		address _approved = getApproved(_tokenId);
		require(_from == _owner);
		require(msg.sender == _owner || msg.sender == _approved || isApprovedForAll(_owner, msg.sender));

		info.list[_tokenId].owner = _to;
		if (_approved != address(0x0)) {
			info.list[_tokenId].approved = address(0x0);
			emit Approval(address(0x0), address(0x0), _tokenId);
		}

		if (getIsBull(_tokenId)) {
			info.users[_from].bulls--;
			info.users[_from].scaledPayout -= int256(info.scaledRewardsPerBull);
			info.users[_to].bulls++;
			info.users[_to].scaledPayout += int256(info.scaledRewardsPerBull);
		} else {
			_update(_from);
			info.users[_from].wsdmPerDay -= WSDM_PER_DAY_PER_BEAR;
			_update(_to);
			info.users[_to].wsdmPerDay += WSDM_PER_DAY_PER_BEAR;
		}

		uint256 _index = info.users[_from].indexOf[_tokenId] - 1;
		uint256 _moved = info.users[_from].list[info.users[_from].balance - 1];
		info.users[_from].list[_index] = _moved;
		info.users[_from].indexOf[_moved] = _index + 1;
		info.users[_from].balance--;
		delete info.users[_from].indexOf[_tokenId];
		uint256 _newIndex = info.users[_to].balance++;
		info.users[_to].indexOf[_tokenId] = _newIndex + 1;
		info.users[_to].list[_newIndex] = _tokenId;
		emit Transfer(_from, _to, _tokenId);
	}

	function _update(address _owner) internal {
		uint256 _last = info.users[_owner].lastUpdated;
		if (_last < block.timestamp) {
			uint256 _diff = block.timestamp - _last;
			uint256 _rewards = ownerWsdmPerDay(_owner) * _diff / 86400;
			uint256 _bullsCut = _rewards * BULLS_CUT / 100;
			info.scaledRewardsPerBull += _bullsCut * FLOAT_SCALAR / totalBulls();
			emit BullsReward(_bullsCut);
			info.users[_owner].lastUpdated = block.timestamp;
			info.users[_owner].rewards += _rewards - _bullsCut;
			emit Reward(_owner, _rewards - _bullsCut);
		}
	}


	function _verify(bytes32[] memory _proof, bytes32 _leaf) internal view returns (bool) {
		require(_leaf != merkleRoot());
		bytes32 _computedHash = _leaf;
		for (uint256 i = 0; i < _proof.length; i++) {
			bytes32 _proofElement = _proof[i];
			if (_computedHash <= _proofElement) {
				_computedHash = keccak256(abi.encodePacked(_computedHash, _proofElement));
			} else {
				_computedHash = keccak256(abi.encodePacked(_proofElement, _computedHash));
			}
		}
		return _computedHash == merkleRoot();
	}
}