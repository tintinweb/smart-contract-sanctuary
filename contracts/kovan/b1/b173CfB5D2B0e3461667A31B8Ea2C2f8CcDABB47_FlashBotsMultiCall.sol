/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

//SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.5.0;
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
      Deposit,   // supply tokens
      Withdraw,  // borrow tokens
      Transfer,  // transfer balance between accounts
      Buy,       // buy an amount of some token (externally)
      Sell,      // sell an amount of some token (externally)
      Trade,     // trade tokens against another account
      Liquidate, // liquidate an undercollateralized or expiring account
      Vaporize,  // use excess tokens to zero-out a completely negative account
      Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei // the amount is denominated in wei
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

abstract contract DyDxPool is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public virtual view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public virtual;
}


// pragma solidity ^0.5.0;
pragma solidity 0.6.12;

contract DyDxFlashLoan is Structs {
    // Main net
    // DyDxPool pool = DyDxPool(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    // Kovan
    DyDxPool pool = DyDxPool(0x4EC3570cADaAEE08Ae384779B0f3A45EF85289DE);

    // Main net
    // address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // Kovan
    address public WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;
    // Main net
    // address public SAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    // Kovan
    address public SAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    // Main net
    // address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // Kovan
    address public USDC = 0x03226d9241875DbFBfE0e814ADF54151e4F3fd4B;
    // Main net
    // address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // Kovan
    address public DAI = 0xC4375B7De8af5a38a93548eb8453a498222C4fF2;
    mapping(address => uint256) public currencies;

    constructor() public {
        currencies[WETH] = 1;
        currencies[SAI] = 2;
        currencies[USDC] = 3;
        currencies[DAI] = 4;
    }

    modifier onlyPool() {
        require(
            msg.sender == address(pool),
            "FlashLoan: could be called by DyDx pool only"
        );
        _;
    }

    function tokenToMarketId(address token) public view returns (uint256) {
        uint256 marketId = currencies[token];
        require(marketId != 0, "FlashLoan: Unsupported token");
        return marketId - 1;
    }

    // the DyDx will call `callFunction(address sender, Info memory accountInfo, bytes memory data) public` after during `operate` call
    function flashloan(address token, uint256 amount, bytes memory data)
        internal
    {
        IERC20(token).approve(address(pool), amount + 1);
        Info[] memory infos = new Info[](1);
        ActionArgs[] memory args = new ActionArgs[](3);

        infos[0] = Info(address(this), 0);

        AssetAmount memory wamt = AssetAmount(
            false,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount
        );
        ActionArgs memory withdraw;
        withdraw.actionType = ActionType.Withdraw;
        withdraw.accountId = 0;
        withdraw.amount = wamt;
        withdraw.primaryMarketId = tokenToMarketId(token);
        withdraw.otherAddress = address(this);

        args[0] = withdraw;

        ActionArgs memory call;
        call.actionType = ActionType.Call;
        call.accountId = 0;
        call.otherAddress = address(this);
        call.data = data;

        args[1] = call;

        ActionArgs memory deposit;
        AssetAmount memory damt = AssetAmount(
            true,
            AssetDenomination.Wei,
            AssetReference.Delta,
            amount + 1
        );
        deposit.actionType = ActionType.Deposit;
        deposit.accountId = 0;
        deposit.amount = damt;
        deposit.primaryMarketId = tokenToMarketId(token);
        deposit.otherAddress = address(this);

        args[2] = deposit;

        pool.operate(infos, args);
    }
}

pragma solidity 0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

abstract contract IOneSplit { // interface for 1inch exchange.
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        public
        virtual
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 disableFlags
    ) public virtual payable;
}

// This contract simply calls multiple targets sequentially, ensuring WETH balance before and after

