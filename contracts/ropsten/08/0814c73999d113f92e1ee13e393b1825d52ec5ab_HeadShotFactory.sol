/**
 *Submitted for verification at Etherscan.io on 2021-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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

library ConvertString {
    function toStr(uint256 value) internal pure returns (string memory str){
        if (value == 0) return "0";
        uint256 j = value;
        uint256 length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bStr = new bytes(length);
        uint256 k = length;
        j = value;
        while (j != 0){
            bStr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bStr);
    }
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ILedger {
    function owner() external view returns (address);
    function addTracker(uint256 code_) external returns (address);
    function getTrackerAddress(uint256 code_) external view returns (address);
    function getTrackerBalance(address address_, address account_) external view returns (uint256);
    function getTrackerSupply(address address_) external view returns (uint256);

    function getTrackerFieldString(address address_, string memory key_) external view returns (string memory);
    function getTrackerFieldNumber(address address_, string memory key_) external view returns (uint256);
    function getTrackerFieldAddress(address address_, string memory key_) external view returns (address);

    function setTrackerFieldString(address address_, string memory key_, string memory value_) external;
    function setTrackerFieldNumber(address address_, string memory key_, uint256 value_) external;
    function setTrackerFieldAddress(address address_, string memory key_, address value_) external;

    function increaseBalance(address address_, address account_, uint256 balance_) external view returns (uint256);
    function decreaseBalance(address address_, address account_, uint256 balance_) external view returns (uint256);

    function listTracker(uint limit_, uint page_) external view returns (address[] memory);
    function listTrx(uint256 code_, address account_) external view returns (
        uint256[] memory, uint256[] memory, uint256[] memory
    );
    function transferOwnership(address newOwner) external;
}

interface IToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external pure returns (uint8);
}

contract HeadShotFactory is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => address) public _ledgerMap;
    address[] public _ledgerList;

    IToken public iToken;

    address private _tokenAddress;
    uint256 private _tokenDecimals;
    uint256 private _tokenTax;

    address private _tokenLedgerAddress;
    address private _ticketLedgerAddress;

    constructor () {
        _tokenAddress = 0x16D70874ADb72d2b142a5367Bf2664e18B6f3e88; // in Ropsten
        //_poolWallet = 0xD7c891f24eEEeE63BB420B177E4cB52b1123FEEd; // in Ropsten
        iToken = IToken(_tokenAddress);
        _tokenDecimals = iToken.decimals();
    }

    receive() external payable {}

    /* Main Factory */
    function addressToken() public view returns (address) {
        return _tokenAddress;
    }
    function setAddressToken(address address_) public onlyOwner {
        require(address_ != address(0), "ERR: Transfer to the zero address");
        _tokenAddress = address_;
        iToken = IToken(_tokenAddress);
        _tokenDecimals = iToken.decimals();
    }

    function tokenTax() public view returns (uint256) {
        return _tokenTax;
    }
    function setTokenTax(uint256 value_) public onlyOwner () {
        _tokenTax = value_;
    }

    function transferLedgerOwnership(address address_) public onlyOwner {
        if (_ledgerList.length > 0){
            for (uint i = 0; i < _ledgerList.length; i++) {
                address _ledgers = _ledgerList[i];
                ILedger iLedger = ILedger(_ledgers);
                iLedger.transferOwnership(address_);
            }
        }
    }

    /* Other Ledger */
    function addLedger(address address_, address pool_) public onlyOwner returns (bool) {
        _ledgerMap[address_] = pool_;
        _ledgerList.push(address_);
        return true;
    }
    function getLedgerPool(address address_) public view returns (address) {
        return _ledgerMap[address_];
    }
    function setLedgerPool(address address_, address payable pool_) public virtual onlyOwner {
        _ledgerMap[address_] = pool_;
    }
    function listLedger() public view returns (address[] memory) {
        uint rowCount = _ledgerList.length;
        address[] memory _ledgers = new address[](rowCount);
        if (rowCount > 0){
            for (uint i = 0; i < rowCount; i++) {
                _ledgers[i] = _ledgerList[i];
            }
        }
        return (_ledgers);
    }

    /* Features */
    function tokenBalanceOf(address account) public view returns (uint256) {
        return iToken.balanceOf(account);
    }
    function add(
        address ledger_,
        uint256 code_,
        uint256 category_,
        string memory name_,
        string memory desc_,
        uint256 price_,
        uint256 max_,
        uint256 startDate_,
        uint256 endDate_
    ) public {
        ILedger iLedger = ILedger(ledger_);
        require(iLedger.getTrackerAddress(code_) == address(0), "ERR: Item already exist");
        address trackerAddress = iLedger.addTracker(code_);
        iLedger.setTrackerFieldNumber(trackerAddress, "code", code_);
        iLedger.setTrackerFieldNumber(trackerAddress, "category", category_);
        iLedger.setTrackerFieldString(trackerAddress, "name", name_);
        iLedger.setTrackerFieldString(trackerAddress, "desc", desc_);
        iLedger.setTrackerFieldNumber(trackerAddress, "price", price_);
        iLedger.setTrackerFieldNumber(trackerAddress, "max", max_);
        iLedger.setTrackerFieldNumber(trackerAddress, "start", startDate_);
        iLedger.setTrackerFieldNumber(trackerAddress, "end", endDate_);
    }
    function calc(address ledger_, uint256 code_, uint256 count_) public view
    returns (uint256, uint256) {
        ILedger iLedger = ILedger(ledger_);
        address tracker_ = iLedger.getTrackerAddress(code_);
        require(iLedger.getTrackerFieldNumber(tracker_, "code") == code_, "ERR: Ticket not exist");

        address _account = _msgSender();
        uint256 _tokenBalance = iToken.balanceOf(_account);
        uint256 _price = iLedger.getTrackerFieldNumber(tracker_, "price");
        uint256 _maxBuy = iLedger.getTrackerFieldNumber(tracker_, "max");
        uint256 _startDate = iLedger.getTrackerFieldNumber(tracker_, "start");
        uint256 _endDate = iLedger.getTrackerFieldNumber(tracker_, "end");
        uint256 _accountBal = iLedger.getTrackerBalance(tracker_, _account);

        uint256 _count = count_;

        if (_startDate > 0 || _endDate > 0){
            require(block.timestamp >= _startDate && block.timestamp <= _endDate, "ERR: Over time");
        }

        if (_maxBuy > 0){
            uint256 _balAfter = _accountBal.add(_count);
            uint256 maxCount_ = (_maxBuy.sub(_balAfter)).add(_count);
            if (_count > maxCount_){
                _count = maxCount_;
            }
        }

        require(_count > 0, "ERR: Over buy, decrease count");
        uint256 _subTotal = _price.mul(_count).mul(10 ** _tokenDecimals);
        uint256 _totalPay = _subTotal;

        if (_tokenTax > 0){
            uint256 _totalTax = _subTotal.mul(_tokenTax).div(10 ** 2);
            _totalPay = _subTotal.add(_totalTax);
        }

        _totalPay = _totalPay.add(uint256(block.timestamp));
        require(_tokenBalance >= _totalPay, "ERR: Insufficient balances");

        return (_count, _totalPay);
    }
    function collect(address ledger_, uint256 code_, uint256 count_, uint256 amount_) public returns (uint256) {
        ILedger iLedger = ILedger(ledger_);
        address tracker_ = iLedger.getTrackerAddress(code_);
        require(iLedger.getTrackerFieldNumber(tracker_, "code") == code_, "ERR: Item not exist");
        address _account = _msgSender();
        iToken.approve(address(this), amount_);
        address _pool = getLedgerPool(ledger_);
        bool pay = iToken.transfer(_pool, amount_);
        if (pay){
            return iLedger.increaseBalance(tracker_, _account, count_);
        }
        return iLedger.getTrackerBalance(tracker_, _account);
    }
    function spend(address ledger_, uint256 code_, uint256 count_) public view returns (uint256) {
        ILedger iLedger = ILedger(ledger_);
        address tracker_ = iLedger.getTrackerAddress(code_);
        require(iLedger.getTrackerFieldNumber(tracker_, "code") == code_, "ERR: Item not exist");
        address _account = _msgSender();
        return iLedger.decreaseBalance(tracker_, _account, count_);
    }
    function withdraw(address ledger_, uint256 code_, address wallet_) public onlyOwner {
        ILedger iLedger = ILedger(ledger_);
        address tracker_ = iLedger.getTrackerAddress(code_);
        uint256 _endDate = iLedger.getTrackerFieldNumber(tracker_, "end");
        uint256 _price = iLedger.getTrackerFieldNumber(tracker_, "price");
        if (_endDate > 0){
            require(block.timestamp <= _endDate, "ERR: Amount locked");
        }
        uint _balance = iLedger.getTrackerSupply(ledger_);
        uint _amount = _balance.mul(_price);
        uint _total = 0;
        if (_tokenTax > 0){
            _total = _amount.mul(uint256(100).sub(_tokenTax)).div(10 ** 2);
        }
        iToken.transferFrom(ledger_, wallet_, _total);
    }
    function getFieldString(address ledger_, address address_, string memory key_)
    public view returns (string memory){
        ILedger iLedger = ILedger(ledger_);
        return iLedger.getTrackerFieldString(address_, key_);
    }
    function getFieldNumber(address ledger_, address address_, string memory key_)
    public view returns (uint256){
        ILedger iLedger = ILedger(ledger_);
        return iLedger.getTrackerFieldNumber(address_, key_);
    }
    function getFieldAddress(address ledger_, address address_, string memory key_)
    public view returns (address){
        ILedger iLedger = ILedger(ledger_);
        return iLedger.getTrackerFieldAddress(address_, key_);
    }
    function listTracker(address ledger_, uint limit_, uint page_) public view returns (address[] memory){
        ILedger iLedger = ILedger(ledger_);
        return iLedger.listTracker(limit_, page_);
    }
    function listTrx(address ledger_, uint256 code_, address account_) public view
    returns (uint256[] memory, uint256[] memory, uint256[] memory){
        ILedger iLedger = ILedger(ledger_);
        return iLedger.listTrx(code_, account_);
    }
}