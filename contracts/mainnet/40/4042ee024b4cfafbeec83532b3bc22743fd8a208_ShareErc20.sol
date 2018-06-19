pragma solidity ^0.4.21;

contract ERC20Interface {
    // function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    //function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    //function symbol() public constant returns (string);
    //function decimals() public constant returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Control {
    bool public pause;
    address public owner;

    event Pause(bool pause);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notPause {
        require(!pause);
        _;
    }

    function setPause(bool _pause) public onlyOwner {
        pause = _pause;

        emit Pause(_pause);
    }
}

contract Share is Control {
    uint256 public totalSupply;
    uint256 public watermark;
    Share public h;

    mapping (address => uint256) public balances;
    mapping (address => uint256) public fullfilled;
    mapping (address => uint256) public sellPrice;
    mapping (address => uint256) public toSell;

    event Transfer(address from, address to, uint256 amount);
    event Income(uint256);
    event Sell(address holder, uint256 price, uint256 amount);
    event Buy(address seller, address buyer, uint256 amount, uint256 value);
    event Withdraw(address owner, uint256 amount);

    function Share(uint256 _totalSupply) public {
        totalSupply = _totalSupply;
        h = Share(0x1db45a09efcdd8955b1C3BB855b5A8d333446bFf);
        balances[msg.sender] = totalSupply;

        emit Transfer(0, msg.sender, totalSupply);
    }

    function onIncome() public payable notPause {
        if (msg.value > 0) {
            uint256 split = (msg.value / totalSupply);
            watermark += split;
            assert(watermark * totalSupply > watermark);

            if ((msg.value - split * totalSupply) > 0) {
                h.onIncome.value(msg.value - split * totalSupply)();
            }
            emit Income(msg.value);
        }
    }

    function() public payable {
        onIncome();
    }

    function revenue() public view returns (uint256) {
        return (watermark - fullfilled[msg.sender]) * balances[msg.sender];
    }

    function withdraw() public notPause {
        if(balances[msg.sender] == 0) {
            return;
        }
        uint256 value = revenue();
        fullfilled[msg.sender] = watermark;
        msg.sender.transfer(value);

        emit Withdraw(msg.sender, value);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        // prevent overflow
        require(amount > 0);
        require(balances[from] >= amount);
        require(balances[to] + amount > balances[to]);
        

        uint256 fromBonus = (watermark - fullfilled[from]) * amount;
        uint256 toBonus = (watermark - fullfilled[to]) * balances[to];

        balances[from] -= amount;
        balances[to] += amount;

        //for to, the revenue stays the same, but balance increases, so update the fullfilled
        fullfilled[to] = (watermark * balances[to] - toBonus)/balances[to];

        //for from, withdraw the revenue on the amount of token transferd
        from.transfer(fromBonus);

        emit Transfer(from, to, amount);
        emit Withdraw(from, fromBonus);
    }

    function sell(uint256 price, uint256 amount) public {
        sellPrice[msg.sender] = price;
        toSell[msg.sender] = amount;

        emit Sell(msg.sender, price, amount);
    }

    function buy(address from) public payable notPause {
        require(sellPrice[from] > 0);
        uint256 amount = msg.value / sellPrice[from];

        if (amount >= balances[from]) {
            amount = balances[from];
        }

        if (amount >= toSell[from]) {
            amount = toSell[from];
        }

        require(amount > 0);

        toSell[from] -= amount;
        _transfer(from, msg.sender, amount);

        from.transfer(msg.value);
        
        emit Buy(from, msg.sender, amount, msg.value);
    }
}
/**
 * this contract stands for the holds of WestIndia group
 * all income will be split to holders according to their holds
 * user can buy holds from shareholders at his will
 */
contract ShareErc20 is Share, ERC20Interface {
    string public symbol;
    string public name;
    uint256 public decimals;

    mapping (address => mapping(address => uint256)) public allowance;

    /**
     * at start the owner has 100% share, which is 10,000 holds
     */
    function ShareErc20(string _symbol, string _name, uint _totalSupply)
      Share(_totalSupply)
      public {        
        name = _name;
        symbol = _symbol;
        decimals = 0;
    }

    function balanceOf(address addr) public constant returns(uint256) {
        return balances[addr];
    }

    function transfer(address to, uint amount) public returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address to, uint256 amount) public returns(bool){
        allowance[msg.sender][to] = amount;

        emit Approval(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        require(allowance[from][msg.sender] >= amount);

        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);

        return true;
    }
}