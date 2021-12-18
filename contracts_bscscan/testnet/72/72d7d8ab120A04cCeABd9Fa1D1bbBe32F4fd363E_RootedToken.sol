// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.4;

/* ROOTKIT: upToken

An upToken is a token that gains in value
against whatever token it is paired with.

- Raise any token using the Market Generation
and Market Distribution contracts
- An equal amount of upToken will be minted
- combine with an ERC-31337 version of the 
raised token.
- Send LP tokens to the Liquidity Controller
for efficent access to market features

*/

import "./LiquidityLockedERC20.sol";
import './IPancakeFactory.sol';
import './IPancakeRouter02.sol';
contract RootedToken is LiquidityLockedERC20("HFuel Token", "HFUEL")
{    
    mapping(address => uint) public transfersReceived;
    IPancakeRouter02 private router;
    IPancakeFactory factory;
    IERC20 baseToken;
    address elite;
    uint endLimit;
    uint buyLimit = 5000000000000000000000;    
    mapping(address => bool) public distributors;
    mapping (address => bool) private _isSniper;
    address[] private _confirmedSnipers;
    address public minter;    
    address public distribution;    
    uint256 public launchTime;    

    modifier onlyDistributors() {
        require(msg.sender == owner || distributors[msg.sender], "Distributors required");
        _;
    }
    
    constructor(IPancakeRouter02 _router, IPancakeFactory _factory, IERC20 _baseToken ){
        factory = _factory;
        router = _router;
        baseToken = _baseToken;
    }
    function setFactoryAndRouter(IPancakeRouter02 _router, IPancakeFactory _factory) public ownerOnly(){
        router = _router;
        factory = _factory;
    }
    function setMinter(address _minter) public ownerOnly()
    {
        minter = _minter;
    }
    function setDistributor(address _distributor) public ownerOnly(){
        distributors[_distributor] = true;
    }
    function setElite(address _elite) public ownerOnly(){
        elite = _elite;
    }
    
    function setLaunchTime(uint256 _launchTime) public onlyDistributors()
    {
        launchTime = _launchTime;
    }
    function mint(uint256 amount) public
    {
        require(msg.sender == minter, "Not a minter");
        require(this.totalSupply() == 0, "Already minted");
        _mint(msg.sender, amount);
    }

    function allowBalance(bool _transferFrom) private
    {
        CallRecord memory last = balanceAllowed;
        CallRecord memory allow = CallRecord({ 
            origin: tx.origin,
            blockNumber: uint32(block.number),
            transferFrom: _transferFrom
        });
        require (last.origin != allow.origin || last.blockNumber != allow.blockNumber || last.transferFrom != allow.transferFrom, "Liquidity is locked (Please try again next block)");
        balanceAllowed = allow;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) 
    {   
        require(!_isSniper[recipient], "You have no power here!");
        require(!_isSniper[msg.sender], "You have no power here!");

        if (liquidityPairLocked[IPancakePair(address(msg.sender))]) {
            allowBalance(false);
        }
        else {
            balanceAllowed = CallRecord({ origin: address(0), blockNumber: 0, transferFrom: false });
        }
        
        transfersReceived[recipient] += amount;        

        // check for snipers
        if(recipient != getElitePairAddress() && !distributors[msg.sender] && recipient != address(router) && !distributors[recipient]){
            //antibot
            if (block.timestamp == launchTime) {
                _isSniper[recipient] = true;
                _confirmedSnipers.push(recipient);   
            }
        }        
        
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) 
    {
        if (liquidityPairLocked[IPancakePair(recipient)]) {
            allowBalance(true);
        }
        else {
            balanceAllowed = CallRecord({ origin: address(0), blockNumber: 0, transferFrom: false });
        }
        
        return super.transferFrom(sender, recipient, amount);
    }

    function getPairAddress() private view returns (address)
    {
        return factory.getPair(address(this), address(baseToken));
    }
    
    function getElitePairAddress() private view returns (address)
    {
        return factory.getPair(address(elite), address(this));
    }

    function isRemovedSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }
    
    function _removeSniper(address account) public ownerOnly() {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not blacklist Uniswap');
        require(!_isSniper[account], "Account is already blacklisted");
        _isSniper[account] = true;
        _confirmedSnipers.push(account);
    }

    function _amnestySniper(address account) public ownerOnly() {
        require(_isSniper[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _confirmedSnipers.length; i++) {
            if (_confirmedSnipers[i] == account) {
                _confirmedSnipers[i] = _confirmedSnipers[_confirmedSnipers.length - 1];
                _isSniper[account] = false;
                _confirmedSnipers.pop();
                break;
            }
        }
    }
}