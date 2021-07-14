/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-30
*/
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Fire {
    
    using SafeMath for uint256;
    
    string  public name = "Fire";
    string  public symbol = "XFR";
    string  public standard = "XFR";
    uint256 public totalSupply;
    uint256 public decimals=18;
    

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    
    event LogRebase(
        uint256 indexed _totalSupply
    );

    
    mapping(address => uint256) private UnburnedBalanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    uint256 public StartTime;
    
    uint256 public RebaseNumerator = 1000000000000000000;
    uint256 public constant RebaseDenominator  = 1000000000000000000;
    
    uint256 public constant DeflatorNumerator = 993712;
    uint256 public constant DeflatorDenominator = 1000000;
    
    uint256 public LastRebaseTime;


    constructor () {
        StartTime = block.timestamp;
        LastRebaseTime = StartTime;
        totalSupply = 100000000000000*(10**decimals);
        UnburnedBalanceOf[msg.sender] = totalSupply;
    }
    
    function rebase() public returns (bool success){
        uint256 current_time = block.timestamp;
        
        if (current_time>(StartTime.add(378432000))){
                current_time = StartTime.add(378432000);
            }
        
        uint256 difference = current_time.sub(LastRebaseTime);
        uint256 number_of_days = difference.div(60).div(60).div(24);

        
        for (uint256 i = 0; i<number_of_days; i++){
            RebaseNumerator = RebaseNumerator.mul(DeflatorNumerator).div(DeflatorDenominator);
        }
        
        totalSupply = 100000000000000*(10**decimals).mul(RebaseNumerator).div(RebaseDenominator);
        
        LastRebaseTime = LastRebaseTime.add(number_of_days.mul(24).mul(60).mul(60));
        
        emit LogRebase(totalSupply);
        
        return(true);
        
    }
    
    function balanceOf(address _add) public view returns(uint256 balance){
        
        balance = UnburnedBalanceOf[_add].mul(RebaseNumerator).div(RebaseDenominator);
        
        return(balance);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        
        require(balanceOf(msg.sender) >= _value);
        
        uint256 unburned_value = UnburnedBalanceOf[msg.sender].mul(_value).div(balanceOf(msg.sender));

        UnburnedBalanceOf[msg.sender] = UnburnedBalanceOf[msg.sender].sub(unburned_value);
        UnburnedBalanceOf[_to] = UnburnedBalanceOf[_to].add(unburned_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf(_from));
        require(_value <= allowance[_from][msg.sender]);
        
        uint256 unburned_value = UnburnedBalanceOf[msg.sender].mul(_value).div(balanceOf(msg.sender));
        
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        UnburnedBalanceOf[_from] = UnburnedBalanceOf[_from].sub(unburned_value);
        UnburnedBalanceOf[_to] = UnburnedBalanceOf[_to].add(unburned_value);

        emit Transfer(_from, _to, _value);

        return true;
    }
}