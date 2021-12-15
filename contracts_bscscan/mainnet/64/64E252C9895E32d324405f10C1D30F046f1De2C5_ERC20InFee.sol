/**
 *Submitted for verification at BscScan.com on 2021-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;


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
    function _transfer(address sender, address recipient, uint amount) internal{
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


contract ERC20InFee is  Context, IERC20{
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint;

    string private _name = 'TestToken';
    string private _symbol = 'Test';
    uint8 private _decimals = 18;
    uint private _totalSupply;

    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    //inFe, outFe
    mapping (address => uint) private _inFee;
    mapping (address => uint) private _outFee;
    mapping (address => bool) private _excludeFee;

    address private _fee2Address = 0xE90C163b377CfA37bC74E234b832a806d559a63a;
    address private _fee3Address = 0xc4815C5A75482Fb7F71a43d102d72939D9B9b09c;

    //dividends
    mapping (address => uint) private _dividendsIndex;
    mapping (uint => address) private _dividendsList;
    uint private _dividendsLength = 0;
    uint private _dividendsAddTimes = 0;

    uint private _dividendsLimit = 10 * 10 ** uint256(decimals());

    //owner
    address private _master;

    //constructor
    constructor () public{
        _master = msg.sender;
        _mint(msg.sender, 3380000 * (10 ** uint256(decimals())));
    }
    function _mint(address account, uint amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint amount) internal{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        //reduce
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        //add
        uint addValue = amount;
        if (!(_excludeFee[sender] || _excludeFee[recipient])) {
            addValue = amount.div(100).mul((100-_outFee[sender]-_inFee[recipient]));
        }
        if (addValue < 0) {
            addValue = 0;
        }

        _balances[recipient] = _balances[recipient].add(addValue);

        //if had fee
        uint fee = amount.sub(addValue);
        //if bigger then 1
        if (fee >= 10 ** uint256(decimals())) {

            //Guess which will cost more gas?
            uint pieces = fee.div(16);
            //burn
            _totalSupply = _totalSupply.sub(pieces.mul(5));//燃烧

            //判断本次转账是否分红
            _sendDividends(pieces.mul(5), sender);

            //two public address
            _balances[_fee2Address] = _balances[_fee2Address].add(pieces.mul(2));
            _balances[_fee3Address] = _balances[_fee3Address].add(pieces.mul(3));
        }

        //about dividends
        if (_balances[recipient] >= _dividendsLimit) {
            _addDividends(recipient);
        }
        if (_balances[sender] < _dividendsLimit) {
            _removeDividends(sender);
        }

        emit Transfer(sender, recipient, amount);
    }

    function _addDividends(address recipient) internal {
        //add if not add
        if (_dividendsIndex[recipient] == 0) {
            _dividendsAddTimes = _dividendsAddTimes + 1;
            _dividendsLength = _dividendsLength + 1;

            _dividendsIndex[recipient] = _dividendsAddTimes;
            _dividendsList[_dividendsAddTimes] = recipient;
        }
    }

    function _removeDividends(address sender) internal {
        //remove if in record
        if (_dividendsIndex[sender] > 0) {
            _dividendsLength = _dividendsLength - 1;

            _dividendsList[_dividendsIndex[sender]] = address(0x0);
            _dividendsIndex[sender] = 0;
        }
    }

    function _sendDividends(uint amount, address sender) internal {
        if (_dividendsLength == 0) {
            return;
        }
        uint oneValue = amount.div(_dividendsLength);
        for (uint i = 1; i <= _dividendsLength; i++) {
            //the sender never enjoy the dividends
            if (_dividendsList[i] == sender && i == _dividendsIndex[_dividendsList[i]]) {
                _totalSupply = _totalSupply.sub(oneValue);//burn
                continue;
            }
            if (i == _dividendsIndex[_dividendsList[i]]) {
                _balances[_dividendsList[i]] = _balances[_dividendsList[i]].add(oneValue);
            }
        }
    }

    function setInFee(address account, uint fee) public returns (bool) {
        require(msg.sender == _master && fee < 100, 'Error!');
        _inFee[account] = fee;
        return true;
    }

    function getInFee(address account) public view returns (uint) {
        return _inFee[account];
    }

    function setOutFee(address account, uint fee) public returns (bool) {
        require(msg.sender == _master && fee < 100, 'Error!');
        _outFee[account] = fee;
        return true;
    }

    function getOutFee(address account) public view returns (uint) {
        return _outFee[account];
    }

    function setDividendsLimit(uint limit) public returns (bool) {
        require(msg.sender == _master, 'Error!');
        _dividendsLimit = limit;
        return true;
    }

    function getDividendsLimit() public view returns (uint) {
        return _dividendsLimit;
    }

    function getDividendsLength() public view returns (uint) {
        return _dividendsLength;
    }

    function changeMaster(address masterNew) public returns (bool) {
        require(msg.sender == _master, 'Error!');
        _master = masterNew;
        return true;
    }

    function setExcludeFee(address account, bool boolValue) public returns (bool) {
        require(msg.sender == _master, 'Error!');
        _excludeFee[account] = boolValue;
        return true;
    }

    function setFee2Address(address newAddress) public returns (bool) {
        require(msg.sender == _master, 'Error!');
        _fee2Address = newAddress;
        return true;
    }
    function getFee2Address() public view returns (address) {
        return _fee2Address;
    }
    function setFee3Address(address newAddress) public returns (bool) {
        require(msg.sender == _master, 'Error!');
        _fee3Address = newAddress;
        return true;
    }
    function getFee3Address() public view returns (address) {
        return _fee3Address;
    }
}