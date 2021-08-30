//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./SafeMath.sol";
import "./Address.sol";
import "./IXSurge.sol";
import "./INativeSurge.sol";
import "./Proxyable.sol";
import "./IUniswapV2Router02.sol";
import "./FeeManager.sol";

/// @title Data storage for XBridges
/// @author Markymark (SafemoonMark) & Gabriel Willen (Useless Surgeon)
/// @notice This is purely for memory alignment in the proxy
contract XBridgeData {
    using SafeMath for uint256;
    using Address for address;

    // xSurge Contract
    IXSurge _xSurge;
    // the exclusive owner of this contract
    address public privateOwner;
    // Name of the bridge
    string  name;
    // Surge Token we receive if bnb is sent to this contract
    address public receiveToken;
    // whether we are buying surge tokens or not
    bool public shouldBuySurgeToken;
    // if we are not buying surge tokens, whether bridge or user gets token
    bool public shouldSendTokensBackToOwner;
    // pcs router
    IUniswapV2Router02 router;
    // whether or not bridge handles logic when we receive BNB
    bool AutoSwapperDisabled;
    // fee manager
    FeeManager feeManager;

}

/// @title  A Unique Contract that allows Users to Privately Interact with the minting/burning of xSurge
/// @author SafemoonMark & Gabriel Willen (Useless Surgeon)
/// @notice There will be one contract deployed at without a userKey that all others will be proxies of.
contract XBridge is XBridgeData, Proxyable {

    using SafeMath for uint256;
    using Address for address;

    /*
        @notice This is required for the proxy implementation as the constructor will not be called..
        If a unique state is needed for the primary copy of the contract set the additional
        state variables inside the constructor as it will never be called again.
   */
    function bind(address userKey) public {
        require(privateOwner == address(0), "proxy already bound to owner");
        privateOwner = userKey;
        shouldBuySurgeToken = true;
        router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        receiveToken = 0x5B1d1BBDCc432213F83b15214B93Dc24D31855Ef;
        feeManager = FeeManager(0xD55bE063ffbD824488556B59c2d9700F3E3aE47f);
        name = "Bridget";
    }

    /// @notice Ensures only Private Owner can call certain functions
    modifier onlyPrivateOwner() {
        require(msg.sender == privateOwner);
        _;
    }

    /// @notice Redirects to init */
    constructor (address userKey) {
        require(msg.sender == 0x773415EbB1754892230b2C6515DF19FF468adB72, 'only manager can create bridges');
        bind(userKey);
    }

    /// @notice Redeems xSurge For Surge Tokens
    /// @param xToken from where the xSurge tokens will be sold
    /// @param xTokenAmount the quantity of xSurge tokens to be sold
    function sellXTokenForNative(address xToken, uint256 xTokenAmount) public onlyPrivateOwner {
        _sellXTokenForNative(xToken, xTokenAmount);
    }

    /// @notice Buys xSurge using Surge as collateral
    /// @param nativeToken the address of xSurge
    /// @param xToken the address of holding the surge used for collateral
    /// @dev Only the contract owner can call this function
    function buyXTokenWithNative(address nativeToken, address xToken) public onlyPrivateOwner {
        _buyXTokenWithNative(nativeToken, xToken, privateOwner);
    }

    /// @notice Buys xToken using a standard BEP20 Token as collateral
    /// @param nativeToken the address of the Native BEP20 Token
    /// @param xToken the address of xToken which holds BEP20 as collateral
    /// @dev Only the contract owner can call this function
    function buyXTokenWithNonSurgeToken(address nativeToken, address xToken) public onlyPrivateOwner {
        // instantiate xSurge
        _xSurge = IXSurge(xToken);
        // require that native Surge matches the xSurge passed in
        require(nativeToken == _xSurge.getNativeAddress(), 'Cannot create a different pegged xSurge!!');

        // get contract's amount of Native
        uint256 nNative = IERC20(nativeToken).balanceOf(privateOwner);
        // make sure there are more than zero tokens
        require(nNative > 0, 'cannot buy xSurge with zero tokens');

        // transfer SURGE to xSurge Contract Address
        bool success = IERC20(nativeToken).transferFrom(privateOwner, xToken, nNative);
        if (success) {
            // mint xSurge to Private Owner's Wallet
            bool succ = _xSurge.mintXToken(privateOwner, nNative);
            require(succ, 'cannot mint new tokens, tx failed');
        } else {
            revert('error sending tokens');
        }
    }

    /// @notice Withdraws Tokens to Private Owner's wallet in case of mistake
    /// @param token address of token being withdrawn
    function withdrawToken(address token, uint256 amount) external onlyPrivateOwner {
        // get contract's amount of tokens
        uint256 bal = IERC20(token).balanceOf(address(this));
        // make sure we have enough tokens to withdraw
        require(bal > 0 && bal >= amount, 'cannot withdraw 0 xSurge tokens');
        // if amount is zero use full balance
        amount = amount == 0 ? bal : amount;
        // send tokens back to owner
        IERC20(token).transfer(privateOwner, amount);
    }

    function withdrawBNB(uint256 amount) external onlyPrivateOwner {
        // make sure we have enough BNB to withdraw
        require(address(this).balance > 0 && amount <= address(this).balance, 'cannot withdraw 0 BNB');
        // if amount is zero, use full balance
        amount = amount == 0 ? address(this).balance : amount;
        // send BNB back to owner
        payable(privateOwner).transfer(address(this).balance);
    }
  
    function sellToken(address token, uint256 amount) external onlyPrivateOwner {
        // Uniswap Pair Path for BNB -> Token
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();
        // balance of contract
        uint256 bal = IERC20(token).balanceOf(address(this));
        // ensure we have enough tokens to trade
        require(bal >= amount && bal > 0, 'Cannot sell more tokens than are owned');
        // if amount is zero use full balance
        amount = amount == 0 ? bal : amount;
        // approve transfer
        IERC20(token).approve(address(router), bal);
        // Swap Token for BNB
        try router.swapExactTokensForETH(
            bal,
            0,
            path,
            privateOwner, // Send To Private Owner
            block.timestamp.add(30)
        ) {} catch{revert();}
    }
    
    function sellTokenSupportingFees(address token, uint256 amount) external onlyPrivateOwner {
        // Uniswap Pair Path for BNB -> Token
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();
        // balance of contract
        uint256 bal = IERC20(token).balanceOf(address(this));
        // ensure we have enough tokens to trade
        require(bal >= amount && bal > 0, 'Cannot sell more tokens than are owned');
        // if amount is zero use full balance
        amount = amount == 0 ? bal : amount;
        // approve transfer
        IERC20(token).approve(address(router), bal);
        // Swap Token for BNB
        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            bal,
            0,
            path,
            privateOwner, // Send To Private Owner
            block.timestamp.add(30)
        ) {} catch{revert();}
    }
    
    /** Swaps xTokens for xTokens on Pancakeswap assuming a pairing exists */
    function swapTokenForTokenPCS(address tokenOne, address tokenTwo, uint256 amountTokenOne, bool sendTokensToBridgeOwner) external onlyPrivateOwner {
        address receiver = sendTokensToBridgeOwner ? privateOwner : address(this);
        _swapTokenForToken(tokenOne, tokenTwo, amountTokenOne, receiver);
    }
    
    /** Swaps xTokens for xTokens on Pancakeswap assuming a pairing exists */
    function swapTokenForTokenPCSUsingBNB(address tokenOne, address tokenTwo, uint256 amountTokenOne, bool sendTokensToBridgeOwner) external onlyPrivateOwner {
        address receiver = sendTokensToBridgeOwner ? privateOwner : address(this);
        _swapTokenForTokenBNBCentered(tokenOne, tokenTwo, amountTokenOne, receiver);
    }
    
    function swapTokenForTokenPCSUsingBNBWithTransferFees(address tokenOne, address tokenTwo, uint256 amountTokenOne, bool sendTokensToBridgeOwner) external onlyPrivateOwner {
        address receiver = sendTokensToBridgeOwner ? privateOwner : address(this);
        _swapTokenForTokenBNBCenteredWithTransferFees(tokenOne, tokenTwo, amountTokenOne, receiver);
    }

    /** Sells Native Surge Tokens For Underlying Asset */
    function sellNativeSurgeForUnderlyingAsset(address nativeSurge, uint256 amount) external onlyPrivateOwner {
        // balance of native surge in bridge
        uint256 bal = IERC20(nativeSurge).balanceOf(address(this));
        // ensure we have enough tokens to sell
        require(bal >= amount && bal > 0, 'Cannot Redeem Zero Native Surge'); 
        // if amount is zero use full balance
        amount = amount == 0 ? bal : amount;
        if (AutoSwapperDisabled) {
            // sell Native Surge for Underlying Asset
            INativeSurge(nativeSurge).sell(amount);
        } else {
            // disable receive function incase BNB is returned
            AutoSwapperDisabled = true;
            // sell Native Surge for Underlying Asset
            INativeSurge(nativeSurge).sell(amount);
            // re enable receive function
            AutoSwapperDisabled = false;
        }
    }

    /** Disables the Swapper Contract From Taking Effect When Receiving BNB */
    function disableAutoSwapperWhenBNBReceived() external onlyPrivateOwner {
        AutoSwapperDisabled = true;
    }

    /** Swaps Surge Tokens for Surge Tokens by utilizing xTokens and PCS */
    function swapNativeSurgeForNativeSurge(address nativeSurgeOne, address xSurgeOne, address xSurgeTwo, uint256 amountSurgeOne) external onlyPrivateOwner {
        // balance of NativeSurge in Contract
        uint256 nativeBalance = IERC20(nativeSurgeOne).balanceOf(address(this));
        // ensure we have enough surge to swap
        require(amountSurgeOne <= nativeBalance && nativeBalance > 0, 'cannot swap zero tokens');
        // if amountSurgeOne is zero, use full balance
        amountSurgeOne = amountSurgeOne == 0 ? nativeBalance : amountSurgeOne;
        // balance of xSurgeOne before swap
        uint256 balBefore = IERC20(xSurgeOne).balanceOf(address(this));
        // buy xToken with Native, storing in contract
        _buyXTokenWithNative(nativeSurgeOne, xSurgeOne, address(this));
        // xSurge Balance
        uint256 bal = IERC20(xSurgeOne).balanceOf(address(this)).sub(balBefore);
        // swap xToken for new xToken
        require(bal > 1, 'cannot swap with less than two tokens');
        // balance of xTokenTwo before swap
        uint256 xTokenTwoBalanceBefore = IERC20(xSurgeTwo).balanceOf(privateOwner);
        // swap xToken for desired xToken, storing in owner wallet
        _swapTokenForToken(xSurgeOne, xSurgeTwo, bal, privateOwner);
        // how many xTokens did we swap for
        uint256 xTokenTwoBalance = IERC20(xSurgeTwo).balanceOf(privateOwner).sub(xTokenTwoBalanceBefore);
        // make sure its greater than zero
        require(xTokenTwoBalance > 0, 'cannot redeem zero xSurge Tokens');
        // redeem newly swapped xToken for native, sending to private Owner
        _sellXTokenForNative(xSurgeTwo, xTokenTwoBalance);
    }
    
    /// @notice Set the name of this bridge
    /// @param newName the new name for this personal contract
    function setBridgeName(string calldata newName) public onlyPrivateOwner {
        name = newName;
    }

    /** Sets Swapper Criteria */
    function setAutoSwapperToken(address tokenToPurchase, bool shouldSendTokensBackToOwnerOnSwap, bool isSurgeToken) public onlyPrivateOwner {
        receiveToken = tokenToPurchase;
        shouldSendTokensBackToOwner = shouldSendTokensBackToOwnerOnSwap;
        shouldBuySurgeToken = isSurgeToken;
    }

    /** Upgrades PCS Router to a different router */
    function upgradePancakeswapRouterForPersonalBridge(address newRouter) external onlyPrivateOwner {
        router = IUniswapV2Router02(newRouter);
    }
    
    /// @notice Get the name of this bridge
    /// @return the name of this personal bridge
    function getBridgeName() public view returns (string memory) {
        return name;
    }
    
    function getTokenBalanceInContract(address token) public view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getDecimalsOfToken(address token) public view returns (uint8) {
        return IERC20(token).decimals();
    }
    
    function getPriceOfTokenInToken(address tokenOne, address tokenTwo, uint256 amountTokenOne) public view returns(uint256){
        address[] memory path = new address[](2);
        path[0] = tokenOne;
        path[1] = tokenTwo;

        return router.getAmountsOut(amountTokenOne, path)[1];
    }
    
    function _sellXTokenForNative(address xToken, uint256 xTokenAmount) private {
        // make sure we're selling more than zero
        require(xTokenAmount > 0, 'Cannot Sell zero xSurge');
        // instantiate xSurge
        _xSurge = IXSurge(xToken);
        // get owner's balance of xSurge
        uint256 xSurgeBalance = _xSurge.balanceOf(privateOwner);
        // make sure they can sell this amount
        require(xSurgeBalance >= xTokenAmount, 'cannot sell more surge than you own');
        // allocate your xSurge Balance to Zero
        bool success = _xSurge.redeemNative(privateOwner, xTokenAmount);
        require(success, 'could not redeem xSurge');
    }
    
    function _buyXTokenWithNative(address nativeToken, address xToken, address receiver) private {
        // instantiate xSurge
        _xSurge = IXSurge(xToken);
        // require that native Surge matches the xSurge passed in
        require(nativeToken == _xSurge.getNativeAddress(), 'Cannot create a different pegged xSurge!!');

        // get contract's amount of Surge
        uint256 nSurge = IERC20(nativeToken).balanceOf(address(this));
        // make sure we have more than zero tokens
        require(nSurge > 0, 'cannot buy xSurge with zero tokens');

        // transfer SURGE to xSurge Contract Address
        bool success = IERC20(nativeToken).transfer(xToken, nSurge);
        if (success) {
            // mint xSurge to Private Owner's Wallet
            bool succ = _xSurge.mintXToken(receiver, nSurge);
            require(succ, 'cannot mint new tokens, tx failed');
        } else {
            revert('error sending tokens');
        }
    }
    
    /** Swaps xSurgeTokens for xSurgeTokens on Pancakeswap assuming a pairing exists */
    function _swapTokenForToken(address tokenOne, address tokenTwo, uint256 amountTokenOne, address receiver) private {
        // balance in contract
        uint256 bal = IERC20(tokenOne).balanceOf(address(this));
        // require we have enough of token one for swap
        require(bal >= amountTokenOne && bal > 0, 'cannot swap with more than you own');
        // if amount is zero use full balance 
        amountTokenOne = amountTokenOne == 0 ? bal : amountTokenOne;
        // Uniswap Pair Path for Token -> Token
        address[] memory path = new address[](2);
        path[0] = tokenOne;
        path[1] = tokenTwo;
        // approve transaction
        IERC20(tokenOne).approve(address(router), amountTokenOne);

        // Swap Token for Token
        try router.swapExactTokensForTokens(
            amountTokenOne,
            0, // accept as many xTokens as we can
            path,
            receiver, // Send To Recipient
            block.timestamp.add(30)
        ) {} catch{revert();}
    }
    
    /** Swaps xSurgeTokens for xSurgeTokens on Pancakeswap assuming a pairing exists */
    function _swapTokenForTokenBNBCentered(address tokenOne, address tokenTwo, uint256 amountTokenOne, address receiver) private {
        // balance in contract
        uint256 bal = IERC20(tokenOne).balanceOf(address(this));
        // check if contract owns enough of token one
        require(bal >= amountTokenOne && bal > 0, 'cannot swap with more than you own');
        // if amount is zero, use full balance
        amountTokenOne = amountTokenOne == 0 ? bal : amountTokenOne;
        // Uniswap Pair Path for Token -> Token
        address[] memory path = new address[](3);
        path[0] = tokenOne;
        path[1] = router.WETH();
        path[2] = tokenTwo;
        // approve transfer
        IERC20(tokenOne).approve(address(router), amountTokenOne);
        // Swap Token for Token
        try router.swapExactTokensForTokens(
            amountTokenOne,
            0, // accept as many xTokens as we can
            path,
            receiver, // Send To Recipient
            block.timestamp.add(30)
        ) {} catch{revert();}
    }
    
    /** Swaps xSurgeTokens for xSurgeTokens on Pancakeswap assuming a pairing exists */
    function _swapTokenForTokenBNBCenteredWithTransferFees(address tokenOne, address tokenTwo, uint256 amountTokenOne, address receiver) private {
        // balance in contract
        uint256 bal = IERC20(tokenOne).balanceOf(address(this));
        // check if contract owns enough of token one
        require(bal >= amountTokenOne && bal > 0, 'cannot swap with more than you own');
        // if amount is zero, use full balance
        amountTokenOne = amountTokenOne == 0 ? bal : amountTokenOne;
        // Uniswap Pair Path for Token -> Token
        address[] memory path = new address[](3);
        path[0] = tokenOne;
        path[1] = router.WETH();
        path[2] = tokenTwo;
        // approve transfer
        IERC20(tokenOne).approve(address(router), amountTokenOne);
        // Swap Token for Token
        try router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountTokenOne,
            0, // accept as many xTokens as we can
            path,
            receiver, // Send To Recipient
            block.timestamp.add(30)
        ) {} catch{revert();}
    }
    
    /** Swaps BNB For Specified Token, delivers to receiver address */
    function swapBNBForToken() private {
        // Uniswap Pair Path for BNB -> Token
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = receiveToken;
        // receiver of function
        address receiver = shouldSendTokensBackToOwner ? privateOwner : address(this);
        // funding
        uint256 tax = feeManager.calculateTaxAmount(msg.value);
        uint256 sendAmount = msg.value.sub(tax);
        // Swap BNB for Token
        try router.swapExactETHForTokens{value: sendAmount}(
            0, // accept as many tokens as we can
            path,
            receiver, // Send To Recipient
            block.timestamp.add(30)
        ) {} catch{revert();}
        
        if (tax > 0) {
            (bool success,) = feeManager.getFeeReceiver().call{value: tax, gas: 26000}("");
            if (success) {}
        }
    }

    /// @notice Purchase BNBSurge and store it in contract in the event BNB is sent to a bridge
    receive() external payable {
        if (AutoSwapperDisabled) return;
        if (shouldBuySurgeToken) {
            (bool successful,) = payable(receiveToken).call{value: msg.value, gas: 200000}("");
            require(successful, 'error purchasing surge');
        } else {
            swapBNBForToken();
        }
    }
}