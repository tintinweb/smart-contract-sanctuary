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
contract RootedToken is LiquidityLockedERC20("Hobbs Network Token", "HNW")
{
    // todo make private after testing
    mapping(address => uint) public transfersReceived;

    address public minter;
    IPancakeRouter02 private router;
    IPancakeFactory factory;
    IERC20 baseToken;
    address public distribution;
    uint endLimit;
    mapping(address => bool) distributors;

    modifier onlyDistributors() {
        require(msg.sender == owner || distributors[msg.sender], "Distributors required");
        _;
    }
    //todo make below private
    function checkLimitTime() public view returns (bool) {
        if(endLimit - block.timestamp >= 0){
            return false; //limit still in affect
        }
        return true;
        
    }
    constructor(IPancakeRouter02 _router, IPancakeFactory _factory ){
        factory = _factory;
        router = _router;
        baseToken = IERC20(router.WETH());
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
    function startTradeLimit(uint timeInSeconds) public  ownerOnly(){
        endLimit = block.timestamp + timeInSeconds;
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
        if (liquidityPairLocked[IPancakePair(address(msg.sender))]) {
            allowBalance(false);
        }
        else {
            balanceAllowed = CallRecord({ origin: address(0), blockNumber: 0, transferFrom: false });
        }

        bool limitInAffect = checkLimitTime();        
        if(!limitInAffect){
            if(!distributors[msg.sender])
            {                        
                //require(limitInAffect, 'Time Limit in Affect');
                if(recipient != getPairAddress()){
                    uint256 totalAmount = transfersReceived[recipient];
                    require(totalAmount <= 5000, "Total Amount already received until time limit over.");
                }
                
            }

            transfersReceived[recipient] += amount;
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
    //todo make private
    function getPairAddress() public view returns (address)
    {
        return factory.getPair(address(this), address(baseToken));
    }
}