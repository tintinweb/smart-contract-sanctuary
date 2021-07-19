//SourceUnit: FloodMaker_v2.sol

pragma solidity 0.5.8;

/*
      ______ _                 _ __  __       _                    ___  
     |  ____| |               | |  \/  |     | |                  |__ \ 
     | |__  | | ___   ___   __| | \  / | __ _| | _____ _ __  __   __ ) |
     |  __| | |/ _ \ / _ \ / _` | |\/| |/ _` | |/ / _ \ '__| \ \ / // / 
     | |    | | (_) | (_) | (_| | |  | | (_| |   <  __/ |     \ V // /_ 
     |_|    |_|\___/ \___/ \__,_|_|  |_|\__,_|_|\_\___|_|      \_/|____|
                                                                    
     "Somehow, I don't know how, it just happened..."
     - MrFunction's explanation of how FloodMaker v2 was made.
     
    A special thanks to all the Function Island VIPs!
*/

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;
        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {return 0;}
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {return div(a, b, "SafeMath: division by zero");}
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b > 0, errorMessage);
        uint c = a / b;
        return c;
    }
}

contract Hourglass {
    function buy(address _referredBy) external payable returns (uint256);
    function exit() external;
    
    function reinvest() public {}
    function myTokens() public view returns(uint256) {}
    function myDividends(bool) public view returns(uint256) {}
}

contract Floodmaker {
    using SafeMath for uint;
    
    Hourglass D1VS;
    
    // // CONFIGURABLES // // // // // // // // // // // // // // // // // // // //
    
    address private _hourglassAddress;
    address private _lastFloodMaker;
    
    uint256 private _mark;
    uint256 private _timesFlooded;
    uint256 private _totalContributors;
    
    mapping (address => uint) _contributedTRXOf;
    
    // // EVENTS // // // // // // // // // // // // // // // // // // // //
    
    event FloodTriggered(address _caller, uint _timestamp);
    
    event FundsReceived(address _sender, uint _amount, uint _timestamp);
    
    event WatersTurned(address _caller, uint _amount, uint _timestamp);
    
    // // CONSTRUCTOR // // // // // // // // // // // // // // // // // //
    
    constructor(address _hourglass) public {
        D1VS = Hourglass(_hourglass);
        _mark = 10e18;
        _hourglassAddress = _hourglass;
        _lastFloodMaker = msg.sender;
    }
    
    // // FUNCTIONS // // // // // // // // // // // // // // // // // // //
    
    function () payable external {
        depositTRX();
    }
    
    // READ FUNCTIONS
    
    function myTokens() public view returns (uint256) {return D1VS.myTokens();}
    function myDividends() public view returns (uint256) {return D1VS.myDividends(true);}
    
    function floodCount() public view returns (uint256) {return (_timesFlooded);}
    function floodMarker() public view returns (uint256) {return (_mark);}
    
    function contributedTRXOf(address _user) public view returns (uint256) {return _contributedTRXOf[_user];}
    function totalContributors() public view returns (uint256) {return _totalContributors;}
    
    function theLastFloodMaker() public view returns (address) {return _lastFloodMaker;}
    
    // WRITE FUNCTIONS
    
    // This function is primarily to be used by contracts which collect any kind of TRX fee.
    // Anyone can use this function to contribute some TRX (Non-refundable - BE CAREFUL!).
    function depositTRX() public payable returns (bool) {
        pumpTheWater();                             // Perform a quick buy-and-reinvest after the deposit
        _contributedTRXOf[msg.sender] += msg.value; // Count the contribution of TRX from the address
        
        // Tell the Network...
        emit FundsReceived(msg.sender, msg.value, now);
        return true;    // Successful Function!
    }
    
    // 
    function pumpTheWater() public returns (bool _success) {
        uint _contractBalance = address(this).balance;  // Let's get this as a static number, to prevent any issues during tx.
        D1VS.buy.value(_contractBalance)(msg.sender);   // Buy as much as possible with what's available...
        D1VS.reinvest();                                // ...and reinvest as well, to use those Dividends!
        
        // Tell the Network...
        emit WatersTurned(msg.sender, _contractBalance, now);
        return true;    // Successful Function!
    }
    
    // This is the main function of this contract.
    function makeItFlood() public returns (bool _success) {
        uint _contractBalance = address(this).balance;      // Let's get this as a static number, to prevent any issues during tx.
        
        // If FloodMaker v2 is holding more D1VS than the current marker...
        if (D1VS.myTokens() > _mark) {
            D1VS.exit();                                    // DO A MASSIVE SELL-OFF...
            D1VS.buy.value(_contractBalance)(msg.sender);   // ... AND RE-BUY IN AGAIN!
            
            _lastFloodMaker = msg.sender;                   // Then, we take note of who's responsible for this mess...
            _mark += ((_mark / 100) * 50);                  // Set the next marker to 150% of the one just reached...
            _timesFlooded += 1;                             // Add this instance to the flood counter
            
            // Tell the Network...
            emit FloodTriggered(msg.sender, now);
            return true;    // Successful Function!
        }
        
        pumpTheWater();                                     // Perform a quick buy-and-reinvest after the deposit
        
        // Tell the Network...
        emit WatersTurned(msg.sender, _contractBalance, now);
        return false;    // Successful Function!
    }
}