/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

pragma solidity >=0.4.22 <0.6.0;

contract PuffyFactory {

    string public constant name = "PuffyCoin";
    string public constant symbol = "PUF";
    uint8 public constant decimals = 18;  

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event onMined(address, uint256 tokens);    
    event levelUp(uint256 level);    

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => uint256) public levelOf;
    uint256 public totalSupply_;
    uint256 public _contractLevel = 1;
    uint256 public _numberInLevel = 0;
    uint256 public _ethBurn = 0 ether;

    using SafeMath for uint256;

    constructor() public payable{  
        join();
    }  
    
    function join()
        public
        payable
    {
        address _customerAddress = msg.sender;
        require(levelOf[_customerAddress] == 0 && msg.value >= _ethBurn);
        uint256 earnedTokens = 1;
        levelOf[_customerAddress] = _contractLevel; 
        balances[_customerAddress] = balances[_customerAddress].add(earnedTokens);
        _numberInLevel = _numberInLevel.add(earnedTokens); 
        if (_numberInLevel == _contractLevel){
            _contractLevel = _contractLevel.add(1);
            _ethBurn.add(.00001 ether);
            _numberInLevel = 0;
            mine();
         emit levelUp(_contractLevel);
       }
        totalSupply_ = totalSupply_.add(earnedTokens);
        emit onMined(_customerAddress, earnedTokens);
    }
    
    function mine()
        public
    {
        address _customerAddress = msg.sender;
        require(levelOf[_customerAddress] != _contractLevel && levelOf[_customerAddress] > 0);
        uint256 earnedTokens = _contractLevel.sub(levelOf[_customerAddress]);
        balances[_customerAddress] = balances[_customerAddress].add(earnedTokens);
        _numberInLevel = _numberInLevel.add(earnedTokens); 
        if (_numberInLevel == _contractLevel){
            _contractLevel = _contractLevel.add(1);
            _numberInLevel = 1;
            earnedTokens = earnedTokens.add(1);
            balances[_customerAddress] = balances[_customerAddress].add(1);
            _ethBurn.add(.00001 ether);
            emit levelUp(_contractLevel);
        } else if (_numberInLevel > _contractLevel){
            _numberInLevel = _numberInLevel.sub(_contractLevel);
            _contractLevel = _contractLevel.add(1);
            earnedTokens = earnedTokens.add(1);
            balances[_customerAddress] = balances[_customerAddress].add(1);
            _ethBurn.add(.00001 ether);
            emit levelUp(_contractLevel);
        }
        levelOf[_customerAddress] = _contractLevel; 
        totalSupply_ = totalSupply_.add(earnedTokens);
        emit onMined(_customerAddress, earnedTokens);
    }

    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    
    
    function puffToMine(address tokenOwner) public view returns (uint256) {
        if(levelOf[tokenOwner]==0){return 1;}
        else {return _contractLevel - levelOf[tokenOwner];}
    }
    
    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
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