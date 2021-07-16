//SourceUnit: ArkMining.sol

pragma solidity 0.5.10;

interface TokenTRC20{
    function airDown(address _addr, uint256 _value) external;
    function balance(address _addr) view external returns (uint256 _balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract ArkMining {
    uint256 constant MIN_DEPOSIT_AMOUNT = 10000000;
    uint256 constant MAX_PLEDGE_TOTAL_AMOUNT = 1000000000000;
    uint256 constant MINING_TIME_STEP = 3 seconds;
    uint256 constant MINING_CYCLE_TIME = 30*24*60*20;
    uint256 public mining_stop_time;
    uint256 mining_step_amount = 1000000; 
    
    uint256 total_users;
    uint256 total_deposited;  
    uint256 total_withdraw;  
    uint256 start_time = block.timestamp;
    
    address payable public owner;
    address[] all_users;
    
    TokenTRC20 token;
    address payable public token_address;
    uint256 public total_air_amount;
    
	struct User {
		uint256 common_profit;
		uint256 common_profit_time;
        uint256 deposit_time;
        uint256 profit_amount_step;
        uint256 total_deposits;		
        uint256 total_withdraw;
        uint256 total_profit;
    }
    mapping(address => User) users;

    constructor(address payable _token_address) public {
        owner = msg.sender;
        
		token_address = _token_address;
		token = TokenTRC20(token_address);
		
		mining_stop_time = block.timestamp + MINING_CYCLE_TIME*3;
    }
    
    function _airToken(address _addr, uint256 _amount) private {
        if (token.balance(token_address) >= _amount){
            token.airDown(_addr, _amount);
            total_air_amount += _amount;
        }
    }
    
    function deposit(uint256 _amount) external {
        require(block.timestamp < mining_stop_time, "mining stop");

		require(_amount >= MIN_DEPOSIT_AMOUNT, "min amount error");
        
        uint256 new_max_pledge_total_amount = _calcMaxPledgeTotalAmount();
		require(total_deposited - total_withdraw + _amount <= new_max_pledge_total_amount, "beyond max amount");
		
		if (users[msg.sender].deposit_time == 0){
		    total_users++;  
            all_users.push(msg.sender);
		}

        // calc old profit
        uint256 block_time = block.timestamp;
        for(uint256 i = 0; i < total_users; i++) {
            if (all_users[i] == address(0)) continue;
            
            users[all_users[i]].common_profit = _calcCommonProfit(all_users[i]);
            users[all_users[i]].common_profit_time = block_time;
        }
        
        users[msg.sender].deposit_time = block_time;
        users[msg.sender].total_deposits += _amount;
        total_deposited += _amount;
        
        token.transferFrom(msg.sender, address(this), _amount);
    }
    
    function withdraw(uint256 _amount) external {
	    uint256 available_withdraw_amount = users[msg.sender].total_deposits - users[msg.sender].total_withdraw;
        require(_amount > 0 && _amount <= available_withdraw_amount, "withdraw amount error");
		
        uint256 _common_profit = _calcCommonProfit(msg.sender);
        
        users[msg.sender].common_profit = 0;
        users[msg.sender].common_profit_time = block.timestamp;
        
        users[msg.sender].total_withdraw += _amount;
        total_withdraw += _amount;
        
        token.transfer(msg.sender, _amount);
        
        if (_common_profit > 0){
            users[msg.sender].total_profit += _common_profit;
            _airToken(msg.sender, _common_profit);
        }
    }
    
    function mintWithdraw() external {
        uint256 _common_profit = _calcCommonProfit(msg.sender);
        require(_common_profit > 0, "amount is zero");
        
        users[msg.sender].common_profit = 0;
        users[msg.sender].common_profit_time = block.timestamp;
        users[msg.sender].total_profit += _common_profit;
        
        _airToken(msg.sender, _common_profit);
    }

    function _calcCommonProfit(address _addr) view private returns(uint256 _common_profit) {
        if (users[_addr].common_profit_time == 0){
            _common_profit = 0;
        }else{
            uint256 block_time = block.timestamp;
            if (block_time > mining_stop_time){
                block_time = mining_stop_time;
            }
            
            uint256 total_amount = token.balance(address(this));
            
            uint256 times = block_time < users[_addr].common_profit_time ? 0 : ((block_time - users[_addr].common_profit_time) / MINING_TIME_STEP);
            uint256 scale = total_amount == 0 ? 0 : (users[_addr].total_deposits - users[_addr].total_withdraw)*1000000 / total_amount;
    
            _common_profit = scale * times * mining_step_amount/1000000 + users[_addr].common_profit;
        }
    }
    
    function _calcMaxPledgeTotalAmount() view private returns(uint256 _max_pledge_total_amount) {
        uint256 times = (block.timestamp - start_time) / 1 days;
        _max_pledge_total_amount = MAX_PLEDGE_TOTAL_AMOUNT + times*1000000/100;
    }
    
    function getFirstInfo(address _addr) view external returns(uint256 _start_time, uint256 _stop_time, uint256 _total_mining_amount, uint256 _total_available_amount, uint256 _contract_balance, uint256 _common_profit) {
        _start_time = start_time;
        _stop_time = mining_stop_time;
        
        _total_mining_amount = mining_step_amount*MINING_CYCLE_TIME;
        _total_available_amount = _total_mining_amount < total_air_amount ? 0 : (_total_mining_amount - total_air_amount);
		
		_contract_balance = token.balance(address(this));
        _common_profit = _calcCommonProfit(_addr);
    }
    
    function getFinishInfo(address _addr) view external returns(uint256 _stop_time, uint256 _total_mining_amount, uint256 _deposit_amount, uint256 _common_profit) {
        _stop_time = mining_stop_time;
		_total_mining_amount = mining_step_amount*MINING_CYCLE_TIME;
		_deposit_amount = users[_addr].total_deposits - users[_addr].total_withdraw;
        _common_profit = _calcCommonProfit(_addr);
    }
    
    function userInfo(address _addr) view external returns(uint256 _deposit_time, uint256 _deposit_amount, uint256 _total_deposits, uint256 _total_withdraw, uint256 _total_profit, uint256 _profit_amount_step, uint256 _common_profit) {
        _deposit_time = users[_addr].deposit_time;
        _deposit_amount = users[_addr].total_deposits - users[_addr].total_withdraw;
        _total_deposits = users[_addr].total_deposits;
        _total_withdraw = users[_addr].total_withdraw;
        _total_profit = users[_addr].total_profit;
        
        uint256 total_amount = token.balance(address(this));
        _profit_amount_step = total_amount == 0 ? 0 : (users[_addr].total_deposits - users[_addr].total_withdraw)*1000000 / total_amount;
        
        _common_profit = _calcCommonProfit(_addr);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_mining_amount, uint256 _total_available_amount, uint256 _mining_surplus_amount, uint256 _mining_step_amount, uint256 _start_time, uint256 _stop_time, uint256 _contract_balance) {
        _total_users = total_users;
        _total_deposited = total_deposited;
        _total_withdraw = total_withdraw;
        _total_mining_amount = mining_step_amount*MINING_CYCLE_TIME;
        _total_available_amount = _total_mining_amount < total_air_amount ? 0 : (_total_mining_amount - total_air_amount);
        _mining_step_amount = mining_step_amount;
        _start_time = start_time;
        _stop_time = mining_stop_time;
        _contract_balance = token.balance(address(this));
        
        uint256 max_pledge_total_amount = _calcMaxPledgeTotalAmount();
        _mining_surplus_amount = max_pledge_total_amount < _contract_balance ? 0 : (max_pledge_total_amount - _contract_balance);
    }
    
}