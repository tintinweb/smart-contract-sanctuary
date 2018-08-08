pragma solidity 0.4.24;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
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

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
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

contract DinoToken is StandardToken, Pausable {
    string public constant name = "DINO Token";
    string public constant symbol = "DINO";
    uint8  public constant decimals = 18;

    address public  tokenSaleContract;

    modifier validDestination(address to) {
        require(to != address(this));
        _;
    }

    function DinoToken(uint _tokenTotalAmount) public {
        totalSupply = _tokenTotalAmount * (10 ** uint256(decimals));

        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

        tokenSaleContract = msg.sender;
    }

    function transfer(address _to, uint _value)
        public
        validDestination(_to)
        whenNotPaused
        returns (bool) 
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value)
        public
        validDestination(_to)
        whenNotPaused
        returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }
}

contract DinoTokenSale is Ownable {
    using SafeMath for uint256;

	// token allocation
    uint public constant TOTAL_DINOTOKEN_SUPPLY  = 200000000;
    uint public constant ALLOC_FOUNDATION       = 40000000e18; // 20%
    uint public constant ALLOC_TEAM             = 30000000e18; // 15%
    uint public constant ALLOC_MARKETING        = 30000000e18; // 15%
    uint public constant ALLOC_ADVISOR          = 10000000e18; // 5%
    uint public constant ALLOC_SALE             = 90000000e18; // 45%

    // sale stage
    uint public constant STAGE1_TIME_END  = 9 days; 
    uint public constant STAGE2_TIME_END  = 20 days; 
    uint public constant STAGE3_TIME_END  = 35 days; 

    // Token sale rate from ETH to DINO
    uint public constant RATE_PRESALE      = 4000; // +25%
    uint public constant RATE_CROWDSALE_S1 = 3680; // +15%
    uint public constant RATE_CROWDSALE_S2 = 3424; // +7%
    uint public constant RATE_CROWDSALE_S3 = 3200; // +0%

	// For token transfer
    address public constant WALLET_FOUNDATION = 0x9bd5ae7400ce11b418a4ef9e9310fbd0c2f5e503; 
    address public constant WALLET_TEAM       = 0x9bb148948a75a5b205b4d13efb9fe893c8c8fb7b; 
    address public constant WALLET_MARKETING  = 0x83e5e7f8f90c90a0b8948dc2c1116f8c0dcf10d8; 
    address public constant WALLET_ADVISOR    = 0x5c166aa48503fbec223fa06d2757af01850d60f7; 

    // For ether transfer
    address private constant WALLET_ETH_DINO  = 0x191B29ADbCA5Ecb285005Cff15441F8411DF5f72; 
    address private constant WALLET_ETH_ADMIN = 0xAba33f3a098f7f0AC9B60614e395A40406e97915; 

    DinoToken public dinoToken; 

    uint256 public presaleStartTime = 1528416000; // 2018-6-8 8:00 (UTC+8) 1528416000
    uint256 public startTime        = 1528848000; // 2018-6-13 8:00 (UTC+8) 1528848000
    uint256 public endTime          = 1531872000; // 2018-7-18 8:00 (UTC+8) 1531872000
    bool public halted;

    mapping(address=>bool) public whitelisted_Presale;

    // stats
    uint256 public totalDinoSold;
    uint256 public weiRaised;
    mapping(address => uint256) public weiContributions;

    // EVENTS
    event updatedPresaleWhitelist(address target, bool isWhitelisted);
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

    function DinoTokenSale() public {
        dinoToken = new DinoToken(TOTAL_DINOTOKEN_SUPPLY);
        dinoToken.transfer(WALLET_FOUNDATION, ALLOC_FOUNDATION);
        dinoToken.transfer(WALLET_TEAM, ALLOC_TEAM);
        dinoToken.transfer(WALLET_MARKETING, ALLOC_MARKETING);
        dinoToken.transfer(WALLET_ADVISOR, ALLOC_ADVISOR);

        dinoToken.transferOwnership(owner);
    }

    function updatePresaleWhitelist(address[] _targets, bool _isWhitelisted)
        public
        onlyOwner
    {
        for (uint i = 0; i < _targets.length; i++) {
            whitelisted_Presale[_targets[i]] = _isWhitelisted;
            emit updatedPresaleWhitelist(_targets[i], _isWhitelisted);
        }
    }

    function validPurchase() 
        internal 
        returns(bool) 
    {
        bool withinPeriod = now >= presaleStartTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase && !halted;
    }

    function getPriceRate()
        public
        view
        returns (uint)
    {
        if (now <= startTime) return 0;
        if (now <= startTime + STAGE1_TIME_END) return RATE_CROWDSALE_S1;
        if (now <= startTime + STAGE2_TIME_END) return RATE_CROWDSALE_S2;
        if (now <= startTime + STAGE3_TIME_END) return RATE_CROWDSALE_S3;
        return 0;
    }

    function ()
        public 
        payable 
    {
        require(validPurchase());

        uint256 weiAmount = msg.value;
        uint256 purchaseTokens;

        if (whitelisted_Presale[msg.sender]) 
            purchaseTokens = weiAmount.mul(RATE_PRESALE); 
        else
            purchaseTokens = weiAmount.mul(getPriceRate()); 

        require(purchaseTokens > 0 && ALLOC_SALE - totalDinoSold >= purchaseTokens); // supply check
        require(dinoToken.transfer(msg.sender, purchaseTokens));
        emit TokenPurchase(msg.sender, weiAmount, purchaseTokens);

        totalDinoSold = totalDinoSold.add(purchaseTokens); 
        weiRaised = weiRaised.add(weiAmount);
        weiContributions[msg.sender] = weiContributions[msg.sender].add(weiAmount);
        
        forwardFunds();
    }

    function forwardFunds() 
        internal 
    {
        WALLET_ETH_DINO.transfer((msg.value).mul(91).div(100));
        WALLET_ETH_ADMIN.transfer((msg.value).mul(9).div(100));
    }

    function hasEnded() 
        public 
        view
        returns(bool) 
    {
        return now > endTime;
    }

    function toggleHalt(bool _halted)
        public
        onlyOwner
    {
        halted = _halted;
    }

    function drainToken(address _to, uint256 _amount) 
        public
        onlyOwner
    {
        require(dinoToken.balanceOf(this) >= _amount);
        dinoToken.transfer(_to, _amount);
    }

    function drainRemainingToken(address _to) 
        public
        onlyOwner
    {
        require(hasEnded());
        dinoToken.transfer(_to, dinoToken.balanceOf(this));
    }

    function safeDrain() 
        public
        onlyOwner
    {
        WALLET_ETH_ADMIN.transfer(this.balance);
    }
}