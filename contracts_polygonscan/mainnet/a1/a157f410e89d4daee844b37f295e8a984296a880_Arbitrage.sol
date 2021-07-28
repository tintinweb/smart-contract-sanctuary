// SPDX-License-Identifier: UNLISENCED
pragma solidity 0.8.4;

import {IFlashLoanReceiver, ILendingPoolAddressesProvider, ILendingPool, IERC20  } from "./Interfaces.sol";
import { SafeERC20, SafeMath } from "./Libraries.sol";
import {IRouter} from "./IUniswapV2.sol";

contract Arbitrage is IFlashLoanReceiver {
    address private owner;
    address private admin;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    ILendingPool internal lendingPool;
    
    constructor(address _lendingPool, address _admin) {
        lendingPool = ILendingPool(_lendingPool);
        owner = msg.sender;
        admin = _admin;
    }
    
    modifier onlyOwner{
        require(owner == msg.sender, "only owner");
        _;
    }
    
    modifier onlyAdmin{
        require(msg.sender == owner || msg.sender == admin, "only admin");
        _;
    }
    
    function setOwner(address _newOwner) public onlyOwner{
        owner = _newOwner;
    }
    
    function setAdmin(address _newAdmin) public onlyOwner{
        admin = _newAdmin;
    }
    
    
    receive() external payable {}
    
    struct ParamData{
        address base;
        address quote;
        address buyFrom;
        address sellAt;
        uint256 amountIn;
        uint256 amountOut;
    }
    
    
    
    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        require(amounts.length > 0 && assets.length > 0, "no assets");
        
        (ParamData memory _p) = abi.decode(params, (ParamData));
        uint256 debt = amounts[0].add(premiums[0]);
        
        {
            // Arbitrage Scope
            // Buying the lended token at the target dex
            require(IERC20(_p.quote).approve(_p.buyFrom, _p.amountIn), "Buy:approve");
            address[] memory buyPath = new address[](2);
            buyPath[0] = _p.quote;
            buyPath[1] = _p.base;
            uint[] memory bought = IRouter(_p.buyFrom).swapExactTokensForTokens(
                _p.amountIn,
                _p.amountOut,
                buyPath,
                address(this),
                block.timestamp
            );
        
            // Selling the swaped token at the target dex
            require(IERC20(_p.base).approve(_p.sellAt, bought[1]), "Sell:approve");
            address[] memory sellPath = new address[](2);
            sellPath[0] = _p.base;
            sellPath[1] = _p.quote;
            uint[] memory sold = IRouter(_p.sellAt).swapExactTokensForTokens(
                bought[1],
                debt,
                sellPath,
                address(this),
                block.timestamp
            );
            uint256 profit = sold[1] - debt;
            require( profit > 0, "unprofitable");
            IERC20(_p.quote).transfer(owner, profit);
        }
        
        // Repaying
        IERC20(assets[0]).approve(address(lendingPool), debt);
        
        return true;
    }
    

    function trade(address base, address quote, address buyFrom, address sellAt, uint256 amountIn, uint256 amountOut) public onlyAdmin returns(bool) {
        address[] memory assets = new address[](1);
        assets[0] = quote;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountIn;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        bytes memory params = abi.encode(ParamData(base, quote, buyFrom, sellAt, amountIn, amountOut));
        uint16 referralCode = 0;

        lendingPool.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            referralCode
        );
        
        return true;
    }
    
    function withdraw(address token, address _to, uint256 _amount) public onlyOwner{
        IERC20(token).transfer(_to, _amount);
    }
}