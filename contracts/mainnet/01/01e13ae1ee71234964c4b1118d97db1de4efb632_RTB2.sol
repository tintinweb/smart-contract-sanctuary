pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

     /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else{
            uint256 z = x;
            for (uint256 i = 1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}

interface shareProfit {
    function increaseProfit() external payable returns(bool);
}

contract RTB2 is shareProfit {
    using SafeMath for uint256;

    uint8 public decimals = 0;
    uint256 public totalSupply = 700;                                            
    uint256 public totalSold = 0;
    uint256 public constant price = 1 ether;
    string public name = "Retro Block Token 2";
    string public symbol = "RTB2";
    address public owner;
    address public finance;
    
    mapping (address=>uint256) received;
    uint256 profit;
    address public jackpot;
    shareProfit public shareContract;
    mapping (address=>uint256) changeProfit;

    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event AddProfit(address indexed _from, uint256 _value, uint256 _newProfit);
    event Withdraw(address indexed _addr, uint256 _value);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }
    
    modifier onlyHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    
    constructor(address _shareAddr) public {
        owner = msg.sender;
        finance = 0x28Dd611d5d2cAA117239bD3f3A548DcE5Fa873b0;
        jackpot = 0x119ea7f823588D2Db81d86cEFe4F3BE25e4C34DC;
        shareContract = shareProfit(_shareAddr);
        balances[this] = 700;
    }

    function() public payable {
        require(msg.value > 0, "Amount must be provided");
        profit = msg.value.div(totalSupply).add(profit);
        emit AddProfit(msg.sender, msg.value, profit);
    }
    
    function increaseProfit() external payable returns(bool){
        if(msg.value > 0){
            profit = msg.value.div(totalSupply).add(profit);
            emit AddProfit(msg.sender, msg.value, profit);
            return true;
        }else{
            return false;
        }
    }
    
    function totalSupply() external view returns (uint256){
        return totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value > 0 && allowed[msg.sender][_spender] == 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= allowed[_from][msg.sender]);
        allowed[_from][msg.sender] -= _value;
        return _transfer(_from, _to, _value);
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0), "Receiver address cannot be null");
        require(_from != _to);
        require(_value > 0 && _value <= balances[_from]);
        uint256 newToVal = balances[_to] + _value;
        assert(newToVal >= balances[_to]);
        uint256 newFromVal = balances[_from] - _value;
        balances[_to] = newToVal;
        balances[_from] =  newFromVal;
        uint256 temp = _value.mul(profit);
        changeProfit[_from] = changeProfit[_from].add(temp);
        received[_to] = received[_to].add(temp);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function buy(uint256 _amount) external onlyHuman payable{
        require(_amount > 0);
        uint256 _money = _amount.mul(price);
        require(msg.value == _money);
        require(balances[this] >= _amount);
        require((totalSupply - totalSold) >= _amount, "Sold out");
        _transfer(this, msg.sender, _amount);
        finance.transfer(_money.mul(60).div(100));
        jackpot.transfer(_money.mul(20).div(100));
        shareContract.increaseProfit.value(_money.mul(20).div(100))();
        totalSold += _amount;
    }

    function withdraw() external {
        uint256 value = getProfit(msg.sender);
        require(value > 0, "No cash available");
        emit Withdraw(msg.sender, value);
        received[msg.sender] = received[msg.sender].add(value);
        msg.sender.transfer(value);
    }

     function getProfit(address _addr) public view returns(uint256){
        return profit.mul(balances[_addr]).add(changeProfit[_addr]).sub(received[_addr]);
    }
    
    function setJackpot(address _addr) public onlyOwner{
        jackpot = _addr;
    }
    
    function setShare(address _addr) public onlyOwner{
        shareContract = shareProfit(_addr);
    }
    
    function setFinance(address _addr) public onlyOwner{
        finance = _addr;
    }
}