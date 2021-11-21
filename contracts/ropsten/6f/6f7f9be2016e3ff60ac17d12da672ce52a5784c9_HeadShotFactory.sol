/**
 *Submitted for verification at Etherscan.io on 2021-11-21
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

interface IHeadShotLedger {
    function owner() external view returns (address);
    function addTracker(uint256 code_) external returns (address);
    function getTrackerAddress(uint256 code_) external view returns (address);
    function getTrackerBalance(address address_, address account_) external view returns (uint256);

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

interface IHeadShotToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external pure returns (uint8);
}

contract HeadShotFactory is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => address) public _ledgerMap;
    address[] public _ledgerList;

    IHeadShotToken public headShotToken;

    IHeadShotLedger public headShotTicketLedger;
    IHeadShotLedger public headShotTokenLedger;

    address private _tokenAddress;
    uint256 private _tokenDecimals;
    uint256 private _tokenTax;

    address private _tokenLedgerAddress;
    address private _ticketLedgerAddress;

    address private _salesWalletAddress;

    constructor () {
        _tokenAddress = 0x16D70874ADb72d2b142a5367Bf2664e18B6f3e88; // in Ropsten
        _salesWalletAddress = 0xD7c891f24eEEeE63BB420B177E4cB52b1123FEEd; // in Ropsten
        headShotToken = IHeadShotToken(_tokenAddress);
        _tokenDecimals = headShotToken.decimals();
    }

    receive() external payable {}

    function walletSales() public view returns (address) {
        return _salesWalletAddress;
    }
    function setWalletSales(address payable wallet_) public virtual onlyOwner {
        _salesWalletAddress = wallet_;
    }

    /* Main Factory */
    function addressToken() public view returns (address) {
        return _tokenAddress;
    }
    function setAddressToken(address address_) public onlyOwner {
        require(address_ != address(0), "ERR: Transfer to the zero address");
        _tokenAddress = address_;
        headShotToken = IHeadShotToken(_tokenAddress);
        _tokenDecimals = headShotToken.decimals();
    }

    function ledgerToken() public view returns (address) {
        return _tokenLedgerAddress;
    }
    function setLedgerToken(address payable address_) public virtual onlyOwner {
        _tokenLedgerAddress = address_;
        addLedger(address_);
        headShotTokenLedger = IHeadShotLedger(_tokenLedgerAddress);
    }
    function ledgerTicket() public view returns (address) {
        return _ticketLedgerAddress;
    }
    function setLedgerTicket(address payable address_) public virtual onlyOwner {
        _ticketLedgerAddress = address_;
        addLedger(address_);
        headShotTicketLedger = IHeadShotLedger(_ticketLedgerAddress);
    }

    function tokenTax() public view returns (uint256) {
        return _tokenTax;
    }

    function setTokenTax(uint256 value_) public onlyOwner () {
        _tokenTax = value_;
    }

    function transferLedgerOwnership(address address_) public onlyOwner {
        /*
        headShotTicketLedger.transferOwnership(address_);
        headShotTokenLedger.transferOwnership(address_);
        */
        if (_ledgerList.length > 0){
            for (uint i = 0; i < _ledgerList.length; i++) {
                address _ledgers = _ledgerList[i];
                IHeadShotLedger headShotLedger = IHeadShotLedger(_ledgers);
                headShotLedger.transferOwnership(address_);
            }
        }
    }

    /* Other Ledger */
    function addLedger(address address_) public onlyOwner returns (bool) {
        _ledgerMap[address_] = address_;
        _ledgerList.push(address_);
        return true;
    }
    function getLedger(address address_) public view returns (address) {
        return _ledgerMap[address_];
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
        return headShotToken.balanceOf(account);
    }
    function addTicket(uint256 code_, string memory name_, string memory desc_, uint256 price_, uint256 max_) public onlyOwner {
        require(headShotTicketLedger.getTrackerAddress(code_) == address(0), "ERR: Item already exist");
        address trackerAddress = headShotTicketLedger.addTracker(code_);
        headShotTicketLedger.setTrackerFieldNumber(trackerAddress, "code", code_);
        headShotTicketLedger.setTrackerFieldString(trackerAddress, "name", name_);
        headShotTicketLedger.setTrackerFieldString(trackerAddress, "desc", desc_);
        headShotTicketLedger.setTrackerFieldNumber(trackerAddress, "price", price_);
        headShotTicketLedger.setTrackerFieldNumber(trackerAddress, "max", max_);
    }
    function addToken(uint256 ticket_, address address_, string memory network_, string memory name_, string memory symbol_, uint256 decimals_, string memory logo_)
    public {
        uint256 code_ = uint256(uint160(address_));
        address tokenAddress_ = headShotTokenLedger.getTrackerAddress(code_);
        require(tokenAddress_ == address(0), "ERR: Token already exist");
        address ticketAddress_ = headShotTicketLedger.getTrackerAddress(ticket_);
        require(headShotTicketLedger.getTrackerFieldNumber(ticketAddress_, "code") == ticket_, "ERR: Ticket not exist");
        address creator_ = _msgSender();

        bool isSell = false;
        if (creator_ == owner()){
            isSell = true;
        } else {
            //decrease ticket
            uint256 prevBalance = headShotTicketLedger.getTrackerBalance(ticketAddress_, creator_);
            if (prevBalance > 0){
                headShotTicketLedger.decreaseBalance(ticketAddress_, creator_, 1);
                uint256 nextBalance = headShotTicketLedger.getTrackerBalance(ticketAddress_, creator_);
                isSell = (nextBalance < prevBalance);
            }
        }
        if (isSell){
            address trackerAddress = headShotTokenLedger.addTracker(code_);
            headShotTokenLedger.setTrackerFieldAddress(trackerAddress, "address", address_);
            headShotTokenLedger.setTrackerFieldString(trackerAddress, "network", network_);
            headShotTokenLedger.setTrackerFieldString(trackerAddress, "name", name_);
            headShotTokenLedger.setTrackerFieldString(trackerAddress, "symbol", symbol_);
            headShotTokenLedger.setTrackerFieldNumber(trackerAddress, "decimals", decimals_);
            headShotTokenLedger.setTrackerFieldString(trackerAddress, "logo", logo_);
        }
    }
    function addSales(address ledger_, uint256 code_, uint256 category_, string memory name_, string memory desc_, uint256 price_) public {
        IHeadShotLedger merchantLedger = IHeadShotLedger(getLedger(ledger_));
        require(merchantLedger.getTrackerAddress(code_) == address(0), "ERR: Item already exist");
        address trackerAddress = merchantLedger.addTracker(code_);
        merchantLedger.setTrackerFieldNumber(trackerAddress, "code", code_);
        merchantLedger.setTrackerFieldNumber(trackerAddress, "category", category_);
        merchantLedger.setTrackerFieldString(trackerAddress, "name", name_);
        merchantLedger.setTrackerFieldString(trackerAddress, "desc", desc_);
        merchantLedger.setTrackerFieldNumber(trackerAddress, "price", price_);
    }
    function collect(uint256 code_, uint256 count_) public returns (uint256) {
        address address_ = headShotTicketLedger.getTrackerAddress(code_);
        require(headShotTicketLedger.getTrackerFieldNumber(address_, "code") == code_, "ERR: Ticket not exist");
        address _account = _msgSender();
        uint256 _tokenBalance = headShotToken.balanceOf(_account);
        uint256 _price = headShotTicketLedger.getTrackerFieldNumber(address_, "price");
        uint256 _maxBuy = headShotTicketLedger.getTrackerFieldNumber(address_, "max");
        uint256 _accountBal = headShotTicketLedger.getTrackerBalance(address_, _account);
        uint256 _newCount = count_;

        if (_maxBuy > 0){
            uint256 _balAfter = _accountBal.add(_newCount);
            uint256 maxCount_ = (_maxBuy.sub(_balAfter)).add(_newCount);
            if (_newCount > maxCount_){
                _newCount = maxCount_;
            }
        }

        require(_newCount > 0, "ERR: Over buy");
        uint256 _totalPay = _price.mul(_newCount).mul(10 ** _tokenDecimals);
        if (_tokenTax > 0){
            _totalPay = _totalPay.add(_totalPay.mul(_tokenTax).div(10 ** 2));
        }
        require(_tokenBalance >= _totalPay, "ERR: Not enough balances");

        bool pay1 = headShotToken.transferFrom(_account, address(this), _totalPay);
        bool pay2 = headShotToken.transferFrom(address(this), _salesWalletAddress, _totalPay);

        if (pay1 && pay2){
            return headShotTicketLedger.increaseBalance(address_, _account, _newCount);
        }
        return headShotTicketLedger.getTrackerBalance(address_, _account);
    }

    function buy(address ledger_, uint256 code_, uint256 count_) public returns (uint256) {
        IHeadShotLedger merchantLedger = IHeadShotLedger(getLedger(ledger_));
        address address_ = merchantLedger.getTrackerAddress(code_);
        require(merchantLedger.getTrackerFieldNumber(address_, "code") == code_, "ERR: Item not exist");

        address _account = _msgSender();
        uint256 _price = merchantLedger.getTrackerFieldNumber(address_, "price");
        require(count_ > 0, "ERR: Rejected, Over balance");
        uint256 _totalPay = _price.mul(count_).mul(10 ** _tokenDecimals);

        bool pay1 = headShotToken.transferFrom(_account, address(this), _totalPay);
        bool pay2 = headShotToken.transferFrom(address(this), _salesWalletAddress, _totalPay);

        if (pay1 && pay2){
            return merchantLedger.increaseBalance(address_, _account, count_);
        }
        return merchantLedger.getTrackerBalance(address_, _account);
    }

    function testBuy() public returns (bool) {
        uint256 _price = 100000;
        uint256 count_ = 1;
        uint256 _totalPay = _price.mul(count_).mul(10 ** _tokenDecimals);

        bool pay1 = headShotToken.transfer(address(this), _totalPay);
        bool pay2 = headShotToken.transferFrom(address(this), _salesWalletAddress, _totalPay);
        return pay2;
    }

    function voteUpToken(uint256 ticket_, address address_) public view returns (uint256) {
        address ticketAddress_ = headShotTicketLedger.getTrackerAddress(ticket_);
        require(headShotTicketLedger.getTrackerFieldNumber(ticketAddress_, "code") == ticket_, "ERR: Ticket not exist");
        uint256 code_ = uint256(uint160(address_));
        require(headShotTokenLedger.getTrackerAddress(code_) != address(0), "ERR: Token not exist");
        address tokenAddress_ = headShotTokenLedger.getTrackerAddress(code_);
        require(headShotTokenLedger.getTrackerFieldAddress(tokenAddress_, "address") == address_, "ERR: Wrong token address");
        address creator_ = _msgSender();
        bool isSell = false;
        if (creator_ == owner()){
            isSell = true;
        } else {
            //decrease ticket
            uint256 prevBalance = headShotTicketLedger.getTrackerBalance(ticketAddress_, creator_);
            if (prevBalance > 0){
                headShotTicketLedger.decreaseBalance(ticketAddress_, creator_, 1);
                uint256 nextBalance = headShotTicketLedger.getTrackerBalance(ticketAddress_, creator_);
                isSell = (nextBalance < prevBalance);
            }
        }
        if (isSell){
            return headShotTokenLedger.increaseBalance(tokenAddress_, creator_, 1);
        }
        return 0;
    }
    function voteDownToken(uint256 ticket_, address address_) public view returns (uint256) {
        address ticketAddress_ = headShotTicketLedger.getTrackerAddress(ticket_);
        require(headShotTicketLedger.getTrackerFieldNumber(ticketAddress_, "code") == ticket_, "ERR: Ticket not exist");
        uint256 code_ = uint256(uint160(address_));
        require(headShotTokenLedger.getTrackerAddress(code_) != address(0), "ERR: Token not exist");
        address tokenAddress_ = headShotTokenLedger.getTrackerAddress(code_);
        require(headShotTokenLedger.getTrackerFieldAddress(tokenAddress_, "address") == address_, "ERR: Wrong token address");
        address creator_ = _msgSender();
        bool isSell = false;
        if (creator_ == owner()){
            isSell = true;
        } else {
            //decrease ticket
            uint256 prevBalance = headShotTicketLedger.getTrackerBalance(ticketAddress_, creator_);
            if (prevBalance > 0){
                headShotTicketLedger.decreaseBalance(ticketAddress_, creator_, 1);
                uint256 nextBalance = headShotTicketLedger.getTrackerBalance(ticketAddress_, creator_);
                isSell = (nextBalance < prevBalance);
            }
        }
        if (isSell){
            return headShotTokenLedger.decreaseBalance(tokenAddress_, creator_, 1);
        }
        return 0;
    }

    function getTrackerFieldString(address ledger_, address address_, string memory key_)
    public view returns (string memory){
        IHeadShotLedger headShotLedger = IHeadShotLedger(ledger_);
        return headShotLedger.getTrackerFieldString(address_, key_);
    }
    function getTrackerFieldNumber(address ledger_, address address_, string memory key_)
    public view returns (uint256){
        IHeadShotLedger headShotLedger = IHeadShotLedger(ledger_);
        return headShotLedger.getTrackerFieldNumber(address_, key_);
    }
    function getTrackerFieldAddress(address ledger_, address address_, string memory key_)
    public view returns (address){
        IHeadShotLedger headShotLedger = IHeadShotLedger(ledger_);
        return headShotLedger.getTrackerFieldAddress(address_, key_);
    }

    function listTrackerTicket(uint limit_, uint page_) public view returns (address[] memory){
        return headShotTicketLedger.listTracker(limit_, page_);
    }
    function listTrackerToken(uint limit_, uint page_) public view returns (address[] memory){
        return headShotTokenLedger.listTracker(limit_, page_);
    }
    function listTrackerLedger(address ledger_, uint limit_, uint page_) public view returns (address[] memory){
        IHeadShotLedger merchantLedger = IHeadShotLedger(getLedger(ledger_));
        return merchantLedger.listTracker(limit_, page_);
    }
    function listTrxTicket(uint256 code_, address account_) public view
    returns (uint256[] memory, uint256[] memory, uint256[] memory){
        return headShotTicketLedger.listTrx(code_, account_);
    }
    function listTrxToken(address address_, address account_) public view
    returns (uint256[] memory, uint256[] memory, uint256[] memory){
        uint256 code_ = uint256(uint160(address_));
        return headShotTokenLedger.listTrx(code_, account_);
    }
    function listTrxLedger(address ledger_, uint256 code_, address account_) public view
    returns (uint256[] memory, uint256[] memory, uint256[] memory){
        IHeadShotLedger merchantLedger = IHeadShotLedger(getLedger(ledger_));
        return merchantLedger.listTrx(code_, account_);
    }
}