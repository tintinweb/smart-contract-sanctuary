/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

interface Bridge {
	function depositFor(address _user, address _rootToken, bytes calldata _depositData) external;
}

interface Router {
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
}

interface Factory {
	function createPair(address, address) external returns (address);
}

interface Pair {
	function token0() external view returns (address);
	function totalSupply() external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface WhalesGame {
	function krillAddress() external view returns (address);
	function stakingRewardsAddress() external view returns (address);
	function getIsWhale(uint256) external view returns (bool);
	function balanceOf(address) external view returns (uint256);
	function ownerOf(uint256) external view returns (address);
	function fishermenOf(address) external view returns (uint256);
	function whalesOf(address) external view returns (uint256);
	function isApprovedForAll(address, address) external view returns (bool);
	function transferFrom(address, address, uint256) external;
	function claim() external;
}

interface KRILL {
	function allowance(address, address) external view returns (uint256);
	function balanceOf(address) external view returns (uint256);
	function approve(address, uint256) external returns (bool);
	function transfer(address, uint256) external returns (bool);
	function transferFrom(address, address, uint256) external returns (bool);
	function burn(uint256) external;
}

contract WrappedToken {

	uint256 constant private UINT_MAX = type(uint256).max;
	uint256 constant private FLOAT_SCALAR = 2**64;
	address constant private POLYGON_ERC20_BRIDGE = 0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf;

	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalSupply;
		uint256 scaledRewardsPerToken;
		uint256 pendingRewards;
		mapping(address => User) users;
		mapping(address => bool) rewardBurn;
		address burnDestination;
		address owner;
		bool isBridged;
		Bridge bridge;
		Router router;
		Pair pair;
		bool weth0;
		bool isWhale;
		WhalesGame wg;
		KRILL krill;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Claim(address indexed user, uint256 amount);
	event Reward(uint256 amount);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor(WhalesGame _wg, bool _isWhale) {
		info.isBridged = false;
		info.bridge = Bridge(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
		info.router = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		info.pair = Pair(Factory(info.router.factory()).createPair(info.router.WETH(), address(this)));
		info.weth0 = info.pair.token0() == info.router.WETH();
		info.wg = _wg;
		info.krill = KRILL(_wg.krillAddress());
		info.isWhale = _isWhale;
		info.owner = tx.origin;
		info.rewardBurn[address(this)] = true;
		info.rewardBurn[pairAddress()] = true;
		info.rewardBurn[POLYGON_ERC20_BRIDGE] = true;
		info.krill.approve(POLYGON_ERC20_BRIDGE, UINT_MAX);
		info.burnDestination = address(0x0);
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setIsBridged(bool _isBridged) external _onlyOwner {
		info.isBridged = _isBridged;
	}

	function setRewardBurn(address _user, bool _shouldBurn) external _onlyOwner {
		uint32 _size;
		assembly {
			_size := extcodesize(_user)
		}
		require(_size > 0);
		info.rewardBurn[_user] = _shouldBurn;
	}

	function setBurnDestination(address _destination) external _onlyOwner {
		info.burnDestination = _destination;
	}


	function disburse(uint256 _amount) external {
		if (_amount > 0) {
			address _this = address(this);
			uint256 _balanceBefore = info.krill.balanceOf(_this);
			info.krill.transferFrom(msg.sender, _this, _amount);
			_disburse(info.krill.balanceOf(_this) - _balanceBefore);
		}
	}

	function wrap(uint256[] calldata _tokenIds) external {
		uint256 _count = _tokenIds.length;
		require(_count > 0);
		_update();
		for (uint256 i = 0; i < _count; i++) {
			require(info.wg.getIsWhale(_tokenIds[i]) == info.isWhale);
			info.wg.transferFrom(msg.sender, address(this), _tokenIds[i]);
		}
		uint256 _amount = _count * 1e18;
		info.totalSupply += _amount;
		info.users[msg.sender].balance += _amount;
		info.users[msg.sender].scaledPayout += int256(_amount * info.scaledRewardsPerToken);
		emit Transfer(address(0x0), msg.sender, _amount);
	}

	function unwrap(uint256[] calldata _tokenIds) external returns (uint256 totalUnwrapped) {
		uint256 _count = _tokenIds.length;
		require(balanceOf(msg.sender) >= _count * 1e18);
		_update();
		totalUnwrapped = 0;
		for (uint256 i = 0; i < _count; i++) {
			if (info.wg.ownerOf(_tokenIds[i]) == address(this)) {
				require(info.wg.getIsWhale(_tokenIds[i]) == info.isWhale);
				info.wg.transferFrom(address(this), msg.sender, _tokenIds[i]);
				totalUnwrapped++;
			}
		}
		require(totalUnwrapped > 0);
		uint256 _cost = totalUnwrapped * 1e18;
		info.totalSupply -= _cost;
		info.users[msg.sender].balance -= _cost;
		info.users[msg.sender].scaledPayout -= int256(_cost * info.scaledRewardsPerToken);
		emit Transfer(msg.sender, address(0x0), _cost);
	}

	function claim() external {
		claimFor(msg.sender);
	}

	function claimFor(address _user) public {
		_update();
		uint256 _rewards = rewardsOf(_user);
		if (_rewards > 0) {
			info.users[_user].scaledPayout += int256(_rewards * FLOAT_SCALAR);
			if (rewardBurn(_user)) {
				address _destination = burnDestination();
				if (_destination == address(0x0)) {
					info.krill.burn(_rewards);
				} else {
					if (isBridged()) {
						info.bridge.depositFor(_destination, address(info.krill), abi.encodePacked(_rewards));
					} else {
						info.krill.transfer(_destination, _rewards);
					}
				}
			} else {
				info.krill.transfer(_user, _rewards);
			}
			emit Claim(_user, _rewards);
		}
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
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
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}
	

	function name() external view returns (string memory) {
		return info.isWhale ? 'Wrapped Whales' : 'Wrapped Fishermen';
	}

	function symbol() external view returns (string memory) {
		return info.isWhale ? 'wWH' : 'wFM';
	}
	
	function owner() public view returns (address) {
		return info.owner;
	}
	
	function isBridged() public view returns (bool) {
		return info.isBridged;
	}
	
	function burnDestination() public view returns (address) {
		return info.burnDestination;
	}
	
	function rewardBurn(address _user) public view returns (bool) {
		return info.rewardBurn[_user];
	}
	
	function pairAddress() public view returns (address) {
		return address(info.pair);
	}
	
	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}
	
	function rewardsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledRewardsPerToken * balanceOf(_user)) - info.users[_user].scaledPayout) / FLOAT_SCALAR;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) external view returns (uint256 totalTokens, uint256 totalLPTokens, uint256 wethReserve, uint256 wrappedReserve, uint256 userTokens, bool userApproved, uint256 userBalance, uint256 userRewards, uint256 userLPBalance, uint256 contractFishermen, uint256 contractWhales) {
		totalTokens = totalSupply();
		totalLPTokens = info.pair.totalSupply();
		(uint256 _res0, uint256 _res1, ) = info.pair.getReserves();
		wethReserve = info.weth0 ? _res0 : _res1;
		wrappedReserve = info.weth0 ? _res1 : _res0;
		userTokens = info.wg.balanceOf(_user);
		userApproved = info.wg.isApprovedForAll(_user, address(this));
		userBalance = balanceOf(_user);
		userRewards = rewardsOf(_user);
		userLPBalance = info.pair.balanceOf(_user);
		contractFishermen = info.wg.fishermenOf(address(this));
		contractWhales = info.wg.whalesOf(address(this));
	}


	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		require(balanceOf(_from) >= _tokens);
		_update();
		info.users[_from].balance -= _tokens;
		info.users[_from].scaledPayout -= int256(_tokens * info.scaledRewardsPerToken);
		info.users[_to].balance += _tokens;
		info.users[_to].scaledPayout += int256(_tokens * info.scaledRewardsPerToken);
		emit Transfer(_from, _to, _tokens);
		return true;
	}

	function _update() internal {
		address _this = address(this);
		uint256 _balanceBefore = info.krill.balanceOf(_this);
		info.wg.claim();
		_disburse(info.krill.balanceOf(_this) - _balanceBefore);
	}

	function _disburse(uint256 _amount) internal {
		if (_amount > 0) {
			if (totalSupply() == 0) {
				info.pendingRewards += _amount;
			} else {
				info.scaledRewardsPerToken += (_amount + info.pendingRewards) * FLOAT_SCALAR / totalSupply();
				info.pendingRewards = 0;
			}
			emit Reward(_amount);
		}
	}
}

