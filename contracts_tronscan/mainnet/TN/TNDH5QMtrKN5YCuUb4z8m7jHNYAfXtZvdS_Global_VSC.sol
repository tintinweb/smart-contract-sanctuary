//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


//SourceUnit: globalcontract.sol

pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./token.sol";

contract Global_VSC {

    constructor(address tethertoken) public{
        token = TetherToken(tethertoken);
        deployTime = now;
        tokenAdd = tethertoken;
        mAd = msg.sender;
        sAd = msg.sender;
        veAm = 1000000; 
    }
     
    insurancesub public insurance;
    using SafeMath for uint256;
    
    TetherToken token;
    address public tokenAdd;
    address public mAd;
    address public sAd;
    address public lastContractAddress;
    address _contractaddress;
    address _phcontractaddress;
    address public insuranceAdd;

    uint256 public deployTime;
    uint256 public totalInsuranceSubContract;
    uint256 public totalPhSubContract;
    uint256 public veAm;

    Contracts[] public contractDatabase;
    
    PHcontracts[] public phcontractDatabase;
    
    GHamounts[] public ghamountDatabase;
    
    address[] public contracts;
    address[] public phcontracts;

    mapping (string => address) public orderIDdetail;
    mapping (address => uint256) public getInsPosition;
    mapping (address => uint256) public getPhPosition;
    mapping (address => uint256) public balances;
    mapping (string => uint256) public ghOrderID;
    
    struct Contracts {
        string orderid;
        address contractadd;
        uint256 totalamount;
        address registeredUserAdd;
    }
    
    struct PHcontracts {
        string phorderid;
        address phcontractadd;
        uint256 phtotalamount;
        address phregisteredUserAdd;
    }
    
    struct GHamounts {
        string ghorderid;
        uint256 ghtotalamount;
        address ghregisteredUserAdd;
    }
    
    event ContractGenerated (
        uint256 _ID,
        string indexed _orderid, 
        address _contractadd, 
        uint256 _totalamount,
        address _userAddress
    );
    
    event PhContractGenerated (
        uint256 _phID,
        string indexed _phorderid, 
        address _phcontractadd, 
        uint256 _phtotalamount,
        address registeredUserAdd
    );
    
    event GhGenerated (
        uint256 _ghID,
        string indexed _ghorderid, 
        uint256 _ghtotalamount,
        address _ghuserAddress
    );

    event InsuranceFundUpdate(
        address indexed user, 
        uint256 insuranceAmount
    );
    
    event FundsTransfered(
        string indexed AmountType, 
        uint256 Amount
    );
    
    modifier onSad() {
        require(msg.sender == sAd, "only sAd");
        _;
    }
    
    modifier onMan() {
        require(msg.sender == mAd || msg.sender == sAd, "only mAn");
        _;
    }
    
    function adMan(address _manAd) public onSad {
        mAd = _manAd;
    
    }
    
    function remMan() public onSad {
        mAd = sAd;
    }
    
    function addInsuranceContract(address _insuranceContractAdd) public onSad{
        insuranceAdd = _insuranceContractAdd;
    }

    function () external payable {
        balances[msg.sender] += msg.value;
    }
    
    function feeC() public view returns (uint256) {
        return address(this).balance;
    }
    
    function witE() public onMan{
        msg.sender.transfer(address(this).balance);
        emit FundsTransfered("TRX", address(this).balance);
    }
    
    function tokC() public view returns (uint256){
        return token.balanceOf(address(this));
    }

    function gethelp(address userAddress, uint256 tokens, string memory OrderID) public onMan {
        require(token.balanceOf(address(this)) >= tokens);
        token.transfer(userAddress, tokens);
        
        
        ghamountDatabase.push(GHamounts({
            ghorderid: OrderID,
            ghtotalamount : tokens,
            ghregisteredUserAdd : userAddress
        }));
        ghOrderID[OrderID] = ghamountDatabase.length - 1;
        emit FundsTransfered("Send GH", tokens);
    }
    

	function generateInsuranceOrder(uint256 amount, string memory OrderID, address userAddress)
		public onMan
		payable
		returns(address newContract) 
	{
	   
		insurancesub c = (new insurancesub).value(msg.value)(OrderID, tokenAdd, amount, mAd, insuranceAdd,userAddress);
		_contractaddress = address(c);
		orderIDdetail[OrderID] = _contractaddress;

		contractDatabase.push(Contracts({
            orderid: OrderID,
            contractadd: _contractaddress,
            totalamount : amount,
            registeredUserAdd : userAddress
        }));
        
        getInsPosition[_contractaddress] = contractDatabase.length - 1;
        totalInsuranceSubContract = contractDatabase.length;
		contracts.push(address(c));
		lastContractAddress = address(c);
		
        emit ContractGenerated (
            contractDatabase.length - 1, 
            OrderID,
            address(c),
            amount,
            userAddress
        );
		return address(c);
	}
	

	function generatePHorder(uint256 amount, string memory OrderID, address userAddress)
		public onMan
		payable
		returns(address newContract) 
	{
	   
		phsubcontract p = (new phsubcontract).value(msg.value)(OrderID, tokenAdd, amount, mAd, address(this) ,userAddress);
		_phcontractaddress = address(p);
		orderIDdetail[OrderID] = _phcontractaddress;

		phcontractDatabase.push(PHcontracts({
            phorderid: OrderID,
            phcontractadd: _phcontractaddress,
            phtotalamount : amount,
            phregisteredUserAdd : userAddress
        }));
        
        getPhPosition[_phcontractaddress] = phcontractDatabase.length - 1;
        totalPhSubContract = phcontractDatabase.length;
		phcontracts.push(address(p));
		lastContractAddress = address(p);
		
        emit PhContractGenerated (
            phcontractDatabase.length - 1, 
            OrderID,
            _phcontractaddress,
            amount,
            userAddress
        );
		return address(p);
	}
	
	function getInsContractCount()
		public
		view
		returns(uint InsContractCount)
	{
		return contracts.length;
	}
	
	function getPhContractCount()
		public
		view
		returns(uint phContractCount)
	{
		return phcontracts.length;
	}
	

	function upVerAm(uint256 _nAm) public onSad{
	    veAm = _nAm;
	}


    function verifyAccount(address userAdd) public view returns(bool){
        if (balances[userAdd] >= veAm){
            return true;
        }
        else{
            return false;
        }
    }
    
    function contractAddress() public view returns(address){
        return address(this);
    }
 
}



