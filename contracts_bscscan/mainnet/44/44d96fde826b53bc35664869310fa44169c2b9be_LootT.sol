/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-19
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

pragma solidity ^0.4.25;

/**
 * @title Multi Sender, support ETH and ERC20 Tokens
 * @dev To Use this Dapp: http://multisender.phizhub.com
*/


library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}

/**
 * @title Multi Sender, support ETH and ERC20 Tokens
 * @dev To Use this Dapp: http://multisender.phizhub.com
*/

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
    

}

/**
 * @title Multi Sender, support ETH and ERC20 Tokens
 * @dev To Use this Dapp: http://multisender.phizhub.com
*/

contract BasicToken is ERC20Basic {

  using SafeMath for uint;

  mapping(address => uint) balances;

  function transfer(address _to, uint _value) public{
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
}

/**
 * @title Multi Sender, support ETH and ERC20 Tokens
 * @dev To Use this Dapp: http://multisender.phizhub.com
*/

contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) public {
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public{
    require((_value == 0) || (allowed[msg.sender][_spender] == 0)) ;
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * @title Multi Sender, support ETH and ERC20 Tokens
 * @dev To Use this Dapp: http://multisender.phizhub.com
*/

contract Ownable {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

/**
 * @title Multi Sender, support ETH and ERC20 Tokens
 * @dev To Use this Dapp: http://multisender.phizhub.com
*/

contract LootT is Ownable{

    using SafeMath for uint;


    event LogTokenMultiSent(address token,uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);
    address public receiverAddress;
    uint public txFee = 0.005 ether;

    uint public VIPFee = 0.005 ether;

    /* VIP List */
    mapping(address => uint) public vipList;
    //byvata=>invata
    mapping(address => address) public vipFrind;
      //三级代理
    mapping(address => uint) public ThreeFrind;
    
    
    constructor() public{
        vipList[0xf5C0D9A2A65dBC7160e2B259b3552978d0052d9b] = 1; 
    }

    /*
  *  get balance
  */
  function getBalance(address _tokenAddress) onlyOwner public {
      address _receiverAddress = getReceiverAddress();
      if(_tokenAddress == address(0)){
          require(_receiverAddress.send(address(this).balance));
          return;
      }
      StandardToken token = StandardToken(_tokenAddress);
      uint256 balance = token.balanceOf(this);
      token.transfer(_receiverAddress, balance);
      emit LogGetToken(_tokenAddress,_receiverAddress,balance);
  }


   /*
  *  Register VIP
  */
  function registerVIP(address _invitation)  public {
      require(_invitation != msg.sender);
      require(vipList[msg.sender]==0,"resistered");
      require(vipList[_invitation]>0,"invitationr no resistered");
      //设置邀请者
      vipFrind[msg.sender]=_invitation;
      //设置VIP 
      vipList[msg.sender] = 1;
  }
 

  /*
  *  VIP list
  */
  function addToVIPList(address[] _vipList) onlyOwner public {
    for (uint i =0;i<_vipList.length;i++){
      vipList[_vipList[i]] =  vipList[_vipList[i]]+1;
    }
  }

  /*
    * Remove address from VIP List by Owner
  */
  function removeFromVIPList(address[] _vipList) onlyOwner public {
    for (uint i =0;i<_vipList.length;i++){
      vipList[_vipList[i]] = 0;
    }
   }

    /*
        * Check isVIP
    */
    function isVIP(address _addr) public view returns (bool) {
        return _addr == owner || vipList[_addr]>0;
    }


     function vipLevel(address _addr) public view returns (uint) {
        return  vipList[_addr]  ;
    }

    /*
        * set receiver address
    */
    function setReceiverAddress(address _addr) onlyOwner public {
        require(_addr != address(0));
        receiverAddress = _addr;
    }


    /*
        * get receiver address
    */
    function getReceiverAddress() public view returns  (address){
        if(receiverAddress == address(0)){
            return owner;
        }

        return receiverAddress;
    }

     /*
        * set vip fee
    */
    function setVIPFee(uint _fee) onlyOwner public {
        VIPFee = _fee;
    }

    /*
        * set tx fee
    */
    function setTxFee(uint _fee) onlyOwner public {
        txFee = _fee;
    }



 ERC20 public gERC20=ERC20(0xA9ECF878d73265b9773CD298eC3aFe40C9D13fE8);
   //配置ERC20地址
  function setERC20(address _addr) onlyOwner public {
        gERC20 = ERC20(_addr);
    }

   address public gTrasfer=0xb5A78f79384612510EcE6822d67575e6b937B29c;
   //配置交易合约地址
  function setGTrasfer(address _addr) onlyOwner public {
        gTrasfer = _addr;
    }
//分红总量
     uint amount =3500000000*1000000000000000000;

  function setAmount(uint _amount) onlyOwner public {
        amount = _amount;
    }

//计算收益  根据mint人获得邀请人的收益
  function setTradsFer(address _addr)  internal {
      
       //获取邀请人收益 
       address invitation = vipFrind[_addr];
       if(invitation!=0){
             ThreeFrind[invitation] =ThreeFrind[invitation]+amount*6/7;
       }
       
       //被邀请人的上级
       address invitationUP = vipFrind[invitation];
       if(invitation!=0){
           ThreeFrind[invitationUP] =ThreeFrind[invitationUP]+amount/7;
       }
       
    }
 
    /*
        * Check profit 查看收益
    */
    function profit(address _addr) public view returns (uint) {
           return   ThreeFrind[_addr]; 
    }

      /*
        * 收割收益
    */
    function withProfit() public {
             require(ThreeFrind[msg.sender]>0);
            gERC20.transferFrom(address(this),msg.sender,ThreeFrind[msg.sender]);
            ThreeFrind[msg.sender] =0;
    }


    function approveToken() onlyOwner public {
             
            gERC20.approve(address(this),1000000000000000000000000000000000000);
    }


    //调度方法
     function transferFrom(address sender, address recipient, uint256 amountNi) public   returns (bool) {
         require(msg.sender == gTrasfer,"power off");
          
         setTradsFer(sender) ;
         gERC20.transferFrom(sender,address(this),amountNi);
         return true;
    }

}