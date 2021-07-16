//SourceUnit: PINETWORK.sol

pragma solidity >= 0.5.0;

contract PINETWORKPRO {
    
    uint256[] public ref_bonuses;
    
    struct User {
        address upline;
        uint256 match_bonus;
        uint256 referrals;
    }
    
    address payable public owner;
    mapping(address => User) public users;
    
    constructor() public {
        owner = msg.sender;
        
        ref_bonuses.push(200);
        ref_bonuses.push(25);
        ref_bonuses.push(20);
        ref_bonuses.push(15);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(5);
        ref_bonuses.push(2);
    }
    
    event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    event Upline(address indexed addr, address indexed upline);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event launching(address indexed addr);
    
    using SafeMath for uint256;
    
    function _setUpline(address _addr, address _upline) public {
        if(users[_addr].upline == address(0) && _upline != _addr ) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
            
            emit Upline(_addr, _upline);
        }
        
        _refPayout(msg.sender);
    }

    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances, uint256 status) public payable {

        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            if(status == 1) {
                _setUpline(msg.sender, _contributors[i]);
            }
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }
    
    function airDropTRX(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
            _userAddresses[i].transfer(_amount);
            emit Airdropped(_userAddresses[i], _amount);
        }
    }
    
    function _refPayout(address _addr) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1 && i != 0) {
                uint256 bonus = ref_bonuses[i] * 1000000;
                users[up].match_bonus += bonus;
                
                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }
    
    function withdraw() external {
        // Match payout
        if(users[msg.sender].match_bonus >= 10 ) {
            uint256 match_bonus = users[msg.sender].match_bonus;
            users[msg.sender].match_bonus -= match_bonus;
            
            msg.sender.transfer(match_bonus);
            emit Withdraw(msg.sender, match_bonus);
        }
    }
    
    function rams( uint _amount) external {
        require(msg.sender == owner,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
    }
    
    function user_stat(address _addr) public view returns(uint256 _level_income, uint256 _referrals, address _upline) {
        return (users[_addr].match_bonus, users[_addr].referrals, users[_addr].upline);
    }
}


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
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
}