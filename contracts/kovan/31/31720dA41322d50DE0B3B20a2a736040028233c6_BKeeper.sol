/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/Arb.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

interface UniswapLens {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

interface UniswapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24  fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external returns (uint256 amountOut);
}

interface UniswapReserve {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

interface ERC20Like {
    function approve(address spender, uint value) external returns(bool);
    function transfer(address to, uint value) external returns(bool);
    function balanceOf(address a) external view returns(uint);
}

interface WethLike is ERC20Like {
    function deposit() external payable;
}

interface CurveLike {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns(uint);
}

interface BAMMLike {
    function swap(uint lusdAmount, uint minEthReturn, address payable dest) external returns(uint);
}

contract Arb {
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address LUSD = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;    
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    UniswapLens constant LENS = UniswapLens(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    UniswapRouter constant ROUTER = UniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    UniswapReserve constant USDCETH = UniswapReserve(0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8);
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    CurveLike constant CURV = CurveLike(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA);
    BAMMLike constant BAMM = BAMMLike(0x0d3AbAA7E088C2c82f54B2f47613DA438ea8C598);

    constructor() public {
        ERC20Like(USDC).approve(address(CURV), uint(-1));
        ERC20Like(LUSD).approve(address(BAMM), uint(-1));
    }

    function getPrice(uint wethQty) external returns(uint) {
        return LENS.quoteExactInputSingle(WETH, USDC, 3000, wethQty, 0);
    }

    function swap(uint ethQty, address bamm) external payable returns(uint) {
        bytes memory data = abi.encode(bamm);
        USDCETH.swap(address(this), false, int256(ethQty), MAX_SQRT_RATIO - 1, data);

        uint retVal = address(this).balance;
        msg.sender.transfer(retVal);

        return retVal;
     }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        require(msg.sender == address(USDCETH), "uniswapV3SwapCallback: invalid sender");
        // swap USDC to LUSD
        uint USDCAmount = uint(-1 * amount0Delta);
        uint LUSDReturn = CURV.exchange_underlying(2, 0, USDCAmount, 1);

        address bamm = abi.decode(data, (address));
        BAMMLike(bamm).swap(LUSDReturn, 1, address(this));

        if(amount1Delta > 0) {
            WethLike(WETH).deposit{value: uint(amount1Delta)}();
            if(amount1Delta > 0) WethLike(WETH).transfer(msg.sender, uint(amount1Delta));            
        }
    }

    receive() external payable {}
}

contract ArbChecker {
    Arb immutable public arb;
    constructor(Arb _arb) public {
        arb = _arb;
    }

    function checkProfitableArb(uint ethQty, uint minProfit, address bamm) public { // revert on failure
        uint balanceBefore = address(this).balance;
        arb.swap(ethQty, bamm);
        uint balanceAfter = address(this).balance;
        require((balanceAfter - balanceBefore) >= minProfit, "min profit was not reached");
    }

    receive() external payable {}       
}

contract BKeeper {
    address public masterCopy;
    ArbChecker immutable public arbChecker;
    Arb immutable public arb;
    uint maxEthQty; // = 1000 ether;
    uint minQty; // = 1e10;
    uint minProfitInBps; // = 100;

    address public admin;
    address[] public bamms;

    event KeepOperation(bool succ);

    constructor(Arb _arb, ArbChecker _arbChecker) public {
        arbChecker = ArbChecker(_arbChecker);
        arb = _arb;
    }

    function findSmallestQty() public returns(uint, address) {
        for(uint i = 0 ; i < bamms.length ; i++) {
            address bamm = bamms[i];
            for(uint qty = maxEthQty ; qty > minQty ; qty = qty / 2) {
                uint minProfit = qty * minProfitInBps / 10000;
                try arbChecker.checkProfitableArb(qty, minProfit, bamm) {
                    return (qty, bamm);
                } catch {

                }
            }
        }

        return (0, address(0));
    }

    function checkUpkeep(bytes calldata /*checkData*/) external returns (bool upkeepNeeded, bytes memory performData) {
        uint[] memory balances = new uint[](bamms.length);
        for(uint i = 0 ; i < bamms.length ; i++) {
            balances[i] = bamms[i].balance;
        }

        (uint qty, address bamm) = findSmallestQty();

        uint bammBalance;
        for(uint i = 0 ; i < bamms.length ; i++) {
            if(bamms[i] == bamm) bammBalance = balances[i];
        }

        upkeepNeeded = qty > 0;
        performData = abi.encode(qty, bamm, bammBalance);
    }
    
    function performUpkeep(bytes calldata performData) external {
        (uint qty, address bamm, uint bammBalance) = abi.decode(performData, (uint, address, uint));
        require(bammBalance == bamm.balance, "performUpkeep: front runned");
        require(qty > 0, "0 qty");
        arb.swap(qty, bamm);
        
        emit KeepOperation(true);        
    }

    function performUpkeepSafe(bytes calldata performData) external {
        try this.performUpkeep(performData) {
            emit KeepOperation(true);
        }
        catch {
            emit KeepOperation(false);
        }
    }    

    receive() external payable {}

    // admin stuff
    function transferAdmin(address newAdmin) external {
        require(msg.sender == admin, "!admin");
        admin = newAdmin;
    }

    function initParams(uint _maxEthQty, uint _minEthQty, uint _minProfit) external {
        require(admin == address(0), "already init");
        maxEthQty = _maxEthQty;
        minQty = _minEthQty;
        minProfitInBps = _minProfit;

        admin = msg.sender;        
    }

    function setMaxEthQty(uint newVal) external {
        require(msg.sender == admin, "!admin");
        maxEthQty = newVal;        
    }

    function setMinEthQty(uint newVal) external {
        require(msg.sender == admin, "!admin");
        minQty = newVal;        
    }
    
    function setMinProfit(uint newVal) external {
        require(msg.sender == admin, "!admin");
        minProfitInBps = newVal;        
    }

    function addBamm(address newBamm) external {
        require(msg.sender == admin, "!admin");        
        bamms.push(newBamm);
    }

    function removeBamm(address bamm) external {
        require(msg.sender == admin, "!admin");
        for(uint i = 0 ; i < bamms.length ; i++) {
            if(bamms[i] == bamm) {
                bamms[i] = bamms[bamms.length - 1];
                bamms.pop();

                return;
            }
        }

        revert("bamm does not exist");
    }

    function withdrawEth() external {
        require(msg.sender == admin, "!admin");
        msg.sender.transfer(address(this).balance);        
    }

    function upgrade(address newMaster) public {
        require(msg.sender == admin, "!admin");
        masterCopy = newMaster;        
    }
}

contract KeeperProxy {

    // masterCopy always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address public masterCopy;

    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable
    {
        // solium-disable-next-line security/no-inline-assembly
        address impl = masterCopy;

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}