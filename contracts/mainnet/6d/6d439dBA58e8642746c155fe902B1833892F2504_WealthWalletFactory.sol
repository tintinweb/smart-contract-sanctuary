// File: contracts/interfaces/IUniswapV2Router.sol

interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn,uint amountOutMin,address[] calldata path,address to,uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);       
    function WETH() external pure returns (address);
}

// File: contracts/interfaces/IUniswapV2Pair.sol

interface IUniswapV2Pair {
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

// File: contracts/interfaces/IWETH.sol

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint amount) external;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function allowance(address owner, address spender) external view returns(uint);
    function balanceOf(address owner) external view returns(uint);
}

// File: contracts/portfolio.sol

pragma solidity ^0.7.6;




contract Portfolio {
    //info
    address public owner;
    string public name;
    uint public totalAssets;
    mapping(uint => Asset) public assets;
    Config config;

    //states
    bool configured;
    bool rulesSet;
    bool started;
    bool running;
    bool rebalancing;

    //interfaces
    IUniswapV2Router iUniswapRouter;
    IWETH iWeth;

    //asset structure
    struct Asset {
        string name;
        string symbol;
        address tokenAddress;
        uint ratio;
        uint amount;
    }

    //configuration structure
    struct Config {
        uint slippage; // basis points out of 10,000 
        uint swapTimeLimit; // time limit until swap expires in seconds
        address uniswapRouterAddress;
        address wethAddress;
    }
    
    constructor(address _owner, string memory _name) public {
        //set main info
        owner = _owner;
        name = _name;
        totalAssets = 0;

        //set states
        configured = false;
        rulesSet = false;
        started= false;
        running = false;
        rebalancing = false;

    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function addAsset(string memory _name, string memory _symbol, address _address, uint _ratio) onlyOwner public {
        //create Asset
        Asset memory asset = Asset(_name, _symbol, _address, _ratio, 0);

        //map asset
        assets[totalAssets] = asset;
        totalAssets++;
    }
    
    function changeAssetRatio(uint _assetIndex, uint _assetRatio) onlyOwner public {
        assets[_assetIndex].ratio = _assetRatio;
    }

    function spreadToAssets() internal {
        //spread contract balance to assets
        uint totalAmount = address(this).balance;
        uint currentAmount = totalAmount;

        //for every asset
        for (uint i=0; i<totalAssets; i++) {
            //if current amount is empty
            if (currentAmount == 0) {
                break;
            }

            //get asset and ratio
            Asset memory asset = assets[i];
            uint assetRatio = asset.ratio;

            if (assetRatio == 0) {
                break;
            }
            
            //calculate amountPerAsset
            uint amountPerAsset = totalAmount * assetRatio / 10000;
            
            //if current amount is more than amount to asset
            if (amountPerAsset <= currentAmount) {
                //buy asset for amount
                buyAsset(i, amountPerAsset);

                //adjust current amount
                if (amountPerAsset == currentAmount) {
                    currentAmount = 0;
                }
                else {
                    currentAmount -= amountPerAsset;
                }
            }
            else {
                //buy remaining current amount and set to 0
                buyAsset(i, currentAmount);
                currentAmount = 0;
            }
        }
        
    }

    function buyAsset(uint currentIndex, uint amountIn) internal {
        //set asset data
        Asset memory asset = assets[currentIndex];
        address buyingAddress = asset.tokenAddress;
        address wethAddress = config.wethAddress;

        require(amountIn <= address(this).balance, "Can't send more than current balance");

        if (buyingAddress == wethAddress) {
            //deposit to Wrapped WETH
            iWeth.deposit{value: amountIn}();
        }
        else {
            //get swap config
            uint slippage = config.slippage;
            uint swapTimeLimit = config.swapTimeLimit;

            //set path
            address[] memory path = new address[](2);
            path[0] = wethAddress;
            path[1] = buyingAddress;

            //get amounts out
            uint[] memory amountsOut = iUniswapRouter.getAmountsOut(amountIn, path);
            uint tokenOutput = amountsOut[1];

            //calculate slippage
            uint amountOutMin =  tokenOutput * (10000 - slippage) / 10000;
            
            //set deadline
            uint deadline = block.timestamp + swapTimeLimit;

            //swap Eth for tokens and set return amounts
            uint[] memory amounts = iUniswapRouter.swapExactETHForTokens{value: amountIn}(amountOutMin, path, address(this), deadline);
        }

        //update balance
        updateAssetBalance(currentIndex);
    }

    function updateAssetBalance(uint currentIndex) internal {
        Asset memory asset = assets[currentIndex];

        //set balance
        uint balance;

        //set Weth address
        address wethAddress = config.wethAddress;

        if (asset.tokenAddress == wethAddress) {
            //get balance
            balance = iWeth.balanceOf(address(this));
        }
        else {
            //create pair instance
            IUniswapV2Pair pair = IUniswapV2Pair(asset.tokenAddress);

            //get balance
            balance = pair.balanceOf(address(this));
        }

        //update balance
        assets[currentIndex].amount = balance;
    }

    function rebalance() onlyOwner public {
        //set rebalancing true 
        rebalancing = true;

        //empty assets
        emptyAssets();

        //spread to assets
        spreadToAssets();    

        //set rebalancing back to false
        rebalancing = false;  
    }

    function emptyAssets() onlyOwner internal {
        //for every asset
        for (uint i=0; i<totalAssets; i++) {
            //get asset and ratio
            Asset memory asset = assets[i];

            //if asset balance not empty
            if (asset.amount > 0) {
                //empty asset
                emptyAsset(i);
            }   
        }
    }

    function emptyAsset(uint currentIndex) internal {
        //set asset data
        Asset memory asset = assets[currentIndex];
        address sellingAddress = asset.tokenAddress;
        address wethAddress = config.wethAddress;

        //get swap config
        uint slippage = config.slippage;
        uint swapTimeLimit = config.swapTimeLimit;

        require(asset.amount > 0, "Asset is already empty");

        if (sellingAddress == wethAddress) {
            //deposit to Wrapped WETH
            iWeth.withdraw(asset.amount);
        }
        else {
            //set path
            address[] memory path = new address[](2);
            path[0] = sellingAddress;
            path[1] = wethAddress;

            //get amounts out
            uint[] memory amountsOut = iUniswapRouter.getAmountsOut(asset.amount, path);
            uint tokenOutput = amountsOut[1];

            //calculate slippage
            uint amountOutMin =  tokenOutput * (10000 - slippage) / 10000;
            
            //set deadline
            uint deadline = block.timestamp + swapTimeLimit;

            IUniswapV2Pair pair = IUniswapV2Pair(sellingAddress);
            pair.approve(address(iUniswapRouter), asset.amount);

            //swap Eth for tokens and set return amounts
            iUniswapRouter.swapExactTokensForETH(asset.amount, amountOutMin, path, address(this), deadline);
        }

        //update asset balance
        updateAssetBalance(currentIndex);
    }

    function configure(uint _slippage, uint _swapTimeLimit, address _uniswapRouterAddress, address _wethAddress) onlyOwner public {
        config = Config({
            slippage: _slippage,
            swapTimeLimit: _swapTimeLimit,
            uniswapRouterAddress: _uniswapRouterAddress,
            wethAddress:_wethAddress
        });

        //set interface instances
        iUniswapRouter = IUniswapV2Router(config.uniswapRouterAddress);
        iWeth = IWETH(config.wethAddress);

        //set configured to true
        configured = true;
    }

    function rename(string memory newName) onlyOwner public {
        name = newName;
    }

    function deposit() public payable {
        require(configured, "Configure portfolio");

        if (!rebalancing) {
            spreadToAssets();
        }
    }

    function withdraw(uint amount) onlyOwner public {
        //set state
        rebalancing = true;

        emptyAssets();

        //transfer to owner
        owner.call{value: amount}("");

        spreadToAssets();

        rebalancing = false;
    }

    function withdrawAll() onlyOwner public {
        //set state
        rebalancing = true;

        emptyAssets();

        //transfer to owner
        owner.call{value: address(this).balance}("");

        spreadToAssets();

        rebalancing = false;
    }

    function getTotalAssets() public view returns (uint) {
        return totalAssets;
    }

    function getAssetDetails(uint i) public view returns (string memory, string memory, address, uint, uint) {
        return (assets[i].name, assets[i].symbol, assets[i].tokenAddress, assets[i].ratio, assets[i].amount);
    }
    

    receive() external payable {
        deposit();
    }
}

// File: contracts/wealthWallet.sol

pragma solidity ^0.7.6;


contract WealthWallet {
    address public owner;
    uint public totalPortfolios;
    mapping(uint => Portfolio) public portfolios;
    bool public defaultSet;
    uint public defaultPortfolio;
    
    constructor(address _owner) public {
        owner = _owner;
        defaultSet = false;
        totalPortfolios = 0;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function createPortfolio(string memory _name) onlyOwner public {
        Portfolio portfolio = new Portfolio(owner, _name);

        portfolios[totalPortfolios] = portfolio;

        //if there is no default portfolio
        if (!defaultSet) {
            //set default to this
            defaultPortfolio = totalPortfolios;
            defaultSet = true;
        }

        //update total portfolios
        totalPortfolios+=1;
    }

    function addFunds() public payable {
        require(defaultSet, "Create a portfolio");
        
        fundPortfolio(defaultPortfolio);
    }

    function fundPortfolio(uint portfolioIndex) public payable {
        //get portfolio
        Portfolio portfolio = portfolios[portfolioIndex];

        //fund portfolio with msg value
        address(portfolio).call{value: msg.value}("");
    }

    function setDefault(uint portfolioIndex) onlyOwner public {
        require(portfolioIndex < totalPortfolios, "Portfolio doesn't exist");

        //sets new default portfolio
        defaultPortfolio = portfolioIndex;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
    function getTotalPortfolios() public view returns (uint) {
        return totalPortfolios;
    }
    function getPortfolio(uint portfolioIndex) public view returns (address) {
        return address(portfolios[portfolioIndex]);
    }

    receive() external payable {
        addFunds();
    }
}

// File: contracts/wealthWalletFactory.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;


contract WealthWalletFactory {
    mapping(address => WealthWallet) public wealthWallets;

    function createWealthWallet() external {
        require(address(wealthWallets[msg.sender]) == address(0), "Wealthwallet already exists");

        //create wealth wallet
        WealthWallet wealthWallet = new WealthWallet(msg.sender);

        //map wealth wallet to sender
        wealthWallets[msg.sender] = wealthWallet;
    }

    function getWealthWallet() external view returns (address) {
        return address(wealthWallets[msg.sender]);
    }
    
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}