/**
 *Submitted for verification at arbiscan.io on 2021-11-16
*/

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

interface UniswapFactory {
    function getPool(address token0, address token1, uint24 fee) external returns(address);
}

interface UniswapReserve {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function token0() external view returns(address);
    function token1() external view returns(address);    
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
    function LUSD() external view returns(address);
}

contract Arb {
    address constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    UniswapLens constant public LENS = UniswapLens(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    UniswapFactory constant FACTORY = UniswapFactory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    uint160 constant MIN_SQRT_RATIO = 4295128739;

    // callable by anyone, but it does not suppose to hold funds anw
    function approve(address bamm) external {
        address token = BAMMLike(bamm).LUSD();
        ERC20Like(token).approve(address(bamm), uint(-1));
    }

    function getPrice(uint wethQty, address bamm) external returns(uint) {
        return LENS.quoteExactInputSingle(WETH, BAMMLike(bamm).LUSD(), 500, wethQty, 0);
    }

    function swap(uint ethQty, address bamm, uint uniFee) external payable returns(uint) {
        bytes memory data = abi.encode(bamm, uniFee);
        address reserve = FACTORY.getPool(WETH, BAMMLike(bamm).LUSD(), uint24(uniFee));
        UniswapReserve(reserve).swap(address(this), true, int256(ethQty), MIN_SQRT_RATIO + 1, data);

        uint retVal = address(this).balance;
        msg.sender.transfer(retVal);

        return retVal;
     }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        //require(msg.sender == address(USDCETH), "uniswapV3SwapCallback: invalid sender");
        // swap USDC to LUSD
        uint USDCAmount = uint(-1 * amount1Delta);
        uint LUSDReturn = USDCAmount;

        address bamm = abi.decode(data, (address));
        BAMMLike(bamm).swap(LUSDReturn, 1, address(this));

        if(amount0Delta > 0) {
            WethLike(WETH).deposit{value: uint(amount0Delta)}();
            if(amount0Delta > 0) WethLike(WETH).transfer(msg.sender, uint(amount0Delta));            
        }
    }

    function checkProfitableArb(uint ethQty, uint minProfit, address bamm, uint uniFee) external { // revert on failure
        uint balanceBefore = address(this).balance;
        this.swap(ethQty, bamm, uniFee);
        uint balanceAfter = address(this).balance;
        require((balanceAfter - balanceBefore) >= minProfit, "min profit was not reached");
    }

    receive() external payable {}
}

contract BKeeper {
    Arb public arb;
    uint maxEthQty; // = 1000 ether;
    uint minQty; // = 1e10;
    uint minProfitInBps; // = 100;

    address public admin;
    address[] public bamms;

    event KeepOperation(bool succ);

    constructor(Arb _arb) public {
        arb = _arb;
    }

    function findSmallestQty() public returns(uint, address, uint) {
        for(uint j = 0 ; j < 2 ; j++)
        {
            uint uniFee = (j == 0) ? 500 : 3000;

            for(uint i = 0 ; i < bamms.length ; i++) {
                address bamm = bamms[i];
                for(uint qty = maxEthQty ; qty > minQty ; qty = qty / 2) {
                    uint minProfit = qty * minProfitInBps / 10000;
                    try arb.checkProfitableArb(qty, minProfit, bamm, uniFee) {
                        return (qty, bamm, uniFee);
                    } catch {

                    }
                }
            }
        }

        return (0, address(0), 0);
    }

    function checkUpkeep(bytes calldata /*checkData*/) external returns (bool upkeepNeeded, bytes memory performData) {
        uint[] memory balances = new uint[](bamms.length);
        for(uint i = 0 ; i < bamms.length ; i++) {
            balances[i] = bamms[i].balance;
        }

        (uint qty, address bamm, uint uniFee) = findSmallestQty();

        uint bammBalance;
        for(uint i = 0 ; i < bamms.length ; i++) {
            if(bamms[i] == bamm) bammBalance = balances[i];
        }

        upkeepNeeded = qty > 0;
        performData = abi.encode(qty, bamm, bammBalance, uniFee);
    }
    
    function performUpkeep(bytes calldata performData) external {
        (uint qty, address bamm, uint bammBalance, uint uniFee) = abi.decode(performData, (uint, address, uint, uint));
        require(bammBalance == bamm.balance, "performUpkeep: front runned");
        require(qty > 0, "0 qty");
        arb.swap(qty, bamm, uniFee);
        
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

    function checker()
        external
        returns (bool canExec, bytes memory execPayload)
    {
        (bool upkeepNeeded, bytes memory performData) = this.checkUpkeep(bytes(""));
        canExec = upkeepNeeded;

        execPayload = abi.encodeWithSelector(
            BKeeper.doer.selector,
            performData
        );
    }

    function doer(bytes calldata performData) external {
        this.performUpkeepSafe(performData);
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

    function setArb(Arb _arb) external {
        require(msg.sender == admin, "!admin");
        arb = _arb;
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
        arb.approve(newBamm);
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
}