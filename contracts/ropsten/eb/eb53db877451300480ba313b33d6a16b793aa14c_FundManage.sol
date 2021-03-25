/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: SimPL-2.0
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

library Tool {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address owner;

    constructor() public {
        owner = msg.sender;
    }

    address newOwner = address(0);

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract PermissionsVerify is Owned {
    bool public lockUp = false;

    bool public openUp;

    mapping(address => bool) admin;

    function setAdmin(address _addr,bool _enable) public onlyOwner returns (bool){
        require(Tool.isContract(_addr), "The address must be a contract!");
        admin[_addr] = _enable;
        return true;
    }

    modifier lockAllowed(address _addr) {
        require(!lockUp && !openUp, "Have lock up!");
        _;
    }

    modifier openAllowed(address _addr) {
        require(openUp && lockUp, "Do not operate this item!");
        _;
    }

    modifier isAdmin() {
        require(admin[msg.sender], "Only admin can operate!");
        _;
    }
}

interface IERC20 {
    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address _addr) external view returns (uint);

    function transfer(address _to, uint _value) external returns (bool);

    function transferFrom(address _from, address _to, uint _value) external returns (bool);
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
}

interface TokenManage {
    function closePositionRelease(bool _debug) external returns (bool);
}

contract FundManageStorage is PermissionsVerify {
    using SafeMath for uint;
    mapping(string => address) _ERC20Address;

    string _currentSymbol;

    address FETCH_ADDRESS;

    address VOUCHER_ADDRESS;

    address FUND_CONTRACT;

    address _tokenManageContract;

    uint brokerageRate = 10;

    address _destroyAddress;

    address BROKERAGE_CONTRACT;

    uint public capitalPool;

    uint public ETHCapitalPool;

    mapping(string => uint) public TokenCapitalPool;

    uint public finalTokenNum;

    mapping(address => bool) _isTakePosition;

    mapping(address => uint) _balance;

    address _exchangeAddress;

    uint _deviation = 10;

    constructor() public {
        _destroyAddress = 0x1111111111111111111111111111111111111111;
    }

    modifier fetchPermission() {
        require(msg.sender == FETCH_ADDRESS, "Address no permission!");
        _;
    }

    function setBrokerageContract(address _addr) public onlyOwner {
        require(Tool.isContract(_addr), "The address must be a contract!");
        BROKERAGE_CONTRACT = _addr;
    }

    function getIsTakePosition(address _addr) external view returns (bool) {
        return _isTakePosition[_addr];
    }

    function getTakePositionBalance(address _addr) external view returns (uint) {
        return _balance[_addr];
    }

    function setBrokerageRate(uint _rate) external isAdmin {
        require(_rate > 0, "The interest rate has to be greater than 0!");
        brokerageRate = _rate;
    }

    function setDeviation(uint _dev) external onlyOwner {
        _deviation = _dev;
    }

    function setExchangeAddress(address _addr) external onlyOwner {
        require(Tool.isContract(_addr), "The address must be a contract!");
        _exchangeAddress = _addr;
    }

    function setTokenManageContract(address _addr) external onlyOwner {
        require(Tool.isContract(_addr), "The address must be a contract!");
        _tokenManageContract = _addr;
    }

    function setFundContract(address _addr) external onlyOwner {
        require(Tool.isContract(_addr), "The address must be a contract!");
        FUND_CONTRACT = _addr;
    }

    function setFetchAddress(address _addr) external onlyOwner {
        require(Tool.isContract(_addr), "The address must be a contract!");
        FETCH_ADDRESS = _addr;
    }

    function setCurrentSymbol(string memory _symbol) external onlyOwner {
        require(existSymbol(_symbol), "The token address does not exist!");
        _currentSymbol = _symbol;
    }

    function getCurrentSymbol() external view returns (string memory) {
        return _currentSymbol;
    }

    function existSymbol(string memory _symbol) internal view returns (bool) {
        if (_ERC20Address[_symbol] != address(0)) {
            return true;
        }
        return false;
    }

    function setContractAddress(address _addr) external onlyOwner {
        require(Tool.isContract(_addr), "The address must be a contract!");

        bytes memory _symbol = bytes(IERC20(_addr).symbol());
        require(_symbol.length > 0, "The address must be ERC20!");

        _ERC20Address[string(_symbol)] = _addr;

        if (bytes(_currentSymbol).length == 0) {
            _currentSymbol = string(_symbol);
        }
    }

    function getBalance(string memory _symbol, address _addr) public view returns (uint) {
        return IERC20(_ERC20Address[_symbol]).balanceOf(_addr);
    }

    function getETHBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractAddress(string memory _symbol) external view returns (address _addr) {
        _addr = _ERC20Address[_symbol];
        require(_addr != address(0), "This address was not found!");
    }
}

