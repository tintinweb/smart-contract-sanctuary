/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

/*

  /$$$$$$                                /$$                               
 /$$__  $$                              | $$                               
| $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$ | $$ /$$   /$$                     
| $$ /$$$$ /$$__  $$ /$$__  $$ /$$__  $$| $$| $$  | $$                     
| $$|_  $$| $$$$$$$$| $$  \ $$| $$  \ $$| $$| $$  | $$                     
| $$  \ $$| $$_____/| $$  | $$| $$  | $$| $$| $$  | $$                     
|  $$$$$$/|  $$$$$$$| $$$$$$$/|  $$$$$$/| $$|  $$$$$$$                     
 \______/  \_______/| $$____/  \______/ |__/ \____  $$                     
                    | $$                     /$$  | $$                     
                    | $$                    |  $$$$$$/                     
                    |__/                     \______/                      
              /$$$$$$   /$$               /$$       /$$                    
             /$$__  $$ | $$              | $$      |__/                    
            | $$  \__//$$$$$$    /$$$$$$ | $$   /$$ /$$ /$$$$$$$   /$$$$$$ 
            |  $$$$$$|_  $$_/   |____  $$| $$  /$$/| $$| $$__  $$ /$$__  $$
             \____  $$ | $$      /$$$$$$$| $$$$$$/ | $$| $$  \ $$| $$  \ $$
             /$$  \ $$ | $$ /$$ /$$__  $$| $$_  $$ | $$| $$  | $$| $$  | $$
            |  $$$$$$/ |  $$$$/|  $$$$$$$| $$ \  $$| $$| $$  | $$|  $$$$$$$
             \______/   \___/   \_______/|__/  \__/|__/|__/  |__/ \____  $$
                                                                  /$$  \ $$
                                                                 |  $$$$$$/
                                                                  \______/ 

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

abstract contract Roles is Ownable {
	/**
	 * @dev keeps a key-value pair for all
	 * the admins
	 */
    mapping(address => bool) private admins;
    
    /**
     * @dev add the owner of the contract to
     * admins
     */
    constructor() {
        addToAdmins(_msgSender());
    }

    /**
     * @dev creates a new admin by adding `_addr` to the 
     * key-value pair as true which will render this address
     * to have supercow powers
     */
    function addToAdmins(address _addr) public onlyOwner {
        admins[_addr] = true;
    }
    /**
     * @dev sets `_addr` to `false` in the mapping which 
     * will render this to not have supercow powers anymore
     */
    function removeFromAdmins(address _addr) public onlyOwner {
        admins[_addr] = false;
    } 
    /**
     * @dev a simple modifer to check if the current caller address 
     * of a any function using this modifier is in the mapping and 
     * is mapped to `true`. basically supercow powers people only area.
     */
    modifier isAdmin() {
        require(admins[_msgSender()], "Roles: This address is not an admin");
        _;
    }
}

interface GEOS20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
	function totalSupply() external view returns (uint256);
	function balanceOf(address wallet) external view returns(uint256);
}

interface IUniswapV2Pair { 
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
	function totalSupply() external view returns (uint);
	function token1() external view returns (address);
}


