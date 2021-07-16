//SourceUnit: EliteInvestors (6).sol

pragma solidity ^0.5.4;

contract EliteInvestors { 
    
    address payable owner;
    uint256 amountref;
    
    struct Investor {
        bool registered;
        uint invested;
        uint withdrawn;
        uint totalRef;
        uint totalWithdrawable;
        uint40 initTime;
        address ref;
    }
    
    mapping (address => Investor) public investors;

    
    uint MIN_DEPOSIT = 50000000;// trx;
    uint MAX_DEPOSIT = 100000000000;// trx;
    
    uint40 public timepay;
    uint public totalInvestors;
    uint public totalInvested;
    uint public balance2owner;
    uint256 public totalwithdrawn;
    uint256 public profitowner;
    
    
    constructor() public payable {
        owner = msg.sender;
        profitowner = msg.value;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Withdraw(address indexed _beneficiary, uint amount);
    event Deposit(address indexed _invest, uint256 _value);
    
    
    function deposits(address _levelUp, uint256 amount) public payable {
        require(amount >= MIN_DEPOSIT, "Min 50 deposits per address");
        require(amount <= MAX_DEPOSIT, "Max 100000 deposits per address");
        
        if(investors[msg.sender].registered != true) {
            investors[msg.sender].initTime = uint40(block.timestamp);
        }

        investors[msg.sender].invested += amount;
        investors[msg.sender].ref = _levelUp;
        investors[msg.sender].registered = true;
        
        
        uint256 amountowner = amount * 105 / 1000;
        0x920F6f1f1C599D677Fd2a3c2BccA1945fABB2DB4.transfer(amountowner);
        
        
        balance2owner += amountowner;
        totalInvested += amount;
        totalInvestors++;

        address ref1level = _levelUp;
        if(investors[ref1level].registered == true) {

            amountref = amount * 30 /1000;
            investors[ref1level].totalRef += amountref;
            amountref = 0;
            address ref2level = investors[ref1level].ref;
            if(investors[ref2level].registered == true) {
    
                amountref = amount * 20 /1000;
                investors[ref2level].totalRef += amountref;
                amountref = 0;
                address ref3level = investors[ref2level].ref;
                if(investors[ref3level].registered == true) {
        
                    amountref = amount * 10 /1000;
                    investors[ref3level].totalRef += amountref;
                    amountref = 0;
                    address ref4level = investors[ref3level].ref;
                    if(investors[ref4level].registered == true) {
            
                        amountref = amount * 10 /1000;
                        investors[ref4level].totalRef += amountref;
                        amountref = 0;
                        address ref5level = investors[ref4level].ref;
                        if(investors[ref5level].registered == true) {
                
                            amountref = amount * 10 /1000;
                            investors[ref5level].totalRef += amountref;
                            amountref = 0;
                        }
                    }
                }
            }
        }

        emit Deposit(msg.sender, amount);
    }
    
    function getTime() external view returns (uint40){
        uint40 tiempo = uint40(block.timestamp);
        return tiempo;
    }
    
    function subtracttime() external view returns (uint40){
        
        Investor storage _investor = investors[msg.sender];
        
        uint40 tim = uint40(block.timestamp) - _investor.initTime;
        return tim;
    }
    
    function currentuser() external view returns (address){
        
        return msg.sender;
    }
    
    function totalinvested() external view returns (uint256){
        
        Investor storage _investor = investors[msg.sender];
        
        return _investor.invested;
    }
    
     function withdrawn() external view returns (uint256){
        
        Investor storage _investor = investors[msg.sender];
        
        return _investor.withdrawn;
    }
    
    function totalref() external view returns (uint){
        
        Investor storage _investor = investors[msg.sender];
        
        uint totref = _investor.totalRef;
        return totref;
    }
    
    function profit() internal {
        Investor storage _investor = investors[msg.sender];
        
        require(_investor.registered == true);
        
        uint timepa = uint(block.timestamp) - _investor.initTime;
        uint payprofit = _investor.invested * 20 / 1000;
        payprofit = payprofit / 86400;
        
        timepa = timepa * payprofit;
        timepa += _investor.totalRef;
        _investor.totalWithdrawable = timepa;
        
    }
    
    function withdraw() external {
        Investor storage _investor = investors[msg.sender];
        
        profit();
        uint256 amount = _investor.totalWithdrawable;
        
        require(amount > 0, "Zero amount");
        
        uint reinvest = amount * 400 / 1000;
        uint withdrawn40 = amount * 400 / 1000;
        uint256 contrt = amount * 200 / 1000;
        
        owner.transfer(contrt);
        msg.sender.transfer(withdrawn40);
        
        emit Transfer(msg.sender, owner, contrt);
        emit Withdraw(msg.sender, withdrawn40);
        
        _investor.invested += reinvest;
        _investor.totalWithdrawable = 0;
        _investor.totalRef = 0;
        _investor.withdrawn += amount;
        _investor.initTime = uint40(block.timestamp);
        totalwithdrawn += amount;
        
    }
    
}