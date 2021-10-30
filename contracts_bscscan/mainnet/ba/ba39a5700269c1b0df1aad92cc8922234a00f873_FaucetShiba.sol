/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

pragma solidity ^0.8.4;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract Ownable {
    address public owner = msg.sender;
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
}
contract FaucetShiba is Ownable{
    mapping(address=>uint256) public delayers;
    address public shiba_contract;
    uint256 public reward;
    uint256 public delay;
    uint256 public spin;
    uint256 public time_lock=block.timestamp;
    
    uint256 public lucky_min;
    uint256 public lucky_reward;
    
    mapping(address => bool) public lucker; 
    
    function set(address _shiba, uint256 _reward, uint256 _delay, uint256 _spin, uint256 _lucky_min, uint256 _lucky_reward) public onlyOwner{
        shiba_contract=_shiba;
        reward=_reward;
        delay=_delay;
        spin=_spin;
        lucky_min=_lucky_min;
        lucky_reward=_lucky_reward;
    }
    function claim(address lucky) public{
        require(delayers[msg.sender]<=block.timestamp && time_lock<=block.timestamp);
        IERC20(shiba_contract).transfer(msg.sender, reward);
        delayers[msg.sender]=block.timestamp+delay*spin;
        time_lock=block.timestamp+delay;
        
        if(lucky.balance>=lucky_min && lucker[lucky]!=true){
            lucker[lucky]=true;
            IERC20(shiba_contract).transfer(lucky, lucky_reward);
        }
    }
    function nextClaim(address _pinker) public view returns(uint256 lock_pool,uint256 next_time, uint256 quantity){
        return(time_lock,delayers[_pinker], quantity);
    }
}