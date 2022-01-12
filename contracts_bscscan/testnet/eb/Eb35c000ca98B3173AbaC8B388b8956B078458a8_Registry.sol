// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./interfaces/IRegistry.sol";
import "./interfaces/ISwap.sol";
import "./Vault.sol";

contract Registry is IRegistry {

    // administrator of Registry contract
    address private admin;
    // total number of vaults
    uint256 public numVaults;

    uint256 public platformFee = 15;
    uint256 public maxNumTokens = 10;

    mapping(bytes32 => address) private vaults;
    mapping(address => address) private vaultCreators;

    constructor() {
        admin = msg.sender;
    }

    function registerVault(
        string calldata _vaultName, 
        string calldata _nTokenName,
        string calldata _nTokenSymbol,
        address[] calldata _tokenAddresses,
        uint256[] calldata _percents,
        ISwap _swap
    ) external override {
        bytes32 identifier = keccak256(abi.encodePacked(_vaultName));
        // Check vault name existence
        require(vaults[identifier] == address(0), Errors.VAULT_NAME_DUP);

        require(_tokenAddresses.length > 0, Errors.VL_INVALID_TOKENOUTS);
        require(_tokenAddresses.length <= maxNumTokens, Errors.EXCEED_MAX_NUMBER);

        Vault vault = new Vault(
            msg.sender,
            admin,
            _vaultName, 
            _nTokenName, 
            _nTokenSymbol, 
            _tokenAddresses, 
            _percents,
            _swap
        );
        vaults[identifier] = address(vault);
        vaultCreators[address(vault)] = msg.sender;
        numVaults++;
    }

    function isRegistered(
        string memory _vaultName
    ) external view override returns(bool) {
        bytes32 identifier = keccak256(
            abi.encodePacked(
                _vaultName
            )
        );

        if(vaults[identifier] == address(0)) return false;
        else return true;
    }

    function vaultAddress(
        string memory _vaultName
    ) external view override returns(address) {
        bytes32 identifier = keccak256(
            abi.encodePacked(
                _vaultName
            )
        );
        return vaults[identifier];
    }

    function vaultCreator(
        address _vault
    ) external view override returns(address) {
        return vaultCreators[_vault];
    }

    function setPlatformFee(uint256 _fee) public {
        platformFee = _fee;
    }

    function getPlatformFee() public view override returns(uint256) {
        return platformFee;
    }

    function setMaxNumTokens(uint256 _num) public {
        maxNumTokens = _num;
    }

    function getMaxNumTokens() public view override returns(uint256) {
        return maxNumTokens;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ISwap.sol";

interface IRegistry {
    function registerVault(
        string calldata _vaultName,
        string calldata _nTokenName,
        string calldata _nTokenSymbol,
        address[] calldata _tokenAddresses,
        uint256[] calldata _percents,
        ISwap _swap
    ) external;

    function isRegistered(
        string memory _vaultName
    ) external view returns(bool);

    function vaultAddress(
        string memory _vaultName
    ) external view returns(address);

    function vaultCreator(
        address _vault
    ) external view returns(address);

    function getPlatformFee() external view returns(uint256);

    function getMaxNumTokens() external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface ISwap {
    function wBNB() external pure returns(address);

    function swapBNBForTokens(
        address _tokenOut,
        uint _amountOutMin,
        address _to
    ) external payable;

    function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn
    )  external view returns (uint);

    function swapTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin,
        address _to
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ISwap.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/INToken.sol";
import "./libraries/Errors.sol";
import "./NToken.sol";
// import "./VaultStorage.sol";

contract Vault is IVault {

    using SafeMath for uint256;

    address public constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // treasury account to save Platform Fee
    address private treasury;

    // vault's creator address
    address public creator;

    // vault name
    string public vaultName;
    address[] public investors;
    uint256 public numInvestors;

    mapping(address => uint256) public balances;
    mapping(address => bool) public isInvestor;
    mapping(address => uint256) public prevTVL;
    
    INToken internal nToken;
    ISwap internal navePortfolioSwap;
    IRegistry internal registry;

    TokenOut[] public tokenOuts;

    uint256 public totalBNBAmount;

    modifier validAmount(uint256 amount) {
        require(amount != 0, Errors.VL_INVALID_AMOUNT);
        _;
    }

    modifier onlyTreasury {
        require(msg.sender == treasury, Errors.NOT_ADMIN);
        _;
    }

    modifier onlyCreator {
        require(msg.sender == creator, Errors.VL_NOT_CREATOR);
        _;
    }

    modifier onlyInvestor {
        require(isInvestor[msg.sender], Errors.VL_NOT_INVESTOR);
        _;
    }

    constructor(
        address _creator,
        address _treasury,
        string memory _vaultName, 
        string memory _nTokenName,
        string memory _nTokenSymbol,
        address[] memory _tokenAddresses,
        uint256[] memory _percents,
        ISwap _navePortfolioSwap
    ) {
        creator = _creator;
        treasury = _treasury;
        
        vaultName = _vaultName;

        navePortfolioSwap = _navePortfolioSwap;
        registry = IRegistry(msg.sender);

        // Create LP Token(NToken) contract
        nToken = new NToken(
            IVault(address(this)), 
            _nTokenName, 
            _nTokenSymbol
        );
        
        // Store vault token distribution
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenOuts.push(
                TokenOut(_tokenAddresses[i], _percents[i])
            );
        }

        emit Initialized(msg.sender, _vaultName, _nTokenName, _nTokenSymbol);
    }

    function setTreasury(address _treasury) public onlyTreasury {
        treasury = _treasury;
    }

    function deposit() external override payable validAmount(msg.value) {
        if(balances[msg.sender] == 0 && creator != msg.sender) {
            addInvestor(msg.sender);
        }
        balances[msg.sender] += msg.value;
        totalBNBAmount += msg.value;

        uint256 totalValueInBUSD = 0;
        for (uint256 i = 0; i < tokenOuts.length; i++) {
            uint256 tokenAmount = IERC20(tokenOuts[i].tokenAddress).balanceOf(address(this));
            if (tokenAmount != 0) {
                totalValueInBUSD += ISwap(navePortfolioSwap).getAmountOutMin(
                    tokenOuts[i].tokenAddress,
                    BUSD,
                    tokenAmount
                );
            }
            ISwap(navePortfolioSwap).swapBNBForTokens{
                value: msg.value * tokenOuts[i].percent / 100
            }(
                tokenOuts[i].tokenAddress, 
                0, 
                address(this)
            );
        }
        prevTVL[msg.sender] = totalValueInBUSD;
        
        uint256 amountInBUSD = ISwap(navePortfolioSwap).getAmountOutMin(
            ISwap(navePortfolioSwap).wBNB(),
            BUSD,
            msg.value
        );
        // Mint LP Tokens
        if (totalValueInBUSD == 0) {
            INToken(nToken).mint(msg.sender, amountInBUSD);
        } else {
            uint256 nTokenTotalSupply = INToken(nToken).scaledTotalSupply();
            INToken(nToken).mint(
                msg.sender, 
                amountInBUSD.mul(nTokenTotalSupply).div(totalValueInBUSD)
            );
        }

        emit Deposit(msg.sender, msg.value, amountInBUSD);
    }

    /**
   * @dev Withdraws BNB from the vault, burning the equivalent nTokens `amount` owned
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole nToken balance
   **/

    function withdraw(uint256 amount) external override onlyInvestor {
        if (amount == type(uint256).max) {
            removeInvestor(msg.sender);
        }
        uint256 nTokenBalance = INToken(nToken).getUserBalance(msg.sender);
        require(amount <= nTokenBalance, Errors.VL_NOT_ENOUGH_AMOUNT);

        for (uint256 i = 0; i < tokenOuts.length; i++) {
            uint256 tokenAmountToSwap = IERC20(tokenOuts[i].tokenAddress).balanceOf(address(this))
                .mul(amount)
                .div(INToken(nToken).scaledTotalSupply());

            swapToBNB(tokenOuts[i].tokenAddress, tokenAmountToSwap);
        }

        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, Errors.VL_WITHDRAW_FAILED);
        
        // burn LP Token
        INToken(nToken).burn(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function nTokenAddress() external view returns(address) {
        return address(nToken);
    }

    function addInvestor(address _investor) internal {
        numInvestors++;
        isInvestor[_investor] = true;
    }

    function removeInvestor(address _investor) internal {
        numInvestors--;
        delete isInvestor[_investor];
        delete balances[_investor];
    }

    function takePlatformFee() external onlyTreasury {
        uint256 nTokenSupply = INToken(nToken).scaledTotalSupply();
        uint256 creatorAmount = INToken(nToken).getUserBalance(creator);

        for (uint256 i = 0; i < tokenOuts.length; i++) {
            uint256 tokenAmountToSwap = IERC20(tokenOuts[i].tokenAddress)
                .balanceOf(address(this))
                .mul(IRegistry(registry).getPlatformFee())
                .mul(nTokenSupply.sub(creatorAmount))
                .div(nTokenSupply * 10**5);

            IERC20(tokenOuts[i].tokenAddress)
                .approve(address(navePortfolioSwap), tokenAmountToSwap);
            
            ISwap(navePortfolioSwap).swapTokensForTokens(
                tokenOuts[i].tokenAddress, 
                BUSD,
                tokenAmountToSwap,
                0, 
                treasury
            );
        }

        emit TakePlatformFee(treasury, block.timestamp);
    }

    function editTokens(
        address[] calldata _tokenAddresses,
        uint256[] calldata _percents
    ) external onlyCreator {
        require(_tokenAddresses.length > 0, Errors.VL_INVALID_TOKENOUTS);
        require(_tokenAddresses.length < IRegistry(registry).getMaxNumTokens(), Errors.EXCEED_MAX_NUMBER);
        
        for (uint256 i = 0; i < tokenOuts.length; i++) {
            uint256 tokenAmountToSwap = IERC20(tokenOuts[i].tokenAddress).balanceOf(address(this));
            
            swapToBNB(tokenOuts[i].tokenAddress, tokenAmountToSwap);
        }
        // initialize tokenOuts array
        delete tokenOuts;
        // set new token distribution
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            tokenOuts.push(
                TokenOut(_tokenAddresses[i], _percents[i])
            );
            ISwap(navePortfolioSwap).swapBNBForTokens{
                value: address(this).balance * tokenOuts[i].percent / 100
            }(
                tokenOuts[i].tokenAddress, 
                0, 
                address(this)
            );
        }
        emit EditTokens(address(this), _tokenAddresses.length, block.timestamp);
    }

    function swapToBNB(
        address tokenIn,
        uint256 amountToSwap
    ) internal {
        IERC20(tokenIn).approve(address(navePortfolioSwap), amountToSwap);
            
        ISwap(navePortfolioSwap).swapTokensForTokens(
            tokenIn, 
            ISwap(navePortfolioSwap).wBNB(),
            amountToSwap,
            0, 
            address(this)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IVault {
    struct TokenOut {
        address tokenAddress;
        uint256 percent;
    }

    event Initialized(
        address indexed creator, 
        string vaultName, 
        string nTokenName, 
        string nTokenSymbol
    );
    
    event EditTokens(
        address indexed vaultAddress,
        uint256 numTokens,
        uint256 timestamp
    );

    event TakePlatformFee(
        address indexed treasury,
        uint256 timestamp
    );

    event Deposit(address indexed from, uint amountInBNB, uint amountInBUSD);
    event Withdraw(address indexed to, uint amount);

    function deposit() external payable;
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface INToken {
    
    event Mint(address indexed from, uint256 value);
    event Burn(address indexed from, uint256 value);

    function mint(address user, uint256 amount) external;
    function burn(address user, uint256 amount) external;

    function scaledTotalSupply() external returns (uint256);
    function getUserBalance(address user) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Errors {
    string public constant VL_INVALID_AMOUNT = "1"; // Amount must be greater than 0
    string public constant VL_INVALID_TOKENOUTS = "2"; // Token to be distributed does not exist
    string public constant CT_CALLER_MUST_BE_VAULT = "3"; // The caller of this function must be a lending pool
    string public constant VL_NOT_CREATOR = "4"; // Not vault creator
    string public constant VL_NOT_INVESTOR = "5"; // Not vault investor
    string public constant VL_WITHDRAW_FAILED = "6"; // Failed to withdraw
    string public constant VL_NOT_ENOUGH_AMOUNT = "7"; // Not enough amount
    string public constant EXCEED_MAX_NUMBER = "8"; // Exceed max number of tokens
    string public constant VAULT_NAME_DUP = "9"; // Duplicated vault name
    string public constant NOT_ADMIN = "10"; // Not admin
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IVault.sol";
import "./interfaces/INToken.sol";
import "./libraries/Errors.sol";

contract NToken is ERC20, INToken {
    
    IVault internal vault;

    modifier onlyVault {
        require(msg.sender == address(vault), Errors.CT_CALLER_MUST_BE_VAULT);
        _;
    }

    constructor(
        IVault _vault,
        string memory _nTokenName,
        string memory _nTokenSymbol
    ) ERC20(_nTokenName, _nTokenSymbol) {
        vault = _vault;
    }

    function mint(
        address user,
        uint256 amount
    ) external override onlyVault {
        require(amount != 0, Errors.VL_INVALID_AMOUNT);
        _mint(user, amount);
        emit Mint(user, amount);
    }

    function burn(
        address user,
        uint256 amount
    ) external override onlyVault {
        require(amount != 0, Errors.VL_INVALID_AMOUNT);
        _burn(user, amount);
        emit Burn(user, amount);
    }

    function scaledTotalSupply() external view override returns (uint256) {
        return super.totalSupply();
    }

    function getUserBalance(address user) external view override returns (uint256) {
        return super.balanceOf(user);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
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
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
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
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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