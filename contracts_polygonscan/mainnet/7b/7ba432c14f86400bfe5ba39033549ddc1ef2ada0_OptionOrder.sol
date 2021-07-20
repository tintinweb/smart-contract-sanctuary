// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Option.sol";

contract Constants2 {
    address internal constant _DAI_                 = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    bytes32 internal constant _ecoAddr_             = 'ecoAddr';
    bytes32 internal constant _ecoRatio_            = 'ecoRatio';
}

struct Ask {
    uint    askID;
    address seller;
    address long;
    uint    volume;
    address settleToken;
    uint    price;
    uint    remain;
}

struct Bid {
    uint    bidID;
    uint    askID;
    address buyer;
    uint    volume;
    uint    amount;
    uint    remain;
}

contract OptionOrder is Configurable, Constants, Constants2 {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    
	bytes32 internal constant _disableCancle_   = 'disableCancle';
	bytes32 internal constant _allowContract_   = 'allowContract';
	bytes32 internal constant _allowlist_       = 'allowlist';
	bytes32 internal constant _blocklist_       = 'blocklist';

    address public factory;
    mapping(uint => Ask) public asks;
    mapping(uint => Bid) public bids;
    uint public asksN;
    uint public bidsN;
    
    address public farm;
    address public reward;
    mapping(address => uint) public settledRewards;
    mapping(address => uint) public claimedRewards;
	uint public begin;
	uint public span;
	uint public lep;            // 1: linear, 2: exponential, 3: power
	uint public times;
	uint public period;
	uint public frequency;
	uint public lasttime;
	
	mapping(address => mapping(address => uint)) public rewardThreshold;

    function initialize(address _governor, address _factory, address _farm, address _reward, address _ecoAddr) public initializer {
        super.initialize(_governor);
        factory = _factory;
        farm    = _farm;
        reward  = _reward;
        config[_ecoAddr_]  = uint(_ecoAddr);
        config[_ecoRatio_] = 0.181818181818181818 ether;    //  5% / 27.5% 
        config[_feeRate_]  = 0.1 ether;                     // 10%
        
	    //IFarm(farm).crop();                       // just check
	    IERC20(_reward).totalSupply();           // just check

        address weth = IUniswapV2Router01(OptionFactory(factory).getConfig(_uniswapRounter_)).WETH();
        setRewardThreshold(_DAI_, weth, 500 ether);
    }
    
    function setRewardThreshold(address _collateral, address _underlying, uint volume) public governance {
        rewardThreshold[_collateral][_underlying] = volume;
    }

    function setBegin(uint _lep, uint _period, uint _span, uint _begin) virtual external governance {
        lep     = _lep;         // 1: linear, 2: exponential, 3: power
        period  = _period;
        span    = _span;
        begin   = _begin;
        lasttime= _begin;
        times   = 0;
    }
    
    function sellOnETH(bool _private, address _underlying, uint _strikePrice, uint _expiry, address settleToken, uint price) virtual external payable returns (uint askID) {
        address weth = IUniswapV2Router01(OptionFactory(factory).getConfig(_uniswapRounter_)).WETH();
        IWETH(weth).deposit{value: msg.value}();
        return sell(_private, weth, _underlying, _strikePrice, _expiry, msg.value, settleToken, price);
    }
    
    function sell(bool _private, address _collateral, address _underlying, uint _strikePrice, uint _expiry, uint volume, address settleToken, uint price) virtual public returns (uint askID) {
        address weth = IUniswapV2Router01(OptionFactory(factory).getConfig(_uniswapRounter_)).WETH();
        if(_collateral != weth || IERC20(_collateral).balanceOf(address(this)) < volume)
            IERC20(_collateral).safeTransferFrom(msg.sender, address(this), volume);
        IERC20(_collateral).safeApprove(factory, volume);
        (address long, address short, uint vol) = OptionFactory(factory).mint(_private, _collateral, _underlying, _strikePrice, _expiry, volume);
        
        //address creator = _private ? tx.origin : address(0);
        //address short = OptionFactory(factory).shorts(creator, _collateral, _underlying, _strikePrice, _expiry);
        IERC20(short).safeTransfer(msg.sender, vol);

        //address long = OptionFactory(factory).longs(creator, _collateral, _underlying, _strikePrice, _expiry);
        return _sell(long, vol, settleToken, price);
    }
    
    function sell(address long, uint volume, address settleToken, uint price) virtual public returns (uint askID) {
        IERC20(long).safeTransferFrom(msg.sender, address(this), volume);
        return _sell(long, volume, settleToken, price);
    }
    
    function _sell(address long, uint volume, address settleToken, uint price) virtual internal returns (uint askID) {
        askID = asksN++;
        asks[askID] = Ask(askID, msg.sender, long, volume, settleToken, price, volume);
        
        emit Sell(askID, msg.sender, long, volume, settleToken, price);
    }
    event Sell(uint askID, address indexed seller, address indexed long, uint volume, address indexed settleToken, uint price);
    
    function reprice(uint askID, uint newPrice) virtual external returns (uint newAskID) {
        require(asks[askID].seller != address(0), 'Nonexistent ask order');
        require(asks[askID].seller == msg.sender, 'Not yours ask Order');
        
        newAskID = asksN++;
        asks[newAskID] = Ask(newAskID, asks[askID].seller, asks[askID].long, asks[askID].remain, asks[askID].settleToken, newPrice, asks[askID].remain);
        asks[askID].remain = 0;
        
        emit Reprice(askID, newAskID, asks[newAskID].seller, asks[newAskID].long, asks[newAskID].volume, asks[newAskID].settleToken, asks[askID].price, newPrice);
    }
    event Reprice(uint askID, uint newAskID, address indexed seller, address indexed long, uint volume, address indexed settleToken, uint price, uint newPrice);
    
    function cancel(uint askID) virtual external returns (uint vol) {
        require(asks[askID].seller != address(0), 'Nonexistent ask order');
        require(asks[askID].seller == msg.sender, 'Not yours ask Order');
        require(config[_disableCancle_] == 0, 'disable cancle');
        
        vol = asks[askID].remain;
        IERC20(asks[askID].long).safeTransfer(msg.sender, vol);
        asks[askID].remain = 0;

        emit Cancel(askID, msg.sender, asks[askID].long, vol);
    }
    event Cancel(uint askID, address indexed seller, address indexed long, uint vol);
    
    function calcFee(uint volume) public view returns (address recipient, uint fee) {
        uint feeRate = getConfig(_feeRate_);
        recipient = address(OptionFactory(factory).getConfig(_feeRecipient_));
        
        if(feeRate != 0 && recipient != address(0))
            fee = volume.mul(feeRate).div(1 ether);
        else
            fee = 0;
    }
    
    function buy(uint askID, uint volume) virtual public returns (uint bidID, uint vol, uint amt) {
        require(asks[askID].seller != address(0), 'Nonexistent ask order');
        vol = volume;
        if(vol > asks[askID].remain)
            vol = asks[askID].remain;
            
        amt = vol.mul(asks[askID].price).div(1 ether);
        (address recipient, uint fee) = calcFee(amt);
        address weth = IUniswapV2Router01(OptionFactory(factory).getConfig(_uniswapRounter_)).WETH();
        address settleToken = asks[askID].settleToken;
        if(settleToken != weth || address(this).balance < amt) {
            IERC20(settleToken).safeTransferFrom(msg.sender, asks[askID].seller, amt.sub(fee));
            if(recipient != address(0) && fee > 0)
                IERC20(settleToken).safeTransferFrom(msg.sender, recipient, fee);
        } else {
            payable(asks[askID].seller).transfer(amt.sub(fee));
            if(recipient != address(0) && fee > 0)
                payable(recipient).transfer(fee);
        }
        asks[askID].remain = asks[askID].remain.sub(vol);
        IERC20(asks[askID].long).safeTransfer(msg.sender, vol);
        
        bidID = bidsN++;
        bids[bidID] = Bid(bidID, askID, msg.sender, vol, amt, vol);
        
        emit Buy(bidID, askID, msg.sender, vol, amt);
    }
    event Buy(uint bidID, uint askID, address indexed buyer, uint vol, uint amt);
    
    function buyInETH(uint askID, uint volume) virtual external payable returns (uint bidID, uint vol, uint amt) {
        require(asks[askID].seller != address(0), 'Nonexistent ask order');
        address weth = IUniswapV2Router01(OptionFactory(factory).getConfig(_uniswapRounter_)).WETH();
        require(asks[askID].settleToken == weth, 'settleToken is NOT WETH');

        vol = volume;
        if(vol > asks[askID].remain)
            vol = asks[askID].remain;
            
        amt = vol.mul(asks[askID].price).div(1 ether);
        require(msg.value >= amt, 'value is too low');
        
        (bidID, vol, amt) = buy(askID, vol);
        
        if(msg.value > amt)
            msg.sender.transfer(msg.value.sub(amt));
    }
    
    function exercise(uint bidID) virtual external returns (uint vol, uint fee, uint amt) {
        return exercise(bidID, bids[bidID].remain, new address[](0));
    }
    function exercise(uint bidID, address[] calldata path) virtual external returns (uint vol, uint fee, uint amt) {
        return exercise(bidID, bids[bidID].remain, path);
    }
    function exercise(uint bidID, uint volume) virtual public returns (uint vol, uint fee, uint amt) {
        return exercise(bidID, volume, new address[](0));
    }
    function exercise(uint bidID, uint volume, address[] memory path) virtual public returns (uint vol, uint fee, uint amt) {
        require(bids[bidID].buyer == msg.sender, 'Nonexistent or not yours bid order');
        if(volume > bids[bidID].remain)
            volume = bids[bidID].remain;
        bids[bidID].remain = bids[bidID].remain.sub(volume);
        
        address long = asks[bids[bidID].askID].long;
        IERC20(long).safeTransferFrom(msg.sender, address(this), volume);
        
        if(path.length == 0) {
            amt = OptionFactory(factory).calcExerciseAmount(long, volume);
            address weth = IUniswapV2Router01(OptionFactory(factory).getConfig(_uniswapRounter_)).WETH();
            address underlying = LongOption(long).underlying();
            if(underlying != weth || IERC20(underlying).balanceOf(address(this)) < amt)
                IERC20(underlying).safeTransferFrom(msg.sender, address(this), amt);
            IERC20(underlying).safeApprove(factory, amt);
        }
        
        (vol, fee, amt) = OptionFactory(factory).exercise(long, volume, path);
        IERC20(LongOption(long).collateral()).safeTransfer(msg.sender, vol);

        _settleReward(msg.sender, LongOption(long).collateral(), LongOption(long).underlying(), volume);
        emit Exercise(bidID, msg.sender, vol, fee, amt);
    }
    event Exercise(uint bidID, address indexed buyer, uint vol, uint fee, uint amt);
    
    function exerciseETH(uint bidID, uint volume) virtual public payable returns (uint vol, uint fee, uint amt) {
        require(bids[bidID].buyer != address(0), 'Nonexistent bid order');
        address long = asks[bids[bidID].askID].long;
        address underlying = LongOption(long).underlying();
        address weth = IUniswapV2Router01(OptionFactory(factory).getConfig(_uniswapRounter_)).WETH();
        require(underlying == weth, 'underlying is NOT WETH');

        if(volume > bids[bidID].remain)
            volume = bids[bidID].remain;
        amt = OptionFactory(factory).calcExerciseAmount(long, volume);
        require(msg.value >= amt, 'value is too low');
        
        IWETH(weth).deposit{value: amt}();
        (vol, fee, amt) = exercise(bidID, volume, new address[](0));
        
        if(msg.value > amt)
            msg.sender.transfer(msg.value.sub(amt));
    }
    function exerciseETH(uint bidID) virtual external payable returns (uint vol, uint fee, uint amt) {
        return exerciseETH(bidID, bids[bidID].remain);
    }

    function waive(uint bidID) virtual external {
        waive(bidID, bids[bidID].remain);
    }
    function waive(uint bidID, uint volume) virtual public returns (uint vol) {
        vol = volume;
        if(vol > bids[bidID].remain)
            vol = bids[bidID].remain;
        bids[bidID].remain = bids[bidID].remain.sub(vol);

        address long = asks[bids[bidID].askID].long;
        IERC20(long).safeTransferFrom(msg.sender, address(this), vol);
        LongOption(long).burn(vol);
        
        _settleReward(msg.sender, LongOption(long).collateral(), LongOption(long).underlying(), vol);
        emit Waive(bidID, msg.sender, vol);
    }
    event Waive(uint bidID, address indexed buyer, uint vol);
    
    function _settleReward(address buyer, address _collateral, address _underlying, uint volume) virtual internal returns (uint amt) {
        if(begin == 0 || begin >= now)
            return 0;
            
        amt = settleableReward(_collateral, _underlying, volume);
        if(amt == 0)
            return 0;

        _updateFrequency();

        settledRewards[buyer] = settledRewards[buyer].add(amt);
        
        uint a = 0;
        address addr = address(config[_ecoAddr_]);
        uint ratio = config[_ecoRatio_];
        if(addr != address(0) && ratio != 0) {
            a = amt.mul(ratio).div(1 ether);
            settledRewards[addr] = settledRewards[addr].add(a);
        }

        settledRewards[address(0)] = settledRewards[address(0)].add(amt).add(a);

        emit SettleReward(buyer, _collateral, _underlying, volume, amt, settledRewards[buyer]);
    }
    event SettleReward(address indexed buyer, address indexed _collateral, address indexed _underlying, uint volume, uint amt, uint settled);

    function settleableReward(address _collateral, address _underlying, uint volume) public view returns (uint) {
        uint threshold = rewardThreshold[_collateral][_underlying];
        if(threshold == 0 || volume < threshold)
            return 0;
        else
            return settleableReward();
    }
    function settleableReward() public view returns (uint amt) {
        if(begin == 0 || begin >= now)
            return 0;
            
        amt = IERC20(reward).allowance(farm, address(this)).add(claimedRewards[address(0)]).sub(settledRewards[address(0)]);
        
        // calc settleable in period
        if(lep == 3) {                                                              // power
            //uint r0 = amt.mul(period).div(now.add(span).sub(begin));
            //uint r1 = amt.mul(period).div(now.add(span).sub(begin).add(period));
            //amt = r0.sub(r1);
            uint y = period.mul(1 ether).div(lasttime.add(span).sub(begin));
            amt = amt.mul(1 ether).div(y);
            y = period.mul(1 ether).div(now.add(span).sub(begin));
            y = y.mul(y).div(1 ether);
            amt = amt.mul(y).div(1 ether);
        } else if(lep == 2) {                                                       // exponential
            if(period < span)
                amt = amt.mul(period).div(span);
        }else if(now.add(period) < begin.add(span))                                 // linear
            amt = amt.mul(period).div(begin.add(span).sub(now));
        else if(now >= begin.add(span))
            amt = 0;
    
        amt = amt.mul(1 ether).div(calcFrequency());
    }
    
    function calcFrequency() public view returns (uint f) {
        if(now < begin.add(period))
            if(now > begin)
                f = times.add(1 ether).mul(period).div(now.sub(begin));
            else
                f = uint(-1);
        else
            if(lasttime.add(period) > now)
                f = lasttime.add(period).sub(now).mul(frequency).div(period).add(1 ether);
            else
                f = 1 ether;
    }
    
    function _updateFrequency() internal returns(uint) {
        frequency = calcFrequency();
        times = times.add(1 ether);
        lasttime = now;
    }

    function getReward() external {
        claim();
    }
    function claim() virtual public returns (uint amt) {
        require(getConfig(_blocklist_, msg.sender) == 0, 'In blocklist');
        bool isContract = msg.sender.isContract();
        require(!isContract || config[_allowContract_] != 0 || getConfig(_allowlist_, msg.sender) != 0, 'No allowContract');

        amt = claimable(msg.sender);
        IERC20(reward).safeTransferFrom(farm, msg.sender, amt);
        claimedRewards[msg.sender] = settledRewards[msg.sender];
        claimedRewards[address(0)] = claimedRewards[address(0)].add(amt);
        
        emit Claim(msg.sender, amt, claimedRewards[msg.sender]);
    }
    event Claim(address indexed seller, uint amt, uint claimed);

    function earned(address account) external view returns (uint256) {
        return claimable(account);
    }
    function claimable(address buyer) public view returns (uint) {
        return settledRewards[buyer].sub(claimedRewards[buyer]);
    }
    
}