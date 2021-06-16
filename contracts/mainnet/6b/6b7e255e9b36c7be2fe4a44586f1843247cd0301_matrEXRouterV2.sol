// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
import "./Ownable.sol";
import "./IUniswapV2Router.sol";
import "./IERC20.sol";
import "./IWETH.sol";

contract matrEXRouterV2 is Ownable, IUniswapV2Router{
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
    * _uniswapV2Router: Uniswap router that all swaps go through
    */
    uint256 private _charityFee;
    address private _charityAddress;
    address private _WETH;
    IUniswapV2Router private _uniswapV2Router;

    /**
    * @dev Sets the Uniswap Router, Charity Fee and Charity Address 
    */
    constructor(){
        _uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _charityFee = 20;
        _charityAddress = address(0x830be1dba01bfF12C706b967AcDeCd2fDEa48990);
        _WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    /**
    * @dev Calculates the fee and takes it, transfers the fee to the charity
    * address and the remains to this contract.
    * emits feeTaken()
    * Then, it checks if there is enough approved for the swap, if not it
    * approves it to the uniswap contract. Emits approvedForTrade if so.
    * @param user: The payer
    * @param token: The token that will be swapped and the fee will be paid
    * in
    * @param totalAmount: The total amount of tokens that will be swapped, will
    * be used to calculate how much the fee will be
    */
    function takeFeeAndApprove(address user, IERC20 token, uint256 totalAmount) internal returns (uint256){
        uint256 _feeTaken = (totalAmount / 10000) * _charityFee;
        token.transferFrom(user, address(this), totalAmount - _feeTaken);
        token.transferFrom(user, _charityAddress, _feeTaken);
        if (token.allowance(address(this), address(_uniswapV2Router)) < totalAmount){
            token.approve(address(_uniswapV2Router), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
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
    function takeFeeETH(uint256 totalAmount) internal returns (uint256){
        uint256 fee = (totalAmount / 10000) * _charityFee;
        emit feeTakenInETH(_msgSender(), fee);
        return totalAmount - fee;
    }
    
    /**
    * @dev The functions below are all the same as the Uniswap contract but
    * they call takeFeeAndApprove() or takeFeeETH() (See the functions above)
    * and deduct the fee from the amount that will be traded.
    */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts){
        uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountIn);
        return _uniswapV2Router.swapExactTokensForTokens(newAmount, amountOutMin, path, to,deadline);
    }
    
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external override returns (uint[] memory amounts){
        uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountOut);
        return _uniswapV2Router.swapTokensForExactTokens(newAmount, amountInMax, path, to,deadline);
        
    }
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        override
        returns (uint[] memory amounts){
            uint256 newValue = takeFeeETH(msg.value);
            return _uniswapV2Router.swapExactETHForTokens{value: newValue}(amountOutMin, path, to, deadline);
        }
        
        
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external override
        returns (uint[] memory amounts){
            uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountOut);
            return _uniswapV2Router.swapTokensForExactETH(newAmount, amountInMax, path, to, deadline);
        }
        
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external override
        returns (uint[] memory amounts) {
            uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountIn);
            return _uniswapV2Router.swapExactTokensForETH(newAmount, amountOutMin, path, to, deadline);
        }
    
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable override
        returns (uint[] memory amounts){
            uint256 newValue = takeFeeETH(msg.value);
            return _uniswapV2Router.swapETHForExactTokens{value: newValue}(amountOut, path, to, deadline);
        }
    
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override {
        uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountIn);
        return _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(newAmount, amountOutMin, path, to, deadline);
    }
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override payable{
        uint256 newValue = takeFeeETH(msg.value);
        return _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: newValue}(amountOutMin, path, to, deadline);
    }
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external override {
        uint256 newAmount = takeFeeAndApprove(_msgSender(), IERC20(path[0]), amountIn);
        return _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(newAmount, amountOutMin, path, to, deadline);
    }

    /**
    * @dev Same as Uniswap
    */
    function quote(uint amountA, uint reserveA, uint reserveB) external override pure returns (uint amountB){
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * reserveB) / reserveA;
    }
    
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure override returns (uint amountOut){
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }
    
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external override pure returns (uint amountIn){
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = (reserveIn * amountOut) * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external override view returns (uint[] memory amounts){
        return _uniswapV2Router.getAmountsOut(amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] calldata path) external override view returns (uint[] memory amounts){
        return _uniswapV2Router.getAmountsIn(amountOut, path);
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
    
    function setUniswapV2Router(IUniswapV2Router newUniswapV2Router) external onlyOwner {
        _uniswapV2Router = newUniswapV2Router;
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
    function uniswapV2Router() external view returns (IUniswapV2Router) {
        return _uniswapV2Router;
    }

    /**
    * @return The current WETH contract that's being used
    */
    function WETH() external view returns (address) {
        return _WETH;
    }
}