interface TransferCallback {
    function fundCallback(address _fetch_address, address _return_address, uint _tokenNum, uint _queryId) external returns (uint);
    function fundETHCallback(address _return_address) payable external returns (uint);
}

interface Exchange{
    function getAmountsOut(uint _tokenNum,address _symbolAddress, address _returnSymbolAddress) external view returns (uint);
}

interface CostHand {
    function payableCharge(address _owner) external payable returns (bool);
}

contract FundManageDebug is FundManageStorage {
    bool public debug = true;

    uint public totalDebugToken;

    function changeDebug() external onlyOwner {
        require(debug, "Non-repeatable call!");
        debug = false;
        lockUp = false;
        openUp = false;
        totalDebugToken = IERC20(VOUCHER_ADDRESS).balanceOf(_destroyAddress);
        finalTokenNum = 0;
        ETHCapitalPool = 0;
        capitalPool = 0;
    }
}

contract FundManage is FundManageDebug {
    receive() external payable {}

    constructor(address _voucherAddress) public {
        VOUCHER_ADDRESS = _voucherAddress;
    }

    function takePosition(
        address _owner,
        uint _charge
    ) public payable isAdmin lockAllowed(_owner) returns (bool) {
        require(FUND_CONTRACT != address(0), "The address cannot be!");
        require(_charge > 0, "The fee must be greater than 0!");
        require(msg.value > _charge, "Building warehouse amount must be greater than poundage!");
        require(!_isTakePosition[_owner], "Non-repeatable operation!");

        _isTakePosition[_owner] = true;
        if (CostHand(FUND_CONTRACT).payableCharge{value:_charge}(_owner)) {
            uint _capital = msg.value.sub(_charge);
            ETHCapitalPool = ETHCapitalPool.add(_capital);
            _balance[_owner] = _balance[_owner].add(_capital);
        } else {
            revert();
        }
        return true;
    }

    function coverToken(string[] memory _tokenName, uint[] memory _ratio) external isAdmin returns (bool) {
        require(_tokenName.length == _ratio.length, "Token and proportional array sizes are inconsistent!");
        uint _capital = address(this).balance;

        uint _ethCoverTotal;
        for (uint i = 0; i < _tokenName.length; i++) {
            require(_ERC20Address[_tokenName[i]] != address(0), "Token address does not exist!");
            uint _coverNum = _capital.mul(_ratio[i]).div(100).sub(1);
            _ethCoverTotal = _ethCoverTotal.add(_coverNum);
            uint _return_num = ETH2Token(_tokenName[i], _coverNum);
            TokenCapitalPool[_tokenName[i]] = TokenCapitalPool[_tokenName[i]].add(_return_num);
        }

        uint _cost = Exchange(_exchangeAddress).getAmountsOut(_ethCoverTotal, _ERC20Address["WETH"], _ERC20Address["USDC"]);
        capitalPool = capitalPool.add(_cost);

        return true;
    }

    function _transferFrom(
        address _from,
        address _to,
        uint _value,
        string memory _symbol
    ) internal returns (bool) {
        return IERC20(_ERC20Address[_symbol]).transferFrom(_from, _to, _value);
    }

    function _transfer(
        address _to,
        uint _value,
        address _erc20Addr
    ) internal returns (bool) {
        require(IERC20(_erc20Addr).balanceOf(address(this)) >= _value, "Transfer out more than the maximum amount!");
        return IERC20(_erc20Addr).transfer(_to, _value);
    }

    function enableLockUp() public isAdmin returns (bool){
        require(!lockUp, "Non-repeatable operation!");
        lockUp = true;
        require(TokenManage(_tokenManageContract).closePositionRelease(debug), "Token release failed!");
        return true;
    }

    function enableOpenUp(uint _totalAsset) public isAdmin returns (bool) {
        require(BROKERAGE_CONTRACT != address(0), "The address cannot be 0!");
        require(!openUp, "Non-repeatable operation!");
        openUp = true;
        uint _currentBalance = getBalance(_currentSymbol, address(this));
        if (_totalAsset > capitalPool) {
            uint _rateUsd = _totalAsset.sub(capitalPool).mul(brokerageRate).div(100);
            uint _rateWbtc = _currentBalance.mul(_rateUsd).div(_totalAsset);
            require(_transfer(BROKERAGE_CONTRACT, _rateWbtc, _ERC20Address[_currentSymbol]), "Failed handling fee transfer out!");
            _currentBalance = _currentBalance.sub(_rateWbtc);
        }
        finalTokenNum = _currentBalance;
        return true;
    }

    function withdrawToken(
        address _to
    ) public openAllowed(_to) isAdmin returns (bool) {
        IERC20 _voucherContract = IERC20(VOUCHER_ADDRESS);
        uint haveTokenNum = _voucherContract.balanceOf(_to);
        require(haveTokenNum > 0, "No assets!");
        require(_voucherContract.transferFrom(_to, _destroyAddress, haveTokenNum), "Please approve!");

        uint totalTokenNum = _voucherContract.totalSupply().sub(totalDebugToken);

        uint _returnNum = finalTokenNum.mul(haveTokenNum).div(totalTokenNum);
        if (_transfer(_to, _returnNum, _ERC20Address[_currentSymbol])) {
            return true;
        } else {
            revert();
        }
    }

    function fetchToken(
        string memory _symbol,
        string memory _return_symbol,
        uint _tokenNum,
        uint _queryId
    ) external fetchPermission returns (bool) {
        require(!openUp && lockUp, "Do not operate this item!");

        address _fetch_address = _ERC20Address[_symbol];
        address _return_address = _ERC20Address[_return_symbol];

        require(_fetch_address != address(0), "The extract token address does not exist!");
        require(_return_address != address(0), "The return token address does not exist!");
        require(getBalance(_symbol, address(this)) >= _tokenNum, "Insufficient account balance!");

        uint _return_balance = getBalance(_return_symbol, address(this));

        if (_transfer(msg.sender, _tokenNum, _fetch_address)) {
            uint _exchange = Exchange(_exchangeAddress).getAmountsOut(_tokenNum, _fetch_address, _return_address);
            uint _return_num = TransferCallback(msg.sender).fundCallback(_fetch_address, _return_address, _tokenNum, _queryId);
            require(_return_num.add(_return_num.mul(_deviation).div(1000)) >= _exchange, "Excessive exchange rate misalignment!");

            if (_return_balance.add(_return_num) <= getBalance(_return_symbol, address(this))) {
                return true;
            } else {
                revert();
            }
        }
        return false;
    }

    function ETH2Token(
        string memory _return_symbol,
        uint _tokenNum
    ) internal returns (uint) {
        address _return_address = _ERC20Address[_return_symbol];
        require(_return_address != address(0), "The return token address does not exist!");

        uint _return_balance = getBalance(_return_symbol, address(this));

        uint _exchange = Exchange(_exchangeAddress).getAmountsOut(_tokenNum, _ERC20Address["WETH"], _return_address);

        uint _return_num = TransferCallback(FETCH_ADDRESS).fundETHCallback{value:_tokenNum}(_return_address);
        require(_return_num.add(_return_num.mul(_deviation).div(1000)) >= _exchange, "Excessive exchange rate misalignment!");
        require (_return_balance.add(_return_num) <= getBalance(_return_symbol, address(this)), "Not yet received the token!");
        return _return_num;
    }
}