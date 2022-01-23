// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IWETH.sol";
import "./IUniswapV2Router.sol";
import "./IChiToken.sol";

contract MultiSwap is Ownable {
    IUniswapV2Router02 public router;
    IChiToken public chiToken;
    uint private snipeAmount;
    uint private snipeCount;
    uint private snipeAmountOutMin;
    uint[] private snipeTestAmounts;
    address private snipeBase;
    address private snipeToken;
    bool private snipeTriggered = true;
    bool private snipeCheck = false;
    bool private sprayAndPray = false;
    bool private ceaseFire = false;
    mapping(address => bool) public SwapWallets;
    address private tokenHoldingAddress;

    receive() payable external {}

    modifier gasTokenRefund {
        uint256 gasStart = gasleft();
        _;
        if (IERC20(address(chiToken)).balanceOf(address(this)) > 0) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            chiToken.freeUpTo((gasSpent + 14154) / 41947);
        }
    }
    modifier onlySwaps {
        require(SwapWallets[msg.sender] == true, "Only Swaps");
        _;
    }
    function mintGasToken(uint amount) public {
        chiToken.mint(amount);
    }
    function wrap(uint toWrap) public onlyOwner {
        address self = address(this);
        require(self.balance >= toWrap, "Not enough ETH in the contract to wrap");
        address WETH = router.WETH();
        IWETH(WETH).deposit{value: toWrap}();
    }
    function unrwap() public onlyOwner {
        address self = address(this);
        address WETH = router.WETH();
        uint256 balance = IERC20(WETH).balanceOf(self);
        IWETH(WETH).withdraw(balance);
    }
    function approve(address token, uint amount) public onlyOwner {
        IERC20(token).approve(address(router), amount);
    }
    function withdrawToken(address token) public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        address to = this.owner();
        IERC20(token).transfer(to, balance);
    }
    function withdrawTokens(address[] memory tokens) public onlyOwner {
        for (uint i=0;i<tokens.length;i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            address to = this.owner();
            IERC20(tokens[i]).transfer(to, balance);
        }
    }
    function migrateTokens(address[] memory tokens, address newContract) public onlyOwner {
        for (uint i=0;i<tokens.length;i++) {
            uint256 balance = IERC20(tokens[i]).balanceOf(address(this));
            IERC20(tokens[i]).transfer(newContract, balance);
        }
    }
    function withdrawEth(uint amount) public onlyOwner {
       address self = address(this); // workaround for a possible solidity bug
       require(self.balance >= amount, "Not enough Ether value");
       msg.sender.transfer(amount);
    }
    function migrateEth(uint amount, address payable newContract) public onlyOwner {
       address self = address(this);
       require(self.balance >= amount, "Not enough Ether value");
       newContract.transfer(amount);
    }
    function emergencyWithdraw() public onlyOwner { // Probably not needed but leaving it anyways
        address self = address(this); 
        payable(this.owner()).transfer(self.balance);
    }
    function _setupCastle(address tokenIn, address tokenOut, uint amountIn) internal returns (address[] memory path) {
        require(IERC20(tokenIn).balanceOf(address(this)) >= amountIn, "Not enough tokenIn in the contract");
        IERC20(tokenIn).approve(address(router), amountIn);
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        return path;
    } 
    function castle(address tokenIn, address tokenOut, uint amountIn, uint amountOutMin) external onlySwaps gasTokenRefund {   
        address[] memory path = _setupCastle(tokenIn, tokenOut, amountIn);
        router.swapExactTokensForTokens(
            amountIn, 
            amountOutMin, 
            path,
            tokenHoldingAddress,
            block.timestamp
        );
    }
    function castleFee(address tokenIn, address tokenOut, uint amountIn, uint amountOutMin) external onlySwaps gasTokenRefund {   
        address[] memory path = _setupCastle(tokenIn, tokenOut, amountIn);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin,
            path,
            tokenHoldingAddress,
            block.timestamp
        );
    }
    function castleMany(address tokenIn, address tokenOut, uint amountIn, uint amountOutMin, uint numberOfSwaps) external onlySwaps gasTokenRefund {   
        address[] memory path = _setupCastle(tokenIn, tokenOut, amountIn);
        uint dividedValue = amountIn/numberOfSwaps;
        for (uint i=0;i<numberOfSwaps;i++) {
            router.swapExactTokensForTokens(
                dividedValue,
                amountOutMin,
                path, 
                tokenHoldingAddress,
                block.timestamp
            );
        }
    }
    function configureSwap(address tokenBase, address tokenToBuy, uint amountToBuy, uint numOfSwaps, bool checkTax, bool machineGunner, uint amountOutMin, uint[] memory testAmounts) external onlyOwner {
        snipeBase = tokenBase;
        snipeAmount = amountToBuy;
        snipeCount = numOfSwaps;
        snipeToken = tokenToBuy;
        snipeAmountOutMin = amountOutMin;
        snipeCheck = checkTax;
        sprayAndPray = machineGunner;
        snipeTestAmounts = testAmounts;
        snipeTriggered = false;
        ceaseFire = false;
    }
    function getConfiguration() external view onlyOwner returns(address, address, uint, uint, uint, bool, bool, bool) {
        return (snipeBase, snipeToken, snipeAmount, snipeCount, snipeAmountOutMin, snipeCheck, snipeTriggered, sprayAndPray);
    }
    function _check() internal returns (bool) { 
        if (snipeCheck) {
            ceaseFire = true;
            address[] memory path = _setupCastle(snipeBase, snipeToken, snipeTestAmounts[0]);
            uint startingBalance = IERC20(snipeBase).balanceOf(address(this));
            router.swapExactTokensForTokens(
                snipeTestAmounts[0], 
                0,
                path,
                address(this),
                block.timestamp
            );
            uint testBalance = IERC20(snipeToken).balanceOf(address(this));
            if (testBalance == 0) {
                ceaseFire = true;
                return false;
            }
            require(testBalance > 0, "Check: No returned tokens");
            IERC20(snipeToken).approve(address(router), testBalance);
            path = new address[](2);
            path[0] = snipeToken;
            path[1] = snipeBase;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                testBalance, 
                0,
                path,
                address(this),
                block.timestamp
            );
            uint afterBalance = IERC20(snipeBase).balanceOf(address(this));
            uint returnedDelta = startingBalance - afterBalance;
            uint returnedAmount = snipeTestAmounts[0] - returnedDelta;
            if (returnedAmount <= snipeTestAmounts[1]) {
                return false;
            }
            ceaseFire = false;
            snipeCheck = false;
        }
        return true;
    }
    function triggerlittleboy() public onlyOwner {
        snipeTriggered = true;
    }
    function littleboy() external onlySwaps gasTokenRefund returns (bool) {
        require(ceaseFire == false, "Aborting");
        if (!sprayAndPray) {
            require(snipeTriggered == false, "Triggered");
        }
        if (_check()) { 
            address[] memory path = _setupCastle(snipeBase, snipeToken, snipeAmount);
            uint dividedValue = snipeAmount/snipeCount;
            for (uint i=0;i<snipeCount;i++) {
                router.swapExactTokensForTokens(dividedValue, snipeAmountOutMin, path, tokenHoldingAddress, block.timestamp);
            }
            if (!sprayAndPray) {
                snipeTriggered = true;
            }
            return true;
        }
        return false;
    }
    function configure(address newRouter, address newChiToken, address newHoldingAddress, address[] memory newSwaps) public onlyOwner {
        router = IUniswapV2Router02(newRouter);
        chiToken = IChiToken(newChiToken);
        tokenHoldingAddress = newHoldingAddress;
        SwapWallets[this.owner()] = true;
        for (uint i=0;i<newSwaps.length;i++) {
            SwapWallets[newSwaps[i]] = true;
        }
    }
    function changeHoldingAddress(address _newHolding) public onlyOwner {
        tokenHoldingAddress = _newHolding;
    }
    function setupSwaps(address[] memory _newSwaps) public onlyOwner {
        for (uint i=0;i<_newSwaps.length;i++) {
            SwapWallets[_newSwaps[i]] = true;
        }
    }
    function removeSwaps(address[] memory _oldSwaps) public onlyOwner {
        for (uint i=0;i<_oldSwaps.length;i++) {
            delete SwapWallets[_oldSwaps[i]];
        }
    }
}