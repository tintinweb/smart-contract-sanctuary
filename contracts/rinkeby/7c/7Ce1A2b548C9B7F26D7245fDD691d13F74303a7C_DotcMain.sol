// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import './IERC20.sol';
import "./EnumerableSet.sol";
import './SafeMath.sol';
import './owned.sol';
import './PriceOracle.sol';

contract DotcMain is owned {
    using SafeMath for uint256;

    uint256 public constant FROZEN_SPAN = 30*86400;

    bool public is_stop; //设置是否停止

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelist;

    /// @notice 支持交易和抵押的资产
    struct Token{
	string symbol;
	address addr;
    }
    Token[] public allTokens;
    mapping (address => Token) internal tokenMap; //支持资产的Map

    /// @notice 抵押资产结构
    struct Collateral{
	Token token;
	uint256 token_amount;
    }

    /// @notice 卖家的广告，卖家资产按广告质押
    struct Ad{
	address token;		//这里是USDT/USDC/DAI地址
	uint256 ad_id; 		//广告ID
	uint256 token_amount; 	//币数量
	uint256 fiat_price; 	//最低单价
	uint256 low_limit; 	//订单最低限额
	uint256 high_limit; 	//订单最高限额
	uint40 place_time; 	//广告上架时间
	uint8 status; 		//广告状态：1-刚上架，0成交，2-部分成交，3-完全成交, 4-卖家撤单
    }

    /// @notice 订单结构, 买家资产按照订单质押
    struct Order{
	uint256 order_id; 	//订单ID
	uint256 token_amount; 	//币数量
	uint256 price; 		//单价
	address seller;
	address buyer;
	address token;		//这里是USDT/USDC/DAI的地址
	uint40 open_time; 	//订单开始时间
	uint40 close_time; 	//订单结束时间 
	uint40 status; //订单状态：1-买家已锁定，未付款；2-买家已标记付款，订单完成； 3-买家付款超时或者被卖家标记为未付款； 4-交易被买家取消； 5-交易被卖家取消； 6-卖家标记已收款，订单完成 7-仲裁中
	              //71-冻卡、72-少U、73-卡有误、74-少付钱、75-限额、76-超时
    }
    mapping (address => mapping(uint256 => Collateral[])) buyerCollateral; 	//买家在每个订单的抵押列表(地址-订单ID-质押数组)
    mapping (address => mapping(uint256 => Collateral[])) sellerCollateral; 	//卖家在每个订单的抵押列表（地址-广告ID-质押数组）

    uint256 public total_ad_num = 0; 				//广告数
    mapping (uint256 => Ad) adMaps; 			//用户的广告（全局）
    uint256 public total_order_num = 0; 			//订单数
    mapping (uint256 => Order) orderMaps; 		//用户的订单（全局）

    mapping (address => uint256[]) userAdsMap; 		//用户发布的订单列表
    mapping (address => uint256[]) userOrdersMap; 	//用户相关的订单列表
    mapping (address => uint256[]) userPenaltyMap; 	//用户相关的被惩罚订单列表

    mapping (address => uint40) frozen_times; 		//用户冻结时间(秒为单位)
    mapping (address => mapping(address => uint256)) user_balances; 		//用户资金余额


    uint256 public minAdQuantityMantissa; 		//卖单最小金额 1e18
    uint256 public buyerPenaltyRatioMantissa; 		//买方撤单惩罚*1e18
    uint256 public sellerPenaltyRatioMantissa; 		//卖方撤单惩罚*1e18
    uint256 public buyerCollateralRatioMantissa; 	//买方抵押额度*1e18
    uint256 public sellerCollateralRatioMantissa; 	//卖方抵押额度*1e18
    uint256 public takerFeeRatioMantissa; 		//taker手续费*1e18
    uint256 public makerFeeRatioMantissa; 		//maker手续费*1e18
    uint256 public buyerUnpayPenaltyRationMantissa; 	//买方24h未付款惩罚*1e18
    uint256 public sellerCardRatioMantissa; 		//卖方卡有问题导致买家订单关闭*1e18
    uint256 public buyerFailedArbitrationMantissa; 	//买方申诉失败惩罚*1e18
    uint256 public sellerFailedArbitrationMantissa; 	//卖方申诉失败惩罚*1e18
    uint256 public buyerBlackMoneyPenaltyMantissa; 	//买方黑钱惩罚*1e18
    uint256 public sellerBlackUPenaltyMantissa; 	//卖方黑U惩罚*1e18
    address payable public fee_wallet;
    PriceOracle oracle; 
    IERC20 usdt;
    IERC20 usdc;
    IERC20 dai;

    //事件
    event NewAdOrder(address indexed token, address indexed seller, uint256 order_id, uint256 fiat_price, uint256 low_limit, uint256 high_limit, uint256 dotc_amount, address[] collateral_tokens, uint256[] collateral_dotc_values);
    event NewSellOrder(address indexed token, address indexed seller, uint256 order_id, uint256 price, uint256 amount);
    event NewBuyOrder(address indexed token, address indexed buyer, uint256 order_id, uint256 price, uint256 amount, address[] collateral_tokens, uint256[] collateral_dotc_values);
    event OrderCanceled(address indexed token, address indexed buyer, uint256 order_id, uint256 price, uint256 amount);
    event OrderPaidBuyer(address indexed token, address indexed buyer, uint256 order_id, uint256 price, uint256 amount);
    event OrderUnpaidSeller(address indexed token, address indexed seller, uint256 order_id, uint256 price, uint256 amount);
    event OrderArbitrationBuyer(address indexed token, address indexed buyer, uint256 order_id, uint256 price, uint256 amount, uint40 status, string reason);
    event OrderArbitrationSeller(address indexed token, address indexed seller, uint256 order_id, uint256 price, uint256 amount, uint40 status, string reason);
    event TokenDeposited(address indexed token, address indexed account, uint256 amount);
    event TokenWithdrawn(address indexed token, address indexed account, uint256 amount);
    event NewOracle(address oldOracle, address newOracle);
    event NewTokenAdded(address indexed tokenAddress, string symbol);
    event NewArbitrationStatus(uint256 indexed order_id, uint40 status, bool isMatch);

    constructor(address oracleAddress, address usdtAddress, address usdcAddress, address daiAddress) {
	oracle = PriceOracle(oracleAddress);

	allTokens.push(Token({symbol:"USDT", addr:usdtAddress}));
	tokenMap[usdtAddress] = Token({symbol:"USDT", addr:usdtAddress});
    	usdt = IERC20(usdtAddress);

	allTokens.push(Token({symbol:"USDC", addr:usdcAddress}));
	tokenMap[usdcAddress] = Token({symbol:"USDC", addr:usdcAddress});
    	usdc = IERC20(usdcAddress);

	allTokens.push(Token({symbol:"DAI", addr:daiAddress}));
	tokenMap[daiAddress] = Token({symbol:"DAI", addr:daiAddress});
    	dai = IERC20(daiAddress);

	is_stop = false;
	minAdQuantityMantissa = 18e6;
	buyerCollateralRatioMantissa = 1e18;
	sellerCollateralRatioMantissa = 1e18;
	buyerPenaltyRatioMantissa = 0.1e18;
	sellerPenaltyRatioMantissa = 0;
	buyerUnpayPenaltyRationMantissa = 0.5e18;
	sellerCardRatioMantissa = 0.1e18;
	buyerFailedArbitrationMantissa = 0.1e18;
	sellerFailedArbitrationMantissa = 0.1e18;
	buyerBlackMoneyPenaltyMantissa = 1e18;
	sellerBlackUPenaltyMantissa = 1e18;
	takerFeeRatioMantissa = 0.01e18;
	makerFeeRatioMantissa = 0.01e18;
	fee_wallet = payable(msg.sender);
    }

    //用户把资产从dotc合约提取到钱包
    function withdraw(address token, uint256 amount) public {
	uint256 amt = user_balances[msg.sender][token];
	if(amount > amt )
		amount = amt;
	IERC20(token).transfer(msg.sender, amount);
	user_balances[msg.sender][token] = user_balances[msg.sender][token].sub(amount);
	emit TokenWithdrawn(token, msg.sender, amount);
    }

    // 用户从钱包充值到dotc合约
    function deposit(address token, uint256 amount) public {
	require(amount <= IERC20(token).balanceOf(msg.sender));
	IERC20(token).transferFrom(msg.sender, address(this), amount);
	user_balances[msg.sender][token] = user_balances[msg.sender][token].add(amount);
	emit TokenDeposited(token, msg.sender, amount);
    }

    //用户把资产从抵押提取到dotc账户
    //type=1: 卖单
    //type=2: 买单
    function withdraw_collateral(uint side, uint256 order_id) public {
	address account = msg.sender;
	uint40 frozen_span = uint40(frozen_times[account]);
	if(side == 1)
	{
		Ad memory ad = adMaps[order_id];
		require(ad.status == 3);
		require(block.timestamp-ad.place_time >= frozen_span);

		Collateral[] memory cols = sellerCollateral[account][order_id];
		for(uint256 i=0; i<cols.length; i++)
		{
			Collateral memory col = cols[i];
			if(col.token_amount > 0)
				user_balances[account][col.token.addr] = user_balances[account][col.token.addr].add(col.token_amount);
		}
		delete sellerCollateral[account][order_id];
	}else if(side == 2)
	{
		require(isReleasable(account, order_id));
		
		Collateral[] memory cols = buyerCollateral[account][order_id];
		for(uint256 i=0; i<cols.length; i++)
		{
			Collateral memory col = cols[i];
			if(col.token_amount > 0)
				user_balances[account][col.token.addr] = user_balances[account][col.token.addr].add(col.token_amount);
		}
		delete buyerCollateral[account][order_id];
	}
    }

    // 批量质押 
    function batch_collateral(address[] memory collateral_tokens, uint256[] memory collateral_wallet_values) public returns (bool){
	require(collateral_tokens.length>0 && collateral_tokens.length == collateral_wallet_values.length);
	for(uint i=0; i<collateral_tokens.length; i++)
	{
		address token_addr = collateral_tokens[i];
		if(collateral_wallet_values[i]>0)
		{
			IERC20(token_addr).transferFrom(msg.sender, address(this), collateral_wallet_values[i]);
			user_balances[msg.sender][token_addr] = user_balances[msg.sender][token_addr].add(collateral_wallet_values[i]);
			emit TokenDeposited(token_addr, msg.sender, collateral_wallet_values[i]);
		}
	}
	return true;
    }
    // 批量提现
    function batch_withdraw(address[] memory tokens, uint256[] memory values) public returns (bool){
	require(tokens.length>0 && tokens.length == values.length);
	for(uint i=0; i<tokens.length; i++)
	{
		address token_addr = tokens[i];
		if(values[i]>0)
		{
			require(user_balances[msg.sender][token_addr]>=values[i]);
			IERC20(token_addr).transfer(msg.sender, values[i]);
			user_balances[msg.sender][token_addr] = user_balances[msg.sender][token_addr].sub(values[i]);
			emit TokenWithdrawn(token_addr, msg.sender, values[i]);
		}
	}
	return true;
    }
    /**  
     * 新广告订单
     * token - 要售卖的Token合约地址
     * fiat_price - CNY价格, 这里传最低出售价格，精度18
     * dotc_amount - 从DOTC账户里导入的数量 
     * low_limit - 最低限额，单位CNY，小数点后2位，这里精度是18
     * high_limit - 最高限额，单位CNY，小数点后2位，这里精度是18
     * collateral_tokens - 抵押资产的合约地址[这里是数组后面的值要跟这里一一对齐，否则会出错]
     * collateral_dotc_values - 来自DOTC账户抵押资产的数量, 要跟前面的collateral_tokens数组对齐
     *
     */
    function new_sell_ad_order(address token_addr, uint256 fiat_price, uint256 low_limit, uint256 high_limit, uint256 dotc_amount, address[] memory collateral_tokens, uint256[] memory collateral_dotc_values) public returns (uint256){
	require(is_stop == false, "Sys stopped");
	require(isListed(token_addr), "not supported");
	require(token_addr != address(0), "0x0");
	require(fiat_price > 0, "price is 0");
	require(low_limit>0 && high_limit>0 && high_limit>low_limit, "limits.");
	require(dotc_amount >= minAdQuantityMantissa, "min ad quantity required");
	require(collateral_tokens.length>0 && collateral_tokens.length == collateral_dotc_values.length, "Collateral check");

	require(user_balances[msg.sender][token_addr] >= dotc_amount, "values not match");
	total_ad_num = total_ad_num.add(1);

	for(uint i=0; i<collateral_tokens.length; i++)
	{
		Token memory tk = tokenMap[collateral_tokens[i]];
		require(user_balances[msg.sender][tk.addr] >= collateral_dotc_values[i], "insuf collateral");
		user_balances[msg.sender][tk.addr] = user_balances[msg.sender][tk.addr].sub(collateral_dotc_values[i]);
		if(tk.addr == token_addr)
		{
			require(user_balances[msg.sender][token_addr] >= dotc_amount, "insuf");
			user_balances[msg.sender][token_addr] = user_balances[msg.sender][token_addr].sub(dotc_amount);
		}
		Collateral[] storage collateral = sellerCollateral[msg.sender][total_ad_num];
		collateral.push(Collateral({token:tk, token_amount:collateral_dotc_values[i]}));
	}

	Ad memory ad = Ad({
		ad_id: total_ad_num,
		token: token_addr,
		token_amount: dotc_amount,
		fiat_price: fiat_price,
		low_limit: low_limit,
		high_limit: high_limit,
		status: 1,
		place_time: uint40(block.timestamp)
	});
	adMaps[total_ad_num] = ad;
	userAdsMap[msg.sender].push(total_ad_num);

    	emit NewAdOrder(token_addr, msg.sender, total_ad_num, fiat_price, low_limit, high_limit, dotc_amount, collateral_tokens, collateral_dotc_values);
	return total_ad_num;
    }

    function _new_order(address seller_addr, uint256 ad_id, address buyer_addr, address token_addr, uint256 token_amount, uint256 token_price) internal returns (uint256) {

	Ad storage ad = adMaps[ad_id];
	require(ad.status == 1 || ad.status == 2, "Done or canceled.");

	total_order_num = total_order_num.add(1);
	ad.token_amount = ad.token_amount.sub(token_amount);
	if(ad.token_amount == 0)
	{
		ad.status = 3;
		uint ind = 0;
		for(uint i=0; i<userAdsMap[seller_addr].length; i++)
			if(userAdsMap[seller_addr][i] == ad_id)
				ind = i;
		delete userAdsMap[seller_addr][ind];
	}else
		ad.status = 2;
	
	//charge fee
	uint256 taker_fee = token_amount.mul(takerFeeRatioMantissa).div(1e18);
	IERC20(token_addr).transfer(fee_wallet, taker_fee);
	uint256 maker_fee = token_amount.mul(makerFeeRatioMantissa).div(1e18);
	IERC20(token_addr).transfer(fee_wallet, maker_fee);

	Order memory order = Order ({
		order_id: total_order_num,
		seller: seller_addr,
	        buyer: buyer_addr,
		token: token_addr,
		token_amount: token_amount.sub(taker_fee),
		price: token_price,
		status: 1,
		open_time: uint40(block.timestamp),
		close_time: 0	
	});
	orderMaps[total_order_num] = order;
	userOrdersMap[buyer_addr].push(total_order_num);
	userOrdersMap[seller_addr].push(total_order_num);
	user_balances[msg.sender][token_addr] = user_balances[msg.sender][token_addr].add(token_amount);
   	return total_order_num; 
    }
    //seller撤单
    function seller_cancel_order(uint256 ad_id) public returns (uint256) {
	Ad storage ad = adMaps[ad_id];
	address seller_addr = msg.sender;
	uint ind = 0;
	bool is_contains = false;
	for(uint i=0; i<userAdsMap[seller_addr].length; i++)
	{
		if(userAdsMap[seller_addr][i] == ad_id)
		{
			ind = i;
			is_contains = true;
			break;
		}
	}
	require(is_contains == true, "contains ad order");

	if(ad.token_amount == 0)
	{
		ad.status = 3;
		delete userAdsMap[seller_addr][ind];
		return 0;
	}else
		ad.status = 4;
	
	//charge fee
	uint256 fee = ad.token_amount.mul(sellerPenaltyRatioMantissa).div(1e18);
	if(fee > 0)
		IERC20(ad.token).transfer(fee_wallet, fee);

	user_balances[msg.sender][ad.token] = user_balances[msg.sender][ad.token].add(ad.token_amount.sub(fee));
   	return ad.token_amount.sub(fee); 
    }

    /**  
     * 新买单订单，这里只考虑Taker的情况
     * token - 要购买的Token合约地址
     * buy_price - CNY价格, 精度18
     * buy_amount - 目标token的数量 
     * collateral_tokens - 抵押资产的合约地址[这里是数组后面的值要跟这里一一对齐，否则会出错]
     * collateral_dotc_values - 来自DOTC账户抵押资产的数量, 要跟前面的collateral_tokens数组对齐
     *
     */
    function new_buy_order(address token_addr, uint256 buy_price, uint256 buy_amount, address seller_addr, uint256 sell_ad_id, address[] memory collateral_tokens, uint256[] memory collateral_dotc_values) public returns (uint256){
	require(is_stop == false, "Sys stopped");
	require(isListed(token_addr), "not supported");
	require(seller_addr != address(0));
	require(buy_price > 0, "Price is 0");
	require(buy_amount > 0, "<=0");
	require(collateral_tokens.length>0 && collateral_tokens.length == collateral_dotc_values.length, "Collateral check.");

	require(adMaps[sell_ad_id].token == token_addr, "Wrong match!");
	//TODO:此处购买数量可否拆碎？
	//如果Ad不足，则按照剩余数量成交，则buy_amount需要更新
	require(adMaps[sell_ad_id].token_amount >= buy_amount, "Insuf in sell Ad");
	require(buy_price >= adMaps[sell_ad_id].fiat_price, "price required");
	uint256 decimal = IERC20(token_addr).decimals();
	require(buy_amount.mul(buy_price).div(10**decimal)>=adMaps[sell_ad_id].low_limit && buy_amount.mul(buy_price).div(10**decimal)<=adMaps[sell_ad_id].high_limit, "Limits");

	// check is over, start to create new buy order.
	for(uint i=0; i<collateral_tokens.length; i++)
	{
		Token memory tk = tokenMap[collateral_tokens[i]];
		require(user_balances[msg.sender][tk.addr] >= collateral_dotc_values[i], "insuffcient collateral");
		user_balances[msg.sender][tk.addr] = user_balances[msg.sender][tk.addr].sub(collateral_dotc_values[i]);
		Collateral[] storage collateral = buyerCollateral[msg.sender][total_ad_num];
		collateral.push(Collateral({token:tk, token_amount:collateral_dotc_values[i]}));
	}
	//for test
	uint256 order_id = _new_order(seller_addr, sell_ad_id, msg.sender, token_addr, buy_amount, buy_price);

    	emit NewSellOrder(token_addr, seller_addr, order_id, buy_price, buy_amount);
    	emit NewBuyOrder(token_addr, msg.sender, order_id, buy_price, buy_amount, collateral_tokens, collateral_dotc_values);
	return order_id;
    }

    /// @notice Buyer cancel the order
    function buyer_cancel_order(uint256 order_id) external {
	require(is_stop == false, "Sys stopped");
    	require(order_id <= total_order_num, "exceeds range");
	Order storage order = orderMaps[order_id];
	require(order.order_id == order_id, "not match!");
	require(order.status == 1, "Only unpaid can be canceled");
	
	order.status = 4;
	order.close_time = uint40(block.timestamp);
	uint256 penalty = order.token_amount.mul(buyerPenaltyRatioMantissa).div(1e18);
	IERC20(order.token).transfer(fee_wallet, penalty);
	
	//FIXME: 假如用户没有当前订单里的币作为质押呢？什么顺序扣罚金呢？扣多少呢？
    	emit OrderCanceled(order.token, order.buyer, order.order_id, order.price, order.token_amount);
    }

    /// @notice Buyer labels order to "paid"
    /// @dev -
    function buyer_label_paid(uint256 order_id) external {
	require(is_stop == false, "Sys stopped");
	Order storage order = orderMaps[order_id];
	require(order.order_id == order_id, "Order not match!");
	require(order.status != 4 && order.status != 5 && order.status != 6, "Only uncompleted can be labeled.");
	order.status = 2;
	order.close_time = uint40(block.timestamp);
	
    	emit OrderPaidBuyer(order.token, order.buyer, order.order_id, order.price, order.token_amount);
    }

    /// @notice Buyer labels order to arbitration
    /// @dev -
    function buyer_label_arbitration(uint256 order_id, uint40 status, string memory reason) external {
	require(is_stop == false, "Sys stopped");
	Order storage order = orderMaps[order_id];
	require(order.order_id == order_id, "Order not match!");
	require(order.status != 4 && order.status != 5 && order.status != 6, "Only uncompleted can be labeled.");
	order.status = status;
    	
	emit OrderArbitrationBuyer(order.token, order.buyer, order_id, order.price, order.token_amount, status, reason);
    }

    /// @notice Seller labels order to arbitration
    /// @dev -
    function seller_label_arbitration(uint256 order_id, uint40 status, string memory reason) external {
	require(is_stop == false, "Sys stopped");
	Order storage order = orderMaps[order_id];
	require(order.order_id == order_id, "Order not match!");
	require(order.status != 4 && order.status != 5 && order.status != 6, "Only uncompleted can be labeled.");
	order.status = status;

    	emit OrderArbitrationSeller(order.token, order.seller, order_id, order.price, order.token_amount, status, reason);
    }
    
    // @notice get all tokens  
    function getAllTokens() external view returns (Token [] memory)
    {
	    return allTokens;
    }
    // @notice get length of token list
    function getAllTokensLength() external view returns (uint)
    {
	    return allTokens.length;
    }
    /**
     * Admin operations
     */
    //添加新的可交易资产
    function _addToken(string memory symbol, address tokenAddress) onlyOwner public {
	require(!isListed(tokenAddress), "token has been listed.");
        allTokens.push(Token({symbol:symbol, addr:tokenAddress}));
        tokenMap[tokenAddress] = Token({symbol:symbol, addr:tokenAddress});
	emit NewTokenAdded(tokenAddress, symbol);
    }
    //设置Orcale
    function _setOracle(address oracleAddress) onlyOwner public {
        address oldOracle = address(oracle);
	oracle = PriceOracle(oracleAddress);
	emit NewOracle(oldOracle, oracleAddress);
    }

    //设置是否停止系统
    function _setIsStop(bool isStop) onlyOwner public {
	    is_stop = isStop;
    }

    //设置卖单最小金额
    function _setAdQuantityMantissa(uint256 limit) onlyOwner public {
	minAdQuantityMantissa = limit;
    }
   
    //设置买方撤单罚没比例
    function _setBuyerPenaltyRatioMantissa(uint256 ratio) onlyOwner public {
	buyerPenaltyRatioMantissa = ratio;
    }

    //设置卖方撤单罚没比例
    function _setSellerPenaltyRatioMantissa(uint256 ratio) onlyOwner public {
	sellerPenaltyRatioMantissa = ratio;
    }

    //设置买方抵押额度
    function _setBuyerCollateralRatioMantissa(uint256 ratio) onlyOwner public {
	buyerCollateralRatioMantissa = ratio;
    }

    //设置卖方抵押额度
    function _setSellerCollateralRatioMantissa(uint256 ratio) onlyOwner public {
	sellerCollateralRatioMantissa = ratio;
    }

    //设置taker手续费
    function _setTakerFeeRatioMantissa(uint256 ratio) onlyOwner public {
	takerFeeRatioMantissa = ratio;
    }

    //设置maker手续费
    function _setMakerFeeRatioMantissa(uint256 ratio) onlyOwner public {
	makerFeeRatioMantissa = ratio;
    } 

    //设置买方24h未付款惩罚比例
    function _setBuyerUnpayPenaltyRatioMantissa(uint256 ratio) onlyOwner public {
	buyerUnpayPenaltyRationMantissa = ratio;
    }

    //设置卖方卡有问题惩罚比例
    function _setSellerCardPenaltyRatioMantissa(uint256 ratio) onlyOwner public {
	sellerCardRatioMantissa = ratio;
    }

    //设置买方申诉失败惩罚
    function _setBuyerFailedArbitrationMantissa(uint256 ratio) public {
    	buyerFailedArbitrationMantissa = ratio;
    }

    //设置卖方申诉失败惩罚
    function _setSellerFailedArbitrationMantissa(uint256 ratio) public {
    	sellerFailedArbitrationMantissa = ratio;
    }

    //设置买方黑钱惩罚
    function _setBuyerBlackMoneyPenaltyMantissa(uint256 ratio) public {
    	buyerBlackMoneyPenaltyMantissa = ratio;
    }

    //设置卖方黑U惩罚
    function _setSellerBlackUPenaltyMantissa(uint256 ratio) public {
	    sellerBlackUPenaltyMantissa = ratio;
    }

    //设置手续费接收钱包
    function _setFeeWallet(address payable wallet) onlyOwner public {
	fee_wallet = wallet;
    }

    //管理员设置仲裁状态
    function _setArbitrationStatus(uint256 order_id, uint40 status, bool is_match, address[] memory buyer_collateral_tokens, uint256[] memory buyer_values, address[] memory seller_collateral_tokens, uint256[] memory seller_values) onlyOwner public {
	Order storage order = orderMaps[order_id];
	require(order.order_id == order_id, "Order not match!");
	order.status = status;

	Collateral[] storage b_cols = buyerCollateral[order.buyer][order_id];
	for(uint i=0; i<b_cols.length; i++)
	{
		for(uint j=0; j<buyer_collateral_tokens.length; j++)
		{
			if(b_cols[i].token.addr == buyer_collateral_tokens[j])
			{
				require(b_cols[i].token_amount >= buyer_values[j], "insufficient collateral");
				b_cols[i].token_amount = b_cols[i].token_amount.sub(buyer_values[j]);
			}
		}
	}
	if(buyer_collateral_tokens.length > 0)
		userPenaltyMap[order.buyer].push(order_id);
	Collateral[] storage s_cols = sellerCollateral[order.seller][order_id];
	for(uint i=0; i<s_cols.length; i++)
	{
		for(uint j=0; j<seller_collateral_tokens.length; j++)
		{
			if(s_cols[i].token.addr == seller_collateral_tokens[j])
			{
				require(s_cols[i].token_amount >= seller_values[j], "insufficient collateral");
				s_cols[i].token_amount = s_cols[i].token_amount.sub(seller_values[j]);
			}
		}
	}
	if(seller_collateral_tokens.length > 0)
		userPenaltyMap[order.seller].push(order_id);
	emit NewArbitrationStatus(order_id, status, is_match);
    }

    //获取仲裁状态
    function getArbitrationStatus(uint256 order_id) onlyOwner public view returns (uint40){
	Order storage order = orderMaps[order_id];
	return order.status;
    }

    /*
     *   Only external call
     */
    //获得用户的买单质押资产列表
    function getUserBuyCollateralList(address account, uint256 order_id) view external returns (Collateral[] memory) {
    	return buyerCollateral[account][order_id];
    }
    //获得用户的卖单质押资产列表
    function getUserSellCollateralList(address account, uint256 order_id) view external returns (Collateral[] memory) {
    	return sellerCollateral[account][order_id];
    }
    //获得用户的卖单详情
    function getUserSellAdInfo(uint256 order_id) view external returns (Ad  memory) {
    	return adMaps[order_id];
    }
    //获得用户的订单详情
    function getUserBuyOrderInfo(uint256 order_id) view external returns (Order  memory) {
    	return orderMaps[order_id];
    }
    //获得用户的卖单记录相关数组
    function getUserAdOrderList(address account) view external returns (uint256[] memory) {
    	return userAdsMap[account];
    }
    //获得用户的订单记录相关数组
    function getUserOrderList(address account) view external returns (uint256[] memory) {
    	return userOrdersMap[account];
    }
    //获得用户的惩罚记录相关数组
    function getUserPenaltyOrderList(address account) view external returns (uint256[] memory) {
    	return userPenaltyMap[account];
    }
    //获得用户的所有现货列表以及余额（symbol, address, balance）
    function getUserTokenList(address account) view external returns (string[] memory symbols, address[] memory addrs, uint256[] memory amounts) {
	uint len = allTokens.length;
	if(len>0)
	{
		symbols = new string[](len);
		addrs = new address[](len);
		amounts = new uint256[](len);
		for(uint i=0; i<len; i++)
		{
			Token memory tk = allTokens[i];
			symbols[i] = tk.symbol;
			addrs[i] = tk.addr;
			amounts[i] = user_balances[account][tk.addr];
		}
	}
    }
    //获得用户某个token的可用余额，因为时间变化，只能实时获取。
    function getTokenAvailableAmount(address token, address account) view external returns(uint256) {
	uint256 amount = user_balances[account][token];
	if(total_order_num > 0)
	{
		for(uint i=0; i<userOrdersMap[account].length; i++)
		{
			uint256 order_id = userOrdersMap[account][i];
			Order storage order = orderMaps[order_id];
			if(order.token != token)
				continue;
			if(account == order.buyer)
			{
				if(!isReleasable(account, i))
					continue;
				for(uint j=0; j<buyerCollateral[account][i].length; j++)
				{
					if(token != buyerCollateral[account][i][j].token.addr)
						continue;
					amount = amount.add(buyerCollateral[account][i][j].token_amount);
				}				
			}
			if(account == order.seller)
			{
				if(!isReleasable(account, i))
					continue;
				for(uint j=0; j<sellerCollateral[account][i].length; j++)
				{
					if(token != sellerCollateral[account][i][j].token.addr)
						continue;
					amount = amount.add(sellerCollateral[account][i][j].token_amount);
				}				
			}
		}	
	}
	return amount;
    }
    //获得用户某个账户的抵押资产额度(USD)
    function getAccountCollateral(address account) view external returns(uint256) {
	uint256 amount = 0;
	if(total_order_num > 0)
	{
		for(uint i=0; i<userOrdersMap[account].length; i++)
		{
			uint256 order_id = userOrdersMap[account][i];
			Order storage order = orderMaps[order_id];
			if(account == order.buyer)
			{
				if(isReleasable(account, i))
					continue;
				for(uint j=0; j<buyerCollateral[account][order_id].length; j++)
				{
					uint price = oracle.getPrice(buyerCollateral[account][order_id][j].token.addr);
					amount = amount.add(buyerCollateral[account][order_id][j].token_amount.mul(price).div(1e18));
				}				
			}
			if(account == order.seller)
			{
				if(isReleasable(account, i))
					continue;
				for(uint j=0; j<sellerCollateral[account][order_id].length; j++)
				{
					uint price = oracle.getPrice(sellerCollateral[account][order_id][j].token.addr);
					amount = amount.add(sellerCollateral[account][order_id][j].token_amount.mul(price).div(1e18));
				}				
			}
		}	
	}
	return amount;
    }
    //获得用户某个账户正在交易中的资产额度(USD)
    function getAccountTradingAssets(address account) view external returns(uint256) {
	uint256 amount = 0;
	if(total_order_num > 0)
	{
		for(uint i=0; i<userOrdersMap[account].length; i++)
		{
			uint256 order_id = userOrdersMap[account][i];
			Order storage order = orderMaps[order_id];
			if(order.status == 1)
			{
				uint price = oracle.getPrice(order.token);
				amount = amount.add(order.token_amount.mul(price).div(1e18));
			}
		}	
	}
	return amount;
    }
    //抵押是否可释放
    function isReleasable(address account, uint256 order_id) view internal returns (bool)
    {
	Order memory order = orderMaps[order_id];
	uint40 frozen_span = uint40(frozen_times[account]);
	if((order.close_time !=0)&&(block.timestamp-order.close_time >= frozen_span))
		return true;
	return false;
    } 
    //是否在支持资产列表里
    function isListed(address token) view internal returns (bool)
    {
	if(tokenMap[token].addr == token)
		return true;
	return false;
    }
    /***********************************|
    |        Whitelist Functions         |
    |__________________________________*/
    function addWhitelist(address _addWhitelist) public onlyOwner returns (bool) {
        require(_addWhitelist != address(0), "DotcMain: _addWhitelist is the zero address");
        return EnumerableSet.add(_whitelist, _addWhitelist);
    }

    function delWhitelist(address _delWhitelist) public onlyOwner returns (bool) {
        require(_delWhitelist != address(0), "DotcMain: _delWhitelist is the zero address");
        return EnumerableSet.remove(_whitelist, _delWhitelist);
    }

    function getWhitelistLength() public view returns (uint256) {
        return EnumerableSet.length(_whitelist);
    }

    function isWhitelist(address account) public view returns (bool) {
        return EnumerableSet.contains(_whitelist, account);
    }

    function getWhitelist(uint256 _index) public view onlyOwner returns (address){
        require(_index <= getWhitelistLength() - 1, "DotcMain: index out of bounds");
        return EnumerableSet.at(_whitelist, _index);
    }

    // modifier for mint function
    modifier onlyWhitelist {
        require(isWhitelist(msg.sender), "DotcMain: caller is not the minter");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
contract owned {
    address public owner;
 
    constructor() {
        owner = msg.sender;
    }
 
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }
 
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
        owner = newOwner;
      }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;
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

  /**
   * @dev gives square root of given x.
   */
  function sqrt(uint256 x)
  internal
  pure
  returns(uint256 y) {
    uint256 z = ((add(x, 1)) / 2);
    y = x;
    while (z < y) {
      y = z;
      z = ((add((x / z), z)) / 2);
    }
  }

  /**
   * @dev gives square. multiplies x by x
   */
  function sq(uint256 x)
  internal
  pure
  returns(uint256) {
    return (mul(x, x));
  }

  /**
   * @dev x to the power of y
   */
  function pwr(uint256 x, uint256 y)
  internal
  pure
  returns(uint256) {
    if (x == 0)
      return (0);
    else if (y == 0)
      return (1);
    else {
      uint256 z = x;
      for (uint256 i = 1; i < y; i++)
        z = mul(z, x);
      return (z);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

abstract contract PriceOracle {
    /// @notice Indicator that this is a PriceOracle contract (for inspection)
    	bool public constant isPriceOracle = true;

    /**
      * @notice Get the price of an asset
      * @param tokenAddress The address to get the price of
      * @return The asset price mantissa (scaled by 1e18).
      *  Zero means the price is unavailable.
      */
	function getPrice(address tokenAddress) external virtual view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
interface IERC20 {

    function totalSupply() external view returns (uint256);
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 _value) external returns (bool success);
    function burnFrom(address _from, uint256 _value) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value); 
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}