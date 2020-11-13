//SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @title Liquidity Mining Redeemer
 * @dev This Contract will redeem the Liquidity Mining Positions of the DFOs DFOhub, EthArt and UniFi.
 * Addresses who held tokens in one of there contracts will receive back the result of their Positions, including the reward until now, plus some gifts by the DFOhub DFO.
 * Anyome can redeem all their tokens in a unique operation.
 * For Gas Consumption purposes only in the initialization phase, this Contract will have an initializer who syncs the contract data after the deployment.
 * In fact, the initializer has the only power to insert the positions to redeem and nothing more.
 * When all the positions will be filled, the completeInitialization method will be called and the redeem can be available.
 */
contract LiquidityMiningRedeemer {

    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private WETH_ADDRESS = IUniswapV2Router(UNISWAP_V2_ROUTER).WETH();

    address private _initializer;

    address private _doubleProxy;

    address[] private _tokens;

    mapping(address => bool) private _redeemed;

    mapping(address => mapping(address => uint256)) private _positions;

    event Redeemed(address indexed sender, address indexed positionOwner);

    /**
     * @dev Constructor
     * @param doubleProxy - The link with the DFO which this Contract depends on
     * @param tokens - The list of all ERC-20 tokens involved in the Liquidity Mining Contracts
     */
    constructor(address doubleProxy, address[] memory tokens) {
        _initializer = msg.sender;
        _doubleProxy = doubleProxy;
        _tokens = tokens;
    }

    /**
     * @dev This method is callable by the initializer only and it helps to do a step-by-step initialization to avoid out-of-gas transaction due to large amount of information.
     * It loads all the addresses having opened positions in the Liquidity Mining Contracts and the amount they will receive to redeem.
     */
    function fillData(address[] memory positionOwners, uint256[] memory token0Amounts, uint256[] memory token1Amounts, uint256[] memory token2Amounts, uint256[] memory token3Amounts, uint256[] memory token4Amounts, uint256[] memory token5Amounts) public {
        require(msg.sender == _initializer, "Unauthorized Action");
        assert(positionOwners.length == token0Amounts.length && token0Amounts.length == token1Amounts.length && token1Amounts.length == token2Amounts.length && token2Amounts.length == token3Amounts.length && token3Amounts.length == token4Amounts.length && token4Amounts.length == token5Amounts.length);
        for(uint256 i = 0; i < positionOwners.length; i++) {
            if(_tokens.length > 0) {
                _positions[positionOwners[i]][_tokens[0]] = token0Amounts[i];
            }
            if(_tokens.length > 1) {
                _positions[positionOwners[i]][_tokens[1]] = token1Amounts[i];
            }
            if(_tokens.length > 2) {
                _positions[positionOwners[i]][_tokens[2]] = token2Amounts[i];
            }
            if(_tokens.length > 3) {
                _positions[positionOwners[i]][_tokens[3]] = token3Amounts[i];
            }
            if(_tokens.length > 4) {
                _positions[positionOwners[i]][_tokens[4]] = token4Amounts[i];
            }
            if(_tokens.length > 5) {
                _positions[positionOwners[i]][_tokens[5]] = token5Amounts[i];
            }
        }
    }

    /**
     * @dev After the end of the contract inizialiation, initializer will be set to address(0) and cannot be edited any more.
     */
    function completeInitialization() public {
        require(msg.sender == _initializer, "Unauthorized Action");
        _initializer = address(0);
    }

    /**
     * @return The address of the Contract initializer
     */
    function initializer() public view returns (address) {
        return _initializer;
    }

    /**
     * @dev Method callable only by voting a Proposal in the linked DFO.
     * For emergency purposes only (e.g. in case of Smart Contract bug)
     * @param additionalTokens all the eventual additional tokens hel by the Contract. Can be empty
     */
    function emergencyFlush(address[] memory additionalTokens) public {
        IMVDProxy proxy = IMVDProxy(IDoubleProxy(_doubleProxy).proxy());
        require(IMVDFunctionalitiesManager(proxy.getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized Action!");
        address walletAddress = proxy.getMVDWalletAddress();
        address tokenAddress = proxy.getToken();
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceOf = token.balanceOf(address(this));
        if(balanceOf > 0) {
            token.transfer(walletAddress, balanceOf);
        }
        balanceOf = 0;
        for(uint256 i = 0; i < _tokens.length; i++) {
            token = IERC20(_tokens[i]);
            balanceOf = token.balanceOf(address(this));
            if(balanceOf > 0) {
                token.transfer(walletAddress, balanceOf);
            }
            balanceOf = 0;
        }
        balanceOf = 0;
        for(uint256 i = 0; i < additionalTokens.length; i++) {
            token = IERC20(additionalTokens[i]);
            balanceOf = token.balanceOf(address(this));
            if(balanceOf > 0) {
                token.transfer(walletAddress, balanceOf);
            }
            balanceOf = 0;
        }
        balanceOf = address(this).balance;
        if(balanceOf > 0) {
            payable(walletAddress).transfer(balanceOf);
        }
    }

    /**
     * @return the Double Proxy Address of the linked DFO
     */
    function doubleProxy() public view returns(address) {
        return _doubleProxy;
    }

    /**
     * @return the address of all the tokens involved in the Liquidity Mining Contracts
     */
    function tokens() public view returns(address[] memory) {
        return _tokens;
    }

    /**
     * @dev Method callable only by voting a Proposal in the linked DFO.
     * Sets the new Double Proxy address, in case it is needed.
     */
    function setDoubleProxy(address newDoubleProxy) public {
        require(IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_doubleProxy).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(msg.sender), "Unauthorized Action!");
        _doubleProxy = newDoubleProxy;
    }

    /**
     * @param positionOwner the Address of the owner you want to know info
     * @return amounts The amount of tokens this address will receive (each position of the array corresponds to the one of the array returned by the votingTokens() call)
     */
    function position(address positionOwner) public view returns (uint256[] memory amounts){
        amounts = new uint256[](_tokens.length);
        for(uint256 i = 0; i < _tokens.length; i++) {
            amounts[i] = _positions[positionOwner][_tokens[i]];
        }
    }

    /**
     * @param positionOwner the Address of the owner you want to know info
     * @return true if this address already redeemed its position. False otherwhise
     */
    function redeemed(address positionOwner) public view returns(bool) {
        return _redeemed[positionOwner];
    }

    receive() external payable {
    }

    /**
     * @dev The redeem function will give back the position amounts to the msg.sender.
     * It can be called just one time per address.
     * Redeem will be available after the finalization of the Smart Contract
     */
    function redeem() public {
        require(_initializer == address(0), "Redeem still not initialized");
        address positionOwner = msg.sender;
        require(!_redeemed[positionOwner], "This position owner already redeemed its position");
        _redeemed[positionOwner] = true;
        for(uint256 i = 0; i < _tokens.length; i++) {
            uint256 amount = _positions[positionOwner][_tokens[i]];
            if(amount == 0) {
                continue;
            }
            if(_tokens[i] == WETH_ADDRESS) {
                payable(positionOwner).transfer(amount);
                continue;
            }
            IERC20(_tokens[i]).transfer(positionOwner, amount);
        }
        emit Redeemed(msg.sender, positionOwner);
    }

    /**
     * @dev Converts the Uniswap V2 LP Tokens sent by the Liquidity Mining Contracts to the corresponding tokens to provide liquidity for the redeemers
     * @param token0 Uniswap V2 LP Token 0
     * @param token1 Uniswap V2 LP Token 1
     * @param amountMin0 Parameter useful to call the UniswapV2Router
     * @param amountMin1 Parameter useful to call the UniswapV2Router
     */
    function convertUniswapV2TokenPool(address token0, address token1, uint256 amountMin0, uint256  amountMin1) public returns (uint256 amountA, uint256 amountB) {
        IERC20 pair = IERC20(IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(token0, token1));
        uint256 liquidity = pair.balanceOf(address(this));
        IUniswapV2Router router = IUniswapV2Router(UNISWAP_V2_ROUTER);
        pair.approve(UNISWAP_V2_ROUTER, liquidity);
        if(token0 == WETH_ADDRESS || token1 == WETH_ADDRESS) {
            return router.removeLiquidityETH(token0 == WETH_ADDRESS ? token1 : token0, liquidity, amountMin0, amountMin1, address(this), block.timestamp + 1000);
        }
        return router.removeLiquidity(token0, token1, liquidity, amountMin0, amountMin1, address(this), block.timestamp + 1000);
    }
}

interface IMVDProxy {
    function getToken() external view returns(address);
    function getStateHolderAddress() external view returns(address);
    function getMVDWalletAddress() external view returns(address);
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
}

interface IStateHolder {
    function setUint256(string calldata name, uint256 value) external returns(uint256);
    function getUint256(string calldata name) external view returns(uint256);
    function getBool(string calldata varName) external view returns (bool);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

interface IMVDFunctionalitiesManager {
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router {

    function WETH() external pure returns (address);

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
}

interface IDoubleProxy {
    function proxy() external view returns(address);
}