/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

pragma solidity 0.6.6;

contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        assert(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

}


contract PepeCoin is Owned, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimal;
    uint256 public TotalSupply;
    uint256 public coinPrice;
    uint256 private conversion;
    uint256 public coinSold;
    

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Sell(address _buyer, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) internal Allowance;

    constructor (uint256 InitialSupply) public {
        name = "PepeCoin";
        symbol = "PEPE";
        decimal = 18;
        balanceOf[owner] = InitialSupply;
        TotalSupply = InitialSupply;
    }

    function transfer(address to, uint coins) public returns (bool success) {
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], coins);
        balanceOf[to] = add(balanceOf[to], coins);
        emit Transfer(msg.sender, to, coins);
        return true;
    }

    function approve(address spender, uint coins) public returns (bool success) {
        Allowance[msg.sender][spender] = coins;
        emit Approval(msg.sender, spender, coins);
        return true;
    }

    function transferFrom(address from, address to, uint coins) public returns (bool success) {
        balanceOf[from] = sub(balanceOf[from], coins);
        Allowance[from][msg.sender] = sub(Allowance[from][msg.sender], coins);
        balanceOf[to] = add(balanceOf[to], coins);
        emit Transfer(from, to, coins);
        return true;
    }
    
    function mint(address account, uint256 coins) external onlyOwner {
        require(account != address(0));

        TotalSupply = add(TotalSupply, coins);
        balanceOf[account] = add(balanceOf[account], coins);
        emit Transfer(address(0), account, coins);
    }   
    
    function burn(address account, uint256 coins) external onlyOwner {
        require(account != address(0));

        TotalSupply = sub(TotalSupply, coins);
        balanceOf[account] = sub(balanceOf[account], coins);
        emit Transfer(account, address(0), coins);
    }

    function PepeCoinSale(uint256 _coinPrice, uint256 _conversion) public onlyOwner {
        coinPrice = _coinPrice;
        conversion = _conversion;
    }

    function buyCoins(uint256 quan) public payable {
        uint256 Quan = mul(quan, conversion);
        require(msg.value == mul(quan, coinPrice));
        require(balanceOf[owner] >= Quan);
        balanceOf[owner] = sub(balanceOf[owner], Quan);
        balanceOf[msg.sender] = add(balanceOf[msg.sender], Quan);

        coinSold = add(Quan, coinSold);

        emit Sell(msg.sender, Quan);
    }

    function withdrawl(uint amount) external onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        msg.sender.transfer(amount);
        return true;
        
    }
}