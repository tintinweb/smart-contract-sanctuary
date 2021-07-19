//SourceUnit: lockUpUz.sol

pragma solidity ^0.5.8;

interface uztoken {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
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
        
        return c;
    }
}

contract lockUpUz{
    
    using SafeMath for *;
    
    address public locupManager;
    uztoken public UzAddr;
    uint256 public  duration = 10368000; // 4 months
    uint256 public startTime;
    uint256 public totalSupply = 1000000;
    uint256 public alreadyWithdrow;
    mapping(uint256 => bool) public withdrowFlag;
    
    constructor(uztoken _UzAddress,address _lmAddr) public{
        locupManager = _lmAddr;
        UzAddr = _UzAddress;
        startTime = now;
    }
    
    function withdrow() public{
        require(msg.sender == locupManager,"error sender");
        uint256 time = now.sub(startTime).div(duration);
        require(time > 0,"is lock");
        //require(withdrowFlag[time],"is lock");
        require(alreadyWithdrow < totalSupply,"not balance");
        
        uint256 checkTime;
        if(time>=4){
            uint256 canWithrow  = totalSupply.sub(alreadyWithdrow);
            if(canWithrow > 0){
                UzAddr.transfer(msg.sender,canWithrow);
                alreadyWithdrow =  alreadyWithdrow.add(canWithrow);
            }
            
        }else{
            for(uint256 i = 1;i<=time;i++){
                if( !withdrowFlag[i]){
                    checkTime++;
                }
            }
            uint256 canWithrow =  totalSupply.mul(30).div(100).mul(checkTime);
            if(alreadyWithdrow.add(canWithrow) >= totalSupply){
                UzAddr.transfer(msg.sender,totalSupply.sub(alreadyWithdrow));
                alreadyWithdrow =  totalSupply;
            
            }else{
                UzAddr.transfer(msg.sender,canWithrow);
                alreadyWithdrow =  alreadyWithdrow.add(canWithrow);
            }
        }
        withdrowFlag[time] = true;
    }
    
    function balanceOfUz() public view returns(uint){
        return UzAddr.balanceOf(address(this));
    }
    
    function cheakLockAll(uint256 _time) public view returns(bool){
        uint256 time = _time.sub(startTime).div(duration);
        if(time >= 4){
            return true;
        }else{
            return false;
        }
    }
    
}