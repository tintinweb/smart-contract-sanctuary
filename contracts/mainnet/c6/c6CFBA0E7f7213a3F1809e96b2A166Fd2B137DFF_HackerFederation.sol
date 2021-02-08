/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
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
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.6.6;

interface Token {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract HackerFederation {
    using SafeMath for uint256;

    // Hashrate decimals
    uint256 public constant hashRateDecimals = 5;
    // 10 usdt = 1 T
    uint256 public constant hashRatePerUsdt = 10;
    // Manager address
    address public owner;
    // Root address
    address public rootAddress;
    // Burn address
    address public burnAddress;

    // DAI-HE3 pair address
    address public daiToHe3Address;

    // DAI ERC20 address
    address public daiTokenAddress;
    Token tokenDai;
    // HE-3 ERC20 address
    address public he3TokenAddress;
    Token tokenHe3;

    // HE-1 ERC20 address
    address public he1TokenAddress;

    // Userinfo
    struct User {
        address superior;
        uint256 hashRate;
        bool isUser;
    }
    mapping(address => User) public users;

    // Buy hashrate event
    event LogBuyHashRate(address indexed owner, address indexed superior, uint256 hashRate);

    constructor(
        address _rootAddress, 
        address _burnAddress, 
        address _daiToHe3Address, 
        address _daiTokenAddress, 
        address _he3TokenAddress, 
        address _he1TokenAddress
    ) public {
        owner = msg.sender;
        rootAddress = _rootAddress;
        burnAddress = _burnAddress;
        daiToHe3Address = _daiToHe3Address;

        daiTokenAddress = _daiTokenAddress;
        tokenDai = Token(daiTokenAddress);

        he3TokenAddress = _he3TokenAddress;
        tokenHe3 = Token(he3TokenAddress);

        he1TokenAddress = _he1TokenAddress;
    }

    // Modifier func
    modifier onlyOwner() {
        require(msg.sender == owner, "This function is restricted to the owner");
        _;
    }

    modifier notAddress0(address newAddress) {
        require(newAddress != address(0), "Address should not be address(0)");
        _;
    }

    /**
     * Use HE-1 to buy hashrate
     *
     * Requirements:
     *
     * - `_tokenAmount`: Amount of HE-1 
     * - `_superior`: User's inviter
     */
    function buyHashRateWithHE1(uint256 _tokenAmount, address _superior) public {
        _buyHashRate(he1TokenAddress, _tokenAmount, _tokenAmount.div(10**12), _superior);
    }

    /**
     * Use HE-3 to buy hashrate
     *
     * Requirements:
     *
     * - `_tokenAmount`: Amount of HE-3
     * - `_superior`: User's inviter
     */
    function buyHashRateWithHE3(uint256 _tokenAmount, address _superior) public {
        uint256 totalDai = getHe3ToDai(_tokenAmount);
        _buyHashRate(he3TokenAddress, _tokenAmount, totalDai.div(10**12), _superior);
    }

    /**
     * Buy hashrate
     *
     * Requirements:
     *
     * - `_token`: HE-1 or HE-3 address
     * - `_tokenAmount`: Amount of token
     * - `_usdtAmount`: Value of _tokenAmount to USDT
     * - `_superior`: inviter
     */
    function _buyHashRate(address _tokenAddress,uint256 _tokenAmount, uint256 _usdtAmount, address _superior) internal {
        // require _superior
        require(users[_superior].isUser || _superior == rootAddress, "Superiorshould be a user or rootAddress");
        
        // burn the token sent by user
        bool sent = Token(_tokenAddress).transferFrom(msg.sender, burnAddress, _tokenAmount);
        require(sent, "Token transfer failed");

        // USDT decimals = 6
        require(_usdtAmount >= 10000000, "Usdt should be great than or equal 10");
        
        uint256 hashRate = _usdtAmount.div(10).div(hashRatePerUsdt);
        if (users[msg.sender].isUser) {
            users[msg.sender].hashRate = users[msg.sender].hashRate.add(hashRate);
        } else {
            users[msg.sender].superior = _superior;
            users[msg.sender].hashRate = hashRate;
            users[msg.sender].isUser = true;
        }
        
        // Buy hashrate event
        emit LogBuyHashRate(msg.sender, _superior, hashRate);
    }

    // Update owner address
    function updateOwnerAddress(address _newOwnerAddress) public onlyOwner {
        owner = _newOwnerAddress;
    }

    // Update burn address
    function updateBurnAddress(address _newBurnAddress) public onlyOwner {
        burnAddress = _newBurnAddress;
    }

    // update HE-3 contract address
    function updateHe3TokenAddress(address _he3TokenAddress) public onlyOwner notAddress0(_he3TokenAddress) {
        he3TokenAddress = _he3TokenAddress;
        tokenHe3 = Token(he3TokenAddress);
    }

    // update HE-1 contract address
    function updateHe1TokenAddress(address _he1TokenAddress) public onlyOwner notAddress0(_he1TokenAddress) {
        he1TokenAddress = _he1TokenAddress;
    }

    // update DAI contract address
    function updateDaiToHe3AddressAddress(address _daiToHe3Address) public onlyOwner notAddress0(_daiToHe3Address) {
        daiToHe3Address = _daiToHe3Address;
    }

    // update DAI-HE3 uniswap pair contract address
    function updateDaiTokenAddress(address _daiTokenAddress) public onlyOwner notAddress0(_daiTokenAddress) {
        daiTokenAddress = _daiTokenAddress;
        tokenDai = Token(daiTokenAddress);
    }

    /**
     * Is user?
     */
    function isUser(address _userAddress) public view returns (bool) {
        return users[_userAddress].isUser;
    }

    // Get amount 1 HE3 to DAI
    function getDaiPerHe3() public view returns (uint256) {
        return getHe3ToDai(10**18);
    }

    // Get amount _he3Amount HE3 to DAI 
    function getHe3ToDai(uint256 _he3Amount) internal view returns (uint256) {
        return tokenDai.balanceOf(daiToHe3Address).mul(_he3Amount).div(tokenHe3.balanceOf(daiToHe3Address));
    }
}