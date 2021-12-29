// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Router.sol";
import "./ICollateralReserveV2Calc.sol";


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
    function withdraw(uint256) external;
    function balanceOf(address account) external view returns (uint256);
}

interface IGateV1 {
    function unclaimed_pool_share() view external returns(uint256);
    function unclaimed_pool_collateral() view external returns(uint256);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IBooMirrorWorld {
    function leave(uint256 _share) external;
    function enter(uint256 _amount)external;
    function balanceOf(address account) external view returns (uint256);
    function xBOOForBOO(uint256 _xBOOAmount) external view returns (uint256 booAmount_);
}

interface ICoffinTheOtherWorld{
    function stake(uint256 _amount) external ;
    function xcoffin() external view returns(address);
    function COFFINForxCOFFIN(uint256 _coffinAmount) external view returns (uint256 xCOFFINAmount_);
}

interface IXCoffin{
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}


interface IyvToken{
    function deposit(uint256 _amount) external;
    function deposit(uint256 _amount, address _recipient) external;
    function withdraw(uint256 _amount) external;
    function withdraw(uint256 _amount, address _recipient) external;
    function balanceOf(address account) external view returns (uint256);
}

interface IDollar {
    function pool_burn_from(address addr, uint256 amount)external;
    function pool_mint(address addr, uint256 amount)external;
    function burnFrom(address addr, uint256 amount)external;
    function totalSupply() external view returns (uint256) ;
}


contract CollateralReserveV2TEST is Ownable{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public manager;
    address public buyback_manager;

    uint256 private constant LIMIT_SWAP_TIME = 10 minutes;


    // // collaterals
    address[] public collaterals;
    mapping(address => bool) public isCollateral;
    mapping(address => bool) public acceptDeposit;
    mapping(address=>bool) public isDepositor;
    // address[] public depositors;

    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

    // oracles
    mapping(address=>address) public collateralCalc;
    //
    uint256 private constant PRICE_PRECISION = 1e6;

    //wftm
    address public wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    //
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address public xboo = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
    address public boo  = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;

    address public coffin;
    address public cousd;
    //
    address public gatev1;
    address public gatev2;
    address public reserveV1;

    //
    address xcoffin = 0xc8a0a1b63F65C53F565ddDB7fbcfdd2eaBE868ED;

    address public coffintheotherworld = 0x5e082C23d1c70466c518306320e4927ea4A844B4;
    address private boomirrorworld = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;

    receive() external payable {
        IWETH(wftm).deposit{value: msg.value}();
    }

    // router address. it's spooky router by default.
    address private spookyRouterAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;
    address private morpheusswapRouterAddress = 0x8aC868293D97761A1fED6d4A01E9FF17C5594Aa3;

    constructor() {

        // gateV1/PROD
        gatev1 = address(0x98e119990E3653486d84Ba46b66BbC4d82f7f604);
        // gateV1/TEST
        // gatev1 = address(0x5d77a7efDd038eb701eB44F2fb47FBEb4D4025B0);

        // reserveV1/PROD
        reserveV1 = address(0x61Befe6E5f20217960bD8659cd3113CC1ca67d2F);
        // reserveV1/TEST
        // reserveV1 = address(0xc0f00b8FB1e95336D2f831fAFB594d0E53331071);

        // coffin(prod
        coffin = address(0x593Ab53baFfaF1E821845cf7080428366F030a9c); // coffin
        // coffin(test
        // coffin = address(0x894c3A00a4b1FF104401DD8f116d9C3E97dd9684); // test coffin

        // cousd prod
        cousd = address(0x0DeF844ED26409C5C46dda124ec28fb064D90D27); // dollar
        // cousd test
        // cousd = address(0xA51a63261A7dfdc7eD1E480223C2f705b9CbEE6F); // test dollar

        // msg.sender by default
        setManager(msg.sender);
        setBuybackManager(msg.sender);
        setGateV2(msg.sender);

    }

    /* ========== MODIFIER ========== */

    modifier onlyGate() {
        require( gatev2 == msg.sender|| gatev1 == msg.sender, "Only gate can trigger this function");
        _;
    }

    modifier onlyOwnerOrManager() {
        require(owner() == msg.sender || manager == msg.sender, "Only owner or manager can trigger this function");
        _;
    }

    modifier onlyBuybackManagerOrOwner() {
        require( owner() == msg.sender || buyback_manager == msg.sender,
            "Only owner or buyback_manager can trigger this function");
        _;
    }
    modifier onlyBuybackManagerOrOwnerOrGate() {
        require( owner() == msg.sender || gatev2 == msg.sender || buyback_manager == msg.sender,
            "Only owner or buyback_manager or Gate can trigger this function");
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function transferWftmTO(
        address _receiver,
        uint256 _amount
    ) public onlyGate {
        transferTo(wftm, _receiver, _amount);
    }

    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) public onlyGate {
        require(_receiver != address(0), "Invalid address");
        require(_amount > 0, "Cannot transfer zero amount");
        IERC20(_token).safeTransfer(_receiver, _amount);
        emit Transfer(msg.sender, _token, _receiver, _amount);
    }

    function setReserveV1(address _reserveV1) public onlyOwner {
        reserveV1 = _reserveV1;
        emit ReserveChangeV1(_reserveV1);
    }
    function setGateV2(address _gate) public onlyOwner {
        require(_gate != address(0), "Invalid address");
        gatev2 = _gate;
        emit GateChangedV2(_gate);
    }

    function setGateV1(address _gate) public onlyOwner {
        require(_gate != address(0), "Invalid address");
        gatev1 = _gate;
        emit GateChangedV1(_gate);
    }

    function setManager(address _manager) public onlyOwner {
        require(_manager != address(0), "Invalid address");
        manager = _manager;
    }

    function setBuybackManager(address _buyback_manager) public onlyOwner {
        require(_buyback_manager != address(0), "Invalid address");
        buyback_manager = _buyback_manager;
    }

    function deposit( uint _amount, address _token, uint _out ) external  {
        require( isCollateral[ _token ], "Not accepted" );
        require( acceptDeposit[ _token ], "Not accepted to deposit for now " );
        require( isDepositor[ msg.sender ], "Not approved" );
        IERC20( _token ).safeTransferFrom( msg.sender, address(this), _amount );
        IDollar( cousd ).pool_mint( msg.sender, _out );
        emit Deposit( _token, _amount, _out );
    }

    function disableDepositToken(address _token) external onlyOwner{
        acceptDeposit[_token] = false;
        emit DisableDepositToken(_token);
    }
    function enableDepositToken(address _token) external onlyOwner{
        acceptDeposit[_token] = true;
        emit EnableDepositToken(_token);
    }

    function addDepositor(address addr) external onlyOwner{
        isDepositor[addr] = true;
        emit AddDepositor(addr);
    }

    function removeDepositor(address addr) external onlyOwner{
        delete isDepositor[addr];
        emit RemoveDepositor(addr);
    }

    // add a collatereal
    function addCollateral(address _token, ICollateralReserveV2Calc _token_oracle) public onlyOwner{
        require(_token != address(0), "invalid token");
        require(address(_token_oracle) != address(0), "invalid token");

        isCollateral[_token] = true;
        // acceptDeposit[_token] = true;
        collateralCalc[_token] = address(_token_oracle);
        if( !listContains( collaterals, _token ) ) {
            collaterals.push(_token);
        }
        emit CollateralAdded(_token);
    }

    // Remove a collatereal
    function removeCollateral(address _token) public onlyOwner {
        require(_token != address(0), "invalid token");
        // Delete from the mapping
        delete collateralCalc[_token];
        delete isCollateral[_token];
        delete acceptDeposit[_token];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < collaterals.length; i++){
            if (collaterals[i] == _token) {
                // coffin_pools_array[i] = address(0);
                // This will leave a null in the array and keep the indices the same
                delete collaterals[i];
                break;
            }
        }
        emit CollateralRemoved(_token);
    }

