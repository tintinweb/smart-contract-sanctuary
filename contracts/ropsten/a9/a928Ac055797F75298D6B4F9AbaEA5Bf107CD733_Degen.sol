/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(),"Not Owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),"Zero address not allowed");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface ISwapFactory {
     function swap(address tokenA, address tokenB, uint256 amount, address user, uint8 OrderType) external payable returns (bool);
     function getPairs(address tokenA, address tokenB) external view returns (address);
     function createPair(address tokenA, address tokenB, bool local) external returns (address payable pair);
}

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
    
    function mint(address to, uint256 amount) external returns(bool);

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

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface I1inch {

    function swap(IERC20 fromToken, IERC20 destToken, uint256 amount, uint256 minReturn, uint256[] calldata distribution, uint256 flags)
    external payable
    returns(uint256);
    
    function getExpectedReturn(IERC20 fromToken, IERC20 toToken, uint256 amount, uint256 parts, uint256 featureFlags) external
        view
        returns(
            uint256,
            uint256[] calldata
        );

    function makeGasDiscount(uint256 gasSpent, uint256 returnAmount, bytes calldata msgSenderCalldata) external;

}

interface IUni {

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external payable
    returns (uint[] memory amounts);
    
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
    external 
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function WETH() external pure returns (address);
}

interface IPoolSwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

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
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IGatewayVault {
    function vaultTransfer(address token, address recipient, uint256 amount) external returns (bool);
    function vaultApprove(address token, address spender, uint256 amount) external returns (bool);
}

library DisableFlags {
    function enabled(uint256 disableFlags, uint256 flag) internal pure returns(bool) {
        return (disableFlags & flag) == 0;
    }

    function disabledReserve(uint256 disableFlags, uint256 flag) internal pure returns(bool) {
        // For flag disabled by default (Kyber reserves)
        return enabled(disableFlags, flag);
    }

    function disabled(uint256 disableFlags, uint256 flag) internal pure returns(bool) {
        return (disableFlags & flag) != 0;
    }
}


