/**
 *Submitted for verification at Etherscan.io on 2021-06-03
*/

pragma solidity ^0.4.23;

contract  ERC20 {
    function totalSupply() external constant returns (uint256 _totalSupply);
    function balanceOf(address addr_) external constant returns (uint256 bal);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address from_, address to_, uint256 _value) external returns (bool);
    function approve(address spender_, uint256 value_) external returns (bool);
    function allowance(address _owner, address _spender) external constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract CoinpassErc is ERC20 {
    using SafeMath for uint256;
    string public constant symbol = "3haz1";
    string public constant name = "3haz1 token";
    uint256 public constant decimals = 8;
    address owner;
    
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    
    uint256 private constant totalsupply_ = 10000000000000;
    
    
    mapping(address => uint256) private balanceof_;
    mapping(address => mapping(address => uint256)) private allowance_;

    constructor() public{
        
        balanceof_[msg.sender] = totalsupply_;
        owner = msg.sender;
    }
    
    function totalSupply() external constant returns(uint256 _totalsupply){
        
        return totalsupply_;
        
    }
    

    function balanceOf(address addr_) external constant returns(uint256 bal){
     
       return balanceof_[addr_];
        
    }

    
    

    function transfer(address to_, uint256 value_) external returns (bool){
        require(value_ <= balanceof_[msg.sender]);
        require(to_ != address(0));
        // SafeMath.sub will throw if there is not enough balance.

        balanceof_[msg.sender] = balanceof_[msg.sender].sub(value_);
        balanceof_[to_] = balanceof_[to_].add(value_);
        emit Transfer(msg.sender, to_, value_);
        return true;
        
    }
    
    

    function transferFrom(address from_, address to_, uint256 _value) external returns (bool){
       
        require(_value <= balanceof_[from_]);
        require(_value <= allowance_[from_][msg.sender]);
        require(to_ != address(0));

        balanceof_[from_] =balanceof_[from_].sub(_value);
        allowance_[from_][msg.sender] = allowance_[from_][msg.sender].sub(_value);
        balanceof_[to_] =balanceof_[to_].add(_value);
        emit Transfer(from_, to_, _value);

        return true;

    }

    
    function approve(address spender_, uint256 value_) external returns (bool){
        
        require(spender_ != address(0));

        bool status = false;

        if(balanceof_[msg.sender] >= value_){
            allowance_[msg.sender][spender_] = value_;
            emit Approval(msg.sender, spender_, value_);
            status = true;
        }

        return status;
    }

    function allowance(address _owner, address _spender) external constant returns (uint256 remaining) {
        return allowance_[_owner][_spender];
        
    }



    struct lock_box{
        
        uint256 value_;
        uint256 releaseTime;
    }
    
    lock_box[] public lockbox_arr;

    modifier onlyOwner {
      require(msg.sender == owner) ;
      _;
    }
    
    function lock_erc(uint256 value_, uint256 releaseTime) onlyOwner external returns (uint256) {
        
        if(lockbox_arr.length == 0){
            lockbox_arr.length++;
        }        

        balanceof_[msg.sender] =balanceof_[msg.sender].sub(value_);
        
        lockbox_arr.length++;

        lockbox_arr[lockbox_arr.length-1].value_ = value_;
        lockbox_arr[lockbox_arr.length-1].releaseTime = releaseTime;
        
        return lockbox_arr.length-1;
      
    }
    
    function release_erc(uint256 lockbox_no) onlyOwner public returns(bool){
        
        bool status = false;
        
        lock_box storage lb = lockbox_arr[lockbox_no];
        
        
        uint256 value_ = lb.value_;
        uint256 releaseTime = lb.releaseTime;
        
        if(releaseTime < now){
            balanceof_[owner] = balanceof_[owner].add(value_);
            status = true;
            lb.value_ = 0;
        }
        
        return status;
    }
    
    

}