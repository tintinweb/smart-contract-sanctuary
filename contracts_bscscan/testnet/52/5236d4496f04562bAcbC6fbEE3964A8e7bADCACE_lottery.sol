/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

contract lottery
{
   using Address for address;
   address token;

   enum Status 
   {
        Pending,
        Open,
        Close,
        Claimable
   }
    
    struct lotterys
    {
        Status status;
        uint256 endlotterytime;
        uint256 startlotterytime;
        uint256 priceofticket;
        uint256 discountDivisor;
        uint256 amountofcake;
        uint256 [] rewarddistribution;
    }
    
    struct Ticket {
        address owner;
        uint256 ticketid;
    }
    
    struct userinfo
    {
        uint256 numberofticket;
        uint256 amountofcake;
        uint256 rewards;
    }
    
    address owner;
    uint256 maxnumberofticket = 100;
    uint256 weeklotterycount  = 14;
    uint256 rewarddistributionumber = 7;
    uint256 minPriceTicketInCake;
    uint256 maxPriceTicketInCake;
    uint256 pendingInjectionNextLottery;
    uint256 public lotteryid;
    uint256 treasurefundsvalue;
    uint256 [] lotterypercentage;    //fille to start
    mapping(uint256 => Ticket) _ticketdetail;
    mapping(uint256 => lotterys) _lotteries;
    mapping(uint256 => mapping(address => uint256 [])) ticketNumber;
    mapping(uint256 => uint256 []) lotteryNumber;
    mapping(uint256 => userinfo) userdata;
    mapping(uint256 => uint256 []) rewardsdividend;
    
    constructor(address _address,address _owneraddress)
    {
       token = _address;
       owner = _owneraddress;
    }
    
    modifier onlyOwner() {
        require((msg.sender == owner), "Not owner or injector");
        _;
    }
    
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }
    
    function Startlottery(uint256 endlotteryhours,uint256 endlotteryday,uint256 _priceofticket,uint256 _discountdivisor,uint256 [] memory _rewardsBreakdown) public onlyOwner
    {
         require(lotteryid==0 ||  _lotteries[lotteryid].status == Status.Claimable,"Lottery not end yet");
         require(_priceofticket !=0 && _discountdivisor != 0 ,"priceofticket and discountdivisor not equal to zero");
         require(minPriceTicketInCake<=_priceofticket && maxPriceTicketInCake> _priceofticket,"price should be less or greater");
         require(
            (_rewardsBreakdown[0] +
                _rewardsBreakdown[1] +
                _rewardsBreakdown[2] +
                _rewardsBreakdown[3] +
                _rewardsBreakdown[4] +
                _rewardsBreakdown[5]) == 100,
            "Rewards must equal 100"
         );
         
         lotteryid+=1;
         uint256 amount = treasurefundsvalue/(weeklotterycount);
         uint256 endtime = (endlotteryday * uint256(86400))+(endlotteryhours*uint256(3600));
         _lotteries[lotteryid] = lotterys({status:Status.Open,endlotterytime:endtime,startlotterytime:block.timestamp,priceofticket:_priceofticket,discountDivisor:_discountdivisor,amountofcake:(pendingInjectionNextLottery+amount),rewarddistribution:_rewardsBreakdown});
    }
                                                              
    function buyTicket(uint256 _lotteryid,uint256 numberofticket) public notContract
    {
        require(numberofticket!=0,"number of ticket is not be zero");  
        require(_lotteries[_lotteryid].status == Status.Open, "Lottery is not open");
        require(block.timestamp < _lotteries[_lotteryid].endlotterytime,"Lottery is over");
        require(!timeperiod(_lotteryid),"lottery end");
        uint256 amountCakeToTransfer = _calculateTotalPriceForBulkTickets(
            _lotteries[_lotteryid].discountDivisor,
            _lotteries[_lotteryid].priceofticket,
            numberofticket
        );

        IERC20(token).transferFrom(address(msg.sender), address(this), amountCakeToTransfer);
        _lotteries[_lotteryid].amountofcake+=amountCakeToTransfer;     
        
        userdata[_lotteryid].numberofticket = numberofticket;
        userdata[_lotteryid].amountofcake = amountCakeToTransfer;
        
        for (uint256 i = 0; i <numberofticket; i++) 
        {
            randomnumbergenerate(_ticketdetail[_lotteryid].ticketid,numberofticket,amountCakeToTransfer,_lotteryid,treasurefundsvalue);
            _ticketdetail[_lotteryid].ticketid += 1;  
            _ticketdetail[_lotteryid].owner = msg.sender;
        }
    }
                       
    function randomnumbergenerate(uint256 ticketid,uint256 ticketnumber,uint256 amountCakeToTransfer,uint256 _lotteryid,uint256 _treasurefundsvalue) internal
    {
        uint256 rand1 = uint(keccak256(abi.encodePacked(ticketid,msg.sender,block.timestamp,block.difficulty))) % 10 ;
        ticketNumber[_lotteryid][msg.sender].push(rand1);
        uint256 rand2 = uint(keccak256(abi.encodePacked(ticketnumber,msg.sender,block.timestamp))) % 10 ;
        ticketNumber[_lotteryid][msg.sender].push(rand2);
        uint256 rand3 = uint(keccak256(abi.encodePacked(amountCakeToTransfer,msg.sender,block.timestamp,block.number))) % 10 ;
        ticketNumber[_lotteryid][msg.sender].push(rand3);
        uint256 rand4 = uint(keccak256(abi.encodePacked(block.difficulty,msg.sender,block.timestamp))) % 10 ;
        ticketNumber[_lotteryid][msg.sender].push(rand4);
        uint256 rand5 = uint(keccak256(abi.encodePacked(_lotteryid,msg.sender,block.timestamp,block.number))) % 10 ;
        ticketNumber[_lotteryid][msg.sender].push(rand5);
        uint256 rand6 = uint(keccak256(abi.encodePacked(_treasurefundsvalue,msg.sender,block.timestamp,block.number,block.difficulty))) % 10 ;
        ticketNumber[_lotteryid][msg.sender].push(rand6);
    }
    
    //put funds on every weeks using this function
    function treasurefunds(uint256 amount) public onlyOwner
    {
        treasurefundsvalue+=amount;
        IERC20(token).transferFrom(address(msg.sender), address(this), amount);
    }
                         
    function Claimable(uint256 _lotteryid,uint256 [] memory bracketnumber) public
    {
        require(timeperiod(_lotteryid),"time not come");
        _lotteries[_lotteryid].status = Status.Close;
        uint256 rewards;
        for (uint256 i = 0 ; i <bracketnumber.length ; i++) 
        {
            uint256 amount = (_lotteries[_lotteryid].amountofcake*(lotterypercentage[bracketnumber[i]]))/100;
            rewards += amount/(rewardsdividend[_lotteryid][bracketnumber[i]]);
        }
        
        IERC20(token).transfer(msg.sender , rewards);
        userdata[_lotteryid].rewards = rewards;
        _lotteries[_lotteryid].amountofcake-=rewards;
        pendingInjectionNextLottery =  _lotteries[_lotteryid].amountofcake;
    }
    
    function lotteryNumbergenerate(uint256 _lotteryid,uint256 [] memory _value,uint256 [] memory _different) public onlyOwner
    {
        uint256 rand1 = uint(keccak256(abi.encodePacked(_value[0],msg.sender,block.timestamp,block.difficulty,_different[0]))) % 10 ;
        lotteryNumber[_lotteryid].push(rand1);
        uint256 rand2 = uint(keccak256(abi.encodePacked(_value[1],msg.sender,block.timestamp,_different[1]))) % 10 ;
        lotteryNumber[_lotteryid].push(rand2);
        uint256 rand3 = uint(keccak256(abi.encodePacked(_value[2],msg.sender,block.timestamp,block.number,_different[2]))) % 10 ;
        lotteryNumber[_lotteryid].push(rand3);
        uint256 rand4 = uint(keccak256(abi.encodePacked(block.difficulty,msg.sender,block.timestamp,_different[3]))) % 10 ;
        lotteryNumber[_lotteryid].push(rand4);
        uint256 rand5 = uint(keccak256(abi.encodePacked(_value[3],msg.sender,block.timestamp,block.number,_different[4]))) % 10 ;
        lotteryNumber[_lotteryid].push(rand5);
        uint256 rand6 = uint(keccak256(abi.encodePacked(_value[4],msg.sender,block.timestamp,block.number,block.difficulty,_different[5]))) % 10 ;
        lotteryNumber[_lotteryid].push(rand6);
    }
    
    function setlotterypercentage(uint256 [] memory _value) public onlyOwner
    {
        require((_value[0] + _value[1] + _value[2] + _value[3] + _value[4] +_value[5]) == 100,"Rewards must equal 100");
        require(_value.length == rewarddistributionumber,"put correct length");
        lotterypercentage = _value;
    }
    
    function setrewardsdividend(uint256 _lotteryid,uint256 [] memory _value) external onlyOwner
    {
        rewardsdividend[_lotteryid] = _value;
    }
    
    function setMinAndMaxTicketPriceInCake(uint256 _minPriceTicketInCake, uint256 _maxPriceTicketInCake)
        external
        onlyOwner
    {
        require(_minPriceTicketInCake <= _maxPriceTicketInCake, "minPrice must be < maxPrice");

        minPriceTicketInCake = _minPriceTicketInCake;
        maxPriceTicketInCake = _maxPriceTicketInCake;
    }

    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) external onlyOwner {
        require(_maxNumberTicketsPerBuy != 0, "Must be > 0");
        maxnumberofticket = _maxNumberTicketsPerBuy;
    }
    
    function timeperiod(uint256 _lotteryid) public view returns(bool status)
    {
        uint256 endtime = _lotteries[_lotteryid].startlotterytime + _lotteries[_lotteryid].endlotterytime;
        if(block.timestamp >= endtime)
        {
            return true;
        }
        
    }
    
    function _calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) internal pure returns (uint256) {
        return (_priceTicket * _numberTickets * (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
    }
    
    function rewarddistributio(uint256 _lotteryid) public view returns(uint256,uint256,uint256,uint256,uint256,uint256)
    {
        uint256 totalamount = _lotteries[_lotteryid].amountofcake;
        uint256 value1 = (totalamount*lotterypercentage[0])/100 ;
        uint256 value2 = (totalamount*lotterypercentage[1])/100 ;
        uint256 value3 = (totalamount*lotterypercentage[2])/100 ;
        uint256 value4 = (totalamount*lotterypercentage[3])/100 ;
        uint256 value5 = (totalamount*lotterypercentage[4])/100 ;
        uint256 value6 = (totalamount*lotterypercentage[5])/100 ;
        
        return (value1,value2,value3,value4,value5,value6);
    }
    
    function _viewticketnumber(uint256 _lotteryid) external view returns(uint256 [] memory)
    {
        return ticketNumber[_lotteryid][msg.sender];
    }

    function _get_calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) external pure returns(uint256)
    {
        uint256 amount =  (_priceTicket * _numberTickets * (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
        return amount;
    }
    
    function _lotteryNumber(uint256 _lotteryid) external view returns(uint256 [] memory)
    {
        return lotteryNumber[_lotteryid];
    }
    
    function userinfomation(uint256 _lotteryid) external view returns(uint256,uint256,uint256)
    {
        return (userdata[_lotteryid].numberofticket,userdata[_lotteryid].amountofcake,userdata[_lotteryid].rewards);
    }
    
    
    function _isContract(address _addr) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;  
    }

}