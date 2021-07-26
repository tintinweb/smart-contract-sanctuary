/**
 *Submitted for verification at Etherscan.io on 2021-07-26
*/

pragma solidity 0.8.4;


contract Token {
    
    
    string public constant name = "SCHNOUF";
    string public constant symbol = "SCHN";
    uint8 public constant decimals = 18;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    
    
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    
    uint256 totalSupply_;
    
    using SafeMath for uint256;
    
    
    constructor(uint _total) {
        totalSupply_ = _total;
        balances[msg.sender] = _total;
    }
    
    function totalSupply() public view  returns (uint256) {
        return totalSupply_;
    }
    
    
    function balancesOf(address _tokenOwner) public view returns (uint) {
        return balances[_tokenOwner];
    }
    
    function transfer(address _receiver, uint _tokenAmount) public returns (bool) {
        require(_tokenAmount <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_tokenAmount);
        balances[_receiver] = balances[_receiver].add(_tokenAmount);
        emit Transfer(msg.sender, _receiver, _tokenAmount);
        return true;
    }
    
    function approve(address _delegate, uint _tokenAmount) public returns (bool) {
        allowed[msg.sender][_delegate] = _tokenAmount;
        emit Approval(msg.sender, _delegate, _tokenAmount);
        return true;
    }
    
    
    function allowance(address _owner, address _delegate) public view returns (uint) {
        return allowed[_owner][_delegate];
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
      require(numTokens <= balances[owner]);
      require(numTokens <= allowed[owner][msg.sender]);
      
      balances[owner] = balances[owner].sub(numTokens);
      allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
      balances[buyer] = balances[buyer].add(numTokens);
      emit Transfer(owner, buyer, numTokens);
      return true;
    }

}

library SafeMath { 
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