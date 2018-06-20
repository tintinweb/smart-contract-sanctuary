pragma solidity ^0.4.24;

contract Control {
    address public owner;
    bool public pause;

    event PAUSED();
    event STARTED();

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier whenPaused {
        require(pause);
        _;
    }

    modifier whenNotPaused {
        require(!pause);
        _;
    }

    function setOwner(address _owner) onlyOwner public {
        owner = _owner;
    }

    function setState(bool _pause) onlyOwner public {
        pause = _pause;
        if (pause) {
            emit PAUSED();
        } else {
            emit STARTED();
        }
    }

}
/**
 * this contract stands for the holds of WestIndia group
 * all income will be split to holders according to their holds
 * user can buy holds from shareholders at his will
 */
contract Share is Control {    /**
     * the holds of every holder
     * the total holds stick to total
     */
    mapping (address => uint) public holds;

    /**
     * since we don&#39;t record holders&#39; address in a list
     * and we don&#39;t want to loop holders list everytime when there is income
     *
     * we use a mechanism called &#39;watermark&#39;
     * 
     * the watermark indicates the value that brought into each holds from the begining
     * it only goes up when new income send to the contract

     * fullfilled indicate the amount that the holder has withdrawaled from his share
     * it goes up when user withdrawal bonus
     * and it goes up when user sell holds, goes down when user buy holds, since the total bonus of him stays the same.
     */
    mapping (address => uint256) public fullfilled;

    /**
     * any one can setup a price to sell his holds
     * if set to 0, means not on sell
     */
    mapping (address => uint256) public sellPrice;
    mapping (address => uint256) public toSell;
    mapping (address => mapping(address => uint256)) public allowance;
    uint256 public watermark;
    uint256 public total;
    uint256 public decimals;
    
    string public symbol;
    string public name;
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event INCOME(uint256);
    event PRICE_SET(address holder, uint shares, uint256 price, uint sell);
    event WITHDRAWAL(address owner, uint256 amount);
    event SELL_HOLDS(address from, address to, uint amount, uint256 price);
    event SEND_HOLDS(address from, address to, uint amount);

    /**
     * at start the owner has 100% share, which is 10,000 holds
     */
    constructor(string _symbol, string _name, uint256 _total) public {        
        symbol = _symbol;
        name = _name;
        owner = msg.sender;
        total = _total;
        holds[owner] = total;
        decimals = 0;
        pause = false;
    }

    /**
     * when there&#39;s income, the water mark goes up
     */
    function onIncome() public payable {
        if (msg.value > 0) {
            watermark += (msg.value / total);
            assert(watermark * total > watermark);
            emit INCOME(msg.value);
        }
    }

    /**
     * automatically split income
     */
    function() public payable {
        onIncome();
    }

    function bonus() public view returns (uint256) {
        return (watermark - fullfilled[msg.sender]) * holds[msg.sender];
    }
    
    function setPrice(uint256 price, uint256 sell) public {
        sellPrice[msg.sender] = price;
        toSell[msg.sender] = sell;
        emit PRICE_SET(msg.sender, holds[msg.sender], price, sell);
    }

    /**
     * withdrawal the bonus
     */
    function withdrawal() public whenNotPaused {
        if (holds[msg.sender] == 0) {
            //you don&#39;t have any, don&#39;t bother
            return;
        }
        uint256 value = bonus();
        fullfilled[msg.sender] = watermark;

        msg.sender.transfer(value);

        emit WITHDRAWAL(msg.sender, value);
    }

    /**
     * transfer holds from => to (only holds, no bouns)
     * this will withdrawal the holder bonus of these holds
     * and the to&#39;s fullfilled will go up, since total bonus unchanged, but holds goes more
     */
    function transferHolds(address from, address to, uint256 amount) internal {
        require(holds[from] >= amount);
        require(holds[to] + amount > holds[to]);

        uint256 fromBonus = (watermark - fullfilled[from]) * amount;
        uint256 toBonus = (watermark - fullfilled[to]) * holds[to];
        

        holds[from] -= amount;
        holds[to] += amount;
        fullfilled[to] = watermark - toBonus / holds[to];

        from.transfer(fromBonus);

        emit Transfer(from, to, amount);
        emit WITHDRAWAL(from, fromBonus);
    }

    /**
     * one can buy holds from anyone who set up an price,
     * and u can buy @ price higher than he setup
     */
    function buyFrom(address from) public payable whenNotPaused {
        require(sellPrice[from] > 0);
        uint256 amount = msg.value / sellPrice[from];

        if (amount >= holds[from]) {
            amount = holds[from];
        }

        if (amount >= toSell[from]) {
            amount = toSell[from];
        }

        require(amount > 0);

        toSell[from] -= amount;
        transferHolds(from, msg.sender, amount);
        
        from.transfer(msg.value);
        emit SELL_HOLDS(from, msg.sender, amount, sellPrice[from]);
    }
    
    function balanceOf(address _addr) public view returns (uint256) {
        return holds[_addr];
    }
    
    function transfer(address to, uint amount) public whenNotPaused returns(bool) {
        transferHolds(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        require(allowance[from][msg.sender] >= amount);
        
        allowance[from][msg.sender] -= amount;
        transferHolds(from, to, amount);
        
        return true;
    }
    
    function approve(address to, uint256 amount) public returns (bool) {
        allowance[msg.sender][to] = amount;
        
        emit Approval(msg.sender, to, amount);
        return true;
    }
    
    function totalSupply() public view returns (uint256) {
        return total;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowance[owner][spender];
    }
}