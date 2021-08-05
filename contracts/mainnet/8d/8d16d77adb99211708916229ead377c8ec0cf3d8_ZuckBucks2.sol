/**
 *Submitted for verification at Etherscan.io on 2020-12-04
*/

pragma solidity 0.7.4;

contract Token {

    function balanceOf(address _owner) virtual public returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) virtual public returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) virtual public returns (bool success) {}

    function approve(address _spender, uint256 _value) virtual public returns (bool success) {}

    function allowance(address _owner, address _spender) virtual public view returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


contract StandardToken is Token {


    function transfer(address _to, uint256 _value) override public returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) override public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) override view public returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) override public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public circulatingSupply;
}

contract ZuckBucks2 is StandardToken {
    /* Public variables of the token */

    string public name;                     // Zuck Bucks 2: Seize the Diem
    uint256 public decimals;                // 18 decimals
    string public symbol;                   // ZUCC
    address payable private owner;          // Contract creator
    uint public totalSupply;                // 60 million tokens possible to be mined, 1.5 million premined for ZBUX-ZUCC swaps
    uint public minimum_contribution;       // Require that at least 0.001 ETH is sent, 0.001 ETH = 1 tick
    uint256 public starting_giveaway;       // Start by giving away 100 ZUCC
    uint256 public halving_tick;            // Halvings occur every 300,000 "ticks" (mining events)
    uint256 public halving_number;          // Number of halvings that have occured (starts at 0)
    uint256 public giveaway_count;          // Number of ticks (mining events) that have occured
    
    StandardToken private ZBUX;
    
    // "Mining" function
    receive() external payable {
        // Only 32 halvings can occur.
        require(halving_number < 33);
        
        // Only transfer if you send 0.001 ETH or more
        require(msg.value >= minimum_contribution);
        
        // Increment ticks (mining events) in 0.001 ETH increments
        uint256 eth_multiplier = uint(msg.value / minimum_contribution);
        
        // Transfer half the ETH to the owner (for exchange listing fees)
        owner.transfer(msg.value / 2);
        
        // If a halving event occurs...
        if(uint(giveaway_count / halving_tick) < uint((giveaway_count + eth_multiplier) / halving_tick)) triggerHalving(eth_multiplier);
        
        // Increment the number of giveaways
        giveaway_count += eth_multiplier;

        // Calculate the next giveaway amount
        uint256 giveaway_value = (starting_giveaway * ((10**decimals) / (2**halving_number))) * eth_multiplier;

        // "Mine" ZUCC to the sender and increment the circulating supply
        balances[msg.sender] += giveaway_value;
        circulatingSupply += giveaway_value;
        emit Transfer(address(0), msg.sender, giveaway_value);
    }
    
    // Trigger a halving
    function triggerHalving(uint _eth_multiplier) private {
        // Set the halving number (how many halvings have occurred)
        halving_number = uint((giveaway_count + _eth_multiplier) / halving_tick);
        
        // EMIT ETH to the winning miner
        msg.sender.transfer(address(this).balance);
        
    }

    function calculateReward(uint _sentETH) public view returns (uint256 reward) {
        // Increment ticks (mining events) in 0.001 ETH increments
        uint256 eth_multiplier = uint(_sentETH / minimum_contribution);
        uint256 _halving_number;
        
        // If a halving event occurs...
        if(uint(giveaway_count / halving_tick) < uint((giveaway_count + eth_multiplier) / halving_tick)) _halving_number = uint((giveaway_count + eth_multiplier) / halving_tick);
        

        // Calculate the next giveaway amount
        return (starting_giveaway * ((10**decimals) / (2**_halving_number))) * eth_multiplier;
    }
    
    function swapFromZBUX(uint _sentZBUX) public {
        require(_sentZBUX >= 1, "Must swap at least one ZBUX.");
        
        ZBUX.transferFrom(msg.sender, address(0), _sentZBUX);
        
        uint giveaway_value = _sentZBUX * (10**decimals);
        
        // "Mine" ZUCC to the sender and increment the circulating supply
        balances[msg.sender] += giveaway_value;
        balances[owner] -= giveaway_value;
        circulatingSupply += giveaway_value;
        emit Transfer(owner, msg.sender, giveaway_value);
        
    }

    constructor() {
        totalSupply             = 61500000000000000000000000;       // TOTAL POSSIBLE TOKENS
        minimum_contribution    = 1000000000000000;
        balances[msg.sender]    = 1500000000000000000000000;        // SEND OWNER PREMINE
        circulatingSupply       = 0;
        name                    = "Zuck Bucks 2: Seize the Diem";
        decimals                = 18;
        symbol                  = "ZUCC";
        starting_giveaway       = 100;
        owner                   = msg.sender;
        giveaway_count          = 0;
        halving_tick            = 300000;
        halving_number          = 0;
        ZBUX                    = StandardToken(0x7090a6e22c838469c9E67851D6489ba9c933a43F);
    }
    
}