// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../node_modules/@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
   

    function init() public{
        _setOwner(_msgSender());
    } 

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BattleHero is IERC20, Ownable, Initializable {
    
    string public name;
    string public symbol;
    uint8 public constant decimals       = 18;
    uint256 public constant TOKEN_ESCALE = 1 * 10 ** uint256(decimals);
    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;


    
    // address teamAccount         = 0x979EBc09e55EA0ab563CF7175e4c4b1a03AFc19a;
    // address marketingAccount    = 0x979EBc09e55EA0ab563CF7175e4c4b1a03AFc19a;
    // address developmentAccount  = 0x979EBc09e55EA0ab563CF7175e4c4b1a03AFc19a;


    uint256 _maxCrowdsaleSupply;
    uint256 _actualCrowdsaleCap;

    uint public VALUE_OF_RPG;
    uint public halvingPeriod;


    mapping(string => uint) prices;
    mapping(address => bool) privateInvestors;    




    using SafeMath for uint256;

    constructor() {  
        init();     
        name = "Battle Hero";
        symbol = "BATH";
        prices["private"]   = 50000000000 wei;
        prices["gleam"]     = 100000000000 wei;
        prices["public"]    = 250000000000 wei;
        totalSupply_        = 1000000000 * TOKEN_ESCALE;
        VALUE_OF_RPG        = 50000000000000 wei;
        halvingPeriod       = 7776000;
        _actualCrowdsaleCap = 0;
        balances[msg.sender]   = totalSupply_;
    }

    function initialize(uint256 value) public initializer {
        init();     
        prices["private"]   = 50000000000 wei;
        prices["gleam"]     = 100000000000 wei;
        prices["public"]    = 250000000000 wei;
        totalSupply_        = 1000000000 * TOKEN_ESCALE;
        VALUE_OF_RPG        = 50000000000000 wei;
        halvingPeriod       = 7776000;
        _actualCrowdsaleCap = 0;        
        balances[owner()] = totalSupply_;    
    }

 //Safe math
    function safeSub(uint a , uint b) internal pure returns (uint){assert(b <= a);return a - b;}  
    function safeAdd(uint a , uint b) internal pure returns (uint){uint c = a + b;assert(c>=a && c>=b);return c;}
    
    function changeRPGPrice(uint value) public onlyOwner{
        VALUE_OF_RPG = value;
    }

    function addPrivateInvestor(address investor) public onlyOwner{        
        privateInvestors[investor] = true;
    }

    modifier isPrivateInvestor() {
        require(privateInvestors[msg.sender] == true);
        _;
    }
    function burn(uint256 _value) public{
		_burn(msg.sender, _value);
	}

    function privateBuy() external payable isPrivateInvestor{
        uint256 bscAmount = msg.value;
    }
    function _burn(address _who, uint256 _value) internal {
		require(_value <= balances[_who]);
		balances[_who] = balances[_who].sub(_value);
		totalSupply_ = totalSupply_.sub(_value);
		emit Transfer(_who, address(0), _value);    
	}
    receive () external payable{
        address beneficiary  = msg.sender;
        uint256 bscAmount    = msg.value;
        uint amountTokens    = calculateTokens(bscAmount);
        _actualCrowdsaleCap  = _actualCrowdsaleCap + amountTokens;        
        _transfer(owner(), beneficiary, amountTokens);
    }
    function tokensSelled() public view returns(uint256){
        return _actualCrowdsaleCap;
    }
    function calculateTokens(uint256 value) public view returns(uint256){
        uint256 tokensToSend = (value * 10 ** uint256(decimals)) / VALUE_OF_RPG;
        return tokensToSend;
    }
    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }
    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        _transfer(msg.sender, receiver, numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    function _transfer(address _from , address _to , uint _value) internal{        
        //Prevent send tokens to 0x0 address        
        require(balances[_from] >= _value);                                           //Check if the sender have enough tokens        
        require(balances[_to] + _value > balances[_to]);                              //Check for overflows        
        balances[_from]         = balances[_from].sub(_value);                        //Subtract from the source ( sender )        
        balances[_to]           = balances[_to].add(_value);                          //Add tokens to destination        
        uint previousBalance    = balances[_from] + balances[_to];                    //To make assert        
        emit Transfer(_from , _to , _value);                                          //Fire event for clients        
        assert(balances[_from] + balances[_to] == previousBalance);                   //Check the assert
    }
    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address from, address delegate) public override view returns (uint) {
        return allowed[from][delegate];
    }

    function transferFrom(address from, address buyer, uint256 numTokens) public override returns (bool) {        
        require(numTokens <= allowed[owner()][msg.sender]);
        balances[from] = balances[from].sub(numTokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(from, buyer, numTokens);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

