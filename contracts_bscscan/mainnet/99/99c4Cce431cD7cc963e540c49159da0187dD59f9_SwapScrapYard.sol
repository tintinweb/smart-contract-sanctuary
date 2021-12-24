/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IDexFactory {

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(
        IDexRouter routerAddress,
        uint256 tokenAmount,
        IBEP20 _token
    ) internal {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = routerAddress.WETH();

        _token.approve(address(routerAddress), tokenAmount);

        // make the swap
        routerAddress.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp + 360
        );
    }

    function swapTokensForTokens(
        IDexRouter routerAddress,
        uint256 tokenAmount,
        address recipient,
        IBEP20 _token1,
        IBEP20 _token2
    ) internal {
        // generate the pancake pair path of token -> busd
        address[] memory path = new address[](2);
        path[0] = address(_token1);
        path[1] = address(_token2);

        _token1.approve(address(routerAddress), tokenAmount);

        // make the swap
        routerAddress.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of tokens
            path,
            recipient,
            block.timestamp + 360
        );
    }

    function swapETHForTokens(
        IDexRouter routerAddress,
        address _token,
        address recipient,
        uint256 ethAmount
    ) internal {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = routerAddress.WETH();
        path[1] = _token;

        // make the swap
        routerAddress.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

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

contract SwapScrapYard {
    using SafeMath for uint256;

    address payable public owner;
    address payable public payoutWallet;
    IBEP20 public myfi;
    IBEP20 public busd = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IDexRouter public dexRouter =
        IDexRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IDexFactory public dexFactory =
        IDexFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    AggregatorV3Interface priceFeedBnb =
        AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

    uint256 public worthLessMaxTokenReward = 7 * 10 ** 18;
    uint256 public worthLessTokenReward = 100;
    uint256 public maxSwapPerDay = 28 * 10 ** 18;
    uint256 public swapTimeLimit = 24 hours;
    uint256 public myfiSupply = 10 * 10 ** 9;
    uint256 public totalSwapAmount;

    mapping(address => uint256) public lastSwapBalance;
    mapping(address => uint256) public lastSwapTime;

    address[] public scrapedTokens;

    modifier onlyOwner() {
        require(
            owner == payable(msg.sender),
            "Ownable: caller is not the owner"
        );
        _;
    }

    constructor(address _myfi, address _payout) {
        owner = payable(msg.sender);
        myfi = IBEP20(_myfi);
        payoutWallet = payable(_payout);
    }

    //to receive BNB from dexRouter when swapping
    receive() external payable {}

    function swapNoneWorthyToken(IBEP20 _token, uint256 tokenAmount)
        public
        returns (bool)
    {
        // uint256 tokenAmount = getUserTokenBalance(msg.sender, _token);
        require(
            myfi.balanceOf(msg.sender) >= myfiSupply,
            "dont have enough myfi"
        );
        require(tokenAmount > 0, "you must have token balance");
        _token.transferFrom(msg.sender, owner, tokenAmount);
        scrapedTokens.push(address(_token));

        uint256 reward = busd.balanceOf(payoutWallet).div(worthLessTokenReward);
        if (reward > worthLessMaxTokenReward) {
            reward = worthLessMaxTokenReward;
        }

        busd.transferFrom(payoutWallet, msg.sender, reward);
        return true;
    }

    function swapWorthyToken(
        IBEP20 _token,
        uint256 pairNumber,
        uint256 tokenAmount,
        address payoutToken
    ) public {
        require(
            myfi.balanceOf(msg.sender) >= myfiSupply,
            "dont have enough myfi"
        );
        require(
            _token.balanceOf(msg.sender) > 0,
            "you must have token balance"
        );
        address pairAddress;
        _token.transferFrom(msg.sender, address(this), tokenAmount);
        scrapedTokens.push(address(_token));
        uint256 reward = busd.balanceOf(payoutWallet).div(worthLessTokenReward);
        if (reward > worthLessMaxTokenReward) {
            reward = worthLessMaxTokenReward;
        }

        busd.transferFrom(payoutWallet, msg.sender, reward);

        if (pairNumber == 1) {
            pairAddress = dexFactory.getPair(
                address(_token),
                dexRouter.WETH()
            );
            require(pairAddress != address(0), "Pair don't exist");
            swapAndLiquifyBNB(msg.sender, tokenAmount, _token, payoutToken);
        } else {
            pairAddress = dexFactory.getPair(
                address(_token),
                address(busd)
            );
            require(pairAddress != address(0), "Pair don't exist");
            swapAndLiquifyBUSD(msg.sender, tokenAmount, _token, payoutToken);
        }
    }

    function swapAndLiquifyBNB(
        address sender,
        uint256 tokenBalance,
        IBEP20 _token,
        address payoutToken
    ) private {
        if (lastSwapTime[sender] > block.timestamp) {
            require(
                lastSwapBalance[sender] <= (maxSwapPerDay),
                "Swap limit exeeded for today"
            );
        } else {
            lastSwapBalance[sender] = 0;
            lastSwapTime[sender] = block.timestamp + swapTimeLimit;
        }

        uint256 initialBalance = getContractBnbBalance();

        // swap tokens for BNB
        Utils.swapTokensForEth(dexRouter, tokenBalance, _token);

        // how much BNB did we just swap into?
        uint256 newBalance = getContractBnbBalance().sub(initialBalance);
        totalSwapAmount = totalSwapAmount.add(newBalance);

        payable(sender).transfer(newBalance.div(2));

        // swap BNB for tokens
        Utils.swapETHForTokens(
            dexRouter,
            payoutToken,
            sender,
            newBalance.div(2)
        );

        lastSwapBalance[sender] = lastSwapBalance[sender].add(
            newBalance.mul(getLatestPriceBnb())
        );
    }

    function swapAndLiquifyBUSD(
        address sender,
        uint256 tokenBalance,
        IBEP20 _token,
        address payoutToken
    ) private {
        if (lastSwapTime[sender] > block.timestamp) {
            require(
                lastSwapBalance[sender] <= (maxSwapPerDay),
                "Swap limit exeeded for today"
            );
        } else {
            lastSwapBalance[sender] = 0;
            lastSwapTime[sender] = block.timestamp + swapTimeLimit;
        }

        uint256 initialBalance = getContractBusdBalance();

        // swap tokens for BUSD
        Utils.swapTokensForTokens(
            dexRouter,
            tokenBalance,
            address(this),
            _token,
            busd
        );

        // how much BUSD did we just swap into?
        uint256 newBalance = getContractBusdBalance().sub(initialBalance);
        totalSwapAmount = totalSwapAmount.add(newBalance);

        busd.transfer(sender, newBalance.div(2));

        // swap BUSD for tokens
        Utils.swapTokensForTokens(
            dexRouter,
            tokenBalance,
            sender,
            busd,
            IBEP20(payoutToken)
        );

        lastSwapBalance[sender] = lastSwapBalance[sender].add(
            newBalance
        );
    }

    // to get real time price of BNB

    function getLatestPriceBnb() public view returns (uint256) {
        (, int256 price, , , ) = priceFeedBnb.latestRoundData();
        return uint256(price).div(1e8);
    }

    function getUserTokenBalance(address _user, IBEP20 _token)
        public
        view
        returns (uint256)
    {
        return _token.balanceOf(_user);
    }

    function getContractBnbBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractBusdBalance() public view returns (uint256) {
        return busd.balanceOf(address(this));
    }

    function migrateFundsBnb(uint256 _value) external onlyOwner {
        owner.transfer(_value);
    }

    function migrateFundsToken(address _token, uint256 _value) external onlyOwner {
        IBEP20(_token).transfer(owner, _value);
    }

    function setOwner(address payable _new)
        external
        onlyOwner
    {
        owner = _new;
    }

    function setPayoutAddress(address payable _new)
        external
        onlyOwner
    {
        payoutWallet = _new;
    }

    function setRoute(address _router, address _factory)
        external
        onlyOwner
    {
        dexRouter = IDexRouter(_router);
        dexFactory = IDexFactory(_factory);
    }

    function setTokens(address _myfi, address _busd)
        external
        onlyOwner
    {
        myfi = IBEP20(_myfi);
        busd = IBEP20(_busd);
    }

    function setPriceFeedAddress(address _new)
        external
        onlyOwner
    {
        priceFeedBnb = AggregatorV3Interface(_new);
    }

    function setSwapTokenReward(uint256 _maxAmount, uint256 _amount)
        external
        onlyOwner
    {
        worthLessMaxTokenReward = _maxAmount;
        worthLessTokenReward = _amount;
    }

    function setMaxSwapPerDay(uint256 _amount) external onlyOwner {
        maxSwapPerDay = _amount;
    }

    function setmyfiSupply(uint256 _amount) external onlyOwner {
        myfiSupply = _amount;
    }

    function setSwapTimeLimit(uint256 _time) external onlyOwner {
        swapTimeLimit = _time;
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}