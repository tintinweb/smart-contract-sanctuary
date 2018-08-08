pragma solidity ^0.4.23;


library Math {


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if(a == 0) { return 0; }
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


contract QRC20 {


    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    

    address public owner_;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        
        owner_ = msg.sender;
    }

    modifier onlyOwner() {
        
        require(msg.sender == owner_);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        
        require(newOwner != address(0));
        emit OwnershipTransferred(owner_, newOwner);
        owner_ = newOwner;
    }
}


contract BasicToken is QRC20 {
    

    using Math for uint256;
    
    uint256 totalSupply_;    
    mapping(address => uint256) balances_;

    function totalSupply() public view returns (uint256) {
        
        return totalSupply_;
    }

    function transfer(address to, uint256 value) public returns (bool) {

        require(to != address(0));
        require(value <= balances_[msg.sender]);

        balances_[msg.sender] = balances_[msg.sender].sub(value);
        balances_[to] = balances_[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {

        return balances_[owner];
    }
}


contract StandardToken is BasicToken {


    event Burn(address indexed burner, uint256 value);
    mapping (address => mapping (address => uint256)) internal allowed_;

    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        require(to != address(0));
        require(value <= balances_[from]);
        require(value <= allowed_[from][msg.sender]);

        balances_[from] = balances_[from].sub(value);
        balances_[to] = balances_[to].add(value);
        allowed_[from][msg.sender] = allowed_[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        
        allowed_[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        
        return allowed_[owner][spender];
    }

    function burn(uint256 value) public {

        require(value <= balances_[msg.sender]);
        address burner = msg.sender;
        balances_[burner] = balances_[burner].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        emit Burn(burner, value);
    }
}


contract UUNIOToken is StandardToken, Ownable {

    
    using Math for uint;

    string constant public name     = "UUNIO Token";
    string constant public symbol   = "UUNIO";
    uint8 constant public decimals  = 8;
    uint256 constant INITIAL_SUPPLY = 900000000e8;

    // MAINNET
    address constant team      = 0x9c619FF74015bECc48D429755aA54435ba367e23;
    address constant advisors  = 0xB4fca416727c92F5dBfC1d3C248F9A50B9f811fE;
    address constant reserve   = 0x8E2c648f493323623C2a55010953aE2B98ec7675;
    address constant system1   = 0x91c2ccf957C32A3F37125240942E97C1bD2aC394;
    address constant system2   = 0xB9E51D549c2c0EE7976E354e8a33CD2F91Ef955C;
    address constant angel     = 0x3f957Fc80cdf9ad2A9D78C3aFd13a75099A167B3;
    address constant partners  = 0x8F3e215C76B312Fd28fBAaf16FE98d6e9357b8AB;
    address constant preSale   = 0x39401cd3f45C682Bbb75eA4D3aDD4E268b19D0Fc;
    address constant crowdSale = 0xB06DD470C23979f8331e790D47866130001e7492;
    address constant benefit   = 0x0Ff19B60b84040019EA6B46E6314367484f66F8F;
    
    // TESTNET
    // address constant team        = 0x08cF66b63c2995c7Cc611f58c3Df1305a1E46ba7;
    // address constant advisors    = 0xCf456ED49752F0376aFd6d8Ed2CC6e959E57C086;
    // address constant reserve     = 0x9F1046F1e85640256E2303AC807F895C5c0b862b;
    // address constant system1     = 0xC97eFe0481964b344Df74e8Fa09b194010736A62;
    // address constant system2     = 0xC97eFe0481964b344Df74e8Fa09b194010736A62;
    // address constant angel       = 0xd03631463a266A749C666E6066D835bDAD307FB8;
    // address constant partners    = 0xd03631463a266A749C666E6066D835bDAD307FB8;
    // address constant preSale     = 0xd03631463a266A749C666E6066D835bDAD307FB8;
    // address constant crowdSale   = 0xd03631463a266A749C666E6066D835bDAD307FB8;
    // address constant benefit     = 0x08cF66b63c2995c7Cc611f58c3Df1305a1E46ba7;

    // 10%
    uint constant teamTokens      = 90000000e8;
    // 10%    
    uint constant advisorsTokens  = 90000000e8;
    // 30%    
    uint constant reserveTokens   = 270000000e8;
    //// total 15.14, 136260000 ///////
    // 15%
    uint constant system1Tokens   = 135000000e8;
    // 0.14%
    uint constant system2Tokens   = 1260000e8;
    ////////////////////////
    // 5.556684%
    uint constant angelTokens     = 50010156e8;
    // 2.360022%
    uint constant partnersTokens  = 21240198e8;
    // 15.275652%
    uint constant preSaleTokens   = 137480868e8;
    // 11.667642%
    uint constant crowdSaleTokens = 105008778e8;

    constructor() public {

        totalSupply_ = INITIAL_SUPPLY;

        preFixed(team, teamTokens);
        preFixed(advisors, advisorsTokens);
        preFixed(reserve, reserveTokens);
        preFixed(system1, system1Tokens);
        preFixed(system2, system2Tokens);
        preFixed(angel, angelTokens);
        preFixed(partners, partnersTokens);
        preFixed(preSale, preSaleTokens);
        preFixed(crowdSale, crowdSaleTokens);
    }

    function preFixed(address addr, uint amount) internal returns (bool) {
        
        balances_[addr] = amount;
        emit Transfer(address(0x0), addr, amount);
        return true;
    }

    function transfer(address to, uint256 value) public returns (bool) {

        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        return super.transferFrom(from, to, value);
    }

    function () public payable {

        benefit.transfer(msg.value);
    }
}