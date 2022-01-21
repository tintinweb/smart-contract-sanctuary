// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./vault.sol";

contract VaultFactory is Ownable {

    uint256 private constant MAX = (10 ** 18) * (10 ** 18);
    uint256 private constant LITTLE_BNB = 10 ** 16; // 0.01 BNB
    
    event Received(address, uint);
    event VaultGenerated(address);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function generateVault(
        string memory _name, 
        address _quoteToken, 
        address _baseToken, 
        address _strategist, 
        uint16 _percentDev, 
        address _company, 
        address _stakers, 
        address _algoDev,
        uint256 _maxCap
    ) public onlyOwner {

        require(_quoteToken != address(0));
        require(_baseToken != address(0));
        require(_strategist != address(0));
        require(_company != address(0));
        require(_stakers != address(0));
        require(_algoDev != address(0));
        require (address(this).balance > LITTLE_BNB, "Put some BNB to this smart contract to give to the generated vaults");
        
        // 1. deploy a new vault
        Vault newVault = new Vault(
            _name, 
            _quoteToken, 
            _baseToken, 
            address(this), 
            _percentDev, 
            _company, 
            _stakers, 
            _algoDev, 
            _maxCap);
        
        // 2. allow tokens for paraswap token transfer proxy
        newVault.approveTokensForParaswap(0x216B4B4Ba9F3e719726886d34a177484278Bfcae, MAX);

        // 3. set strategist
        newVault.setStrategist(_strategist);

        // 3. send some bnb for paraswap call
        payable(newVault).transfer(LITTLE_BNB);

        // 4. emit event
        emit VaultGenerated(address(newVault));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/uniswapv2.sol";
import "./interfaces/iparaswap.sol";

contract Vault is ERC20 {
    address public strategist;
    mapping(address => bool) public whiteList;

    address public quoteToken;
    address public baseToken;

    uint256 public maxCap = 0;
    uint256 public position = 0; // 0: closed, 1: opened
    uint256 public soldAmount = 0;
    uint256 public profit = percentMax;

    address public constant pancakeRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // mainnet v2

    address public constant wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // mainnet

    address public constant ubxt = 0xBbEB90cFb6FAFa1F69AA130B7341089AbeEF5811; // mainnet
    
    uint16 public percentDev = 500;
    uint16 public percentUpbotsFee = 10;
    uint16 public percentBurn = 350;
    uint16 public percentStakers = 350;
    uint16 public constant percentMax = 10000;

    address[] private pathForward;
    address[] private pathBackward;

    address public company;
    address public stakers;
    address public algoDev;

    string public vaultName;

    event Received(address, uint);
    event ParameterUpdated(address, address, address, uint16, uint16, uint16, uint16, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    constructor(
        string memory _name, 
        address _quoteToken, 
        address _baseToken, 
        address _strategist, 
        uint16 _percentDev, 
        address _company, 
        address _stakers, 
        address _algoDev,
        uint256 _maxCap
    )
        ERC20(
            string(abi.encodePacked("xUBXT_", _name)), 
            string(abi.encodePacked("xUBXT_", _name))
        )
    {
        require(_quoteToken != address(0), "Please provide valid address");
        require(_baseToken != address(0), "Please provide valid address");
        require(_strategist != address(0), "Please provide valid address");
        require(_company != address(0), "Please provide valid address");
        require(_stakers != address(0), "Please provide valid address");
        require(_algoDev != address(0), "Please provide valid address");

        vaultName = _name;
        company = _company;
        stakers = _stakers;
        algoDev = _algoDev;
        maxCap = _maxCap;

        strategist = _strategist;
        whiteList[_strategist] = true;

        quoteToken = _quoteToken;
        baseToken = _baseToken;

        percentDev = _percentDev;

        pathForward = new address[](3);
        pathForward[0] = quoteToken;
        pathForward[1] = wbnb;
        pathForward[2] = baseToken;
        
        pathBackward = new address[](3);
        pathBackward[0] = baseToken;
        pathBackward[1] = wbnb;
        pathBackward[2] = quoteToken;
    }

    function setParameters(
        uint16 _percentDev, 
        uint16 _percentUpbotsFee, 
        uint16 _percentBurn,
        uint16 _percentStakers,
        address _company, 
        address _stakers, 
        address _algoDev,
        uint256 _maxCap
    ) public  {
        
        require(_company != address(0), "Please provide valid address");
        require(_stakers != address(0), "Please provide valid address");
        require(_algoDev != address(0), "Please provide valid address");
        require(msg.sender == strategist, "Not strategist");

        company = _company;
        stakers = _stakers;
        algoDev = _algoDev;
        percentDev = _percentDev;
        percentUpbotsFee = _percentUpbotsFee;
        percentBurn = _percentBurn;
        percentStakers = _percentStakers;
        maxCap = _maxCap;

        emit ParameterUpdated(company, stakers, algoDev, percentDev, percentUpbotsFee, percentBurn, percentStakers, maxCap);
    }

    // Send remanining BNB (used for paraswap integration) to other wallet
    function fundTransfer(address receiver, uint256 amount) public {
        
        require(msg.sender == strategist, "Not strategist");
        require(receiver != address(0), "Please provide valid address");

        payable(receiver).transfer(amount);
    }

    function approveTokensForParaswap(address paraswap, uint256 amount) public {

        require(msg.sender == strategist, "Not strategist");
        require(paraswap != address(0), "Please provide valid address");
        IERC20(quoteToken).approve(paraswap, amount);
        IERC20(baseToken).approve(paraswap, amount);
    }

    function poolSize() public view returns (uint256) {
        return
            (IERC20(quoteToken).balanceOf(address(this)) + _calculateQuoteFromBase());
    }

    function depositQuote(uint256 amount) public {

        // 1. Check max cap
        uint256 _pool = poolSize();
        require (maxCap == 0 || _pool + amount < maxCap, "The vault reached the max cap");

        // 2. transfer quote from sender to this vault
        uint256 _before = IERC20(quoteToken).balanceOf(address(this));
        IERC20(quoteToken).transferFrom(msg.sender, address(this), amount);
        uint256 _after = IERC20(quoteToken).balanceOf(address(this));
        amount = _after - _before; // Additional check for deflationary tokens

        // 3. swap Quote to Base if position is opened
        if (position == 1) {
            soldAmount = soldAmount + amount;

            _before = IERC20(baseToken).balanceOf(address(this));
            _swapPancakeswap(quoteToken, baseToken, amount);
            _after = IERC20(baseToken).balanceOf(address(this));
            amount = _after - _before;

            _pool = _before;
        }

        // 4. calculate share and send back xUBXT
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        }
        else {
            shares = amount * totalSupply() / _pool;
        }
        _mint(msg.sender, shares);
    }

    function depositBase(uint256 amount) public {

        // 1. Check max cap
        uint256 _pool = poolSize();
        uint256[] memory amounts = UniswapRouterV2(pancakeRouter).getAmountsOut(amount, pathBackward);
        uint256 expectedQuote = amounts[2];
        require (maxCap == 0 || _pool + expectedQuote < maxCap, "The vault reached the max cap");

        // 2. transfer base from sender to this vault
        uint256 _before = IERC20(baseToken).balanceOf(address(this));
        IERC20(baseToken).transferFrom(msg.sender, address(this), amount);
        uint256 _after = IERC20(baseToken).balanceOf(address(this));
        amount = _after - _before; // Additional check for deflationary tokens

        _pool = _before;

        // 3. swap Base to Quote if position is closed
        if (position == 0) {
            _before = IERC20(quoteToken).balanceOf(address(this));
            _swapPancakeswap(baseToken, quoteToken, amount);
            _after = IERC20(quoteToken).balanceOf(address(this));
            amount = _after - _before;

            _pool = _before;
        }

        // update soldAmount if position is opened
        if (position == 1) {
            soldAmount = soldAmount + amounts[2];
        }

        // 4. calculate share and send back xUBXT
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = amount;
        } else {
            shares = amount * totalSupply() / _pool;
        }
        _mint(msg.sender, shares);
    }

    function withdraw(uint256 shares) public  {

        require (shares <= balanceOf(msg.sender), "invalid share amount");

        if (position == 0) {

            uint256 amountQuote = IERC20(quoteToken).balanceOf(address(this)) * shares / totalSupply();
            if (amountQuote > 0) {
                IERC20(quoteToken).transfer(msg.sender, amountQuote);
            }
        }

        if (position == 1) {

            uint256 amountBase = IERC20(baseToken).balanceOf(address(this)) * shares / totalSupply();
            uint256[] memory amounts = UniswapRouterV2(pancakeRouter).getAmountsOut(amountBase, pathBackward);
            
            uint256 thisSoldAmount = soldAmount * shares / totalSupply();
            uint256 _profit = profit * amounts[2] / thisSoldAmount;
            if (_profit > percentMax) {

                uint256 profitAmount = amountBase * (_profit - percentMax) / _profit;
                uint256 feeAmount = takePerformanceFeesFromBaseToken(profitAmount);
                amountBase = amountBase - feeAmount;
            }
            soldAmount = soldAmount - thisSoldAmount;
            
            if (amountBase > 0) {
                IERC20(baseToken).transfer(msg.sender, amountBase);
            }
        }

        // burn these shares from the sender wallet
        _burn(msg.sender, shares);

    }

    function buy() public {
        // 0. check whitelist
        require(isWhitelisted(msg.sender), "Not whitelisted");

        // 1. Check if the vault is in closed position
        require(position == 0, "The vault is already in open position");

        // 2. get the amount of quoteToken to trade
        uint256 amount = IERC20(quoteToken).balanceOf(address(this));
        require (amount > 0, "No enough balance to trade");

        // 3. takeUpbotsFees
        amount = takeUpbotsFees(quoteToken, amount);

        // 4. save the remaining to soldAmount
        soldAmount = amount;

        // 5. swap tokens to B
        _swapPancakeswap(quoteToken, baseToken, amount);

        // 6. update position
        position = 1;
    }

    function sell() public {
        // 0. check whitelist
        require(isWhitelisted(msg.sender), "Not whitelisted");

        // 1. check if the vault is in open position
        require(position == 1, "The vault is in closed position");

        // 2. get the amount of baseToken to trade
        uint256 amount = IERC20(baseToken).balanceOf(address(this));

        if (amount > 0) {

            // 3. takeUpbotsFee
            amount = takeUpbotsFees(baseToken, amount);

            // 3. swap tokens to Quote and get the newly create quoteToken
            uint256 _before = IERC20(quoteToken).balanceOf(address(this));
            _swapPancakeswap(baseToken, quoteToken, amount);
            uint256 _after = IERC20(quoteToken).balanceOf(address(this));
            amount = _after - _before;

            // 4. calculate the profit in percent
            profit = profit * amount / soldAmount;

            // 5. take performance fees in case of profit
            if (profit > percentMax) {

                uint256 profitAmount = amount * (profit - percentMax) / profit;
                takePerformanceFees(profitAmount);
                profit = percentMax;
            }
        }

        // 6. update soldAmount
        soldAmount = 0;

        // 7. update position
        position = 0;
    }

    function resetTrade() public {
        
        require(msg.sender == strategist, "Not strategist");

        // 1. swap all baseToken to quoteToken
        uint256 amount = IERC20(baseToken).balanceOf(address(this));
        if (amount > 10**6) {
            _swapPancakeswap(baseToken, quoteToken, amount);
        }

        // 2. reset profit calculation
        profit = percentMax;
        soldAmount = 0;

        // 3. reset position
        position = 0;
    }

    function resetTradeParaswap(address augustusAddr, bytes memory swapCalldata) public {
        
        require(msg.sender == strategist, "Not strategist");

        // 1. swap all baseToken to quoteToken
        (bool success,) = augustusAddr.call(swapCalldata);
        
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // 2. reset profit calculation
        profit = percentMax;
        soldAmount = 0;

        // 3. reset position
        position = 0;
    }

    function addToWhiteList(address _address) public {
        require(msg.sender == strategist, "Not strategist");
        whiteList[_address] = true;
    }

    function removeFromWhiteList(address _address) public {
        require(msg.sender == strategist, "Not strategist");
        whiteList[_address] = false;
    }
    
    function setStrategist(address _address) public {
        
        require(_address != address(0), "Please provide valid address");
        require(msg.sender == strategist, "Not strategist");
        whiteList[_address] = true;
        strategist = _address;
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whiteList[_address];
    }

    function takeUpbotsFees(address token, uint256 amount) private returns(uint256) {
        
        if (amount == 0) {
            return 0;
        }

        // calculate fee
        uint256 fee = amount * percentUpbotsFee / percentMax;

        // swap to UBXT
        uint256 _before = IERC20(ubxt).balanceOf(address(this));
        _swapPancakeswap(token, ubxt, fee);
        uint256 _after = IERC20(ubxt).balanceOf(address(this));
        uint256 ubxtAmt = _after - _before;

        // transfer to company wallet
        IERC20(ubxt).transfer(company, ubxtAmt);
        
        // return remaining token amount 
        return amount - fee;
    }
    
    function takePerformanceFees(uint256 amount) private {

        if (amount == 0) {
            return ;
        }

        // calculate fees
        uint256 burnAmount = amount * percentBurn / percentMax;
        uint256 stakersAmount = amount * percentStakers / percentMax;
        uint256 devAmount = amount * percentDev / percentMax;
        
        // swap to UBXT
        uint256 _total = stakersAmount + devAmount + burnAmount;
        uint256 _before = IERC20(ubxt).balanceOf(address(this));
        _swapPancakeswap(quoteToken, ubxt, _total);
        uint256 _after = IERC20(ubxt).balanceOf(address(this));
        uint256 ubxtAmt = _after - _before;

        // calculate UBXT amounts
        stakersAmount = ubxtAmt * stakersAmount / _total;
        devAmount = ubxtAmt * devAmount / _total;
        burnAmount = ubxtAmt - stakersAmount - devAmount;

        // Transfer
        IERC20(ubxt).transfer(
            address(0), // burn
            burnAmount
        );
        
        IERC20(ubxt).transfer(
            stakers,
            stakersAmount
        );

        IERC20(ubxt).transfer(
            algoDev,
            devAmount
        );
    }

    function takePerformanceFeesFromBaseToken(uint256 amount) private returns(uint256) {

        if (amount == 0) {
            return 0;
        }

        // calculate fees
        uint256 burnAmount = amount * percentBurn / percentMax;
        uint256 stakersAmount = amount * percentStakers / percentMax;
        uint256 devAmount = amount * percentDev / percentMax;
        
        // swap to UBXT
        uint256 _total = stakersAmount + devAmount + burnAmount;
        uint256 _before = IERC20(ubxt).balanceOf(address(this));
        uint256 _tokenbBefore = IERC20(baseToken).balanceOf(address(this));
        _swapPancakeswap(baseToken, ubxt, _total);
        uint256 _after = IERC20(ubxt).balanceOf(address(this));
        uint256 _tokenbAfter = IERC20(baseToken).balanceOf(address(this));
        
        uint256 ubxtAmt = _after - _before;
        uint256 feeAmount = _tokenbBefore - _tokenbAfter;

        // calculate UBXT amounts
        stakersAmount = ubxtAmt * stakersAmount / _total;
        devAmount = ubxtAmt * devAmount / _total;
        burnAmount = ubxtAmt - stakersAmount - devAmount;

        // Transfer
        IERC20(ubxt).transfer(
            address(0), // burn
            burnAmount
        );
        
        IERC20(ubxt).transfer(
            stakers,
            stakersAmount
        );

        IERC20(ubxt).transfer(
            algoDev,
            devAmount
        );

        return feeAmount;
    }

    // *** internal functions ***

    function _calculateQuoteFromBase() internal view returns(uint256) {
        
        uint256 amountBase = IERC20(baseToken).balanceOf(address(this));

        if (amountBase == 0) {
            return 0;
        }
        uint256[] memory amounts = UniswapRouterV2(pancakeRouter).getAmountsOut(amountBase, pathBackward);
        return amounts[2];
    }
    
    function _swapPancakeswap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        // Swap with uniswap
        IERC20(_from).approve(pancakeRouter, 0);
        IERC20(_from).approve(pancakeRouter, _amount);

        address[] memory path;

        if (_from == wbnb || _to == wbnb) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = wbnb;
            path[2] = _to;
        }

        uint256[] memory amounts = UniswapRouterV2(pancakeRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp + 60
        );

        require(amounts[0] > 0, "There was problem in pancakeswap");
    }

    function buyParaswap(address augustusAddr, bytes memory swapCalldata) public {
        
        require(augustusAddr != address(0), "Please provide valid address");

        // 0. check whitelist
        require(isWhitelisted(msg.sender), "Not whitelisted");

        // 1. Check if the vault is in closed position
        require(position == 0, "The vault is already in open position");

        // 2. get the amount of quoteToken to trade
        uint256 amount = IERC20(quoteToken).balanceOf(address(this));
        require (amount > 0, "No enough balance to trade");

        // 3. takeUpbotsFees
        amount = takeUpbotsFees(quoteToken, amount);

        // 4. save the remaining to soldAmount
        soldAmount = amount;

        // 5. swap tokens to B
        (bool success,) = augustusAddr.call(swapCalldata);
        
        if (!success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // 6. update position
        position = 1;
    }

    function sellParaswap(address augustusAddr, bytes memory swapCalldata) public {
        
        require(augustusAddr != address(0), "Please provide valid address");

        // 0. check whitelist
        require(isWhitelisted(msg.sender), "Not whitelisted");

        // 1. check if the vault is in open position
        require(position == 1, "The vault is in closed position");

        // 2. get the amount of baseToken to trade
        uint256 amount = IERC20(baseToken).balanceOf(address(this));

        if (amount > 0) {

            // 3. takeUpbotsFee
            amount = takeUpbotsFees(baseToken, amount);

            // 3. swap tokens to Quote and get the newly create quoteToken
            uint256 _before = IERC20(quoteToken).balanceOf(address(this));
            (bool success,) = augustusAddr.call(swapCalldata);
            
            if (!success) {
                // Copy revert reason from call
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
            uint256 _after = IERC20(quoteToken).balanceOf(address(this));
            amount = _after - _before;

            // 4. calculate the profit in percent
            profit = profit * amount / soldAmount;

            // 5. take performance fees in case of profit
            if (profit > percentMax) {

                uint256 profitAmount = amount * (profit - percentMax) / profit;
                takePerformanceFees(profitAmount);
                profit = percentMax;
            }
        }

        // 6. update soldAmount
        soldAmount = 0;

        // 7. update position
        position = 0;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface UniswapRouterV2 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library Utils {
    /**
   * @param fromToken Address of the source token
   * @param fromAmount Amount of source tokens to be swapped
   * @param toAmount Minimum destination token amount expected out of this swap
   * @param expectedAmount Expected amount of destination tokens without slippage
   * @param beneficiary Beneficiary address
   * 0 then 100% will be transferred to beneficiary. Pass 10000 for 100%
   * @param path Route to be taken for this swap to take place

   */
    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.Path[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        Utils.MegaSwapPath[] path;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct SimpleData {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address[] callees;
        bytes exchangeData;
        uint256[] startIndexes;
        uint256[] values;
        address payable beneficiary;
        address payable partner;
        uint256 feePercent;
        bytes permit;
        uint256 deadline;
        bytes16 uuid;
    }

    struct Adapter {
        address payable adapter;
        uint256 percent;
        uint256 networkFee;
        Route[] route;
    }

    struct Route {
        uint256 index;//Adapter at which index needs to be used
        address targetExchange;
        uint percent;
        bytes payload;
        uint256 networkFee;//Network fee is associated with 0xv3 trades
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;//Network fee is associated with 0xv3 trades
        Adapter[] adapters;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import "./lib/Utils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IParaswap {
    event Swapped(
        bytes16 uuid,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount,
        uint256 expectedAmount
    );

    event Bought(
        bytes16 uuid,
        address initiator,
        address indexed beneficiary,
        address indexed srcToken,
        address indexed destToken,
        uint256 srcAmount,
        uint256 receivedAmount
    );

    event FeeTaken(
        uint256 fee,
        uint256 partnerShare,
        uint256 paraswapShare
    );

    function multiSwap(
        Utils.SellData calldata data
    )
        external
        payable
        returns (uint256);

    function megaSwap(
        Utils.MegaSwapSellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedMultiSwap(
        Utils.SellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedMegaSwap(
        Utils.MegaSwapSellData calldata data
    )
        external
        payable
        returns (uint256);

    function protectedSimpleSwap(
        Utils.SimpleData calldata data
    )
        external
        payable
        returns (uint256 receivedAmount);

    function protectedSimpleBuy(
        Utils.SimpleData calldata data
    )
        external
        payable;

    function simpleSwap(
        Utils.SimpleData calldata data
    )
        external
        payable
        returns (uint256 receivedAmount);

    function simpleBuy(
        Utils.SimpleData calldata data
    )
        external
        payable;

    function swapOnUniswap(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable;

    function swapOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path
    )
        external
        payable;

    function buyOnUniswap(
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable;

    function buyOnUniswapFork(
        address factory,
        bytes32 initCode,
        uint256 amountInMax,
        uint256 amountOut,
        address[] calldata path
    )
        external
        payable;

    function swapOnUniswapV2Fork(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address weth,
        uint256[] calldata pools
    )
        external
        payable;

    function buyOnUniswapV2Fork(
        address tokenIn,
        uint256 amountInMax,
        uint256 amountOut,
        address weth,
        uint256[] calldata pools
    )
        external
        payable;

    function swapOnZeroXv2(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable;

    function swapOnZeroXv4(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 amountOutMin,
        address exchange,
        bytes calldata payload
    )
    external
    payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}