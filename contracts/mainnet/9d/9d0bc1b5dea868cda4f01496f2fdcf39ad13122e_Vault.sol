// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
//pragma experimental ABIEncoderV2;

import "./ONE.sol";
import "./SwapLib.sol";

interface IAETH is IERC20 {
    function ratio() external view returns (uint256);
}

contract Constant {
    bytes32 internal constant _ratioAEthWhenMint_       = 'ratioAEthWhenMint';
}

contract Vault is Constant, Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using EmaOracle for EmaOracle.Observations;
    
    bytes32 internal constant _periodTwapOne_           = 'periodTwapOne';
    bytes32 internal constant _periodTwapOns_           = 'periodTwapOns';
    bytes32 internal constant _periodTwapAEth_          = 'periodTwapAEth';
    //bytes32 internal constant _thresholdReserve_        = 'thresholdReserve';
    bytes32 internal constant _initialMintQuota_        = 'initialMintQuota';
    bytes32 internal constant _rebaseInterval_          = 'rebaseInterval';
    bytes32 internal constant _rebaseThreshold_         = 'rebaseThreshold';
    bytes32 internal constant _rebaseCap_               = 'rebaseCap';
    bytes32 internal constant _burnOneThreshold_        = 'burnOneThreshold';
    
    address public oneMinter;
    ONE public one;
    ONS public ons;
    address public onb;
    IAETH public aEth;
    address public WETH;
    uint public begin;
    uint public span;
    EmaOracle.Observations public twapOne;
    EmaOracle.Observations public twapOns;
    EmaOracle.Observations public twapAEth;
    uint public totalEthValue;
    uint public rebaseTime;
    
	function __Vault_init(address governor_, address _oneMinter, ONE _one, ONS _ons, address _onb, IAETH _aEth, address _WETH, uint _begin, uint _span) external initializer {
		__Governable_init_unchained(governor_);
		__Vault_init_unchained(_oneMinter, _one, _ons, _onb, _aEth, _WETH, _begin, _span);
	}
	
	function __Vault_init_unchained(address _oneMinter, ONE _one, ONS _ons, address _onb, IAETH _aEth, address _WETH, uint _begin, uint _span) public governance {
		oneMinter = _oneMinter;
		one = _one;
		ons = _ons;
		onb = _onb;
		aEth = _aEth;
		WETH = _WETH;
		begin = _begin;
		span = _span;
		//config[_thresholdReserve_]  = 0.8 ether;
		config[_ratioAEthWhenMint_] = 0.9 ether;
		config[_periodTwapOne_]     =  8 hours;
		config[_periodTwapOns_]     = 15 minutes;
		config[_periodTwapAEth_]    = 15 minutes;
		config[_initialMintQuota_]  = 10000 ether;
		config[_rebaseInterval_]    = 8 hours;
		config[_rebaseThreshold_]   = 1.05 ether;
		config[_rebaseCap_]         = 0.05 ether;   // 5%
		rebaseTime = now;
		config[_burnOneThreshold_]  = 1.0 ether;
	}
	
	function twapInit(address swapFactory) external governance {
		twapOne.initialize(swapFactory, config[_periodTwapOne_], address(one), address(aEth));
		twapOns.initialize(swapFactory, config[_periodTwapOns_], address(ons), address(aEth));
		twapAEth.initialize(swapFactory, config[_periodTwapAEth_], address(aEth), WETH);
	}
		
    modifier updateTwap {
        twapOne.update(config[_periodTwapOne_], address(one), address(aEth));
        twapOns.update(config[_periodTwapOns_], address(ons), address(aEth));
        twapAEth.update(config[_periodTwapAEth_], address(aEth), WETH);
        _;
    }
    
    //function updateTWAP() external updateTwap {
    //    
    //}
    
    //function mintONE(uint amt) external updateTwap {
    //    if(now < begin || now > begin.add(span)) {
    //        uint quota = IERC20(one).totalSupply().sub0(IERC20(aEth).balanceOf(address(this)).mul(1e18).div(config[_thresholdReserve_]));
    //        require(quota > 0 , 'mintONE only when aEth.balanceOf(this)/one.totalSupply() < 80%');
    //        amt = Math.min(amt, quota);
    //    }
    //    
    //    IERC20(aEth).safeTransferFrom(msg.sender, address(this), amt.mul(config[_ratioAEthWhenMint_]).div(1e18));
    //    
    //    uint vol = amt.mul(uint(1e18).sub(config[_ratioAEthWhenMint_])).div(1e18);
    //    vol = twapOns.consultHi(config[_periodTwapOns_], address(aEth), vol, address(ons));
    //    ons.transferFrom_(msg.sender, address(this), vol);
    //    
    //    one.mint_(msg.sender, amt);
    //}
    
    function E2B(uint vol) external {
        
    }
    
    function B2E(uint vol) external {
        
    }
    
    function burnableONE(uint amt) public view returns (uint) {
        require(onePriceHi() < config[_burnOneThreshold_], 'ONE price is not low enough to burn');
        return amt.mul(aEth.balanceOf(address(this))).div(one.totalSupply());
    }
    
    function burnONE(uint amt) external {
        one.burn_(msg.sender, amt);
        aEth.transfer(msg.sender, burnableONE(amt));
    }
    
    function burnONB(uint vol) external {
        
    }
    
    function onePriceNow() public view returns (uint price) {
        price = twapOne.consultNow( address(one), 1 ether, address(aEth));
        price = twapAEth.consultNow(address(aEth), price,  address(WETH));
    }
    function onePriceEma() public view returns (uint price) {
        price = twapOne.consultEma( config[_periodTwapOne_],  address(one), 1 ether, address(aEth));
        price = twapAEth.consultEma(config[_periodTwapAEth_], address(aEth), price,  address(WETH));
    }
    function onePriceHi() public view returns (uint) {
        return Math.max(onePriceNow(), onePriceEma());
    }
    function onePriceLo() public view returns (uint) {
        return Math.min(onePriceNow(), onePriceEma());
    }
    
    function onsPriceNow() public view returns (uint price) {
        price = twapOns.consultNow( address(ons), 1 ether, address(aEth));
        price = twapAEth.consultNow(address(aEth), price,  address(WETH));
    }
    function onsPriceEma() public view returns (uint price) {
        price = twapOns.consultEma( config[_periodTwapOns_],  address(ons), 1 ether, address(aEth));
        price = twapAEth.consultEma(config[_periodTwapAEth_], address(aEth), price,  address(WETH));
    }
    function onsPriceHi() public view returns (uint) {
        return Math.max(onsPriceNow(), onsPriceEma());
    }
    function onsPriceLo() public view returns (uint) {
        return Math.min(onsPriceNow(), onsPriceEma());
    }
    
    function rebaseable() public view returns (uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol) {
        uint aEthPrice = 1e36 / aEth.ratio();
        uint onsPrice  = onsPriceLo();
        uint aEthBalance = aEth.balanceOf(oneMinter);
        uint onsBalance  = ons.balanceOf(oneMinter);
        uint oneVolAEth = aEthBalance.mul(aEthPrice).div(config[_ratioAEthWhenMint_]);
        uint oneVolOns  = onsBalance.mul(onsPrice).div(uint(1e18).sub(config[_ratioAEthWhenMint_]));
        oneVol = one.totalSupply().mul(config[_rebaseCap_]).div(1e18);
        oneVol = Math.min(Math.min(oneVol, oneVolAEth), oneVolOns);
        if(oneVol == 0)
            return (0, 0, 0, 0, 0);
        //aEthVol = oneVol.mul(config[_ratioAEthWhenMint_]).div(aEthPrice);
        //onsVol  = oneVol.mul(uint(1e18).sub(config[_ratioAEthWhenMint_])).div(onsPrice);
        aEthRatio = oneVol.mul(1e18).div(oneVolAEth);
        onsRatio  = oneVol.mul(1e18).div(oneVolOns);
        aEthVol = aEthBalance.mul(aEthRatio).div(1e18);
        onsVol  = onsBalance.mul(onsRatio).div(1e18);
    }
    
    function rebase() public updateTwap returns (uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol) {
        if(now < begin)
            return (0, 0, 0, 0, 0);
        else if (now > begin.add(span) || one.totalSupply() >= config[_initialMintQuota_]) {
            uint interval = config[_rebaseInterval_];
            if(now / interval <= rebaseTime / interval)
                return (0, 0, 0, 0, 0);
            uint price = onePriceLo();
            if(price < config[_rebaseThreshold_])
                return (0, 0, 0, 0, 0);
        }        
        (aEthVol, aEthRatio, onsVol, onsRatio, oneVol) = rebaseable();
        if(oneVol == 0)
            return (0, 0, 0, 0, 0);
            
        receiveAEthFrom(address(oneMinter), aEthVol);
        ons.transferFrom(address(oneMinter), address(this), onsVol);
        one.mint_(address(oneMinter), oneVol);
        rebaseTime = now;
        emit Rebase(aEthVol, aEthRatio, onsVol, onsRatio, oneVol);
    }
    event Rebase(uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol);
    
    function receiveAEthFrom(address from, uint vol) public {
        aEth.transferFrom(from, address(this), vol);
        totalEthValue = totalEthValue.add(vol.mul(1e18).div(aEth.ratio()));
    }
    
    function _sendAEthTo(address to, uint vol) internal {
        totalEthValue = totalEthValue.sub(vol.mul(1e18).div(aEth.ratio()));
        aEth.transfer(to, vol);
    }
    
    function interests() public view returns (uint) {
        return aEth.balanceOf(address(this)).mul(1e18).div(aEth.ratio()).sub(totalEthValue);
    }
}

