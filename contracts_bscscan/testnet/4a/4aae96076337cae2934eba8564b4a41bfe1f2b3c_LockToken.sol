//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";

interface ILockSetting {
    function getWhitelistFeeTokenLength() external view returns (uint256);

    function getBaseFee() external view returns (uint256);

    function getTokenFee() external view returns (uint256);

    function getAddressFee() external view returns (address payable);

    function userHoldSufficientWhitelistToken(address _user) external view returns (bool);

    function getWhitelistAddressStatus(address _user) external view returns (bool);
}

contract LockToken is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    ILockSetting public LOCK_SETTING;

    struct FeeItem {
        uint256 baseFee;
        uint256 tokenFeePercent;
        uint256 tokenFeeAmount;
        uint256 realTokenAmount;
        address addressFee;
        bool needToPayFee;
        bool whitelistAddress;
        bool holdWhitelistToken;
    }

    /* Lock Token Item Structure */
    struct LockItem {
        uint256 id;
        address tokenAddress;
        address lockAddress;
        address withdrawalAddress;
        uint256 tokenAmount;
        uint256 lockTime;
        uint256 unlockTime;
        uint256 withdrawTime;
        bool isPayFee;
        uint256 baseFee;
        uint256 tokenFeePercent;
        uint256 tokenFeeAmount;
        uint256 realTokenAmount;
        bool isWithdraw;
    }

    uint256 public lockId;
    uint256[] public allLockIds;
    mapping(address => uint256[]) public locksByWithdrawalAddress;
    mapping(uint256 => LockItem) public lockedToken;
    mapping(address => mapping(address => uint256)) public walletTokenBalance;

    constructor () {
        LOCK_SETTING = ILockSetting(0x0565b899809dC371845a62e45B8D14c9Cb2f9088);
    }

    event LockTokenItem(
        uint256 id,
        address tokenAddress,
        address lockAddress,
        address withdrawAddress,
        uint256 tokenAmount,
        uint256 lockTime,
        uint256 unlockTime,
        bool needToPayFee,
        uint256 baseFee,
        uint256 tokenFeePercent,
        uint256 tokenFeeAmount,
        uint256 realTokenAmount
    );
    event WithdrawToken(address receiveAddress, address tokenAddress, uint256 tokenAmount, uint256 receiveAmount, uint256 id, uint256 unlockTime);
    event TransferLock(address fromAddress, address toAddress, address tokenAddress, uint256 id, uint256 amount);
    event ExtendLockDuration(address extendAddress, address tokenAddress, uint256 id, uint256 oldUnlockTime, uint256 newUnlockTime);
    event SetFee(uint256 oldValue, uint256 newValue);
    event SetDiscountPercent(uint256 oldValue, uint256 newValue);
    event UpdateWhitelistAddress(address indexed user, bool status);
    event UpdateFeeReceiveAddress(address indexed oldAddress, address indexed newAddress);
    event RetrieveBalance(address indexed receiveAddress, uint256 value);

    /* Lock token */
    function lockToken(address _tokenAddress, address _withdrawalAddress, uint256 _amount, uint256 _unlockTime) public payable {

        require(_amount > 0, "Invalid amount");
        require(_unlockTime < 1e10 && _unlockTime > block.timestamp, "Invalid unlock time");

        FeeItem memory feeItem = checkToPayFee(_amount);
        if (feeItem.needToPayFee) {
            if (feeItem.baseFee > 0) {
                require(msg.value == feeItem.baseFee, "Please pay the fee");
                payable(feeItem.addressFee).transfer(msg.value);
            } else {
                payable(msg.sender).transfer(msg.value);
            }
        } else {
            // Refund if whitelist send fee
            if (msg.value > 0) {
                payable(msg.sender).transfer(msg.value);
            }
        }

        // Update balance in address
        walletTokenBalance[_tokenAddress][_withdrawalAddress] = walletTokenBalance[_tokenAddress][_withdrawalAddress].add(feeItem.realTokenAmount);

        uint256 _id = ++lockId;
        LockItem memory newLockItem = LockItem({
        id : _id,
        tokenAddress : _tokenAddress,
        lockAddress : msg.sender,
        withdrawalAddress : _withdrawalAddress,
        tokenAmount : _amount,
        lockTime : block.timestamp,
        unlockTime : _unlockTime,
        withdrawTime : 0,
        isPayFee : feeItem.needToPayFee,
        baseFee : feeItem.baseFee,
        tokenFeePercent : feeItem.tokenFeePercent,
        tokenFeeAmount : feeItem.tokenFeeAmount,
        realTokenAmount : feeItem.realTokenAmount,
        isWithdraw : false
        });
        lockedToken[_id] = newLockItem;

        allLockIds.push(_id);
        locksByWithdrawalAddress[_withdrawalAddress].push(_id);

        // Transfer token into contract
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount), "Cannot transfer token");
        if (feeItem.tokenFeeAmount > 0) {
            require(IERC20(_tokenAddress).transfer(feeItem.addressFee, feeItem.tokenFeeAmount), "Cannot transfer fee token");
        }
        emit LockTokenItem(
            _id,
            _tokenAddress,
            msg.sender,
            _withdrawalAddress,
            _amount,
            block.timestamp,
            _unlockTime,
            feeItem.needToPayFee,
            feeItem.baseFee,
            feeItem.tokenFeePercent,
            feeItem.tokenFeeAmount,
            feeItem.realTokenAmount
        );
    }

    function checkToPayFee(uint256 _amount) private view returns (FeeItem memory){

        bool isWhitelistAddress = LOCK_SETTING.getWhitelistAddressStatus(msg.sender);
        bool isHoldWhitelistToken = false;
        if (LOCK_SETTING.getWhitelistFeeTokenLength() > 0) {
            isHoldWhitelistToken = LOCK_SETTING.userHoldSufficientWhitelistToken(msg.sender);
        }

        bool needToPayFee = true;
        if (isWhitelistAddress || isHoldWhitelistToken) {
            needToPayFee = false;
        }

        uint256 tokenFeePercent = LOCK_SETTING.getTokenFee();
        uint256 tokenFeeAmount = 0;
        if (tokenFeePercent > 0) {
            tokenFeeAmount = _amount.mul(tokenFeePercent).div(1000);
        }

        uint realTokenAmount = _amount.sub(tokenFeeAmount);

        FeeItem memory feeItem = FeeItem({
        baseFee : LOCK_SETTING.getBaseFee(),
        tokenFeePercent : tokenFeePercent,
        tokenFeeAmount : tokenFeeAmount,
        realTokenAmount : realTokenAmount,
        addressFee : payable(LOCK_SETTING.getAddressFee()),
        needToPayFee : needToPayFee,
        whitelistAddress : isWhitelistAddress,
        holdWhitelistToken : isHoldWhitelistToken
        });

        return feeItem;
    }

    /* Extend lock Duration */
    function extendLockDuration(uint256 _id, uint256 _unlockTime) public {
        LockItem storage lockedTokenItem = getLockTokenItem(_id);
        require(_unlockTime < 1e10, "Invalid unlock time");
        require(_unlockTime > lockedTokenItem.unlockTime, "New unlock time is less than old unlock time");
        require(!lockedTokenItem.isWithdraw, "Lock is withdrawn");
        require(msg.sender == lockedTokenItem.withdrawalAddress, "Invalid withdraw address");
        uint256 oldUnlockTime = lockedTokenItem.unlockTime;
        // Update new unlock time
        lockedTokenItem.unlockTime = _unlockTime;
        emit ExtendLockDuration(msg.sender, lockedTokenItem.tokenAddress, _id, oldUnlockTime, _unlockTime);
    }

    /* Transfer locked token */
    function transferLock(uint256 _id, address _receiverAddress) public {
        LockItem storage lockedTokenItem = getLockTokenItem(_id);
        require(!lockedTokenItem.isWithdraw, "Lock is withdrawn");
        require(msg.sender == lockedTokenItem.withdrawalAddress, "Invalid withdraw address");
        address tokenAddress = lockedTokenItem.tokenAddress;
        uint256 realTokenAmount = lockedTokenItem.realTokenAmount;

        // Decrease sender's token balance
        walletTokenBalance[lockedTokenItem.tokenAddress][msg.sender] = walletTokenBalance[tokenAddress][msg.sender].sub(realTokenAmount);

        // Increase receiver's token balance
        walletTokenBalance[tokenAddress][_receiverAddress] = walletTokenBalance[tokenAddress][_receiverAddress].add(realTokenAmount);

        // Remove this id from this address
        uint256[] storage listAddressLockId = locksByWithdrawalAddress[msg.sender];
        uint256 lockByAddressLength = listAddressLockId.length;
        for (uint256 i = 0; i < lockByAddressLength; i++) {
            if (listAddressLockId[i] == _id) {
                listAddressLockId[i] = listAddressLockId[lockByAddressLength - 1];
                listAddressLockId.pop();
                break;
            }
        }

        // Assign this id to receiver address
        lockedTokenItem.withdrawalAddress = _receiverAddress;
        locksByWithdrawalAddress[_receiverAddress].push(_id);
        emit TransferLock(msg.sender, _receiverAddress, tokenAddress, _id, realTokenAmount);
    }

    /* Withdraw token */
    function withdrawToken(uint256 _id) public {
        LockItem storage lockedTokenItem = getLockTokenItem(_id);
        require(block.timestamp >= lockedTokenItem.unlockTime, "Invalid unlock time");
        require(msg.sender == lockedTokenItem.withdrawalAddress, "Invalid withdraw address");
        require(!lockedTokenItem.isWithdraw, "Lock is withdrawn");
        lockedTokenItem.isWithdraw = true;
        lockedTokenItem.withdrawTime = block.timestamp;
        address tokenAddress = lockedTokenItem.tokenAddress;
        uint256 tokenAmount = lockedTokenItem.tokenAmount;
        uint256 realTokenAmount = lockedTokenItem.realTokenAmount;

        // Update balance in address
        walletTokenBalance[tokenAddress][msg.sender] = walletTokenBalance[tokenAddress][msg.sender].sub(realTokenAmount);

        // Remove this id from this address
        uint256[] storage listAddressLockId = locksByWithdrawalAddress[msg.sender];
        uint256 lockByAddressLength = listAddressLockId.length;
        for (uint256 i = 0; i < lockByAddressLength; i++) {
            if (listAddressLockId[i] == _id) {
                listAddressLockId[i] = listAddressLockId[lockByAddressLength - 1];
                listAddressLockId.pop();
                break;
            }
        }

        // Transfer token to wallet address
        require(IERC20(tokenAddress).transfer(msg.sender, realTokenAmount), "Cannot transfer token");
        emit WithdrawToken(msg.sender, tokenAddress, tokenAmount, realTokenAmount, _id, lockedTokenItem.unlockTime);
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
    function getLockDetail(uint256 _id) view public returns (LockItem memory) {
        return lockedToken[_id];
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
        address payable addressFee = payable(LOCK_SETTING.getAddressFee());
        addressFee.transfer(mainBalance);
        emit RetrieveBalance(addressFee, mainBalance);
    }

}