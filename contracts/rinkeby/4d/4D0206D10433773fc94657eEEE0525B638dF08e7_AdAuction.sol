/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity >=0.8.6;


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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }


}

contract AdAuction is Ownable {
    using SafeMath for uint256;

//    //每轮区块数(竞标初始时长)
//    uint256 public numberOfBlocksPerRound = 720;
//    //延长时间（10分钟）
//    uint256 public extensionOfBlock = 40;
//    //广告时间区块（21小时）
//    uint256 public showBlock = 5040;
//    //广告位
//    uint256 public advertisingSpace = 5;
//    //每小时成块数
//    uint256 public oneHourBlock = 240;

    //每轮区块数
    uint256 public numberOfBlocksPerRound = 20;
    //延长时间
    uint256 public extensionOfBlock = 4;
    //广告时间区块
    uint256 public showBlock = 50;
    //广告位
    uint256 public advertisingSpace = 5;
    //每小时成块数
    uint256 public oneHourBlock =  240;

    address public pttoken = 0xf4883aF3534B2E3d11550c287cB16E9f8365B667;

    address public teamAddress = 0x43eE4A2547fF50ab3139D3A5992BDC86A65D3fDc;

    address blackHoleAddress = 0x000000000000000000000000000000000000dEaD;

    struct AdUser{
       uint256 epoch;
       address userAddress;
       uint256 amount;
        uint256 latestBid;
        //是否中标
       bool whetherToWinTheBid;
       bool returnStatus;
        //下一个出价者溢价20%的奖励
       uint256 bidReward;
    }

    struct Round{
        //位置
        uint256 position;
        uint256 startBlock;
        uint256 endBlock;
        //增加的区块数开始
        uint256 addStartBlock;
        //增加的区块数结束
        uint256 addEndBlock;
        //加时次数
        uint overtime;
        //上一次用户出价
        uint256 lastUserAmount;
        //竞标成功地址
        address lastUserAddress;
        AdUser lastUserData;
        //竞价结束
        bool endOfAuction;
    }


    mapping(uint256 => mapping(uint256 => mapping(address => AdUser))) ledger;
    mapping(uint256 => mapping(address => uint256[])) public userRounds;
    //不同广告位的回合数
    mapping(uint256 => uint256) private epochMap;

    //5个广告位的竞拍状态
    mapping(uint256 => bool) public positionStatus;
    //当前竞价中
    mapping(uint256 => mapping(uint256 => Round)) private currentBidding;
    //竞标成功记录 mapping(广告位 => mapping(回合 => Round))
    mapping(uint256 => mapping(uint256 => Round)) private successAdDataMap;

    //总占比
    uint256 public percentage = 10;
    //支付涨幅占比
    uint256 public increaseInAuctions = 1;
    //溢价返利占比
    uint256 public rebatePercentage = 2;
    //团队占比
    uint256 public proportionOfTeam = 4;
    //初始价格
    uint256 public initialPrice = 100*10 ** 9;


    //开始竞拍
    event startBidding(uint256 indexed adIndex,uint256 startBlock,uint256 indexed epoch,uint256 endBlock);
    //延长竞拍
    event extendBidding(uint256 indexed adIndex,uint256 indexed epoch,uint256 indexed endBlock);
    //参与竞拍
    event participateBidding(uint256 indexed adIndex,uint256 indexed epoch,uint256 amount,address biddingAddress,string image,string description,string name,string category );
    //竞拍成功
    event successfulBidding(uint256 indexed adIndex,uint256 indexed epoch,address userAddress);
    //结束竞拍
    event endOfAuction(uint256 indexed adIndex,uint256 indexed epoch);

    //返还失败竞拍
    event returnFailedBids(uint256 indexed adIndex,uint256 indexed epoch,uint256 amount,uint256 bidReward,address userAddress);
    //是否超过广告位数
    modifier locationExists(uint256 adIndex){
        require(adIndex <= advertisingSpace,"EXCEED_THE_AD_POSITION");
        _;
    }
    bool bidLock = false;
    //锁
    modifier biddingLock(){
        require(!bidLock,"BIDDING_TRY_AGAIN_LATER");
        bidLock = true;
        _;
        bidLock = false;
    }

    function _startBidding(uint256 adIndex) external locationExists(adIndex) onlyOwner{
        require(!positionStatus[adIndex],"UNABLE_TO_CONTINUE_THE_AUCTION");
        uint256 currentRound =  epochMap[adIndex]+1;
        require(currentBidding[adIndex][currentRound-1].endBlock.add(showBlock) < block.number,"THE_LAST_ROUND_OF_IMPRESSIONS_IS_NOT_OVER_YET");
        epochMap[adIndex] = currentRound;
        Round storage round = currentBidding[adIndex][currentRound];
        round.startBlock = block.number;
        round.endBlock = round.startBlock.add(numberOfBlocksPerRound);
        round.position = adIndex;
        round.addEndBlock = round.endBlock;
        round.addStartBlock = round.endBlock.sub(oneHourBlock);
        round.endOfAuction = false;
        positionStatus[adIndex] = true;
        emit startBidding(adIndex,round.startBlock,currentRound,round.endBlock);
    }

    function _endBidding(uint256 adIndex) external locationExists(adIndex) onlyOwner{
        require(positionStatus[adIndex],"AUCTION_HAS_ENDED");
        uint256 currentRound =  epochMap[adIndex];
        Round storage round = currentBidding[adIndex][currentRound];
        require(round.endBlock < block.number,"END_TIME_IS_NOT_REACHED");
        positionStatus[adIndex] = false;
        round.endBlock = block.number;
        round.endOfAuction = true;
        AdUser storage adUser =  ledger[adIndex][currentRound][round.lastUserAddress];
        adUser.whetherToWinTheBid = true;
//        uint256 rebate = 0;
//        if(adUser.latestBid > initialPrice){
//            //前一次出价数量
//            uint256 lastPrice = adUser.latestBid.mul(percentage).div((percentage.add(increaseInAuctions)));
//            //给上一次出价的返利
//            rebate = (adUser.latestBid.sub(lastPrice)).mul(rebatePercentage).div(percentage);
//        }
        if(adPrice[adIndex]> 0){
            uint256 teamAmount = adPrice[adIndex].mul(proportionOfTeam).div(percentage);
            TransferHelper.safeTransfer(pttoken,teamAddress,teamAmount);
            //销毁数量
            uint256 destroyAmount =adPrice[adIndex].sub(teamAmount);
            TransferHelper.safeTransfer(pttoken,blackHoleAddress,destroyAmount);
            emit successfulBidding(adIndex,currentRound,adUser.userAddress);
        }
        emit endOfAuction(adIndex,currentRound);
        Round storage rounds = successAdDataMap[adIndex][currentRound];
        rounds = round;
    }

    mapping(uint256 => uint256) adPrice;
    /**
    *   竞拍合约
    */
    function _auctionBilling(uint256 adIndex,string memory image,string memory description,string memory name,string memory category) external locationExists(adIndex) biddingLock{
        require(positionStatus[adIndex],"THE_IMPRESSION_IS_NOT_OVER_AND_CANNOT_BE_BID");
        //获取竞价回合
        uint256 currentRound = epochMap[adIndex];
        Round storage round = currentBidding[adIndex][currentRound];
        require(!round.endOfAuction,"endOfAuction");
        require(block.number < round.endBlock,"BID_LOCKED");
        address msgSender = _msgSender();
        //计算本次出价
        uint256 thisBid = round.lastUserAmount.div(percentage).add(round.lastUserAmount);
        if(thisBid <= 0){
            thisBid = initialPrice;
        }
        adPrice[adIndex] += thisBid;
        TransferHelper.safeTransferFrom(pttoken,msgSender,address(this),thisBid);
        //获取用户的竞拍信息
        AdUser storage adUser = ledger[adIndex][currentRound][msgSender];
        if(adUser.amount <= 0){
            userRounds[adIndex][msgSender].push(currentRound);
            adUser.epoch = currentRound;
            adUser.whetherToWinTheBid =false;
            adUser.returnStatus = false;
            adUser.userAddress = msgSender;
        }
        adUser.amount = adUser.amount.add(thisBid);
        addBidReward(adIndex,currentRound,thisBid,round.lastUserAddress);
        adUser.latestBid = thisBid;
        round.lastUserAmount = thisBid;
        round.lastUserAddress = msgSender;
        round.lastUserData = adUser;
        //如果当前区块已经超过 加时的结束时间 说明1个小时的限制已经过去 有人继续竞拍 1小时内可以延长时间
        if(block.number > round.addEndBlock){
            round.addEndBlock = round.endBlock;
            round.addStartBlock = round.endBlock.sub(oneHourBlock);
            round.overtime = 0;
        }
        //判断是否在增加时间的区块内
        if(block.number < round.addEndBlock && block.number > round.addStartBlock){
            //判断增加次数
            if(round.overtime < 6){
                round.endBlock +=  extensionOfBlock;
                round.overtime += 1;
                emit extendBidding(adIndex,currentRound,round.endBlock);
            }
        }
        emit participateBidding(adIndex,currentRound,thisBid,msgSender,image,description,name,category);
    }

    function showAdUser(uint256 adIndex,uint256 currentRound,address selAddress) view external returns(uint256,address,uint256,uint256,bool,bool,uint256){
        AdUser storage adUser =  ledger[adIndex][currentRound][selAddress];
        return(adUser.epoch,adUser.userAddress,adUser.amount,adUser.latestBid,adUser.whetherToWinTheBid,adUser.returnStatus,adUser.bidReward);
    }

    function addBidReward(uint256 adIndex,uint256 currentRound,uint256 bidPrice,address lastAddress) internal {
        AdUser storage adUser = ledger[adIndex][currentRound][lastAddress];
        uint256 reward = (bidPrice.sub(adUser.latestBid)).mul(rebatePercentage).div(percentage);
        adUser.bidReward += reward;
        adPrice[adIndex] = adPrice[adIndex].sub(reward).sub(adUser.latestBid);
    }


    function _redemption(uint256 epoch,uint256 adIndex) external locationExists(adIndex){

        address msgSender = _msgSender();
        AdUser storage adUser = ledger[adIndex][epoch][msgSender];
        require(!adUser.returnStatus,"CANNOT_BE_REDEEMED_REPEATEDLY");
        Round storage round = currentBidding[adIndex][epoch];
        require(round.endOfAuction,"The bid has not been settled, and the reward cannot be obtained");
        uint256 refund;
        //竞标成功
        if(adUser.whetherToWinTheBid){
            refund = adUser.amount.sub(adUser.latestBid).add(adUser.bidReward);
        }else{
            refund = adUser.bidReward.add(adUser.amount);
        }
        require(refund > 0,"NO_REDEMPTION_AMOUNT_RECEIVED");
        TransferHelper.safeTransfer(pttoken,msgSender,refund);
        adUser.returnStatus = true;
        emit returnFailedBids(adIndex,epoch,adUser.whetherToWinTheBid?adUser.amount.sub(adUser.latestBid):adUser.amount,adUser.bidReward,msgSender);
    }


}