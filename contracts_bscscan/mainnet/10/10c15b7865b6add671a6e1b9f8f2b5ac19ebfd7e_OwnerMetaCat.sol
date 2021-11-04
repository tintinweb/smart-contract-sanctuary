/**
 *Submitted for verification at BscScan.com on 2021-11-04
*/

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}
 
interface IMetaCatToken {
    function excludeFromFee(address account) external;
    function includeInFee(address account) external;
    function setTaxFeePercent(uint256 taxFee) external;
    function setLiquidityFeePercent(uint256 liquidityFee) external;
    function setMaxTxAmount(uint256 maxTxAmount) external;
    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external;
    function setMarketingAddress(address _marketingAddress) external;
    function setSwapAndLiquifyEnabled(bool _enabled) external;
    function setBuyBackEnabled(bool _enabled) external;
    function setMarketingDivisor(uint256 divisor) external;
    function setBuybackUpperLimit(uint256 buyBackLimit) external;
}
 
contract OwnerMetaCat is Ownable {
    IMetaCatToken public  metaCatToken;
 
    constructor(address metaCatTokenAddress) {
        metaCatToken = IMetaCatToken(metaCatTokenAddress);
    }
    function excludeFromFee(address account) public onlyOwner {
        metaCatToken.excludeFromFee(account);
    }
 
    function includeInFee(address account) public onlyOwner {
        metaCatToken.includeInFee(account);
    }
 
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee <= 5, "Tax Fee must be less than 5%");
        metaCatToken.setTaxFeePercent(taxFee);
    }
 
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee <= 12, "liquidity fee must be less than 12%");
        metaCatToken.setLiquidityFeePercent(liquidityFee);
    }
 
    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount >= 1000000000 *1e9, "Max Tx amount should be more than or equal to 1000000000");
        metaCatToken.setMaxTxAmount(maxTxAmount);
    }
 
    function setMarketingDivisor(uint256 divisor) external onlyOwner() {
        metaCatToken.setMarketingDivisor(divisor);
    }
 
    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        metaCatToken.setNumTokensSellToAddToLiquidity(_minimumTokensBeforeSwap);
    }
 
    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        metaCatToken.setBuybackUpperLimit(buyBackLimit);
    }
 
    function setMarketingAddress(address _marketingAddress) external onlyOwner() {
        metaCatToken.setMarketingAddress(_marketingAddress);
    }
 
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        metaCatToken.setSwapAndLiquifyEnabled(_enabled);
    }
 
    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        metaCatToken.setBuyBackEnabled(_enabled);
    }
 
}