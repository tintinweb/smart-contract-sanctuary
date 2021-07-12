/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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


library Address {
   
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

   
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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}




contract CloverXGOLDBasic {

    address public impl;
    address public contractOwner;

    constructor() public {
        contractOwner = msg.sender;
    }
    
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
        
        mapping(uint8 => bool) activexGoldLevels;
        
        mapping(uint8 => xGold) xGoldMatrix;
    }
    
    
    struct xGold {
        address currentReferrer;
        address[2] firstLevelReferrals;
        address[4] secondLevelReferrals;
        address[8] thirdLevelReferrals;
		address[16] forthLevelReferrals;
        bool blocked;
        uint reinvestCount;

        address closedPart;
    }

    uint8 public LAST_LEVEL;
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
    mapping(address => uint) public balances; 

    uint public lastUserId;
    address public id1;
    address public multisig;
    
    mapping(uint8 => uint) public levelPrice;

    IERC20 public depositToken;
    
    uint public BASIC_PRICE;

    bool public locked;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event Reinvest(address indexed user, address indexed currentReferrer, address indexed caller, uint8 matrix, uint8 level);
    event Upgrade(address indexed user, address indexed referrer, uint8 matrix, uint8 level);
    event NewUserPlace(address indexed user, address indexed referrer, uint8 matrix, uint8 level, uint8 place);
    event MissedEthReceive(address indexed receiver, address indexed from, uint8 matrix, uint8 level);
    event SentExtraEthDividends(address indexed from, address indexed receiver, uint8 matrix, uint8 level);
}

