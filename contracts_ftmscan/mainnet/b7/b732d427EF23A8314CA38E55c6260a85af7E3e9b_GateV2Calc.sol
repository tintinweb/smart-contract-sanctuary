// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

// import "./interfaces/IPoolToken.sol";
// import "./CoffinOracle.sol";
// import "./interfaces/IGatePolicy.sol";

// import "./interfaces/IGate.sol";
// import "./interfaces/ICollateralReserve.sol";
// import "./interfaces/IWETH.sol";

interface ITokenOracle {
    function getPrice() external view returns (uint256, uint8);
}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view  returns (uint8) ;

}

contract GateV2Calc is Ownable {
    // using SafeERC20 for ERC20;
    using SafeMath for uint256;
    // using Address for address;

    // address public oracle;
    // address public collateral;
    // address public dollar;
    // address public policy;
    // address public share;

    address public collateralReserveV2 = 0x624135E0756FF780757fdcc60b2EB42c0AaB16a8; // bydefault
    // address public coffin = 0x593Ab53baFfaF1E821845cf7080428366F030a9c; // coffin
    // address public dollar = 0x0DeF844ED26409C5C46dda124ec28fb064D90D27; // dollar 
    // address public policy = 0x226E0FC82Bcf38a0DA32999AD5CdFC40a71903bd; // policy 
    // address public oracle = 0x605ce7209B6811c1892Ae18Cfa6595bA1462C403; // oracle 



    //wftm
    address public wftm = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    //
    address public usdc = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public dai = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address public mim = 0x82f0B8B456c1A451378467398982d4834b6829c1;
    address public wmemo = 0xDDc0385169797937066bBd8EF409b5B3c0dFEB52;
    address public weth = 0x74b23882a30290451A17c44f4F05243b6b58C76d;
    address public yvdai = 0x637eC617c86D24E421328e6CAEa1d92114892439;
    address public xboo = 0xa48d959AE2E88f1dAA7D5F611E01908106dE7598;
    address public yvusdc = 0xEF0210eB96c7EB36AF8ed1c20306462764935607;
    


    // mapping(address => uint256) public redeem_share_balances;
    // mapping(address => uint256) public redeem_collateral_balances;

    // uint256 public override unclaimed_pool_collateral;
    // uint256 public unclaimed_pool_share;

    // mapping(address => uint256) public last_redeemed;
    // mapping(address => uint256) public time_of_redemptions;
    

    // // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    // uint256 private constant RATIO_PRECISION = 1e6;

    // uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    // uint256 private constant COLLATERAL_RATIO_MAX = 1e6;
    // uint256 private constant LIMIT_SWAP_TIME = 10 minutes;
    
    // 

    // // wrapped ftm
    // address private wftmAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;

    // uint256 private missing_decimals;

    // // AccessControl state variables
    // bool public mint_paused = false;
    // bool public redeem_paused = false;
    
    // router address. it's spooky router by default. 
    // address routerAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;

        
    /* ========== MODIFIERS ========== */

    // modifier notContract() {
    //     require(!msg.sender.isContract(), "Allow non-contract only");
    //     _;
    // }

    /* ========== CONSTRUCTOR ========== */

    constructor(){

        // addCollateral(dai);
        // addCollateral(wftm);
        // // addCollateralToken(weth);
        // addCollateral(usdc);
    }
    address[] public collaterals;
    mapping(address=>address) public collateralOracles;

    // add a collatereal 
    function addCollateral(address _token, ITokenOracle _token_oracle) public onlyOwner{
        require(_token != address(0), "invalid token");
        require(address(_token_oracle) != address(0), "invalid token");
        if (collateralOracles[_token] != address(0)) {
            // aready;
            return;
        }
        collateralOracles[_token] = address(_token_oracle);
        collaterals.push(_token);

        emit CollateralAdded(_token);
    }
    // Remove a collatereal 
    function removeCollateral(address _token) public onlyOwner {
        require(_token != address(0), "invalid token");
        // Delete from the mapping
        delete collateralOracles[_token];

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
    
    event CollateralRemoved(address _token);
    event CollateralAdded(address _token);
    function getGlobalCollateralValue() public view  returns (uint256) {
        uint256 val = 0;
        for (uint i = 0; i < collaterals.length; i++){ 
            if (address(collaterals[i])!=address(0)
                &&
                collateralOracles[collaterals[i]]!=address(collateralOracles[collaterals[i]]))
            {
                // ITokenOracle(collateralOracles[collaterals[i]]).getPrice()
                val += getCollateralValue(collaterals[i]);
            }
        }
        return val;
        // require(address(collateralOracles[_token])!=address(0), "err0");
        // ( uint256 price, uint8 d ) = ITokenOracle(collateralOracles[_token]).getPrice();
        // return getCollateralBalance(_token).mul(price).div(10**d);
    }

    function getCollateralValue(address _token) public view  returns (uint256) {
        require(address(collateralOracles[_token])!=address(0), "err0");
        // ( uint256 price, uint8 d ) = ITokenOracle(collateralOracles[_token]).getPrice();
        return getCollateralBalance(_token).mul(getCollateralPrice(_token));
    }

    function getCollateralPrice(address _token) public view  returns (uint256) {
        require(address(collateralOracles[_token])!=address(0), "err0");
        ( uint256 price, uint8 d ) = ITokenOracle(collateralOracles[_token]).getPrice();
        return price.mul(PRICE_PRECISION).div(10**d);
    }
    function getCollateralBalance(address _token) public view  returns (uint256) {
        require(address(_token)!=address(0), "err1");
        uint256 missing_decimals = 18 - IERC20(_token).decimals();
        // return IERC20(_token).balanceOf(address(this)).mul(10**missing_decimals);
        return IERC20(_token).balanceOf(address(collateralReserveV2)).mul(10**missing_decimals);
    }

    // function globalCollateralValue() public view override returns (uint256) {
    //     return (globalCollateralBalance() * getCollateralPrice() * (10**missing_decimals)) / PRICE_PRECISION;
    // }    
    // /* ========== VIEWS ========== */

    // function getCollateralPrice() public view override returns (uint256) {
    //     (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getFTMUSD();
    //     return __price.mul(PRICE_PRECISION).div(10**__d);
    // }

    // function getDollarPrice() public view override returns (uint256) {
    //     (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getCOUSDUSD();
    //     return __price.mul(PRICE_PRECISION).div(10**__d);
    // }

    // function getCoffinPrice() public view override returns (uint256) {
    //     (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getCOFFINUSD();
    //     return __price.mul(PRICE_PRECISION).div(10**__d);
    // }

    // function getDollarTwap() public view override returns (uint256) {
    //     (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getTwapCOUSDUSD();
    //     return __price.mul(PRICE_PRECISION).div(10**__d);
    // }

    // function getCoffinTwap() public view override returns (uint256) {
    //     (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getTwapCOFFINUSD();
    //     return __price.mul(PRICE_PRECISION).div(10**__d);
    // }

    /* ========== PUBLIC FUNCTIONS ========== */

    // function gateInfo()
    //     public
    //     view
    //     returns (
    //         uint256 _minting_fee,
    //         uint256 _redemption_fee,
    //         uint256 _ex_red_fee,
    //         uint256 _collateral_price,
    //         uint256 _share_price,
    //         uint256 _dollar_price,
    //         uint256 _share_twap,
    //         uint256 _dollar_twap,
    //         // uint256 _ecr,
    //         uint256 _tcr,
    //         bool _mint_paused,
    //         bool _redeem_paused,
    //         uint256 _unclaimed_pool_collateral,
    //         uint256 _unclaimed_pool_share
    //     )
    // {
    //     _minting_fee = IGatePolicy(policy).minting_fee();
    //     _redemption_fee = IGatePolicy(policy).redemption_fee();
    //     _ex_red_fee = IGatePolicy(policy).extra_redemption_fee();
    //     _collateral_price = getCollateralPrice();
    //     _share_price = getCoffinPrice();
    //     _dollar_price = getDollarPrice();
    //     _share_twap = getCoffinTwap();
    //     _dollar_twap = getDollarTwap();

    //     _tcr = IGatePolicy(policy).target_collateral_ratio();
    //     // _ecr = IGatePolicy(policy).getEffectiveCollateralRatio();

    //     _mint_paused = mint_paused;
    //     _redeem_paused = redeem_paused;

    //     _unclaimed_pool_collateral = unclaimed_pool_collateral;
    //     _unclaimed_pool_share = unclaimed_pool_share;

    // }

    // function setWFTMAddress(address adr) external onlyOwner {
    //     wftmAddress = adr;
    // }

    receive() external payable {
        payable(collateralReserveV2).transfer(msg.value);
    }

    // function rescueFund() external onlyOwner {
    //     uint256 amount = ERC20(collateral).balanceOf(collateralReserve);
    //     _requestTransferCollateralFTM(msg.sender, amount);
    // }

    // uint period = 6 hours; 
    // uint redeem_count =0;  
    // uint limitation_by_address_daily = 500;
    // uint period_limit = 5000;
    // uint last_redeem = 0;
    // bool public twap_for_redeem = false;
    

    // function newRedeem(
    //     uint256 _dollar_amount,
    //     uint256 _share_out_min,
    //     uint256 _collateral_out_min
    // ) external nonReentrant {

    //     require(redeem_paused == false, "Redemption is paused");

    //     last_redeem = block.timestamp;
    //     // 
    //     uint256 _share_price = 0;
    //     uint256 _dollar_price = 0;
    //     if (twap_for_redeem) { 
    //         _share_price = getCoffinTwap();
    //         _dollar_price = getDollarTwap();
    //     }
    //     if (_share_price==0 ) {
    //         _share_price = getCoffinPrice();
    //     }
    //     if (_dollar_price==0) {
    //         _dollar_price = getDollarPrice();
    //     }

    //     uint256 _redemption_fee = IGatePolicy(policy).redemption_fee();
    //     uint256 extra_redemption_fee = IGatePolicy(policy).extra_redemption_fee();
    //     uint256 price_target = IGatePolicy(policy).price_target();

    //     // uint256 _redemption_fee = redemption_fee;
    //     if (_dollar_price < price_target) {
    //         _redemption_fee += extra_redemption_fee;
    //     }

    //     // uint256 _ecr = Collateral(calcu).getEffectiveCollateralRatio();

    //     uint256 _collateral_price = getCollateralPrice();
    //     require(_collateral_price > 0, "Invalid collateral price");
    //     require(_share_price > 0, "Invalid share price");
    //     uint256 _dollar_amount_post_fee = _dollar_amount - ((_dollar_amount * _redemption_fee) / PRICE_PRECISION);
    //     uint256 _collateral_output_amount = 0;
    //     uint256 _share_output_amount = 0;

    //     if (_ecr < COLLATERAL_RATIO_MAX) {
    //         uint256 _share_output_value 
    //             = _dollar_amount_post_fee - ((_dollar_amount_post_fee * _ecr) / PRICE_PRECISION);
    //         _share_output_amount 
    //             = (_share_output_value * PRICE_PRECISION) / _share_price;
    //     }

    //     if (_ecr > 0) {
    //         uint256 _collateral_output_value 
    //             = ((_dollar_amount_post_fee * _ecr) / PRICE_PRECISION) / (10**missing_decimals);
    //         _collateral_output_amount 
    //             = (_collateral_output_value * PRICE_PRECISION) / _collateral_price;
    //     }

    //     // Check if collateral balance meets and meet output expectation
    //     uint256 _totalCollateralBalance = globalCollateralBalance();
    //     require(_collateral_output_amount <= _totalCollateralBalance, "<collateralBalance");
    //     require(_collateral_out_min <= _collateral_output_amount , ">> slippage than expected...");
    //     require(_share_out_min <= _share_output_amount, ">> slippage than expected......");

    //     if (_collateral_output_amount > 0) {
    //         redeem_collateral_balances[msg.sender] 
    //= redeem_collateral_balances[msg.sender] + _collateral_output_amount;
    //         unclaimed_pool_collateral = unclaimed_pool_collateral + _collateral_output_amount;
    //     }
        
    //     if (_share_output_amount > 0) {
    //         redeem_share_balances[msg.sender] = redeem_share_balances[msg.sender] + _share_output_amount;
    //         unclaimed_pool_share = unclaimed_pool_share + _share_output_amount;
    //     }

    //     // last_redeemed[msg.sender] = block.timestamp;
    //     time_of_redemptions[msg.sender] = block.timestamp + redemption_delay;

    //     uint256 dollar_amount = _dollar_amount;
    //     IPoolToken(dollar).pool_burn_from(msg.sender, dollar_amount);
    //     if (_share_output_amount > 0) {
    //         _mintShareToCollateralReserve(_share_output_amount);
    //     }
    // }
    // // function redeem(
    // //     uint256 _dollar_amount,
    // //     uint256 _share_out_min,
    // //     uint256 _collateral_out_min
    // // ) external nonReentrant {
    // //     require(redeem_paused == false, "Redemption is paused");

    // //     // 
    // //     uint256 _share_price = 0;
    // //     uint256 _dollar_price = 0;
    // //     if (twap_for_redeem) { 
    // //         _share_price = getCoffinTwap();
    // //         _dollar_price = getDollarTwap();
    // //     }
    // //     if (_share_price==0 ) {
    // //         _share_price = getCoffinPrice();
    // //     }
    // //     if (_dollar_price==0) {
    // //         _dollar_price = getDollarPrice();
    // //     }

    // //     uint256 _redemption_fee = IGatePolicy(policy).redemption_fee();
    // //     uint256 extra_redemption_fee = IGatePolicy(policy).extra_redemption_fee();
    // //     uint256 price_target = IGatePolicy(policy).price_target();

    // //     // uint256 _redemption_fee = redemption_fee;
    // //     if (_dollar_price < price_target) {
    // //         _redemption_fee += extra_redemption_fee;
    // //     }

    // //     uint256 _ecr = Collateral(calcu).getEffectiveCollateralRatio();

    // //     uint256 _collateral_price = getCollateralPrice();
    // //     require(_collateral_price > 0, "Invalid collateral price");
    // //     require(_share_price > 0, "Invalid share price");
    // //     uint256 _dollar_amount_post_fee = _dollar_amount - ((_dollar_amount * _redemption_fee) / PRICE_PRECISION);
    // //     uint256 _collateral_output_amount = 0;
    // //     uint256 _share_output_amount = 0;

    // //     if (_ecr < COLLATERAL_RATIO_MAX) {
    // //         uint256 _share_output_value 
    // //             = _dollar_amount_post_fee - ((_dollar_amount_post_fee * _ecr) / PRICE_PRECISION);
    // //         _share_output_amount 
    // //             = (_share_output_value * PRICE_PRECISION) / _share_price;
    // //     }

    // //     if (_ecr > 0) {
    // //         uint256 _collateral_output_value 
    // //             = ((_dollar_amount_post_fee * _ecr) / PRICE_PRECISION) / (10**missing_decimals);
    // //         _collateral_output_amount 
    // //             = (_collateral_output_value * PRICE_PRECISION) / _collateral_price;
    // //     }

    // //     // Check if collateral balance meets and meet output expectation
    // //     uint256 _totalCollateralBalance = globalCollateralBalance();
    // //     require(_collateral_output_amount <= _totalCollateralBalance, "<collateralBalance");
    // //     require(_collateral_out_min <= _collateral_output_amount , ">> slippage than expected...");
    // //     require(_share_out_min <= _share_output_amount, ">> slippage than expected......");

    // //     if (_collateral_output_amount > 0) {
    // //         redeem_collateral_balances[msg.sender] = 
    // // redeem_collateral_balances[msg.sender] + _collateral_output_amount;
    // //         unclaimed_pool_collateral = unclaimed_pool_collateral + _collateral_output_amount;
    // //     }
        
    // //     if (_share_output_amount > 0) {
    // //         redeem_share_balances[msg.sender] = redeem_share_balances[msg.sender] + _share_output_amount;
    // //         unclaimed_pool_share = unclaimed_pool_share + _share_output_amount;
    // //     }

    // //     last_redeemed[msg.sender] = block.timestamp;

    // //     uint256 dollar_amount = _dollar_amount;
    // //     IPoolToken(dollar).pool_burn_from(msg.sender, dollar_amount);
    // //     if (_share_output_amount > 0) {
    // //         _mintShareToCollateralReserve(_share_output_amount);
    // //     }
    // // }

    // uint redemption_delay = 2 days; 
    // function setRedemptionDelay(uint _delay) external onlyOwner {
    //     require ( _delay< 14 days, "_delay too long");
    //     redemption_delay = _delay;
    // }

    // function collectRedemption() external nonReentrant {
    //     require(time_of_redemptions[msg.sender] <= block.timestamp, " < redemption_delay");
        
    //     bool _send_share = false;
    //     bool _send_collateral = false;
    //     uint256 _share_amount;
    //     uint256 _collateral_amount;

    //     // Use Checks-Effects-Interactions pattern
    //     if (redeem_share_balances[msg.sender] > 0) {
    //         _share_amount = redeem_share_balances[msg.sender];
    //         redeem_share_balances[msg.sender] = 0;
    //         unclaimed_pool_share = unclaimed_pool_share - _share_amount;
    //         _send_share = true;
    //     }

    //     if (redeem_collateral_balances[msg.sender] > 0) {
    //         _collateral_amount = redeem_collateral_balances[msg.sender];
    //         redeem_collateral_balances[msg.sender] = 0;
    //         unclaimed_pool_collateral = unclaimed_pool_collateral - _collateral_amount;
    //         _send_collateral = true;
    //     }

    //     if (_send_share) {
    //         _requestTransferCoffin(msg.sender, _share_amount);
    //     }

    //     if (_send_collateral) {
    //         _requestTransferCollateralFTM(msg.sender, _collateral_amount);
    //     }
    // }

    // /* ========== INTERNAL FUNCTIONS ========== */

    // function _transferWftmToReserveFrom(address _sender, uint256 _amount) internal {
    //     _transferToReserveFrom(wftmAddress, _sender, _amount);
    // }

    // function _transferToReserveFrom(address _token, address _sender, uint256 _amount) internal {
    //     require(collateralReserveV2 != address(0), "Invalid reserve address");
    //     ERC20(_token).safeTransferFrom(_sender, collateralReserveV2, _amount);
    // }

    // // transfer collateral(wftm) from the gate to reserve.
    // function _transferToReserve(address _token, uint256 _amount) internal {
    //     require(collateralReserveV2 != address(0), "Invalid reserve address");
    //     ERC20(_token).safeTransfer(collateralReserveV2, _amount);
    // }
    
    // // transfer collateral(wftm) from the gate to reserve.
    // function _transferWftmToReserve(uint256 _amount) internal {
    //     _transferToReserve(wftmAddress, _amount);
    // }

    // // mint share(ERC20) to reserve.
    // function _mintShareToCollateralReserve(uint256 _amount) internal {
    //     require(collateralReserveV2 != address(0), "Invalid reserve address");
    //     IPoolToken(coffin).pool_mint(collateralReserveV2, _amount);
    // }

    // // transfer collateral(wftm) from reserve to the gate.
    // // then convert wftm to ftm, then transfer it to a user.
    // function _requestTransferCollateralFTM(address to, uint256 amount) internal {
    //     require(to != address(0), "Invalid reserve address");
    //     ICollateralReserve(collateralReserveV2).transferTo(wftmAddress, address(this), amount);
    //     IWETH(wftmAddress).withdraw(amount);
    //     payable(to).transfer(amount);
    // }

    // // transfer collateral(wftm) from reserve to a user.
    // function _requestTransferCollateralWrappedFTM(address _receiver, uint256 _amount) internal {
    //     ICollateralReserve(collateralReserveV2).transferTo(wftmAddress, _receiver, _amount);
    // }

    // // transfer share(ERC20) from reserve to users.
    // function _requestTransferCoffin(address _receiver, uint256 _amount) internal {
    //     ICollateralReserve(collateralReserveV2).transferTo(coffin, _receiver, _amount);
    // }

    // /* ========== RESTRICTED FUNCTIONS ========== */

    // function toggleMinting() external onlyOwner {
    //     mint_paused = !mint_paused;
    // }

    // function toggleRedeeming() external onlyOwner {
    //     redeem_paused = !redeem_paused;
    // }

    // function setOracle(address _oracle) external onlyOwner {
    //     require(_oracle != address(0), "Invalid address");
    //     oracle = _oracle;
    // }


    // function setPolicy(address _policy) external onlyOwner {
    //     require(_policy != address(0), "Invalid address");
    //     policy = _policy;
    // }




    // function getDollarSupply() public view override returns (uint256) {
    //     return IERC20(dollar).totalSupply();
    // }

    // function getCoffinSupply() public view override returns (uint256) {
    //     return IERC20(coffin).totalSupply();
    // }

    // function globalCollateralValue() public view override returns (uint256) {
    //     return (globalCollateralBalance() * getCollateralPrice() * (10**missing_decimals)) / PRICE_PRECISION;
    // }

    // function globalCollateralBalance() public view override returns (uint256) {
    //     uint256 _collateralReserveBalance = IERC20(wftmAddress).balanceOf(collateralReserveV2);
    //     return _collateralReserveBalance - unclaimed_pool_collateral;
    // }

    // function setCollateralReserve(address _collateralReserveV2) public onlyOwner {
    //     require(_collateralReserveV2 != address(0), "invalidAddress");
    //     collateralReserveV2 = _collateralReserveV2;
    // }

    // // function getCollateralBalance() public view override returns (uint256) {
    // //     return IERC20(wftmAddress).balanceOf(collateralReserve);
    // // }


    // event ZapSwapped(uint256 indexed collateralAmount, uint256 indexed shareAmount);

}

// SPDX-License-Identifier: MIT

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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