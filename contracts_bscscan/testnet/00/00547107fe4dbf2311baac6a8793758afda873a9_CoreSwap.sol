/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

//SPDX-License-Identifier: UNLICENSED

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


interface ISwap {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOut,
        address[] memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface ICore {
    function addAccepted(address _adr) external returns (bool);

    function CheckAccepted(address adr) external view returns (bool);

    function EthtoToken(address _src, address _t2)
        external
        payable
        returns (bool);

    function TokentoToken(
        address _src,
        address _t1,
        address _t2,
        uint256 _amounts
    ) external returns (bool);

    function TokentoEth(
        address _src,
        address _t1,
        uint256 _amounts
    ) external returns (bool);

    function GetAllow(address _src, address _t2)
        external
        view
        returns (uint256);

    function GetReturnAmountOut(
        uint256 amountIns,
        address _t1,
        address _t2
    ) external returns (uint256[] memory);
}

contract CoreSwap is ICore {
    address owner;
    address router;
    address BNB;

    mapping(address => bool) accepted;

    // apeswap = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7
    // pancakeAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // USDT = 0x55d398326f99059fF775485246999027B3197955;
    // BNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    constructor(
        address _router,
        address _BNB
    ) {
        owner = msg.sender;

        router = _router;
        BNB = _BNB;
        accepted[msg.sender] = true;
    }

    modifier onlyOwner(){
        require(owner == msg.sender, "Not Allowed");
        _;
    }

    /// For Provider
    function addAccepted(address adr) external onlyOwner returns (bool) {
        accepted[adr] = true;
        return true;
    }

    function CheckAccepted(address adr) external view returns (bool) {
        return accepted[adr];
    }

    function RemoveAccepted(address adr) public onlyOwner returns (bool) {
        accepted[adr] = false;
        return true;
    }

    //End Provider

    //Swap function

    function GeneratePath(address _t1, address _t2)
        private
        pure
        returns (address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = _t1;
        path[1] = _t2;
        return path;
    }

    function EthtoToken(address _src, address _t2)
        public
        payable
        returns (bool)
    {
        require(accepted[_src] == true, "Not Allowed");
        ISwap PANCAKE = ISwap(router);
        IERC20 Tokens = IERC20(_t2);
        Tokens.approve(_src, msg.value);

        uint256 OutAmount = GetReturnAmountOut(msg.value, BNB, _t2)[1];
        uint256 deadline = block.timestamp + 1440;
        PANCAKE.swapExactETHForTokens{value: msg.value}(
            OutAmount,
            GeneratePath(BNB, _t2),
            _src,
            deadline
        );
        return true;
    }

    function TokentoToken(
        address _src,
        address _t1,
        address _t2,
        uint256 _amounts
    ) public returns (bool) {
        require(accepted[_src] == true, "Not Allowed");
        IERC20(_t1).transferFrom(msg.sender, address(this), _amounts);
        IERC20(_t1).approve(router, _amounts);

        ISwap(router).swapExactTokensForTokens(
            _amounts,
            GetReturnAmountOut(_amounts, _t1, _t2)[1],
            GeneratePath(_t1, _t2),
            _src,
            block.timestamp
        );
        return true;
    }

    function TokentoEth(
        address _src,
        address _t1,
        uint256 _amounts
    ) public returns (bool) {
        require(accepted[_src] == true, "Not Allowed");
        IERC20(_t1).transferFrom(msg.sender, address(this), _amounts);
        IERC20(_t1).approve(router, _amounts);

        ISwap(router).swapExactTokensForETH(
            _amounts,
            0,
            GeneratePath(_t1, BNB),
            _src,
            block.timestamp
        );
        return true;
    }

    function GetAllow(address _src, address _t2) public view returns (uint256) {
        IERC20 Tokens = IERC20(_t2);
        return Tokens.allowance(address(this), _src);
    }

    function GetReturnAmountOut(
        uint256 amountIns,
        address _t1,
        address _t2
    ) public view returns (uint256[] memory) {
        ISwap PANCAKE = ISwap(router);
        return PANCAKE.getAmountsOut(amountIns, GeneratePath(_t1, _t2));
    }
}