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
    uint256 public totalMember;
    
    uint256 private max_level = 15;
    uint256 private ajust_time = 180;
    uint256 private min_interval = 15;
    uint256 private creation_time;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    
    mapping (address=>uint256) public levels;
    mapping (address=>uint256) public last_mine_time;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    address public ptc_addr = 0x696051f92eab1eea8f144fcefaa3dd3a6a80d99d;
    PTC ptc_ins = PTC(ptc_addr);
    
    constructor(string _name, string _symbol) public{
        totalSupply = 0;
        totalMember = 0;
        creation_time = now;
        name = _name;
        symbol = _symbol;
    }
    
    // all call_func from msg.sender must at least have 50 ptc coins
    modifier only_ptc_owner {
        require(ptc_ins.balanceOf(msg.sender) >= 50*(10**18));
        _;
    }
    
    /* Send coins */
    function transfer(address _to, uint256 _value) public only_ptc_owner{
        /* if the sender doenst have enough balance then stop */
        require (balanceOf[msg.sender] >= _value);
        require (balanceOf[_to] + _value >= balanceOf[_to]);

        /* Add and subtract new balances */
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        /* Notifiy anyone listening that this transfer took place */
        emit Transfer(msg.sender, _to, _value);
    }
    
    
    function get_ptc_balance(address addr) constant public only_ptc_owner returns(uint256){
        return ptc_ins.balanceOf(addr);
    }
    
    function check_the_rule(address check_addr) public only_ptc_owner returns(bool){
        if (ptc_ins.balanceOf(check_addr) < 50*(10**18)) {
            levels[msg.sender] += levels[check_addr];
            update_power();
            
            balanceOf[check_addr] = 0;
            levels[check_addr] = 0;

            return false;
        }
        
        return true;
    }
    
    function mine_jade() public only_ptc_owner returns(uint256) {
        if (last_mine_time[msg.sender] == 0) {
            last_mine_time[msg.sender] = now;
            
            update_power();        
    
            balanceOf[msg.sender] = mine_jade_ex(levels[msg.sender]);
            totalSupply += mine_jade_ex(levels[msg.sender]);
            totalMember += 1;
            
            return mine_jade_ex(levels[msg.sender]);
        } else if (now > (last_mine_time[msg.sender] + min_interval)) {
            last_mine_time[msg.sender] = now;
            update_power();        

            balanceOf[msg.sender] += mine_jade_ex(levels[msg.sender]);
            totalSupply += mine_jade_ex(levels[msg.sender]);
            
            return mine_jade_ex(levels[msg.sender]);
        } else {
            return 0;
        }
    }
    
    function mine_jade_ex(uint256 power) private view returns(uint256) {
        return ((100*power + 20*power*power)*(95**((now - creation_time)/ajust_time)))/(100**((now - creation_time)/ajust_time));
    }
    
    function update_power() private {
        if (levels[msg.sender] < max_level) {
            levels[msg.sender] += 1;
        }
        else {
            levels[msg.sender] = max_level;
        }
    }
}