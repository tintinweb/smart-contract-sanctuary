// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./HeadShotLib.sol";

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
    function transferFromContract(address sender, uint256 amount) external returns (bool);
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

    address private _tokenLedgerAddress;
    address private _ticketLedgerAddress;

    constructor () {
        _tokenAddress = 0x16D70874ADb72d2b142a5367Bf2664e18B6f3e88; // in Ropsten
        headShotToken = IHeadShotToken(_tokenAddress);
        _tokenDecimals = headShotToken.decimals();
    }

    receive() external payable {}

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
        if (headShotTicketLedger.getTrackerFieldNumber(address_, "code") == code_){
            address _account = _msgSender();
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

            require(_newCount > 0, "ERR: Rejected, Over balance");
            uint256 _totalPay = _price.mul(_newCount).mul(10 ** _tokenDecimals);
            headShotToken.transferFromContract(_account, _totalPay);
            return headShotTicketLedger.increaseBalance(address_, _account, _newCount);
        }
        return 0;
    }
    function buy(address ledger_, uint256 code_, uint256 count_) public returns (uint256) {
        IHeadShotLedger merchantLedger = IHeadShotLedger(getLedger(ledger_));
        address address_ = merchantLedger.getTrackerAddress(code_);
        if (merchantLedger.getTrackerFieldNumber(address_, "code") == code_){
            address _account = _msgSender();
            uint256 _price = merchantLedger.getTrackerFieldNumber(address_, "price");
            require(count_ > 0, "ERR: Rejected, Over balance");
            uint256 _totalPay = _price.mul(count_).mul(10 ** _tokenDecimals);
            headShotToken.transferFromContract(_account, _totalPay);
            return merchantLedger.increaseBalance(address_, _account, count_);
        }
        return 0;
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