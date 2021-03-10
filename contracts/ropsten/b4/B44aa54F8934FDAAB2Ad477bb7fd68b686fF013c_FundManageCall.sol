/**
 *Submitted for verification at Etherscan.io on 2021-03-10
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
    address owner;

    mapping(address => bool) admin;

    constructor() public {
        owner = msg.sender;
        setAdmin(msg.sender, true);
    }

    address newOwner = address(0);

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function setAdmin(address _addr, bool _enable) public onlyOwner {
        admin[_addr] = _enable;
    }

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

    modifier isPermission() {
        require(admin[msg.sender], "permission denied!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

interface IFundManage {
    function coverToken(string[] memory _tokenName, uint[] memory _ratio) external returns (bool);

    function enableOpenUp(uint _totalAsset) external returns (bool);

    function enableLockUp() external returns (bool);

    function withdrawToken(address _to) external returns (bool);

    function getCurrentSymbol() external view returns (string memory);

    function getContractAddress(string memory _symbol) external view returns (address _addr);

    function getBalance(string memory _symbol, address _addr) external view returns (uint);
}

interface Exchange{
    function getAmountsOut(uint _tokenNum,address _symbolAddress, address _returnSymbolAddress) external view returns (uint);
}

contract FundManageCall is Owned {
    address FUND_MANAGE;

    uint public openTime;

    address _exchangeAddress;

    string _currentSymbol;

    constructor (address _addr) public {
        FUND_MANAGE = _addr;
        _currentSymbol = "USDC";
    }

    function setCurrentSymbol(string memory _symbol) external onlyOwner {
        _currentSymbol = _symbol;
    }

    function setExchangeAddress(address _addr) external onlyOwner {
        require(Tool.isContract(_addr), "The address must be a contract!");
        _exchangeAddress = _addr;
    }

    function coverToken(string[] memory _tokenName, uint[] memory _ratio) external isPermission returns (bool) {
        return IFundManage(FUND_MANAGE).coverToken(_tokenName, _ratio);
    }

    function enableOpenUp() external returns (bool) {
        // require(openTime > 0, "The opening time is not reached!");
        // require(block.timestamp >= openTime, "The opening time is not reached!");
        IFundManage _fund = IFundManage(FUND_MANAGE);
        string memory _symbol = _fund.getCurrentSymbol();
        address _currentAddress = _fund.getContractAddress(_symbol);
        address _returnSymbolAddress = _fund.getContractAddress(_currentSymbol);
        uint _tokenNum = _fund.getBalance(_symbol, FUND_MANAGE);
        uint _totalAsset = Exchange(_exchangeAddress).getAmountsOut(_tokenNum, _currentAddress, _returnSymbolAddress);
        return IFundManage(FUND_MANAGE).enableOpenUp(_totalAsset);
    }

    function enableLockUp() external isPermission returns (bool) {
        openTime = block.timestamp + 3650 days;
        return IFundManage(FUND_MANAGE).enableLockUp();
    }

    function withdrawToken() external returns (bool) {
        return IFundManage(FUND_MANAGE).withdrawToken(msg.sender);
    }

}