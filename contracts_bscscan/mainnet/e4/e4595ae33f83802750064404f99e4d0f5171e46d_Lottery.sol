// SPDX-Licence-Identifier: MIT 


pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./LotteryNFT.sol";


contract LotteryOwnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
    }

    function initOwner(address owner) internal {
        _owner = owner;
        emit OwnershipTransferred(address(0), owner);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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



/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// import "@nomiclabs/buidler/console.sol";

// 4 numbers
contract Lottery is LotteryOwnable, Initializable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeERC20 for IERC20;

    uint8 constant keyLengthForEachBuy = 11;
    // Allocation for first/sencond/third reward
    uint8[3] public allocation;
    // The TOKEN to buy lottery
    IERC20 public zinarix;
    // The Lottery NFT for tickets
    LotteryNFT public lotteryNFT;
    // adminAddress
    address public adminAddress;
    // maxNumber
    uint8 public maxNumber;
    // minPrice, if decimal is not 18, please reset it
    uint256 public minPrice;

    // =================================

    // issueId => winningNumbers[numbers]
    mapping (uint256 => uint8[4]) public historyNumbers;
    // issueId => [tokenId]
    mapping (uint256 => uint256[]) public lotteryInfo;
    // issueId => [totalAmount, firstMatchAmount, secondMatchingAmount, thirdMatchingAmount]
    mapping (uint256 => uint256[]) public historyAmount;
    // issueId => trickyNumber => buyAmountSum
    mapping (uint256 => mapping(uint64 => uint256)) public userBuyAmountSum;
    // address => [tokenId]
    mapping (address => uint256[]) public userInfo;

    uint256 public issueIndex = 0;
    uint256 public totalAddresses = 0;
    uint256 public totalAmount = 0;
    uint256 public lastTimestamp;

    uint8[4] public winningNumbers;

    // default false
    bool public drawingPhase;

    // =================================

    event Buy(address indexed user, uint256 tokenId);
    event Drawing(uint256 indexed issueIndex, uint8[4] winningNumbers);
    event Claim(address indexed user, uint256 tokenid, uint256 amount);
    event DevWithdraw(address indexed user, uint256 amount);
    event Reset(uint256 indexed issueIndex);
    event MultiClaim(address indexed user, uint256 amount);
    event MultiBuy(address indexed user, uint256 amount);

    constructor() public {
    }

    function initialize(
        IERC20 _zinarix,
        LotteryNFT _lottery,
        uint256 _minPrice,
        uint8 _maxNumber,
        address _owner,
        address _adminAddress
    ) public initializer {
        zinarix = _zinarix;
        lotteryNFT = _lottery;
        minPrice = _minPrice;
        maxNumber = _maxNumber;
        adminAddress = _adminAddress;
        lastTimestamp = block.timestamp;
        allocation = [60, 20, 10];
        initOwner(_owner);
    }

    uint8[4] private nullTicket = [0,0,0,0];

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    function drawed() public view returns(bool) {
        return winningNumbers[0] != 0;
    }

    function reset() external onlyAdmin {
        require(drawed(), "drawed?");
        lastTimestamp = block.timestamp;
        totalAddresses = 0;
        totalAmount = 0;
        winningNumbers[0]=0;
        winningNumbers[1]=0;
        winningNumbers[2]=0;
        winningNumbers[3]=0;
        drawingPhase = false;
        issueIndex = issueIndex +1;
        if(getMatchingRewardAmount(issueIndex-1, 4) == 0) {
            uint256 amount = getTotalRewards(issueIndex-1).mul(allocation[0]).div(100);
            internalBuy(amount, nullTicket);
        }
        emit Reset(issueIndex);
    }

    function enterDrawingPhase() external onlyAdmin {
        require(!drawed(), 'drawed');
        drawingPhase = true;
    }

    // add externalRandomNumber to prevent node validators exploiting
    function drawing(uint256 _externalRandomNumber) external onlyAdmin {
        require(!drawed(), "reset?");
        require(drawingPhase, "enter drawing phase first");
        bytes32 _structHash;
        uint256 _randomNumber;
        uint8 _maxNumber = maxNumber;
        bytes32 _blockhash = blockhash(block.number-1);

        // waste some gas fee here
        for (uint i = 0; i < 10; i++) {
            getTotalRewards(issueIndex);
        }
        uint256 gasleft = gasleft();

        // 1
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                totalAddresses,
                gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[0]=uint8(_randomNumber);

        // 2
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                totalAmount,
                gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[1]=uint8(_randomNumber);

        // 3
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                lastTimestamp,
                gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[2]=uint8(_randomNumber);

        // 4
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                gasleft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[3]=uint8(_randomNumber);
        historyNumbers[issueIndex] = winningNumbers;
        historyAmount[issueIndex] = calculateMatchingRewardAmount();
        drawingPhase = false;
        emit Drawing(issueIndex, winningNumbers);
    }

    function internalBuy(uint256 _price, uint8[4] memory _numbers) internal {
        require (!drawed(), 'drawed, can not buy now');
        for (uint i = 0; i < 4; i++) {
            require (_numbers[i] <= maxNumber, 'exceed the maximum');
        }
        uint256 tokenId = lotteryNFT.newLotteryItem(address(this), _numbers, _price, issueIndex);
        lotteryInfo[issueIndex].push(tokenId);
        totalAmount = totalAmount.add(_price);
        lastTimestamp = block.timestamp;
        emit Buy(address(this), tokenId);

    }

    function buy(uint256 _price, uint8[4] memory _numbers) external {
        require(!drawed(), 'drawed, can not buy now');
        require(!drawingPhase, 'drawing, can not buy now');
        require (_price >= minPrice, 'price must above minPrice');
        for (uint i = 0; i < 4; i++) {
            require (_numbers[i] <= maxNumber, 'exceed number scope');
        }
        uint256 tokenId = lotteryNFT.newLotteryItem(msg.sender, _numbers, _price, issueIndex);
        lotteryInfo[issueIndex].push(tokenId);
        if (userInfo[msg.sender].length == 0) {
            totalAddresses = totalAddresses + 1;
        }
        userInfo[msg.sender].push(tokenId);
        totalAmount = totalAmount.add(_price);
        lastTimestamp = block.timestamp;
        uint64[keyLengthForEachBuy] memory userNumberIndex = generateNumberIndexKey(_numbers);
        for (uint i = 0; i < keyLengthForEachBuy; i++) {
            userBuyAmountSum[issueIndex][userNumberIndex[i]]=userBuyAmountSum[issueIndex][userNumberIndex[i]].add(_price);
        }
        zinarix.safeTransferFrom(address(msg.sender), address(this), _price);
        emit Buy(msg.sender, tokenId);
    }

    function  multiBuy(uint256 _price, uint8[4][] memory _numbers) external {
        require (!drawed(), 'drawed, can not buy now');
        require(!drawingPhase, 'drawing, can not buy now');
        require (_price >= minPrice, 'price must above minPrice');
        uint256 totalPrice  = 0;
        for (uint i = 0; i < _numbers.length; i++) {
            for (uint j = 0; j < 4; j++) {
                require (_numbers[i][j] <= maxNumber && _numbers[i][j] > 0, 'exceed number scope');
            }
            uint256 tokenId = lotteryNFT.newLotteryItem(msg.sender, _numbers[i], _price, issueIndex);
            lotteryInfo[issueIndex].push(tokenId);
            if (userInfo[msg.sender].length == 0) {
                totalAddresses = totalAddresses + 1;
            }
            userInfo[msg.sender].push(tokenId);
            totalAmount = totalAmount.add(_price);
            lastTimestamp = block.timestamp;
            totalPrice = totalPrice.add(_price);
            uint64[keyLengthForEachBuy] memory numberIndexKey = generateNumberIndexKey(_numbers[i]);
            for (uint k = 0; k < keyLengthForEachBuy; k++) {
                userBuyAmountSum[issueIndex][numberIndexKey[k]]=userBuyAmountSum[issueIndex][numberIndexKey[k]].add(_price);
            }
        }
        zinarix.safeTransferFrom(address(msg.sender), address(this), totalPrice);
        emit MultiBuy(msg.sender, totalPrice);
    }

    function claimReward(uint256 _tokenId) external {
        require(msg.sender == lotteryNFT.ownerOf(_tokenId), "not from owner");
        require (!lotteryNFT.getClaimStatus(_tokenId), "claimed");
        uint256 reward = getRewardView(_tokenId);
        lotteryNFT.claimReward(_tokenId);
        if(reward>0) {
            zinarix.safeTransfer(address(msg.sender), reward);
        }
        emit Claim(msg.sender, _tokenId, reward);
    }

    function  multiClaim(uint256[] memory _tickets) external {
        uint256 totalReward = 0;
        for (uint i = 0; i < _tickets.length; i++) {
            require (msg.sender == lotteryNFT.ownerOf(_tickets[i]), "not from owner");
            require (!lotteryNFT.getClaimStatus(_tickets[i]), "claimed");
            uint256 reward = getRewardView(_tickets[i]);
            if(reward>0) {
                totalReward = reward.add(totalReward);
            }
        }
        lotteryNFT.multiClaimReward(_tickets);
        if(totalReward>0) {
            zinarix.safeTransfer(address(msg.sender), totalReward);
        }
        emit MultiClaim(msg.sender, totalReward);
    }

    function generateNumberIndexKey(uint8[4] memory number) public pure returns (uint64[keyLengthForEachBuy] memory) {
        uint64[4] memory tempNumber;
        tempNumber[0]=uint64(number[0]);
        tempNumber[1]=uint64(number[1]);
        tempNumber[2]=uint64(number[2]);
        tempNumber[3]=uint64(number[3]);

        uint64[keyLengthForEachBuy] memory result;
        result[0] = tempNumber[0]*256*256*256*256*256*256 + 1*256*256*256*256*256 + tempNumber[1]*256*256*256*256 + 2*256*256*256 + tempNumber[2]*256*256 + 3*256 + tempNumber[3];

        result[1] = tempNumber[0]*256*256*256*256 + 1*256*256*256 + tempNumber[1]*256*256 + 2*256+ tempNumber[2];
        result[2] = tempNumber[0]*256*256*256*256 + 1*256*256*256 + tempNumber[1]*256*256 + 3*256+ tempNumber[3];
        result[3] = tempNumber[0]*256*256*256*256 + 2*256*256*256 + tempNumber[2]*256*256 + 3*256 + tempNumber[3];
        result[4] = 1*256*256*256*256*256 + tempNumber[1]*256*256*256*256 + 2*256*256*256 + tempNumber[2]*256*256 + 3*256 + tempNumber[3];

        result[5] = tempNumber[0]*256*256 + 1*256+ tempNumber[1];
        result[6] = tempNumber[0]*256*256 + 2*256+ tempNumber[2];
        result[7] = tempNumber[0]*256*256 + 3*256+ tempNumber[3];
        result[8] = 1*256*256*256 + tempNumber[1]*256*256 + 2*256 + tempNumber[2];
        result[9] = 1*256*256*256 + tempNumber[1]*256*256 + 3*256 + tempNumber[3];
        result[10] = 2*256*256*256 + tempNumber[2]*256*256 + 3*256 + tempNumber[3];

        return result;
    }

    function calculateMatchingRewardAmount() internal view returns (uint256[4] memory) {
        uint64[keyLengthForEachBuy] memory numberIndexKey = generateNumberIndexKey(winningNumbers);

        uint256 totalAmout1 = userBuyAmountSum[issueIndex][numberIndexKey[0]];

        uint256 sumForTotalAmout2 = userBuyAmountSum[issueIndex][numberIndexKey[1]];
        sumForTotalAmout2 = sumForTotalAmout2.add(userBuyAmountSum[issueIndex][numberIndexKey[2]]);
        sumForTotalAmout2 = sumForTotalAmout2.add(userBuyAmountSum[issueIndex][numberIndexKey[3]]);
        sumForTotalAmout2 = sumForTotalAmout2.add(userBuyAmountSum[issueIndex][numberIndexKey[4]]);

        uint256 totalAmout2 = sumForTotalAmout2.sub(totalAmout1.mul(4));

        uint256 sumForTotalAmout3 = userBuyAmountSum[issueIndex][numberIndexKey[5]];
        sumForTotalAmout3 = sumForTotalAmout3.add(userBuyAmountSum[issueIndex][numberIndexKey[6]]);
        sumForTotalAmout3 = sumForTotalAmout3.add(userBuyAmountSum[issueIndex][numberIndexKey[7]]);
        sumForTotalAmout3 = sumForTotalAmout3.add(userBuyAmountSum[issueIndex][numberIndexKey[8]]);
        sumForTotalAmout3 = sumForTotalAmout3.add(userBuyAmountSum[issueIndex][numberIndexKey[9]]);
        sumForTotalAmout3 = sumForTotalAmout3.add(userBuyAmountSum[issueIndex][numberIndexKey[10]]);

        uint256 totalAmout3 = sumForTotalAmout3.add(totalAmout1.mul(6)).sub(sumForTotalAmout2.mul(3));

        return [totalAmount, totalAmout1, totalAmout2, totalAmout3];
    }

    function getMatchingRewardAmount(uint256 _issueIndex, uint256 _matchingNumber) public view returns (uint256) {
        return historyAmount[_issueIndex][5 - _matchingNumber];
    }

    function getTotalRewards(uint256 _issueIndex) public view returns(uint256) {
        require (_issueIndex <= issueIndex, '_issueIndex <= issueIndex');

        if(!drawed() && _issueIndex == issueIndex) {
            return totalAmount;
        }
        return historyAmount[_issueIndex][0];
    }

    function getRewardView(uint256 _tokenId) public view returns(uint256) {
        uint256 _issueIndex = lotteryNFT.getLotteryIssueIndex(_tokenId);
        uint8[4] memory lotteryNumbers = lotteryNFT.getLotteryNumbers(_tokenId);
        uint8[4] memory _winningNumbers = historyNumbers[_issueIndex];
        require(_winningNumbers[0] != 0, "not drawed");

        uint256 matchingNumber = 0;
        for (uint i = 0; i < lotteryNumbers.length; i++) {
            if (_winningNumbers[i] == lotteryNumbers[i]) {
                matchingNumber= matchingNumber +1;
            }
        }
        uint256 reward = 0;
        if (matchingNumber > 1) {
            uint256 amount = lotteryNFT.getLotteryAmount(_tokenId);
            uint256 poolAmount = getTotalRewards(_issueIndex).mul(allocation[4-matchingNumber]).div(100);
            reward = amount.mul(1e12).div(getMatchingRewardAmount(_issueIndex, matchingNumber)).mul(poolAmount);
        }
        return reward.div(1e12);
    }


    // Update admin address by the previous dev.
    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function adminWithdraw(uint256 _amount) public onlyAdmin {
        zinarix.safeTransfer(address(msg.sender), _amount);
        emit DevWithdraw(msg.sender, _amount);
    }

    // Set the minimum price for one ticket
    function setMinPrice(uint256 _price) external onlyAdmin {
        minPrice = _price;
    }

    // Set the minimum price for one ticket
    function setMaxNumber(uint8 _maxNumber) external onlyAdmin {
        maxNumber = _maxNumber;
    }

    // Set the allocation for one reward
    function setAllocation(uint8 _allcation1, uint8 _allcation2, uint8 _allcation3) external onlyAdmin {
        allocation = [_allcation1, _allcation2, _allcation3];
    }

}