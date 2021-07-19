//SourceUnit: TrxOctxLpReward.sol

pragma solidity ^0.5.8;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity ^0.5.8;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.5.8;

contract Context {
    constructor () internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


pragma solidity ^0.5.8;
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.8;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

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
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


pragma solidity ^0.5.5;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


pragma solidity ^0.5.8;

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


pragma solidity ^0.5.0;


contract TokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public usdt = IERC20(0x417BCFA446C8B677B1E1B5498946422FA2EABAA69B); //Address
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        usdt.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        usdt.transfer(msg.sender, amount);
    }
}

contract TrxOctxLpReward is TokenWrapper {
    using SafeMath for uint256;
    IERC20 rewardToken = IERC20(0x418162773F2789D1056E338849C1843E5B7D1FBC99); // TOKEN OCTX

    uint256 beginTime = 1604664000;
    uint256 currentLevel = 0;
    uint256 totalHarvest = 0;
    uint256 public totalHarvestWithdraw = 0;
    uint256 lastUpdateTime = 0;

    uint256[] public circleStopTimes = [0, 0, 0, 0, 0, 0, 0, 0, 0];
    uint256[] public tokenTotalAmountCircles = 
    [5e6 * 1e18, 
    5e6 * 1e18, 
    5e6 * 1e18, 
    5e6 * 1e18, 
    5e6 * 1e18, 
    5e6 * 1e18, 
    5e6 * 1e18, 
    5e6 * 1e18, 
    5e6 * 1e18];
    uint256[] public tokenHarvestPerDay = 
    [20e16 / 1e6, 
    18e16 / 1e6, 
    15e16 / 1e6, 
    12e16 / 1e6, 
    10e16 / 1e6, 
    8e16 / 1e6, 
    7e16 / 1e6, 
    6e16 / 1e6, 
    5e16 / 1e6];
    uint256 constant public ONEDAY = 1 days;
    
    uint256 public totalInvestAmount = 0;
    uint256 public trxBalance = 0;

    uint256 constant refBonusRate = 10;
    uint256 constant PERCENTS_DIVIDER = 100;
                                                                                                                                                                                                                                                                                           
    mapping(address => User) public users;
    uint256 public totalUserCount = 0;
    

    struct User {
        address ref;
        uint256 balance;
        uint256 unStakeBonus;
        uint256 totalStake;
        
        uint256 refBalance;
        uint256 refUnstakeBonus;
        uint256 refUserCount;
        uint256 updateTime;
    }

    constructor() public {
    }

    function freeze(address _ref,uint256 amount) public payable {
    
        require(block.timestamp > beginTime , "Not start!");
    
        require(amount > 0, "Stake must > 0！");
        super.stake(amount);
        clearHarvest();

        User storage user = users[msg.sender];
        if(user.totalStake == 0){
            totalUserCount = totalUserCount.add(1);

            if(user.ref == address(0) && _ref != msg.sender && _ref != address(0)){
                user.ref = _ref;
                User storage refUser = users[user.ref];
                refUser.refUserCount = refUser.refUserCount.add(1);
            }
        }

        
        uint256 stakeHarvest = calHarvest(user.balance, user.updateTime, false);
        uint256 refStakeHarvest = calHarvest(user.refBalance, user.updateTime, true);
        user.unStakeBonus = user.unStakeBonus.add(stakeHarvest);
        user.refUnstakeBonus = user.refUnstakeBonus.add(refStakeHarvest);
        user.updateTime = block.timestamp;


        if(user.ref != address(0)){
            User storage refUser = users[user.ref];
            uint256 stakeHarvest2 = calHarvest(refUser.balance, refUser.updateTime, false);
            uint256 refStakeHarvest2 = calHarvest(refUser.refBalance, refUser.updateTime, true);
            refUser.unStakeBonus = refUser.unStakeBonus.add(stakeHarvest2);
            refUser.refUnstakeBonus = refUser.refUnstakeBonus.add(refStakeHarvest2);
            refUser.updateTime = block.timestamp;
        }

        totalInvestAmount = totalInvestAmount.add(amount);
        trxBalance = trxBalance.add(amount);

        user.balance = user.balance.add(amount);
        user.totalStake = user.totalStake.add(amount);
        if(user.ref != address(0)){
            User storage refUser = users[user.ref];
            refUser.refBalance = refUser.refBalance.add(amount);
        }

        updateCircleStopTimes();
    }

    function unfreeze() public {
        User storage user = users[msg.sender];
        require(user.balance > 0, "Insufficient Balance！");
        uint256 amount = user.balance;
        super.withdraw(amount);

        clearHarvest();

        uint256 stakeHarvest = calHarvest(user.balance, user.updateTime, false);
        uint256 refStakeHarvest = calHarvest(user.refBalance, user.updateTime, true);
        user.unStakeBonus = user.unStakeBonus.add(stakeHarvest);
        user.refUnstakeBonus = user.refUnstakeBonus.add(refStakeHarvest);
        user.updateTime = block.timestamp;

        if(user.ref != address(0)){
            User storage refUser = users[user.ref];
            
            uint256 stakeHarvest2 = calHarvest(refUser.balance, refUser.updateTime, false);
            uint256 refStakeHarvest2 = calHarvest(refUser.refBalance, refUser.updateTime, true);
            refUser.unStakeBonus = refUser.unStakeBonus.add(stakeHarvest2);
            refUser.refUnstakeBonus = refUser.refUnstakeBonus.add(refStakeHarvest2);
            refUser.updateTime = block.timestamp;
        }

        trxBalance = trxBalance.sub(amount);

        user.balance = 0;
        if(user.ref != address(0)){
            User storage refUser = users[user.ref];
            refUser.refBalance = refUser.refBalance.sub(amount);
        }

        updateCircleStopTimes();
    }

    function clearHarvest() internal{
        if(lastUpdateTime == 0){
            totalHarvest = 0;
            lastUpdateTime = block.timestamp;
        }else{
            if(lastUpdateTime > circleStopTimes[circleStopTimes.length - 1]){
                currentLevel = circleStopTimes.length-1;
                return;
            }

            uint256 newHarvest = 0 ;
            uint256 timePlus = 0 ;
            for(uint256 i = 0; i < circleStopTimes.length; i++){
                if(circleStopTimes[i] > lastUpdateTime){
                    if(circleStopTimes[i] > block.timestamp){
                        uint256 time = block.timestamp.sub(lastUpdateTime.add(timePlus));
                        timePlus = timePlus.add(time);
                        newHarvest = newHarvest.add(
                            trxBalance.mul(time.mul(tokenHarvestPerDay[i]).div(ONEDAY))
                        );
                        break;
                    }else{
                        uint256 time = circleStopTimes[i].sub(lastUpdateTime.add(timePlus));
                        timePlus = timePlus.add(time);
                        newHarvest = newHarvest.add(
                            trxBalance.mul(time.mul(tokenHarvestPerDay[i]).div(ONEDAY))
                        );
                    }
                }
            }

            totalHarvest = totalHarvest.add(newHarvest).add(newHarvest.mul(refBonusRate).div(PERCENTS_DIVIDER));
            lastUpdateTime = block.timestamp;
        }
    }

    function updateCircleStopTimes() private{
        if(trxBalance <= 0){
            return;
        }
        uint256 totalAmount = 0 ;
        uint256 newCurrentLevel = currentLevel;
        for(uint256 i = 0; i < tokenTotalAmountCircles.length; i++){
            totalAmount = totalAmount.add(tokenTotalAmountCircles[i]);
            if(i >= currentLevel){
                if(totalHarvest > totalAmount){
                    newCurrentLevel = i;
                }else{
                    if(i == currentLevel){
                        circleStopTimes[i] = lastUpdateTime + 
                        (totalAmount.sub(totalHarvest))
                        .mul(ONEDAY)
                        .div(trxBalance)
                        .div(
                            tokenHarvestPerDay[i].add(tokenHarvestPerDay[i].mul(refBonusRate).div(PERCENTS_DIVIDER))
                        );
                    }else{
                        circleStopTimes[i] = circleStopTimes[i-1] + 
                        tokenTotalAmountCircles[i]
                        .mul(ONEDAY)
                        .div(trxBalance)
                        .div(
                            tokenHarvestPerDay[i].add(tokenHarvestPerDay[i].mul(refBonusRate).div(PERCENTS_DIVIDER))
                        );
                    }
                    
                }

            }
        }
        currentLevel = newCurrentLevel > tokenTotalAmountCircles.length ? tokenTotalAmountCircles.length : newCurrentLevel ;
    }


    function calHarvest(uint256 amount, uint256 startTime, bool isRef) private view returns (uint256){
        uint256 harvest = 0;
        uint256 timePlus = 0;
        for(uint256 i = 0; i < circleStopTimes.length; i++){
            if(circleStopTimes[i]>startTime){
                if(block.timestamp<circleStopTimes[i]){
                    harvest = harvest.add(
                        amount.mul(
                            block.timestamp.sub(startTime.add(timePlus))
                            .mul(tokenHarvestPerDay[i])
                            .div(ONEDAY)
                            )
                        );
                    break;
                }else{
                    uint256 time = circleStopTimes[i].sub(startTime).sub(timePlus) ;
                    timePlus = timePlus.add(time);
                    harvest = harvest.add(
                        amount.mul(
                            time
                            .mul(tokenHarvestPerDay[i])
                            .div(ONEDAY)
                            )
                        );
                }
            }
        }
        return isRef?(harvest.mul(refBonusRate).div(PERCENTS_DIVIDER)):harvest;
    }

    function getHarvest() public {
        User storage user = users[msg.sender];

        clearHarvest();

        uint256 stakeHarvest = calHarvest(user.balance, user.updateTime, false);
        uint256 refStakeHarvest = calHarvest(user.refBalance, user.updateTime, true);
        uint256 amount = user.unStakeBonus.add(stakeHarvest).add(user.refUnstakeBonus.add(refStakeHarvest));
        user.unStakeBonus = 0;
        user.refUnstakeBonus = 0;
        user.updateTime = block.timestamp;
        totalHarvestWithdraw = totalHarvestWithdraw.add(amount);
        require(amount > 0, "harvest <= 0");

        mintReward(msg.sender, amount);
    }

    function getHarvestInfo() public view returns (uint256 harvest, uint256 refHarvest) {
        User storage user = users[msg.sender];

        uint256 stakeHarvest = calHarvest(user.balance, user.updateTime, false);
        harvest = user.unStakeBonus.add(stakeHarvest);
        
        uint256 refStakeHarvest = calHarvest(user.refBalance, user.updateTime, true);
        refHarvest = user.refUnstakeBonus.add(refStakeHarvest);
        
        return (harvest, refHarvest);
    }


    function mintReward(address _account, uint _amount) private{
        rewardToken.mint(address(this), _amount);
        rewardToken.safeTransfer(_account, _amount);
    }

    function getStakeInfo() public view returns (uint256){
        User storage user = users[msg.sender];
        return user.balance;
    }

    function getRefInfo() public view returns (uint256 refUserCount, uint256 refBalance){
        User storage user = users[msg.sender];
        refUserCount = user.refUserCount;
        refBalance = user.refBalance;
        return (refUserCount, refBalance);
    }

    function getTotalHarvest() public view returns (uint256){
        uint256 newHarvest = calHarvest(trxBalance, lastUpdateTime, false);
        newHarvest = newHarvest.add(newHarvest.mul(refBonusRate).div(PERCENTS_DIVIDER)).add(totalHarvest);
        return newHarvest;
    }

    function getCurrentLevel() public view returns (uint256 level, uint256 totalLevel){
    
        
        if(lastUpdateTime > 0){
            level = circleStopTimes.length-1;
            for(uint256 i = 0; i < circleStopTimes.length; i++){
                if(block.timestamp < circleStopTimes[i]){
                    level = i;
                    break;
                }
            }
        }else{
            level = 0;
        }
        totalLevel = circleStopTimes.length;
        return (level+1, totalLevel) ;
    }
}