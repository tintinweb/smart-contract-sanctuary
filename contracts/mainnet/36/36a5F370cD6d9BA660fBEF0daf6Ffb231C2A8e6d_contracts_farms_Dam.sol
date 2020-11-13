pragma solidity ^0.5.17;

import "./Farm.sol";
import "../lib/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Dam is Farm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => bool) public acceptedPairs;
    IERC20[] public unwrappedTokens;
    mapping(address => mapping(address => uint256)) public unwrappedBalances;
    IUniswapV2Router02 public uniswapRouter;

    event Staked(address indexed user, address uniswapPair, uint256 amount);
    event Withdrawn(address indexed user, address token, uint256 amount);

    constructor(
        IERC20 _ham,
        IUniswapV2Pair[] memory _acceptedPairs,
        IUniswapV2Router02 _uniswapRouter
    ) Farm(_ham, IERC20(address(0))) public {
        uniswapRouter = _uniswapRouter;
        wrappedToken = IERC20(_uniswapRouter.WETH());
        for (uint i = 0; i<_acceptedPairs.length; i++) {
            address token0 = _acceptedPairs[i].token0();
            address token1 = _acceptedPairs[i].token1();
            require(
                token0 == address(wrappedToken) || token1 == address(wrappedToken),
                "pairs must be against weth"
            );
            acceptedPairs[address(_acceptedPairs[i])] = true;
            unwrappedTokens.push(token0 == address(wrappedToken) ? IERC20(token1) : IERC20(token0));
        }
    }

    function stakeAndUnwrap(IUniswapV2Pair pair, uint256 amount) public updateReward(msg.sender) checkStart {
        require(amount > 0, "can't stake 0");
        require(acceptedPairs[address(pair)], "token not accepted");
        IERC20(address(pair)).safeTransferFrom(msg.sender, address(this), amount);
        require(pair.approve(address(uniswapRouter), amount), 'failed approve');

        address otherToken = pair.token0();
        if (otherToken == address(wrappedToken)) {
            otherToken = pair.token1();
        }

        (uint256 amountOther, uint256 amountWrapped) = uniswapRouter.removeLiquidity(otherToken, address(wrappedToken), amount, 0, 0, address(this), block.timestamp);

        _balances[msg.sender] = _balances[msg.sender].add(amountWrapped);
        _totalSupply = _totalSupply.add(amount);
        unwrappedBalances[otherToken][msg.sender] = unwrappedBalances[otherToken][msg.sender].add(amountOther);

        emit Staked(msg.sender, amountWrapped);
    }

    function stake(uint256 amount) public {
        revert("cant stake without unwrapping");
    }

    function withdraw(uint256 amount) public {
        revert("cant withdraw, use exit");
    }

	// gtfo
    function exit() external updateReward(msg.sender) checkStart {
		uint256 amount = balanceOf(msg.sender);
        super.withdraw(amount);
        emit Withdrawn(msg.sender, address(wrappedToken), amount);
        for (uint i = 0; i<unwrappedTokens.length; i++) {
			address ti = address(unwrappedTokens[i]);
            if (unwrappedBalances[ti][msg.sender] > 0) {
                uint256 toSend = unwrappedBalances[ti][msg.sender];
                unwrappedBalances[ti][msg.sender] = 0;
                unwrappedTokens[i].safeTransfer(msg.sender, toSend);
            }
        }
        getReward();
    }
}
