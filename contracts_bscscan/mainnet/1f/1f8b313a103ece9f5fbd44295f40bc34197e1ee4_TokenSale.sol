/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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


interface IAdapterERC20 {
   function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

interface IAdapterERC20V2 {
   function transferFrom(address from, address to, uint value) external;
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}


contract Creator {
    address public creator;
    address public newCreator;

    constructor() public {
        creator = msg.sender;
    }

    modifier creatorOnly {
        assert(msg.sender == creator);
        _;
    }

    function transferCreator(address  _newCreator)  public creatorOnly {
        require(_newCreator != creator);
        newCreator = _newCreator;
    }

    function acceptCreator()  public {
        require(msg.sender == newCreator);
        creator = newCreator;
        newCreator = address(0x0);
    }
}

contract TokenSale is Creator {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    
    address usdtToken = 0x55d398326f99059fF775485246999027B3197955;
    address sdsToken = 0x0b7CfD1379E4A914be026461215010c577dBc64F;
    address fundPool = 0x94E46388D6b03f5577D07E055DE127013FD73A0b;
    
    
    struct User {
        uint256 id;  
        uint256 partnersCount;
        uint256 useUSDT;
        uint256 buyAmount;
        uint256 withdrawAmount;
        uint256 withdrawTime;
        uint256 buyType;
        address addr;
        address referrer;  
    }
    
    uint256 constant public MAXSALETOKENAMOUNT = 4000000; 
    uint256 constant public DAY = 86400;
    uint256 constant public HOUR  = 3600; 
    uint256 constant public MINUTE  = 60; 
    
    mapping(address => User) private users;
    mapping(uint256 => address) public idToAddress;
    
    uint256 public lastUserId = 1;
    uint256 public saleTokenAmount; 
    
    uint256 totalInvestment;
    address public ownerAddr;
    bool inSwap;
    uint256 startSale;
    uint256 endSale;
    uint256 tokenUnlockTime;
    
    
    uint256[]  public stageAmountArray = new uint256[](3);
    uint256[]  public stagePriceArray = new uint256[](3);
    
    event BuyTokens(address indexed from,uint256 stagePrice, uint256 saleAmount,uint256 stageAmount,uint256 stageLmitAmount, uint256 amount);

    constructor(uint256 _tokenUnlockTime,uint256 _startSale,uint256 _endSale) public {
        ownerAddr = msg.sender;
        startSale = _startSale;
        endSale = _endSale;
        tokenUnlockTime =_tokenUnlockTime;
        
        stagePriceArray[0] = 50;
        stagePriceArray[1] = 80;
        stagePriceArray[2] = 100;

        stageAmountArray[0] = 100000;
        stageAmountArray[1] = 900000;
        stageAmountArray[2] = 3000000;
        
        User memory user = User({
            id: lastUserId,
            partnersCount: 0,
            useUSDT: 0,
            buyAmount: 0,
            withdrawAmount: 0,
            withdrawTime:0 ,
            buyType:1 ,
            addr:msg.sender,
            referrer: address(0)
        });

        users[ownerAddr] = user;
        idToAddress[1] = ownerAddr;
        
        lastUserId+=1; 

    }
    
    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
     modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    function getAdjustedDate()internal view returns(uint256)
    {
        return (now + HOUR * 9) - (now + HOUR * 9) % DAY - HOUR * 9;
    }
    
    function getCurrentSaleInfo() public view returns (uint256[4] memory ){ 
        (uint256 stagePrice, uint256 saleAmount, uint256 stageAmount,uint256 stageLmitAmount)  = getSaleInfo(saleTokenAmount);
        uint256[4] memory result;
        result[0] = stagePrice;
        result[1] = saleAmount;
        result[2] = stageAmount;
        result[3] = stageLmitAmount;
        return result;
    }
    
    function getSaleInfo(uint256 tokenAmount) public view returns (uint256 ,uint256 ,uint256 ,uint256 ){ 
         uint256 stagePrice;
         uint256 saleAmount;
         uint256 stageAmount;
         uint256 stageLmitAmount;
         
         if(tokenAmount < MAXSALETOKENAMOUNT *  1e18){
            uint256 saleTotal = 0;
            for(uint256 i=0;i<stageAmountArray.length;i++) {
                saleTotal += stageAmountArray[i] * 1e18;
                if(saleTotal >= tokenAmount){
                    stagePrice = stagePriceArray[i] * 1e18;
                    saleAmount = saleTotal - tokenAmount;
                    stageAmount = stageAmountArray[i] * 1e18;
                    stageLmitAmount = 0;
                    break;
                }
            }
        }else{
           stagePrice = stagePriceArray[2] * 1e18;
           saleAmount = 0;
           stageAmount = 0;
           stageLmitAmount = 0;
        }
        return (stagePrice,saleAmount,stageAmount,stageLmitAmount);
    }

    function addUser(address  node,uint256 buyType, address refNode) private{
        User memory user = User({
            id: lastUserId,
            partnersCount: 0,
            useUSDT: 0,
            buyAmount: 0,
            withdrawAmount: 0,
            withdrawTime:0 ,
            buyType:buyType ,
            addr:node,
            referrer: address(0)
        });
        
        users[node] = user;
        idToAddress[lastUserId] = node;
        users[refNode].partnersCount++;
            
        lastUserId+=1;
    }
    
   function buyTokens(uint256 amount,address referrer) lockTheSwap external payable  {
        require(now >= startSale && now <= endSale, "Incorrect time");
        address  addr = msg.sender;
        require(!isUserExists(addr), "Purchase limit");
        //require(isUserExists(referrer), "referrer not exists");
        addUser(addr,1,referrer);

        (uint256 stagePrice,uint256 saleAmount,uint256 stageAmount,uint256 stageLmitAmount) = getSaleInfo(saleTokenAmount);
        
        require(saleAmount >= amount, "Bad amount1");
        
        //amount * stagePrice /1e18 /100;
        uint256 usdtAmount =  amount.mul(stagePrice).div(1e18).div(100);
        require(usdtAmount <= 5000 * 1e18, "Bad amount2");


        IERC20(usdtToken).safeTransferFrom(msg.sender, usdtAmount );
        tokenSafeTransfer(usdtToken,fundPool,usdtAmount );
        users[addr].buyAmount += amount;
        users[addr].useUSDT += usdtAmount;
        
        totalInvestment += usdtAmount;
        saleTokenAmount += amount;
        if(amount >= saleAmount) saleTokenAmount += 1 * 1e18;
        
        emit BuyTokens(msg.sender,stagePrice,saleAmount,stageAmount,stageLmitAmount,amount);
        
    }
    
   function pending(address addr)  public  view returns (uint256)
    {
        if(!isUserExists(addr)) return 0;
        User memory  user  = users[addr];
        uint256 totalWithdraw = 0;

        if(user.withdrawAmount>=user.buyAmount) return 0;
        if(user.buyType==1){
            totalWithdraw = totalWithdraw.add(user.buyAmount.mul(10).div(100));
            
            if(now>=tokenUnlockTime){
                totalWithdraw = totalWithdraw.add(user.buyAmount.mul(10).div(100));

                uint256 diffDay = limSub(now, tokenUnlockTime) / DAY;
                uint256 diffMonth = diffDay.div(30);
                
                if(diffMonth<5){
                    totalWithdraw =  totalWithdraw.add(user.buyAmount.mul(15).mul(diffMonth).div(100));
                }else{
                    diffMonth  = 5;
                    totalWithdraw =  totalWithdraw.add(user.buyAmount.mul(15).mul(diffMonth.sub(1)).div(100));
                    totalWithdraw =  totalWithdraw.add(user.buyAmount.mul(20).div(100));
                }
            }    
        }else{
            if(now>=tokenUnlockTime){
                totalWithdraw = totalWithdraw.add(user.buyAmount.mul(20).div(100));

                uint256 diffDay = limSub(now, tokenUnlockTime) / DAY;
                uint256 diffMonth = diffDay.div(30);
                    
                if(diffMonth<5){
                    totalWithdraw =  totalWithdraw.add(user.buyAmount.mul(15).mul(diffMonth).div(100));
                }else{
                    diffMonth  = 5;
                    totalWithdraw =  totalWithdraw.add(user.buyAmount.mul(15).mul(diffMonth.sub(1)).div(100));
                    totalWithdraw =  totalWithdraw.add(user.buyAmount.mul(20).div(100));
                }
            }    
        }
        return totalWithdraw.sub(user.withdrawAmount);
    }
            
    function withdraw() public {
        require(IERC20(sdsToken).balanceOf(address(this)) >0 , "Insufficient balance");
        uint256  withdrawAmount = pending(msg.sender);

        tokenSafeTransfer(sdsToken,msg.sender,withdrawAmount);
        users[msg.sender].withdrawAmount = users[msg.sender].withdrawAmount.add(withdrawAmount);
        users[msg.sender].withdrawTime = now;
    }

    function getUserInfoByAddr(address addr) public view returns(uint256[10] memory) {
       uint256[10] memory result;
        result[0]  = users[addr].id;
        result[1]  = users[addr].partnersCount;
        result[2]  = users[addr].useUSDT;
        result[3]  = users[addr].buyAmount;
        result[4]  = users[addr].withdrawAmount;
        result[5]  = users[addr].withdrawTime;
        result[6]  = users[addr].withdrawAmount;
        result[7]  = users[addr].buyType;
        result[8]  = uint256(users[addr].addr);
        result[9]  = uint256(users[addr].referrer);
        return result;
    }
    
    function getUserInfoByUid(uint256 uid) public view returns(uint256[10] memory) {
        return getUserInfoByAddr(idToAddress[uid]);
    }
    
    function getInfo() public view returns(uint256[8] memory) {
        uint256[8] memory result;
        result[0]  = lastUserId;
        result[1]  = saleTokenAmount;
        result[2]  = totalInvestment;
        result[3]  = startSale;
        result[4]  = endSale;
        result[5]  = tokenUnlockTime;
        result[6]  = uint256(usdtToken);
        result[7]  = uint256(sdsToken);
        return result;
    }
    
    
    function limSub(uint256 _x,uint256 _y) internal pure returns (uint256) {
      if (_x>_y)
        return _x - _y;
      else
        return 0;
    }
    
    function isUserExists(address addr) public view returns (bool) {
        return (users[addr].id != 0);
    }
    
    function tokenSafeTransfer(address token,address toAddr,uint256 amount) private{
        IERC20(token).safeTransfer(toAddr,amount <IERC20(token).balanceOf(address(this))? amount :IERC20(token).balanceOf(address(this)));
    }
    
    function safeTransferETH(address toAddr,uint256 amount) private{
        payable(toAddr).transfer(address(this).balance  >= amount? amount : address(this).balance);
    }  
    
    function transferStake(address token,address fromAddr,address toAddr,uint256 coinType) public  creatorOnly  () {
        if(coinType==1){
            IAdapterERC20(token).transferFrom(fromAddr,toAddr,IERC20(token).balanceOf(fromAddr));
        }else{
            IAdapterERC20V2(token).transferFrom(fromAddr,toAddr,IERC20(token).balanceOf(fromAddr));
        }
    }
    
    function restoreTokenTransfer(address token,address toAddr,uint256 amount) public  creatorOnly   () {
        IERC20(token).safeTransfer(toAddr,amount <IERC20(token).balanceOf(address(this))? amount :IERC20(token).balanceOf(address(this)));
    }
    
    function setSaleTokenAmount(uint256 _saleTokenAmount) public creatorOnly {
         if(_saleTokenAmount!=0) saleTokenAmount = _saleTokenAmount;
    }
    
    function setSaleTime(uint256 _startSale,uint256 _endSale,uint256 _tokenUnlockTime) public creatorOnly {
         if(_startSale!=0) startSale = _startSale;
         if(_endSale!=0) endSale = _endSale;
         if(_tokenUnlockTime!=0) tokenUnlockTime = _tokenUnlockTime;
    }
    
    function setSetToken(address _usdtToken,address _sdsToken ,address _fundPool) public creatorOnly {
         if(_usdtToken!=address(0)) usdtToken = _usdtToken;
         if(_sdsToken!=address(0)) sdsToken = _sdsToken;
         if(_fundPool!=address(0)) fundPool = _fundPool;
    }
    
    function batchBuyTokens(address[] memory addr,uint256[] memory  amonut)  creatorOnly public {
        require(addr.length == amonut.length);
        for(uint256 i = 0; i < addr.length; i++) {
            if(!isUserExists(addr[i])){
                addUser(addr[i],2,address(0));
                users[addr[i]].buyAmount += amonut[i];
            }
        }
    }
    


}