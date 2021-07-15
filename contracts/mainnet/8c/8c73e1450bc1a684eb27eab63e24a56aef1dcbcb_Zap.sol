// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

// unused imports; required for a forced contract compilation
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/ProxyAdmin.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20, SafeMath} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import {AccessControlDefendedBase} from "./common/AccessControlDefended.sol";

import {ISett} from "./interfaces/ISett.sol";
import {IBadgerSettPeak, IByvWbtcPeak} from "./interfaces/IPeak.sol";
import {IbBTC} from "./interfaces/IbBTC.sol";
import {IbyvWbtc} from "./interfaces/IbyvWbtc.sol";

contract Zap is Initializable, Pausable, AccessControlDefendedBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    IBadgerSettPeak public constant settPeak = IBadgerSettPeak(0x41671BA1abcbA387b9b2B752c205e22e916BE6e3);
    IByvWbtcPeak public constant byvWbtcPeak = IByvWbtcPeak(0x825218beD8BE0B30be39475755AceE0250C50627);
    IERC20 public constant ibbtc = IERC20(0xc4E15973E6fF2A35cC804c2CF9D2a1b817a8b40F);
    IERC20 public constant ren = IERC20(0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D);
    IERC20 public constant wbtc = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    IController public constant controller = IController(0x63cF44B2548e4493Fd099222A1eC79F3344D9682);

    struct Pool {
        IERC20 lpToken;
        ICurveFi deposit;
        ISett sett;
    }
    Pool[4] public pools;

    address public governance;

    modifier onlyGovernance() {
        require(governance == msg.sender, "NOT_OWNER");
        _;
    }

    function init(address _governance) initializer external {
        _setGovernance(_governance);
        pools[0] = Pool({ // crvRenWBTC [ ren, wbtc ]
            lpToken: IERC20(0x49849C98ae39Fff122806C06791Fa73784FB3675),
            deposit: ICurveFi(0x93054188d876f558f4a66B2EF1d97d16eDf0895B),
            sett: ISett(0x6dEf55d2e18486B9dDfaA075bc4e4EE0B28c1545)
        });
        pools[1] = Pool({ // crvRenWSBTC [ ren, wbtc, sbtc ]
            lpToken: IERC20(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3),
            deposit: ICurveFi(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714),
            sett: ISett(0xd04c48A53c111300aD41190D63681ed3dAd998eC)
        });
        pools[2] = Pool({ // tbtc-sbtcCrv [ tbtc, ren, wbtc, sbtc ]
            lpToken: IERC20(0x64eda51d3Ad40D56b9dFc5554E06F94e1Dd786Fd),
            deposit: ICurveFi(0xaa82ca713D94bBA7A89CEAB55314F9EfFEdDc78c),
            sett: ISett(0xb9D076fDe463dbc9f915E5392F807315Bf940334)
        });
        pools[3] = Pool({ // Exclusive to wBTC
            lpToken: wbtc,
            deposit: ICurveFi(0x0),
            sett: ISett(0x4b92d19c11435614CD49Af1b589001b7c08cD4D5) // byvWbtc
        });

        // Since we don't hold any tokens in this contract, we can optimize gas usage in mint calls by providing infinite approvals
        for (uint i = 0; i < pools.length; i++) {
            Pool memory pool = pools[i];
            pool.lpToken.safeApprove(address(pool.sett), uint(-1));
            if (i < 3) {
                ren.safeApprove(address(pool.deposit), uint(-1));
                wbtc.safeApprove(address(pool.deposit), uint(-1));
                IERC20(address(pool.sett)).safeApprove(address(settPeak), uint(-1));
            } else {
                IERC20(address(pool.sett)).safeApprove(address(byvWbtcPeak), uint(-1));
            }
        }
        pools[2].lpToken.safeApprove(address(pools[2].deposit), uint(-1));
    }

    /**
    * @notice Mint ibbtc with wBTC / renBTC
    * @param token wBTC or renBTC address
    * @param amount wBTC or renBTC amount
    * @param poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv, 3=yvWbtc
    * @param idx Index of the token in the curve pool while adding liquidity; redundant for yvWbtc
    * @param minOut Minimum amount of ibbtc to mint. Use for capping slippage while adding liquidity to curve pool.
    * @return _ibbtc Minted ibbtc amount
    */
    function mint(IERC20 token, uint amount, uint poolId, uint idx, uint minOut)
        external
        defend
        blockLocked
        whenNotPaused
        returns(uint _ibbtc)
    {
        token.safeTransferFrom(msg.sender, address(this), amount);

        Pool memory pool = pools[poolId];
        if (poolId < 3) { // setts
            _addLiquidity(pool.deposit, amount, poolId + 2, idx); // pools are such that the #tokens they support is +2 from their poolId.
            pool.sett.deposit(pool.lpToken.balanceOf(address(this)));
            _ibbtc = settPeak.mint(poolId, pool.sett.balanceOf(address(this)), new bytes32[](0));
        } else if (poolId == 3) { // byvwbtc
            IbyvWbtc(address(pool.sett)).deposit(new bytes32[](0)); // pulls all available
            _ibbtc = byvWbtcPeak.mint(pool.sett.balanceOf(address(this)), new bytes32[](0));
        } else {
            revert("INVALID_POOL_ID");
        }

        require(_ibbtc >= minOut, "INSUFFICIENT_IBBTC"); // used for capping slippage in curve pools
        ibbtc.safeTransfer(msg.sender, _ibbtc);
    }

    /**
    * @dev Add liquidity to curve btc pools
    * @param amount wBTC / renBTC amount
    * @param pool Curve btc pool
    * @param numTokens # supported tokens for the curve pool
    * @param idx Index of the supported token in the curve pool in question
    */
    function _addLiquidity(ICurveFi pool, uint amount, uint numTokens, uint idx) internal {
        if (numTokens == 2) {
            uint[2] memory amounts;
            amounts[idx] = amount;
            pool.add_liquidity(amounts, 0);
        }

        if (numTokens == 3) {
            uint[3] memory amounts;
            amounts[idx] = amount;
            pool.add_liquidity(amounts, 0);
        }

        if (numTokens == 4) {
            uint[4] memory amounts;
            amounts[idx] = amount;
            pool.add_liquidity(amounts, 0);
        }
    }

    /**
    * @notice Calculate the most optimal route and expected ibbtc amount when minting with wBTC / renBtc.
    * @dev Use returned params poolId, idx and bBTC in the call to mint(...)
           The last param `minOut` in mint(...) should be a bit less than the returned bBTC value.
           For instance 0.2% - 1% lesser depending on slippage tolerange.
    * @param amount renBTC amount
    * @return poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv, 3=byvwbtc
    * @return idx Index of the supported token in the curve pool (poolId). Should be ignored for poolId=3
    * @return bBTC Expected ibbtc. Not for precise calculations. Doesn't factor in (deposit) fee charged by the curve pool / byvwbtc.
    * @return fee Fee being charged by ibbtc system. Denominated in corresponding sett token
    */
    function calcMint(address token, uint amount) external view returns(uint poolId, uint idx, uint bBTC, uint fee) {
        if (token == address(ren)) {
            return calcMintWithRen(amount);
        }
        if (token == address(wbtc)) {
            return calcMintWithWbtc(amount);
        }
        revert("INVALID_TOKEN");
    }

    /**
    * @notice Calculate the most optimal route and expected ibbtc amount when minting with renBTC.
    * @dev Use returned params poolId, idx and bBTC in the call to mint(...)
           The last param `minOut` in mint(...) should be a bit more than the returned bBTC value.
           For instance 0.2% - 1% higher depending on slippage tolerange.
    * @param amount renBTC amount
    * @return poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv
    * @return idx Index of the supported token in the curve pool (poolId)
    * @return bBTC Expected ibbtc. Not for precise calculations. Doesn't factor in fee charged by the curve pool
    * @return fee Fee being charged by ibbtc system. Denominated in corresponding sett token
    */
    function calcMintWithRen(uint amount) public view returns(uint poolId, uint idx, uint bBTC, uint fee) {
        uint _ibbtc;
        uint _fee;

        // poolId=0, idx=0
        (bBTC, fee) = curveLPToIbbtc(0, pools[0].deposit.calc_token_amount([amount,0], true));

        (_ibbtc, _fee) = curveLPToIbbtc(1, pools[1].deposit.calc_token_amount([amount,0,0], true));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 1;
            // idx=0
        }

        (_ibbtc, _fee) = curveLPToIbbtc(2, pools[2].deposit.calc_token_amount([0,amount,0,0], true));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 2;
            idx = 1;
        }
    }

    /**
    * @notice Calculate the most optimal route and expected ibbtc amount when minting with wBTC.
    * @dev Use returned params poolId, idx and bBTC in the call to mint(...)
           The last param `minOut` in mint(...) should be a bit more than the returned bBTC value.
           For instance 0.2% - 1% higher depending on slippage tolerange.
    * @param amount renBTC amount
    * @return poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv, 3=byvwbtc
    * @return idx Index of the supported token in the curve pool (poolId). Should be ignored for poolId=3
    * @return bBTC Expected ibbtc. Not for precise calculations. Doesn't factor in (deposit) fee charged by the curve pool / byvwbtc.
    * @return fee Fee being charged by ibbtc system. Denominated in corresponding sett token
    */
    function calcMintWithWbtc(uint amount) public view returns(uint poolId, uint idx, uint bBTC, uint fee) {
        uint _ibbtc;
        uint _fee;

        // poolId=0
        (bBTC, fee) = curveLPToIbbtc(0, pools[0].deposit.calc_token_amount([0,amount], true));
        idx = 1;

        (_ibbtc, _fee) = curveLPToIbbtc(1, pools[1].deposit.calc_token_amount([0,amount,0], true));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 1;
            // idx=1
        }

        (_ibbtc, _fee) = curveLPToIbbtc(2, pools[2].deposit.calc_token_amount([0,0,amount,0], true));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 2;
            idx = 2;
        }

        // for byvwbtc, sett.pricePerShare returns a wbtc value, as opposed to lpToken amount in setts
        (_ibbtc, _fee) = byvWbtcPeak.calcMint(amount.mul(1e8).div(IbyvWbtc(address(pools[3].sett)).pricePerShare()));
        if (_ibbtc > bBTC) {
            bBTC = _ibbtc;
            fee = _fee;
            poolId = 3;
            // idx value will be ignored anyway
        }
    }

    /**
    * @dev Curve LP token amount to expected ibbtc amount
    */
    function curveLPToIbbtc(uint poolId, uint _lp) public view returns(uint bBTC, uint fee) {
        Pool memory pool = pools[poolId];
        uint _sett = _lp.mul(1e18).div(pool.sett.getPricePerFullShare());
        return settPeak.calcMint(poolId, _sett);
    }

    // Redeem Methods

    function redeem(IERC20 token, uint amount, uint poolId, int128 idx, uint minOut)
        external
        defend
        blockLocked
        whenNotPaused
        returns(uint out)
    {
        ibbtc.safeTransferFrom(msg.sender, address(this), amount);

        Pool memory pool = pools[poolId];
        if (poolId < 3) { // setts
            settPeak.redeem(poolId, amount);
            pool.sett.withdrawAll();
            pool.deposit.remove_liquidity_one_coin(pool.lpToken.balanceOf(address(this)), idx, minOut);
        } else if (poolId == 3) { // byvwbtc
            byvWbtcPeak.redeem(amount);
            IbyvWbtc(address(pool.sett)).withdraw(); // withdraws all available
        } else {
            revert("INVALID_POOL_ID");
        }
        out = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, out);
    }

    /**
    * @notice Calculate the most optimal route and expected token amount when redeeming ibbtc.
    * @dev Use returned params poolId, idx and out in the call to redeem(...)
           The last param `redeem` in mint(...) should be a bit less than the returned `out` value.
           For instance 0.2% - 1% lesser depending on slippage tolerange.
    * @param amount ibbtc amount
    * @return poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv, 3=byvwbtc
    * @return idx Index of the supported token in the curve pool (poolId). Should be ignored for poolId=3
    * @return out Expected amount for token. Not for precise calculations. Doesn't factor in (deposit) fee charged by the curve pool / byvwbtc.
    * @return fee Fee being charged by ibbtc + setts. Denominated in corresponding sett token
    */
    function calcRedeem(address token, uint amount) external view returns(uint poolId, uint idx, uint out, uint fee) {
        if (token == address(ren)) {
            return calcRedeemInRen(amount);
        }
        if (token == address(wbtc)) {
            return calcRedeemInWbtc(amount);
        }
        revert("INVALID_TOKEN");
    }

    /**
    * @notice Calculate the most optimal route and expected renbtc amount when redeeming ibbtc.
    * @dev Use returned params poolId, idx and renAmount in the call to redeem(...)
           The last param `minOut` in redeem(...) should be a bit less than the returned renAmount value.
           For instance 0.2% - 1% lesser depending on slippage tolerange.
    * @param amount ibbtc amount
    * @return poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv
    * @return idx Index of the supported token in the curve pool (poolId)
    * @return renAmount Expected renBtc. Not for precise calculations. Doesn't factor in fee charged by the curve pool
    * @return fee Fee being charged by ibbtc system. Denominated in corresponding sett token
    */
    function calcRedeemInRen(uint amount) public view returns(uint poolId, uint idx, uint renAmount, uint fee) {
        uint _lp;
        uint _fee;
        uint _ren;

        // poolId=0, idx=0
        (_lp, fee) = ibbtcToCurveLP(0, amount);
        renAmount = pools[0].deposit.calc_withdraw_one_coin(_lp, 0);

        (_lp, _fee) = ibbtcToCurveLP(1, amount);
        _ren = pools[1].deposit.calc_withdraw_one_coin(_lp, 0);
        if (_ren > renAmount) {
            renAmount = _ren;
            fee = _fee;
            poolId = 1;
            // idx=0
        }

        (_lp, _fee) = ibbtcToCurveLP(2, amount);
        _ren = pools[2].deposit.calc_withdraw_one_coin(_lp, 1);
        if (_ren > renAmount) {
            renAmount = _ren;
            fee = _fee;
            poolId = 2;
            idx = 1;
        }
    }

    /**
    * @notice Calculate the most optimal route and expected wbtc amount when redeeming ibbtc.
    * @dev Use returned params poolId, idx and wbtc in the call to redeem(...)
           The last param `minOut` in redeem(...) should be a bit less than the returned wbtc value.
           For instance 0.2% - 1% lesser depending on slippage tolerange.
    * @param amount ibbtc amount
    * @return poolId 0=crvRenWBTC, 1=crvRenWSBTC, 2=tbtc-sbtcCrv, 3=byvwbtc
    * @return idx Index of the supported token in the curve pool (poolId)
    * @return wBTCAmount Expected wbtc. Not for precise calculations. Doesn't factor in fee charged by the curve pool
    * @return fee Fee being charged by ibbtc system. Denominated in corresponding sett token
    */
    function calcRedeemInWbtc(uint amount) public view returns(uint poolId, uint idx, uint wBTCAmount, uint fee) {
        uint _lp;
        uint _fee;
        uint _wbtc;

        // poolId=0, idx=0
        (_lp, fee) = ibbtcToCurveLP(0, amount);
        wBTCAmount = pools[0].deposit.calc_withdraw_one_coin(_lp, 1);
        idx = 1;

        (_lp, _fee) = ibbtcToCurveLP(1, amount);
        _wbtc = pools[1].deposit.calc_withdraw_one_coin(_lp, 1);
        if (_wbtc > wBTCAmount) {
            wBTCAmount = _wbtc;
            fee = _fee;
            poolId = 1;
            // idx=1
        }

        (_lp, _fee) = ibbtcToCurveLP(2, amount);
        _wbtc = pools[2].deposit.calc_withdraw_one_coin(_lp, 2);
        if (_wbtc > wBTCAmount) {
            wBTCAmount = _wbtc;
            fee = _fee;
            poolId = 2;
            idx = 2;
        }

        uint _byvWbtc;
        uint _max;
        (_byvWbtc,_fee,_max) = byvWbtcPeak.calcRedeem(amount);
        if (amount <= _max) {
            uint strategyFee = _byvWbtc.mul(pools[3].sett.withdrawalFee()).div(10000);
            _wbtc = _byvWbtc.sub(strategyFee).mul(pools[3].sett.pricePerShare()).div(1e8);
            if (_wbtc > wBTCAmount) {
                wBTCAmount = _wbtc;
                fee = _fee.add(strategyFee);
                poolId = 3;
            }
        }
    }

    function ibbtcToCurveLP(uint poolId, uint bBtc) public view returns(uint lp, uint fee) {
        uint sett;
        uint max;
        (sett,fee,max) = settPeak.calcRedeem(poolId, bBtc);
        Pool memory pool = pools[poolId];
        if (bBtc > max) {
            return (0,fee);
        } else {
            // pesimistically charge 0.5% on the withdrawal.
            // Actual fee might be lesser if the vault keeps keeps a buffer
            uint strategyFee = sett.mul(controller.strategies(pool.lpToken).withdrawalFee()).div(1000);
            lp = sett.sub(strategyFee).mul(pool.sett.getPricePerFullShare()).div(1e18);
            fee = fee.add(strategyFee);
        }
    }

    // Governance controls

    function setGovernance(address _governance) external onlyGovernance {
        _setGovernance(_governance);
    }

    function _setGovernance(address _governance) internal {
        require(_governance != address(0), "NULL_ADDRESS");
        governance = _governance;
    }

    function approveContractAccess(address account) external onlyGovernance {
        _approveContractAccess(account);
    }

    function revokeContractAccess(address account) external onlyGovernance {
        _revokeContractAccess(account);
    }

    function pause() external onlyGovernance {
        _pause();
    }

    function unpause() external onlyGovernance {
        _unpause();
    }
}

