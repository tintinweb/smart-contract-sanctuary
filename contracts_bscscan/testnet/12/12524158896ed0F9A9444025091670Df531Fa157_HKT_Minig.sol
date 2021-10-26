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
import "./router.sol";

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface HKT721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function cardIdMap(uint tokenId) external view returns (uint256 cardId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface Flash {
    function y(address coin_) external view returns (uint);
}


contract HKT_Minig is Ownable {
    IPancakeRouter02 public router = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IERC20 public HKT;
    IERC20 public U;
    HKT721 public NFT;
    Flash public F;
    uint public constant acc = 1e10;
    uint public constant dailyOut = 275 ether;
    uint public rate;
    uint public debt;
    uint public totalPower;
    uint public lastTime;
    uint public startTime;
    address public stage;
    address public fund;
    uint public coinAmount;
    uint public userAmount;

    uint public CatId;
    address public nftPool;
    address[]  path = new address[](2);

    event Stake(address indexed sender_, address indexed coin_, uint indexed slot_, uint amount_);
    event Claim(address indexed sender_, uint indexed amount_);
    event Deposite(address indexed sender_, uint indexed amount_, uint indexed pool_);
    event UnDeposit(address indexed sender_, uint indexed pool_);
    event Renew(address indexed sender_, uint indexed pool_);

    struct UserInfo {
        uint total;
        uint claimed;
        bool frist;
        uint value;
    }


    struct SlotInfo {
        bool status;
        uint power;
        uint stakeTime;
        uint endTime;
        uint claimTime;
        uint debt;
    }

    struct PoolInfo {
        uint TVL;
        uint debt;
        uint lastTime;
        address token;
        uint rate;

    }//1 for HKT,2for LP;

    struct UserPool {
        uint stakeAmount;
        uint debt;
        uint toClaim;
        uint claimed;

    }

    mapping(uint => PoolInfo)public poolInfo;
    mapping(address => mapping(uint => UserPool))public userPool;
    mapping(address => UserInfo)public userInfo;
    mapping(address => mapping(uint => SlotInfo))public slotInfo;
    mapping(uint => address)public coinID;


    constructor(){
        rate = dailyOut / 1 days;
        poolInfo[1].rate = 40;
        poolInfo[2].rate = 60;
    }

    function setPoolToken(uint pool_, address token_) public onlyOwner {
        poolInfo[pool_].token = token_;
    }

    function setToken(address HKT_, address U_) public onlyOwner {
        HKT = IERC20(HKT_);
        U = IERC20(U_);
        poolInfo[1].token = HKT_;
        path[1] = HKT_;
        path[0] = U_;
    }

    function setAddress(address fund_, address stage_, address nftPool_, address HKT721_, address Flash_) public onlyOwner {
        fund = fund_;
        stage = stage_;
        nftPool = nftPool_;
        NFT = HKT721(HKT721_);
        F = Flash(Flash_);
    }

    function coutingDebt() public view returns (uint _debt){
        _debt = totalPower > 0 ? (rate * 85 / 100) * (block.timestamp - lastTime) * acc / totalPower + debt : 0 + debt;
    }

    function coutingPower(uint amount_, address token_) public view returns (uint){
        if (startTime == 0) {
            return 0;
        }
        uint decimal = IERC20(token_).decimals();
        uint uAmount = amount_ * (10 ** (18 - decimal));
        uint _total = getPrice(token_, amount_) + uAmount;
        uint day = (block.timestamp - startTime) % 1 days;
        return ((day + 100) / 100) * _total;

    }

    function datePower() public view returns (uint){
        if (startTime == 0) {
            return 100;
        }
        uint day = (block.timestamp - startTime) % 1 days;
        return day + 100;
    }

    function getPrice(address token_, uint amount_) public view returns (uint){
        uint decimal = IERC20(token_).decimals();
        uint price = F.y(token_);
        return amount_ * price / 10 ** decimal;

    }

    function setCoinID(uint id_, address coin_) public onlyOwner {
        coinID[id_] = coin_;
        coinAmount += 1;
    }

    function calculateRewards(address addr_, uint slot_) public view returns (uint){
        SlotInfo storage slot = slotInfo[addr_][slot_];
        uint tempDebt;
        uint rewards;
        if (!slotInfo[addr_][slot_].status) {
            return 0;
        }
        if (block.timestamp > slot.endTime && slot.claimTime < slot.endTime) {
            tempDebt = (rate * 85 / 100) * (slot.endTime - slot.claimTime) * acc / totalPower;
            rewards = tempDebt * slot.power / acc;
        } else if (block.timestamp < slot.endTime) {
            tempDebt = coutingDebt();
            rewards = slot.power * (tempDebt - slot.debt) / acc;
        }
        return rewards;

    }

    function checkPoudage(uint amount_) public view returns (uint rew_, uint burn_, uint pool_){
        if (userAmount <= 500) {
            rew_ = amount_ * 2 / 10;
            burn_ = amount_ / 2;
            pool_ = amount_ * 3 / 10;
        } else if (userAmount > 500 && userAmount <= 2000) {
            rew_ = amount_ * 3 / 10;
            burn_ = amount_ * 45 / 100;
            pool_ = amount_ * 25 / 100;
        } else if (userAmount > 2000 && userAmount <= 5000) {
            rew_ = amount_ * 5 / 10;
            burn_ = amount_ * 35 / 100;
            pool_ = amount_ * 15 / 100;
        } else if (userAmount > 5000) {
            rew_ = amount_ * 99 / 100;
            burn_ = 0;
            pool_ = amount_ / 100;
        }
    }

    function checkRate() public view returns (uint){
        uint out;
        if (userAmount <= 500) {
            out = 20;
        } else if (userAmount > 500 && userAmount <= 2000) {
            out = 30;
        } else if (userAmount > 2000 && userAmount <= 5000) {
            out = 50;
        } else if (userAmount > 5000) {
            out = 99;
        }
        return out;
    }

    function calculateAll(address addr_) public view returns (uint){
        uint tempAmount;
        for (uint i = 0; i < 10; i++) {
            if (slotInfo[addr_][i].status) {
                tempAmount += calculateRewards(addr_, i);
            } else {
                continue;
            }
        }
        (uint out_,,) = checkPoudage(tempAmount);
        return out_;

    }

    function claimRewards() external {
        require(userInfo[_msgSender()].total > 0, 'no stake');
        uint tempAmount;
        for (uint i = 0; i < 10; i++) {
            if (slotInfo[_msgSender()][i].status) {
                tempAmount += calculateRewards(_msgSender(), i);
                slotInfo[_msgSender()][i].claimTime = block.timestamp;
                slotInfo[_msgSender()][i].debt = coutingDebt();
                if (slotInfo[_msgSender()][i].claimTime >= slotInfo[_msgSender()][i].endTime) {
                    slotInfo[_msgSender()][i].status = false;
                    uint tempPow = slotInfo[_msgSender()][i].power;
                    userInfo[_msgSender()].total -= tempPow;
                    totalPower -= tempPow;
                    debt = coutingDebt();
                }
            } else {
                continue;
            }
        }
        require(tempAmount > 0, 'no amount');
        (uint rew,uint burn,uint pool) = checkPoudage(tempAmount);
        HKT.transfer(_msgSender(), rew);
        HKT.transfer(address(0), burn);
        HKT.transfer(nftPool, pool);
        userInfo[_msgSender()].claimed += tempAmount;
        emit Claim(_msgSender(), tempAmount);
    }

    function checkSlotNum(address addr_) public view returns (uint){
        uint cc = 99;
        for (uint i = 0; i < 10; i++) {
            if (!slotInfo[addr_][i].status || slotInfo[addr_][i].claimTime >= slotInfo[addr_][i].endTime) {
                cc = i;
                break;
            } else {
                continue;
            }
        }
        return cc;
    }

    function checkUserSlot(address addr_) public view returns (uint[10] memory out_){
        for (uint i = 0; i < 10; i++) {
            if (slotInfo[addr_][i].status) {
                out_[i] = 1;
            }
        }
    }

    function stake(uint coinID_, uint amount_, uint slot_) public {
        if (slotInfo[_msgSender()][slot_].claimTime >= slotInfo[_msgSender()][slot_].endTime) {
            slotInfo[_msgSender()][slot_].status = false;
        }
        require(!slotInfo[_msgSender()][slot_].status, 'staked');
        require(coinID[coinID_] != address(0), 'wrong ID');
        require(slot_ < 10, 'wrong slot');
        require(amount_ % 1 ether == 0, 'must be int');
        if (startTime == 0) {
            startTime = block.timestamp;
        }
        if (!userInfo[_msgSender()].frist) {
            userInfo[_msgSender()].frist = true;
            userAmount += 1;
        }
        uint uAmount;
        uint decimal = IERC20(coinID[coinID_]).decimals();
        uAmount = amount_ * (10 ** (18 - decimal));
        IERC20(coinID[coinID_]).transferFrom(_msgSender(), address(0), amount_);

        U.transferFrom(_msgSender(), stage, uAmount * 2 / 100);
        U.transferFrom(_msgSender(), fund, uAmount * 2 / 100);
        U.transferFrom(_msgSender(), address(this), uAmount * 96 / 100);
        // router.swapExactTokensForTokens(amount_ * 96 / 100, 0, path, address(this), block.timestamp + 720);
        uint tempPow = coutingPower(amount_, coinID[coinID_]);
        totalPower += tempPow;

        uint tempDebt = coutingDebt();
        debt = tempDebt;
        lastTime = block.timestamp;
        userInfo[_msgSender()].total += tempPow;
        userInfo[_msgSender()].value += getPrice(coinID[coinID_], amount_) + amount_;
        slotInfo[_msgSender()][slot_] = SlotInfo({
        status : true,
        power : tempPow,
        stakeTime : block.timestamp,
        endTime : block.timestamp + 30 days,
        claimTime : block.timestamp,
        debt : tempDebt
        });
        emit Stake(_msgSender(), coinID[coinID_], slot_, amount_);
    }

    function coutingRenew(address addr_, uint slot_) public view returns (uint){
        if (slotInfo[addr_][slot_].power == 0) {
            return 0;
        }
        uint r = slotInfo[addr_][slot_].power % 1e18;
        uint tempPow = slotInfo[addr_][slot_].power / 1e20;
        if (r > 0) {
            return tempPow += 1;
        } else {
            return tempPow;
        }
    }

    function setCatFood(uint cardId_) public onlyOwner {
        CatId = cardId_;
    }

    function coutingCatFood(address addr_) public view returns (uint){
        uint k = NFT.balanceOf(addr_);
        uint tokenId;
        uint cardId;
        uint out;
        if (k == 0) {
            return 0;
        }
        for (uint i = 0; i < k; i++) {
            tokenId = NFT.tokenOfOwnerByIndex(addr_, i);
            cardId = NFT.cardIdMap(tokenId);
            if (cardId == CatId) {
                out ++;
            }
        }
        return out;
    }


    function renew(uint slot_) public {
        require(slotInfo[_msgSender()][slot_].power > 0, 'no power');
        require(slotInfo[_msgSender()][slot_].endTime > block.timestamp, 'overdue');
        uint need = coutingRenew(_msgSender(), slot_);
        uint catFood = coutingCatFood(_msgSender());
        require(catFood >= need, 'not enough amount');
        uint tokenId;
        uint cardId;
        uint k = NFT.balanceOf(_msgSender());
        uint amount;
        for (uint i = 0; i < k; i++) {
            tokenId = NFT.tokenOfOwnerByIndex(_msgSender(), i);
            cardId = NFT.cardIdMap(tokenId);
            if (cardId == CatId) {
                NFT.safeTransferFrom(_msgSender(), address(this), tokenId);
                amount += 1;
                if (amount == need) {
                    break;
                }
            }
        }
        slotInfo[_msgSender()][slot_].endTime += 30 days;
        emit Renew(_msgSender(), slot_);
    }

    function safePull(address token_, address wallet, uint amount_) public onlyOwner {
        IERC20(token_).transfer(wallet, amount_);
    }

    function coutingPoolDebt(uint pool_) public view returns (uint _debt){
        _debt = poolInfo[pool_].TVL > 0 ? (rate * 15 * poolInfo[pool_].rate / 10000) * (block.timestamp - poolInfo[pool_].lastTime) * acc / poolInfo[pool_].TVL + poolInfo[pool_].debt : 0 + poolInfo[pool_].debt;
    }

    function calculatePool(uint pool_, address addr_) public view returns (uint rew_){
        if (userPool[addr_][pool_].stakeAmount == 0) {
            return 0;
        }
        uint tempDebt = coutingPoolDebt(pool_);
        uint rew = (tempDebt - userPool[addr_][pool_].debt) * userPool[addr_][pool_].stakeAmount / acc;
        return rew;
    }

    function checkRew(address addr_, uint pool_) public view returns (uint rew_){
        if (userPool[addr_][pool_].stakeAmount == 0) {
            return 0;
        }
        uint temp = calculatePool(pool_, addr_);
        (uint s,,) = checkPoudage(temp);
        rew_ = s + userPool[addr_][pool_].toClaim;

    }

    function claimPool(uint pool_) public {
        require(userPool[_msgSender()][pool_].stakeAmount > 0, 'no amount');
        uint tempAmount = calculatePool(pool_, _msgSender()) + userPool[_msgSender()][pool_].toClaim;
        (uint rew,uint burn,uint pool) = checkPoudage(tempAmount);
        HKT.transfer(_msgSender(), rew);
        HKT.transfer(address(0), burn);
        HKT.transfer(nftPool, pool);
        userPool[_msgSender()][pool_].toClaim = 0;
        userPool[_msgSender()][pool_].claimed += tempAmount;
        emit Claim(_msgSender(), tempAmount);
    }


    function deposite(uint amount_, uint pool_) public {
        require(amount_ > 0, 'no amount');
        require(pool_ == 1 || pool_ == 2, 'wrong pool');
        if (userPool[_msgSender()][pool_].stakeAmount > 0) {
            (uint tempRew,,) = checkPoudage(calculatePool(pool_, _msgSender()));
            userPool[_msgSender()][pool_].toClaim += tempRew;

        }
        uint tempDebt = coutingPoolDebt(pool_);
        poolInfo[pool_].TVL += amount_;
        poolInfo[pool_].debt = tempDebt;
        poolInfo[pool_].lastTime = block.timestamp;
        userPool[_msgSender()][pool_].stakeAmount += amount_;
        userPool[_msgSender()][pool_].debt = tempDebt;
        IERC20(poolInfo[pool_].token).transferFrom(_msgSender(), address(this), amount_);
        emit Deposite(_msgSender(), amount_, pool_);
    }

    function unDeposit(uint pool_) public {
        require(userPool[_msgSender()][pool_].stakeAmount > 0, 'no amount');
        require(pool_ == 1 || pool_ == 2, 'wrong pool');
        claimPool(pool_);
        uint s = userPool[_msgSender()][pool_].claimed;
        poolInfo[pool_].TVL -= userPool[_msgSender()][pool_].stakeAmount;
        poolInfo[pool_].debt = coutingPoolDebt(pool_);
        poolInfo[pool_].lastTime = block.timestamp;
        userPool[_msgSender()][pool_] = UserPool({
        stakeAmount : 0,
        debt : 0,
        toClaim : 0,
        claimed : s
        });
        emit UnDeposit(_msgSender(), pool_);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}