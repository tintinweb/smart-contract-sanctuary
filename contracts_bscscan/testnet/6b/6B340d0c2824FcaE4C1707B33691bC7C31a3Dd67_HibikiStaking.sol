/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

struct Shoujo {
	uint16 nameIndex;
	uint16 surnameIndex;
	uint8 rarity;
	uint8 personality;
	uint8 cuteness;
	uint8 lewd;
	uint8 intelligence;
	uint8 aggressiveness;
	uint8 talkative;
	uint8 depression;
	uint8 genki;
	uint8 raburabu;
	uint8 boyish;
}

interface IShoujoStats {
	function tokenStatsByIndex(uint256 id) external view returns(Shoujo memory);
}

interface ICryptoShoujo {
	function ownerOf(uint256 tokenId) external view returns (address);
	function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract HibikiStaking is Auth {

    struct Stake {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address public stakingToken;
    address public rewardToken;
	address public cryptoShoujo;
	address public shoujoStats;

    uint256 public totalRealised;
    uint256 public totalStaked;

    mapping (address => Stake) public stakes;
	mapping (uint256 => address) nftIdToStaker;

	uint256 public baseValueForNft;

	event Realised(address account, uint amount);
    event Staked(address account, uint amount);
    event Unstaked(address account, uint amount);

    constructor (address _stakingToken, address _rewardToken, address _cs, address _shoujoStats) Auth(msg.sender) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
		cryptoShoujo = _cs;
		shoujoStats = _shoujoStats;
		baseValueForNft = 5 ether;
    }

    uint256 _accuracyFactor = 10 ** 36;
    uint256 _rewardsPerLP;
    uint256 _lastContractBalance;

    function getTotalRewards() external view  returns (uint256) {
        return totalRealised + IBEP20(rewardToken).balanceOf(address(this));
    }

    function getCumulativeRewardsPerLP() external view returns (uint256) {
        return _rewardsPerLP;
    }

    function getLastContractBalance() external view returns (uint256) {
        return _lastContractBalance;
    }

    function getAccuracyFactor() external view returns (uint256) {
        return _accuracyFactor;
    }

    function getStake(address account) public view returns (uint256) {
        return stakes[account].amount;
    }

    function getRealisedEarnings(address staker) external view returns (uint256) {
        return stakes[staker].totalRealised; // realised gains plus outstanding earnings
    }

    function getUnrealisedEarnings(address staker) external view returns (uint256) {
        if(stakes[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewards = stakes[staker].amount * getCurrentRewardsPerLP() / _accuracyFactor;
        uint256 stakerTotalExcluded = stakes[staker].totalExcluded;

        if (stakerTotalRewards <= stakerTotalExcluded) {
			return 0;
		}

        return stakerTotalRewards - stakerTotalExcluded;
    }

    function getCumulativeRewards(uint256 amount) public view returns (uint256) {
        return amount * _rewardsPerLP / _accuracyFactor;
    }

    function stake(uint amount) external {
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    function stakeFor(address staker, uint256 amount) external {
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(staker, amount);
    }

    function stakeAll() external {
        uint256 amount = IBEP20(stakingToken).balanceOf(msg.sender);
        require(amount > 0);

        IBEP20(stakingToken).transferFrom(msg.sender, address(this), amount);

        _stake(msg.sender, amount);
    }

    function unstake(uint amount) external {
        require(amount > 0);

        _unstake(msg.sender, amount);
    }

    function unstakeAll() external {
        uint256 amount = getStake(msg.sender);
        require(amount > 0);

        _unstake(msg.sender, amount);
    }

    function realise() external {
        _realise(msg.sender);
    }

    function _realise(address staker) internal {
        _updateRewards();

        uint amount = earnt(staker);

        if (getStake(staker) == 0 || amount == 0) {
            return;
        }

        stakes[staker].totalRealised += amount;
        stakes[staker].totalExcluded += amount;
        totalRealised += amount;

        IBEP20(rewardToken).transfer(staker, amount);

        _updateRewards();

        emit Realised(staker, amount);
    }

    function earnt(address staker) internal view returns (uint256) {
        if(stakes[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewards = getCumulativeRewards(stakes[staker].amount);
        uint256 stakerTotalExcluded = stakes[staker].totalExcluded;

        if(stakerTotalRewards <= stakerTotalExcluded){ return 0; }

        return stakerTotalRewards - stakerTotalExcluded;
    }

    function _stake(address staker, uint256 amount) internal {
        require(amount > 0);

        _realise(staker);

        // add to current address' stake
        stakes[staker].amount += amount;
        stakes[staker].totalExcluded = getCumulativeRewards(stakes[staker].amount);
        totalStaked += amount;

        emit Staked(staker, amount);
    }

    function _unstake(address staker, uint256 amount) internal {
        require(stakes[staker].amount >= amount, "Insufficient Stake");

        _realise(staker); // realise staking gains

        // remove stake
        stakes[staker].amount -= amount;
        stakes[staker].totalExcluded = getCumulativeRewards(stakes[staker].amount);
        totalStaked -= amount;

        IBEP20(stakingToken).transfer(staker, amount);

        emit Unstaked(staker, amount);
    }

    function _updateRewards() internal  {
        uint tokenBalance = IBEP20(rewardToken).balanceOf(address(this));

        if (tokenBalance > _lastContractBalance && totalStaked != 0) {
            uint256 newRewards = tokenBalance - _lastContractBalance;
            uint256 additionalAmountPerLP = newRewards * _accuracyFactor / totalStaked;
            _rewardsPerLP += additionalAmountPerLP;
        }

        if (totalStaked > 0) {
			_lastContractBalance = tokenBalance;
		}
    }

    function getCurrentRewardsPerLP() public view returns (uint256 currentRewardsPerLP) {
        uint tokenBalance = IBEP20(rewardToken).balanceOf(address(this));
        if(tokenBalance > _lastContractBalance && totalStaked != 0){
            uint256 newRewards = tokenBalance - _lastContractBalance;
            uint256 additionalAmountPerLP = newRewards* _accuracyFactor / totalStaked;
            currentRewardsPerLP = _rewardsPerLP + additionalAmountPerLP;
        }
    }

    function setAccuracyFactor(uint256 newFactor) external authorized {
        _rewardsPerLP = _rewardsPerLP * newFactor / _accuracyFactor;
        _accuracyFactor = newFactor;
    }

    function emergencyUnstakeAll() external {
        require(stakes[msg.sender].amount > 0, "No Stake");

        IBEP20(stakingToken).transfer(msg.sender, stakes[msg.sender].amount);
        totalStaked -= stakes[msg.sender].amount;
        stakes[msg.sender].amount = 0;
    }

    function migrateStakingToken(address newToken) external authorized {
        IBEP20(newToken).transferFrom(msg.sender, address(this), totalStaked);
        assert(IBEP20(newToken).balanceOf(address(this)) == totalStaked);

        IBEP20(stakingToken).transfer(msg.sender, totalStaked);

        stakingToken = newToken;
    }

	function setBaseValueForNft(uint256 value) external authorized {
		baseValueForNft = value;
	}

	function valueOfNft(uint256 nftId) public view returns(uint256) {
		IShoujoStats stats = IShoujoStats(shoujoStats);
		Shoujo memory stat = stats.tokenStatsByIndex(nftId);
		return (stat.rarity + 1) * baseValueForNft;
	}

	function stakeShoujo(uint256 nftId) external {
		ICryptoShoujo nft = ICryptoShoujo(cryptoShoujo);
		require(nft.ownerOf(nftId) == msg.sender, "NFT must be yours!");
		uint256 amount = valueOfNft(nftId);
		_stake(msg.sender, amount);
		nft.safeTransferFrom(msg.sender, address(this), nftId);
		nftIdToStaker[nftId] = msg.sender;
	}

	function unstakeShoujo(uint256 nftId) external {
		ICryptoShoujo nft = ICryptoShoujo(cryptoShoujo);
		require(nft.ownerOf(nftId) == msg.sender, "NFT must be yours!");
		require(nftIdToStaker[nftId] == msg.sender, "You did not stake this NFT.");
        uint256 amount = valueOfNft(nftId);
        _unstake(msg.sender, amount);
		nft.safeTransferFrom(address(this), msg.sender, nftId);
		delete nftIdToStaker[nftId];
    }

	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) public pure returns (bytes4) {
        return 0x150b7a02;
    }
}