contract OneMinter is Constant, Configurable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint internal constant INITIAL_INPUT = 1e27;

    Vault public vault;
    ONE public one;
    ONS public ons;
    IAETH public aEth;
    
    mapping (address => uint) internal _aEthBalances;
    mapping (address => uint) internal _onsBalances;
    mapping (address => uint) internal _aEthRIOs;
    mapping (address => uint) internal _onsRIOs;
    mapping (uint => uint) internal _aEthRioIn;
    mapping (uint => uint) internal _onsRioIn;
    uint internal _aEthRound;
    uint internal _onsRound;

    function __OneMinter_init(address governor_, address vault_) external initializer {
        __Governable_init_unchained(governor_);
        __OneMinter_init_unchained(vault_);
    }
    
	function __OneMinter_init_unchained(address vault_) public governance {
		vault = Vault(vault_);
		one = ONE(vault.one());
		ons = ONS(vault.ons());
		aEth = IAETH(vault.aEth());
		aEth.approve(address(vault), uint(-1));
		ons.approve(address(vault), uint(-1));
        _aEthRound = _onsRound = 1;
        _aEthRioIn[1] = packRIO(1, INITIAL_INPUT, 0);
        _onsRioIn [1] = packRIO(1, INITIAL_INPUT, 0);
	}
	
    //struct RIO {
    //    uint32  round;
    //    uint112 input;
    //    uint112 output;
    //}

    function packRIO(uint256 round, uint256 input, uint256 output) internal pure virtual returns (uint256) {
        require(round <= uint32(-1) && input <= uint112(-1) && output <= uint112(-1), 'RIO OVERFLOW');
        return round << 224 | input << 112 | output;
    }
    
    function unpackRIO(uint256 rio) internal pure virtual returns (uint256 round, uint256 input, uint256 output) {
        round  = rio >> 224;
        input  = uint112(rio >> 112);
        output = uint112(rio);
    }
    
    function totalSupply() external view returns (uint aEthSupply, uint onsSupply) {
        aEthSupply = aEth.balanceOf(address(this));
        onsSupply  =  ons.balanceOf(address(this));
    }
    
    function balanceOf_(address acct) public returns (uint aEthBal, uint onsBal) {
        _rebase();
        return balanceOf(acct);
    }
    
    function balanceOf(address acct) public view returns (uint aEthBal, uint onsBal) {
        uint rio = _aEthRIOs[acct];
        (uint r, uint i, ) = unpackRIO(rio);
        uint RIO = _aEthRioIn[r];
        if(RIO != rio) {
            (, uint I, ) = unpackRIO(RIO);
            aEthBal = _aEthBalances[acct].mul(I).div(i);
        } else
            aEthBal = _aEthBalances[acct];

        rio = _onsRIOs[acct];
        (r, i, ) = unpackRIO(rio);
        RIO = _onsRioIn[r];
        if(RIO != rio) {
            (, uint I, ) = unpackRIO(RIO);
            onsBal = _onsBalances[acct].mul(I).div(i);
        } else
            onsBal = _onsBalances[acct];
    }
    
    function mintInitial(uint aEthVol, uint onsVol) external {
        purchase(aEthVol, onsVol);
        //mint();
        cancel(uint(-1), uint(-1));
    }
    
    function purchase(uint aEthVol, uint onsVol) public {
        mint();
        
        aEth.transferFrom(msg.sender, address(this), aEthVol);
        ons.transferFrom_(msg.sender, address(this), onsVol);
        _aEthBalances[msg.sender] = _aEthBalances[msg.sender].add(aEthVol);
        _onsBalances [msg.sender] = _onsBalances [msg.sender].add(onsVol);
        
        emit Purchase(msg.sender, aEthVol, onsVol);
    }
    event Purchase(address acct, uint aEthVol, uint onsVol);
    
    function cancel(uint aEthVol, uint onsVol) public {
        mint();
        
        if(aEthVol == uint(-1))
            aEthVol = _aEthBalances[msg.sender];
        if(onsVol == uint(-1))
            onsVol = _onsBalances[msg.sender];
        _aEthBalances[msg.sender] = _aEthBalances[msg.sender].sub(aEthVol);
        _onsBalances [msg.sender] = _onsBalances [msg.sender].sub(onsVol);
        aEth.transfer(msg.sender, aEthVol);
        ons.transfer (msg.sender, onsVol);
        
        emit Cancel(msg.sender, aEthVol, onsVol);
    }
    event Cancel(address acct, uint aEthVol, uint onsVol);
    
    function mintable_(address acct) public returns (uint) {
        _rebase();
        return mintable(acct);
    }
    
    function mintable(address acct) public view returns (uint vol) {
        uint rio = _aEthRIOs[acct];
        (uint r, uint i, uint o) = unpackRIO(rio);
        uint RIO = _aEthRioIn[r];
        if(rio == RIO)
            return 0;
        
        uint bal = _aEthBalances[acct];
        (, , uint O) = unpackRIO(RIO);
        vol = O.sub(o).mul(bal).div(i);

        rio = _onsRIOs[acct];
        (r, i, o) = unpackRIO(rio);
        RIO = _onsRioIn[r];
        (, , O) = unpackRIO(RIO);
        vol = O.sub(o).mul(bal).div(i).add(vol);
    }
    
    function mint() public {
        _rebase();
        
        (uint aEthBal, uint onsBal) = balanceOf(msg.sender);
        uint oneVol = mintable(msg.sender);
        
        uint RIO = _aEthRioIn[_aEthRound];
        uint rio = _aEthRIOs[msg.sender];
        if(rio != RIO) {
            _aEthRIOs[msg.sender] = RIO;
            _onsRIOs [msg.sender] = _onsRioIn[_onsRound];
        }
            
        _aEthBalances[msg.sender] = aEthBal;
        _onsBalances [msg.sender] = onsBal;
        one.transfer(msg.sender, oneVol);
        emit Mint(msg.sender, oneVol);
    }
    event Mint(address acct, uint oneVol);
    
    function _rebase() internal {
        (uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol) = vault.rebase();
        if(oneVol == 0)
            return;
            
        uint ratioAEthWhenMint = vault.getConfig(_ratioAEthWhenMint_);
        (uint round, uint input, uint output) = unpackRIO(_aEthRioIn[_aEthRound]);
        output = oneVol.mul(ratioAEthWhenMint).div(aEthVol).mul(input.mul(aEthRatio).div(1e18)).div(1e18).add(output);
        input = uint(1e18).sub(aEthRatio).mul(input).div(1e18);
        _aEthRioIn[round] = packRIO(round, input, output);
        if(input == 0)
            _aEthRioIn[++_aEthRound] = packRIO(++round, INITIAL_INPUT, 0);
            
        (round, input, output) = unpackRIO(_onsRioIn[_onsRound]);
        output = oneVol.mul(uint(1e18).sub(ratioAEthWhenMint)).div(onsVol).mul(input.mul(onsRatio).div(1e18)).div(1e18).add(output);
        input = uint(1e18).sub(onsRatio).mul(input).div(1e18);
        _onsRioIn[round] = packRIO(round, input, output);
        if(input == 0)
            _onsRioIn[++_onsRound] = packRIO(++round, INITIAL_INPUT, 0);
            
        emit Rebase(aEthVol, aEthRatio, onsVol, onsRatio, oneVol);
    }
    event Rebase(uint aEthVol, uint aEthRatio, uint onsVol, uint onsRatio, uint oneVol);
}