/**
 *Submitted for verification at Etherscan.io on 2021-12-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

library SafeMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0 , 'ds-math-div-overflow');
        return x / y;
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

contract LpFarm{

    using SafeMath for uint;

    address public lpTokenAddress;

    address owner;

    enum Operate{
        DEPOSIT,
        WITHDRAW
    }

    struct Record{
        address sender;

        Operate operate;

        uint amount;

        uint balance;

        uint time;
    }

    mapping(string => mapping(address => uint)) public balanceOf;

    mapping(string => Record[]) private records;


    event Deposit(string indexed uid,address indexed sender,uint amount, uint balance,uint time);

    event Withdraw(string indexed uid,address indexed sender,uint amount, uint balance,uint time);

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    uint constant daySeconds = 86400;

    uint constant LIMIT_DAY = 7;

    constructor(address _lpTokenAddress){
        lpTokenAddress = _lpTokenAddress;
        owner = msg.sender;
    }

    modifier isOwner(){
        require(msg.sender == owner,' not owner');
        _;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Hero Farm: TRANSFER_FAILED');
    }

    function deposit(string memory uid,uint amount) public {
        IERC20 lpToken = IERC20(lpTokenAddress);
        require(lpToken.balanceOf(msg.sender) >= amount,"lp token not enought");
        uint allowance = lpToken.allowance(msg.sender,address(this));
        require(allowance >= amount,'allowance not enough');
        lpToken.transferFrom(msg.sender,address(this),amount);
        balanceOf[uid][msg.sender] = balanceOf[uid][msg.sender].add(amount);
    
        Record memory record = Record({
            sender: msg.sender,
            time: block.timestamp,
            balance: balanceOf[uid][msg.sender],
            amount: amount,
            operate: Operate.DEPOSIT
        });
        records[uid].push(record);
        emit Deposit(uid,msg.sender,amount,balanceOf[uid][msg.sender],block.timestamp);
    }

    function withdraw(string memory uid,uint amount) public {
        require(balanceOf[uid][msg.sender] >= amount,"balance not enought");
        uint totalWithdrawAmount = getWithdrawedAmount(uid);
        uint before7DayDepositedAmount;
        uint after7DayDepositedAmount;
        (before7DayDepositedAmount,after7DayDepositedAmount) =  splitDepositedAmountByDay(uid,LIMIT_DAY);
        uint before7dayBal = before7DayDepositedAmount - totalWithdrawAmount;
        require(before7dayBal >= amount,"limit day balance not enought");
        uint fee = 0;
        uint before30DayDepositedAmount;
        uint after30DayDepositedAmount;
        (before30DayDepositedAmount,after30DayDepositedAmount) =  splitDepositedAmountByDay(uid,30);
        if(totalWithdrawAmount > before30DayDepositedAmount){
            fee = amount.mul(50).div(1000);
        }else{
            uint beforeBal = before30DayDepositedAmount.sub(totalWithdrawAmount);
            if(beforeBal > amount){
                fee = amount.mul(25).div(1000); 
            }else{
                fee = beforeBal.mul(25).div(1000).add((amount.sub(beforeBal)).mul(50).div(1000));
            }
        }
        require(balanceOf[uid][msg.sender] >= amount.add(fee),"balance not enought to withdraw fee");
        balanceOf[uid][msg.sender] = balanceOf[uid][msg.sender].sub(amount.add(fee));
        _safeTransfer(lpTokenAddress,msg.sender,amount);
        Record memory record = Record({
            sender: msg.sender,
            time: block.timestamp,
            balance: balanceOf[uid][msg.sender],
            amount: amount,
            operate: Operate.WITHDRAW
        });
        records[uid].push(record);
        emit Withdraw(uid,msg.sender,amount,balanceOf[uid][msg.sender],block.timestamp);
    }

    function getRecords(string memory uid) public view returns(Record[] memory){
        return records[uid];
    }

    
    function splitDepositedAmountByDay(string memory uid,uint day) private view returns(uint,uint) {
        uint beforeAmount = 0; 
        uint afterAmount = 0;
        Record[] storage historyRecords = records[uid];
        uint beforeDayTime = block.timestamp - day * daySeconds;
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
}