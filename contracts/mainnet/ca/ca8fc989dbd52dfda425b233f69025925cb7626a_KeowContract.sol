pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c; 
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BasicTokenERC20 {  
    using SafeMath for uint256;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (uint8 => mapping (address => uint256)) internal whitelist;

    uint256 totalSupply_;
    address public owner_;
    
    constructor() public {
        owner_ = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0));
        require(value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    } 
    
    function transferFrom(address from, address to, uint256 value) public returns (bool){
        require(to != address(0));
        require(value <= balances[from]);
        require(value <= allowed[from][msg.sender]);

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return allowed[owner][spender];
    }

    modifier onlyOwner() {
        require(msg.sender == owner_);
        _;
    }

    function addWhiteList(uint8 whiteListType, address investor, uint256 value) public onlyOwner returns (bool){
        whitelist[whiteListType][investor] = value;
        return true;
    }

    function removeFromWhiteList(uint8 whiteListType, address investor) public onlyOwner returns (bool){
        whitelist[whiteListType][investor] = 0;
        return true;
    }
}

contract KeowContract is BasicTokenERC20 {    

    string public constant name = "KeowToken"; 
    string public constant symbol = "KEOW";
    uint public decimals = 18; 
    uint256 public milion = 1000000;
    event TestLog(address indexed from, address indexed to, uint256 value, uint8 state);
    //// 1 billion tokkens KEOW
    uint256 public INITIAL_SUPPLY = 1000 * milion * (uint256(10) ** decimals);
    //// exchange in 1 eth = 30000 KEOW
    uint256 public exchangeETH = 30000;
    //// limit min ethsale
    uint256 public limitClosedSale = 100 * (uint256(10) ** decimals);
    uint256 public limitPreSale = 25 * (uint256(10) ** decimals);
    
    /// address of wallet
    address public ecoSystemWallet;
    address public marketWallet;
    address public contributorsWallet;
    address public companyWallet;
    address public closedSaleWallet;
    address public preSaleWallet;
    address public firstStageWallet;
    address public secondStageWallet;

    uint256 public investors = 0;
    address public currentWallet;    

    /// 0 - Not start/ pause
    /// 1 - closed sale
    /// 2 - presale
    /// 3 - sale1
    /// 4 - sale2
    /// 9 - end    
    uint8 public state = 0;
        
    constructor(address w0, address w1, address w2, address w3, address w4, address w5, address w6, address w7) public {        
        totalSupply_ = INITIAL_SUPPLY;

        uint256 esoSystemValue = 20 * milion * (uint256(10) ** decimals);
        ecoSystemWallet = w0;    
        balances[ecoSystemWallet] = esoSystemValue;
        emit Transfer(owner_, ecoSystemWallet, esoSystemValue);

        uint256 marketValue = 50 * milion * (uint256(10) ** decimals);
        marketWallet = w1;
        balances[marketWallet] = marketValue;
        emit Transfer(owner_, marketWallet, marketValue);

        uint256 contributorsValue = 100 * milion * (uint256(10) ** decimals);
        contributorsWallet = w2;
        balances[contributorsWallet] = contributorsValue;
        emit Transfer(owner_, contributorsWallet, contributorsValue);

        uint256 companyValue = 230 * milion * (uint256(10) ** decimals);
        companyWallet = w3;
        balances[companyWallet] = companyValue;
        emit Transfer(owner_, companyWallet, companyValue);
        
        uint256 closedSaleValue = 50 * milion * (uint256(10) ** decimals);
        closedSaleWallet = w4;
        balances[closedSaleWallet] = closedSaleValue;
        emit Transfer(owner_, closedSaleWallet, closedSaleValue);

        uint256 preSaleValue = 50 * milion * (uint256(10) ** decimals);
        preSaleWallet = w5;
        balances[preSaleWallet] = preSaleValue;
        emit Transfer(owner_, preSaleWallet, preSaleValue);

        uint256 firstStageValue = 250 * milion * (uint256(10) ** decimals);
        firstStageWallet = w6;
        balances[firstStageWallet] = firstStageValue;
        emit Transfer(owner_, firstStageWallet, firstStageValue);

        uint256 secondStageValue = 250 * milion * (uint256(10) ** decimals);
        secondStageWallet = w7; 
        balances[secondStageWallet] = secondStageValue;
        emit Transfer(owner_, secondStageWallet, secondStageValue);
    }    

    function () public payable {
        require(state > 0);
        require(state < 9);
        require(msg.sender != 0x0);
        require(msg.value != 0);
        uint256 limit = getMinLimit();
        
        require(msg.value >= limit);
        address beneficiary = msg.sender;
        require(whitelist[state][beneficiary] >= msg.value);
        
        uint256 weiAmount = msg.value;
        uint256 tokens = weiAmount.mul(exchangeETH);
        require(balances[currentWallet] >= tokens);
        
        balances[currentWallet] = balances[currentWallet].sub(tokens);
        balances[beneficiary] = balances[beneficiary].add(tokens); 
        
        emit Transfer(currentWallet, beneficiary, tokens);
        
        whitelist[state][beneficiary] = 0;
        investors++;        
    }
    
    function getMinLimit () public view returns (uint256) {        
        if (state == 0) {
            return 0;
        }
        
        if (state == 1) {
            return limitClosedSale;
        }
        
        if (state == 2) {
            return limitPreSale;
        }
        
        return 1;
    }

    function updateExchangeRate(uint256 updateExchange) public onlyOwner {
        exchangeETH = updateExchange;
    }

    function withdraw(uint value) public onlyOwner {
        require(value > 0);
        require(companyWallet != 0x0);        
        companyWallet.transfer(value);
    }

    function startCloseSalePhase() public onlyOwner { 
        currentWallet = closedSaleWallet;      
        state = 1;
    }

    function startPreSalePhase() public onlyOwner {        
        currentWallet = preSaleWallet;
        state = 2;
    }

    function startSale1Phase() public onlyOwner {        
        currentWallet = firstStageWallet;
        state = 3;
    }

    function startSale2Phase() public onlyOwner {        
        currentWallet = secondStageWallet;
        state = 4;
    }    

    function stopSale() public onlyOwner {        
        currentWallet = 0;
        state = 0;
    }    

    function endSale () public onlyOwner {
        currentWallet = 0;
        state = 9;
    }        
}