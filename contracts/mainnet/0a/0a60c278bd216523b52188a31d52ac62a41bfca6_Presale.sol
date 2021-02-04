/**
 *Submitted for verification at Etherscan.io on 2021-02-03
*/

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
contract Presale {

    IERC20 public MFI;
    // these aren't ether, we're just using this for unit conversion
    uint public constant presaleSupply = 4_000_000 ether;
    // how much the presale has already issued
    uint public presaleIssued = 0;
    address public treasury;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint public startDate;
    uint public lastVestedQuarter;
    // 1_500_000 / 8
    uint public constant vestingQuarterly = 187_500 ether;

    // check for reentrancy
    bool disbursing;

    // initial best-guess ETH price
    uint constant initialDollarsPerETH = 1400;
    // updatable ETH price
    uint public dollarsPerETH = initialDollarsPerETH;
    uint public constant tokensPerDollar = 4;

    uint public constant maxPerWallet = 10 ether * initialDollarsPerETH * tokensPerDollar;

    constructor(IERC20 tokenContract, uint _startDate, address _treasury) public {
        MFI = tokenContract;
        treasury = _treasury;
        startDate = _startDate;
    }

    receive() external payable {
        // rule out reentrancy
        require(!disbursing, "No re-entrancy");
        disbursing = true;

        // check time constraints
        // after start date
        require(block.timestamp >= startDate, "Presale hasn't started yet");
        uint endDate = startDate + 2 days;
        // before end date
        require(endDate >= block.timestamp, "Presale is over");

        // calculate price
        // no overflow because scarcity
        uint tokensPerETH = dollarsPerETH * tokensPerDollar;
        // no overflow, again because scarcity
        uint tokensRequested = msg.value * tokensPerETH;

        // calculate how much the sender actually gets
        uint tokensToTransfer = min(tokensRequested, // price
                                    sub(presaleSupply, presaleIssued), // don't exceed supply
                                    sub(maxPerWallet, MFI.balanceOf(msg.sender))); // don't exceed wallet max

        // any eth that needs to go back
        uint ethReturn = sub(tokensRequested, tokensToTransfer) / tokensPerETH;
        if (ethReturn > 0) {
            // send it back
            payable(msg.sender).transfer(ethReturn);
        }

        // send eth to treasury and tokens to buyer
        payable(treasury).transfer(sub(msg.value, ethReturn));
        MFI.transferFrom(treasury, msg.sender, tokensToTransfer);
        disbursing = false;
    }

    // can be called by anyone to update the current price
    function setDollarsPerETH() external {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        dollarsPerETH = UniRouter(uniRouter).getAmountsOut(1 ether, path)[1] / 1 ether;
    }

    function min(uint a, uint b, uint c) internal pure returns (uint result) {
        // if a is smallest
        result = a;
        // if be is smaller
        if (result > b) {
            result = b;
        }
        // if c is even smaller
        if (result > c) {
            result = c;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction underflow");
        uint256 c = a - b;

        return c;
    }

    // send vested tokens back to treasury
    function withdrawVested() external {
        uint timeDiff = block.timestamp - startDate;
        uint quarter = timeDiff / (90 days);
        if (quarter > lastVestedQuarter) {
            MFI.transfer(treasury, vestingQuarterly);
            lastVestedQuarter = quarter;
        }
    }
}

interface UniRouter {
    function getAmountsOut(uint amountIn, address[] calldata path)
        external view returns (uint[] memory amounts);
}