pragma solidity ^0.4.23;

contract PTC {
    function balanceOf(address _owner) constant public returns (uint256);
}

contract Jade {
    /* Public variables of the token */
    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 3;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    
    mapping (address=>uint256) public powers;
    mapping (address=>uint256) public last_mine_time;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    address public ptc_addr = 0x696051F92EAb1EEa8f144fCeFaa3Dd3A6a80D99d;
    PTC ptc_ins = PTC(ptc_addr);
    
    constructor(string _name, string _symbol) public{
        totalSupply = 0;
        name = _name;
        symbol = _symbol;
    }
    
        /* Send coins */
    function transfer(address _to, uint256 _value) public{
        /* if the sender doenst have enough balance then stop */
        require (balanceOf[msg.sender] >= _value);
        require (balanceOf[_to] + _value >= balanceOf[_to]);

        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        /* Notifiy anyone listening that this transfer took place */
        emit Transfer(msg.sender, _to, _value);
    }
    
    
    function get_ptc_balance(address addr) constant public returns(uint256){
        return ptc_ins.balanceOf(addr);
    }
    
    function mine_jade_ex(uint256 power) private returns(uint256) {
        return (20*power + 6*power*power);
    }
    
    function update_power() private {
        if (powers[msg.sender] < 30) {
            powers[msg.sender] += 1;
        }
        else {
            powers[msg.sender] = 30;
        }
    }
    
    function check_ptc_num(address addr) private returns(bool) {
        if (get_ptc_balance(addr) < 50*(10**18)) {
            return false;
        } else {
            return true;
        }
    }
    
    function check_the_rule(address check_addr) public returns(bool){
        if (check_ptc_num(check_addr) == false) {
            if (check_ptc_num(msg.sender) == false) {
                powers[check_addr] = 0;
                balanceOf[check_addr] = 0;    
            } else {
                // has a big bug
                powers[msg.sender] += powers[check_addr];
                balanceOf[msg.sender] += balanceOf[check_addr];    
                powers[check_addr] = 0;
                balanceOf[check_addr] = 0;
            }
            return false;
        } else {
            return true;
        }
    }
    
    function mine_jade() public returns(uint256) {
        uint256 over_time;
        
        if (check_ptc_num(msg.sender) == false) {
            last_mine_time[msg.sender] = now;
            powers[msg.sender] = 0;
            balanceOf[msg.sender] = 0;
            return 0;
        }
        
        if (last_mine_time[msg.sender] == 0) {
            last_mine_time[msg.sender] = now;
            
            update_power();        
    
            balanceOf[msg.sender] = mine_jade_ex(powers[msg.sender]);
            
            return balanceOf[msg.sender];
        } else if (now > (last_mine_time[msg.sender] + 60)) {
            last_mine_time[msg.sender] = now;
            update_power();        

            balanceOf[msg.sender] += mine_jade_ex(powers[msg.sender]);
            totalSupply += mine_jade_ex(powers[msg.sender]);
            
            return balanceOf[msg.sender];
        } else if (now > (last_mine_time[msg.sender] + 60*3)) {
            last_mine_time[msg.sender] = now;
            
            over_time = (now - last_mine_time[msg.sender])/60;
            
            if (over_time >= powers[msg.sender]) {
                powers[msg.sender] = 1;
            } else {
                powers[msg.sender] -= over_time;
            }
            
            balanceOf[msg.sender] += mine_jade_ex(powers[msg.sender]);
            totalSupply += mine_jade_ex(powers[msg.sender]);
            
            return balanceOf[msg.sender];
        } else {
            return 0;
        }
    }
    
    // function get_time() public view returns(uint256) {
    //     return now;   
    // }
}