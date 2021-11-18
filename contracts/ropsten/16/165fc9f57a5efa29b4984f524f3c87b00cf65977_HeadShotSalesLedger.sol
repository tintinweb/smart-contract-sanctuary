// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./HeadShotTracker.sol";

contract HeadShotSalesLedger is ERC20, Ownable {
    using SafeMath for uint256;
    using ConvertString for uint256;
    using Address for address;

    uint256 private _totalSupply;

    struct SalesInfo {
        uint256 category;
        uint256 code;
        string name;
        string desc;
        uint256 price;
    }

    mapping (address => uint256) private _balances;

    mapping(uint256 => SalesInfo) public _salesMap;
    mapping(uint256 => address) public _trackerMap;

    address[] public _trackerList;
    SalesInfo[] public _salesList;

    constructor() ERC20("HeadShotSalesLedger", "HSSL", 0) {}

    receive() external payable {}

    function totalSupply() public view override returns (uint256) {
        return _trackerList.length;
    }
    /*
    function balanceOf(address account) public view override returns (uint256) {
        return _trackerList.length;
    }
    */
    function transfer(address, uint256) public pure override returns (bool) {
        revert("HSSF: method not implemented");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("HSSF: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("HSSF: method not implemented");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("HSSF: method not implemented");
    }

    function addSalesInfo(uint256 category_, uint256 code_, string memory name_,
        string memory desc_, uint256 price_, uint256 maxBuy_) public onlyOwner returns (bool) {
        string memory codeString = ConvertString.toStr(code_);
        string memory trackerName = string(abi.encodePacked("HeadShotTracker_", codeString));
        string memory trackerSymbol = string(abi.encodePacked("HSTracker_", codeString));
        HeadShotTracker headShotTracker = new HeadShotTracker(trackerName, trackerSymbol);

        headShotTracker.setFieldNumber("code", code_);
        headShotTracker.setFieldNumber("category", category_);
        headShotTracker.setFieldString("name", name_);
        headShotTracker.setFieldString("desc", desc_);
        headShotTracker.setFieldNumber("price", price_);
        headShotTracker.setFieldNumber("maxBuy", maxBuy_);

        SalesInfo memory salesInfo = SalesInfo(category_, code_, name_, desc_, price_);
        _salesMap[code_] = salesInfo;
        _salesList.push(salesInfo);

        address trackerAddress = address(headShotTracker);
        addTrackerInfo(code_, trackerAddress);
        return true;
    }

    function getTrackerFieldString(uint256 code_, string memory key_) public view returns (string memory) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.getFieldString(key_);
    }

    function getTrackerFieldNumber(uint256 code_, string memory key_) public view returns (uint256) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.getFieldNumber(key_);
    }

    function getAccountBalance(uint256 code_, address account_) public view returns (uint256) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.getAccountBalance(account_);
    }

    function getTrackerFieldAddress(uint256 code_, string memory key_) public view returns (address) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.getFieldAddress(key_);
    }

    function buy(address account_, uint256 code_, uint256 count_) public onlyOwner returns (bool) {
        if (getSalesCode(code_) == code_){
            HeadShotTracker headShotTracker =
            HeadShotTracker(payable(getTrackerAddress(code_)));
            return headShotTracker.buy(account_, count_);
        }
        return false;
    }

    function spend(address account_, uint256 code_, uint256 count_) public onlyOwner returns (bool) {
        if (getSalesCode(code_) == code_){
            HeadShotTracker headShotTracker =
            HeadShotTracker(payable(getTrackerAddress(code_)));
            bool trx = headShotTracker.spend(account_, count_);
            return trx;
        }
        return false;
    }

    function getSalesCode(uint256 code_) public view returns (uint256) {
        return _salesMap[code_].code;
    }

    function getSalesPrice(uint256 code_) public view returns (uint256) {
        return _salesMap[code_].price;
    }

    function getTrackerAddress(uint256 code_) public view returns (address) {
        return _trackerMap[code_];
    }

    function addTrackerInfo(uint256 code_, address trackerAddress_) private returns (bool) {
        _trackerMap[code_] = trackerAddress_;
        _trackerList.push(trackerAddress_);
        return true;
    }

    function listSalesPart1(uint limit_, uint page_) public view onlyOwner returns (
        uint256[] memory,
        uint256[] memory,
        string[] memory
    ) {
        uint listCount = _salesList.length;

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

        uint256[] memory _categories = new uint256[](rowCount);
        uint256[] memory _codes = new uint256[](rowCount);
        string[] memory _names = new string[](rowCount);

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
                    _categories[id] = _salesList[i].category;
                    _codes[id] = _salesList[i].code;
                    _names[id] = _salesList[i].name;
                    id++;
                }
                j++;
            }
        }

        return (_categories, _codes, _names);
    }

    function listSalesPart2(uint limit_, uint page_) public view onlyOwner returns (
        uint256[] memory,
        string[] memory,
        uint256[] memory
    ) {
        uint listCount = _salesList.length;

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

        uint256[] memory _codes = new uint256[](rowCount);
        string[] memory _descs = new string[](rowCount);
        uint256[] memory _prices = new uint256[](rowCount);

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
                    _codes[id] = _salesList[i].code;
                    _descs[id] = _salesList[i].desc;
                    _prices[id] = (_salesList[i].price).div(10 ** 9);
                    id++;
                }
                j++;
            }
        }

        return (_codes, _descs, _prices);
    }

    function listSalesTracker(uint limit_, uint page_) public view onlyOwner returns (address[] memory) {
        uint listCount = _trackerList.length;

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

        address[] memory _trackers = new address[](rowCount);

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
                    _trackers[id] = _trackerList[i];
                    id++;
                }
                j++;
            }
        }

        return (_trackers);
    }

    function listSalesTrx(uint256 code_, address account_) public view returns (
        uint256[] memory, address[] memory, uint256[] memory, uint256[] memory) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.listTrx(account_);
    }
}