contract phsubcontract {


    constructor(string memory OrderID, address tokenAdd, uint256 amount, address mAd, address _mainAdd, address _userAddress) public payable{
      order = OrderID;
      deployTime = now;
      mainconractAdd = _mainAdd;
      contractAmount = amount;
      manAdd = mAd;
      tokenAddress = tokenAdd;
      userAdd = _userAddress;
      token = TetherToken(tokenAddress);
      Deployer = msg.sender;
    }
    
    address payable Deployer;
    string public order;
    address public manAdd;
    address public mainconractAdd;
    address public userAdd;
    uint256 public deployTime;
    address public tokenAddress;
    uint256 public contractAmount;
    uint256 public withdrawedToken;
    TetherToken token;
    
    mapping (address => uint256) public balances;
    mapping (address => uint256) public tokenBalance;

    modifier onMan() {
        require(msg.sender == manAdd, "onMan");
        _;
      }
   
    function () external payable {
        balances[msg.sender] += msg.value;
        
    }
    
    function feeC() public view returns (uint256) {
            return address(this).balance;
    }
    
    function witAl() public onMan {
        require(token.balanceOf(address(this)) >= contractAmount, 'greater b');
        withdrawedToken = token.balanceOf(address(this));
        token.transfer(mainconractAdd, token.balanceOf(address(this)));
    }
    

    function witE(uint256 amount) public onMan{
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
    }
    
    function checkAmount() public view returns(bool){
        if (token.balanceOf(address(this)) == contractAmount){
            return true;
        }
        else{
            return false;
        }
    }
    
    function checkUser(address _userAddress) public view returns(bool) {
        if(userAdd == _userAddress){
            return true;
        }
        else{
            return false;
        }
    }
    
    function tokC() public view returns (uint256){
       return token.balanceOf(address(this));
    }

   
     
}


