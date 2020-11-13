// File: contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts/interfaces/IOneSwapToken.sol

pragma solidity 0.6.12;


interface IOneSwapBlackList {
    event OwnerChanged(address);
    event AddedBlackLists(address[]);
    event RemovedBlackLists(address[]);

    function owner()external view returns (address);
    function newOwner()external view returns (address);
    function isBlackListed(address)external view returns (bool);

    function changeOwner(address ownerToSet) external;
    function updateOwner() external;
    function addBlackLists(address[] calldata  accounts)external;
    function removeBlackLists(address[] calldata  accounts)external;
}

interface IOneSwapToken is IERC20, IOneSwapBlackList{
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function multiTransfer(uint256[] calldata mixedAddrVal) external returns (bool);
}

// File: contracts/interfaces/IOneSwapFactory.sol

pragma solidity 0.6.12;

interface IOneSwapFactory {
    event PairCreated(address indexed pair, address stock, address money, bool isOnlySwap);

    function createPair(address stock, address money, bool isOnlySwap) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setFeeBPS(uint32 bps) external;
    function setPairLogic(address implLogic) external;

    function allPairsLength() external view returns (uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function feeBPS() external view returns (uint32);
    function pairLogic() external returns (address);
    function getTokensFromPair(address pair) external view returns (address stock, address money);
    function tokensToPair(address stock, address money, bool isOnlySwap) external view returns (address pair);
}

// File: contracts/interfaces/IOneSwapRouter.sol

pragma solidity 0.6.12;

interface IOneSwapRouter {
    event AddLiquidity(uint stockAmount, uint moneyAmount, uint liquidity);
    event PairCreated(address indexed pair, address stock, address money, bool isOnlySwap);

    function factory() external pure returns (address);

    // liquidity
    function addLiquidity(
        address stock,
        address money,
        bool isOnlySwap,
        uint amountStockDesired,
        uint amountMoneyDesired,
        uint amountStockMin,
        uint amountMoneyMin,
        address to,
        uint deadline
    ) external payable returns (uint amountStock, uint amountMoney, uint liquidity);
    function removeLiquidity(
        address pair,
        uint liquidity,
        uint amountStockMin,
        uint amountMoneyMin,
        address to,
        uint deadline
    ) external returns (uint amountStock, uint amountMoney);

    // swap token
    function swapToken(
        address token,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    // limit order
    function limitOrder(
        bool isBuy,
        address pair,
        uint prevKey,
        uint price,
        uint32 id,
        uint stockAmount,
        uint deadline
    ) external payable;
}

// File: contracts/interfaces/IOneSwapBuyback.sol

pragma solidity 0.6.12;

interface IOneSwapBuyback {
    event BurnOnes(uint256 burntAmt);

    function ones() external pure returns (address);
    function router() external pure returns (address);
    function factory() external pure returns (address);

    function addMainToken(address token) external;
    function removeMainToken(address token) external;
    function isMainToken(address token) external view returns (bool);
    function mainTokens() external view returns (address[] memory list);

