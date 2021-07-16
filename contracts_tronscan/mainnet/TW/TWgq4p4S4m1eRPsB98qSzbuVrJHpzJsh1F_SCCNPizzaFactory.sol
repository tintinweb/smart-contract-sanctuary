//SourceUnit: ISCCN.sol

pragma solidity ^0.5.10;

interface ISCCN {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
	
    function burn (uint256 _value) external returns (bool);
	
    function burnFrom (address _from, uint256 _value) external returns (bool);

}


//SourceUnit: PizzaFactory.sol

pragma solidity ^0.5.10;
import "./SafeMath.sol";
import "./ISCCN.sol";

contract SCCNPizzaFactory {

    using SafeMath for uint256;

    ISCCN constant tokenSCCN = ISCCN(0xBefFF58bD7943af49261F520D823AC3487bB60E2); // link SCCN TRC20
    
    address public owner;
    uint256 factoryCost;
    uint256 pizzasPerSCCN;
    uint256 public totalFactories;
    uint256 referrerPercentage;
    
    mapping(address => uint256) public factoryCount;
    mapping(address => uint256) lastSecond;
    mapping(address => uint256) owedTo;
    
    mapping(address => address) public referrer;
    mapping(address => uint256) public referralEarnings;
    
    event SetOwner(address indexed owner);
    event FactoryPurchase(address indexed user, uint256 value);
    event PizzaSell(address indexed user, uint256 value);
    event ReferralBind(address indexed user, address indexed referrer);
    
    constructor() public {
        factoryCost = 1000 * 100; // 1000 SCCN
        pizzasPerSCCN = 10; // 0.01 / 10 SCCN each
        totalFactories = 0;
        referrerPercentage = 1;
        owner = msg.sender;
        emit SetOwner(msg.sender);
    }
    
    function purchaseFactory(uint256 _value) public returns (bool success) {
        require(tokenSCCN.transferFrom(msg.sender, address(this), SafeMath.mul(_value, factoryCost))); // take (_value * SafeMath.div(factoryCost, 100)) SCCN from their wallet
        
        if(lastSecond[msg.sender] != 0) {
            owedTo[msg.sender] = pizzaBalance(msg.sender); // 1 per second
        }
        
        // Referrer gets 1%
        if(referrer[msg.sender] != address(0)) {
			tokenSCCN.transfer(referrer[msg.sender], SafeMath.div(SafeMath.mul(SafeMath.mul(_value, factoryCost), referrerPercentage), 100));
		}
        
        factoryCount[msg.sender] = SafeMath.add(factoryCount[msg.sender], _value);
        totalFactories = SafeMath.add(totalFactories, _value);
        lastSecond[msg.sender] = now;
        
        emit FactoryPurchase(msg.sender, _value);
        return true;
    }
    
    function sellPizzaAll() public returns (bool success) {
        require(factoryCount[msg.sender] > 0);
        uint256 oldBalance = pizzaBalance(msg.sender);
        require(tokenSCCN.transfer(msg.sender, SafeMath.div(pizzaBalance(msg.sender), pizzasPerSCCN)));
        
        lastSecond[msg.sender] = now;
        owedTo[msg.sender] = 0;
        
        emit PizzaSell(msg.sender, oldBalance);
        return true;
    }
    
    function pizzaBalance(address _user) public view returns (uint256 value) {
        return SafeMath.add(owedTo[_user], SafeMath.mul(factoryCount[_user], SafeMath.sub(now, lastSecond[_user])));
    }
    
    function setReferrer(address _user) public returns (bool success) {
        require(referrer[msg.sender] == address(0));
        require(msg.sender != _user);
        require(factoryCount[_user] >= 5);
        
        referrer[msg.sender] = _user;
        
        emit ReferralBind(msg.sender, _user);
        return true;
    }

}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.10;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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