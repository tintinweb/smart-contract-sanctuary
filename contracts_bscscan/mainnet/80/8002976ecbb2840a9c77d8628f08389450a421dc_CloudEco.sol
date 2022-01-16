/**
 *Submitted for verification at BscScan.com on 2022-01-16
*/

// SPDX-License-Identifier: GPL-v3.0
pragma solidity >=0.4.0;
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity >=0.4.0;

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

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.2;

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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




pragma solidity ^0.6.0;

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}




pragma solidity >=0.4.0;

contract Context {

    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}




pragma solidity >=0.4.0;

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity >=0.6.2;

interface ILookupReferral {

    function getTopLeader(address _user) external view returns (address);

    function getLeaderByUser(address _user) external view returns (address) ;
}

pragma solidity >=0.6.2;

interface IReferral {
/**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

pragma solidity >=0.5.16;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.6;
interface IPancakeRouter{
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;
interface IBuyBack{
    function saveQueueByContract(address sellerAdd,uint256 totalXOSParam) external;
}

pragma solidity >=0.6.2;
interface ISmartChef{
    struct UserInfo {
        uint256 amount;  
        uint256 amount12; //amount value in token   
        uint256[] amountDetail;
        uint256[] amountDetailUSD;
        uint256[] createDates;
        uint256[] priceToken;
        uint256 amountUSD12;
        uint256 dailyReward12; 
        uint256 lastClaim;
        bool isPromo;
        uint256 promoEnd;
        uint256 promoDailyReward;
    }
    function getUserByAddress(address _user) external view returns (UserInfo memory);
    function getAllUsers() external view returns (address[] memory);
}

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

contract CloudEco is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    IPancakeRouter public pancakeRouter;
    IBuyBack public buyback;
    ILookupReferral public ref;
    ISmartChef public sc;

    // xos->usdt
    address[][] public path = [[0x4BacB027E0bf98025d8EC91493F6512b9F0FA0dc,0x55d398326f99059fF775485246999027B3197955]];

    // Info of each user.
    struct UserInfo {
        uint256 amount;  
        uint256 amount12; //amount value in token   
        uint256[] amountDetail;
        uint256[] amountDetailUSD;
        uint256[] createDates;
        uint256[] priceToken;
        uint256 amountUSD12;
        uint256 dailyReward12; 
        uint256 lastClaim;
        bool isPromo;
        uint256 promoEnd;
        uint256 promoDailyReward;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        IBEP20 rewardToken;
        uint256 totalStaked;
        uint256 totalStakedUSD;
        uint256 lastTimeReward;
        uint256 totalStakedXOS;
    }

    struct Promo {
        uint256 start;
        uint256 end;
        uint256 reward;
        uint256 minAmount;
        uint256 duration;
    }

    IBEP20 public rewardToken;

    uint256 public totalStakedAmount;

    uint256 public totalStakedAmountInXOS;
    // Info of each pool.
    PoolInfo[] public poolInfo;

    Promo public promo;
    //all user
    address[] public users;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    
    IReferral public referral;
    // Referral commission rate: 20%.
    uint16 public referralCommissionRate = 2000;
    // Maximum referral commission rate: 25%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 2500;
    // daily reward: 1%.
    uint256 public dailyReward12 = 100;
    // contract length in day
    uint256 public contractLength12 = 365; 
    // top leader commission 10%
    uint16 public topLeaderRate = 5;
    uint256 public leaderRate = 5;
    uint16 public referral1Rate = 5;
    uint16 public referral2Rate = 3;
    uint16 public referral3Rate = 2;
    
    mapping(address=>uint256) public topSales1;
    
    mapping(address=>uint256) public topSales2;
    
    mapping(address=>uint256) public topSales3;
    
    uint256 public targetSale1 = 10000*1000000000000000000;
    
    uint256 public targetSale2 = 100000*1000000000000000000;
    
    uint256 public targetSale3 = 100000*1000000000000000000;
    mapping(address=>uint256) public sales;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    mapping(address => bool) public smartChef;

    modifier onlyMasterChef() {
        require(smartChef[msg.sender] == true, "Only MasterChef can call this function");
        _;
    }

    constructor(IBEP20 _salsa,IBEP20 _rewardToken,IReferral _referral, address _pancakeRouter, address _buyback, address _ref,address _sc) public {
        rewardToken = _rewardToken;
        referral = _referral;
        totalStakedAmount = 0;
        totalStakedAmountInXOS = 0;
        pancakeRouter = IPancakeRouter(_pancakeRouter);
        buyback = IBuyBack(_buyback);
        ref = ILookupReferral(_ref);
        sc = ISmartChef(_sc);
        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _salsa,
            rewardToken: _rewardToken,
            totalStaked: 0,
            totalStakedUSD: 0,
            lastTimeReward:0,
            totalStakedXOS:0
        }));
    }

    function setOldSC(address _sc) public onlyOwner{
        sc = ISmartChef(_sc);
    }

    function addSmartChef(address _smartChef) external onlyOwner {
        smartChef[_smartChef] = true;
    }

    function setPromo(uint256 _start,uint256 _end,uint256 _reward,uint256 _minAmount,uint256 _duration) external onlyOwner {
        require(_end>_start,"End Date must be after Start Date");
        require(_reward>0,"Reward must be greated than 0");
        require(_minAmount>0,"Amount must be greated than 0");
        require(_duration>0,"Duration must be greated than 0");
        promo.start=_start;
        promo.end=_end;
        promo.reward=_reward;
        promo.minAmount=_minAmount;
        promo.duration=_duration;
    }

    function importUser(uint256 index,uint length) public onlyOwner{
        //get all address from old masterchef
        address[] memory usersimport = sc.getAllUsers();
        uint256 start = index*length;
        uint256 end = index*length + length;
        if(end>usersimport.length)
            end = usersimport.length;
        for(uint256 i=start;i<end;i++){
            ISmartChef.UserInfo memory userimport = sc.getUserByAddress(usersimport[i]);

            addUsers(usersimport[i]);

            UserInfo memory user;
            user.amount=userimport.amount;
            user.amount12=userimport.amount12;
            user.amountDetail=userimport.amountDetail;
            user.amountDetailUSD=userimport.amountDetailUSD;
            user.createDates=userimport.createDates;
            user.priceToken=userimport.priceToken;
            user.amountUSD12=userimport.amountUSD12;
            user.dailyReward12=userimport.dailyReward12;
            user.lastClaim=userimport.lastClaim;
            user.isPromo=userimport.isPromo;
            user.promoEnd=userimport.promoEnd;
            user.promoDailyReward=userimport.promoDailyReward;
            userInfo[usersimport[i]] = user;

            //update pool info
            PoolInfo storage pool = poolInfo[0];
            pool.totalStakedUSD = pool.totalStakedUSD + user.amountUSD12;
            pool.totalStaked = pool.totalStaked + user.amount;
            pool.totalStakedXOS = pool.totalStakedXOS + user.amount12;
        }
    }

    function getTotalPendingReward(uint256 _pid) public view returns (uint256) {
        uint256 totalPending = 0;
        for(uint256 i=0;i<users.length;i++){
            totalPending = totalPending + pendingReward(_pid,users[i]);
        }
        return totalPending;
    }

    function setTotalStakedAmount(uint256 _totalStakedAmount,uint256 _totalStakedUSD) public onlyOwner{
        totalStakedAmount = _totalStakedAmount;
        PoolInfo storage pool = poolInfo[0];
        pool.totalStakedUSD = _totalStakedUSD;
        pool.totalStaked = _totalStakedAmount;
    }

    function setPancakeRouter(address _pancakeRouter) public{
        pancakeRouter = IPancakeRouter(_pancakeRouter);
    }

    function setBuyback(address _buyback) public{
        buyback = IBuyBack(_buyback);
    }
    
    function stopReward(uint256 _pid) public onlyOwner {
        poolInfo[_pid].lastTimeReward = block.timestamp;
    }

    function getUserByAddress(address _user) public view returns (UserInfo memory) {
        return userInfo[_user];
    }

    function addUsers(address _user) internal{
        if(userInfo[_user].amount==0){
             users.push(_user);
        }   
    }

    function getAllUsers() public view returns (address[] memory){
        return users;
    }

    //return totalAmountCanRemove
    function getTotalAmountCanRemove(address _user) public view returns (uint256){
        UserInfo storage user = userInfo[_user];
        uint256[] storage contractdate = user.createDates;
        uint256 totalAmount = 0;
        for(uint i=0; i<contractdate.length; i++){
            uint256 contractLength = contractLength12;
            uint256 end = contractdate[i] + contractLength*86400;
            if(block.timestamp >= end){
                totalAmount = totalAmount + user.amountDetail[i];
            }
        }
        return totalAmount;
    }

    // View function to see pending Reward on frontend.
    function pendingReward(uint256 _pid,address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        PoolInfo storage pool = poolInfo[_pid];
        // per daily
        uint256 rew = 0;
        if(pool.lastTimeReward==0 && !user.isPromo){
            rew = (user.amount12*(block.timestamp - user.lastClaim)*user.dailyReward12)/8640000/1000000;
        //promo
        }else if(pool.lastTimeReward==0 && user.isPromo){
            if(block.timestamp>user.promoEnd)
                rew = ((user.amount12*(user.promoEnd - user.lastClaim)*user.promoDailyReward)+(user.amount12*(block.timestamp - user.promoEnd)*user.dailyReward12))/8640000/1000000;
            else
                rew = (user.amount12*(block.timestamp - user.lastClaim)*user.promoDailyReward)/8640000/1000000;
        }else{
            rew = (user.amount12*(pool.lastTimeReward - user.lastClaim)*user.dailyReward12)/8640000/1000000;
        }
        return rew*10000;
    }
    
    function getLPPrice(address lp) public view returns (uint256){
        uint256 totalSupply = IPancakePair(lp).totalSupply();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPancakePair(lp).getReserves();
        uint256 price = reserve1*2/totalSupply; 
        return price;
    }
    
    //update sales
    function updateSales(address _user,uint256 _amount) internal{
        address _refer = referral.getReferrer(_user);
        while(_refer != address(0)){
            sales[_refer] = sales[_refer] + _amount;
            if(sales[_refer]>=targetSale3){
                topSales3[_refer] = sales[_refer];
                delete topSales2[_refer];
                delete topSales1[_refer];
            }else if(sales[_refer]>=targetSale2){
                topSales2[_refer] = sales[_refer];
                 delete topSales1[_refer];
            }else if(sales[_refer]>=targetSale1){
                topSales1[_refer] = sales[_refer];
            }
            _refer = referral.getReferrer(_refer);
        }
    }

    function getPriceToken(uint256 _pid) public view returns (uint){
        uint256 price = pancakeRouter.getAmountsOut(1,path[_pid])[1];
        return price;
    }

    function harvest(uint256 _pid) public {
        harv(_pid,msg.sender);
    }

    function harv(uint256 _pid,address buyer) internal {
        UserInfo storage user = userInfo[buyer];

        if (user.amount > 0) {
            uint256 pending = pendingReward(_pid,buyer);
            if(pending > 0) {
                //transfer to buyback
                rewardToken.safeTransfer(address(buyback), pending.mul(8).div(10));
                buyback.saveQueueByContract(address(buyer),pending.mul(8).div(10));
                payReferralCommission(buyer, pending);
                user.lastClaim = block.timestamp;
                user.dailyReward12 = dailyReward12;
            }
        }
        if(user.isPromo && block.timestamp>user.promoEnd){
            //reset promo
            user.isPromo = false;
            user.promoEnd = 0;
            user.promoDailyReward = 0;
        }
    }

    function depo(uint256 _pid,uint256 _amount, address _referrer, address _sender) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_sender];

        if (_amount > 0 && address(referral) != address(0) && _referrer != address(0) && _referrer != _sender) {
            referral.recordReferral(_sender, _referrer);
        }
        if (user.amount > 0) {
            harv(_pid,_sender);
        }
        if(_amount > 0) {
            //pool.lpToken.safeTransferFrom(address(_sender), address(this), _amount);
            uint256 _tokenPrice = getLPPrice(address(pool.lpToken));
            uint256 _tokenValue = _amount*_tokenPrice;
            uint256 price = getPriceToken(_pid);
            //check promo
            if(block.timestamp>=promo.start && block.timestamp<=promo.end && _tokenValue>promo.minAmount && user.amount==0){
                user.isPromo = true;
                user.promoEnd = block.timestamp + promo.duration;
                user.promoDailyReward = promo.reward;
            }
            addUsers(address(_sender));
            user.amount = user.amount.add(_amount);
            totalStakedAmount = totalStakedAmount.add(_amount);
            user.lastClaim = block.timestamp;
            user.amountDetail.push(_amount);
            user.createDates.push(block.timestamp);
            user.amountDetailUSD.push(_tokenValue);
            user.priceToken.push(price);
            user.amountUSD12 = user.amountUSD12.add(_tokenValue);
            user.amount12 = user.amount12 + _tokenValue/price;
            if(user.dailyReward12==0)
                user.dailyReward12 = dailyReward12;
            totalStakedAmountInXOS = totalStakedAmountInXOS + _tokenValue/price;
            updateSales(address(_sender),_tokenValue);
            
            //update pool info
            pool.totalStaked = pool.totalStaked + _amount;
            pool.totalStakedUSD = pool.totalStakedUSD.add(_tokenValue);
            pool.totalStakedXOS = pool.totalStakedXOS + _tokenValue/price;
        }
        emit Deposit(_sender, _amount);
    }

    function depositFromSellback(uint256 _pid,uint256 _amount, address _referrer, address _seller) public onlyMasterChef{
        depo(_pid,_amount,_referrer,_seller);
    }
    
    function withdraw(uint256 _pid,uint256 _amount) public {
        if(_amount<=getTotalAmountCanRemove(msg.sender)){
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[msg.sender];
            require(user.amount >= _amount, "withdraw: not good");
            harvest(_pid);
            if(_amount > 0) {
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
                //remove amount in array
                uint256 removeAmount = 0;
                uint256 totalWasRemove = _amount;
                uint256 totalWasRemoveUSD = 0;

                //calculate percent remove
                uint256 percentRemove = _amount*100/user.amount;
                uint256 totalXOSRemoved = user.amount12*percentRemove/100;
                user.amount12 = user.amount12 - totalXOSRemoved;

                for(uint i=0; i<user.createDates.length; i++){
                    uint256 contractLength = contractLength12;
                    uint256 end = user.createDates[i] + contractLength*86400;
                    if(block.timestamp >= end && removeAmount<_amount && totalWasRemove>0){
                        totalWasRemove = totalWasRemove - user.amountDetail[i];
                        if(totalWasRemove>=0){
                            user.amountUSD12 = user.amountUSD12 -user.amountDetailUSD[i];
                            totalWasRemoveUSD = totalWasRemoveUSD+user.amountDetailUSD[i];
                            removeAmount = removeAmount + user.amountDetail[i];
                            user.amount = user.amount-user.amountDetail[i];
                            //remove array
                            delete user.amountDetail[i];
                            delete user.amountDetailUSD[i];
                            delete user.createDates[i];
                        }else{
                            //update array
                            uint256 lastremove = _amount-removeAmount;
                            user.amountDetail[i] = user.amountDetail[i] - lastremove;
                            uint256 amtUSD = user.amountUSD12;
                            user.amountUSD12 = user.amountUSD12 * (1-lastremove/user.amount12);
                            totalWasRemoveUSD = totalWasRemoveUSD+(amtUSD-user.amountUSD12); 
                            removeAmount = removeAmount + lastremove;
                            user.amount = user.amount-lastremove;
                        }
                    }
                }
                if(user.amount == 0){
                    user.dailyReward12 = 0;
                }
                totalStakedAmount = totalStakedAmount.sub(_amount);
                totalStakedAmountInXOS = totalStakedAmountInXOS - totalXOSRemoved;
                pool.totalStaked = pool.totalStaked - _amount;
                pool.totalStakedUSD = pool.totalStakedUSD - totalWasRemoveUSD;
            }
    
            emit Withdraw(msg.sender, _amount);
        }
    }

    function getTotalStakedAmount(uint256 _pid) public view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        return pool.totalStaked;
    }


    function emergencyTokenWithdraw(IBEP20 token,uint256 _amount,address _to) public onlyOwner {
        require(_amount < token.balanceOf(address(this)), 'not enough token');
        token.safeTransfer(address(_to), _amount);
    }

    function LPWithdraw(uint256 _pid,uint256 _amount) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        require(_amount < pool.lpToken.balanceOf(address(this)), 'not enough token');
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
    }
    
    function setDailyReward12(uint256 _dailyReward12) public onlyOwner{
        dailyReward12 = _dailyReward12;
    }
    
    function setContractLength12(uint16 _contractLength12) public onlyOwner{
        contractLength12 = _contractLength12;
    }

    // Update the referral contract address by the owner
    function setReferralAddress(IReferral _referral) external onlyOwner {
        referral = _referral;
    }
    
    // Update top leader rate
    function setTopLeaderRate(uint16 _topLeaderRate) public onlyOwner {
        topLeaderRate = _topLeaderRate;
    }
    
     // Update leader rate
    function setLeaderRate(uint256 _leaderRate) public onlyOwner {
        leaderRate = _leaderRate;
    }
    
    // Update referral rate level 1
    function setReferral1Rate(uint16 _referral1Rate) public onlyOwner {
        referral1Rate = _referral1Rate;
    }
    
    // Update referral rate level 2
    function setReferral2Rate(uint16 _referral2Rate) public onlyOwner {
        referral2Rate = _referral2Rate;
    }
    
    // Update referral rate level 3
    function setReferral3Rate(uint16 _referral3Rate) public onlyOwner {
        referral3Rate = _referral3Rate;
    }
    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        uint256 commissionAmount = _pending.mul(topLeaderRate).div(100);
        if(commissionAmount>0){
            //pay to top Leader
            address tpLeader = ref.getTopLeader(_user);
            if(tpLeader != address(0)){
                rewardToken.safeTransfer(tpLeader, commissionAmount);
                emit ReferralCommissionPaid(_user, tpLeader, commissionAmount);
            }
            
            //pay to Leader
            uint256 commissionAmountLead = _pending*leaderRate/100;
            address lowlead = ref.getLeaderByUser(_user);
            if(lowlead != address(0)){
                rewardToken.safeTransfer(lowlead, commissionAmountLead);
                emit ReferralCommissionPaid(_user, lowlead, commissionAmountLead);
            }
            
            if(address(referral) != address(0)){
                //pay to referral level 1
                //address _referrallevel1 = refer[_user];
                address _referrallevel1 = referral.getReferrer(_user);
                if(_referrallevel1 != address(0)){
                    uint256 commissionAmount1 = _pending.mul(referral1Rate).div(100);
                    rewardToken.safeTransfer(_referrallevel1, commissionAmount1);
                    emit ReferralCommissionPaid(_user, _referrallevel1, commissionAmount1);
                    
                    //pay to referral level 2
                    //address _referrallevel2 = refer[_referrallevel1];
                    address _referrallevel2 = referral.getReferrer(_referrallevel1);
                    if(_referrallevel2 != address(0)){
                        uint256 commissionAmount2 = _pending.mul(referral2Rate).div(100);
                        rewardToken.safeTransfer(_referrallevel2, commissionAmount2);
                        emit ReferralCommissionPaid(_user, _referrallevel2, commissionAmount2);
                        
                        //pay to referral level 3
                        //address _referrallevel3 = refer[_referrallevel2];
                        address _referrallevel3 = referral.getReferrer(_referrallevel2);
                        if(_referrallevel3 != address(0)){
                            uint256 commissionAmount3 = _pending.mul(referral3Rate).div(100);
                            rewardToken.safeTransfer(_referrallevel3, commissionAmount3);
                            emit ReferralCommissionPaid(_user, _referrallevel3, commissionAmount3);
                        }
                    }
                }
            }
        }
    }

    function setTargetSale1(uint256 _targetSale1) external onlyOwner {
        targetSale1 = _targetSale1*1000000000000000000;
    }
    
    function setTargetSale2(uint256 _targetSale2) external onlyOwner {
        targetSale2 = _targetSale2*1000000000000000000;
    }
    
    function setTargetSale3(uint256 _targetSale3) external onlyOwner {
        targetSale3 = _targetSale3*1000000000000000000;
    }
    
}