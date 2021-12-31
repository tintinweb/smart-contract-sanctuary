// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract SmudgeToken is ERC20, Pausable, Ownable {
    // Charity fee
    uint256 private _charityFee;

    // Maximum mintable tokens
    uint256 private _maximumSupply;

    // Address where all charity funds are collected per transaction
    address payable private _charityWallet;

    // List of address that are excluded form the charity fee
    mapping(address => bool) private _isExcludedFromFee;

    /**
     * @dev Sets the values for `name` and `symbol`. All two of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        uint256 maximumSupply_,
        uint256 charityFee_,
        address payable charityWallet_
    ) ERC20(name_, symbol_) {
        require(charityFee_ > 0, "Crowdsale: charity fee is 0");
        require(maximumSupply_ > 0, "Crowdsale: maximum token supply is 0");
        require(
            maximumSupply_ > initialSupply_,
            "Crowdsale: initial token supply is greater than maximum token supply"
        );
        require(
            charityWallet_ != address(0),
            "Crowdsale: charity wallet is the zero address"
        );

        _charityFee = charityFee_;
        _charityWallet = charityWallet_;
        _maximumSupply = maximumSupply_;

        // Exclude owner and this contract from the charity fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[charityWallet_] = true;

        // Mint the initial supply only if greater than zero
        if (initialSupply_ > 0) {
            _mint(msg.sender, initialSupply_);
        }

        // start the token as paused for non-owners
        _pause();
    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     */
    fallback() external payable {
        revert("Not allowed to accept funds");
    }

    /**
     * @dev receive function ***DO NOT OVERRIDE***
     */
    receive() external payable {
        revert("Not allowed to accept funds");
    }

    /**
     * @dev The maximum supply of mintable tokens
     */
    function maximumSupply() public view returns (uint256) {
        return _maximumSupply;
    }

    /**
     * @dev Convert token count to full big number using decimals
     *
     * @param tokens to be converted to full count
     *
     * Requirements:
     *
     */
    function _tokensToFulllDecimalsTotal(uint256 tokens)
        internal
        view
        returns (uint256)
    {
        return tokens * (10**uint256(decimals()));
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(
            !paused() || msg.sender == owner(),
            "ERC20Pausable: token transfer while paused"
        );
    }

    /**
     * @dev Calculate a charity fee based on the amount
     *
     * @param amount to be calculated into the charity fee
     *
     * Requirements:
     *
     */
    function _calculateCharityFee(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (amount * _charityFee) / (10**2);
    }

    /**
     * @dev Transfer tokens to the recipients list.
     *
     * @param recipients address to receive the tokens.
     * @param amount to transfer.
     *
     */
    function airdrop(address[] memory recipients, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        require(
            amount > 0,
            "Amount of airdrop for each recipients must be greater than zero"
        );

        uint256 airdrops = recipients.length;
        uint256 totalAmount = airdrops * amount;

        uint256 senderBalance = balanceOf(_msgSender());

        require(
            senderBalance >= totalAmount,
            "Airdrop total amount exceeds balance of sender"
        );

        for (uint256 i = 0; i < airdrops; i++) {
            _transfer(_msgSender(), recipients[i], amount);
        }

        return true;
    }

    /**
     * @dev Transfer tokens and take the charity share. This method is overriden from base ERC20 class.
     *
     * @param recipient address to receive the tokens.
     * @param amount to transfer.
     *
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[_msgSender()] || _isExcludedFromFee[recipient]) {
            _transfer(_msgSender(), recipient, amount);
        } else {
            uint256 fee = _calculateCharityFee(amount);
            uint256 toTransfer = amount - fee;
            _transfer(_msgSender(), _charityWallet, fee);
            _transfer(_msgSender(), recipient, toTransfer);
        }

        return true;
    }

    /**
     * @dev Transfer tokens and take the charity share. This method is overriden from base ERC20 class.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * @param sender address to send tokens from.
     * @param recipient address to receive the tokens.
     * @param amount to transfer.
     *
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 fee = _calculateCharityFee(amount);
            uint256 toTransfer = amount - fee;
            _transfer(sender, _charityWallet, fee);
            _transfer(sender, recipient, toTransfer);
        }

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Mints `amount` of tokens and adds to the total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * @param amount of owner tokens to mint.
     */
    function mintSupply(uint256 amount) public onlyOwner {
        require(
            amount > 0,
            "Amount of new tokens to mint must be greater than zero"
        );
        require(
            totalSupply() + amount <= _maximumSupply,
            "Can not mint beyond the maximum token supply count"
        );

        _mint(msg.sender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from token owner address, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * @param amount of owner tokens to burn.
     */
    function burnSupply(uint256 amount) public onlyOwner {
        _maximumSupply -= amount;
        _burn(msg.sender, amount);
    }

    /**
     * @dev Unpause the token from the owner. Token can not be paused again
     *
     * Emits a {Unpaused} event.
     *
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Add an address to the excluded from charity fee
     *
     * @param account address to be excluded from the charity fee
     *
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @dev Remove an address from the excluded charity fee
     *
     * @param account address to be included from the charity fee
     *
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @dev Checks if address is excluded from fee
     *
     * @param account address to check for exclude fee
     *
     */
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
     * @dev Returns the address of the charity wallet.
     */
    function charityWallet() public view virtual returns (address) {
        return _charityWallet;
    }

    /**
     * @dev Set the charity wallet to a new account (`newWallet`).
     * Can only be called by the current owner.
     */
    function setCharityWallet(address payable newWallet) public onlyOwner {
        require(
            newWallet != address(0),
            "Ownable: new wallet is the zero address"
        );

        _setCharityWallet(newWallet);
    }

    /**
     * @dev Set the charity wallet to a new account (`newWallet`).
     */
    function _setCharityWallet(address payable newWallet) private {
        _charityWallet = newWallet;
    }
}