    // // buyback coffin
    function buyBackCoffin(uint _amount, uint _min) public onlyBuybackManagerOrOwner {
        require(coffin!=address(0), "coffin address error");
        rebalance(wftm, coffin, _amount, _min, true, spookyRouterAddress);
    }

    // buyback cousd
    function buyBackCoUSDwithUSDC(uint _amount, uint _min) public onlyBuybackManagerOrOwner {
        require(cousd!=address(0), "cousd address error");
        rebalance(usdc, cousd, _amount, _min, true, spookyRouterAddress);
    }

    function stakeBOO(uint _amount) public onlyOwnerOrManager {
        require(boomirrorworld!=address(0), "boomirrorworld address error");
        require(_amount!=0, "amount error");
        IERC20(boo).approve(address(boomirrorworld), 0);
        IERC20(boo).approve(address(boomirrorworld), _amount);
        IBooMirrorWorld(boomirrorworld).enter(_amount);
    }

    function unstakeXBOO(uint _amount) public onlyOwnerOrManager {
        require(boomirrorworld!=address(0), "boomirrorworld address error");
        require(_amount!=0, "amount error");
        IERC20(xboo).approve(address(boomirrorworld), 0);
        IERC20(xboo).approve(address(boomirrorworld), _amount);
        IBooMirrorWorld(boomirrorworld).leave(_amount);
    }


