// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./math/SafeMath.sol";
import "./token/IERC20.sol";
import "./access/Ownable.sol";
import "./token/IERC1155.sol";
import "./NFTBase.sol";
import "./ERC20TokenList.sol";

/**
 *
 * @dev Implementation of Market [지정가판매(fixed_price), 경매(auction)]
 *
 */

// interface for ERC1155
interface NFTBaseLike {
    function getCreator(uint256 id) external view returns (address);
    function getRoyaltyRatio(uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
}

// interface for payment ERC20 Token List
interface ERC20TokenListLike {
    function contains(address addr) external view returns (bool);
}


contract NFTMarket is Ownable
{
    using SafeMath for uint256;
    
    struct SaleData {
        address seller;            
        bool isAuction;      // auction true, fixed_price false         
        uint256 nftId;       // ERC1155 Token Id               
        uint256 volume;      // number of nft,  volume >= 2 -> isAuction=false, remnant value : number decrease after buying
        address erc20;       // payment erc20 token 
        uint256 price;       // auction : starting price, fixed_price : sellig unit price 
        uint256 bid;         // bidding price     
        address buyer;       // fixed_price : 구매자 auction : bidder, 최종구매자 
        uint256 start;       // auction start time [unix epoch time]    unit : sec
        uint256 end;         // auction expiry time  [unix epoch time]  unit : sec     
        bool isCanceled;     // no buyer or no bidder 만 가능 
        bool isSettled;      // 정산되었는지 여부
    }
    
    mapping (uint256 => SaleData) private _sales;        //mapping from uint256 to sales data 
    uint256 private _currentSalesId = 0;                //현재 salesId 
     
    uint256 private  _feeRatio = 10;                    // 수수료율 100% = 100
    address private  _feeTo;                            // 거래수수료 수취주소 
    
    uint256 private _interval = 15 minutes;             // additionl bidding time  [seconds]
    //uint256 private _duration = 1 days;                 // 1 days total auction length  [seconds]
    
    NFTBaseLike _nftBase;                               // ERC1155
    ERC20TokenListLike _erc20s;                         // payment ERC20 Token List
    

    //event
    event Open(uint256 id,address indexed seller,bool isAuction,uint256 nftId,uint256 volume,address indexed erc20,uint256 price,uint256 start, uint256 end);
    event Buy(uint256 id,address indexed buyer,uint256 amt);
    event Clear(uint256 id);
    event Cancel(uint256 id);

    event Bid(uint256 id,address indexed guy, uint256 amount,uint256 end);
    //event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    //event Transfer(address indexed from, address indexed to, uint256 value);

    /* Keccak256 
        Open(uint256,address,bool,uint256,uint256,address,uint256)  : 0x0e884c2228e2e8cc975ba6a7d1c29574c38bda6a723957411fd523ad0c03d04e
        Buy(uint256,address,uint256)                                : 0x3b599f6217e39be59216b60e543ce0d4c7d534fe64dd9d962334924e7819894e
        Clear(uint256)                                              : 0x6e4c858d91fb3af82ec04ba219c6b12542326a62accb6ffac4cf87ba00ba95a3
        Cancel(uint256)                                             : 0x8bf30e7ff26833413be5f69e1d373744864d600b664204b4a2f9844a8eedb9ed
        Bid(uint256,address,uint256,uint256)                        : 0x3138d8d517460c959fb333d4e8d87ea984f1cf15d6742c02e2955dd27a622b70
        TransferSingle(address,address,address,uint256,uint256)     : 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
        Transfer(address,address,uint256)                           : 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
    */

    /**
     * @dev feeTo address, ERC1155 Contract, ERC20 Payment Token List 설정 
     */
    constructor(NFTBaseLike nftBase_,ERC20TokenListLike erc20s_) {
        _feeTo = address(this);
        _nftBase = NFTBaseLike(nftBase_);
        _erc20s = ERC20TokenListLike(erc20s_);
    }

    /**
     * @dev feeRatio 설정 
     *
     * Requirements:
     *
     * - 100% 이하
     */
    function setFeeRatio(uint256 feeRatio_) external onlyOwner {
        require(feeRatio_ <= 100,"NFTMarket/FeeRation_>_100");
       _feeRatio = feeRatio_;
    }

    function getFeeRatio() external view returns(uint256) {
        return _feeRatio;
    }

    /**
     * @dev feeTo Address 설정 
     *
     * Requirements:
     *
     * - not zero address
     */

    function setFeeTo(address feeTo_) external onlyOwner {
        require(feeTo_ != address(0),"NFTMarket/FeeTo_address_is_0");
       _feeTo = feeTo_;
    }

    function getFeeTo() external view returns(address) {
        return _feeTo;
    }
    
    /**
     * @dev auction 연장 시간 설정 [minites]
     *
     * Requirements:
     * 
     */    
    function setInterval(uint256 interval_) external onlyOwner {
        _interval = interval_;
    }

    function getInterval() external view returns(uint256) {
        return _interval;
    }
    /**
     * @dev auction 시간 설정 [minites]
     *
     * Requirements:
     *
     * - not zero 
     */    
    /*     
    function setDuration(uint256 duration_) external onlyOwner   {
        require(duration_ > 0,"NFTMarket/duration_is_0");
        _duration = duration_;
    }    
    
    function getDuration() external view returns(uint256) {
        return _duration;
    }
    */

    /**
     * @dev open : 판매시작, NFT escrow , SaleData 등록
     *   args  
     *     isAuction : true - auction, false - fixed_price 
     *     nftId : ERC1155 mint token Id 
     *     volume : 수량 
     *     erc20 : payment ERC20 Token
     *     price : auction : starting price, fixed_price : sellig unit price 
     *   
     *
     * Requirements:
     *
     *   수량(volume) > 1 인 경우 fixed_price 만 가능 
     *   수량 > 0, 가격 > 0
     *   결제 ERC20 contract : ERC20TokenList 중의 하나 
     *
     * Event : Open, TransferSingle(NFTBase)
     * 
     * Return  salesId
     */ 	 
    function open(bool isAuction,uint256 nftId,uint256 volume,address erc20, uint256 price,uint256 start, uint256 end) public returns (uint256 id) {
        if(volume > 1 && isAuction) {
            revert("NFTMarket/if_volume_>_1,isAuction_should_be_false");
        }
        require(volume > 0,"NFTMarket/open_0_volume");
        require(price > 0, "NFTMarket/open_0_price");
        require(_erc20s.contains(erc20),"NFTMarket/open_erc20_not_registered");
        if(isAuction) {
            require(end > start,"NFTMarket/open_should_end_>_start");
        }
                
        _nftBase.safeTransferFrom(_msgSender(),address(this),nftId,volume,"");    

        id = ++_currentSalesId;
        _sales[id].seller = _msgSender();
        _sales[id].isAuction = isAuction;
        _sales[id].nftId = nftId;
        _sales[id].volume = volume;
        _sales[id].erc20 = erc20;
        _sales[id].price = price;
        _sales[id].isCanceled = false;
        _sales[id].isSettled = false;
        
        if(isAuction) {
            _sales[id].bid = price;
            _sales[id].start = start;
            _sales[id].end = end;
        }
        emit Open(id,_msgSender(),isAuction,nftId,volume,erc20,price,start,end);            
    }
    
    /**
     * @dev buy : 바로구매, 정산 
     *   args  
     *     id     : saleId
     *     amt    : 구매수량 

     * Requirements:
     *
     *   auction이 아니고 (fixed_price 이어야)
     *   buyer가 확정되지 않아야 하고 (settle 되어지 않아야)
     *   취소상태가 아니어야 함 
     * 
     * Event : Buy,TransferSingle(NFTBase),Transfer(ERC20)      
     * 
     */ 	 

    function buy(uint256 id,uint256 amt) public {
        require(id <= _currentSalesId,"NFTMarket/sale_is_not_open");
        require(!_sales[id].isAuction, "NFTMarket/sale_is_auction");
        require(!_sales[id].isCanceled,"NFTMarket/sale_already_cancelled");    
        require(!_sales[id].isSettled,"NFTMarket/sale_already_settled");   
        require(amt > 0,"NFTMarket/buy_must_>_0");
        require(amt <= _sales[id].volume,"NFTMarket/buy_should_<=_sale_volume");
        
        _sales[id].buyer = _msgSender();

        settle(id,amt);
        emit Buy(id,_msgSender(),amt);
    }
    
    /**
     * @dev bid : 경매 참여, ERC20 Token escrow, 경매시간 연장  
     *   args : 
     *      id : salesId
     *      amount : bidding 금액  
     *      bidder = msg.sender 
     * 
     * Requirements:
     * 
     *   auction이고
     *   취소상태가 아니고
     *   경매 종료시간이 지나지 않아야 함
     *   bidding 금액이 기존 금액(첫 bidding인경우 seller가 제시한 금액)보다 커야함     
     * 
     * Event : Bid,Transfer(ERC20)       
     */ 

    function bid(uint256 id,uint256 amount) public {
        require(id <= _currentSalesId,"NFTMarket/sale_is_not_open");
        require(_sales[id].isAuction, "NFTMarket/sale_should_be_auction");
        require(!_sales[id].isCanceled,"NFTMarket/sale_already_cancelled");    
        require(!_sales[id].isSettled,"NFTMarket/sale_already_settled");         
        require(block.timestamp >= _sales[id].start, "NFTMarket/auction_doesn't_start");     
        require(_sales[id].end >= block.timestamp, "NFTMarket/auction_finished");
        require(amount > _sales[id].bid, "NFTMarket/bid_should_be_higher");

        IERC20 erc20Token = IERC20(_sales[id].erc20);
        erc20Token.transferFrom(_msgSender(),address(this),amount);

        // not first bidding
        if(_sales[id].buyer != address(0)) {
            erc20Token.transfer(_sales[id].buyer,_sales[id].bid);     
        }
        
        _sales[id].buyer = _msgSender();
        _sales[id].bid = amount;        
        
        // auction end time increase
        if(block.timestamp < _sales[id].end && _sales[id].end < block.timestamp + _interval) 
            _sales[id].end = _sales[id].end.add(_interval);
        
        emit Bid(id,_msgSender(),amount,_sales[id].end);        
    }
    

    /**
     * @dev clear : 경매 정리, 정산  
     *   args : 
     *      id : salesId
     *      amount : bidding 금액  
     *      bidder = msg.sender 
     * 
     * Requirements:
     * 
     *      id가 존재해야 하고     
     *      auction이고 
     *      취소상태가 아니고
     *      아직 정산되지 않아야 하고 
     *      경매 종료시간이 지나야 하고 
     *      caller는 sales[id].seller 이어야 함     
     * 
     * Event : Clear,TransferSingle(NFTBase),Transfer(ERC20)       
     */ 
   
    function clear(uint256 id) public {
        require(id <= _currentSalesId,"NFTMarket/sale_is_not_open");
        require(_sales[id].isAuction, "NFTMarket/sale_should_be_auction");          
        require(!_sales[id].isCanceled,"NFTMarket/sale_already_cancelled");    
        require(_sales[id].buyer != address(0), "NFTMarket/auction_not_bidded");
        require(!_sales[id].isSettled,"NFTMarket/auction_already_settled");                  
        require(_sales[id].end < block.timestamp, "NFTMarket/auction_ongoing");
        require(_msgSender() == _sales[id].seller, "NFTMarket/only_seller_can_clear");

        settle(id,1);   
        emit Clear(id);
    }
    
	/**
     * @dev cancel : 세일 취소, escrow 반환  
     *   args : 
     *      id : salesId
     *      amount : bidding 금액  
     *      bidder = msg.sender 
     *    
     * Requirements:     
     *      id가 존재해야 하고
     *      취소상태가 아니고
     *      이미 정산되지 않아야 하고 
     *      경매의 경우 Bidder가 없어야 
     *      caller는 sales[id].seller 이어야 함 
     *
     * Event : Cancel,TransferSingle(NFTBase)       
     */ 
    function cancel(uint256 id) public {
        require(id <= _currentSalesId,"NFTMarket/sale_is_not_open");
        require(!_sales[id].isCanceled,"NFTMarket/sale_already_cancelled");
        require(!_sales[id].isSettled,"NFTMarket/sale_already_settled");
        if (_sales[id].isAuction)
            require(_sales[id].buyer == address(0), "NFTMarket/auction_not_cancellable");
        require(_msgSender() == _sales[id].seller, "NFTMarket/only_seller_can_cancel");
        _sales[id].isCanceled = true;
        _nftBase.safeTransferFrom(address(this),_sales[id].seller,_sales[id].nftId,_sales[id].volume,"");
        emit Cancel(id);
    }
    
    /**
     * @dev settle : 정산   
     *      1. 수수료 정산     : this ->  feeTo
	 *      2. royalty 정산    : this ->  creator
	 *      3. nft 오너쉽 정리 : this -> buyer     
     *
     *   args : 
     *      id  : salesId
     *      amt : number of nft in fixed-price buy or auction 
     * 
     * Requirements:
     *
     * - feeRatio + royaltyRatio < 100
     *
     * Event : TransferSingle(NFTBase), Transfer(ERC20)
     */     

    function settle(uint256 id,uint256 amt) private {
        SaleData memory sd = _sales[id];
  
        uint256 amount = sd.isAuction ? sd.bid : sd.price*amt;
        uint256 fee = amount.mul(_feeRatio).div(100);

        address creator = _nftBase.getCreator(sd.nftId);
        uint256 royaltyRatio = _nftBase.getRoyaltyRatio(sd.nftId);

        require(_feeRatio.add(royaltyRatio) <= 100, "NFTMarket/fee_+_royalty_>_100%");
        uint256 royalty = amount.mul(royaltyRatio).div(100);    

        IERC20 erc20Token = IERC20(sd.erc20);
        if(sd.isAuction) {
            erc20Token.transfer(_feeTo,fee);
            erc20Token.transfer(creator,royalty);
            erc20Token.transfer(sd.seller,amount.sub(fee).sub(royalty));
        } else {
            erc20Token.transferFrom(_msgSender(),_feeTo,fee);
            erc20Token.transferFrom(_msgSender(),creator,royalty);
            erc20Token.transferFrom(_msgSender(),sd.seller,amount.sub(fee).sub(royalty));
        }
        _nftBase.safeTransferFrom(address(this),sd.buyer,sd.nftId,amt,"");

        _sales[id].volume -= amt;
        _sales[id].isSettled = (_sales[id].volume == 0);
    }

    function getAuctionEnd(uint256 id) external view returns (uint256) 
    {
        require(_sales[id].isAuction,"NFTMarket/sale_should_be_auction");
        return _sales[id].end;
    }

    /**
     * @dev getSaleData : SaleData Return
     */
    function getSaleData(uint256 id) external view 
        returns (
            address         
            ,bool
            ,uint256
            ,uint256
            ,address
            ,uint256
            ,uint256
            ,address
            ,uint256
            ,uint256
            ,bool
            ,bool 
        ) {        
            SaleData memory sd = _sales[id];
            return (
                sd.seller            
                ,sd.isAuction
                ,sd.nftId
                ,sd.volume
                ,sd.erc20
                ,sd.price
                ,sd.bid
                ,sd.buyer
                ,sd.start
                ,sd.end
                ,sd.isCanceled
                ,sd.isSettled
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

pragma solidity ^0.7.0;

import "../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./token/ERC1155.sol";
import "./access/AccessControl.sol";
import "./access/Ownable.sol";
import "./utils/Context.sol";

/**
 *
 * @dev Implementation of ERC1155 + NFT Token Data 
 *
 * AccessControl 
 *   DEFAULT_ADMIN_ROLE = 0
 *   새로운 role 생성 될때마다 adminRole = 0 이된다. 
 *   따라서 자연스럽게 adminRole = DEFAULT_ADMIN_ROLE 이 된다.
 */


contract NFTBase is ERC1155, Ownable, AccessControl
{
 
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");        //Role Id 

    struct TokenData {
        uint256 supply;                            // NFT 공급량 
        string uri;                             // NFT url : json 화일 
        address creator;                        // 저작권자
        uint256 royaltyRatio;                      // 로열티 100% = 100
    }

    mapping(uint256 => TokenData) private _tokens;     // mapping from uint256 to nft token data 
    uint256 private _currentTokenId = 0;            // 현재 tokenId
    
    bool private _isPrivate = true;                 // private Mint 설정 - 오직 MINTER_ROLE 보유자만 가능 
    uint256 private _royaltyMinimum = 0;               // 로열티 최소값
    uint256 private _royaltyMaximum = 90;              // 로열티 최대값
    
    //event
    event Mint(uint256 id,uint256 supply, string uri, address indexed creator, uint256 royaltyRatio);
    /* keccak256 
        Mint(uint256,uint256,string,address,uint256)                : 0x21881410541b694573587a7b14f2da71c815c0d7e24797822fe90249daaf884e
        TransferSingle(address,address,address,uint256,uint256)     : 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
        RoleGranted(bytes32,address,address)                        : 0x2f8788117e7eff1d82e926ec794901d17c78024a50270940304540a733656f0d
        RoleRevoked(bytes32,address,address)                        : 0xf6391f5c32d9c69d2a47ea670b442974b53935d1edc7fd64eb21e047a839171b
    */


    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE,_msgSender());        //MINTER_ROLE Amin 설정 
        addWhiteList(_msgSender());
    }
    
    /**
     * @dev setPrivateMarket : Private Market set 
     *
     * Requirements:
     *
     * - 100% 이하
     */

    function setPrivateMarket(bool isPrivate_) external onlyOwner  {
        _isPrivate = isPrivate_;
    }   
    
    function getPrivateMarket() external view returns(bool) {
        return _isPrivate;
    }
    /**
     * @dev setRoyaltyRange : Royalty Range set 
     *
     * Requirements:
     *
     *    Royalty min <= Royalty max
     *    0<= Royalty max <= 100
     */    
    function setRoyaltyRange(uint256 min,uint256 max) external {
        require(max >= min,"NFTBase/should_be_(max >= min)");
        require(max <= 100,"NFTBase/should_be_(max <= 100)"); 
        _royaltyMinimum = min;
        _royaltyMaximum = max;
    }
    
    function getRoyaltyRange() external view returns(uint256,uint256) {
        return (_royaltyMinimum,_royaltyMaximum);
    }

    /**
     * @dev addWhiteList : whitelist account add
     *
     * Requirements:
     *
     *    MINTER_ROLE을 보유하고 있지 않은 address
     *    msg_sender가 DEFAULT_ADMIN_ROLE 보유해야 
     * 
     * Event : RoleGranted
     */

    function addWhiteList(address minter) public  {
        require(!hasRole(MINTER_ROLE,minter),"NFTBase/minter_has_role_already");
        grantRole(MINTER_ROLE,minter);
    }


    /**
     * @dev removeWhiteList : whitelist account remove
     *
     * Requirements:
     *
     *    MINTER_ROLE을 보유하고 있는 address
     *    DEFAULT_ADMIN_ROLE DEFAULT_ADMIN_ROLE 보유해야 
     *
     * Event : RoleRevoked
     *
     */
    function removeWhiteList(address minter)  external {
        require(hasRole(MINTER_ROLE,minter),"NFTBase/minter_has_not_role");
        revokeRole(MINTER_ROLE,minter);
    }
    
    /**
     * @dev mint :   NFT Token 발행
     *
     * Requirements:
     *
     *    supply > 0, uri != "", creator != address(0)
     *    royalty : royalty Range안에 
     *    Private Market의 경우 msg.seder는 MINTER_ROLE을 보유해야 
     *
     * Event : TransferSingle
     */

    /**
     * Only incaseof private market, check if caller has a minter role 
     */
    function mint(uint256 supply, string memory uri, address creator, uint256 royaltyRatio) public returns(uint256 id) {
        require(supply > 0,"NFTBase/supply_is_0");
        require(!compareStrings(uri,""),"NFTBase/uri_is_empty");
        require(creator != address(0),"NFTBase/createor_is_0_address");
        require(_royaltyMinimum <= royaltyRatio && royaltyRatio <= _royaltyMaximum,"NFTBase/royalty_out_of_range");
        
        if(_isPrivate)
            require(hasRole(MINTER_ROLE,_msgSender()),"NFTBase/caller_has_not_minter_role");
        id = ++_currentTokenId;    
        
        _tokens[id].supply  = supply;
        _tokens[id].uri     = uri;
        _tokens[id].creator = creator;
        _tokens[id].royaltyRatio = royaltyRatio;
        
        ERC1155._mint(_msgSender(),id,supply,"");    // TransferSingle Event  

        emit Mint(id,supply,uri,creator,royaltyRatio);
    }
    
    /**
     * @dev tokenURI : NFT Token uri 조회 MI
     */    
    function tokenURI(uint256 id) external view returns (string memory) {
        return  _tokens[id].uri;
    }
    
    /**
     * @dev getCreator : NFT Creator조회 
     */        
    function getCreator(uint256 id) external view returns (address) {
        return _tokens[id].creator;
    }

    /**
     * @dev getRoyaltyRatio : NFT RoyaltyRatio 조회 
     */         
    function getRoyaltyRatio(uint256 id) external view returns (uint256) {
        return _tokens[id].royaltyRatio;
    }
    
    /**
     * @dev compareStrings : string을 암호화해서 비교 
     *   Solidiy string 비교함수 제공하지 않음 
     */
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }    

    /**
     * @dev getTokenData : TokenData Return
     */
    function getTokenData(uint256 id) external view 
        returns(
            uint256
            ,string memory
            ,address
            ,uint256) 
        {
            TokenData memory td = _tokens[id];
            return (
                td.supply
                ,td.uri
                ,td.creator
                ,td.royaltyRatio
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./utils/Address.sol";
import "./access/Ownable.sol";

/**
 *
 * @dev 결제용 ERC20 Token List 
 *
 */

contract ERC20TokenList is Ownable {
    using Address for address;

    address[] private _addresses;
    mapping (address => uint256) private _indexes;   // 1-based  1,2,3.....
    
    /**
     * @dev contains : 기존 등록 여부 조회
    */
    function contains(address addr) public view returns (bool) {
        return _indexes[addr] != 0;
    }

    /**
     * @dev addToken : ERC20 Token 추가 
     * 
     * Requirements:
     *
     *   address Not 0 address 
     *   중복여부 확인 
     *   address가 contract 인지 확인 
     *     
	 */
    
    function addToken(address addr) public onlyOwner {

        //console.log("address = %s",addr);
        //console.log("contains = %s",contains(addr));

        require(addr != address(0),"TokenList/address_is_0");
        require(!contains(addr),"TokenList/address_already_exist");
        require(addr.isContract(),"TokenList/address_is_not_contract");

        _addresses.push(addr);
        _indexes[addr] = _addresses.length;
    }
    

    /**
     * @dev removeToken : ERC20 Token 삭제 
     * 
     * Requirements:
     *
     *   기존 존재여부 확인 
     *   address가 contract 인지 확인 
     *     
	 */

    function removeToken(address addr) public  onlyOwner {
        require(contains(addr),"TokenList/address_is_not_exist");
        uint256 idx = _indexes[addr];
        uint256 toDeleteIndex = idx - 1;
        uint256 lastIndex = _addresses.length - 1;
        
        address lastAddress = _addresses[lastIndex];
        
        _addresses[toDeleteIndex] = lastAddress;
        _indexes[lastAddress] = toDeleteIndex + 1;
        
        _addresses.pop();
        delete _indexes[addr];
    }
    
    /**
     * @dev getAddressList : ERC20 Token List return 
     * 
	 */    
    function getAddressList() public view returns (address[] memory) {
        return _addresses;
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

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155.sol";
import "../introspection/ERC165.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155 {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;


    /**
     * @dev 
     */
    constructor () {

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

    }


    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Rbaequirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "ERC1155: insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/EnumerableSet.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
}

