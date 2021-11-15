//SPDX-License-Identifier: LICENSED
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Swap.sol";

//Import custom interfaces and libraries
import "./interfaces/IBank.sol";
import "./interfaces/IOrderState.sol";


//Import custom libraries
import "./libraries/StringLibrary.sol";
import "./libraries/BytesLibrary.sol";


contract Exchange is Swap{
    using SafeMath for uint256;
    using StringLibrary for string;
    using BytesLibrary for bytes32;

    struct OrderData{
        address payable buyer;
        address payable seller;
        IERC20 currency;
        uint256 price;
        string salt;
        bytes32 key;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    address public resolveAddress;
    address public adminAddress;
    IOrderState public orderState;

    

    //////////////////////////////////////////////////////////////////////////////////
    constructor(IBank _bank, IOrderState _orderState) public Swap(_bank){
        adminAddress = msg.sender;
        orderState = _orderState;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only admin function");
        _;
    }
    modifier onlyResolver() {
        require(msg.sender == resolveAddress, "Only resolver function");
        _;
    }

    modifier keyCheck(OrderData calldata orderData){
        bytes32 key = keccak256(abi.encode(orderData.buyer,orderData.seller,orderData.currency,orderData.price,orderData.salt));
        require(orderData.key==key,"Key validation failed");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////////
    /////////Sign with buyers signature////////////////////////////////////////////
    function placeOrder(
       address _seller, IERC20 _token, uint256 _price, string memory salt, address[] calldata _routers
    ) public payable returns(bytes32 _key){
        swapToCurrency(_routers,address(_token),_price,address(this));

        _key = _generateKey(_msgSender(), _seller,_token, _price,salt);
        require(orderState.placeOrder(_msgSender(),_seller,_token,_price,_key),"Order not placed");
    }

    /////////Sign with sellers signature///////////////////////////////////////////////
    


    /////////Sign with buyers signature////////////////////////////////////////////
    function markCompleted(
        OrderData calldata orderData
        ) 
            public keyCheck(orderData){
                require(verifyMessage(orderData),"Order is not verified");
                require(orderData.seller==_msgSender()||orderData.buyer==_msgSender(), "Caller is not the seller/buyer");
                require(orderState.setComplete(orderData.key),"Order is not written completed");
                bank.withdraw(orderData.price,orderData.buyer,_msgSender(),false);
    }


    /////////Sign with buyers signature////////////////////////////////////////////
    function resolveConflict(
        OrderData calldata orderData,
        bool canceled
        ) public onlyResolver keyCheck(orderData) {
            if(!canceled){
                bank.withdraw(orderData.price,orderData.buyer,orderData.seller,canceled);
                orderState.setComplete(orderData.key);
            }
            else{
                bank.withdraw(orderData.price,orderData.buyer,orderData.seller,canceled);
                orderState.drop(orderData.key);
            }
    }

    /////////////////////////////////////////////////////////////////////////////
    function setAdminAddress(address admin) public onlyAdmin {
        adminAddress = admin;
    }

    function setResolveAddress(address resolver) public onlyAdmin {
        resolveAddress = resolver;
    }

    /////////////////Signature Function//////////////////

    function _generateKey(address buyer,address seller,IERC20 currency ,uint256 price ,string memory salt )internal pure returns(bytes32 key){
        key = keccak256(abi.encode(buyer,seller,currency,price,salt));
    }

    function generateKey(address buyer,address seller,IERC20 currency ,uint256 price ,string memory salt)external pure returns(bytes32 key){
        key = _generateKey(buyer,seller,currency,price,salt);
    }

    function generateMessage(address buyer,address seller,IERC20 currency ,uint256 price ,string memory salt) external pure returns(string memory _message){
        _message = _generateKey(buyer,seller,currency,price,salt).toString();
    }

    function verifyMessage(OrderData calldata orderData)public pure returns(bool verified){
        bytes32 _message = _generateKey(orderData.buyer,orderData.seller,orderData.currency,orderData.price,orderData.salt);
        address confirmed = _message.toString().recover(orderData.v,orderData.r,orderData.s);
        return (confirmed==orderData.buyer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";


//Import custom interfaces
import "./interfaces/IBank.sol";
import "./interfaces/Router02.sol";
import "./interfaces/IBEP20.sol";

//Import custom libraries
//import "./libraries/StringLibrary.sol";
//import "./libraries/BytesLibrary.sol";
import "./interfaces/TransferHelper.sol";


contract Swap is Ownable {
    using SafeMath for uint256;

    IBank public bank;
    address public WBNB;
    address public currency;
    mapping(address=>bool) public isOld;

    constructor(IBank _bank)public{
        WBNB=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        bank = _bank;
        currency =address(bank.currency());
    } 

    event Swapped(address indexed fromToken, address indexed toToken, uint256 value);

    fallback () external payable {
    }
    receive () external payable {
    }

    function bestTrade(address[] calldata routers,address fromTokenAddress,address toTokenAddress, uint256 amount, bool exactOut)public view returns(uint256[] memory minMax,address bestRouter){
        address[] memory path;
        minMax = new uint256[](2);
        uint256[] memory returnAmounts;
        for(uint i=0;i<routers.length;i++){
            Router01 router = Router01(routers[i]);
            if(fromTokenAddress ==address(0)){
                path = new address[](2);
                path[0] = WBNB;
                path[1] = currency;
            }
            else if(toTokenAddress == address(0)){
                path = new address[](2);
                path[0] = currency;
                path[1] = WBNB;
            }
            else{
                path = new address[](3);
                if(exactOut){
                    path[0] = fromTokenAddress;
                    path[1] = WBNB;
                    path[2] = currency;
                }
                else{
                    path[0] = currency;
                    path[1] = WBNB;
                    path[2] = toTokenAddress;
                }
            }
            
            if(exactOut){
                returnAmounts=router.getAmountsIn(amount,path);
                if(i==0){
                    minMax[1]=returnAmounts[0];
                    minMax[0]=returnAmounts[0];
                    bestRouter = routers[i];
                }
                if(returnAmounts[0]>minMax[1]){
                    minMax[1]=returnAmounts[0];
                }
                if(returnAmounts[0]<minMax[0]){
                    minMax[0]=returnAmounts[0];
                    bestRouter = routers[i];
                }
            }

            else{
                returnAmounts=router.getAmountsOut(amount,path);
                if(i==0){
                    minMax[1]=returnAmounts[path.length - 1];
                    minMax[0]=returnAmounts[path.length - 1];
                    bestRouter = routers[i];
                }
                if(returnAmounts[path.length - 1]>minMax[1]){
                    minMax[1]=returnAmounts[1];
                    bestRouter = routers[i];
                }
                if(returnAmounts[path.length - 1]<minMax[0]){
                    minMax[0]=returnAmounts[1];
                }
            }
            
        }
        
    }


    function swapTokensToCurrency(address[] calldata routers,address tokenAddress,uint256 amountOut,address to) public returns(uint[] memory returnData){
        (uint256[] memory minMax,address bestRouter) = bestTrade(routers,tokenAddress, currency,amountOut,true);

        Router01 router = Router01(bestRouter);
        address[] memory path = new address[](3);
        path[0] = tokenAddress;
        path[1] = WBNB;
        path[2] = currency;
        
        //transfer tokens to the contract
        TransferHelper.safeTransferFrom(tokenAddress,msg.sender,address(this),minMax[1]);
        TransferHelper.safeApprove(tokenAddress,bestRouter,minMax[1]);
        returnData= router.swapTokensForExactTokens(amountOut,minMax[1],path,to,block.timestamp.add(600));
        TransferHelper.safeTransfer(tokenAddress,msg.sender,minMax[1]-returnData[0]);
        emit Swapped(tokenAddress,currency,returnData[0]);
    }

    function swapCurrencyToTokens(address[] calldata routers, address tokenAddress,uint256 amountIn,address to) public returns(uint[] memory returnData){
        (uint256[] memory minMax,address bestRouter) = bestTrade(routers,currency,tokenAddress, amountIn,false);

        Router01 router = Router01(bestRouter);
        address[] memory path = new address[](3);
        path[0] = currency;
        path[1] = WBNB;
        path[2] = tokenAddress;
        
        //transfer tokens to the contract
        TransferHelper.safeTransferFrom(currency,msg.sender,address(this),amountIn);
        TransferHelper.safeApprove(currency,bestRouter,amountIn);
        returnData= router.swapExactTokensForTokens(amountIn,minMax[0],path,to,block.timestamp.add(600));
        emit Swapped(currency,tokenAddress,amountIn);
    }

    function swapBNBToCurrency(address[] calldata routers,uint256 amountOut,address to)public payable returns(uint[] memory returnData){
        (uint256[] memory minMax,address bestRouter) = bestTrade(routers,address(0), currency,amountOut,true);

        Router01 router = Router01(bestRouter);
        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = currency;
        
        //call swapTokensForExactTokens
        if(isOld[bestRouter]){
            returnData= router.swapETHForExactTokens{value:msg.value}(amountOut,path,to,block.timestamp+60);
        }
        else{
            returnData= router.swapBNBForExactTokens{value:msg.value}(amountOut,path,to,block.timestamp+60);
        }
        TransferHelper.safeTransferETH(msg.sender, msg.value - returnData[0]);
        emit Swapped(WBNB,currency,returnData[0]);
    }

     function swapCurrencyToBNB(address[] calldata routers,uint256 amountIn,address to) public returns(uint[] memory returnData){
        (uint256[] memory minMax,address bestRouter) = bestTrade(routers,currency,address(0), amountIn,false);

        Router01 router = Router01(bestRouter);
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = WBNB;
        
         //transfer tokens to the contract
        TransferHelper.safeTransferFrom(currency,msg.sender,address(this),amountIn);
        TransferHelper.safeApprove(currency,bestRouter,amountIn);
        
        
        //call swapTokensForExactTokens
        if(minMax[1]>0){
            if(isOld[bestRouter]){
                returnData= router.swapExactTokensForETH(amountIn,minMax[0],path,to,block.timestamp+60);
            }
            else{
                returnData= router.swapExactTokensForBNB(amountIn,minMax[0],path,to,block.timestamp+60);
            }
        }
        emit Swapped(currency,WBNB,amountIn);
    }
    


    function swapToCurrency(address[] calldata routers,address inputToken,uint256 amountOut,address to) public payable returns(uint[] memory returnData){
        if(inputToken==address(0)){
            returnData = swapBNBToCurrency(routers,amountOut,to);
        }
        else{
            returnData = swapTokensToCurrency(routers,inputToken,amountOut,to);
        }
    }

    function swapFromCurrency(address[] calldata routers,address outputToken, uint256 amountIn,address to) external returns(uint[] memory returnData){
        if(outputToken==address(0)){
            returnData = swapCurrencyToBNB(routers,amountIn,to);
        }
        else{
            returnData = swapCurrencyToTokens(routers,outputToken,amountIn,to);
        }
    }


    function changeCurrency(address newCurrency) public onlyOwner returns(bool){
        currency = newCurrency;
        return true;
    }

    function setRouters(address _router, bool _isOld) public onlyOwner returns(bool){
        isOld[_router] = _isOld;
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IBEP20 is IERC20 {}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./IBEP20.sol";
interface IBank {
    event Deposit(address indexed fundOwner, uint256 value);
    event Withdraw(address toAccount,uint256 value);

    function currency() external view returns (IBEP20);
    function commission() external view returns (uint256);
    function refundable() external view returns (uint256);
    function deposits(address) external view returns (uint256);

    function deposit(address buyer, uint256 amount) external returns(bool);

    function withdraw(
        uint256 amount,
        address buyer,
        address seller,
        bool canceled
    ) external returns (bool);

    //This function will be called on a emergency situation and stored funds will be transfered to a new Bank contract
    function emergencyWithdraw(address newBankContract)
        external
        returns (bool);

    function emergencySwap(address newBankContract)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

interface IOrderState{
    

    event OperatorAdded(address indexed _operator);
    event OperatorRemoved(address indexed _operator);
    event OrderPlaced(bytes32 indexed _key, address indexed _buyer, address indexed _seller);
    event OrderDroped(bytes32 indexed _key);
    event OrderReplaced(bytes32 indexed _prevKey,bytes32 indexed _newKey);
    event OrderCompleted(bytes32 indexed _key);
    
    function addOperator(address _address) external;

    function removeOperator(address _address) external;

    function drop(bytes32 _key) external;

    function placeOrder(
        address _buyer,
        address _seller,
        IERC20 _currency,
        uint256 _price,
        bytes32 _key
        )
        external returns(bool);

    function chnagePrice(
        uint256 _newPrice,
        bytes32 _prevKey,
        bytes32 _newKey
        )
        external;

    function setComplete(bytes32 _key) external returns(bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
interface Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactBNBForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapTokensForExactBNB(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForBNB(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapBNBForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "./Router01.sol";
interface Router02 is Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactBNBForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForBNBSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
library BytesLibrary {
    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(value[i] >> 4)];
            str[1+i*2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "./UintLibrary.sol";

library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory a, string memory b) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bab = new bytes(ba.length + bb.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bab[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bab[k++] = bb[i];
        return string(bab);
    }

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        bytes memory ba = bytes(a);
        bytes memory bb = bytes(b);
        bytes memory bc = bytes(c);
        bytes memory bbb = new bytes(ba.length + bb.length + bc.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) bbb[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) bbb[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) bbb[k++] = bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory ba, bytes memory bb, bytes memory bc, bytes memory bd, bytes memory be, bytes memory bf, bytes memory bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(ba.length + bb.length + bc.length + bd.length + be.length + bf.length + bg.length);
        uint k = 0;
        for (uint i = 0; i < ba.length; i++) resultBytes[k++] = ba[i];
        for (uint i = 0; i < bb.length; i++) resultBytes[k++] = bb[i];
        for (uint i = 0; i < bc.length; i++) resultBytes[k++] = bc[i];
        for (uint i = 0; i < bd.length; i++) resultBytes[k++] = bd[i];
        for (uint i = 0; i < be.length; i++) resultBytes[k++] = be[i];
        for (uint i = 0; i < bf.length; i++) resultBytes[k++] = bf[i];
        for (uint i = 0; i < bg.length; i++) resultBytes[k++] = bg[i];
        return resultBytes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library UintLibrary {
    using SafeMath for uint;

    function toString(uint256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = byte(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    function bp(uint value, uint bpValue) internal pure returns (uint) {
        return value.mul(bpValue).div(10000);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

