// SPDX-License-Identifier: MIT

// expanded from ---
// ^--- OpenZeppelin Contracts v4.4.0 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.4;

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitVault is Context, Ownable {
    event PayeeAdded(address account, uint256 shares, uint id);
    event PayeeWalletChanged(address old, address account, uint256 shares, uint id);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address payable[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    IERC20[] private _tokens;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address payable[] memory payees, uint256[] memory shares_) payable {
        _setPayees(payees, shares_);
    }

    function _setPayees(address payable[] memory payees, uint256[] memory shares_) private {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        reset();
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    function setPayees(address payable[] memory payees, uint256[] memory shares_) public onlyOwner {
        release();
        releaseTokens(); // needed otherwise the balances are off.
        _setPayees(payees, shares_);
    }
    function changePayee(address payable old, address payable _payee) public onlyOwner {
        require(old != address(0), "zero address");
        require(_payee != address(0), "zero address");
        uint id;
        for (uint256 i = 0; i < _payees.length; i++) {
            if (_payees[i] == old) id = i;
        }
        emit PayeeWalletChanged(old, _payee, _shares[old], id);
        _payees[id] = _payee;
        _shares[_payee] = _shares[old];
        delete _shares[old];

        for (uint256 i = 0; i < _tokens.length; i++) {
            _erc20Released[_tokens[i]][_payee] = _erc20Released[_tokens[i]][old];
            delete _erc20Released[_tokens[i]][old];
        }
    }

    function reset() internal onlyOwner {
        for (uint256 i = 0; i < _payees.length; i++) {
            delete _shares[_payees[i]];
        }
        delete _payees;
    }

    modifier onlyPayees() { // payees or owner.
        bool found = false;
        if (_msgSender() == owner()) found = true;

        for (uint256 i = 0; i < _payees.length; i++) {
            if (_payees[i] == _msgSender()) found = true;
        }
        require(found, "only payees");
        _;
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
//        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }


    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }
    function numPayees() public view returns (uint) {
        return _payees.length;
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function releaseOne(address payable account) public onlyPayees virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    function release() public onlyPayees virtual {
        for (uint256 i=0; i<_payees.length; i++) {
            address payable account = _payees[i];
            if (_shares[account] > 0) {
                uint256 totalReceived = address(this).balance + totalReleased();
                uint256 payment = _pendingPayment(account, totalReceived, released(account));
                if (payment != 0) {
                    _released[account] += payment;
                    _totalReleased += payment;
                    Address.sendValue(account, payment);
                    emit PaymentReleased(account, payment);
                }
            }
        }
    }

    /**
  * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function releaseTokenOne(IERC20 token, address account) public onlyPayees virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));
        require(payment != 0, "PaymentSplitter: account is not due payment");
        addToken(token);

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function releaseToken(IERC20 token) public onlyPayees virtual {
        addToken(token);
        for (uint256 i=0; i<_payees.length; i++) {
            address payable account = _payees[i];
            if (_shares[account] > 0) {
                uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
                uint256 payment = _pendingPayment(account, totalReceived, released(token, account));
                if (payment != 0) {
                    _erc20Released[token][account] += payment;
                    _erc20TotalReleased[token] += payment;

                    SafeERC20.safeTransfer(token, account, payment);
                    emit ERC20PaymentReleased(token, account, payment);
                }
            }
        }
    }
    function releaseTokens() public onlyPayees virtual {
        for (uint256 i=0; i<_tokens.length; i++) {
            releaseToken(_tokens[i]);
        }
    }
    function addToken(IERC20 _token) public onlyPayees {
        for (uint256 i=0; i<_tokens.length; i++) {
            if (_tokens[i] == _token) return;
        }
        _tokens.push(_token);
    }
    function tokens() public view returns (IERC20[] memory) {
        return _tokens;
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address payable account, uint256 shares_) private onlyOwner {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        emit PayeeAdded(account, shares_, _payees.length);
        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
    }

    // recovery if we get sent erc721s
    function withdrawERC721(address payable to, IERC721 _token, uint id) public onlyOwner {
        require(IERC721(_token).ownerOf(id) == address(this), "token not owned");
        IERC721(_token).safeTransferFrom(address(this), address(to), id);
    }

}