// solium-disable linebreak-style
pragma solidity ^0.5.0;

contract CryptoTycoonsVIPLib{
    
    address payable public owner;

    mapping (address => uint) userExpPool;
    mapping (address => bool) public callerMap;
    modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    modifier onlyCaller {
        bool isCaller = callerMap[msg.sender];
        require(isCaller, "onlyCaller methods called by non-caller.");
        _;
    }

    constructor() public{
        owner = msg.sender;
        callerMap[owner] = true;
    }

    function kill() external onlyOwner {
        selfdestruct(owner);
    }

    function addCaller(address caller) public onlyOwner{
        bool isCaller = callerMap[caller];
        if (isCaller == false){
            callerMap[caller] = true;
        }
    }

    function deleteCaller(address caller) external onlyOwner {
        bool isCaller = callerMap[caller];
        if (isCaller == true) {
            callerMap[caller] = false;
        }
    }

    function addUserExp(address addr, uint256 amount) public onlyCaller{
        uint exp = userExpPool[addr];
        exp = exp + amount;
        userExpPool[addr] = exp;
    }

    function getUserExp(address addr) public view returns(uint256 exp){
        return userExpPool[addr];
    }

    function getVIPLevel(address user) public view returns (uint256 level) {
        uint exp = userExpPool[user];

        if(exp >= 30 ether && exp < 150 ether){
            level = 1;
        } else if(exp >= 150 ether && exp < 300 ether){
            level = 2;
        } else if(exp >= 300 ether && exp < 1500 ether){
            level = 3;
        } else if(exp >= 1500 ether && exp < 3000 ether){
            level = 4;
        } else if(exp >= 3000 ether && exp < 15000 ether){
            level = 5;
        } else if(exp >= 15000 ether && exp < 30000 ether){
            level = 6;
        } else if(exp >= 30000 ether && exp < 150000 ether){
            level = 7;
        } else if(exp >= 150000 ether){
            level = 8;
        } else{
            level = 0;
        }

        return level;
    }

    function getVIPBounusRate(address user) public view returns (uint256 rate){
        uint level = getVIPLevel(user);

        if(level == 1){
            rate = 1;
        } else if(level == 2){
            rate = 2;
        } else if(level == 3){
            rate = 3;
        } else if(level == 4){
            rate = 4;
        } else if(level == 5){
            rate = 5;
        } else if(level == 6){
            rate = 7;
        } else if(level == 7){
            rate = 9;
        } else if(level == 8){
            rate = 11;
        } else if(level == 9){
            rate = 13;
        } else if(level == 10){
            rate = 15;
        } else{
            rate = 0;
        }
    }
}