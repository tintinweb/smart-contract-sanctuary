// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IBandStdReference.sol";

// import "./interfaces/IPoolToken.sol";
// import "./CoffinOracle.sol";
// import "./interfaces/IGatePolicy.sol";


contract GateV2CalcOracles is Ownable {
    // using SafeMath for uint256;
    // using FixedPoint for *;

    // IUniswapV2Router02 public uniswapv2router;
    // address public coffin;
    // address public dollar;
    // address public xcoffin;
    address public wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public boo = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
    address public dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    IBandStdReference bandRef;
    // uint32 public override PERIOD = 600; // 10-minute TWAP

    // struct Pair {
    //     uint256 price0CumulativeLast;
    //     uint256 price1CumulativeLast;
    //     uint32 blockTimestampLast;
    //     FixedPoint.uq112x112 price0Average;
    //     FixedPoint.uq112x112 price1Average;
    //     bool initialized;
    // }

    // mapping(address => Pair) public getPair;

    // function setPeriod(uint32 _period) external onlyOwner {
    //     PERIOD = _period;
    // }

    constructor(
        // address _coffinAddress,
        // address _cousdAddress,
        // address _xcoffinAddress
    ) {
        // // router address. it's spooky router by default. 
        // address routerAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
        // setRouter(routerAddress);

        address fantomBandProtocol = 0x56E2898E0ceFF0D1222827759B56B28Ad812f92F;

        setBandOracle(fantomBandProtocol);
        // setCOFFINAddress(_coffinAddress);
        // setDollarAddress(_cousdAddress);
        // setXCOFFINAddress(_xcoffinAddress);
    }

    function getBandRate(string memory token0, string memory token1)
        public
        view
        returns (uint256)
    {
        IBandStdReference.ReferenceData memory data = bandRef.getReferenceData(
            token0,
            token1
        );
        return data.rate;
    }


    // function getFTMUSD() public view  returns (uint256, uint8) {
    //     return (getBandRate("FTM","USD"), 18);
    // }

    // function setCOFFINAddress(address _coffinAddress) public onlyOwner {
    //     coffin = _coffinAddress;
    // }

    // function setXCOFFINAddress(address _xcoffinAddress) public onlyOwner {
    //     xcoffin = _xcoffinAddress;
    // }

    // function setDollarAddress(address _cousdAddress) public onlyOwner {
    //     dollar = _cousdAddress;
    // }

    // function setRouter(address _uniswapv2routeraddress)
    //     public
    //     onlyOwner
    // {
    //     uniswapv2router = IUniswapV2Router02(_uniswapv2routeraddress);
    // }

    function setBandOracle(address _bandOracleAddress) public onlyOwner {
        bandRef = IBandStdReference(_bandOracleAddress);
    }


    // function getCOFFINUSD() external view override returns (uint256, uint8) {
    //     (uint256 v1, uint8 d1) = getCOFFINFTM();
    //     (uint256 v2, uint8 d2) = getFTMUSD();
    //     return ((v1 * v2) / (10**d1), d2);
    // }

    // function getTwapCOFFINUSD() external view override returns (uint256, uint8) {
    //     (uint256 v1, uint8 d1) = getTwapCOFFINFTM();
    //     (uint256 v2, uint8 d2) = getFTMUSD();
    //     return ((v1 * v2) / (10**d1), d2);
    // }
    
    // function getUSDCUSD() public view  returns (uint256, uint8) {
    //     return (getBandRate("USDC","USD"), 18);
    // }
    // function getDAIUSD() public view  returns (uint256, uint8) {
    //     return (getBandRate("DAI","USD"), 18);
    // }
    
    // uint8 public oracleMode = 0; 

    // function enableFTMOracle() external onlyOwner {
    //     oracleMode = 1;
    // }
    // function enableDAIOracle() external onlyOwner {
    //     oracleMode = 2 ;
    // }
    // function enableUSDCracle() external onlyOwner {
    //     oracleMode = 0 ;
    // // }

    // function getCOUSDUSD() external view override returns (uint256, uint8) {
    //     if (oracleMode==1) {
    //         (uint256 v1, uint8 d1) = getCOUSDFTM();
    //         (uint256 v2, uint8 d2) = getFTMUSD();
    //         return ((v1 * v2) / (10**d1), d2);
    //     } else if (oracleMode==2) {
    //         (uint256 v1, uint8 d1) = getCOUSDDAI();
    //         (uint256 v2, uint8 d2) = getDAIUSD();
    //         return ((v1 * v2) / (10**d1), d2);
    //     } else {
    //         (uint256 v1, uint8 d1) = getCOUSDUSDC();
    //         (uint256 v2, uint8 d2) = getUSDCUSD();
    //         return ((v1 * v2) / (10**d1), d2);
    //     }
    // }

    // function getTwapCOUSDUSD() external view override returns (uint256, uint8) {
    //     if (oracleMode==1) {
    //         (uint256 v1, uint8 d1) = getTwapCOUSDFTM();
    //         (uint256 v2, uint8 d2) = getFTMUSD();
    //         return ((v1 * v2) / (10**d1), d2);
    //     } else if (oracleMode==2) {   
    //         (uint256 v1, uint8 d1) = getTwapCOUSDDAI();
    //         (uint256 v2, uint8 d2) = getDAIUSD();
    //         return ((v1 * v2) / (10**d1), d2);
    //     } else {
    //         (uint256 v1, uint8 d1) = getTwapCOUSDUSDC();
    //         (uint256 v2, uint8 d2) = getUSDCUSD();
    //         return ((v1 * v2) / (10**d1), d2);     
    //     }

    // }

    
    


    // function getXCOFFINUSD() external view override returns (uint256, uint8) {
    //     (uint256 v1, uint8 d1) = getXCOFFINFTM();
    //     (uint256 v2, uint8 d2) = getFTMUSD();
    //     return ((v1 * v2) / (10**d1), d2);
    // }

    // function getTwapXCOFFINUSD() external view override returns (uint256, uint8) {
    //     (uint256 v1, uint8 d1) = getTwapXCOFFINFTM();
    //     (uint256 v2, uint8 d2) = getFTMUSD();
    //     return ((v1 * v2) / (10**d1), d2);
    // }

    // function getTwapCOUSDFTM() public view  returns (uint256, uint8) {
    //     (uint256 a, uint8 b) = getTwapRate(dollar,wftm);
    //     if (a>0) {
    //         return (a,b);
    //     }
    //     return getRealtimeRate(dollar,wftm);
    // }
    
    // function getTwapCOUSDDAI() public view  returns (uint256, uint8) {
    //     (uint256 a, uint8 b) = getTwapRate(dollar,dai);
    //     if (a>0) {
    //         return (a,b);
    //     }
    //     return getRealtimeRate(dollar,usdc);
    // }
    // function getTwapCOUSDUSDC() public view  returns (uint256, uint8) {
    //     (uint256 a, uint8 b) = getTwapRate(dollar,usdc);
    //     if (a>0) {
    //         return (a,b);
    //     }
    //     return getRealtimeRate(dollar,usdc);
    // }
    
    // function getCOUSDFTM() public view override returns (uint256, uint8) {
    //     return getRealtimeRate(dollar,wftm);
    // }
    // function getCOUSDUSDC() public view returns (uint256, uint8) {
    //     return getRealtimeRate(dollar,usdc);
    // }
    // function getCOUSDDAI() public view returns (uint256, uint8) {
    //     return getRealtimeRate(dollar,dai);
    // }
    

    // function getTwapXCOFFINFTM() public view  returns (uint256, uint8) {
    //     (uint256 a, uint8 b) = getTwapRate(xcoffin,wftm);
    //     if (a>0) {
    //         return (a,b);
    //     }
    //     return getRealtimeRate(xcoffin,wftm);
    // }

    // function getXCOFFINFTM() public view override returns (uint256, uint8) {
    //     return getRealtimeRate(xcoffin,wftm);
    // }

    // function getTwapCOFFINFTM() public view returns (uint256, uint8) {
    //     (uint256 a, uint8 b) = getTwapRate(coffin,wftm);
    //     if (a>0) {
    //         return (a,b);
    //     }
    //     return getRealtimeRate(coffin,wftm);
    // }
    // function getCOFFINFTM() public view override returns (uint256, uint8) {
    //     return getRealtimeRate(coffin,wftm);
    // }


    // function currentBlockTimestamp() internal view returns (uint32) {
    //     return uint32(block.timestamp % 2**32);
    // }

    // function currentCumulativePrices(address uniswapV2Pair)
    //     internal
    //     view
    //     returns (
    //         uint256 price0Cumulative,
    //         uint256 price1Cumulative,
    //         uint32 blockTimestamp
    //     )
    // {
    //     // Pair storage pairStorage = getPair[uniswapV2Pair];

    //     blockTimestamp = currentBlockTimestamp();
    //     IUniswapLP uniswapPair = IUniswapLP(uniswapV2Pair);
    //     price0Cumulative = uniswapPair.price0CumulativeLast();
    //     price1Cumulative = uniswapPair.price1CumulativeLast();

    //     // if time has elapsed since the last update on the pair, mock the accumulated price values
    //     (uint112 reserve0, uint112 reserve1, uint32 _blockTimestampLast) = uniswapPair.getReserves();
    //     if (_blockTimestampLast != blockTimestamp) {
    //         // subtraction overflow is desired
    //         uint32 timeElapsed = blockTimestamp - _blockTimestampLast;
    //         // addition overflow is desired
    //         // counterfactual
    //         price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
    //         // counterfactual
    //         price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
    //     }
    // }


    // function getTwapRate(address token0, address token1)
    //     public
    //     view
    //     returns (uint256 priceLatest, uint8 decimals)
    // {
    //     address[] memory path = new address[](2);
    //     path[0] = token0;
    //     path[1] = token1;
    //     address factory = address(uniswapv2router.factory());
    //     address uniswapV2Pair = IUniswapV2Factory(factory).getPair(token0, token1);

    //     if (uniswapV2Pair== address(0)) {
    //         return (0,0);
    //     } 

    //     // Pair memory pair = getPair[uniswapV2Pair];
    //     Pair storage pairStorage = getPair[uniswapV2Pair];

    //     // require(pairStorage.initialized, "need to setup first");
    //     if (!pairStorage.initialized) {
    //         return getRealtimeRate(token0, token1);
    //         // return (0,0);
    //     }
        
    //     (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = currentCumulativePrices(
    //         address(uniswapV2Pair)
    //     );
    //     uint32 timeElapsed = blockTimestamp - pairStorage.blockTimestampLast; // Overflow is desired

    //     FixedPoint.uq112x112 memory price0Average 
    //         = FixedPoint.uq112x112(uint224((price0Cumulative - pairStorage.price0CumulativeLast) / timeElapsed));
    //     FixedPoint.uq112x112 memory price1Average 
    //         = FixedPoint.uq112x112(uint224((price1Cumulative - pairStorage.price1CumulativeLast) / timeElapsed));

    //     uint256 amountIn = 1e18;
    //     if (IUniswapLP(uniswapV2Pair).token0() == token0) {
    //         priceLatest = uint256(price0Average.mul(amountIn).decode144());
    //         decimals = ERC20(token1).decimals();
    //     } else {
    //         require(IUniswapLP(uniswapV2Pair).token0() == token1, "TwapOracle: INVALID_TOKEN");
    //         priceLatest = uint256(price1Average.mul(amountIn).decode144());
    //         decimals = ERC20(token0).decimals();
    //     }
    // }

    // function getTwapRateWithUpdate(address token0, address token1)
    //     external
    //     returns (uint256 priceLatest, uint8 decimals)
    // {
    //     updateTwap(token0,token1);
    //     return getTwapRate(token0,token1);
    // }
    

    // function updateTwapDollarFTM() public  {
    //     updateTwap(dollar, wftm);
    // }
    // function updateTwapDollar() public override {
    //     updateTwap(dollar, dai);
    // }
    // function updateTwapDollarUSDC() public  {
    //     updateTwap(dollar, usdc);
    // }
    // function updateTwapCoffin() public override {
    //     updateTwap(coffin, wftm);
    // }
    // function updateTwapXCoffin() public override {
    //     updateTwap(xcoffin, wftm);
    // }

    // function updateTwap(address token0, address token1) public override {

    //     address[] memory path = new address[](2);
    //     path[0] = token0;
    //     path[1] = token1;
    //     address factory = address(uniswapv2router.factory());
    //     address uniswapV2Pair = IUniswapV2Factory(factory).getPair(token0, token1);

    //     if (uniswapV2Pair== address(0)) {
    //         return;
    //     }
    //     Pair storage pairStorage = getPair[uniswapV2Pair];
    //     // require(pairStorage.initialized, "need to setup first");
        
    //     (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = currentCumulativePrices(
    //         address(uniswapV2Pair)
    //     );

    //     if (!pairStorage.initialized) {
    //         // first time 
    //         pairStorage.price0CumulativeLast = price0Cumulative;
    //         pairStorage.price1CumulativeLast = price1Cumulative;
    //         pairStorage.blockTimestampLast = blockTimestamp;
    //         pairStorage.initialized = true;
    //         return;
    //     }

    //     // Overflow is desired
    //     uint32 timeElapsed = blockTimestamp - pairStorage.blockTimestampLast; 
        
    //     // Ensure that at least one full period has passed since the last update
    //     if (timeElapsed < PERIOD) {
    //         return ;
    //     }
        
    //     pairStorage.price0Average 
    //         = FixedPoint.uq112x112(uint224((price0Cumulative - pairStorage.price0CumulativeLast) / timeElapsed));
    //     pairStorage.price1Average 
    //         = FixedPoint.uq112x112(uint224((price1Cumulative - pairStorage.price1CumulativeLast) / timeElapsed));
    //     pairStorage.price0CumulativeLast = price0Cumulative;
    //     pairStorage.price1CumulativeLast = price1Cumulative;
    //     pairStorage.blockTimestampLast = blockTimestamp;
    // }

    // function getRealtimeRate(address tokenA, address tokenB)
    //     public
    //     view
    //     returns (uint256 priceLatest, uint8 decimals)
    // {

    //     address factory = address(uniswapv2router.factory());
    //     address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    //     if (pair== address(0)) {
    //         return (0,0);
    //     }
        
    //     (uint112 reserve0, uint112 reserve1,) =
    //         IUniswapLP(pair).getReserves();
    //     if (IUniswapLP(pair).token0()==address(tokenA)) {
    //         priceLatest = uint256(reserve1).mul(uint256(10**ERC20(tokenA).decimals())).div(uint256(reserve0));
    //         decimals = ERC20(tokenB).decimals();
    //     } else {
    //         priceLatest = uint256(reserve0).mul(uint256(10**ERC20(tokenA).decimals())).div(uint256(reserve1));
    //         decimals = ERC20(tokenB).decimals();
    //     }

    //     if ((18-decimals)>0) { 
    //         priceLatest = priceLatest.mul(10**(18-decimals));
    //         decimals = 18;
    //     }
    // }
}




contract GateV2CalcOraclesFTM is GateV2CalcOracles {
    function getPrice() external view returns (uint256, uint8) {
        // return super.getFTMUSD();
        return (super.getBandRate("FTM","USD"), 18);

    }
}

contract GateV2CalcOraclesDAI is GateV2CalcOracles {
    function getPrice() external view returns (uint256, uint8) {
        // return super.getDAIUSD();
        return (super.getBandRate("DAI","USD"), 18);

    }
}

contract GateV2CalcOraclesUSDC is GateV2CalcOracles {
    function getPrice() external view returns (uint256, uint8) {
        // return super.getUSDCUSD();
        return (super.getBandRate("USDC","USD"), 18);

    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBandStdReference {
    /// A structure returned whenever someone requests for standard reference data.
    struct ReferenceData {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    /// Returns the price data for the given base/quote pair. Revert if not available.
    function getReferenceData(string memory _base, string memory _quote)
        external
        view
        returns (ReferenceData memory);
    
    /// Similar to getReferenceData, but with multiple base/quote pairs at once.
    function getReferenceDataBulk(
        string[] memory _bases,
        string[] memory _quotes
    ) external view returns (ReferenceData[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}