    function yvDeposit(address _token0, address _token1, uint _amount) public onlyOwnerOrManager {
        IERC20(_token0).approve(address(_token1), 0);
        IERC20(_token0).approve(address(_token1), _amount);
        IyvToken(address(_token1)).deposit(_amount);
    }
    function yvWithdraw(address _token, uint _amount) public onlyOwnerOrManager {
        IERC20(_token).approve(address(_token), 0);
        IERC20(_token).approve(address(_token), _amount);
        IyvToken(address(_token)).withdraw(_amount);
    }


    function stakeCoffin(uint _amount) public onlyBuybackManagerOrOwnerOrGate {
        require(coffin!=address(0), "coffin address error");
        require(coffintheotherworld!=address(0), "coffintheotherworld address error");
        require(_amount!=0, "amount error");
        IERC20(coffin).approve(address(coffintheotherworld), 0);
        IERC20(coffin).approve(address(coffintheotherworld), _amount);
        ICoffinTheOtherWorld(coffintheotherworld).stake(_amount);
    }

    // burn xcoffin by coffin
    function burnXCoffinByCoffin(uint _coffin_ammount) public onlyBuybackManagerOrOwnerOrGate {
        require(coffin!=address(0), "coffin address error");
        require(coffintheotherworld!=address(0), "coffintheotherworld address error");
        require(_coffin_ammount!=0, "amount error");
        uint256 xcoffinAmmount = ICoffinTheOtherWorld(coffintheotherworld).COFFINForxCOFFIN(_coffin_ammount);
        uint256 balance = IXCoffin(ICoffinTheOtherWorld(coffintheotherworld).xcoffin()).balanceOf(address(this));
        if (xcoffinAmmount>balance) {
            xcoffinAmmount = balance;
        }
        IXCoffin(ICoffinTheOtherWorld(coffintheotherworld).xcoffin()).burn(xcoffinAmmount);
    }


    // burn xcoffin
    function burnXCoffin(uint _amount) public onlyBuybackManagerOrOwnerOrGate {
        require(coffintheotherworld!=address(0), "coffin address error");
        IXCoffin(ICoffinTheOtherWorld(coffintheotherworld).xcoffin()).burn(_amount);
    }

    function rebalance(
            address token0,
            address token1,
            uint256 _amount,
            uint256 _min_output_amount,
            bool nocheckcollateral,
            address routerAddress
    ) public onlyOwnerOrManager
    {
        if (!nocheckcollateral) {
            require(isCollateral[token0] == true, "not support it as collateral.");
            require(isCollateral[token1] == true, "not collateral token");
        }
        IERC20(token0).approve(address(routerAddress), 0);
        IERC20(token0).approve(address(routerAddress), _amount);


        address[] memory router_path = new address[](2);
        router_path[0] = token0;
        router_path[1] = token1;

        uint256[] memory _received_amounts
            = IUniswapV2Router(routerAddress).swapExactTokensForTokens(_amount,
            _min_output_amount, router_path, address(this), block.timestamp + LIMIT_SWAP_TIME);

        require(_received_amounts[_received_amounts.length - 1] >= _min_output_amount, "Slippage limit reached");

        emit Rebalance(token0,token1,_amount,
            _min_output_amount, _received_amounts[_received_amounts.length - 1]);
    }