contract FlashBotsMultiCall is DyDxFlashLoan {
    uint256 public loan;

    address payable private immutable owner;
    address private immutable executor;
    // Main net
    // IWETH private constant WETH_TOKEN = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // Kovan
    IWETH private constant WETH_TOKEN = IWETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);

    // Main net
    address ONE_SPLIT_ADDRESS = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    uint256 PARTS = 10;
    uint256 FLAGS = 0;

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(address _executor) public payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WETH_TOKEN.deposit{value: msg.value}();
        }
        _getWeth(msg.value);
        // _approveWeth(msg.value);
    }

    receive() external payable {
    }

    // function getFlashloan(address _fromSwapAddress, address _fromProxyAddress, address _fromToken, address _toSwapAddress, address _toProxyAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) external payable onlyOwner {
    function getFlashloan(address _fromSwapAddress, address _fromToken, address _toSwapAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) external payable onlyOwner {
        uint256 balanceBefore = IERC20(_fromToken).balanceOf(address(this));
        // bytes memory data = abi.encode(_fromSwapAddress, _fromProxyAddress, _fromToken, _toSwapAddress, _toProxyAddress, _toToken, _fromAmount, _ethAmountToCoinbase, balanceBefore);
        bytes memory data = abi.encode(_fromSwapAddress, _fromToken, _toSwapAddress, _toToken, _fromAmount, _ethAmountToCoinbase, balanceBefore);
        flashloan(_fromToken, _fromAmount, data); // execution goes to `callFunction`
    }

    function callFunction(
        address, /* sender */
        Info calldata, /* accountInfo */
        bytes calldata data
    ) external onlyPool {
        // (address _fromSwapAddress, address _fromProxyAddress, address _fromToken, address _toSwapAddress, address _toProxyAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase, uint256 balanceBefore) = abi
        //     .decode(data, (address, address, address, address, address, address, uint256, uint256, uint256));
        (address _fromSwapAddress, address _fromToken, address _toSwapAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase, uint256 balanceBefore) = abi
            .decode(data, (address, address, address, address, uint256, uint256, uint256));
        uint256 balanceAfter = IERC20(_fromToken).balanceOf(address(this));
        require(
            balanceAfter - balanceBefore == _fromAmount,
            "contract did not get the loan"
        );
        loan = balanceAfter;

        // do whatever you want with the money
        // the dept will be automatically withdrawn from this contract at the end of execution
        // _arb(_fromSwapAddress, _fromProxyAddress, _fromToken, _toSwapAddress, _toProxyAddress, _toToken, _fromAmount, _ethAmountToCoinbase);
        _arb(_fromSwapAddress, _fromToken, _toSwapAddress, _toToken, _fromAmount, _ethAmountToCoinbase);
    }

    // function arb(address _fromSwapAddress, address _fromProxyAddress, address _fromToken, address _toSwapAddress, address _toProxyAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) onlyOwner payable public {
    //     _arb(_fromSwapAddress, _fromProxyAddress, _fromToken, _toSwapAddress, _toProxyAddress, _toToken, _fromAmount, _ethAmountToCoinbase);
    // }

    function arb(address _fromSwapAddress, address _fromToken, address _toSwapAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) onlyOwner payable public {
        _arb(_fromSwapAddress, _fromToken, _toSwapAddress, _toToken, _fromAmount, _ethAmountToCoinbase);
    }

    // function _arb(address _fromSwapAddress, address _fromProxyAddress, address _fromToken, address _toSwapAddress, address _toProxyAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) internal {
    function _arb(address _fromSwapAddress, address _fromToken, address _toSwapAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) internal {
        // Track original balance
        uint256 _startBalance = IERC20(_fromToken).balanceOf(address(this));

        // Perform the arb trade
        // _trade(_fromSwapAddress, _fromProxyAddress, _fromToken, _toSwapAddress, _toProxyAddress, _toToken, _fromAmount, _ethAmountToCoinbase);
        _trade(_fromSwapAddress, _fromToken, _toSwapAddress, _toToken, _fromAmount, _ethAmountToCoinbase);

        // Track result balance
        uint256 _endBalance = IERC20(_fromToken).balanceOf(address(this));

        // Require that arbitrage is profitable
        require(_endBalance > _startBalance, "End balance must exceed start balance.");
    }

    // function trade(address _fromSwapAddress, address _fromProxyAddress, address _fromToken, address _toSwapAddress, address _toProxyAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) onlyOwner payable public {
    //     _trade(_fromSwapAddress, _fromProxyAddress, _fromToken, _toSwapAddress, _toProxyAddress, _toToken, _fromAmount, _ethAmountToCoinbase);
    // }

    function trade(address _fromSwapAddress, address _fromToken, address _toSwapAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) onlyOwner payable public {
        _trade(_fromSwapAddress, _fromToken, _toSwapAddress, _toToken, _fromAmount, _ethAmountToCoinbase);
    }

    // function _trade(address _fromSwapAddress, address _fromProxyAddress, address _fromToken, address _toSwapAddress, address _toProxyAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) internal {
    function _trade(address _fromSwapAddress, address _fromToken, address _toSwapAddress, address _toToken, uint256 _fromAmount, uint256 _ethAmountToCoinbase) internal {
        uint256 _fromBalanceBefore = IERC20(_fromToken).balanceOf(address(this));
        uint256 _beforeBalance = IERC20(_toToken).balanceOf(address(this));

        // _basicSwap(_fromSwapAddress, _fromProxyAddress, _fromToken, _fromAmount);
        _basicSwap(_fromSwapAddress, _fromToken, _fromAmount);

        uint256 _afterBalance = IERC20(_toToken).balanceOf(address(this));

        uint256 _toAmount = _afterBalance - _beforeBalance;

        // _basicSwap(_toSwapAddress, _toProxyAddress, _toToken, _toAmount);
        _basicSwap(_toSwapAddress, _toToken, _toAmount);
        // _oneSplitSwap(_toToken, _fromToken, _toAmount, minReturn, distribution);

        uint256 _fromBalanceAfter = IERC20(_fromToken).balanceOf(address(this));
        require(_fromBalanceAfter > _fromBalanceBefore);
        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH_TOKEN.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    // function basicSwap(address _swapAddress, address _proxyAddress, address _from, uint256 _amount) onlyOwner public payable {
    //     _basicSwap(_swapAddress, _proxyAddress, _from, _amount);
    // }

    function basicSwap(address _swapAddress, address _from, uint256 _amount) onlyOwner public payable {
        _basicSwap(_swapAddress, _from, _amount);
    }

    // function _basicSwap(address _swapAddress, address _proxyAddress, address _from, uint256 _amount) internal {
    function _basicSwap(address _swapAddress, address _from, uint256 _amount) internal {
        IERC20 _fromIERC20 = IERC20(_from);
        // _fromIERC20.approve(_proxyAddress, _amount);

        address(_swapAddress).call{value: msg.value}("");

        // _fromIERC20.approve(_proxyAddress, 0);
    }

    function oneSplitSwap(address _from, address _to, uint256 _amount, uint256 _minReturn, uint256[] memory _distribution) onlyOwner public payable {
        _oneSplitSwap(_from, _to, _amount, _minReturn, _distribution);
    }

    function _oneSplitSwap(address _from, address _to, uint256 _amount, uint256 _minReturn, uint256[] memory _distribution) internal {
        // Setup contracts
        IERC20 _fromIERC20 = IERC20(_from);
        IERC20 _toIERC20 = IERC20(_to);
        IOneSplit _oneSplitContract = IOneSplit(ONE_SPLIT_ADDRESS);

        // Approve tokens
        _fromIERC20.approve(ONE_SPLIT_ADDRESS, _amount);

        // Swap tokens: give _from, get _to
        _oneSplitContract.swap(_fromIERC20, _toIERC20, _amount, _minReturn, _distribution, FLAGS);

        // Reset approval
        _fromIERC20.approve(ONE_SPLIT_ADDRESS, 0);
    }

    // function uniswapWeth(uint256 _wethAmountToFirstMarket, uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) external onlyExecutor payable {
    //     require (_targets.length == _payloads.length);
    //     uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
    //     WETH.transfer(_targets[0], _wethAmountToFirstMarket);
    //     for (uint256 i = 0; i < _targets.length; i++) {
    //         (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
    //         require(_success); _response;
    //     }

    //     uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
    //     require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase);
    //     if (_ethAmountToCoinbase == 0) return;

    //     uint256 _ethBalance = address(this).balance;
    //     if (_ethBalance < _ethAmountToCoinbase) {
    //         WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
    //     }
    //     block.coinbase.transfer(_ethAmountToCoinbase);
    // }

    // function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
    //     require(_to != address(0));
    //     (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
    //     require(_success);
    //     return _result;
    // }

    function getWeth() public payable onlyOwner {
        _getWeth(msg.value);
    }

    function _getWeth(uint256 _amount) internal {
        (bool success, ) = WETH.call{value: _amount}("");
        require(success, "failed to get weth");
    }

    // function approveWeth(uint256 _amount) public onlyOwner {
    //     _approveWeth(_amount);
    // }

    // function _approveWeth(uint256 _amount) internal {
    //     IERC20(WETH).approve(ZRX_STAKING_PROXY, _amount); // approves the 0x staking proxy - the proxy is the fee collector for 0x, i.e. we will use WETH in order to pay for trading fees
    // }

    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(owner, balance);
    }

    function withdrawEther() public onlyOwner {
        address self = address(this); // workaround for a possible solidity bug
        uint256 balance = self.balance;
        owner.transfer(balance);
    }
}