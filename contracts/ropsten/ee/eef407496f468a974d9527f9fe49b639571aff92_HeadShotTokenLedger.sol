// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./HeadShotTracker.sol";

contract HeadShotTokenLedger is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using ConvertString for uint256;
    using Address for address;

    string private constant _name = "HeadShotTokenLedger";
    string private constant _symbol = "HSTL";
    uint8 private constant _decimals = 0;

    struct TokenInfo {
        address tokenAddress;
        string tokenNetwork;
        string tokenName;
        string tokenSymbol;
        uint256 tokenDecimals;
        uint256 tokenCreated;
        address tokenCreator;
    }

    mapping(address => uint256) private _balances;
    mapping(address => TokenInfo) public _tokenMap;
    mapping(address => address) public _trackerMap;

    address[] public _trackerList;
    TokenInfo[] public _tokenList;

    constructor(){}

    receive() external payable {}

    /* Start of show properties */
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _trackerList.length;
    }
    /* End of show properties */

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

    function addTokenInfo(
        address address_, string memory network_, string memory name_,
        string memory symbol_, uint256 decimals_, uint256 created_, address creator_
    ) public onlyOwner returns (bool) {
        string memory trackerName = string(abi.encodePacked("Tracker_", name_));
        string memory trackerSymbol = string(abi.encodePacked("HTTracker_", symbol_));
        HeadShotTracker headShotTracker = new HeadShotTracker(trackerName, trackerSymbol);

        headShotTracker.setFieldString("name", name_);
        headShotTracker.setFieldString("symbol", symbol_);
        headShotTracker.setFieldString("network", network_);
        headShotTracker.setFieldNumber("decimals", decimals_);
        headShotTracker.setFieldNumber("created", created_);
        headShotTracker.setFieldAddress("address", address_);
        headShotTracker.setFieldAddress("creator", creator_);

        address trackerAddress = address(headShotTracker);
        addTrackerInfo(address_, trackerAddress);

        TokenInfo memory tokenInfo = TokenInfo(
            address_,
            network_,
            name_,
            symbol_,
            decimals_,
            created_,
            creator_
        );
        _tokenMap[address_] = tokenInfo;
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
        return headShotTracker.getAccountBalance(account_);
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

    function listTokenPart1(uint limit_, uint page_) public view onlyOwner returns (address[] memory, string[] memory, string[] memory, uint256[] memory) {
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

    function listTokenPart2(uint limit_, uint page_) public view onlyOwner returns (address[] memory, string[] memory, uint256[] memory, address[] memory) {
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
        string[] memory _tokenNetworks = new string[](rowCount);
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
                    _tokenNetworks[id] = _tokenList[i].tokenNetwork;
                    _tokenCreates[id] = _tokenList[i].tokenCreated;
                    _tokenCreators[id] = _tokenList[i].tokenCreator;
                    id++;
                }
                j++;
            }
        }

        return (_tokenAddresses, _tokenNetworks, _tokenCreates, _tokenCreators);
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