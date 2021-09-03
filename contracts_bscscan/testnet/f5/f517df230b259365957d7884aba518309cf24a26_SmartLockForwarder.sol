// SPDX-License-Identifier: MIT



pragma solidity 0.6.12;

import "./Ownable.sol";
import "./TransferHelper.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IPresaleFactory.sol";
import "./IUniswapV2Pair.sol";

interface ISmartLocker {
    function lockLPToken (address _lpToken, uint256 _amount, uint256 _unlock_date, address payable _withdrawer) external payable;
}

contract SmartLockForwarder is Ownable {
    
    IPresaleFactory public presaleFactory;
    ISmartLocker public smartLocker;
    IUniswapV2Factory public swapFactory;
    
    constructor(IPresaleFactory _presaleFactory, ISmartLocker _smartLocker, IUniswapV2Factory _swapFactory) public {
        presaleFactory = _presaleFactory;
        smartLocker = _smartLocker;
        swapFactory = _swapFactory;
    }

    /**
        Send in _token0 as the PRESALE token, _token1 as the BASE token (usually WETH) for the check to work. As anyone can create a pair,
        and send WETH to it while a presale is running, but no one should have access to the presale token. If they do and they send it to 
        the pair, scewing the initial liquidity, this function will return true
    */
    function swapPairIsInitialised (address _token0, address _token1) public view returns (bool) {
        address pairAddress = swapFactory.getPair(_token0, _token1);
        if (pairAddress == address(0)) {
            return false;
        }
        uint256 balance = IERC20(_token0).balanceOf(pairAddress);
        if (balance > 0) {
            return true;
        }
        return false;
    }
    
    function lockLiquidity (IERC20 _baseToken, IERC20 _saleToken, uint256 _baseAmount, uint256 _saleAmount, uint256 _unlock_date, address payable _withdrawer) external {
        require(presaleFactory.presaleIsRegistered(msg.sender), 'PRESALE NOT REGISTERED');
        address pair = swapFactory.getPair(address(_baseToken), address(_saleToken));
        if (pair == address(0)) {
            swapFactory.createPair(address(_baseToken), address(_saleToken));
            pair = swapFactory.getPair(address(_baseToken), address(_saleToken));
        }
        
        TransferHelper.safeTransferFrom(address(_baseToken), msg.sender, address(pair), _baseAmount);
        TransferHelper.safeTransferFrom(address(_saleToken), msg.sender, address(pair), _saleAmount);
        IUniswapV2Pair(pair).mint(address(this));
        uint256 totalLPTokensMinted = IUniswapV2Pair(pair).balanceOf(address(this));
        require(totalLPTokensMinted != 0 , "LP creation failed");
    
        TransferHelper.safeApprove(pair, address(smartLocker), totalLPTokensMinted);
        uint256 unlock_date = _unlock_date > 9999999999 ? 9999999999 : _unlock_date;
        smartLocker.lockLPToken(pair, totalLPTokensMinted, unlock_date, _withdrawer);
    }
    
}