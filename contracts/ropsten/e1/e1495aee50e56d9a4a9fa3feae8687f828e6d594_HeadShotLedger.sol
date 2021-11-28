// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./HeadShotTracker.sol";

contract HeadShotLedger is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using ConvertString for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals = 0;

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) public _trackerMap;
    address[] public _trackerList;

    constructor(string memory name_, string memory symbol_, uint8 decimals_){
        _name = string(abi.encodePacked("HeadShotLedger_", name_));
        _symbol = symbol_;
        _decimals = decimals_;
    }

    receive() external payable {}

    /* Start of show properties */
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view returns (uint256) {
        return _trackerList.length;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    /* End of show properties */
    function transfer(address, uint256) public pure override returns (bool) {
        revert("HeadShotLedger: method not implemented");
    }
    function allowance(address, address) public pure override returns (uint256) {
        revert("HeadShotLedger: method not implemented");
    }
    function approve(address, uint256) public pure override returns (bool) {
        revert("HeadShotLedger: method not implemented");
    }
    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("HeadShotLedger: method not implemented");
    }
    function getTrackerAddress(uint256 code_) public view returns (address) {
        return _trackerMap[code_];
    }

    function getTrackerBalance(address address_, address account_) public view returns (uint256) {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.getAccountBalance(account_);
    }

    function getTrackerSupply(address address_) public view returns (uint256) {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.totalSupply();
    }

    function getTrackerFieldString(address address_, string memory key_) public view returns (string memory) {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.getFieldString(key_);
    }
    function getTrackerFieldNumber(address address_, string memory key_) public view returns (uint256) {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.getFieldNumber(key_);
    }
    function getTrackerFieldAddress(address address_, string memory key_) public view returns (address) {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.getFieldAddress(key_);
    }

    function setTrackerFieldString(address address_, string memory key_, string memory value_) public onlyOwner {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.setFieldString(key_, value_);
    }
    function setTrackerFieldNumber(address address_, string memory key_, uint256 value_) public onlyOwner {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.setFieldNumber(key_, value_);
    }
    function setTrackerFieldAddress(address address_, string memory key_, address value_) public onlyOwner {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.setFieldAddress(key_, value_);
    }

    function increaseBalance(address address_, address account_, uint256 balance_) public onlyOwner returns (uint256){
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.increaseBalance(account_, balance_);
    }
    function decreaseBalance(address address_, address account_, uint256 balance_) public onlyOwner returns (uint256){
        HeadShotTracker headShotTracker = HeadShotTracker(payable(address_));
        return headShotTracker.decreaseBalance(account_, balance_);
    }

    function addTracker(uint256 code_) public onlyOwner returns (address){
        string memory codeString = ConvertString.toStr(code_);
        string memory trackerName = string(abi.encodePacked("HeadShotTracker_", codeString));
        string memory trackerSymbol = string(abi.encodePacked("HSTracker_", codeString));

        HeadShotTracker headShotTracker = new HeadShotTracker(trackerName, trackerSymbol);
        address address_ = address(headShotTracker);
        _trackerMap[code_] = address_;
        _trackerList.push(address_);

        return address_;
    }

    function listTracker(uint limit_, uint page_) public view returns (address[] memory) {
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
    function listTrx(uint256 code_, address account_) public view returns (
        uint256[] memory, uint256[] memory, uint256[] memory) {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.listTrx(account_);
    }
}