// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../other/divestor.sol";
import "../interface/Ikaka721.sol";
import "../interface/IKMT.sol";
import "../interface/Ipancake_router.sol";
import "../other/random_generator.sol";


contract AlchemyS2 is ERC721Holder, Ownable, Divestor, RandomGenerator {
    using SafeERC20 for IKMT;
    using SafeERC20 for IERC20;

    struct Meta {
        IKTA KNFT;
        IKMT KMT;
        IERC20 u;
        IPancakeRouter router;
        address pair;
        uint rate;
        uint premium;
        bool isOpen;
        bool repoOpen;
    }
    struct RepoPool {
       uint amount;
    }
    struct PoolInfo {
        uint cardId;
        uint jackpot;
        uint price;
        uint time;
        uint totalNum;
        uint commonReward;
        // stats
        uint totalKmt;
        uint totalAddr;
    }
    struct Winner {
        bool isWin;
        address addr;
        uint openTime;
        uint duration;
        
    }
    struct Reward {
        uint tokenId;
        uint freeTime;   // 冻结回购的时间
        uint initDebt;
        uint rewardDebt;
        uint commonReward;  // 推荐收益
        uint commonNumber;  // 推荐人数
        uint claimedCommon; // 已领取推荐收益
    }
    
    Meta public meta; 
    RepoPool public repoPool;
    address[] public path;

    // poolId => PoolInfo
    mapping(uint => PoolInfo) public PoolInfoes;
    // poolId => Winner
    mapping(uint => Winner) public winners;
    // tokenId => Reward
    mapping(uint => Reward) public RewardDatas;

    // stats
    mapping(uint => mapping(address => bool)) public addrSubMap;
    mapping(address => bool) public addrMap;
    mapping(address => bool) public whiteList;
    uint public totalAddr; 
    uint public totalKmt; 
    uint public totalRepo;  // 回购人数
    uint public totalRepoU; // 回购出去的u
    uint public totalPoundage;   // 累积手续费u

    constructor() {
        meta.KMT = IKMT(0xC529341E0A13e6D539bCcC41D814eB24a50f35C5);
        meta.KNFT = IKTA(0x793841c40CDcE53c52C240a90161cC4790957ADD);
        meta.u = IERC20(0x7063B8CE05627301bC0bdBB390F0CB1C6B46d9A3);
        PoolInfoes[1009] = PoolInfo({
            cardId: 1009,
            price: 10000 ether,
            time: 2 days,
            jackpot: 50000 ether,
            totalNum: 0,
            commonReward: 0,
            totalKmt: 0,
            totalAddr: 0
        });
        PoolInfoes[1010] = PoolInfo({
            cardId: 1010,
            price: 2000 ether,
            time: 1 days,
            jackpot: 10000 ether,
            totalNum: 0,
            commonReward: 0,
            totalKmt: 0,
            totalAddr: 0
        });
        PoolInfoes[1011] = PoolInfo({
            cardId: 1011,
            price: 300 ether,
            time: 1 days,
            jackpot: 3000 ether,
            totalNum: 0,
            commonReward: 0,
            totalKmt: 0,
            totalAddr: 0
        });

        meta.rate = 5;
        meta.premium = 120;  
        // meta.isOpen = true;
        meta.repoOpen = true;      

        path.push(address(meta.KMT));
        path.push(address(meta.u));
    }

    modifier onlyOpen {
        require(meta.isOpen, "not open yet");
        _;
    }

    event Repurchase(address indexed account, uint indexed poolId, uint indexed tokenId, uint amount);
    event Play(address indexed account, uint indexed poolId, uint indexed tokenId);
    event ClaimReward(address indexed account, uint indexed poolId, uint indexed tokenId, uint amount);
    event ClaimCommonReward(address indexed account, uint indexed poolId, uint indexed tokenId, uint amount);

    // ---------------- onlyOwner -----------------
    function setMeta(address knft_, address kmt_) external onlyOwner {
        meta.KMT = IKMT(kmt_);
        meta.KNFT = IKTA(knft_);
    }

    function setWhiteList(address[] calldata accounts_, bool[] calldata states_) external onlyOwner {
        for (uint i = 0; i < accounts_.length; i++) {
            whiteList[accounts_[i]] = states_[i];
        }
    }
    
    function startPlay() external onlyOwner {
        require(!meta.isOpen);
        meta.isOpen = true;
        for (uint i = 1009; i <= 1011; i++){
            winners[i].openTime = block.timestamp;
        }
    }

    function stopPlay() external onlyOwner onlyOpen {
        meta.isOpen = false;
    }

    function setRepo(bool state) external onlyOwner onlyOpen {
        meta.repoOpen = state;
    }

    // ---------------- onlyOwner -----------------

    function getPrice() public view returns(uint, uint) {
        // uint reserve0 = meta.u.balanceOf(meta.pair);
        // uint reserve1 = meta.KMT.balanceOf(meta.pair);
        // return (reserve0, reserve1);
        return (1,1);
    }


    function getValue(uint[] calldata tokenIds_) public view returns(uint) {
        uint value;
        for (uint i = 0; i < tokenIds_.length; i++) {
            uint poolId = meta.KNFT.cardIdMap(tokenIds_[i]);
            if (PoolInfoes[poolId].cardId != poolId) {
                continue;
            }
            value += PoolInfoes[poolId].price;
        }
        return value;
    }

    function donate(uint amount) public onlyOpen returns(uint) {
        require(whiteList[_msgSender()], "not allow");

        meta.u.safeTransferFrom(_msgSender(), address(this), amount);

        // 随机抽取一张nft给用户
        uint balance = meta.KNFT.balanceOf(address(this));
        uint i = randomCeil(balance) - 1;
        uint tokenId = meta.KNFT.tokenOfOwnerByIndex(address(this), i);
        meta.KNFT.safeTransferFrom(address(this), _msgSender(), tokenId);
        return tokenId;
    }

    function repurchase(uint tokenId_) public returns(uint) {
        require(meta.repoOpen, "not open");
        uint poolId = meta.KNFT.cardIdMap(tokenId_);
        require(PoolInfoes[poolId].cardId == poolId, "wrong card");
        require(block.timestamp >= RewardDatas[tokenId_].freeTime, "wrong time");

        meta.KNFT.safeTransferFrom(_msgSender(), address(this), tokenId_);

        uint price = PoolInfoes[poolId].price / 100 * meta.premium;
        uint poundage = PoolInfoes[poolId].price / 100 * 5;
        uint amount = _swap(price - poundage);
        meta.u.safeTransfer(_msgSender(), amount);

        totalRepo += 1;
        totalRepoU += amount;
        totalPoundage += poundage;

        emit Repurchase(_msgSender(), poolId, tokenId_, amount);
        return amount;
    }

    function repurchaseBatch(uint[] calldata tokenIds_) public returns(bool) {
        for(uint i = 0; i < tokenIds_.length; i++) {
            repurchase(tokenIds_[i]);
        }
        return true;
    }

    function play(uint poolId_, uint tokenId_) public onlyOpen returns (bool) {
        require(PoolInfoes[poolId_].cardId != 0, "Err poolId");
        require(RewardDatas[tokenId_].tokenId != 0, "Err inviter");
        uint price = PoolInfoes[poolId_].price;

        meta.KMT.safeTransferFrom(_msgSender(), address(this), price);

        //50% 回购池
        uint repoAmount = _swap(price / 10 * 5);
        repoPool.amount += repoAmount;
        
        // 10% 分红
        uint commonReward = price / 10 * 1;
        if (PoolInfoes[poolId_].totalNum > 0) {
            PoolInfoes[poolId_].commonReward += commonReward / PoolInfoes[poolId_].totalNum;
        }
        PoolInfoes[poolId_].totalNum += 1;

        uint tokenId = meta.KNFT.mint(_msgSender(), PoolInfoes[poolId_].cardId);
        RewardDatas[tokenId] = Reward({
            tokenId: tokenId,
            freeTime: block.timestamp + 600,
            initDebt: PoolInfoes[poolId_].commonReward,
            rewardDebt: PoolInfoes[poolId_].commonReward,
            commonReward: 0,
            commonNumber: 0,
            claimedCommon: 0
        });

        // 20% 奖金池
        uint fomoReward = price / 10 * 2;

        // 20% 推荐奖励
        if (tokenId_ != 0) {
            RewardDatas[tokenId_].commonReward += price / 10 * 1;
            RewardDatas[tokenId_].commonNumber += 1;
            RewardDatas[tokenId].commonReward += price / 10 * 1;
        } else {
            fomoReward += price / 10 * 2;
        }

        if (!winners[poolId_].isWin) {
            PoolInfoes[poolId_].jackpot += fomoReward;
        }

        // stats
        totalKmt += price / 10 * 5;
        PoolInfoes[poolId_].totalKmt += price / 10 * 5;
        if (!addrMap[_msgSender()]) {
            addrMap[_msgSender()] = true;
            totalAddr += 1;
        }
        if (!addrSubMap[poolId_][_msgSender()]) {
            addrSubMap[poolId_][_msgSender()] = true;
            PoolInfoes[poolId_].totalAddr += 1;
        }

        _chechWinner(poolId_);

        emit Play(_msgSender(), poolId_, tokenId_);
        return true;
    }

    function claimReward(uint tokenId_) public onlyOpen returns (uint) {
        require(meta.KNFT.ownerOf(tokenId_) == _msgSender(), "Not token owner");
        if (RewardDatas[tokenId_].tokenId == 0) {
            return 0;
        }
        uint poolId = meta.KNFT.cardIdMap(tokenId_);
        uint myReward = PoolInfoes[poolId].commonReward - RewardDatas[tokenId_].rewardDebt;
        if (myReward == 0) {
            return myReward;
        }
        meta.KMT.safeTransfer(_msgSender(), myReward);
        RewardDatas[tokenId_].rewardDebt = PoolInfoes[poolId].commonReward;

        emit ClaimReward(_msgSender(), poolId, tokenId_, myReward);
        return myReward;
    }

    function claimCommonReward(uint tokenId_) public onlyOpen returns (uint) {
        require(meta.KNFT.ownerOf(tokenId_) == _msgSender(), "Not token owner");
        if (RewardDatas[tokenId_].tokenId == 0) {
            return 0;
        }
        uint poolId = meta.KNFT.cardIdMap(tokenId_);
        (uint myReward, ) = viewCommonReward(tokenId_);
        if (myReward == 0) {
            return myReward;
        }
        meta.KMT.safeTransfer(_msgSender(), myReward);

        RewardDatas[tokenId_].commonReward += myReward;
        emit ClaimCommonReward(_msgSender(), poolId, tokenId_, myReward);
        return myReward;
    }

    function viewCommonReward(uint tokenId_) public view returns (uint, uint) {
        if (RewardDatas[tokenId_].tokenId == 0) {
            return (0, 0);
        }
        uint myReward = RewardDatas[tokenId_].commonReward - RewardDatas[tokenId_].claimedCommon;
        uint myRewarded = RewardDatas[tokenId_].claimedCommon;
        return (myReward, myRewarded);
    }

    function viewCommonRewardBatch(uint[] memory tokenIds_) public view returns (uint[] memory, uint[] memory) {
        uint[] memory myReward = new uint[](tokenIds_.length);
        uint[] memory myRewarded = new uint[](tokenIds_.length);
        for (uint i = 0; i < tokenIds_.length; i++){
            (uint a, uint b) = viewReward(tokenIds_[i]);
            myReward[i] = a;
            myRewarded[i] = b;
        }
        return (myReward, myRewarded);
    }
    
    function claimRewardBatch(uint[] calldata tokenIds_) public onlyOpen returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < tokenIds_.length; i++){
            sum += claimReward(tokenIds_[i]);
        }
        return sum;
    }

    function viewReward(uint tokenId_) public view returns (uint, uint) {
        if (RewardDatas[tokenId_].tokenId == 0) {
            return (0, 0);
        }
        uint poolId = meta.KNFT.cardIdMap(tokenId_);
        uint myReward = PoolInfoes[poolId].commonReward - RewardDatas[tokenId_].rewardDebt;
        uint myRewarded = RewardDatas[tokenId_].rewardDebt - RewardDatas[tokenId_].initDebt;
        return (myReward, myRewarded);
    }

    function viewRewardBatch(uint[] memory tokenIds_) public view returns (uint[] memory, uint[] memory) {
        uint[] memory myReward = new uint[](tokenIds_.length);
        uint[] memory myRewarded = new uint[](tokenIds_.length);
        for (uint i = 0; i < tokenIds_.length; i++){
            (uint a, uint b) = viewReward(tokenIds_[i]);
            myReward[i] = a;
            myRewarded[i] = b;
        }
        return (myReward, myRewarded);
    }

    function _swap(uint amount) private returns(uint) {
        return amount;
        // uint[] memory amounts = meta.router.swapExactTokensForTokens(amount, 0, path, _msgSender(), block.timestamp + 60);
        // return amounts[1];
    }

    function _chechWinner(uint poolId_) private {
        if (winners[poolId_].isWin) {
            return;
        }

        if (PoolInfoes[poolId_].totalNum == 0) {
            winners[poolId_].addr = _msgSender();
            winners[poolId_].duration = 0;
            winners[poolId_].isWin = false;
            return;
        }

        uint duration = block.timestamp - winners[poolId_].openTime;
        if (duration >= PoolInfoes[poolId_].time) {
            winners[poolId_].isWin = true;
            winners[poolId_].duration = duration;
        } else {
            if (winners[poolId_].addr == _msgSender()) {
                return;
            }
            winners[poolId_].addr = _msgSender();
            winners[poolId_].openTime = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomGenerator {
    uint private randNonce = 0;

    function random(uint256 seed) internal returns (uint256) {
        randNonce += 1;
        return uint256(keccak256(abi.encodePacked(
                blockhash(block.number - 1),
                blockhash(block.number - 2),
                blockhash(block.number - 3),
                blockhash(block.number - 4),
                blockhash(block.number - 5),
                blockhash(block.number - 6),
                blockhash(block.number - 7),
                blockhash(block.number - 8),
                block.timestamp,
                msg.sender,
                randNonce,
                seed
            )));
    }

    function randomCeil(uint256 q) internal returns (uint256) {
        return (random(gasleft()) % q) + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract Divestor is Ownable {
    using SafeERC20 for IERC20;
    event Divest(address token, address payee, uint value);

    function divest(address token_, address payee_, uint value_) external onlyOwner {
        if (token_ == address(0)) {
            payable(payee_).transfer(value_);
            emit Divest(address(0), payee_, value_);
        } else {
            IERC20(token_).safeTransfer(payee_, value_);
            emit Divest(address(token_), payee_, value_);
        }
    }

    function setApprovalForAll(address token_, address _account) external onlyOwner {
        IERC721(token_).setApprovalForAll(_account, true);
    }
    
    function setApprovalForAll1155(address token_, address _account) external onlyOwner {
        IERC1155(token_).setApprovalForAll(_account, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancakeRouter {
    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
        ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IKTA{
    function balanceOf(address owner) external view returns(uint256);
    function cardIdMap(uint) external view returns(uint); // tokenId => cardId
    function cardInfoes(uint) external returns(uint cardId, string memory name, uint currentAmount, uint maxAmount, string memory _tokenURI);
    function tokenURI(uint256 tokenId_) external view returns(string memory);
    function mint(address player_, uint cardId_) external returns(uint256);
    function mintWithId(address player_, uint id_, uint tokenId_) external returns (bool);
    function mintMulti(address player_, uint cardId_, uint amount_) external returns(uint256);
    function burn(uint tokenId_) external returns (bool);
    function burnMulti(uint[] calldata tokenIds_) external returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);
    function totalSupply() external view returns (uint256);
    function burned() external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKMT is IERC20 {
    function ownerOf(uint256 tokenId) external returns(address user);
    function burn(uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

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

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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