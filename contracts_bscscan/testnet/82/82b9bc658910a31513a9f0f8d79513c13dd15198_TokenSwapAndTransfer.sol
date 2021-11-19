/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

pragma solidity ^0.8.0;

interface IBEP20 {
    function name() external view returns (string memory);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IPancakePair {
    function initialize(address, address) external;
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPancakeRouter {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function removeLiquidity(address tokenA,
                                    address tokenB,
                                    uint liquidity,
                                    uint amountAMin,
                                    uint amountBMin,
                                    address to,
                                    uint deadline) external;
    
}

interface ILP is IBEP20 {
    function token0() external view returns (IBEP20);
    function token1() external view returns (IBEP20);
    function approve(address spender, uint value) external returns (bool);
}


contract TokenSwapAndTransfer {

    address public wallet;
    uint256 MAX_INT = 2**256 - 1;
    IBEP20 private stableCoin;
    mapping (address => bool) public approvedTokens;
    // mainnet
    /*
    IBEP20 public BUSD = IBEP20(address(0xe9e7cea3dedca5984780bafc599bd69add087d56));
    IBEP20 public USDT = IBEP20(address(0xb46d67fb63770052a07d5b7c14ed858a8c90f825));
    IBEP20 public USDC = IBEP20(address(0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d));

    IPancakeRouter pRouter = IPancakeRouter(address(0x10ED43C718714eb63d5aA57B78B54704E256024E));
    IPancakeFactory pFactory = IPancakeFactory(address(0xca143ce32fe78f1f7019d7d551a6402fc5350c73));
    */

    //test wallet = 0xc9d8d134B01E1E2E33875D01474bd89D1EEE9d33
    // shitBUSD to shit USDT pair = 0x1cC99C81d89f53ad2145Ad31b1e1598621D08d16
    
    // testnet
    IBEP20 public BUSD = IBEP20(address(0xf7C1B407c5b87c59C95797779703BA17c80cB8f3));
    IBEP20 public USDT = IBEP20(address(0x5Ca0a0cbCb4F69063a5462f8a3375E71Ee207c6c));
    IBEP20 public USDC = IBEP20(address(0x9780881Bf45B83Ee028c4c1De7e0C168dF8e9eEF));
    IPancakeRouter pRouter = IPancakeRouter(address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3));
    IPancakeFactory pFactory = IPancakeFactory(address(0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc));

    // IPancakePair public pair = IPancakePair(address(0xB289a5ce97aDb89E09575D9EE5E1ADc0D0E13DD9)); // my shit pair
    // IBEP20 public cake = IBEP20(address(0x2083D87D6A3545eAA651316A4CE25546F7186Bc6)); // my shitcake


    function _transferAndConvertIBEPToken(uint _amount, address _IBEPToken, uint _deadline, bool calledFromUser) internal {
        
        
        if (!approvedTokens[_IBEPToken]) {
            IBEP20(_IBEPToken).approve(address(pRouter), MAX_INT);
            approvedTokens[_IBEPToken] = true;
        }

        if (_IBEPToken != address(BUSD) && _IBEPToken != address(USDT) && _IBEPToken != address(USDC)){
            if (pFactory.getPair(_IBEPToken, address(BUSD)) == address(0)) {
                if (pFactory.getPair(_IBEPToken, address(USDC)) == address(0)) {
                    if (pFactory.getPair(_IBEPToken, address(USDT)) == address(0)) {
                    } else {
                        stableCoin = USDT;
                    }
                } else {
                    stableCoin = USDC;
                }
            } else {
                stableCoin = BUSD;
            }
        } else {
            stableCoin = IBEP20(_IBEPToken);
        }
        
        require(address(stableCoin) != address(0), "Pair with your token and stable coin does not exist");

        if (_IBEPToken != address(stableCoin)) {
            IBEP20 token = IBEP20(address(_IBEPToken));
            if (calledFromUser) {
                token.transferFrom(msg.sender, address(this), _amount); // needed approve from msg.sender for this contract
            }

            address[] memory path = new address[](2);
            path[0] = _IBEPToken;
            path[1] = address(stableCoin);
            // token.approve(address(pRouter), _amount); // not cheap to approve every tx
            pRouter.swapExactTokensForTokens(_amount, 0, path, wallet, _deadline);
        }  else {
            IBEP20 token = IBEP20(address(_IBEPToken));
            if (calledFromUser) {
                token.transferFrom(msg.sender, wallet, _amount);
            } else {
                token.transfer(wallet, _amount);
            }
        }
    }

    function _transferAndConvertLPToken(uint _amount, address _lpToken, uint _deadline) internal {
        
        IBEP20 token0 = ILP(address(_lpToken)).token0();
        IBEP20 token1 = ILP(address(_lpToken)).token1();
        uint token0BalanceBefore = token0.balanceOf(address(this));
        uint token1BalanceBefore = token1.balanceOf(address(this));
        ILP lpToken = ILP(address(_lpToken));
        lpToken.transferFrom(msg.sender, address(this), _amount); // needed approve for this contract from msg.sender
        // lpToken.approve(address(pRouter), _amount); // not cheap to approve every tx
        pRouter.removeLiquidity(address(token0), address(token1), _amount, 0, 0, address(this), _deadline);

        uint token0BalanceAfter = token0.balanceOf(address(this));
        uint token1BalanceAfter = token1.balanceOf(address(this));
        _transferAndConvertIBEPToken( (token0BalanceAfter - token0BalanceBefore), address(token0), _deadline, false);
        _transferAndConvertIBEPToken( (token1BalanceAfter - token1BalanceBefore), address(token1), _deadline, false);
    }

    function transferAndConvertToken(uint _amount, address _token, uint _deadline) external {
        if (tryLp(ILP(_token))) {
            _transferAndConvertLPToken(_amount, _token, _deadline);
        } else if (tryToken(IBEP20(_token))) {
            _transferAndConvertIBEPToken(_amount, _token, _deadline, true);
        }
    }

    function tryLp(ILP lpToken) public view returns (bool isLP) {
        ILP _lpToken = lpToken;
        try _lpToken.token0() {
            isLP = tryToken(_lpToken.token0());
        } catch {
            isLP = false;
        }
    }

    function tryToken(IBEP20 token) public view returns (bool isBEP) {
        IBEP20 _token = token;
        try _token.name() {
            isBEP = true;
        } catch {
            isBEP = false;
        }

    }

    function getContractAddress() external view returns (address) {
        return address(this);
    }

    constructor(address _wallet, address lpToken) {
        wallet = _wallet;
        ILP(lpToken).approve(address(pRouter), MAX_INT);
    }

}