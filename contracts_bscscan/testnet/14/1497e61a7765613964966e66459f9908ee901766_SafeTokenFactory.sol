// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./SafeERC20TokenBasic.sol";

contract SafeTokenFactory is Ownable {
    using SafeMath for uint256;

    uint256 public tTotal;
    uint256 public vTotal;
    address[] public allTokens;
    mapping (address => address[]) public tokensByCreatorAddress;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 public serviceFee = 1 / 100 * 10**18;
    bool inWithdraw;

    modifier lockWithdraw {
        inWithdraw = true;
        _;
        inWithdraw = false;
    }

    constructor () Ownable(_msgSender()) {
        // _isExcludedFromFee[owner()] = true;
    }

    function create(string memory name_, string memory symbol_, uint8 decimals_, uint256  totalSupply_)  public payable returns (address tokenAddress)  {
        address from = _msgSender();
        if(!_isExcludedFromFee[from]) require(msg.value >= serviceFee, "The service fee is too low");
        SafeERC20Token token = new SafeERC20Token(name_, symbol_, decimals_, totalSupply_, from);
        tTotal += 1;
        vTotal += msg.value;
        tokenAddress = address(token);
        allTokens.push(tokenAddress);
        tokensByCreatorAddress[from].push(tokenAddress);
        return tokenAddress;
    }

    receive() external payable {}

    function balanceOf() public view returns(uint256){
        return address(this).balance;
    }

    function withdraw() public onlyOwner lockWithdraw returns (uint256) {
        uint256 balance = address(this).balance;
        if(!inWithdraw && balance > 0){
            payable(owner()).transfer(balance);
        }
        return balance;
    }

    function setServiceFee(uint256 fee) external onlyOwner() {
        serviceFee = fee.div(100).mul(10**18);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function getAllTokens() view public returns (address[] memory){
        return allTokens;
    }

    function getTokensByCreatorAddress(address creator) view public returns (address[] memory){
        return tokensByCreatorAddress[creator];
    }
    
}