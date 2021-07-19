//SourceUnit: TBT.sol

pragma solidity ^0.5.4;


contract TBT {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    uint256 initialSupply = 5000000;
    string tokenName = 'Tron Beast Token';
    string tokenSymbol = 'TBT';
    constructor() public {

        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;      
                                                         // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }


    
    function mint(address account, uint256 value) internal {
        require(account != address(0));

        totalSupply += value;
        balanceOf[account] += value;
        emit Transfer(address(0), account, value);
    }
}


//SourceUnit: TronBeastv2.sol

pragma solidity 0.5.4;
import "./TBT.sol";  

 contract TronBeastv2 {

    TBT public tbt;  

    struct User { 
        address payable upline ;
        uint256 referrals ;
        uint256 payouts ;
        uint256 direct_bonus ;  
        uint256 deposit_amount ; 
        uint256 deposit_time ; 
        uint256 payout_time ; 
        uint256 temp_directs_count; 
        bool isActive ;
 	    uint256 daily_roi ;
        uint256 last_pay ;
        uint256[3] level_income;
       } 
    
    struct User2 {
        uint256 total_deposits ;
        uint256 total_payouts ;
        uint256 total_structure ; 
        uint256 cycle ;
        uint256 tbt_from_withdrawal ;
        uint256 tbt_from_deposit ;
        uint256 total_tbt ;
      } 
     
    uint256[] public deposit_cycles ;                            
    uint256[] public ref_bonuses ;  
    uint256 public H_C_B = 0 ; 
    uint256 public Lower_H_C_B = 0 ; 
    uint256 public Higher_H_C_B = 0 ; 
    bool public contract_status = true; 
    
    uint256 constant public tbt_min_deposit = 1000 trx;  // 1000 trx
    uint256 constant public twenty_four_hours_deposit_value = 5000 trx ;  // 5000 trx 
    uint256 constant public min_deposit = 500 trx ;  // 500 trx
    uint256 public tbt_price = 5000 trx; // 5000 trx 
    uint256 constant public one_day = 1 days ;  // 1 days   
    uint256 constant public six_percent = 60 ;  
    uint256 constant public fifteen_percent = 150 ;  
    
    uint256 constant public two_days = 2*one_day ;  
    uint256 constant public divider = 1000 ;   

    mapping(address => User) public users ;
    mapping(address => User2) public users2 ;
 
    uint256 public total_users = 1 ; 
    
    event Upline(address indexed addr, address indexed upline) ;
    event NewDeposit(address indexed addr, uint256 amount) ;
    event DirectPayout(address indexed addr, address indexed from, uint256 amount) ;
    event Withdraw(address indexed addr, uint256 amount) ;
    event LimitReached(address indexed addr, uint256 amount) ;  
    
    uint256 public total_deposited ;
    uint256 public total_withdraw ;
    uint256 public total_tbt_sent ;
    address payable public owner ; 
    address payable public admin ;  
    address payable public admin2 ;  
    address payable public user ;

    constructor( TBT _tbt, 
                address payable _owner, 
                address payable _user, 
                address payable _admin,
                address payable _admin2  
                
                ) public {

        owner = _owner;
        tbt = _tbt;
        admin = _admin; 
        admin2 = _admin2; 
        user = _user; 

        ref_bonuses.push(3);
        ref_bonuses.push(2);
        ref_bonuses.push(1); 
        
        deposit_cycles.push(30000 trx/1000);  //  30000*1000000
        deposit_cycles.push(60000 trx/1000);  //  60000*1000000
        deposit_cycles.push(125000 trx/1000); // 125000*1000000
        deposit_cycles.push(250000 trx/1000); // 250000*1000000
        deposit_cycles.push(500000 trx/1000); // 500000*1000000 
  
        users[owner].deposit_amount = min_deposit;
        users[owner].daily_roi = six_percent; 
        users[owner].payout_time = two_days; 
        users[owner].isActive = true;
        users[owner].deposit_time = block.timestamp ;
        users[owner].last_pay = block.timestamp ; 
        users2[owner].total_deposits += min_deposit ; 
      }

       function() payable external { 
             _deposit(msg.sender, msg.value);     
     }
 
    function _setUpline(address _addr, address payable _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && 
		(users[_upline].deposit_time > 0 || _upline == owner)) {
            
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++; 

            for(uint256 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break; 
                users2[_upline].total_structure++; 
                _upline = users[_upline].upline;
            }
        }
    }

    function _deposit(address _addr, uint256 _amount) private {

        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
        require(users[_addr].isActive == false,"Active deposit exists"); 
       
        uint256 tbt_amount ; 
        
        if(_amount >= tbt_min_deposit){ // 1000 trx | 50 trx
             
            tbt_amount = _amount/(tbt_price/10);  // 1000 trx | 20 trx per token
               
            require(tbt.balanceOf(address(this)) >= tbt_amount*100000 , "TBT balance not sufficient");

            tbt.transfer(msg.sender,tbt_amount*100000); // token transfer

            users2[_addr].tbt_from_deposit += tbt_amount*100000 ;
            users2[_addr].total_tbt += tbt_amount*100000 ;
            total_tbt_sent += tbt_amount*100000 ;

        }
  
        if(users[_addr].deposit_time > 0){ 
             users2[_addr].cycle++ ;
             require(_amount >= users[_addr].deposit_amount && _amount <= deposit_cycles[users2[_addr].cycle > deposit_cycles.length - 1 ? deposit_cycles.length - 1 : users2[_addr].cycle], "Bad amount");
             
        } else {
            require(_amount >= min_deposit && _amount <= deposit_cycles[0], "Bad amount");
        }
        
        users[_addr].payouts = 0;
        users[_addr].deposit_amount = _amount;
        users[_addr].isActive = true;
        users[_addr].daily_roi = six_percent;
        users[_addr].deposit_time = block.timestamp ;
        users[_addr].last_pay = block.timestamp ;  

        users2[_addr].total_deposits += _amount;
        if(_amount >= twenty_four_hours_deposit_value){
            users[_addr].payout_time = one_day; 
        } else {
            users[_addr].payout_time = two_days;
        } 

        total_deposited += _amount; 
        address payable up = users[_addr].upline;   
        emit NewDeposit(_addr, _amount); 

        if((block.timestamp <  users[up].deposit_time + two_days) && users[up].deposit_amount <= _amount ){
            users[up].temp_directs_count++; 
             if(users[up].temp_directs_count >= 3 && users[up].daily_roi == six_percent){
                 users[up].daily_roi = fifteen_percent ;
             }}  

        for(uint256 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break; 
                uint256 bonus = _amount * ref_bonuses[i] / 100; 
                up.transfer(bonus); 
                users[up].level_income[i] += bonus;
                users[up].direct_bonus += bonus;
                emit DirectPayout(up, _addr, bonus); 
                up = users[up].upline;
        } 
        admin.transfer(_amount * 14 / 100);   
        admin2.transfer(_amount / 100);   
        
        if(contract_status == false && address(this).balance > Higher_H_C_B){
            contract_status = true; 
        }
        if(H_C_B < address(this).balance){
            H_C_B = address(this).balance;
            Lower_H_C_B = 85*H_C_B/100;
            Higher_H_C_B = 105*H_C_B/100;
        } 
    }

    function deposit(address payable _upline) payable external {
         if(users2[msg.sender].cycle == 0){
            _setUpline(msg.sender, _upline); 
         }
            _deposit(msg.sender, msg.value); 
    } 
 
    function withdraw(address payable _addr) external {
        
        require(_addr == msg.sender , "you are not allowed to do this"); 
        require(block.timestamp > users[_addr].last_pay + users[_addr].payout_time, "Cannot withdraw now"); 
        require(users[_addr].isActive == true, "User is not active");
 
        uint256 to_payout = this.getROI(msg.sender);
        uint256 to_payout_temp; 
      
        if(to_payout + users[_addr].payouts >= 3*users[_addr].deposit_amount){
            to_payout = 3*users[_addr].deposit_amount - users[_addr].payouts;
            users[_addr].isActive = false;
            emit LimitReached(_addr, 3*users[_addr].deposit_amount);
        } else if(to_payout > address(this).balance ){
            to_payout = 9999*address(this).balance/10000;
        }

        to_payout_temp = to_payout;
        
        uint256 to_tbt = to_payout_temp*15/100;
        to_payout = to_payout_temp*85/100;
        uint256 tbt_amount;
         
        if(to_tbt > 0 ){ 
                
                tbt_amount = to_tbt/(tbt_price/10);  // 1000 trx | 20 trx per token
                tbt.transfer(_addr,tbt_amount*100000); // token transfer
                admin.transfer(to_tbt);
                total_tbt_sent += tbt_amount*100000 ;
                
                users2[_addr].tbt_from_withdrawal += tbt_amount*100000 ;
                users2[_addr].total_tbt += tbt_amount*100000 ;
         }
        
        require(to_payout > 0, "Zero payout");
        
        users2[_addr].total_payouts += to_payout_temp ;
        users[_addr].payouts += to_payout_temp ;
        total_withdraw += to_payout_temp ;
        
        if(to_payout > 0){
             _addr.transfer(to_payout) ; 
             users[_addr].last_pay = block.timestamp ;
        } 

        if(address(this).balance < Lower_H_C_B){
            contract_status = false;
        } 
        emit Withdraw(_addr, to_payout_temp); 
    }

    /*
        Only external call
    */ 

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}  
  
    function changeAdmin1(address payable _newAdmin1) public {
		require(msg.sender == admin || msg.sender == user, "Not allowed");
		admin  = _newAdmin1;
	}   

    function getAdmin() external view returns (address ){ 
         return admin;   
    }   

    function getUser() external view returns (address){ 
        return user;
    } 
    
    function getNow() external view returns (uint256){ 
        return block.timestamp;
    } 

    function getPaySecs() external view returns (uint256){ 
        uint256 secs = block.timestamp - users[msg.sender].last_pay;
        if(secs > users[msg.sender].payout_time){
            secs = users[msg.sender].payout_time;
        }
        return secs;
    } 

    function getROI(address _addr) view external returns(uint256 roi){
        uint256 secsGone = block.timestamp - users[_addr].last_pay;
         if(contract_status == true){
            if(users[_addr].payout_time == one_day){
                if(secsGone > one_day){
                    secsGone = one_day;
                }
                roi = users[_addr].deposit_amount*users[_addr].daily_roi*secsGone/divider/one_day;
            } else {
                if(secsGone > two_days){
                    secsGone = two_days;
               }
                roi = users[_addr].deposit_amount*users[_addr].daily_roi*secsGone/divider/one_day;
            }
        } else {
            if(users[_addr].payout_time == one_day){
                if(secsGone > one_day){
                    secsGone = one_day;
                }
                roi = users[_addr].deposit_amount*users[_addr].daily_roi*secsGone/divider/one_day/2;
            } else {
                if(secsGone > two_days){
                    secsGone = two_days;
               }
                roi = users[_addr].deposit_amount*users[_addr].daily_roi*secsGone/divider/one_day/2;
            }
        }
    }

    function userInfo(address _addr) view external returns(address upline, uint256 deposit_time, uint256 payout_time, uint256 deposit_amount,  uint256 direct_bonus  , bool user_status ) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].payout_time, users[_addr].deposit_amount, users[_addr].direct_bonus , users[_addr].isActive );
    }

    function tbtInfo(address _addr) view external returns(uint256 from_deposit, uint256 from_withdrawal, uint256 total_tbt1, uint256 tbt_bal, uint256 contract_tbt_bal) {
        return (users2[_addr].tbt_from_deposit, users2[_addr].tbt_from_withdrawal, users2[_addr].total_tbt, tbt.balanceOf(_addr), tbt.balanceOf(address(this)));
    }

    function userInfo2(address _addr) view external returns( uint256 temp_directs_count, uint256 last_pay , uint256 daily_roi, uint256 payouts, uint256 my_cycle ) {
        return ( users[_addr].temp_directs_count, users[_addr].last_pay, users[_addr].daily_roi , users[_addr].payouts, users2[_addr].cycle  );
    }
 
    function levelInfo(address _addr) view external returns(uint256 level1, uint256 level2, uint256 level3 ) {
        return (users[_addr].level_income[0] , users[_addr].level_income[1] , users[_addr].level_income[2]  );
    } 
    
    function cycleInfo() view external returns(uint256 cycle1, uint256 cycle2, uint256 cycle3, uint256 cycle4, uint256 cycle5) {
        return (deposit_cycles[0] , deposit_cycles[1] , deposit_cycles[2], deposit_cycles[3], deposit_cycles[4]);
    } 
     
    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure  ) {
        return (users[_addr].referrals, users2[_addr].total_deposits, users2[_addr].total_payouts, users2[_addr].total_structure );
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 H_C_B1 , uint256 Higher_H_C_B1, uint256 Lower_H_C_B1 ) {
        return (total_users, total_deposited, total_withdraw, H_C_B, Higher_H_C_B, Lower_H_C_B  );
    }  
}