abstract contract Router {
     using DisableFlags for uint256;
     
    uint256 public constant FLAG_UNISWAP = 0x01;
    uint256 public constant FLAG_SUSHI = 0x02;
    uint256 public constant FLAG_1INCH = 0x04;
    
    mapping (address => uint256) _disabledDEX;
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}

    event Received(address, uint);
    event Error(address);

    receive() external payable {
        // if (validUser[msg.sender] == true) {
        //     balance[msg.sender][ETH] += msg.value;
        emit Received(msg.sender, msg.value);
        // } else {
        //     balance[owner][ETH] += msg.value;
        // }
    }

    fallback() external payable {
        revert();
    }
    
    event Caught(string stringFailure,uint index,uint256 amount);

    I1inch OneSplit;
    IUni Uni;
    IUni Sushi;
    address ETH = address(0);
    constructor(address _Uni, address _sushi, address _oneSplit) public payable {
        // owner = payable(msg.sender);
        OneSplit = I1inch(_oneSplit);
        Uni = IUni(_Uni);
        Sushi = IUni(_sushi);
    }
    
    function getArray() internal returns(uint256[] memory){
        
    }
    
    function setDisabledDEX(uint256 _disableFlag) external returns(bool) {
        _disabledDEX[msg.sender] = _disableFlag;
        return true;
    }
    
    function getDisabledDEX(address account) public view returns(uint256) {
        return _disabledDEX[account];
    }
    
    function calculateUniswapReturn( uint256 amountIn, address[] memory path, OrderType orderType,uint256 /*disableFlags*/) public view returns(uint256, uint256[] memory) {
        uint256[] memory uniAmounts =new uint[](path.length);
        uint256[] memory distribution;

        uniAmounts[1] = uint256(0);
        
        if(orderType == OrderType.EthForTokens){
            path[0] = Uni.WETH();
            try Uni.getAmountsOut(amountIn, path)returns(uint256[] memory _amounts) {
                uniAmounts = _amounts;
            }
            catch{}
            
            
           
        } else if(orderType == OrderType.TokensForEth){
            path[path.length-1] = Uni.WETH();
            try Uni.getAmountsOut(amountIn, path)returns(uint256[] memory _amounts) {
                uniAmounts = _amounts;
            }catch{}
            
            
        } else{
            try Uni.getAmountsOut(amountIn, path)returns(uint256[] memory _amounts) {
                uniAmounts = _amounts;
            }catch{}
            
        }
        
        return (uniAmounts[1],distribution);
        

    }
    
    function calculateSushiReturn( uint256 amountIn, address[] memory path, OrderType orderType,uint256 /*disableFlags*/) public view returns(uint256, uint256[] memory) {
        uint256[] memory sushiAmounts =new uint[](path.length);
        uint256[] memory distribution;

        sushiAmounts[1] = uint256(0);
        
        if(orderType == OrderType.EthForTokens){
            try Sushi.getAmountsOut(amountIn, path) returns(uint256[] memory _amounts) {
                sushiAmounts = _amounts;
            }catch{}
            
           
        } else if(orderType == OrderType.TokensForEth){
            try Sushi.getAmountsOut(amountIn, path) returns(uint256[] memory _amounts) {
                sushiAmounts = _amounts;
            }catch{}
            
        } else{

            try Sushi.getAmountsOut(amountIn, path) returns(uint256[] memory _amounts) {
                sushiAmounts = _amounts;
            }catch{}
            
        }
        
        return (sushiAmounts[1],distribution);

    }
    
    function calculate1InchReturn( uint256 amountIn, address[] memory path, OrderType orderType,uint256 /*disableFlags*/) public view returns(uint256,uint256[] memory) {
        uint256 returnAmount;
        uint256[] memory distribution;

        if(orderType == OrderType.EthForTokens){
            path[0] = ETH;
            try OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[path.length-1]), amountIn, 100, 0) returns(uint256 _amount, uint256[] memory _distribution){
                returnAmount = _amount;
                distribution = _distribution;
            
            }catch{}
            
           
        } else if(orderType == OrderType.TokensForEth){
            path[path.length-1] = ETH;
            try OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[path.length-1]), amountIn, 100, 0) returns(uint256 _amount, uint256[] memory _distribution){
                returnAmount = _amount;
                distribution = _distribution;
            
            }catch{}
            
        } else{
             try OneSplit.getExpectedReturn(IERC20(path[0]), IERC20(path[path.length-1]), amountIn, 100, 0) returns(uint256 _amount, uint256[] memory _distribution){
                returnAmount = _amount;
                distribution = _distribution;
            
            }catch{}
            
        }
        
        return (returnAmount,distribution);

    }
    
    function _calculateNoReturn( uint256/* amountIn*/, address[] memory /*path*/, OrderType /*orderType*/,uint256 /*disableFlags*/) internal pure returns(uint256, uint256[] memory) {
        uint256[] memory distribution;
        return (uint256(0), distribution);
    }
    
    function getBestQuote(address[] memory path, uint256 amountIn, OrderType orderType, uint256 disableFlags) public view returns (uint, uint256,uint256[] memory) {
        
        function(uint256, address[] memory, OrderType ,uint256 ) view returns(uint256,uint256[]memory)[3] memory reserves = [
            disableFlags.disabled(FLAG_UNISWAP) ? _calculateNoReturn : calculateUniswapReturn,
            disableFlags.disabled(FLAG_SUSHI)   ? _calculateNoReturn : calculateSushiReturn,
            disableFlags.disabled(FLAG_1INCH)   ? _calculateNoReturn : _calculateNoReturn
        ];
        
        
        uint256[3] memory rates;
        uint256[][3] memory distribution;
        
        for (uint i = 0; i < rates.length; i++) {
            (rates[i],distribution[i]) = reserves[i](amountIn,path,orderType,disableFlags);
        }
        
        if(rates[1]>rates[0]) {
            if(rates[1]>rates[2]){
                return(2,rates[1],distribution[1]);
            } else{
                return(0,rates[2],distribution[2]);
            }
            
        } else {
            if(rates[0]>rates[2]) {
                return(1,rates[0],distribution[0]);
            } else {
                return(0,rates[2],distribution[2]);
            }
        }
        

        
    
    }
 
    function swap(address _fromToken, address _toToken, uint256 amountIn, uint256 minReturn, uint256[] memory distribution, uint256 flags)
    internal {
        if (_fromToken == ETH) {
            try OneSplit.swap{value: amountIn}(IERC20(ETH), IERC20(_toToken), amountIn, minReturn, distribution, flags)
             returns (uint256 amountOut){
                 TransferHelper.safeTransferFrom(_toToken, address(this), msg.sender, amountOut);
            } catch {
                emit Error(msg.sender);
                revert("Error");
            }
        } else {
             try OneSplit.swap(IERC20(_fromToken), IERC20(_toToken), amountIn, minReturn, distribution, flags)
              returns (uint256 amountOut){
                  if(_toToken == ETH){
                      msg.sender.transfer(amountOut);
                  } else {
                      TransferHelper.safeTransferFrom(_toToken, address(this), msg.sender, amountOut);
                  }
             } catch {
                emit Error(msg.sender);
                revert("Error");
            }
        }
    }
    
}
 
