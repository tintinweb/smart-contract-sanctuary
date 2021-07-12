/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of the BEP2020 standard as defined in the EIP.
 */
interface IBEP20 {
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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract SSTXLocker is Ownable {

    address deployerAdd;
    address constant teamAdd = 0x5f43cBA50fd67Fb0C274A18AE9f14e39a6e65B84;
    address constant marketingAdd = 0xCaEB94a90e41e6Df9F040302bdD9fb9232D6eAE8;

    uint256[9] private Granularity = [0, 25, 25, 25, 15, 0, 0, 5, 5];
    uint256 private Token_granule = 0;
    uint256 private LP_granule = 0;

    constructor() {
      deployerAdd = msg.sender;
    }

    // Token Address
    IBEP20 token = IBEP20(0x5396734569e26101677Eb39C89413F7fa7d8006f);

    // LP Address
    IBEP20 _LP = IBEP20(0x76719a435e2C5d92F10c00cd30e66Ba72773A59D);

    struct User{
        bool hasLocked;
        uint32 snapshotTime;
        uint256 stakedValue;
        uint32 lastWithdrawTime;
        uint256 totalWithdrawn;
    }

    mapping(address=>User) public userInfo1;
    mapping(address=>User) public userInfo2;

    event TokenLocked(address userAddress, uint32 timestamp, uint256 value);
    event Withdrawn(address userAddress, uint32 timestamp, uint256 value);
    event LPLocked(address userAddress, uint32 timestamp, uint256 value);
    event LPWithdrawn(address userAddress, uint32 timestamp, uint256 value);

    // update SSTX address
    function updateTokenAddress(address _newToken) external onlyOwner() returns (bool){
      token = IBEP20(_newToken);
      return true;
    }

    // update LP address
    function updateLPAddress(address _new_LP) external onlyOwner() returns (bool){
      _LP = IBEP20(_new_LP);
      return true;
    }

     // LOCKER
    function Lock_Token(uint256 value) external returns(bool){
        require(token.balanceOf(msg.sender)>=value, "LOCK: Insufficient balance");
        User storage person = userInfo1[msg.sender];
        require(!person.hasLocked, "Can not lock again!");

        token.transferFrom(msg.sender, address(this), value);
        person.hasLocked = true;
        person.snapshotTime = uint32(block.timestamp);
        person.stakedValue += value;
        person.lastWithdrawTime = uint32(block.timestamp);

        emit TokenLocked(msg.sender, uint32(block.timestamp), value);
        return true;
    }

    function Lock_LP(uint256 value) external returns(bool){
        require(_LP.balanceOf(msg.sender)>=value, "LOCK: Insufficient balance");
        User storage person = userInfo2[msg.sender];
        require(!person.hasLocked, "Can not lock again!");

        _LP.transferFrom(msg.sender, address(this), value);
        person.hasLocked = true;
        person.snapshotTime = uint32(block.timestamp);
        person.stakedValue += value;
        person.lastWithdrawTime = uint32(block.timestamp);

        emit LPLocked(msg.sender, uint32(block.timestamp), value);
        return true;
    }

     // add withdraw SSTX from contract
    function collectTokens() external returns(bool){
        User storage person = userInfo1[msg.sender];
        require(person.hasLocked, "No locked Tokens");
        require(person.stakedValue > 0, "Error: Zero balance account");
        require(person.stakedValue > person.totalWithdrawn, "Error: No Locked Tokens found");

        if(msg.sender == teamAdd){
            require(uint256(block.timestamp) > uint256(person.lastWithdrawTime) + 30 days, "Please wait for some time!");

            // per month share
            uint256 value = person.stakedValue/36;

            // if share >= remaining claim cap send only cap
            if(value >= person.stakedValue-person.totalWithdrawn){
                value = person.stakedValue-person.totalWithdrawn;
            }

            // send tokens
            person.totalWithdrawn += value;
            person.lastWithdrawTime = uint32(uint256(person.lastWithdrawTime) + 30 days);
            token.transfer(teamAdd, value);

            emit Withdrawn(teamAdd, uint32(block.timestamp), value);
            return true;
        }

        else if(msg.sender == marketingAdd){
            require(block.timestamp > uint256(person.lastWithdrawTime) + 30 days, "Please wait for some time!");

            // per month share
            uint256 value = person.stakedValue/12;

            // if share >= remaining claim cap send only cap
            if(value >= person.stakedValue-person.totalWithdrawn){
                value = person.stakedValue-person.totalWithdrawn;
            }

            // send tokens
            person.totalWithdrawn += value;
            person.lastWithdrawTime = uint32(uint256(person.lastWithdrawTime) + 30 days);
            token.transfer(marketingAdd, value);
            emit Withdrawn(marketingAdd, uint32(block.timestamp), value);
            return true;
        }

        else if(msg.sender == deployerAdd){

            require(block.timestamp >= uint256(person.lastWithdrawTime) + 90 days, "Please wait for some time!");
            person.lastWithdrawTime = uint32(uint256(person.lastWithdrawTime) + 90 days);
            Token_granule++;
            if(Granularity[Token_granule] > 0){
                uint256 value = person.stakedValue*Granularity[Token_granule]/100;
                // send tokens
                person.totalWithdrawn += value;
                token.transfer(deployerAdd, value);
                emit Withdrawn(deployerAdd, uint32(block.timestamp), value);
                return true;
            }
        }
        else{
            return false;
        }
        return false;
    }

    function collectLP() external returns(bool){

        User storage person = userInfo2[msg.sender];
        require(person.hasLocked, "No locked amount found");
        require(person.stakedValue > 0, "Error: Zero balance account");
        require(person.stakedValue > person.totalWithdrawn, "Error: No Locked Tokens found");

        if(msg.sender == teamAdd){

            require(block.timestamp >= (uint256(person.lastWithdrawTime) + 30 days), "Please wait for few more days..");

            // per month share
            uint256 value = person.stakedValue/36;

            // if share >= remaining claim cap then send only cap
            if(value >= person.stakedValue-person.totalWithdrawn){
                value = person.stakedValue-person.totalWithdrawn;
            }

            // send tokens
            person.totalWithdrawn += value;
            person.lastWithdrawTime = uint32(uint256(person.lastWithdrawTime) + 30 days);
            _LP.transfer(teamAdd, value);
            emit LPWithdrawn(teamAdd, uint32(block.timestamp), value);
        }

        else if(msg.sender == marketingAdd){

          require(block.timestamp >= uint256(person.lastWithdrawTime) + 30 days, "Please wait for few more days");

          // per month share
          uint256 value = person.stakedValue/12;

          // if share >= remaining claim cap send only cap
          if(value >= person.stakedValue-person.totalWithdrawn){
              value = person.stakedValue-person.totalWithdrawn;
          }

          // send tokens
          person.totalWithdrawn += value;
          person.lastWithdrawTime = uint32(uint256(person.lastWithdrawTime) + 30 days);
          _LP.transfer(msg.sender,value);
          emit LPWithdrawn(marketingAdd, uint32(block.timestamp), value);
          return true;
        }

        else if(msg.sender == deployerAdd){

          require(block.timestamp >= uint256(person.lastWithdrawTime) + 90 days, "Please wait for few more days");
          person.lastWithdrawTime = uint32(uint256(person.lastWithdrawTime) + 90 days );

          LP_granule++;
          if(Granularity[LP_granule] > 0){
              uint256 value = person.stakedValue*Granularity[LP_granule]/100;
              // send tokens
              person.totalWithdrawn += value;
              _LP.transfer(deployerAdd, value);
              emit LPWithdrawn(deployerAdd, uint32(block.timestamp), value);
              return true;
          }

        }
        else{
            return false;
        }
        return false;
    }

    function checkUserTokenBal(address userAdd) external view returns(uint256){
        return token.balanceOf(userAdd);
    }

    function checkUserLpBal(address userAdd) external view returns(uint256){
        return _LP.balanceOf(userAdd);
    }

    function checkContractTokenBal() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    function checkContractLpBal() external view returns(uint256){
        return _LP.balanceOf(address(this));
    }

    // withdraw BNB from contract
    function withdrawBNB() external onlyOwner() returns (bool){
        require(address(this).balance > 0);
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }

}