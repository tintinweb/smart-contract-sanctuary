//SourceUnit: agri2change.sol

pragma solidity 0.5.4;
contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() 
  {
	  require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");
	  bool wasInitializing = initializing;
	  initializing = true;
	  initialized = true;
		_;
	  initializing = wasInitializing;
  }
  function isConstructor() private view returns (bool) 
  {
  uint256 cs;
  assembly { cs := extcodesize(address) }
  return cs == 0;
  }
  uint256[50] private __gap;

}

contract Ownable is Initializable {
  address public _owner;
  uint256 private _ownershipLocked;
  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
  address indexed previousOwner,
  address indexed newOwner
	);
  function initialize(address sender) internal initializer {
   _owner = sender;
   _ownershipLocked = 0;

  }
  function ownerr() public view returns(address) {
   return _owner;

  }

  modifier onlyOwner() {
    require(isOwner());
    _;

  }

  function isOwner() public view returns(bool) {
  return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
   _transferOwnership(newOwner);

  }
  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;

  }

  // Set _ownershipLocked flag to lock contract owner forever

  function lockOwnership() public onlyOwner {
    require(_ownershipLocked == 0);
    emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private __gap;

}

interface ITRC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
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
   
contract AGRITECH_MLM is Ownable {
     using SafeMath for uint256;
   
    address public owner;
    event Registration(string  member_name, string  sponcer_id,address indexed sender);
	event LevelPaymentEvent(string  member_name,uint256 current_level);
	event MatrixPaymentEvent(string  member_name,uint256 matrix);
  event ROIIncome(address indexed  userWallet,uint256 roiIncome,string member_user_id);
  
	
   ITRC20 private AGRITECH; 
   ITRC20 private IIOT; 
   event onBuy(address buyer , uint256 amount);

    constructor(address ownerAddress,ITRC20 _AGRITECH,ITRC20 _IIoT) public 
    {
                 
        owner = ownerAddress;
        
        AGRITECH = _AGRITECH;

        IIOT = _IIoT;
        
        Ownable.initialize(msg.sender);
    }
    
 
    function withdrawLostTRXFromBalance() public 
    {
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(address(this).balance);
    }
    
    function NewRegistration(uint package,string memory member_name, string memory sponcer_id,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
	{
    require(package==500,"Invalid Package Amount");
	  uint256 tokenQty=0;
      uint256 tokenQtyAg=0;
	    if(package==500)
	    {
	        tokenQty=2500;
            tokenQtyAg=250;
	    }
	  
	  AGRITECH.transfer(msg.sender , (tokenQtyAg*100000000));
    IIOT.transfer(msg.sender , (tokenQty*100000000));
		multisendTRX(_contributors,_balances);
		emit Registration(member_name, sponcer_id,msg.sender);
	}

   function stakeagri(address sponsor,uint package,uint refcom) public payable
   {
   require(package>=2500,"Invalid Stake Amount");
   uint256 agriStake=(package*100000000);
   //uint256 amt=package.mul(50);
   uint256 agricom=refcom;
   require(AGRITECH.balanceOf(msg.sender)>=agriStake,"Insufficient Balance");
   require(AGRITECH.allowance(msg.sender,address(this))>=agriStake,"Approve Your Token First");
   AGRITECH.transferFrom(msg.sender, address(this), agriStake);
   AGRITECH.transfer(sponsor,agricom);
   }

   function stakeiiot(address sponsor,uint package,uint refcom) public payable
   {
   require(package>=25000,"Invalid Stake Amount");
   uint256 iiotStake=(package*100000000);
   //uint256 amt=package.mul(100);
   uint256 iiotcom=refcom;
   require(IIOT.balanceOf(msg.sender)>=iiotStake,"Insufficient Balance");
   require(IIOT.allowance(msg.sender,address(this))>=iiotStake,"Approve Your Token First");
   IIOT.transferFrom(msg.sender, address(this), iiotStake);
   IIOT.transfer(sponsor ,iiotcom);
   }

  function LevelPayment(string memory member_name,uint Level,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
	{
		multisendTRX(_contributors,_balances);
		emit LevelPaymentEvent(member_name, Level);
	}
	function MatrixPayment(string memory member_name,uint matrix,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
	{
		multisendTRX(_contributors,_balances);
		emit MatrixPaymentEvent(member_name, matrix);
	}
  function TokenFromBalanceIOT() public 
	{
        require(msg.sender == owner, "onlyOwner");
        IIOT.transfer(owner,address(this).balance);
 	}
function TokenFromBalanceAGRI() public 
	{
        require(msg.sender == owner, "onlyOwner");
        AGRITECH.transfer(owner,address(this).balance);
 	}

function ROIWithdrawIOT(address payable userWallet,uint256 roiIncome,string memory member_user_id) public 
	{
        require(msg.sender == owner, "onlyOwner");
        IIOT.transfer(userWallet,roiIncome);
        emit ROIIncome(userWallet,roiIncome,member_user_id);
	}
  function ROIWithdrawAGRI(address payable userWallet,uint256 roiIncome,string memory member_user_id) public 
	{
        require(msg.sender == owner, "onlyOwner");
        AGRITECH.transfer(userWallet,roiIncome);
        emit ROIIncome(userWallet,roiIncome,member_user_id);
	}
	function walletLossTrx(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(address(this).balance);
    }

    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
    
    }

      function multisendTokenIOT(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        require(msg.sender == owner, "onlyOwner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
          
            IIOT.transfer(_contributors[i],_balances[i]);
        }
}
        function multisendTokenAGRI(address payable[]  memory  _contributors, uint256[] memory _balances) public payable
          {
              require(msg.sender == owner, "onlyOwner");
             uint256 i = 0;
              for (i; i < _contributors.length; i++) {
                
                  AGRITECH.transfer(_contributors[i],_balances[i]);
              }
        
          }
        }