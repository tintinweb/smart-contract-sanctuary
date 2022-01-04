/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
 
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
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface CalcFee{
    function calcRate(uint[2][] memory records,uint totalWithdrawAmount,uint withdrawAmount) external view returns(uint);
}

contract LpFarm{

    using SafeMath for uint;

    address public lpTokenAddress;

    address public calcRateContractAddress;

    address owner;

    enum Operate{
        DEPOSIT,
        WITHDRAW
    }

    struct Record{
        address sender;

        Operate operate;

        uint amount;

        uint fee;

        uint balance;

        uint time;
    }

    mapping(string => mapping(address => uint)) public balanceOf;

    mapping(string => Record[]) private records;

    uint private  feeAmount;

    uint public userCount;

    uint public totalLimit;

    event Deposit(string indexed uid,address indexed sender,uint amount, uint fee,uint balance,uint time);

    event Withdraw(string indexed uid,address indexed sender,uint amount, uint fee,uint balance,uint time);

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));


    uint public limitDay = 7;

    constructor(address _lpTokenAddress,uint _totalLimit,address _calcRateContractAddress){
        lpTokenAddress = _lpTokenAddress;
        calcRateContractAddress = _calcRateContractAddress;
        totalLimit = _totalLimit;
        owner = msg.sender;
    }

    modifier isOwner(){
        require(msg.sender == owner,' not owner');
        _;
    }

    function changeLimitDay(uint _limitDay) public isOwner{
        limitDay = _limitDay;
    }

    function setCalcRateContractAddress(address _calcRateContractAddress) public isOwner{
        calcRateContractAddress = _calcRateContractAddress;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Hero Farm: TRANSFER_FAILED');
    }

    function takeFeeTo(address to) public isOwner{
        _safeTransfer(lpTokenAddress,to,feeAmount);    
    }

    function deposit(string memory uid,uint amount) public {
        IERC20 lpToken = IERC20(lpTokenAddress);
        require(lpToken.balanceOf(msg.sender) >= amount,"lp token not enought");
        uint allowance = lpToken.allowance(msg.sender,address(this));
        require(allowance >= amount,"allowance not enough");
        lpToken.transferFrom(msg.sender,address(this),amount);
        balanceOf[uid][msg.sender] = balanceOf[uid][msg.sender].add(amount);
      
        if(records[uid].length == 0){
            userCount = userCount.add(1);
        }
        uint fee = 0;
        Record memory record = Record({
            sender: msg.sender,
            time: block.timestamp,
            balance: balanceOf[uid][msg.sender],
            amount: amount,
            fee: fee,
            operate: Operate.DEPOSIT
        });
        records[uid].push(record);
        emit Deposit(uid,msg.sender,amount,fee,balanceOf[uid][msg.sender],block.timestamp);
    }

    function withdraw(string memory uid,uint amount) public {
        require(balanceOf[uid][msg.sender] >= amount,"balance not enought");
        uint totalWithdrawAmount = getWithdrawedAmount(uid);
        uint before7DayDepositedAmount;
        uint after7DayDepositedAmount;
        (before7DayDepositedAmount,after7DayDepositedAmount) =  splitDepositedAmountByDay(uid,limitDay);
        require(before7DayDepositedAmount >= amount.add(totalWithdrawAmount),"limit day balance not enought");

        CalcFee caleFeeContract = CalcFee(calcRateContractAddress);
        uint fee = caleFeeContract.calcRate(getDepositRecords(uid),totalWithdrawAmount,amount);
        require(balanceOf[uid][msg.sender] >= amount.add(fee),"balance not enought to withdraw fee");
        balanceOf[uid][msg.sender] = balanceOf[uid][msg.sender].sub(amount.add(fee));
        _safeTransfer(lpTokenAddress,msg.sender,amount);
        feeAmount = feeAmount.add(fee);
        Record memory record = Record({
            sender: msg.sender,
            time: block.timestamp,
            balance: balanceOf[uid][msg.sender],
            amount: amount,
            fee: fee,
            operate: Operate.WITHDRAW
        });
        records[uid].push(record);
        emit Withdraw(uid,msg.sender,amount,fee,balanceOf[uid][msg.sender],block.timestamp);
    }

    function getRecords(string memory uid) public view returns(Record[] memory){
        return records[uid];
    }

    
    function splitDepositedAmountByDay(string memory uid,uint day) private view returns(uint,uint) {
        uint beforeAmount = 0; 
        uint afterAmount = 0;
        Record[] storage historyRecords = records[uid];
        uint beforeDayTime = block.timestamp - day * 1 days;
        for(uint i = 0; i < historyRecords.length; i ++){
            uint time = historyRecords[i].time;
            uint amount = historyRecords[i].time;
            if(historyRecords[i].operate == Operate.DEPOSIT){
                if (beforeDayTime > time) {
                    beforeAmount = beforeAmount.add(amount);
                }else{
                    afterAmount = afterAmount.add(amount);
                }
            }
        }
        return (beforeAmount,afterAmount);
    }

    function getWithdrawedAmount(string memory uid) private view returns(uint){
        uint amount = 0;
        Record[] storage historyRecords = records[uid];
        for(uint i = 0; i < historyRecords.length; i ++){
            if(historyRecords[i].operate == Operate.WITHDRAW){
                amount = amount.add(historyRecords[i].amount);
            }
        }
        return amount;
    }

    function getDepositRecords(string memory uid) public view returns(uint[2][] memory){
        uint[2][] memory results = new uint[2][](0);
        Record[] storage historyRecords = records[uid];
        uint index = 0;
        for(uint i = 0; i < historyRecords.length; i ++){
            if(historyRecords[i].operate == Operate.DEPOSIT){
                results[index][0] = historyRecords[i].time;
                results[index][1] = historyRecords[i].amount;
                index++;
            }
        }
        return results;
    }
}