//SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <=0.8.6;

import "./ERC721.sol";
import "./IERC20.sol";
import "./extensions/IERC721Pausable.sol";
import "../utils/Address.sol";
import "../utils/math/SafeMath.sol";

contract PaybNftMarketplace is ERC721, IERC721Pausable{
    using Address for address;
    using SafeMath for uint256;

    event PriceChanged(uint256 _tokenId, uint256 _price, address _tokenAddress, address _user);
    event RoyaltyChanged(uint256 _tokenId, uint256 _royalty, address _user);
    event FundsTransfer(uint256 _tokenId, uint256 _amount, address _user);

    mapping(uint256 => bool) tokenStatus;

    mapping(uint256 => uint256) prices;

    mapping(uint256 => address) tokenAddress;

    mapping(uint256 => uint256) royalties; // in decimals (min 0.01%, max 100%)

    mapping(uint256 => address) tokenCreators;

    mapping(address => uint256[]) creatorsTokens;

    uint256 tokenId;

    uint256 platformFee = 0;

    constructor(string memory name_, string memory symbol_, address payable owner_, address admin_) ERC721(name_, symbol_) {
        tokenId = 1;
        owner = owner_;
        admins[admin_] = true;
    }

    function withdraw() external onlyOwner() {
        owner.transfer(getBalance());
    }

    function withdraw(address _user, uint256 _amount) external onlyOwner() {
        uint256 _balance = getBalance();
        require(_balance > 0, "Balance is null");
        require(_balance >= _amount, "Amount is greater than the balance of contract");

        payable(_user).transfer(_amount);
    }

    function withdraw(address _tokenErc20, address _user) external onlyOwner() {
        require(_tokenErc20.isContract(), "Token address isn`t a contract address");
        uint256 _totalBalance = IERC20(_tokenErc20).balanceOf(address(this));

        require(_totalBalance > 0, "Total balance is zero");

        IERC20(_tokenErc20).transfer(_user, _totalBalance);
    }

    function setPlatformFee(uint256 _newFee) public onlyAdmin {
        require(_newFee < 10000, "Royalty can be 100 percent of the total amount");
        platformFee = _newFee;
    }

    function getPlatformFee() public view returns(uint256) {
        return platformFee;
    }

    function getBalance() public view returns(uint256){
        address _self = address(this);
        uint256 _balance = _self.balance;
        return _balance;
    }

    function mint(address _to, address _token, uint256 _price, string memory _uri, uint256 _royalty) public payable {
        require(_token == address(0) || _token.isContract(), "Token address isn`t a contract address");
        require(_royalty + platformFee < 10000, "Creator royalty plus platform fee must be less than 100%");

        prices[tokenId] = _price;
        tokenAddress[tokenId] = _token;
        tokenStatus[tokenId] = true;
        royalties[tokenId] = _royalty;
        tokenCreators[tokenId] = _to;
        creatorsTokens[_to].push(tokenId);

        if((isAdmin(msg.sender) && msg.sender != _to) || msg.sender == address(this)){
            _pause(tokenId);
        }

        _safeMint(_to, tokenId, _uri);

        emit PriceChanged(tokenId++, _price, _token, msg.sender);
    }

    function setPriceAndSell(uint256 _tokenId, uint256 _price) public tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(ownerOf(_tokenId) == msg.sender, "Sender isn`t owner of token");

        prices[_tokenId] = _price;
        _resume(_tokenId);

        emit PriceChanged(_tokenId, _price, tokenAddress[_tokenId], msg.sender);
    }

    function buy(uint256 _tokenId) public payable tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(tokenStatus[_tokenId], "Token not for sale");
        require(ownerOf(_tokenId) != msg.sender, "Sender is already owner of token");

        uint256 _price = prices[_tokenId];
        uint256 _creatorRoyalty = (_price.mul(royalties[_tokenId])).div(10000);
        uint256 _platformFee = (_price.mul(platformFee)).div(10000);

        if(tokenAddress[_tokenId] == address(0)) {
            require(_price == msg.value, "Value isn`t equal to price!");
            payable(ownerOf(_tokenId)).transfer(_price.sub(_creatorRoyalty + _platformFee));
            payable(tokenCreators[_tokenId]).transfer(_creatorRoyalty);
            owner.transfer(_platformFee);
        }else {
            require(IERC20(tokenAddress[_tokenId]).balanceOf(msg.sender) >= _price, "Insufficient funds");
            IERC20(tokenAddress[_tokenId]).transferFrom(msg.sender, address(this), _price);

            IERC20(tokenAddress[_tokenId]).transfer(ownerOf(_tokenId), _price.sub(_creatorRoyalty + _platformFee));
            IERC20(tokenAddress[_tokenId]).transfer(owner, _platformFee);
            IERC20(tokenAddress[_tokenId]).transfer(tokenCreators[_tokenId], _creatorRoyalty);
        }

        _pause(_tokenId);

        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }

    function balanceOf(address _user, uint256 _tokenId) public view returns(uint256) {
        return IERC20(tokenAddress[_tokenId]).balanceOf(_user);
    }

    function getPriceInTokens(uint256 _tokenId) public view tokenNotFound(_tokenId) isUnlock(_tokenId) returns(uint256, address){
        return (prices[_tokenId], tokenAddress[_tokenId]);
    }

    function pause(uint256 _tokenId) external override tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(ownerOf(_tokenId) == msg.sender, "User isn`t owner of token!");

        _pause(_tokenId);
    }

    function _pause(uint256 _tokenId) internal {
        tokenStatus[_tokenId] = false;

        emit Paused(_tokenId);
    }

    function resume(uint256 _tokenId) external override tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(ownerOf(_tokenId) == msg.sender, "User isn`t owner of token!");

        _resume(_tokenId);
    }

    function _resume(uint256 _tokenId) internal {
        tokenStatus[_tokenId] = true;

        emit Resumed(_tokenId);
    }

    function getTokenStatus(uint256 _tokenId) public view returns(bool) {
        return isLock(_tokenId);
    }

    function isForSale(uint256 _tokenId) public view returns(bool) {
        return tokenStatus[_tokenId];
    }

    function getRoyalty(uint256 _tokenId) public view returns(uint256) {
        return royalties[_tokenId];
    }

    function setNewRoyalty(uint256 _tokenId, uint256 _newRoyalty) public tokenNotFound(_tokenId) isUnlock(_tokenId){
        require(msg.sender == ownerOf(_tokenId), "Sender isn`t an owner of token");
        require(_newRoyalty > royalties[_tokenId] && _newRoyalty <= 10000 && _newRoyalty + platformFee <= 10000, "New royalty cannot be less than the old one or more than 100%");

        royalties[_tokenId] = _newRoyalty;

        emit RoyaltyChanged(_tokenId, _newRoyalty, msg.sender);
    }

    function sendToken(uint256 _tokenId, address _from, address _to) public tokenNotFound(_tokenId) onlyAdmin() {
        require(isLock(_tokenId), "Token is unlocked");
        _transfer(_from, _to, _tokenId);
        _unlock(_tokenId);
        _pause(_tokenId);
    }

    function sendTo(uint256 _tokenId, address payable _to) public onlyAdmin() tokenNotFound(_tokenId) payable{
        require(ownerOf(_tokenId) == _to, "To isn`t an owner of token");

        uint256 _price = prices[_tokenId];
        address _token = tokenAddress[_tokenId];


        uint256 _creatorRoyalty = (_price.mul(royalties[_tokenId])).div(10000);
        uint256 _platformFee = (_price.mul(platformFee)).div(10000);

        if(_token == address(0)){
            require(_price == msg.value, "Amount isn`t equal to price");
            _to.transfer(_price.sub(_creatorRoyalty + _platformFee));
            payable(tokenCreators[_tokenId]).transfer(_creatorRoyalty);
            owner.transfer(_platformFee);
        }else {
            require(IERC20(_token).balanceOf(msg.sender) >= _price, "Insufficient funds");
            IERC20(_token).transferFrom(msg.sender, _to, _price.sub(_creatorRoyalty + _platformFee));
            IERC20(_token).transferFrom(msg.sender, tokenCreators[_tokenId], _creatorRoyalty);
        }

        _lock(_tokenId);
        _pause(_tokenId);
    }

    function sendToAdmin(address _token, address _admin, uint256 _amount, uint256 _tokenId) public payable{
        require(_token.isContract() || _token == address(0), "Token isn`t a contract address");

         if(_token == address(0)){
            payable(_admin).transfer(msg.value);
        }else {
            require(IERC20(_token).balanceOf(msg.sender) >= _amount, "Insufficient funds");
            IERC20(_token).transferFrom(msg.sender, _admin, _amount);
        }

        emit FundsTransfer(_tokenId, _amount == 0? msg.value : _amount, msg.sender);
    }

    function getAllTokensObjs() public view returns(Token[] memory) {
        Token[] memory _tokensObj = new Token[](_allTokens.length);

        uint256 _id = 1;
        while(_allTokens.length >= _id){
            Token memory _token = Token({
                id:    _id,
                price: prices[_id],
                token: tokenAddress[_id],
                owner: _owners[_id],
                creator: tokenCreators[_id],
                uri:   _tokenURIs[_id],
                status: isForSale(_id),
                isLocked: isLock(_id)
            });

            _tokensObj[_id-1] = _token;
            _id++;
        }

        return _tokensObj;
    }

    function getAllTokensByPage(uint256 _from, uint256 _to) public view returns(Token[] memory) {
        require(_from < _to, "From is bigger than to");

        uint256 _last = (_to > _allTokens.length) ? _allTokens.length : _to;

        Token[] memory _tokens = new Token[](_to-_from + 1);

        uint256 _j = 0;

        for(uint256 i=_from; i<=_last; i++) {
            Token memory _token = Token({
                id:    i,
                price: prices[i],
                token: tokenAddress[i],
                owner: _owners[i],
                creator: tokenCreators[i],
                uri:   _tokenURIs[i],
                status: isForSale(i),
                isLocked: isLock(i)
            });

            _tokens[_j++] = _token;
        }

        return _tokens;
    }

    function getTokensByUserObjs(address _user) public view returns(Token[] memory) {
        Token[] memory _tokens = new Token[](_balances[_user]);

        for(uint256 i=0; i<_tokens.length; i++) {
            if(_ownedTokens[_user][i] != 0) {
                uint256 _tokenId = _ownedTokens[_user][i];
                Token memory _token = Token({
                    id:    _tokenId,
                    price: prices[_tokenId],
                    token: tokenAddress[_tokenId],
                    owner: _user,
                    creator: tokenCreators[_tokenId],
                    uri:   _tokenURIs[_tokenId],
                    status: isForSale(_tokenId),
                    isLocked: isLock(_tokenId)
                });

                _tokens[i] = _token;
            }
        }

        return _tokens;
    }

    function getTokenInfo(uint256 _tokenId) public view returns(Token memory) {
        Token memory _token = Token({
            id: _tokenId,
            price: prices[_tokenId],
            token: tokenAddress[_tokenId],
            owner: _owners[_tokenId],
            creator: tokenCreators[_tokenId],
            uri: _tokenURIs[_tokenId],
            status: isForSale(_tokenId),
            isLocked: isLock(_tokenId)
        });

        return _token;
    }

    function getCreatorsTokens(address _creator) public view returns(uint256[] memory) {
        return creatorsTokens[_creator];
    }

    function getCreatorsTokensObj(address _creator) public view returns(Token[] memory) {
        Token[] memory _tokens = new Token[](creatorsTokens[_creator].length);

        for(uint256 i=0; i<_tokens.length; i++) {
            uint256 _tokenId = creatorsTokens[_creator][i];
            Token memory _token = Token({
                id: _tokenId,
                price: prices[_tokenId],
                token: tokenAddress[_tokenId],
                owner: _owners[_tokenId],
                creator: _creator,
                uri: _tokenURIs[_tokenId],
                status: isForSale(_tokenId),
                isLocked: isLock(_tokenId)
            });

            _tokens[i] = _token;
        }


        return _tokens;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/*
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

pragma solidity >=0.8.4 <= 0.8.6;

interface ILockable {

    event SetLock(uint256 _tokenId, bool _isLock);

    function lock(uint256 _tokenId) external;

    function unlock(uint256 _tokenId) external;

    function isLock(uint256 _tokenId) external view returns(bool);
}

pragma solidity >=0.8.4 <= 0.8.6;

interface IERC721Pausable {

    event Paused(uint256 _tokenId);//, uint256 _timeSec);
    event Resumed(uint256 _tokenId);
    
    function pause(uint256 _tokenId) external;

    //function pause(uint256 _tokenId, uint256 _timeSec) external returns(bool);

    function resume(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity >=0.8.4 <= 0.8.6;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safeTransfer`. This function MUST return the function selector,
   * otherwise the caller will revert the transaction. The selector to be
   * returned can be obtained as `this.onERC721Received.selector`. This
   * function MAY throw to revert and reject the transfer.
   * Note: the ERC721 contract address is always the message sender.
   * @param operator The address which called `safeTransferFrom` function
   * @param from The address which previously owned the token
   * @param tokenId The NFT identifier which is being transferred
   * @param data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  )
    external
    returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <=0.8.6;

import "./IERC721.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC721Enumerable.sol";
import "./extensions/ILockable.sol";
import "./ERC721Receiver.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Enumerable, IERC721Metadata, ILockable, ERC721Receiver {
    using Address for address;
    using Strings for uint256;

    event AdminSet(address _admin, bool _isAdmin);
    
    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;

    address payable owner;

    string private _name;

    string private _symbol;

    uint256[] internal _allTokens;

    mapping(uint256 => address) internal _owners;

    mapping(address => uint256) internal _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => bool) admins;
    
    mapping(uint256 => bool) lockedTokens;

    mapping(uint256 => string) internal _tokenURIs;

    mapping(address => mapping(uint256 => uint256)) internal _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    mapping(uint256 => uint256) private _allTokensIndex;

    struct Token {
        uint256 id;
        uint256 price;
        address token;
        address owner;
        address creator;
        string uri;
        bool status;
        bool isLocked;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner");
        _;
    }

     modifier onlyAdmin() {
        require(admins[msg.sender] || owner == msg.sender, "Only admin or owner");
        _;
    }

    modifier tokenNotFound(uint256 _tokenId) {
        require(exists(_tokenId), "Token isn't exist");
        _;
    }

    modifier isUnlock(uint256 _tokenId) {
        require(!isLock(_tokenId), "Token is locked");
        _;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address _owner) public view virtual override returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balances[_owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address _owner = _owners[tokenId];
        require(_owner != address(0), "ERC721: owner query for nonexistent token");
        return _owner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address _owner = ERC721.ownerOf(tokenId);
        require(to != _owner, "ERC721: approval to current owner");

        require(
            _msgSender() == _owner || isApprovedForAll(_owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address _owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[_owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(exists(tokenId), "ERC721: operator query for nonexistent token");
        address _owner = ERC721.ownerOf(tokenId);
        return (spender == _owner || getApproved(tokenId) == spender || isApprovedForAll(_owner, spender));
    }

    function _safeMint(address to, uint256 tokenId, string memory uri) internal virtual {
        _safeMint(to, tokenId, "", uri);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data,
        string memory _uri
    ) internal virtual {
        _mint(to, tokenId, _uri);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId, string memory uri) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _setTokenURI(tokenId, uri);

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try ERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == ERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function tokenOfOwnerByIndex(address _owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[_owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from == address(0)) {
            _allTokensIndex[tokenId] = _allTokens.length;
            _allTokens.push(tokenId);
        } else if (from != to) {
            uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
            uint256 tokenIndex = _ownedTokensIndex[tokenId];

            if (tokenIndex != lastTokenIndex) {
                uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

                _ownedTokens[from][tokenIndex] = lastTokenId; 
                _ownedTokensIndex[lastTokenId] = tokenIndex;
            }

            delete _ownedTokensIndex[tokenId];
            delete _ownedTokens[from][lastTokenIndex];
        }
        if (to == address(0)) {
            uint256 lastTokenIndex = _allTokens.length - 1;
            uint256 tokenIndex = _allTokensIndex[tokenId];

            uint256 lastTokenId = _allTokens[lastTokenIndex];

            _allTokens[tokenIndex] = lastTokenId; 
            _allTokensIndex[lastTokenId] = tokenIndex;

            delete _allTokensIndex[tokenId];
            _allTokens.pop();
        } else if (to != from) {
            uint256 length = ERC721.balanceOf(to);
            _ownedTokens[to][length] = tokenId;
            _ownedTokensIndex[tokenId] = length;
        }
    }
 
  function name() external override view returns (string memory) {
    return _name;
  }

  function symbol() external override view returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) external override view returns (string memory) {
    require(ERC721.exists(tokenId));
    return _tokenURIs[tokenId];
  }

  function _setTokenURI(uint256 tokenId, string memory uri) internal {
    require(ERC721.exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

    function lock(uint256 _tokenId) public override tokenNotFound(_tokenId) isUnlock(_tokenId) onlyAdmin{
        _transfer(ownerOf(_tokenId), address(0), _tokenId);
        _lock(_tokenId);
    }

    function _lock(uint256 _tokenId) internal {
        lockedTokens[_tokenId] = true;

        emit SetLock(_tokenId, true);
    }

    function unlock(uint256 _tokenId) public override tokenNotFound(_tokenId) onlyAdmin{
        require(isLock(_tokenId), "Token is already unlocked");
        lockedTokens[_tokenId] = false;

        emit SetLock(_tokenId, false);
    }

    function _unlock(uint256 _tokenId) internal {
        lockedTokens[_tokenId] = false;

        emit SetLock(_tokenId, false);
    }

    function isLock(uint256 _tokenId) public view override returns(bool) {
        return lockedTokens[_tokenId];
    }

    function setAdmin(address _user, bool _isAdmin) public onlyOwner() {
        require(!isAdmin(_user), "User is already admin");
        admins[_user] = _isAdmin;

        emit AdminSet(_user, _isAdmin);
    }

    function isAdmin(address _admin) public view returns(bool) {
        return admins[_admin];
    }
}