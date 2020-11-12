// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERCMint {
    function mint(address _to, uint256 _amount) external;
}

contract UNCLAirdrop is Ownable {
    using SafeMath for uint256;
    
    IERCMint public uncl;
    IERC20 public uncx;
    IERC20 public uncx_weth;
    uint256 public end_block;
    bool public token0IsPeg = true;
    uint256 public uncx_min_deposit = 1e18;
    
    mapping(address => uint256) public uncxBalances;
    mapping(address => uint256) public uncxWethLPBalances;
    mapping(address => uint256) public uncxWethEffectiveBalances;

    constructor (IERC20 _uncx, IERC20 _uncxweth, IERCMint _uncl, uint256 _end_block) public {
        uncl = _uncl;
        uncx = _uncx;
        uncx_weth = _uncxweth;
        end_block = _end_block;
    }
    
    function updateEndBlock (uint256 _end_block) public onlyOwner {
        end_block = _end_block;
    }
    
    function setToken0IsPeg (bool _value) public onlyOwner {
        token0IsPeg = _value;
    }
    
    function setMinDeposit (uint256 _min) public onlyOwner {
        uncx_min_deposit = _min;
    }
    
    function depositUNCX (uint256 _amount) public {
        require(block.number < end_block, 'AIRDROP PERIOD OVER');
        uint256 userBalance = uncxBalances[msg.sender];
        uint256 newBalance = userBalance.add(_amount);
        require(newBalance >= uncx_min_deposit, 'TOO SMALL');
        TransferHelper.safeTransferFrom(address(uncx), address(msg.sender), address(this), _amount);
        uncxBalances[msg.sender] = newBalance;
    }
    
    function withdrawUNCX () public {
        require(block.number > end_block, 'NOT YET');
        uint256 userBalance = uncxBalances[msg.sender];
        require(userBalance > 0, 'ZERO BALANCE');
        uncxBalances[msg.sender] = 0;
        TransferHelper.safeTransfer(address(uncx), msg.sender, userBalance);
        uncl.mint(msg.sender, userBalance.mul(3));
    }
    
    function depositUNCXWETH (uint256 _amount) public {
        require(block.number < end_block, 'AIRDROP PERIOD OVER');
        uint256 userBalance = uncxWethEffectiveBalances[msg.sender];
        
        IUniswapV2Pair lpair = IUniswapV2Pair(address(uncx_weth));
        (uint112 reserve0, uint112 reserve1, ) = lpair.getReserves();
        
        uint256 reserve = token0IsPeg ? reserve0 : reserve1;
        uint256 uncxValue = _amount.mul(reserve).div(lpair.totalSupply());
        
        uint256 newBalance = userBalance.add(uncxValue);
        
        require(newBalance >= uncx_min_deposit, 'TOO SMALL');
        TransferHelper.safeTransferFrom(address(uncx_weth), address(msg.sender), address(this), _amount);
        uncxWethEffectiveBalances[msg.sender] = newBalance;
        uncxWethLPBalances[msg.sender] = uncxWethLPBalances[msg.sender].add(_amount);
    }
    
    function withdrawUNCXWETH () public {
        require(block.number > end_block, 'NOT YET');
        uint256 userBalance = uncxWethLPBalances[msg.sender];
        require(userBalance > 0, 'ZERO BALANCE');
        uint256 effectiveBalance = uncxWethEffectiveBalances[msg.sender];
        uncxWethLPBalances[msg.sender] = 0;
        uncxWethEffectiveBalances[msg.sender] = 0;
        TransferHelper.safeTransfer(address(uncx_weth), msg.sender, userBalance);
        uncl.mint(msg.sender, effectiveBalance.mul(6));
    }
    
    function getInfo() external view returns (uint256, uint256) {
        return (end_block, uncx_min_deposit);
    }
    
    
}