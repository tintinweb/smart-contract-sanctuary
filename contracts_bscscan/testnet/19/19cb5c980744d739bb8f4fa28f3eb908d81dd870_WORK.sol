/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
   
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function nftMap(uint256 tokenId) external view returns(uint256,string memory,uint256,uint256,uint256,uint256,uint256,uint256,uint256);
    function leverMultiple(uint256 _lever) external view returns(uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


abstract contract Ownable is Context {

	mapping(address => bool) public manager;

    event OwnershipTransferred(address indexed newOwner, bool isManager);


    constructor() {
        _setOwner(_msgSender(), true);
    }

    modifier onlyOwner() {
        require(manager[_msgSender()], "Ownable: caller is not the owner");
        _;
    }

    function setOwner(address newOwner,bool isManager) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner,isManager);
    }

    function _setOwner(address newOwner, bool isManager) private {
        manager[newOwner] = isManager;
        emit OwnershipTransferred(newOwner, isManager);
    }
}

contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract WORK is ERC721Holder,Ownable{
    using SafeMath for uint256; 

    struct WorkCondition{
        uint256 minLever;
        uint256[] roleIds;
        uint256 minComAtt;
        uint256 minForce;
        uint256 minAgile;
        uint256 minPhysique;
        uint256 minIntellect;
        uint256 minWillpower;
        uint256 minSpirit;
    }
    struct WorkReward{
        uint256 basicSalary;
        uint256 subKey;  //0 no  1 subForce 2 subAgile 3 subPhysique 4 subIntellect 5 subWillpower 6 subSpirit  7 subAll
        uint256 subValue;
		uint256 modulus;
        uint256 crisis;

    }

    struct WorkInfo{
        WorkCondition workCondition;
        WorkReward workReward;
    }
    struct UserInfo{
        bool status;
        uint256 workId;
        uint256 lastblockNum;        
    }

    event SetWorkForCondition(uint256 indexed _workId,
        uint256 _minLever,
        uint256 _minComAtt,
        uint256 _minForce,
        uint256 _minAgile,
        uint256 _minPhysique,
        uint256 _minIntellect,
        uint256 _minWillpower,
        uint256 _minSpirit,
        uint256[] _roleIds);
		
    event SetWorkForReward(uint256 indexed _workId,uint256 _basicSalary,uint256 _subKey,uint256 _subValue,uint256 _modulus,uint256 _crisis);
    event Withdrawal(address indexed user, uint256 indexed nftId, uint256 allSalary);
	event Onboarding(address indexed user, uint256 indexed workId, uint256 nftId);
	event Resign(address indexed user, uint256 indexed workId, uint256 nftId);
	
    IERC721 public nftContract = IERC721(0x5C3A029dB274eFE67cD7A107ad63739D97f0fd21);
    IERC20 public goldAddress = IERC20(0x8bDc49F52B5028f0d81e6A08586e9Ba2842a6582);
	IERC20  public bnxAddress = IERC20(0xC1bb5A80b508c595e168B2d5936757e02593D1c2);

    mapping (uint256 => WorkInfo) public workMap;

    mapping (address => mapping(uint256 => UserInfo)) public userMap;
	mapping (address => mapping(uint256 => uint256[])) private userWork;
	
	uint256[] private boxNftKeys = [1,2,3,4,5,6,7,8,9,10];

	constructor() {
		// Odd job
		_setWorkForCondition(1,2,0,0,0,0,0,0,0,boxNftKeys);
		_setWorkForReward(1,1*10**16,0,0,0,10000);
		
		// Lumberjack
		_setWorkForCondition(2,3,0,86,0,61,0,0,0,boxNftKeys);
		_setWorkForReward(2,1*10**16,1,85,5*10**15,10000);
		
		//Winemaker
		_setWorkForCondition(3,3,0,61,86,0,0,0,0,boxNftKeys);
		_setWorkForReward(3,1*10**16,2,85,5*10**15,10000);
		
		//hunter
		_setWorkForCondition(4,3,0,86,61,0,0,0,0,boxNftKeys);
		_setWorkForReward(4,1*10**16,1,85,5*10**15,10000);
		
		//Scroll Transcript
		_setWorkForCondition(5,3,0,0,0,0,86,0,61,boxNftKeys);
		_setWorkForReward(5,1*10**16,4,85,5*10**15,10000);
		
		//Legendary Realm
		_setWorkForCondition(6,2,401,0,0,0,0,0,0,boxNftKeys);
		_setWorkForReward(6,65*10**15,0,0,25*10**14,10000);
				
		
	}


    function onboarding(uint256 _workId, uint256 _nftId) public {
        isWork(_workId,_nftId);
        nftContract.transferFrom(msg.sender, address(this), _nftId);        

		(bool isIn, ) = firstIndexOf(userWork[msg.sender][_workId], _nftId);
        if(!isIn){
        	userWork[msg.sender][_workId].push(_nftId);
        }
		userMap[msg.sender][_nftId].status =  true;
        userMap[msg.sender][_nftId].workId =  _workId;
		userMap[msg.sender][_nftId].lastblockNum = block.number;
		emit Onboarding(msg.sender,_workId,_nftId);

    }

    function isWork(uint256 _workId, uint256 _nftId)internal view{
        WorkCondition memory workCondition = workMap[_workId].workCondition;        
        (uint256 lever,, uint256 roleId, uint256 force, uint256 agile, uint256 physique, uint256 intellect, uint256 willpower, uint256 spirit) = nftContract.nftMap(_nftId);
        require(
                lever >= workCondition.minLever &&
                force >= workCondition.minForce &&
                agile >= workCondition.minAgile &&
                physique >= workCondition.minPhysique &&
                intellect >= workCondition.minIntellect &&
                willpower >= workCondition.minWillpower &&
                spirit >= workCondition.minSpirit ,"Ability mismatch"
        );
        uint256 _minComAtt = force.add(agile).add(physique);
        _minComAtt = _minComAtt.add(intellect).add(willpower).add(spirit);

		(bool isIn, ) = firstIndexOf(workMap[_workId].workCondition.roleIds, roleId);
        require(isIn,"role does not match");
        require( _minComAtt >= workCondition.minComAtt, "too low");
    }



    function resign(uint256 _nftId) public {
		//require(userMap[msg.sender][_nftId].status,"NO");
        withdrawal(_nftId);
		uint256 lastWorkId = userMap[msg.sender][_nftId].workId;
		(bool isIn, uint256 index) = firstIndexOf(userWork[msg.sender][lastWorkId],_nftId);
        if(isIn){
          removeByIndex(msg.sender,lastWorkId, index);
        }
		
        nftContract.transferFrom(address(this),msg.sender, _nftId);
        userMap[msg.sender][_nftId].status =  false;
        userMap[msg.sender][_nftId].workId =  0;
        userMap[msg.sender][_nftId].lastblockNum = block.number;
		emit Resign(msg.sender,lastWorkId,_nftId);
    }
	
	function firstIndexOf(uint256[] memory array, uint256 key) internal pure returns (bool, uint256) {

    	if(array.length == 0){
    		return (false, 0);
    	}

    	for(uint256 i = 0; i < array.length; i++){
    		if(array[i] == key){
    			return (true, i);
    		}
    	}
    	return (false, 0);
    }

	function removeByIndex(address _user, uint256 _workId, uint index) internal{
    	require(index < userWork[_user][_workId].length, "ArrayForUint256: index out of bounds");

        while (index < userWork[_user][_workId].length - 1) {
            userWork[_user][_workId][index] = userWork[_user][_workId][index + 1];
            index++;
        }
        //userWork[_user][_workId].length--;
    }
	
    function getSalary(address _user, uint256 _nftId) public view returns(uint256){
        require(userMap[_user][_nftId].status,"NO");        
        uint256 workTime = block.number.sub(userMap[_user][_nftId].lastblockNum);
        uint256 currentWorkId = userMap[_user][_nftId].workId;
        WorkReward memory workReward = workMap[currentWorkId].workReward;

        (uint256 subtracted, uint256 multiple) = _getSalary(workReward.subKey,workReward.subValue,_nftId);
       
        uint256 allSalary = workReward.basicSalary;
		if(workReward.modulus > 0 ){
			allSalary = allSalary.add(subtracted.mul(workReward.modulus).mul(multiple));
		}
        allSalary = allSalary.mul(workTime).mul(workReward.crisis).div(10000);
        return allSalary;
    }
    function _getSalary(uint256 _subKey, uint256 _subValue, uint256 _nftId)public view returns(uint256,uint256){
        (uint256 lever,,, uint256 force, uint256 agile, uint256 physique, uint256 intellect, uint256 willpower, uint256 spirit) = nftContract.nftMap(_nftId);
        uint256 subtracted ;
        uint256 multiple = nftContract.leverMultiple(lever);
       
		//0 no  1 subForce 2 subAgile 3 subPhysique 4 subIntellect 5 subWillpower 6 subSpirit  7 subAll
		
		if(_subKey == 1){           
            subtracted = force.sub(_subValue);            
        }
		if(_subKey == 2){           
            subtracted = agile.sub(_subValue);            
        }
		if(_subKey == 3){           
            subtracted = physique.sub(_subValue);            
        }
		if(_subKey == 4){           
            subtracted = intellect.sub(_subValue);            
        }
		if(_subKey == 5){           
            subtracted = willpower.sub(_subValue);            
        }
		if(_subKey == 6){           
            subtracted = spirit.sub(_subValue);            
        }
		
		if(_subKey == 7){
            uint256 allAtt = force.add(agile).add(physique).add(intellect);
            allAtt =  allAtt.add(willpower).add(spirit);
            subtracted = allAtt.sub(_subValue);
            
        }
		
        return (subtracted,multiple);
    }

    function withdrawal(uint256 _nftId) public {
		require(userMap[msg.sender][_nftId].status,"NO");
        uint256 allSalary = getSalary(msg.sender, _nftId);           
        goldAddress.transfer(msg.sender,allSalary); 
        userMap[msg.sender][_nftId].lastblockNum = block.number;
        emit Withdrawal(msg.sender, _nftId, allSalary);


    }
	
	function setWorkForCondition(uint256 _workId,
        uint256 _minLever,
        uint256 _minComAtt,
        uint256 _minForce,
        uint256 _minAgile,
        uint256 _minPhysique,
        uint256 _minIntellect,
        uint256 _minWillpower,
        uint256 _minSpirit,
        uint256[] memory _roleIds)external onlyOwner{
			
        _setWorkForCondition(_workId,_minLever, _minComAtt, _minForce, _minAgile, _minPhysique, _minIntellect, _minWillpower, _minSpirit, _roleIds);
    }


    function _setWorkForCondition(uint256 _workId,
        uint256 _minLever,
        uint256 _minComAtt,
        uint256 _minForce,
        uint256 _minAgile,
        uint256 _minPhysique,
        uint256 _minIntellect,
        uint256 _minWillpower,
        uint256 _minSpirit,
        uint256[] memory _roleIds)internal{
        
        workMap[_workId].workCondition.minLever = _minLever;
        workMap[_workId].workCondition.minComAtt = _minComAtt;
        workMap[_workId].workCondition.minForce = _minForce;
        workMap[_workId].workCondition.minAgile = _minAgile;
        workMap[_workId].workCondition.minPhysique = _minPhysique;
        workMap[_workId].workCondition.minIntellect = _minIntellect;
        workMap[_workId].workCondition.minWillpower = _minWillpower;
        workMap[_workId].workCondition.minSpirit = _minSpirit;
        workMap[_workId].workCondition.roleIds = _roleIds;
        
        emit SetWorkForCondition(_workId, _minLever, _minComAtt, _minForce, _minAgile, _minPhysique, _minIntellect, _minWillpower, _minSpirit, _roleIds);

    }

	function setWorkForReward(uint256 _workId,
		uint256 _basicSalary,
        uint256 _subKey,
        uint256 _subValue,
        uint256 _modulus,
        uint256 _crisis)external onlyOwner{
			
		_setWorkForReward(_workId, _basicSalary, _subKey, _subValue,_modulus, _crisis);
	}
		
    function _setWorkForReward(uint256 _workId,
		uint256 _basicSalary,
        uint256 _subKey,
        uint256 _subValue,
		uint256 _modulus,
        uint256 _crisis)internal{
		
		workMap[_workId].workReward.basicSalary = _basicSalary;
		workMap[_workId].workReward.subKey = _subKey;
		workMap[_workId].workReward.subValue = _subValue;
		workMap[_workId].workReward.modulus = _modulus;
		workMap[_workId].workReward.crisis = _crisis;
		
		emit SetWorkForReward(_workId,_basicSalary,_subKey,_subValue,_modulus,_crisis);
	}
	
	
	function userNft(address _user, uint256 _workId)public view returns(uint256[] memory){
		return userWork[_user][_workId];
		
	}
}