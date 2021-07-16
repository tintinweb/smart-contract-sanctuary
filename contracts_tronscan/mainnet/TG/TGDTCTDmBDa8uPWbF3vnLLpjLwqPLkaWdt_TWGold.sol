//SourceUnit: token.sol

pragma solidity =0.4.25;

library SafeMath { //We divide only by constans, no check requeries.

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}

//receiving contract, is taken from ERC223 code
contract ReceivingContract { 
    function tokenFallback(address from, uint value, uint16 itemId, uint64 quantity);
}


 //Standard TRC20 token
 //Implementation of the basic standard token.

contract TRC20 {
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _totalSupply;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}

contract TWGold is TRC20("Tron Worlds Gold", "TWGold", 6){

    //the main Tron worlds contract TJYNMUtUeDTEQGHKQQ7ZijMkh1E2kGKg4C in base58
    address constant TWContract = address(0x5e068a2DcAFB9D8dFD29ab2aB95a5396993149cA); //in 0xCheckSum

    address admin;
    address owner;

    event ContractTransfer(address indexed from, address indexed to, uint256 value, uint16 itemId, uint64 quantity);
    event BuyItem(address indexed from, address indexed to, uint256 value, uint16 itemId, uint64 quantity);

    constructor(address _owner, address _admin) public {
        owner = _owner;
        admin = _admin;
        //total supply is zero after deployment, no premine
    }

    //admin gets 5% from any purchase.
    function changeAdmin(address _admin) external {
        require(msg.sender == owner);
        admin = _admin;
    }

    //alternative way to transfer tokens to a contract, similar, but not compartable with ERC223 standart
    //can be used by third party shops and exchangers
    function contractTransfer(address to, uint value, uint16 itemId, uint64 quantity) external {

        _transfer(msg.sender, to, value);

        ReceivingContract receiver = ReceivingContract(to);
        receiver.tokenFallback(msg.sender, value, itemId, quantity);
        
        emit ContractTransfer(msg.sender, to, value, itemId, quantity);
    }

    //the only way to mint new tokens is buy them with game balance in the main Tron Worlds contract
    function doAction(address player, uint amount, uint8 action) external {
        require(msg.sender == TWContract);
        _mint(player, amount);
    }

    //spend tokens in the game shop, with any purchase 5% goes to the admin account, the rest is burnt
    function buyItem(address to, uint value, uint16 itemId, uint64 quantity) external {

        uint adminAmount = value / 20; //5% of tokens goes to the admin account and will be used for promotion purpose
        _transfer(msg.sender, admin, adminAmount);
        uint burnAmount = value.sub(adminAmount);
        _burn(msg.sender, burnAmount); //95% of tokens is burnt

        ReceivingContract receiver = ReceivingContract(to);
        receiver.tokenFallback(msg.sender, value, itemId, quantity);

        emit BuyItem(msg.sender, to, value, itemId, quantity);
    }

}