    function createLiquidity(
        address token0,
        address token1,
        uint256 amtToken0,
        uint256 amtToken1,
        uint256 minToken0,
        uint256 minToken1,
        address routerAddrsss
    )
        public
        onlyOwnerOrManager
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(amtToken0 != 0 && amtToken1 != 0, "amounts can't be 0");

        IERC20(token0).approve(address(routerAddrsss), 0);
        IERC20(token0).approve(address(routerAddrsss), amtToken0);

        IERC20(token1).approve(address(routerAddrsss), 0);
        IERC20(token1).approve(address(routerAddrsss), amtToken1);


        uint256 resultAmtToken0;
        uint256 resultAmtToken1;
        uint256 liquidity;

        (resultAmtToken0, resultAmtToken1, liquidity) = IUniswapV2Router(routerAddrsss).addLiquidity(
            token0,
            token1,
            amtToken0,
            amtToken1,
            minToken0,
            minToken1,
            address(this),
            block.timestamp + LIMIT_SWAP_TIME
        );
        return (resultAmtToken0, resultAmtToken1, liquidity);
    }


    function removeLiquidity(
        address token0,
        address token1,
        uint liquidity,
        uint256 minToken0,
        uint256 minToken1,
        address routerAddrsss
    )
        public
        onlyOwnerOrManager
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(minToken0 != 0 && minToken1 != 0, " can't be 0");

        address pair = IUniswapV2Factory(IUniswapV2Router(routerAddrsss).factory()).getPair(token0, token1);

        IERC20(pair).approve(address(routerAddrsss), 0);
        IERC20(pair).approve(address(routerAddrsss), liquidity);

        uint256 resultAmtToken0;
        uint256 resultAmtToken1;

        (resultAmtToken0, resultAmtToken1) = IUniswapV2Router(routerAddrsss).removeLiquidity(
            token0,
            token1,
            liquidity,
            minToken0,
            minToken1,
            address(this),
            block.timestamp + LIMIT_SWAP_TIME
        );
        emit CreateLiquidy( token0,  token1,  liquidity );
        return (resultAmtToken0, resultAmtToken1, liquidity);
    }

    /* ========== INTERNAL FUNCTIONS ========== */
    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains( address[] storage _list, address _token ) internal view returns ( bool ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return true;
            }
        }
        return false;
    }

    /* ========== PUBLIC FUNCTIONS ========== */


    function excessReserves() public view returns ( uint ) {
        return getTotalCollateralValue().sub( IERC20( cousd ).totalSupply());
    }

    // function v1Debt() public view returns ( uint ) {
    //     return IGateV1(gatev1).unclaimed_pool_collateral();
    // }


    function getTotalCollateralValue() public view  returns (uint256) {
        uint256 val = 0;
        for (uint i = 0; i < collaterals.length; i++){
            if (address(collaterals[i])!=address(0)
                &&
                collateralCalc[collaterals[i]]!=address(0))
            {
                val += getCollateralValue(collaterals[i]);
            }
        }
        if (val>v1Debt()) {
            val = val.sub(v1Debt());
        }
        return val;
    }


    function getActualCollateralValue() public view  returns (uint256) {
        uint256 val = 0;
        for (uint i = 0; i < collaterals.length; i++){
            if (address(collaterals[i])!=address(0)
                &&
                collateralCalc[collaterals[i]]!=address(0)
                && address(collaterals[i])!=coffin
                && address(collaterals[i])!=xcoffin
                && address(collaterals[i])!=cousd
                && collateralCalc[collaterals[i]]!=address(0)
            )
            {
                val += getCollateralValue(collaterals[i]);
            }
        }

        if (val>v1Debt()) {
            val = val.sub(v1Debt());
        }
        return val;
    }


    function dollarSupply() public view returns(uint) {
        return IERC20( cousd ).totalSupply();
    }

    function getActualCollateralRatio() public view  returns(uint256 acr) {
        uint _collateral_value = getActualCollateralValue();
        uint total_supply_dollar = dollarSupply();

        if (total_supply_dollar == 0) {
            return COLLATERAL_RATIO_MAX;
        }
        if (_collateral_value == 0) {
            return 0;
        }
        //  6 decimal
        acr = _collateral_value.mul(1e6).div(total_supply_dollar);
    }

    function getEffectiveCollateralRatio() public view  returns(uint256 ecr) {
        ecr = getActualCollateralRatio();
        if (ecr > COLLATERAL_RATIO_MAX) {
            ecr = COLLATERAL_RATIO_MAX;
        }
        return ecr;
    }

    // 18 decimals
    function getCollateralValue(address _token) public view  returns (uint256) {
        require(address(collateralCalc[_token])!=address(0), "err0");
        return getCollateralBalance(_token).mul(getCollateralPrice(_token)).div(1e6) ;
    }

    // 18 decimals
    function getValue(address _token, uint256 _amt) public view  returns (uint256) {
        require(address(collateralCalc[_token])!=address(0), "err0");
        return _amt.mul(getCollateralPrice(_token)).div(1e6);
    }

    // 18 decimals
    function valueOf( address _token, uint _amount ) public view returns ( uint value_ ) {
        value_ = 0;
        try ICollateralReserveV2Calc( collateralCalc[ _token ] ).valuation(  _amount ) returns (uint v) {
            value_ = v;
        } catch Error(string memory /*reason*/) {
            value_ =  0;
        }
    }

    function v1Debt() public view returns ( uint ) {
        uint v1debut_amount = IGateV1(gatev1).unclaimed_pool_collateral();
        try ICollateralReserveV2Calc( collateralCalc[ wftm ] ).valuation(  v1debut_amount ) returns (uint v) {
            return v;
        } catch Error(string memory /*reason*/) {
            return 0;
        }
        // return 0;
    }

    // // 6 decimals
    function getCollateralPrice(address _token) public view  returns (uint256) {
        require(address(collateralCalc[_token])!=address(0), "err0");
        try ICollateralReserveV2Calc(collateralCalc[_token]).getPrice() returns ( uint256 price, uint8 d ) {
            return price.mul(PRICE_PRECISION).div(10**d);
        } catch Error(string memory /*reason*/) {
            return 0;
        }
    }

    function getCollateralBalance(address _token) public view  returns (uint256) {
        require(address(_token)!=address(0), "err1");
        try ERC20(_token).decimals() returns (uint8 d) {
            uint256 missing_decimals = 18 - uint256(d);
            try IERC20(_token).balanceOf(address(this)) returns ( uint256 balanceV2 ) {
                uint256 balanceV1 = 0;
                if (reserveV1!=address(0)) {
                    balanceV1 = IERC20(_token).balanceOf(address(reserveV1));
                }
                return (balanceV2.add(balanceV1)).mul(10**missing_decimals);
            } catch Error(string memory /*reason*/) {
                return 0;
            }
        } catch Error(string memory /*reason*/) {
            return 0;
        }
    }
    /* ========== EVENTS  ========== */

    event GateChangedV1(address indexed _gate);
    event GateChangedV2(address indexed _gate);
    event ReserveChangeV1(address indexed _reserve);

    event Transfer(address se, address indexed token, address indexed receiver, uint256 amount);
    event Rebalance(address _from_address,address _to_address,
        uint256 _amount, uint256 _min_output_amount,uint256 _received_amount);

    event CollateralRemoved(address  _token);
    event CollateralAdded(address  _token);

    event CreateLiquidy(address token0, address token1, uint liquidity );
    event ReservesUpdated( uint indexed totalReserves );
    event RemoveLiquidy(address token0, address token1, uint liquidity );
    event Deposit( address indexed token, uint amount, uint out );

    event RemoveDepositor(address  addr );
    event AddDepositor(address  addr );
    event DisableDepositToken(address  addr );
    event EnableDepositToken(address  addr );

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

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

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


interface ICollateralReserveV2Calc{
    function getPrice() external view returns (uint256, uint8);
    function valuation( uint amount_ ) external view returns ( uint _value );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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