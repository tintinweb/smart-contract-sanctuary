/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

/**
 *Submitted for verification at Etherscan.io on 2020-12-14
*/

pragma solidity ^ 0.4.19;


contract Ownable {

    address public owner;

    function Ownable() public {

        owner = msg.sender;

    }

    function _msgSender() internal view returns (address)

    {

        return msg.sender;

    }

    modifier onlyOwner {

        require(msg.sender == owner);

        _;
    }

}

contract SafeMath {

  function safeMul(uint256 a, uint256 b) internal returns (uint256) {

    uint256 c = a * b;

    assert(a == 0 || c / a == b);

    return c;

  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {

    assert(b > 0);

    uint256 c = a / b;

    assert(a == b * c + a % b);

    return c;

  }


  function safeSub(uint256 a, uint256 b) internal returns (uint256) {

    assert(b <= a);

    return a - b;

  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {

    uint256 c = a + b;

    assert(c>=a && c>=b);

    return c;

  }

  function assert(bool assertion) internal {

    if (!assertion) {

      throw;

    }

  }

}

contract TDC is Ownable, SafeMath {

    /* Public variables of the token */

    string public name = 'TDCACH';

    string public symbol = 'TDC';

    uint8 public decimals = 9;

    uint256 public totalSupply =(2949642995000  * (10 ** uint256(decimals)));

    uint public TotalHoldersAmount;

    /*Lock transfer from all accounts */

    bool private Lock = false;

    bool public CanChange = true;

    address public admin;

    address public AddressForReturn;

    address[] Accounts;

    /* This creates an array with all balances */

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

   /*Individual Lock*/

    mapping(address => bool) public AccountIsLock;

    /*Allow transfer for ICO, Admin accounts if IsLock==true*/

    mapping(address => bool) public AccountIsNotLock;

   /*Allow transfer tokens only to ReturnWallet*/

    mapping(address => bool) public AccountIsNotLockForReturn;

    mapping(address => uint) public AccountIsLockByDate;

    mapping (address => bool) public isHolder;

    mapping (address => bool) public isArrAccountIsLock;

    mapping (address => bool) public isArrAccountIsNotLock;

    mapping (address => bool) public isArrAccountIsNotLockForReturn;

    mapping (address => bool) public isArrAccountIsLockByDate;

    address [] public Arrholders;

    address [] public ArrAccountIsLock;

    address [] public ArrAccountIsNotLock;

    address [] public ArrAccountIsNotLockForReturn;

    address [] public ArrAccountIsLockByDate;


    /* This generates a public event on the blockchain that will notify clients */

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    event StartBurn(address indexed from, uint256 value);

    event StartAllLock(address indexed account);

    event StartAllUnLock(address indexed account);

    event StartUseLock(address indexed account,bool re);
    
    event StartUseUnLock(address indexed account,bool re);

    event StartAdmin(address indexed account);

    event ReturnAdmin(address indexed account);

    event PauseAdmin(address indexed account);

    modifier IsNotLock{

      require(((!Lock&&AccountIsLock[msg.sender]!=true)||((Lock)&&AccountIsNotLock[msg.sender]==true))&&now>AccountIsLockByDate[msg.sender]);

      _;

     }

     modifier isCanChange{

         if(CanChange == true)

         {

             require((msg.sender==owner||msg.sender==admin));

         }

         else if(CanChange == false)

         {

             require(msg.sender==owner);

         }

      _;

     }

     modifier whenNotPaused(){

         require(!Lock);

         _;

     }

    /* Initializes contract with initial supply tokens to the creator of the contract */

  function TDC() public {

        balanceOf[msg.sender] = totalSupply;

        Arrholders[Arrholders.length++]=msg.sender;

        admin=msg.sender;

    }

     function AddAdmin(address _address) public onlyOwner{

        require(CanChange);

        admin=_address;

        StartAdmin(admin);

    }

    modifier whenNotLock(){

        require(!Lock);

        _;

    }

    modifier whenLock() {

        require(Lock);

        _;

    }

    function AllLock()public isCanChange whenNotLock{

        Lock = true;

        StartAllLock(_msgSender()); 

    }
    
    function AllUnLock()public onlyOwner whenLock{

        Lock = false;

        StartAllUnLock(_msgSender()); 

    }

    function UnStopAdmin()public onlyOwner{

        CanChange = true;

        ReturnAdmin(_msgSender());

    }

    function StopAdmin() public onlyOwner{

        CanChange = false;

        PauseAdmin(_msgSender());

    }

    function UseLock(address _address)public onlyOwner{

    bool _IsLock = true;

     AccountIsLock[_address]=_IsLock;

     if (isArrAccountIsLock[_address] != true) {

        ArrAccountIsLock[ArrAccountIsLock.length++] = _address;

        isArrAccountIsLock[_address] = true;

    }if(_IsLock == true){

    StartUseLock(_address,_IsLock);

        }

    }

    function UseUnLock(address _address)public onlyOwner{

        bool _IsLock = false;

     AccountIsLock[_address]=_IsLock;

     if (isArrAccountIsLock[_address] != true) {

        ArrAccountIsLock[ArrAccountIsLock.length++] = _address;

        isArrAccountIsLock[_address] = true;

    }

    if(_IsLock == false){

    StartUseUnLock(_address,_IsLock);

        }

    }


    /* Send coins */

    function transfer(address _to, uint256 _value) public  {

        require(((!Lock&&AccountIsLock[msg.sender]!=true)||((Lock)&&AccountIsNotLock[msg.sender]==true)||(AccountIsNotLockForReturn[msg.sender]==true&&_to==AddressForReturn))&&now>AccountIsLockByDate[msg.sender]);

        require(_to != 0x0);

        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough

        require (balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows

        balanceOf[msg.sender] -= _value; // Subtract from the sender

        balanceOf[_to] += _value; // Add the same to the recipient

        Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place

        if (isHolder[_to] != true) {

        Arrholders[Arrholders.length++] = _to;

        isHolder[_to] = true;

    }}


    /* A contract attempts to get the coins */

    function transferFrom(address _from, address _to, uint256 _value)public IsNotLock returns(bool success)  {

        require(((!Lock&&AccountIsLock[_from]!=true)||((Lock)&&AccountIsNotLock[_from]==true))&&now>AccountIsLockByDate[_from]);

        require (balanceOf[_from] >= _value) ; // Check if the sender has enough

        require (balanceOf[_to] + _value >= balanceOf[_to]) ; // Check for overflows

        require (_value <= allowance[_from][msg.sender]) ; // Check allowance

        balanceOf[_from] -= _value; // Subtract from the sender

        balanceOf[_to] += _value; // Add the same to the recipient

        allowance[_from][msg.sender] -= _value;

        Transfer(_from, _to, _value);

        if (isHolder[_to] != true) {

        Arrholders[Arrholders.length++] = _to;

        isHolder[_to] = true;

        }

        return true;

    }

 /* @param _value the amount of money to burn*/

    function Burn(uint256 _value)public onlyOwner returns (bool success) {

        require(msg.sender != address(0));

        if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough

		if (_value <= 0) throw; 

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender

        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply

        Transfer(msg.sender,address(0),_value);

        StartBurn(msg.sender, _value);

        return true;

    }

    function GetHoldersCount () public view returns (uint _HoldersCount){

         return (Arrholders.length-1);

    }

    function GetAccountIsLockCount () public view returns (uint _Count){

         return (ArrAccountIsLock.length);

    }

    function GetAccountIsNotLockForReturnCount () public view returns (uint _Count){

         return (ArrAccountIsNotLockForReturn.length);

    }

    function GetAccountIsNotLockCount () public view returns (uint _Count){

         return (ArrAccountIsNotLock.length);

    }

     function GetAccountIsLockByDateCount () public view returns (uint _Count){

         return (ArrAccountIsLockByDate.length);

    }

   function () public payable {

         revert();

    }


}