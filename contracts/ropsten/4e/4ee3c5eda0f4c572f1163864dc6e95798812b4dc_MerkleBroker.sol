/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/MerkleBroker.sol

pragma solidity ^0.5.0;


contract MerkleBroker {
    using SafeMath for uint256;

    address public coordinator;

    mapping(address => mapping(address => uint256)) public balances;
    mapping(bytes32 => uint256) public offers;
    mapping(bytes32 => uint256) public usedNonces;

    event BalanceIncrease(address indexed user, address indexed asset, uint256 amount);
    event BalanceDecrease(address indexed user, address indexed asset, uint256 amount);

    constructor() public {
        coordinator = msg.sender;
    }

    function deposit(address _user, address _asset, uint256 _amount) external {
        _increaseBalance(_user, _asset, _amount);
    }

    function withdraw(address _user, address _asset, uint256 _amount) external {
        _decreaseBalance(_user, _asset, _amount);
    }

    function trade(
        address[] calldata _users, // _users[0]: maker, _users[1]: taker
        address[] calldata _assets, // _assets[0]: offerAsset, _assets[1]: wantAsset, _assets[2]: feeAsset
        uint256[] calldata _amounts, // _amounts[0]: offerAmount, _amounts[1]: wantAmount, _amounts[2]: takeAmount, _amounts[3]: feeAmount
        uint256[] calldata _nonces, // _nonces[0]: offerNonce, _nonces[1]: fillNonce
        uint8[] calldata _v,
        bytes32[] calldata _r,
        bytes32[] calldata _s
    )
        external
    {
        bytes32 offerHash = _makeOffer(_users, _assets, _amounts, _nonces[0], _v[0], _r[0], _s[0]);

        // taker, offerHash, takeAmount, feeAsset, feeAmount, fillNonce
        _validateFill(_users[1], offerHash, _assets, _amounts, _nonces[1], _v[1], _r[1], _s[1]);

        _fill(_users, _assets, _amounts);
    }

    function markNonce(uint256 _nonce) external {
        _markNonceAsUsed(_nonce);
    }

    function _markNonceAsUsed(uint256 _nonce) private {
        uint256 compactedNonce = _nonce.div(256);
        uint256 remainder = _nonce.sub(compactedNonce.mul(256));
        bytes32 nonceHash = keccak256(abi.encodePacked(compactedNonce));
        usedNonces[nonceHash] = usedNonces[nonceHash] | (2 ** remainder);
    }

    function _nonceIsUsed(uint256 _nonce) private view returns(bool) {
        uint256 compactedNonce = _nonce.div(256);
        uint256 remainder = _nonce.sub(compactedNonce.mul(256));
        bytes32 nonceHash = keccak256(abi.encodePacked(compactedNonce));
        return usedNonces[nonceHash] & (2 ** remainder) != 0;
    }

    function _fill(
        address[] memory _users, // _users[0]: maker, _users[1]: taker
        address[] memory _assets, // _assets[0]: offerAsset, _assets[1]: wantAsset, _assets[2]: feeAsset
        uint256[] memory _amounts // _amounts[0]: offerAmount, _amounts[1]: wantAmount, _amounts[2]: takeAmount, _amounts[3]: feeAmount
    )
        private
    {
        // fillAmount / takeAmount = wantAmount / offerAmount
        // fillAmount = takeAmount * wantAmount / offerAmount
        uint256 fillAmount = (_amounts[2].mul(_amounts[1])).div(_amounts[0]);
        _decreaseBalance(_users[1], _assets[1], fillAmount);
        _increaseBalance(_users[0], _assets[1], fillAmount);

        uint256 receiveAmount = _assets[0] == _assets[2] ? _amounts[2].sub(_amounts[3]) : _amounts[2];
        _increaseBalance(_users[1], _assets[0], receiveAmount);

        if (_assets[0] != _assets[2]) {
            _decreaseBalance(_users[1], _assets[2], _amounts[3]);
        }

        _increaseBalance(coordinator, _assets[2], _amounts[3]);
    }

    function _makeOffer(
        address[] memory _users, // _users[0]: maker, _users[1]: taker
        address[] memory _assets, // _assets[0]: offerAsset, _assets[1]: wantAsset
        uint256[] memory _amounts, // _amounts[0]: offerAmount, _amounts[1]: wantAmount, _amounts[2]: takeAmount
        uint256 _offerNonce, // _nonces[0]: offerNonce, _nonces[1]: fillNonce
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        private
        returns (bytes32)
    {
        bytes32 offerHash = keccak256(abi.encodePacked(
            "makeOffer",
            _users[0], // maker
            _assets[0], // offerAsset
            _assets[1], // wantAsset
            _amounts[0], // offerAmount
            _amounts[1], // wantAmount
            _offerNonce
        ));

        require(_recoverAddress(offerHash, _v, _r, _s) == _users[0], &#39;Invalid signature&#39;);

        bool isNewOffer = _nonceIsUsed(_offerNonce);
        offers[offerHash] =  isNewOffer ? offers[offerHash].sub(_amounts[2]) : _amounts[0];

        // make offer by deducting offer amount from user
        if (isNewOffer == false) {
            _decreaseBalance(_users[0], _assets[0], _amounts[0]);
            _markNonceAsUsed(_offerNonce);
        }

        return offerHash;
    }

    function _decreaseBalance(address _user, address _asset, uint256 _amount) private {
        balances[_user][_asset] = balances[_user][_asset].sub(_amount);
        emit BalanceDecrease(_user, _asset, _amount);
    }

    function _increaseBalance(address _user, address _asset, uint256 _amount) private {
        balances[_user][_asset] = balances[_user][_asset].add(_amount);
        emit BalanceIncrease(_user, _asset, _amount);
    }

    function _validateFill(
        address _taker,
        bytes32 _offerHash,
        address[] memory _assets, // _assets[0]: offerAsset, _assets[1]: wantAsset, _assets[2]: feeAsset
        uint256[] memory _amounts, // _amounts[0]: offerAmount, _amounts[1]: wantAmount, _amounts[2]: takeAmount, _amounts[3]: feeAmount
        uint256 _fillNonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        private
    {
        bytes32 fillHash = keccak256(abi.encodePacked(
            "fillOffer",
            _taker,
            _offerHash,
            _amounts[2],
            _assets[2],
            _amounts[3],
            _fillNonce
        ));

        require(_recoverAddress(fillHash, _v, _r, _s) == _taker, &#39;Invalid signature&#39;);

        // require fillHash to be unused
        require(_nonceIsUsed(_fillNonce) == false, "Hash already used");
        _markNonceAsUsed(_fillNonce);
    }

    function _recoverAddress(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s)
        private
        pure
        returns (address)
    {
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
        return ecrecover(prefixedHash, _v, _r, _s);
    }
}