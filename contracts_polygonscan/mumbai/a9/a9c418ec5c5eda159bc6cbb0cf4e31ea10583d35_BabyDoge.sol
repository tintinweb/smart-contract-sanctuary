/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Interface of the IERC20 standard
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BabyDoge is IERC20 {
    /// @dev Token Details
    string public constant name = "Baby Doge Coin";
    string public constant symbol = "BabyDoge";
    uint8 public constant decimals = 12;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    uint256 private baseSupply = 1e24;
    uint256 private _totalSupply = 1e24;

    /// @dev Divisors/Multiplier used to calculate burn and fees
    uint32 private baseBurnDivisor = 30;
    uint32 private hodlerFeeDivisor = 50;
    uint32 private externalFeeDivisor = 1000;
    uint8 private whaleBurnMultiplier = 50;

    /// @dev Admin and address where fees are sent
    address private admin;
    address private feeAddress;

    mapping(address => bool) private excludedSenders;
    mapping(address => bool) private excludedReceivers;

    /// @dev freeTransfer() enabled
    bool private allowFreeTransfer = false;

    constructor() {
        admin = msg.sender;
        feeAddress = msg.sender;
        balances[msg.sender] = _totalSupply;
        excludedSenders[msg.sender] = true;
        excludedReceivers[msg.sender] = true;
    }

    /**
     * @dev Throws if called by any account other than the admin
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "BabyDoge: caller is not Admin");
        _;
    }

    /**
     * @return Balance of given @param account
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return Balance of given @param account
     */
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return (balances[account] * _totalSupply) / baseSupply;
    }

    /**
     * @return Allowance given to @param spender by @param owner
     */
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    /**
     * @notice Approves @param spender to spend up to @param amount on behalf of caller
     */
    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Increases the spending allowance granted to @param spender for caller by @param addedValue
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    /**
     * @notice Decreases the spending allowance granted to @param spender for caller by @param subtractedValue
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 currentAllowance = allowances[msg.sender][spender];
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    /**
     * @param _baseBurnDivisor divisor to calculate base burn rate. amount / divisor = baseBurnRate
     */
    function setBaseBurnDivisor(uint8 _baseBurnDivisor) external onlyAdmin {
        require(
            _baseBurnDivisor > 19,
            "BabyDoge::setBaseBurnDivisor: baseBurnDivisor must be greater than 19"
        ); // 1/20 = 5% max base burn
        baseBurnDivisor = _baseBurnDivisor;
    }

    /**
     * @param _hodlerFeeDivisor divisor to calculate fees to Hodlers. amount / divisor = fees
     */
    function setHodlerFeeDivisor(uint8 _hodlerFeeDivisor) external onlyAdmin {
        require(
            _hodlerFeeDivisor > 19,
            "BabyDoge::setFeeDivisor: hodlerFeeDivisor must be greater than 19"
        ); // 1/20 = 5% Max Fee
        hodlerFeeDivisor = _hodlerFeeDivisor;
    }

    /**
     * @param _externalFeeDivisor divisor to calculate fees to Hodlers. amount / divisor = fees
     */
    function setExternalFeeDivisor(uint8 _externalFeeDivisor)
        external
        onlyAdmin
    {
        require(
            _externalFeeDivisor > 19,
            "BabyDoge::setFeeDivisor: externalFeeDivisor must be greater than 19"
        ); // 1/20 = 5% Max Fee
        externalFeeDivisor = _externalFeeDivisor;
    }

    /**
     * @param _whaleBurnMultiplier Multiplier to calculate amount burned for large transfers
     */
    function setWhaleBurnMultiplier(uint8 _whaleBurnMultiplier)
        external
        onlyAdmin
    {
        require(
            _whaleBurnMultiplier < 30,
            "BabyDoge::setWhaleBurnMultiplier: _whaleBurnMultiplier must be less than 30"
        );
        whaleBurnMultiplier = _whaleBurnMultiplier;
    }

    /**
     * @param _feeAddress address to collect fees
     */
    function setFeeAddress(address _feeAddress) external onlyAdmin {
        feeAddress = _feeAddress;
    }

    /**
     * @param _senderToAdd address to exclude from paying fees when sending
     */
    function addExcludedSender(address _senderToAdd) external onlyAdmin {
        excludedSenders[_senderToAdd] = true;
    }

    /**
     * @param _senderToRemove address to remove from fee exception when sending
     */
    function removeExcludedSender(address _senderToRemove) external onlyAdmin {
        excludedSenders[_senderToRemove] = false;
    }

    /**
     * @param _receiverToAdd address to exclude from paying fees when receiving
     */
    function addExcludedReceiver(address _receiverToAdd) external onlyAdmin {
        excludedReceivers[_receiverToAdd] = true;
    }

    /**
     * @param _receiverToRemove address to remove from fee exception when receiving
     */
    function removeExcludedReceiver(address _receiverToRemove)
        external
        onlyAdmin
    {
        excludedReceivers[_receiverToRemove] = false;
    }

    /**
     * @return bool wether @param sender is excluded from fees
     */
    function isExcludedSender(address sender) external view returns (bool) {
        return excludedSenders[sender];
    }

    /**
     * @return bool wether @param receiver is excluded from fees
     */
    function isExcludedReceiver(address receiver) external view returns (bool) {
        return excludedReceivers[receiver];
    }

    /**
     * @param _allowFreeTransfer Whether free transfers should be allowed to public
     */
    function setAllowFreeTransfer(bool _allowFreeTransfer) external onlyAdmin {
        allowFreeTransfer = _allowFreeTransfer;
    }

    /**
     * @param _newAdmin address to become new Admin.
     */
    function setAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    /**
     * @notice Transfer tokens
     * @param recipient Address to recieve transferred tokens
     * @param amount Amount to be sent. A portion of this will be burned and collected as fees
     */
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        // Bypass fees if sender or reciever is excluded
        if (excludedSenders[msg.sender] || excludedReceivers[recipient]) {
            _transfer(msg.sender, recipient, amount);
        } else {
            _transferWithFees(msg.sender, recipient, amount);
        }
        return true;
    }

    /**
     * @notice Transfer tokens from approved allowance
     * @param sender address sending tokens.
     * @param recipient address to recieve transferred tokens.
     * @param amount Amount to be sent. A portion of this will be burned.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);

        // Bypass fees if sender or reciever is excluded
        if (
            excludedSenders[sender] ||
            excludedSenders[msg.sender] ||
            excludedReceivers[recipient]
        ) {
            _transfer(sender, recipient, amount);
        } else {
            _transferWithFees(sender, recipient, amount);
        }
        return true;
    }

    /**
     * @notice Transfer without burn/fees. This is not the standard BEP20 transfer.
     * @param recipient address to recieve transferred tokens.
     * @param amount Amount to be sent.
     */
    function freeTransfer(address recipient, uint256 amount) external {
        require(
            allowFreeTransfer,
            "BabyDoge::freeTransfer: freeTransfer is currently turned off"
        );
        _transfer(msg.sender, recipient, amount);
    }

    /**
     * @notice Transfer without burn from approved allowance. This is not the standard BEP20 transferFrom.
     * @param sender address sending tokens.
     * @param recipient address to recieve transferred tokens.
     * @param amount Amount to be sent.
     */
    function freeTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external {
        require(
            allowFreeTransfer,
            "BabyDoge::freeTransferFrom: freeTrasnfer is currently turned off"
        );
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        _transfer(sender, recipient, amount);
    }

    /**
     * @notice Transfers tokens to multiple addresses.
     * @param addresses Addresses to send tokens to.
     * @param amounts Amounts of tokens to send.
     */
    function multiTransfer(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external {
        require(
            allowFreeTransfer,
            "BabyDoge::freeTransferFrom: freeTrasnfer is currently turned off"
        );
        require(
            addresses.length == amounts.length,
            "BabyDoge::multiTransfer: addresses and amounts count do not match"
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            _transfer(msg.sender, addresses[i], amounts[i]);
        }
    }

    /**
     * @notice Destroys @param amount tokens and reduces total supply.
     */
    function burn(uint256 amount) external {
        uint256 baseAccountBalance = balances[msg.sender];
        require(
            (baseAccountBalance * _totalSupply) / baseSupply >= amount,
            "BabyDoge::burn: burn amount exceeds balance"
        );
        uint256 baseAmount = (amount * baseSupply) / _totalSupply;
        balances[msg.sender] = baseAccountBalance - baseAmount;
        _totalSupply -= amount;
        baseSupply -= baseAmount;
        _removeDust(msg.sender);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @notice Transfer with all fees and burn applied
     * @param sender address sending tokens.
     * @param recipient address to recieve transferred tokens.
     * @param amount Amount to be sent. Fees and burn deducted from this amount
     */
    function _transferWithFees(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        // Calculate burn and fee amount
        uint256 burnAmount =(amount / baseBurnDivisor) + ((amount**2 / _totalSupply) * whaleBurnMultiplier);
        if (burnAmount > amount / 10) {
            burnAmount = amount / 10;
        }
        uint256 externalFeeAmount = amount / externalFeeDivisor;
        uint256 hodlerFeeAmount = amount / hodlerFeeDivisor;
        uint256 recipientAmount = amount - burnAmount - externalFeeAmount - hodlerFeeAmount;

        // Burn/transfer tokens
        balances[sender] -= (amount * baseSupply) / _totalSupply;
        balances[feeAddress] += (externalFeeAmount * baseSupply) / _totalSupply;
        balances[recipient] += (recipientAmount * baseSupply) / _totalSupply;
        baseSupply -= ((hodlerFeeAmount + burnAmount) * baseSupply) / _totalSupply;
        _totalSupply -= burnAmount;
        _removeDust(sender);
        emit Transfer(sender, address(0), burnAmount);
        emit Transfer(sender, feeAddress, externalFeeAmount);
        emit Transfer(sender, recipient, recipientAmount);
    }

    /**
     * @dev Moves @param amount tokens from @param sender to @param recipient
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(
            recipient != address(0),
            "BabyDoge::_transfer: transfer to the zero address"
        );
        uint256 baseSenderBalance = balances[sender];
        require(
            (baseSenderBalance * _totalSupply) / baseSupply >= amount,
            "BabyDoge::_transfer: transfer amount exceeds balance"
        );
        uint256 baseAmount = (amount * baseSupply) / _totalSupply;
        balances[sender] = baseSenderBalance - baseAmount;
        balances[recipient] += baseAmount;
        _removeDust(sender);
        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Approves spending to @param spender of up to @param amount tokens from @param owner
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Remove extremely small balances likely caused by integer division
     */
    function _removeDust(address account) private {
        if (balances[account] < 5) {
            balances[account] = 0;
        }
    }
}