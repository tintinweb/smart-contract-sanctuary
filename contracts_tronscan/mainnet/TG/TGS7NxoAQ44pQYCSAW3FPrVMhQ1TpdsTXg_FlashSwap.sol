//SourceUnit: Common.sol

pragma solidity ^0.5.8;


interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract TRC20 is Context, ITRC20 {
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

library Address {

    function isContract(address account) internal view returns (bool) {

        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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


library SafeTRC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ITRC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeIRC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ITRC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeTRC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    bool private _notEntered;
    constructor () internal {
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }
}



//SourceUnit: FlashSwap.sol

pragma solidity ^0.5.8;


import "./Common.sol";


interface ITokenSwap {

    function tokenToTrxTransferInput(
        uint256 tokens_sold,
        uint256 min_trx,
        uint256 deadline,
        address recipient)
    external returns (uint256);


    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_trx_bought,
        uint256 deadline,
        address recipient,
        address token_addr)
    external returns (uint256);

    function trxToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient)
    external payable returns(uint256);

    function tokenAddress() external view returns (address);

    function getTrxToTokenInputPrice(uint256 trx_sold)
    external view returns (uint256);

    function getTokenToTrxInputPrice(uint256 tokens_sold)
    external view returns (uint256);
}

contract FlashSwap is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeTRC20 for ITRC20;

    address payable public finance;
    uint256 public baseFee = 10000;
    uint256 public tradingFee;
    bool public paused = false;

    function pause() external onlyOwner  {
        paused = true;
    }

    function unPause() external onlyOwner {
        paused = false;
    }

    constructor () public {
        finance = msg.sender;
        tradingFee = 10;
    }

    function() external payable {
    }

    function setFinanceAddress(address payable _financeAddress) external onlyOwner returns(bool) {
        finance = _financeAddress;
        return true;
    }

    function setTradingFee(uint256 _value) external onlyOwner returns(bool) {
        tradingFee = _value;
        return true;
    }

    function getBaseInfo() public view returns (address payable, uint256) {
        return (finance, tradingFee);
    }

    function getSwapToken(address lpToken) public view returns(address) {
        return address(ITokenSwap(lpToken).tokenAddress());
    }

    // swap: tokenToTrx
    function tokenToTrxSwap(address swapToken, address lpToken, uint256 tokensSold, uint256 minTrx, address payable userAddress) external returns (uint256) {
        require(!paused, "the contract had been paused");
        require(swapToken == ITokenSwap(lpToken).tokenAddress(), "swapToken and lpToken not matched");
        require(tokensSold > 0 && minTrx > 0);

        ITRC20(swapToken).safeTransferFrom(msg.sender, address(this), tokensSold);
        uint256 _value = ITRC20(swapToken).allowance(address(this), address(lpToken));
        if (_value < tokensSold) {
            ITRC20(swapToken).safeApprove(address(lpToken), uint256(-1));
        }
        return tokenToTrx(swapToken, lpToken, tokensSold, minTrx, userAddress);
    }

    function tokenToTrx(address swapToken, address lpToken, uint256 tokensSold, uint256 minTrx, address payable userAddress) private nonReentrant returns (uint256) {
        uint256 _value = ITokenSwap(lpToken).tokenToTrxTransferInput(tokensSold, minTrx, block.timestamp.add(1800), address(this));
        if (_value == 0) {
            return 0;
        }
        uint256 _a = _value.mul(tradingFee).div(baseFee);
        uint _b = _value.sub(_a);
        if (_b > 0) {
            address(userAddress).transfer(_b);
        }
        if (_a > 0) {
            address(finance).transfer(_a);
        }
        return _b;
    }

    // swap: tokenToToken
    function tokenToTokenSwap(address swapToken, address lpToken, uint256 tokensSold, uint256 minTokensBought, uint256 minTrxBought, address userAddress, address targetToken) external returns (uint256) {
        require(!paused, "the contract had been paused");
        require(swapToken == ITokenSwap(lpToken).tokenAddress(), "swapToken and lpToken not matched");
        require(swapToken != targetToken, "swapToken not equal targetToken");
        require(tokensSold > 0 && minTokensBought > 0 && minTrxBought > 0);

        ITRC20(swapToken).safeTransferFrom(msg.sender, address(this), tokensSold);

        uint256 _value = ITRC20(swapToken).allowance(address(this), address(lpToken));
        if (_value < tokensSold) {
            ITRC20(swapToken).safeApprove(address(lpToken), uint256(-1));
        }

        return tokenToToken(swapToken, lpToken, tokensSold, minTokensBought, minTrxBought, userAddress, targetToken);
    }

    function tokenToToken(address swapToken, address lpToken, uint256 tokensSold, uint256 minTokensBought, uint256 minTrxBought, address userAddress, address targetToken) private nonReentrant  returns (uint256) {
        uint256 _value = ITokenSwap(lpToken).tokenToTokenTransferInput(tokensSold, minTokensBought, minTrxBought, block.timestamp.add(1800), address(this), targetToken);
        if (_value == 0) {
            return 0;
        }
        uint256 _a = _value.mul(tradingFee).div(baseFee);
        uint _b = _value.sub(_a);
        if (_b > 0) {
            ITRC20(targetToken).transfer(userAddress, _b);
        }
        if (_a > 0) {
            ITRC20(targetToken).transfer(finance, _a);
        }

        return _b;
    }

    // swap: trxToToken
    function trxToTokenSwap(address swapToken, address lpToken, uint256 minTokens, address userAddress) external payable returns (uint256) {
        require(!paused, "the contract had been paused");
        require(swapToken == ITokenSwap(lpToken).tokenAddress(), "swapToken and lpToken not matched");
        require(msg.value > 0 && minTokens > 0);

        return trxToToken(swapToken, lpToken, msg.value, minTokens, userAddress);
    }

    function trxToToken(address swapToken, address lpToken, uint256 trxAmounts, uint256 minTokens, address userAddress) private nonReentrant returns (uint256) {
        uint256 _value = ITokenSwap(lpToken).trxToTokenTransferInput.value(trxAmounts)(minTokens, block.timestamp.add(1800), address(this));
        if (_value == 0) {
            return 0;
        }
        uint256 _a = _value.mul(tradingFee).div(baseFee);
        uint _b = _value.sub(_a);
        if (_b > 0) {
            ITRC20(swapToken).transfer(userAddress, _b);
        }
        if (_a > 0) {
            ITRC20(swapToken).transfer(finance, _a);
        }
        return _b;
    }

    function getBalanceOfTrx(address user) public view returns(uint256) {
        require(user != address(0));
        return address(user).balance;
    }

    function getBalanceOfToken(address token, address user) public view returns(uint256) {
        require(token != address(0) && user != address(0));
        return ITRC20(token).balanceOf(user);
    }

    function getTrxToTokenPrice(address lpToken, uint256 trxAmount) public view returns(uint256) {
        require(lpToken != address(0) && trxAmount > 0);
        return ITokenSwap(lpToken).getTrxToTokenInputPrice(trxAmount);
    }

    function getTokenToTrxPrice(address lpToken, uint256 tokenAmount) public view returns(uint256) {
        require(lpToken != address(0) && tokenAmount > 0);
        return ITokenSwap(lpToken).getTokenToTrxInputPrice(tokenAmount);
    }

    function getTokenToTokenPrice(address sourceLpToken, address targetLpToken, uint256 sourceTokenAmount) public view returns(uint256) {
        require(sourceLpToken != address(0) && targetLpToken != address(0) && sourceTokenAmount > 0);
        uint256 _trxValue = ITokenSwap(sourceLpToken).getTokenToTrxInputPrice(sourceTokenAmount);
        return ITokenSwap(targetLpToken).getTrxToTokenInputPrice(_trxValue);
    }

    function rescueTrx(address payable toAddress, uint256 amount) external onlyOwner returns(bool) {
        require(toAddress != address(0) && amount> 0);
        address(toAddress).transfer(amount);
        return true;
    }

    function rescueToken(address toAddress, address token, uint256 amount) external onlyOwner returns(bool) {
        require(toAddress != address(0) && token != address(0) && amount > 0);
        ITRC20(token).transfer(toAddress, amount);
        return true;
    }


}