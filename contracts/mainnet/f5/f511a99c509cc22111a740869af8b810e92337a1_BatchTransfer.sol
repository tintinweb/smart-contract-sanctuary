pragma solidity ^0.4.23;

contract ERC20 {

    // optional functions
    function name() public view returns (string);
    function symbol() public view returns (string);
    function decimals() public view returns (uint8);

    // required functios
    function balanceOf(address user) public view returns (uint256);
    function allowance(address user, address spender) public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool); 
    function approve(address spender, uint256 value) public returns (bool); 

    // required events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed user, address indexed spender, uint256 value);
}

contract BatchTransfer {
    address private _owner;
    address private _erc20_address;
    mapping(address => bool) private _authed_addresses;

    constructor(address erc20_address) public {
        _owner = msg.sender;
        _erc20_address = erc20_address;
        _authed_addresses[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "require owner permission");
        _;
    }

    modifier onlyAuthed() {
        require(_authed_addresses[msg.sender], "require auth permission");
        _;
    }

    /**
        function to update auth, contract owner can grant other account auth permission by this
        it require:
            1. transaction sender grant owner permission
        please check requirement before you invoke  
     */
    function updateAuth(address auth_address, bool is_auth) public onlyOwner {
        _authed_addresses[auth_address] = is_auth;
    }

    /**
        convinient function for read token&#39;s owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
        convinient function for read token&#39;s erc20Address
     */
    function erc20Address() public view returns (address) {
        return _erc20_address;
    }

    /**
        convinient function for read is address authed
     */
    function isAuthed(address authed_address) public view returns (bool){
        return _authed_addresses[authed_address];
    }

    /**
        function for batch transfer
        it require:
            1. token_holder have suffcient balance
            2. token_holder approve enough token to this contract
            3. transaction sender grant auth permission
        please check requirement before you invoke  
     */
    function transferFrom(address token_holder, address[] token_receivers, uint256[] values) public onlyAuthed returns (bool) {
        require(token_receivers.length == values.length, "token_receiver&#39;s size must eq value&#39;s size");
        require(token_receivers.length > 0, "token_receiver&#39;s length must gt 0");
        
        uint length = token_receivers.length;

        // share variables, declare here for reuse later
        uint i = 0;
        uint value = 0;
        uint total_value = 0;

        for(i = 0; i < length; ++i) {
            value = values[i];
            require(value > 0, "value must gt 0");
            total_value += value;
        }
        
        ERC20 token_contract = ERC20(_erc20_address);
        uint256 holder_balance = token_contract.balanceOf(token_holder);
        require(holder_balance >= total_value, "balance of holder must gte total_value");
        uint256 my_allowance = token_contract.allowance(token_holder, this);
        require(my_allowance >= total_value, "allowance to contract must gte total_value");

        // perform real transfer; require all transaction success; if one fail, all fail
        for(i = 0; i < length; ++i) {
            address token_receiver = token_receivers[i];
            value = values[i];
            bool is_success = token_contract.transferFrom(token_holder, token_receiver, value);
            require(is_success, "transaction should be success");
        }

        return true;
    }
}