pragma solidity ^0.4.25;

contract ERC20 {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
}


contract ExToke {

    string public name = "ExToke Token";
    string public symbol = "XTE";
    uint8 public decimals = 18;
    
    uint256 public crowdSaleSupply = 500000000  * (uint256(10) ** decimals);
    uint256 public tokenSwapSupply = 3000000000 * (uint256(10) ** decimals);
    uint256 public dividendSupply = 2400000000 * (uint256(10) ** decimals);
    uint256 public totalSupply = 7000000000 * (uint256(10) ** decimals);

    mapping(address => uint256) public balanceOf;
    
    
    address public oldAddress = 0x28925299Ee1EDd8Fd68316eAA64b651456694f0f;
    address tokenAdmin = 0xEd86f5216BCAFDd85E5875d35463Aca60925bF16;
    
    uint256 public finishTime = 1548057600;
    
    uint256[] public releaseDates = 
    [1543665600, 1546344000, 1549022400, 1551441600, 1554120000, 1556712000,
    1559390400, 1561982400, 1564660800, 1567339200, 1569931200, 1572609600,
    1575201600, 1577880000, 1580558400, 1583064000, 1585742400, 1588334400,
    1591012800, 1593604800, 1596283200, 1598961600, 1601553600, 1604232000];
    
    uint256 public nextRelease = 0;

    function ExToke() public {
        balanceOf[tokenAdmin] = 1100000000 * (uint256(10) ** decimals);
    }

    uint256 public scaling = uint256(10) ** 8;

    mapping(address => uint256) public scaledDividendBalanceOf;

    uint256 public scaledDividendPerToken;

    mapping(address => uint256) public scaledDividendCreditedTo;

    function update(address account) internal {
        if(nextRelease < 24 && block.timestamp > releaseDates[nextRelease]){
            releaseDivTokens();
        }
        uint256 owed =
            scaledDividendPerToken - scaledDividendCreditedTo[account];
        scaledDividendBalanceOf[account] += balanceOf[account] * owed;
        scaledDividendCreditedTo[account] = scaledDividendPerToken;
        
        
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        update(msg.sender);
        update(to);

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        update(from);
        update(to);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    uint256 public scaledRemainder = 0;
    
    function() public payable{
        tokenAdmin.transfer(msg.value);
        if(finishTime >= block.timestamp && crowdSaleSupply >= msg.value * 100000){
            balanceOf[msg.sender] += msg.value * 100000;
            crowdSaleSupply -= msg.value * 100000;
            
        }
        else if(finishTime < block.timestamp){
            balanceOf[tokenAdmin] += crowdSaleSupply;
            crowdSaleSupply = 0;
        }
    }

    function releaseDivTokens() public returns (bool success){
        require(block.timestamp > releaseDates[nextRelease]);
        uint256 releaseAmount = 100000000 * (uint256(10) ** decimals);
        dividendSupply -= releaseAmount;
        uint256 available = (releaseAmount * scaling) + scaledRemainder;
        scaledDividendPerToken += available / totalSupply;
        scaledRemainder = available % totalSupply;
        nextRelease += 1;
        return true;
    }

    function withdraw() public returns (bool success){
        update(msg.sender);
        uint256 amount = scaledDividendBalanceOf[msg.sender] / scaling;
        scaledDividendBalanceOf[msg.sender] %= scaling;  // retain the remainder
        balanceOf[msg.sender] += amount;
        return true;
    }

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    

    function swap(uint256 sendAmount) returns (bool success){
        require(tokenSwapSupply >= sendAmount * 3);
        if(ERC20(oldAddress).transferFrom(msg.sender, tokenAdmin, sendAmount)){
            balanceOf[msg.sender] += sendAmount * 3;
            tokenSwapSupply -= sendAmount * 3;
        }
        return true;
    }

}