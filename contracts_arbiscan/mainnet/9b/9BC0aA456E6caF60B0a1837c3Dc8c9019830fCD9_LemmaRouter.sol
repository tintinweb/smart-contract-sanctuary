// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import {Multicall} from '@uniswap/v3-periphery/contracts/base/Multicall.sol';
import {IWETH9} from '@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol';
import {IUSDLemma} from './interfaces/IUSDLemma.sol';
import {IXUSDL} from './interfaces/IXUSDL.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {TransferHelper} from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import {IPerpetualWrapper} from './interfaces/IPerpetualWrapper.sol';
import {IUniswapV2Router} from './interfaces/IUniswapV2Router.sol';

/**
    @title Periphery Contract to help with Lemma Contracts
    @author Lemma Finance
*/
contract LemmaRouter is Multicall {
    // ERC20 WETH token address
    IWETH9 public weth;
    // ERC20 USDL token address
    IUSDLemma public usdl;
    // ERC20 xUSDL token address
    IXUSDL public xusdl;
    address public routerSushiswap;

    /**
     * @dev Deploy Lemma Periphery Contract.
            Periphery Contract to help with Lemma Contracts
     * @param _weth WETH ERC20 contract address
     * @param _xusdl XUSDL ERC20 contract address
     * @param _routerSushiswap Sushiswap exchange router contract address
    */
    constructor(
        address _weth,
        address _xusdl,
        address _routerSushiswap
    ) {
        weth = IWETH9(_weth);
        xusdl = IXUSDL(_xusdl);
        usdl = IUSDLemma(address(xusdl.usdl()));
        routerSushiswap = _routerSushiswap;
        TransferHelper.safeApprove(_weth, address(usdl), type(uint256).max);
        TransferHelper.safeApprove(address(usdl), _xusdl, type(uint256).max);
    }

    // To receive ethereum from othre address to this periphery contract
    receive() external payable {}

    /**
     * @dev mint USDL token by depositing collateral and transfer USDL to toAddress
            collateral->USDL 
     * @notice before calling this function,
               user should have to approve this contract for collateral token
     * @param to address where minted usdl will transfer
     * @param amount user want to mint this number of USDL 
     * @param maxCollateralRequired Required collateral should be than than or equal to maxCollateralRequired
     * @param dexIndex Index of perpetual dex, where position will be opened
     * @param collateral collateral token address
    */
    function mintUSDLTo(
        address to,
        uint256 amount,
        uint256 maxCollateralRequired,
        uint256 dexIndex,
        IERC20 collateral
    ) public {
        uint256 collateralAmountRequired = IPerpetualWrapper(
            usdl.perpetualDEXWrappers(dexIndex, address(collateral))
        ).getCollateralAmountGivenUnderlyingAssetAmount(amount, true);
        TransferHelper.safeTransferFrom(
            address(collateral),
            msg.sender,
            address(this),
            collateralAmountRequired
        );

        usdl.depositTo(to, amount, dexIndex, maxCollateralRequired, collateral);
    }

    /**
     * @dev mint USDL token by depositing weth and transfer USDL to msg.sender
            collateral->USDL 
     * @notice before calling this function,
               user should have to approve this contract for collateral token
     * @param amount user want to mint this number of USDL 
     * @param maxCollateralRequired Required collateral should be less than than or equal to maxCollateralRequired
     * @param dexIndex Index of perpetual dex, where position will be opened
     * @param collateral collateral token address
    */
    function mintUSDL(
        uint256 amount,
        uint256 maxCollateralRequired,
        uint256 dexIndex,
        IERC20 collateral
    ) external {
        mintUSDLTo(
            msg.sender,
            amount,
            maxCollateralRequired,
            dexIndex,
            collateral
        );
    }

    /**
     * @dev mint USDL token by depositing weth, and transfer USDL to toAddress
            But before deposit weth, It first convert eth to weth by weth contract address
            ETH->WETH->USDL
     * @param to address where minted usdl will transfer
     * @param amount user want to mint this number of USDL 
     * @param dexIndex Index of perpetual dex, where position will be opened
    */
    function mintUSDLToETH(
        address to,
        uint256 amount,
        uint256 dexIndex
    ) public payable {
        weth.deposit{value: msg.value}();
        usdl.depositTo(to, amount, dexIndex, msg.value, weth);
        weth.withdraw(weth.balanceOf(address(this)));
        TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /**
     * @dev mint USDL token by depositing weth, and transfer USDL to msg.sender
            But before deposit weth, It first convert eth to weth by weth contract address
            ETH->WETH->USDL
     * @param amount user want to mint this number of USDL 
     * @param dexIndex Index of perpetual dex, where position will be opened
    */
    function mintUSDLETH(uint256 amount, uint256 dexIndex) external payable {
        mintUSDLToETH(msg.sender, amount, dexIndex);
    }

    /**
     * @dev redeemUSDLTo method will burn USDL and will transfer collateral back to toAddress
            USDL->collateral
     * @notice before calling this function,
               user should have to approve this contract for usdl token     
     * @param to toAddress where collateral will transfer
     * @param amount amount of USDL want to redeem for collateral
     * @param minCollateralToGetBack collateralAmountToGetBack should be greater than equal to minCollateralToGetBack 
     * @param dexIndex Index of perpetual dex, where position will be closed
     * @param collateral collateral token address
    */
    function redeemUSDLTo(
        address to,
        uint256 amount,
        uint256 minCollateralToGetBack,
        uint256 dexIndex,
        IERC20 collateral
    ) public {
        //transfer usdl from user to this address
        TransferHelper.safeTransferFrom(
            address(usdl),
            msg.sender,
            address(this),
            amount
        );
        _redeemUSDL(to, amount, dexIndex, minCollateralToGetBack, collateral);
    }

    /**
     * @dev redeemUSDL method will burn USDL and will transfer collateral back to msg.sender
            USDL->collateral
     * @notice before calling this function,
               user should have to approve this contract for usdl token     
     * @param amount amount of USDL want to redeem for collateral
     * @param minCollateralToGetBack collateralAmountToGetBack should be greater than equal to minCollateralToGetBack 
     * @param dexIndex Index of perpetual dex, where position will be closed
     * @param collateral collateral token address
    */
    function redeemUSDL(
        uint256 amount,
        uint256 minCollateralToGetBack,
        uint256 dexIndex,
        IERC20 collateral
    ) external {
        redeemUSDLTo(
            msg.sender,
            amount,
            minCollateralToGetBack,
            dexIndex,
            collateral
        );
    }

    /**
     * @dev redeemUSDLToETH method will burn USDL and will transfer collateral back to toAddress
            But before withdraw eth, It first convert weth to eth by weth contract address
            USDL->WETH->ETH
            and then send collateral(eth) back to toAddress
     * @notice before calling this function,
               user should have to approve this contract for usdl token     
     * @param to toAddress where collateral will transfer
     * @param amount amount of USDL want to redeem for collateral
     * @param minCollateralToGetBack collateralAmountToGetBack should be greater than equal to minCollateralToGetBack 
     * @param dexIndex Index of perpetual dex, where position will be closed
    */
    function redeemUSDLToETH(
        address to,
        uint256 amount,
        uint256 minCollateralToGetBack,
        uint256 dexIndex
    ) public {
        TransferHelper.safeTransferFrom(
            address(usdl),
            msg.sender,
            address(this),
            amount
        );
        _redeemUSDL(
            address(this),
            amount,
            dexIndex,
            minCollateralToGetBack,
            weth
        );
        weth.withdraw(weth.balanceOf(address(this)));
        TransferHelper.safeTransferETH(to, address(this).balance);
    }

    /**
     * @dev redeemUSDLTo method will burn USDL and will transfer collateral back to msg.sender
            But before withdraw eth, It first convert weth to eeth by weth contract address
            and then send collateral(eth) back to msg.sender
            USDL->WETH->ETH
     * @notice before calling this function,
               user should have to approve this contract for usdl token     
     * @param amount amount of USDL want to redeem for collateral
     * @param minCollateralToGetBack collateralAmountToGetBack should be greater than equal to minCollateralToGetBack 
     * @param dexIndex Index of perpetual dex, where position will be closed
    */
    function redeemUSDLETH(
        uint256 amount,
        uint256 minCollateralToGetBack,
        uint256 dexIndex
    ) external {
        redeemUSDLToETH(msg.sender, amount, minCollateralToGetBack, dexIndex);
    }

    /**
     * @dev _redeemUSDL method will burn USDL and will transfer collateral back to toAddress
     * @notice This is the internal method. It will not call by any user
     * @param to toAddress where collateral will transfer
     * @param amount amount of USDL want to redeem for collateral
     * @param dexIndex Index of perpetual dex, where position will be closed
     * @param minCollateralToGetBack collateralAmountToGetBack should be greater than equal to minCollateralToGetBack
     * @param collateral collateral token address
     */
    function _redeemUSDL(
        address to,
        uint256 amount,
        uint256 dexIndex,
        uint256 minCollateralToGetBack,
        IERC20 collateral
    ) internal {
        usdl.withdrawTo(
            to,
            amount,
            dexIndex,
            minCollateralToGetBack,
            collateral
        );
    }

    /**
     * @dev swapCollateralForToken method use to swap collateral(eth) for token
     * @notice It is using sushiswap as a router to swap collateral to token.
               It is the internal method.
     * @param collateral collateral is from address to swap
     * @param token specified token is to address for swap
     * @param amountIn collateral amount input
    */
    function swapCollateralForToken(
        address collateral,
        address token,
        uint256 amountIn
    ) internal {
        require(amountIn > 0, 'Nothing to transfer');

        address[] memory path = new address[](2);
        path[0] = collateral;
        path[1] = token;

        uint256 amountOutMin = IUniswapV2Router(routerSushiswap).getAmountsOut(
            amountIn,
            path
        )[1];
        require(amountOutMin > 0, 'No token available');

        // Approve transfer to Sushiswap Router
        require(
            IERC20(collateral).approve(routerSushiswap, amountIn),
            'Approve failed'
        );

        IUniswapV2Router(routerSushiswap).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            msg.sender,
            block.timestamp
        );
    }

    /**
     * @dev mintUSDLToUsingToken is used to mint USDL for toAddress
            In this method user can use other tokens to mint usdl
            so tokens will transfer to collateral internally then it will mint usdl
            token->collateral->USDL
     * @notice before calling this function,
               user should have to approve this contract for specified token address   
     * @param token specified token address as collateral and will swap internally token to weth
     * @param tokenAmount is the amount of collateral
     * @param swapActions it is the contract address of dex aggregator of 1inch
     * @param swapDatas it is the function signature which needs to call
     * @param to transfer minted USDL to toAddress
     * @param amount amount of USDL want to mint
     * @param maxCollateralRequired Required collateral should be less than or equal to max maxCollateralRequired
     * @param dexIndex Index of perpetual dex, where position will be opened
     * @param collateral collateral token address
    */
    function mintUSDLToUsingToken(
        IERC20 token,
        uint256 tokenAmount,
        address[] memory swapActions,
        bytes[] memory swapDatas,
        address to,
        uint256 amount,
        uint256 maxCollateralRequired,
        uint256 dexIndex,
        IERC20 collateral
    ) public {
        TransferHelper.safeTransferFrom(
            address(token),
            msg.sender,
            address(this),
            tokenAmount
        );
        _swap(token, swapActions, swapDatas, amount, dexIndex, collateral);
        //swap token for collateral
        //mint USDL using the collateral
        usdl.depositTo(to, amount, dexIndex, maxCollateralRequired, collateral);
        //transfer the extra collateral back to user
        swapCollateralForToken(
            address(collateral),
            address(token),
            collateral.balanceOf(address(this))
        );
    }

    /**
     * @dev mintUSDLUsingToken isused to mint USDL for msg.sender
            In this method user can use other tokens to mint usdl
            so tokens will transfer to collateral internally then it will mint usdl
            token->collateral->USDL
     * @notice before calling this function,
               user should have to approve this contract for specified token address   
     * @param token specified token address as collateral and will swap internally token to weth
     * @param tokenAmount is the amount of collateral
     * @param swapActions it is the contract address of dex aggregator of 1inch
     * @param swapDatas it is the function signature which needs to call
     * @param amount amount of USDL want to mint
     * @param maxCollateralRequired Required collateral should be less than or equal to max maxCollateralRequired
     * @param dexIndex Index of perpetual dex, where position will be opened
     * @param collateral collateral token address
    */
    function mintUSDLUsingToken(
        IERC20 token,
        uint256 tokenAmount,
        address[] memory swapActions,
        bytes[] memory swapDatas,
        uint256 amount,
        uint256 maxCollateralRequired,
        uint256 dexIndex,
        IERC20 collateral
    ) external {
        TransferHelper.safeTransferFrom(
            address(token),
            msg.sender,
            address(this),
            tokenAmount
        );
        _swap(token, swapActions, swapDatas, amount, dexIndex, collateral);
        //swap token for collateral
        //mint USDL using the collateral
        usdl.depositTo(
            msg.sender,
            amount,
            dexIndex,
            maxCollateralRequired,
            collateral
        );
        //transfer the extra collateral back to user

        swapCollateralForToken(
            address(collateral),
            address(token),
            collateral.balanceOf(address(this))
        );
    }

    /**
     * @dev _swap method is used to swap token for collateral(token -> weth)
     * @notice it is using 1inch protocol to swap
               It is internal method 
     * @param token specified token address as collateral and will swap internally token to weth
     * @param swapActions it is the contract address of dex aggregator of 1inch
     * @param swapDatas it is the function signature which needs to call
     * @param amount amount of USDL want to mint
     * @param dexIndex Index of perpetual dex, where position will be opened or closed
     * @param collateral collateral token address
    */
    function _swap(
        IERC20 token,
        address[] memory swapActions,
        bytes[] memory swapDatas,
        uint256 amount,
        uint256 dexIndex,
        IERC20 collateral
    ) internal {
        for (uint256 i; i < swapActions.length; i++) {
            (bool success, ) = swapActions[i].call(swapDatas[i]);
            require(success, 'swap failed');
        }
        uint256 collateralAmountRequired = IPerpetualWrapper(
            usdl.perpetualDEXWrappers(dexIndex, address(collateral))
        ).getCollateralAmountGivenUnderlyingAssetAmount(amount, true);

        require(
            collateral.balanceOf(address(this)) >= collateralAmountRequired,
            'swapped amount is less than required'
        );
        require(
            token.balanceOf(address(this)) == 0,
            'all the tokens need to be used'
        );
    }

    /**
     * @dev redeemUSDLToUsingToken is used to redeem USDL from 
            and get back its specied token as a collateral to toAddress
            USDL->collateral->token
     * @notice before calling this function,
               user should have to approve this contract for usdl token
     * @param token specified token address get back after collateral withdraw so will swap internally weth to token
     * @param swapActions it is the contract address of dex aggregator of 1inch
     * @param swapDatas it is the function signature which needs to call
     * @param to transfer specified tokens to toAddress
     * @param amount amount of USDL want to burn
     * @param minTokenAmount after swap weth to token. tokenAmount should be greater than or equal to minTokenAmount
     * @param dexIndex Index of perpetual dex, where position will be closed
     * @param collateral collateral token address
    */
    function redeemUSDLToUsingToken(
        IERC20 token,
        address[] memory swapActions,
        bytes[] memory swapDatas,
        address to,
        uint256 amount,
        uint256 minTokenAmount,
        uint256 dexIndex,
        IERC20 collateral
    ) external {
        TransferHelper.safeTransferFrom(
            address(usdl),
            msg.sender,
            address(this),
            amount
        );

        usdl.withdrawTo(address(this), amount, dexIndex, 0, collateral);

        _swapToToken(token, swapActions, swapDatas, minTokenAmount);

        TransferHelper.safeTransfer(
            address(token),
            to,
            token.balanceOf(address(this))
        );

        swapCollateralForToken(
            address(collateral),
            address(token),
            collateral.balanceOf(address(this))
        );
    }

    /**
     * @dev redeemUSDLUsingToken is used to redeem USDL from 
            and get back its specied token as a collateral to msg.sender
            USDL->collateral->token
     * @notice before calling this function,
               user should have to approve this contract for usdl token
     * @param token specified token address get back after collateral withdraw so will swap internally weth to token
     * @param swapActions it is the contract address of dex aggregator of 1inch
     * @param swapDatas it is the function signature which needs to call
     * @param amount amount of USDL want to burn
     * @param minTokenAmount after swap weth to token. tokenAmount should be greater than or equal to minTokenAmount
     * @param dexIndex Index of perpetual dex, where position will be closed
     * @param collateral collateral token address
    */
    function redeemUSDLUsingToken(
        IERC20 token,
        address[] memory swapActions,
        bytes[] memory swapDatas,
        uint256 amount,
        uint256 minTokenAmount,
        uint256 dexIndex,
        IERC20 collateral
    ) external {
        TransferHelper.safeTransferFrom(
            address(usdl),
            msg.sender,
            address(this),
            amount
        );

        usdl.withdrawTo(address(this), amount, dexIndex, 0, collateral);

        _swapToToken(token, swapActions, swapDatas, minTokenAmount);

        TransferHelper.safeTransfer(
            address(token),
            msg.sender,
            token.balanceOf(address(this))
        );

        swapCollateralForToken(
            address(collateral),
            address(token),
            collateral.balanceOf(address(this))
        );
    }

    /**
     * @dev _swapToToken is usedd to swap collateral(weth) to specified token
     * @notice It is using 1inch protocol to swap
               _swap to token is usedd when user will redeem USDL 
               and user wants its token as collateral instead weth 
     * @param token specified token address get back after swap weth to token
     * @param swapActions it is the contract address of dex aggregator of 1inch
     * @param swapDatas it is the function signature which needs to call
     * @param minTokenAmount after swap weth to token. tokenAmount should be greater than or equal to minTokenAmount
    */
    function _swapToToken(
        IERC20 token,
        address[] memory swapActions,
        bytes[] memory swapDatas,
        uint256 minTokenAmount
    ) internal {
        for (uint256 i; i < swapActions.length; i++) {
            (bool success, ) = swapActions[i].call(swapDatas[i]);
            require(success, 'swap failed');
        }

        require(
            token.balanceOf(address(this)) >= minTokenAmount,
            'swapped amount is less than token amount required'
        );
    }

    /**
     * @dev stakeUSDL is used to stake USDL in xUSDL contract 
            and msg.sender will get xUSDL as share token
            USDL->xUSDL
     * @notice before calling this function,
               user should have to approve this contract for usdl token
     * @param amount amount od USDL token to stake
    */
    function stakeUSDL(uint256 amount) external {
        TransferHelper.safeTransferFrom(
            address(usdl),
            msg.sender,
            address(this),
            amount
        );
        _stakeUSDLTo(amount, msg.sender);
    }

    /**
     * @dev _stakeUSDLTo is used to stake USDL in xUSDL contract 
            and user address will get xUSDL as share token
            USDL->xUSDL
     * @notice by staking you will get extra USDL as a yield
               _stakeUSDLTo is the internal method
     * @param amount amount od USDL token to stake
     * @param user minted xUSDL tokens to user address
    */
    function _stakeUSDLTo(uint256 amount, address user) internal {
        xusdl.deposit(amount);
        TransferHelper.safeTransfer(
            address(xusdl),
            user,
            xusdl.balanceOf(address(this))
        );
    }

    /**
     * @dev unstakeUSDL is used to withdraw USDL by giving back xUSDL token to xUSDL contract
            and msg.sender address will get USDL token get back
            xUSDL->USDL
     * @notice before calling this function,
               msg.sender should have to approve this contract for xUSDL token
     * @param amount amount of xUSDL tokens to burn for withdraw USDL
    */
    function unstakeUSDL(uint256 amount) external {
        unstakeUSDLTo(msg.sender, amount);
    }

    /**
     * @dev unstakeUSDLTo is used to withdraw USDL by giving back xUSDL token to xUSDL contract
            and toAddress will get USDL token get back
            xUSDL->USDL
     * @notice before calling this function,
               msg.sender should have to approve this contract for xUSDL token
     * @param to transfer usdl to toAddress
     * @param amount amount of xUSDL tokens to burn for withdraw USDL
    */
    function unstakeUSDLTo(address to, uint256 amount) public {
        TransferHelper.safeTransferFrom(
            address(xusdl),
            msg.sender,
            address(this),
            amount
        );
        xusdl.withdrawTo(to, amount);
    }

    /**
     * @dev mint USDL token by depositing weth, and transfer USDL to address(this)
            But before deposit weth, It first convert eth to weth by weth contract address
            and once contract mint USDL it will stake USDL in xUSDL contract 
            and msg.sender address will get xUSDL as share token
            ETH->WETH->USDL->xUSDL
     * @notice msg.sender should have the eth in his wallet
     * @param amount the amount of collateral tokens
     * @param dexIndex Index of perpetual dex, where position will be opened
    */
    function mintForEthAndStake(uint256 amount, uint256 dexIndex)
        external
        payable
    {
        mintUSDLToETH(address(this), amount, dexIndex);
        _stakeUSDLTo(amount, msg.sender);
    }

    /**
     * @dev mint USDL token by depositing collateral(weth) and transfer USDL to this contract address
            and once contract mint USDL it will stake USDL in xUSDL contract 
            and msg.sender address will get xUSDL as share token
            collateral->USDL->xUSDL
     * @notice before calling this function,
               user should have to approve this contract for collateral token
     * @param amount the amount of collateral tokens
     * @param dexIndex Index of perpetual dex, where position will be opened
     * @param maxCollateralRequired Required collateral should be less than or equal to max maxCollateralRequired
     * @param collateral collateral token address
    */
    function mintAndStake(
        uint256 amount,
        uint256 dexIndex,
        uint256 maxCollateralRequired,
        IERC20 collateral
    ) external {
        mintUSDLTo(
            address(this),
            amount,
            maxCollateralRequired,
            dexIndex,
            collateral
        );
        _stakeUSDLTo(amount, msg.sender);
    }

    /**
     * @dev mintUsingTokenAndStake is mint USDL for address(this).
            In this method user can use other tokens to mint usdl,
            so tokens will transfer to collateral internally then it will mint usdl.
            and once contract mint USDL it will stake USDL in xUSDL contract 
            and msg.sender address will get xUSDL as share token
            token->collateral->USDL->xUSDL
     * @notice before calling this function,
               user should have to approve this contract for specified token address  
     * @param token specified token address as collateral and will swap internally token to weth
     * @param tokenAmount is the amount of collateral 
     * @param swapActions it is the contract address of dex aggregator of 1inch
     * @param swapDatas it is the function signature which needs to call
     * @param amount amount of USDL want to mint
     * @param maxCollateralRequired Required collateral should be less than or equal to max maxCollateralRequired
     * @param dexIndex Index of perpetual dex, where position will be opened
     * @param collateral collateral token address
    */
    function mintUsingTokenAndStake(
        IERC20 token,
        uint256 tokenAmount,
        address[] memory swapActions,
        bytes[] memory swapDatas,
        uint256 amount,
        uint256 maxCollateralRequired,
        uint256 dexIndex,
        IERC20 collateral
    ) external {
        mintUSDLToUsingToken(
            token,
            tokenAmount,
            swapActions,
            swapDatas,
            address(this),
            amount,
            maxCollateralRequired,
            dexIndex,
            collateral
        );
        _stakeUSDLTo(amount, msg.sender);
    }

    /**
     * @dev unstakeAndRedeemUSDLForEth is used to withdraw USDL by giving back xUSDL token to xUSDL contract
            and address(this) will get USDL token get back
            and once USDL token withdraw, then calling `usdl.withdrawTo` to withdraw weth collateral back
            and swap weth to eth by weth contract and transfer to msg.sender
            xUSDL->USDL->WETH->ETH
     * @notice before calling this function,
               msg.sender should have to approve this contract for xusdl address
     * @param amount the amount of xUSDL tokend to burn and withdraw USDL tokens
     * @param dexIndex Index of perpetual dex, where position will be closed
    */
    function unstakeAndRedeemUSDLForEth(
        uint256 amount,
        uint256 dexIndex,
        uint256 minETHToGetBack
    ) external {
        unstakeAndRedeemUSDLForEthTo(
            msg.sender,
            amount,
            dexIndex,
            minETHToGetBack
        );
    }

    /**
     * @dev unstakeAndRedeemUSDLForEthTo is used to withdraw USDL by giving back xUSDL token to xUSDL contract
            and address(this) will get USDL token get back
            and once USDL token withdraw, then calling `usdl.withdrawTo` to withdraw weth collateral back
            and swap weth to eth by weth contract and transfer toAddress
            xUSDL->USDL->WETH->ETH
     * @notice before calling this function,
               msg.sender should have to approve this contract for xusdl address
     * @param to transfer collateral(eth) to toAddress
     * @param amount the amount of xUSDL tokend to burn and withdraw USDL tokens
     * @param dexIndex Index of perpetual dex, where position will be closed
    */
    function unstakeAndRedeemUSDLForEthTo(
        address to,
        uint256 amount,
        uint256 dexIndex,
        uint256 minETHToGetBack
    ) public {
        TransferHelper.safeTransferFrom(
            address(xusdl),
            msg.sender,
            address(this),
            amount
        );
        xusdl.withdraw(amount);
        usdl.withdrawTo(
            address(this),
            usdl.balanceOf(address(this)),
            dexIndex,
            minETHToGetBack,
            weth
        );
        weth.withdraw(weth.balanceOf(address(this)));
        TransferHelper.safeTransferETH(to, address(this).balance);
    }

    /**
     * @dev unstakeAndRedeemUSDL is used to withdraw USDL by giving back xUSDL token to xUSDL contract
            and address(this) will get USDL token get back 
            and once USDL token withdraw, _redeemUSDL method will burn USDL and will transfer collateral back to msg.sender
            xUSDL->USDL->collateral
     * @notice before calling this function,
               msg.sender should have to approve this contract for xusdl address
     * @param amount the amount of xUSDL tokens to burn and withdraw USDL tokens
     * @param minCollateralToGetBack collateralAmountToGetBack should be greater than equal to minCollateralToGetBack 
     * @param dexIndex Index of perpetual dex, where position will be closed
     * @param collateral collateral token address
    */
    function unstakeAndRedeemUSDL(
        uint256 amount,
        uint256 minCollateralToGetBack,
        uint256 dexIndex,
        IERC20 collateral
    ) external {
        unstakeAndRedeemUSDLTo(
            msg.sender,
            amount,
            minCollateralToGetBack,
            dexIndex,
            collateral
        );
    }

    /**
     * @dev unstakeAndRedeemUSDL is used to withdraw USDL by giving back xUSDL token to xUSDL contract
            and address(this) will get USDL token get back 
            and once USDL token withdraw, _redeemUSDL method will burn USDL and will transfer collateral back toAddress
            xUSDL->USDL->collateral
     * @notice before calling this function,
               msg.sender should have to approve this contract for xusdl address
     * @param to transfer collateral to toAddress
     * @param amount the amount of xUSDL tokens to burn and withdraw USDL tokens
     * @param minCollateralToGetBack collateralAmountToGetBack should be greater than equal to minCollateralToGetBack 
     * @param dexIndex Index of perpetual dex, where position will be closed
     * @param collateral collateral token address
    */
    function unstakeAndRedeemUSDLTo(
        address to,
        uint256 amount,
        uint256 minCollateralToGetBack,
        uint256 dexIndex,
        IERC20 collateral
    ) public {
        TransferHelper.safeTransferFrom(
            address(xusdl),
            msg.sender,
            address(this),
            amount
        );
        xusdl.withdraw(amount);
        _redeemUSDL(
            to,
            usdl.balanceOf(address(this)),
            dexIndex,
            minCollateralToGetBack,
            collateral
        );
    }

    /**
     * @dev unstakeAndRedeemToken is used to withdraw USDL by giving back xUSDL token to xUSDL contract
            and address(this) will get USDL token get back 
            and once USDL token withdraw, then calling `usdl.withdrawTo` to withdraw weth collateral back
            and swap weth to specified token by _swapToToken and tranfer specified token to msg.sender
            xUSDL->USDL->collateral->token
     * @notice before calling this function,
               msg.sender should have to approve this contract for xusdl address
     * @param token specified token address get back after collateral withdraw so will swap internally weth to token
     * @param swapActions it is the contract address of dex aggregator of 1inch
     * @param swapDatas it is the function signature which needs to call
     * @param amount amount of xUSDL want to burn
     * @param minTokenAmount after swap weth to token. tokenAmount should be greater than or equal to minTokenAmount
     * @param dexIndex Index of perpetual dex, where position will be closed
     * @param collateral collateral token address
    */
    function unstakeAndRedeemToken(
        IERC20 token,
        address[] memory swapActions,
        bytes[] memory swapDatas,
        uint256 amount,
        uint256 minTokenAmount,
        uint256 dexIndex,
        IERC20 collateral
    ) external {
        unstakeAndRedeemToToken(
            token,
            swapActions,
            swapDatas,
            msg.sender,
            amount,
            minTokenAmount,
            dexIndex,
            collateral
        );
    }

    /**
     * @dev unstakeAndRedeemToToken is used to withdraw USDL by giving back xUSDL token to xUSDL contract
            and address(this) will get USDL token get back 
            and once USDL token withdraw, then calling `usdl.withdrawTo` to withdraw weth collateral back
            and swap weth to specified token by _swapToToken and tranfer specified token to toAddress
            xUSDL->USDL->collateral->token
     * @notice before calling this function,
               msg.sender should have to approve this contract for xusdl address
     * @param token specified token address get back after collateral withdraw so will swap internally weth to token
     * @param swapActions it is the contract address of dex aggregator of 1inch
     * @param swapDatas it is the function signature which needs to call
     * @param to transfer specified tokens to toAddress
     * @param amount amount of xUSDL want to burn
     * @param minTokenAmount after swap weth to token. tokenAmount should be greater than or equal to minTokenAmount
     * @param dexIndex Index of perpetual dex, where position will be closed
     * @param collateral collateral token address
    */
    function unstakeAndRedeemToToken(
        IERC20 token,
        address[] memory swapActions,
        bytes[] memory swapDatas,
        address to,
        uint256 amount,
        uint256 minTokenAmount,
        uint256 dexIndex,
        IERC20 collateral
    ) public {
        TransferHelper.safeTransferFrom(
            address(xusdl),
            msg.sender,
            address(this),
            amount
        );

        xusdl.withdraw(amount);

        usdl.withdrawTo(
            address(this),
            usdl.balanceOf(address(this)),
            dexIndex,
            0,
            collateral
        );

        _swapToToken(token, swapActions, swapDatas, minTokenAmount);

        TransferHelper.safeTransfer(
            address(token),
            to,
            token.balanceOf(address(this))
        );

        swapCollateralForToken(
            address(collateral),
            address(token),
            collateral.balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import '../interfaces/IMulticall.sol';

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IUSDLemma is IERC20 {
    function depositTo(
        address to,
        uint256 amount,
        uint256 perpetualDEXIndex,
        uint256 maxCollateralRequired,
        IERC20 collateral
    ) external;

    function withdrawTo(
        address to,
        uint256 amount,
        uint256 perpetualDEXIndex,
        uint256 minCollateralToGetBack,
        IERC20 collateral
    ) external;

    function perpetualDEXWrappers(uint256 perpetualDEXIndex, address collateral)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXUSDL is IERC20 {
    
    function usdl() external view returns (IERC20); 

    /// @notice Balance of USDL in xUSDL contract
    /// @return Amount of USDL
    function balance() external view returns (uint256);

    /// @notice Minimum blocks user funds need to be locked in contract
    /// @return Minimum blocks for which USDL will be locked
    function MINIMUM_LOCK() external view returns (uint256);

    /// @notice Deposit and mint xUSDL in exchange of USDL
    /// @param amount of USDL to deposit
    /// @return Amount of xUSDL minted
    function deposit(uint256 amount) external returns (uint256);

    /// @notice Withdraw USDL and burn xUSDL
    /// @param shares of xUSDL to burn
    /// @return Amount of USDL withdrawn
    function withdraw(uint256 shares) external returns (uint256);

    /// @notice Withdraw USDL and burn xUSDL
    /// @param user address to withdraw usdl to
    /// @param shares of xUSDL to burn
    /// @return Amount of USDL withdrawn
    function withdrawTo(address user, uint256 shares) external returns (uint256);

    /// @notice Price per share in terms of USDL
    /// @return Price of 1 xUSDL in terms of USDL
    function pricePerShare() external view returns (uint256);

    /// @notice Block number after which user can withdraw USDL
    /// @return Block number after which user can withdraw USDL 
    function userUnlockBlock(address usr) external view returns (uint256);

    function updatePeriphery(address _periphery) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IPerpetualWrapper {
    function open(uint256 amount) external;

    function close(uint256 amount) external;

    function getCollateralAmountGivenUnderlyingAssetAmount(uint256 amount, bool isShorting)
        external
        returns (uint256 collateralAmountRequired);

    function reBalance(
        address _reBalancer,
        int256 amount,
        bytes calldata data
    ) external returns (bool);

    function getAmountInCollateralDecimals(uint256 amount, bool roundUp) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}