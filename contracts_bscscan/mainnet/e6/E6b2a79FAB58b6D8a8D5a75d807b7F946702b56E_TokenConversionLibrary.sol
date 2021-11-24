// SPDX-License-Identifier: GPLv2
pragma solidity 0.8.9;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFactory {
    function checkIfTokensCanBeExchangedWith1Exchange(address _fromToken, address _toToken) external returns(bool, address, address[] memory);
    function getInContract(uint256 _exchange) external returns (address);
    function getOutContract(uint256 _exchange) external returns (address);
    function isAddressApprovedForStaticFunctions(address _address, uint256 riskLevel) external view returns (bool);
    function isAddressApprovedForDirectCallFunction(address _address, uint256 riskLevel) external view returns (bool);
    function yieldStakeContract() external view returns (address);
    function yieldStakePair() external view returns (address);
    function yieldStakeRewardToken() external view returns (address);
    function yieldStakeExchange() external view returns (uint256);
    function getYieldStakeSettings() external view returns (address, address, uint256, uint256, uint256, uint256, address);
    function developmentFund() external view returns (address payable);
    function networkNativeToken() external view returns (address);
    function yieldToken() external view returns (address);
    function onRewardNativeDevelopmentFund() external view returns (uint256);//5.00%
    function onRewardNativeBurn() external view returns (uint256);//5.00%
    function onRewardYieldDevelopmentFund() external view returns (uint256);//2.50%
    function onRewardYieldBurn() external view returns (uint256);//2.50%
    function generatePersonalContractEvent(string calldata _type, bytes calldata _data) external;
}

interface IWBNBWETH {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

interface ITokenExchangeRouter {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);
}


