// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "IERC20.sol";
import "Ownable.sol";
import "AggregatorV3Interface.sol";
import "IUniswapV2Router02.sol";

contract TradableFundsPool is Ownable {
    address[] public investorList;
    address[] public acceptedTokenList;
    mapping(address => AggregatorV3Interface) public tokenToPriceFeed;
    mapping(address => uint256) public amountOwnership;
    mapping(address => uint256) public amountFunded;
    mapping(address => bool) public acceptedTokens;
    IERC20 public unitOfAccountToken;
    IUniswapV2Router02 public dexRouter;

    constructor(
        address _unitOfAccountTokenAddress,
        address[] memory _tokenAddressList,
        address _dexRouterAddress,
        address[] memory priceFeedAddressList
    ) public {
        unitOfAccountToken = IERC20(_unitOfAccountTokenAddress);
        dexRouter = IUniswapV2Router02(_dexRouterAddress);

        for (uint256 i = 0; i < _tokenAddressList.length; i++) {
            acceptedTokenList.push(_tokenAddressList[i]);
            acceptedTokens[_tokenAddressList[i]] = true;
            tokenToPriceFeed[_tokenAddressList[i]] = AggregatorV3Interface(
                priceFeedAddressList[i]
            );
        }
    }

    function depositFund(address _tokenAddress, uint256 _amount) public {
        require(_amount > 0);
        require(acceptedTokens[_tokenAddress] == true);
        require(_tokenAddress == address(unitOfAccountToken));

        uint256 beforeWorth = getCurrentWorth();
        if (amountFunded[msg.sender] == 0) {
            investorList.push(msg.sender);
        }
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        amountFunded[msg.sender] += _amount;

        (, int256 answer, , , ) = tokenToPriceFeed[address(unitOfAccountToken)]
            .latestRoundData();
        uint8 decimals = tokenToPriceFeed[address(unitOfAccountToken)]
            .decimals();
        uint256 correctedDecimals = uint256(decimals);
        uint256 uocPrice = uint256(answer) / (10**(correctedDecimals));

        uint256 amountWorth = (_amount * uocPrice) / (10**18);
        uint256 percentageIncrease = (amountWorth * 10**18) /
            (amountWorth + beforeWorth); //change from float to uint256
        updateInvestorsOwnership(int256(percentageIncrease), msg.sender);
    }

    function updateInvestorsOwnership(
        int256 _percentageIncrease,
        address sender
    ) internal {
        uint256 percentageIncrease = uint256(_percentageIncrease);
        // amountOwnership[msg.sender] = percentageIncrease;
        for (uint256 i = 0; i < investorList.length; i++) {
            address curInvestor = investorList[i];
            if (curInvestor != sender) {
                amountOwnership[curInvestor] =
                    ((10**18 - percentageIncrease) *
                        amountOwnership[curInvestor]) /
                    (10**18);
            } else {
                amountOwnership[curInvestor] =
                    ((10**18 - percentageIncrease) *
                        amountOwnership[curInvestor]) /
                    (10**18) +
                    percentageIncrease;
            }
        }
    }

    function getCurrentWorth() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < acceptedTokenList.length; i++) {
            address curToken = acceptedTokenList[i];
            uint256 curAmount = erc20Balance(curToken);
            (, int256 answer, , , ) = tokenToPriceFeed[curToken]
                .latestRoundData();
            uint8 decimals = tokenToPriceFeed[curToken].decimals();
            uint256 correctedDecimals = uint256(decimals);
            uint256 curPrice = uint256(answer) / (10**(correctedDecimals));
            total += curPrice * curAmount;
        }
        return total / (10**18);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) public onlyOwner {
        require(acceptedTokens[path[0]] == true);
        require(acceptedTokens[path[1]] == true);
        IERC20 tokenIn = IERC20(path[0]);
        tokenIn.approve(address(dexRouter), amountIn);
        dexRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 10000
        );
    }

    function ethBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function erc20Balance(address _tokenAddress) public view returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    // function withdraw() public {
    //     require(amountOwnership[msg.sender] > 0);
    //     uint256 senderOwnership = amountOwnership[msg.sender];
    //     for (uint256 i = 0; i < acceptedTokenList.length; i++) {
    //         address curTokenAddress = acceptedTokenList[i];
    //         IERC20 curToken = IERC20(curTokenAddress);

    //         if (erc20Balance(curTokenAddress) < 1000000) {
    //             continue;
    //         }

    //         uint256 amount = (senderOwnership * erc20Balance(curTokenAddress)) /
    //             (10**18);
    //         curToken.approve(address(this), amount);
    //         curToken.transfer(msg.sender, amount);
    //     }

    //     amountOwnership[msg.sender] = 0;
    //     amountFunded[msg.sender] = 0;
    //     updateInvestorsOwnership(-1 * senderOwnership, msg.sender);
    // }

    //     fallback() external payable {}
    //     receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}