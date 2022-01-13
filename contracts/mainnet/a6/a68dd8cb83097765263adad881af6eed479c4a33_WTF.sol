// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./WTFNFT.sol";
import "./Treasury.sol";
import "./StakingRewards.sol";

interface Callable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
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


contract WTF {

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private UINT_MAX = type(uint256).max;
	uint256 constant private TRANSFER_FEE_SCALE = 1000; // 1 = 0.1%
	uint256 constant private WTF_STAKING_SUPPLY = 2e25; // 20M WTF
	uint256 constant private LP_STAKING_SUPPLY = 4e25; // 40M WTF
	uint256 constant private TREASURY_SUPPLY = 4e25; // 40M WTF
	uint256 constant private BASE_UPGRADE_COST = 1e19; // 10 WTF
	uint256 constant private SERVICE_FEE = 0.01 ether;

	string constant public name = "fees.wtf";
	string constant public symbol = "WTF";
	uint8 constant public decimals = 18;

	struct User {
		uint256 balance;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
		uint256 reflinkLevel;
		bool unlocked;
	}

	struct Info {
		bytes32 merkleRoot;
		uint256 openingTime;
		uint256 closingTime;
		uint256 totalSupply;
		uint256 scaledRewardsPerToken;
		mapping(uint256 => uint256) claimedWTFBitMap;
		mapping(uint256 => uint256) claimedNFTBitMap;
		mapping(address => User) users;
		mapping(address => bool) toWhitelist;
		mapping(address => bool) fromWhitelist;
		address owner;
		Router router;
		Pair pair;
		bool weth0;
		WTFNFT nft;
		TeamReferral team;
		Treasury treasury;
		StakingRewards stakingRewards;
		StakingRewards lpStakingRewards;
		address feeManager;
		uint256 transferFee;
		uint256 feeManagerPercent;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event WhitelistUpdated(address indexed user, bool fromWhitelisted, bool toWhitelisted);
	event ReflinkRewards(address indexed referrer, uint256 amount);
	event ClaimRewards(address indexed user, uint256 amount);
	event Reward(uint256 amount);

	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor(bytes32 _merkleRoot, uint256 _openingTime, uint256 _stakingRewardsStart) {
		info.merkleRoot = _merkleRoot;
		info.openingTime = block.timestamp < _openingTime ? _openingTime : block.timestamp;
		info.closingTime = openingTime() + 30 days;
		info.router = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		info.pair = Pair(Factory(info.router.factory()).createPair(info.router.WETH(), address(this)));
		info.weth0 = info.pair.token0() == info.router.WETH();
		info.transferFee = 40; // 4%
		info.feeManagerPercent = 25; // 25%
		info.owner = 0x65dd4990719bE9B20322e4E8D3Bd77a4401a0357;
		info.nft = new WTFNFT();
		info.team = new TeamReferral();
		info.treasury = new Treasury();
		_mint(treasuryAddress(), TREASURY_SUPPLY);
		info.stakingRewards = new StakingRewards(WTF_STAKING_SUPPLY, _stakingRewardsStart, ERC20(address(this)));
		_mint(stakingRewardsAddress(), WTF_STAKING_SUPPLY);
		info.lpStakingRewards = new StakingRewards(LP_STAKING_SUPPLY, _stakingRewardsStart, ERC20(pairAddress()));
		_mint(lpStakingRewardsAddress(), LP_STAKING_SUPPLY);
		info.feeManager = address(new FeeManager());
		_approve(feeManagerAddress(), stakingRewardsAddress(), UINT_MAX);
		_approve(feeManagerAddress(), lpStakingRewardsAddress(), UINT_MAX);
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setFeeManager(address _feeManager) external _onlyOwner {
		info.feeManager = _feeManager;
	}

	function setClosingTime(uint256 _closingTime) external _onlyOwner {
		info.closingTime = _closingTime;
	}

	function setTransferFee(uint256 _transferFee) external _onlyOwner {
		require(_transferFee <= 100); // ≤10%
		info.transferFee = _transferFee;
	}

	function setFeeManagerPercent(uint256 _feeManagerPercent) external _onlyOwner {
		require(_feeManagerPercent <= 100);
		info.feeManagerPercent = _feeManagerPercent;
	}

	function setWhitelisted(address _address, bool _fromWhitelisted, bool _toWhitelisted) external _onlyOwner {
		info.fromWhitelist[_address] = _fromWhitelisted;
		info.toWhitelist[_address] = _toWhitelisted;
		emit WhitelistUpdated(_address, _fromWhitelisted, _toWhitelisted);
	}


	function disburse(uint256 _amount) external {
		require(_amount > 0);
		uint256 _balanceBefore = balanceOf(address(this));
		_transfer(msg.sender, address(this), _amount);
		uint256 _amountReceived = balanceOf(address(this)) - _balanceBefore;
		_disburse(_amountReceived);
	}

	function sweep() external {
		if (address(this).balance > 0) {
			teamAddress().transfer(address(this).balance);
		}
	}

	function upgradeReflink(uint256 _toLevel) external {
		uint256 _currentLevel = reflinkLevel(msg.sender);
		require(_currentLevel < _toLevel);
		uint256 _totalCost = 0;
		for (uint256 i = _currentLevel; i < _toLevel; i++) {
			_totalCost += upgradeCost(i);
		}
		burn(_totalCost);
		info.users[msg.sender].reflinkLevel = _toLevel;
	}

	function unlock(address _account, address payable _referrer) external payable {
		require(block.timestamp < closingTime());
		require(!isUnlocked(_account));
		require(msg.value == SERVICE_FEE);
		uint256 _refFee = 0;
		if (_referrer != address(0x0)) {
			_refFee = SERVICE_FEE * reflinkPercent(_referrer) / 100;
			!_referrer.send(_refFee);
			emit ReflinkRewards(_referrer, _refFee);
		}
		uint256 _remaining = SERVICE_FEE - _refFee;
		teamAddress().transfer(_remaining);
		emit ReflinkRewards(teamAddress(), _remaining);
		info.users[_account].unlocked = true;
	}
	
	function claim(address _account, uint256[9] calldata _data, bytes32[] calldata _proof) external {
		// Data array in format: (index, amount, totalFees, failFees, totalGas, avgGwei, totalDonated, totalTxs, failTxs)
		claimWTF(_account, _data, _proof);
		claimNFT(_account, _data, _proof);
	}
	
	function claimWTF(address _account, uint256[9] calldata _data, bytes32[] calldata _proof) public {
		require(isOpen());
		require(isUnlocked(_account));
		uint256 _index = _data[0];
		uint256 _amount = _data[1];
		require(!isClaimedWTF(_index));
		require(_verify(_proof, keccak256(abi.encodePacked(_account, _data))));
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		info.claimedWTFBitMap[_claimedWordIndex] = info.claimedWTFBitMap[_claimedWordIndex] | (1 << _claimedBitIndex);
		_mint(_account, _amount);
	}

	function claimNFT(address _account, uint256[9] calldata _data, bytes32[] calldata _proof) public {
		require(isOpen());
		require(isUnlocked(_account));
		uint256 _index = _data[0];
		require(!isClaimedNFT(_index));
		require(_verify(_proof, keccak256(abi.encodePacked(_account, _data))));
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		info.claimedNFTBitMap[_claimedWordIndex] = info.claimedNFTBitMap[_claimedWordIndex] | (1 << _claimedBitIndex);
		info.nft.mint(_account, _data[2], _data[3], _data[4], _data[5], _data[6], _data[7], _data[8]);
	}

	function claimRewards() external {
		boostRewards();
		uint256 _rewards = rewardsOf(msg.sender);
		if (_rewards > 0) {
			info.users[msg.sender].scaledPayout += int256(_rewards * FLOAT_SCALAR);
			_transfer(address(this), msg.sender, _rewards);
			emit ClaimRewards(msg.sender, _rewards);
		}
	}

	function boostRewards() public {
		address _this = address(this);
		uint256 _rewards = rewardsOf(_this);
		if (_rewards > 0) {
			info.users[_this].scaledPayout += int256(_rewards * FLOAT_SCALAR);
			_disburse(_rewards);
			emit ClaimRewards(_this, _rewards);
		}
	}

	function burn(uint256 _tokens) public {
		require(balanceOf(msg.sender) >= _tokens);
		info.totalSupply -= _tokens;
		info.users[msg.sender].balance -= _tokens;
		info.users[msg.sender].scaledPayout -= int256(_tokens * info.scaledRewardsPerToken);
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
	

	function pairAddress() public view returns (address) {
		return address(info.pair);
	}

	function nftAddress() external view returns (address) {
		return address(info.nft);
	}

	function teamAddress() public view returns (address payable) {
		return payable(address(info.team));
	}

	function treasuryAddress() public view returns (address) {
		return address(info.treasury);
	}

	function stakingRewardsAddress() public view returns (address) {
		return address(info.stakingRewards);
	}

	function lpStakingRewardsAddress() public view returns (address) {
		return address(info.lpStakingRewards);
	}

	function feeManagerAddress() public view returns (address) {
		return info.feeManager;
	}

	function owner() public view returns (address) {
		return info.owner;
	}

	function transferFee() public view returns (uint256) {
		return info.transferFee;
	}

	function feeManagerPercent() public view returns (uint256) {
		return info.feeManagerPercent;
	}

	function isFromWhitelisted(address _address) public view returns (bool) {
		return info.fromWhitelist[_address];
	}

	function isToWhitelisted(address _address) public view returns (bool) {
		return info.toWhitelist[_address];
	}

	function merkleRoot() public view returns (bytes32) {
		return info.merkleRoot;
	}

	function openingTime() public view returns (uint256) {
		return info.openingTime;
	}

	function closingTime() public view returns (uint256) {
		return info.closingTime;
	}

	function isOpen() public view returns (bool) {
		return block.timestamp > openingTime() && block.timestamp < closingTime();
	}

	function isUnlocked(address _user) public view returns (bool) {
		return info.users[_user].unlocked;
	}

	function isClaimedWTF(uint256 _index) public view returns (bool) {
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		uint256 _claimedWord = info.claimedWTFBitMap[_claimedWordIndex];
		uint256 _mask = (1 << _claimedBitIndex);
		return _claimedWord & _mask == _mask;
	}

	function isClaimedNFT(uint256 _index) public view returns (bool) {
		uint256 _claimedWordIndex = _index / 256;
		uint256 _claimedBitIndex = _index % 256;
		uint256 _claimedWord = info.claimedNFTBitMap[_claimedWordIndex];
		uint256 _mask = (1 << _claimedBitIndex);
		return _claimedWord & _mask == _mask;
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

	function reflinkLevel(address _user) public view returns (uint256) {
		return info.users[_user].reflinkLevel;
	}

	function reflinkPercent(address _user) public view returns (uint256) {
		return 10 * (reflinkLevel(_user) + 1);
	}

	function upgradeCost(uint256 _reflinkLevel) public pure returns (uint256) {
		require(_reflinkLevel < 4);
		return BASE_UPGRADE_COST * 10**_reflinkLevel;
	}

	function reflinkInfoFor(address _user) external view returns (uint256 balance, uint256 level, uint256 percent) {
		return (balanceOf(_user), reflinkLevel(_user), reflinkPercent(_user));
	}

	function claimInfoFor(uint256 _index, address _user) external view returns (uint256 openTime, uint256 closeTime, bool unlocked, bool claimedWTF, bool claimedNFT, uint256 wethReserve, uint256 wtfReserve) {
		openTime = openingTime();
		closeTime = closingTime();
		unlocked = isUnlocked(_user);
		claimedWTF = isClaimedWTF(_index);
		claimedNFT = isClaimedNFT(_index);
		( , , wethReserve, wtfReserve, , , ) = allInfoFor(address(0x0));
	}

	function allInfoFor(address _user) public view returns (uint256 totalTokens, uint256 totalLPTokens, uint256 wethReserve, uint256 wtfReserve, uint256 userBalance, uint256 userRewards, uint256 userLPBalance) {
		totalTokens = totalSupply();
		totalLPTokens = info.pair.totalSupply();
		(uint256 _res0, uint256 _res1, ) = info.pair.getReserves();
		wethReserve = info.weth0 ? _res0 : _res1;
		wtfReserve = info.weth0 ? _res1 : _res0;
		userBalance = balanceOf(_user);
		userRewards = rewardsOf(_user);
		userLPBalance = info.pair.balanceOf(_user);
	}


	function _mint(address _account, uint256 _amount) internal {
		info.totalSupply += _amount;
		info.users[_account].balance += _amount;
		info.users[_account].scaledPayout += int256(_amount * info.scaledRewardsPerToken);
		emit Transfer(address(0x0), _account, _amount);
	}
	
	function _approve(address _owner, address _spender, uint256 _tokens) internal returns (bool) {
		info.users[_owner].allowance[_spender] = _tokens;
		emit Approval(_owner, _spender, _tokens);
		return true;
	}
	
	function _transfer(address _from, address _to, uint256 _tokens) internal returns (bool) {
		require(balanceOf(_from) >= _tokens);
		info.users[_from].balance -= _tokens;
		info.users[_from].scaledPayout -= int256(_tokens * info.scaledRewardsPerToken);
		uint256 _fee = 0;
		if (!_isExcludedFromFee(_from, _to)) {
			_fee = _tokens * transferFee() / TRANSFER_FEE_SCALE;
			address _this = address(this);
			info.users[_this].balance += _fee;
			info.users[_this].scaledPayout += int256(_fee * info.scaledRewardsPerToken);
			emit Transfer(_from, _this, _fee);
		}
		uint256 _transferred = _tokens - _fee;
		info.users[_to].balance += _transferred;
		info.users[_to].scaledPayout += int256(_transferred * info.scaledRewardsPerToken);
		emit Transfer(_from, _to, _transferred);
		if (_fee > 0) {
			uint256 _feeManagerRewards = _fee * feeManagerPercent() / 100;
			info.users[feeManagerAddress()].scaledPayout -= int256(_feeManagerRewards * FLOAT_SCALAR);
			_disburse(_fee - _feeManagerRewards);
		}
		return true;
	}

	function _disburse(uint256 _amount) internal {
		if (_amount > 0) {
			info.scaledRewardsPerToken += _amount * FLOAT_SCALAR / totalSupply();
			emit Reward(_amount);
		}
	}


	function _isExcludedFromFee(address _from, address _to) internal view returns (bool) {
		return isFromWhitelisted(_from) || isToWhitelisted(_to)
			|| _from == address(this) || _to == address(this)
			|| _from == feeManagerAddress() || _to == feeManagerAddress()
			|| _from == treasuryAddress() || _to == treasuryAddress()
			|| _from == stakingRewardsAddress() || _to == stakingRewardsAddress()
			|| _from == lpStakingRewardsAddress() || _to == lpStakingRewardsAddress();
	}
	
	function _verify(bytes32[] memory _proof, bytes32 _leaf) internal view returns (bool) {
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