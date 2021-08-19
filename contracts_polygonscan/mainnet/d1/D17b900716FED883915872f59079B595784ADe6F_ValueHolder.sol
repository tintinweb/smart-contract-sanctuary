/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

// File: polygon_contracts/interfaces/IExternalPool.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExternalPool {
    function enterToken() external view returns (address);

    function LPToken() external view returns (address);

    function getPoolValue(address denominator) external view returns (uint256);

    function getTokenStaked() external view returns (uint256);

    function getLPStaked() external view returns (uint256);

    function addPosition(address token) external returns (uint256);

    function exitPosition(uint256 amount) external;

    function stakeLP() external;

    function unstakeLP(uint256 amount) external;

    function unstakeAllLP() external;

    function claimValue() external;

    function transferTokenTo(
        address TokenAddress,
        address recipient,
        uint256 amount
    ) external returns (uint256);

    function compoundHarvest() external returns (uint256);

    function removeLiquidity(uint256 amount) external;
}

// File: polygon_contracts/interfaces/IERC20.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function decimals() external view returns (uint8);

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

// File: polygon_contracts/interfaces/ISFToken.sol


pragma solidity ^0.8.0;


interface ISFToken is IERC20 {
    function rebase(uint256 _totalSupply) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

// File: polygon_contracts/interfaces/IBEP20.sol


pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: polygon_contracts/interfaces/IXChangerPolygon.sol


pragma solidity ^0.8.0;


interface XChanger {
    function swap(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount,
        bool slipProtect
    ) external payable returns (uint256 result);

    function quote(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount
    )
        external
        view
        returns (
            uint256 returnAmount,
            uint256[5] memory swapAmountsIn,
            uint256[5] memory swapAmountsOut,
            address swapVia
        );

    /*
    function reverseQuote(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 returnAmount
    )
        external
        view
        returns (
            uint256 inputAmount,
            uint256[5] memory swapAmountsIn,
            uint256[5] memory swapAmountsOut,
            bool swapVia
        );
    */
}

// File: polygon_contracts/XChangerUserPolygon.sol



pragma solidity ^0.8.0;



/**
 * @dev Helper contract to communicate to XChanger(XTrinity) contract to obtain prices and change tokens as needed
 */
contract XChangerUser {
    XChanger public xchanger;

    uint256 private constant ex_count = 5;

    /**
     * @dev get a price of one token amount in another
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken
     */

    function quote(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount
    ) public view returns (uint256 returnAmount) {
        if (fromToken == toToken) {
            returnAmount = amount;
        } else {
            try xchanger.quote(fromToken, toToken, amount) returns (
                uint256 _returnAmount,
                uint256[ex_count] memory, //swapAmountsIn,
                uint256[ex_count] memory, //swapAmountsOut,
                address //swapVia
            ) {
                returnAmount = _returnAmount;
            } catch {}
        }
    }

    /**
     * @dev swap one token to another given the amount we want to spend
     
     * @param fromToken - token we want to change/spend
     * @param toToken - token we want to receive/spend to
     * @param amount - of the fromToken we are spending
     * @param slipProtect - flag to ensure the transaction will be performed if the received amount is not less than expected within the given slip %% range (like 1%)
     */
    function swap(
        IBEP20 fromToken,
        IBEP20 toToken,
        uint256 amount,
        bool slipProtect
    ) public payable returns (uint256 returnAmount) {
        allow(fromToken, address(xchanger), amount);
        returnAmount = xchanger.swap(fromToken, toToken, amount, slipProtect);
    }

    /**
     * @dev function to fix allowance if needed
     */
    function allow(
        IBEP20 token,
        address spender,
        uint256 amount
    ) internal {
        if (token.allowance(address(this), spender) < amount) {
            token.approve(spender, 0);
            token.approve(spender, type(uint256).max);
        }
    }

    /**
     * @dev payable fallback to allow for WBNB withdrawal
     */
    receive() external payable {}

    fallback() external payable {}
}

// File: polygon_contracts/interfaces/IWETH.sol



pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

// File: polygon_contracts/access/Context.sol


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: polygon_contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function initialize() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    /*
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }*/

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: polygon_contracts/utils/ReentrancyGuard.sol



pragma solidity >0.8.0;

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

    /**
     * @dev useful addon to limit one call per block - to be used with multiple different excluding methods - e.g. mint and burn
     *
     */