library TokenConversionLibrary {

    /**
    @notice Estimate tokens to eth or wbnb
    @param _fromToken personal contract will work with pools only if their risk level is less than this variable. 0-100%
    @param _amount personal contract will work with pools only if their risk level is less than this variable. 0-100%
    */
    function estimateTokenAndNetworkNative(address _factory, address _fromToken, address _toToken, uint256 _amount) public returns (uint256) {

        address networkNativeToken = IFactory(_factory).networkNativeToken();
        if(_fromToken == address(0))_fromToken = networkNativeToken;//for estimation, to exclude ZERO_ADDRESS error
        if(_toToken == address(0))_toToken = networkNativeToken;//for estimation, to exclude ZERO_ADDRESS error

        if(_fromToken == networkNativeToken && _toToken == networkNativeToken){
            //means we would like to exchange WETH(WBNB) to ETH(BNB) or vice versa
            return _amount;
        }
     
        (, address router, address[] memory path) = IFactory(_factory).checkIfTokensCanBeExchangedWith1Exchange(_fromToken, _toToken);
        return ITokenExchangeRouter(router).getAmountsOut(_amount, path)[path.length - 1];
    }

    /**
    @notice convert any tokens to any tokens.
    @param _fromToken address of token witch will be converted
    @param _toToken address of token witch will be returned
    @param _amount how much will be converted
    */
    function estimateTokenToToken(address _factory, address _fromToken, address _toToken, uint256 _amount) public returns (uint256) {       

        if(_fromToken == address(0) || _toToken == address(0)){
            return estimateTokenAndNetworkNative(_factory, _fromToken, _toToken, _amount);
        }

        if(_fromToken == _toToken)return _amount;

        (bool sameExchange, address routerAddress, address[] memory path) = IFactory(_factory).checkIfTokensCanBeExchangedWith1Exchange(_fromToken, _toToken);

        if(!sameExchange){
            _amount = ITokenExchangeRouter(routerAddress).getAmountsOut(_amount, path)[path.length - 1];
            return estimateTokenAndNetworkNative(_factory, IFactory(_factory).networkNativeToken(), _toToken, _amount);
        }

        return ITokenExchangeRouter(routerAddress).getAmountsOut(_amount, path)[path.length - 1];

    }


    /**
    @notice Convert tokens to eth or wbnb
    @param _toWhomToIssue personal contract will work with pools only if their risk level is less than this variable. 0-100%
    @param _tokenToExchange personal contract will work with pools only if their risk level is less than this variable. 0-100%
    @param _amount personal contract will work with pools only if their risk level is less than this variable. 0-100%
    */
    function convertTokenToETH(address _factory, address _toWhomToIssue, address _tokenToExchange, uint256 _amount, uint256 _minOutputAmount) public returns (uint256) {

        address networkNativeToken = IFactory(_factory).networkNativeToken();
        if(_tokenToExchange == networkNativeToken){
            address yieldToken = IFactory(_factory).yieldToken();
            //means we would like to exchange WETH(WBNB) to ETH(BNB)
            //IWBNBWETH(networkNativeToken).withdraw(_amount); - this reverts due to https://eips.ethereum.org/EIPS/eip-1884[EIP1884]
            //have to do this: WETH -> YIELD TOKEN -> ETH
            _amount = convertTokenToToken(_factory, address(this), _tokenToExchange, yieldToken,  _amount, 1);//min tokens doesn't matter here, we'll check in the last conversion
            _tokenToExchange = yieldToken;
        }
     
        (, address router, address[] memory path) = IFactory(_factory).checkIfTokensCanBeExchangedWith1Exchange(_tokenToExchange, networkNativeToken);
        
        _approve(_tokenToExchange, router, _amount);

        return ITokenExchangeRouter(router).swapExactTokensForETH(
            _amount,
            _minOutputAmount,
            path,
            _toWhomToIssue,
            block.timestamp
        )[path.length - 1];
    }

    /**
    @notice Convert eth to token or wbnb
    @param _toWhomToIssue personal contract will work with pools only if their risk level is less than this variable. 0-100%
    @param _tokenToExchange personal contract will work with pools only if their risk level is less than this variable. 0-100%
    */
    function convertETHToToken(address _factory, address _toWhomToIssue, address _tokenToExchange, uint256 _amount, uint256 _minOutputAmount) public returns (uint256)  {

        address networkNativeToken = IFactory(_factory).networkNativeToken();
        if(_tokenToExchange == networkNativeToken){
            //means we would like to exthange ETH(BNB) to WETH(WBNB)
            IWBNBWETH(networkNativeToken).deposit{value: _amount}();
            if(_toWhomToIssue != address(this)){
                IERC20(networkNativeToken).transfer(_toWhomToIssue, _amount);
            }
            return _amount;
        }

        (, address router, address[] memory path) = IFactory(_factory).checkIfTokensCanBeExchangedWith1Exchange(networkNativeToken, _tokenToExchange);

        return ITokenExchangeRouter(router).swapExactETHForTokens{value: _amount}(
            _minOutputAmount,
            path,
            _toWhomToIssue,
            block.timestamp
        )[path.length - 1];
    }

    /**
    @notice convert any tokens to any tokens.
    @param _toWhomToIssue is address of personal contract for this user
    @param _fromToken address of token witch will be converted
    @param _toToken address of token witch will be returned
    @param _amount how much will be converted
    */
    function convertTokenToToken(address _factory, address _toWhomToIssue, address _fromToken, address _toToken, uint256 _amount, uint256 _minOutputAmount) public returns (uint256) {       

        if(_fromToken == address(0)){
            return convertETHToToken(_factory, _toWhomToIssue, _toToken, _amount, _minOutputAmount);
        }

        if(_toToken == address(0)){
            return convertTokenToETH(_factory, _toWhomToIssue, _fromToken, _amount, _minOutputAmount);
        }

        if(_fromToken == _toToken)return _amount;

        (bool sameExchange, address routerAddress, address[] memory path) = IFactory(_factory).checkIfTokensCanBeExchangedWith1Exchange(_fromToken, _toToken);

        _approve(_fromToken, routerAddress, _amount);
        if(!sameExchange){
            uint256 nativeTokenAmount =  ITokenExchangeRouter(routerAddress).swapExactTokensForETH(
                _amount,
                1,
                path,
                address(this),
                block.timestamp
            )[path.length - 1];
            return convertETHToToken(_factory, _toWhomToIssue, _toToken, nativeTokenAmount, _minOutputAmount);
        }

        //TODO: add min tokens variable instead of 1. (function swapExactTokensForETH), Search key mintokn1024
        //this is high priority

        return ITokenExchangeRouter(routerAddress).swapExactTokensForTokens(
            _amount,
            _minOutputAmount,
            path,
            _toWhomToIssue,
            block.timestamp
        )[path.length - 1];

    }

    
    /**
    @notice convert array of tokens to a token.
    @param _factory is needed to check if tokens can be exchanged with 1 exchange
    @param _convertToToken is the desired token
    @param _toWhomToIssue is address of personal contract for this user
    @param _tokens array of tokens to be converted
    @param _minTokensRec reverts if less tokens received than this (if conversion happen)
    @return balance of the 1 desired token in this address 
    */
    function convertArrayOfTokensToToken(address _factory, address[] memory _tokens, address _convertToToken, address _toWhomToIssue, uint256 _minTokensRec) external returns (uint256) {
        
        uint256 amount;
        for (uint256 i; i < _tokens.length; i++){
            if(_tokens[i] != _convertToToken){
                uint256 b = IERC20(_tokens[i]).balanceOf(address(this));
                if(b > 0){
                    amount += convertTokenToToken(_factory, _toWhomToIssue, _tokens[i], _convertToToken, b, 1);
                }
            }
        }

        //note: amount can be 0, cause we may not have some tokens on balance, but we can't revert 
        //can't revert cause it might break complex unstake process. where single conversion doesn't metter
        require(amount == 0 || amount >= _minTokensRec, 'convert tokens to token: slippage error');

        //return all balance, not just freshly converted
        //this is cause there is no split logic
        return IERC20(_convertToToken).balanceOf(address(this));
    }

    function _approve(address _token, address _spender, uint256 _amount) internal {
        //first set to 0 due to:
        //1. USDT: https://github.com/Uniswap/uniswap-interface/issues/1172
        //2. in case SafeERC20: approve from non-zero to non-zero allowance
        IERC20(_token).approve(_spender, 0);
        IERC20(_token).approve(_spender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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