/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

pragma experimental ABIEncoderV2;

// These definitions are taken from across multiple dydx contracts, and are
// limited to just the bare minimum necessary to make flash loans work.
library Types {
    enum AssetDenomination { Wei, Par }
    enum AssetReference { Delta, Target }
    struct AssetAmount {
        bool sign;
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }
}

library Account {
    struct Info {
        address owner;
        uint256 number;
    }
}

library Actions {
    enum ActionType {
        Deposit, Withdraw, Transfer, Buy, Sell, Trade, Liquidate, Vaporize, Call
    }
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        Types.AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }
}

interface ISoloMargin {
    function operate(Account.Info[] memory accounts, Actions.ActionArgs[] memory actions) external;
}

// The interface for a contract to be callable after receiving a flash loan
interface ICallee {
    function callFunction(address sender, Account.Info memory accountInfo, bytes memory data) external;
}

// Standard ERC-20 interface
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Additional methods available for WETH
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract FlashBotsMultiCall02 is ICallee {
    
    struct ArbitrageData {
        uint256 wethAmountToFirstMarket;
        uint256 ethAmountToCoinbase;
        address[] targets;
        bytes[] payloads;
    }

    // The WETH token contract, since we're assuming we want a loan in WETH
    IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    // The dydx Solo Margin contract
    ISoloMargin private constant soloMargin = ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    address private immutable owner;
    address private executor;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor);
        _;
    }

    constructor(address _executor) public payable {
        owner = msg.sender;
        executor = _executor;
        if (msg.value > 0) {
            WETH.deposit{value: msg.value}();
        }
        // Give infinite approval to dydx to withdraw WETH on contract deployment,
        // so we don't have to approve the loan repayment amount (+2 wei) on each call.
        // The approval is used by the dydx contract to pay the loan back to itself.
        WETH.approve(address(soloMargin), uint(-1));
    }

    receive() external payable {
    }

    function withdrawAmount(address payable receiver, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance);
        receiver.transfer(amount);
    }

    function withdrawTokenAmount(address receiver, uint256 amount, IERC20 token) public onlyOwner {
        require(amount <= token.balanceOf(address(this)));
        token.transfer(receiver, amount);
    }

    function setExecutor(address _executor) public onlyOwner {
        executor = _executor;
    }

    // This is the function we call
    function flashLoan(
        uint256 _wethAmountToFirstMarket,
        uint256 _ethAmountToCoinbase,
        address[] memory _targets,
        bytes[] memory _payloads
    ) external onlyExecutor {
        /*
        The flash loan functionality in dydx is predicated by their "operate" function,
        which takes a list of operations to execute, and defers validating the state of
        things until it's done executing them.
        
        We thus create three operations, a Withdraw (which loans us the funds), a Call
        (which invokes the callFunction method on this contract), and a Deposit (which
        repays the loan, plus the 2 wei fee), and pass them all to "operate".
        
        Note that the Deposit operation will invoke the transferFrom to pay the loan 
        (or whatever amount it was initialised with) back to itself, there is no need
        to pay it back explicitly.
        
        The loan must be given as an ERC-20 token, so WETH is used instead of ETH. Other
        currencies (DAI, USDC) are also available, their index can be looked up by
        calling getMarketTokenAddress on the solo margin contract, and set as the 
        primaryMarketId in the Withdraw and Deposit definitions.
        */

        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);
        
        // 1. Withdraw
        operations[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: _wethAmountToFirstMarket // Amount to borrow
            }),
            primaryMarketId: 0, // WETH
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        // 2. Call
        operations[1] = Actions.ActionArgs({
            actionType: Actions.ActionType.Call,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: 0
            }),
            primaryMarketId: 0,
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: abi.encode(
                ArbitrageData({
                    wethAmountToFirstMarket: _wethAmountToFirstMarket,
                    ethAmountToCoinbase: _ethAmountToCoinbase,
                    targets: _targets,
                    payloads: _payloads
                })
            )
        });

        // 3. Deposit
        operations[2] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: _wethAmountToFirstMarket + 2 // Repayment amount with 2 wei fee
            }),
            primaryMarketId: 0, // WETH
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = Account.Info({owner: address(this), number: 1});

        soloMargin.operate(accountInfos, operations);
    }

    // This is the function called by dydx after giving us the loan
    function callFunction(address sender, Account.Info memory accountInfo, bytes memory data) external override {
        require(msg.sender == address(soloMargin), 'SIMP AT [email protected]');
        // Decode the passed variables from the data object
        ArbitrageData memory arbData = abi.decode(data, (ArbitrageData));
        
        // Arbitrage logic
        arbitrage(arbData.wethAmountToFirstMarket, arbData.ethAmountToCoinbase, arbData.targets, arbData.payloads);

        // It can be useful for debugging to have a verbose error message when
        // the loan can't be paid, since dydx doesn't provide one
        require(WETH.balanceOf(address(this)) > arbData.wethAmountToFirstMarket + 2, "RUGGED IN PROD");
        // Leave just enough WETH to pay back the loan, and convert the rest to ETH
        // WETH.withdraw(WETH.balanceOf(address(this)) - loanAmount - 2);
        // Send any profit in ETH to the account that invoked this transaction
        // actualSender.transfer(address(this).balance);
    }

    function uniswapWeth(
        uint256 _wethAmountToFirstMarket,
        uint256 _ethAmountToCoinbase,
        address[] memory _targets,
        bytes[] memory _payloads
    ) external onlyExecutor payable {
        arbitrage(_wethAmountToFirstMarket, _ethAmountToCoinbase, _targets, _payloads);
    }

    function arbitrage(uint256 _wethAmountToFirstMarket, uint256 _ethAmountToCoinbase, address[] memory _targets, bytes[] memory _payloads) private {
        require (_targets.length == _payloads.length);
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        require(_wethBalanceBefore >= _wethAmountToFirstMarket);

        WETH.transfer(_targets[0], _wethAmountToFirstMarket);
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool _success, bytes memory _response) = _targets[i].call(_payloads[i]);
            require(_success); _response;
        }

        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceAfter > _wethBalanceBefore + _ethAmountToCoinbase);
        if (_ethAmountToCoinbase == 0) return;

        uint256 _ethBalance = address(this).balance;
        if (_ethBalance < _ethAmountToCoinbase) {
            WETH.withdraw(_ethAmountToCoinbase - _ethBalance);
        }
        block.coinbase.transfer(_ethAmountToCoinbase);
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data);
        require(_success);
        return _result;
    }
}