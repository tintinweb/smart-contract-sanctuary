/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


}

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

contract LuckyBoxBNB is Ownable{
    using SafeMath for uint256;
    address payable private _lotteryMoneyAddress;
    //奖池内容
    LotteryContextModel _lotteryContextConfig;
    struct LotteryContextModel{
        uint256 minBetAmount;//最低投注额
        uint256 maxBetAmount;//最高投注额
        uint256 drawAmount;//开奖金额
        string lotteryName;//赌厅名称
    }
    //档期对象
    struct LotteryScheduleModel{
        uint8 roundId;//奖池编号
        uint256 sumAmount;
        address[] userList;
        mapping(address=>uint256) userAmount;
        address payable winner;
        uint8 status;//1 进行中  2 待结算  3 结算完成
        uint blockNumber;
    }

    //中奖记录对象
    struct LotteryWinnerModel{
        uint8 roundId;//奖池编号
        uint256 sumMoney;
        address winner;
    }

    //彩票档期
    uint8 public _roundNum;

    //彩票档期_明细
    mapping (uint8 => LotteryScheduleModel) private _lotterySchedule;

    //彩票中奖记录对象
    LotteryWinnerModel[] private _lotteryWinner;


    //shoushui收税 比例
    uint8 private _txRate=10;
    //中奖人获奖比例(例：当获奖金比例为90%时，该值为90.)
    uint8 private _rewardRate=90;
    //展示中奖记录数量
    uint8 private _showWinnerRecordCount=10;
    //展示投注记录数量
    uint8 private _showBetRecordCount=10;
    //有效的结算间隔  如果刚结束十个区块再不开奖
    uint8 public _blockNumberInterval=10;
    uint256 private _gameBoxRate=10**16;

    constructor(){
        _lotteryContextConfig=LotteryContextModel(5*_gameBoxRate,10*_gameBoxRate,20*_gameBoxRate,"las vegas"); //初级厅
        _lotteryMoneyAddress=payable(owner());
        _createLotterySchedule();
    }
    //创建新赌厅档期
    function _createLotterySchedule() private {
        LotteryScheduleModel storage schedule = _lotterySchedule[++_roundNum];
        schedule.roundId=_roundNum;
        schedule.status=1;
    }

    //赌厅配置
    function getLotteryConfig() external view returns(uint256,uint256,uint256,string memory){
        //1;投注总额
        //2;最低投注额
        //3;最高投注额
        //4;赌厅名称
        return(_lotteryContextConfig.drawAmount,_lotteryContextConfig.minBetAmount,_lotteryContextConfig.maxBetAmount,_lotteryContextConfig.lotteryName);
    }

    //投注详情
    function getLotteryScheduleDetail() external view returns(uint8,uint256,uint8,uint256,uint256,address[] memory,uint256[] memory){

        //1;奖池编号
        //2;投注总额
        //3;1 进行中  2 待结算  3 结算完成
        //4;当前档期投注总人数
        //5;当前用户投注金额 未唤起钱包 可为空
        //6;投注用户列表
        //7;投注金额列表

        uint8 roundId=_roundNum;
        uint256 sumAmount= _lotterySchedule[roundId].sumAmount;
        uint8 status= _lotterySchedule[roundId].status;
        uint256 userSum= _lotterySchedule[roundId].userList.length;
        uint256  userAmount=_lotterySchedule[roundId].userAmount[_msgSender()];

        address[] memory userArr;
        uint256[] memory userAmountRecord;
        if(userSum<=0){
            return(roundId,sumAmount,status,userSum,userAmount,userArr,userAmountRecord);
        }
        uint minIndex=0;
        if(userSum>_showBetRecordCount){
            userArr = new address[](_showBetRecordCount);
            userAmountRecord = new uint256[](_showBetRecordCount);
            minIndex= userSum-_showBetRecordCount;
        }else{
            userArr = new address[](userSum);
            userAmountRecord = new uint256[](userSum);
        }
        uint value=0;
        for(uint index =userSum; index > minIndex; index--){
            userArr[value]=_lotterySchedule[roundId].userList[index-1];
            userAmountRecord[value]=_lotterySchedule[roundId].userAmount[userArr[value]];
            value++;
        }
        return(roundId,sumAmount,status,userSum,userAmount,userArr,userAmountRecord);
    }

    //中奖历史
    function getLotteryWinnerDetail() external view returns(uint8[] memory,address[] memory,uint256[] memory){

        //1 开奖期数
        //2 中奖地址
        //3 中奖金额
        uint256 winnerSum=_lotteryWinner.length;
        address[] memory userArr;
        uint256[] memory sumMoney;
        uint8[] memory roundList;
        if(winnerSum<=0){
            return(roundList,userArr,sumMoney);
        }
        uint minIndex=0;
        if(winnerSum>_showWinnerRecordCount){
            userArr = new address[](_showWinnerRecordCount);
            sumMoney = new uint256[](_showWinnerRecordCount);
            roundList=new uint8[](_showWinnerRecordCount);
            minIndex=winnerSum-_showWinnerRecordCount;
        }else{
            userArr = new address[](winnerSum);
            sumMoney = new uint256[](winnerSum);
            roundList=new uint8[](winnerSum);
        }
        uint value=0;
        for(uint index=winnerSum;index>minIndex;index--){
            userArr[value]=_lotteryWinner[index-1].winner;
            sumMoney[value]=_lotteryWinner[index-1].sumMoney;
            roundList[value]=_lotteryWinner[index-1].roundId;
            value++;
        }
        return(roundList,userArr,sumMoney);
    }

    //投注
    function bet(uint8 roundId) public payable returns(bool){
        uint256 amount = msg.value;
        require(amount>0 && roundId>0,"Parameter error!");
        require(_lotteryContextConfig.minBetAmount<=amount,"param minBetAmount error!");
        require(_lotteryContextConfig.maxBetAmount>=amount,"param maxBetAmount error!");
        LotteryScheduleModel storage schedule= _lotterySchedule[roundId];
        require(schedule.roundId!=0,"Schedule non-existent");
        //开奖中
        require(schedule.status==1,"Betting is not allowed at this time");
        require(_lotteryContextConfig.maxBetAmount>=schedule.userAmount[_msgSender()].add(amount),"Cannot exceed the maximum individual bet");
        //投注金额超过开奖金额 则开奖
        if(schedule.sumAmount.add(amount)>=_lotteryContextConfig.drawAmount){
            amount=_lotteryContextConfig.drawAmount.sub(schedule.sumAmount);
            schedule.status=2;
            schedule.blockNumber=block.number;
        }
        //可投注金额小于最小投注金额 则结束
        if(_lotteryContextConfig.drawAmount.sub(schedule.sumAmount).sub(amount)<_lotteryContextConfig.minBetAmount){
            schedule.status=2;
            schedule.blockNumber=block.number;
        }
        if(schedule.userAmount[_msgSender()]==0){
            schedule.userList.push(_msgSender());
        }
        //每个档期奖池金额累积
        schedule.sumAmount+=amount;
        //累计用户金额
        schedule.userAmount[_msgSender()]+=amount;
        return true;
    }

    //开奖
    function draw() external onlyOwner{
        uint8  roundId=_roundNum;
        require(roundId>0,"Parameter error!");
        LotteryScheduleModel storage schedule= _lotterySchedule[roundId];
        require(schedule.roundId!=0,"Schedule non-existent");
        require(schedule.userList.length>1,"No one was involved");
        require(schedule.status==2,"Cannot settle at present");
        //十个区块以内不开奖 等下一轮 防止卡 bug
        require(block.number-_blockNumberInterval>schedule.blockNumber,"Settlement not completed");
        //利用当前区块的时间戳、挖矿难度和盘内投注彩民数来取随机值
        bytes memory randomInfo = abi.encodePacked(block.timestamp,block.difficulty,schedule.userList.length);
        bytes32 randomHash =keccak256(randomInfo);
        //利用随机值来取获奖人在数组中的索引
        uint256 winnerIndex= uint256(randomHash).mod(_lotteryContextConfig.drawAmount);
        for(uint8 index=0;index<schedule.userList.length;index++){
            //遍历用户
            address currentUser=schedule.userList[index];
            if(currentUser==address(0)){
                continue;
            }
            uint256 money= schedule.userAmount[currentUser];
            if(winnerIndex<=money){
                schedule.winner=payable(currentUser);
                break;
            }
            winnerIndex-=money;
        }
        require(schedule.winner!=address(0),"No one was involved");
        //转账给中奖人
        uint256 winningBonus =schedule.sumAmount.mul(_rewardRate).div(100);
        schedule.winner.transfer(winningBonus);
        //记录中奖者信息
        LotteryWinnerModel memory winnerModel=LotteryWinnerModel(roundId,winningBonus,schedule.winner);
        _lotteryWinner.push(winnerModel);
        //开始新的一局
        schedule.status=3;
        _createLotterySchedule();
    }

    //设置有效间隔
    function setBlockNumberInterval(uint8 blockNumberInterval) external onlyOwner returns(bool){
        _blockNumberInterval=blockNumberInterval;
        return true;
    }
    //设置投注记录数量
    function setShowBetRecordCount(uint8 showBetRecordCount) external onlyOwner returns(bool){
        _showBetRecordCount=showBetRecordCount;
        return true;
    }
    //设置中奖记录数量
    function setShowWinnerRecordCount(uint8 showWinnerRecordCount) external onlyOwner returns(bool){
        _showWinnerRecordCount=showWinnerRecordCount;
        return true;
    }


    //设置开奖比例
    function setLotteryAllocation(uint8 txRate,uint8 rewardRate) external onlyOwner returns(bool){
        _txRate=txRate;
        _rewardRate=rewardRate;
        return true;
    }

    //设置赌厅配置
    function setLotteryConfig(uint256 minBet,uint256 maxBet,uint256 drawAmount,string memory lotteryName) external onlyOwner returns(bool){
        _lotteryContextConfig.drawAmount=drawAmount;
        _lotteryContextConfig.minBetAmount=minBet;
        _lotteryContextConfig.maxBetAmount=maxBet;
        _lotteryContextConfig.lotteryName=lotteryName;
        return true;
    }

    //清空合约账户 防止残留多余的一些虚拟货币
    function clearLottery() external  onlyOwner{
        _lotteryMoneyAddress.transfer(address(this).balance);
    }

    function transferForeignToken(address _token, address _to) public onlyOwner returns(bool _sent){
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function Sweep() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    receive() external payable {

    }

    fallback() external payable {

    }
}