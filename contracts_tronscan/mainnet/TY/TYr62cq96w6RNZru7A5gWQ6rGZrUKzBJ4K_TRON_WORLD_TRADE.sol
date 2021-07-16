//SourceUnit: TRON_WORLD_TRADE.sol

pragma solidity ^0.5.0;

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

contract TRON_WORLD_TRADE is owned{
  
    struct UserStruct {
        bool isExist;
        uint investment;
        uint withdrawal;
        uint investment_USDT;
        uint withdrawal_USDT;
    }

    mapping (address => UserStruct) public userInfo;

    uint public noOfInvestedUsers = 0;

    event investEvent(address indexed _user, uint _amount, uint _time);
    
    
    function balance_TRX() view public returns (uint) {
        return address(this).balance;
    }
    
    function Deposit_TRX() public payable returns (bool) {
       
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


}