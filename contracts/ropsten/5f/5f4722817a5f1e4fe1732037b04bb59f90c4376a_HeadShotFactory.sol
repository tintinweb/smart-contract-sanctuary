// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./HeadShotLib.sol";

interface IHeadShotSalesLedger {
    function addSalesInfo(uint256 category_, uint256 code_, string memory name_,
        string memory desc_, uint256 price_, uint256 maxBuy_) external returns (bool);
    function getSalesCode(uint256 code_) external view returns (uint256);
    function getSalesPrice(uint256 code_) external view returns (uint256);
    function getAccountBalance(uint256 code_, address account_) external view returns (uint256);
    function buy(address account_, uint256 code_, uint256 count_) external returns (bool);
    function spend(address account_, uint256 code_, uint256 count_) external returns (bool);
    function getTrackerAddress(uint256 code_) external view returns (address);
    function getTrackerFieldString(uint256 code_, string memory key_) external view returns (string memory);
    function getTrackerFieldNumber(uint256 code_, string memory key_) external view returns (uint256);
    function getTrackerFieldAddress(uint256 code_, string memory key_) external view returns (address);
    function listSalesTrx(uint256 code_, address account_) external view returns (
        uint256[] memory, address[] memory, uint256[] memory, uint256[] memory);
    function listSalesPart1(uint limit_, uint page_) external view returns (
        uint256[] memory, uint256[] memory, string[] memory);
    function listSalesPart2(uint limit_, uint page_) external view returns (
        uint256[] memory, string[] memory, uint256[] memory);
    function listSalesTracker(uint limit_, uint page_) external view returns (address[] memory);
    function transferOwnership(address newOwner) external;
}

interface IHeadShotTokenLedger {
    function addTokenInfo(address address_, string memory network_, string memory name_,
        string memory symbol_, uint256 decimals_, uint256 created_, address creator_
    ) external view returns (bool);
    function getTokenAddress(address tokenAddress_) external view returns (address);
    function getAccountBalance(uint256 tokenAddress_, address account_) external view returns (uint256);
    function getTrackerAddress(address tokenAddress_) external view returns (address);
    function getTrackerFieldString(address tokenAddress_, string memory key_) external view returns (string memory);
    function getTrackerFieldNumber(address tokenAddress_, string memory key_) external view returns (uint256);
    function getTrackerFieldAddress(address tokenAddress_, string memory key_) external view returns (address);
    function listTokenPart1(uint limit_, uint page_) external view returns (
        address[] memory, string[] memory, string[] memory, uint256[] memory);
    function listTokenPart2(uint limit_, uint page_) external view returns (
        address[] memory, uint256[] memory, uint256[] memory, address[] memory);
    function listTokenTracker(uint limit_, uint page_) external view returns (address[] memory);
    function voteUp(address account_, address tokenAddress_) external returns (bool);
    function voteDown(address account_, address tokenAddress_) external returns (bool);
    function transferOwnership(address newOwner) external;
}

interface IHeadShotLedger {
    function getAccountBalance(uint256 code_, address account_) external view returns (uint256);
    function buy(address account_, uint256 code_, uint256 count_) external returns (bool);
    function spend(address account_, uint256 code_, uint256 count_) external returns (bool);
    function addTracker(uint256 code_, address trackerAddress_) external returns (bool);
    function getTrackerAddress(uint256 code_) external view returns (address);
    function getTrackerFieldString(uint256 code_, string memory key_) external view returns (string memory);
    function getTrackerFieldNumber(uint256 code_, string memory key_) external view returns (uint256);
    function getTrackerFieldAddress(uint256 code_, string memory key_) external view returns (address);
    function listTrx(uint256 code_, address account_) external view returns (
        uint256[] memory, address[] memory, uint256[] memory, uint256[] memory);
    function listTracker(uint limit_, uint page_) external view returns (address[] memory);
    function transferOwnership(address newOwner) external;
}

