/**
 *Submitted for verification at BscScan.com on 2022-01-25
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Farming.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title Farming
 * @author gotbit
 */



interface ITokenConverter {
    function convertTwoUniversal(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);
}

interface IRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

contract Farming is Ownable {
    struct Farm {
        uint256 start;
        uint256 amount;
        uint8 period;
        uint256 rate;
        address token;
        bool native;
        bool unlockly;
    }
    address public BUSD;
    address public WBNB;

    IERC20 public tokenDBA;
    ITokenConverter public tokenConverter;
    IRouter public router;

    uint256[5] public periods = [30 days, 60 days, 90 days, 180 days, 365 days];
    uint256[5] public unlockRates = [130, 140, 150, 170, 190];

    mapping(address => Farm) public farms;
    mapping(address => bool) public allowedTokens;

    /// @dev dev-comment
    function stakeToken(
        uint256 amount,
        uint8 _period,
        bool unlockly
    ) external {
        require(farms[msg.sender].start == 0, "Already farming");
        require(
            _period < periods.length,
            "Invalid period, must be from 0 to 4"
        );
        IERC20 farmToken = IERC20(BUSD);

        require(
            farmToken.balanceOf(msg.sender) >= amount,
            "Not enough tokens on balance"
        );
        require(
            farmToken.allowance(msg.sender, address(this)) > 0,
            "Not approved"
        );

        farmToken.transferFrom(msg.sender, address(this), amount);
        if (!unlockly) {
            address[] memory path = new address[](2);
            path[0] = BUSD;
            path[1] = WBNB;
            IERC20(BUSD).approve(address(router), amount);
            router.swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                block.timestamp
            );
            uint256 WBNBtoLiq = IERC20(WBNB).balanceOf(address(this));
            uint256 DBAtoLiq = tokenConverter.convertTwoUniversal(
                WBNB,
                address(tokenDBA),
                WBNBtoLiq
            );
            IERC20(WBNB).approve(address(router), WBNBtoLiq);
            tokenDBA.approve(address(router), DBAtoLiq);
            router.addLiquidity(
                WBNB,
                address(tokenDBA),
                WBNBtoLiq,
                DBAtoLiq,
                0,
                0,
                address(this),
                block.timestamp + 10000
            );
        }
        farms[msg.sender] = Farm({
            start: block.timestamp,
            amount: amount,
            period: _period,
            token: BUSD,
            rate: unlockRates[_period],
            native: false,
            unlockly: unlockly
        });
        // todo: event
    }

    /// @dev dev-comment
    function stakeBNB(
        uint256 amount,
        uint8 _period,
        bool unlockly
    ) external payable {
        require(farms[msg.sender].start == 0, "Already farming");
        require(msg.value >= amount, "Small value");

        payable(msg.sender).transfer(msg.value - amount);
        if (!unlockly) {
            uint256 BNBtoLiq = address(this).balance;
            uint256 DBAtoLiq = tokenConverter.convertTwoUniversal(
                WBNB,
                address(tokenDBA),
                BNBtoLiq
            );
            tokenDBA.approve(address(router), DBAtoLiq);
            router.addLiquidityETH{ value: BNBtoLiq }(
                address(tokenDBA),
                DBAtoLiq,
                0,
                0,
                address(this),
                block.timestamp + 10000
            );
        }
        farms[msg.sender] = Farm({
            start: block.timestamp,
            amount: amount,
            period: _period,
            token: WBNB,
            rate: unlockRates[_period],
            native: true,
            unlockly: unlockly
        });
        // todo: event
    }

    // func{value: BNB}()
    function unlock() external {
        require(farms[msg.sender].start != 0, "Not farming");
        Farm memory farm = farms[msg.sender];
        uint256 amount = ((farm.amount * farm.rate) * (farm.unlockly ? 1 : 2)) /
            100;
        uint256 _totalRewardDBA;
        if (farm.native) {
            _totalRewardDBA = tokenConverter.convertTwoUniversal(
                WBNB,
                address(tokenDBA),
                farm.unlockly ? amount - farm.amount : amount
            );
        } else {
            uint256 _totalRewardTokensWBNB = tokenConverter.convertTwoUniversal(
                BUSD,
                WBNB,
                farm.unlockly ? amount - farm.amount : amount
            );
            _totalRewardDBA = tokenConverter.convertTwoUniversal(
                WBNB,
                address(tokenDBA),
                _totalRewardTokensWBNB
            );
        }
        require(
            block.timestamp > farm.start + periods[farm.period],
            "Period not passed yet"
        );
        if (farm.unlockly) {
            if (farm.native) {
                payable(msg.sender).transfer(farm.amount);
            } else {
                IERC20(farm.token).transfer(msg.sender, farm.amount);
            }
        }

        tokenDBA.transfer(msg.sender, _totalRewardDBA);

        delete farms[msg.sender];
        // todo: event
    }

    function getFarms(address user) external view returns (Farm memory) {
        return farms[user];
        // todo: event
    }

    function witdraw(IERC20 _token, uint256 amount) external onlyOwner {
        require(amount <= _token.balanceOf(address(this)));
        _token.transfer(msg.sender, amount);
        // todo: event
    }

    function changeTokenConverter(address tokenConverter_) external onlyOwner {
        tokenConverter = ITokenConverter(tokenConverter_);
        // todo: event
    }

    constructor(
        address token_,
        address tokenBUSD,
        address tokenWBNB,
        address tokenConverter_,
        address router_
    ) {
        tokenDBA = IERC20(token_);
        BUSD = tokenBUSD;
        WBNB = tokenWBNB;
        tokenConverter = ITokenConverter(tokenConverter_);
        router = IRouter(router_);
    }
}