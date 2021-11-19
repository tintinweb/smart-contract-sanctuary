/**
 *Submitted for verification at polygonscan.com on 2021-11-19
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
  }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IElectronDAOPresale is IERC20 {
    function estimateTokensOut(uint256 daiAmount) external view returns (uint256);
    function presale(uint256 daiAmount) external;
    function redeemPresaleTokens(uint256 amount) external;
    function setPresaleActive(bool active) external;
    function setRedeemEnabled(bool enabled) external;
    function withdrawDAI(uint256 amount) external;
}

contract ElectronMultisigTimelock {

    using SafeMath for uint256;

    struct Transaction {
        uint256 proposed;
        address target;
        uint256 value;
        bytes data;
        bool active;
    }

    IERC20 public DAI;
    IERC20 public ELECTRON;
    IElectronDAOPresale public Presale;
    IUniswapV2Router02 public Router;

    address public leader;
    address[] public signers;

    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) confirmations;
    uint256 public transactionCount;

    uint256 public timelockDelay = 6 hours;
    uint256 public minTimelockDelay = 6 hours;

    uint256 private MAX_INT = 2**256 - 1;

    event RouterChanged(address indexed oldRouter, address indexed newRouter);

    event LeadershipChanged(address indexed oldLeader, address indexed newLeader);
    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);

    event TransactionSubmitted(uint256 indexed id);
    event TransactionCanceled(uint256 indexed id);
    event SignerConfirmation(address indexed signer, uint256 indexed id);
    event SignerRevoke(address indexed signer, uint256 indexed id);
    event TransactionExecuted(uint256 indexed id);

    event TimelockDelayChanged(uint256 delay);

    modifier onlyMultisig {
        require(msg.sender == address(this), "Multisig: caller is not the multisig");
        _;
    }

    modifier onlyLeader {
        require(msg.sender == leader, "Multisig: caller is not the multisig leader");
        _;
    }

    modifier onlySigner {
        require(isSigner(msg.sender), "Multisig: caller is not an authorized signer");
        _;
    }

    modifier transactionActive(uint256 id) {
        require(id < transactionCount, "Multisig: transaction does not exist");
        require(transactions[id].active, "Multisig: transaction is not active");
        _;
    }

    constructor(
        address _DAI,
        address _ELECTRON,
        address _Presale,
        address _Router,
        address[] memory signerAddresses
    ) {
        DAI = IERC20(_DAI);
        ELECTRON = IERC20(_ELECTRON);
        Presale = IElectronDAOPresale(_Presale);
        Router = IUniswapV2Router02(_Router);
        emit RouterChanged(address(0), address(Router));

        leader = msg.sender;
        signers.push(leader);
        emit LeadershipChanged(address(0), leader);
        emit SignerAdded(leader);
        for (uint256 s = 0; s < signerAddresses.length; s ++) {
            signers.push(signerAddresses[s]);
            emit SignerAdded(signerAddresses[s]);
        }
    }

    function changeLeader(address newLeader) external onlyMultisig {
        require(isSigner(newLeader), "Multisig: new leader must be an existing signer");
        address oldLeader = leader;
        leader = newLeader;
        emit LeadershipChanged(oldLeader, leader);
    }

    function addSigner(address signer) external onlyMultisig {
        require(!isSigner(signer), "Multisig: address is an existing signer");
        signers.push(signer);
        emit SignerAdded(signer);
    }

    function removeSigner(address signer) external onlyMultisig {
        require(isSigner(signer), "Multisig: address is not a signer");
        require(signer != leader, "Multisig: cannot remove leader from signers");
        for (uint256 s = 0; s < signers.length; s ++) {
            if (signers[s] == signer) {
                signers[s] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }
        emit SignerRemoved(signer);
    }

    function changeTimelockDelay(uint256 delay) external onlyMultisig {
        require(delay >= minTimelockDelay, "Multisig: delay too low");
        timelockDelay = delay;
        emit TimelockDelayChanged(delay);
    }

    function setRouterAddress(address router) external onlyMultisig {
        address oldRouter = address(Router);
        Router = IUniswapV2Router02(router);
        emit RouterChanged(oldRouter, address(Router));
    }

    function proposeTransaction(address txTarget, uint256 txValue, bytes calldata txData) external onlyLeader {
        require(txTarget != address(Presale), "Multisig: cannot propose transaction to the presale contract");
        uint256 txId = transactionCount;
        transactions[txId] = Transaction({
            proposed: block.timestamp,
            target: txTarget,
            value: txValue,
            data: txData,
            active: true
        });
        transactionCount = transactionCount.add(1);
        emit TransactionSubmitted(txId);
    }

    function confirmTransaction(uint256 id) external onlySigner transactionActive(id) {
        require(!confirmations[id][msg.sender], "Multisig: transaction already confirmed by signer");
        confirmations[id][msg.sender] = true;
        emit SignerConfirmation(msg.sender, id);
    }

    function revokeConfirmation(uint256 id) external onlySigner transactionActive(id) {
        require(confirmations[id][msg.sender], "Multisig: transaction not confirmed by signer");
        delete confirmations[id][msg.sender];
        emit SignerRevoke(msg.sender, id);
    }

    function executeTransaction(uint256 id) external onlyLeader transactionActive(id) returns (bytes memory) {
        Transaction memory txn = transactions[id];
        require(txn.proposed.add(timelockDelay) <= block.timestamp, "Multisig: insufficient timelock delay");
        uint256 confirms = 0;
        for (uint256 s = 0; s < signers.length; s ++) {
            if (confirmations[id][signers[s]]) {
                confirms = confirms.add(1);
            }
        }
        require(confirms == signers.length, "Multisig: insufficient signer confirmations");
        (bool success, bytes memory result) = txn.target.call{value: txn.value}(txn.data);
        require(success, "Multisig: external call failed");
        txn.active = false;
        emit TransactionExecuted(id);
        return result;
    }

    function cancelTransaction(uint256 id) external onlyLeader transactionActive(id) {
        transactions[id].active = false;
        emit TransactionCanceled(id);
    }

    function setPresaleActive(bool active) external onlyLeader {
        Presale.setPresaleActive(active);
    }

    function setRedeemEnabled(bool enabled) external onlyLeader {
        Presale.setRedeemEnabled(enabled);
    }

    function addPresaleLiquidity(uint256 ELECTRONAmount) external onlyLeader {
        Presale.withdrawDAI(DAI.balanceOf(address(Presale)));
        uint256 DAIAmount = DAI.balanceOf(address(this));
        ELECTRON.approve(address(Router), ELECTRONAmount);
        DAI.approve(address(Router), DAIAmount);
        Router.addLiquidity(
            address(ELECTRON),
            address(DAI),
            ELECTRONAmount,
            DAIAmount,
            0,
            0,
            address(this),
            MAX_INT
        );
    }

    function isSigner(address account) public view returns (bool) {
        for (uint256 s = 0; s < signers.length; s ++) {
            if (signers[s] == account) {
                return true;
            }
        }
        return false;
    }

    receive() external payable {}
    fallback() external payable {}

}