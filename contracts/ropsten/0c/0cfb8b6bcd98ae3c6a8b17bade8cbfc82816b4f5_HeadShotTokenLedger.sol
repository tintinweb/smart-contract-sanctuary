// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./HeadShotTracker.sol";

contract HeadShotTokenLedger is ERC20, Ownable {
    using SafeMath for uint256;
    using ConvertString for uint256;
    using Address for address;

    uint256 private _totalSupply;

    struct TokenInfo {
        address tokenAddress;
        string tokenName;
        string tokenSymbol;
        uint256 tokenDecimals;
        uint256 tokenSupply;
        uint256 tokenCreated;
        address tokenCreator;
    }

    mapping (address => uint256) private _balances;

    mapping(address => TokenInfo) public _tokenMap;
    mapping(address => address) public _trackerMap;

    address[] public _trackerList;
    TokenInfo[] public _tokenList;

    constructor() ERC20("HeadShotTokenLedger", "HSTL") {}

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
        revert("HSTF: method not implemented");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("HSTF: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("HSTF: method not implemented");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("HSTF: method not implemented");
    }

    function addTokenInfo(
        address tokenAddress_,
        string memory tokenName_,
        string memory tokenSymbol_,
        uint256 tokenDecimals_,
        uint256 tokenSupply_,
        uint256 tokenCreated_,
        address tokenCreator_
    ) public onlyOwner returns (bool) {
        string memory trackerName = string(abi.encodePacked("Tracker_", tokenName_));
        string memory trackerSymbol = string(abi.encodePacked("HTTracker_", tokenSymbol_));
        HeadShotTracker headShotTracker = new HeadShotTracker(trackerName, trackerSymbol);

        headShotTracker.setFieldString("tokenName", tokenName_);
        headShotTracker.setFieldString("tokenSymbol", tokenSymbol_);
        headShotTracker.setFieldNumber("tokenSupply", tokenSupply_);
        headShotTracker.setFieldNumber("tokenDecimals", tokenDecimals_);
        headShotTracker.setFieldNumber("tokenCreated", tokenCreated_);
        headShotTracker.setFieldAddress("tokenAddress", tokenAddress_);
        headShotTracker.setFieldAddress("tokenCreator", tokenCreator_);

        address trackerAddress = address(headShotTracker);
        addTrackerInfo(tokenAddress_, trackerAddress);

        TokenInfo memory tokenInfo = TokenInfo(
            tokenAddress_,
            tokenName_,
            tokenSymbol_,
            tokenDecimals_,
            tokenSupply_,
            tokenCreated_,
            tokenCreator_
        );
        _tokenMap[tokenAddress_] = tokenInfo;
        _tokenList.push(tokenInfo);

        return true;
    }

    function getTokenAddress(address tokenAddress_) public view returns (address) {
        return _tokenMap[tokenAddress_].tokenAddress;
    }

    function getTrackerAddress(address tokenAddress_) public view returns (address) {
        return _trackerMap[tokenAddress_];
    }

    function getTrackerFieldString(address tokenAddress_, string memory key_) public view returns (string memory) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(tokenAddress_)));
        return headShotTracker.getFieldString(key_);
    }

    function getTrackerFieldNumber(address tokenAddress_, string memory key_) public view returns (uint256) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(tokenAddress_)));
        return headShotTracker.getFieldNumber(key_);
    }

    function getAccountBalance(address tokenAddress_, address account_) public view returns (uint256) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(tokenAddress_)));
        return headShotTracker.balanceOf(account_);
    }

    function getTrackerFieldAddress(address tokenAddress_, string memory key_) public view returns (address) {
        HeadShotTracker headShotTracker =
        HeadShotTracker(payable(getTrackerAddress(tokenAddress_)));
        return headShotTracker.getFieldAddress(key_);
    }

    function addTrackerInfo(address tokenAddress_, address trackerAddress_) private returns (bool) {
        _trackerMap[tokenAddress_] = trackerAddress_;
        _trackerList.push(trackerAddress_);
        return true;
    }

    function voteUp(address account_, address tokenAddress_) public onlyOwner returns (bool) {
        if (getTokenAddress(tokenAddress_) == tokenAddress_){
            HeadShotTracker headShotTracker =
            HeadShotTracker(payable(getTrackerAddress(tokenAddress_)));
            return headShotTracker.buy(account_, 1);
        }
        return false;
    }

    function voteDown(address account_, address tokenAddress_) public onlyOwner returns (bool) {
        if (getTokenAddress(tokenAddress_) == tokenAddress_){
            HeadShotTracker headShotTracker =
            HeadShotTracker(payable(getTrackerAddress(tokenAddress_)));
            bool trx = headShotTracker.spend(account_, 1);
            return trx;
        }
        return false;
    }

    function listTokenPart1(uint limit_, uint page_) public view onlyOwner returns (
        address[] memory,
        string[] memory,
        string[] memory,
        uint256[] memory
    ) {
        uint listCount = _tokenList.length;

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

        address[] memory _tokenAddresses = new address[](rowCount);
        string[] memory _tokenNames = new string[](rowCount);
        string[] memory _tokenSymbols = new string[](rowCount);
        uint256[] memory _tokenDecimals = new uint256[](rowCount);

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
                    _tokenAddresses[id] = _tokenList[i].tokenAddress;
                    _tokenNames[id] = _tokenList[i].tokenName;
                    _tokenSymbols[id] = _tokenList[i].tokenSymbol;
                    _tokenDecimals[id] = _tokenList[i].tokenDecimals;
                    id++;
                }
                j++;
            }
        }

        return (_tokenAddresses, _tokenNames, _tokenSymbols, _tokenDecimals);
    }

    function listTokenPart2(uint limit_, uint page_) public view onlyOwner returns (
        address[] memory,
        uint256[] memory,
        uint256[] memory,
        address[] memory
    ) {
        uint listCount = _tokenList.length;

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

        address[] memory _tokenAddresses = new address[](rowCount);
        uint256[] memory _tokenSupplies = new uint256[](rowCount);
        uint256[] memory _tokenCreates = new uint256[](rowCount);
        address[] memory _tokenCreators = new address[](rowCount);

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
                    _tokenAddresses[id] = _tokenList[i].tokenAddress;
                    _tokenSupplies[id] = _tokenList[i].tokenSupply;
                    _tokenCreates[id] = _tokenList[i].tokenCreated;
                    _tokenCreators[id] = _tokenList[i].tokenCreator;
                    id++;
                }
                j++;
            }
        }

        return (_tokenAddresses, _tokenSupplies, _tokenCreates, _tokenCreators);
    }

    function listTokenTracker(uint limit_, uint page_) public view onlyOwner returns (address[] memory) {
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
}