contract CloverXGOLD is CloverXGOLDBasic {
    
    using SafeERC20 for IERC20;

    

    modifier onlyContractOwner() { 
        require(msg.sender == contractOwner, "onlyOwner"); 
        _; 
    }

    modifier onlyUnlocked() { 
        require(!locked || msg.sender == contractOwner); 
        _; 
    }
    
    function init(address _ownerAddress, address _multisig, IERC20 _depositTokenAddress) public onlyContractOwner {
        
        BASIC_PRICE = 10e18;
        LAST_LEVEL = 15;

        levelPrice[1] = BASIC_PRICE;
        levelPrice[2] = 20e18;
        levelPrice[3] = 30e18;
        levelPrice[4] = 50e18;
        levelPrice[5] = 80e18;
        levelPrice[6] = 130e18;
        levelPrice[7] = 210e18;
        levelPrice[8] = 340e18;
        levelPrice[9] = 550e18;
        levelPrice[10] = 890e18;
        levelPrice[11] = 1440e18;
        levelPrice[12] = 2330e18;
		levelPrice[13] = 3770e18;
		levelPrice[14] = 6100e18;
		levelPrice[15] = 9870e18;
		
        id1 = _ownerAddress;
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[_ownerAddress] = user;
        idToAddress[1] = _ownerAddress;
        
        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[_ownerAddress].activexGoldLevels[i] = true;
        }
        
        userIds[1] = _ownerAddress;
        lastUserId = 2;
        multisig = _multisig;

        depositToken = _depositTokenAddress;

        locked = true;
    }

    function changeLock() external onlyContractOwner() {
        locked = !locked;
    }
    
    fallback() external {
        if(msg.data.length == 0) {
            return registration(msg.sender, id1);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external onlyUnlocked() {
        registration(msg.sender, referrerAddress);
    }

    
    
    function buyNewLevel(uint8 matrix, uint8 level) external onlyUnlocked() {
        _buyNewLevel(msg.sender, matrix, level);
    }

    

    function _buyNewLevel(address _userAddress, uint8 matrix, uint8 level) internal {
        require(isUserExists(_userAddress), "user is not exists. Register first.");
        require(matrix == 4 , "invalid matrix");

        depositToken.safeTransferFrom(msg.sender, address(this), levelPrice[level]);
        // require(msg.value == levelPrice[level], "invalid price");
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        
        {
            require(users[_userAddress].activexGoldLevels[level-1], "buy previous level first");
            require(!users[_userAddress].activexGoldLevels[level], "level already activated"); 

            if (users[_userAddress].xGoldMatrix[level-1].blocked) {
                users[_userAddress].xGoldMatrix[level-1].blocked = false;
            }

            address freeXGoldReferrer = findFreexGoldReferrer(_userAddress, level);
            
            users[_userAddress].activexGoldLevels[level] = true;
            updateXGOLDReferrer_Main(_userAddress, freeXGoldReferrer, level);
            
            emit Upgrade(_userAddress, freeXGoldReferrer, 4, level);
        }
    }
    function registration(address userAddress, address referrerAddress) private {
        depositToken.safeTransferFrom(msg.sender, address(this), BASIC_PRICE);
        // require(msg.value == BASIC_PRICE * 2, "invalid registration value");

        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
       // require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        users[userAddress].activexGoldLevels[1] = true; 
       
        
        
        userIds[lastUserId] = userAddress;
        lastUserId++;
        
        users[referrerAddress].partnersCount++;

        address freeXGoldReferrer = findFreexGoldReferrer(userAddress, 1);
        users[userAddress].xGoldMatrix[1].currentReferrer = freeXGoldReferrer;
        updateXGOLDReferrer_Main(userAddress, freeXGoldReferrer, 1);
  
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    function updateXGOLDReferrer_Main(address userAddress, address referrerAddress, uint8 level) private {
        require(users[referrerAddress].activexGoldLevels[level], "500. Referrer level is inactive");
        uint8 postition=99;
        uint n=0;
        uint j=0;
        bool _isFirstLevelHasSpace;
        bool _isSecondLevelHasSpace;
        bool _isThirdLevelHasSpace;
        bool _isForthLevelHasSpace;
		
        for (j = 0; j < 16; j++) {  //for loop example
            if(j<2)
            {
                if(users[referrerAddress].xGoldMatrix[level].firstLevelReferrals[j] == address(0)) 
                    _isFirstLevelHasSpace = true;
            }
            if(j<4)
            {
                if(users[referrerAddress].xGoldMatrix[level].secondLevelReferrals[j] == address(0)) 
                    _isSecondLevelHasSpace = true;
            }
            if(j<8)
            {
                if(users[referrerAddress].xGoldMatrix[level].thirdLevelReferrals[j] == address(0)) 
                    _isThirdLevelHasSpace = true;
                
            }
            if(j<16)
            {
                if(users[referrerAddress].xGoldMatrix[level].forthLevelReferrals[j] == address(0)) 
                    _isForthLevelHasSpace = true;
                  
            }
        }
        
        if (_isFirstLevelHasSpace) {
		    postition = updatexGoldReferrer_FirstLevel(userAddress, referrerAddress, level);
		    postition = updatexGoldReferrer_SecondLevel(userAddress, referrerAddress, level,postition);
		    postition = updatexGoldReferrer_ThirdLevel(userAddress, referrerAddress, level,postition);
		    postition = updatexGoldReferrer_ForthLevel(userAddress, referrerAddress, level, postition);		

		}
		
		else if (_isSecondLevelHasSpace) {
		    
		    for (j = 0; j < 4; j++) {  //for loop example
                if(users[referrerAddress].xGoldMatrix[level].secondLevelReferrals[j] == address(0))
                    {
                        break;
                    }
              }
            
            if(j == 0 || j==1) { n = 0; }
            else if(j == 2 || j==3) { n = 1; }
            
            postition = updatexGoldReferrer_FirstLevel(userAddress, users[referrerAddress].xGoldMatrix[level].firstLevelReferrals[n], level);
            postition = updatexGoldReferrer_SecondLevel(userAddress, users[referrerAddress].xGoldMatrix[level].firstLevelReferrals[n], level,postition);     
		    postition = updatexGoldReferrer_ThirdLevel(userAddress, users[referrerAddress].xGoldMatrix[level].firstLevelReferrals[n], level,postition);
		    postition = updatexGoldReferrer_ForthLevel(userAddress, users[referrerAddress].xGoldMatrix[level].firstLevelReferrals[n], level, postition);		

		}
		else if (_isThirdLevelHasSpace) {
		    
		    for (j = 0; j < 8; j++) {  //for loop example
                if(users[referrerAddress].xGoldMatrix[level].thirdLevelReferrals[j] == address(0))
                    {
                        break;
                    }
              }
            
            if(j == 0 || j==1) { n = 0; }
            else if(j == 2 || j==3) { n = 1; }
            else if(j == 4 || j==5) { n = 2; }
            else if(j == 6 || j==7) { n = 3; }
            
            postition = updatexGoldReferrer_FirstLevel(userAddress, users[referrerAddress].xGoldMatrix[level].secondLevelReferrals[n], level);
            postition = updatexGoldReferrer_SecondLevel(userAddress, users[referrerAddress].xGoldMatrix[level].secondLevelReferrals[n], level, postition);     
		    postition = updatexGoldReferrer_ThirdLevel(userAddress, users[referrerAddress].xGoldMatrix[level].secondLevelReferrals[n], level, postition);
		    postition = updatexGoldReferrer_ForthLevel(userAddress, users[referrerAddress].xGoldMatrix[level].secondLevelReferrals[n], level, postition);		
		    
		}
		else
		{
		    
		    for (j = 0; j < 16; j++) {  //for loop example
                if(users[referrerAddress].xGoldMatrix[level].forthLevelReferrals[j] == address(0))
                    {
                        break;
                    }
              }
            
            if(j == 0 || j==1) { n = 0; }
            else if(j == 2 || j==3) { n = 1; }
            else if(j == 4 || j==5) { n = 2; }
            else if(j == 6 || j==7) { n = 3; }
            else if(j == 8 || j==9) { n = 4; }
            else if(j == 10 || j==11) { n = 5; }
            else if(j == 12 || j==13) { n = 6; }
            else if(j == 14 || j==15) { n = 7; }
           
            
            postition = updatexGoldReferrer_FirstLevel(userAddress, users[referrerAddress].xGoldMatrix[level].thirdLevelReferrals[n], level);
            postition = updatexGoldReferrer_SecondLevel(userAddress, users[referrerAddress].xGoldMatrix[level].thirdLevelReferrals[n], level,postition);     
		    postition = updatexGoldReferrer_ThirdLevel(userAddress, users[referrerAddress].xGoldMatrix[level].thirdLevelReferrals[n], level,postition);
		    postition = updatexGoldReferrer_ForthLevel(userAddress, users[referrerAddress].xGoldMatrix[level].thirdLevelReferrals[n], level,postition);		
		}
		
		
	}		
	
    function updatexGoldReferrer_FirstLevel(address userAddress, address referrerAddress, uint8 level) private returns(uint8 firstlevelpos) {
            if (users[referrerAddress].xGoldMatrix[level].firstLevelReferrals[0]==address(0)) {
                firstlevelpos = 0;
            }
            else
            {
               firstlevelpos = 1;
            }
        
            users[referrerAddress].xGoldMatrix[level].firstLevelReferrals[firstlevelpos] =userAddress;
            emit NewUserPlace(userAddress, referrerAddress, 4, level, firstlevelpos+1);
            
            //set current level
            users[userAddress].xGoldMatrix[level].currentReferrer = referrerAddress;

            updatexGoldReferrerFirstLevel(userAddress, referrerAddress, level);
            
            return firstlevelpos + 1 ;
        
        
    }
    function updatexGoldReferrer_SecondLevel(address userAddress, address referrerAddress, uint8 level, uint8 firstlevelpos) private returns(uint8 secondlevelpos) {
            if(firstlevelpos == 99)
            {
                return 99;
            }
            
            address ref_2 = users[referrerAddress].xGoldMatrix[level].currentReferrer;            
            uint8 len_2 = 0;
            secondlevelpos=99;
            
            if(isUserExists(users[ref_2].xGoldMatrix[level].firstLevelReferrals[0])
            && isUserExists(users[ref_2].xGoldMatrix[level].firstLevelReferrals[1]))
            {
                len_2=2;
            }
            if(isUserExists(users[ref_2].xGoldMatrix[level].firstLevelReferrals[0])
            && !isUserExists(users[ref_2].xGoldMatrix[level].firstLevelReferrals[1]))
            {
                len_2=1;
            }
            
            if(ref_2 != address(0))
            {
                if ((len_2 == 2) && 
                    (users[ref_2].xGoldMatrix[level].firstLevelReferrals[0] == referrerAddress) &&
                    (users[ref_2].xGoldMatrix[level].firstLevelReferrals[1] == referrerAddress)) {
                        secondlevelpos = firstlevelpos + 4;  
                }  else if ((len_2 == 1 || len_2 == 2) &&
                        users[ref_2].xGoldMatrix[level].firstLevelReferrals[0] == referrerAddress) {
                        secondlevelpos = firstlevelpos + 2;  
                } else if (len_2 == 2 && users[ref_2].xGoldMatrix[level].firstLevelReferrals[1] == referrerAddress) {
                        secondlevelpos = firstlevelpos + 4;  
                }
                
                users[ref_2].xGoldMatrix[level].secondLevelReferrals[secondlevelpos - 3] =userAddress; 
                emit NewUserPlace(userAddress, ref_2, 4, level, secondlevelpos);
               
                updatexGoldReferrerSecondLevel(userAddress, ref_2, level);
            }
            
            return secondlevelpos;
        
        
    }
    function updatexGoldReferrer_ThirdLevel(address userAddress, address referrerAddress, uint8 level, uint8 secondlevelpos) private returns(uint8 thirdlevelpos) {
            if(secondlevelpos == 99)
            {
                return 99;
            }
            
            address ref_2 = users[referrerAddress].xGoldMatrix[level].currentReferrer;          
            address ref_3 = users[ref_2].xGoldMatrix[level].currentReferrer;            
            uint8 len_3 = 0;
            thirdlevelpos=99;
            
            if(isUserExists(users[ref_3].xGoldMatrix[level].firstLevelReferrals[0])
            && isUserExists(users[ref_3].xGoldMatrix[level].firstLevelReferrals[1]))
            {
                len_3=2;
            }
            if(isUserExists(users[ref_3].xGoldMatrix[level].firstLevelReferrals[0])
            && !isUserExists(users[ref_3].xGoldMatrix[level].firstLevelReferrals[1]))
            {
                len_3=1;
            }
            
            
            if(ref_3 != address(0))
            {
                if ((len_3 == 2) && 
                    (users[ref_3].xGoldMatrix[level].firstLevelReferrals[0] == ref_2) &&
                    (users[ref_3].xGoldMatrix[level].firstLevelReferrals[1] == ref_2)) {
    					thirdlevelpos = secondlevelpos + 8;
    	        } else if ((len_3 == 1 || len_3 == 2) &&
                        users[ref_3].xGoldMatrix[level].firstLevelReferrals[0] == ref_2) {
    					thirdlevelpos = secondlevelpos + 4;
    	        } else if (len_3 == 2 && users[ref_3].xGoldMatrix[level].firstLevelReferrals[1] == ref_2) {
    					thirdlevelpos = secondlevelpos + 8;
    	        }
    			
    			users[ref_3].xGoldMatrix[level].thirdLevelReferrals[thirdlevelpos - 7] =userAddress; 
                emit NewUserPlace(userAddress, ref_3, 4, level, thirdlevelpos);
    			
    			updatexGoldReferrerThirdLevel(userAddress, ref_3, level);
            }
			return thirdlevelpos;
        
        
    }
    function updatexGoldReferrer_ForthLevel(address userAddress, address referrerAddress, uint8 level, uint8 thirdlevelpos) private returns(uint8 forthlevelpos) {
            if(thirdlevelpos == 99)
            {
                return 99;
            }
           
            address ref_2 = users[referrerAddress].xGoldMatrix[level].currentReferrer;          
            address ref_3 = users[ref_2].xGoldMatrix[level].currentReferrer;  
			address ref_4 = users[ref_3].xGoldMatrix[level].currentReferrer;            
            uint8 len_4 = 0;
            
            forthlevelpos=99;
            if(isUserExists(users[ref_4].xGoldMatrix[level].firstLevelReferrals[0])
            && isUserExists(users[ref_4].xGoldMatrix[level].firstLevelReferrals[1]))
            {
                len_4=2;
            }
            if(isUserExists(users[ref_4].xGoldMatrix[level].firstLevelReferrals[0])
            && !isUserExists(users[ref_4].xGoldMatrix[level].firstLevelReferrals[1]))
            {
                len_4=1;
            }
            
            if(ref_4 != address(0))
            {
                if ((len_4 == 2) && 
                    (users[ref_4].xGoldMatrix[level].firstLevelReferrals[0] == ref_3) &&
                    (users[ref_4].xGoldMatrix[level].firstLevelReferrals[1] == ref_3)) {
    					forthlevelpos = thirdlevelpos + 16;
    					
                } else if ((len_4 == 1 || len_4 == 2) &&
                        users[ref_4].xGoldMatrix[level].firstLevelReferrals[0] == ref_3) {
    					forthlevelpos = thirdlevelpos + 8;
    					
                } else if (len_4 == 2 && users[ref_4].xGoldMatrix[level].firstLevelReferrals[1] == ref_3) {
    					forthlevelpos = thirdlevelpos + 16;
    					
                }
                
                users[ref_4].xGoldMatrix[level].forthLevelReferrals[forthlevelpos - 15] = userAddress; 
                emit NewUserPlace(userAddress, ref_4, 4, level, forthlevelpos);
               
                updatexGoldReferrerForthLevel(userAddress, ref_4, level);
            }
            return forthlevelpos;
        
    }

     function updatexGoldReferrerFirstLevel(address userAddress, address referrerAddress, uint8 level) private {
            if (referrerAddress == id1) {
                return sendETHDividends(referrerAddress, userAddress, 4, level, 100);
            }
    }
    
    function updatexGoldReferrerSecondLevel(address userAddress, address referrerAddress, uint8 level) private {
      
        
          if (referrerAddress == id1) {
                return sendETHDividends(referrerAddress, userAddress, 4, level, 100);
            }
        return sendETHDividends(referrerAddress, userAddress, 4, level,20);
        
    }
	
	function updatexGoldReferrerThirdLevel(address userAddress, address referrerAddress, uint8 level) private {
	      if (referrerAddress == id1) {
                return sendETHDividends(referrerAddress, userAddress, 4, level, 80);
            }
        return sendETHDividends(referrerAddress, userAddress, 4, level,30);
    }
     
	 
    function updatexGoldReferrerForthLevel(address userAddress, address referrerAddress, uint8 level) private {
       
		bool _flag;
		uint j=0;
		uint NodesCount=0;
	   
        for (j = 0; j < 16; j++) {  //for loop example
            if(users[referrerAddress].xGoldMatrix[level].forthLevelReferrals[j] == address(0))
            {
                _flag =true;
            }
			else
            {
                NodesCount = NodesCount + 1;
            }
        }
       
		if(NodesCount == 15)
        {
            return;
        }
		
        if (_flag) {
            return sendETHDividends(referrerAddress, userAddress, 4, level,50);
        }
    
        
        if (users[users[referrerAddress].xGoldMatrix[level].currentReferrer].xGoldMatrix[level].firstLevelReferrals[0] != address(0) 
        && users[users[referrerAddress].xGoldMatrix[level].currentReferrer].xGoldMatrix[level].firstLevelReferrals[1] != address(0)) {
            if (users[users[referrerAddress].xGoldMatrix[level].currentReferrer].xGoldMatrix[level].firstLevelReferrals[0] == referrerAddress ||
                users[users[referrerAddress].xGoldMatrix[level].currentReferrer].xGoldMatrix[level].firstLevelReferrals[1] == referrerAddress) {
                users[users[referrerAddress].xGoldMatrix[level].currentReferrer].xGoldMatrix[level].closedPart = referrerAddress;
            }
        }
        
        for (j = 0; j < 16; j++) {  //for loop example
            if(j<2)
            {
                users[referrerAddress].xGoldMatrix[level].firstLevelReferrals[j] = address(0);  
            }
            if(j<4)
            {
                users[referrerAddress].xGoldMatrix[level].secondLevelReferrals[j] = address(0);  
            }
            if(j<8)
            {
                users[referrerAddress].xGoldMatrix[level].thirdLevelReferrals[j] = address(0);  
            }
            if(j<16)
            {
                users[referrerAddress].xGoldMatrix[level].forthLevelReferrals[j] = address(0);  
            }
        }
              
        
        users[referrerAddress].xGoldMatrix[level].closedPart = address(0);

        if (!users[referrerAddress].activexGoldLevels[level+1] && level != LAST_LEVEL) {
            users[referrerAddress].xGoldMatrix[level].blocked = true;
        }

        users[referrerAddress].xGoldMatrix[level].reinvestCount++;
        
        if (referrerAddress != id1) {
            address freeReferrerAddress = findFreexGoldReferrer(referrerAddress, level);

            emit Reinvest(referrerAddress, freeReferrerAddress, userAddress, 4, level);
            updateXGOLDReferrer_Main(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(id1, address(0), userAddress, 4, level);
            sendETHDividends(id1, userAddress, 4, level,100);
        }
    }
   
    
     function findFreexGoldReferrer(address userAddress, uint8 level) public view returns(address) {
        while (true) {
            if (users[users[userAddress].referrer].activexGoldLevels[level]) {
                return users[userAddress].referrer;
            }
            
            userAddress = users[userAddress].referrer;
        }
    }
    
    function usersActivexGoldLevels(address userAddress, uint8 level) public view returns(bool) {
        return users[userAddress].activexGoldLevels[level];
    }
    
     function usersReinvest(address userAddress, uint8 level) public view returns(uint,address) {
        return  (users[userAddress].xGoldMatrix[level].reinvestCount,
                users[userAddress].xGoldMatrix[level].closedPart);
    }

    function usersxGoldMatrix(address userAddress, uint8 level) public view returns(address, address[2] memory, address[4] memory, address[8] memory, address[16] memory, bool) {
        return (users[userAddress].xGoldMatrix[level].currentReferrer,
                users[userAddress].xGoldMatrix[level].firstLevelReferrals,
                users[userAddress].xGoldMatrix[level].secondLevelReferrals,
                users[userAddress].xGoldMatrix[level].thirdLevelReferrals,
                users[userAddress].xGoldMatrix[level].forthLevelReferrals,
                users[userAddress].xGoldMatrix[level].blocked
                );
    }
    
    
	
	
    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function findEthReceiver(address userAddress, address _from, uint8 matrix, uint8 level) private returns(address, bool) {
        address receiver = userAddress;
        bool isExtraDividends;
        if (matrix == 4) {
            while (true) {
                if (users[receiver].xGoldMatrix[level].blocked) {
                    emit MissedEthReceive(receiver, _from, 4, level);
                    isExtraDividends = true;
                    receiver = users[receiver].xGoldMatrix[level].currentReferrer;
                } else {
                    return (receiver, isExtraDividends);
                }
            }
        } 
    }

    function sendETHDividends(address userAddress, address _from, uint8 matrix, uint8 level,uint256 percent) private {
        (address receiver, bool isExtraDividends) = findEthReceiver(userAddress, _from, matrix, level);

        depositToken.safeTransfer(receiver, (levelPrice[level]*percent)/100);
        // if (!address(uint160(receiver)).send(levelPrice[level])) {
        //     return address(uint160(receiver)).transfer(address(this).balance);
        // }
        
        if (isExtraDividends) {
            emit SentExtraEthDividends(_from, receiver, matrix, level);
        }
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function withdrawLostTokens(address tokenAddress) public onlyContractOwner {
        require(tokenAddress != address(depositToken), "cannot withdraw deposit token");
        if (tokenAddress == address(0)) {
            address(uint160(multisig)).transfer(address(this).balance);
        } else {
            IERC20(tokenAddress).transfer(multisig, IERC20(tokenAddress).balanceOf(address(this)));
        }
    }
}