interface ICurveFi {
    function add_liquidity(uint[2] calldata amounts, uint min_mint_amount) external;
    function calc_token_amount(uint[2] calldata amounts, bool isDeposit) external view returns(uint);

    function add_liquidity(uint[3] calldata amounts, uint min_mint_amount) external;
    function calc_token_amount(uint[3] calldata amounts, bool isDeposit) external view returns(uint);

    function add_liquidity(uint[4] calldata amounts, uint min_mint_amount) external;
    function calc_token_amount(uint[4] calldata amounts, bool isDeposit) external view returns(uint);

    function remove_liquidity_one_coin(uint _token_amount, int128 i, uint min_amount) external;
    function calc_withdraw_one_coin(uint _token_amount, int128 i) external view returns(uint);
}

interface IStrategy {
    function withdrawalFee() external view returns(uint);
}

interface IController {
    function strategies(IERC20 token) external view returns(IStrategy);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 * 
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 * 
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 * 
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 * 
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     * 
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     * 
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     * 
     * Emits an {AdminChanged} event.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     * 
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal override virtual {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     * 
     * Requirements:
     * 
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     * 
     * Requirements:
     * 
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     * 
     * Requirements:
     * 
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     * 
     * Requirements:
     * 
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     * 
     * Requirements:
     * 
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {GovernableProxy} from "./proxy/GovernableProxy.sol";

contract AccessControlDefendedBase {
    mapping (address => bool) public approved;
    mapping(address => uint256) public blockLock;

    modifier defend() {
        require(msg.sender == tx.origin || approved[msg.sender], "ACCESS_DENIED");
        _;
    }

    modifier blockLocked() {
        require(blockLock[msg.sender] < block.number, "BLOCK_LOCKED");
        _;
    }

    function _lockForBlock(address account) internal {
        blockLock[account] = block.number;
    }

    function _approveContractAccess(address account) internal {
        approved[account] = true;
    }

    function _revokeContractAccess(address account) internal {
        approved[account] = false;
    }
}

contract AccessControlDefended is GovernableProxy, AccessControlDefendedBase {
    uint256[50] private __gap;

    function approveContractAccess(address account) external onlyGovernance {
        _approveContractAccess(account);
    }

    function revokeContractAccess(address account) external onlyGovernance {
        _revokeContractAccess(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISett is IERC20 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _shares) external;
    function withdrawAll() external;
    function approveContractAccess(address account) external;

    function getPricePerFullShare() external view returns (uint256);
    function balance() external view returns (uint256);

    // byvwbtc
    function pricePerShare() external view returns (uint256);
    function withdrawalFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface IPeak {
    function portfolioValue() external view returns (uint);
}

interface IBadgerSettPeak is IPeak {
    function mint(uint poolId, uint inAmount, bytes32[] calldata merkleProof)
        external
        returns(uint outAmount);

    function calcMint(uint poolId, uint inAmount)
        external
        view
        returns(uint bBTC, uint fee);

    function redeem(uint poolId, uint inAmount)
        external
        returns (uint outAmount);

    function calcRedeem(uint poolId, uint bBtc)
        external
        view
        returns(uint sett, uint fee, uint max);
}

interface IByvWbtcPeak is IPeak {
    function mint(uint inAmount, bytes32[] calldata merkleProof)
        external
        returns(uint outAmount);

    function calcMint(uint inAmount)
        external
        view
        returns(uint bBTC, uint fee);

    function redeem(uint inAmount)
        external
        returns (uint outAmount);

    function calcRedeem(uint bBtc)
        external
        view
        returns(uint sett, uint fee, uint max);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IbBTC is IERC20 {
    function mint(address account, uint amount) external;
    function burn(address account, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IbyvWbtc is IERC20 {
    function pricePerShare() external view returns (uint);
    function deposit(bytes32[] calldata merkleProof) external;
    function withdraw() external returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 * 
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     * 
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = _logic.delegatecall(_data);
            require(success);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal override view returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     * 
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 * 
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 * 
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal virtual view returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     * 
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     * 
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

contract GovernableProxy {
    bytes32 constant OWNER_SLOT = keccak256("proxy.owner");

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        _transferOwnership(msg.sender);
    }

    modifier onlyGovernance() {
        require(owner() == msg.sender, "NOT_OWNER");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address _owner) {
        bytes32 position = OWNER_SLOT;
        assembly {
            _owner := sload(position)
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) external onlyGovernance {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "OwnableProxy: new owner is the zero address");
        emit OwnershipTransferred(owner(), newOwner);
        bytes32 position = OWNER_SLOT;
        assembly {
            sstore(position, newOwner)
        }
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}