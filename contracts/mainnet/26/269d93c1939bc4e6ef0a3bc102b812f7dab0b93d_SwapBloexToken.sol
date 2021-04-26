/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

pragma solidity ^0.5.17;


interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


contract Context {
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}


contract ERC20 is Context, IERC20 {
    using SafeMath for uint;

    mapping (address => uint) private _balances;

    mapping (address => mapping (address => uint)) private _allowances;

    uint private _totalSupply;
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function transfer(address recipient, uint amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) public returns (bool) {
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
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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



contract SwapBloexToken is ERC20, ERC20Detailed {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;
    
    IERC20 public btToken;   
    IERC20 public usdtToken;
    address public governance;

    uint8 public isOpenDeposit = 1;
    uint8 public isOpenWithdraw = 1;
    
    uint public btRate = 2230;              //bt founding value
    uint constant public rateBase = 10000; 

    address constant public usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);      //Tether USD (USDT)
    address constant public bt = address(0x061C266cAF366e73CeA4bdc9DC22392fb81115F2);             //Bloex Token (BT) 


    constructor () public ERC20Detailed("BloexSwap", "BTSwap", 18) {
        btToken = IERC20(bt);
        usdtToken = IERC20(usdt);
        governance = 0x1360CFA0606E5b057df468D540fA81F75d8146E3;
    }
    
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
    
    //set bt founding value
    function setBTRate(uint _btRate) external {
        require(msg.sender == governance, "!governance");
        btRate = _btRate;
    }
    
    function setOpenDeposit(uint8 _isOpenDeposit) external {
        require(msg.sender == governance, "!governance");
        isOpenDeposit = _isOpenDeposit;
    }
    function setOpenWithdraw(uint8 _isOpenWithdraw) external {
        require(msg.sender == governance, "!governance");
        isOpenWithdraw = _isOpenWithdraw;
    }


    //buy bt with usdt
    function deposit(uint _amount) public {
        require(isOpenDeposit == 1, "!isOpenDeposit");

        // Check usdt balance
        require(_amount <= usdtToken.balanceOf(msg.sender), "!sufficient USDT");

        //get bt amount
        uint bt_amount = _amount.mul(rateBase).div(btRate).mul(1e12);  //18 decimals
        
        // Check bt balance
        require(bt_amount <= btToken.balanceOf(address(this)), "!sufficient BT");        

        //deposit usdt
        usdtToken.safeTransferFrom(msg.sender, address(this), _amount);

        //pay bt
        btToken.safeTransfer(msg.sender, bt_amount);
    }
    
    //swap bt to usdt
    function withdraw(uint _amount) public {
        require(isOpenWithdraw == 1, "!isOpenWithdraw");
        
        // Check bt balance
        require(_amount <= btToken.balanceOf(msg.sender), "!sufficient BT");
        
        //swap back usdt amount
        uint usdt_amount = _amount.mul(btRate).div(rateBase).div(1e12);  //6 decimals
        
        // Check usdt balance
        require(usdt_amount <= usdtToken.balanceOf(address(this)), "!sufficient USDT");
        
        //withdraw bt
        btToken.safeTransferFrom(msg.sender, address(this), _amount);

        //pay usdt
        usdtToken.safeTransfer(msg.sender, usdt_amount);
    }
    
    function depositAll() external {
        require(isOpenDeposit == 1, "!isOpenDeposit");
        
        deposit(usdtToken.balanceOf(msg.sender));
    }
    
    function withdrawAll() external {
        require(isOpenWithdraw == 1, "!isOpenWithdraw");
        
        withdraw(balanceOf(msg.sender));
    }
    
    function moveUSDT() public {
        require(msg.sender == governance, "!governance");
        uint _amount = usdtToken.balanceOf(address(this));
        usdtToken.safeTransfer(msg.sender, _amount);
    }
    
    function moveBT() public {
        require(msg.sender == governance, "!governance");
        uint _amount = btToken.balanceOf(address(this));
        btToken.safeTransfer(msg.sender, _amount);
    }

    //bt balanceOf
    function balanceOf(address _owner) public view returns (uint256) {
        return btToken.balanceOf(_owner);

    }
    
    function inCaseTokensGetStuck(address _token, uint _amount) public {
      //any erc20
      require(msg.sender == governance, "!governance");
      IERC20(_token).safeTransfer(governance, _amount);
    }
    
    function getPricePerFullShare() public view returns (uint) {
      return btRate.mul(1e18).div(rateBase);
    }
}