interface IHeadShotToken {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transferFromContract(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function decimals() external pure returns (uint8);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract HeadShotFactory is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;

    IHeadShotSalesLedger public headShotSalesLedger;
    IHeadShotTokenLedger public headShotTokenLedger;
    IHeadShotToken public headShotToken;

    mapping(address => address) public _ledgerMap;
    address[] public _ledgerList;

    address private _salesLedgerAddress;
    address private _tokenLedgerAddress;
    address private _tokenAddress;
    address private _salesWalletAddress;
    uint256 _decimals;

    constructor () {
        _salesLedgerAddress = 0x2D0873E39bA0C029200c1f560D28eE99966811E8; // in Ropsten
        headShotSalesLedger = IHeadShotSalesLedger(_salesLedgerAddress);

        _tokenLedgerAddress = 0x197Ef964af5714414f419E11DF6418FD471E5EDc; // in Ropsten
        headShotTokenLedger = IHeadShotTokenLedger(_tokenLedgerAddress);

        _tokenAddress = 0xcC9510f9cc3c736FB164A7CAB935DC79D0fa4909; // in Ropsten
        headShotToken = IHeadShotToken(_tokenAddress);
        _decimals = headShotToken.decimals();

        _salesWalletAddress = 0xD7c891f24eEEeE63BB420B177E4cB52b1123FEEd;
    }

    receive() external payable {}

    /* Main Factory */
    function walletLedgerOfSales() public view returns (address) {
        return _salesLedgerAddress;
    }
    function walletLedgerOfToken() public view returns (address) {
        return _tokenLedgerAddress;
    }
    function setAddressSalesLedger(address payable newWallet_) public onlyOwner {
        require(newWallet_ != address(0), "ERR: Transfer to the zero address");
        _salesLedgerAddress = newWallet_;
        headShotSalesLedger = IHeadShotSalesLedger(_salesLedgerAddress);
    }
    function setAddressTokenLedger(address payable newWallet_) public onlyOwner {
        require(newWallet_ != address(0), "ERR: Transfer to the zero address");
        _tokenLedgerAddress = newWallet_;
        headShotTokenLedger = IHeadShotTokenLedger(_tokenLedgerAddress);
    }
    function walletSales() public view returns (address) {
        return _salesWalletAddress;
    }
    function setWalletSales(address payable newWallet_) public virtual onlyOwner {
        _salesWalletAddress = newWallet_;
    }
    function setAddressToken(address payable address_) public onlyOwner {
        require(address_ != address(0), "ERR: Transfer to the zero address");
        _tokenAddress = address_;
        headShotToken = IHeadShotToken(_tokenAddress);
        _decimals = headShotToken.decimals();
    }
    function addLedger(address ledgerAddress_) public onlyOwner returns (bool) {
        _ledgerMap[ledgerAddress_] = ledgerAddress_;
        _ledgerList.push(ledgerAddress_);
        return true;
    }
    function getLedgerAddress(address ledgerAddress_) public view returns (address) {
        return _ledgerMap[ledgerAddress_];
    }
    function listLedger(uint limit_, uint page_) public view onlyOwner returns (address[] memory) {
        uint listCount = _ledgerList.length;

        uint rowStart = 0;
        uint rowEnd = 0;
        uint rowCount = listCount;
        bool pagination = false;

        if (limit_ > 0 && page_ > 0){
            rowStart = (page_ - 1) * limit_;
            rowEnd = (rowStart + limit_) - 1;
            pagination = true;
            rowCount = limit_;
        }

        address[] memory _ledgers = new address[](rowCount);

        uint id = 0;
        uint j = 0;

        if (listCount > 0){
            for (uint i = 0; i < listCount; i++) {
                bool insert = !pagination;
                if (pagination){
                    if (j >= rowStart && j <= rowEnd){
                        insert = true;
                    }
                }
                if (insert){
                    _ledgers[id] = _ledgerList[i];
                    id++;
                }
                j++;
            }
        }

        return (_ledgers);
    }

    /* Features */
    function transferSalesOwnership(address newOwner) public onlyOwner {
        return headShotSalesLedger.transferOwnership(newOwner);
    }
    function transferTokenOwnership(address newOwner) public onlyOwner {
        return headShotTokenLedger.transferOwnership(newOwner);
    }
    function transferGeneralOwnership(address address_, address newOwner) public onlyOwner {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.transferOwnership(newOwner);
    }
    function addSales(uint256 category_, uint256 code_, string memory name_,
        string memory desc_, uint256 price_, uint256 maxBuy_) public onlyOwner returns (bool){
        require(headShotSalesLedger.getSalesCode(code_) != code_, "ERR: Sales already exist");
        require(_salesWalletAddress != address(0), "ERR: No sales wallet exist");
        return headShotSalesLedger.addSalesInfo(category_, code_, name_, desc_, price_.mul(10 ** _decimals), maxBuy_);
    }
    function collect(uint256 code_, uint256 count_) public returns (bool) {
        if (headShotSalesLedger.getSalesCode(code_) == code_){
            address _account = _msgSender();
            uint256 _price = headShotSalesLedger.getTrackerFieldNumber(code_, "price");
            uint256 _maxBuy = headShotSalesLedger.getTrackerFieldNumber(code_, "maxBuy");
            uint256 _accountBal = headShotSalesLedger.getAccountBalance(code_, _account);
            uint256 _newCount = count_;

            if (_maxBuy > 0){
                uint256 _balAfter = _accountBal.add(_newCount);
                uint256 maxCount_ = (_maxBuy.sub(_balAfter)).add(_newCount);
                if (_newCount > maxCount_){
                    _newCount = maxCount_;
                }
            }

            require(_newCount > 0, "ERR: Rejected, Over balance");
            uint256 _totalPay = _price.mul(_newCount);
            headShotToken.transferFromContract(_account, _salesWalletAddress, _totalPay);
            return headShotSalesLedger.buy(_account, code_, _newCount);
        }
        return false;
    }

    function check(uint256 code_, uint256 count_) public view returns (address, address, uint256, uint256, uint256) {
        if (headShotSalesLedger.getSalesCode(code_) == code_){
            address _account = _msgSender();
            uint256 _price = headShotSalesLedger.getTrackerFieldNumber(code_, "price");
            uint256 _maxBuy = headShotSalesLedger.getTrackerFieldNumber(code_, "maxBuy");
            uint256 _accountBal = headShotSalesLedger.getAccountBalance(code_, _account);
            uint256 _newCount = count_;

            if (_maxBuy > 0){
                uint256 _balAfter = _accountBal.add(_newCount);
                uint256 maxCount_ = (_maxBuy.sub(_balAfter)).add(_newCount);
                if (_newCount > maxCount_){
                    _newCount = maxCount_;
                }
            }
            uint x = headShotToken.balanceOf(_account);
            uint y = headShotToken.balanceOf(address(this));
            //uint256 _totalPay = _price.mul(_newCount);
            return (_account, _salesWalletAddress, _price, x, y);
        }
        return (address(0), address(0), 0, 0, 0);
    }

    function addToken(uint256 code_, address address_, string memory network_,
        string memory name_, string memory symbol_, uint256 decimals_) public onlyOwner returns (bool) {
        require(code_ != 0, "ERR: Zero code");
        require(address_ != address(0), "ERR: Zero address");
        require(headShotTokenLedger.getTokenAddress(address_) != address_, "ERR: Token already exist");
        address tokenCreator_ = _msgSender();
        bool isSell = false;
        if (tokenCreator_ == owner()){
            isSell = true;
        } else {
            isSell = headShotSalesLedger.spend(tokenCreator_, code_, 1);
        }
        uint256 tokenCreated_ = block.timestamp;
        if (isSell){
            return headShotTokenLedger.addTokenInfo(
                address_, network_, name_, symbol_, decimals_, tokenCreated_, tokenCreator_
            );
        }
        return false;
    }
    function voteUp(address tokenAddress_) public returns (bool) {
        require(tokenAddress_ != address(0), "ERR: Zero address");
        if (headShotTokenLedger.getTokenAddress(tokenAddress_) == tokenAddress_){
            headShotTokenLedger.voteUp(_msgSender(), tokenAddress_);
            return true;
        }
        return false;
    }
    function voteDown(address tokenAddress_) public returns (bool) {
        require(tokenAddress_ != address(0), "ERR: Zero address");
        if (headShotTokenLedger.getTokenAddress(tokenAddress_) == tokenAddress_){
            headShotTokenLedger.voteDown(_msgSender(), tokenAddress_);
            return true;
        }
        return false;
    }

    /* Sales Ledger */
    function getSalesCode(uint256 code_) public view returns (uint256){
        return headShotSalesLedger.getSalesCode(code_);
    }
    function getSalesPrice(uint256 code_) public view returns (uint256){
        return headShotSalesLedger.getSalesPrice(code_);
    }
    function getSalesTrackerAddress(uint256 code_) external view returns (address){
        return headShotSalesLedger.getTrackerAddress(code_);
    }
    function getSalesAccountBalance(uint256 code_, address account_) public view returns (uint256){
        return headShotSalesLedger.getAccountBalance(code_, account_);
    }
    function salesBuy(address account_, uint256 code_, uint256 count_) public returns (bool){
        return headShotSalesLedger.buy(account_, code_, count_);
    }
    function salesSpend(address account_, uint256 code_, uint256 count_) public returns (bool){
        return headShotSalesLedger.spend(account_, code_, count_);
    }
    function getSalesTrackerFieldString(uint256 code_, string memory key_) public view returns (string memory){
        return headShotSalesLedger.getTrackerFieldString(code_, key_);
    }
    function getSalesTrackerFieldNumber(uint256 code_, string memory key_) public view returns (uint256){
        return headShotSalesLedger.getTrackerFieldNumber(code_, key_);
    }
    function getSalesTrackerFieldAddress(uint256 code_, string memory key_) public view returns (address){
        return headShotSalesLedger.getTrackerFieldAddress(code_, key_);
    }
    function listSalesTrx(uint256 code_, address account_) public view returns (
        uint256[] memory, address[] memory, uint256[] memory, uint256[] memory){
        return headShotSalesLedger.listSalesTrx(code_, account_);
    }
    function listSalesPart1(uint limit_, uint page_) public view returns (
        uint256[] memory, uint256[] memory, string[] memory){
        return headShotSalesLedger.listSalesPart1(limit_, page_);
    }
    function listSalesPart2(uint limit_, uint page_) public view returns (
        uint256[] memory, string[] memory, uint256[] memory){
        return headShotSalesLedger.listSalesPart2(limit_, page_);
    }
    function listSalesTracker(uint limit_, uint page_) public view returns (address[] memory){
        return headShotSalesLedger.listSalesTracker(limit_, page_);
    }

    /* Token Ledger */
    function listTokenPart1(uint limit_, uint page_) public view returns (
        address[] memory, string[] memory, string[] memory, uint256[] memory){
        return headShotTokenLedger.listTokenPart1(limit_, page_);
    }
    function listTokenPart2(uint limit_, uint page_) public view returns (
        address[] memory, uint256[] memory, uint256[] memory, address[] memory){
        return headShotTokenLedger.listTokenPart2(limit_, page_);
    }
    function listTokenTracker(uint limit_, uint page_) public view returns (address[] memory){
        return headShotTokenLedger.listTokenTracker(limit_, page_);
    }
    function getTokenAddress(address tokenAddress_) public view returns (address){
        return headShotTokenLedger.getTokenAddress(tokenAddress_);
    }
    function getTokenTrackerAddress(address tokenAddress_) public view returns (address) {
        return headShotTokenLedger.getTrackerAddress(tokenAddress_);
    }
    function getTokenAccountBalance(uint256 tokenAddress_, address account_) public view returns (uint256){
        return headShotTokenLedger.getAccountBalance(tokenAddress_, account_);
    }
    function getTokenTrackerFieldString(address address_, string memory key_) public view returns (string memory){
        return headShotTokenLedger.getTrackerFieldString(address_, key_);
    }
    function getTokenTrackerFieldNumber(address address_, string memory key_) public view returns (uint256){
        return headShotTokenLedger.getTrackerFieldNumber(address_, key_);
    }
    function getTokenTrackerFieldAddress(address address_, string memory key_) public view returns (address){
        return headShotTokenLedger.getTrackerFieldAddress(address_, key_);
    }

    /* General Ledger */
    function getGeneralTrackerFieldString(address address_, uint256 code_, string memory key_) public view returns (string memory) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.getTrackerFieldString(code_, key_);
    }
    function getGeneralTrackerFieldNumber(address address_, uint256 code_, string memory key_) public view returns (uint256) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.getTrackerFieldNumber(code_, key_);
    }
    function getGeneralTrackerFieldAddress(address address_, uint256 code_, string memory key_) public view returns (address) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.getTrackerFieldAddress(code_, key_);
    }
    function getGeneralAccountBalance(address address_, uint256 code_, address account_) public view returns (uint256) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.getAccountBalance(code_, account_);
    }
    function getGeneralTrackerAddress(address address_, uint256 code_) public view returns (address) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.getTrackerAddress(code_);
    }
    function generalBuy(address address_, address account_, uint256 code_, uint256 count_) public onlyOwner returns (bool) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.buy(account_, code_, count_);
    }
    function generalSpend(address address_, address account_, uint256 code_, uint256 count_) public onlyOwner returns (bool) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.spend(account_, code_, count_);
    }
    function addGeneralTracker(address address_, uint256 code_, address trackerAddress_) public onlyOwner returns (bool) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.addTracker(code_, trackerAddress_);
    }
    function listGeneralTracker(address address_, uint limit_, uint page_) public view onlyOwner returns (address[] memory) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.listTracker(limit_, page_);
    }
    function listGeneralTrx(address address_, uint256 code_, address account_) public view returns (
        uint256[] memory, address[] memory, uint256[] memory, uint256[] memory) {
        require(_ledgerMap[address_] == address_, "ERR: Ledger not found");
        IHeadShotLedger headShotLedger = IHeadShotLedger(address_);
        return headShotLedger.listTrx(code_, account_);
    }
}