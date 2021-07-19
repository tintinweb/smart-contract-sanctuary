//SourceUnit: bee_07_06.sol

pragma solidity ^0.5.0;

/**
 * @title BT
**/
interface tokenTransfer {
    function totalSupply() external view returns (uint256);
    function balanceOf(address receiver) external view returns(uint256);
    function transfer(address receiver, uint amount) external;
    function transferFrom(address _from, address _to, uint256 _value) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IJustExchange{
    
  /**
   * @notice external price function for TRX to Token trades with an exact input.
   * @param trx_sold Amount of TRX sold.
   * @return Amount of Tokens that can be bought with input TRX.
   */
  function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);

  /**
   * @notice external price function for TRX to Token trades with an exact output.
   * @param tokens_bought Amount of Tokens bought.
   * @return Amount of TRX needed to buy output Tokens.
   */
  function getTrxToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256);

  /**
   * @notice external price function for Token to TRX trades with an exact input.
   * @param tokens_sold Amount of Tokens sold.
   * @return Amount of TRX that can be bought with input Tokens.
   */
  function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);

  /**
   * @notice external price function for Token to TRX trades with an exact output.
   * @param trx_bought Amount of output TRX.
   * @return Amount of Tokens needed to buy output TRX.
   */
  function getTokenToTrxOutputPrice(uint256 trx_bought) external view returns (uint256);
}


contract Util {
    uint usdtWei = 1e6;

    //根据代数和业绩获取返现百分比
    function getRecommendScaleByAmountAndTim(uint performance,uint times) internal view returns(uint){
        if (times == 1) {
            return 7;
        }
        if(performance >= 2000*usdtWei && performance < 6000*usdtWei){
            if (times == 2){
                return 5;
            }
            if(times == 3){
                return 4;
            }
        }
        if(performance >= 6000*usdtWei && performance < 10000*usdtWei){
            if (times == 2){
                return 5;
            }
            if(times == 3){
                return 4;
            }
            if(times >= 4 && times <=8){
                return 2;
            }
        }
        if(performance >= 10000*usdtWei && performance < 20000*usdtWei){
            if (times == 2){
                return 5;
            }
            if(times == 3){
                return 4;
            }
            if(times >= 4 && times <=13){
                return 2;
            }
        }
        if(performance >= 20000*usdtWei && performance < 30000 * usdtWei){
            if (times == 2){
                return 5;
            }
            if(times == 3){
                return 4;
            }
            if(times >= 4 && times <=15){
                return 2;
            }
            if(times >= 16 && times <=21){
                return 1;
            }
        }

        if(performance >= 30000*usdtWei){
            if (times == 2){
                return 5;
            }
            if(times == 3){
                return 4;
            }
            if(times >= 4 && times <=15){
                return 2;
            }
            if(times >= 16 && times <=30){
                return 1;
            }
        }

        return 0;
    }
    
    
    
    function getRecommendTimes(uint performance) internal view returns(uint){
        if(performance >= 2000*usdtWei && performance < 6000*usdtWei){
            return 3;
        }
        if(performance >= 6000*usdtWei && performance < 10000*usdtWei){
            return 8;
        }
        if(performance >= 10000*usdtWei && performance < 20000*usdtWei){
            return 13;
        }
        if(performance >= 20000*usdtWei && performance < 30000 * usdtWei){
            return 21;
        }

        if(performance >= 30000*usdtWei){
            return 30;
        }
        return 1;
    }

    //zeng chan
    function getDynLevel(uint myPerformance,uint hashratePerformance, uint smallPerformance) internal view returns(uint) {
        if (myPerformance < 2000 * usdtWei ) {
            return 0;
        }
        if (hashratePerformance >= 800000 * usdtWei && smallPerformance >= 300000 * usdtWei) {
            return 5;
        }
        if (hashratePerformance >= 600000 * usdtWei && smallPerformance >= 200000 * usdtWei) {
            return 4;
        }
        if (hashratePerformance >= 300000 * usdtWei && smallPerformance >= 100000 * usdtWei) {
            return 3;
        }
        if (hashratePerformance >= 30000 * usdtWei  && smallPerformance >= 20000 * usdtWei) {
            return 2;
        }
        if (hashratePerformance >= 2000 * usdtWei) {
            return 1;
        }
        return 0;
    }

    function compareStr(string memory _str, string memory str) internal pure returns(bool) {
        if (keccak256(abi.encodePacked(_str)) == keccak256(abi.encodePacked(str))) {
            return true;
        }
        return false;
    }

}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context, Ownable {
    using Roles for Roles.Role;

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelist(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelist(_msgSender()) || isOwner(), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function addWhitelist(address account) public onlyWhitelistAdmin {
        _addWhitelist(account);
    }

    function removeWhitelist(address account) public onlyOwner {
        _whitelistAdmins.remove(account);
    }

    function isWhitelist(address account) private view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function _addWhitelist(address account) internal {
        _whitelistAdmins.add(account);
    }

}

contract CoinTokenWrapper {

    using SafeMath for *;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }
}