contract Degen is Router, Ownable {
    using SafeMath for uint256;
    address _oneSplit = address(0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E); //mainnet network address for oneInch
    address _Uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //ropsten network address for uniswap
    address _sushi = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // ropsten network address for sushiswap
    address USDT = address(0x47A530f3Fa882502344DC491549cA9c058dbC7Da); // USDT Token Address
    address swapFactoryAddress;
    address system;
    address gatewayVault;

    // address _swapFactory = address(0);
    I1inch OneSplitt = I1inch(_oneSplit);
    IUni Unii = IUni(_Uni);
    IUni Sushii = IUni(_sushi);
    IERC20 degen;
    ISwapFactory swapFactory;
    IPoolSwapPair poolContract;
   
   modifier onlySystem() {
        require(msg.sender == system,"Caller is not system");
        _;
    }
    
    
    constructor(address _tokenAddress, address _degEthPool, address _swapFactory, address _system, address _gatewayVault) Router( _Uni, _sushi, _oneSplit) public {
         degen = IERC20(_tokenAddress);
         poolContract = IPoolSwapPair(_degEthPool);
         swapFactory = ISwapFactory(_swapFactory);
         swapFactoryAddress = _swapFactory;
         system = _system;
         gatewayVault = _gatewayVault;
    }
    
    
    function degenPrice() public view returns (uint256){
        (uint112 reserve0, uint112 reserve1,) = poolContract.getReserves();
        if(poolContract.token0() == Uni.WETH()){
            return ((reserve1 * (10**18)) /(reserve0));
        } else {
            return ((reserve0 * (10**18)) /(reserve1));
        }
    }
    
    function setSwapFactory(address _swapFactory) external onlyOwner {
        swapFactory = ISwapFactory(_swapFactory);
        swapFactoryAddress = _swapFactory;
    }
    
    function setGatewayVault(address _gatewayVault) external onlyOwner returns(bool) {
        gatewayVault = _gatewayVault;
    }
    
    function setSystem (address _system) external onlyOwner returns(bool) {
        system = _system;
    }
    
    // added slippage and deadline
    function executeSwap(OrderType orderType, address[] memory path, uint256 assetInOffered, uint256 fees, uint256 minExpectedAmount) public payable  {
        uint256 gasTokens = 0;
        uint256 gasA = gasleft();
        if(orderType == OrderType.EthForTokens){
            require(msg.value >= assetInOffered.add(fees), "Payment = assetInOffered + fees");
            gasTokens = gasTokens + msg.value - assetInOffered;
        } else {
            require(msg.value >= fees, "fees not received");
            gasTokens = gasTokens + msg.value;
            TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), assetInOffered);
        }
        
        _swap(orderType,path,assetInOffered,minExpectedAmount,msg.sender,msg.sender);
       
   
        uint256 gasB = gasleft();
        gasTokens = gasTokens + (gasA - gasB)*tx.gasprice;
        uint256 degenAmount = (degenPrice() * gasTokens)/10**18;
        degen.mint(msg.sender, degenAmount);
        

        
    }
    
    function _swap( OrderType orderType, address[] memory path, uint256 assetInOffered,uint256 minExpectedAmount, address user,address to) internal returns(uint256){
         
         uint256 disableFlags = getDisabledDEX(user);

        (uint dexId, uint256 minAmountExpected, uint256[] memory distribution) = getBestQuote(path, assetInOffered,orderType ,disableFlags);
        require(minExpectedAmount <= minAmountExpected  , "Degen : Higher slippage than allowed.");
         
         if(dexId == 0){
            if(orderType == OrderType.EthForTokens) {
                 path[0] = ETH;
            }
            else if (orderType == OrderType.TokensForEth) {
                path[path.length-1] = ETH;
            }
            swap(path[0], path[path.length-1], assetInOffered, 0, distribution, 0);
        }

        
        else if(dexId == 1){
            uint[] memory swapResult;
            if(orderType == OrderType.EthForTokens) {
                 path[0] = Uni.WETH();
                 swapResult = Uni.swapExactETHForTokens{value:assetInOffered}(0, path, to,block.timestamp);
            }
            else if (orderType == OrderType.TokensForEth) {
                path[path.length-1] = Uni.WETH();
                TransferHelper.safeApprove(path[0], address(_Uni), assetInOffered);
                swapResult = Uni.swapExactTokensForETH(assetInOffered, 0, path,to, block.timestamp);
            }
            else if (orderType == OrderType.TokensForTokens) {
                TransferHelper.safeApprove(path[0], address(_Uni), assetInOffered);
                swapResult = Uni.swapExactTokensForTokens(assetInOffered, minAmountExpected, path, to, block.timestamp);
            }
        } 
        
        else if(dexId == 2){
            uint[] memory swapResult;
            if(orderType == OrderType.EthForTokens) {
                 path[0] = Sushii.WETH();
                 swapResult = Sushii.swapExactETHForTokens{value:assetInOffered}(minAmountExpected, path, to, block.timestamp);
            }
            else if (orderType == OrderType.TokensForEth) {
                path[path.length-1] = Sushii.WETH();
                TransferHelper.safeApprove(path[0], address(_sushi), assetInOffered);
                swapResult = Sushii.swapExactTokensForETH(assetInOffered, minAmountExpected, path, to, block.timestamp);
            }
            else if (orderType == OrderType.TokensForTokens) {
                TransferHelper.safeApprove(path[0], address(_sushi), assetInOffered);
                swapResult = Sushii.swapExactTokensForTokens(assetInOffered, minAmountExpected, path, to, block.timestamp);
            }
        }
        
        return minAmountExpected;
    }
    

    function executeCrossExchange(address[] memory path, OrderType orderType,uint8 crossOrderType, uint256 assetInOffered, uint256 fees,  uint256 minExpectedAmount) external payable {
        
        uint256 gasTokens = 0;
        uint256 gasA = gasleft();
        
        require(msg.value >= fees, "fees not received");
        gasTokens = gasTokens + msg.value;
        
        TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), assetInOffered);

        
        if(path[0] == USDT) {
            IERC20(USDT).approve(swapFactoryAddress,assetInOffered);
            swapFactory.swap(USDT,path[path.length-1],assetInOffered,msg.sender,crossOrderType);
        }
        
        else {
            address tokenB = path[path.length-1];
            uint256 minAmountExpected = _swap(orderType,path,assetInOffered,minExpectedAmount,msg.sender,address(this));
            
            
            
            IERC20(USDT).approve(swapFactoryAddress,minAmountExpected);
            swapFactory.swap(USDT,tokenB,minAmountExpected,msg.sender,crossOrderType);
        }
        
        
        uint256 gasB = gasleft();
        gasTokens = gasTokens + (gasA - gasB)*tx.gasprice;
        uint256 degenAmount = (degenPrice() * gasTokens)/10**18;
        degen.mint(msg.sender, degenAmount);
    }


    function callbackCrossExchange(address[] memory path, OrderType orderType, uint256 assetInOffered, address user) external returns(bool) {
        require(msg.sender == swapFactoryAddress , "Degen : caller is not SwapFactory");
        _swap(orderType,path,assetInOffered,uint256(0),user,user);
        
        return true;
    }



}