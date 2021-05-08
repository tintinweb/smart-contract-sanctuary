/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-07
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
contract NFTSHARK is ERC20 {
    
    string public name = "NFTSHARK";
    string public symbol = "NFTS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1 * 10**9 * 10**18;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    address public owner;
    address private giveawayWallet;
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    
    constructor(address _giveawayWallet) public {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        giveawayWallet = _giveawayWallet;
    }
    
    function balanceOf(address _address) public view returns (uint256 balance) {
        return balances[_address];
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Zero address error");
        require(balances[msg.sender] >= _value && _value > 0, "Insufficient balance or zero amount");

        uint256 _holdersRewardsAmount = SafeMath.div(_value,10);
        balances[giveawayWallet] = SafeMath.add(balances[giveawayWallet], _holdersRewardsAmount);

        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
        balances[_to] = SafeMath.add(balances[_to], SafeMath.sub(_value,_holdersRewardsAmount));
        emit Transfer(msg.sender, _to, _value);
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
        require(_from != address(0) && _to != address(0), "Zero address error");
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0, "Insufficient balance or zero amount");
        balances[_from] = SafeMath.sub(balances[_from], _value);
        uint256 _holdersRewardsAmount = SafeMath.div(_value,10);
        balances[giveawayWallet] = SafeMath.add(balances[giveawayWallet], _holdersRewardsAmount);
        
        balances[_to] = SafeMath.add(balances[_to], SafeMath.sub(_value,_holdersRewardsAmount));
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    
    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
    }
    
    
}