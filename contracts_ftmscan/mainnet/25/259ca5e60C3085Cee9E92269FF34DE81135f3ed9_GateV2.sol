// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IUniswapV2Router.sol";


// Coffin Gate
// fork&inspired by FRAX & IRON

interface ICollateralReserve {
    function transferTo(
        address _token,
        address _receiver,
        uint256 _amount
    ) external;
    function fundBalance
    (
        address _token
    ) external view returns (uint256) ;
    function stakeCoffin(uint _amount) external;
    function burnXCoffin(uint _amount) external;
    function burnXCoffinByCoffin(uint _coffin_ammount) external;
    function getCollateralBalance(address _token) external view  returns (uint256);
    function getActualCollateralValue() external view  returns (uint256);
    function getTotalCollateralValue() external view  returns (uint256);

}

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

interface ICoffinOracle{
    function PERIOD() external view returns (uint32);
    function getCOFFINUSD() external view returns (uint256, uint8);
    function updateTwap(address token0, address token1) external ;
    function getCOUSDUSD() external view returns (uint256, uint8);
    function getTwapCOUSDUSD() external view returns (uint256, uint8);
    function getTwapCOFFINUSD() external view returns (uint256, uint8);
    function getTwapXCOFFINUSD() external view returns (uint256, uint8);
    function updateTwapDollar() external ;
    function updateTwapCoffin() external ;
    function updateTwapXCoffin() external ;
    function getXCOFFINUSD() external view returns (uint256, uint8);
    function getCOUSDFTM() external view returns (uint256, uint8);
    function getXCOFFINFTM() external view returns (uint256, uint8);
    function getCOFFINFTM() external view returns (uint256, uint8);
    function getFTMUSD() external view returns (uint256, uint8);
}
interface ICollateralReserveV2Calc {
    // function getActualCollateralValue() external view  returns (uint256) ;
    // function getTotalCollateralValue() external view  returns (uint256) ;

    function getValue(address _token, uint256 _amt) external view  returns (uint256) ;
}
interface IGateV1 {
    function unclaimed_pool_share() view external returns(uint256);
    function unclaimed_pool_collateral() view external returns(uint256);
}
interface ICoffinTheOtherWorld {
    function stake(uint256 _amount) external;
    function unstake(uint256 _share, uint256 expected_output) external;
}
interface ICoffin {
    function pool_burn_from(address addr, uint256 amount)external;
    function pool_mint(address addr, uint256 amount)external;
    function burnFrom(address addr, uint256 amount)external;
    function totalSupply() external view returns (uint256) ;

}
interface IDollar {
    function pool_burn_from(address addr, uint256 amount)external;
    function pool_mint(address addr, uint256 amount)external;
    function burnFrom(address addr, uint256 amount)external;
    function totalSupply() external view returns (uint256) ;
}


interface IXCoffin {
    function burn(uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256) ;
}
interface ITokenOracle {
    function getPrice() external view returns (uint256, uint8);
}



