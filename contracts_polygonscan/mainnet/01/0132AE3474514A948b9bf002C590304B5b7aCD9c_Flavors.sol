/**
 *Submitted for verification at polygonscan.com on 2021-10-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;











library Address {

    
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    
    function sendValue(address payable recipient,uint256 amount) internal {
        require(address(this).balance >= amount,"Address: insufficient balance");
        (bool success,) = recipient.call{ value: amount}("");
        require(success,"Address: unable to send value");
    }

    
    function functionCall(address target,bytes memory data) internal returns (bytes memory) {
        return functionCall(target,data,"Address: low-level call failed");
    }

    
    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target,data,0,errorMessage);
    }

    
    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target,data,value,"Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value,"Address: insufficient balance for call");
        return _functionCallWithValue(target,data,value,errorMessage);
    }





    function _functionCallWithValue(address target,bytes memory data,uint256 weiValue,string memory errorMessage) private returns (bytes memory) {
        require(isContract(target),"Address: call to non-contract");

        (bool success,bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32,returndata),returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}










library SafeMath {
    
    function tryAdd(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false,0);
            return (true,c);
        }
    }

    
    function trySub(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b > a) return (false,0);
            return (true,a - b);
        }
    }

    
    function tryMul(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (a == 0) return (true,0);
            uint256 c = a * b;
            if (c / a != b) return (false,0);
            return (true,c);
        }
    }

    
    function tryDiv(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a / b);
        }
    }

    
    function tryMod(uint256 a,uint256 b) internal pure returns (bool,uint256) {
        unchecked {
            if (b == 0) return (false,0);
            return (true,a % b);
        }
    }

    
    function add(uint256 a,uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a,uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a,uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a,uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a,uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a,errorMessage);
            return a - b;
        }
    }

    
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0,errorMessage);
            return a % b;
        }
    }
}









abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}











interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient,uint256 amount) external returns (bool);
    function allowance(address _owner,address spender) external view returns (uint256);
    function approve(address spender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);

    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}








interface IFlavorsChainData {
    function chainId() external view returns (uint);
    function tokenName() external view returns (string memory name);
    function tokenSymbol() external view returns (string memory symbol);
    function router() external view returns (address);
    function wrappedNative() external view returns (address);
}












interface IBridge {


    function initialize(address ownableFlavors,address bridgeTroll) external;

    function pauseBridge_OAD() external;
    function unPauseBridge_OAD() external;
    function updateOwnable_OAD(address new_ownableFlavors) external;

    function burnItAllDown_OOF() external;
    function updateIceCreamMan_OOF(address new_iceCreamMan) external;
    function updateOwner_OOF(address new_owner) external;

    function waitToCross(uint32 sourceChainId, uint32 destinationChainId, uint256 tokens) external;
    function sendDepositToCreamery(uint256 value) external;

    function FlavorsToken() external returns (address);
    function Ownable() external returns (address);
    function bridgeTroll() external returns (address);
    function iceCreamMan() external returns (address);
    function owner() external returns (address);
    function bridgePaused() external returns (address);
    function initialized() external returns (address);



}








interface ICreamery {
    function initialize(address ownableFlavors) external;
    function launch() external;

    function updateOwnable(address new_ownableFlavors) external;
    function burnItAllDown_OOF() external;

    function deposit(string memory note) external;

}








interface IDEXFactory {
    function createPair(address tokenA,address tokenB) external returns (address pair);
}








interface IDEXPair {
    event Approval(address indexed owner,address indexed spender,uint value);
    event Transfer(address indexed from,address indexed to,uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner,address spender) external view returns (uint);

    function approve(address spender,uint value) external returns (bool);
    function transfer(address to,uint value) external returns (bool);
    function transferFrom(address from,address to,uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner,address spender,uint value,uint deadline,uint8 v,bytes32 r,bytes32 s) external;

    event Mint(address indexed sender,uint amount0,uint amount1);
    event Burn(address indexed sender,uint amount0,uint amount1,address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0,uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0,uint112 reserve1,uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0,uint amount1);
    function swap(uint amount0Out,uint amount1Out,address to,bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address,address) external;
}









interface IDEXRouter {
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
    ) external returns (uint amountA,uint amountB,uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken,uint amountETH,uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken,uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountA,uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,uint8 v,bytes32 r,bytes32 s
    ) external returns (uint amountToken,uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut,uint amountInMax,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut,address[] calldata path,address to,uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA,uint reserveA,uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn,uint reserveIn,uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut,uint reserveIn,uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn,address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut,address[] calldata path) external view returns (uint[] memory amounts);
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
        bool approveMax,uint8 v,bytes32 r,bytes32 s
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}








interface IFlavorDripper {

    
    function claimDividend() external;
    function deposit() external payable;

    
    function setFlavorDistCriteria_OAD(uint256 _minPeriod,uint256 _minDistribution) external;
    function updateOwnableFlavors_OAD(address new_ownableFlavors) external;

    
    function setShare_OT(address shareholder,uint256 amount) external;
    function process_OT(uint256 gas) external payable;

    
    function updateFlavorsToken_OO(address new_flavorsToken) external;
    function updateFlavor_OO(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract
    ) external;
    function updateRouter_OO(address new_router) external;
    function burnItAllDown_OOF() external;

    
    function initialize_OI(
        address new_flavor,
        bool new_isCustomBuy,
        address new_customBuyerContract,
        address new_ownableFlavors
    ) external;


}











interface IOwnableFlavors {
    function initialize0(
      address flavorsChainData,
      address iceCreamMan,
      address owner,
      address token,
      address bridge,
      address bridgeTroll
    ) external;

    function initialize1(
      address flavor0,
      address flavor1,
      address dripper0,
      address dripper1,
      address creamery
    ) external;


    function updateDripper0_OAD(
        address new_flavor0,
        bool new_isCustomBuy0,
        address new_dripper0,
        address new_customBuyerContract0
    ) external returns(bool);

    function updateDripper1_OA(
        address new_flavor1,
        bool new_isCustomBuy1,
        address new_dripper1,
        address new_customBuyerContract1
    ) external returns(bool);

    function updateDripper1_OAD(address addr) external returns(bool);
    function updateFlavorsToken_OAD(address new_flavorsToken) external;
    function updateBridgeTroll_OAD(address new_bridgeTroll) external returns(bool);
    function updateBridge_OAD(address new_bridge, address new_bridgeTroll) external returns(bool);
    
    function isAuthorized(address addr) external view returns (bool);
    function iceCreamMan() external view returns(address);
    function owner() external view returns(address);
    function flavorsToken() external view returns(address);
    function pair() external view returns(address);
    function updatePair(address pair) external;

    function bridge() external view returns(address);
    function bridgeTroll() external view returns(address);
    function router() external view returns(address);
    function flavor0() external view returns(address);
    function flavor1() external view returns(address);

    function customBuyerContract0() external view returns(address);
    function customBuyerContract1() external view returns(address);

    function dripper0() external view returns(address);
    function dripper1() external view returns(address);
    function ownable() external view returns(address);
    function creamery() external view returns(address);

    function pending_iceCreamMan() external view returns(address);
    function pending_owner() external view returns(address);
    function wrappedNative() external view returns(address);
  
    function burnItAllDown_OI() external;
}





contract Flavors is Context, IERC20{
    using Address for address;
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals = 9;
    uint256 public totalSupply;

    uint256 _maxTx;

    
    uint256 public swapThreshold;

    
    mapping (address => uint256) public _balance;
    mapping (address => mapping (address => uint256))  _allowance;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isDividendExempt;
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balance[account];
    }
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowance[_owner][_spender];
    }
    
    
    uint16 fee_flavor0;
    uint16 fee_flavor1;
    uint16 fee_creamery;
    uint16 fee_icm;
    uint16 fee_total_buy;
    uint16 fee_total_sell;
    uint16 public constant FEE_DENOMINATOR = 10_000;

    uint32 gas_dripper0;
    uint32 gas_dripper1;
    uint32 gas_icm;
    uint32 gas_creamery;
    uint32 gas_withdrawal;

    
  function fees() external view returns (uint16, uint16, uint16, uint16, uint16, uint16, uint16){
    return (fee_flavor0, fee_flavor1, fee_creamery, fee_icm, fee_total_buy, fee_total_sell, FEE_DENOMINATOR);
  }

  function gas() external view returns (uint32, uint32, uint32, uint32, uint32){
      return (gas_dripper0, gas_dripper1, gas_icm, gas_creamery, gas_withdrawal);
  }

    uint256 public launchedAtBlock;
    uint256 public launchedAtTimestamp;

    address public ownable;
    address public wrappedNative;
    address public iceCreamMan;
    address public flavorsChainData;
    
    function router() public view returns(address) { return Ownable.router();}
    function flavor0() public view returns(address) { return Ownable.flavor0();}
    function flavor1() public view returns(address) { return Ownable.flavor1();}
    function dripper0() public view returns(address) { return Ownable.dripper0();}
    function dripper1() public view returns(address) { return Ownable.dripper1();}
    function creamery() public view returns(address) { return Ownable.creamery();}
    function pair() public view returns(address) { return Ownable.pair();}
    function owner() public view returns(address) { return Ownable.owner();}
    function getOwner() public view returns (address){ return Ownable.owner();}
    function bridge() public view returns(address) { return Ownable.bridge();}
    function bridgeTroll() public view returns(address) { return Ownable.bridgeTroll();}
    
    IDEXRouter Router;
    IFlavorDripper Dripper0;
    IFlavorDripper Dripper1;
    ICreamery Creamery;
    IDEXPair Pair;
    IOwnableFlavors Ownable;
    IBridge Bridge;
    IFlavorsChainData FlavorsChainData;

    

    
    function initialize (
        address _dripper0,
        address _dripper1,
        address _creamery,
        address _ownableFlavors,
        address _flavor0,
        address _flavor1,
        address _bridge,
        uint256 initialSupply,
        address _flavorsChainData
    ) public initializer {
        flavorsChainData = _flavorsChainData;
        FlavorsChainData = IFlavorsChainData(flavorsChainData);
        name = FlavorsChainData.tokenName();
        symbol = FlavorsChainData.tokenSymbol();

        gas_dripper0 = 1_000_000;
        gas_dripper1 = 1_000_000;
        gas_icm = 200_000;
        gas_creamery = 200_000;
        gas_withdrawal = 200_000;
       
        iceCreamMan = _msgSender();
        _updateOwnable(_ownableFlavors);
        
        Ownable.initialize0(
            _flavorsChainData,
            iceCreamMan,// iceCreamMan
            iceCreamMan,// owner
            address(this),// flavors token
            _bridge,// bridge
            iceCreamMan
        );
        Ownable.initialize1(
            _flavor0,// flavor0
            _flavor1,// flavor1
            _dripper0,// Dripper0
            _dripper1,// drippper1
            _creamery// Creamery
        );

        wrappedNative = Ownable.wrappedNative();
        

        setTotalSupply(initialSupply.mul(10 ** decimals));
        _maxTx = totalSupply.div(10);
        swapThreshold = totalSupply.div(10_000);

        isFeeExempt[Ownable.bridge()] = true;
        isDividendExempt[Ownable.bridge()] = true;
        isTxLimitExempt[address(this)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0x000000000000000000000000000000000000dEaD)] = true;
        isDividendExempt[address(0x0000000000000000000000000000000000000000)] = true;
        isDividendExempt[address(0x0000000000000000000000000000000000000001)] = true;
        isDividendExempt[address(Ownable)] = true;
        isDividendExempt[address(Bridge)] = true;

        _balance[iceCreamMan] = totalSupply;
        emit Transfer(address(0),iceCreamMan,totalSupply);
        _updateShares(iceCreamMan);
        initialized = true;
    }
    bool presalePrepped = false;

    function prepForPreSale_OI() external onlyIceCreamMan {
        
        fee_flavor0 = 0;
        fee_flavor1 = 0;
        fee_creamery = 0;
        fee_icm = 0;
        fee_total_buy = 0;
        fee_total_sell = 0;
        _maxTx = type(uint256).max;
        presalePrepped = true;
    }
        
    bool presaleFinalized = false;
    function finalizePreSale_OI() external onlyIceCreamMan {
        
        fee_flavor0 = 350;
        fee_flavor1 = 350;
        fee_creamery = 400;
        fee_icm = 100;
        fee_total_buy = 1200;
        fee_total_sell = 3500;
        
        _maxTx = totalSupply.div(20);
        presaleFinalized = true;
        launchedAtBlock = block.number;
        launchedAtTimestamp = block.timestamp;
        Creamery.launch();
    }
    
    function setBalance(address holder,uint256 value) internal returns (bool) { _balance[holder] = value;return true;}

    function addBalance_OB(address holder,uint256 value) external onlyBridge returns(bool) { return _addBalance(holder,value);}
    function _addBalance(address holder,uint256 value) internal returns(bool) {
      uint256 holderBalance = _balance[holder];
      _balance[holder] = holderBalance.add(value);
      delete holderBalance;
      return true;
    }

    function subBalance_OB(address holder,uint256 value) external onlyBridge returns(bool) { return _subBalance(holder,value);}
    function _subBalance(address holder,uint256 value) internal returns(bool) { 
        uint256 holderBalance = _balance[holder];
        _balance[holder] = holderBalance.sub(value);
        delete holderBalance;
        return true;
    }
    
    function setTotalSupply(uint256 value) internal returns (bool) { totalSupply = value;return true;}

    function addTotalSupply_OB(uint256 value) external onlyBridge returns (bool) { return _addTotalSupply(value);}
    function _addTotalSupply(uint256 value) internal returns (bool) {totalSupply = totalSupply.add(value);return true;}
    
    function subTotalSupply_OB(uint256 value) external onlyBridge returns (bool) { return _subTotalSupply(value);}
    function _subTotalSupply(uint256 value) internal returns (bool) { totalSupply = totalSupply.sub(value);return true;}

    bool functionLocked = false;
    modifier lockWhileUsing() { require(functionLocked == false, "FLAVORS: lockWhileUsing => function locked while in use" );
        functionLocked = true;// set the function locked variable        
        _;
        functionLocked = false;
    }
    
    bool public initialized = false;
    modifier initializer() {
        
        _;
        initialized = true;
    }

    
    

    function cream(uint256 tokens) private returns (bool) {
        require(_addTotalSupply(tokens),"FLAVORS: cream => addTotalSupply error");
        require(_addBalance(address(this),tokens),"FLAVORS: cream => addBalance error");return true;
    }
    
    

    
    function getRate() internal returns(uint256) {
        address token0 = Pair.token0();
        address token1 = Pair.token1();
        Pair.sync();
        (uint112 reserve0,uint112 reserve1,uint32 blockTimestamp) = Pair.getReserves();
        emit GetReserves(reserve0,reserve1,blockTimestamp);
        if(address(token0) == address(this) && address(token1) == wrappedNative) {
            emit TokenPrice(uint256(reserve1).div(uint256(reserve0)));
            delete token0;
            delete token1;
            return(uint256(reserve1).div(uint256(reserve0)));
        } else if (address(token1) == address(this) && address(token0) == wrappedNative) {
            emit TokenPrice(uint256(reserve0).div(uint256(reserve1)));
            delete token0;
            delete token1;
            return(uint256(reserve0).div(uint256(reserve1)));
        } else {
            emit TokenPrice(0);
            delete token0;
            delete token1;
            return 0;
        }
    }

    function addLiquidityETH(
        uint256 tokenAmount,
        uint256 pairedTokenAmount
    ) payable public returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    ) {
        (amountToken,amountETH,liquidity) = Router.addLiquidityETH{value: pairedTokenAmount}(
            address(this),//    address token,
            tokenAmount,//       uint amountTokenDesired,
            0,
            0,
            address(this),//    address to,
            block.timestamp//       uint deadline
      );
            emit LiquidityAdded(amountToken,amountETH,liquidity);
            return (amountToken,amountETH,liquidity);
    }



    function creamAndFreeze() public payable {
        uint256 _value = msg.value;
        require (_value > 0, "FLAVORS: creamAndFreeze => value must be greater than zero" );
        uint256 tokens = _value.div(getRate());
        cream(tokens);
        (,,uint256 liquidity) = addLiquidityETH(tokens,_value);
        Pair.approve(address(Pair),liquidity);
        Pair.transfer(address(0),liquidity.div(2));
        Pair.transfer(iceCreamMan,liquidity.mul(fee_icm).div(FEE_DENOMINATOR));
        Pair.transfer(address(Creamery),Pair.balanceOf(address(this)));
        delete tokens;
        delete liquidity;
    }

    function updateShares_OB(address holder) public onlyBridge { _updateShares(holder);}
    function _updateShares(address holder) private {
        if(isDividendExempt[holder]) { try Dripper0.setShare_OT(holder,_balance[holder]) {} catch {} }
        if(isDividendExempt[holder]) { try Dripper1.setShare_OT(holder,_balance[holder]) {} catch {} }
    }

    function approve(address spender, uint value) public returns (bool) { _approve(_msgSender(), spender, value);return true;}
    function _approve(address _owner, address spender, uint value) private {
        _allowance[_owner][spender] = value;
        emit Approval(
            _owner,
            spender,
            value);
        
    }
    function approveMax(address spender) public returns (bool) { return this.approve(spender, type(uint256).max);}
    function addAllowance_OB(address holder,address spender,uint256 amount) public onlyBridge { _addAllowance(holder,spender,amount);}
    function _addAllowance(address holder,address spender,uint256 amount) private { _allowance[holder][spender] = _allowance[holder][spender].add(amount);emit Approval(holder,spender,amount);}
    function _subAllowance(address holder,address spender,uint256 amount) private { _allowance[holder][spender] = _allowance[holder][spender].sub(amount, "FLAVORS: transferFrom => Insufficient Allowance" );}
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowance[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowance[_msgSender()][spender].sub(subtractedValue,
        "FLAVORS: Cannot Decrease Allowance Below Zero"));
        return true;
    }



    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowance[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance.sub(amount));
        return true;
    }



    







        
    function _transfer(address from, address to, uint256 amount) private {      
        require(from != address(0), "FLAVORS: _transfer => No Transfer From 0x0");
        require(to != address(0), "FLAVORS: _transfer => No Transfer To 0x0");
        require(amount > 0, "FLAVORS: _transfer => Transfer Amount 0");
        require(amount <= _maxTx || isTxLimitExempt[from], "FLAVORS: _transfer => Exceeds _maxTx" );
        bool _takeFee = true;
        if(isFeeExempt[from]) {
            _takeFee = false;
        }
        _tokenTransfer(from,to,amount,_takeFee);
    }
    

    
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool _takeFee) private {
        require(_subBalance(sender, amount), "FLAVORS: _transfer => Insufficient Balance" );
        _updateShares(sender);
            if(_takeFee){
                uint256 feeAmount;
                feeAmount = (amount.mul((recipient == address(Pair)) ? fee_total_sell : fee_total_buy)).div(FEE_DENOMINATOR);
                _addBalance(recipient, amount.sub(feeAmount));
                _updateShares(recipient);
                emit Transfer(sender, recipient, amount.sub(feeAmount));
                _addBalance(address(this), feeAmount);
                emit Transfer(sender, address(this), feeAmount);
                delete feeAmount;
            } else {
                _addBalance(recipient, amount);
                emit Transfer(sender, recipient, amount);
            }
            if(_balance[address(this)] >= swapThreshold) { _swapAndSend();}
            try Dripper0.process_OT{gas: gas_dripper0}(gas_dripper0) {} catch {}
            try Dripper1.process_OT{gas: gas_dripper1}(gas_dripper1) {} catch {}
    }

    function swapAndSend_OA() external onlyAuthorized { _swapAndSend();}

    function _swapAndSend() private {
        require(swapExactTokensForETHSupportingFeeOnTransferTokens(), "FLAVORS: swapAndSend => fail" );
        uint256 toDrip0 = (((address(this)).balance).mul(fee_flavor0)).div(fee_total_buy);
        uint256 toDrip1 = (((address(this)).balance).mul(fee_flavor1)).div(fee_total_buy);
        uint256 toICM = (((address(this)).balance).mul(fee_icm)).div(fee_total_buy);

        Address.sendValue(payable(address(Dripper0)),toDrip0);
        Address.sendValue(payable(address(Dripper1)),toDrip1);
        Address.sendValue(payable(iceCreamMan),toICM);
        Address.sendValue(payable(address(Creamery)),address(this).balance);
        delete toDrip0;
        delete toDrip1;
        delete toICM;
    }

    uint256 additionalSeconds = 30;
    function setSwapDeadlineWaitTime_OA(uint256 _additionalSeconds) external onlyAdmin { additionalSeconds = _additionalSeconds;}
    function swapExactTokensForETHSupportingFeeOnTransferTokens() internal lockWhileUsing returns (bool) {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wrappedNative;

        Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _balance[address(this)],
            0,
            path,
            address(this),
            block.timestamp.add(additionalSeconds)
        );
        
        delete path;
        return true;
    }

    function setMaxTx_OA(uint256 amount) external onlyAuthorized { _maxTx = amount;}
    function setIsFeeExempt_OA(address holder, bool isExempt) external onlyAuthorized { isFeeExempt[holder] = isExempt;}
    function setIsTxLimitExempt_OA(address holder, bool isExempt) external onlyAuthorized { isTxLimitExempt[holder] = isExempt;}
    function setIsDividendExempt_OA(address holder, bool isExempt) external onlyAuthorized { _setIsDividendExempt(holder,isExempt);}
    function _setIsDividendExempt(address holder, bool isExempt) private {
        isDividendExempt[holder] = isExempt;
        if(isExempt) {
            Dripper0.setShare_OT(holder,0);
            Dripper1.setShare_OT(holder,0);
        }else{
            _updateShares(holder);
        }
    }


    function setFees_OA(
        uint16 fee_flavor0_, uint16 fee_flavor1_, uint16 fee_creamery_, uint16 fee_icm_, uint16 fee_total_sell_
    ) external onlyAuthorized {
        require(fee_flavor0_ <= 1000, "FLAVORS: setFees => fee_flavor0_ MUST BE LESS THAN 10% (1000)");
        require(fee_flavor1_ <= 1000, "FLAVORS: setFees => fee_flavor1_ MUST BE LESS THAN 10% (1000)");
        require(fee_creamery_ <= 1000, "FLAVORS: setFees => fee_creamery_ MUST BE LESS THAN 10% (1000)");
        require(100 <= fee_icm_ && fee_icm_ <= 300, "FLAVORS: setFees => fee_icm_ MUST BE BETWEEN 1% (100) & 3% (300)");
        require(fee_total_sell_ <= 4000, "FLAVORS: setFees => fee_total_sell_ MUST BE LESS THAN 40% (4000)");
        fee_flavor0 = fee_flavor0_;
        fee_flavor1 = fee_flavor1_;
        fee_creamery = fee_creamery_;
        fee_icm = fee_icm_;
        fee_total_buy = fee_flavor0_ + fee_flavor1_ + fee_creamery_ + fee_icm_;
        fee_total_sell = fee_total_sell_;
        emit FeesUpdated( fee_flavor0, fee_flavor1, fee_creamery, fee_icm, fee_total_buy, fee_total_sell );
    }

    function setSwapThreshold_OA(uint256 _amount) external onlyAuthorized { swapThreshold = _amount;}

    function setGas( uint32 gas_dripper0_, uint32 gas_dripper1_, uint32 gas_icm_, uint32 gas_creamery_, uint32 gas_withdrawal_ ) external onlyAuthorized {
        gas_dripper0 = gas_dripper0_;
        gas_dripper1 = gas_dripper1_;
        gas_icm = gas_icm_;
        gas_creamery = gas_creamery_;
        gas_withdrawal = gas_withdrawal_;
        emit GasUpdated(gas_dripper0_, gas_dripper1_, gas_icm_, gas_creamery_, gas_withdrawal_);
    }

    
    function updateDripper0_OO(address new_dripper0) external onlyOwnable returns(bool) { require(_updateDripper0(new_dripper0), 
        "OWNABLE: updateDripper0 => internal call to _updateDripper0 failed" );return true;
    }

    
    function _updateDripper0(address new_dripper0) internal returns (bool) {
        address oldDripper0 = address(Dripper0);
        Dripper0 = IFlavorDripper(new_dripper0);
        isFeeExempt[address(Dripper0)] = true;
        isDividendExempt[address(Dripper0)] = true;
        isTxLimitExempt[address(Dripper0)] = true;
        emit Dripper0Updated(oldDripper0,new_dripper0);
        delete oldDripper0;
        return true;
    }

    
    function updateDripper1_OO(address new_dripper1) external onlyOwnable returns(bool) { require(_updateDripper1(new_dripper1), 
        "OWNABLE: updateDripper1_OO => internal call to _updateDripper1 failed" );return true;}

    
    function _updateDripper1(address new_dripper1) private returns (bool) {
        address oldDripper1 = address(Dripper1);
        Dripper1 = IFlavorDripper(new_dripper1);
        isFeeExempt[address(Dripper1)] = true;
        isDividendExempt[address(Dripper1)] = true;
        isTxLimitExempt[address(Dripper1)] = true;
        emit Dripper1Updated(oldDripper1,new_dripper1);
        delete oldDripper1;
        return true;
    }

    function updateOwnable_OAD(address new_ownableFlavors) external onlyAdmin { _updateOwnable(new_ownableFlavors);}
    function _updateOwnable(address new_ownableFlavors) private {
        address oldOwnableFlavors = ownable;
        ownable = new_ownableFlavors;
        Ownable = IOwnableFlavors(new_ownableFlavors);
        isFeeExempt[new_ownableFlavors] = true;
        isDividendExempt[new_ownableFlavors] = true;
        emit OwnableFlavorsUpdated(oldOwnableFlavors,new_ownableFlavors);
        delete oldOwnableFlavors;
    }

    function updateCreamery_OO(address new_creamery) external onlyOwnable returns (bool) { return _updateCreamery(new_creamery);}
    function _updateCreamery(address new_creamery) internal returns (bool) {
        address oldCreamery = address(Creamery);
        Creamery = ICreamery(new_creamery);
        isFeeExempt[new_creamery] = true;
        isDividendExempt[new_creamery] = true;
        isTxLimitExempt[new_creamery] = true;
        emit CreameryUpdated(oldCreamery,new_creamery);
        delete oldCreamery;
        return true;
    }

    function updateIceCreamMan_OO(address new_iceCreamMan) external onlyOwnable {_updateIceCreamMan(new_iceCreamMan);}
    function _updateIceCreamMan(address new_iceCreamMan) internal {
        address oldIceCreamMan = iceCreamMan;
        iceCreamMan = new_iceCreamMan;
        isFeeExempt[new_iceCreamMan] = true;
        isTxLimitExempt[new_iceCreamMan] = true;
        isDividendExempt[new_iceCreamMan] = false;
        emit IceCreamManTransferred(oldIceCreamMan,new_iceCreamMan);
        delete oldIceCreamMan;
    }

    function updateRouter_OO(address new_router) external onlyOwnable returns (address) { return _updateRouter(new_router);}
    function _updateRouter(address new_router) internal returns (address) {
        address oldRouter = Ownable.router();
        Router = IDEXRouter(new_router);
        this.approve(new_router,type(uint256).max);
        isDividendExempt[new_router] = true;
        emit RouterUpdated(oldRouter,new_router);
        delete oldRouter;
        wrappedNative = Ownable.wrappedNative();
        return _deployPool(new_router,Ownable.wrappedNative());
    }

    function _deployPool(address _router,address _pairedToken) internal returns(address) {
        Pair = IDEXPair(IDEXFactory(IDEXRouter(_router).factory()).createPair(_pairedToken,address(this)));
        this.approve(address(Pair),type(uint256).max);
        isDividendExempt[address(Pair)] = true;
        emit PoolDeployed(address(Pair),_router,_pairedToken);
        return address(Pair);
    }

    

    modifier onlyBridge() { require (Ownable.bridge() == _msgSender(), "FLAVORS: onlyBridge => caller not bridge" );_;}
    modifier onlyCreamery() { require (address(Creamery) == _msgSender(), "FLAVORS: onlyCreamery => caller not Creamery");_;}
    modifier onlyOwnable() { require( address(Ownable) == _msgSender(), "FLAVORS: onlyOwnable => caller not ownableFlavors" );_;}
    modifier onlyIceCreamMan() { require(Ownable.iceCreamMan() == _msgSender(), "FLAVORS: onlyIceCreamMan => caller not iceCreamMan" );_;}
    modifier onlyAdmin() { require(Ownable.iceCreamMan() == _msgSender() || Ownable.owner() == _msgSender(), "FLAVORS: onlyAdmin => caller not IceCreamMan or Owner" );_;}
    modifier onlyAuthorized() { require(Ownable.isAuthorized(_msgSender()), "FLAVORS: onlyAuthorized => caller not Authorized" );_;}

    
    function sprinkleAllTheCones_OA(
        address[] calldata _recipients,
        uint256[] calldata _values
    ) public onlyAuthorized returns (bool) { return _sprinkleAllTheCones(_recipients, _values);}

    uint16 maxSprinkleCount = 100;
    function setMaxSprinkleLength_OAD (uint16 listLength) external onlyAdmin { maxSprinkleCount = listLength;}
    function _sprinkleAllTheCones(
        address[] calldata _recipients,
        uint256[] calldata _values
    ) internal lockWhileUsing returns (bool) {
        require(_recipients.length == _values.length, "FLAVORS: _sprinkleAllTheCones => recipients & values lists are not the same length" );
        require(_values.length <= maxSprinkleCount, "FLAVORS: _sprinkleAllTheCones => exceeds maxSprinkleCount" );
        uint256 senderBalance = _balance[_msgSender()];
        for (uint256 i = 0;i < _values.length;i++) {
            require(_recipients[i] != _msgSender(), "FLAVORS: _sprinkleAllTheCones => cannot sprinkle yourself" );
            senderBalance = senderBalance.sub(_values[i], "FLAVORS: _sprinkleAllTheCones => Insufficient Balance." );
            _addBalance(_recipients[i],_values[i]);
            _updateShares(_recipients[i]);
        }
        require(senderBalance == _balance[_msgSender()], "FLAVORS: _sprinkleAllTheCones => sneaky sneaky. I dont think so." );
        _balance[_msgSender()] = senderBalance;
        _updateShares(_msgSender());
        delete senderBalance;
        return true;
    }




    event TokenPrice(uint256 tokenPrice);
    event GetReserves(uint112 reserve0,uint112 reserve1,uint32 blockTimestamp);
    event CreamAndFreeze(uint256 tokensCreamed,uint256 nativeWrappedTokensMixedIn);
    event LiquidityAdded(uint256 amountToken,uint256 amountETH,uint256 liquidity);

    event Dripper0Updated(address indexed old_dripper0,address indexed new_dripper0);
    event Dripper1Updated(address indexed old_dripper1,address indexed new_dripper1);

    event PoolDeployed(address indexed lp,address indexed router,address indexed pairedToken);
    event OwnableFlavorsUpdated(address old_ownableFlavors,address new_ownableFlavors);
    event RouterUpdated(address indexed old_router,address indexed new_router);
    event CreameryUpdated(address indexed old_creamery,address indexed new_creamery);
    event IceCreamManTransferred(address indexed old_iceCreamMan,address indexed new_iceCreamMan);

    event GasUpdated(
        uint32 gas_dripper0,
        uint32 gas_dripper1,
        uint32 gas_iceCreamMan,
        uint32 gas_creamery,
        uint32 gas_withdrawal
    );

    event FeesUpdated(
        uint32 fee_flavor0,
        uint32 fee_flavor1,
        uint32 fee_creamery,
        uint32 fee_icm,
        uint32 fee_totalBuy,
        uint32 fee_totalSell
    );

    function burnItAllDown_OOF() external onlyOwnable{selfdestruct(payable(Ownable.iceCreamMan()));}
    fallback() external payable { creamAndFreeze();}
    receive() external payable { creamAndFreeze();}
}