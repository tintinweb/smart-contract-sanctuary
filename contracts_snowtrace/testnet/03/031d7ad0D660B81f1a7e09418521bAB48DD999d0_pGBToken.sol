/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-11
*/

// SPDX-License-Identifier: Copyright (C) 2022 - pingNpay  [email protected] . This file is part of {pingNpay small value payments network}. This software can not be copied and/or distributed without the express permission of {Richard Bell CEO pingNpay [email protected]}

/*
#How to Deploy this Contract on AVAX-C chain
https://docs.avax.network/build/tutorials/smart-contracts/deploy-a-smart-contract-on-avalanche-using-remix-and-metamask/

#Measuring Performance of Contract - Transaction Analysis
*/

/*
#Reference
    https://eips.ethereum.org/EIPS/eip-20
    https://ethereum.org/en/developers/docs/standards/tokens/erc-20/#top

*/

/**
#**pingNpay Smart Contract Summary Overview** 
##Parties: 
    ###System 
        Spender
        Owner 
    ###pingNpay Payment
        Sender 
        Recipient
    note Receiver Wallet Provider DLT_Address_id for receiver payment (not fees is) variable is r_wp_dlt_op_id aka an operational account

    ###pingNpay Fees
        p_wp_fee  - Payer Wallet Provider
        p_wd_fee - Payer Wallet Developer
        r_wp_fee - Receiver Wallet Developer
        r_wd_fee - Receiver Wallet Developer
        pingNpay_fee - pingNpay
        dlt_network_fee - dlt Network 

    ##Functions:
        owner
        name
        symbol
        decimals
        totalSupply
        balanceOf
        allowanceapprove
        transfer
        transferFrom
        mint 
        burn
        payment
        updateFees

    ##Events / Emits
        Transfer
        Approval
        Mint
        Burn
        Payment
*/

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 */
contract ERC20 is Context, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {balanceOf} and {transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 6;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual onlyOwner returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract pGBToken is ERC20 {
    /** @dev IMPORTANT NOTE ABOUT FEES-------------------------------------------
     * Fee percentages are formatted in a specific way in order to optimally
     * calculate fees. The first two digit places represent the tenths and
     * hundredths places for the percent. If these values are 0, they will
     * need to be set to 0.
     *
     * Example.
     * If we wanted to represent 50.25% in our smart contract, we would format
     * it as such: 5025. The 25 represents the 0.25% and the 5000 represents the
     * 50%.
     * Another Example.
     * 1.01% would be formatted as 101. 100 would be the 1% and 1 would be the
     * 0.01%
     */
    uint256 private p_wp_fee;
    uint256 private p_wd_fee;
    uint256 private r_wp_fee;
    uint256 private r_wd_fee;
    uint256 private pingNpay_fee;
    uint256 private dlt_network_fee;
    uint256 private kyc_modifer_rate;
    uint256 private _feeDec = 10**(4);

    // Addresses
    address private _dlt_network;

    address private _wp1;
    address private _wp2;

    /**
     * @dev Constructor for the pGB token.
     * Takes in the wallet provider addresses as an input and sets the local variables
     * to it. The order of the addresses doesn't matter but they cannot be changed
     * later.
     * Inputs:
     *
     * - `wp1` the first wallet provider address
     * - `wp2` the second wallet provider address
     * - `dlt_network` the address to send the dlt_network_fee to
     */
    constructor(
        address wp1,
        address wp2,
        address dlt_network
    ) ERC20("pingNpay", "pGB") {
        _wp1 = wp1;
        _wp2 = wp2;
        _dlt_network = dlt_network;
    }

    /**
     * @dev External call to mint tokens to `account. Also emits an event with the
     * payloadHash and inputs.
     */

    function mint(
        address account,
        uint256 amount,
        bytes32 payloadHash
    ) public onlyOwner {
        _mint(account, amount);
        emit Mint(account, amount, payloadHash);
    }

    /**
     * @dev External call to burn tokens from `account. Also emits an event with the
     * payloadHash and inputs.
     */

    function burn(
        address account,
        uint256 amount,
        bytes32 payloadHash
    ) public onlyOwner {
        _burn(account, amount);
        emit Burn(account, amount, payloadHash);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This function calculates a series of fees to be sent to parties and sends said
     * fees to the respective parties. {payment} only sends fees to parties with fee rates
     * greater than zero.
     */
    function payment(
        uint256 amount, // amount being sent
        bytes32 payloadHash, // hash used by pingNpay to resolve payer/sender information
        bool p_kyc, // payer KYC
        bool r_kyc, // sender KYC
        address p_wp_dlt_id, // payer wallet provider
        address r_wp_dlt_id, // receiver wallet provider
        address p_wd_dlt_id, // payer wallet developer
        address r_wd_dlt_id, // receiver wallet developer
        address r_wp_dlt_op_id // Receiver WP Operational Account
    ) public returns (bool) {
        require(
            _msgSender() == _wp1 ||
                _msgSender() == _wp2 ||
                _msgSender() == owner(),
            "pGB: Permission Denied Not allowed to call Payment"
        );
        uint256 totalFees = 0;
        {
            uint256 totalFeePercent = pingNpay_fee;
            uint256 currentFee = 0;
            {
                // payer wallet provider currentFee transfer
                uint256 feeMod = p_kyc
                    ? p_wp_fee
                    : p_wp_fee + ((p_wp_fee * kyc_modifer_rate) / _feeDec);
                totalFeePercent += feeMod;
                currentFee = (amount * feeMod) / _feeDec;
                _transfer(_msgSender(), p_wp_dlt_id, currentFee);
                totalFees += currentFee;
                // receiver wallet provider fee transfer
                feeMod = r_kyc
                    ? r_wp_fee
                    : r_wp_fee + (r_wp_fee + kyc_modifer_rate / _feeDec);
                totalFeePercent += feeMod;
                currentFee = (amount * feeMod) / _feeDec;
                _transfer(_msgSender(), r_wp_dlt_id, currentFee);
                totalFees += currentFee;
            }
            // payer wallet developer fee transfer
            if (p_wd_fee > 0) {
                currentFee = (amount * p_wd_fee) / _feeDec;
                totalFeePercent += p_wd_fee;
                _transfer(_msgSender(), p_wd_dlt_id, currentFee);
                totalFees += currentFee;
            }
            // receiver wallet developer fee transfer
            if (r_wd_fee > 0) {
                currentFee = (amount * r_wd_fee) / _feeDec;
                totalFeePercent += r_wd_fee;
                _transfer(_msgSender(), r_wd_dlt_id, currentFee);
                totalFees += currentFee;
            }
            // DLT network fee transfer
            if (dlt_network_fee > 0) {
                currentFee = (amount * dlt_network_fee) / _feeDec;
                totalFeePercent += dlt_network_fee;
                _transfer(_msgSender(), _dlt_network, currentFee);
                totalFees += currentFee;
            }
            // pingNpay fee transfer
            if (pingNpay_fee > 0) {
                currentFee = ((amount * totalFeePercent) / _feeDec) - totalFees;
                _transfer(_msgSender(), owner(), currentFee);
                totalFees += currentFee;
            }
        }
        uint256 remainder = amount - totalFees;
        _transfer(_msgSender(), r_wp_dlt_op_id, remainder);
        emit Payment(p_wp_dlt_id, r_wp_dlt_id, amount, payloadHash);
        return true;
    }

    /**
     * @dev Updates the fees as described by the pGB spec
     *
     * This function updates the following fees: p_wp_fee, p_wd_fee, r_wp_fee
     * r_wp_fee, new_r_wd_fee, pingNpay_fee, dlt_network_fee. Additionally it
     * updated the kyc_modifer_rate. All percentages should be formatted as
     * described earlier.
     */
    function updateFees(
        uint256 new_p_wp_fee,
        uint256 new_p_wd_fee,
        uint256 new_r_wp_fee,
        uint256 new_r_wd_fee,
        uint256 new_pingNpay_fee,
        uint256 new_dlt_network_fee,
        uint256 new_kyc_modifer_rate
    ) public onlyOwner {
        p_wp_fee = new_p_wp_fee;
        p_wd_fee = new_p_wd_fee;
        r_wp_fee = new_r_wp_fee;
        r_wd_fee = new_r_wd_fee;
        pingNpay_fee = new_pingNpay_fee;
        dlt_network_fee = new_dlt_network_fee;
        kyc_modifer_rate = new_kyc_modifer_rate;
    }

    /**
     * @dev Updates the addresses used in the pGB contract
     *
     * This function updates the following addresses: wp1, wp2, dlt_network.
     */

    function updateAddresses(
        address wp1,
        address wp2,
        address dlt_network
    ) public onlyOwner {
        _wp1 = wp1;
        _wp2 = wp2;
        _dlt_network = dlt_network;
    }

    event Mint(address to, uint256 amount, bytes32 payloadHash);
    event Burn(address from, uint256 amount, bytes32 payloadHash);
    event Payment(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes32 payloadHash
    );
}