contract Islands {

	uint256 constant private UINT_MAX = type(uint256).max;
	uint256 constant private POLYGON_ISLANDS = 1000;
	uint256 constant private MINTABLE_ISLANDS = 1000;
	uint256 constant private MAX_ISLANDS = POLYGON_ISLANDS + MINTABLE_ISLANDS; // 2k
	uint256 constant private BASE_KRILL_COST = 1e23; // 100k
	uint256 constant private KRILL_COST_INCREMENT = 2e21; // 2k

	string constant public name = "Whales Game Islands";
	string constant public symbol = "ISLAND";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
	}

	struct Info {
		uint256 totalSupply;
		mapping(address => User) users;
		Router router;
		Pair pair;
		WhalesGame wg;
		KRILL krill;
		WrappedToken wfm;
		WrappedToken wwh;
		address owner;
		address feeRecipient;
		bool weth0;
		uint256 openingTime;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor(WhalesGame _wg, address _booster, uint256 _openingTime) {
		info.router = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		info.pair = Pair(Factory(info.router.factory()).createPair(info.router.WETH(), address(this)));
		info.weth0 = info.pair.token0() == info.router.WETH();
		info.wg = _wg;
		info.krill = KRILL(_wg.krillAddress());
		info.wfm = new WrappedToken(_wg, false);
		info.wwh = new WrappedToken(_wg, true);
		info.owner = msg.sender;
		info.feeRecipient = _booster;
		info.openingTime = _openingTime;

		uint256 _polygonIslands = POLYGON_ISLANDS * 1e18;
		info.totalSupply = _polygonIslands;
		info.users[msg.sender].balance = _polygonIslands;
		emit Transfer(address(0x0), msg.sender, _polygonIslands);
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setFeeRecipient(address _feeRecipient) external _onlyOwner {
		info.feeRecipient = _feeRecipient;
	}

	function buyIsland(uint256[4] memory _fishermenIds, uint256 _whaleId) external {
		require(block.timestamp >= info.openingTime);
		require(totalIslands() < MAX_ISLANDS);
		require(info.wg.getIsWhale(_whaleId));
		info.wg.transferFrom(msg.sender, wrappedWhalesAddress(), _whaleId);
		require(!info.wg.getIsWhale(_fishermenIds[0]));
		info.wg.transferFrom(msg.sender, wrappedFishermenAddress(), _fishermenIds[0]);
		require(!info.wg.getIsWhale(_fishermenIds[1]));
		info.wg.transferFrom(msg.sender, info.wg.stakingRewardsAddress(), _fishermenIds[1]);
		require(!info.wg.getIsWhale(_fishermenIds[2]));
		info.wg.transferFrom(msg.sender, info.wg.stakingRewardsAddress(), _fishermenIds[2]);
		require(!info.wg.getIsWhale(_fishermenIds[3]));
		info.wg.transferFrom(msg.sender, feeRecipient(), _fishermenIds[3]);
		info.krill.transferFrom(msg.sender, feeRecipient(), currentKrillCost());

		info.totalSupply += 1e18;
		info.users[msg.sender].balance += 1e18;
		emit Transfer(address(0x0), msg.sender, 1e18);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		return _transfer(msg.sender, _to, _tokens);
	}

	function approve(address _spender, uint256 _tokens) external returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
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
		_transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Callable(_to).tokenCallback(msg.sender, _tokens, _data));
		}
		return true;
	}
	
	
	function whalesGameAddress() external view returns (address) {
		return address(info.wg);
	}

	function wrappedFishermenAddress() public view returns (address) {
		return address(info.wfm);
	}

	function wrappedWhalesAddress() public view returns (address) {
		return address(info.wwh);
	}

	function owner() public view returns (address) {
		return info.owner;
	}

	function feeRecipient() public view returns (address) {
		return info.feeRecipient;
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function totalIslands() public view returns (uint256) {
		return totalSupply() / 1e18;
	}

	function currentKrillCost() public view returns (uint256) {
		return BASE_KRILL_COST + (totalIslands() - POLYGON_ISLANDS) * KRILL_COST_INCREMENT;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance;
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function allInfoFor(address _user) external view returns (uint256 openingTime, uint256 totalTokens, uint256 totalLPTokens, uint256 wethReserve, uint256 islandReserve, uint256 userTokens, bool userApproved, uint256 userAllowance, uint256 userKRILL, uint256 userBalance, uint256 userLPBalance) {
		openingTime = info.openingTime;
		totalTokens = totalSupply();
		totalLPTokens = info.pair.totalSupply();
		(uint256 _res0, uint256 _res1, ) = info.pair.getReserves();
		wethReserve = info.weth0 ? _res0 : _res1;
		islandReserve = info.weth0 ? _res1 : _res0;
		userTokens = info.wg.balanceOf(_user);
		userApproved = info.wg.isApprovedForAll(_user, address(this));
		userAllowance = info.krill.allowance(_user, address(this));
		userKRILL = info.krill.balanceOf(_user);
		userBalance = balanceOf(_user);
		userLPBalance = info.pair.balanceOf(_user);
	}


	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		info.users[_to].balance += _tokens;
		emit Transfer(_from, _to, _tokens);
		return true;
	}
}