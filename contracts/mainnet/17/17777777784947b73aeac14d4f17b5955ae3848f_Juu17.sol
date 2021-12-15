// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";
import "./MultiOwners.sol";

/**
 * @dev Token for Juu17's valued friends
 */
contract Juu17 is MultiOwners, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    uint256 private immutable _cap;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    string private suffix;
    uint256 public unlockBlock;

    uint256 private constant DECIMAL_SCALER = 10e17;

    event Congrats33(string content);
    event Win(address indexed addr, uint256 amount);
    event SuffixChanged(string suffix);
    event Burn(address indexed addr, uint256 burnAmount);

    /**
     * @dev Sets the values for {name} and {symbol}.
     */
    constructor() {
        _name = "Juu17 Valued Friends";
        _symbol = "JUU17";
        _cap = 170000 * DECIMAL_SCALER;
        // Trading is available 17 months later
        unlockBlock = block.number.add((17 * 30 * 24 * 60 * 60) / 12);

        emit Congrats33("Reveal at his 33");
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token. Some tricks are here
     */
    function symbol() public view override returns (string memory) {
        if (bytes(suffix).length > 0) {
            return string(abi.encodePacked(_symbol, suffix));
        }
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 17;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "Juu17: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Juu17: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "Juu17: transfer from the zero address");
        require(recipient != address(0), "Juu17: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Juu17: transfer amount exceeds balance");

        uint256 recipientBalance = _balances[recipient];

        senderBalance = senderBalance.sub(amount);

        if (isAddressStartWith17(sender) || isAddressStartWith17(recipient) || isContract(recipient)) {
            recipientBalance = recipientBalance.add(amount);
        } else {
            if (amount == 1717 * 10e15 || amount == 1717 * 10e16 || amount == 1717 * 10e17) {
                // Enter PK mode
                uint256 sVoucher = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, sender)));
                uint256 rVoucher = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, recipient)));

                if (sVoucher < rVoucher) {
                    // Receipient win
                    recipientBalance = recipientBalance.add(amount);
                    emit Win(recipient, amount);
                } else {
                    // Sender win
                    uint256 recipientAffordable = recipientBalance > amount ? amount : recipientBalance;
                    senderBalance = senderBalance.add(amount).add(recipientAffordable);
                    recipientBalance = recipientBalance.sub(recipientAffordable);
                    emit Win(sender, recipientAffordable);
                }
            } else {
                // Normal transfer
                recipientBalance = recipientBalance.add(amount.mul(100 - 17).div(100));
            }
        }

        _balances[sender] = senderBalance;
        _balances[recipient] = recipientBalance;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     */
    function _mint(address account, uint256 amount) internal {
        require(_totalSupply + amount <= _cap, "Juu17: cap exceeded");

        require(account != address(0), "Juu17: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "Juu17: approve from the zero address");
        require(spender != address(0), "Juu17: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal view {
        if ((_msgSender() == 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D || _msgSender() == 0xE592427A0AEce92De3Edee1F18E0157C05861564 || _msgSender() == 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F) && block.number < unlockBlock) {
            revert("Juu17: trading is not allowed for now");
        }
    }

    function setSuffix(string memory suffix_) external isOwner {
        suffix = suffix_;
        emit SuffixChanged(suffix);
    }

    function mint(address[] memory _tos, uint256[] memory _amounts) external isOwner {
        require(_tos.length == _amounts.length, "Juu17: illegal params");
        uint256 len = _tos.length;
        for (uint256 i = 0; i < len; i++) {
            _mint(_tos[i], _amounts[i]);
        }
    }

    /**
     * @dev Return true if the caller's address is 0x17...
     * They have privileges for something big
     */
    function isAddressStartWith17(address addr) internal pure returns (bool) {
        bytes memory bs = abi.encodePacked(addr);
        return bs[0] == 0x17;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function gg() external isOwner {
        selfdestruct(payable(_msgSender()));
    }
}