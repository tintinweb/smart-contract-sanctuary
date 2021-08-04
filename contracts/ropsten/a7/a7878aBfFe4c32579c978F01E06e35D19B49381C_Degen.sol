/**
 *Submitted for verification at Etherscan.io on 2021-08-04
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

    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
    external payable 
    returns (uint amountToken, uint amountETH, uint liquidity);
}

interface I0xToken {

    function sellTokenForToken(address inputToken, address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData)
    external
    returns (uint256 boughtAmount);

    function sellEthForToken(address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData)
    external payable
    returns (uint256 boughtAmount);

    function sellTokenForEth(address inputToken, address payable recipient, uint256 minBuyAmount, bytes calldata auxiliaryData)
    external
    returns (uint256 boughtAmount);

    function getSellQuote(address inputToken, address outputToken, uint256 sellAmount)
    external view
    returns (uint256 outputTokenAmount);
}

// interface ICurve {
//     // solium-disable-next-line mixedcase
//     function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

//     // solium-disable-next-line mixedcase
//     function get_dy(int128 i, int128 j, uint256 dx) external view returns(uint256 dy);

//     // solium-disable-next-line mixedcase
//     function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 minDy) external;

//     // solium-disable-next-line mixedcase
//     function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;
// }


// pragma experimental ABIEncoderV2;

// library Types {
//   bytes constant internal EIP191_HEADER = "\x19\x01";
//   struct Order {
//     uint256 nonce;                // Unique per order and should be sequential
//     uint256 expiry;               // Expiry in seconds since 1 January 1970
//     Party signer;                 // Party to the trade that sets terms
//     Party sender;                 // Party to the trade that accepts terms
//     Party affiliate;              // Party compensated for facilitating (optional)
//     Signature signature;          // Signature of the order
//   }
//   struct Party {
//     bytes4 kind;                  // Interface ID of the token
//     address wallet;               // Wallet address of the party
//     address token;                // Contract address of the token
//     uint256 amount;               // Amount for ERC-20 or ERC-1155
//     uint256 id;                   // ID for ERC-721 or ERC-1155
//   }
//   struct Signature {
//     address signatory;            // Address of the wallet used to sign
//     address validator;            // Address of the intended swap contract
//     bytes1 version;               // EIP-191 signature version
//     uint8 v;                      // `v` value of an ECDSA signature
//     bytes32 r;                    // `r` value of an ECDSA signature
//     bytes32 s;                    // `s` value of an ECDSA signature
//   }
// }
// interface IAirSwap {

//     // function getSignerSideQuote(uint256 senderAmount, address senderToken, address signerToken) 
//     // external view 
//     // returns (uint256 signerAmount);

//     // function getSenderSideQuote(uint256 signerAmount, address signerToken, address senderToken) 
//     // external view 
//     // returns (uint256 senderAmount);

//     function getMaxQuote(address senderToken, address signerToken)
//     external view
//     returns (uint256 senderAmount, uint256 signerAmount);

//     function swap(
//     Types.Order calldata order
//   ) external;
// }

pragma experimental ABIEncoderV2;
interface IParaSwap {
  struct OptimalRate {
    uint rate;
    RateDistribution distribution;
  }

  struct RateDistribution {
    uint Uniswap;
    uint Bancor;
    uint Kyber;
    uint Oasis;
  }

  function getBestPrice(address fromToken, address toToken, uint srcAmount) external view returns (OptimalRate memory optimalRate);
  
  function getBestPriceSimple(address fromToken, address toToken, uint srcAmount) external view returns (uint256);

    function swap(IERC20 fromToken, IERC20 toToken, uint256 fromAmount, uint256 toAmount, address exchange, bytes calldata payload) 
    external payable 
    returns (uint256);
}

// interface IPoolSwapPair {
//     event Approval(address indexed owner, address indexed spender, uint value);
//     event Transfer(address indexed from, address indexed to, uint value);

//     function name() external pure returns (string memory);
//     function symbol() external pure returns (string memory);
//     function decimals() external pure returns (uint8);
//     function totalSupply() external view returns (uint);
//     function balanceOf(address owner) external view returns (uint);
//     function allowance(address owner, address spender) external view returns (uint);

//     function approve(address spender, uint value) external returns (bool);
//     function transfer(address to, uint value) external returns (bool);
//     function transferFrom(address from, address to, uint value) external returns (bool);

//     function DOMAIN_SEPARATOR() external view returns (bytes32);
//     function PERMIT_TYPEHASH() external pure returns (bytes32);
//     function nonces(address owner) external view returns (uint);

//     function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

//     event Mint(address indexed sender, uint amount0, uint amount1);
//     event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
//     event Swap(
//         address indexed sender,
//         uint amount0In,
//         uint amount1In,
//         uint amount0Out,
//         uint amount1Out,
//         address indexed to
//     );
//     event Sync(uint112 reserve0, uint112 reserve1);

//     function MINIMUM_LIQUIDITY() external pure returns (uint);
//     function factory() external view returns (address);
//     function token0() external view returns (address);
//     function token1() external view returns (address);
//     function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
//     function price0CumulativeLast() external view returns (uint);
//     function price1CumulativeLast() external view returns (uint);
//     function kLast() external view returns (uint);

//     function mint(address to) external returns (uint liquidity);
//     function burn(address to) external returns (uint amount0, uint amount1);
//     function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
//     function skim(address to) external;
//     function sync() external;

//     function initialize(address, address) external;
// }

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

interface ICurveRegistry {
    function get_pool_info(address pool)
    external view
    returns(
        uint256[8] memory balances,
        uint256[8] memory underlying_balances,
        uint256[8] memory decimals,
        uint256[8] memory underlying_decimals,
        address lp_token,
        uint256 A,
        uint256 fee
    );

    function find_pool_for_coins(address _from, address _to, uint256 i)
    external view
    returns (address);

    // def find_pool_for_coins(_from: address, _to: address, i: uint256 = 0) -> address:

    function get_exchange_amount(
        address pool, address _from, address _to, uint256 _amount
    ) 
    external payable 
    returns (uint256);

    // def get_exchange_amount(
    //     _pool: address,
    //     _from: address,
    //     _to: address,
    //     _amount: uint256
    // ) -> uint256:

    function exchange(
        address pool, address _from, address _to, uint256 _amount, uint256 _expected
    ) 
    external payable 
    returns (bool);
}

interface IReimbursement {
    function getLicenseeFee(address licenseeVault, address projectContract) external view returns(uint256); // return fee percentage with 2 decimals
    function getVaultOwner(address vault) external view returns(address);
    // returns address of fee receiver or address(0) if licensee can't receive the fee (fee should be returns to user)
    function requestReimbursement(address user, uint256 feeAmount, address licenseeVault) external returns(address);
}

// interface ICurveCalculator {
//     function get_dy(
//         int128 nCoins,
//         uint256[8] calldata balances,
//         uint256 amp,
//         uint256 fee,
//         uint256[8] calldata rates,
//         uint256[8] calldata precisions,
//         bool underlying,
//         int128 i,
//         int128 j,
//         uint256[100] calldata dx
//     ) external view returns(uint256[100] memory dy);
// }


abstract contract Router {
     using DisableFlags for uint256;
     
    uint256 public constant FLAG_UNISWAP = 0x01;
    uint256 public constant FLAG_SUSHI = 0x02;
    uint256 public constant FLAG_1INCH = 0x04;
    uint256 public constant FLAG_Paraswap = 0x08;
    uint256 public constant FLAG_Curve = 0x10;
    // uint256 public constant FLAG_0x = 0x20;


    
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
    // I0xToken xToken;
    // IAirSwap AirSwap;
    IParaSwap ParaSwap;
    IUni public uniV2Router;            // uniswap compatible router where we have to feed company token pair
    // ICurve curveCompound;
    // ICurveCalculator constant internal curveCalculator = ICurveCalculator(0xc1DB00a8E5Ef7bfa476395cdbcc98235477cDE4E);

    ICurveRegistry constant internal curveRegistry = ICurveRegistry(0x7002B727Ef8F5571Cb5F9D70D13DBEEb4dFAe9d1);
    
    address constant ETH = address(0);

     // add these variables into contract and initialize it in constructor.
    // also, create setter functions for it with onlyOwner restriction.




    constructor(address _Uni, address _sushi, address _oneSplit,/* address _xToken, address _airSwap,*/ address _paraSwap) public payable {
        // owner = payable(msg.sender);
        OneSplit = I1inch(_oneSplit);
        Uni = IUni(_Uni);
        Sushi = IUni(_sushi);
        // xToken = I0xToken(_xToken);
        // AirSwap = IAirSwap(_airSwap);
        ParaSwap = IParaSwap(_paraSwap);
        // curveCompound = ICurve(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
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

        uniAmounts[path.length-1] = uint256(0);
        
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
        
        return (uniAmounts[path.length-1],distribution);
        

    }
    
    function calculateSushiReturn( uint256 amountIn, address[] memory path, OrderType orderType,uint256 /*disableFlags*/) public view returns(uint256, uint256[] memory) {
        uint256[] memory sushiAmounts =new uint[](path.length);
        uint256[] memory distribution;

        sushiAmounts[path.length-1] = uint256(0);
        
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
        
        return (sushiAmounts[path.length-1],distribution);

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

    // function calculateAirSwapReturn( uint256 amountIn, address[] memory path, OrderType orderType,uint256 /*disableFlags*/) public view returns(uint256,uint256[] memory) {
    //     uint256 returnAmount;
    //     uint256[] memory distribution;

    //     if(orderType == OrderType.EthForTokens){
    //         path[0] = ETH;
    //         try AirSwap.getMaxQuote(path[0], path[path.length-1]) returns(uint256 _senderAmount, uint256 _signerAmount){
    //             returnAmount = _senderAmount;
    //         }catch{}
    //     } else if(orderType == OrderType.TokensForEth){
    //         path[path.length-1] = ETH;
    //         try AirSwap.getMaxQuote(path[0], path[path.length-1]) returns(uint256 _senderAmount, uint256 _signerAmount){
    //             returnAmount = _senderAmount;
    //         }catch{}
    //     } else{
    //         try AirSwap.getMaxQuote(path[0], path[path.length-1]) returns(uint256 _senderAmount, uint256 _signerAmount){
    //             returnAmount = _senderAmount;
    //         }catch{}  
    //     }
        
    //     return (returnAmount,distribution);

    // }

    function calculateParaSwapReturn( uint256 amountIn, address[] memory path, OrderType orderType,uint256 /*disableFlags*/) public view returns(uint256,uint256[] memory) {
        uint256 returnAmount;
        uint256[] memory distribution;

        if(orderType == OrderType.EthForTokens){
            path[0] = ETH;
            try ParaSwap.getBestPriceSimple(path[0], path[path.length-1], amountIn) returns(uint256 _amount){
                returnAmount = _amount;
            }catch{}
        } else if(orderType == OrderType.TokensForEth){
            path[path.length-1] = ETH;
            try ParaSwap.getBestPriceSimple(path[0], path[path.length-1], amountIn) returns(uint256 _amount){
                returnAmount = _amount;
            }catch{}
        } else{
            try ParaSwap.getBestPriceSimple(path[0], path[path.length-1], amountIn) returns(uint256 _amount){
                returnAmount = _amount;
            }catch{}  
        }
        
        return (returnAmount,distribution);
    }
    
    // function calculate0xTokenReturn( uint256 amountIn, address[] memory path, OrderType orderType,uint256 /*disableFlags*/) public view returns(uint256,uint256[] memory) {
    //     uint256 returnAmount;
    //     uint256[] memory distribution;

    //     if(orderType == OrderType.EthForTokens){
    //         path[0] = ETH;
    //         try xToken.getSellQuote(path[0], path[path.length-1], amountIn) returns(uint256 _amount){
    //             returnAmount = _amount;
    //         }catch{}
            
           
    //     } else if(orderType == OrderType.TokensForEth){
    //         path[path.length-1] = ETH;
    //         try xToken.getSellQuote(path[0], path[path.length-1], amountIn) returns(uint256 _amount){
    //             returnAmount = _amount;
    //         }catch{}
            
    //     } else{
    //         try xToken.getSellQuote(path[0], path[path.length-1], amountIn) returns(uint256 _amount){
    //             returnAmount = _amount;
    //         }catch{}
            
    //     }
        
    //     return (returnAmount,distribution);
    // }

    // function calculateCurveReturn( uint256 amountIn, address[] memory path, OrderType orderType,uint256 /*disableFlags*/) public view returns(uint256,uint256[] memory) {
    //     uint256 returnAmount;
    //     uint256[] memory distribution;
    //     address curveRegistryPool;

    //     if(orderType == OrderType.EthForTokens){
    //         path[0] = ETH;
    //         curveRegistryPool = curveRegistry.find_pool_for_coins(path[0], path[path.length-1], 0);
    //         returnAmount = curveRegistry.get_exchange_amount(curveRegistryPool, path[0], path[path.length-1], amountIn);
           
    //     } else if(orderType == OrderType.TokensForEth){
    //         path[path.length-1] = ETH;
    //         curveRegistryPool = curveRegistry.find_pool_for_coins(path[0], path[path.length-1], 0);
    //         returnAmount = curveRegistry.get_exchange_amount(curveRegistryPool, path[0], path[path.length-1], amountIn);
            
    //     } else{
    //         curveRegistryPool = curveRegistry.find_pool_for_coins(path[0], path[path.length-1], 0);
    //         returnAmount = curveRegistry.get_exchange_amount(curveRegistryPool, path[0], path[path.length-1], amountIn);
    //     }
        
    //     return (returnAmount,distribution);

    // }
    
    function _calculateNoReturn( uint256/* amountIn*/, address[] memory /*path*/, OrderType /*orderType*/,uint256 /*disableFlags*/) internal pure returns(uint256, uint256[] memory) {
        uint256[] memory distribution;
        return (uint256(0), distribution);
    }
    
    // returns : 
    // dexId ->  which dex gives highest amountOut 0-> 1inch 1-> uniswap 2-> sushiswap 3-> 0x  4-> paraswap  5-> curve
    // minAmountExpected ->  how much tokens you will get after swap
    // distribution -> the route of swappping
    function getBestQuote(address[] memory path, uint256 amountIn, OrderType orderType, uint256 disableFlags) public view returns (uint, uint256,uint256[] memory) {
        
        function(uint256, address[] memory, OrderType ,uint256 ) view returns(uint256,uint256[]memory)[5] memory reserves = [
            disableFlags.disabled(FLAG_1INCH)   ? _calculateNoReturn : _calculateNoReturn,
            disableFlags.disabled(FLAG_UNISWAP) ? _calculateNoReturn : calculateUniswapReturn,
            disableFlags.disabled(FLAG_SUSHI)   ? _calculateNoReturn : calculateSushiReturn,
	    disableFlags.disabled(FLAG_Paraswap)   ? _calculateNoReturn : _calculateNoReturn,
	    disableFlags.disabled(FLAG_Curve)   ? _calculateNoReturn : _calculateNoReturn		
        ];
        
        uint256[5] memory rates;
        uint256[][5] memory distribution;
        
        for (uint i = 0; i < rates.length; i++) {
            (rates[i],distribution[i]) = reserves[i](amountIn,path,orderType,disableFlags);
        }
        
        uint temp = 0;
        for(uint i = 1; i < rates.length; i++) {
            if(rates[i] > rates[temp]) {
                temp = i;
            }
        }
        return(temp, rates[temp], distribution[temp]);   
    
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
    address _Uni = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //mainnet network address for uniswap
    address _sushi = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // Mainnet network address for sushiswap
    address USDT = address(0x47A530f3Fa882502344DC491549cA9c058dbC7Da); // USDT Token Address
    // https://0x.org/docs/guides/0x-cheat-sheet#ropsten-3 (SOURCE)
    // address _xToken = address(0xFb2DD2A1366dE37f7241C83d47DA58fd503E2C64); // ropsten network address for 0x Token Address
    address _paraSwap = address(0x9509665d015Bfe3C77AA5ad6Ca20C8Afa1d98989); // https://etherscan.io/address/0x9509665d015bfe3c77aa5ad6ca20c8afa1d98989#code
    address system;
    address gatewayVault;
    uint256 proccessingFee = 0 ;

    // https://etherscan.io/address/0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5#code
    // address curveRegistryPool = address(0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5);


    IReimbursement public reimbursementContract;      // reimbursement contract address

    address public companyToken;        // company reimbursement token (BSWAP, DEGEN, SMART)
    address public companyVault;    // the vault address of our company registered in reimbursement contract

    ISwapFactory swapFactory;
    // IPoolSwapPair poolContract;
   
   modifier onlySystem() {
        require(msg.sender == system || owner() == msg.sender,"Caller is not the system");
        _;
    }
    
    
    constructor(address _companyToken,address _swapFactory, address _system, address _gatewayVault, address _companyVault, address _reimbursementContract) 
    Router( _Uni, _sushi, _oneSplit, _paraSwap) public {
        companyToken = _companyToken;
        companyVault = _companyVault;
        reimbursementContract = IReimbursement(_reimbursementContract);
        //  poolContract = IPoolSwapPair(_degEthPool);
         swapFactory = ISwapFactory(_swapFactory);
         system = _system;
         gatewayVault = _gatewayVault;
    }
    
    
    // function degenPrice() public view returns (uint256){
    //     (uint112 reserve0, uint112 reserve1,) = poolContract.getReserves();
    //     if(poolContract.token0() == Uni.WETH()){
    //         return ((reserve1 * (10**18)) /(reserve0));
    //     } else {
    //         return ((reserve0 * (10**18)) /(reserve1));
    //     }
    // }

    function setCompanyToken(address _companyToken) external onlyOwner {
        companyToken = _companyToken;
    }

    function setCompanyVault(address _comapnyVault) external onlyOwner returns(bool){
        companyVault = _comapnyVault;
        return true;
    }

    function setReimbursementContract(address _reimbursementContarct) external onlyOwner returns(bool){
        reimbursementContract = IReimbursement(_reimbursementContarct);
        return true;
    }


    function setProccessingFee(uint256 _processingFees ) external onlySystem {
        proccessingFee = _processingFees;
    }


    function setSwapFactory(address _swapFactory) external onlyOwner {
        swapFactory = ISwapFactory(_swapFactory);

    }
    
    function setGatewayVault(address _gatewayVault) external onlyOwner returns(bool) {
        gatewayVault = _gatewayVault;
    }
    
    function setSystem (address _system) external onlyOwner returns(bool) {
        system = _system;
    }

    // Call function processFee() at the end of main function for correct gas usage calculation.
    // txGas - is gasleft() on start of calling contract. Put `uint256 txGas = gasleft();` as a first command in function
    // feeAmount - fee amount that user paid
    // licenseeVault - address that licensee received on registration and should provide when users comes from their site
    // user - address of user who has to get reimbursement (usually msg.sender)

    function processFee(uint256 txGas, uint256 feeAmount, address licenseeVault, address user) internal {
        if (address(reimbursementContract) == address(0)) {
            payable(user).transfer(feeAmount); // return fee to sender if no reimbursement contract
            return;
        }

        uint256 licenseeFeeRate = reimbursementContract.getLicenseeFee(licenseeVault, address(this));
        uint256 companyFeeRate = reimbursementContract.getLicenseeFee(companyVault, address(this));
        uint256 licenseeFeeAmount = (feeAmount * licenseeFeeRate)/(licenseeFeeRate + companyFeeRate);
        if (licenseeFeeAmount != 0) {
            address licenseeFeeTo = reimbursementContract.requestReimbursement(user, licenseeFeeAmount, licenseeVault);
            if (licenseeFeeTo == address(0)) {
                payable(user).transfer(licenseeFeeAmount);    // refund to user
            } else {
                payable(licenseeFeeTo).transfer(licenseeFeeAmount);  // transfer to fee receiver
            }
        }
        feeAmount -= licenseeFeeAmount; // company's part of fee

        // swap half fee to company token
        address[] memory path = new address[](2);
        path[0] = Uni.WETH();
        path[1] = companyToken;
        
        uint[] memory amounts = uniV2Router.swapExactETHForTokens{value: feeAmount/2}(
            0,
            path,
            address(this),
            block.timestamp
        );
        // use tokens and rest of fee to addLiquidity
        IERC20(path[1]).approve(address(Uni),amounts[1]);

        uniV2Router.addLiquidityETH{value: feeAmount/2}(
            path[1],
            amounts[1],
            0,
            0,
            reimbursementContract.getVaultOwner(companyVault),  // company address will receive LP
            block.timestamp
        );

        txGas -= gasleft(); // get gas amount that was spent on Licensee fee
        txGas = txGas * tx.gasprice;
        // request reimbursement for user
        reimbursementContract.requestReimbursement(user, feeAmount+txGas, companyVault);
    }
    
    // added slippage and deadline
    function executeSwap(OrderType orderType, address[] memory path, uint256 assetInOffered, uint256 fees, uint256 minExpectedAmount, address licenseeVault) public payable  {
        uint256 receivedFees = 0;
        uint256 gasA = gasleft();
        if(orderType == OrderType.EthForTokens){
            require(msg.value >= assetInOffered.add(fees), "Payment = assetInOffered + fees");
            receivedFees = receivedFees + msg.value - assetInOffered;
        } else {
            require(msg.value >= fees, "fees not received");
            receivedFees = receivedFees + msg.value;
            TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), assetInOffered);
        }
        
        _swap(orderType,path,assetInOffered,minExpectedAmount,msg.sender,msg.sender);
   
        // processFee(gasA, receivedFees, licenseeVault, msg.sender);
        
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
                 path[0] = Sushi.WETH();
                 swapResult = Sushi.swapExactETHForTokens{value:assetInOffered}(minAmountExpected, path, to, block.timestamp);
            }
            else if (orderType == OrderType.TokensForEth) {
                path[path.length-1] = Sushi.WETH();
                TransferHelper.safeApprove(path[0], address(_sushi), assetInOffered);
                swapResult = Sushi.swapExactTokensForETH(assetInOffered, minAmountExpected, path, to, block.timestamp);
            }
            else if (orderType == OrderType.TokensForTokens) {
                TransferHelper.safeApprove(path[0], address(_sushi), assetInOffered);
                swapResult = Sushi.swapExactTokensForTokens(assetInOffered, minAmountExpected, path, to, block.timestamp);
            }
        }

        // // dex id 3 is for 0xToken
        // else if(dexId == 3){
        //     uint[] memory swapResult;
        //     if(orderType == OrderType.EthForTokens) {
        //          path[0] = ETH;
        //          xToken.sellEthForToken{value:assetInOffered}(path[path.length-1], to, minAmountExpected, '');
        //     }
        //     else if (orderType == OrderType.TokensForEth) {
        //         path[path.length-1] = ETH;
        //         TransferHelper.safeApprove(path[0], address(_xToken), assetInOffered);
        //         xToken.sellTokenForEth(path[0], payable(to), minAmountExpected, '');
        //     }
        //     else if (orderType == OrderType.TokensForTokens) {
        //         TransferHelper.safeApprove(path[0], address(_xToken), assetInOffered);
        //         xToken.sellTokenForToken(path[0], path[path.length-1], to, minAmountExpected, '');
        //     }
        // }

        // dex id 3 is for paraswap
        // else if(dexId == 3){
        //     if(orderType == OrderType.EthForTokens) {
        //          path[0] = ETH;
        //     }
        //     else if (orderType == OrderType.TokensForEth) {
        //         path[path.length-1] = ETH;
        //     }

        //     if (path[0] == ETH) {
        //         try ParaSwap.swap{value: assetInOffered}(IERC20(ETH), IERC20(path[path.length-1]), assetInOffered, minExpectedAmount, address(_paraSwap), '')
        //         returns (uint256 amountOut){
        //             TransferHelper.safeTransfer(path[path.length-1], to, amountOut);
        //         } catch {
        //             emit Error(msg.sender);
        //             revert("Error");
        //         }
        //     } else {
        //         try ParaSwap.swap(IERC20(path[0]), IERC20(path[path.length-1]), assetInOffered, minExpectedAmount, address(_paraSwap), '')
        //         returns (uint256 amountOut){
        //             if(path[path.length-1] == ETH){
        //                 payable(to).transfer(amountOut);
        //             } else {
        //                 TransferHelper.safeTransfer(path[path.length-1], to, amountOut);
        //             }
        //         } catch {
        //             emit Error(msg.sender);
        //             revert("Error");
        //         }
        //     }
        // }

        // dex id 4 is for Curve
        // else if(dexId == 4){
        //     address curveRegistryPool;
        //     uint256 returnAmount;
        //     if(orderType == OrderType.EthForTokens) {
        //         path[0] = ETH;
        //         curveRegistryPool = curveRegistry.find_pool_for_coins(path[0], path[path.length-1], 0);
        //         returnAmount = curveRegistry.get_exchange_amount(curveRegistryPool, path[0], path[path.length-1], assetInOffered);
        //         curveRegistry.exchange{value: assetInOffered}(curveRegistryPool, path[0], path[path.length-1], assetInOffered, minExpectedAmount);
        //         TransferHelper.safeTransfer(path[path.length-1],to,returnAmount);
        //     }
        //     else if (orderType == OrderType.TokensForEth) {
        //         path[path.length-1] = ETH;
        //         curveRegistryPool = curveRegistry.find_pool_for_coins(path[0], path[path.length-1], 0);
        //         returnAmount = curveRegistry.get_exchange_amount(curveRegistryPool, path[0], path[path.length-1], assetInOffered);
        //         TransferHelper.safeApprove(path[0], address(curveRegistry), assetInOffered);
        //         curveRegistry.exchange(curveRegistryPool, path[0], path[path.length-1], assetInOffered, minExpectedAmount);
        //         payable(to).transfer(returnAmount);

        //     }
        //     else if (orderType == OrderType.TokensForTokens) {
        //         curveRegistryPool = curveRegistry.find_pool_for_coins(path[0], path[path.length-1], 0);
        //         TransferHelper.safeApprove(path[0], address(curveRegistry), assetInOffered);
        //         returnAmount = curveRegistry.get_exchange_amount(curveRegistryPool, path[0], path[path.length-1], assetInOffered);
        //         curveRegistry.exchange(curveRegistryPool, path[0], path[path.length-1], assetInOffered, minExpectedAmount);
        //         TransferHelper.safeTransfer(path[path.length-1],to,returnAmount);

        //     }

        //     // if (path[0] == ETH) {
        //     //     TransferHelper.safeApprove(path[0], address(this), assetInOffered);
        //     //     curveRegistry.exchange(curveRegistryPool, ETH, path[path.length-1], assetInOffered, minExpectedAmount);
        //     //     try curveRegistry.get_exchange_amount{value: assetInOffered}(curveRegistryPool, ETH, path[path.length-1], assetInOffered)
        //     //     returns (uint256 amountOut){
        //     //         TransferHelper.safeTransferFrom(path[path.length-1], address(this), msg.sender, amountOut);
        //     //     } catch {
        //     //         emit Error(msg.sender);
        //     //         revert("Error");
        //     //     }
        //     // } else {
        //     //     try curveRegistry.get_exchange_amount(curveRegistryPool, path[0], path[path.length-1], assetInOffered)
        //     //     returns (uint256 amountOut){
        //     //         if(path[path.length-1] == ETH){
        //     //             msg.sender.transfer(amountOut);
        //     //         } else {
        //     //             TransferHelper.safeTransferFrom(path[path.length-1], address(this), msg.sender, amountOut);
        //     //         }
        //     //     } catch {
        //     //         emit Error(msg.sender);
        //     //         revert("Error");
        //     //     }
        //     // }
        // }
        
        return minAmountExpected;
    }
    

    function executeCrossExchange(address[] memory path, OrderType orderType,uint8 crossOrderType, uint256 assetInOffered, uint256 fees,  uint256 minExpectedAmount, address licenseeVault) external payable {
        uint256 receivedFees = 0;
        uint256 gasA = gasleft();

        if(orderType == OrderType.EthForTokens){
            require(msg.value >= assetInOffered.add(fees).add(proccessingFee), "Payment = assetInOffered + fees + proccessingFee");
            receivedFees = receivedFees + msg.value - assetInOffered;
        } else {
            require(msg.value >= fees.add(proccessingFee), "fees not received");
            receivedFees = receivedFees + msg.value;
            TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), assetInOffered);
        }
        
        if(path[0] == USDT) {
            IERC20(USDT).approve(address(swapFactory),assetInOffered);
            swapFactory.swap(USDT,path[path.length-1],assetInOffered,msg.sender,crossOrderType);
        }
        else {
            address tokenB = path[path.length-1];
            path[path.length-1] = USDT;

            uint256 minAmountExpected = _swap(orderType,path,assetInOffered,minExpectedAmount,msg.sender,address(this));
                
            IERC20(USDT).approve(address(swapFactory),minAmountExpected);
            swapFactory.swap(USDT,tokenB,minAmountExpected,msg.sender,crossOrderType);
        }        

        processFee(gasA, receivedFees, licenseeVault, msg.sender);

    }


    function callbackCrossExchange( OrderType orderType, address[] memory path, uint256 assetInOffered, address user) external returns(bool) {
        require(msg.sender == address(swapFactory) , "Degen : caller is not SwapFactory");
        _swap(orderType,path,assetInOffered,uint256(0),user,user);
        
        return true;
    }



}