contract Bee is Util, WhitelistAdminRole,CoinTokenWrapper {

    string constant private name = "Bee";

    struct User{
        uint id;
        string referrer;
        uint dynamicLevel;
        uint allInvest;
        uint freezeAmount;
        uint allDynamicAmount;
        uint hisDynamicAmount;

        uint performance;

        uint nodePerformance;
        Invest[] invests;
        uint staticFlag;

        uint hashratePerformance;

        uint hisBtAward;

        uint256 vipBonus;

        uint256 vipTotalBonus;

        uint checkpoint;

        address[] sub;

        // uint subIndex;
    }

    struct UserGlobal {
        uint id;
        address userAddress;
        string inviteCode;
        string referrer;
    }

    struct Invest{
        uint investAmount;
        uint limitAmount;
        uint earnAmount;
    }


    uint investMoney;

    uint residueMoney;
    uint beeDestory;
    uint uid = 0;
    uint rid = 1;

    mapping (uint => mapping(address => User)) userRoundMapping;
    mapping(address => UserGlobal) userMapping;
    mapping (string => address) addressMapping;
    mapping (uint => address) indexMapping;
    

    //==============================================================================
    //TNfqtctaqEMCENFShroMNCfmSMVYied7vP
    address payable destructionAddr = address(0x8b50F0F5507dCa4D5a2AB3a45BD8aD17347407f9);
    //TGVXfWnBa2PQf4PSStqrkTVBTd3cDe4BDB
    address payable marketAddr = address(0x478CD00aA07b6b442187B300dbDdC857d9ffdc58);
    //TPvPnW59HtSArgugGy5yyqodCPdeMVKtce
    address payable coinPriceAddr = address(0x990983C36Ce06a3eC97024aB2908796c877975e0);
    //TT8H65DQEhRPjX77LXZkaykioqfLGWTguA
    address payable outAddr = address(0xBC314b0DFEe7Df2e329cf5755dfAe46B45ad465c);
    //
    address payable blackAddr = address(1);
    
    address trxUsdtExchange = address(0xA2726afbeCbD8e936000ED684cEf5E2F5cf43008);
   //
    address trxBeeExchange = address(0xd9531Be49A4D0B9F9fE1ce190ba58de2b29a892a);
    
    //TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t
    address uTokenAddr = address(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);
    // address uTokenAddr = address(0xA6E8699A876B8Bd393e27969d513B9a16aa702c6);
    tokenTransfer uToken = tokenTransfer(uTokenAddr);
    //TYz2awuo1Ba75ZWSqQWPJmDmDc1gRUmDGj
    address beeTokenAddr = address(0xFc729D48860047e7BbfC42b7644723BA300AA31D);
    // address beeTokenAddr = address(0x07cc6bBE1eA85a39EE3Fe359750a553A906fBf4E);
    tokenTransfer beeToken = tokenTransfer(beeTokenAddr);


    uint256 turnover;
    uint256 bonusPool;

    uint256 period = 1 days;
    uint256 startTime = block.timestamp;
    uint256 endTime = startTime.add(period);


    //
    uint256 status = 0;
    //utc+8 2021-03-12 19:41:05
    uint256 public starttime = 1615549265;
    //
    uint256 public periodFinish = 0;
    //rate
    uint256 public rewardRate = 0;
    //
    uint256 public lastUpdateTime;
    //
    uint256 public rewardPerTokenStored;
    //
    mapping(address => uint256) public userRewardPerTokenPaid;
    //
    mapping(address => uint256) public rewards;

    //---------------------------------global vip
    struct Bonus {
        uint256 vip1AvgBonus;
        uint256 vip2AvgBonus;
        uint256 vip3AvgBonus;
        uint256 vip4AvgBonus;
        uint256 vip5AvgBonus;
    }


    uint256 public shareBonusCount = 1;
    //
    mapping (uint => Bonus) public gifts;

    //uid -> 1
    mapping (uint => uint) vip1s;
    mapping (uint => uint) vip2s;
    mapping (uint => uint) vip3s;
    mapping (uint => uint) vip4s;
    mapping (uint => uint) vip5s;

    //vip rate
    uint256[] bonusRate = [15,9,7,5,4];

    uint256[] public vipTodayBonus = [0,0,0,0,0];

    uint256[] public vipHisBonus = [0,0,0,0,0];
    //vip
    uint256[] public vipLength = [0,0,0,0,0];
    
    event LogInvestIn(address indexed who, uint indexed uid, uint amount, uint time, string inviteCode, string referrer);
    event LogWithdrawProfit(address indexed who, uint indexed uid, uint amount, uint time);
    event LogGameWinner(address indexed who, uint amount, uint time,string gameType);
    event UserLevel(address indexed user,uint256 p, uint256 level);
    event LogPullUpPrices(address user,uint256 amt);
    

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);



    //==============================================================================
    // Constructor
    //==============================================================================
    constructor () public {
        
    }

    function () external payable {
    }

    modifier isHuman() {
        address addr = msg.sender;
        uint codeLength;

        assembly {codeLength := extcodesize(addr)}
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    function getInValueJust(uint256 usdtValue) public view returns(uint256 usdt,uint256 beeCoin){
        IJustExchange eFeeTrx = IJustExchange(trxBeeExchange);
        IJustExchange eUsdtTrx = IJustExchange(trxUsdtExchange);
        uint256 uValue = usdtValue.mul(usdtWei);
        uint256 feeUValue = usdtValue.div(4);
        
        uint256 trxAmount = eUsdtTrx.getTokenToTrxInputPrice(usdtWei);
        uint256 feeAmount = eFeeTrx.getTrxToTokenInputPrice(trxAmount);
        return (uValue, feeUValue.mul(feeAmount));
    }  
    
    function getInValueJust2(uint256 usdtValue) public view returns(uint256 usdt,uint256 beeCoin){
        // IJustExchange eFeeTrx = IJustExchange(trxBeeExchange);
        // IJustExchange eUsdtTrx = IJustExchange(trxUsdtExchange);
        uint256 uValue = usdtValue.mul(usdtWei);
        return (uValue, usdtValue.mul(1e18).div(4));
    } 


    function investIn(string memory inviteCode,string memory referrer,uint256 usdtValue)
    public
    updateReward(msg.sender)
    checkStart
    checkhalve
    isHuman()
    {
        (uint256 uValue,uint256 beeValue) = getInValueJust(usdtValue);
        require(uValue >= 100*usdtWei, "The minimum bet is 100 USDT");
        require(uValue == uValue.div(usdtWei).mul(usdtWei), "invalid msg value");
        require(uToken.balanceOf(msg.sender) >= uValue, "usdt not enough");
        require(beeToken.balanceOf(msg.sender) >= beeValue, "bee not enough");


        uToken.transferFrom(msg.sender,address(this),uValue);
        beeToken.transferFrom(msg.sender,address(this),beeValue);


        UserGlobal storage userGlobal = userMapping[msg.sender];
        if (userGlobal.id == 0) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            address referrerAddr = getUserAddressByCode(referrer);
            require(uint(referrerAddr) != 0, "referer not exist");
            require(referrerAddr != msg.sender, "referrer can't be self");
            require(!isUsed(inviteCode), "invite code is used");
            registerUser(msg.sender, inviteCode, referrer, referrerAddr);
        }


        User storage user = userRoundMapping[rid][msg.sender];
        if (user.id != 0) {
            user.allInvest = user.allInvest.add(uValue);
            user.freezeAmount = user.freezeAmount.add(uValue);
        } else {
            user.id = userGlobal.id;
            user.freezeAmount = uValue;
            user.allInvest = uValue;
            user.referrer = userGlobal.referrer;
        }

        uint256 uPower = uValue.mul(5).div(4);


        Invest memory invest = Invest(uValue, uValue.mul(3), 0);
        user.invests.push(invest);


        investMoney = investMoney.add(uPower);

        uint256 beehalf = beeValue.div(2);
        
        beeDestory = beeDestory.add(beehalf);

        beeToken.transfer(blackAddr,beehalf);

        beeToken.transfer(marketAddr,beehalf);
        

        uToken.transfer(coinPriceAddr,uValue.mul(5).div(100));

        uToken.transfer(marketAddr,uValue.div(10));


        tjUserDynamicTree(userGlobal.referrer,uValue,uPower);


        fixedDepositMining(uValue);


        statisticOfDay();



        super.stake(uValue);
        emit LogInvestIn(msg.sender, userGlobal.id, uValue, now, userGlobal.inviteCode, userGlobal.referrer);
    }


    function tjUserDynamicTree(string memory referrer, uint investAmount,uint uPower) private {
        string memory tmpReferrer = referrer;

        uint dynAmt = investAmount;//.mul(55).div(100);

        uint totalTmpAmount;
        for (uint i = 1; i <= 30; i++) {
            if (compareStr(tmpReferrer, "")) {
                break;
            }
            address tmpUserAddr = addressMapping[tmpReferrer];
            User storage calUser = userRoundMapping[rid][tmpUserAddr];
            if (calUser.id == 0) {
                break;
            }
            
            calUser.hashratePerformance = calUser.hashratePerformance.add(uPower);


            if(i == 1 || i == 2){
                if(i == 1){
                    calUser.performance = calUser.performance.add(uPower);
                }
                calUser.nodePerformance = calUser.nodePerformance.add(uPower);
            }


            if(calUser.freezeAmount <= 0){
                tmpReferrer = calUser.referrer;
                continue;
            }
            

            uint recommendSc = getRecommendScaleByAmountAndTim(calUser.nodePerformance, i);
            if (recommendSc != 0) {



                uint tmpDynamicAmount = dynAmt.mul(recommendSc).div(100);

                Invest storage invest = calUser.invests[calUser.staticFlag];
                invest.earnAmount = invest.earnAmount.add(tmpDynamicAmount);
                if (invest.earnAmount >= invest.limitAmount) {
                    calUser.staticFlag = calUser.staticFlag.add(1);
                    calUser.freezeAmount = calUser.freezeAmount.sub(invest.investAmount);

                    uint correction = invest.earnAmount.sub(invest.limitAmount);
                    if(correction > 0){
                        tmpDynamicAmount = tmpDynamicAmount.sub(correction);
                        invest.earnAmount = invest.limitAmount;
                    }
                }

                calUser.allDynamicAmount = calUser.allDynamicAmount.add(tmpDynamicAmount);
                calUser.hisDynamicAmount = calUser.hisDynamicAmount.add(tmpDynamicAmount);
                totalTmpAmount = totalTmpAmount.add(tmpDynamicAmount);
            }

            tmpReferrer = calUser.referrer;
        }


        residueMoney = residueMoney.add(dynAmt.mul(55).div(100).sub(totalTmpAmount));
        outIncentives();
    }

    //
    function withdrawProfit() updateReward(msg.sender) checkhalve checkIncreaseCoin public{
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");

        uint resultMoney = user.allDynamicAmount;
        if (resultMoney > 0) {
            takeInner(msg.sender,resultMoney);
            user.allDynamicAmount = 0;
            emit LogWithdrawProfit(msg.sender, user.id, resultMoney, now);
        }


        // upDynamicLevel();
        

        // settlementBonus();
    }



    function marketIncentives() private {
        uint resultMoney = residueMoney;
        takeInner(marketAddr,resultMoney);
        residueMoney = 0;
        emit LogPullUpPrices(marketAddr,resultMoney);
    }
    
    function outIncentives() public {
        uint resultMoney = residueMoney;
        takeInner(outAddr,resultMoney);
        residueMoney = 0;
        emit LogPullUpPrices(marketAddr,resultMoney);
    }

    function fixedDepositMining(uint256 money) private {
        uint miningAmount = money.mul(30).div(100);
        takeInner(destructionAddr,miningAmount);
    }

    function tjUserSmail1(User memory user) private view returns (uint256){
        uint myPerformance = user.hashratePerformance;
        uint256 uMax =0;
        if (user.sub.length == 0){
            return 0;
        }
        for (uint i=0;i<user.sub.length;i++){
            address ua = user.sub[i];
            User memory calUser = userRoundMapping[rid][ua];
            uint256 userPower = calUser.hashratePerformance.add(calUser.allInvest.mul(5).div(4));
            if (uMax < userPower){
                uMax = userPower;
            }
        }
        if (myPerformance> uMax){
            return myPerformance.sub(uMax);
        }else{
            return 0;
        }
    }

    
    
    function tjUserSmail(User memory user) private view returns (uint256){
        uint myPerformance = user.hashratePerformance;
        
        uint256 uMax =0;
        if (user.sub.length == 0){
            return 0;
        }
        for (uint i=0;i<user.sub.length;i++){
            address ua = user.sub[i];
            User memory calUser = userRoundMapping[rid][ua];
            uint256 userPower = calUser.hashratePerformance.add(calUser.allInvest.mul(5).div(4));
            
            if (uMax < userPower){
                uMax = userPower;
            }
        }
        if (myPerformance> uMax){
            return myPerformance.sub(uMax);
        }else{
            return 0;
        }
    }
    

    function tjUserSmail(address userAddress) public view returns (uint256){
        User memory user = userRoundMapping[rid][userAddress];
        return tjUserSmail(user);
    }
    
    function getUserSub(address userAddress) public view returns(address[] memory){
        User memory user = userRoundMapping[rid][userAddress];
        return user.sub;
    }


    function upDynamicLevel() private
    {
        User storage calUser = userRoundMapping[rid][msg.sender];

        uint dynamicLevel = calUser.dynamicLevel;
        uint newDynLevel = getDynLevel(calUser.performance,calUser.hashratePerformance,tjUserSmail(calUser));
        if(newDynLevel != 0 && dynamicLevel != newDynLevel){

            getBonus();
            //update checkpoint
            if(calUser.checkpoint == 0){
                calUser.checkpoint = shareBonusCount;
            }

            //
            useStatisticalBonusInner();

            //up level
            calUser.dynamicLevel = newDynLevel;


            doRemoveVip(calUser.id,dynamicLevel);
            doAddVip(calUser.id,newDynLevel);
            emit UserLevel(msg.sender,calUser.hashratePerformance,newDynLevel);
        }
    }

    function isEnoughBalance(uint sendMoney) private view returns (bool, uint){
        uint _balance = uToken.balanceOf(address(this));
        if (sendMoney >=  _balance) {
            return (false, _balance);
        } else {
            return (true, sendMoney);
        }
    }

    function takeInner(address payable userAddress, uint money) private {
        uint sendMoney;
        (, sendMoney) = isEnoughBalance(money);
        if (sendMoney > 0) {
            uToken.transfer(userAddress,sendMoney);
        }
    }

    function isUsed(string memory code) public view returns(bool) {
        address user = getUserAddressByCode(code);
        return uint(user) != 0;
    }

    function getUserAddressByCode(string memory code) public view returns(address) {
        return addressMapping[code];
    }

    function getMiningInfo(address _user) public view returns(uint[43] memory ct,string memory inviteCode, string memory referrer) {
        User memory userInfo = userRoundMapping[rid][_user];

        uint256 earned = earned(_user);


        ct[0] = totalSupply();

        ct[1] = turnover;
 
        ct[2] = userInfo.hashratePerformance;
 
        ct[3] = tjUserSmail(userInfo);

        ct[4] = userInfo.hisBtAward;

        ct[5] = userInfo.dynamicLevel;

        ct[6] = earned;

        ct[7] = status;

        ct[8] = bonusPool;


        ct[9] = vipTodayBonus[0];
        ct[10] = vipTodayBonus[1];
        ct[11] = vipTodayBonus[2];
        ct[12] = vipTodayBonus[3];
        ct[13] = vipTodayBonus[4];


        ct[14] = vipHisBonus[0];
        ct[15] = vipHisBonus[1];
        ct[16] = vipHisBonus[2];
        ct[17] = vipHisBonus[3];
        ct[18] = vipHisBonus[4];


        ct[19] = vipLength[0];
        ct[20] = vipLength[1];
        ct[21] = vipLength[2];
        ct[22] = vipLength[3];
        ct[23] = vipLength[4];


        ct[24] = unWithdrawBonus(_user);

        ct[25] = basicCoin;

        ct[26] = increaseNumber;

        ct[27] = userInfo.vipBonus;

        ct[28] = userInfo.vipTotalBonus;
 
        ct[29] = userInfo.checkpoint;


        ct[30] = investMoney;
 
        ct[31] = residueMoney;

        //USER INFO

        ct[32] = userInfo.dynamicLevel;

        ct[33] = userInfo.allInvest;

        ct[34] = userInfo.freezeAmount;

        ct[35] = userInfo.allDynamicAmount;

        ct[36] = userInfo.hisDynamicAmount;

        ct[37] = userInfo.staticFlag;

        ct[38] = userInfo.invests.length;

        ct[39] = userInfo.performance;

        ct[40] = userInfo.nodePerformance;

        ct[41] = periodFinish;
 
        ct[42] = beeDestory;

        inviteCode = userMapping[_user].inviteCode;
        referrer = userMapping[_user].referrer;

        return (
        ct,
        inviteCode,
        referrer
        );
    }

    function getUserAssetInfo(address user, uint i) public view returns(
        uint[5] memory ct
    ) {
        User memory userInfo = userRoundMapping[rid][user];
        ct[0] = userInfo.invests.length;
        if (ct[0] != 0) {
            ct[1] = userInfo.invests[i].investAmount;
            ct[2] = userInfo.invests[i].limitAmount;
            ct[3] = userInfo.invests[i].earnAmount;
            ct[4] = 0;
        } else {
            ct[1] = 0;
            ct[2] = 0;
            ct[3] = 0;
            ct[4] = 0;
        }
    }


    function registerUserInfo(address user, string calldata inviteCode, string calldata referrer,address  referrerAddress) external onlyOwner {
        registerUser(user, inviteCode, referrer, referrerAddress);
    }

    function registerUser(address user, string memory inviteCode, string memory referrer, address  referrerAddress) private {
        UserGlobal storage userGlobal = userMapping[user];
        uid++;
        userGlobal.id = uid;
        userGlobal.userAddress = user;
        userGlobal.inviteCode = inviteCode;
        userGlobal.referrer = referrer;

        addressMapping[inviteCode] = user;
        indexMapping[uid] = user;

        User storage userReferrer = userRoundMapping[rid][referrerAddress];
        userReferrer.sub.push(user);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return SafeMath.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }

    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }


    function getReward() public updateReward(msg.sender) checkhalve checkIncreaseCoin {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");

        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            uint staticReward = reward.mul(60).div(100);

            user.hisBtAward = user.hisBtAward.add(staticReward);

            turnover = turnover.add(staticReward);

            rewards[msg.sender] = 0;
            beeToken.transfer(msg.sender, staticReward);
            emit RewardPaid(msg.sender, staticReward);

            uint dynReward = reward.mul(40).div(100);
            bonusPool = bonusPool.add(dynReward);

            for(uint i = 0;i<bonusRate.length;i++){
                uint amt = reward.mul(bonusRate[i]).div(100);
                vipTodayBonus[i] = vipTodayBonus[i].add(amt);
                vipHisBonus[i] = vipHisBonus[i].add(amt);
            }
        }


        upDynamicLevel();
        

        statisticOfDay();
    }
    
    
     function statisticOfDay() private {
        if(block.timestamp < endTime){
            return;
        }
        //update time
        startTime = endTime;
        endTime = startTime.add(period);
        
        settlementBonus();
    }


    function settlementBonus() private {
        for(uint i = 0;i<vipTodayBonus.length;i++){
            uint todayBonus = vipTodayBonus[i];
            if(todayBonus == 0){
                break;
            }

            uint length = vipLength[i];
            if(length == 0){
                length = 1;
            }

            uint256 avgBonus = todayBonus.div(length);
            if(i == 0){
                gifts[shareBonusCount].vip1AvgBonus = avgBonus;
            }else if(i == 1){
                gifts[shareBonusCount].vip2AvgBonus = avgBonus;
            }else if(i == 2){
                gifts[shareBonusCount].vip3AvgBonus = avgBonus;
            }else if(i == 3){
                gifts[shareBonusCount].vip4AvgBonus = avgBonus;
            }else if (i == 4){
                gifts[shareBonusCount].vip5AvgBonus = avgBonus;
            }


            vipTodayBonus[i] = 0;
        }
        shareBonusCount++;
    }


    function useStatisticalBonusInner() private {
        User storage user = userRoundMapping[rid][msg.sender];
        uint totalAmt = unWithdrawBonus(msg.sender);
        if(totalAmt > 0){
            user.vipBonus = user.vipBonus.add(totalAmt);
            user.vipTotalBonus = user.vipTotalBonus.add(totalAmt);
        }
        //must update checkpoint
        user.checkpoint = shareBonusCount;
    }

    
    function unWithdrawBonus(address _add) public view returns(uint) {
        User storage user = userRoundMapping[rid][_add];
        if(user.id == 0){
            return 0;
        }

        uint level = user.dynamicLevel;
        uint checkpoint = user.checkpoint;

        uint totalAmt = 0;
        for(uint i = checkpoint;i<shareBonusCount;i++){
            if(level == 1){
                totalAmt = totalAmt.add(gifts[i].vip1AvgBonus);
            }else if(level == 2){
                totalAmt = totalAmt.add(gifts[i].vip2AvgBonus);
            }else if(level == 3){
                totalAmt = totalAmt.add(gifts[i].vip3AvgBonus);
            }else if(level == 4){
                totalAmt = totalAmt.add(gifts[i].vip4AvgBonus);
            }else if(level == 5){
                totalAmt = totalAmt.add(gifts[i].vip5AvgBonus);
            }
        }
        return totalAmt;
    }

    function getBonus() public updateReward(msg.sender) checkhalve checkIncreaseCoin {
        User storage user = userRoundMapping[rid][msg.sender];
        require(user.id > 0, "user not exist");

        useStatisticalBonusInner();

        if(user.vipBonus > 0){
            uint dynReward = user.vipBonus;

            user.hisBtAward = user.hisBtAward.add(dynReward);
            turnover = turnover.add(dynReward);

            beeToken.transfer(msg.sender, dynReward);
            user.vipBonus = 0;
            emit RewardPaid(msg.sender, dynReward);
        }


        // upDynamicLevel();
        

        // settlementBonus();
    }

    modifier checkhalve(){
        if(status == 0){
            if (block.timestamp >= periodFinish) {
                changeNotifyRewardAmount();
            }
        }
        _;
    }


    function correctionStatistics() external onlyWhitelistAdmin{
         //分红
        statisticOfDay();
    }

    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }

    modifier checkIncreaseCoin(){
        increaseCoin(investMoney);
        _;
    }

    function notifyRewardAmount()
    external
    onlyWhitelistAdmin
    updateReward(address(0))
    {
        uint256 reward = 10000 * 30 * 1e18;
        uint256 INIT_DURATION = 30 days;
        // uint256 reward = 10000.mul(1e18).div(24);
        // uint256 INIT_DURATION = 60 minutes;
        basicCoin =10000* 1e18;
        rewardRate = reward.div(INIT_DURATION);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(INIT_DURATION);
        emit RewardAdded(reward);
    }

    function changeNotifyRewardAmount() private {
        status = 1;
        basicCoin =5000 * 1e18;
        uint256 reward = 5000 * 400 * 1e18;
        uint256 DURATION = 400 days;

        rewardRate = reward.div(DURATION);
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }


    uint public basicCoin = 5000 * 1e18;
    //increase Number
    uint public increaseNumber = 0;

    uint increaseUnits = 1000 * 1e18;

    uint public increaseCondition = 500000 * usdtWei;

    event LogIncreaseCoin(uint256 _newBasicCoin,uint256 _btBalance,uint _rewardRate,uint256 _periodFinish);


    function increaseCoin(uint256 total) public {
        if(status == 0 || total < increaseCondition){
            return;
        }

        uint increaseGaps = total.div(increaseCondition);
        if(increaseGaps > increaseNumber){
            //last balance
            uint balance = beeToken.balanceOf(address(this));
            if(balance > basicCoin){
                uint difference = increaseGaps.sub(increaseNumber);
                basicCoin = basicCoin.add(difference.mul(increaseUnits));
                increaseNumber = increaseGaps;

                uint newDuration = balance.div(basicCoin).mul(1 days);

                rewardRate = balance.div(newDuration);
                periodFinish = block.timestamp.add(newDuration);
                emit LogIncreaseCoin(basicCoin,balance,rewardRate,periodFinish);
            }
        }
    }


    function doAddVip(uint _uid,uint _level) private
    {
        uint8 flag = 1;
        if(_level == 1){
            vip1s[_uid] = flag;
        }else if(_level == 2){
            vip2s[_uid] = flag;
        }else if(_level == 3){
            vip3s[_uid] = flag;
        }else if(_level == 4){
            vip4s[_uid] = flag;
        }

        uint _index = _level - 1;
        vipLength[_index] = vipLength[_index].add(1);
    }


    function doRemoveVip(uint _uid,uint _level) private
    {
        if(doContainsVip(_uid,_level)){
            uint8 flag = 0;
            if(_level == 1){
                vip1s[_uid] = flag;
            }else if(_level == 2){
                vip2s[_uid] = flag;
            }else if(_level == 3){
                vip3s[_uid] = flag;
            }else if(_level == 4){
                vip4s[_uid] = flag;
            }

            uint _index = _level - 1;
            vipLength[_index] = vipLength[_index].sub(1);
        }
    }


    function doContainsVip(uint _uid,uint _level) public view returns (bool)
    {
        uint8 flag = 1;
        if(_level == 1){
            return vip1s[_uid] == flag;
        }else if(_level == 2){
            return vip2s[_uid] == flag;
        }else if(_level == 3){
            return vip3s[_uid] == flag;
        }else if(_level == 4){
            return vip4s[_uid] == flag;
        }
        return false;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div zero"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "lower sub bigger");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "overflow");

        return c;
    }

}