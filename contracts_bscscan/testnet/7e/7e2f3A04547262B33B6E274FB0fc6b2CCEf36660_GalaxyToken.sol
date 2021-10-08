/**
 *Submitted for verification at BscScan.com on 2021-10-08
*/

pragma solidity 0.5.16;



//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}



//*******************************************************************//
//--------------------- ApproveAndCallFallBack ----------------------//
//*******************************************************************//
interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}



//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//
contract owned {
    address  payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



//****************************************************************************//
//---------------------        MAIN CODE STARTS HERE     ---------------------//
//****************************************************************************//
contract GalaxyToken is owned {



  /*===============================
  =         DATA STORAGE          =
  ===============================*/    

  using SafeMath for uint256;
  bool public safeGuard=false;

  string public constant name  = "Galaxy Token";
  string public constant symbol = "GLXY";
  uint8 public constant decimals = 18;
  
  uint256 public _totalSupply;
  uint256 public tokenPrice;
  uint256 public soldTokens;
  uint256 public preMintedToken;
  
  mapping(address=>uint256) public Pool;
  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event TransferPoolamount(address _from, address _to, uint256 _ether);
  event Approval(address _from, address _spender, uint256 _tokenAmt);
  
  
  
  
  /**
   * Contract creator should provide total supply (without decimals) and token price, while deploying the smart contract. 
   */
  constructor(uint256 _supply,uint256 _price,uint256 _premint) public {
     _totalSupply= _supply * (10 ** 18);
     tokenPrice=_price;
     soldTokens=_premint* (10 ** 18);
    balances[msg.sender] = _premint* (10 ** 18);
    emit Transfer(address(0), msg.sender, _premint* (10 ** 18));
  }
  
  
  /**
   * Users get tokens immediately according to ether contributed.
   */
  function buyToken() payable public returns(bool)
  {
      require(msg.value!=0,"Invalid Amount");
      
      uint256 one=10**18/tokenPrice;
      
      uint256 tknAmount=one*msg.value;
      
      require(soldTokens.add(tknAmount)<=_totalSupply,"Token Not Available");
      
      balances[msg.sender]+=tknAmount;
      //_totalSupply-=tknAmount;
      Pool[owner]+=msg.value;
      soldTokens+=tknAmount;
      
      emit Transfer(address(this),msg.sender,tknAmount);
  }
  
  
  /**
   * owner can withdraw the fund anytime.
   */
  function withDraw() public onlyOwner{
      
      require(Pool[owner]!=0,"No Ether Available");
      owner.transfer(Pool[owner]);
      
      emit TransferPoolamount(address(this),owner,Pool[owner]);
      Pool[owner]=0;
  }
  
  
  /**
   *Owner can chaneg teh token price anytime.
   */
  
  function changeTokenPrice(uint256 _price) public onlyOwner{
      require(_price!=0);
      tokenPrice=_price;
  }
  

  /**
   * when safeGuard is true, then only token transfer will start. 
   * once token transfer will be started, then it will not even reverted by owner.
   */
  function transfer(address to, uint256 value) public returns (bool) {
    require(safeGuard==true,'Transfer Is Not Available');
    require(value <= balances[msg.sender]);
    require(to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);

    emit Transfer(msg.sender, to, value);
    return true;
  }
  
  
  /**
   * when safeGuard is true, then only token transfer will start. 
   * once token transfer will be started, then it will not even reverted by owner.
   */
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(safeGuard==true,'Transfer Is Not Available');
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(to != address(0));
    
    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
    
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
    
    emit Transfer(from, to, value);
    return true;
  }


  /**
   * user can transfer tokens in bulk. 
   * maximum 150 at a time.
   */
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    uint256 arrayLength = receivers.length;
    require(arrayLength <= 150, 'Too many addresses');
    for (uint256 i = 0; i < arrayLength; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }
  
  
  /**
   * approve token spending to any third party.
   * approved user or contract can spend toknes.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  
  /**
   * This function allows user to approve and at the same time call any other smart contract function and do any code execution.
   */
  function approveAndCall(address spender, uint256 tokens, bytes calldata data) external returns (bool) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
    }

  
  /**
   * Increase allowance.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }
  
  
  
  /**
   * decrease allowance.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }

  
  /**
   * anyone can burn the tokens. and it will decrease the total supply of the tokens.
   */
  function burn(uint256 amount) external {
    require(amount != 0);
    require(amount <= balances[msg.sender]);
    _totalSupply = _totalSupply.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
  }
  
  
  
  /**
   * only owner can change thi safeGuard status to true. 
   * It will start the token transfer. and once it is started, it can not be stoped.
   */
  function changeSafeGuard() public onlyOwner{
      if(safeGuard==false){
          safeGuard=true;
      }
          else{
              safeGuard=false;
          }
      }
  
  
  
  
  /*===============================
    =       VIEW FUNCTIONS        =
    ===============================*/
  function tokenSold() public view returns(uint256)
  {
      return soldTokens;
  }
  
  function totalEther() public view returns(uint256)
  {
      return Pool[owner];
  }
  
  function availableToken() public view returns(uint256)
  {
      return _totalSupply.sub(soldTokens);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address player) public view returns (uint256) {
    return balances[player];
  }
  
  function allowance(address player, address spender) public view returns (uint256) {
    return allowed[player][spender];
  }

}