contract GateV2 is Ownable,  ReentrancyGuard {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Address for address;

    address public collateralReserveV2; //  = address(0x624135E0756FF780757fdcc60b2EB42c0AaB16a8); // bydefault
    address public coffin;

    address public oracle = address(0x605ce7209B6811c1892Ae18Cfa6595bA1462C403); // oracle
    // address public oracleTest = address(0x2e3C0EE9Ff3DA0ab201fbB6f942Da7184a481Ebd); // oracle
    address xcoffin = 0xc8a0a1b63F65C53F565ddDB7fbcfdd2eaBE868ED;

    address public dollar;

    // address public calc; // = address(0xC762Cdaaba5a351890552d110eCc4f366d9C3250);
    address public gatev1 = address(0x98e119990E3653486d84Ba46b66BbC4d82f7f604);
    address public theotherworld = address(0x98e119990E3653486d84Ba46b66BbC4d82f7f604);

    uint256 private constant LIMIT_SWAP_TIME = 10 minutes;


    // limitation
    uint public oneTimeRedeemLimitation = 50 * 1e18;
    uint public redeemCounterLimitation = 1000 * 1e18;
    uint public redeemCounter = 0;
    uint public redeemCounterResetPeriod = 10800;
    uint public lastRedeemCounterUpdate;

    uint public redeem_collateral_limitation = 100 * 1e18;
    uint public redeem_coffin_limitation = 500 * 1e18;

    uint redemption_delay = 7 days;

    bool public using_twap_for_redeem = false;
    bool public using_fixed_minting_collateral_ratio = false;
    uint256 public fixed_minting_collateral_ratio = 900000; // 900000 / 1e6 = 90%


    uint256 public unclaimed_pool_coffin; // unclaimed coffin  balance
    uint256 public unclaimed_pool_collateral; // unclaimed coffin  balance
    uint256 private minting_fee = 3000; // minting_fee / PRICE_PRECISION ( 1e6)  => 3000/1000000 => 3/1000 => 0.3%
    uint256 private redemption_fee = 4000;// redemption_fee / PRICE_PRECISION ( 1e6)  => 4000/1000000 => 4/1000 => 0.4%
    uint256 private extra_redemption_fee = 3000;

    mapping (address => uint256) public redeem_coffin_balance;
    mapping(address => uint256) public redeem_collateral_balances;

    mapping(address => uint256) public time_of_redemptions;

    uint256 public redeem_price_threshold = 993333; // $0.993333
    uint256 public mint_price_threshold = 1003333; // $1.003333
    uint256 public extra_redemption_fee_threshold = 950000; // $0.950000

    // uint256 public mint_price_threshold = 1010000; // $1.01

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant RATIO_PRECISION = 1e6;

    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;
    // uint256 private constant LIMIT_SWAP_TIME = 10 minutes;

    // wrapped ftm
    address public wftmAddress = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    address public usdcAddress = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
    address public daiAddress = 0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E;
    address public mimAddress = 0x82f0B8B456c1A451378467398982d4834b6829c1;

    uint256 private missing_decimals = 0 ;

    // AccessControl state variables
    bool public redeem_paused = false;
    bool public mint_paused = false;
    // bool public bond_mint_paused = false;

    address public spookyRouterAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;


    /* ========== MODIFIERS ========== */

    modifier notContract() {
        require(!msg.sender.isContract(), "Allow non-contract only");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        // coffin(prod
        // coffin = address(0x593Ab53baFfaF1E821845cf7080428366F030a9c); // coffin
        // coffin(test
        coffin = address(0x894c3A00a4b1FF104401DD8f116d9C3E97dd9684); // test coffin

        // dollar prod
        // dollar = address(0x0DeF844ED26409C5C46dda124ec28fb064D90D27); // dollar
        // dollar test
        dollar = address(0xA51a63261A7dfdc7eD1E480223C2f705b9CbEE6F); // test dollar
    }


    receive() external payable {
        if (collateralReserveV2!=address(0)) {
            payable(collateralReserveV2).transfer(msg.value);
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function gateInfo()
        public
        view
        returns (
            uint256 _minting_fee,
            uint256 _redemption_fee,
            uint256 _ex_red_fee,
            uint256 _collateral_price,
            uint256 _coffin_price,
            uint256 _dollar_price,
            uint256 _share_twap,
            uint256 _dollar_twap,
            uint256 _ecr,
            bool _mint_paused,
            bool _redeem_paused,
            uint256 _unclaimed_pool_collateral,
            uint256 _unclaimed_pool_coffin
        )
    {
        _minting_fee = minting_fee;
        _redemption_fee = redemption_fee;
        _ex_red_fee = extra_redemption_fee;
        _collateral_price = getCollateralPrice();
        _coffin_price = getCoffinPrice();
        _dollar_price = getDollarPrice();
        _share_twap = getCoffinTwap();
        _dollar_twap = getDollarTwap();

        // _tcr = IGatePolicy(policy).target_collateral_ratio();
        _ecr = getEffectiveCollateralRatio();

        _mint_paused = mint_paused;
        _redeem_paused = redeem_paused;

        _unclaimed_pool_collateral = totalUnclaimedPoolCollateral();
        _unclaimed_pool_coffin = unclaimed_pool_coffin;
    }
    function gateInfo2() view public returns (
        bool _using_fixed_minting_collateral_ratio,
        uint256 _fixed_minting_collateral_ratio,
        uint  _oneTimeRedeemLimitation,
        uint  _redeemCounterLimitation ,
        uint  _redeemCounter ,
        uint  _redeemCounterResetPeriod ,
        uint  _lastRedeemCounterUpdate,
        uint  _redeem_collateral_limitation ,
        uint  _redeem_coffin_limitation ,
        uint _redemption_delay ,
        uint256  _redeem_price_threshold ,
        uint256  _mint_price_threshold ,
        uint256  _extra_redemption_fee_threshold
    )
    {
        _using_fixed_minting_collateral_ratio = using_fixed_minting_collateral_ratio;
        _fixed_minting_collateral_ratio = fixed_minting_collateral_ratio;

        _oneTimeRedeemLimitation = oneTimeRedeemLimitation;
        _redeemCounterLimitation=  redeemCounterLimitation;
        _redeemCounter=  redeemCounter;
        _redeemCounterResetPeriod=  redeemCounterResetPeriod;
        _lastRedeemCounterUpdate=  lastRedeemCounterUpdate;

        _redeem_collateral_limitation=  redeem_collateral_limitation;
        _redeem_coffin_limitation=  redeem_coffin_limitation;

        _redemption_delay= redemption_delay;


        _redeem_price_threshold=  redeem_price_threshold ;
        _mint_price_threshold=  mint_price_threshold ;
        _extra_redemption_fee_threshold=  extra_redemption_fee_threshold;
    }

    function totalUnclaimedPoolCollateral() view public returns (uint256) {
        return unclaimed_pool_collateral + IGateV1(gatev1).unclaimed_pool_collateral();
    }

    function getUnclaimedPoolCollateralValue() view public returns (uint256) {
        return totalUnclaimedPoolCollateral().mul(getFTMPrice());
    }

    function getEffectiveCollateralRatio() public view  returns(uint256 ecr) {
        ecr = getActualCollateralRatio();
        if (ecr > COLLATERAL_RATIO_MAX) {
            ecr = COLLATERAL_RATIO_MAX;
        }
        return ecr;
    }
    function getCollateralInfo() public view returns
    (
        uint256 actual_collateral_value
        ,uint256 total_collateral_value
        ,uint256 dollar_total_supply
        ,uint256 dollar_price
        ,uint256 effective_collateral_ratio
        ,uint256 consolidated_collateral_ratio
    )
    {


        actual_collateral_value = ICollateralReserve(collateralReserveV2).getActualCollateralValue();
        total_collateral_value = ICollateralReserve(collateralReserveV2).getTotalCollateralValue();

        dollar_total_supply = IDollar(dollar).totalSupply();
        dollar_price = getDollarPrice();
        effective_collateral_ratio = getEffectiveCollateralRatio();
        consolidated_collateral_ratio = getConsolidatedCollateralRatio();
    }

    function getConsolidatedCollateralRatio() public view returns (uint256 ccr) {
        if (address(collateralReserveV2)==address(0)) {
            return 0;
        }

        // uint256 _collateral_value = ICollateralReserveV2Calc(calc)
        //     .getTotalCollateralValue();
        uint256 _collateral_value = ICollateralReserve(collateralReserveV2).getTotalCollateralValue();

        uint256 _ftm_price = getFTMPrice();
        uint256 unclaimedCollateralValue = _ftm_price.mul(totalUnclaimedPoolCollateral());

        if (unclaimedCollateralValue<=_collateral_value) {
            _collateral_value -= unclaimedCollateralValue;
        } else {
            _collateral_value = 0;
        }
        uint256 total_supply_dollar = IERC20(dollar).totalSupply();

        if (total_supply_dollar == 0) {
            return COLLATERAL_RATIO_MAX;
        }
        if (_collateral_value == 0) {
            return 0;
        }
        // 6 decimals * 1000000 / 18 decimals
        ccr = _collateral_value.mul(1e18).div(total_supply_dollar);
    }

    function getActualCollateralRatio() public view  returns(uint256 acr) {
        if (address(collateralReserveV2)==address(0)) {
        // if (address(calc)==address(0)) {
            return 0;
        }

        // uint256 _collateral_value = ICollateralReserveV2Calc(calc)
        //     .getActualCollateralValue();
        uint256 _collateral_value = ICollateralReserve(collateralReserveV2).getActualCollateralValue();

        uint256 _ftm_price = getFTMPrice();

        // 18 decimal
        uint256 unclaimedCollateralValue = _ftm_price.mul(totalUnclaimedPoolCollateral()).div(1e6);

        if (unclaimedCollateralValue<=_collateral_value) {
            _collateral_value -= unclaimedCollateralValue;
        } else {
            _collateral_value = 0;
        }
        uint256 total_supply_dollar = IERC20(dollar).totalSupply();

        if (total_supply_dollar == 0) {
            return COLLATERAL_RATIO_MAX;
        }
        if (_collateral_value == 0) {
            return 0;
        }
        //  6 decimal
        acr = _collateral_value.mul(1e6).div(total_supply_dollar);
    }


    function getDollarSupply() public view  returns (uint256) {
        return IERC20(dollar).totalSupply();
    }

    function getCoffinSupply() public view  returns (uint256) {
        return IERC20(coffin).totalSupply();
    }

    function getCollateralPrice() public view  returns (uint256) {
        (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getFTMUSD();
        return __price.mul(PRICE_PRECISION).div(10**__d);
    }

    function getFTMPrice() public view  returns (uint256) {
        (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getFTMUSD();
        return __price.mul(PRICE_PRECISION).div(10**__d);
    }

    function getDollarPrice() public view  returns (uint256) {
        (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getCOUSDUSD();
        return __price.mul(PRICE_PRECISION).div(10**__d);
    }

    function getCoffinPrice() public view  returns (uint256) {
        (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getCOFFINUSD();
        return __price.mul(PRICE_PRECISION).div(10**__d);
    }

    function getDollarTwap() public view  returns (uint256) {
        (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getTwapCOUSDUSD();
        return __price.mul(PRICE_PRECISION).div(10**__d);
    }

    function getCoffinTwap() public view  returns (uint256) {
        (uint256 __price, uint8 __d) = ICoffinOracle(oracle).getTwapCOFFINUSD();
        return __price.mul(PRICE_PRECISION).div(10**__d);
    }


    /* ========== INTERNAL FUNCTIONS ========== */

    function _transferWftmToReserveFrom(address _sender, uint256 _amount) internal {
        _transferToReserveFrom(wftmAddress, _sender, _amount);
    }

    function _transferToReserveFrom(address _token, address _sender, uint256 _amount) internal {
        require(collateralReserveV2 != address(0), "Invalid reserve address");
        IERC20(_token).safeTransferFrom(_sender, collateralReserveV2, _amount);
    }

    // transfer collateral(wftm) from the gate to reserve.
    function _transferToReserve(address _token, uint256 _amount) internal {
        require(collateralReserveV2 != address(0), "Invalid reserve address");
        IERC20(_token).safeTransfer(collateralReserveV2, _amount);
    }

    // transfer collateral(wftm) from the gate to reserve.
    function _transferWftmToReserve(uint256 _amount) internal {
        _transferToReserve(wftmAddress, _amount);
    }


    // transfer collateral(wftm) from reserve to the gate.
    // then convert wftm to ftm, then transfer it to a user.
    function _requestTransferCollateralFTM(address to, uint256 amount) internal {
        require(to != address(0), "Invalid reserve address");
        ICollateralReserve(collateralReserveV2).transferTo(wftmAddress, address(this), amount);
        IWETH(wftmAddress).withdraw(amount);
        payable(to).transfer(amount);
    }

    // transfer collateral(wftm) from reserve to a user.
    function _requestTransferCollateralWrappedFTM(address _receiver, uint256 _amount) internal {
        ICollateralReserve(collateralReserveV2).transferTo(wftmAddress, _receiver, _amount);
    }



    function swapOnSpooky(
            address token0,
            address token1,
            uint256 _amount,
            uint256 _min_output_amount
    )
        internal returns (uint256 )
    {

        IERC20(token0).approve(address(spookyRouterAddress), 0);
        IERC20(token0).approve(address(spookyRouterAddress), _amount);

        address[] memory router_path = new address[](2);
        router_path[0] = token0;
        router_path[1] = token1;

        uint256[] memory _received_amounts
            = IUniswapV2Router(spookyRouterAddress).swapExactTokensForTokens(_amount,
            _min_output_amount, router_path, address(this), block.timestamp + LIMIT_SWAP_TIME);

        require(_received_amounts[_received_amounts.length - 1] >= _min_output_amount, "Slippage limit reached");
        return _received_amounts[_received_amounts.length - 1];
    }



    /////////////////////////// only Owner



    function setRedemptionDelay(uint _delay) external onlyOwner {
        require ( _delay<= 30 days, "_delay too long");
        require ( _delay > 300 , "_delay too short");
        redemption_delay = _delay;
    }

    // just for test
    function setTimeOfRedemption(address a , uint i ) external onlyOwner{
        time_of_redemptions[a] = i;
    }

    function setCollateralReserve(address _collateralReserveV2) public onlyOwner {
        require(_collateralReserveV2 != address(0), "invalidAddress");
        collateralReserveV2 = _collateralReserveV2;
    }

    // function setCalc(address _calc) public onlyOwner {
    //     require(_calc != address(0), "invalidAddress");
    //     calc = _calc;
    // }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Invalid address");
        oracle = _oracle;
    }


    function setFees(
        uint256 new_mint_fee,
        uint256 new_redeem_fee
    ) external onlyOwner
    {
        minting_fee= new_mint_fee;
        redemption_fee = new_redeem_fee;
    }

    function enableRedeem() external onlyOwner {
        redeem_paused = false;
    }
    function enableMint() external onlyOwner {
        mint_paused = false;
    }
    function disableRedeem() external onlyOwner {
        redeem_paused = true;
    }
    function disableMint() external onlyOwner {
        mint_paused = true;
    }


    function setOneTimeRedeemLimitation(uint256 _limit)external onlyOwner {
        oneTimeRedeemLimitation =  _limit * 1e18;
    }

    function setRedeemCounterResetPeriod(uint256 _period)external onlyOwner {
        require(_period>=3600,"should be more than 1 hours");
        require(_period>=3600,"should be less than 30 days");
        redeemCounterResetPeriod =  _period; // X days by default
    }


    function setRedeemCollateralLimitation(uint _redeem_collateral_limitation) external onlyOwner {
        redeem_collateral_limitation = _redeem_collateral_limitation;
    }
    function setRedeemCoffinLimitation(uint _redeem_coffin_limitation) external onlyOwner {
        redeem_coffin_limitation = _redeem_coffin_limitation;
    }


    function setExRedemptionFeeThreshold(uint256 _extra_redemption_fee_threshold ) external onlyOwner {
        require(_extra_redemption_fee_threshold<=redeem_price_threshold,
            "ex redemption threshold must be lower than redeem price threshold");
        extra_redemption_fee_threshold = _extra_redemption_fee_threshold;
    }

    function setPriceThresholds(
        uint256 new_mint_price_threshold,
        uint256 new_redeem_price_threshold
    ) external onlyOwner {
        require(extra_redemption_fee_threshold<=new_redeem_price_threshold,
            "ex redemption threshold must be lower than redeem price threshold");
        mint_price_threshold = new_mint_price_threshold;
        redeem_price_threshold = new_redeem_price_threshold;
        emit PriceThresholdsSet(new_mint_price_threshold, new_redeem_price_threshold);
    }

    function setUsingTwapForRedeem(bool _val) external onlyOwner{
        using_twap_for_redeem = _val;
    }

    function setUsingFixedMintingCollateralRatio(bool _val) external onlyOwner{
        using_fixed_minting_collateral_ratio = _val;
    }
    function updateFixedMintingCollateralRatio(uint256 _val ) external onlyOwner {
        require (_val<= 1000000, " less than 1000000");
        fixed_minting_collateral_ratio = _val;
    }




    //////////////////////// for users

    function mintFTM(
        uint256 _coffin_amt,
        uint256 _cousd_out_min,
        bool _one_to_one_override
    ) external payable nonReentrant notContract onlyOwner
    {
        require(mint_paused == false, "Minting is paused");
        uint256 _cousd_price =getDollarPrice();
        uint256 _coffin_price = getCoffinPrice();
        // Prevent unneccessary mints
        require(_cousd_price >= mint_price_threshold, "CoUSD price too low");
        uint256 _ftm_price = getFTMPrice();
        require(_ftm_price > 0 , "FTM Price Oracle error");

        uint256 _collateral_amount = msg.value;
        uint256 _total_dollar_value = 0;

        // FTM
        // COFFIN-FTM
        uint256 _ecr = getEffectiveCollateralRatio();
        if (using_fixed_minting_collateral_ratio) {
            _ecr = fixed_minting_collateral_ratio;
        }
        uint256 _required_coffin_amount = 0;

        if (_one_to_one_override || _ecr >= COLLATERAL_RATIO_MAX) { // _ecr = 100%
            require(_collateral_amount > 0, "need FTM ");
            _total_dollar_value
                = ((_collateral_amount * (10**missing_decimals)) * _ftm_price) / PRICE_PRECISION;
            _required_coffin_amount = 0 ;
        } else if (_ecr > 0) {  // 0 < _ecr < 100
            require(_collateral_amount > 0, "need FTM ");

            uint256 _collateral_value
                = ((_collateral_amount * (10**missing_decimals)) * _ftm_price) / PRICE_PRECISION;
            _total_dollar_value = (_collateral_value * COLLATERAL_RATIO_PRECISION) / _ecr;

            _required_coffin_amount = ((_total_dollar_value - _collateral_value) * PRICE_PRECISION) / _coffin_price;
        } else {
            // _ecr == 0
            if (_collateral_amount > 0) {
                payable(msg.sender).transfer(_collateral_amount);
                _collateral_amount = 0;
            }

            _total_dollar_value = (_coffin_amt * _coffin_price) / PRICE_PRECISION;
            _required_coffin_amount = _coffin_amt;

        }
        uint256 fee = _total_dollar_value.mul(minting_fee).div(PRICE_PRECISION);
        uint256 _actual_dollar_amount = _total_dollar_value.sub(fee);

        require(_cousd_out_min <= _actual_dollar_amount,
            "COFFIN slippage");

        require (_required_coffin_amount > 0|| _collateral_amount > 0 , " need to pay ");

        if (_required_coffin_amount > 0) {

            // transfer coffin from msg.sender to reserve.
            _transferToReserveFrom(coffin, msg.sender, _required_coffin_amount);
            // convert coffin to xcoffin.
            ICollateralReserve(collateralReserveV2).stakeCoffin(_required_coffin_amount);
            // ICoffinTheOtherWorld(theotherworld).stake(_required_coffin_amount);
        }

        // ftm_needed;
        if (_collateral_amount > 0) {
            // ERC20(wftmAddress).safeTransfer(collateralReserveV2, _collateral_amount);
            IWETH(wftmAddress).deposit{value: _collateral_amount}();
            _transferWftmToReserve(_collateral_amount);
        }

        // burn XCoffin By Coffin instead of fee.
        if (fee>0) {
            ICollateralReserve(collateralReserveV2).burnXCoffinByCoffin(fee.div(_coffin_price));
        }

        // Mint the CoUSD
        IDollar(dollar).pool_mint(msg.sender, _actual_dollar_amount);

    }



    function redeem(
        uint256 cousd_amount,
        uint256 coffin_out_min,
        uint256 col_out_min
    ) external onlyOwner nonReentrant notContract returns ( // onlyOwner => testing purpose.
        uint256 collat_out,
        uint256 coffin_out
    ) {
        require(redeem_paused == false, "Redemption is paused");

        // Prevent unneccessary redemptions that could adversely affect the COFFIN price
        require(getDollarPrice() <= redeem_price_threshold, "CoUSD price too high");
        //
        require(oneTimeRedeemLimitation > cousd_amount, " one time limitation ");
        if ( lastRedeemCounterUpdate + redeemCounterResetPeriod < block.timestamp ) {
            redeemCounter = 0;
            lastRedeemCounterUpdate = block.timestamp;
        }
        redeemCounter += cousd_amount;
        require ( redeemCounter <= redeemCounterLimitation, "there is redeemCounter limitation");

        uint256 _coffin_price = 0;
        uint256 _dollar_price = 0;


        if (using_twap_for_redeem) {
            _coffin_price = getCoffinTwap();
            _dollar_price = getDollarTwap();
        }
        if (_coffin_price==0 ) {
            _coffin_price = getCoffinPrice();
        }
        if (_dollar_price==0) {
            _dollar_price = getDollarPrice();
        }
        uint256 _ftm_price = getFTMPrice();

        uint256 _redemption_fee = redemption_fee;
        uint256 _ecr = getEffectiveCollateralRatio();

        if (_dollar_price <= extra_redemption_fee_threshold ) {
            _redemption_fee += extra_redemption_fee;
        }


        uint256 fee = cousd_amount.mul(_redemption_fee).div(PRICE_PRECISION);
        uint256 cousd_after_fee = cousd_amount.sub(fee);

        // Assumes $1 CoUSD in all cases
        if(_ecr >= PRICE_PRECISION) {
            // 1-to-1 or overcollateralized
            collat_out = cousd_after_fee
                            .mul(_ftm_price)
                            .div(10 ** (6 + missing_decimals));
            coffin_out = 0;
        } else if (_ecr == 0) {
            // ecr==0%; Algorithmic
            coffin_out = cousd_after_fee
                            .mul(PRICE_PRECISION)
                            .div(_coffin_price);
            collat_out = 0;

        } else {
            // Fractional
            collat_out = cousd_after_fee
                            .mul(_ecr)
                            .mul(_ftm_price)
                            .div(10 ** (12 + missing_decimals)); // PRICE_PRECISION ^2 + missing decimals
            coffin_out = cousd_after_fee
                            .mul(PRICE_PRECISION.sub(_ecr))
                            .div(_coffin_price); // PRICE_PRECISIONS CANCEL OUT
        }

        // TODO: Checks there is enough FTM collateral.


        require(collat_out >= col_out_min, "Collateral slippage");
        require(coffin_out >= coffin_out_min, "Coffin slippage");

        // Account for the redeem delay
        // redeemCollateralBalances[msg.sender][col_idx]
        //  = redeemCollateralBalances[msg.sender][col_idx].add(collat_out);
        // unclaimedPoolCollateral[col_idx] = unclaimedPoolCollateral[col_idx].add(collat_out);

        redeem_collateral_balances[msg.sender] = redeem_collateral_balances[msg.sender].add(collat_out);
        if (redeem_collateral_limitation>0) {
            require(redeem_collateral_balances[msg.sender]<=redeem_collateral_limitation,
                " redeem FTM limitation per address ");
        }

        redeem_coffin_balance[msg.sender] = redeem_coffin_balance[msg.sender].add(coffin_out);
        if (redeem_coffin_limitation>0) {
            require(redeem_coffin_balance[msg.sender]<=redeem_coffin_limitation,
                " redeem coffin limitation per address. ");
        }

        // unclaimedPoolCollateral = unclaimedPoolCollateral.add(collat_out);
        unclaimed_pool_collateral = unclaimed_pool_collateral.add(collat_out);
        // unclaimedPoolFXS = unclaimedPoolFXS.add(coffin_out);
        unclaimed_pool_coffin = unclaimed_pool_coffin.add(coffin_out);

        time_of_redemptions[msg.sender] = block.timestamp + redemption_delay;

        //TODO: fee to treasury.

        IDollar(dollar).pool_burn_from(msg.sender, cousd_amount);
        // IDollar(dollar).pool_mint(address(this), coffin_out);

        if (coffin_out > 0) {
            // _mintShareToCollateralReserve(coffin_out);
            ICoffin(coffin).pool_mint(address(this), coffin_out);
        }
    }

    function collectCoffin(bool stake) external nonReentrant {
        require(time_of_redemptions[msg.sender] <= block.timestamp, " < redemption_delay");

        bool _send_share = false;
        uint256 _share_amount;

        // Use Checks-Effects-Interactions pattern
        if (redeem_coffin_balance[msg.sender] > 0) {
            _share_amount = redeem_coffin_balance[msg.sender];
            redeem_coffin_balance[msg.sender] = 0;
            unclaimed_pool_coffin = unclaimed_pool_coffin - _share_amount;
            _send_share = true;
        }

        if (_send_share) {
            if (stake) {
                IERC20(coffin).approve( theotherworld, _share_amount);
                uint b = IXCoffin(xcoffin).balanceOf(address(this));
                ICoffinTheOtherWorld(theotherworld).stake(_share_amount);
                uint a = IXCoffin(xcoffin).balanceOf(address(this));
                if (a.sub(b)>0) {
                    IERC20(xcoffin).safeTransfer( msg.sender, a.sub(b));
                }
            } else {
                IERC20(coffin).safeTransfer( msg.sender, _share_amount);
            }
        }
    }
    function collectCollateral(uint8 option) external nonReentrant {
        require(time_of_redemptions[msg.sender] <= block.timestamp, " < redemption_delay");

        bool _send_collateral = false;
        uint256 _collateral_amount;

        if (redeem_collateral_balances[msg.sender] > 0) {
            _collateral_amount = redeem_collateral_balances[msg.sender];
            redeem_collateral_balances[msg.sender] = 0;
            unclaimed_pool_collateral = unclaimed_pool_collateral - _collateral_amount;
            _send_collateral = true;
        }

        if (_send_collateral) {
            if (option==1) { // buy coffin and stake
                uint _ftm_price = getFTMPrice();
                uint _coffin_price = getCoffinPrice();
                uint slippage = 1;
                uint _min_output_amount = _collateral_amount.mul(_ftm_price)
                    .div(_coffin_price).mul(100-slippage).div(100);

                uint outputCoffin = swapOnSpooky(wftmAddress, address(coffin), _collateral_amount, _min_output_amount);
                IERC20(coffin).approve( theotherworld, outputCoffin);

                uint b = IXCoffin(xcoffin).balanceOf(address(this));
                ICoffinTheOtherWorld(theotherworld).stake(outputCoffin);
                uint a = IXCoffin(xcoffin).balanceOf(address(this));
                IERC20(xcoffin).safeTransfer( msg.sender, a.sub(b));

            // } else if (option==2 && IBondingHelper(bondingHelper)!=address(0)){
                // TODO: zap CoUSD-COFFIN and BOND COUSD at discount price.
                // payable(bondingHelper)
                // IBondingHelper(bondingHelper).buyBond(_collateral_amount)

                // in this case, no need to wait....!?

                // FTM zap CoUSD-COFFIN for BOND CoUSD at discount price.
                // Current ROI is 5% in 5 days. APR => 365%.

            } else {
                _requestTransferCollateralFTM(msg.sender, _collateral_amount);
                //TransferHelper.safeTransfer(collateral_addresses[col_idx], msg.sender, _collateral_amount);
            }
        }
    }


    event PriceThresholdsSet(uint256 new_bonus_rate, uint256 new_redemption_delay);

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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