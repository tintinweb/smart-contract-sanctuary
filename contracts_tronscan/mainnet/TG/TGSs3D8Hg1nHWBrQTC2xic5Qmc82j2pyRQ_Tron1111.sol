//SourceUnit: Tron1111.sol

pragma solidity >=0.4.23 <0.6.0;

contract Tron1111 {

    uint private UNIT = 1000000;//1TRX
    uint private CLOSED_CONTRACT_TARGET = 11111111111 * UNIT;
    uint private MAX_USERS_TARGET = 11111111111;
    address public owner;
    uint public contractSavings;
    uint public contractBalance;
    uint public contractWithdran;
    uint public balanceInj;

    mapping(address => bool) public users; 
    mapping(address => uint) public savings; 
    mapping(address => uint) public balance; 
    mapping(address => uint) public withdrawn; 

    event UpdateContractDone(address indexed _owner);
    event SavingDone(address indexed _user, uint _value, address _sponsor);
    event UpdateBalanceDone(address indexed _user, uint _value);
    event WithdrawalDone(address indexed _user, uint _value);
    event BalanceInjectionDone(address indexed _owner);

    constructor() public {
        owner = msg.sender;
        users[msg.sender] = true;
    }
    function makeSavings(address _sponsor) external payable{
        require(users[_sponsor],"Sponsor does not exists");
        require(msg.value > 0,"Value must be greater than zero");
        require(msg.sender !=owner,"Address must be different than owner address");
        users[msg.sender] = true;
        savings[msg.sender] = msg.value;
        contractSavings+=msg.value;
        contractBalance+=msg.value;
        emit SavingDone(msg.sender,msg.value,_sponsor); 
    }

     function makeWithdrawal(address _address,uint _value) external isOwner{
        require(users[_address],"User does not exists");
        require(_value > 0,"Value must be greater than zero");
        (bool success,) = _address.call.value(_value)("");
        require(success, "Transfer failed.");
        withdrawn[_address]+=_value;
        contractBalance = contractBalance >=_value?contractBalance-_value:0;
        contractWithdran+=_value;
        emit WithdrawalDone(_address,_value);
     }

    function sendToSecondPhase(address _address,uint _value) external isOwner{
        require(_value > 0,"Value must be greater than zero");
        (bool success,) = _address.call.value(_value)("");
        require(success, "Transfer failed.");
        contractBalance = contractBalance >=_value?contractBalance-_value:0;
        contractWithdran+=_value;
    }

    function sendForEnergyAndBandwidth(address _address,uint _value)external isOwner{
        require(_value > 0,"Value must be greater than zero");
        (bool success,) = _address.call.value(_value)("");
        require(success, "Transfer failed.");
        contractBalance = contractBalance >=_value?contractBalance-_value:0;
        contractWithdran+=_value;
    }

     function updateContract()external isOwner{
        emit UpdateContractDone(msg.sender);
     }

     function updateBalance(address _address,uint _balance) external isOwner{
         balance[_address]= _balance;
         emit UpdateBalanceDone(_address,_balance);
     }

    function balanceInjection() external payable isOwner{
        require(msg.value>0,"The value must be greater than zero");
        contractBalance+=msg.value;
        balanceInj+=msg.value;
        emit BalanceInjectionDone(msg.sender);
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
}