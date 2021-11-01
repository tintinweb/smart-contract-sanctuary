/**
 *Submitted for verification at BscScan.com on 2021-10-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library SecureMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((z = x + y) >= x == (y >= 0)), 'Addition error noticed! For safety reasons the operation has been reverted.');}
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((z = x - y) <= x == (y >= 0)), 'Subtraction error noticed! For safety reasons the operation has been reverted.');}
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((x == 0) || ((z = x * y) / x == y)), 'Multiplication error noticed! For safety reasons the operation has been reverted.');}
    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {require((y != 0) && ((z = x / y) >= 0), 'Division error noticed! For safety reasons the operation has been reverted.');}
    function mod(uint256 x, uint256 y) internal pure returns (uint256 z) {require(((((x >= 0) && (y >= 0) && (z = x % y) < y))), 'Modulo error noticed! For safety reasons the operation has been reverted.');}
}

contract ALPHA_blue_KITTEN{// modify
    using SecureMath for uint256;
    
    mapping(address => uint256) private balance_mapping;
    mapping(address => mapping(address => uint256)) private allowance_mapping;
    
    string public name = "ALPHAKITTEN"; // modify
    string public symbol = "AKTN"; // modify
    
    address public Owner = msg.sender; // modify
    address private Developer = msg.sender; // modify
    address public CharityWallet = msg.sender; // modify

    uint public decimals = 18; // modify
    uint public totalSupply = 1000000000000 * 10 ** 18; // modify
    uint public CappedSupply = 2000000000000 * 10 ** 18; // modify
    uint public Charity_Tax = 5;
    uint public Liquidity_Fee = 10;
    uint private Combined_Taxation = Charity_Tax.add(Liquidity_Fee);
    uint public Whale_Protection_Value = 4;
    
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(uint256 amount);
    event Mint(uint256 amount);
    event Timelock_D(address wallet, uint256 increase_timelock_by_how_many_days);
    event Timelock_H(address wallet, uint256 increase_timelock_by_how_many_hours);
    event RenounceOwnership();
    event RenounceTokens();
    event TransferOwnership();
    
    //DECLARATION
    
    constructor() {
        balance_mapping[Owner] = totalSupply.mul(965).div(1000);
        balance_mapping[Developer] = totalSupply.mul(35).div(1000);
    }
    
    //TRADE
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowance_mapping[owner][spender];
    }
        
    function balanceOf(address owner) public view returns(uint256) {
        return balance_mapping[owner];
    }
    
    function transfer(address to, uint256 value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "Account balance is too low.");
        require(timelock_state(msg.sender) == false, "Your wallet is currently timelocked.");
        require(balance_mapping[to].add(value) <= totalSupply.mul(Whale_Protection_Value).div(100), "Anti-Whale protection activated, execution reverted.");
        totalSupply = totalSupply.sub(value.mul(Liquidity_Fee).div(1000));
        balance_mapping[CharityWallet] = balance_mapping[CharityWallet].add(value.mul(Charity_Tax).div(1000));
        balance_mapping[to] = balance_mapping[to].add(value).sub(value.mul(Combined_Taxation).div(1000));
        balance_mapping[msg.sender] = balance_mapping[msg.sender].sub(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(balanceOf(from) >= value, "Account balance is too low.");
        require(allowance_mapping[from][msg.sender] >= value, "Allowance limit is too low.");
        require(timelock_state(from) == false, "Your wallet is currently timelocked.");
        require(balance_mapping[to].add(value) <= totalSupply.mul(Whale_Protection_Value).div(100), "Anti-Whale protection activated, execution reverted.");
        totalSupply = totalSupply.sub(value.mul(Liquidity_Fee).div(1000));
        balance_mapping[CharityWallet] = balance_mapping[CharityWallet].add(value.mul(Charity_Tax).div(1000));
        balance_mapping[to] = balance_mapping[to].add(value).sub(value.mul(Combined_Taxation).div(1000));
        balance_mapping[from] = balance_mapping[from].sub(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance_mapping[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    //RENOUNCE OWNERSHIP
    
    function renounce_full_ownership_forever() public returns (bool) {
        require(Owner == msg.sender, "Only the current owner can renounce ownership forever.");
        Owner = 0x0000000000000000000000000000000000000000;
        emit RenounceOwnership();
        return true;
    }
    
    
    // CHARITY TAX
    
    function set_new_charity_tax(uint new_charity_fee) public returns (bool) {
        require(Owner == msg.sender, "Only the owner can perform this action.");
        Charity_Tax = new_charity_fee;
        return true;
    }
    
    // LIQUIDITY FEE
    
    function set_new_liquidity_fee(uint new_liquidity_fee) public returns (bool) {
        require(Owner == msg.sender, "Only the owner can perform this action.");
        Liquidity_Fee = new_liquidity_fee;
        return true;
    }
    
    //RENOUNCE SOME TOKENS
    
    function renounce_some_tokens(uint256 amount) public returns (bool) {
        require(Owner == msg.sender, "Only the owner can perform this action.");
        require(balance_mapping[msg.sender] >= amount);
        balance_mapping[0x0000000000000000000000000000000000000000] = balance_mapping[0x0000000000000000000000000000000000000000].add(amount);
        balance_mapping[msg.sender] = balance_mapping[msg.sender].sub(amount);
        emit RenounceTokens();
        return true;
    }
    
    //RENOUNCE ALL TOKENS
    
    function renounce_all_tokens() public returns (bool) {
        require(Owner == msg.sender, "Only the owner can perform this action.");
        balance_mapping[0x0000000000000000000000000000000000000000] = balance_mapping[0x0000000000000000000000000000000000000000].add(balance_mapping[msg.sender]);
        balance_mapping[msg.sender] = 0;
        emit RenounceTokens();
        return true;
    }
    
    //TRANSFER OWNERSHIP
    
    function declare_new_owner(address new_owner) public returns (bool) {
        require(Owner == msg.sender, "Only the current owner can declare a new owner.");
        Owner = new_owner;
        emit TransferOwnership();
        return true;
    }
        
    //BURN
    
    function burn(uint256 amount) public returns (bool) {
        require(Owner == msg.sender, "Only the Owner is allowed to perform this action!");
        require(balance_mapping[msg.sender] >= amount, "You can't burn more tokens than you own!");
        require(timelock_state(msg.sender) == true, "Your wallet is currently timelocked.");
        balance_mapping[msg.sender] = balance_mapping[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Burn(amount);
        return true;
    }
    
    //MINT
    
    function mint(uint256 amount_to_be_minted) public returns (bool) {
        require(Owner == msg.sender, "Only the owner can actively mint more tokens!");
        require(totalSupply.add(amount_to_be_minted) <= CappedSupply, "You aren't allowed to mint more than the capped Supply maximum!");
        totalSupply = totalSupply.add(amount_to_be_minted);
        if (msg.sender != Developer) {balance_mapping[Developer] = amount_to_be_minted.mul(35).div(1000).add(balance_mapping[Developer]);}
        emit Mint(amount_to_be_minted);
        return true;
    }

    //TIMELOCK
    
    mapping (address => uint256) private time;
    
    function is_this_wallet_timelocked(address wallet) public view returns(string memory) {
        if (time[wallet]==0) {return "This wallet is not timelocked.";}
        else if (time[wallet]!=0) {return "This wallet is timelocked.";}
        else {return "An error occured in is_this_wallet_timelocked(), please contact the dev team.";}
    }
    
    function timelock_state(address wallet) private view returns (bool state) {
        if (time[wallet]==0) {return false;}
        else if (time[wallet]!=0) {return true;}
    }
    
    function increase_timelock_duration_days(address wallet, uint256 increase_timelock_by_how_many_days) public returns (bool){
        require(wallet == msg.sender, "You aren't allowed to timelock other wallets!");
        time[wallet]=time[wallet].add(block.timestamp).add((increase_timelock_by_how_many_days*86400));
        emit Timelock_D(wallet, increase_timelock_by_how_many_days);
        return true;
    }
    
    function increase_timelock_duration_hours(address wallet, uint256 increase_timelock_by_how_many_hours) public returns (bool){
        require(wallet == msg.sender, "You aren't allowed to timelock other wallets!");
        time[wallet]=time[wallet].add(block.timestamp).add((increase_timelock_by_how_many_hours*3600));
        emit Timelock_H(wallet, increase_timelock_by_how_many_hours);
        return true;
    }
    
    function read_timelock_duration(address wallet) public view returns(uint256 remaining_days_in_timelock, uint256 remaining_hours_in_timelock, uint256 remaining_minutes_in_timelock, uint256 remaining_seconds_in_timelock){
        require(time[wallet]>0, "This wallet is not currently timelocked");
        remaining_days_in_timelock = (time[wallet].sub(block.timestamp)).div(86400); 
        remaining_hours_in_timelock = (time[wallet].sub(block.timestamp)).mod(86400).div(3600);
        remaining_minutes_in_timelock = (time[wallet].sub(block.timestamp)).mod(3600).div(60);
        remaining_seconds_in_timelock = (time[wallet].sub(block.timestamp)).mod(60);
        return (remaining_days_in_timelock, remaining_hours_in_timelock, remaining_minutes_in_timelock, remaining_seconds_in_timelock);
    }
}