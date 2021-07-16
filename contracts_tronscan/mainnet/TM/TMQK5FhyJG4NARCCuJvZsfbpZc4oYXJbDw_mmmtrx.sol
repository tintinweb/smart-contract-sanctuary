//SourceUnit: mmmtrx.sol

pragma solidity ^0.5.10;

contract mmmtrx{
    
    address constant private TicketsAddr = 0x471fD66465B83B00f60c913F0b1ECAD2C3026a3C; //门票合约
    address constant private usdtAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C; //USDT
    
    address private OwnerAddr;
    
    TicketsInterface private ticketsInterface;
    USDTInterface private usdtInterface;
    
    event addTickets(address sender, uint256 ticketsNum);
    event subTickets(uint256 id, address sender, uint256 ticketsNum, uint256 orderID);
    event invest(uint256 flag, uint256 start);
    event withdraw(address sender, uint256 withdrawNum);
    event pastDue(uint256 flag, uint256 start);
    event ExtractAward(address sender, uint256 amount);
    
    constructor() public{
        OwnerAddr = msg.sender;
        ticketsInterface = TicketsInterface(TicketsAddr);
        usdtInterface = USDTInterface(usdtAddr);
    }
    
    modifier ifAdmin() {
        require(msg.sender == OwnerAddr);
        _;
    }
    
    function AddTickets(address userAddr, uint256 amount) public {
        require(ticketsInterface.AddTickets(userAddr, amount));
        emit addTickets(userAddr, amount);
    }
    
    function SubTickets(uint256 id, address userAddr ,uint256 amount) public {
        uint256 orderID = ticketsInterface.SubTickets(userAddr, amount);
        emit subTickets(id, userAddr, amount, orderID);
    } 
    
    function Withdraw(address userAddr, uint256 orderID) payable public  {
        uint256 Sum = ticketsInterface.Withdraw(userAddr, orderID);
        require(Sum > 0);
        usdtInterface.transfer(userAddr, Sum);
        emit withdraw(userAddr, Sum);
    }
    
    function Invest(address userAddr,uint256 orderID,uint PayType,uint IncomeType,uint256 amount) public returns(uint256, uint256) {
        uint256 flag = 0;
        uint256 start = 0;
        (flag, start) = ticketsInterface.Invest(userAddr, orderID, PayType, IncomeType, amount);
        if (flag == 5) {
            emit pastDue(flag, start);
            return (flag, start);
        }else{
            emit invest(flag, start);
            return (flag, start);
        }
    }
    
    function getUserDeposit(address userAddr, uint256 orderID) public view returns(uint256,uint256, uint256,uint256, uint, uint, uint){
        return ticketsInterface.getUserDeposit(userAddr, orderID);
    }
    
    function getUserInfo(address userAddr) public view returns(uint256, uint256, uint256){
        return ticketsInterface.getUserInfo(userAddr);
    }
    
    function Award(address userAddr, uint256 amount) payable public ifAdmin {
        require(amount > 0, "error in quantity");
        usdtInterface.transfer(userAddr, amount);
        emit ExtractAward(userAddr, amount);
    }
    
    function fallback() payable public {}
}

interface TicketsInterface {
    function AddTickets(address userAddr, uint256 addNum) external returns(bool);
    function SubTickets(address userAddr ,uint256 amount) external returns(uint256);
    function Withdraw(address userAddr,uint256 orderID) external returns(uint256);
    function Invest(address userAddr,uint256 orderID,uint PayType,uint IncomeType,uint256 amount) external returns(uint256,uint256);
    function getUserDeposit(address userAddr,uint256 orderID) external view returns(uint256,uint256, uint256,uint256, uint, uint, uint);
    function getUserInfo(address userAddr) external view returns(uint256, uint256, uint256);
}

interface USDTInterface {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}