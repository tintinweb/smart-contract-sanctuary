// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface HKT721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function cardIdMap(uint tokenId) external view returns (uint256 cardId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface Box {
    function price() external view returns (uint);

    function getPrice() external view returns (uint);
}

contract HKT_NFT_Deposit is Ownable {
    address public NFT;
    address public HKT;
    address public U;
    Box public box;
    uint public n = 5;
    uint public catFood = 1000;

    struct StakeInfo {
        bool staking;
        uint claimTime;
        uint endTime;
        uint rate;
        uint cardId;
        uint tokenId;
        uint toClaim;
    }

    struct CardInfo {
        uint rate;
        uint cycle;
        uint cost;
    }

    struct UserInfo {
        uint claimed;
        uint toClaim;
        uint[] cardList;
    }

    mapping(address => UserInfo)public userInfo;
    mapping(address => mapping(uint => StakeInfo))public stakeInfo;
    // mapping(uint => StakeInfo)public stakeInfo;
    mapping(uint => CardInfo)public cardInfo;

    event Deposite(address indexed sender_, uint indexed tokenId_);
    event UnDeposite(address indexed sender_, uint indexed tokenId_);
    event CLaim(address indexed sender_, uint indexed amount_);
    event ReNew(address indexed sender_, uint indexed tokenId_);
    constructor(){
        cardInfo[20001] = CardInfo({
        rate : 1200,
        cycle : 7 days,
        cost : 2
        });
        cardInfo[20002] = CardInfo({
        rate : 2600,
        cycle : 15 days,
        cost : 4
        });
        cardInfo[20003] = CardInfo({
        rate : 12000,
        cycle : 30 days,
        cost : 15
        });
    }


    function setAddress(address U_, address HKT_, address NFT_, address box_) external onlyOwner {
        U = U_;
        HKT = HKT_;
        NFT = NFT_;
        box = Box(box_);
    }

    function setN(uint n_) external onlyOwner {
        n = n_;
    }

    function deposite(uint tokenId_) external {
        if (block.timestamp > stakeInfo[msg.sender][tokenId_].endTime
        + cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cycle
            && stakeInfo[msg.sender][tokenId_].staking == true)
        {
            stakeInfo[msg.sender][tokenId_].staking = false;
        }
        require(!stakeInfo[msg.sender][tokenId_].staking, 'already staked');
        uint id = HKT721(NFT).cardIdMap(tokenId_);
        uint tempRate = box.price() * n * 1e18 / box.getPrice() * cardInfo[id].rate / 100 / 365 days;
        stakeInfo[msg.sender][tokenId_].rate = tempRate;
        stakeInfo[msg.sender][tokenId_].claimTime = block.timestamp;
        stakeInfo[msg.sender][tokenId_].endTime = block.timestamp + cardInfo[id].cycle;
        stakeInfo[msg.sender][tokenId_].staking = true;
        stakeInfo[msg.sender][tokenId_].cardId = id;
        stakeInfo[msg.sender][tokenId_].tokenId = tokenId_;
        userInfo[msg.sender].cardList.push(tokenId_);
        HKT721(NFT).safeTransferFrom(msg.sender, address(this), tokenId_);
        emit Deposite(msg.sender, tokenId_);
    }

    function coutingClaim(address addr_, uint tokenId_) public view returns (uint rew_){
        if (!stakeInfo[addr_][tokenId_].staking) {
            return 0;
        }
        if (stakeInfo[addr_][tokenId_].claimTime >= stakeInfo[addr_][tokenId_].endTime) {
            return 0;
        }
        rew_ = (block.timestamp - stakeInfo[addr_][tokenId_].claimTime) * stakeInfo[addr_][tokenId_].rate;
    }

    function claim(uint tokenId_) public {
        require(stakeInfo[msg.sender][tokenId_].staking, 'no staked');
        uint rew = coutingClaim(msg.sender, tokenId_);
        require(rew > 0, 'none to claim');
        if (block.timestamp > stakeInfo[msg.sender][tokenId_].endTime + cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cycle) {
            stakeInfo[msg.sender][tokenId_].staking = false;
        }
        IERC20(HKT).transfer(msg.sender, rew + userInfo[msg.sender].toClaim);
        userInfo[msg.sender].claimed += rew + userInfo[msg.sender].toClaim;
        stakeInfo[msg.sender][tokenId_].claimTime = block.timestamp;
        userInfo[msg.sender].toClaim = 0;

    }

    function coutingAll(address addr_) public view returns (uint){
        uint rew;
        for (uint i = 0; i < userInfo[addr_].cardList.length; i++) {
            rew += coutingClaim(addr_, userInfo[addr_].cardList[i]);
        }
        return rew + userInfo[addr_].toClaim;
    }

    function claimAll() public {
        require(userInfo[msg.sender].cardList.length > 0, 'no card');
        uint rew;
        for (uint i = 0; i < userInfo[msg.sender].cardList.length; i++) {
            rew += coutingClaim(msg.sender, userInfo[msg.sender].cardList[i]);
            stakeInfo[msg.sender][userInfo[msg.sender].cardList[i]].claimTime = block.timestamp;
        }
        IERC20(HKT).transfer(msg.sender, rew + userInfo[msg.sender].toClaim);
        userInfo[msg.sender].claimed += rew + userInfo[msg.sender].toClaim;
        uint rews = rew + userInfo[msg.sender].toClaim;
        userInfo[msg.sender].toClaim = 0;


        emit CLaim(msg.sender, rews);
    }

    function coutingCatFood(address addr_) public view returns (uint){
        uint k = HKT721(NFT).balanceOf(addr_);
        uint tokenId;
        uint cardId;
        uint out;
        if (k == 0) {
            return 0;
        }
        for (uint i = 0; i < k; i++) {
            tokenId = HKT721(NFT).tokenOfOwnerByIndex(addr_, i);
            cardId = HKT721(NFT).cardIdMap(tokenId);
            if (cardId == catFood) {
                out ++;
            }
        }
        return out;
    }


    function reNew(uint tokenId_) external {
        require(stakeInfo[msg.sender][tokenId_].staking, 'no staked');
        require(block.timestamp < stakeInfo[msg.sender][tokenId_].endTime + cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cycle, 'overdue');
        uint temp = coutingCatFood(msg.sender);
        uint need = cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cost;
        require(need <= temp, 'not enough');
        uint tokenId;
        uint cardId;
        uint k = HKT721(NFT).balanceOf(_msgSender());
        uint amount;
        for (uint i = 0; i < k; i++) {
            tokenId = HKT721(NFT).tokenOfOwnerByIndex(_msgSender(), i);
            cardId = HKT721(NFT).cardIdMap(tokenId);
            if (cardId == catFood) {
                HKT721(NFT).safeTransferFrom(_msgSender(), address(this), tokenId);
                amount += 1;
                if (amount == need) {
                    break;
                }
            }
        }
        if (block.timestamp > stakeInfo[msg.sender][tokenId_].endTime && stakeInfo[msg.sender][tokenId_].claimTime < stakeInfo[msg.sender][tokenId_].endTime) {
            uint tempRew = (stakeInfo[msg.sender][tokenId_].endTime - stakeInfo[msg.sender][tokenId_].claimTime) * stakeInfo[msg.sender][tokenId_].rate;
            userInfo[msg.sender].toClaim += tempRew;
            stakeInfo[msg.sender][tokenId_].claimTime = block.timestamp;
        }
        if (stakeInfo[msg.sender][tokenId_].claimTime >= stakeInfo[msg.sender][tokenId_].endTime) {
            stakeInfo[msg.sender][tokenId_].claimTime = block.timestamp;
        }

        stakeInfo[msg.sender][tokenId_].endTime += cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cycle;
        emit ReNew(msg.sender, tokenId_);

    }

    function unDeposite(uint tokenId_) external {
        require(stakeInfo[msg.sender][tokenId_].staking, 'no staked');
        if (block.timestamp < stakeInfo[msg.sender][tokenId_].endTime) {
            uint tokenId;
            uint cardId;
            uint temp = coutingCatFood(msg.sender);
            uint need = cardInfo[stakeInfo[msg.sender][tokenId_].cardId].cost;
            require(need <= temp, 'not enough');
            uint k = HKT721(NFT).balanceOf(_msgSender());
            for (uint i = 0; i < k; i++) {
                tokenId = HKT721(NFT).tokenOfOwnerByIndex(_msgSender(), i);
                cardId = HKT721(NFT).cardIdMap(tokenId);
                if (cardId == catFood) {
                    HKT721(NFT).safeTransferFrom(_msgSender(), address(this), tokenId);

                    if (i == need) {
                        break;
                    }
                }
            }
        }
        claim(tokenId_);
        stakeInfo[msg.sender][tokenId_].staking = false;
        HKT721(NFT).safeTransferFrom(address(this), msg.sender, tokenId_);
        for (uint i = 0; i < userInfo[msg.sender].cardList.length; i ++) {
            if (userInfo[msg.sender].cardList[i] == tokenId_) {
                userInfo[msg.sender].cardList[i] = userInfo[msg.sender].cardList[userInfo[msg.sender].cardList.length - 1];
                userInfo[msg.sender].cardList.pop();
            }
        }
        stakeInfo[msg.sender][tokenId_].cardId = 0;
        emit UnDeposite(msg.sender, tokenId_);
    }

    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }

    function safePullCard(address wallet_, uint tokenId_) public onlyOwner {
        HKT721(NFT).safeTransferFrom(address(this), wallet_, tokenId_);
    }


}