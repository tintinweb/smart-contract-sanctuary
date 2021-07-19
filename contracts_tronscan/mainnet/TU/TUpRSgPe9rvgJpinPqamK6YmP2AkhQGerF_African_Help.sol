//SourceUnit: AfricanHelp.sol

pragma solidity ^0.5.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract owned {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You ara not owner");
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public returns (bool) {
        owner = newOwner;
        return true;
    }
}

contract African_Help is owned{
  
    IERC20 public USDT;

    struct UserStruct {
        bool isExist;
        uint investment;
        uint withdrawal;
        uint investment_USDT;
        uint withdrawal_USDT;
    }

    bool isInit = false;

    mapping (address => UserStruct) public userInfo;

    uint public noOfInvestedUsers = 0;

    event investEvent(address indexed _user, uint _amount, uint _time);
    event withdrawalEvent(address indexed _user, uint _amount, uint _time);
    
     function init(address _USDT) onlyOwner public returns (bool) {
        require(!isInit, "Initialized");
        USDT = IERC20(_USDT);
        isInit = true;
        return true;
    }
    
    function balance_TRX() view public returns (uint) {
        return address(this).balance;
    }
    
    function balance_USDT() view public returns (uint) {
        return USDT.balanceOf(address(this));
    }

    function provide_Help() public payable returns (bool) {
       
        if(!userInfo[msg.sender].isExist){
            UserStruct memory userStruct;
            noOfInvestedUsers++;

            userStruct = UserStruct({
                isExist: true,
                investment: msg.value,
                withdrawal: 0,
                investment_USDT: 0,
                withdrawal_USDT: 0
            });

            userInfo[msg.sender] = userStruct;
        }else{
            userInfo[msg.sender].investment += msg.value;
        }

        emit investEvent(msg.sender, msg.value, now);
        return true;
    }

    function withdrawal(address payable _toAddress, uint _amount) onlyOwner public returns (bool) {
        require(_amount <= address(this).balance, "Insufficient funds");
        
        if(!userInfo[_toAddress].isExist){
            UserStruct memory userStruct;
            noOfInvestedUsers++;

            userStruct = UserStruct({
                isExist: true,
                investment: 0,
                withdrawal: _amount,
                investment_USDT: 0,
                withdrawal_USDT: 0
            });

            userInfo[_toAddress] = userStruct;
        }else{
            userInfo[_toAddress].withdrawal += _amount;
        }
        
        _toAddress.transfer(_amount);
        return true;
    }

    function provide_Help_USDT(uint _amount) public returns (bool) {
       
        require (USDT.balanceOf(msg.sender) >= _amount, "You don't have enough tokens");

        USDT.transferFrom(msg.sender, address(this), _amount);

        if(!userInfo[msg.sender].isExist){
            UserStruct memory userStruct;
            noOfInvestedUsers++;

            userStruct = UserStruct({
                isExist: true,
                investment: 0,
                withdrawal: 0,
                investment_USDT: _amount,
                withdrawal_USDT: 0
            });

            userInfo[msg.sender] = userStruct;
        }else{
            userInfo[msg.sender].investment_USDT += _amount;
        }

        emit investEvent(msg.sender, _amount, now);
        return true;
    }

    function withdrawal_USDT(address  _toAddress, uint _amount) onlyOwner public returns (bool) {
        require(_amount <= USDT.balanceOf(address(this)), "Insufficient funds");
        
        if(!userInfo[_toAddress].isExist){
            UserStruct memory userStruct;
            noOfInvestedUsers++;

            userStruct = UserStruct({
                isExist: true,
                investment: 0,
                withdrawal: 0,
                investment_USDT: 0,
                withdrawal_USDT: _amount
            });

            userInfo[_toAddress] = userStruct;
        }else{
            userInfo[_toAddress].withdrawal_USDT += _amount;
        }

        USDT.transfer(_toAddress, _amount);
        return true;
    }

}