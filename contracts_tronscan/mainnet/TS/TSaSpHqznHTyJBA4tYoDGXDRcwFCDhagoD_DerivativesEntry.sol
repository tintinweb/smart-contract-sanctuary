//SourceUnit: drv-entry.sol

pragma solidity ^0.4.25;

contract Derivatives
{
    struct Client
	{
		uint256 hard_balance_unit_cents;
		uint256 soft_balance_unit_cents;
		
		uint256 position_type; // 0 long, 1 short
		uint256 quantity_usd;
		uint256 price_in_usd_cents;
	}
	
    address public master;
    address public service;
	uint256 public price_in_usd_cents;
	uint256 public hard_reserved_unit_cents;
	mapping (address => Client) public clients;
	
	uint256 public constant UNIT_CENTS = 10 ** 6;
    uint256 public constant USD_CENTS = 10 ** 8;

    function deposit() external payable;
    function withdrawal(uint256 value) external;
	function set_price(uint256 new_price) external;
	function set_price_and_liquidation(uint256 new_price, address[] to_liquidate) external;
	function liquidation(address[] to_liquidate) external;
    function create_order_long(uint256 quantity_usd) external;
    function create_order_short(uint256 quantity_usd) external;
    function create_order_x_long(uint256 x) external;
    function create_order_x_short(uint256 x) external;
}

contract DerivativesEntry is Derivatives
{
	uint public master_confirmation_time;
	address public next_service;
	uint public next_service_request_time;
	uint256 master_withdrawal_value;
	uint master_withdrawal_time;
	
    event on_price(uint256 price);
    event on_deposit(address indexed target, uint256 value);
    event on_withdrawal(address indexed target, uint256 value);
    event on_create_order(address indexed target, uint256 quantity_usd, uint256 position_type, uint256 price);
    event on_liquidate(address indexed target, uint256 quantity_usd, uint256 position_type, uint256 price, uint256 liquidation_price);
    event try_create_order(address indexed target, uint256 quantity_usd, uint256 position_type, uint256 price);
    event on_debug(uint256 label);

    constructor() public
    {
        master = msg.sender;
        master_confirmation_time = now;
    }
    
    function master_confirmation() external
    {
        require(msg.sender == master, "only master can do this");
        
        master_confirmation_time = now;
    }
    
    function become_master() external
    {
        require(master_confirmation_time + 3 days < now, "too early");
        
        master = msg.sender;
    }
    
    function request_next_service(address _service) external
    {
        require(msg.sender == master, "only master can do this");
        
        next_service = _service;
        next_service_request_time = service != address(0)? now:(now - 3 days);
    }
    
    function set_next_service() external
    {
        require(msg.sender == master, "only master can do this");
        require(next_service_request_time + 3 days < now, "too early");
        
        service = next_service;
    }
    
    function master_withdrawal_request(uint256 value) external
    {
        require(msg.sender == master, "only master can do this");
     
     	master_withdrawal_value = value;
	    master_withdrawal_time = now;
    }
    
    function master_withdrawal() external
    {
        require(msg.sender == master, "only master can do this");
        require(master_withdrawal_time + 3 days < now, "too early");
        require(master_withdrawal_value > 0, "only positive value");

		uint256 contract_balance = address(this).balance;
		require(contract_balance >= hard_reserved_unit_cents + master_withdrawal_value);
		
		msg.sender.transfer(master_withdrawal_value);
		
     	master_withdrawal_value = 0;
    }
    
    function deposit() external payable
    {
        require(service != address(0), "service not initialized");
        
        bool success = service.delegatecall(abi.encodeWithSignature("deposit()"));
        require(success, "delegatecall failed");
    }

    function withdrawal(uint256 value) external
    {
        require(service != address(0), "service not initialized");
        
        bool success = service.delegatecall(abi.encodeWithSignature("withdrawal(uint256)", value));
        require(success, "delegatecall failed");
    }
    
    function set_price(uint256 new_price) external
    {
        require(service != address(0), "service not initialized");
        
        bool success = service.delegatecall(abi.encodeWithSignature("set_price(uint256)", new_price));
        require(success, "delegatecall failed");
    }
    
	function set_price_and_liquidation(uint256 new_price, address[] to_liquidate) external
	{
        require(service != address(0), "service not initialized");
        
        bool success = service.delegatecall(abi.encodeWithSignature("set_price_and_liquidation(uint256,address[])", new_price, to_liquidate));
        require(success, "delegatecall failed");
	}
	
	function liquidation(address[] to_liquidate) external
	{
        require(service != address(0), "service not initialized");
        
        bool success = service.delegatecall(abi.encodeWithSignature("liquidation(address[])", to_liquidate));
        require(success, "delegatecall failed");
	}
    
    function create_order_long(uint256 quantity_usd) external
    {
        require(service != address(0), "service not initialized");
        
        bool success = service.delegatecall(abi.encodeWithSignature("create_order_long(uint256)", quantity_usd));
        require(success, "delegatecall failed");
    }
    
    function create_order_short(uint256 quantity_usd) external
    {
        require(service != address(0), "service not initialized");
        
        bool success = service.delegatecall(abi.encodeWithSignature("create_order_short(uint256)", quantity_usd));
        require(success, "delegatecall failed");
    }
    
    function create_order_x_long(uint256 x) external
    {
        require(service != address(0), "service not initialized");
        
        bool success = service.delegatecall(abi.encodeWithSignature("create_order_x_long(uint256)", x));
        require(success, "delegatecall failed");
    }
    
    function create_order_x_short(uint256 x) external
    {
        require(service != address(0), "service not initialized");
        
        bool success = service.delegatecall(abi.encodeWithSignature("create_order_x_short(uint256)", x));
        require(success, "delegatecall failed");
    }
}