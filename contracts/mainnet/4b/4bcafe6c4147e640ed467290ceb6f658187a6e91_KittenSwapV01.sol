/**
 *Submitted for verification at Etherscan.io on 2021-02-17
*/

//   _    _ _   _                __ _                            
//  | |  (_) | | |              / _(_)                           
//  | | ___| |_| |_ ___ _ __   | |_ _ _ __   __ _ _ __   ___ ___ 
//  | |/ / | __| __/ _ \ '_ \  |  _| | '_ \ / _` | '_ \ / __/ _ \
//  |   <| | |_| ||  __/ | | |_| | | | | | | (_| | | | | (_|  __/
//  |_|\_\_|\__|\__\___|_| |_(_)_| |_|_| |_|\__,_|_| |_|\___\___|
//
//  KittenSwap v0.1
//
//  https://www.KittenSwap.org/
//
pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "!!add");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "!!sub");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "!!mul");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "!!div");
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

////////////////////////////////////////////////////////////////////////////////

contract KittenSwapV01 
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    ////////////////////////////////////////////////////////////////////////////////
    
    address public govAddr;
    address public devAddr;
    
    constructor () public {
        govAddr = msg.sender;
        devAddr = msg.sender;
    }
    
    modifier govOnly() 
    {
    	require(msg.sender == govAddr, "!gov");
    	_;
    }
    function govTransferAddr(address newAddr) external govOnly 
    {
    	require(newAddr != address(0), "!addr");
    	govAddr = newAddr;
    }
    
    modifier devOnly() 
    {
    	require(msg.sender == devAddr, "!dev");
    	_;
    }
    function devTransferAddr(address newAddr) external govOnly 
    {
    	require(newAddr != address(0), "!addr");
    	devAddr = newAddr;
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    
    mapping (address => mapping (address => uint)) public vault;
    
    event VAULT_DEPOSIT(address indexed user, address indexed token, uint amt);
    event VAULT_WITHDRAW(address indexed user, address indexed token, uint amt);
    
    function vaultWithdraw(address token, uint amt) external 
    {
        address payable user = msg.sender;

        vault[user][token] = vault[user][token].sub(amt);
        if (token == address(0)) {
            user.transfer(amt);
        } else {
            IERC20(token).safeTransfer(user, amt);
        }
        emit VAULT_WITHDRAW(user, token, amt);
    }
    
    function vaultDeposit(address token, uint amt) external payable
    {
        address user = msg.sender;

        if (token == address(0)) {
            vault[user][token] = vault[user][token].add(msg.value);
        } else {
            IERC20(token).safeTransferFrom(user, address(this), amt);
            vault[user][token] = vault[user][token].add(amt);
        }
        emit VAULT_DEPOSIT(user, token, amt);
    }    
    
    ////////////////////////////////////////////////////////////////////////////////
    
    struct MARKET {
        address token;        // fixed after creation
        uint96 AMT_SCALE;     // fixed after creation
        uint96 PRICE_SCALE;   // fixed after creation
        uint16 DEVFEE_BP;     // in terms of basis points (1 bp = 0.01%)
    }
    MARKET[] public marketList;
    
    event MARKET_CREATE(address indexed token, uint96 $AMT_SCALE, uint96 $PRICE_SCALE, uint indexed id);
    
    function govCreateMarket(address $token, uint96 $AMT_SCALE, uint96 $PRICE_SCALE, uint16 $DEVFEE_BP) external govOnly 
    {
        require ($AMT_SCALE > 0);
        require ($PRICE_SCALE > 0);
        require ($DEVFEE_BP <= 60);
        
        MARKET memory m;
        m.token = $token;
        m.AMT_SCALE = $AMT_SCALE;
        m.PRICE_SCALE = $PRICE_SCALE;
        m.DEVFEE_BP = $DEVFEE_BP;
        
        marketList.push(m);
        
        emit MARKET_CREATE($token, $AMT_SCALE, $PRICE_SCALE, marketList.length - 1);
    }
    
    function govSetDevFee(uint $marketId, uint16 $DEVFEE_BP) external govOnly 
    {
        require ($DEVFEE_BP <= 60);
        marketList[$marketId].DEVFEE_BP = $DEVFEE_BP;
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    
    struct ORDER {
        uint32 tokenAmtScaled;  // scaled by AMT_SCALE        SCALE 10^12 => 1 ~ 2^32-1 means 0.000001 ~ 4294.967295
        uint24 priceLowScaled;  // scaled by PRICE_SCALE      SCALE 10^4 => 1 ~ 2^24-1 means 0.0001 ~ 1677.7215
        uint24 priceHighScaled; // scaled by PRICE_SCALE      SCALE 10^4 => 1 ~ 2^24-1 means 0.0001 ~ 1677.7215
        uint160 userMaker;
    }
    mapping (uint => ORDER[]) public orderList; // div 2 = market, mod 2 = 0 sell, 1 buy
    
    uint constant UINT32_MAX = 2**32 - 1;
    
    event ORDER_CREATE(address indexed userMaker, uint indexed marketIsBuy, uint orderInfo, uint indexed orderId);
    event ORDER_MODIFY(address indexed userMaker, uint indexed marketIsBuy, uint newOrderInfo, uint indexed orderId);
    event ORDER_TRADE(address indexed userTaker, address userMaker, uint indexed marketIsBuy, uint fillOrderInfo, uint indexed orderId);

    ////////////////////////////////////////////////////////////////////////////////
    
    function marketCount() external view returns (uint)
    {
        return marketList.length;
    }
    
    function orderCount(uint $marketIsBuy) external view returns (uint)
    {
        return orderList[$marketIsBuy].length;
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    
    function orderCreate(uint $marketIsBuy, uint32 $tokenAmtScaled, uint24 $priceLowScaled, uint24 $priceHighScaled) external payable 
    {
        require($priceLowScaled > 0, "!priceLow");
        require($priceHighScaled > 0, "!priceHigh");
        require($priceHighScaled >= $priceLowScaled, "!priceRange");

        uint isMakerBuy = $marketIsBuy % 2;
        MARKET memory m = marketList[$marketIsBuy / 2];
        require(m.token != address(0), "!market");
        
        //------------------------------------------------------------------------------

        address userMaker = msg.sender;
            
        if (isMakerBuy > 0) // buy token -> deposit ETH
        {
            uint ethAmt = uint($tokenAmtScaled) * uint(m.AMT_SCALE) * (uint($priceLowScaled) + uint($priceHighScaled)) / uint(m.PRICE_SCALE * 2);
            require(msg.value == ethAmt, '!eth');
        }
        else // sell token -> deposit token
        {
            IERC20 token = IERC20(m.token);
            if ($tokenAmtScaled > 0)
                token.safeTransferFrom(userMaker, address(this), uint($tokenAmtScaled) * uint(m.AMT_SCALE));
            require(msg.value == 0, '!eth');
        }
        
        //------------------------------------------------------------------------------
        
        ORDER memory o;
        o.userMaker = uint160(userMaker);
        o.tokenAmtScaled = $tokenAmtScaled;
        o.priceLowScaled = $priceLowScaled;
        o.priceHighScaled = $priceHighScaled;
        
        //------------------------------------------------------------------------------

        ORDER[] storage oList = orderList[$marketIsBuy];
        oList.push(o);
        
        uint orderId = oList.length - 1;
        uint orderInfo = $tokenAmtScaled | ($priceLowScaled<<32) | ($priceHighScaled<<(32+24));

        emit ORDER_CREATE(userMaker, $marketIsBuy, orderInfo, orderId);
    }

    ////////////////////////////////////////////////////////////////////////////////
    
    function orderModify(uint $marketIsBuy, uint32 newTokenAmtScaled, uint24 newPriceLowScaled, uint24 newPriceHighScaled, uint orderID) external payable 
    {
        require(newPriceLowScaled > 0, "!priceLow");
        require(newPriceHighScaled > 0, "!priceHigh");
        require(newPriceHighScaled >= newPriceLowScaled, "!priceRange");
        
        address payable userMaker = msg.sender;
        ORDER storage o = orderList[$marketIsBuy][orderID];
        require (uint160(userMaker) == o.userMaker, "!user");

        uint isMakerBuy = $marketIsBuy % 2;
        MARKET memory m = marketList[$marketIsBuy / 2];
        
        //------------------------------------------------------------------------------

        if (isMakerBuy > 0) // old order: maker buy token -> modify ETH amt
        {
            uint oldEthAmt = uint(o.tokenAmtScaled) * uint(m.AMT_SCALE) * (uint(o.priceLowScaled) + uint(o.priceHighScaled)) / uint(m.PRICE_SCALE * 2);
            uint newEthAmt = uint(newTokenAmtScaled) * uint(m.AMT_SCALE) * (uint(newPriceLowScaled) + uint(newPriceHighScaled)) / uint(m.PRICE_SCALE * 2);

            uint extraEthAmt = (msg.value).add(oldEthAmt).sub(newEthAmt); // throw if not enough
            
            if (extraEthAmt > 0)
                userMaker.transfer(extraEthAmt); // return extra ETH to maker
        }
        else // old order: maker sell token -> modify token amt
        {
            uint oldTokenAmt = uint(o.tokenAmtScaled) * uint(m.AMT_SCALE);
            uint newTokenAmt = uint(newTokenAmtScaled) * uint(m.AMT_SCALE);

            IERC20 token = IERC20(m.token);
            if (newTokenAmt > oldTokenAmt) {
                token.safeTransferFrom(userMaker, address(this), newTokenAmt - oldTokenAmt);
            }
            else if (newTokenAmt < oldTokenAmt) {
                token.safeTransfer(userMaker, oldTokenAmt - newTokenAmt); // return extra token to maker
            }
            require(msg.value == 0, '!eth');            
        }
        
        //------------------------------------------------------------------------------
        
        if (o.tokenAmtScaled != newTokenAmtScaled)
            o.tokenAmtScaled = newTokenAmtScaled;
        if (o.priceLowScaled != newPriceLowScaled)
            o.priceLowScaled = newPriceLowScaled;
        if (o.priceHighScaled != newPriceHighScaled)
            o.priceHighScaled = newPriceHighScaled;

        uint orderInfo = newTokenAmtScaled | (newPriceLowScaled<<32) | (newPriceHighScaled<<(32+24));

        emit ORDER_MODIFY(userMaker, $marketIsBuy, orderInfo, orderID);
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    
    
    
    function _fill_WLO(ORDER storage o, MARKET memory m, uint isMakerBuy, uint32 $tokenAmtScaled, uint24 fillPriceWorstScaled) internal returns (uint fillTokenAmtScaled, uint fillEthAmt)
    {
        uint allSlots = uint(1) + uint(o.priceHighScaled) - uint(o.priceLowScaled);
        uint fullFillSlots = allSlots * ($tokenAmtScaled) / uint(o.tokenAmtScaled);
        if (fullFillSlots > allSlots) {
            fullFillSlots = allSlots;
        }
        
        if (isMakerBuy > 0) // maker buy token -> taker sell token
        {
            require (fillPriceWorstScaled <= o.priceHighScaled, '!price');
            uint fillPriceEndScaled = uint(o.priceHighScaled).sub(fullFillSlots);
            if ((uint(fillPriceWorstScaled) * 2) > (o.priceHighScaled))
            {
                uint _ppp = (uint(fillPriceWorstScaled) * 2) - (o.priceHighScaled);
                if (fillPriceEndScaled < _ppp)
                    fillPriceEndScaled = _ppp;
            }
            require (fillPriceEndScaled <= o.priceHighScaled, '!price');
            
            //------------------------------------------------------------------------------
            
            if (($tokenAmtScaled >= o.tokenAmtScaled) && (fillPriceEndScaled <= o.priceLowScaled)) // full fill
            {
                fillTokenAmtScaled = o.tokenAmtScaled;
                fillEthAmt = uint(fillTokenAmtScaled) * uint(m.AMT_SCALE) * (uint(o.priceLowScaled) + uint(o.priceHighScaled)) / uint(m.PRICE_SCALE * 2);

                o.tokenAmtScaled = 0;

                return (fillTokenAmtScaled, fillEthAmt);
            }
            
            //------------------------------------------------------------------------------
            
            {
                uint fillTokenAmtFirst = 0; // full fill @ [fillPriceEndScaled+1, priceHighScaled]
                {
                    uint firstFillSlots = uint(o.priceHighScaled) - uint(fillPriceEndScaled);
                    fillTokenAmtFirst = firstFillSlots * uint(o.tokenAmtScaled) * uint(m.AMT_SCALE) / allSlots;
                }
                fillEthAmt = fillTokenAmtFirst * (uint(o.priceHighScaled) + uint(fillPriceEndScaled) + 1) / uint(m.PRICE_SCALE * 2);
                
                uint fillTokenAmtSecond = (uint($tokenAmtScaled) * uint(m.AMT_SCALE)).sub(fillTokenAmtFirst); // partial fill @ fillPriceEndScaled
                {
                    uint amtPerSlot = uint(o.tokenAmtScaled) * uint(m.AMT_SCALE) / allSlots;
                    if (fillTokenAmtSecond > amtPerSlot) {
                        fillTokenAmtSecond = amtPerSlot;
                    }
                }
                
                fillTokenAmtScaled = (fillTokenAmtFirst + fillTokenAmtSecond) / uint(m.AMT_SCALE);
                
                fillTokenAmtSecond = (fillTokenAmtScaled * uint(m.AMT_SCALE)).sub(fillTokenAmtFirst);
                fillEthAmt = fillEthAmt.add(fillTokenAmtSecond * fillPriceEndScaled / uint(m.PRICE_SCALE));
            }
            
            //------------------------------------------------------------------------------
            
            uint newPriceHighScaled =
                (
                    ( uint(o.tokenAmtScaled) * uint(m.AMT_SCALE) * (uint(o.priceLowScaled) + uint(o.priceHighScaled)) )
                    .sub
                    ( fillEthAmt * uint(m.PRICE_SCALE * 2) )
                )
                /
                ( (uint(o.tokenAmtScaled).sub(fillTokenAmtScaled)) * uint(m.AMT_SCALE) )
            ;
            newPriceHighScaled = newPriceHighScaled.sub(o.priceLowScaled);
            
            require (newPriceHighScaled >= o.priceLowScaled, "!badFinalRange"); // shall never happen
            
            o.priceHighScaled = uint24(newPriceHighScaled);        
            
            o.tokenAmtScaled = uint32(uint(o.tokenAmtScaled).sub(fillTokenAmtScaled));
        }
        //------------------------------------------------------------------------------
        else // maker sell token -> taker buy token
        {
            require (fillPriceWorstScaled >= o.priceLowScaled, '!price');
            uint fillPriceEndScaled = uint(o.priceLowScaled).add(fullFillSlots);
            {
                uint _ppp = (uint(fillPriceWorstScaled) * 2).sub(o.priceLowScaled);
                if (fillPriceEndScaled > _ppp)
                    fillPriceEndScaled = _ppp;
            }
            require (fillPriceEndScaled >= o.priceLowScaled, '!price');
            
            //------------------------------------------------------------------------------
            
            if (($tokenAmtScaled >= o.tokenAmtScaled) && (fillPriceEndScaled >= o.priceHighScaled)) // full fill
            {
                fillTokenAmtScaled = o.tokenAmtScaled;
                fillEthAmt = uint(fillTokenAmtScaled) * uint(m.AMT_SCALE) * (uint(o.priceLowScaled) + uint(o.priceHighScaled)) / uint(m.PRICE_SCALE * 2);

                o.tokenAmtScaled = 0;

                return (fillTokenAmtScaled, fillEthAmt);
            }
            
            //------------------------------------------------------------------------------

            {
                uint fillTokenAmtFirst = 0; // full fill @ [priceLowScaled, fillPriceEndScaled-1]
                {
                    uint firstFillSlots = uint(fillPriceEndScaled) - uint(o.priceLowScaled);
                    fillTokenAmtFirst = firstFillSlots * uint(o.tokenAmtScaled) * uint(m.AMT_SCALE) / allSlots;
                }
                fillEthAmt = fillTokenAmtFirst * (uint(o.priceLowScaled) + uint(fillPriceEndScaled) - 1) / uint(m.PRICE_SCALE * 2);
                
                uint fillTokenAmtSecond = (uint($tokenAmtScaled) * uint(m.AMT_SCALE)).sub(fillTokenAmtFirst); // partial fill @ fillPriceEndScaled
                {
                    uint amtPerSlot = uint(o.tokenAmtScaled) * uint(m.AMT_SCALE) / allSlots;
                    if (fillTokenAmtSecond > amtPerSlot) {
                        fillTokenAmtSecond = amtPerSlot;
                    }
                }
                
                fillTokenAmtScaled = (fillTokenAmtFirst + fillTokenAmtSecond) / uint(m.AMT_SCALE);
                
                fillTokenAmtSecond = (fillTokenAmtScaled * uint(m.AMT_SCALE)).sub(fillTokenAmtFirst);
                fillEthAmt = fillEthAmt.add(fillTokenAmtSecond * fillPriceEndScaled / uint(m.PRICE_SCALE));
            }
            
            //------------------------------------------------------------------------------
            
            o.tokenAmtScaled = uint32(uint(o.tokenAmtScaled).sub(fillTokenAmtScaled));
            o.priceLowScaled = uint24(fillPriceEndScaled);
        }
    }
    
    ////////////////////////////////////////////////////////////////////////////////
    
    function orderTrade(uint $marketIsBuy, uint32 $tokenAmtScaled, uint24 fillPriceWorstScaled, uint orderID) external payable 
    {
        ORDER storage o = orderList[$marketIsBuy][orderID];
        require ($tokenAmtScaled > 0, '!amt');
        require (o.tokenAmtScaled > 0, '!amt');

        address payable userTaker = msg.sender;
        address payable userMaker = payable(o.userMaker);

        uint isMakerBuy = $marketIsBuy % 2;
        MARKET memory m = marketList[$marketIsBuy / 2];
        IERC20 token = IERC20(m.token);

        uint fillTokenAmtScaled = 0;
        uint fillEthAmt = 0;
        
        //------------------------------------------------------------------------------

        if (o.priceLowScaled == o.priceHighScaled) // simple limit order
        {
            uint fillPriceScaled = o.priceLowScaled;
            
            if (isMakerBuy > 0) { // maker buy token -> taker sell token
                require (fillPriceScaled >= fillPriceWorstScaled, "!price"); // sell at higher price
            }
            else { // maker sell token -> taker buy token
                require (fillPriceScaled <= fillPriceWorstScaled, "!price"); // buy at lower price
            }
            
            //------------------------------------------------------------------------------

            fillTokenAmtScaled = $tokenAmtScaled;
            if (fillTokenAmtScaled > o.tokenAmtScaled)
                fillTokenAmtScaled = o.tokenAmtScaled;

            fillEthAmt = fillTokenAmtScaled * uint(m.AMT_SCALE) * (fillPriceScaled) / uint(m.PRICE_SCALE);

            o.tokenAmtScaled = uint32(uint(o.tokenAmtScaled).sub(fillTokenAmtScaled));
        }
        //------------------------------------------------------------------------------
        else // Wide Limit Order
        {
            require (o.priceHighScaled > o.priceLowScaled, '!badOrder');
            
            (fillTokenAmtScaled, fillEthAmt) = _fill_WLO(o, m, isMakerBuy, $tokenAmtScaled, fillPriceWorstScaled); // will modify order
        }
        
        //------------------------------------------------------------------------------
        
        require(fillTokenAmtScaled > 0, "!fillTokenAmtScaled");
        require(fillEthAmt > 0, "!fillEthAmt");
        
        uint fillTokenAmt = fillTokenAmtScaled * uint(m.AMT_SCALE);
        
        if (isMakerBuy > 0) // maker buy token -> taker sell token
        {
            token.safeTransferFrom(userTaker, userMaker, fillTokenAmt); // send token to maker (from taker)

            uint devFee = fillEthAmt * uint(m.DEVFEE_BP) / (10000);
            vault[devAddr][address(0)] = vault[devAddr][address(0)].add(devFee);

            userTaker.transfer(fillEthAmt.sub(devFee)); // send eth to taker
            require(msg.value == 0, '!eth');
        }
        else // maker sell token -> taker buy token
        {
            require(msg.value >= fillEthAmt, '!eth');
            
            token.safeTransfer(userTaker, fillTokenAmt); // send token to taker

            uint devFee = fillEthAmt * uint(m.DEVFEE_BP) / (10000);
            vault[devAddr][address(0)] = vault[devAddr][address(0)].add(devFee);

            userMaker.transfer(fillEthAmt.sub(devFee)); // send eth to maker
            
            if (msg.value > fillEthAmt) {
                userTaker.transfer(msg.value - fillEthAmt); // return extra eth to taker
            }
        }

        //------------------------------------------------------------------------------

        uint orderInfo = fillTokenAmtScaled | fillEthAmt<<32;

        emit ORDER_TRADE(userTaker, userMaker, $marketIsBuy, orderInfo, orderID);    
    }
}