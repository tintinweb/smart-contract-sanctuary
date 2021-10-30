/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// File: escrows/Address.sol



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

// File: escrows/SafeMath.sol



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

// File: escrows/IERC20.sol



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

// File: escrows/escrow.sol







pragma solidity ^0.8.0; 

contract Escrow {

    using SafeMath for uint256;
    using Address for address payable;

    enum State{initiated,paid,disputed}
    

    // Struct typed data structure to represent each Proposal and its information inside
    struct proposal{
        uint256 id;
        address buyer;
        address payable seller;
        uint256 amt;
        uint256 time;
        bool accepted;
        uint256 payTokenType;
    }

   // Struct typed data structure to represent each Escrow and its information inside
    struct instance{
        uint256 id;
        address buyer;
        address payable seller;
        uint256 payTokenType; // 0 if BNB/ 1 if LKN tokens /2 if BUSD Token
        uint256 totalAmt;
        uint256 amtPaid;
        bool sellerConfirmation;
        bool buyerConfirmation;
        uint256 start;
        uint256 timeInDays;
        State currentState;
    }
    
     // Info of each pool.
    struct PoolInfo {
        IERC20 token;           // Address of token contract.
    }

    //Owner address
    address payable public owner;
    
    //Liquiduty pool address
    address payable public liquidityPool;

    //Admin adress
    address payable public admin;

    // Burn Address
    address payable public burnAddress;
    
    // Total number of Proposals 
    uint256 public proposalCount;
    
    // Mapping for storing each proposal
    mapping(uint256=>proposal) public getProposal;

    // Mapping for storing each Escrow
    mapping(uint256 => instance) public getEscrow;

    //mapping for storing BNBamounts corresponding to each Escrow
    mapping(uint256=>uint256) public escrowAmtsBNB;
    
    //mapping for storing Tokenamounts corresponding to each Escrow
    mapping(uint256=>uint256) public escrowAmtsToken;

    // Mapping for BNB balances to store if they send directly to this smart contract
    mapping(address => uint256) balances;


    // Owner cut
    uint8 public ownerCut;

    // PoolCut
     uint8 public PoolCut;

    // Admin Cut for Non-Token Based
    uint8 public adminCutBNB;
    
    // Admin Cut Token Based
    uint8 public adminCutLKN;
    
    // Burn Cut for Non-Token Based
    uint8 public burnCutBNB;
    
    // Burn Cut for Token Based
    uint8 public burnCutLKN;
    
    // Buyer refelction
    uint8 public buyerRef;


    //Mapping to store Disputed Escrow ID with the Disputer Address(Who raised dispute)
    mapping(uint256=> address) public disputedRaisedBy;

    //Mapping to store Escrow creator with Escrow Ids
    mapping(address=>uint256) public AddressEscrowMap;

    // Total Number of Escrows
    uint256 public totalEscrows;

    // Max number of time limit(in Days)
    uint256 public timeLimitInDays;

    // Array to store all disputed escrows
    uint256[] public disputedEscrows;
 
    // Array to store Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Event emitter type when Escrow will be created
    event EscrowCreated(
        uint256 id,
        address buyer,
        address payable seller,
        uint256 payTokenType,
        uint256 paid,
        uint256 start,
        uint256 timeInDays,
        State currentState
    );
    // Proposal emitter type when Proposal will be created
     event ProposalCreated(
        uint256 id,
        address buyer,
        address payable seller,
        uint256 payTokenType,
        uint256 paid,
        uint256 start,
        uint256 timeInDays
    );
    

    // State change event emitter
    event StateChanged(uint256 indexed id,State indexed _state);

    // Onlyowner Access Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Onlyadmin Access Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }


    // OnlyBuyer Access Modifiers
    modifier onlyBuyer(uint _id){
        require(msg.sender == getEscrow[_id].buyer);
        _;
    }

    // OnlySeller Access Modifiers
    modifier onlySeller(uint _id){
        require(msg.sender == getEscrow[_id].seller);
        _;
    }

    constructor(address payable _owner,uint256 _timeLimitInDays,address payable _admin,address payable _liquidityPool,address payable _burnAddress) {
        owner = _owner;
        burnAddress = _burnAddress;
        admin = _admin;
        liquidityPool = _liquidityPool;
        totalEscrows =0;
        timeLimitInDays = _timeLimitInDays;
        
        poolInfo.push(PoolInfo({token: IERC20(address(0xc7F0A7489Ce09fe9583A1474eB6Dc2AFb63Bf2cF))}));
        poolInfo.push(PoolInfo({token: IERC20(address(0x35efE0E04d134Cf73Bafc292e51B05970f1b9233))}));

    }
    

    // Function to set tax %age and also update it and it can only be called by admin
    function setFeesAdminPoolCut(uint8 fees,uint8 _adminBNB,uint8 _adminLKN,uint8 _poolCut,uint8 _burnCutBNB,uint8 _burnCutLKN,uint8 _buyerRef) public onlyOwner {
        ownerCut = fees;
        PoolCut = _poolCut;
        adminCutBNB=_adminBNB;
        adminCutLKN=_adminLKN;
        burnCutBNB=_burnCutBNB;
        burnCutLKN=_burnCutLKN;
        buyerRef= _buyerRef;
        
    }
    // Function to create each proposal along with all the info needed
    function createProposal(uint256 amt,uint256 time,uint256 payType) public payable{
        require(msg.value >=amt);
        address payable _seller = payable(address(0));
        proposalCount++;
        uint256 _id = proposalCount;
        getProposal[_id]=proposal(_id,msg.sender,_seller,amt,time,false,payType);
        emit ProposalCreated(_id,msg.sender,_seller,payType,amt,block.timestamp,time);
    }
    
    // Function to accept each proposal along with all the info needed and Creating ESCROW in the end
    function acceptProposal(uint256 _id) public {
        require(!getProposal[_id].accepted,"already accepted");
        getProposal[_id].seller = payable(msg.sender);
        getProposal[_id].accepted = true;
        proposal memory temp = getProposal[_id];
        if(temp.payTokenType ==0){
            createEscrowBNB(temp.buyer,temp.seller,temp.amt,temp.time);   
        }else {
            createEscrowToken(temp.buyer,temp.payTokenType,temp.seller,temp.amt,temp.time);
        }
        
    }
     
     // Function to create proposals for Tokens based 
    function createProposalToken(uint256 amt,uint256 time,uint256 payTokenType) internal {
        PoolInfo storage pool = poolInfo[payTokenType-1];
        IERC20 token = pool.token;
        require(token.balanceOf(address(msg.sender))>=amt,"You dont have enough Tokens");
        address payable _seller = payable(address(0));
        proposalCount++;
        uint256 _id = proposalCount;
        token.transferFrom(address(msg.sender), address(this), amt);
        getProposal[_id]=proposal(_id,msg.sender,_seller,amt,time,false,payTokenType);
        emit ProposalCreated(_id,msg.sender,_seller,payTokenType,amt,block.timestamp,time);
    }

    // Function to create milestone proposals for Tokens based
    function createProposalMileStoneToken(uint256[] calldata amounts,uint256[] calldata times,uint256[] calldata payType) public{
           uint256 len = amounts.length;
           for(uint256 i=0;i<len;i++){
                createProposalToken(amounts[i],times[i],payType[i]);
           }
    }

    // Function to create milestone proposals for Non-Token based
    function createProposalMileStone(uint256[] calldata amounts,uint256 sum ,uint256[] calldata times,uint256[] calldata payType) public payable{
           require(msg.value>=sum,"You arent depositing enough funds");
           uint256 len = amounts.length;
           for(uint256 i=0;i<len;i++){
                createProposal(amounts[i],times[i],payType[i]);
           }
    }
    
    // Function to accept milestone proposals
    function acceptProposalMilestone(uint256[] calldata _ids) public {
           uint256 len = _ids.length;
           for(uint256 i=0;i<len;i++){
                acceptProposal(_ids[i]);
           }
    }
    
    // Function to create Escrow of type Non-Token Based
    function createEscrowBNB(address _buyer,address payable _seller,uint256 amt,uint256 timeInDays) internal {
        require(timeInDays <= timeLimitInDays,"timePeriod more than limit");
        totalEscrows++;
        uint256 id = totalEscrows;
        getEscrow[id]= instance(id,_buyer,_seller,0,amt,0,false,false,block.timestamp,timeInDays,State.initiated);
        escrowAmtsBNB[id] = amt;
        AddressEscrowMap[_buyer] = id;
        emit EscrowCreated(id,_buyer,_seller,0,amt,block.timestamp,timeInDays,State.initiated);
    }

    // Function to create Escrow of type Token Based
    function createEscrowToken(address __buyer,uint256 _tokenID,address payable _seller,uint256 amt,uint256 timeInDays) internal {
        require(timeInDays <= timeLimitInDays,"timePeriod more than limit");
        totalEscrows++;
        uint256 id = totalEscrows;
        getEscrow[id]= instance(id,__buyer,_seller,_tokenID,amt,0,false,false,block.timestamp,timeInDays,State.initiated);
        escrowAmtsToken[id] = amt;
        AddressEscrowMap[__buyer] = id;
        emit EscrowCreated(id,__buyer,_seller,_tokenID,amt,block.timestamp,timeInDays,State.initiated);
    }

    // Function to release Payments associated with each Escrow ID
    function releasePayment(uint256 _id) public {
        instance memory temp = getEscrow[_id];
        require((msg.sender == temp.seller) || (msg.sender == temp.buyer));
        require(temp.currentState != State.disputed, 'Unalbe to release payment, Escrow in dispute state');
        require(!getEscrow[_id].buyerConfirmation,"Buyer already confirmed");
        delete getEscrow[_id];

        if(temp.payTokenType ==0){
            uint256 Temp= escrowAmtsBNB[_id];
            uint256 _PoolCut = ceilDiv(SafeMath.mul(PoolCut,Temp),10000);
            uint256 _adminCut = ceilDiv(SafeMath.mul(adminCutBNB,Temp),10000);//service fee
            uint256 _burnCut = ceilDiv(SafeMath.mul(burnCutBNB,Temp),10000);
            escrowAmtsBNB[_id] = 0;
            temp.seller.sendValue(Temp);
            admin.sendValue(_adminCut);
            burnAddress.sendValue(_burnCut);
            liquidityPool.sendValue(_PoolCut);
        }

        else if (temp.payTokenType ==1){
            PoolInfo storage pool = poolInfo[temp.payTokenType-1];
            IERC20 token = pool.token;
            uint256 _temp = escrowAmtsToken[_id];
            uint256 buyerReflection= ceilDiv(SafeMath.mul(buyerRef,_temp),10000);
            uint256 _adminCut = ceilDiv(SafeMath.mul(adminCutLKN,_temp),10000);
            uint256 _burnCut = ceilDiv(SafeMath.mul(burnCutLKN,_temp),10000);
            escrowAmtsToken[_id] = 0;   
            token.transfer(temp.seller,_temp);
            token.transfer(admin,_adminCut);
            token.transfer(burnAddress,_burnCut);
            token.transfer(address(msg.sender),buyerReflection);
        }
        else{
            PoolInfo storage pool = poolInfo[temp.payTokenType-1];
            IERC20 token = pool.token;
            uint256 _temp = escrowAmtsToken[_id];
            uint256 _adminCut = ceilDiv(SafeMath.mul(adminCutBNB,_temp),10000);
            uint256 _burnCut = ceilDiv(SafeMath.mul(burnCutBNB,_temp),10000);
            uint256 _PoolCut = ceilDiv(SafeMath.mul(PoolCut,_temp),10000);
            escrowAmtsToken[_id] = 0;   
            token.transfer(temp.seller,_temp);
            token.transfer(admin,_adminCut);
            token.transfer(burnAddress,_burnCut);
            token.transfer(liquidityPool, _PoolCut);
        }
        getEscrow[_id].buyerConfirmation=true;
        getEscrow[_id].currentState = State.paid;
    }

    //Function to raise dispute by rightful users
    function raiseDispute(uint256 id) public{
        require(msg.sender == getEscrow[id].seller || msg.sender == getEscrow[id].buyer);
        require(!getEscrow[id].buyerConfirmation || !getEscrow[id].sellerConfirmation);
        require(getEscrow[id].currentState != State.disputed);
        getEscrow[id].currentState = State.disputed;
        disputedEscrows.push(id);
        disputedRaisedBy[id] == msg.sender;
        emit StateChanged(id, getEscrow[id].currentState);
    }

    // Function to accept and cancel dispute and it can only be called by owner
    function approveForWithdraw(uint256 id,bool withdrawParty) public {  //onlyOwner function
        // withdrawParty -- true if buyer,false if seller
        require(getEscrow[id].currentState == State.disputed);
        if(withdrawParty){
            payable(getEscrow[id].buyer).sendValue(escrowAmtsBNB[id]);
        }
        else if(!withdrawParty){
            getEscrow[id].seller.sendValue(escrowAmtsBNB[id]);
        }
    }
    
    // Function to cancel proposal before User B accepts the proposal and created Escrow
    function cancelProposal(uint256[] calldata _ids) public {
        uint256 len = _ids.length;
        for(uint256 _id=0;_id<len;_id++){
        uint256 id = _ids[_id];    
        require((getProposal[id].buyer==msg.sender) || (getProposal[id].seller == msg.sender),"You havent created this Proposal");
        require(!(getProposal[id].accepted), "Proposal accepted by seller, try raising dispute instead");
        uint256 _amount = getProposal[id].amt;
        if(getProposal[id].payTokenType ==0){
          payable(getProposal[id].buyer).sendValue(_amount);
        }
        else{
             PoolInfo storage pool = poolInfo[getProposal[id].payTokenType-1];
             IERC20 token = pool.token;
             token.transfer(getProposal[id].buyer,_amount);
        }
        delete getProposal[id];
        }
    }
     // Function to cancel Escrow and refund funds back to user A
    function cancelEscrow(uint256[] calldata _ids) public {
        uint256 len = _ids.length;
        for(uint256 _id=0;_id<len;_id++){
        uint256 id = _ids[_id];    
        require((getEscrow[id].buyer==msg.sender) || (getEscrow[id].seller == msg.sender),"You havent created this Escrow");
        require(getEscrow[id].currentState != State.disputed);
        uint256 _amount = getEscrow[id].totalAmt;
        if(getEscrow[id].payTokenType ==0){
            payable(getEscrow[id].buyer).sendValue(_amount);
        }
        else{
             PoolInfo storage pool = poolInfo[getEscrow[id].payTokenType-1];
             IERC20 token = pool.token;
             token.transfer(getEscrow[id].buyer,_amount);
        }
        delete getEscrow[id];
        }
    }
    
    function getPoolInfo(uint256 _id) public view returns(PoolInfo memory){
        return poolInfo[_id];
    }
    
    //Function to get all disputed Escrows
    function getDisputedEscrows() public view returns(uint256[] memory) {
        return disputedEscrows;
    }
    

    // Function for Ceil Devision
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

     // Fallback function which gets triggered when someone sends BNB to this contracts address directly
    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}