contract GeoStaking is Roles{

	/**
	 * @dev pools are actually
	 * momentaraly static, timley dyanmic
	 * i.e: `lockTime` & `apy` might change
	 * however, change is only applied
	 * on new stakes not old ones
	 */
	struct Pool {
		// check existance
		bool exists;
		// maximum allowed in the pool
		uint256 maxAllowed;
		// current in the pool
		uint256 currentParticipation;
		// the APY dedicated to return
		uint256[] apy;
		// locktime on the pool
		uint256[] lockTimes;
		// minimum to stake on the pool
		uint256 minAllowed;
		// is an LP
		bool isLP;
		// address of token
		address refTokenAddr;
	}

	/**
	 * @dev each address will get
	 * a structure for their stakes
	 * although not completley effecient
	 * in gas fees, is the best way to 
	 * track all possible stakes
	 */
	struct Stakes {
		// address reference for `ERC20` standard token
		address stakingPool;
		// amount staked by the wallet
		uint256[] amountStaked;
		// the apy at the time of staking
		uint256[] roi;
		// the locktime+block.timestamp at the time of staking
		uint256[] unlockTimes;
	}


	/**
	 * @dev a choice of locking times
	 * between 15 days and 30 days
	 */
	enum LOCKTIME {
		HALF,
		FULL
	}

	mapping(address => mapping(LOCKTIME => uint256)) _APYs;
	mapping(address => mapping(LOCKTIME => uint256)) _LTs;
	


	// to stake tokens you need to pay a small fee
	uint256 public stakingFee = 0.1 ether;

	// all the pool combined in a mapping
	mapping(address => Pool) private _pools;

	/**
	 * @dev this serves so much better than a regular
	 * mapping(address => mapping(address => uint256))
	 * which is the standard for staking. This results in a
	 * configurable staking pools, locktimes, and APY architicture.
	 * any wallet that staked or will stake
	 */
	mapping(address => Stakes[]) private _stakers;

	// keep track of all the fees being paid by the stakers
	uint256 private totalFees;

	// track all rewards
	uint256 private _totalRewards;

	// track all staked
	uint256 private _totalStaked;

	uint256 private _liqOfStake;

	uint256 private _Nexcess;

	function _getLocktime(address pool, LOCKTIME opt) internal view returns(uint256) {
		return(_LTs[pool][opt]);
	}

	// internal transfer `ERC20` standard tokens into the contract for the staking
	function _pullTokens(address sender, address tokenAddr, uint256 tokenAmount) internal returns(bool){
		require(GEOS20(tokenAddr).allowance(sender, address(this)) >= tokenAmount, "You need to approve us to stake your tokens");
		require(GEOS20(tokenAddr).transferFrom(sender, address(this), tokenAmount), "You need to transfer the tokens to stake them");
		return true;
	}

	function getStakes(address staker, address pool) external view returns(Stakes memory _stake){
		require(_poolExists(pool), "pool does not exist");
		for (uint256 i=0; i<_stakers[staker].length; i++){
			if(_stakers[staker][i].stakingPool == pool){
				_stake = _stakers[staker][i];
			}
		}
	}

	// internal transfer `ERC20` standard tokens from the contract into the staker as a payment (original + profit)
	function _pushTokens(address sender, address tokenAddr, uint256 tokenAmount) internal returns(bool){
		require(GEOS20(tokenAddr).balanceOf(address(this)) >= tokenAmount, "Balance of contract less than requested, please wait for next epoch");
		require(GEOS20(tokenAddr).transfer(sender,tokenAmount), "Cannot currently transfer any tokens");
		return true;		
	}

	// internal returns the current timestamp + locktime of the pool
	function _getStakingTS(address pool, LOCKTIME ltopt) internal view returns(uint256){
		uint256 _lt = _LTs[pool][ltopt];
		return((block.timestamp + _lt));
	}

	/**
	 * parameters: {pool address `(ERC20 token)`}  
	 * 
	 * @dev as each staking pool is capped at a maximum 
	 * we can retreive the maximum a wallet can stake
	 * for any particular pool
	 */
	function getMaxAllowed(address pool) public view returns(uint256) {
		require(_pools[pool].exists, "This Pool Does not exist");
		return ((_pools[pool].maxAllowed - _pools[pool].currentParticipation));
	}

	/**
	 * parameters: {pool address `(ERC20 token)`}  
	 * 
	 * @dev get the current staked amount by all wallets 
	 * in one pool, by providing the address of the pool
	 * throws if pool doesn't exist
	 */
	function getCurrentStaked(address pool) public view returns(uint256){
		require(_pools[pool].exists, "this pool does not exist");
		return(_pools[pool].currentParticipation);
	}

	/**
	 * parameters: {pool address `(ERC20 token)`} 
	 * 
	 * @dev get the current Annual Percentage Yeild (APY) of any pool
	 * throws if pool doesn't exist
	 */
	function getStakingReturn(address pool, LOCKTIME lockTime) public view returns(uint256){
		require(_pools[pool].exists, "this pool does not exist");
		uint256 _sr = _APYs[pool][lockTime];
		return(_sr);
	}

	function _canStakeWithCurrentLiquidity(address pool, LOCKTIME ltopt, uint256 amount) internal returns(bool){
		bool _isLP = _isLiquidityPool(pool);
		address _refAddr = _getRefTokenAddr(pool);
		uint256 _tbr = _calcReturn(amount, getStakingReturn(pool, ltopt), _isLP , pool);
		uint256 bal = GEOS20(_refAddr).balanceOf(address(this));
		if(!_isLP){
			_tbr -= amount;
		}
		if((bal >= (_liqOfStake + _tbr))){
			_liqOfStake += _tbr;
			return true;
		}
		return false;
	}

	/**
	 * parameters: pool address (ERC20 token), amountToStake 
	 * 
	 * @dev checks if the current staked amount + the new amountToStake 
	 * is less than or equal to the maximum allowed for the pool in question
	 * 
	 * internal => checks are required beforehand.
	 */
	function _canStakeAmount(address pool, uint256 amount) internal view returns(bool){
		if((getCurrentStaked(pool)+amount <= getMaxAllowed(pool))){
			return true;
		}
	  return false;
	}

	/**
	 * parameters: pool address (ERC20 token)
	 * 
	 * @dev checks if the current address corresponds to a pool
	 */
	function _poolExists(address poolAddr) internal view returns(bool){

		return(_pools[poolAddr].exists);
	}

	/**
	 * parameters: pool address (ERC20 token), amount to convert
	 * 
	 * @dev since each swap provides a different amount of LP tokens
	 * it's safe to consider a general case where we check for the address
	 * of the token either `token0` or `token1` and we calculate the returns
	 * based on the ratio of the input amount * reserve in native token / the total supply to the lp.
	 */
	function _getInGEOSFromLP(address pool, uint256 amount) public view returns(uint256) {
		uint112 _res = 0;
		address _token1 = IUniswapV2Pair(pool).token1();
		uint _totalSupply = IUniswapV2Pair(pool).totalSupply();
		(uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pool).getReserves();
		if (_getRefTokenAddr(pool) == _token1){
			_res = reserve1;
		}else{
			_res = reserve0;
		}
		return(((amount*_res)/_totalSupply));
	}

	/**
	 * parameters: address of staker, address of the pool
	 * 
	 * @dev an intermiedtry function to send the staked tokens + profit back to the
	 * wallet of which it was staked from.
	 * throws if sending the tokens failed.
	 */
	function returnStakes(address staker, address pool) internal returns(bool) {
		(uint256 _total, uint256 _nativeTotal) = totalReturnable(staker, pool);
		require(_total > 0, "Nothing to be returned yet.");
		if(_isLiquidityPool(pool)){
			require(_pushTokens(staker, pool, _nativeTotal), "cannot allocate native pool tokens");
		}
		_Nexcess += _total;
		require(_pushTokens(staker, _getRefTokenAddr(pool), _total), "cannot transfer GEOS20 tokens");
        return true;
	}

	/**
	 * parameters: {amountStake uint256, APY(%) uint256, isAliquidityPoolAddress bool, pool address}, apy at the time of staking
	 * 
	 * @dev calculates via a basic formula (amountStaked*AnnualPY)/12months
	 */
	function _calcReturn(uint256 amount, uint256 annualPercentage, bool isALP, address pool) public view returns(uint256 finalAmount){
		uint256 _offset = 0;
		if(_APYs[pool][LOCKTIME.HALF] == annualPercentage){
			_offset = 24;
		}else{
			_offset = 12;
		}
		if (isALP){
			uint112 _res = 0;
			address _token1 = IUniswapV2Pair(pool).token1();
			uint _totalSupply = IUniswapV2Pair(pool).totalSupply();
			(uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(pool).getReserves();
			if (_getRefTokenAddr(pool) == _token1){
				_res = reserve1;
			}else{
				_res = reserve0;
			}
			finalAmount = ((amount*annualPercentage*_res)/(_offset*100*_totalSupply));
		}else{
			finalAmount = (amount + ((amount*annualPercentage)/(_offset*100)));
		}
	}

	/**
	 * parameters: pool address (ERC20 token), amount to remove
	 * 
	 * @dev removes the staked amount from the currentParticpation
	 * to keep track of the pool current staking
	 * automatically throws if negative on uint256
	 */
	function _removeFromPool(address pool, uint256 amountRemove) internal {

		_pools[pool].currentParticipation -= amountRemove;
	}

	function _removeFromStaker(address staker, address pool) internal returns(bool){
		uint256 currentTS = block.timestamp;
		for(uint256 i=0; i<_stakers[staker].length; i++){
			if(_stakers[staker][i].stakingPool == pool){
				Stakes storage _stake = _stakers[staker][i];
				for(uint256 j=0; j<_stake.unlockTimes.length; j++){
					if(_stake.unlockTimes[j] <= currentTS){
						_removeFromPool(pool, _stake.amountStaked[j]);
						_stake.amountStaked[j] = 0;
						_stake.unlockTimes[j] = 0;
						_stake.roi[j] = 0;
					}
				}
				
			}
		}
		return true;
	}

	
	// checks if a contract address is a liquidity pool or not 
	function _isLiquidityPool(address pool) internal view returns(bool){

		return(_pools[pool].isLP);
	}

	// a simple XNOR gate
	function XNOR(bool A, bool B) internal pure returns(bool){
		if (A && B){
			return true;
		}else if (!A && !B){
			return true;
		}else { return false; }
	}

	// get the reference token address
	function _getRefTokenAddr(address pool) internal view returns(address){

		return (_pools[pool].refTokenAddr);
	}


	/**
	 * parameters: amount Added, current APY, unlocking timestamp
	 * 
	 * @dev forms arrays in which will be added to Stakes[] of the wallet
	 */
    function _formArrays(uint256 amount, uint256 stakingROI, uint256 stakingTS) internal pure returns(uint256[] memory amnts, uint256[] memory stakesROI, uint256[] memory stakesTS){
        amnts = new uint256[](1);
		stakesROI = new uint256[](1);
		stakesTS = new uint256[](1);
		amnts[0] = amount;
        stakesROI[0] = stakingROI;
        stakesTS[0] = stakingTS;
    }

	/**
	 * parameters: sender address, the Stakes index in the array, the amount to add
	 * 
	 * @dev retreives the current Stakes by the address of the sender and access 
	 * the address of the staking pool to retreive information 
	 * adds the variables to their arrays respectivly `amountStaked, unlockTimes, roi`
	 * throws if the amount to stake + current participation is above the max
	 * throws if transfering the tokens of the contract returns false
	 */
	function _addToStaking(address sender, uint256 stakesIdx, LOCKTIME lockTimeOption ,uint256 amount) internal returns(bool) {
		Stakes storage _ogStake = _stakers[sender][stakesIdx];
		address poolAddr = _ogStake.stakingPool;
		require(_pullTokens(sender, poolAddr, amount), "GEOS20: Transfer Failed");
		_ogStake.amountStaked.push(amount);
		_ogStake.unlockTimes.push(_getStakingTS(poolAddr, lockTimeOption));
		_ogStake.roi.push(getStakingReturn(poolAddr, lockTimeOption));
		if(_isLiquidityPool(poolAddr)){
			_totalStaked += _getInGEOSFromLP(poolAddr, amount);
		}else{
			_totalStaked += amount;
		}
		_pools[poolAddr].currentParticipation += amount;
		return true;
	}

    /**
     * parameters: sender address, address of the pool, the amount of staking
     * 
     * @dev creates a new staking for the wallet of the address on the pool specified
     * and appends to the array of Stakes[]
     * throws if the amount to stake + current participation is equal to the max
     */
	function _createNewStaking(address sender, address pool, LOCKTIME lockTimeOption , uint256 amount) internal returns(bool) {
        (uint256[] memory a, uint256[] memory b, uint256[] memory c) = _formArrays(amount, getStakingReturn(pool, lockTimeOption), _getStakingTS(pool, lockTimeOption));
		_stakers[sender].push(Stakes(pool, a, b, c));
		require(_pullTokens(sender, pool, amount), "GEOS20: Transfer Failed");
		if(_isLiquidityPool(pool)){
			_totalStaked += _getInGEOSFromLP(pool, amount);
		}else{
			_totalStaked += amount;
		}
		_pools[pool].currentParticipation += amount;
		return true;
	}

	/**
	 * { address wallet, address pool }
	 * 
	 * @dev returns the total returnable at the current timestamp, returns 0 if no returns aval
	 */
	function totalReturnable(address staker, address pool) public view returns(uint256 total, uint256 nativeTotal) {
		uint256 currentTS = block.timestamp;
		bool _lp = _isLiquidityPool(pool);
		for(uint256 i=0; i<_stakers[staker].length; i++){
			if(_stakers[staker][i].stakingPool == pool){
				Stakes memory _stake = _stakers[staker][i];
				for(uint256 j=0; j<_stake.unlockTimes.length; j++){
					if(_stake.unlockTimes[j] <= currentTS){
						total += _calcReturn(_stake.amountStaked[j], _stake.roi[j], _lp, pool);
						nativeTotal += _stake.amountStaked[j];
					}
				}
				
			}
		}
		return (total, nativeTotal);	
	}

	/**
	 * parameters: address of staker, address of the pool
	 * 
	 * @dev returns the total staked amount of a particular pool specified
	 * by the pool address
	 * throws if pool doesnt exist.
	 */
	function getTotalStakedAmount(address staker, address pool) public view returns(uint256 totalStaked){
		require(_poolExists(pool), "this pool does not exist");
		for(uint256 i=0; i<_stakers[staker].length; i++){
			if(_stakers[staker][i].stakingPool == pool){
				for (uint256 j=0; j<_stakers[staker][i].amountStaked.length; j++){
                    totalStaked += _stakers[staker][i].amountStaked[j];
                }
                break;
			}
		}
	}

	// get the pool properties from address
	function getPoolProps(address pool) external view returns(Pool memory){
		require(_poolExists(pool), "pool doesnt exist");
		return(_pools[pool]);
	}

	/**
	 * parameters: address of the pool, amount to stake
	 * 
	 * @dev external function to stake the tokens specified in _pools
	 * throws if no payment of `StakingFee` to the contract
	 * throws if pool does not exist
	 * throws if the Stake exists and `_addToStaking` returns `false`
	 * throws if the Stake does not exist and _createNewStaking returns `false`
	 */
	function GeoStake(address pool, LOCKTIME lockTimeOption ,uint256 amount) external payable {
		require(_poolExists(pool), "This Staking Pool Does Not Exist");
		require(_canStakeAmount(pool, amount), "Cannot Stake Above the maximum");
		require(_canStakeWithCurrentLiquidity(pool, lockTimeOption ,amount), "No suffiecent liquidity to stake");
		require(msg.value >= stakingFee, "Need to pay the fee for staking");
		bool _didAdd = false;
		totalFees += msg.value;
		Stakes[] memory _ogStakes = _stakers[msg.sender];
		if(_ogStakes.length != 0 ){
			for (uint256 i=0; i<_ogStakes.length; i++){
				if(_ogStakes[i].stakingPool == pool){
					require(_addToStaking(msg.sender, i, lockTimeOption ,amount), "Unable To Stake Currently");
					_didAdd = true;
					break;
				}
			}
			if(!_didAdd){
				require(_createNewStaking(msg.sender, pool, lockTimeOption ,amount), "Unable To Stake currently");
				_didAdd = true;
			}
		}else{
			require(_createNewStaking(msg.sender, pool, lockTimeOption ,amount), "Unable To Stake currently");
			_didAdd = true;
		}
		require(_didAdd, "Unable to create a new staking instance");
	}

	/**
	 * parameters: address of the pool
	 * 
	 * @dev returns the staked tokens + profit from staking
	 * to msg.sender which had previously created a Stake in a supported pool
	 * throws if pool does not exist
	 * throws if staked amount is equal to 0
	 * throws if the returned stakes throws
	 */
	function GeoReturn(address pool) external {
		require(returnStakes(msg.sender, pool), "Currently cannot return stakes");
		require(_removeFromStaker(msg.sender, pool), "Cannot evaluate post-unstaking amount");
	}

	/**
	 * parameters: pool address (ERC20 token), maximum allowed for staking, minimum allowed for staking, the locktime for any stake, the APY for the stake
	 * 
	 * @dev initalizes a staking pool for the ERC20 token with the important features
	 * throws if pool exists as it doesn't allow any overriding
	 */
	function initPool(address pool, uint256 maximumStaking, uint256 minimumStaking, uint256[] memory lockTimesSeconds , uint256[] memory annualPercentageYeild, bool lp, address refAddr) external isAdmin {
		require(!_poolExists(pool), "Cannot Initalize An existing Pool");
		if(lp){
			require(pool != refAddr, "To stake liquidity please provide the reference token");
		}
		_pools[pool] = Pool(true, maximumStaking, uint256(0), annualPercentageYeild, lockTimesSeconds, minimumStaking, lp, refAddr);
		_APYs[pool][LOCKTIME.HALF] = annualPercentageYeild[0];
		_LTs[pool][LOCKTIME.HALF] =  lockTimesSeconds[0];
		_APYs[pool][LOCKTIME.FULL] = annualPercentageYeild[1];
		_LTs[pool][LOCKTIME.FULL] = lockTimesSeconds[1];
	}

	/**
	 * parameters: address of the pool
	 * 
	 * @dev removes a pool by reseting Pool() variables from the struct
	 * throws if the pool still has participation 
	 * Can only remove if the currentparticipation is 0
	 */
	function removePool(address pool) external isAdmin {
		require(_poolExists(pool), "This pool does not exist");
		require(getCurrentStaked(pool) == 0, "This pool still has investments");
		uint256[] memory _locktimes = new uint256[](0);

		_pools[pool] = Pool(false, uint256(0), uint256(0), _locktimes, _locktimes, uint256(0), false, address(0));
	}

	/**
	 * @dev transfers the fees associated with Geostake
	 * from the contract, this should not be something to worry
	 * as it's implemented in uint256 value and not address(this).balance
	 */
	function withdrawFees() external onlyOwner {
		require(payable(msg.sender).send(totalFees));
		totalFees = 0;
	}

	/**
	 * parameters: new fee for staking
	 * 
	 * @dev changes the fee associated with Geostake
	 */
	function changeFee(uint256 newFee) external isAdmin {

		stakingFee = newFee;
	}

	/**
	 * parameters:  pool address (ERC20 token), maximum allowed for staking, minimum allowed for staking, the locktime for any stake, the APY for the stake
	 * 
	 * @dev edits the current pool for new parameters as this creates a configurable pool
	 * however, everything is momentarly applied, i.e: when a person stakes they will get their staking done with the parameters specifed at the time of staking
	 * throws if maximum allowed for staking is less than the current being staked
	 * throws if the APY is 0 
	 */
	function changePoolParams(address pool, uint256 maximumStaking, uint256 minimumStaking, uint256[] memory lockTimesSeconds, uint256[] memory annualPercentageYeild, bool lp, address refAddr) external isAdmin{
	 	require(_poolExists(pool), "Cannot Edit A Non-initalized Pool");
		require(XNOR(lp , _isLiquidityPool(pool)), "Cannot change from an lp to a non-lp");
		require(_getRefTokenAddr(pool) == refAddr, "Cannot change the reference address for an LP");
	 	uint256 currentWalletStakes = getCurrentStaked(pool);
	 	require(maximumStaking >= currentWalletStakes, "The maximum of staking needs to be more than the currently staked");
		require(lockTimesSeconds.length == annualPercentageYeild.length, "Array mismatch");
	 	_pools[pool] = Pool(true, maximumStaking, currentWalletStakes, annualPercentageYeild, lockTimesSeconds, minimumStaking, lp, refAddr);
		_APYs[pool][LOCKTIME.HALF] = annualPercentageYeild[0];
		_LTs[pool][LOCKTIME.HALF] =  lockTimesSeconds[0];
		_APYs[pool][LOCKTIME.FULL] = annualPercentageYeild[1];
		_LTs[pool][LOCKTIME.FULL] = lockTimesSeconds[1];
	 }


	function withdraw() external onlyOwner {
		require(payable(msg.sender).send(address(this).balance));
	}


	function getExcess(address token) external view returns(uint256 removable, uint256 excess, uint256 original){
		uint256 _balance = GEOS20(token).balanceOf(address(this));
		removable = _balance + _Nexcess - _liqOfStake;
		excess = _Nexcess;
		original = _liqOfStake;
	}


	function withdrawExcess(address token, uint256 amount) external onlyOwner{
		uint256 _balance = GEOS20(token).balanceOf(address(this));
		uint256 removable = _balance + _Nexcess - _liqOfStake;
		if(amount <= removable){
			require(GEOS20(token).transfer(msg.sender, amount));
		}
	}

}