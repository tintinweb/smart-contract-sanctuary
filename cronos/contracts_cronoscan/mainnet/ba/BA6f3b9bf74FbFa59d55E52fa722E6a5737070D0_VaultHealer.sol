// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "./QuartzUniV2Zap.sol";
import "./VaultHealerBoostedPools.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract VaultHealer is VaultHealerBoostedPools, Multicall {

    address immutable public zap;

    constructor(address _vhAuth, address _feeMan, address _zap)
        VaultHealerBase(_vhAuth, _feeMan)
        ERC1155("")
    {
        zap = _zap;
    }

   function isApprovedForAll(address account, address operator) public view override(ERC1155, IERC1155) returns (bool) {
        return super.isApprovedForAll(account, operator) || operator == address(zap);
   }

    function setURI(string calldata _uri) external auth {
        _setURI(_uri);
    }

    function stakedWantTokens(address account, uint vid) public view returns (uint) {
        uint shares = account == address(0) ? 0 : balanceOf(account, vid);
        return shares == 0 ? 0 : wantLockedTotal(vid) * shares / totalSupply[vid];
    }
    
    function tokenData(address account, uint[] calldata vids) external view returns (uint[4][] memory data) {
        /*[0]: user staked want tokens
          [1]: user shares (balanceOf)
          [2]: wantLockedTotal
          [3]: totalSupply
        */

        uint len = vids.length;
        data = new uint[4][](len);

        for (uint i; i < vids.length; i++) {
            uint vid = vids[i];
            uint supply = totalSupply[vid];
            if (supply == 0) continue;
            data[i][3] = supply;
            uint wlt = wantLockedTotal(vid);
            data[i][2] = wlt;
            if (account == address(0)) continue;
            uint bal = balanceOf(account, vid);
            data[i][1] = bal;
            data[i][0] = bal * wlt / supply;
        }
    }
    function wantLockedTotal(uint vid) public view returns (uint) {
        return strat(vid).wantLockedTotal();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || interfaceId == type(IVaultHealer).interfaceId;
    }

    //This contract should not hold ERC20 tokens at the end of a transaction. If this happens due to some error, this will send the 
    //tokens to the treasury if it is set. Contact the team for help, and maybe they can return your missing token!
    function rescue(address token) external {
        (address receiver,) = vaultFeeManager.getWithdrawFee(0);
        if (receiver == address(0)) receiver = msg.sender;
        IERC20(token).transfer(receiver, IERC20(token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: GPLv2

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

// @author Wivern for Beefy.Finance, ToweringTopaz for Crystl.Finance
// @notice This contract adds liquidity to Uniswap V2 compatible liquidity pair pools and stake.

pragma solidity ^0.8.14;

import "./libraries/LibQuartz.sol";

contract QuartzUniV2Zap {
    using SafeERC20 for IERC20;
    using LibQuartz for IVaultHealer;
    using VaultChonk for IVaultHealer;

    uint256 public constant MINIMUM_AMOUNT = 1000;
    IVaultHealer public immutable vaultHealer;

    mapping(IERC20 => bool) private approvals;

    constructor(address _vaultHealer) {
        vaultHealer = IVaultHealer(_vaultHealer);
    }

    receive() external payable {
        require(Address.isContract(msg.sender));
    }

    function quartzInETH (uint vid, uint256 tokenAmountOutMin) external payable {
        require(msg.value >= MINIMUM_AMOUNT, 'Quartz: Insignificant input amount');
        
        IWETH weth = vaultHealer.getRouter(vid).WETH();
        
        weth.deposit{value: msg.value}();

        _swapAndStake(vid, tokenAmountOutMin, weth);
    }

    function estimateSwap(uint vid, IERC20 tokenIn, uint256 fullInvestmentIn) external view returns(uint256 swapAmountIn, uint256 swapAmountOut, IERC20 swapTokenOut) {
        return LibQuartz.estimateSwap(vaultHealer, vid, tokenIn, fullInvestmentIn);
    }

    function quartzIn (uint vid, uint256 tokenAmountOutMin, IERC20 tokenIn, uint256 tokenInAmount) external {
        uint allowance = tokenIn.allowance(msg.sender, address(this));
        uint balance = tokenIn.balanceOf(msg.sender);

        if (tokenInAmount == type(uint256).max) tokenInAmount = allowance < balance ? allowance : balance;
        else {
            require(allowance >= tokenInAmount, 'Quartz: Input token is not approved');
            require(balance >= tokenInAmount, 'Quartz: Input token has insufficient balance');
        }
        require(tokenInAmount >= MINIMUM_AMOUNT, 'Quartz: Insignificant input amount');
        
        tokenIn.safeTransferFrom(msg.sender, address(this), tokenInAmount);
        require(tokenIn.balanceOf(address(this)) >= tokenInAmount, 'Quartz: Fee-on-transfer/reflect tokens not yet supported');

        _swapAndStake(vid, tokenAmountOutMin, tokenIn);
    }

    //should only happen when this contract deposits as a maximizer
    function onERC1155Received(
        address operator, address /*from*/, uint256 /*id*/, uint256 /*amount*/, bytes calldata) external view returns (bytes4) {
        //if (msg.sender != address(vaultHealer)) revert("Quartz: Incorrect ERC1155 issuer");
        if (operator != address(this)) revert("Quartz: Improper ERC1155 transfer"); 
        return 0xf23a6e61;
    }

    function quartzOut (uint vid, uint256 withdrawAmount) public {
        (IUniRouter router,, IUniPair pair, bool isPair) = vaultHealer.getRouterAndPair(vid);
        if (withdrawAmount > 0) {
            uint[4] memory data = vaultHealer.tokenData(msg.sender, asSingletonArray(vid))[0];
            vaultHealer.safeTransferFrom(
                msg.sender, 
                address(this), 
                vid, 
                withdrawAmount > data[0] ? //user want tokens
                    data[1] : //user shares
                    withdrawAmount * data[3] / data[2], //amt * totalShares / wantLockedTotal
                ""
            );
        } else if (vaultHealer.balanceOf(address(this), vid) == 0) return;

        vaultHealer.withdraw(vid, type(uint).max, "");
        if (vid > 2**16) quartzOut(vid >> 16, 0);

        IWETH weth = router.WETH();

        if (isPair) {
            IERC20 token0 = pair.token0();
            IERC20 token1 = pair.token1();
            if (token0 != weth && token1 != weth) {
                LibQuartz.removeLiquidity(pair, msg.sender);
            } else {
                LibQuartz.removeLiquidity(pair, address(this));
                returnAsset(token0, weth); //returns any leftover tokens to user
                returnAsset(token1, weth); //returns any leftover tokens to user
            }
        } else {
            returnAsset(pair, weth);
        }
    }

    function _swapAndStake(uint vid, uint256 tokenAmountOutMin, IERC20 tokenIn) private {
        (IUniRouter router,,IUniPair pair, bool isPair) = vaultHealer.getRouterAndPair(vid);        
        
        IWETH weth = router.WETH();

        if (isPair) {
            IERC20 token0 = pair.token0();
            IERC20 token1 = pair.token1();

        //_approveTokenIfNeeded(tokenIn, router);

            if (token0 == tokenIn) {
                (uint256 reserveA, uint256 reserveB,) = pair.getReserves();
                LibQuartz.swapDirect(router, LibQuartz.getSwapAmount(router, tokenIn.balanceOf(address(this)), reserveA, reserveB), tokenIn, token1, tokenAmountOutMin);
            } else if (token1 == tokenIn) {
                (uint256 reserveA, uint256 reserveB,) = pair.getReserves();
                LibQuartz.swapDirect(router, LibQuartz.getSwapAmount(router, tokenIn.balanceOf(address(this)), reserveB, reserveA), tokenIn, token0, tokenAmountOutMin);
            } else {
                uint swapAmountIn = tokenIn.balanceOf(address(this))/2;
                
                if(LibQuartz.hasSufficientLiquidity(token0, tokenIn, router, MINIMUM_AMOUNT)) {
                    LibQuartz.swapDirect(router, swapAmountIn, tokenIn, token0, tokenAmountOutMin);
                } else {
                    LibQuartz.swapViaToken(router, swapAmountIn, tokenIn, weth, token0, tokenAmountOutMin);
                }
                
                if(LibQuartz.hasSufficientLiquidity(token1, tokenIn, router, MINIMUM_AMOUNT)) {
                    LibQuartz.swapDirect(router, swapAmountIn, tokenIn, token1, tokenAmountOutMin);
                } else {
                    LibQuartz.swapViaToken(router, swapAmountIn, tokenIn, weth, token1, tokenAmountOutMin);
                }

                returnAsset(tokenIn, weth);
            }
            
            LibQuartz.optimalMint(pair, token0, token1);
            returnAsset(token0, weth);
            returnAsset(token1, weth);
        } else {
            uint swapAmountIn = tokenIn.balanceOf(address(this));
            if(LibQuartz.hasSufficientLiquidity(pair, tokenIn, router, MINIMUM_AMOUNT)) {
                LibQuartz.swapDirect(router, swapAmountIn, tokenIn, pair, tokenAmountOutMin);
            } else {
                LibQuartz.swapViaToken(router, swapAmountIn, tokenIn, weth, pair, tokenAmountOutMin);
            }
            returnAsset(tokenIn, weth);
        }

        _approveTokenIfNeeded(pair);
        uint balance = pair.balanceOf(address(this));
        vaultHealer.deposit(vid, balance, "");
        
        balance = vaultHealer.balanceOf(address(this), vid);
        vaultHealer.safeTransferFrom(address(this), msg.sender, vid, balance, "");
    }


    function returnAsset(IERC20 token, IWETH weth) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;
        
        if (token == weth) {
            weth.withdraw(balance);
            (bool success,) = msg.sender.call{value: address(this).balance}(new bytes(0));
            require(success, 'Quartz: ETH transfer failed');
        } else {
            token.safeTransfer(msg.sender, balance);
        }
    }

    function _approveTokenIfNeeded(IERC20 token) private {
        if (!approvals[token]) {
            token.safeApprove(address(vaultHealer), type(uint256).max);
            approvals[token] = true;
        }
    }

    function asSingletonArray(uint256 n) internal pure returns (uint256[] memory tempArray) {
        tempArray = new uint256[](1);
        tempArray[0] = n;
    }

    //This contract should not hold ERC20 tokens at the end of a transaction. If this happens due to some error, this will send the 
    //tokens to the treasury if it is set. Contact the team for help, and maybe they can return your missing token!
    function rescue(IERC20 token) external {
        (address receiver,) = vaultHealer.vaultFeeManager().getWithdrawFee(0);
        if (receiver == address(0)) receiver = msg.sender;
        token.transfer(receiver, token.balanceOf(address(this)));
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./VaultHealerGate.sol";
import "./interfaces/IBoostPool.sol";

abstract contract VaultHealerBoostedPools is VaultHealerGate {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap activeBoosts;
    mapping(address => BitMaps.BitMap) userBoosts;
    
    function boostPool(uint _boostID) public view returns (IBoostPool) {
        return IBoostPool(Cavendish.computeAddress(bytes32(_boostID)));
    }
    
    function nextBoostPool(uint vid) external view returns (uint, IBoostPool) {
        return boostPoolVid(vid, vaultInfo[vid].numBoosts);
    }

    function boostPoolVid(uint vid, uint16 n) public view returns (uint, IBoostPool) {

        uint _boostID = (uint(bytes32(bytes4(0xB0057000 + n))) | vid);
        return (_boostID, boostPool(_boostID));
    }

    function createBoost(uint vid, address _implementation, bytes calldata initdata) external requireValidVid(vid) auth {
        VaultChonk.createBoost(vaultInfo, activeBoosts, vid, _implementation, initdata);
    }

    //Users can enableBoost to opt-in to a boosted vault
    function enableBoost(address _user, uint _boostID) public nonReentrant {
		
        if (msg.sender != _user && !isApprovedForAll(_user, msg.sender)) revert NotApprovedToEnableBoost(_user, msg.sender);
        if (!activeBoosts.get(_boostID)) revert BoostPoolNotActive(_boostID);
        if (userBoosts[_user].get(_boostID)) revert BoostPoolAlreadyJoined(_user, _boostID);
        userBoosts[_user].set(_boostID);

        boostPool(_boostID).joinPool(_user, uint112(balanceOf(_user, uint224(_boostID))));
        emit EnableBoost(_user, _boostID);
    }

    //Standard opt-in function users will call
    function enableBoost(uint _boostID) external {
        enableBoost(msg.sender, _boostID);
    }

    function harvestBoost(uint _boostID) external nonReentrant {
        boostPool(_boostID).harvest(msg.sender);
    }

    //In case of a buggy boost pool, users can opt out at any time but lose the boost rewards
    function emergencyBoostWithdraw(uint _boostID) external nonReentrant {
        if (!userBoosts[msg.sender].get(_boostID)) revert BoostPoolNotJoined(msg.sender, _boostID);
        try boostPool(_boostID).emergencyWithdraw{gas: 2**19}(msg.sender) returns (bool success) {
            if (!success) activeBoosts.unset(_boostID); //Disable boost if the pool is broken
        } catch {
            activeBoosts.unset(_boostID);
        }
        userBoosts[msg.sender].unset(_boostID);
        emit BoostEmergencyWithdraw(msg.sender, _boostID);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        //If boosted pools are affected, update them
        
        for (uint i; i < ids.length; i++) {
            uint vid = ids[i];
            uint numBoosts = vaultInfo[vid].numBoosts;
            for (uint16 k; k < numBoosts; k++) { //Loop through all of the transferred token's boostpools (if any)
                updateBoostPool(vid, k, from, to, amounts[i]);
            }
        }
        
    }

    function updateBoostPool(uint vid, uint16 n, address from, address to, uint amount) private {
        (uint boostID, IBoostPool pool) = boostPoolVid(vid, n); //calculate address and ID for pool
        from = from == address(0) || userBoosts[from].get(boostID) ? from : address(0);
        to = to == address(0) || userBoosts[to].get(boostID) ? to : address(0);

        if ((from != address(0) || to != address(0)) && pool.notifyOnTransfer(from, to, amount)) {// Is the pool closed?
            activeBoosts.unset(boostID); //close finished pool
            userBoosts[from].unset(boostID); //pool finished for "from"
            userBoosts[to].unset(boostID); //pool finished for "to"
        }
    }

    function boostInfo(address account, uint vid) external view returns (
        BoostInfo[] memory active, //user is in these pools; pools are still earning
        BoostInfo[] memory finished, //user is in these pools; pool is finished so user needs to make final harvest
        BoostInfo[] memory available //user could join these pools and earn
    ) {
        BoostInfo[][3] memory boosts = VaultChonk.boostInfo(vaultInfo[vid].numBoosts, activeBoosts, userBoosts[account], account, vid);
        (active, finished, available) = (boosts[0], boosts[1], boosts[2]);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPLv2

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.

// @author Wivern for Beefy.Finance, ToweringTopaz for Crystl.Finance
// @notice This contract adds liquidity to Uniswap V2 compatible liquidity pair pools and stake.

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./VaultChonk.sol";
import "../interfaces/IUniRouter.sol";

library LibQuartz {
    using SafeERC20 for IERC20;
    using SafeERC20 for IUniPair;
    using VaultChonk for IVaultHealer;

    uint256 constant MINIMUM_AMOUNT = 1000;
    
    function getRouter(IVaultHealer vaultHealer, uint vid) internal view returns (IUniRouter) {
        return vaultHealer.strat(vid).router();
    }
    
    function getRouterAndPair(IVaultHealer vaultHealer, uint _vid) internal view returns (IUniRouter router, IStrategy strat, IUniPair pair, bool valid) {
        strat = vaultHealer.strat(_vid);
        router = strat.router();
        pair = IUniPair(address(strat.wantToken()));

        try pair.factory() returns (IUniFactory _f) {
            valid = _f == router.factory();
            require(valid, "Quartz: This vault cannot be zapped"); //Risk of illiquid pair loss here, so we shouldn't zap
        } catch {

        }
    }
    function getSwapAmount(IUniRouter router, uint256 investmentA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 swapAmount) {
        uint256 halfInvestment = investmentA / 2;
        uint256 numerator = router.getAmountOut(halfInvestment, reserveA, reserveB);
        uint256 denominator = router.quote(halfInvestment, reserveA + halfInvestment, reserveB - numerator);
        swapAmount = investmentA - sqrt(halfInvestment * halfInvestment * numerator / denominator);
    }
    function returnAssets(IUniRouter router, IERC20[] memory tokens) internal {
        IWETH weth = router.WETH();
        
        
        for (uint256 i; i < tokens.length; i++) {
            uint256 balance = tokens[i].balanceOf(address(this));
            if (balance == 0) continue;
            if (tokens[i] == weth) {
                weth.withdraw(balance);
                (bool success,) = msg.sender.call{value: balance}(new bytes(0));
                require(success, 'Quartz: ETH transfer failed');
            } else {
                tokens[i].safeTransfer(msg.sender, balance);
            }
        }
    
    }

    function swapDirect(
        IUniRouter _router,
        uint256 _amountIn,
        IERC20 input,
        IERC20 output,
        uint amountOutMin
    ) public returns (uint amountOutput) {
        IUniFactory factory = _router.factory();

        IUniPair pair = factory.getPair(input, output);
        input.safeTransfer(address(pair), _amountIn);
        uint balanceBefore = output.balanceOf(address(this));

        bool inputIsToken0 = input < output;
        
        (uint reserve0, uint reserve1,) = pair.getReserves();

        (uint reserveInput, uint reserveOutput) = inputIsToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountInput = input.balanceOf(address(pair)) - reserveInput;
        amountOutput = _router.getAmountOut(amountInput, reserveInput, reserveOutput);

        (uint amount0Out, uint amount1Out) = inputIsToken0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
        
        pair.swap(amount0Out, amount1Out, address(this), "");
    
        if (output.balanceOf(address(this)) <= amountOutMin + balanceBefore) {
            unchecked {
                revert IStrategy.InsufficientOutputAmount(output.balanceOf(address(this)) - balanceBefore, amountOutMin);
            }
        }
    }

    function swapViaToken(
        IUniRouter _router,
        uint256 _amountIn,
        IERC20 input,
        IERC20 middle,
        IERC20 output,
        uint amountOutMin
    ) public returns (uint amountOutput) {
        IUniFactory factory = _router.factory();

        IUniPair pairA = factory.getPair(input, middle);
        IUniPair pairB = factory.getPair(middle, output);        
        input.safeTransfer(address(pairA), _amountIn);

        uint balanceBefore = output.balanceOf(address(this));

        {
            {
                (uint reserve0, uint reserve1,) = pairA.getReserves();        
                (uint reserveInput, uint reserveOutput) = (input < middle) ? (reserve0, reserve1) : (reserve1, reserve0);
                uint amountInput = input.balanceOf(address(pairA)) - reserveInput;
                amountOutput = _router.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = (input < middle) ? (uint(0), amountOutput) : (amountOutput, uint(0));
            pairA.swap(amount0Out, amount1Out, address(pairB), "");
        }
        {
            {
                (uint reserve0, uint reserve1,) = pairB.getReserves();
                (uint reserveInput, uint reserveOutput) = (middle < output) ? (reserve0, reserve1) : (reserve1, reserve0);
                uint amountInput = middle.balanceOf(address(pairB)) - reserveInput;
                amountOutput = _router.getAmountOut(amountInput, reserveInput, reserveOutput);
            }

            (uint amount0Out, uint amount1Out) = (middle < output) ? (uint(0), amountOutput) : (amountOutput, uint(0));
            pairB.swap(amount0Out, amount1Out, address(this), "");
        }

        if (output.balanceOf(address(this)) <= amountOutMin + balanceBefore) {
            unchecked {
                revert IStrategy.InsufficientOutputAmount(output.balanceOf(address(this)) - balanceBefore, amountOutMin);
            }
        }
    }

    function estimateSwap(IVaultHealer vaultHealer, uint pid, IERC20 tokenIn, uint256 fullInvestmentIn) public view returns(uint256 swapAmountIn, uint256 swapAmountOut, IERC20 swapTokenOut) {
        (IUniRouter router,,IUniPair pair,bool isPair) = getRouterAndPair(vaultHealer, pid);
        
        require(isPair, "Quartz: Cannot estimate swap for non-LP token");

        IERC20 token0 = pair.token0();

        (uint256 reserveA, uint256 reserveB,) = pair.getReserves();
        if (token0 == tokenIn) {
            swapTokenOut = pair.token1();
        } else {
            require(pair.token1() == tokenIn, 'Quartz: Input token not present in liquidity pair');
            swapTokenOut = token0;
            (reserveA, reserveB) = (reserveB, reserveA);
        }

        swapAmountIn = getSwapAmount(router, fullInvestmentIn, reserveA, reserveB);
        swapAmountOut = router.getAmountOut(swapAmountIn, reserveA, reserveB);
    }

    function removeLiquidity(IUniPair pair, address to) internal {
        uint balance = pair.balanceOf(address(this));

        if (balance == 0) return;
        pair.safeTransfer(address(pair), balance);
        (uint256 amount0, uint256 amount1) = pair.burn(to);

        require(amount0 >= MINIMUM_AMOUNT, 'Quartz: INSUFFICIENT_A_AMOUNT');
        require(amount1 >= MINIMUM_AMOUNT, 'Quartz: INSUFFICIENT_B_AMOUNT');
    }

    function optimalMint(IUniPair pair, IERC20 token0, IERC20 token1) public returns (uint liquidity) {
        (token0, token1) = token0 < token1 ? (token0, token1) : (token1, token0);
        
        pair.skim(address(this));
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        uint balance0 = token0.balanceOf(address(this));
        uint balance1 = token1.balanceOf(address(this));

        if (balance0 * reserve1 < balance1 * reserve0) {
            balance1 = balance0 * reserve1 / reserve0;
        } else {
            balance0 = balance1 * reserve0 / reserve1;
        }

        token0.safeTransfer(address(pair), balance0);
        token1.safeTransfer(address(pair), balance1);
        liquidity = pair.mint(address(this));
    }

    function hasSufficientLiquidity(IERC20 token0, IERC20 token1, IUniRouter router, uint256 min_amount) internal view returns (bool hasLiquidity) {
        IUniFactory factory = router.factory();
        IUniPair pair = IUniPair(factory.getPair(token0, token1));
        if (address(pair) == address(0)) return false; //pair hasn't been created, so zero liquidity
		
        (uint256 reserveA, uint256 reserveB,) = pair.getReserves();

        return reserveA > min_amount && reserveB > min_amount;
    }

    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        unchecked { //impossible for any of this to overflow
            if (x == 0) return 0;
            // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
            // however that code costs significantly more gas
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return (r < r1 ? r : r1);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "../interfaces/IVaultHealer.sol";
import "../interfaces/IBoostPool.sol";
import "./Cavendish.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

library VaultChonk {
    using BitMaps for BitMaps.BitMap;

    event AddVault(uint indexed vid);
    event AddBoost(uint indexed boostid);

    function createVault(mapping(uint => IVaultHealer.VaultInfo) storage vaultInfo, uint vid, IStrategy _implementation, bytes calldata data) external {
        addVault(vaultInfo, vid, _implementation, data);
    }
	
    function createMaximizer(mapping(uint => IVaultHealer.VaultInfo) storage vaultInfo, uint targetVid, bytes calldata data) external returns (uint vid) {
		if (targetVid >= 2**208) revert IVaultHealer.MaximizerTooDeep(targetVid);
        IVaultHealer.VaultInfo storage targetVault = vaultInfo[targetVid];
        uint16 nonce = targetVault.numMaximizers + 1;
        vid = (targetVid << 16) | nonce;
        targetVault.numMaximizers = nonce;
        addVault(vaultInfo, vid, strat(targetVid).getMaximizerImplementation(), data);
    }

    function addVault(mapping(uint => IVaultHealer.VaultInfo) storage vaultInfo, uint256 vid, IStrategy implementation, bytes calldata data) private {
        //
        if (!implementation.supportsInterface(type(IStrategy).interfaceId) //doesn't support interface
            || implementation.implementation() != implementation //is proxy
        ) revert IVaultHealer.NotStrategyImpl(implementation);
        IVaultHealer implVaultHealer = implementation.vaultHealer();
        if (address(implVaultHealer) != address(this)) revert IVaultHealer.ImplWrongHealer(implVaultHealer);

        IStrategy _strat = IStrategy(Cavendish.clone(address(implementation), bytes32(uint(vid))));
        _strat.initialize(abi.encodePacked(vid, data));
        vaultInfo[vid].want = _strat.wantToken();
        vaultInfo[vid].active = true; //uninitialized vaults are paused; this unpauses
        emit AddVault(vid);
    }

    function createBoost(mapping(uint => IVaultHealer.VaultInfo) storage vaultInfo, BitMaps.BitMap storage activeBoosts, uint vid, address _implementation, bytes calldata initdata) external {
        if (vid >= 2**224) revert IVaultHealer.MaximizerTooDeep(vid);
        IVaultHealer.VaultInfo storage vault = vaultInfo[vid];
        uint16 nonce = vault.numBoosts;
        vault.numBoosts = nonce + 1;

        uint _boostID = (uint(bytes32(bytes4(0xB0057000 + nonce))) | vid);

        IBoostPool _boost = IBoostPool(Cavendish.clone(_implementation, bytes32(_boostID)));

        _boost.initialize(msg.sender, _boostID, initdata);
        activeBoosts.set(_boostID);
        emit AddBoost(_boostID);
    }

    //Computes the strategy address for any vid based on this contract's address and the vid's numeric value
    function strat(uint vid) internal view returns (IStrategy) {
        if (vid == 0) revert IVaultHealer.VidOutOfRange(0);
        return IStrategy(Cavendish.computeAddress(bytes32(vid)));
    }

    function strat(IVaultHealer vaultHealer, uint256 vid) internal pure returns (IStrategy) {
        if (vid == 0) revert IVaultHealer.VidOutOfRange(0);
        return IStrategy(Cavendish.computeAddress(bytes32(vid), address(vaultHealer)));
    }
	
    function boostInfo(
        uint16 len,
        BitMaps.BitMap storage activeBoosts, 
        BitMaps.BitMap storage userBoosts,
        address account,
        uint vid
    ) external view returns (
        IVaultHealer.BoostInfo[][3] memory boosts //active, finished, available
    ) {
        //Create bytes array indicating status of each boost pool and total number for each status
        bytes memory statuses = new bytes(len);
        uint numActive;
        uint numFinished;
        uint numAvailable;
        for (uint16 i; i < len; i++) {
            uint id = uint(bytes32(bytes4(0xB0057000 + i))) | vid;
            bytes1 status;

            if (userBoosts.get(id)) status = 0x01; //pool active for user
            if (activeBoosts.get(id) && boostPool(id).isActive()) status |= 0x02; //pool still paying rewards
            
            if (status == 0x00) continue; //pool finished, user isn't in, nothing to do
            else if (status == 0x01) numFinished++; //user in finished pool
            else if (status == 0x02) numAvailable++; //user not in active pool
            else numActive++; //user in active pool

            statuses[i] = status;
        }

        boosts[0] = new IVaultHealer.BoostInfo[](numActive);
        boosts[1] = new IVaultHealer.BoostInfo[](numFinished);
        boosts[2] = new IVaultHealer.BoostInfo[](numAvailable);

        uint[3] memory infoIndex;

        for (uint16 i; i < len; i++) {
            uint8 status = uint8(statuses[i]);
            if (status == 0) continue; //pool is done and user isn't in
            status %= 3;
            
            (uint boostID, IBoostPool pool) = boostPoolVid(vid, i);

            IVaultHealer.BoostInfo memory info = boosts[status][infoIndex[status]++]; //reference to the output array member where we will be storing the data

            info.id = boostID;
            (info.rewardToken, info.pendingReward) = pool.pendingReward(account);
        }
    }

    function boostPool(uint _boostID) internal view returns (IBoostPool) {
        return IBoostPool(Cavendish.computeAddress(bytes32(_boostID)));
    }

    function boostPoolVid(uint vid, uint16 n) internal view returns (uint, IBoostPool) {

        uint _boostID = (uint(bytes32(bytes4(0xB0057000 + n))) | vid);
        return (_boostID, boostPool(_boostID));
    }

	function sizeOf(address _contract) external view returns (uint256 size) {
	
		assembly ("memory-safe") {
			size := extcodesize(_contract)
		}
	}

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IUniFactory.sol";
import "./IWETH.sol";

interface IUniRouter {
    function factory() external pure returns (IUniFactory);

    function WETH() external pure returns (IWETH);

    function addLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        IERC20 token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        IERC20 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        IERC20 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, IERC20[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, IERC20[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        IERC20 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        IERC20 token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        IERC20[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStrategy.sol";
import "./IVaultFeeManager.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./IBoostPool.sol";
import "../libraries/Cavendish.sol";

///@notice Interface for the Crystl v3 Vault central contract
interface IVaultHealer is IERC1155 {

    event AddVault(uint indexed vid);

    event Paused(uint indexed vid);
    event Unpaused(uint indexed vid);

    event Deposit(address indexed account, uint256 indexed vid, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 indexed vid, uint256 amount);

    event Earned(uint256 indexed vid, uint256 wantLockedTotal, uint256 totalSupply);
    event AddBoost(uint indexed boostid);
    event EnableBoost(address indexed user, uint indexed boostid);
    event BoostEmergencyWithdraw(address user, uint _boostID);
    event SetAutoEarn(uint indexed vid, bool earnBeforeDeposit, bool earnBeforeWithdraw);
    event FailedEarn(uint indexed vid, string reason);
    event FailedEarnBytes(uint indexed vid, bytes reason);
    event FailedWithdrawFee(uint indexed vid, string reason);
    event FailedWithdrawFeeBytes(uint indexed vid, bytes reason);
    event MaximizerHarvest(address indexed account, uint indexed vid, uint targetShares);
	
	error PausedError(uint256 vid); //Action cannot be completed on a paused vid
	error MaximizerTooDeep(uint256 targetVid); //Too many layers of nested maximizers (13 is plenty I should hope)
	error VidOutOfRange(uint256 vid); //Specified vid does not represent an existing vault
	error PanicCooldown(uint256 expiry); //Cannot panic this vault again until specified time
	error InvalidFallback(); //The fallback function should not be called in this context
	error WithdrawZeroBalance(address from); //User attempting to withdraw from a vault when they have zero shares
	error UnauthorizedPendingDepositAmount(); //Strategy attempting to pull more tokens from the user than authorized
    error RestrictedFunction(bytes4 selector);
    error NotStrategyImpl(IStrategy implementation);
    error ImplWrongHealer(IVaultHealer implHealer); //Attempting to use a strategy configured for another VH, not this one
    error InsufficientBalance(IERC20 token, address from, uint balance, uint requested);
    error InsufficientApproval(IERC20 token, address from, uint available, uint requested);

	error NotApprovedToEnableBoost(address account, address operator);
	error BoostPoolNotActive(uint256 _boostID);
	error BoostPoolAlreadyJoined(address account, uint256 _boostID);
	error BoostPoolNotJoined(address account, uint256 _boostID);
    error ArrayMismatch(uint lenA, uint lenB);

	error ERC1167_Create2Failed();	//Low-level error with creating a strategy proxy
	error ERC1167_ImplZeroAddress(); //If attempting to deploy a strategy with a zero implementation address
	
    ///@notice This is used solely by strategies to indirectly pull ERC20 tokens.
    function executePendingDeposit(address _to, uint192 _amount) external;
    ///@notice This is used solely by maximizer strategies to deposit their earnings
    function maximizerDeposit(uint256 _vid, uint256 _wantAmt, bytes calldata _data) external payable;
    ///@notice Compounds the listed vaults. Generally only needs to be called by an optimized earn script, not frontend users. Earn is triggered automatically on deposit and withdraw by default.
    function earn(uint256[] calldata vids) external returns (uint[] memory successGas);
    function earn(uint256[] calldata vids, bytes[] calldata data) external returns (uint[] memory successGas);

////Functions for users and frontend developers are below

    ///@notice Standard withdraw for msg.sender
    function withdraw(uint256 _vid, uint256 _wantAmt, bytes calldata _data) external;

    ///@notice Withdraw with custom to account
    function withdraw(uint256 _vid, uint256 _wantAmt, address _to, bytes calldata _data) external;

    function deposit(uint256 _vid, uint256 _wantAmt, bytes calldata _data) external payable;

    function totalSupply(uint256 vid) external view returns (uint256);

    ///@notice This returns the strategy address for any vid.
    ///@dev For dapp or contract usage, it may be better to calculate strategy addresses locally. The formula is in the function Cavendish.computeAddress
    //function strat(uint256 _vid) external view returns (IStrategy);

    struct VaultInfo {
        IERC20 want;
        uint8 noAutoEarn;
        bool active; //not paused
        uint48 lastEarnBlock;
        uint16 numBoosts;
        uint16 numMaximizers; //number of maximizer vaults pointing here. For vid 0x0045, its maximizer will be 0x00450001, 0x00450002, ...
    }

    function vaultInfo(uint vid) external view returns (IERC20, uint8, bool, uint48,uint16,uint16);

    function tokenData(address account, uint[] calldata vids) external view returns (uint[4][] memory data);

    //@notice Returns the number of non-maximizer vaults, where the want token is compounded within one strategy
    function numVaultsBase() external view returns (uint16);

    ///@notice The number of shares in a maximizer's target vault pending to a user account from said maximizer
    ///@param _account Some user account
    ///@param _vid The vid of the maximizer
    ///@dev The vid of the target is implied to be _vid >> 16
	function maximizerPendingTargetShares(address _account, uint256 _vid) external view returns (uint256);

    ///@notice The balance of a user's shares in a vault, plus any pending shares from maximizers
	function totalBalanceOf(address _account, uint256 _vid) external view returns (uint256 amount);

    ///@notice Harvests a single maximizer
    ///@param _vid The vid of the maximizer vault, which deposits into some other target
	function harvestMaximizer(uint256 _vid) external;

	///@notice Harvests all maximizers earning to the specified target vid
    ///@param _vid The vid of the target vault, to which many maximizers may deposit
    function harvestTarget(uint256 _vid) external;

    ///@notice This can be used to make two or more calls to the contract as an atomic transaction.
    ///@param inputs are the standard abi-encoded function calldata with selector. This can be any external function on vaultHealer.
    //function multicall(bytes[] calldata inputs) external returns (bytes[] memory);

    struct BoostInfo {
        uint id;
        IBoostPool pool;
        IERC20 rewardToken;
        uint pendingReward;
    }

    function vaultFeeManager() external view returns (IVaultFeeManager);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBoostPool {
    function bonusEndBlock() external view returns (uint32);
    function BOOST_ID() external view returns (uint256);
    function joinPool(address _user, uint112 _amount) external;
    function harvest(address) external;
    function emergencyWithdraw(address _user) external returns (bool success);
    function notifyOnTransfer(address _from, address _to, uint256 _amount) external returns (bool poolDone);
    function initialize(address _owner, uint256 _boostID, bytes calldata initdata) external;
    function pendingReward(address _user) external view returns (IERC20 token, uint256 amount);
    function isActive() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

/// @title Cavendish clones
/// @author ToweringTopaz
/// @notice Creates ERC-1167 minimal proxies whose addresses depend only on the salt and deployer address
/// @dev See _fallback for important instructions

library Cavendish {

/*
    Proxy init bytecode: 

    11 bytes: 602d80343434335afa15f3

    60 push1 2d       : size
    80 dup1           : size size
    34 callvalue      : 0 size size 
    34 callvalue      : 0 0 size size 
    34 callvalue      : 0 0 0 size size 
    33 caller         : caller 0 0 0 size size
    5a gas            : gas caller 0 0 0 size size
    fa staticcall     : success size
    15 iszero         : 0 size
    f3 return         : 

*/
    
	bytes11 constant PROXY_INIT_CODE = hex'602d80343434335afa15f3';	//below is keccak256(abi.encodePacked(PROXY_INIT_CODE));
    bytes32 constant PROXY_INIT_HASH = hex'577cbdbf32026552c0ae211272febcff3ea352b0c755f8f39b49856dcac71019';

	error ERC1167_Create2Failed();
	error ERC1167_ImplZeroAddress();

    /// @notice Creates an 1167-compliant minimal proxy whose address is purely a function of the deployer address and the salt
    /// @param _implementation The contract to be cloned
    /// @param salt Used to determine and calculate the proxy address
    /// @return Address of the deployed proxy
    function clone(address _implementation, bytes32 salt) internal returns (address) {
        if (_implementation == address(0)) revert ERC1167_ImplZeroAddress();
        address instance;
        assembly ("memory-safe") {
            sstore(PROXY_INIT_HASH, shl(96, _implementation)) //store at slot PROXY_INIT_HASH which should be empty
            mstore(0, PROXY_INIT_CODE)
            instance := create2(0, 0x00, 11, salt)
            sstore(PROXY_INIT_HASH, 0) 
        }
        if (instance == address(0)) revert ERC1167_Create2Failed();
        return instance;
    }
    
    //Standard function to compute a create2 address deployed by this address, but not impacted by the target implemention
    function computeAddress(bytes32 salt) internal view returns (address) {
        return computeAddress(salt, address(this));
    }

    //Standard function to compute a create2 address, but not impacted by the target implemention
    function computeAddress(
        bytes32 salt,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, PROXY_INIT_HASH));
        return address(uint160(uint256(_data)));
    }
	
    /// @notice Called by the proxy constructor to provide the bytecode for the final proxy contract. 
    /// @dev Deployer contracts must call Cavendish._fallback() in their own fallback functions.
    ///      Generally compatible with contracts that use fallback functions. Simply call this at the
    ///       top of your fallback, and it will run only when needed.
    function _fallback() internal view {
        assembly ("memory-safe") {
            if iszero(extcodesize(caller())) { //will be, for a contract under construction
                let _implementation := sload(PROXY_INIT_HASH)
                if gt(_implementation, 0) {
                    mstore(0x00, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
                    mstore(0x0a, _implementation)
                    mstore(0x1e, 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                    return(0x00, 0x2d) //Return to external caller, not to any internal function
                }

            }
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniRouter.sol";
import "../libraries/Fee.sol";
import "../libraries/Tactics.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IMagnetite.sol";
import "./IVaultHealer.sol";

interface IStrategy is IERC165 {

    error Muppet(address caller);
    error IdenticalAddresses(IERC20 a, IERC20 b);
    error ZeroAddress();
    error InsufficientOutputAmount(uint amountOut, uint amountOutMin);
    error Strategy_CriticalMemoryError(uint ptr);
    error Strategy_Improper1155Deposit(address operator, address from, uint id);
    error Strategy_Improper1155BatchDeposit(address operator, address from, uint[] ids);
    error Strategy_ImproperEthDeposit(address sender, uint amount);
    error Strategy_NotVaultHealer(address sender);
    error Strategy_InitializeOnlyByProxy();
    error Strategy_ExcessiveFarmSlippage();
    error Strategy_WantLockedLoss();
	error Strategy_TotalSlippageWithdrawal(); //nothing to withdraw after slippage
	error Strategy_DustDeposit(uint256 wantAdded); //Deposit amount is insignificant after slippage
    

    function initialize (bytes calldata data) external;
    function wantToken() external view returns (IERC20); // Want address
    function wantLockedTotal() external view returns (uint256); // Total want tokens managed by strategy (vaultSharesTotal + want token balance)
	function vaultSharesTotal() external view returns (uint256); //Want tokens deposited in strategy's pool
    function earn(Fee.Data[3] memory fees, address _operator, bytes calldata _data) external returns (bool success, uint256 _wantLockedTotal); // Main want token compounding function
    
    function deposit(uint256 _wantAmt, uint256 _sharesTotal, bytes calldata _data) external payable returns (uint256 wantAdded, uint256 sharesAdded);
    function withdraw(uint256 _wantAmt, uint256 _userShares, uint256 _sharesTotal, bytes calldata _data) external returns (uint256 sharesRemoved, uint256 wantAmt);

    function panic() external;
    function unpanic() external;
    function router() external view returns (IUniRouter); // Univ2 router used by this strategy

    function vaultHealer() external view returns (IVaultHealer);
    function implementation() external view returns (IStrategy);
    function isMaximizer() external view returns (bool);
    function getMaximizerImplementation() external view returns (IStrategy);

    struct ConfigInfo {
        uint256 vid;
        IERC20 want;
        uint256 wantDust;
        address masterchef;
        uint pid;
        IUniRouter _router;
        IMagnetite _magnetite;
        IERC20[] earned;
        uint256[] earnedDust;
        uint slippageFactor;
        bool feeOnTransfer;
    }

    function configInfo() external view returns (ConfigInfo memory);
    function tactics() external view returns (Tactics.TacticsA tacticsA, Tactics.TacticsB tacticsB);
    
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../libraries/Fee.sol";

interface IVaultFeeManager {

    function getEarnFees(uint vid) external view returns (Fee.Data[3] memory fees);
    function getWithdrawFee(uint vid) external view returns (address receiver, uint16 rate);
    function getEarnFees(uint[] calldata vids) external view returns (Fee.Data[3][] memory fees);
    function getWithdrawFees(uint[] calldata vids) external view returns (Fee.Data[] memory fees);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.14;

import "../interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Fee {
    using Fee for Data;
    using Fee for Data[3];

    type Data is uint256;

    uint256 constant FEE_MAX = 3000; // 100 = 1% : basis points

    function rate(Data _fee) internal pure returns (uint16) {
        return uint16(Data.unwrap(_fee));
    }
    function receiver(Data _fee) internal pure returns (address) {
        return address(uint160(Data.unwrap(_fee) >> 16));
    }
    function receiverAndRate(Data _fee) internal pure returns (address, uint16) {
        uint fee = Data.unwrap(_fee);
        return (address(uint160(fee >> 16)), uint16(fee));
    }
    function create(address _receiver, uint16 _rate) internal pure returns (Data) {
        return Data.wrap((uint256(uint160(_receiver)) << 16) | _rate);
    }

    function totalRate(Data[3] calldata _fees) internal pure returns (uint16 total) {
        unchecked { //overflow is impossible if Fee.Data are valid
            total = uint16(Data.unwrap(_fees[0]) + Data.unwrap(_fees[1]) + Data.unwrap(_fees[2]));
            require(total <= FEE_MAX, "Max total fee of 30%");
        }
    }
    function check(Data[3] memory _fees, uint maxTotal) internal pure returns (uint16 total) {
        unchecked { //overflow is impossible if Fee.Data are valid
            total = uint16(Data.unwrap(_fees[0]) + Data.unwrap(_fees[1]) + Data.unwrap(_fees[2]));
            require(total <= maxTotal, "Max total fee exceeded");
        }
    }

    //Token amount is all fees
    function payTokenFeeAll(Data[3] calldata _fees, IERC20 _token, uint _tokenAmt) internal {
        if (_tokenAmt == 0) return;
        uint feeTotalRate = totalRate(_fees);
        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            SafeERC20.safeTransfer(_token, _receiver, _tokenAmt * _rate / feeTotalRate);
        }
    }
    //Amount includes fee and non-fee portions
    function payTokenFeePortion(Data[3] calldata _fees, IERC20 _token, uint _tokenAmt) internal returns (uint amtAfter) {
        if (_tokenAmt == 0) return 0;
        amtAfter = _tokenAmt;
        uint feeTotalRate = totalRate(_fees);
        uint feeTotalAmt = feeTotalRate * _tokenAmt / 10000;

        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            uint amount = _tokenAmt * _rate / 10000;
            SafeERC20.safeTransfer(_token, _receiver, amount);
        }
        return _tokenAmt - feeTotalAmt;
    }

    //Use this if ethAmt is all fees
    function payEthAll(Data[3] calldata _fees, uint _ethAmt) internal {
        if (_ethAmt == 0) return;
        uint feeTotalRate = totalRate(_fees);
        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            (bool success,) = _receiver.call{value: _ethAmt * _rate / feeTotalRate, gas: 0x40000}("");
            require(success, "Fee: Transfer failed");
        }
    }
    //Use this if ethAmt includes both fee and non-fee portions
    function payEthPortion(Data[3] calldata _fees, uint _ethAmt) internal returns (uint ethAfter) {
        ethAfter = _ethAmt;
        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            uint amount = _ethAmt * _rate / 10000;
            (bool success,) = _receiver.call{value: amount, gas: 0x40000}("");
            require(success, "Fee: Transfer failed");
            ethAfter -= amount;
        }
    }
    function payWethPortion(Data[3] calldata _fees, IWETH weth, uint _wethAmt) internal returns (uint wethAfter) {
        uint feeTotalRate = totalRate(_fees);
        uint feeTotalAmt = feeTotalRate * _wethAmt / 10000;
        weth.withdraw(feeTotalAmt);
        for (uint i; i < 3; i++) {
            (address _receiver, uint _rate) = Fee.receiverAndRate(_fees[i]);
            if (_receiver == address(0) || _rate == 0) break;
            uint amount = _wethAmt * _rate / 10000;
            (bool success,) = _receiver.call{value: amount, gas: 0x40000}("");
            require(success, "Fee: Transfer failed");
        }
        return _wethAmt - feeTotalAmt;
    }

    function set(Data[3] storage _fees, address[3] memory _receivers, uint16[3] memory _rates) internal {

        uint feeTotal;
        for (uint i; i < 3; i++) {
            address _receiver = _receivers[i];
            uint16 _rate = _rates[i];
            require(_receiver != address(0) || _rate == 0, "Invalid treasury address");
            feeTotal += _rate;
            uint256 _fee = uint256(uint160(_receiver)) << 16 | _rate;
            _fees[i] = Data.wrap(_fee);
        }
        require(feeTotal <= 3000, "Max total fee of 30%");
    }

    function check(Data _fee, uint maxRate) internal pure { 
        (address _receiver, uint _rate) = _fee.receiverAndRate();
        if (_rate > 0) {
            require(_receiver != address(0), "Invalid treasury address");
            require(_rate <= maxRate, "Max withdraw fee exceeded");
        }
    }

}

// SPDX-License-Identifier: GPLv2

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Address.sol";

/// @title Tactics
/// @author ToweringTopaz
/// @notice Provides a generic method which vault strategies can use to call deposit/withdraw/balance on stakingpool or masterchef-like contracts
library Tactics {
    using Address for address;

    /*
    This library handles masterchef function call data packed as follows:

        uint256 tacticsA: 
            160: masterchef
            24: pid
            8: position of vaultSharesTotal function's returned amount within the returndata 
            32: selector for vaultSharesTotal
            32: vaultSharesTotal encoded call format

        uint256 tacticsB:
            32: deposit selector
            32: deposit encoded call format
            
            32: withdraw selector
            32: withdraw encoded call format
            
            32: harvest selector
            32: harvest encoded call format
            
            32: emergencyVaultWithdraw selector
            32: emergencyVaultWithdraw encoded call format

    Encoded calls use function selectors followed by single nibbles as follows, with the output packed to 32 bytes:
        0: end of line/null
        f: 32 bytes zero
        4: specified amount
        3: address(this)
        2: pid
    */
    type TacticsA is bytes32;
    type TacticsB is bytes32;

    function masterchef(TacticsA tacticsA) internal pure returns (address) {
        return address(bytes20(TacticsA.unwrap(tacticsA)));
    }  
    function pid(TacticsA tacticsA) internal pure returns (uint24) {
        return uint24(bytes3(TacticsA.unwrap(tacticsA) << 160));
    }  
    function vaultSharesTotal(TacticsA tacticsA) internal view returns (uint256 amountStaked) {
        uint returnvarPosition = uint8(uint(TacticsA.unwrap(tacticsA)) >> 64); //where is our vaultshares in the return data
        uint64 encodedCall = uint64(uint(TacticsA.unwrap(tacticsA)));
        if (encodedCall == 0) return 0;
        bytes memory data = _generateCall(pid(tacticsA), encodedCall, 0); //pid, vst call, 0
        data = masterchef(tacticsA).functionStaticCall(data, "Tactics: staticcall failed");
        assembly ("memory-safe") {
            amountStaked := mload(add(data, add(0x20,returnvarPosition)))
        }
    }

    function deposit(TacticsA tacticsA, TacticsB tacticsB, uint256 amount) internal {
        _doCall(tacticsA, tacticsB, amount, 192);
    }
    function withdraw(TacticsA tacticsA, TacticsB tacticsB, uint256 amount) internal {
        _doCall(tacticsA, tacticsB, amount, 128);
    }
    function harvest(TacticsA tacticsA, TacticsB tacticsB) internal {
        _doCall(tacticsA, tacticsB, 0, 64);
    }
    function emergencyVaultWithdraw(TacticsA tacticsA, TacticsB tacticsB) internal {
        _doCall(tacticsA, tacticsB, 0, 0);
    }
    function _doCall(TacticsA tacticsA, TacticsB tacticsB, uint256 amount, uint256 offset) private {
        uint64 encodedCall = uint64(uint(TacticsB.unwrap(tacticsB)) >> offset);
        if (encodedCall == 0) return;
        bytes memory generatedCall = _generateCall(pid(tacticsA), encodedCall, amount);
        masterchef(tacticsA).functionCall(generatedCall, "Tactics: call failed");
        
    }

    function _generateCall(uint24 _pid, uint64 encodedCall, uint amount) private view returns (bytes memory generatedCall) {

        generatedCall = abi.encodePacked(bytes4(bytes8(encodedCall)));

        for (bytes4 params = bytes4(bytes8(encodedCall) << 32); params != 0; params <<= 4) {
            bytes1 p = bytes1(params) & bytes1(0xf0);
            uint256 word;
            if (p == 0x20) {
                word = _pid;
            } else if (p == 0x30) {
                word = uint(uint160(address(this)));
            } else if (p == 0x40) {
                word = amount;
            } else if (p != 0xf0) {
                revert("Tactics: invalid tactic");
            }
            generatedCall = abi.encodePacked(generatedCall, word);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMagnetite {
    function findAndSavePath(address _router, IERC20 a, IERC20 b) external returns (IERC20[] memory path);
    function overridePath(address router, IERC20[] calldata _path) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniPair.sol";

interface IUniFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (IUniPair pair);
    function allPairs(uint) external view returns (IUniPair pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (IUniPair pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPLv2
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniFactory.sol";

interface IUniPair is IERC20 {
  
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (IUniFactory);
  function token0() external view returns (IERC20);
  function token1() external view returns (IERC20);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "./VaultHealerBase.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ERC1155.sol";

abstract contract VaultHealerGate is VaultHealerBase, ERC1155 {
    using SafeERC20 for IERC20;

    struct PendingDeposit {
        IERC20 token;
        uint96 amount0;
        address from;
        uint96 amount1;
    }
    mapping(address => mapping(uint256 => uint256)) public maximizerEarningsOffset;
    mapping(uint256 => uint256) public totalSupply;
    mapping(uint256 => uint256) public totalMaximizerEarnings;

    mapping(address => PendingDeposit) private pendingDeposits;

    //For front-end and general purpose external compounding. Returned amounts are zero on failure, or the gas cost on success
    function earn(uint256[] calldata vids) external nonReentrant returns (uint[] memory successGas) {
        Fee.Data[3][] memory fees = vaultFeeManager.getEarnFees(vids);
        uint len = vids.length;

        successGas = new uint[](len);
        for (uint i; i < len; i++) {
            uint gasBefore = gasleft();
            if (_earn(vids[i], fees[i], msg.data[0:0])) successGas[i] = gasBefore - gasleft();
        }
    }

    function earn(uint256[] calldata vids, bytes[] calldata data) external nonReentrant returns (uint[] memory successGas) {
        uint len = vids.length;
        if (data.length != len) revert ArrayMismatch(len, data.length);
        Fee.Data[3][] memory fees = vaultFeeManager.getEarnFees(vids);
        
        successGas = new uint[](len);
        for (uint i; i < len; i++) {
            uint gasBefore = gasleft();
            if (_earn(vids[i], fees[i], data[i])) successGas[i] = gasBefore - gasleft();
        }
    }

    function _earn(uint256 vid, Fee.Data[3] memory fees, bytes calldata data) internal returns (bool) {
        VaultInfo storage vault = vaultInfo[vid];
        if (paused(vid) || vault.lastEarnBlock == block.number) return false;

        vault.lastEarnBlock = uint48(block.number);
        try strat(vid).earn(fees, msg.sender, data) returns (bool success, uint256 wantLockedTotal) {
            if (success) {                
                emit Earned(vid, wantLockedTotal, totalSupply[vid]);
                return true;
            }
        } catch Error(string memory reason) {
            emit FailedEarn(vid, reason);
        } catch (bytes memory reason) {
            emit FailedEarnBytes(vid, reason);
        }
        return false;
    }
    
    //Allows maximizers to make reentrant calls, only to deposit to their target
    function maximizerDeposit(uint _vid, uint _wantAmt, bytes calldata _data) external payable whenNotPaused(_vid) {
        require(address(strat(_vid)) == msg.sender, "VH: sender does not match vid");
        totalMaximizerEarnings[_vid] += _deposit(_vid >> 16, _wantAmt, _data);
    }

    // Want tokens moved from user -> this -> Strat (compounding
    function deposit(uint256 _vid, uint256 _wantAmt, bytes calldata _data) external payable whenNotPaused(_vid) nonReentrant {
        IERC20 token = vaultInfo[_vid].want;
        uint balance = token.balanceOf(msg.sender);
        if (balance < _wantAmt) revert InsufficientBalance(token, msg.sender, balance, _wantAmt);
        uint approval = token.allowance(msg.sender, address(this));
        if (approval < _wantAmt) revert InsufficientApproval(token, msg.sender, approval, _wantAmt);

        _deposit(_vid, _wantAmt, _data);
    }

    function _deposit(uint256 _vid, uint256 _wantAmt, bytes calldata _data) private returns (uint256 vidSharesAdded) {
        uint totalSupplyBefore = totalSupply[_vid];
        // If enabled, we call an earn on the vault before we action the _deposit
        if (totalSupplyBefore > 0 && vaultInfo[_vid].noAutoEarn & 1 == 0) _earn(_vid, vaultFeeManager.getEarnFees(_vid), _data); 

        //Store the _from address, deposit amount, and ERC20 token associated with this vault. The strategy will be able to withdraw from _from via 
        //VaultHealer's approval, but no more than _wantAmt. This allows VaultHealer to be the only vault contract where token approvals are needed. 
        //Users can be approve VaultHealer freely and be assured that VaultHealer will not withdraw anything except when they call deposit, and only
        //up to the correct deposit amount.
        IERC20 vaultWant = vaultInfo[_vid].want;
        if (_wantAmt > 0 && address(vaultWant) != address(0)) pendingDeposits[address(strat(_vid))] = PendingDeposit({
            token: vaultWant,
            amount0: uint96(_wantAmt >> 96),
            from: msg.sender,
            amount1: uint96(_wantAmt)
        });

        // we make the deposit
        (_wantAmt, vidSharesAdded) = strat(_vid).deposit{value: msg.value}(_wantAmt, totalSupplyBefore, abi.encode(msg.sender, msg.sender, msg.sender, _data));

        //we mint tokens for the user via the 1155 contract
        _mint(
            msg.sender,
            _vid, //use the vid of the strategy 
            vidSharesAdded,
            _data
        );

        delete pendingDeposits[address(strat(_vid))]; //In case the pending deposit was not used, don't store it

        emit Deposit(msg.sender, _vid, _wantAmt);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _vid, uint256 _wantAmt, bytes calldata _data) external nonReentrant {
        _withdraw(_vid, _wantAmt, msg.sender, _data);
    }

    function withdraw(uint256 _vid, uint256 _wantAmt, address _to, bytes calldata _data) external nonReentrant {
        _withdraw(_vid, _wantAmt, _to, _data);
    }

    function _withdraw(uint256 _vid, uint256 _wantAmt, address _to, bytes calldata _data) private returns (uint256 vidSharesRemoved) {
		uint fromBalance = balanceOf(msg.sender, _vid);
        if (fromBalance == 0) revert WithdrawZeroBalance(msg.sender);

        // we call an earn on the vault before we action the _deposit
        if (vaultInfo[_vid].noAutoEarn & 2 == 0) _earn(_vid, vaultFeeManager.getEarnFees(_vid), _data); 

        (vidSharesRemoved, _wantAmt) = strat(_vid).withdraw(_wantAmt, fromBalance, totalSupply[_vid], abi.encode(msg.sender, msg.sender, _to, _data));
		
        //burn the tokens equal to vidSharesRemoved
        _burn(
            msg.sender,
            _vid,
            vidSharesRemoved
        );
		
        //Collect the withdrawal fee and transfer the ERC20 token out
        IERC20 _wantToken = vaultInfo[_vid].want;
        address vaultStrat = address(strat(_vid));
        if (address(_wantToken) != address(0)) {
            //withdraw fee is implemented here
            try vaultFeeManager.getWithdrawFee(_vid) returns (address feeReceiver, uint16 feeRate) {
                //hardcoded 3% max fee rate
                if (feeReceiver != address(0) && feeRate <= 300 && !paused(_vid)) { //waive withdrawal fee on paused vaults as there's generally something wrong
                    uint feeAmt = _wantAmt * feeRate / 10000;
                    _wantAmt -= feeAmt;
                    _wantToken.safeTransferFrom(vaultStrat, feeReceiver, feeAmt);
                }
            } catch {}

            _wantToken.safeTransferFrom(vaultStrat, _to, _wantAmt);
        }

        emit Withdraw(msg.sender, _to, _vid, _wantAmt);
    }

    //called by strategy, cannot be nonReentrant
    function executePendingDeposit(address _to, uint192 _amount) external {
        IERC20 token = pendingDeposits[msg.sender].token;
        uint amount0 = pendingDeposits[msg.sender].amount0;
        address from = pendingDeposits[msg.sender].from;
        uint amount1 = pendingDeposits[msg.sender].amount1;
        if (_amount > amount0 << 96 | amount1) revert UnauthorizedPendingDepositAmount();
        delete pendingDeposits[msg.sender];

        token.safeTransferFrom(from, _to, _amount);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) { //tokens minted during deposit
            for (uint i; i < ids.length; i++) {
                uint vid = ids[i];
                uint supplyBefore = totalSupply[vid];
                uint supplyAfter = supplyBefore + amounts[i];
                totalSupply[vid] = supplyAfter;

                if (vid > 2**16 && supplyBefore > 0) {
                    uint bal = balanceOf(to, vid);
                    _maximizerHarvest(to, vid, bal, bal + amounts[i], supplyBefore, supplyAfter);
                }
            }
        } else if (to == address(0)) { //tokens burned during withdrawal
            for (uint i; i < ids.length; i++) {
                uint vid = ids[i];
                uint amount = amounts[i];
                uint supplyAfter = totalSupply[vid] - amount;
                totalSupply[vid] = supplyAfter;

                if (vid > 2**16 && amount > 0) {
                    if (supplyAfter == 0) {
                        uint targetVid = vid >> 16;
                        address vaultStrat = address(strat(vid));
                        uint remainingTargetShares = balanceOf(vaultStrat, targetVid);

                        _safeTransferFrom(vaultStrat, from, targetVid, remainingTargetShares, "");

                        totalMaximizerEarnings[vid] = 0;
                        maximizerEarningsOffset[from][vid] = 0;
                        emit MaximizerHarvest(from, vid, remainingTargetShares);
                    } else {
                        uint bal = balanceOf(from, vid);
                        _maximizerHarvest(from, vid, bal, bal - amount, supplyAfter + amount, supplyAfter);
                    }
                }
            }
        } else {
            for (uint i; i < ids.length; i++) {
                uint vid = ids[i];
                if (vid > 2**16) {
                    _earn(vid, vaultFeeManager.getEarnFees(vid), msg.data[0:0]);
                    _maximizerHarvest(from, vid, balanceOf(from, vid), balanceOf(from, vid) - amounts[i], totalSupply[vid], totalSupply[vid]);
                    _maximizerHarvest(to, vid, balanceOf(to, vid), balanceOf(to, vid) + amounts[i], totalSupply[vid], totalSupply[vid]);
                }
            }
        }
    }

	//Add nonReentrant for maximizer security
	function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override(ERC1155, IERC1155) nonReentrant { super.safeTransferFrom(from, to, id, amount, data); }
	
	//Add nonReentrant for maximizer security
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155, IERC1155) nonReentrant { super.safeBatchTransferFrom(from, to, ids, amounts, data); }


    // // For maximizer vaults, this function helps us keep track of each users' claim on the tokens in the target vault
	function _maximizerHarvest(address _account, uint256 _vid, uint256 _balance, uint256 _supply) private {
        _maximizerHarvest(_account, _vid, _balance, _balance, _supply, _supply);
    }
	
	
    function _maximizerHarvest(address _account, uint256 _vid, uint256 _balanceBefore, uint256 _balanceAfter, uint256 _supplyBefore, uint256 _supplyAfter) private {
        uint accountOffset = maximizerEarningsOffset[_account][_vid];
        uint totalBefore = totalMaximizerEarnings[_vid];
		
		maximizerEarningsOffset[_account][_vid] = _balanceAfter * totalBefore / _supplyBefore;
        totalMaximizerEarnings[_vid] = _supplyAfter * totalBefore / _supplyBefore;

        uint targetShares = _balanceBefore * totalBefore / _supplyBefore;
        if (targetShares > accountOffset) {
            uint sharesEarned = targetShares - accountOffset;
            _safeTransferFrom(address(strat(_vid)), _account, _vid >> 16, sharesEarned, "");
            emit MaximizerHarvest(_account, _vid, sharesEarned);
        }
    }

	
	function maximizerPendingTargetShares(address _account, uint256 _vid) public view returns (uint256) {
        uint userVaultBalance = balanceOf(_account, _vid);
		if (userVaultBalance == 0) return 0;		

		uint targetVidShares = userVaultBalance * totalMaximizerEarnings[_vid] / totalSupply[_vid];
		uint accountOffset = maximizerEarningsOffset[_account][_vid];
		
		return targetVidShares > accountOffset ? targetVidShares - accountOffset : 0;
	}

	//balanceOf, but including all pending shares from maximizers
	function totalBalanceOf(address _account, uint256 _vid) external view returns (uint256 amount) {
		amount = super.balanceOf(_account, _vid);
		uint lastMaximizer = (_vid << 16) + vaultInfo[_vid].numMaximizers;
		for (uint i = (_vid << 16) + 1; i <= lastMaximizer; i++) {
			amount += maximizerPendingTargetShares(_account, i);
		}
	}
    function totalBalanceOfBatch(address[] calldata _account, uint256[] calldata _vid) external view returns (uint256[] memory amounts) {
        amounts = super.balanceOfBatch(_account, _vid);

        for (uint k; k < amounts.length; k++) {
            uint lastMaximizer = (_vid[k] << 16) + vaultInfo[_vid[k]].numMaximizers;
            for (uint i = (_vid[k] << 16) + 1; i <= lastMaximizer; i++) {
                amounts[k] += maximizerPendingTargetShares(_account[k], i);
            }
        }
    }

	function harvestMaximizer(uint256 _vid) external nonReentrant {
		_maximizerHarvest(msg.sender, _vid, balanceOf(msg.sender, _vid), totalSupply[_vid]);
	}
	
	function harvestTarget(uint256 _vid) external nonReentrant {
		uint lastMaximizer = (_vid << 16) + vaultInfo[_vid].numMaximizers;
		for (uint i = (_vid << 16) + 1; i <= lastMaximizer; i++) {
			_maximizerHarvest(msg.sender, i, balanceOf(msg.sender, i), totalSupply[i]);
		}		
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "./libraries/Cavendish.sol";
import "./interfaces/IVaultHealer.sol";
import "./VaultFeeManager.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./VaultHealerAuth.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./libraries/VaultChonk.sol";

abstract contract VaultHealerBase is IVaultHealer, ReentrancyGuard {

    uint constant PANIC_LOCK_DURATION = 6 hours;

    IVaultFeeManager immutable public vaultFeeManager;
    VaultHealerAuth immutable public vhAuth;
    
    uint16 public numVaultsBase; //number of non-maximizer vaults

    mapping(uint => VaultInfo) public vaultInfo; // Info of each vault.
	mapping(uint => uint) private panicLockExpiry;

    constructor(address _vhAuth, address _feeMan) {
        vhAuth = VaultHealerAuth(_vhAuth);
        vaultFeeManager = IVaultFeeManager(_feeMan);
    }

    modifier auth {
        _auth();
        _;
    }
    function _auth() view private {
        bytes4 selector = bytes4(msg.data);
        if (!IAccessControl(vhAuth).hasRole(selector, msg.sender)) revert RestrictedFunction(selector);
    }

    function createVault(IStrategy _implementation, bytes calldata data) external auth nonReentrant returns (uint16 vid) {
        vid = numVaultsBase + 1;
        numVaultsBase = vid;
        VaultChonk.createVault(vaultInfo, vid, _implementation, data);
    }
	
    function createMaximizer(uint targetVid, bytes calldata data) external requireValidVid(targetVid) auth nonReentrant returns (uint vid) {
        return VaultChonk.createMaximizer(vaultInfo, targetVid, data);
    }

    //Computes the strategy address for any vid based on this contract's address and the vid's numeric value
    function strat(uint _vid) public view returns (IStrategy) {
        return VaultChonk.strat(_vid);
    }

    //Requires that a vid represents some deployed vault
    modifier requireValidVid(uint vid) {
        _requireValidVid(vid);
        _;
    }
    function _requireValidVid(uint vid) internal view {
        uint subVid = vid & 0xffff;
        if (subVid == 0 || subVid > (subVid == vid ? numVaultsBase : vaultInfo[vid >> 16].numMaximizers))
			revert VidOutOfRange(vid);
    }

    //True values are the default behavior; call earn before deposit/withdraw
    function setAutoEarn(uint vid, bool earnBeforeDeposit, bool earnBeforeWithdraw) external auth requireValidVid(vid) {
        vaultInfo[vid].noAutoEarn = (earnBeforeDeposit ? 0 : 1) | (earnBeforeWithdraw ? 0 : 2);
        emit SetAutoEarn(vid, earnBeforeDeposit, earnBeforeWithdraw);
    }

//Like OpenZeppelin Pausable, but centralized here at the vaulthealer

    function pause(uint vid, bool panic) external auth requireValidVid(vid) {
        if (vaultInfo[vid].active) { //use direct variable; paused(vid) also may be true due to maximizer
            if (panic) {
                uint expiry = panicLockExpiry[vid];
                if (expiry > block.timestamp) revert PanicCooldown(expiry);
                expiry = block.timestamp + PANIC_LOCK_DURATION;
                strat(vid).panic();
            }
            vaultInfo[vid].active = false;
            emit Paused(vid);
        }
    }
    function unpause(uint vid) external auth requireValidVid(vid) {
        if ((vid >> 16) > 0 && paused(vid >> 16)) revert PausedError(vid >> 16); // if maximizer's target is paused, it must be unpaused first
        if (!vaultInfo[vid].active) { //use direct variable
            vaultInfo[vid].active = true;
            strat(vid).unpanic();
            emit Unpaused(vid);
        }
    }
    function paused(uint vid) public view returns (bool) {
        return !vaultInfo[vid].active || ((vid >> 16) > 0 && paused(vid >> 16));
    }
    function paused(uint[] calldata vids) external view returns (bytes memory pausedArray) {
        
        uint len = vids.length;
        pausedArray = new bytes(len);

        for (uint i; i < len; i++) {
            pausedArray[i] = paused(vids[i]) ? bytes1(0x01) : bytes1(0x00);
        }        
    }
    modifier whenPaused(uint vid) {
        if (!paused(vid)) revert PausedError(vid);
        _;
    }
    modifier whenNotPaused(uint vid) {
        if (paused(vid)) revert PausedError(vid);
        _;
    }

    fallback() external {
        Cavendish._fallback();
        revert InvalidFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    error ERC1155_BalanceQueryZeroAddress();
    error ERC1155_TransferZeroAddress();
    error ERC1155_ReceiverRejectedTokens();
    error ERC1155_ArrayLengthMismatch();    
    error ERC1155_NotReceiver();
    error ERC1155_SetApprovalSelf();
    error ERC1155_NotApproved();
    error ERC1155_InsufficientBalance();

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if (account == address(0)) revert ERC1155_BalanceQueryZeroAddress();
        return _balances[id][account];
    }
    
    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length) revert ERC1155_ArrayLengthMismatch();

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        if (!(from == msg.sender || isApprovedForAll(from, msg.sender))) revert ERC1155_NotApproved();
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        if (!(from == msg.sender || isApprovedForAll(from, msg.sender))) revert ERC1155_NotApproved();
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert ERC1155_TransferZeroAddress();

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) revert ERC1155_InsufficientBalance();
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (amounts.length != ids.length) revert ERC1155_ArrayLengthMismatch();
        if (to == address(0)) revert ERC1155_TransferZeroAddress();

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) revert ERC1155_InsufficientBalance();
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert ERC1155_TransferZeroAddress();

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert ERC1155_TransferZeroAddress();
        if (amounts.length != ids.length) revert ERC1155_ArrayLengthMismatch();

        address operator = msg.sender;

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) revert ERC1155_TransferZeroAddress();

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) revert ERC1155_InsufficientBalance();
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (from == address(0)) revert ERC1155_TransferZeroAddress();
        if (amounts.length != ids.length) revert ERC1155_ArrayLengthMismatch();

        address operator = msg.sender;

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) revert ERC1155_InsufficientBalance();
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (owner == operator) revert ERC1155_SetApprovalSelf();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155_ReceiverRejectedTokens();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155_NotReceiver();
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert ERC1155_ReceiverRejectedTokens();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155_NotReceiver();
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./interfaces/IVaultHealer.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./interfaces/IVaultFeeManager.sol";
import "./libraries/Constants.sol";

contract VaultFeeManager is IVaultFeeManager {
    using BitMaps for BitMaps.BitMap;
    using Fee for *;

    address constant public TX_ORIGIN = address(bytes20(keccak256("TX_ORIGIN"))); // if this address is used for earn fee, substitute tx.origin to pay the account providing the gas

    IAccessControl immutable public vhAuth;

    mapping(uint256 => Fee.Data) withdrawFee;
    mapping(uint256 => Fee.Data[3]) earnFees;

    BitMaps.BitMap internal _overrideDefaultEarnFees; // strategy's fee config doesn't change with the vaulthealer's default
    BitMaps.BitMap private _overrideDefaultWithdrawFee;
    Fee.Data[3] public defaultEarnFees; // Settings which are generally applied to all strategies
    Fee.Data public defaultWithdrawFee; //withdrawal fee is set separately from earn fees

    event SetDefaultEarnFees(Fee.Data[3] _earnFees);
    event SetDefaultWithdrawFee(Fee.Data _withdrawFee);
    event SetEarnFees(uint vid, Fee.Data[3] _earnFees);
    event SetWithdrawFee(uint vid, Fee.Data _withdrawFee);
    event ResetEarnFees(uint vid);
    event ResetWithdrawFee(uint vid);

    constructor(address _vhAuth) {
        vhAuth = IAccessControl(_vhAuth);
    }

    modifier auth {
        _auth();
        _;
    }
    function _auth() internal view virtual {
        require(vhAuth.hasRole(FEE_SETTER, msg.sender), "!auth");
    }

    function getEarnFees(uint _vid) external view returns (Fee.Data[3] memory _fees) {
        _fees = _overrideDefaultEarnFees.get(_vid) ? earnFees[_vid] : defaultEarnFees;
        for (uint i; i < 3; i++) {
            if (_fees[i].receiver() == TX_ORIGIN)
                _fees[i] = Fee.create(tx.origin, _fees[i].rate());
        }
    }

    function getEarnFees(uint[] calldata _vids) external view returns (Fee.Data[3][] memory _fees) {
        _fees = new Fee.Data[3][](_vids.length);
        Fee.Data[3] memory _default = defaultEarnFees;
        for (uint i; i < _vids.length; i++) {
            uint vid = _vids[i];
            _fees[i] = _overrideDefaultEarnFees.get(vid) ? earnFees[vid] : _default;
            for (uint k; k < 3; k++) {
                if (_fees[i][k].receiver() == TX_ORIGIN)
                    _fees[i][k] = Fee.create(tx.origin, _fees[i][k].rate());
            }
        }
    }

    function getWithdrawFee(uint _vid) external view returns (address _receiver, uint16 _rate) {
        return _overrideDefaultWithdrawFee.get(_vid) ? withdrawFee[_vid].receiverAndRate() : defaultWithdrawFee.receiverAndRate();
    }

    function getWithdrawFees(uint[] calldata _vids) external view returns (Fee.Data[] memory _withdrawFees) {
        _withdrawFees = new Fee.Data[](_vids.length);
        Fee.Data _default = defaultWithdrawFee;
        for (uint i; i < _vids.length; i++) {
            uint vid = _vids[i];
            _withdrawFees[i] = _overrideDefaultWithdrawFee.get(vid) ? withdrawFee[vid] : _default;
        }
    }

    function setDefaultWithdrawFee(address withdrawReceiver, uint16 withdrawRate) external auth {
         _setDefaultWithdrawFee(withdrawReceiver, withdrawRate);
    }
    function _setDefaultWithdrawFee(address withdrawReceiver, uint16 withdrawRate) internal {
        defaultWithdrawFee = Fee.create(withdrawReceiver, withdrawRate);
        Fee.check(defaultWithdrawFee, 300);
        emit SetDefaultWithdrawFee(defaultWithdrawFee);
    }

    function setEarnFees(uint _vid, address[3] calldata earnReceivers, uint16[3] calldata earnRates) external auth {
        _overrideDefaultEarnFees.set(_vid);
        earnFees[_vid].set(earnReceivers, earnRates);
        Fee.check(earnFees[_vid], 3000);
        emit SetEarnFees(_vid, earnFees[_vid]);
    }
    function resetEarnFees(uint _vid) external auth {
        _overrideDefaultEarnFees.unset(_vid);
        delete earnFees[_vid];
        emit ResetEarnFees(_vid);
    }
    
    function setDefaultEarnFees(address[3] memory earnReceivers, uint16[3] memory earnRates) external auth {
        _setDefaultEarnFees(earnReceivers, earnRates);
    }
    function _setDefaultEarnFees(address[3] memory earnReceivers, uint16[3] memory earnRates) internal {
        defaultEarnFees.set(earnReceivers, earnRates);
        Fee.check(defaultEarnFees, 3000);
        emit SetDefaultEarnFees(defaultEarnFees);
    }

    function setWithdrawFee(uint _vid, address withdrawReceiver, uint16 withdrawRate) external auth {
        _overrideDefaultWithdrawFee.set(_vid);
        withdrawFee[_vid] = Fee.create(withdrawReceiver, withdrawRate);
        Fee.check(defaultWithdrawFee, 300);
        emit SetWithdrawFee(_vid, withdrawFee[_vid]);
    }

    function resetWithdrawFee(uint _vid) external auth {
        _overrideDefaultEarnFees.unset(_vid);
        withdrawFee[_vid] = Fee.Data.wrap(0);
         emit ResetWithdrawFee(_vid);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./libraries/Constants.sol";

contract VaultHealerAuth is AccessControlEnumerable {

    bytes32 constant CREATE_ADMIN = keccak256("CREATE_ADMIN");
    bytes32 constant PAUSE_ADMIN = keccak256("PAUSE_ADMIN");

    constructor() {
        _setRoleAdmin(bytes4(keccak256("createVault(address,bytes)")), CREATE_ADMIN);
        _setRoleAdmin(bytes4(keccak256("createMaximizer(uint256,bytes)")), CREATE_ADMIN);
        _setRoleAdmin(bytes4(keccak256("createBoost(uint256,address,bytes)")), CREATE_ADMIN);
        _setRoleAdmin(bytes4(keccak256("pause(uint256,bool)")), PAUSE_ADMIN);
        _setRoleAdmin(bytes4(keccak256("setAutoEarn(uint256,bool,bool)")), PAUSE_ADMIN);
        _setRoleAdmin(bytes4(keccak256("unpause(uint256)")), PAUSE_ADMIN);
    }

    function setAccess(address account, uint level) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setAccess(account, level);
    }

    //Sets an account's roles to match a predefined tiered list, with 3 being the highest level. These correspond to VaultHealer function selectors.
    function _setAccess(address account, uint level) internal {

        if (level > 3) revert("Invalid access level");

        function(bytes32,address) update = _revokeRole;

        if (level == 3) update = _grantRole; //Owner-level access, controlling fees and permissions

        update(DEFAULT_ADMIN_ROLE, account);
        update(CREATE_ADMIN, account);
        update(PAUSE_ADMIN, account);
        update(FEE_SETTER, account);
        update(bytes4(keccak256("setURI(string)")), account);

        if (level == 2) update = _grantRole; //Vault creators

        update(bytes4(keccak256("createVault(address,bytes)")), account);
        update(bytes4(keccak256("createMaximizer(uint256,bytes)")), account);
        update(bytes4(keccak256("createBoost(uint256,address,bytes)")), account);            

        if (level == 1) update = _grantRole; //Pausers

        update(bytes4(keccak256("setAutoEarn(uint256,bool,bool)")), account);
        update(bytes4(keccak256("unpause(uint256)")), account);
        update(bytes4(keccak256("pause(uint256,bool)")), account);

    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;


bytes32 constant FEE_SETTER = keccak256("FEE_SETTER");

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}