/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract Utils is ReentrancyGuard {
    function _takeAsset (
        address tokenAddress, address fromAddress, uint256 amount
    ) internal returns (bool) {
        require(tokenAddress != address(0), 'Token address should not be zero');
        IERC20 tokenContract = IERC20(tokenAddress);

        tokenContract.transferFrom(fromAddress, address(this), amount);

        return true;
    }

    function _sendAsset (
        address tokenAddress, address toAddress, uint256 amount
    ) internal nonReentrant returns (bool) {
        if (tokenAddress == address(0)) {
            require(address(this).balance >= amount,
                'Not enough contract balance');
            payable(toAddress).transfer(amount);
        } else {
            IERC20 tokenContract = IERC20(tokenAddress);
            tokenContract.transfer(toAddress, amount);
        }
        return true;
    }
}

contract Sale is Ownable, Utils {
    modifier onlyManager() {
        require(_managers[msg.sender], 'Caller is not the manager');
        _;
    }

    modifier purchaseAllowed() {
        require(block.timestamp >= _startTime, 'Sale is not started yet');
        require(!_isSaleOver(), 'Sale is over');
        if (_whitelistMode && block.timestamp < _whitelistEndTime) {
            require(
                _whitelist[msg.sender],
                'Available for whitelisted only when whitelist mode is on'
            );
        }
        _;
    }

    event Purchase(
        address indexed userAddress, uint256 indexed paymentProfileIndex,
        uint256 amount, uint256 tokenAmount
    );
    event Withdraw(
        address indexed userAddress, uint256 tokenAmount
    );

    struct PaymentProfile {
        address contractAddress;
        uint256 usdRate; // Asset rate in USD * 10000
        uint256 weight; // sorting order at UI (asc from left to right)
        uint256 totalPaid;  // total amount of tokens paid in this currency
        string name;
        string currency;
        bool active;
    }

    mapping (uint256 => PaymentProfile) internal _paymentProfiles;
    mapping (address => uint256) internal _paidTokenAmount;
    mapping (address => uint256) internal _withdrawnTokenAmount;
    mapping (address => bool) internal _whitelist;
    mapping (address => bool) internal _managers;

    address internal _tokenAddress;
    address internal _assetsReceiverAddress;
    uint256 internal _totalPaidTokenAmount;
    uint256 internal _totalWithdrawnTokenAmount;
    uint256 internal _paymentProfilesNumber;
    uint256 internal _maxTokenAmount;
    uint256 internal _tokenUsdRate; // 0xpad token USD rate * 10000
    uint256 internal _startTime; // timestamp of the sale start time
    uint256 internal _whitelistEndTime; // timestamp of the sale start time
    uint256 internal _endTime; // timestamp of the sale end time
    uint256 internal _salePoolSize; // maximum tokens amount to be sold
    uint256 _batchLimit = 100;
    bool internal _saleOver;
    bool internal _withdrawalAvailable;
    bool internal _whitelistMode = true;

    constructor (
        address newOwner,
        address assetsReceiverAddress,
        address tokenAddress,
        uint256 startTime,
        uint256 whitelistEndTime,
        uint256 endTime,
        uint256 tokenUsdRate,
        uint256 salePoolSize
    ) {
        require(startTime <= whitelistEndTime, 'startTime should be less or equal than whitelistEndTime');
        require(whitelistEndTime <= endTime, 'whitelistEndTime should be less or equal than endTime');
        require(endTime > block.timestamp, 'endTime should be in future');
        require(tokenUsdRate > 0, 'tokenUsdRate should be greater than zero');
        require(newOwner != address(0), 'Owner address can not be zero');
        require(assetsReceiverAddress != address(0), 'Assets receiver address can not be zero');
        require(tokenAddress != address(0), 'Token address can not be zero');
        _startTime = startTime;
        _whitelistEndTime = whitelistEndTime;
        _endTime = endTime;
        _tokenUsdRate = tokenUsdRate;
        transferOwnership(newOwner);
        _assetsReceiverAddress = assetsReceiverAddress;
        _tokenAddress = tokenAddress;
        _managers[newOwner] = true;
        _salePoolSize = salePoolSize;
    }

    /**
     * @dev Function accepts payments both in native currency and
     * in predefined erc20 tokens
     * Distributed token is accrued to the buyer's address to be withdrawn later
     */
    function purchase (
        uint256 paymentProfileIndex, uint256 amount
    ) external payable purchaseAllowed returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        require(
            _paymentProfiles[paymentProfileIndex].active,
            'This payment profile is blocked'
        );
        if (_paymentProfiles[paymentProfileIndex].contractAddress != address(0)) {
            require(amount > 0, 'amount for this payment profile should be greater than zero');
        } else {
            amount = msg.value;
            require(
                amount > 0,
                'Message value for this payment profile should be greater than zero'
            );
        }
        uint256 tokenAmount = _getTokenAmount(paymentProfileIndex, amount);
        require(tokenAmount > 0, 'Token amount can not be zero');

        require(
            tokenAmount + _totalPaidTokenAmount <= _salePoolSize,
            'Sale pool size exceeded'
        );
        require(
            _maxTokenAmount == 0 || (tokenAmount + _paidTokenAmount[msg.sender] <= _maxTokenAmount),
            'Max token amount exceeded'
        );
        if (_paymentProfiles[paymentProfileIndex].contractAddress != address(0)) {
            _takeAsset(
                _paymentProfiles[paymentProfileIndex].contractAddress,
                msg.sender,
                amount
            );
        }
        _sendAsset(
            _paymentProfiles[paymentProfileIndex].contractAddress,
            _assetsReceiverAddress,
            amount
        );
        _paidTokenAmount[msg.sender] += tokenAmount;
        _totalPaidTokenAmount += tokenAmount;
        _paymentProfiles[paymentProfileIndex].totalPaid += amount;
        emit Purchase(msg.sender, paymentProfileIndex, amount, tokenAmount);

        return true;
    }

    /**
     * @dev Function let users withdraw specified amount of distributed token
     * (amount that was paid for) when withdrawal is available
     */
    function withdrawTokens (
        uint256 tokenAmount
    ) external returns (bool) {
        require(_withdrawalAvailable, 'Withdrawal is not available');
        require(
            tokenAmount <= _getAvailableTokenAmount(msg.sender),
            'tokenAmount can not be greater than available token amount'
        );
        _withdrawnTokenAmount[msg.sender] += tokenAmount;
        _totalWithdrawnTokenAmount += tokenAmount;
        emit Withdraw(msg.sender, tokenAmount);
        _sendAsset(_tokenAddress, msg.sender, tokenAmount);
        return true;
    }

    /**
     * @dev Function let users withdraw distributed token (amount that was paid for)
     * when withdrawal is available
     */
    function withdrawAllTokens () external returns (bool) {
        require(_withdrawalAvailable, 'Withdrawal is not available');
        uint256 tokenAmount = _getAvailableTokenAmount(msg.sender);
        _withdrawnTokenAmount[msg.sender] += tokenAmount;
        _totalWithdrawnTokenAmount += tokenAmount;
        emit Withdraw(msg.sender, tokenAmount);
        _sendAsset(_tokenAddress, msg.sender, tokenAmount);
        return true;
    }

    // manager functions
    function addPaymentProfile (
        address contractAddress,
        uint256 usdRate,
        uint256 weight,
        string memory name,
        string memory currency
    ) external onlyManager returns (bool) {
        require(usdRate > 0, 'USD rate should be greater than zero');
        _paymentProfilesNumber ++;
        _paymentProfiles[_paymentProfilesNumber].contractAddress = contractAddress;
        _paymentProfiles[_paymentProfilesNumber].usdRate = usdRate;
        _paymentProfiles[_paymentProfilesNumber].weight = weight;
        _paymentProfiles[_paymentProfilesNumber].name = name;
        _paymentProfiles[_paymentProfilesNumber].currency = currency;
        _paymentProfiles[_paymentProfilesNumber].active = true;

        return true;
    }

    function setPaymentProfileUsdRate (
        uint256 paymentProfileIndex,
        uint256 usdRate
    ) external onlyManager returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        require(usdRate > 0, 'USD rate should be greater than zero');
        _paymentProfiles[paymentProfileIndex].usdRate = usdRate;
        return true;
    }

    function setPaymentProfileWeight (
        uint256 paymentProfileIndex,
        uint256 weight
    ) external onlyManager returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        _paymentProfiles[paymentProfileIndex].weight = weight;

        return true;
    }

    function setPaymentProfileName (
        uint256 paymentProfileIndex,
        string calldata name
    ) external onlyManager returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        _paymentProfiles[paymentProfileIndex].name = name;
        return true;
    }

    function setPaymentProfileCurrency (
        uint256 paymentProfileIndex,
        string calldata currency
    ) external onlyManager returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        _paymentProfiles[paymentProfileIndex].currency = currency;
        return true;
    }

    function setPaymentProfileStatus (
        uint256 paymentProfileIndex,
        bool active
    ) external onlyManager returns (bool) {
        require(
            paymentProfileIndex > 0 && paymentProfileIndex <= _paymentProfilesNumber,
            'Payment profile is not found'
        );
        _paymentProfiles[paymentProfileIndex].active = active;
        return true;
    }

    function setBatchLimit (
        uint256 batchLimit
    ) external onlyManager returns (bool) {
        require(batchLimit > 0, 'Batch limit should be greater than zero');
        _batchLimit = batchLimit;
        return true;
    }

    function setTokenUsdRate (uint256 tokenUsdRate) external onlyManager returns (bool) {
        require(tokenUsdRate > 0, 'Token USD rate should be greater than zero');
        _tokenUsdRate = tokenUsdRate;
        return true;
    }

    function setSalePoolSize (uint256 salePoolSize) external onlyManager returns (bool) {
        require(
            salePoolSize >= _totalPaidTokenAmount,
            'Sale pool size can not be less then paid token amount'
        );
        _salePoolSize = salePoolSize;
        return true;
    }

    function addToWhitelist (address userAddress) external onlyManager returns (bool) {
        _whitelist[userAddress] = true;
        return true;
    }

    function addToWhitelistMultiple (address[] calldata userAddresses) external onlyManager returns (bool) {
        for (uint256 i; i < userAddresses.length; i ++) {
            if (i >= _batchLimit) break;
            _whitelist[userAddresses[i]] = true;
        }
        return true;
    }

    function removeFromWhitelist (address userAddress) external onlyManager returns (bool) {
        _whitelist[userAddress] = false;
        return true;
    }

    function removeFromWhitelistMultiple (address[] calldata userAddresses) external onlyManager returns (bool) {
        for (uint256 i; i < userAddresses.length; i ++) {
            if (i >= _batchLimit) break;
            _whitelist[userAddresses[i]] = false;
        }
        return true;
    }

    function setMaxTokenAmount (uint256 maxTokenAmount) external onlyManager returns (bool) {
        _maxTokenAmount = maxTokenAmount;
        return true;
    }

    function setStartTime (uint256 startTime) external onlyManager returns (bool) {
        _startTime = startTime;
        return true;
    }

    function setWhitelistEndTime (uint256 whitelistEndTime) external onlyManager returns (bool) {
        _whitelistEndTime = whitelistEndTime;
        return true;
    }

    function setEndTime (uint256 endTime) external onlyManager returns (bool) {
        _endTime = endTime;
        return true;
    }

    function setWithdrawalAvailable (bool isTrue) external onlyManager returns (bool) {
        _withdrawalAvailable = isTrue;
        return true;
    }

    function setTokenAddress (
        address tokenAddress
    ) external onlyManager returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        _tokenAddress = tokenAddress;
        return true;
    }

    function setSaleOver (bool isTrue) external onlyManager returns (bool) {
        _saleOver = isTrue;
        return true;
    }

    function setWhitelistMode (bool isTrue) external onlyManager returns (bool) {
        _whitelistMode = isTrue;
        return true;
    }

    // admin functions
    function setAssetsReceiverAddress (
        address assetsReceiverAddress
    ) external onlyOwner returns (bool) {
        require(assetsReceiverAddress != address(0), 'Assets receiver address can not be zero');
        _assetsReceiverAddress = assetsReceiverAddress;
        return true;
    }

    function addToManagers (address userAddress) external onlyOwner returns (bool) {
        _managers[userAddress] = true;
        return true;
    }

    function removeFromManagers (address userAddress) external onlyOwner returns (bool) {
        _managers[userAddress] = false;
        return true;
    }

    // Zero contract address should be used for native currency withdrawing
    function adminWithdraw (
        address tokenAddress, uint256 amount
    ) external onlyOwner returns (bool) {
        _sendAsset(tokenAddress, msg.sender, amount);
        return true;
    }

    // view functions
    function getTokenAmount (
        uint256 paymentProfileIndex, uint256 amount
    ) external view returns (uint256) {
        return _getTokenAmount(paymentProfileIndex, amount);
    }

    function getAvailableTokenAmount (
        address userAddress
    ) external view returns (uint256) {
        return _getAvailableTokenAmount(userAddress);
    }

    function getPaidTokenAmount (
        address userAddress
    ) external view returns (uint256) {
        return _paidTokenAmount[userAddress];
    }

    function getWithdrawnTokenAmount (
        address userAddress
    ) external view returns (uint256) {
        return _withdrawnTokenAmount[userAddress];
    }

    function getTotalPaidTokenAmount () external view returns (uint256) {
        return _totalPaidTokenAmount;
    }

    function getTotalWithdrawnTokenAmount () external view returns (uint256) {
        return _totalWithdrawnTokenAmount;
    }

    function getAssetsReceiverAddress () external view returns (address) {
        return _assetsReceiverAddress;
    }

    function getTokenAddress () external view returns (address) {
        return _tokenAddress;
    }

    function getSaleOver () external view returns (bool) {
        return _saleOver;
    }

    function getWithdrawalAvailable () external view returns (bool) {
        return _withdrawalAvailable;
    }

    function getStartTime () external view returns (uint256) {
        return _startTime;
    }

    function getTimestamp () external view returns (uint256) {
        return block.timestamp;
    }

    function getWhitelistEndTime () external view returns (uint256) {
        return _whitelistEndTime;
    }

    function getEndTime () external view returns (uint256) {
        return _endTime;
    }

    function getMaxTokenAmount () external view returns (uint256) {
        return _maxTokenAmount;
    }

    function getBatchLimit () external view returns (uint256) {
        return _batchLimit;
    }

    function getTokenUsdRate () external view returns (uint256) {
        return _tokenUsdRate;
    }

    function getSalePoolSize () external view returns (uint256) {
        return _salePoolSize;
    }

    function getPaymentProfile (uint256 paymentProfileIndex) external view returns (
        address contractAddress,
        uint256 usdRate,
        uint256 weight,
        uint256 totalPaid,
        string memory name,
        string memory currency,
        bool active
    ) {
        return (
            _paymentProfiles[paymentProfileIndex].contractAddress,
            _paymentProfiles[paymentProfileIndex].usdRate,
            _paymentProfiles[paymentProfileIndex].weight,
            _paymentProfiles[paymentProfileIndex].totalPaid,
            _paymentProfiles[paymentProfileIndex].name,
            _paymentProfiles[paymentProfileIndex].currency,
            _paymentProfiles[paymentProfileIndex].active
        );
    }

    function getPaymentProfilesNumber () external view returns (uint256) {
        return _paymentProfilesNumber;
    }

    function isManager (address userAddress) external view returns (bool) {
        return _managers[userAddress];
    }

    function isWhitelisted (address userAddress) external view returns (bool) {
        return _whitelist[userAddress];
    }

    function isWhitelistMode () external view returns (bool) {
        return _whitelistMode;
    }

    function isSaleOver () external view returns (bool) {
        return _isSaleOver();
    }

    // internal view functions
    function _isSaleOver () internal view returns (bool) {
        return block.timestamp > _endTime || _saleOver;
    }

    function _getTokenAmount (
        uint256 paymentProfileIndex, uint256 amount
    ) internal view returns (uint256) {
        return amount * _paymentProfiles[paymentProfileIndex].usdRate / _tokenUsdRate;
    }

    function _getAvailableTokenAmount (
        address userAddress
    ) internal view returns (uint256) {
        return _paidTokenAmount[userAddress] - _withdrawnTokenAmount[userAddress];
    }
}