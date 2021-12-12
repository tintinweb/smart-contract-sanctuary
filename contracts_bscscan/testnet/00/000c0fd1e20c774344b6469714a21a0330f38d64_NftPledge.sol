/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function mint(address account, uint amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {

    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7; 
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        _registerInterface(_INTERFACE_ID_ERC165);
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }


    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

interface IERC1155 is IERC165 {
    
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function nftMap(uint256 _nftId) external view returns(bool,uint256,uint256,string memory,uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
interface IERC1155Receiver is IERC165 {

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

library Address {
    
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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

abstract contract Ownable is Context {
    address private _owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract NftPledge is ERC1155Holder,Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    
    IERC20 public award;
    IERC1155 public nftContract;
	uint256 public lastMiningTime;
    uint256 public dayTime;

    // Info of each user.
    struct UserInfo {
        mapping(uint256 => uint256) nfts;
        uint256[] nftkeys;
    }
    mapping(address => UserInfo) userMap;
    // Info of each pool.
    struct PoolInfo {
        uint256 nftAmount;
        uint256 lastTime; 
    }
    //mapping(uint256 => PoolInfo) poolMap;
    //uint256[] public poolkeys;

    mapping(address => mapping(uint256 => PoolInfo)) public users;

    

    event Pledge(address indexed user, uint256 nftId, uint256 amount);
    event RePledge(address indexed user, uint256 nftId, uint256 amount);
    event Withdraw(address indexed user, uint256 nftId, uint256 amount);
	event forciblyRePledge(address indexed user, uint256 nftId, uint256 amount);

    constructor(){
        dayTime = 60 * 60 * 24;
        lastMiningTime = block.timestamp.mul(dayTime);
        award = IERC20(0xA70051fBE83cDA5e9D55dD65e23e83306c135c7E);
        nftContract = IERC1155(0xeaA682Ef5D6A47fd06F35fAc2ea1fD740bF1fb4e);
    }


   
    function pendingGood(address _user,uint256 _nftId)public view returns (uint256,uint256){
    
      (,,,,uint256 power) = nftContract.nftMap(_nftId);
	   uint256 currentTime = block.timestamp > lastMiningTime ? lastMiningTime : block.timestamp;
       uint256 multiplier =  currentTime.sub(users[_user][_nftId].lastTime);
	   uint256 pending = multiplier.mul(power).div(dayTime).mul(users[_user][_nftId].nftAmount);
	   return (users[_user][_nftId].nftAmount,pending);
	   

    }

    function bathpendingGood(address[] memory _users, uint256[] memory _ids)public view returns (uint256[] memory ,uint256[] memory){
        uint256 length = _ids.length;
        uint256[] memory nftAmount = new uint256[](length);
        uint256[] memory pending = new uint256[](length);
        for(uint256 i = 0; i < length; i++){
            (nftAmount[i] , pending[i]) = pendingGood(_users[i],_ids[i]);
        }
        return (nftAmount, pending);
    }

    function pledge(uint256 _nftId, uint256 _nftAmount) public {
		require(block.timestamp < lastMiningTime,"Has stopped");
		require(_nftAmount > 0,"Illegal quantity");
		
		if(users[msg.sender][_nftId].nftAmount > 0){
			withdraw(_nftId);
		}
          
        nftContract.safeTransferFrom(
            address(msg.sender),
            address(this),
            _nftId,
            _nftAmount,
            ""
        );
        users[msg.sender][_nftId].nftAmount = users[msg.sender][_nftId].nftAmount.add(_nftAmount);
		users[msg.sender][_nftId].lastTime = block.timestamp;
        emit Pledge(msg.sender, _nftId, _nftAmount);
    }


    function rePledge(uint256 _nftId, uint256 _nftAmount) public {
        require(_nftAmount > 0,"Illegal quantity");
        require(users[msg.sender][_nftId].nftAmount >= _nftAmount, "You no have pledged NFT");        

        withdraw(_nftId);
       
        users[msg.sender][_nftId].nftAmount  = users[msg.sender][_nftId].nftAmount .sub(_nftAmount);

        nftContract.safeTransferFrom(            
            address(this),
            address(msg.sender),
            _nftId,
            _nftAmount,
            ""
        );

        emit RePledge(msg.sender, _nftId, _nftAmount);
    }
	
	function forceRePledge(uint256 _nftId, uint256 _nftAmount) public {
        require(_nftAmount > 0,"Illegal quantity");
        require(users[msg.sender][_nftId].nftAmount >= _nftAmount, "You no have pledged NFT");        

        
        users[msg.sender][_nftId].nftAmount  = users[msg.sender][_nftId].nftAmount .sub(_nftAmount);

        nftContract.safeTransferFrom(            
            address(this),
            address(msg.sender),
            _nftId,
            _nftAmount,
            ""
        );

        emit forciblyRePledge(msg.sender, _nftId, _nftAmount);
    }

    function withdraw(uint256 _nftId) public  {       
        
		(,uint256 pending) = pendingGood(msg.sender ,_nftId);
        if(pending > 0){
            safeGoodTransfer(msg.sender, pending);
        }
		emit Withdraw(msg.sender, _nftId, pending);
    }
	
	function batchWithdraw(uint256[] memory _nftIds) external{
		uint256 length = _nftIds.length;
		for(uint256 i = 0; i < length; i++){
			withdraw(_nftIds[i]);
		}
	}

    function userNft(uint256 _nftId, address _user) external view returns(uint256){            
        return users[_user][_nftId].nftAmount;
    }

    function safeGoodTransfer(address _to, uint256 _amount) internal {
        award.transfer(_to, _amount);
       
    }  
    
    receive() external payable {
      
    }      
    
	function setLastMiningTime( uint256 _lastMiningTime)public onlyOwner {
		lastMiningTime = _lastMiningTime;
	}
    function setDayTime(uint256 _dayTime)public onlyOwner {
        dayTime = _dayTime;
    }
	
	function withdrawalBNB() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function withdrawalTokens(IERC20 token) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
    }

    function withdrawalNfts(IERC1155 token, uint256 _nftId) public onlyOwner {
        uint256 amount = token.balanceOf(address(this), _nftId);
        token.safeTransferFrom(address(this), msg.sender, _nftId, amount, "");
    }


}