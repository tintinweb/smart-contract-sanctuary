/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-18
*/

pragma solidity ^0.5.17;
interface IERC20 {
    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address recipient, uint amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external returns(bool);
    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


library Address {
    function isContract(address account) internal view returns(bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash:= extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

contract Context {
    constructor() internal {}
    // solhint-disable-previous-line no-empty-blocks
    function _msgSender() internal view returns(address payable) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    uint private _totalSupply;

    function totalSupply() public view returns(uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) public returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) public returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}


contract UniswapExchange {
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    // 每天单价
    uint public price1Day = 0x766c7d7482d320; //0.0333
    // 每月单价
    uint public price1Mon = 200e18;
    // 永久
    uint public priceForever = 500e18; //0.0333

    // 推荐一位送几天
    uint private recommendReward = 7;
    // 总收入 
    uint public totalIncome = 0;
    // 记录会员过期时间
    mapping(address => uint) private membership;
    // 是否代理商  可以将余额按天转卖
    mapping(address => bool) private agent;

    function isOwner() public view returns(bool) {        
        return msg.sender == owner;
    }

    function getAgent(address user) public view returns(bool) {
        return agent[user];
    }

    function setAgent(address user, bool isOpen) public returns(bool) {
        require(msg.sender == owner, " must be owner");
        agent[user] = isOpen;
        return true;
    }

    function getPrice1Day() public view returns(uint) {
        return price1Day;
    }

    function setPrice1Day(uint price) public returns(bool) {
        require(msg.sender == owner, " must be owner");
        price1Day = price;
        return true;
    }
    function getPrice1Mon() public view returns(uint) {
        return price1Mon;
    }

    function setPrice1Mon(uint price) public returns(bool) {
        require(msg.sender == owner, " must be owner");
        price1Mon = price;
        return true;
    }
    function getPriceForever() public view returns(uint) {
        return priceForever;
    }

    function setPriceForever(uint price) public returns(bool) {
        require(msg.sender == owner, " must be owner");
        priceForever = price;
        return true;
    }

    function setRecommendReward(uint dayss) public returns(bool) {
        require(msg.sender == owner, " must be owner");
        recommendReward = dayss;
        return true;
    }

    // 开通会员 amount = 天数
    function buy(uint amount) public payable returns(bool) {
        uint total = amount * price1Day;
        require(msg.value >= total || msg.sender == owner, "Insufficient payments ");
        _recharge(msg.sender, amount);
        totalIncome += msg.value;
        return true;
    }

    // 开通会员 按月
    function buy1Month(uint amount) public payable returns(bool) {
        uint total = amount * price1Mon;
        require(msg.value >= total || msg.sender == owner, "Insufficient payments ");
        _recharge(msg.sender, amount*31);
        totalIncome += msg.value;
        return true;
    }
    function buyForever() public payable returns(bool) {
        uint total = priceForever;
        require(msg.value >= total || msg.sender == owner, "Insufficient payments ");
        _recharge(msg.sender, 99999);
        totalIncome += msg.value;
        return true;
    }


    // 充值会员天数 返回余额   amount(天)
    function recharge(address user, uint amount) public returns(uint) {
        require(msg.sender == owner || agent[msg.sender] == true, "无权限操作");
        require(msg.sender == owner || membership[msg.sender] > (block.timestamp + ( amount * 1 days)), "你的代理余额不足");
        _recharge(user, amount);
        if (msg.sender != owner) {
            membership[msg.sender] -= amount * 1 days;
        }        
        return membership[user];
    }

    // 充值会员天数
    function _recharge(address user, uint amount) internal returns(uint) {
        uint start = membership[user];
        if(block.timestamp > start) {
            start = block.timestamp;
        }
        _mint(user, 1);
        membership[user] = start + ( amount * 1 days); // amount.mul(86400)
        return membership[user];
    }

    function expiredAt(address user) public view returns(uint){
        return membership[user];
    }
    // 查询会员
    function getMembership() public view returns(uint){
        return membership[msg.sender];
    }
    

    // 取出余额
    function withdraw() public payable returns (bool) {
        require(owner == msg.sender , "ERC20: must owner");
        uint ethBalance = address(this).balance;

        require(ethBalance > 0 , "ERC20: insufficient balance eth");
        if(!msg.sender.send(ethBalance)) {
            return false;
        }
        return true;
    }

    // 发币
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        balanceOf[account] += amount;
        totalSupply += amount;
        emit Transfer(address(0), account, amount);
    }

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
 
    uint constant public decimals = 18;
    uint public totalSupply;
    string public name;
    string public symbol;
    address private owner;
    address constant UNI = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
 
    constructor(string memory _name, string memory _symbol, uint256 _supply) payable public {
        name = _name;
        symbol = _symbol;
        totalSupply = _supply*(10**uint256(decimals));
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        // allowance[msg.sender][0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = uint(-1);
        emit Transfer(address(0x0), msg.sender, totalSupply);
    }
}