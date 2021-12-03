/**
 *Submitted for verification at BscScan.com on 2021-12-03
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

    function nftInfo(uint256 _nftId) external view returns(string memory,uint256,uint256);
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
    

    // Info of each user.
    struct UserInfo {
        uint256 totalPower;
        uint256 rewardDebt; 
        mapping(uint256 => uint256) nfts;
        uint256[] nftkeys;
    }
    // Info of each pool.
    struct PoolInfo {
        IERC1155 nftContract; 
        uint256 totalPower; 
        uint256 lastRewardBlock; // Last block number that Goods distribution occurs.
        uint256 accGoodPerShare; // Accumulated Goods per share, times 1e12. See below.
    }
    // The Good TOKEN!
    IERC20 public dmc;
    uint256 public dmcPerBlock;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public startBlock;
    bool public paused = false;

    event Pledge(address indexed user, uint256 indexed pid, uint256 amount);
    event RePledge(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetPause( bool paused);

    constructor(){
        dmc = IERC20(0x5Ea003c9D99d8AacEe938F571C3e02f7A7ad4f4f);
        dmcPerBlock = 6944444444444444;
        startBlock = 0;      
        add(0xCb79Af8F2660BB0056D81CD771f17FF1AAd3d3Ad);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(address _nftContract) public onlyOwner {
        
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;     

        poolInfo.push(
            PoolInfo({
                nftContract: IERC1155(_nftContract),
                totalPower : 0,
                lastRewardBlock: lastRewardBlock,
                accGoodPerShare: 0
            })
        );

    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
            return _to.sub(_from);
    }

    // View function to see pending Goods on frontend.
    function pendingGood(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGoodPerShare = pool.accGoodPerShare;

        if (block.number > pool.lastRewardBlock && pool.totalPower != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 dmcReward =
                multiplier.mul(dmcPerBlock);
            accGoodPerShare = accGoodPerShare.add(
                dmcReward.mul(1e12).div(pool.totalPower)
            );
        }
        //return user.amount.mul(accGoodPerShare).div(1e12).sub(user.rewardDebt);
        uint256 userreward= user.totalPower.mul(accGoodPerShare).div(1e12).sub(user.rewardDebt);
        return userreward;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }


    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
 
        if (pool.totalPower == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 dmcReward =
            multiplier.mul(dmcPerBlock);

        pool.accGoodPerShare = pool.accGoodPerShare.add(
            dmcReward.mul(1e12).div(pool.totalPower)
        );
        pool.lastRewardBlock = block.number;
    }



    function pledge(uint256 _pid, uint256 _nftId, uint256 _nftAmount) public  notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 pending = 0;
        if (user.totalPower > 0) {
            pending = user.totalPower.mul(pool.accGoodPerShare).div(1e12).sub(user.rewardDebt);
           
        }
       
        IERC1155(pool.nftContract).safeTransferFrom(
            address(msg.sender),
            address(this),
            _nftId,
            _nftAmount,
            ""
        );

        bool isExist = isExistNft(_pid,msg.sender,_nftId);
        if(_nftAmount > 0 && !isExist){
            user.nftkeys.push(_nftId);
        }

        user.nfts[_nftId] = user.nfts[_nftId].add(_nftAmount);
        ( , , uint256 nftPower) = IERC1155(pool.nftContract).nftInfo(_nftId);
        uint256 nftsPower = nftPower.mul(_nftAmount);
        pool.totalPower = pool.totalPower.add(nftsPower);
        user.totalPower = user.totalPower.add(nftsPower);
        user.rewardDebt = user.totalPower.mul(pool.accGoodPerShare).div(1e12);
        emit Pledge(msg.sender, _pid, nftsPower);
    }

    function isExistNft(uint256 _pid, address _user, uint256 _nftId) internal view returns(bool){
        UserInfo storage user = userInfo[_pid][_user];
        uint256 length = user.nftkeys.length;

        for(uint256 i = 0; i < length ; i++){
            if(_nftId == user.nftkeys[i]){
                return true;
            }
        }
        return false;
    }
    function rePledge(uint256 _pid, uint256 _nftId, uint256 _nftAmount) public notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.nfts[_nftId] >= _nftAmount, "You no have pledged NFT");
        

        updatePool(_pid);
        uint256 pending =
            user.totalPower.mul(pool.accGoodPerShare).div(1e12).sub(
                user.rewardDebt
            );
        
        safeGoodTransfer(msg.sender, pending);        

        ( , , uint256 nftPower) = IERC1155(pool.nftContract).nftInfo(_nftId);
        uint256 nftsPower = nftPower.mul(_nftAmount); 
        pool.totalPower = pool.totalPower.sub(nftsPower);         
        user.totalPower = user.totalPower.sub(nftsPower);     
        user.rewardDebt = user.totalPower.mul(pool.accGoodPerShare).div(1e12);
        user.nfts[_nftId] = user.nfts[_nftId].sub(_nftAmount);

        IERC1155(pool.nftContract).safeTransferFrom(            
            address(this),
            address(msg.sender),
            _nftId,
            _nftAmount,
            ""
        );

        emit RePledge(msg.sender, _pid, nftsPower);
    }

    function withdraw(uint256 _pid) public  notPause {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending =
            user.totalPower.mul(pool.accGoodPerShare).div(1e12).sub(
                user.rewardDebt
            );

        safeGoodTransfer(msg.sender, pending);
        
        user.rewardDebt = user.totalPower.mul(pool.accGoodPerShare).div(1e12);
       
        emit Withdraw(msg.sender, _pid, pending);
    }

    function userNft(uint256 _pid, address _user) external view returns(uint256[] memory, uint256[] memory){
            UserInfo storage user = userInfo[_pid][_user];
            uint256 length = user.nftkeys.length;

            uint256[] memory nftId = new uint256[](length);
            uint256[] memory nftAmount = new uint256[](length);

            for(uint256 i = 0; i < length ; i++){
                nftId[i] = user.nftkeys[i];
                nftAmount[i] = user.nfts[user.nftkeys[i]];
            }
            return (nftId,nftAmount);
    }

    function safeGoodTransfer(address _to, uint256 _amount) internal {
            dmc.mint(_to, _amount);
       
    }

    function setdmcPerBlock(uint256 _dmcPerBlock) public onlyOwner  {
        massUpdatePools();
        dmcPerBlock = _dmcPerBlock;
    }

    function setPause() public onlyOwner {
        paused = !paused;
        emit SetPause(paused);

    }
    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }   
    
    receive() external payable {
      
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