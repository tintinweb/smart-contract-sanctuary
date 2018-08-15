pragma solidity 0.4.24;

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
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}
contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
contract DVPlock is Ownable{
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  ERC20 public token;
  address public sponsor;
  mapping (address => uint256) public balances;
  mapping (address => uint256) public withdrawAmounts;
  uint256 public tokenTotal;
  uint256 public releaseTime;

  constructor() public{
    releaseTime = 0;
    tokenTotal = 0;
    sponsor = msg.sender;    
  }

  function setToken(ERC20 _token) onlyOwner public{
    //Only allowed once
    if(token!=address(0)){
      revert();
    }
    token = _token;
  }


  function setReleaseTime(uint256 _releaseTime) onlyOwner public{
      require(releaseTime==0);
      releaseTime = _releaseTime;
      require(addSponsor(sponsor));
  }


  // for sponsor 20% tokens
  function addSponsor(address _sponsor) internal returns(bool result){
      uint256 _amount =token.totalSupply()/5;
      return addInvestor(_sponsor,_amount);
  }

  function addInvestor(address investor,uint256 amount) onlyOwner public returns(bool result){
      if(releaseTime!=0){
          require(block.timestamp < releaseTime);
      }
      require(tokenTotal == token.balanceOf(this));
      balances[investor] = balances[investor].add(amount);
      tokenTotal = tokenTotal.add(amount);

      if(tokenTotal>token.balanceOf(this)){
          token.safeTransferFrom(msg.sender,this,amount);
      }
      return true;
  }

  
  
  function release() public {
    require(releaseTime!=0);
    require(block.timestamp >= releaseTime);
    require(balances[msg.sender] > 0);

    //60*60*24*30*3 second = 1 quarter,If the time difference is more than 1 quarters, it means that it has been released 1 times.
    uint256 released_times = (block.timestamp-releaseTime).div(60*60*24*30*3); 
    uint256 _amount = 0;
    uint256 lock_quarter = 0;
    
    if(msg.sender!=sponsor){
        //The white paper stipulates that investors&#39; balance needs to be locked up for 1.5 years and released on a quarterly average.So 1.5 years =18 months =6 quarter
        lock_quarter = 6 ;
    }else{
         //The white paper stipulates that sponsor&#39; balance needs to be locked up for 3 years and released on a quarterly average.So 3 years =36 months =12 quarter
        lock_quarter = 12;
    }
    
    if(withdrawAmounts[msg.sender]==0){
        withdrawAmounts[msg.sender]= balances[msg.sender].div(lock_quarter);
    }
    
    if(released_times>=lock_quarter){
        _amount = balances[msg.sender];
    }else{
        _amount = balances[msg.sender].sub(withdrawAmounts[msg.sender].mul(lock_quarter.sub(released_times+1)));
    }

    balances[msg.sender] = balances[msg.sender].sub(_amount);
    tokenTotal = tokenTotal.sub(_amount);
    token.safeTransfer(msg.sender, _amount);
  }
}