    mapping(address => uint256) public lastblock;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        /**
         * @dev useful addon to limit one call per block - to be used with multiple different excluding methods - e.g. mint and burn
         *
         */
        require(
            lastblock[tx.origin] != block.number,
            "Reentrancy: this block is used"
        );
        lastblock[tx.origin] = block.number;

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: polygon_contracts/ElasticToken.sol


pragma solidity ^0.8.0;


/**
 * @title uFragments ERC20 token
 * @dev This is part of an implementation of the uFragments Ideal Money protocol.
 *      uFragments is a normal ERC20 token, but its supply can be adjusted by splitting and
 *      combining tokens proportionally across all wallets.
 *
 *      uFragment balances are internally represented with a hidden denomination, 'gons'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'gons' and the public 'fragments'.
 */
contract ElasticToken is Ownable {
    // PLEASE READ BEFORE CHANGING ANY ACCOUNTING OR MATH
    // Anytime there is division, there is a risk of numerical instability from rounding errors. In
    // order to minimize this risk, we adhere to the following guidelines:
    // 1) The conversion rate adopted is the number of gons that equals 1 fragment.
    //    The inverse rate must not be used--TOTAL_GONS is always the numerator and _totalSupply is
    //    always the denominator. (i.e. If you want to convert gons to fragments instead of
    //    multiplying by the inverse rate, you should divide by the normal rate)
    // 2) Gon balances converted into Fragments are always rounded down (truncated).
    //
    // We make the following guarantees:
    // - If address 'A' transfers x Fragments to address 'B'. A's resulting external balance will
    //   be decreased by precisely x Fragments, and B's external balance will be precisely
    //   increased by x Fragments.
    //
    // We do not guarantee that the sum of all balances equals the result of calling totalSupply().
    // This is because, for any conversion function 'f()' that has non-zero rounding error,
    // f(x0) + f(x1) + ... + f(xn) is not always equal to f(x0 + x1 + ... xn).

    address public valueHolder;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    /**
     * @dev Modifier for certain methods that are controlled only by ValueHolder contract - rebase, mint, burn
     */
    modifier onlyValueHolder() {
        require(msg.sender == valueHolder, "Not Value Holder");
        _;
    }

    uint256 private constant DECIMALS = 18;
    // MAX amount is reduced by 10**6 to allow space for minting
    uint256 private constant MAX_uint = type(uint256).max;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        5000 * 10**6 * 10**DECIMALS;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint for max granularity.
    uint256 private constant TOTAL_GONS =
        MAX_uint - (MAX_uint % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private _totalGons;
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address private _owner;
    bool private initialized;

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

    event LogValueHolderUpdated(address valueHolder);
    event LogRebase(uint256 totalSupply);

    /**
     * @dev Sets a new ValueHolder contract address
     */
    function setValueHolder(address _valueHolder) external onlyOwner {
        valueHolder = _valueHolder;
        emit LogValueHolderUpdated(_valueHolder);
    }

    /**
     * @dev initializer method instead of a constructor - to be used behind a proxy
     */
    function init (string memory newName, string memory newSymbol) public {
        require(!initialized, "Contract already initialized");
        initialized = true;

        _name = newName;
        _symbol = newSymbol;
        _decimals = uint8(DECIMALS);
        Ownable.initialize(); // Do not forget this call!

        _totalGons = TOTAL_GONS;
        _gonBalances[msg.sender] = _totalGons;
        valueHolder = msg.sender;
        _owner = msg.sender;

        rebase(INITIAL_FRAGMENTS_SUPPLY);
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @param _newSupply New total token supply
     */
    function rebase(uint256 _newSupply) public onlyValueHolder {
        _totalSupply = _newSupply;
        _gonsPerFragment = _totalGons / _newSupply;

        emit LogRebase(_newSupply);
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view returns (uint256) {
        return _gonBalances[who] / _gonsPerFragment;
    }

    /**
     * Returns the bep20 token owner which is necessary for binding with bep2 token.
     */

    function getOwner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return True on success, false otherwise.
     */
    function transfer(address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
        uint256 gonValue = value * _gonsPerFragment;
        if (gonValue > _gonBalances[msg.sender]) {
            gonValue = _gonBalances[msg.sender];
            value = gonValue / _gonsPerFragment;
        }
        _gonBalances[msg.sender] = _gonBalances[msg.sender] - (gonValue);
        _gonBalances[to] = _gonBalances[to] + gonValue;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner has allowed to a spender.
     * @param owner_ The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return The number of tokens still available for the spender.
     */
    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address you want to send tokens from.
     * @param to The address you want to transfer to.
     * @param value The amount of tokens to be transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public validRecipient(to) returns (bool) {
        _allowedFragments[from][msg.sender] =
            _allowedFragments[from][msg.sender] -
            value;

        uint256 gonValue = value * _gonsPerFragment;
        if (gonValue > _gonBalances[msg.sender]) {
            gonValue = _gonBalances[msg.sender];
            value = gonValue / _gonsPerFragment;
        }

        _gonBalances[from] = _gonBalances[from] - gonValue;
        _gonBalances[to] = _gonBalances[to] + gonValue;
        emit Transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of
     * msg.sender. This method is included for ERC20 compatibility.
     * increaseAllowance and decreaseAllowance should be used instead.
     * Changing an allowance with this method brings the risk that someone may transfer both
     * the old and the new allowance - if they are both greater than zero - if a transfer
     * transaction is mined before the later approve() call is mined.
     *
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner has allowed to a spender.
     * This method should be used instead of approve() to avoid the double approval vulnerability
     * described above.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender] +
            addedValue;
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner has allowed to a spender.
     *
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue - subtractedValue;
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }
}

// File: polygon_contracts/DeployElastic2.sol


pragma solidity ^0.8.0;


contract DeployElastic {
    event Deployed(address addr, uint256 salt);

    // 1. Get bytecode of contract to be deployed
    // NOTE: _owner and _foo are arguments of the ElasticToken's constructor
    function getBytecode()
        public
        pure
        returns (
            //string memory newName, string memory newSymbol)
            bytes memory
        )
    {
        bytes memory bytecode = type(ElasticToken).creationCode;

        //return abi.encodePacked(bytecode, abi.encode(newName, newSymbol));
        return bytecode;
    }

    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddress(bytes memory bytecode, uint256 _salt)
        public
        view
        returns (address)
    {
        bytes32 hash =
            keccak256(
                abi.encodePacked(
                    bytes1(0xff),
                    address(this),
                    _salt,
                    keccak256(bytecode)
                )
            );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    // 3. Deploy the contract
    // NOTE:
    // Check the event log Deployed which contains the address of the deployed TestContract.
    // The address in the log should equal the address computed from above.
    function deploy(bytes memory bytecode, uint256 _salt)
        public
        payable
        returns (address addr)
    {
        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                _salt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, _salt);
    }

    function doDeploy(
        string memory newName,
        string memory newSymbol,
        uint256 salt
    ) public returns (address addr) {
        addr = deploy(getBytecode(), salt);

        ElasticToken newContract = ElasticToken(addr);
        newContract.init(newName, newSymbol);
    }
}

// File: polygon_contracts/ValueHolderElasticPolygon.sol


pragma solidity ^0.8.0;









/**
 * @title ValueHolder main administrative contract
 * @dev Main contract controlling the Mint/Burn/Rebase operations of a token.
 * Retrieves values from a multiple external/internal (Uni) pools in denominated [DAI] tokens
 */
contract ValueHolder is Ownable, XChangerUser, ReentrancyGuard, DeployElastic {
    mapping(uint256 => IExternalPool) public elasticPools;
    mapping(IExternalPool => ISFToken) public elasticTokens;

    uint256 public epLen;
    uint256 private constant fpDigits = 8;
    uint256 private constant fpNumbers = 10**fpDigits;

    event LogManagerUpdated(address manager);
    event LogGnosisUpdated(address gnosis);
    event LogSFTokenUpdated(address newSFToken);
    event LogXChangerUpdated(address newXChanger);
    event LogMintTaken(uint256 fromTokenAmount);
    event LogBurnGiven(uint256 toTokenAmount);
    event ElasticTokenCreated(address Token);
    event ElasticTokenRebased(address Pool, address Token, uint256 value);

    address public manager;
    address public gnosis;

    bool public unfoldLP;
    bool private initialized;

    /**
     * @dev some functions should be available only to Gnosis address
     */
    modifier onlyGnosis() {
        require(msg.sender == gnosis, "Not Gnosis");
        _;
    }

    /**
     * @dev some functions should be available only to Manager address
     */
    modifier onlyManager() {
        require(msg.sender == manager || isOwner(), "Not Manager");
        _;
    }

    /**
     * @dev initializer method instead of a constructor - to be used behind a proxy
     */
    function init(address initXchanger) external {
        require(!initialized, "Initialized");
        initialized = true;
        _initVariables(initXchanger);
        Ownable.initialize(); // Do not forget this call!
    }

    /**
     * @dev internal variable initialization
     * @param initXchanger - XChanger(XTrinity) contract to be used for quotes and swaps
     */
    function _initVariables(address initXchanger) internal {
        gnosis = msg.sender;
        manager = msg.sender;
        xchanger = XChanger(initXchanger);
        unfoldLP = true;
    }

    /**
     * @dev re-initializer might be helpful for the cases where proxy's storage is corrupted by an old contact, but we cannot run init as we have the owner address already.
     * This method might help fixing the storage state.
     */
    function reInit(address initXchanger) external onlyOwner {
        _initVariables(initXchanger);
    }

    /**
     * @dev set new Gnosis address
     */
    function setGnosis(address newGnosis) external onlyOwner {
        gnosis = newGnosis;
        emit LogGnosisUpdated(newGnosis);
    }

    /**
     * @dev set new Value Manager address
     */
    function setManager(address newManager) external onlyOwner {
        manager = newManager;
        emit LogManagerUpdated(newManager);
    }

    /**
     * @dev set new XChanger/XTrinity address
     */
    function setXChangerImpl(address newXchanger) external onlyOwner {
        xchanger = XChanger(newXchanger);
        emit LogSFTokenUpdated(newXchanger);
    }

    /**
     * @dev set new unFoldLP variable
     */
    function setUnFoldLP(bool newUnfoldLP) external onlyOwner {
        unfoldLP = newUnfoldLP;
    }

    /**
     * @dev Value Manager can only access the tokens at this contract. Normally it is not used in the workflow.
     */
    function retrieveToken(address tokenAddress)
        external
        onlyGnosis
        returns (uint256)
    {
        IBEP20 Token = IBEP20(tokenAddress);
        uint256 balance = Token.balanceOf(address(this));
        Token.transfer(msg.sender, balance);
        return balance;
    }

    /**
     * @dev Main mint S/F token method
     * takes any token, converts it as required and puts it into a default (Voted) pool
     * resulting additional value is minted as S/F tokens (denominated in [DAI])
     */

    function mint(address fromToken, uint256 i)
        external
        onlyGnosis
        nonReentrant
    {
        IBEP20 tokenBEP20 = IBEP20(fromToken);
        uint256 available_amount = tokenBEP20.balanceOf(msg.sender);
        if (available_amount > 0) {
            tokenBEP20.transferFrom(
                msg.sender,
                address(this),
                available_amount
            );
        }

        tokenBEP20.transfer(
            address(elasticPools[i]),
            tokenBEP20.balanceOf(address(this))
        );

        elasticPools[i].addPosition(fromToken);

        _rebaseOnChain(i);
    }

    function mintLP(uint256 i) external onlyGnosis nonReentrant {
        transferLPtoPool(i);
        elasticPools[i].stakeLP();
        _rebaseOnChain(i);
    }

    function transferLPtoPool(uint256 i) public onlyGnosis {
        address LPToken_address = elasticPools[i].LPToken();
        require(LPToken_address != address(0), "No pool LP Token");
        IBEP20 LPToken = IBEP20(LPToken_address);

        uint256 senderLPBalance = LPToken.balanceOf(msg.sender);

        if (
            senderLPBalance > 0 &&
            LPToken.allowance(msg.sender, address(this)) >= senderLPBalance
        ) {
            LPToken.transferFrom(msg.sender, address(this), senderLPBalance);
        }

        uint256 localLPBalance = LPToken.balanceOf(address(this));
        require(localLPBalance > 0, "No LP Token balance");

        LPToken.transfer(address(elasticPools[i]), localLPBalance);
    }

    /**
     * @dev Main method to burn S/F tokens and get back the requested amount from denominated token [DAI] to user
     * NB: flashloan attacks shold be discouraged
     * NB: considering to split it into 2 separate transactions, to disregard the flashloan use. 
    
     */
    function burnLP(uint256 i, uint256 amount)
        external
        onlyGnosis
        nonReentrant
    {
        // limit by existing balance - be can burn only that value and no more than that
        uint256 senderBalance = elasticTokens[elasticPools[i]].balanceOf(
            msg.sender
        );
        if (senderBalance < amount) {
            amount = senderBalance;
        }

        uint256 amountLPToUnstake = (elasticPools[i].getLPStaked() * amount) /
            elasticTokens[elasticPools[i]].totalSupply();

        getLP(i, amountLPToUnstake);
        _rebaseOnChain(i);
    }

    function getLP(uint256 i, uint256 amountLP) public onlyGnosis {
        address LPToken_address = elasticPools[i].LPToken();
        require(LPToken_address != address(0), "No pool LP Token");

        elasticPools[i].unstakeLP(amountLP);
        getExtraSteps(i, amountLP);
    }

    function burnAllLP(uint256 i) external onlyGnosis nonReentrant {
        getAllLP(i);
        _rebaseOnChain(i);
    }

    function getAllLP(uint256 i) public onlyGnosis {
        uint256 amountLP = elasticPools[i].getLPStaked();
        getLP(i, amountLP);
    }

    function getExtraSteps(uint256 i, uint256 amountLP) internal {
        address LPToken_address = elasticPools[i].LPToken();
        address enterToken_address = elasticPools[i].enterToken();

        require(LPToken_address != address(0), "No pool LP Token");
        //extra steps to unwind - if available
        if (unfoldLP) {
            try elasticPools[i].removeLiquidity(amountLP) {} catch {}
        }

        try elasticPools[i].compoundHarvest() {} catch {}

        // transfer back to Gnosis
        transferFromPool(i, enterToken_address, type(uint256).max);
        transferFromPool(i, LPToken_address, type(uint256).max);
    }

    /**
     * @dev Function to transfer to Gnosis any token from the pool
     * @param TokenAddress - address of the token
     */

    function transferFromPool(
        uint256 i,
        address TokenAddress,
        uint256 amount
    ) public onlyGnosis {
        elasticPools[i].transferTokenTo(TokenAddress, msg.sender, amount);
    }

    /**
     * @dev Internal function to rebase ElasticToken with given value
     * @param value - Total supply of ElasticToken
     */

    function _rebase(uint256 i, uint256 value) internal {
        elasticTokens[elasticPools[i]].rebase(value);
        emit ElasticTokenRebased(
            address(elasticPools[i]),
            address(elasticTokens[elasticPools[i]]),
            value
        );
    }

    /**
     * @dev Internal function to rebase main S/F token with the value
     * as confirmed by on-chain quotes from XChanger(XTrinity) contract
     * Consumes more gas, therefore it will be used only when minting/burning
     */
    function _rebaseOnChain(uint256 i) internal {
        uint256 value = getPoolValue(elasticPools[i]) + 1;
        _rebase(i, value);
    }

    /**
     * @dev ValueManager can run onchain rebase any time as required
     */
    function rebase(uint256 i) public onlyManager {
        _rebaseOnChain(i);
    }

    /**
     * @dev ValueManager can run an arbitrary rebase too - to save on gas as this TX is much cheaper
     * This is really a workaround that should be disregarded by the community
     */
    function rebase(uint256 i, uint256 value) external onlyManager {
        _rebase(i, value);
    }

    function getPoolValue(IExternalPool pool)
        public
        view
        returns (uint256 value)
    {
        // Check if pool exists if it can return method values
        try pool.enterToken() returns (address poolEnterToken) {
            value = pool.getPoolValue(poolEnterToken);
        } catch {
            revert("Pool does not exist");
        }
    }

    function getPoolName(uint256 i) public view returns (string memory name) {
        IExternalPool pool = elasticPools[i];
        name = IBEP20(address(elasticTokens[pool])).name();
    }

    /**
     * @dev add new Elastic pool - only by Manager
     */
    function addElasticPool(
        address pool,
        string memory newName,
        string memory newSymbol,
        uint256 salt
    ) external onlyManager {
        IExternalPool elasticPool = IExternalPool(pool);

        // Check if pool exists if it can return method values
        getPoolValue(elasticPool);

        elasticPools[epLen] = elasticPool;

        address addr = doDeploy(newName, newSymbol, salt);
        emit ElasticTokenCreated(addr);
        ISFToken poolEPToken = ISFToken(addr);

        elasticTokens[elasticPool] = poolEPToken;
        poolEPToken.transfer(gnosis, poolEPToken.balanceOf(address(this)));
        _rebaseOnChain(epLen);
        epLen++;
    }

    /**
     * @dev remove a Uni pool - only by Manager
     */
    function delElasticPool(uint256 i) external onlyManager {
        elasticPools[i] = IExternalPool(address(0));
    }

    /**
     * @dev to fix the length on the elasticPools pool array
     * might be not needed but good for testing/fixing storage state
     */
    function setEpLen(uint256 i) external onlyManager {
        epLen = i;
    }
}