/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.2.0/contracts/token/ERC20/IERC20.sol";

interface IERC20 {

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

interface Router {
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
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

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}

interface DexInterface {
    function createSwaps(
        string memory _swapName,
        address _dexRouter,
        address _factory,
        address _router
    ) external;
    
    function addRegistrar(address _user) external;
    
    function setFees(uint256 _fees) external;
    
    function checkRegistrar() external returns(address);
    
    function addLiquidity(
        uint256 swapId,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external;
    
    function swapExactTokensForTokens(
        uint256 swapId,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external;
    
    function swapTokensForExactTokens(
        uint256 swapId,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external;
    
    function swapExactETHForTokens(
        uint256 swapId,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable;
    
    function swapTokensForExactETH(
        uint256 swapId,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external;
    
    function swapExactTokensForETH(
        uint256 swapId,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external;
    
    function swapETHForExactTokens(
        uint256 swapId,
        uint256 amountOut,
        address[] calldata path,
        address to
    ) external payable;
}

contract Dex {
    IERC20 private _token;
    
    address owner;

    uint256 fees;

    uint256 public count;

    struct Swaps {
        uint256 id;
        string swapName;
        address dexRouter;
        address factory;
        address router;
    }

    mapping(uint256 => Swaps) public swaps;

    mapping(address => address) public registrar;

    event Swap(uint256, string, address, address, address);

    constructor() {
        owner = msg.sender;
    }
    
    // Use this function where we want to set fees
    function transferEco(IERC20 token, uint256 _amount) public {
        _token = token;
        _token.transferFrom(msg.sender, address(this), _amount);
    }

    function createSwaps(
        string memory _swapName,
        address _dexRouter,
        address _factory,
        address _router
    ) public {
        count++;

        swaps[count] = Swaps(count, _swapName, _dexRouter, _factory, _router);

        emit Swap(count, _swapName, _dexRouter, _factory, _router);
    }

    function addRegistrar(address _user) public {
        require(msg.sender == owner);

        registrar[_user] = _user;
    }

    function setFees(uint256 _fees) public {
        require(msg.sender == owner);

        fees = _fees;
    }

    function checkRegistrar() public view returns(address) {
        return registrar[msg.sender];
    }

    function addLiquidity(
        uint256 swapId,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) public {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 time = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            time
        );
    }

    function swapExactTokensForTokens(
        uint256 swapId,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 time = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, time);
    }

    function swapTokensForExactTokens(
        uint256 swapId,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) public {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 time = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            to,
            time
        );
    }

    function swapExactETHForTokens(
        uint256 swapId,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public payable {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 deadline = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapTokensForExactETH(
        uint256 swapId,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) public {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 deadline = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            to,
            deadline
        );
    }

    function swapExactTokensForETH(
        uint256 swapId,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) public {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 deadline = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    function swapETHForExactTokens(
        uint256 swapId,
        uint256 amountOut,
        address[] calldata path,
        address to
    ) public payable {
        uint256 feesForUser = checkRegistrar() == address(0) ? fees : 0;

        Swaps memory s = swaps[swapId];

        Router router = Router(s.dexRouter);

        uint256 deadline = block.timestamp + 120 days;

        require(feesForUser > 0, "Please check fee amount");

        router.swapETHForExactTokens{value: msg.value}(
            amountOut,
            path,
            to,
            deadline
        );
    }
}