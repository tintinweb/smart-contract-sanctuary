// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV3Router.sol";
import "./IWETH.sol";
import {Path} from "./Path.sol";

contract matrEXRouterV3 is Ownable, IUniswapV3Router{
    using Path for bytes;

    /**
    * @dev Event emitted when the charity fee is taken
    * @param from: The user it is taken from
    * @param token: The token that was taken from the user
    * @param amount: The amount of the token taken for charity
    */
    event feeTaken(address from, IERC20 token, uint256 amount);

    /**
    * @dev Event emitted when the charity fee is taken (in ETH)
    * @param from: The user it was taken from
    * @param amount: The amount of ETH taken in wei
    */
    event feeTakenInETH(address from, uint256 amount);

    /**
    * @dev Event emmited when a token is approved for trade for the first
    * time on Uniswap (check takeFeeAndApprove())
    * @param token: The tokens that was approved for trade
    */
    event approvedForTrade(IERC20 token);

    /**
    * @dev 
    * _charityFee: The % that is taken from each swap that gets sent to charity
    * _charityAddress: The address that the charity funds get sent to
    * _uniswapV3Router: Uniswap router that all swaps go through
    * _WETH: The address of the WETH token
    */
    uint256 private _charityFee;
    address private _charityAddress;
    IUniswapV3Router private _uniswapV3Router;
    address private _WETH;

    /**
    * @dev Sets the Uniswap router, the charity fee, the charity address and
    * the WETH token address 
    */
    constructor(){
        _uniswapV3Router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        _charityFee = 20;
        _charityAddress = address(0x830be1dba01bfF12C706b967AcDeCd2fDEa48990);
        _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    /**
    * @dev Calculates the fee and takes it, transfers the fee to the charity
    * address and the remains to this contract.
    * emits feeTaken()
    * Then, it checks if there is enough approved for the swap, if not it
    * approves it to the uniswap contract. Emits approvedForTrade() if so.
    * @param user: The payer
    * @param token: The token that will be swapped and the fee will be paid
    * in
    * @param totalAmount: The total amount of tokens that will be swapped, will
    * be used to calculate how much the fee will be
    */
    function takeFeeAndApprove(address user, IERC20 token, uint256 totalAmount) internal returns (uint256){
        uint256 _feeTaken = (totalAmount * _charityFee) / 10000;
        token.transferFrom(user, address(this), totalAmount - _feeTaken);
        token.transferFrom(user, _charityAddress, _feeTaken);
        if (token.allowance(address(this), address(_uniswapV3Router)) < totalAmount){
            token.approve(address(_uniswapV3Router), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            emit approvedForTrade(token);
        }
        emit feeTaken(user, token, _feeTaken);
        return totalAmount -= _feeTaken;
    }

    /**
    * @dev Calculates the fee and takes it, holds the fee in the contract and 
    * can be sent to charity when someone calls withdraw()
    * This makes sure:
    * 1. That the user doesn't spend extra gas for an ERC20 transfer + 
    * wrap
    * 2. That funds can be safely transfered to a contract
    * emits feeTakenInETH()
    * @param totalAmount: The total amount of tokens that will be swapped, will
    * be used to calculate how much the fee will be
    */   
    function takeFeeETH(uint256 totalAmount) internal returns (uint256 fee){
        uint256 _feeTaken = (totalAmount * _charityFee) / 10000;
        emit feeTakenInETH(_msgSender(), _feeTaken);
        return totalAmount - _feeTaken;
    }
    
    /**
    * @dev The functions below are all the same as the Uniswap contract but
    * they call takeFeeAndApprove() or takeFeeETH() (See the functions above)
    * and deduct the fee from the amount that will be traded.
    */

    function exactInputSingle(ExactInputSingleParams calldata params) external virtual override payable returns (uint256){
        if (params.tokenIn == _WETH && msg.value >= params.amountIn){
            uint256 newValue = takeFeeETH(params.amountIn);
            ExactInputSingleParams memory params_ = params;
            params_.amountIn = newValue;
            return _uniswapV3Router.exactInputSingle{value: params_.amountIn}(params_);
        }else{
            IERC20 token = IERC20(params.tokenIn);
            uint256 newAmount = takeFeeAndApprove(_msgSender(), token, params.amountIn);
            ExactInputSingleParams memory _params = params;
            _params.amountIn = newAmount;
            return _uniswapV3Router.exactInputSingle(_params);
        }
    }
    
    function exactInput(ExactInputParams calldata params) external virtual override payable returns (uint256){
        (address tokenIn, address tokenOut, uint24 fee) = params.path.decodeFirstPool();
        if (tokenIn == _WETH && msg.value >= params.amountIn){
            uint256 newValue = takeFeeETH(params.amountIn);
            ExactInputParams memory params_ = params;
            params_.amountIn = newValue;
            return _uniswapV3Router.exactInput{value: params_.amountIn}(params_);
        }else{
            IERC20 token = IERC20(tokenIn);
            uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(token), params.amountIn);
            ExactInputParams memory _params = params;
            _params.amountIn = newAmount;
            return _uniswapV3Router.exactInput(_params);
        }
    }
    
     function exactOutputSingle(ExactOutputSingleParams calldata params) external virtual payable override returns (uint256){
        if (params.tokenIn == address(_WETH) && msg.value >= params.amountOut){
            uint256 newValue = takeFeeETH(params.amountOut);
            ExactOutputSingleParams memory params_ = params;
            params_.amountOut = newValue;
            return _uniswapV3Router.exactOutputSingle{value: params_.amountOut}(params_);
        }else{
            IERC20 token = IERC20(params.tokenIn);
            uint256 newAmount = takeFeeAndApprove(_msgSender(), token, params.amountOut);
            ExactOutputSingleParams memory _params = params;
            _params.amountOut = newAmount;
            return _uniswapV3Router.exactOutputSingle(_params);
        }
    }
    
    function exactOutput(ExactOutputParams calldata params) external virtual override payable returns (uint256){
        (address tokenIn, address tokenOut, uint24 fee) = params.path.decodeFirstPool();
         if (tokenIn == address(_WETH) && msg.value >= params.amountOut){
            uint256 newValue = takeFeeETH(params.amountOut);
            ExactOutputParams memory params_ = params;
            params_.amountOut == newValue;
            return _uniswapV3Router.exactOutput{value: params_.amountOut}(params_);
        }else{
            IERC20 token = IERC20(tokenIn);
            uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(token), params.amountOut);
            ExactOutputParams memory _params = params;
            _params.amountOut == newAmount;
            return _uniswapV3Router.exactOutput(_params);
        }
    } 

    /**
    * @dev Wraps all tokens in the contract and sends them to the charity 
    * address 
    * To know why, see takeFeeETH() 
    */
    function withdraw() external {
        uint256 contractBalance = address(this).balance;
        IWETH(_WETH).deposit{value: contractBalance}();
        IWETH(_WETH).transfer(_charityAddress, contractBalance);
    }
    
    /**
    * @dev Functions that only the owner can call that change the variables
    * in this contract
    */    
    function setCharityFee(uint256 newCharityFee) external onlyOwner {
        _charityFee = newCharityFee;
    }
    
    function setCharityAddress(address newCharityAddress) external onlyOwner {
        _charityAddress = newCharityAddress;
    }
    
    function setUniswapV3Router(IUniswapV3Router newUniswapV3Router) external onlyOwner {
        _uniswapV3Router = newUniswapV3Router;
    }

    function setWETH(address newWETH) external onlyOwner {
        _WETH = newWETH;
    }
    
    /**
    * @return Returns the % fee taken from each swap that goes to charity
    */
    function charityFee() external view returns (uint256) {
        return _charityFee;
    }
    
    /**
    * @return The address that the "Charity Fee" is sent to
    */
    function charityAddress() external view returns (address) {
        return _charityAddress;
    }
    
    /**
    * @return The router that all swaps will be directed through
    */
    function uniswapV3Router() external view returns (IUniswapV3Router) {
        return _uniswapV3Router;
    }

    /**
    * @return The current WETH contract that's being used
    */
    function WETH() external view returns (address) {
        return _WETH;
    }
}