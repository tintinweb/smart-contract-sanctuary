// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './utils/Ownable.sol';
import './utils/HelperOwnable.sol';
import './utils/WeigthOwnable.sol';
import './interface/IERC721Metadata.sol';
import './interface/IERC721Receiver.sol';
import './interface/IManager.sol';
import './library/Address.sol';


contract Manager is Ownable, HelperOwnable, WeigthOwnable, IERC721, IERC721Metadata, IManager {
    using Address for address;

    struct Army {
        string name;
        string metadata;
        uint256 id;
        uint64 mint;
        uint256 claim;
        uint64 weigth;
    }

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => Army) private _nodes;
    mapping(address => uint256[]) private _bags;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => bool) private _blacklist;

    uint256 public override price;
    uint32 public precision = 10**9;
    uint256 public reward;
    uint128 public claimTime = 86400;
    string public defaultUri;

    uint256 private nodeCounter = 1;

    constructor (uint256 _price, uint256 _reward, string memory _defaultUri){
        price = _price;
        reward = _reward;
        defaultUri = _defaultUri;
    }

    function name() external override pure returns (string memory) {
        return "Sparta Platoon";
    }

    function symbol() external override pure returns (string memory) {
        return "PLATOON";
    }

    modifier onlyIfExists(uint256 _id) {
        require(_exists(_id), "ERC721: operator query for nonexistent token");
        _;
    }

    function totalNodesCreated() view external returns (uint) {
        return nodeCounter - 1;
    }

    function isBlacklisted(address wallet) view external returns (bool) {
        return _blacklist[wallet];
    }

    function importArmy(address account, string memory _name, uint64 mint, uint64 _claim) onlyHelper override external {
        uint256 nodeId = nodeCounter;
        _createArmy(nodeId, _name, mint, _claim, "", account, 1);
        nodeCounter += 1;
    }

    function createNode(address account, string memory nodeName) onlyHelper override external {
        uint256 nodeId = nodeCounter;
        _createArmy(nodeId, nodeName, uint64(block.timestamp), uint64(block.timestamp), "", account, 1);
        nodeCounter += 1;
    }

    function claim(address account, uint256 _id) external onlyIfExists(_id) onlyHelper override returns (uint) {
        require(ownerOf(_id) == account, "MANAGER: You are not the owner");
        Army storage _node = _nodes[_id];

        uint percentTimeElapsed = (block.timestamp - _node.claim) * precision / claimTime;
        uint rewardNode = reward * percentTimeElapsed / precision;

        if(rewardNode > 0) {
            _node.claim = uint256(block.timestamp);
            return rewardNode;
        } else {
            return 0;
        }
    }
    
    function claimInternal(uint256 _id) internal returns (uint256) {
        Army storage _node = _nodes[_id];

        uint256 percentTimeElapsed = (block.timestamp - _node.claim) * precision / claimTime;
        uint256 rewardNode = reward * percentTimeElapsed / precision;

        _node.claim = uint256(block.timestamp);
        return rewardNode;
    }

    function claimAll(address account) external onlyHelper override returns (uint256) {
        uint256 rewards = 0;
        for (uint256 i = 0; i < _bags[account].length; i++) {
            rewards += claimInternal(_bags[account][i]);
        }
        return rewards;
    }

    function getAllPendingRewards(address account) public view returns (uint) {
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < _bags[account].length; i++) {
            uint256 nodeId = _bags[account][i];
            Army memory node = _nodes[nodeId];
            uint percentTimeElapsed = (block.timestamp - node.claim) * precision / claimTime;
            uint rewardNode = reward * percentTimeElapsed / precision;
            totalRewards += rewardNode;
        }
        return totalRewards;
    }

    function getNodesAccount(address account) public view returns (uint256 [] memory){
        return _bags[account];
    }
    function getNodesCountAccount(address account) public view returns (uint256){
        return _bags[account].length;
    }

    function updateArmy(uint256 id, uint64 weigth, string calldata metadata) onlyWeigth external {
        Army storage army = _nodes[id];
        army.weigth = weigth;
        army.metadata = metadata;
    }

    function getArmy(uint256 _id) public view onlyIfExists(_id) returns (Army memory) {
        return _nodes[_id];
    }

    function getRewardOf(uint256 _id) public view onlyIfExists(_id) returns (uint) {
        Army memory node = _nodes[_id];
        uint percentTimeElapsed = (block.timestamp - node.claim) * precision / claimTime;
        return reward * percentTimeElapsed / precision;
    }

    function getNameOf(uint256 _id) public view override onlyIfExists(_id) returns (string memory) {
        return _nodes[_id].name;
    }

    function getMintOf(uint256 _id) public view override onlyIfExists(_id) returns (uint64) {
        return _nodes[_id].mint;
    }

    function getClaimOf(uint256 _id) public view override onlyIfExists(_id) returns (uint256) {
        return _nodes[_id].claim;
    }

    function getArmiesOf(address _account) public view returns (uint256[] memory) {
        return _bags[_account];
    }

    function getWeightOf(uint256 _id) public view onlyIfExists(_id) returns (uint64) {
        return _nodes[_id].weigth;
    }

    function getPrice() external view override returns (uint256) {
        return price;
    }

    function _changeArmyPrice(uint256 newPrice) onlyOwner external {
        price = newPrice;
    }

    function _changeRewardPerArmy(uint64 newReward) onlyOwner external {
        reward = newReward;
    }

    function _changeClaimTime(uint64 newTime) onlyOwner external {
        claimTime = newTime;
    }

    function _changeRewards(uint64 newReward, uint64 newTime, uint32 newPrecision) onlyOwner external {
        reward = newReward;
        claimTime = newTime;
        precision = newPrecision;
    }

    function _setTokenUriFor(uint256 nodeId, string memory uri) onlyOwner external {
        _nodes[nodeId].metadata = uri;
    }

    function _setDefaultTokenUri(string memory uri) onlyOwner external {
        defaultUri = uri;
    }

    function _setBlacklist(address malicious, bool value) onlyOwner external {
        _blacklist[malicious] = value;
    }

    function _addArmy(uint256 _id, string calldata _name, uint64 _mint, uint64 _claim, string calldata _metadata, address _to, uint64 _weigth) onlyOwner external {
        _createArmy(_id, _name, _mint, _claim, _metadata, _to, _weigth);
    }

    function _deleteArmy(uint256 _id) onlyOwner external {
        address owner = ownerOf(_id);
        _balances[owner] -= 1;
        delete _owners[_id];
        delete _nodes[_id];
        _remove(_id, owner); 
    }

    function _deleteMultipleArmy(uint256[] calldata _ids) onlyOwner external {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            address owner = ownerOf(_id);
            _balances[owner] -= 1;
            delete _owners[_id];
            delete _nodes[_id];
            _remove(_id, owner);
        }
    }


    function transferWeigthOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit WeigthOwnershipTransferred(_weigthContract, newOwner);
        _weigthContract = newOwner;
    }

    function _createArmy(uint256 _id, string memory _name, uint64 _mint, uint64 _claim, string memory _metadata, address _to, uint64 _weigth) internal {
        require(!_exists(_id), "MANAGER: Army already exist");
        _nodes[_id] = Army({
            name: _name,
            mint: _mint,
            claim: _claim,
            id: _id,
            metadata: _metadata,
            weigth: _weigth
        });
        _owners[_id] = _to;
        _balances[_to] += 1;
        _bags[_to].push(_id);

        emit Transfer(address(0), _to, _id);
    }

    function _remove(uint256 _id, address _account) internal {
        uint256[] storage _ownerNodes = _bags[_account];
        uint length = _ownerNodes.length;

        uint _index = length;
        
        for (uint256 i = 0; i < length; i++) {
            if(_ownerNodes[i] == _id) {
                _index = i;
            }
        }
        if (_index >= _ownerNodes.length) return;
        
        _ownerNodes[_index] = _ownerNodes[length - 1];
        _ownerNodes.pop();
    }

    function tokenURI(uint256 tokenId) external override view returns (string memory) {
        Army memory _node = _nodes[uint64(tokenId)];
        if(bytes(_node.metadata).length == 0) {
            // return defaultUri;
            return string(abi.encodePacked(defaultUri, uint2str(tokenId)));
        } else {
            return _node.metadata;
        }
    }

    function balanceOf(address owner) public override view returns (uint256 balance){
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public override view onlyIfExists(uint64(tokenId)) returns (address owner) {
        address theOwner = _owners[uint64(tokenId)];
        return theOwner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId ) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function renameArmy(uint64 id, string memory newName) external {
        require(ownerOf(id) == msg.sender, "MANAGER: You are not the owner");
        Army storage army = _nodes[id];
        army.name = newName;
    }

    function transferFrom(address from, address to,uint256 tokenId) external override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) external override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public override view onlyIfExists(uint64(tokenId)) returns (address operator){
        return _tokenApprovals[uint64(tokenId)];
    }

    function setApprovalForAll(address operator, bool _approved) external override {
        _setApprovalForAll(_msgSender(), operator, _approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId) external override pure returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        uint64 _id = uint64(tokenId);
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!_blacklist[to], "MANAGER: You can't transfer to blacklisted user");
        require(!_blacklist[from], "MANAGER: You can't transfer as blacklisted user");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[_id] = to;

        _bags[to].push(_id);
        _remove(_id, from);

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[uint64(tokenId)] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view onlyIfExists(uint64(tokenId)) returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[uint64(tokenId)] != address(0);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[uint64(tokenId)];
        delete _nodes[uint64(tokenId)];
        _remove(uint64(tokenId), owner);
        emit Transfer(owner, address(0), tokenId);
    }

    function transferHelperOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit HelperOwnershipTransferred(_helperContract, newOwner);
        _helperContract = newOwner;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Context.sol';

contract WeigthOwnable is Context {
    address internal _weigthContract;

    event WeigthOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _weigthContract = msgSender;
        emit WeigthOwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function weigthContract() public view returns (address) {
        return _weigthContract;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyWeigth() {
        require(_weigthContract == _msgSender(), "Ownable: caller is not the weight");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Context.sol';

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Context.sol';

contract HelperOwnable is Context {
    address internal _helperContract;

    event HelperOwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Returns the address of the current owner.
     */
    function helperContract() public view returns (address) {
        return _helperContract;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyHelper() {
        require(_helperContract == _msgSender(), "Ownable: caller is not the helper");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IERC721.sol';

interface IManager is IERC721 {
    function price() external returns(uint256);
    function createNode(address account, string memory nodeName) external;
    function claim(address account, uint256 _id) external returns (uint);
    function claimAll(address account) external returns (uint);
    function importArmy(address account, string calldata _name, uint64 mint, uint64 _claim) external; 
    function getNameOf(uint256 _id) external view returns (string memory);
    function getMintOf(uint256 _id) external view returns (uint64);
    function getClaimOf(uint256 _id) external view returns (uint256);
    function getPrice() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IERC721.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}