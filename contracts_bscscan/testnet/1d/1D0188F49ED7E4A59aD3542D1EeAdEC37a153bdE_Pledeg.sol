// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface ISRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function burn (address addr_,uint amount_) external returns(bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Pledeg is Ownable{
    ISRC20 public SpeToken;
    uint public priceNBCT;
    address public banker = 0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954;
    uint public upTime;
    uint public dayOutPut;
    uint public rate;
    uint[5] public cycle = [7 days, 15 days, 30 days, 60 days, 90 days];
    uint[5] public Coe = [8, 9, 10 ,11, 12]; //算力系数 
    uint public startTime;
    uint public decimal = 1e18;
    bool public status;
    uint public Acc = 1e10 ;
    uint public TVL;
    uint public totalPower;
    bytes32 public test;
    address public test2;
    event stakeSpe(address indexed sender_, uint indexed slot_, uint indexed amount_, uint timestamp);
    event stakeNBTC(address indexed sender_, uint indexed slot_, uint indexed amount_, uint  price_, uint timestamp);

    struct Debt {
        uint timestamp;
        uint debted;
    }
    Debt public debt;
    struct slot{
        bool status;
        uint stakeAmount;
        uint debt;
        uint stakeTime;
        uint power;
        uint endTime;
    }

    // mapping(address => userSlot)slotInfo;
    struct UserInfo{
        uint NBCT;
        uint finalPower;
        uint stakeAmount;
        mapping(uint => slot)userSlot;
        address invitor;
        uint refer_n;
        uint toClaim;
        uint Claimed;
        uint lockSpe;

    }
    mapping(address => UserInfo) public userInfo;
    modifier checkTime{
        if(block.timestamp - startTime >= 365 days){
            startTime += 365 days;
            dayOutPut = dayOutPut * 80 / 100;
            rate = dayOutPut / 1 days;
        }
        _;
    }
    modifier isStart{
        require(status,'not start yet');
        _;
    }
    function setInit() public onlyOwner{
        startTime = block.timestamp;
        status = true;
    }
    constructor(){
        dayOutPut = 6068600 * decimal / 365;
        rate = dayOutPut / 1 days;

    }
    function coutingDebt() public view returns( uint debt_){
        debt_ = totalPower>0 ?  (rate * 6 / 10)  * (block.timestamp - debt.timestamp) * Acc / totalPower + debt.debted:0;

    }
    function calculateSlotRewards(address addr_,uint slot_) public view returns(uint rewards) {
        require(slot_ >= 1 && slot_ <= 10,'worng slot');
        require (userInfo[addr_].userSlot[slot_].stakeAmount > 0, 'no amount');
        rewards = userInfo[addr_].stakeAmount * (coutingDebt() - userInfo[addr_].userSlot[slot_].debt) / Acc ;
    }


    function stakeWithSpe(uint slot_, uint amount_, uint cycle_) isStart public returns(bool){
        require(slot_ >= 1 && slot_ <= 10,'worng slot');
        require(cycle_ >=1 && cycle_ <= 5,'wrong cycle');
        require(amount_ >= 50 * decimal,'not enough amount');
        require(!userInfo[msg.sender].userSlot[slot_].status,'already staked');
        require(SpeToken.transferFrom(msg.sender,address(this),amount_),'Transfer fail');
        uint nowdebt = coutingDebt();
        uint tempPower = amount_ * Coe[cycle_ - 1];
        userInfo[msg.sender].userSlot[slot_] = slot({
        status : true,
        stakeAmount : amount_,
        debt : nowdebt,
        stakeTime : block.timestamp,
        power : tempPower,
        endTime : block.timestamp + cycle[cycle_ - 1]
        });

        userInfo[msg.sender].stakeAmount += amount_;
        userInfo[msg.sender].finalPower += tempPower;
        debt.debted = nowdebt;
        debt.timestamp = block.timestamp;
        TVL += amount_;
        totalPower += tempPower;
        return true;
    }

    function stakeWithNBTC(uint slot_, uint amount_, uint cycle_) isStart public returns(bool){
        require(slot_ >= 1 && slot_ <= 10,'worng slot');
        require(cycle_ >=1 && cycle_ <= 5,'wrong cycle');
        uint tempSPE = amount_ * priceNBCT  * decimal / 10;
        require(tempSPE >= 50 ,'not enough amount');
        require(!userInfo[msg.sender].userSlot[slot_].status,'already staked');
        require(userInfo[msg.sender].NBCT >= amount_,'not enough NBCT');
        userInfo[msg.sender].NBCT -= amount_;
        uint nowdebt = coutingDebt();
        uint tempPower = tempSPE * Coe[cycle_ - 1];
        userInfo[msg.sender].userSlot[slot_] = slot({
        status : true,
        stakeAmount : tempSPE,
        debt : nowdebt,
        stakeTime : block.timestamp,
        power : tempPower,
        endTime : block.timestamp + cycle[cycle_ - 1]
        });

        userInfo[msg.sender].stakeAmount += tempSPE;
        userInfo[msg.sender].finalPower += tempPower;
        debt.debted = nowdebt;
        debt.timestamp = block.timestamp;
        TVL += tempSPE;
        totalPower += tempPower;
        return true;
    }

//    function claimStatic(uint slot_) isStart public {
//        require(slot_ >= 1 && slot_ <= 10,'worng slot');
//        require(userInfo[msg.sender].userSlot[slot_].stakeAmount > 0,'no amount');
//        if(block.timestamp >= userInfo[msg.sender].userSlot[slot_].endTime && userInfo[msg.sender].userSlot[slot_].stakeTime < userInfo[msg.sender].userSlot[slot_].endTime ){
//
//
//        }
//
//    }

    function activateInvite(address addr_,bytes32 r, bytes32 s, uint8 v) external {
        // require(userInfo[addr_].invitor == address(0),'wrong');

        bytes32 hash =  keccak256(abi.encodePacked(addr_));
        // test = hash;
        address a = ecrecover(hash, v, r, s);
        // test2 = a;
        require(a == banker, "Invalid signature");
        userInfo[addr_].invitor = msg.sender;
        userInfo[msg.sender].refer_n += 1;
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
        return msg.data;
    }
}

