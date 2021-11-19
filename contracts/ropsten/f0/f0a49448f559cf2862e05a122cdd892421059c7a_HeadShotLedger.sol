// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./HeadShotTracker.sol";

contract HeadShotLedger is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using ConvertString for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) public _trackerMap;
    address[] public _trackerList;

    constructor(string memory name_, string memory symbol_, uint8 decimals_){
        _name = name_;
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
    function totalSupply() public view override returns (uint256) {
        return _trackerList.length;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

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

    /* End of show properties */

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
    function getTrackerFieldAddress(uint256 code_, string memory key_) public view returns (address) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.getFieldAddress(key_);
    }
    function getAccountBalance(uint256 code_, address account_) public view returns (uint256) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.getAccountBalance(account_);
    }
    function getTrackerAddress(uint256 code_) public view returns (address) {
        return _trackerMap[code_];
    }

    function buy(address account_, uint256 code_, uint256 count_) public onlyOwner returns (bool) {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.buy(account_, count_);
    }
    function spend(address account_, uint256 code_, uint256 count_) public onlyOwner returns (bool) {
        HeadShotTracker headShotTracker = HeadShotTracker(payable(getTrackerAddress(code_)));
        return headShotTracker.spend(account_, count_);
    }
    function addTracker(uint256 code_, address trackerAddress_) public onlyOwner returns (bool) {
        _trackerMap[code_] = trackerAddress_;
        _trackerList.push(trackerAddress_);
        return true;
    }
    function listTracker(uint limit_, uint page_) public view onlyOwner returns (address[] memory) {
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