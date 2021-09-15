/**
 *Submitted for verification at BscScan.com on 2021-09-15
*/

//SPDX-License-Identifier: UNLICENSED
 
     pragma solidity 0.8.2;
     interface ERC20 {
        function totalSupply() external view returns (uint);
        function balanceOf(address tokenOwner) external view returns (uint balance);
        function transfer(address to, uint tokens) external returns (bool success);
        
        function allowance(address tokenOwner, address spender) external view returns (uint remaining);
        function approve(address spender, uint tokens) external returns (bool success);
        function transferFrom(address from, address to, uint tokens) external returns (bool success);
        
        event Transfer(address indexed from, address indexed to, uint tokens);
        event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    }
       
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an BNB balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

    constructor ()  {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

abstract contract Context {
    

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
         
 contract NewBosonWallet is Context, ReentrancyGuard{
     
     using Address for address;
     using SafeMath for uint;
     
     string private _name = "New Boson Community Wallet";
     function name() public view returns (string memory) {
        return _name;
    }
    
    //defining marketingwallet
    address payable public marketingwallet;
    
    function Marketingwallet (address payable _marketingwallet) onlyAdmin public
    {
        marketingwallet= _marketingwallet;
    }
    
             uint public value;
             address public admin;
      //marketing fund 5% for marketing and service      
              receive () payable external {
                  uint marketingfund = msg.value.mul(5).div(100);
                  (bool success, ) = address(marketingwallet).call{ value: marketingfund }("");
            require(success, " Error: Cannot send");    
                  value=value.add(msg.value.mul(95).div(100));
                  
              }
              
            
             constructor() {
                         admin = msg.sender;
                         allowed = true;
                         timestampA=block.timestamp;
                         timestampB=block.timestamp;
                         
    }
    
    //defining onlyadmin
         modifier onlyAdmin()
         {
            require(msg.sender == admin, "Not owner");
            _;
        }
       
        
        
    //transfer of admin
         function ownershipstransfer(address New) onlyAdmin public
         { admin = New;}   
         
    
        
    
         mapping (address=>uint8) public voter25;
          mapping (address=>uint8) public voter50;
           mapping (address=>uint8) public voter100;
             mapping (address=>uint8) public mvoteagainstoneyear;
             mapping (address=>uint8) public mvoteagainstsixmonths;
         uint public votepercent25;
         uint public votepercent50;
         uint public votepercent100;
          uint public votedagainstoneyear;
          uint public votedagainstsixmonths;
          
                address[]Voter25;
                address[]Voter50;
                address[]Voter100;
                address[]avoteagainstoneyear;
                address[]avoteagainstsixmonths;
            
             
                
        
              
    //function Vote to withdraw 25%
    function vote25percent() isHuman nonReentrant public returns (bool)
    { 
        require (voter25[msg.sender]<1);
        uint G = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).totalSupply();
        uint B = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).balanceOf(address(msg.sender));
        require (B>0 && B<G);
        Voter25.push(msg.sender);
        voter25[msg.sender]=1;
        uint L = B.mul(10000000000);
        uint P = L.div(G);
        votepercent25=votepercent25.add(P);
          return true;
        
              
    }
   //function Vote to withdraw 50%
          function vote50percent() isHuman nonReentrant public returns (bool)
    {
        require (voter50[msg.sender]<1);
        uint G = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).totalSupply();
        uint B = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).balanceOf(address(msg.sender));
         require (B>0 && B<G);
         uint L = B.mul(10000000000);
         uint P = L.div(G);
        votepercent50=votepercent50.add(P);
         Voter50.push(msg.sender);
        voter50[msg.sender]=1;
               return true;
    }
    //function Vote to withdraw 100%
    function vote100percent() isHuman nonReentrant public returns (bool)
    {
        require (voter100[msg.sender]<1);
        uint G = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).totalSupply();
        uint B = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).balanceOf(address(msg.sender));
        require (B>0 && B<G);
         uint L = B.mul(10000000000);
         uint P = L.div(G);
        votepercent100=votepercent100.add(P);
         Voter100.push(msg.sender);
        voter100[msg.sender]=1;
               return true;
    }
    
    //function Vote against withdrawal on oneyear
     function Voteagainstoneyr() isHuman nonReentrant public returns (bool)
     {
        require (mvoteagainstoneyear[msg.sender]<1);
        uint G = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).totalSupply();
        uint B = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).balanceOf(address(msg.sender));
        require (B>0 && B<G);
         uint L = B.mul(10000000000);
         uint P = L.div(G);
        votedagainstoneyear=votedagainstoneyear.add(P);
        avoteagainstoneyear.push(msg.sender);
        mvoteagainstoneyear[msg.sender]=1;
               return true;
    }
    
     //function Vote against withdrawal on six months
     function Voteagainst6months() isHuman nonReentrant public returns (bool)
     {
        require (mvoteagainstsixmonths[msg.sender]<1);
        uint G = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).totalSupply();
        uint B = ERC20(0xDA93C706F1761006E5A72576358D304b6D32a7F6).balanceOf(address(msg.sender));
        require (B>0 && B<G);
         uint L = B.mul(10000000000);
         uint P = L.div(G);
        votedagainstsixmonths=votedagainstsixmonths.add(P);
         avoteagainstsixmonths.push(msg.sender);
        mvoteagainstsixmonths[msg.sender]=1;
               return true;
    }
    //defining withdraw address
    address payable public withdrawaddress;
    
    function Withdrawaddress (address payable _withdrawaddress) onlyAdmin public{
        withdrawaddress=_withdrawaddress;
            }
            
      //withdraw 25% after successfully voted by more than 50% of New Boson holders      
            
    function withdraw25() nonReentrant public onlyAdmin returns(bool)
    {
        require(votepercent25>5000000000);
         for (uint i=0; i<Voter25.length; i++)
         voter25[Voter25[i]]=0;
         votepercent25=0;
         uint value25 = value.mul(25).div(100);
        value = value.sub(value25);
        (bool success, ) = address(withdrawaddress).call{ value: value25 }("");
        require(success, " Error: Cannot send, voted against by holders");  
        delete Voter25;
        return true;
    }
    
    //withdraw 50% after successfully voted by more than 50% of New Boson holders 
      
    function withdraw50() nonReentrant public onlyAdmin returns(bool){
        require(votepercent50>5000000000);
        for (uint i=0; i<Voter50.length; i++)
        voter50[Voter50[i]]=0;
        votepercent50=0;
        uint value50 = value.mul(50).div(100);
        value = value.sub(value50);
        (bool success, ) = address(withdrawaddress).call{ value: value50 }("");
        require(success, " Error: Cannot send, voted against by holders");  
        delete Voter50;
        return true;
    }
    
   //withdraw 100% after successfully voted by more than 50% of New Boson holders 
   
    function withdraw100() nonReentrant public onlyAdmin returns(bool){
        require(votepercent100>5000000000);
       for (uint i = 0; i<Voter100.length; i++)
        voter100[Voter100[i]]=0;
        votepercent100=0;
        value = 0;
        (bool success, ) = address(withdrawaddress).call{ value: address(this).balance }("");
        require(success, " Error: Cannot send, voted against by holders"); 
        delete Voter100;
        return true;
    }
    
    
    //withdraw is set after oneyear for emergency or required situations
    //if not requires will be extended for next oneyear
    //cannot withdraw if more than 50% of New boson holders vote against withdraw
      uint public timestampA;
    function withdrawoneyear (bool requirement) nonReentrant public onlyAdmin returns(bool){
        if (requirement == true)
    {
        require (votedagainstoneyear<5000000000);
        require (block.timestamp>timestampA.add(31536000));
        for (uint i=0; i<avoteagainstoneyear.length; i++)
        mvoteagainstoneyear[avoteagainstoneyear[i]]=0;
        votedagainstoneyear=0;
        value = 0;
        (bool success, ) = address(withdrawaddress).call{ value: address(this).balance }("");
        require(success, " Error: Cannot send, voted against by holders");   
        timestampA=block.timestamp;
        delete avoteagainstoneyear;
        return true;
    }
        require (requirement == false);
        require (block.timestamp>timestampA.add(31536000));
        timestampA=block.timestamp;
        for (uint i=0; i<avoteagainstoneyear.length; i++)
        mvoteagainstoneyear[avoteagainstoneyear[i]]=0;
        votedagainstoneyear=0;
        delete avoteagainstoneyear;
        return false;
      
    }   
    
    //withdraw 50% of value is set after six months for emergency or required situations
    //if not requires will be extended for next six months
    //cannot withdraw if more than 50% of New boson holders vote against withdraw
      uint public timestampB;
    function withdrawsixmonths (bool requirement) nonReentrant onlyAdmin public returns(bool){
        if (requirement == true)
    {
        require (votedagainstsixmonths<5000000000);
        require (block.timestamp>timestampB.add(15768000));
        for (uint i=0; i<avoteagainstsixmonths.length; i++)
        mvoteagainstsixmonths[avoteagainstsixmonths[i]]=0;
        votedagainstsixmonths=0;
        uint valuesixmonths = value.mul(50).div(100);
        value = value.sub(valuesixmonths);
        (bool success, ) = address(withdrawaddress).call{ value: valuesixmonths }("");
        require(success, " Error: Cannot send, voted against by holders"); 
        timestampB=block.timestamp;
        delete avoteagainstsixmonths;
        return true;
    }
        require (requirement == false);
        require (block.timestamp>timestampB.add(15768000));
        timestampB=block.timestamp;
        for (uint i=0; i<avoteagainstsixmonths.length; i++)
        mvoteagainstsixmonths[avoteagainstsixmonths[i]]=0;
        votedagainstsixmonths=0;
        delete avoteagainstsixmonths;
        return false;
      
    }   
        
        
    //one time withdraw of 30% to provide pancake exchange trading liquidity during successful launch
    bool public allowed;
    function withdrawforlisting () isHuman nonReentrant public onlyAdmin returns(bool){
        require (allowed==true);
        uint withdraw30 =value.mul(30).div(100);
        (bool success, ) = address(withdrawaddress).call{ value: withdraw30 }("");
            require(success, " Error: Can claim only once");    
               value = value.sub(withdraw30);
               allowed = false; // makes this function non-reusable
        return true;
    }
    
     
        
    }