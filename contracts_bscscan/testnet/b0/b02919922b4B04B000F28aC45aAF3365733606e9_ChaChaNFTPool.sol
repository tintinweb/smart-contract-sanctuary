// SPDX-License-Identifier: GPL-2.0-or-later

import '../interface/IPool.sol';
import '../interface/IChaChaDao.sol';
import '../interface/IChaCha.sol';
import '../interface/IERC20.sol';
import '../interface/IOracle.sol';
import '../libraries/Owned.sol';
import '../libraries/TransferHelper.sol';


import '../interface/IChaChaNFT.sol';
import '../interface/IChaChaNode.sol';

import '../interface/IChaChaPrice.sol';

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract ChaChaNFTPool is IPool,Owned,IERC1155Receiver{

    using SafeMath for uint256;

    address private daoAddress;

    address private chachaToken;

    uint256 public totalAllocPoint = 0;

    address public nodeSaleAddress;

    address public boxSaleAddress;

    address public orcale;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC1155 nftToken; // Address of LP token contract.
        uint256 id;
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardTime; // Last block number that SUSHIs distribution occurs.
        uint256 accChaChaPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
        uint256 deadAmount;
    }

       // Info of each pool.
    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    bool private isStart;

    uint256 private totalReword;

    uint256 private startTime;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(address _daoAddress,address _chachaToken,uint256 _startTime){
        daoAddress = _daoAddress;
        chachaToken = _chachaToken;
        startTime = _startTime;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMinter() {
        require(IChaChaDao(daoAddress).isMinter(msg.sender), "Ownable: caller is not the MinterAddress");
        _;
    }


    function mint(address account, uint256 amount)
        external
        override
        onlyMinter
        returns (bool){
            if(IERC20(chachaToken).balanceOf(address(this)) < amount){
                IChaCha(chachaToken).mint();
            }
        require(IERC20(chachaToken).balanceOf(address(this)) >= amount, "NFT mint may be end");
        TransferHelper.safeTransfer(chachaToken, account, amount);
        return true;
    }

    function setNodeSaleAddress(
        address _nodeSaleAddress
    ) public onlyOwner {
        nodeSaleAddress = _nodeSaleAddress;
    }

    function setOrcale(
        address _orcale
    ) public onlyOwner {
        orcale = _orcale;
    }

    function setBoxSaleAddress(
        address _boxSaleAddress
    ) public onlyOwner {
        boxSaleAddress = _boxSaleAddress;
    }

    function add(
        uint256 _allocPoint,
        IERC1155 _nftToken,
        uint256 _id,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardTime =
            block.timestamp > startTime ? block.timestamp : startTime;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                nftToken: _nftToken,
                id:_id,
                allocPoint: _allocPoint,
                lastRewardTime: lastRewardTime,
                accChaChaPerShare: 0,
                deadAmount:0
            })
        );
    }

     // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.nftToken.balanceOf(address(this),pool.id);
        if (lpSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 chachaReward = 
            IChaChaNFT(address(chachaToken)).getMultiplierForNFT(pool.lastRewardTime, block.timestamp).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        if(chachaReward.div(lpSupply) >= getMaxReward(pool.lastRewardTime,block.timestamp)){
            pool.accChaChaPerShare = pool.accChaChaPerShare.add(
                getMaxReward(pool.lastRewardTime,block.timestamp).mul(1e12)
            );
            pool.deadAmount += (chachaReward.sub(getMaxReward(pool.lastRewardTime,block.timestamp).mul(lpSupply)));
        }else{
            pool.accChaChaPerShare = pool.accChaChaPerShare.add(
            chachaReward.mul(1e12).div(lpSupply)
            );
        }
        pool.lastRewardTime = block.timestamp;
    }

    function getMaxReward(uint256 from,uint256 to) public view returns(uint256){
        uint256 reward = IChaChaNode(address(chachaToken)).getMultiplierForNode(from,to);

        uint256 maxSupply = IChaChaPrice(nodeSaleAddress).maxSupply();

        uint256 price = IChaChaPrice(nodeSaleAddress).getPublicSalePrice();

        uint256 boxPrice = IChaChaPrice(boxSaleAddress).getPublicSalePrice();

        return reward.mul(60).mul(boxPrice).div(price).div(100).div(maxSupply);
    }

    // Update the given pool's SUSHI allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    
    // View function to see pending SUSHIs on frontend.
    function pendingChaCha(uint256 _pid, address _user)
        external
        view
        returns (uint256,uint256,uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accChaChaPerShare = pool.accChaChaPerShare;
        uint256 lpSupply = pool.nftToken.balanceOf(address(this),pool.id);
        uint256 totalReword = 0;
        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 chachaReward = 
            IChaChaNFT(address(chachaToken)).getMultiplierForNFT(pool.lastRewardTime, block.timestamp).mul(pool.allocPoint).div(
                totalAllocPoint
            );
            if(chachaReward.div(lpSupply) >= getMaxReward(pool.lastRewardTime,block.timestamp)){
                totalReword = getMaxReward(pool.lastRewardTime,block.timestamp).mul(lpSupply);
                accChaChaPerShare = pool.accChaChaPerShare.add(
                    getMaxReward(pool.lastRewardTime,block.timestamp).mul(1e12)
                );
            }else{
                accChaChaPerShare = pool.accChaChaPerShare.add(
                    chachaReward.mul(1e12).div(lpSupply)
                );
                totalReword = chachaReward;
            }
        }
        if(IERC1155(pool.nftToken).balanceOf(address(this), pool.id) > 0){
            uint256 total = totalReword.mul(IOracle(orcale).getChaChaPrice()).mul(365 * 24 * 60 * 60) .div(block.timestamp.sub(pool.lastRewardTime));
            uint256 apy = total.div(IERC1155(pool.nftToken).balanceOf(address(this), pool.id).mul(IChaChaPrice(boxSaleAddress).getPublicSalePrice()));
            return (user.amount.mul(accChaChaPerShare).div(1e12).sub(user.rewardDebt),user.amount,apy);
        }else{
            return (user.amount.mul(accChaChaPerShare).div(1e12).sub(user.rewardDebt),user.amount,0);
        }
        
    }

     // Deposit LP tokens to MasterChef for SUSHI allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accChaChaPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeChaChaTransfer(msg.sender, pending);
        }
        if(_amount >0 ){
            IERC1155(pool.nftToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            pool.id,
            _amount,
            "deposit"
            );
        }
        
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accChaChaPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    //Withdraw NFT tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accChaChaPerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeChaChaTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accChaChaPerShare).div(1e12);
        if(_amount >0 ){
            IERC1155(pool.nftToken).safeTransferFrom(address(this), address(msg.sender), pool.id, _amount, "withdraw");
        }
        if(pool.deadAmount != 0 ){
            safeChaChaBurn(pool.deadAmount);
            pool.deadAmount = 0;
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        IERC1155(pool.nftToken).safeTransferFrom(address(this), address(msg.sender), pool.id, user.amount, "emergencyWithdraw");
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe sushi transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeChaChaTransfer(address _to, uint256 _amount) internal {
        uint256 sushiBal = IERC20(chachaToken).balanceOf(address(this));
        if (_amount > sushiBal) {
            IChaCha(chachaToken).mint();
            TransferHelper.safeTransfer(chachaToken, _to, _amount);
        } else {
            TransferHelper.safeTransfer(chachaToken, _to, _amount);
        }
    }

    function safeChaChaBurn(uint256 _amount) internal{
        uint256 sushiBal = IERC20(chachaToken).balanceOf(address(this));
        if (_amount > sushiBal) {
            IChaCha(chachaToken).mint();
            TransferHelper.safeTransfer(chachaToken, address(0), _amount);
        } else {
            TransferHelper.safeTransfer(chachaToken, address(0), _amount);
        }
        
    }
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override view returns (bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override view returns (bytes4){
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function supportsInterface(bytes4 interfaceId) external override view returns (bool){
        return true;
    }

    
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IPool{
     function mint(address account, uint256 amount)
        external
        returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IChaChaDao {
    function getChaCha() external view returns (address);
    function lpRate() external view returns (uint256);
    function nftRate() external view returns (uint256);
    function nodeRate() external view returns (uint256);
    function protocolRate() external view returns (uint256);
    function lpPool() external view returns(address);
    function nftPool() external view returns(address);
    function nodePool() external view returns(address);
    function protocolAddress() external view returns(address);
    function boxAddress() external view returns(address);
    function isPool(address pool) external view returns(bool);
    function isMinter(address minter) external view returns(bool);
    function setMinter(address minter,bool isMinter) external  returns(bool);
    function setLpRate(uint256 lpRate) external returns (uint256);
    function setNodeRate(uint256 nodeRate) external returns (uint256);
    function setNftRate(uint256 nftRate) external returns (uint256);
    function setProtocolRate(uint256 protocolRate) external returns (uint256);
    function setChachaToken(address chachaToken) external returns (address);
    function setLpPool(address lpPool) external returns (address);
    function setNftPool(address nftPool) external returns (address);
    function setNodePool(address nodePool) external returns (address);
    function setProtocolAddress(address protocolAddress) external returns (address);
    function setBoxAddress(address boxAddress) external returns (address);

}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import './IChaChaLP.sol'; 
import './IChaChaNFT.sol'; 
import './IChaChaNode.sol';
import './IChaChaSwitch.sol';

interface IChaCha is IChaChaLP,IChaChaNFT,IChaChaNode,IChaChaSwitch{
     function mint()
        external
        returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;
interface IOracle{
    function getChaChaPrice() external view returns(uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

/**
 * @title Owned
 * @notice Basic contract to define an owner.
 * @author Julien Niset - <[email protected]>
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @notice Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;

import '../interface/IERC20Minimal.sol';

library TransferHelper {

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

   
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20Minimal.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IChaChaNFT{
     function getMultiplierForNFT(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IChaChaNode{
     function getMultiplierForNode(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IChaChaPrice{
    function getPublicSalePrice()
        external
        view
        returns (uint256);

    function maxSupply()
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IChaChaLP{
     function getMultiplierForLp(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IChaChaSwitch{
     function setStart()
        external
        returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6;
interface IERC20Minimal {
    
    function balanceOf(address account) external view returns (uint256);

  
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

 
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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