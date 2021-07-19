//SourceUnit: TronInfinityLevel.sol

pragma solidity >= 0.5.0;

contract TronInfinityLevel {
    
    event TronMultisendLevel(uint256 value , address indexed sender);
    event TronAirdropLevel(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    
    function InfinityDropTRXLevel(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
            _userAddresses[i].transfer(_amount);
            emit TronAirdropLevel(_userAddresses[i], _amount);
        }
    }
    
    function InfinityMultiTRXLevel(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit TronMultisendLevel(msg.value, msg.sender);
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
}