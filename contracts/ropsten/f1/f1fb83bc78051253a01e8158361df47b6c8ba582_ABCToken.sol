/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// SPDX-License-Identifier: None

pragma solidity ^0.6.6;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

contract ReferenceConsumer {
  AggregatorInterface internal ref;
  // For ETH-USD on ropsten, input the address:
  // 0x8468b2bDCE073A157E560AA4D9CcF6dB1DB98507

  constructor(address _aggregator) public {
    ref = AggregatorInterface(_aggregator);
  }

  function getLatestAnswer() public view returns (int256) {
    return ref.latestAnswer();
  }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


library SafeMath {
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    function name() public view returns (string memory) {
        return _name;
    }    
    function symbol() public view returns (string memory) {
        return _symbol;
    }    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Ownable {
    address private owner;
    
    constructor () public {
        owner = msg.sender;
    }
    
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
    
    function getOwner () public view returns (address) {
        return owner;
    }
}

contract Switchable is Ownable{
    enum state {Active, Inactive}
    state internal State;
    
    constructor () public {
        State = state.Active;
    }
    
    function getState () public view returns (string memory) {
        if (State == state.Active) {
            return "Active";
        } else {
            return "Inactive";
        }
    }
    
    function switchState () internal onlyOwner returns (string memory) {
        if (State == state.Active) {
            State = state.Inactive;
        } else {
            State = state.Active;
        }
        
        return getState();
    }
    
    modifier onlyActive {
        require (State == state.Active, "Token is inactive!");
        _;
    }
}

interface EthRateInterface {
    function EthToUsdRate() external view returns(uint256);
}

contract ABCToken is ERC20, Ownable, Switchable {
    using SafeERC20 for IERC20;

    IERC20 usdtToken;
    IERC20 daiToken;
    EthRateInterface public EthRateSource = EthRateInterface(0x9dd4C0a264B53e26B61Fa27922Ac4697f0b9dD8b);
    uint256 private price;
    
    AggregatorInterface internal ref;
  // For ETH-USD on ropsten, input the address:
  // 0x8468b2bDCE073A157E560AA4D9CcF6dB1DB98507

  

    function getLatestAnswer() public view returns (uint256) {
       return uint256(ref.latestAnswer());
    }

    mapping (address => uint256) private last_purchases;

    uint256[] private inactive_purchases;
    mapping (uint256 => address) private inactive_purchases_addresses;

    constructor (string memory name, string memory symbol, 
                 uint8 decimals, address _usdtToken, 
                 address _daiToken, uint256 _price, address aggregator) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = 0;
        usdtToken = IERC20(_usdtToken);
        daiToken = IERC20(_daiToken);
        price = _price;
        ref = AggregatorInterface(aggregator);
    }
    
    receive() payable external {
        uint256 usdt_amount = msg.value.mul(getLatestAnswer()).div(10e20);
        uint256 amount = _viewSell(usdt_amount);
        address payable _owner = payable(getOwner());
        _owner.transfer(msg.value);
        _buy(msg.sender, amount);
    }
    
    function getBalance () private view returns (uint256) {
        return usdtToken.balanceOf(address(this));
    }
    
    function transfer (address recipient, uint256 amount) public override onlyActive returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function getPrice () public view returns (uint256) {
        return price;
    }
    
    function _viewBuy (uint256 usdtValue) private view returns (uint256) {
        return usdtValue.mul(10e5).div(price);
    }
    
    function _viewSell (uint256 tokenValue) private view returns (uint256) {
        return tokenValue.mul(price).div(10e5);
    }
    
    function _buy (address receiver, uint256 value) private {
        require (value > 0);

        if (State == state.Inactive) {
            uint256 addressIndex = 0;
            bool addressInArray = false;
            for (uint256 i = 0; i < inactive_purchases.length; i++){
                if (inactive_purchases_addresses[i] == receiver) {
                    addressInArray = true;
                    addressIndex = i;
                    break;
                }
            }

            if (addressInArray) {
                inactive_purchases[addressIndex].add(value);
            } else {
                inactive_purchases_addresses[inactive_purchases.length] = receiver;
                inactive_purchases.push(value);
            }
        }

        _mint(receiver, value);
        last_purchases[receiver] = block.timestamp;
    }
    
    function usdtBuy (uint256 value) public {
        require (usdtToken.allowance(msg.sender, address(this)) >= value, "Allowance is less than value");
        usdtToken.safeTransferFrom(msg.sender, address(getOwner()), value);
        _buy(msg.sender, value);
    }
    
    function daiBuy (uint256 value) public {
        require (daiToken.allowance(msg.sender, address(this)) >= value, "Allowance is less than value");
        usdtToken.safeTransferFrom(msg.sender, address(getOwner()), value);
        _buy(msg.sender, _viewBuy(value.div(10e5)));
    }
    
    function withdraw (uint256 value) public onlyActive {
        require (balanceOf(msg.sender) >= value, "You have not such amount of this token to withdraw");
        require (block.timestamp - last_purchases[msg.sender] > 86400, "1 day should pass from last purchase");
        require(usdtToken.allowance(address(getOwner()), address(this)) >= value, "Internal error. Try again later!");
        
        _burn(msg.sender, value);
        usdtToken.safeTransferFrom(address(getOwner()), msg.sender, value);
    }
    
    function beginTrading () public onlyOwner onlyActive {
        switchState();
    }
    
    function tradingStopped () public onlyOwner {
        require (State == state.Inactive, "Token is active");
        require (usdtToken.balanceOf(address(getOwner())) >= 0, "USDT balance is equals to zero!");
        uint256 old_price = price;
        price = usdtToken.balanceOf(address(getOwner())).mul(10e5).div(_totalSupply);
        switchState();

        for (uint256 i = 0; i < inactive_purchases.length; i++){
            uint256 bought = _balances[inactive_purchases_addresses[i]];
            uint256 usdAmount = bought.mul(old_price).div(10e5);
            uint256 newValue = _viewBuy(usdAmount);

            _balances[inactive_purchases_addresses[i]] = _balances[inactive_purchases_addresses[i]].sub(bought).add(newValue);
        }
    }
}