// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IKTA{
    function balanceOf(address owner) external returns(uint256);
    function cardIdMap(uint) external view returns(uint); // tokenId => cardId
    function cardInfoes(uint) external returns(uint cardId, string memory name, uint currentAmount, uint maxAmount, string memory _tokenURI);
    function tokenURI(uint256 tokenId_) external view returns(string memory);
    function mint(address player_, uint cardId_) external returns(uint256);
    function mintMulti(address player_, uint cardId_, uint amount_) external returns(uint256);
    function burn(uint tokenId_) external returns (bool);
    function burnMulti(uint[] calldata tokenIds_) external returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external returns (uint256);

    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Imsbox {
    function mint(address to_, uint boxId_, uint amount_) external returns (bool);
    function burn(address account, uint256 id, uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../other/random_generator.sol";
import "../interface/Ikaka721.sol";
import "../interface/Imsbox1155.sol";

contract MysteryBoxS4 is Ownable, RandomGenerator {
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Address for address;
    using Strings for uint256;

    address public banker;

    bool public isSale;
    bool public isOpenBox;

    uint public price;

    //获得key地址
    address[] public keyAddresss;

    // 购买人数
    uint public total;
    mapping(address => bool) purchase_flag;

    // 一开
    mapping(uint => cardBagInfo) public firstCardBag;
    uint public firstCardBagCap;
    uint public firstCardAmount;

    // 二开
    mapping(uint => cardBagInfo) public secCardBag;
    uint public secCardBagCap;
    uint public secCardAmount;

    struct cardBagInfo {
        uint cardId;
        uint amount;
    }

    //二开价格
    uint public secPrice;

    Winner public winner;
    uint public secTotalAmount;

    struct Winner {
        address addr;
        uint openTime;
        uint duration;
        bool isWin;
    }

    uint public repurchasePrice;

    uint public msBoxKey = 8;
    Imsbox public Msbox;

    address public wallet;

    IERC20 public U;

    IKTA public KTA;

    uint public saleBoxAmount;
    uint public saleMaxNum;

    uint private _accSales_n;
    uint private _accSales_u;
    mapping(uint => uint) public secOpenUsed;
    mapping(uint => uint) public secOpenGet;

    event BuyBox(address indexed user, uint cardId, uint amount);
    event OpenBox(address indexed user, uint indexed cardId, uint indexed tokenId);
    event SecOpenBox(address indexed user, uint indexed cardId);

    modifier saleStage () {
        require(isSale, "not sale stage");
        _;
    }

    modifier openBoxStage(){
        require(isOpenBox, "not openbox stage");
        _;
    }

    constructor(address KTA_, address Msbox_, address U_, address wallet_) {
        KTA = IKTA(KTA_);
        Msbox = Imsbox(Msbox_);
        U = IERC20(U_);
        wallet = wallet_;

        price = 199 ether;
        secPrice = 6 * 1e16;
        repurchasePrice = price * 80 / 100;

        uint[20] memory cardIds_ = [uint(90001), uint(90002), uint(90003), uint(90004), uint(90005), uint(90006), uint(90007), uint(90008), uint(90009), uint(90010), uint(90011), uint(90012), uint(90013), uint(90014), uint(90015), uint(90016), uint(90017), uint(90018), uint(90019), uint(90020)];
        uint[20] memory amounts_ = [uint(10), uint(80), uint(80), uint(290), uint(290), uint(290), uint(290), uint(290), uint(290), uint(290), uint(480), uint(480), uint(480), uint(480), uint(480), uint(480), uint(480), uint(480), uint(480), uint(480)];
        firstCardBagCap = cardIds_.length;

        for (uint i = 0; i < firstCardBagCap; ++i) {
            firstCardBag[i] = cardBagInfo({
            cardId : cardIds_[i],
            amount : amounts_[i]
            });
            firstCardAmount = firstCardAmount.add(amounts_[i]);
        }
        saleMaxNum = firstCardAmount;

        uint[5] memory secCardIds_ = [uint(999), uint(902), uint(903), uint(904), uint(777)];
        uint[5] memory secAmounts_ = [uint(3), uint(136), uint(409), uint(3551), uint(2731)];
        secCardBagCap = secCardIds_.length;

        for (uint i = 0; i < secCardBagCap; ++i) {
            secCardBag[i] = cardBagInfo({
            cardId : secCardIds_[i],
            amount : secAmounts_[i]
            });
            secCardAmount = secCardAmount.add(secAmounts_[i]);
        }
        secTotalAmount = secCardAmount;
    }

    // only owner

    function setSaleToken(address com) public onlyOwner {
        U = IERC20(com);
    }

    function setWallet(address com) public onlyOwner {
        wallet = com;
    }

    function setKTAAddr(address com) public onlyOwner {
        KTA = IKTA(com);
    }

    function setMsboxAddr(address com) public onlyOwner {
        Msbox = Imsbox(com);
    }

    function startSale() external onlyOwner {
        require(!isSale);
        isSale = true;
    }

    function stopSale() external onlyOwner saleStage {
        isSale = false;
    }

    function startOpenBox() external onlyOwner {
        require(!isOpenBox);
        isOpenBox = true;
    }

    function stopOpenBox() external onlyOwner openBoxStage {
        isOpenBox = false;
    }


    function viewSales() external view onlyOwner returns (uint n, uint u) {
        return (_accSales_n, _accSales_u);
    }

    function setBanker(address banker_) external onlyOwner {
        banker = banker_;
    }
    // only owner end

    function buyBox(uint amounts_) external saleStage returns (bool) {
        uint curSaleBox = saleBoxAmount.add(amounts_);
        require(curSaleBox <= saleMaxNum, "Out of limit");

        U.safeTransferFrom(_msgSender(), wallet, amounts_.mul(price));
        Msbox.mint(_msgSender(), msBoxKey, amounts_);

        if (!purchase_flag[_msgSender()]) {
            purchase_flag[_msgSender()] = true;
            total = total.add(1);
        }

        saleBoxAmount = curSaleBox;
        _accSales_n += amounts_;
        _accSales_u += amounts_.mul(price);

        emit BuyBox(_msgSender(), msBoxKey, amounts_);
        return true;
    }

    function openBox() external openBoxStage returns (uint) {
        require(firstCardAmount >= 1, "Out of limit");

        Msbox.burn(_msgSender(), msBoxKey, 1);

        firstCardAmount = firstCardAmount.sub(1);
        uint level = _randomCardLevel();
        uint cardId = firstCardBag[level].cardId;
        uint tokenId = KTA.mint(_msgSender(), cardId);
        firstCardBag[level].amount = firstCardBag[level].amount.sub(1);
        emit OpenBox(_msgSender(), cardId, tokenId);
        return tokenId;
    }

    function openBoxBatch(uint amounts_) external openBoxStage returns (bool){
        require(firstCardAmount >= amounts_, "Out of limit");

        Msbox.burn(_msgSender(), msBoxKey, amounts_);
        firstCardAmount = firstCardAmount.sub(amounts_);

        uint level;
        uint cardId;
        uint tokenId;
        for (uint i = 0; i < amounts_; ++i) {
            level = _randomCardLevel();
            cardId = firstCardBag[level].cardId;
            tokenId = KTA.mint(_msgSender(), cardId);
            firstCardBag[level].amount = firstCardBag[level].amount.sub(1);
            emit OpenBox(_msgSender(), cardId, tokenId);
        }
        return true;
    }

    function secOpenWithBnb(uint tokenId_) external openBoxStage payable returns (uint) {
        require(msg.value == secPrice, 'not balance');
        payable(wallet).transfer(secPrice);
        uint cardId = KTA.cardIdMap(tokenId_);
        require(cardId >= 90004 && cardId <= 90020, "Invalid token id");

        secOpenUsed[cardId] += 1;
        // 处理winner
        _chechWinner();

        KTA.burn(tokenId_);
        if (secCardAmount <= 0) {
            return 0;
        }
        secCardAmount = secCardAmount.sub(1);

        uint level = _secRandomCardLevel();
        secCardBag[level].amount = secCardBag[level].amount.sub(1);

        cardId = secCardBag[level].cardId;
        uint repurPrice;
        if (cardId == 0) {
            revert();
        }
        if (cardId == 999) {
            keyAddresss.push(_msgSender());
        }
        if (cardId == 902) {
            repurPrice = repurchasePrice.mul(300).div(100);
            U.safeTransfer(_msgSender(), repurPrice);
        }
        if (cardId == 903) {
            repurPrice = repurchasePrice.mul(200).div(100);
            U.safeTransfer(_msgSender(), repurPrice);
        }
        if (cardId == 904) {
            repurPrice = repurchasePrice.mul(60).div(100);
            U.safeTransfer(_msgSender(), repurPrice);
        }

        secOpenGet[cardId] += 1;
        emit SecOpenBox(_msgSender(), cardId);
        return cardId;
    }

    function secOpen(uint tokenId_, uint expireAt_, bytes32 r, bytes32 s, uint8 v) external openBoxStage returns (uint) {
        require(block.timestamp <= expireAt_, "Signature expired");
        uint cardId = KTA.cardIdMap(tokenId_);
        require(cardId >= 90004 && cardId <= 90020, "Invalid token id");
        secOpenUsed[cardId] += 1;

        bytes32 hash = keccak256(abi.encodePacked(expireAt_, _msgSender()));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "Invalid signature");
        // 处理winner
        _chechWinner();

        KTA.burn(tokenId_);

        if (secCardAmount <= 0) {
            return 0;
        }
        secCardAmount = secCardAmount.sub(1);

        uint level = _secRandomCardLevel();
        secCardBag[level].amount = secCardBag[level].amount.sub(1);

        cardId = secCardBag[level].cardId;
        uint repurPrice;
        if (cardId == 0) {
            revert();
        }
        if (cardId == 999) {
            keyAddresss.push(_msgSender());
        }
        if (cardId == 902) {
            repurPrice = repurchasePrice.mul(300).div(100);
            U.safeTransfer(_msgSender(), repurPrice);
        }
        if (cardId == 903) {
            repurPrice = repurchasePrice.mul(200).div(100);
            U.safeTransfer(_msgSender(), repurPrice);
        }
        if (cardId == 904) {
            repurPrice = repurchasePrice.mul(60).div(100);
            U.safeTransfer(_msgSender(), repurPrice);
        }

        secOpenGet[cardId] += 1;
        emit SecOpenBox(_msgSender(), cardId);
        return cardId;
    }

    function _chechWinner() internal {
        if (winner.isWin) {
            return;
        }

        // 第一个入场的人初始化
        if (secCardAmount == secTotalAmount) {
            winner.addr = _msgSender();
            winner.openTime = block.timestamp;
            winner.duration = 0;
            winner.isWin = false;
            return;
        }

        // 处理winner
        uint duration = (block.timestamp).sub(winner.openTime);
        if (duration >= 1 days) {
            winner.isWin = true;
            winner.duration = duration;
        } else {
            // 同一用户连续开盲盒不会刷新倒计时
            if (winner.addr == _msgSender()) {
                return;
            }
            winner.addr = _msgSender();
            winner.openTime = block.timestamp;
        }
    }

    function _randomCardLevel() internal returns (uint) {
        uint level = randomCeil(firstCardAmount);
        uint cardIndex;
        for (uint i = 0; i < firstCardBagCap; ++i) {
            cardIndex = cardIndex.add(firstCardBag[i].amount);
            if (level <= cardIndex) {
                return i;
            }
        }

        revert("Random: Internal error");
    }

    function _secRandomCardLevel() internal returns (uint) {
        uint level = randomCeil(secCardAmount);
        uint cardIndex;
        for (uint i = 0; i < secCardBagCap; ++i) {
            cardIndex = cardIndex.add(secCardBag[i].amount);
            if (level <= cardIndex) {
                return i;
            }
        }

        revert("Second random: Internal error");
    }

    // 提钱
    function safePull(address account_, uint amount_) public onlyOwner {
        U.safeTransfer(account_, amount_);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

