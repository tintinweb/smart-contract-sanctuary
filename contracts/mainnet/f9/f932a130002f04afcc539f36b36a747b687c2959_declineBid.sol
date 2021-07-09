/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

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

interface Cryptopunks {
    function punkIndexToAddress (uint256 punkIndex) external view returns (address);
    function punkBids (uint256 punkIndex) external view returns ( bool , uint256 , address , uint256 );
    function enterBidForPunk (uint256 punkIndex) external payable;
    function withdrawBidForPunk (uint256 punkIndex) external;
    function withdraw () external;
}

interface ENS{
    function setName(string memory name) external returns (bytes32);
}

contract declineBid is ICallee {
    // The WETH token contract, since we're assuming we want a loan in WETH
    IWETH private WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // The dydx Solo Margin contract, as can be found here:
    // https://github.com/dydxprotocol/solo/blob/master/migrations/deployed.json
    ISoloMargin private soloMargin = ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);
    Cryptopunks constant punkContract=Cryptopunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    ENS constant ensRegistar=ENS(0x084b1c3C81545d370f3634392De611CaaBFf8148);
    address private owner;

    constructor() {
        // Give infinite approval to dydx to withdraw WETH on contract deployment,
        // so we don't have to approve the loan repayment amount (+2 wei) on each call.
        // The approval is used by the dydx contract to pay the loan back to itself.
        WETH.approve(address(soloMargin), uint(-1));
        owner= msg.sender;
    }
    
    // This is the function we call
    function declineBidOnPunk(uint256 punkIndex) external {
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
        
        (,,,uint loanAmount) = punkContract.punkBids(punkIndex) ; //add 1 wei
        require (loanAmount!=0,"No bid on this punk!");
        require (msg.sender==owner || msg.sender==punkContract.punkIndexToAddress(punkIndex),"Not your punk!"); //owner may use for testing
        loanAmount+=1;

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
                    loanAmount,
                    punkIndex
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
            uint loanAmount,
            uint256 punkIndex

        ) = abi.decode(data, (
            address, uint, uint256
        ));
        
        // We now have a WETH balance of loanAmount. The logic for what we
        // want to do with it goes here. The code below is just there in case
        // it's useful.
        WETH.withdraw(loanAmount);
        punkContract.enterBidForPunk{value:loanAmount}(punkIndex);
        punkContract.withdrawBidForPunk(punkIndex);
        punkContract.withdraw();
        WETH.deposit{value: loanAmount}();
        // It can be useful for debugging to have a verbose error message when
        // the loan can't be paid, since dydx doesn't provide one
        require(WETH.balanceOf(address(this)) > loanAmount + 2, "CANNOT REPAY LOAN");
    }

    function setReverseRecord(string memory _name) external 
    {
        require (msg.sender==owner);
        ensRegistar.setName(_name);
    }
}