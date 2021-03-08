/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/// @dev brief interface for sushi swapping ETH - based on Uniswap v2 router.
interface ISushiSwapETH {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

/// @dev brief interface for entering and leaving SUSHI bar (xSUSHI).
interface ISushiBar { 
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function enter(uint256 amount) external;
    function leave(uint256 share) external;
}

/// @dev brief interface for depositing into and withdrawing from Aave lending pool.
interface IAaveDepositWithdraw {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function withdraw(address token, uint256 amount, address destination) external;
}

/// @dev contract that batches ETH and SUSHI staking into Aave xSUSHI (aXSUSHI).
contract Swaave {
    address constant wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Wrapped ETH token contract
    ISushiSwapETH constant sushiSwapRouter = ISushiSwapETH(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // SushiSwap router contract
    ISushiBar constant sushiToken = ISushiBar(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2); // SUSHI token contract
    ISushiBar constant sushiBar = ISushiBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272); // xSUSHI staking contract for SUSHI
    IAaveDepositWithdraw constant aave = IAaveDepositWithdraw(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9); // Aave lending pool contract for xSUSHI staking into aXSUSHI
    IAaveDepositWithdraw constant aaveSushiToken = IAaveDepositWithdraw(0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a); // aXSUSHI staking contract for xSUSHI
    
    constructor() public {
        sushiToken.approve(address(sushiSwapRouter), type(uint256).max); // max approve `sushiSwapRouter` spender to swap SUSHI into ETH from this contract
        sushiToken.approve(address(sushiBar), type(uint256).max); // max approve `sushiBar` spender to stake SUSHI into xSUSHI from this contract
        sushiBar.approve(address(aave), type(uint256).max); // max approve `aave` spender to stake xSUSHI into aXSUSHI from this contract
    }
    
    /*************
    ETH -> AXSUSHI 
    *************/
    /// @dev fallback - stake ETH `msg.value` into aXSUSHI by batching calls to `sushiSwapRouter`, `sushiBar` and `aave` lending pool.
    receive() external payable {
        address[] memory path = new address[](2); // load ETH-SUSHI swap `path` for `sushiSwapRouter`
        path[0] = wETH;
        path[1] = address(sushiToken);
        sushiSwapRouter.swapExactETHForTokens{value: msg.value}(0, path, address(this), block.timestamp + 1200); // swap `msg.value` ETH into SUSHI with 20 minute deadline
        sushiBar.enter(sushiToken.balanceOf(address(this))); // stake resulting SUSHI into `sushiBar` xSUSHI
        aave.deposit(address(sushiBar), sushiBar.balanceOf(address(this)), msg.sender, 0); // stake resulting xSUSHI into `aave` aXSUSHI - transfer to `msg.sender`
    }
    
    /// @dev stake ETH `msg.value` into aXSUSHI by batching calls to `sushiSwapRouter`, `sushiBar` and `aave` lending pool.
    function swaave() external payable {
        address[] memory path = new address[](2); // load ETH-SUSHI swap `path` for `sushiSwapRouter`
        path[0] = wETH;
        path[1] = address(sushiToken);
        sushiSwapRouter.swapExactETHForTokens{value: msg.value}(0, path, address(this), block.timestamp + 1200); // swap `msg.value` ETH into SUSHI with 20 minute deadline
        sushiBar.enter(sushiToken.balanceOf(address(this))); // stake resulting SUSHI into `sushiBar` xSUSHI
        aave.deposit(address(sushiBar), sushiBar.balanceOf(address(this)), msg.sender, 0); // stake resulting xSUSHI into `aave` aXSUSHI - transfer to `msg.sender`
    }
    
    /// @dev stake ETH `msg.value` into aXSUSHI for benefit of `to` by batching calls to `sushiSwapRouter`, `sushiBar` and `aave` lending pool.
    function swaaveTo(address to) external payable {
        address[] memory path = new address[](2); // load ETH-SUSHI swap `path` for `sushiSwapRouter`
        path[0] = wETH;
        path[1] = address(sushiToken);
        sushiSwapRouter.swapExactETHForTokens{value: msg.value}(0, path, address(this), block.timestamp + 1200); // swap `msg.value` ETH into SUSHI with 20 minute deadline
        sushiBar.enter(sushiToken.balanceOf(address(this))); // stake resulting SUSHI into `sushiBar` xSUSHI
        aave.deposit(address(sushiBar), sushiBar.balanceOf(address(this)), to, 0); // stake resulting xSUSHI into `aave` aXSUSHI - transfer to `to`
    }
    
    /*************
    AXSUSHI -> ETH 
    *************/
    /// @dev unstake aXSUSHI `amount` into ETH by batching calls to `aave` lending pool, `sushiBar` and `sushiSwapRouter`.
    function unSwaave(uint256 amount) external {
        aaveSushiToken.transferFrom(msg.sender, address(this), amount); // deposit `msg.sender` aXSUSHI `amount` into this contract
        aave.withdraw(address(sushiBar), amount, address(this)); // unstake deposited aXSUSHI `amount` from `aave` into xSUSHI
        sushiBar.leave(amount); // unstake resulting xSUSHI `amount` from `sushiBar` into SUSHI
        address[] memory path = new address[](2); // load SUSHI-ETH swap `path` for `sushiSwapRouter`
        path[0] = address(sushiToken);
        path[1] = wETH;
        sushiSwapRouter.swapExactTokensForETH(sushiToken.balanceOf(address(this)), 0, path, msg.sender, block.timestamp + 1200); // swap resulting SUSHI into ETH with 20 minute deadline - transfer to `msg.sender`
    }
    
    /// @dev unstake aXSUSHI `amount` into ETH for benefit of `to` by batching calls to `aave` lending pool, `sushiBar` and `sushiSwapRouter`.
    function unSwaaveTo(address to, uint256 amount) external {
        aaveSushiToken.transferFrom(msg.sender, address(this), amount); // deposit `msg.sender` aXSUSHI `amount` into this contract
        aave.withdraw(address(sushiBar), amount, address(this)); // unstake deposited aXSUSHI `amount` from `aave` into xSUSHI
        sushiBar.leave(amount); // unstake resulting xSUSHI `amount` from `sushiBar` into SUSHI
        address[] memory path = new address[](2); // load SUSHI-ETH swap `path` for `sushiSwapRouter`
        path[0] = address(sushiToken);
        path[1] = wETH;
        sushiSwapRouter.swapExactTokensForETH(sushiToken.balanceOf(address(this)), 0, path, to, block.timestamp + 1200); // swap resulting SUSHI into ETH with 20 minute deadline - transfer to `to`
    }
    
    /***************
    SUSHI -> AXSUSHI 
    ***************/
    /// @dev stake SUSHI `amount` into aXSUSHI by batching calls to `sushiBar` and `aave` lending pool.
    function saave(uint256 amount) external {
        sushiToken.transferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        sushiBar.enter(amount); // stake deposited SUSHI `amount` into `sushiBar` xSUSHI
        aave.deposit(address(sushiBar), sushiBar.balanceOf(address(this)), msg.sender, 0); // stake resulting xSUSHI into `aave` aXSUSHI - transfer to `msg.sender`
    }
    
    /// @dev stake SUSHI `amount` into aXSUSHI for benefit of `to` by batching calls to `sushiBar` and `aave` lending pool.
    function saaveTo(address to, uint256 amount) external {
        sushiToken.transferFrom(msg.sender, address(this), amount); // deposit `msg.sender` SUSHI `amount` into this contract
        sushiBar.enter(amount); // stake deposited SUSHI `amount` into `sushiBar` xSUSHI
        aave.deposit(address(sushiBar), sushiBar.balanceOf(address(this)), to, 0); // stake resulting xSUSHI into `aave` aXSUSHI - transfer to `to`
    }
    
    /***************
    AXSUSHI -> SUSHI 
    ***************/
    /// @dev unstake aXSUSHI `amount` into SUSHI by batching calls to `aave` lending pool and `sushiBar`.
    function unSaave(uint256 amount) external {
        aaveSushiToken.transferFrom(msg.sender, address(this), amount); // deposit `msg.sender` aXSUSHI `amount` into this contract
        aave.withdraw(address(sushiBar), amount, address(this)); // unstake deposited aXSUSHI `amount` from `aave` into xSUSHI
        sushiBar.leave(amount); // unstake resulting xSUSHI `amount` from `sushiBar` into SUSHI
        sushiToken.transfer(msg.sender, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `msg.sender`
    }
    
    /// @dev unstake aXSUSHI `amount` into SUSHI for benefit of `to` by batching calls to `aave` lending pool and `sushiBar`.
    function unSaaveTo(address to, uint256 amount) external {
        aaveSushiToken.transferFrom(msg.sender, address(this), amount); // deposit `msg.sender` aXSUSHI `amount` into this contract
        aave.withdraw(address(sushiBar), amount, address(this)); // unstake deposited aXSUSHI `amount` from `aave` into xSUSHI
        sushiBar.leave(amount); // unstake resulting xSUSHI `amount` from `sushiBar` into SUSHI
        sushiToken.transfer(to, sushiToken.balanceOf(address(this))); // transfer resulting SUSHI to `to`
    }
}