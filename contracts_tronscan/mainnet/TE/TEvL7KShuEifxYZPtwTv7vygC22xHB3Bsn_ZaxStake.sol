//SourceUnit: ZaxStake2.sol

pragma solidity ^0.5.9;

contract ZaxStake {
    using SafeMath for uint;

    address payable public owner;
    ITRC20 public ZAXtoken;

	address payable internal contract_;
    
    uint public invested;
    uint public burned;
    uint public earnings;
    uint public withdrawn;
    uint public reinvested;
    uint public direct_bonus;

    uint private DailyRoi = 57871;
    uint private MaximumRoi = 5;  
    
    uint public AllowStaking = 0; 
    
    
    
    uint internal lastUid = 1;

    mapping(address => DataStructs.Player) public players;

    mapping(uint => address) public getPlayerbyId;


    event NewDeposit(address indexed addr, uint amount);
    event MatchPayout(address indexed addr, address indexed from, uint amount);
    event Withdraw(address indexed addr, uint amount);

   
       constructor(address payable _owner, ITRC20 _token) public {
       owner = _owner;
       ZAXtoken = _token;
       contract_ = msg.sender;
       

         }

    /**
     * Modifiers
     * */
    modifier hasDeposit(address _userId){
        require(players[_userId].deposits.length > 0);
        _;
    }
                                                                                              
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
  function _checkout(address _userId) private hasDeposit(_userId){
        DataStructs.Player storage player = players[_userId];
        if(player.deposits.length == 0) return;
        uint _minuteRate;
        uint _myEarnings;

        for(uint i = 0; i < player.deposits.length; i++){
            DataStructs.Deposit storage dep = player.deposits[i];
            uint secPassed = now - dep.time;
            if (secPassed > 0) {
                _minuteRate = DailyRoi;
                 
                uint _gross = dep.amount.mul(secPassed).mul(_minuteRate).div(1e12);
                
                uint _max = dep.amount.mul(MaximumRoi);
                uint _releasednet = dep.earnings;
                uint _released = dep.earnings.add(_gross);
                
                if(_released < _max){
                    _myEarnings += _gross;
                    dep.earnings += _gross;
                    dep.time = now;
                }
                
           else{
            uint256 collectProfit_net = _max.sub(_releasednet); 
             
             if (collectProfit_net > 0) {
             
             if(collectProfit_net <= _gross)
             {_myEarnings += collectProfit_net; 
             dep.earnings += collectProfit_net;
             dep.time = now;
             }
             else{
             _myEarnings += _gross; 
             dep.earnings += _gross;
             dep.time = now;}
             }
              else{
              _myEarnings += 0;
              dep.earnings += 0; 
              dep.time = now;
              }
            }
                
}
        }
        
        player.finances[0].available += _myEarnings;
        player.finances[0].last_payout = now;
        player.finances[0].total_earnings += _myEarnings;
       // _matchingPayout(_userId, _myEarnings);
        
 }

  /*
    * Only external call
    */

    function() external payable{

    }
    
     function directDeposit(uint _amount) external{ 
        //require(now >= releaseTime, "not launched yet!");
        require(AllowStaking > 0, "Staking is Disabled!");
        require(ITRC20(ZAXtoken).transferFrom(msg.sender, address(this), _amount),'Failed_Transfer');
        deposit(_amount, msg.sender);
    }

    function deposit(uint _amount, address payable _userId) internal {
        ITRC20 _token = ITRC20(ZAXtoken);
        ITRC20(ZAXtoken).burn(address(this), _token.balanceOf(address(this)));
	    
        DataStructs.Player storage player = players[_userId];

        player.deposits.push(DataStructs.Deposit({
            
            amount: _amount,
            earnings: 0,
            time: uint(block.timestamp)
            }));

        player.finances[0].total_invested += _amount;
        invested += _amount;
        burned += _amount;
       
        
        _checkout(_userId);


        //AllowStaking = 0;
        
        
        emit NewDeposit(_userId, _amount);
        
    }
    
        function withdraw() external hasDeposit(msg.sender){
        
        address payable _userId = msg.sender;
        DataStructs.Player storage player = players[_userId];
        
         _checkout(_userId);
       
        uint amount = player.finances[0].available;
        
        require(amount > 0, "Insufficient Balance!");
        
        ITRC20(ZAXtoken).mint(_userId, amount);

        player.finances[0].available = 0;
        player.finances[0].total_withdrawn += amount;
      
        withdrawn += amount;
        emit Withdraw(msg.sender, amount);
    }


function _getEarnings(address _userId) view external returns(uint) {

        DataStructs.Player storage player = players[_userId];
        if(player.deposits.length == 0) return 0;
        uint _minuteRate;
       
        uint _myEarnings;

        for(uint i = 0; i < player.deposits.length; i++){
            DataStructs.Deposit storage dep = player.deposits[i];
            uint secPassed = now - dep.time;
            if (secPassed > 0) {
                _minuteRate = DailyRoi;
                
                uint _gross = dep.amount.mul(secPassed).mul(_minuteRate).div(1e12);
                
                uint _max = dep.amount.mul(MaximumRoi);
                uint _releasednet = dep.earnings;
                uint _released = dep.earnings.add(_gross);
                
                
        if(_released < _max){
                    _myEarnings += _gross;
                }
            else{
            uint256 collectProfit_net = _max.sub(_releasednet); 
             
             if (collectProfit_net > 0) {
             
             if(collectProfit_net <= _gross)
             {_myEarnings += collectProfit_net; 
             }
             else{
             _myEarnings += _gross; 
             }
             }
              else{
              _myEarnings += 0;
              }
            }
        }
        }
        return player.finances[0].available.add(_myEarnings);
    }
    
    function BurnZAX(uint _amount) external{ 
        require(ITRC20(ZAXtoken).transferFrom(msg.sender, address(this), _amount),'Failed_Transfer');
        ITRC20 _token = ITRC20(ZAXtoken);
        ITRC20(ZAXtoken).burn(address(this), _token.balanceOf(address(this)));
    }

 

    function userInfo(address _userId) view external returns(uint for_withdraw, uint total_invested, uint total_withdrawn) {
        DataStructs.Player storage player = players[_userId];
        uint _myEarnings = this._getEarnings(_userId).add(player.finances[0].available);

        return (
        _myEarnings,
        player.finances[0].total_invested,
        player.finances[0].total_withdrawn);
}
    
    function contractInfo() view external returns(uint, uint, uint, uint, uint, uint) {
        return (invested, withdrawn, earnings.add(withdrawn), direct_bonus, lastUid, burned);
    }
    
    /**
     * Restrictied functions
     * */

	function setOwner(address payable _owner) external onlyOwner()  returns(bool){
        owner = _owner;
        return true;
    }


      function setDailyRoi(uint256 _DailyRoi) public {
      require(msg.sender==owner);
      DailyRoi = _DailyRoi;
    } 
       
       function setMaximumRoi(uint256 _MaximumRoi) public {
      require(msg.sender==owner);
      MaximumRoi = _MaximumRoi;
    } 
    
      function setOnStaking() public {
      require(msg.sender==owner);
      AllowStaking = 1;
    } 
    
          function setOffStaking() public {
      require(msg.sender==owner);
      AllowStaking = 0;
    } 
    
    
}