contract insurancesub {


    constructor(string memory OrderID, address tokenAdd, uint256 amount, address mAd, address _insuranceAdd, address _userAddress) public payable{
      order = OrderID;
      deployTime = now;
      insuranceAdd = _insuranceAdd;
      contractAmount = amount;
      manAdd = mAd;
      tokenAddress = tokenAdd;
      userAdd = _userAddress;
      token = TetherToken(tokenAddress);
      Deployer = msg.sender;
    }
    
    address payable Deployer;
    string public order;
    address public manAdd;
    address public insuranceAdd;
    address public userAdd;
    uint256 public deployTime;
    address public tokenAddress;
    uint256 public contractAmount;
    uint256 public withdrawedToken;
    TetherToken token;
    
    mapping (address => uint256) public balances;
    mapping (address => uint256) public tokenBalance;

    modifier onMan() {
        require(msg.sender == manAdd, "onMan");
        _;
      }
   
    function () external payable {
        balances[msg.sender] += msg.value;
       
    }
    
    function feeC() public view returns (uint256) {
            return address(this).balance;
    }
    
    function witAl() public onMan {
        require(token.balanceOf(address(this)) >= contractAmount, 'GH');
        withdrawedToken = token.balanceOf(address(this));
        token.transfer(insuranceAdd, token.balanceOf(address(this)));
    }
    
    
    function witE(uint256 amount) public onMan{
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
    }
    
    function checkAmount() public view returns(bool){
        if (token.balanceOf(address(this)) == contractAmount){
            return true;
        }
        else{
            return false;
        }
    }
    
    function checkUser(address _userAddress) public view returns(bool) {
        if(userAdd == _userAddress){
            return true;
        }
        else{
            return false;
        }
    }
    
    function tokC() public view returns (uint256){
       return token.balanceOf(address(this));
    }
    
}

//SourceUnit: token.sol

/**
 *Submitted for verification at Etherscan.io on 2017-11-28
*/

pragma solidity ^0.5.10;
import "./SafeMath.sol";



contract Ownable {
    address public owner;


    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


contract ERC20Basic {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is Ownable, ERC20Basic {
    using SafeMath for uint;

    mapping(address => uint) public balances;

    uint public basisPointsRate = 0;
    uint public maximumFee = 0;


    modifier onlyPayloadSize(uint size) {
        require(!(msg.data.length < size + 4));
        _;
    }


    function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        uint sendAmount = _value.sub(fee);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(msg.sender, owner, fee);
        }
        emit Transfer(msg.sender, _to, sendAmount);
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

}


contract StandardToken is BasicToken, ERC20 {

    mapping (address => mapping (address => uint)) public allowed;

    uint public constant MAX_UINT = 2**256 - 1;


    function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
        uint256 _allowance = allowed[_from][msg.sender];


        uint fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
        if (_allowance < MAX_UINT) {
            allowed[_from][msg.sender] = _allowance.sub(_value);
        }
        uint sendAmount = _value.sub(fee);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(sendAmount);
        if (fee > 0) {
            balances[owner] = balances[owner].add(fee);
            emit Transfer(_from, owner, fee);
        }
        emit Transfer(_from, _to, sendAmount);
    }


    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {

        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }


    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;



  modifier whenNotPaused() {
    require(!paused);
    _;
  }


  modifier whenPaused() {
    require(paused);
    _;
  }


  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }


  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract BlackList is Ownable, BasicToken {

    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}

contract UpgradedStandardToken is StandardToken{

    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
}

contract TetherToken is Pausable, StandardToken, BlackList {

    string public name;
    string public symbol;
    uint public decimals;
    address public upgradedAddress;
    bool public deprecated;


    constructor (uint _initialSupply, string memory _name, string memory _symbol, uint _decimals) public {
        _totalSupply = _initialSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        balances[owner] = _initialSupply;
        deprecated = false;
    }

    function transfer(address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint _value) public whenNotPaused {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

    function balanceOf(address who) public view returns (uint) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

    function approve(address _spender, uint _value) public onlyPayloadSize(2 * 32) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        if (deprecated) {
            return StandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    function deprecate(address _upgradedAddress) public onlyOwner {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    function totalSupply() public view returns (uint) {
        if (deprecated) {
            return StandardToken(upgradedAddress).totalSupply();
        } else {
            return _totalSupply;
        }
    }

    function issue(uint amount) public onlyOwner {
        require(_totalSupply + amount > _totalSupply);
        require(balances[owner] + amount > balances[owner]);

        balances[owner] += amount;
        _totalSupply += amount;
        emit Issue(amount);
    }


    function redeem(uint amount) public onlyOwner {
        require(_totalSupply >= amount);
        require(balances[owner] >= amount);

        _totalSupply -= amount;
        balances[owner] -= amount;
        emit Redeem(amount);
    }

    function setParams(uint newBasisPoints, uint newMaxFee) public onlyOwner {
        require(newBasisPoints < 20);
        require(newMaxFee < 50);

        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(10**decimals);

        emit Params(basisPointsRate, maximumFee);
    }

    event Issue(uint amount);

    event Redeem(uint amount);

    event Deprecate(address newAddress);

    event Params(uint feeBasisPoints, uint maxFee);
}