// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


contract PausePool{
    
    mapping(uint256 => bool) private pausedPool;

    event PoolPaused(uint256 indexed _pid, bool _paused);

    modifier whenNotPaused(uint256 _pid) {
        require(!pausedPool[_pid], "Pausable: paused");
        _;
    }

    function pausePoolViaPid(uint256 _pid, bool _paused) internal {
        pausedPool[_pid] = _paused;
        emit PoolPaused(_pid, _paused);
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SilToken.sol";
import "./interfaces/IMatchPair.sol";
import './interfaces/IWETH.sol';
import './interfaces/IMintRegulator.sol';
import "./interfaces/IProxyRegistry.sol";
import './TrustList.sol';
import './PausePool.sol';



// SilMaster is the master of Sil. He can make Sil and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SIL is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract SilMaster is Ownable , TrustList, IProxyRegistry, PausePool{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 buff;       // if not `0`,1000-based, allow NFT Manager adjust the value of buff 

        uint256 totalDeposit;
        uint256 totalWithdraw;
    }

    // Info of each pool.
    struct PoolInfo {
        IMatchPair matchPair;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SILs to distribute per block.

        uint256 lastRewardBlock;  // Last block number that SILs distribution occurs by token0.

        uint256 totalDeposit0;  // totol deposit token0
        uint256 totalDeposit1;  // totol deposit token0

        uint256 accSilPerShare0; // Accumulated SILs per share, times 1e12. See below.
        uint256 accSilPerShare1; // Accumulated SILs per share, times 1e12. See below.
    }

    // The SIL TOKEN!
    SilToken public sil;
    // Dev address.
    address public devaddr;
    // 10% is the community reserve, which is used by voting through governance contracts
    address public ecosysaddr;
    // 0.5% fee will be collect , then repurchase Sil and distribute to depositor
    address public repurchaseaddr;
    // NFT will be published in future, for a interesting mining mode  
    address public nftProphet;

    address public WETH;
    //IMintRegulator 
    address public mintRegulator;
    // Block number when bonus SIL period ends.
    uint256 public bonusEndBlock;
    // SIL tokens created per block.
    uint256 public baseSilPerBlock;
    uint256 public silPerBlock;
    // Bonus muliplier for early sil makers.
    uint256 public bonus_multiplier;
    uint256 public maxAcceptMultiple = 3;
    uint256 public maxAcceptMultipleDenominator = 9;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SIL mining starts.
    uint256 public startBlock;
    // Fee repurchase SIL and redistribution
    uint256 public periodFinish;
    uint256 public feeRewardRate;
    // Prevent the invasion of giant whales
    bool public whaleSpear;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP(token0/token1) tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo0;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo1;
    // MatchPair delegatecall implmention
    mapping (uint256 => address) public matchPairRegistry;
    mapping (uint256 => bool) public matchPairPause;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SilPerBlockUpdated(address indexed user, uint256 _molecular, uint256 _denominator);
    event WithdrawSilToken(address indexed user, uint256 indexed pid, uint256 silAmount0, uint256 silAmount1);

    constructor(
            SilToken _sil,
            address _devaddr,
            address _ecosysaddr,
            address _repurchaseaddr,
            address _weth
        ) public {
        sil = _sil;
        devaddr = _devaddr;
        ecosysaddr = _ecosysaddr;
        repurchaseaddr = _repurchaseaddr;
        WETH = _weth;
    }

    function initSetting(
        uint256 _silPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _bonus_multiplier)
        public
        onlyOwner()
    {
        require(startBlock == 0, "Init only once" );
        silPerBlock = _silPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        baseSilPerBlock = _silPerBlock;
        bonus_multiplier = _bonus_multiplier;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    /**
     * @dev adjust mint number by regulater.getScale()
     */
    function setMintRegulator(address _regulator) public onlyOwner() {
        mintRegulator = _regulator;
    }
    /**
     * @notice register delegate implementation
     */
    function matchPairRegister(uint256 _index, address _implementation) public onlyOwner() {
        matchPairRegistry[_index] = _implementation;
    }
    /**
     * @dev setting max accept multiple. must > 1
     * maxDepositAmount = pool.lp.tokenAmount * multiple - pool.pendingAmount
     */
    function setMintRegulator(uint _maxAcceptMultiple, uint _maxAcceptMultipleDenominator) public onlyOwner() {
        maxAcceptMultiple = _maxAcceptMultiple;
        maxAcceptMultipleDenominator = _maxAcceptMultipleDenominator;
    } 
    
    function setNFTProphet(address _nftProphet) public onlyOwner()  {
        nftProphet = _nftProphet;
    }
    
    function updateSilPerBlock() public {
        require(mintRegulator != address(0), "IMintRegulator not setting");

        (uint256 _molecular, uint256 _denominator)  = IMintRegulator(mintRegulator).getScale();
        uint256 silPerBlockNew = baseSilPerBlock.mul(_molecular).div(_denominator);
        if(silPerBlock != silPerBlockNew) {
             massUpdatePools();
             silPerBlock = silPerBlockNew;
        }
    
        emit SilPerBlockUpdated(msg.sender, _molecular, _denominator);
    }
    //Reserve shares for cross-chain
    function reduceSil(uint256 _reduceAmount) public onlyOwner() {

        baseSilPerBlock = baseSilPerBlock.sub(baseSilPerBlock.mul(_reduceAmount).div(sil.maxMint()));
        sil.reduce(_reduceAmount);
        //update Pool
        massUpdatePools();
        //update silPerBlock
        if(mintRegulator != address(0)) {
            updateSilPerBlock();
        }else {
            silPerBlock = baseSilPerBlock;
        }

    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IMatchPair _matchPair) public onlyOwner {

        // if (_withUpdate) {
        massUpdatePools();
        // }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            matchPair: _matchPair,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            totalDeposit0: 0,
            totalDeposit1: 0,
            accSilPerShare0: 0,
            accSilPerShare1: 0
            }));
    }
    //@notice Prevent unilateral mining of large amounts of funds
    function holdWhaleSpear(bool _hold) public onlyOwner {
        whaleSpear = _hold;
    }
    //@notice Update the given pool's SIL allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner {

        massUpdatePools();
        
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {

        if(_from < startBlock) {
            _from = startBlock;
        }

        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(bonus_multiplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(bonus_multiplier).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending SILs on frontend.
    function pendingSil(uint256 _pid, uint256 _index, address _user) external view   returns (uint256) {
        //if over limit pending is burn
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _index == 0? userInfo0[_pid][_user] : userInfo1[_pid][_user];

        uint256 accSilPerShare = _index == 0? pool.accSilPerShare0 : pool.accSilPerShare1;
        uint256 lpSupply = _index == 0? pool.totalDeposit0 : pool.totalDeposit1;


        if (block.number > pool.lastRewardBlock && lpSupply != 0) {            
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            
            uint256 silReward = multiplier.mul(silPerBlock).mul(pool.allocPoint).div(totalAllocPoint);//
            uint256 totalMint = sil.balanceOf(address(this));
            if(sil.maxMint()< totalMint.add(silReward)) {
                silReward = sil.maxMint().sub(totalMint);
            }
            silReward = getFeeRewardAmount(pool.allocPoint, pool.lastRewardBlock).add(silReward);
            accSilPerShare = accSilPerShare.add(silReward.mul(1e12).div(lpSupply).div(2));
        } 
        return  amountBuffed(user.amount, user.buff).mul(accSilPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {

        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply0 = pool.totalDeposit0;
        uint256 lpSupply1 = pool.totalDeposit1;

        if(lpSupply0.add(lpSupply1) > 0 ) {
            uint256 silReward;
            if(!sil.mintOver()) {
                uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
                silReward = multiplier.mul(silPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            }
            //add fee Reward if exist
            silReward = getFeeRewardAmount(pool.allocPoint, pool.lastRewardBlock).add(silReward);
            // token0 side
            if(lpSupply0 > 0) {
                pool.accSilPerShare0 = pool.accSilPerShare0.add(silReward.mul(1e12).div(lpSupply0).div(2));
            }
            // token1 side
            if(lpSupply1 > 0) {
                pool.accSilPerShare1 = pool.accSilPerShare1.add(silReward.mul(1e12).div(pool.totalDeposit1).div(2));
            }
            if(lpSupply0 ==0 || lpSupply1==0) {
                silReward = silReward.div(2);
            }



            if(silReward > 0){        
                sil.mint(devaddr, silReward.mul(17).div(68)); // 17%
                sil.mint(ecosysaddr, silReward.mul(15).div(68)); // 15%
                sil.mint(address(this), silReward); // 68%
            }
        }
        
        pool.lastRewardBlock = block.number;
    }

    function getFeeRewardAmount(uint allocPoint, uint256 lastRewardBlock ) private view returns (uint256 feeReward) {
        if(feeRewardRate > 0) {

            uint256 endPoint = block.number < periodFinish ? block.number : periodFinish;
            if(endPoint > lastRewardBlock) {
                feeReward = endPoint.sub(lastRewardBlock).mul(feeRewardRate).mul(allocPoint).div(totalAllocPoint);
            }
        }
    }

    function batchGrantBuff(uint256[] calldata _pid, uint256[] calldata _index, uint256[] calldata _value, address[] calldata _user) public {
        require(msg.sender == nftProphet, "Grant buff: Prophet allowed");
        require(_pid.length > 0 , "_pid.length is zore");
        require(_pid.length ==  _index.length ,   "Require length equal: pid, index");
        require(_index.length ==  _value.length , "Require length equal: index, _value");
        require(_value.length ==  _user.length ,  "Require length equal: _value, _user");
        
        uint256 length = _pid.length;

        for (uint256 i = 0; i < length; i++) {
           grantBuff(_pid[i], _index[i], _value[i], _user[i]);
        }
    }

    function grantBuff(uint256 _pid, uint256 _index, uint256 _value, address _user) public {
        require(msg.sender == nftProphet, "Grant buff: Prophet allowed");

        UserInfo storage user = _index == 0  ? userInfo0[_pid][_user] : userInfo1[_pid][_user];
        // if user.amount == 0, just set `buff` value
        if (user.amount > 0 && !sil.mintOver()) {
            updatePool(_pid);

            PoolInfo storage pool = poolInfo[_pid];
            uint256 accPreShare;
            if(_index == 0) {
               accPreShare = pool.accSilPerShare0;
               pool.totalDeposit0 = pool.totalDeposit0
                                    .sub(amountBuffed(user.amount, user.buff))
                                    .add(amountBuffed(user.amount, _value));
            }else {
               accPreShare = pool.accSilPerShare1;
               pool.totalDeposit1 = pool.totalDeposit1
                                    .sub(amountBuffed(user.amount, user.buff))
                                    .add(amountBuffed(user.amount, _value));
            }

            uint256 pending = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeSilTransfer(_user, pending);
            }
            user.rewardDebt = amountBuffed(user.amount, _value).mul(accPreShare).div(1e12);
        }
        user.buff = _value;
    }

    function depositEth(uint256 _pid, uint256 _index ) public payable { 
        uint256 _amount = msg.value;
        uint256 acceptAmount;
        if(whaleSpear) {
            PoolInfo storage pool = poolInfo[_pid];
            acceptAmount = pool.matchPair.maxAcceptAmount(_index, maxAcceptMultiple, maxAcceptMultipleDenominator, _amount);
        }else {
            acceptAmount = _amount;
        }
        IWETH(WETH).deposit{value: acceptAmount}();
        deposit(_pid, _index, acceptAmount);
        //chargeback
        if(_amount > acceptAmount) {
            safeTransferETH(msg.sender , _amount.sub(acceptAmount));
        }
    }

    // Deposit LP tokens to SilMaster.
    function deposit(uint256 _pid, uint256 _index,  uint256 _amount) whenNotPaused(_pid) public  {
        //check account (normalAccount || trustable)
        checkAccount(msg.sender);
        bool _index0 = _index == 0;
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _index0 ? userInfo0[_pid][msg.sender] : userInfo1[_pid][msg.sender];
        updatePool(_pid);
        if(whaleSpear) {

            _amount = pool.matchPair.maxAcceptAmount(_index, maxAcceptMultiple, maxAcceptMultipleDenominator, _amount);

        }
        
        uint256 accPreShare = _index0 ? pool.accSilPerShare0 : pool.accSilPerShare1;
       
        if (user.amount > 0 && !sil.mintOver()) {
            uint256 pending = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeSilTransfer(msg.sender, pending);
            }
        }

        if(_amount > 0) {
            address tokenTarget = pool.matchPair.token(_index);
            if(tokenTarget == WETH) {
                safeTransfer(WETH, address(pool.matchPair), _amount);
            }else{
                safeTransferFrom( pool.matchPair.token(_index), msg.sender,  address(pool.matchPair), _amount);
            }
            //stake to MatchPair
            pool.matchPair.stake(_index, msg.sender, _amount);
            user.amount = user.amount.add(_amount);
            user.totalDeposit = user.totalDeposit.add(_amount); 
            if(_index0) {
                pool.totalDeposit0 = pool.totalDeposit0.add(amountBuffed(_amount, user.buff));
            }else {
                pool.totalDeposit1 = pool.totalDeposit1.add(amountBuffed(_amount, user.buff));
            }
        }


        user.rewardDebt = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdrawToken(uint256 _pid, uint256 _index, uint256 _amount) public { 
        address _user = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];

        //withdrawToken from MatchPair

        uint256 untakeTokenAmount = pool.matchPair.untakeToken(_index, _user, _amount);
        address targetToken = pool.matchPair.token(_index);


        uint256 userAmount = untakeTokenAmount.mul(995).div(1000);

        withdraw(_pid, _index, _user, untakeTokenAmount);
        if(targetToken == WETH) {

            IWETH(WETH).withdraw(untakeTokenAmount);

            safeTransferETH(_user, userAmount);
            safeTransferETH(repurchaseaddr, untakeTokenAmount.sub(userAmount) );
        }else {
            safeTransfer(pool.matchPair.token(_index),  _user, userAmount);
            safeTransfer(pool.matchPair.token(_index),  repurchaseaddr, untakeTokenAmount.sub(userAmount));
        }
    }
    // Withdraw LP tokens from SilMaster.
    function withdraw( uint256 _pid, uint256 _index, address _user, uint256 _amount) whenNotPaused(_pid)  private {
        
        bool _index0 = _index == 0;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _index0? userInfo0[_pid][_user] :  userInfo1[_pid][_user];
        //record withdraw origin Amount
        user.totalWithdraw = user.totalWithdraw.add(_amount);
        if(user.amount < _amount) {
            _amount = user.amount;
        }
        updatePool(_pid);

        uint256 accPreShare = _index0 ? pool.accSilPerShare0 : pool.accSilPerShare1;
        uint256 pending = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeSilTransfer(_user, pending);
        }

        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if(_index0) {
                pool.totalDeposit0 = pool.totalDeposit0.sub(amountBuffed(_amount, user.buff));
            }else {
                pool.totalDeposit1 = pool.totalDeposit1.sub(amountBuffed(_amount, user.buff));
            }
        }
        user.rewardDebt = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12);
        emit Withdraw(_user, _pid, _amount);
    }
    /**
     * @dev withdraw SILToken mint by deposit token0 & token1
     */
    function withdrawSil(uint256 _pid) public {

        updatePool(_pid);

        uint256 silAmount0 = withdrawSilCalcu(_pid, 0, msg.sender);
        uint256 silAmount1 = withdrawSilCalcu(_pid, 1, msg.sender);

        safeSilTransfer(msg.sender, silAmount0.add(silAmount1));
        
        emit WithdrawSilToken(msg.sender, _pid, silAmount0, silAmount1);
    }

    function withdrawSilCalcu(uint256 _pid, uint256 _index,  address _user) private returns (uint256 silAmount) {
        bool _index0 = _index == 0;
        
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = _index0 ? userInfo0[_pid][_user] : userInfo1[_pid][_user];
        
        uint256 accPreShare = _index0 ? pool.accSilPerShare0 : pool.accSilPerShare1;

        if (user.amount > 0) {
            silAmount = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12).sub(user.rewardDebt);
        }
        user.rewardDebt = amountBuffed(user.amount, user.buff).mul(accPreShare).div(1e12);
    }

    // Safe sil transfer function, just in case if rounding error causes pool to not have enough SILs.
    function safeSilTransfer(address _to, uint256 _amount) internal {
        uint256 silBal = sil.balanceOf(address(this));
        if (_amount > silBal) {
            sil.transfer(_to, silBal);
        } else {
            sil.transfer(_to, _amount);
        }
    }

    function amountBuffed(uint256 amount, uint256 buff) private pure returns (uint256) {
        if(buff == 0) {
            return amount;
        }else {
            return amount.mul(buff).div(1000);
        }
    }

    function mintableAmount(uint256 _pid, uint256 _index, address _user) external view returns (uint256) {

        UserInfo storage user = _index == 0? userInfo0[_pid][_user] :  userInfo1[_pid][msg.sender];
        return user.amount;
    }


    function getProxy(uint256 _index) external  view override returns(address) {
        require(!matchPairPause[_index], "Proxy paused, waiting upgrade via governance");
        return matchPairRegistry[_index];
    }

    /**
     * @notice to protect fund of users, 
     * allow developers to pause then upgrade via community governor
     */
    function pauseProxy(uint256 _pid, bool _paused) public {
        require(msg.sender == devaddr, "dev sender required");
        matchPairPause[_pid] = _paused;
    }

    function pause(uint256 _pid, bool _paused) public {
        require(msg.sender == devaddr, "dev sender required");
        pausePoolViaPid(_pid, _paused);
    }
    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function ecosys(address _ecosysaddraddr) public {
        require(msg.sender == ecosysaddr, "ecosys: wut?");
        ecosysaddr = _ecosysaddraddr;
    }
    
    function repurchase(address _repurchaseaddr) public {
        require(msg.sender == repurchaseaddr, "repurchase: wut?");
        repurchaseaddr = _repurchaseaddr;
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'MasterTransfer: TRANSFER_FROM_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'MasterTransfer: TRANSFER_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'MasterTransfer: ETH_TRANSFER_FAILED');
    }

    function notifyRewardAmount(uint256 reward, uint256 duration)
        onlyOwner
        external
    {
        //update all poll first
        massUpdatePools();
        if (block.number >= periodFinish) {
            feeRewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.number);
            uint256 leftover = remaining.mul(feeRewardRate);
            feeRewardRate = reward.add(leftover).div(duration);
        }
        periodFinish = block.number.add(duration);

    }

    function checkAccount(address _account) private {
        require(!_account.isContract() || trustable(_account) , "High risk account");
    }

    receive() external payable {
        require(msg.sender == WETH, "only accept from WETH"); // only accept ETH via fallback from the WETH contract
    }
}

pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// Sister In Law with Governance.
contract SilToken is ERC20, Ownable {
    uint256 public maxMint;
    bool public mintOver;
    constructor ( uint256 _maxMint ) ERC20("SIL Finance Token", "SIL") public  {
        maxMint = _maxMint;
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (SilMaster).
    function mint(address _to, uint256 _amount) public onlyOwner {

        if(totalSupply().add(_amount) <= maxMint ) {
            _mint(_to, _amount);
            _moveDelegates(address(0), _delegates[_to], _amount);
        }else {
            mintOver = true;
            uint256 mintAmount = maxMint - totalSupply();
             _mint(_to, mintAmount);
            _moveDelegates(address(0), _delegates[_to], mintAmount);
        }
    }

    function reduce(uint256 _reduceAmount) public onlyOwner() {
        require(_reduceAmount.add(totalSupply()) < maxMint , "Reduce over amount");
        maxMint = maxMint.sub(_reduceAmount);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @notice A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CYZ::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CYZ::delegateBySig: invalid nonce");
        require(now <= expiry, "CYZ::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "CYZ::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        super._transfer(sender, recipient, amount);
        _moveDelegates(_delegates[sender], _delegates[recipient], amount);
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying SUSHIs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "CYZ::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./utils/MasterCaller.sol";

contract TrustList is MasterCaller {
    
    mapping(address => bool) whiteMap;

    event WhiteListUpdate(address indexed _account, bool _trustable);

    function updateList(address _account, bool _trustable) public  onlyMasterCaller() {
        whiteMap[_account] = _trustable;

        emit WhiteListUpdate(_account, _trustable);
    }

    function trustable(address _account) internal returns (bool) {
        return whiteMap[_account];
    }

}

pragma solidity 0.6.12;

interface IMatchPair {
    
    function stake(uint256 _index, address _user,uint256 _amount) external;  // owner
    function untakeToken(uint256 _index, address _user,uint256 _amount) external returns (uint256 _tokenAmount);// owner
    // function untakeLP(uint256 _index, address _user,uint256 _amount) external returns (uint256);// owner

    function token(uint256 _index) external view  returns (address);

    //token0 - token1 Amount
    //LP0 - LP1 Amount
    // queue Token0 / token1
    function queueTokenAmount(uint256 _index) external view  returns (uint256);
    // max Accept Amount
    function maxAcceptAmount(uint256 _index, uint256 _molecular, uint256 _denominator, uint256 _inputAmount) external view returns (uint256);

}

pragma solidity >=0.5.0;

interface IMintRegulator {

    function getScale() external view returns (uint256 _molecular, uint256 _denominator);
}

pragma solidity 0.6.12;

interface IProxyRegistry {
    function getProxy(uint256 _index) external view returns(address);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract MasterCaller {
    address private _master;

    event MastershipTransferred(address indexed previousMaster, address indexed newMaster);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _master = msg.sender;
        emit MastershipTransferred(address(0), _master);
    }

    /**
     * @dev Returns the address of the current MasterCaller.
     */
    function masterCaller() public view returns (address) {
        return _master;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMasterCaller() {
        require(_master == msg.sender, "Master: caller is not the master");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferMastership(address newMaster) public virtual onlyMasterCaller {
        require(newMaster != address(0), "Master: new owner is the zero address");
        emit MastershipTransferred(_master, newMaster);
        _master = newMaster;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}