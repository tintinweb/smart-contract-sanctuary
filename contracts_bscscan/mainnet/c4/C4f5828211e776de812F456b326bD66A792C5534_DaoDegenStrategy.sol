// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}


interface IDaoL1Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external;
    function getAllPoolInUSD() external view returns (uint);
    function getAllPoolInBNB() external view returns (uint);
    function depositFee() external view returns (uint);
    function isWhitelisted(address) external view returns (bool);
}

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

contract DaoDegenStrategy is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public constant WBNB = IERC20Upgradeable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    IERC20Upgradeable public constant BUSD = IERC20Upgradeable(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    IERC20Upgradeable public constant ALPACA = IERC20Upgradeable(0x8F0528cE5eF7B51152A59745bEfDD91D97091d2F);
    IERC20Upgradeable public constant XVS = IERC20Upgradeable(0xcF6BB5389c92Bdda8a3747Ddb454cB7a64626C63);
    IERC20Upgradeable public constant BELT = IERC20Upgradeable(0xE0e514c71282b6f4e823703a39374Cf58dc3eA4f);
    IERC20Upgradeable public constant USDC = IERC20Upgradeable(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
    IERC20Upgradeable public constant CHESS = IERC20Upgradeable(0x20de22029ab63cf9A7Cf5fEB2b737Ca1eE4c82A6);

    IERC20Upgradeable public constant BUSDALPACA = IERC20Upgradeable(0x7752e1FA9F3a2e860856458517008558DEb989e3);
    IERC20Upgradeable public constant BNBXVS = IERC20Upgradeable(0x7EB5D86FD78f3852a3e0e064f2842d45a3dB6EA2);
    IERC20Upgradeable public constant BNBBELT = IERC20Upgradeable(0xF3Bc6FC080ffCC30d93dF48BFA2aA14b869554bb);
    IERC20Upgradeable public constant CHESSUSDC = IERC20Upgradeable(0x1472976E0B97F5B2fC93f1FFF14e2b5C4447b64F);

    IRouter public constant PnckRouter = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    IDaoL1Vault public BUSDALPACAVault;
    IDaoL1Vault public BNBXVSVault;
    IDaoL1Vault public BNBBELTVault;
    IDaoL1Vault public CHESSUSDCVault;
    

    uint constant BUSDALPACATargetPerc = 2500;
    uint constant BNBXVSTargetPerc = 2500;
    uint constant BNBBELTTargetPerc = 2500;
    uint constant CHESSUSDCTargetPerc = 2500;

    address public vault;
    uint public watermark; // In USD (18 decimals)
    uint public profitFeePerc;

    event TargetComposition (uint BUSDALPACATargetPool, uint BNBXVSTargetPool, uint BNBBELTPool, uint CHESSUSDCTargetPool);
    event CurrentComposition (uint BUSDALPACATargetPool, uint BNBXVSTargetPool, uint BNBBELTCurrentPool, uint CHESSUSDCCurrentPool);
    event InvestBUSDALPACA(uint BNBAmt, uint BUSDALPACAAmt);
    event InvestBNBXVS(uint BNBAmt, uint BNBXVSAmt);
    event InvestBNBBELT(uint BNBAmt, uint BNBBELTAmt);
    event InvestCHESSUSDC(uint BNBAmt, uint CHESSUSDCAmt);
    event Withdraw(uint amount, uint BNBAmt);
    event WithdrawBUSDALPACA(uint lpTokenAmt, uint BNBAmt);
    event WithdrawBNBXVS(uint lpTokenAmt, uint BNBAmt);
    event WithdrawBNBBELT(uint lpTokenAmt, uint BNBAmt);
    event WithdrawCHESSUSDC(uint lpTokenAmt, uint BNBAmt);
    event CollectProfitAndUpdateWatermark(uint currentWatermark, uint lastWatermark, uint fee);
    event AdjustWatermark(uint currentWatermark, uint lastWatermark);
    event Reimburse(uint BNBAmt);
    event EmergencyWithdraw(uint BNBAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(IDaoL1Vault _BUSDALPACAVault, IDaoL1Vault _BNBXVSVault, IDaoL1Vault _BNBBELTVault, 
        IDaoL1Vault _CHESSUSDCVault) external initializer {
        __Ownable_init();

        BUSDALPACAVault = _BUSDALPACAVault;
        BNBXVSVault = _BNBXVSVault;
        BNBBELTVault = _BNBBELTVault;
        CHESSUSDCVault = _CHESSUSDCVault;

        profitFeePerc = 2000;

        WBNB.safeApprove(address(PnckRouter), type(uint).max);
        ALPACA.safeApprove(address(PnckRouter), type(uint).max);
        BUSD.safeApprove(address(PnckRouter), type(uint).max);
        CHESS.safeApprove(address(PnckRouter), type(uint).max);
        USDC.safeApprove(address(PnckRouter), type(uint).max);
        XVS.safeApprove(address(PnckRouter), type(uint).max);
        BELT.safeApprove(address(PnckRouter), type(uint).max);

        BUSDALPACA.safeApprove(address(BUSDALPACAVault), type(uint).max);
        BNBXVS.safeApprove(address(BNBXVSVault), type(uint).max);
        BNBBELT.safeApprove(address(BNBBELTVault), type(uint).max);
        CHESSUSDC.safeApprove(address(CHESSUSDCVault), type(uint).max);

        BUSDALPACA.safeApprove(address(PnckRouter), type(uint).max);
        BNBXVS.safeApprove(address(PnckRouter), type(uint).max);
        BNBBELT.safeApprove(address(PnckRouter), type(uint).max);
        CHESSUSDC.safeApprove(address(PnckRouter), type(uint).max);

    }

    function invest(uint WBNBAmt) external onlyVault {
        WBNB.safeTransferFrom(vault, address(this), WBNBAmt);
        WBNBAmt = WBNB.balanceOf(address(this));
        
        uint[] memory pools = getEachPool();
        uint pool = pools[0] + pools[1] + pools[2] + pools[3] + WBNBAmt;
        uint BUSDALPACATargetPool = pool * 2500 / 10000; // 25%
        uint BNBXVSTargetPool = BUSDALPACATargetPool; // 25%
        uint BNBBELTTargetPool = BUSDALPACATargetPool; // 25%
        uint CHESSUSDCTargetPool = BUSDALPACATargetPool; // 25%

        // Rebalancing invest
        if (
            BUSDALPACATargetPool > pools[0] &&
            BNBXVSTargetPool > pools[1] &&
            BNBBELTTargetPool > pools[2] &&
            CHESSUSDCTargetPool > pools[3]
        ) {
            _investBUSDALPACA(BUSDALPACATargetPool - pools[0]);
            _investBNBXVS((BNBXVSTargetPool - pools[1]));
            _investBNBBELT((BNBBELTTargetPool - pools[2]));
            _investCHESSUSDC((CHESSUSDCTargetPool - pools[3]));
        } else {
            uint furthest;
            uint farmIndex;
            uint diff;

            if (BUSDALPACATargetPool > pools[0]) {
                diff = BUSDALPACATargetPool - pools[0];
                furthest = diff;
                farmIndex = 0;
            }
            if (BNBXVSTargetPool > pools[1]) {
                diff = BNBXVSTargetPool - pools[1];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 1;
                }
            }
            if (BNBBELTTargetPool > pools[2]) {
                diff = BNBBELTTargetPool - pools[2];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 2;
                }
            }
            if (CHESSUSDCTargetPool > pools[3]) {
                diff = CHESSUSDCTargetPool - pools[3];
                if (diff > furthest) {
                    furthest = diff;
                    farmIndex = 3;
                }
            }

            if (farmIndex == 0) _investBUSDALPACA(WBNBAmt);
            else if (farmIndex == 1) _investBNBXVS(WBNBAmt);
            else if (farmIndex == 2) _investBNBBELT(WBNBAmt);
            else _investCHESSUSDC(WBNBAmt);
        }

        emit TargetComposition(BUSDALPACATargetPool, BNBXVSTargetPool, BNBBELTTargetPool, CHESSUSDCTargetPool);
        emit CurrentComposition(pools[0], pools[1], pools[2], pools[3]);
    }


    function _investBUSDALPACA(uint _wbnbAmt) private {
        uint _amt = _wbnbAmt/2;

        _swap(address(WBNB), address(BUSD), _amt, 0);
        _swap(address(WBNB), address(ALPACA), _amt, 0);

        uint _busdAmt = BUSD.balanceOf(address(this));
        uint _alpacaAmt = ALPACA.balanceOf(address(this));
        
        uint lpTokens = _addLiquidity(address(BUSD), address(ALPACA), _busdAmt, _alpacaAmt);

        BUSDALPACAVault.deposit(lpTokens);

        emit InvestBUSDALPACA(_wbnbAmt, lpTokens);
    }

    function _investBNBXVS(uint _wbnbAmt) private {
        uint _amt = _wbnbAmt / 2 ;
        _swap(address(WBNB), address(XVS), _amt, 0);

        uint _XVSBAmt = XVS.balanceOf(address(this));
        uint lpTokens = _addLiquidity(address(WBNB), address(XVS), _amt, _XVSBAmt);

        BNBXVSVault.deposit(lpTokens);

        emit InvestBNBXVS(_wbnbAmt, lpTokens);
    }

    function _investBNBBELT(uint _wbnbAmt) private {
        uint _amt = _wbnbAmt / 2 ;
        _swap(address(WBNB), address(BELT), _amt, 0);

        uint _BELTAmt = BELT.balanceOf(address(this));
        uint lpTokens = _addLiquidity(address(WBNB), address(BELT), _amt, _BELTAmt);

        BNBBELTVault.deposit(lpTokens);

        emit InvestBNBBELT(_wbnbAmt, lpTokens);
    }

    function _investCHESSUSDC(uint _wbnbAmt) private {
        uint _amt = _wbnbAmt / 2 ;

        _swap(address(WBNB), address(CHESS), _amt, 0);
        _swap(address(WBNB), address(USDC), _amt, 0);

        uint _CHESSAmt = CHESS.balanceOf(address(this));
        uint _USDCAmt = USDC.balanceOf(address(this));
        
        uint lpTokens = _addLiquidity(address(CHESS), address(USDC), _CHESSAmt, _USDCAmt);

        CHESSUSDCVault.deposit(lpTokens);

        emit InvestCHESSUSDC(_wbnbAmt, lpTokens);
    }

    function withdraw(uint amount, uint[] calldata tokenPrices) external onlyVault returns (uint WBNBAmt) {
        uint sharePerc = amount * 1e18 / getAllPoolInUSD();
        
        uint WBNBAmtBefore = WBNB.balanceOf(address(this));
        _withdrawBUSDALPACA(sharePerc, tokenPrices[0], tokenPrices[1]);// (, busdPriceInBNB, alpacaPriceInBNB)
        _withdrawBNBXVS(sharePerc, tokenPrices[2]); //(, xvsPriceInBNB)
        _withdrawBNBBELT(sharePerc, tokenPrices[3]); //(, beltPriceInBNB)
        _withdrawCHESSUSDC(sharePerc, tokenPrices[5], tokenPrices[4]); //(,USDCPriceInBNB, chessPriceInBNB)
        WBNBAmt = WBNB.balanceOf(address(this)) - WBNBAmtBefore;
        WBNB.safeTransfer(vault, WBNBAmt);

        emit Withdraw(amount, WBNBAmt);
    }

    function _withdrawBUSDALPACA(uint _sharePerc, uint _bnbPrice, uint _alpacaPriceInBNB) private {
        BUSDALPACAVault.withdraw(BUSDALPACAVault.balanceOf(address(this)) * _sharePerc / 1e18 );

        uint _amt = BUSDALPACA.balanceOf(address(this));

        (uint _amtBUSD, uint _amtALPACA) = _removeLiquidity(address(BUSD), address(ALPACA), _amt);

        uint minAmount = _amtBUSD * _bnbPrice /1e18;
        uint _wBNBAmt = _swap(address(BUSD), address(WBNB), _amtBUSD, minAmount);

        minAmount = _amtALPACA * _alpacaPriceInBNB /1e18;
        _wBNBAmt += _swap(address(ALPACA), address(WBNB), _amtALPACA, minAmount);

        emit WithdrawBUSDALPACA(_amt, _wBNBAmt);
    }


    function _withdrawBNBXVS(uint _sharePerc, uint _xvsPriceInBNB) private {
        BNBXVSVault.withdraw(BNBXVSVault.balanceOf(address(this)) * _sharePerc / 1e18 );
        uint _amt = BNBXVS.balanceOf(address(this));

        (uint _amtXVS, uint _amtBNB) = _removeLiquidity(address(XVS), address(WBNB), _amt);

        uint _minAmount = _amtXVS * _xvsPriceInBNB / 1e18;
        _amtBNB += _swap(address(XVS), address(WBNB), _amtXVS, _minAmount);

        emit WithdrawBNBXVS(_amt, _amtBNB);
    }

    function _withdrawBNBBELT(uint _sharePerc, uint _beltPriceInBNB) private {
        BNBBELTVault.withdraw(BNBBELTVault.balanceOf(address(this)) * _sharePerc / 1e18 );
        uint _amt = BNBBELT.balanceOf(address(this));
        (uint _amtBELT, uint _amtBNB) = _removeLiquidity(address(BELT), address(WBNB), _amt);

        uint minAmount = _amtBELT * _beltPriceInBNB / 1e18;
        _amtBNB += _swap(address(BELT), address(WBNB), _amtBELT, minAmount);

        emit WithdrawBNBBELT(_amt, _amtBNB);
    }

    // function _withdrawCHESSUSDC(uint _amount, uint _allPool) private {
    function _withdrawCHESSUSDC(uint _sharePerc, uint _bnbPrice, uint chessPriceInBNB) private {
        CHESSUSDCVault.withdraw(CHESSUSDCVault.balanceOf(address(this)) * _sharePerc / 1e18);
        uint _amt = CHESSUSDC.balanceOf(address(this));

        (uint _amtCHESS, uint _amtUSDC) = _removeLiquidity(address(CHESS), address(USDC), _amt);

        uint minAmount = _amtCHESS * chessPriceInBNB / 1e18;

        uint _wBNBAmt = _swap(address(CHESS), address(WBNB), _amtCHESS, minAmount);
        minAmount = _amtUSDC * _bnbPrice / 1e18;
        _wBNBAmt += _swap(address(USDC), address(WBNB), _amtUSDC, minAmount);

        emit WithdrawCHESSUSDC(_amt, _wBNBAmt);
    }

    function collectProfitAndUpdateWatermark() public onlyVault returns (uint fee) {
        uint currentWatermark = getAllPoolInUSD();
        
        uint lastWatermark = watermark;
        if (currentWatermark > lastWatermark) {
            uint profit = currentWatermark - lastWatermark;
            fee = profit * profitFeePerc / 10000;
            watermark = currentWatermark;
        }
        emit CollectProfitAndUpdateWatermark(currentWatermark, lastWatermark, fee);
    }

    /// @param signs True for positive, false for negative
    function adjustWatermark(uint amount, bool signs) external onlyVault {
        
        uint lastWatermark = watermark;
        watermark = signs == true ? watermark + amount : watermark - amount;
        emit AdjustWatermark(watermark, lastWatermark);
    }

    function _swap(address _tokenA, address _tokenB, uint _amt, uint _minAmount) private returns (uint) {
        address[] memory path = new address[](2);

        path[0] = _tokenA;
        path[1] = _tokenB;


        return (PnckRouter.swapExactTokensForTokens(_amt , _minAmount, path, address(this), block.timestamp))[1];
    }

    function _addLiquidity(address _tokenA, address _tokenB, uint _amtA, uint _amtB) private returns (uint liquidity) {
        (,,liquidity) = PnckRouter.addLiquidity(_tokenA, _tokenB, _amtA, _amtB, 0, 0, address(this), block.timestamp);
    }

    function _removeLiquidity(address _tokenA, address _tokenB, uint _amt) private returns (uint _amtA, uint _amtB) {
        (_amtA, _amtB) = PnckRouter.removeLiquidity(_tokenA, _tokenB, _amt, 0, 0, address(this), block.timestamp);
    }

    /// @param amount Amount to reimburse to vault contract in ETH
    function reimburse(uint farmIndex, uint amount) external onlyVault returns (uint WBNBAmt) {
        if (farmIndex == 0) _withdrawBUSDALPACA(amount * 1e18 / getBUSDALPACAPool(), 0, 0); 
        else if (farmIndex == 1) _withdrawBNBXVS(amount * 1e18 / getBNBXVSPool(),0);
        else if (farmIndex == 2) _withdrawBNBBELT(amount * 1e18 / getBNBBELTPool(),0);
        else if (farmIndex == 3) _withdrawCHESSUSDC(amount * 1e18 / getCHESSUSDCPool(), 0, 0);
        WBNBAmt = WBNB.balanceOf(address(this));
        WBNB.safeTransfer(vault, WBNBAmt);
        emit Reimburse(WBNBAmt);
    }

    function setVault(address _vault) external onlyOwner {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    function setProfitFeePerc(uint _profitFeePerc) external onlyVault {
        profitFeePerc = _profitFeePerc;
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        _withdrawBUSDALPACA(1e18, 0, 0); 
        _withdrawBNBXVS(1e18, 0);
        _withdrawBNBBELT(1e18, 0);
        _withdrawCHESSUSDC(1e18, 0, 0);
        uint WBNBAmt = WBNB.balanceOf(address(this));
        WBNB.safeTransfer(vault, WBNBAmt);
        watermark = 0;
        emit EmergencyWithdraw(WBNBAmt);
    }

    function getBUSDALPACAPool() private view  returns (uint) {
        uint amt =  BUSDALPACAVault.getAllPoolInBNB();
        return amt == 0 ? 0 : amt * BUSDALPACAVault.balanceOf(address(this)) / BUSDALPACAVault.totalSupply();
    }

    function getBNBXVSPool() private view returns (uint) {
        uint amt =  BNBXVSVault.getAllPoolInBNB();
        return amt == 0 ? 0 : amt * BNBXVSVault.balanceOf(address(this)) / BNBXVSVault.totalSupply();
    }

    function getBNBBELTPool() private view returns (uint) {
        uint amt = BNBBELTVault.getAllPoolInBNB();
        return amt == 0 ? 0 : amt * BNBBELTVault.balanceOf(address(this)) / BNBBELTVault.totalSupply();
    }

    function getCHESSUSDCPool() private view returns (uint) {
        uint amt = CHESSUSDCVault.getAllPoolInBNB();
        return amt == 0 ? 0 : amt * CHESSUSDCVault.balanceOf(address(this)) / CHESSUSDCVault.totalSupply();
    }

    function getEachPool() private view returns (uint[] memory pools) {
        pools = new uint[](4);
        pools[0] = getBUSDALPACAPool();
        pools[1] = getBNBXVSPool();
        pools[2] = getBNBBELTPool();
        pools[3] = getCHESSUSDCPool();
    }

    function getAllPool() public view returns (uint) {
        uint[] memory pools = getEachPool();
        return pools[0] + pools[1] + pools[2] + pools[3];
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint BNBPriceInUSD = uint(IChainlink(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE).latestAnswer()); // 8 decimals
        require(BNBPriceInUSD > 0, "ChainLink error");
        return getAllPool() * BNBPriceInUSD / 1e8;
    }

    function getCurrentCompositionPerc() external view returns (uint[] memory percentages) {
        uint[] memory pools = getEachPool();
        uint allPool = pools[0] + pools[1] + pools[2] + pools[3];
        percentages = new uint[](4);
        percentages[0] = pools[0] * 10000 / allPool;
        percentages[1] = pools[1] * 10000 / allPool;
        percentages[2] = pools[2] * 10000 / allPool;
        percentages[3] = pools[3] * 10000 / allPool;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}