    function removeLiquidity(address[] calldata pairs) external;
    function swapForMainToken(address[] calldata pairs) external;
    function swapForOnesAndBurn(address[] calldata pairs) external;
}

// File: contracts/OneSwapBuyback.sol

pragma solidity 0.6.12;





contract OneSwapBuyback is IOneSwapBuyback {

    uint256 private constant _MAX_UINT256 = uint256(-1); 
    address private constant _ETH = address(0);

    address public immutable override ones;
    address public immutable override router;
    address public immutable override factory;

    mapping (address => bool) private _mainTokens;
    address[] private _mainTokenArr;

    constructor(address _ones, address _router, address _factory) public {
        ones = _ones;
        router = _router;
        factory = _factory;

        // add ETH & ONES to main token list
        _mainTokens[_ETH] = true;
        _mainTokenArr.push(_ETH);
        _mainTokens[_ones] = true;
        _mainTokenArr.push(_ones);
    }

    receive() external payable { }

    // add token into main token list
    function addMainToken(address token) external override {
        require(msg.sender == IOneSwapToken(ones).owner(), "OneSwapBuyback: NOT_ONES_OWNER");
        if (!_mainTokens[token]) {
            _mainTokens[token] = true;
            _mainTokenArr.push(token);
        }
    }
    // remove token from main token list
    function removeMainToken(address token) external override {
        require(msg.sender == IOneSwapToken(ones).owner(), "OneSwapBuyback: NOT_ONES_OWNER");
        require(token != _ETH, "OneSwapBuyback: REMOVE_ETH_FROM_MAIN");
        require(token != ones, "OneSwapBuyback: REMOVE_ONES_FROM_MAIN");
        if (_mainTokens[token]) {
            _mainTokens[token] = false;
            uint256 lastIdx = _mainTokenArr.length - 1;
            for (uint256 i = 2; i < lastIdx; i++) { // skip ETH & ONES
                if (_mainTokenArr[i] == token) {
                    _mainTokenArr[i] = _mainTokenArr[lastIdx];
                    break;
                }
            }
            _mainTokenArr.pop();
        }
    }
    // check if token is in main token list
    function isMainToken(address token) external view override returns (bool) {
        return _mainTokens[token];
    }
    // query main token list
    function mainTokens() external view override returns (address[] memory list) {
        list = _mainTokenArr;
    }

    // remove Buyback's liquidity from all pairs
    // swap got minor tokens for main tokens if possible
    function removeLiquidity(address[] calldata pairs) external override {
        for (uint256 i = 0; i < pairs.length; i++) {
            _removeLiquidity(pairs[i]);
        }
    }
    function _removeLiquidity(address pair) private {
        (address a, address b) = IOneSwapFactory(factory).getTokensFromPair(pair);
        require(a != address(0) || b != address(0), "OneSwapBuyback: INVALID_PAIR");

        uint256 amt = IERC20(pair).balanceOf(address(this));
        // require(amt > 0, "OneSwapBuyback: NO_LIQUIDITY");
        if (amt == 0) { return; }

        IERC20(pair).approve(router, 0);
        IERC20(pair).approve(router, amt);
        IOneSwapRouter(router).removeLiquidity(
            pair, amt, 0, 0, address(this), _MAX_UINT256);

        // minor -> main
        bool aIsMain = _mainTokens[a];
        bool bIsMain = _mainTokens[b];
        if ((aIsMain && !bIsMain) || (!aIsMain && bIsMain)) {
            _swapForMainToken(pair);
        }
    }

    // swap minor tokens for main tokens
    function swapForMainToken(address[] calldata pairs) external override {
        for (uint256 i = 0; i < pairs.length; i++) {
            _swapForMainToken(pairs[i]);
        }
    }
    function _swapForMainToken(address pair) private {
        (address a, address b) = IOneSwapFactory(factory).getTokensFromPair(pair);
        require(a != address(0) || b != address(0), "OneSwapBuyback: INVALID_PAIR");

        address mainToken;
        address minorToken;
        if (_mainTokens[a]) {
            require(!_mainTokens[b], "OneSwapBuyback: SWAP_TWO_MAIN_TOKENS");
            (mainToken, minorToken) = (a, b);
        } else {
            require(_mainTokens[b], "OneSwapBuyback: SWAP_TWO_MINOR_TOKENS");
            (mainToken, minorToken) = (b, a);
        }

        uint256 minorTokenAmt = IERC20(minorToken).balanceOf(address(this));
        // require(minorTokenAmt > 0, "OneSwapBuyback: NO_MINOR_TOKENS");
        if (minorTokenAmt == 0) { return; }

        address[] memory path = new address[](1);
        path[0] = pair;

        // minor -> main
        IERC20(minorToken).approve(router, 0);
        IERC20(minorToken).approve(router, minorTokenAmt);
        IOneSwapRouter(router).swapToken(
            minorToken, minorTokenAmt, 0, path, address(this), _MAX_UINT256);
    }

    // swap main tokens for ones, then burn all ones
    function swapForOnesAndBurn(address[] calldata pairs) external override {
        for (uint256 i = 0; i < pairs.length; i++) {
            _swapForOnes(pairs[i]);
        }

        // burn all ones
        uint256 allOnes = IERC20(ones).balanceOf(address(this));
        if (allOnes == 0) { return; }
        IOneSwapToken(ones).burn(allOnes);
        emit BurnOnes(allOnes);
    }
    function _swapForOnes(address pair) private {
        (address a, address b) = IOneSwapFactory(factory).getTokensFromPair(pair);
        require(a != address(0) || b != address(0), "OneSwapBuyback: INVALID_PAIR");
        require(a == ones || b == ones, "OneSwapBuyback: ONES_NOT_IN_PAIR");

        address token = (a == ones) ? b : a;
        require(_mainTokens[token], "OneSwapBuyback: MAIN_TOKEN_NOT_IN_PAIR");

        address[] memory path = new address[](1);
        path[0] = pair;

        if (token == _ETH) { // eth -> ones
            uint256 ethAmt = address(this).balance;
            // require(ethAmt > 0, "OneSwapBuyback: NO_ETH");
            if (ethAmt == 0) { return; }

            IOneSwapRouter(router).swapToken{value: ethAmt}(
                _ETH, ethAmt, 0, path, address(this), _MAX_UINT256);
        } else { // main token -> ones
            uint256 tokenAmt = IERC20(token).balanceOf(address(this));
            // require(tokenAmt > 0, "OneSwapBuyback: NO_MAIN_TOKENS");
            if (tokenAmt == 0) { return; }

            IERC20(token).approve(router, 0);
            IERC20(token).approve(router, tokenAmt);
            IOneSwapRouter(router).swapToken(
                token, tokenAmt, 0, path, address(this), _MAX_UINT256);
        }
    }

}