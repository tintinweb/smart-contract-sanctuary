// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract DYTTokenAVAX is ERC20, Ownable, ReentrancyGuard {
    
    using SafeMath for uint256;
    
    uint256 public sellFee = 2;
    uint256 public buyFee =1;
    uint256 public maxAmount =  200 * 10**3 * 10**18;

    address public mktAddr = 0x9d7550f782EdEa1Fd25dE9b47ad22A07360e179A;
    
    uint256 public swapTokensAtAmount = 10 * 10**3 * 10**18;
     // exlcude from fees and max transaction amount
    mapping (address => bool) private _isWhitelist;
    mapping (address => bool) private _isAmmPair;

    constructor() public ERC20("DYT TOKEN", "DYT") {
        
        setWhitelistAddr(address(this), true);
        setWhitelistAddr(owner(), true);
        setWhitelistAddr(mktAddr, true);
        _mint(owner(), 400000000 * (10**18));
    }

    receive() external payable {}

    function setFee(uint256 _sellFee, uint256 _buyFee) public onlyOwner{
        require(0<= _sellFee && _sellFee <=10, "SellFee <= 10");
        require(0<= _buyFee && _buyFee <=10, "BuyFee <= 10");
        sellFee = _sellFee;
        buyFee = _buyFee;
    } 


    function setMktAddress(address  _wallet) external onlyOwner{
        require(_wallet != address(0), "Invalid Address");
        mktAddr = _wallet;
    }

    function setWhitelistAddr(address account, bool value) public onlyOwner{
        _isWhitelist[account] = value;
    }

    function isWhitelistAddr(address account) public view returns(bool) {
        return _isWhitelist[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        require(amount >0 , "amount = 0");
        if (amount > maxAmount && _isAmmPair[to] && !isWhitelistAddr(from)){
            revert("MaxAmount");
        }

        uint256 transferFee = true == _isAmmPair[to]
            ? sellFee
            : (true == _isAmmPair[from] ? buyFee : 0);

        if (
            transferFee > 0 &&
            from != address(this) &&
            to != address(this) 
        ) {
            uint256 _fee = amount.mul(transferFee).div(100);
            super._transfer(from, address(this), _fee); 
            amount = amount.sub(_fee);
        }

        super._transfer(from, to, amount);
        
    }
    
    
    function setAmmPair(address _addr) external onlyOwner{
        _isAmmPair[_addr] = true;
    }

    function setMaxAmount(uint256 _maxAmount) external onlyOwner{
        require(_maxAmount > 200 * 10**3 * 10**18, "maxAmount too small");
        maxAmount = _maxAmount;
    }

    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) external onlyOwner{
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    function swapForMkt() public nonReentrant onlyOwner {
        uint256 _contractBalance = balanceOf(address(this));
        require(_contractBalance >= swapTokensAtAmount, "contractBalance < swapTokensAtAmount");
        super._transfer(address(this), msg.sender, swapTokensAtAmount);
        //swapTokensForEth(swapTokensAtAmount);
        
    }
    
    

}