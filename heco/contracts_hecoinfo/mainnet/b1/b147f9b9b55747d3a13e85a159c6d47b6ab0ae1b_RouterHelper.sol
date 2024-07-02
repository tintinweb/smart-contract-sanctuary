/**
 *Submitted for verification at hecoinfo.com on 2022-05-27
*/

/**
 *Submitted for verification at hecoinfo.com on 2022-05-26
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "e0");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "e1");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "e3");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ow1");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ow2");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "e4");
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "e5");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "e6");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "e7");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "e8");
        uint256 c = a / b;
        return c;
    }
}

interface fatory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function factory() external view returns (address);
}


interface router {
    function factory() external pure returns (address);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

contract RouterHelper is Ownable {
    using SafeMath for uint256;
    struct pathItem {
        address[] path3;
    }

    struct pairItem {
        address pair;
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        string symbol0;
        string symbol1;
        uint256 decimals0;
        uint256 decimals1;
    }

    struct pairItem2 {
        address pair;
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 decimals0;
        uint256 decimals1;
        uint256 decimals;
        uint256 totalSupply;
        uint256 balance;
    }

    struct tokenInfoItem {
        IERC20 token;
        string name;
        string symbol;
        uint256 decimals;
        uint256 balance;
    }

    struct massGetPathNewItem {
        fatory Fatory;
        pairItem[] pairItemList;
    }

    struct massGetPairItem {
        address pair_;
        tokenInfoItem[] tokenInfoList;
        pairItem2[] PairInfo;
    }
    
   function max(uint256[] memory numList) public pure returns(uint256 maxAmout,uint256 maxIndex) {
        uint256 len = numList.length;
        for (uint256 i=0;i<len;i++) {
            uint256 num = 0;
            for (uint256 j=0;j<len;j++) {
                if (numList[i]>=numList[j]) {
                    num = num+1;
                }
            }
            if (len == num) {
                maxAmout = numList[i];
                maxIndex = i;
               break;
            }
        }
   }
   
   function min(uint256[] memory numList) public pure returns(uint256 minAmout,uint256 minIndex) {
        uint256 len = numList.length;
        for (uint256 i=0;i<len;i++) {
            uint256 num = 0;
            for (uint256 j=0;j<len;j++) {
                if (numList[i]<=numList[j]) {
                    num = num+1;
                }
            }
            if (len == num) {
                minAmout = numList[i];
                minIndex = i;
                break;
            }
        }
   }
   
    
    
    function getout(router[] memory _routerList,address fromToken,address toToken,uint256 fromAmount) public view returns(router _router,address _pair,uint256 toAmount) {
        uint256[] memory outList = new uint256[](_routerList.length);
        address[] memory pairList = new address[](_routerList.length);
        uint256 out;
        for (uint256 i=0;i<_routerList.length;i++) {
            //router x = ;
            address Fatory = _routerList[i].factory();
            address pair_ = fatory(Fatory).getPair(fromToken,toToken);
             if (pair_ != address(0)) {
                 (uint256 reserve0, uint256 reserve1,) = pair(pair_).getReserves();
                 address token0 = pair(pair_).token0();
                 if (fromToken == token0) {
                      out = _routerList[i].getAmountOut(fromAmount,reserve0,reserve1);
                 } else {
                      out = _routerList[i].getAmountOut(fromAmount,reserve1,reserve0);
                 }
             } else {
                  out = 0;
             }
            outList[i] = out;
            pairList[i] = pair_;
            (,uint256 maxIndex) = max(outList);
            _router = _routerList[maxIndex];
            _pair = pairList[maxIndex];
            toAmount = outList[maxIndex];
        }
    }
    
    
    function massgetout(router[] memory _routerList,address[] memory tokenList,uint256 fromAmount) external view returns(router[] memory routerList_,address[] memory _pairList,uint256 toAmount_) {
      routerList_ = new router[](tokenList.length-1);
      _pairList = new address[](tokenList.length-1);
      for (uint256 i=0;i<tokenList.length-1;i++) {
          address fromToken = tokenList[i];
          address toToken = tokenList[i+1];
          (router _router,address _pair,  uint256 toAmount) = getout(_routerList,fromToken,toToken,fromAmount);
          routerList_[i] = _router;
          _pairList[i] = _pair;
          fromAmount = toAmount;
          toAmount_ = toAmount;
      }
    }
    
    
    

    function getPairInfo(fatory Fatory, address tokenA, address tokenB, address _account) public view returns (address pair_, tokenInfoItem[] memory tokenInfoList, pairItem2[] memory PairInfo) {
        pair_ = Fatory.getPair(tokenA, tokenB);
        tokenInfoList = new tokenInfoItem[](2);
        PairInfo = new pairItem2[](1);
        if (pair_ != address(0)) {
            (uint256 reserve0, uint256 reserve1,) = pair(pair_).getReserves();
            address token0 = pair(pair_).token0();
            address token1 = pair(pair_).token1();
            tokenInfoList[0] = tokenInfoItem(IERC20(token0), IERC20(token0).name(), IERC20(token0).symbol(), IERC20(token0).decimals(), IERC20(token0).balanceOf(_account));
            tokenInfoList[1] = tokenInfoItem(IERC20(token1), IERC20(token1).name(), IERC20(token1).symbol(), IERC20(token1).decimals(), IERC20(token1).balanceOf(_account));
            PairInfo[0] = pairItem2(pair_, token0, token1, reserve0, reserve1, IERC20(token0).decimals(), IERC20(token1).decimals(), pair(pair_).decimals(), pair(pair_).totalSupply(), pair(pair_).balanceOf(_account));
        }
    }

    function MassGetPairInfo(fatory Fatory, address[] memory addressLsit, address _account) public view returns (massGetPairItem[] memory massGetPairList) {
        uint256 num = addressLsit.length.div(2);
        massGetPairList = new massGetPairItem[](num);
        for (uint256 i = 0; i < num; i++) {
            address tokenA = addressLsit[uint256(2).mul(i)];
            address tokenB = addressLsit[uint256(2).mul(i).add(1)];
            (address pair_,tokenInfoItem[] memory tokenInfoList,pairItem2[] memory PairInfo) = getPairInfo(Fatory, tokenA, tokenB, _account);
            massGetPairList[i] = massGetPairItem(pair_, tokenInfoList, PairInfo);
        }
    }

    function getPathNew(fatory Fatory, address[] memory pathList) public view returns (pairItem[] memory pairItemList) {
        uint256 num = pathList.length.div(2);
        uint256 t;
        for (uint256 i = 0; i < num; i++) {
            address tokenA = pathList[uint256(2).mul(i)];
            address tokenB = pathList[uint256(2).mul(i).add(1)];
            address pair2 = Fatory.getPair(tokenA, tokenB);
            if (pair2 != address(0)) {
                t = t.add(1);
            }
        }
        pairItemList = new pairItem[](t);
        t = 0;
        for (uint256 i = 0; i < num; i++) {
            address tokenA = pathList[uint256(2).mul(i)];
            address tokenB = pathList[uint256(2).mul(i).add(1)];
            address pair2 = Fatory.getPair(tokenA, tokenB);
            if (pair2 != address(0)) {
                (uint256 reserve0, uint256 reserve1,) = pair(pair2).getReserves();
                address token0 = pair(pair2).token0();
                address token1 = pair(pair2).token1();
                pairItemList[t] = pairItem(pair2, token0, token1, reserve0, reserve1, IERC20(token0).symbol(), IERC20(token1).symbol(), IERC20(token0).decimals(), IERC20(token1).decimals());
                t = t.add(1);
            }
        }
    }

    function massGetPathNew(fatory[] memory FatoryList, address[] memory pathList) external view returns (massGetPathNewItem[] memory pairItemList) {
        uint256 num = FatoryList.length;
        pairItemList = new massGetPathNewItem[](num);
        for (uint256 i = 0; i < num; i++) {
            pairItem[] memory pairItemListItem = getPathNew(FatoryList[i], pathList);
            pairItemList[i] = massGetPathNewItem(FatoryList[i], pairItemListItem);
        }
    }

    function massGetTokenBalance(address _address, IERC20[] memory _tokenList) external view returns (tokenInfoItem[] memory tokenInfoList, uint256 balance) {
        balance = _address.balance;
        uint256 num = _tokenList.length;
        tokenInfoList = new tokenInfoItem[](num);
        IERC20 tokenItem;
        for (uint256 i = 0; i < num; i++) {
            tokenItem = _tokenList[i];
            tokenInfoList[i] = tokenInfoItem(tokenItem, tokenItem.name(), tokenItem.symbol(), tokenItem.decimals(), tokenItem.balanceOf(_address));
        }
    }
    
    struct pairReservesItem {
        address pair;
        address factory;
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 decimals0;
        uint256 decimals1;
        uint256 lpDecimals;
        uint256 totalLpSupply;
        string symbol0;
        string symbol1;
        string name0;
        string name1;

    }
    
    function getTokensReserves(address[] memory _pairList) public view returns (pairReservesItem[] memory pairReservesList) {
        pairReservesList = new pairReservesItem[](_pairList.length);
        for (uint256 i = 0; i < _pairList.length; i++)
        {
            address _pair = _pairList[i];
            address token0 = pair(_pair).token0();
            address token1 = pair(_pair).token1();
            (uint256 reserve0, uint256 reserve1,) = pair(_pair).getReserves();
            pairReservesList[i] = pairReservesItem(_pair,pair(_pair).factory(), token0, token1, reserve0, reserve1, IERC20(token0).decimals(), IERC20(token1).decimals(), pair(_pair).decimals(), pair(_pair).totalSupply(), IERC20(token0).symbol(), IERC20(token1).symbol(), IERC20(token0).name(), IERC20(token1).name());
        }
    }

}