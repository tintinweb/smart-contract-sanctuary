/**
 *Submitted for verification at BscScan.com on 2021-08-07
*/

/**
 * https://bscscan.com/address/0x1eb03906458b30c8c0d65b124b0d69b853893b2b#code
 * Submitted for verification at BscScan.com on 2021-07-26
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC202 {
    function approve(address spender, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

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

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
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
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

contract LockToken is Ownable, IERC202 {
    using SafeMath for uint256;
    using Address for address;

    struct LockItem {
        uint256 id;
        address tokenAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 unlockTime;
        bool isWithdraw;
    }

    uint256 public lockId;
    uint256[] public allLockIds;
    mapping(address => uint256[]) public locksByWithdrawalAddress;
    mapping(uint256 => LockItem) public lockedToken;
    mapping(address => mapping(address => uint256)) public walletTokenBalance;
    uint256 public fee = 0.05 ether;

    event WithdrawToken(address receiveAddress, address tokenAddress, uint256 receiveAmount, uint256 id, uint256 unlockTime);
    event LockTokenItem(uint256 id, address tokenAddress, address withdrawAddress, uint256 amount, uint256 unlockTime);
    event TransferLocks(address fromAddress, address toAddress, address tokenAddress, uint256 id, uint256 amount);
    event ExtendLockDuration(address extendAddress, address tokenAddress, uint256 id, uint256 oldUnlockTime, uint256 newUnlockTime);
    event SetFee(uint256 oldValue, uint256 newValue);

    function approve(address spender, uint256 amount) public override returns (bool) {
        emit Approval(_msgSender(), spender, amount);
        return true;
    }
    

    /* Lock token */
    function lockToken(address _tokenAddress, address _withdrawalAddress, uint256 _amount, uint256 _unlockTime) public payable returns (uint256 _id) {
        require(msg.value == fee, "Please pay the fee");
        require(_amount > 0, "Invalid amount");
        //require(_unlockTime < 10000000000 && _unlockTime > block.timestamp, "Invalid unlock time");

        // Update balance in address
        walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amount);

        _id = ++lockId;

        LockItem memory newLockItem = LockItem({
        id : _id,
        tokenAddress : _tokenAddress,
        withdrawalAddress : _withdrawalAddress,
        tokenAmount : _amount,
        unlockTime : _unlockTime,
        isWithdraw : false
        });
        lockedToken[_id] = newLockItem;

        allLockIds.push(_id);
        locksByWithdrawalAddress[_withdrawalAddress].push(_id);

        // Transfer token into contract
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), "Cannot transfer token");
        emit LockTokenItem(_id, _tokenAddress, _withdrawalAddress, _amount, _unlockTime);
    }

    /* Multiple lock token */
    function multipleLockToken(address _tokenAddress, address _withdrawalAddress, uint256[] memory _amounts, uint256[] memory _unlockTimes) public payable returns (uint256 _id) {
        require(_amounts.length > 0);
        require(_amounts.length == _unlockTimes.length);
        uint256 requestNumber = _amounts.length;
        uint256 feeRequired = fee * requestNumber;
        if (requestNumber > 1) {
            uint256 discount = feeRequired.div(10);
            feeRequired = feeRequired.sub(discount);
        }
        require(msg.value == feeRequired, "Please pay the fee");

        for (uint256 i = 0; i < requestNumber; i++) {
            require(_amounts[i] > 0, "Invalid amount");
            require(_unlockTimes[i] < 10000000000 && _unlockTimes[i] > block.timestamp, "Invalid unlock time");

            // Update balance in address
            walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(_amounts[i]);

            _id = ++lockId;

            LockItem memory newLockItem = LockItem({
            id : _id,
            tokenAddress : _tokenAddress,
            withdrawalAddress : _withdrawalAddress,
            tokenAmount : _amounts[i],
            unlockTime : _unlockTimes[i],
            isWithdraw : false
            });
            lockedToken[_id] = newLockItem;

            allLockIds.push(_id);
            locksByWithdrawalAddress[_withdrawalAddress].push(_id);

            // Transfer token into contract
            require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amounts[i]));
            emit LockTokenItem(_id, _tokenAddress, _withdrawalAddress, _amounts[i], _unlockTimes[i]);
        }
    }

    /* Extend lock Duration */
    function extendLockDuration(uint256 _id, uint256 _unlockTime) public {
        LockItem storage lockedTokenItem = getLockTokenItem(_id);
        require(_unlockTime < 10000000000);
        require(_unlockTime > lockedTokenItem.unlockTime);
        require(!lockedTokenItem.isWithdraw);
        require(msg.sender == lockedTokenItem.withdrawalAddress);
        uint256 oldUnlockTime = lockedTokenItem.unlockTime;
        // Update new unlock time
        lockedTokenItem.unlockTime = _unlockTime;
        emit ExtendLockDuration(msg.sender, lockedTokenItem.tokenAddress, _id, oldUnlockTime, _unlockTime);
    }

    /* Transfer locked token */
    function transferLocks(uint256 _id, address _receiverAddress) public {
        LockItem storage lockedTokenItem = getLockTokenItem(_id);
        require(!lockedTokenItem.isWithdraw);
        require(msg.sender == lockedTokenItem.withdrawalAddress);
        // Decrease sender's token balance
        walletTokenBalance[lockedTokenItem.tokenAddress][msg.sender] = walletTokenBalance[lockedTokenItem.tokenAddress][msg.sender].sub(lockedTokenItem.tokenAmount);

        // Increase receiver's token balance
        walletTokenBalance[lockedTokenItem.tokenAddress][_receiverAddress] = walletTokenBalance[lockedTokenItem.tokenAddress][_receiverAddress].add(lockedTokenItem.tokenAmount);

        // Remove this id from this address
        uint256 lockLength = locksByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;
        for (uint256 i = 0; i < lockLength; i++) {
            if (locksByWithdrawalAddress[lockedTokenItem.withdrawalAddress][i] == _id) {
                delete locksByWithdrawalAddress[lockedTokenItem.withdrawalAddress][i];
                break;
            }
        }

        // Assign this id to receiver address
        lockedTokenItem.withdrawalAddress = _receiverAddress;
        locksByWithdrawalAddress[_receiverAddress].push(_id);
        emit TransferLocks(msg.sender, _receiverAddress, lockedTokenItem.tokenAddress, _id, lockedTokenItem.tokenAmount);
    }

    /* Withdraw token */
    function withdrawToken(uint256 _id) public {
        LockItem storage lockedTokenItem = getLockTokenItem(_id);
        //require(block.timestamp >= lockedTokenItem.unlockTime);
        require(msg.sender == lockedTokenItem.withdrawalAddress);
        require(!lockedTokenItem.isWithdraw);
        lockedTokenItem.isWithdraw = true;

        // Update balance in address
        walletTokenBalance[lockedTokenItem.tokenAddress][msg.sender] = walletTokenBalance[lockedTokenItem.tokenAddress][msg.sender].sub(lockedTokenItem.tokenAmount);

        // Remove this id from this address
        uint256 lockLength = locksByWithdrawalAddress[lockedToken[_id].withdrawalAddress].length;
        for (uint256 i = 0; i < lockLength; i++) {
            if (locksByWithdrawalAddress[lockedTokenItem.withdrawalAddress][i] == _id) {
                delete locksByWithdrawalAddress[lockedTokenItem.withdrawalAddress][i];
                break;
            }
        }

        // Transfer token to wallet address
        require(IERC20(lockedTokenItem.tokenAddress).transfer(msg.sender, lockedTokenItem.tokenAmount));
        emit WithdrawToken(msg.sender, lockedTokenItem.tokenAddress, lockedTokenItem.tokenAmount, _id, lockedTokenItem.unlockTime);
    }

    /* Get Total Token Balance By Contract */
    function getTotalTokenBalance(address _tokenAddress) view public returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    /* Get Token Balance By Address */
    function getTokenBalanceByAddress(address _tokenAddress, address _walletAddress) view public returns (uint256) {
        return walletTokenBalance[_tokenAddress][_walletAddress];
    }

    /* Get All Lock Ids */
    function getAllLockIds() view public returns (uint256[] memory) {
        return allLockIds;
    }

    /* Get Lock Detail By Id */
    function getLockDetails(uint256 _id) view public returns (address _tokenAddress, address _withdrawalAddress, uint256 _tokenAmount, uint256 _unlockTime, bool _isWithdraw) {
        return (lockedToken[_id].tokenAddress, lockedToken[_id].withdrawalAddress, lockedToken[_id].tokenAmount, lockedToken[_id].unlockTime, lockedToken[_id].isWithdraw);
    }

    /* Get Lock By Withdrawal Address */
    function getLocksByWithdrawalAddress(address _withdrawalAddress) view public returns (uint256[] memory) {
        return locksByWithdrawalAddress[_withdrawalAddress];
    }

    /* Get Lock Token Item By Id */
    function getLockTokenItem(uint256 id) view private returns (LockItem storage) {
        return lockedToken[id];
    }

    fallback() payable external {}

    receive() payable external {}

    /* Retrieve main balance */
    function retrieveMainBalance() public onlyOwner() {
        uint256 mainBalance = address(this).balance;
        require(mainBalance > 0, "Nothing to retrieve");
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    /* Set Fee */
    function setFee(uint256 _fee) public onlyOwner() {
        uint256 oldValue = fee;
        fee = _fee;
        emit SetFee(oldValue, fee);
    }

}