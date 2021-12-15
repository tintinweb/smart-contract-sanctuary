/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a,uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)external view returns (
      uint80 roundId,
      uint256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()external view returns (
      uint80 roundId,
      uint256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;
    /**
     * Network: Binance Smart Chain
     * Aggregator: BNB/USD
     * Address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
     * TestNet: 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
     */

    constructor()  {
        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
    }

    /**
     * Returns the latest price
     */
    function getLatestPriceBNB() public view returns (uint256) {
        (
            uint80 roundID,
            uint256 price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

contract AnimaToken is Context, IERC20, IERC20Metadata, PriceConsumerV3 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply = 1000 * 10**9 * 10**8;
    uint8 private _decimals = 8;
    string private _symbol = "ANIMA";
    string private _name = "Animal Land";
    address public owner;

    constructor() {
        owner = _msgSender();
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    modifier onlyOwner() {
        require(_msgSender() == owner, "Ownable: caller is not the owner");
        _;
    }
    modifier notOwner() {
        require(_msgSender() != owner, "Ownable: owner is not call");
        _;
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
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transferToken(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address _owner, address _spender) public view virtual override returns (uint256) {
        return _allowances[_owner][_spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transferToken(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transferToken(address sender,address recipient,uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require((_balances[sender] - getLockAmount(sender)) >= amount, "LOCK! Your balance is unlocked over time");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "BEP20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address _owner,address spender,uint256 amount) internal virtual {
        require(_owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function _beforeTokenTransfer(address from,address to,uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from,address to,uint256 amount) internal virtual {}


    // -------------------------
    mapping(address => User) internal _users;

    struct User {
        address uAddress;
        uint256 initAmount;
        uint timeLockStart;
        uint timeLock1;
        uint timeLockEnd;
        uint8 step;
    }

    function transferAddLock(address _to, uint256 _value, uint256 _timeLock1, uint256 _timeLockEnd, uint8  _step) public onlyOwner returns (bool success){
        _addUserLock(_to, _value, _timeLock1, _timeLockEnd, _step);
        return true;
    }

    function _addUserLock(address addr, uint256 initAmount,  uint timeLock1, uint timeLockEnd, uint8 step ) internal {        
        _users[addr] = User(addr, (_users[addr].initAmount + initAmount), block.timestamp, block.timestamp+timeLock1, block.timestamp+timeLockEnd, step );
         _transferToken(owner, addr, initAmount);
    }

    function editUserLock(address addr, uint timeLock1, uint timeLockEnd, uint8 step ) public onlyOwner {
        _users[addr] = User(addr, _users[addr].initAmount, block.timestamp, block.timestamp + timeLock1, block.timestamp + timeLockEnd, step);
    }

     function getUserLock(address addr) public view  returns (uint256, uint, uint, uint, uint){
       return (
        _users[addr].initAmount,
       _users[addr].timeLockStart,
       (_users[addr].timeLock1 - _users[addr].timeLockStart),
       (_users[addr].timeLockEnd - _users[addr].timeLockStart),
       _users[addr].step
       );
    }
    
    function getLockAmount(address addr) public view returns (uint256){
        if (block.timestamp >= _users[addr].timeLockEnd) {
            return 0;
        } else if (block.timestamp >= _users[addr].timeLock1) {
            uint256 _lockAmount1Step = _users[addr].initAmount / _users[addr].step;
            uint256 _lockTime1Step = (_users[addr].timeLockEnd - _users[addr].timeLock1) / _users[addr].step;
            uint256 _timeLock = _users[addr].timeLockEnd - block.timestamp;
            // uint b = uint(5)/2
            return (uint(_timeLock / _lockTime1Step)+1) * _lockAmount1Step;
        } else {
            return _users[addr].initAmount;
        }
    }

    
    // -------------------------
    uint256 public tokenPrice = 1*10**8; // 1 token for 100000000 wei
    uint256 private _rateOfPN = 20;
    uint256 private _tokenPricePN = tokenPrice - (tokenPrice * _rateOfPN / 100);

    // uint256 public bnbPirce = 53160350033; // getLatestPriceBNB()
    function _tokenToBNB(uint256 _tk, uint256 _price) internal virtual returns (uint256){
        return ((_tk * _price) / getLatestPriceBNB())*10**10;
    }
    
    event Bought(address addr, uint256 amount);
    event Sold(address addr, uint256 amount);
    
    function setPrice(uint256 _newPrice, uint256 _ratePN) public onlyOwner {
        tokenPrice = _newPrice;
        _rateOfPN = _ratePN;
    }

    function checkBalance(address _ofAddr) public view returns (uint256){
        return _ofAddr.balance;
    }

    function buyByBNB(uint256 _amountToken) public notOwner{
        require(_tokenToBNB(_amountToken, tokenPrice) <= msg.sender.balance, "Not enough BNB in your balance");
        require(_amountToken <= _balances[owner], "Not enough tokens in the reserve");
        
        uint256 _oneMonthSec = 2592000;
        _addUserLock(_msgSender(), _amountToken, (_oneMonthSec*6), (_oneMonthSec*18), 12);
        payable(owner).transfer( _tokenToBNB(_amountToken, tokenPrice));        
        
        emit Bought(_msgSender(), _amountToken);
    }

    function _pnBuyByBNB(uint256 _amountToken) internal virtual notOwner{
        require(_tokenToBNB(_amountToken, _tokenPricePN) <= msg.sender.balance, "Not enough BNB in your balance");
        require(_amountToken <= _balances[owner], "Not enough tokens in the reserve");
        
        uint256 _oneMonthSec = 2592000;
        _addUserLock(_msgSender(), _amountToken, (_oneMonthSec*6), (_oneMonthSec*18), 12);
        payable(owner).transfer( _tokenToBNB(_amountToken, _tokenPricePN));        
        
        emit Bought(_msgSender(), _amountToken);
    }

    function setSell(uint256 _min, uint8 _open) public onlyOwner {
        _minSell = _min;
        _openSell = _open; // open = 0, close > 0
    }

    uint256 private _minSell = 100*10**8;
    uint8 private _openSell = 1;
    function tokenToBnb(uint256 _amountToken) public notOwner {
        require(_openSell > 0, "Token to BNB is close!");
        require(_minSell <= _minSell, "Tokens need to be more than the minimum!");
        require(_tokenToBNB(_amountToken, tokenPrice) <= owner.balance, "Not enough BNB in the reserve");
        require(_amountToken > 0, "You need to sell at least some tokens");
        
        _balances[_msgSender()] -= _amountToken; // decrement the token balance of the seller
        _balances[owner] += _amountToken; // increment the token balance of this contract    
        payable(_msgSender()).transfer( _tokenToBNB(_amountToken, tokenPrice));
    
        emit Transfer(_msgSender(), owner, _amountToken);
        emit Sold(_msgSender(), _amountToken);
    }
}