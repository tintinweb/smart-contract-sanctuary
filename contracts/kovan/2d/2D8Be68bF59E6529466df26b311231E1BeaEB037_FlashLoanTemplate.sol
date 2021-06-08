// SPDX-License-Identifier: AGPL-3.0-or-later

// The ABI encoder is necessary, but older Solidity versions should work
pragma solidity ^0.7.0;
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

contract FlashLoanTemplate is ICallee {
    // The WETH token contract, since we're assuming we want a loan in WETH
    //IWETH private WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // kovan
    IWETH private WETH = IWETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    // The dydx Solo Margin contract, as can be found here:
    // https://github.com/dydxprotocol/solo/blob/master/migrations/deployed.json
    //ISoloMargin private soloMargin = ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    // kovan
    ISoloMargin private soloMargin = ISoloMargin(0x4EC3570cADaAEE08Ae384779B0f3A45EF85289DE);

    constructor() {
        // Give infinite approval to dydx to withdraw WETH on contract deployment,
        // so we don't have to approve the loan repayment amount (+2 wei) on each call.
        // The approval is used by the dydx contract to pay the loan back to itself.
        WETH.approve(address(soloMargin), uint(-1));
    }
    
    // This is the function we call
    function flashLoan(uint loanAmount) external {
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

        operations[0] = Actions.ActionArgs({
            actionType: Actions.ActionType.Withdraw,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: false,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: loanAmount // Amount to borrow
            }),
            primaryMarketId: 0, // WETH
            secondaryMarketId: 0,
            otherAddress: address(this),
            otherAccountId: 0,
            data: ""
        });
        
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
                    // Replace or add any additional variables that you want
                    // to be available to the receiver function
                    msg.sender,
                    loanAmount
                )
            });
        
        operations[2] = Actions.ActionArgs({
            actionType: Actions.ActionType.Deposit,
            accountId: 0,
            amount: Types.AssetAmount({
                sign: true,
                denomination: Types.AssetDenomination.Wei,
                ref: Types.AssetReference.Delta,
                value: loanAmount + 2 // Repayment amount with 2 wei fee
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
        // Decode the passed variables from the data object
        (
            // This must match the variables defined in the Call object above
            address payable actualSender,
            uint loanAmount
        ) = abi.decode(data, (
            address, uint
        ));
        
        // We now have a WETH balance of loanAmount. The logic for what we
        // want to do with it goes here. The code below is just there in case
        // it's useful.
        
        // It can be useful for debugging to have a verbose error message when
        // the loan can't be paid, since dydx doesn't provide one
        require(WETH.balanceOf(address(this)) > loanAmount + 2, "CANNOT REPAY LOAN");
        // Leave just enough WETH to pay back the loan, and convert the rest to ETH
        WETH.withdraw(WETH.balanceOf(address(this)) - loanAmount - 2);
        // Send any profit in ETH to the account that invoked this transaction
        actualSender.transfer(address(this).balance);
    }

    fallback () payable external {}
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}