contract ZaxStake_{

    struct Deposit {
        //uint planId;
        uint amount;
        uint earnings; // Released = Added to available
        uint time;
    }

    struct Player {
        
        uint available;
        uint total_earnings;
        uint total_direct_bonus;
        uint total_invested;
        uint last_payout;
        uint total_withdrawn;
        Deposit[] deposits;
    }
    
    mapping(address => Player) public players;

    function _getEarnings(address _userId) external view returns(uint){}


						  
    function userInfo(address _userId) external view returns(uint, uint, uint, uint){}

}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}

library DataStructs{
    /*struct Plan{
        uint dailyRate;
        uint maxRoi;
    } */

    struct Deposit {
        //uint planId;
        uint amount;
        uint earnings; 
        uint time;
    }

    
   struct Finances{
        uint available;
        uint total_earnings;
        uint total_direct_bonus;
        uint total_invested;
        uint last_payout;
        uint total_withdrawn;
        }

    struct Player {
        uint playerId;
        Finances[1] finances;
        Deposit[] deposits;
      }
}
interface ITRC20 {

    function balanceOf(address tokenOwner) external pure returns (uint balance);

    function transfer(address to, uint value) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
    
    function mint(address account, uint256 amount) external;
    
    function burn(address account, uint256 amount) external;

    event Transfer(address indexed from, address indexed to, uint value);

    event Approval(address indexed owner, address indexed spender, uint value);
}