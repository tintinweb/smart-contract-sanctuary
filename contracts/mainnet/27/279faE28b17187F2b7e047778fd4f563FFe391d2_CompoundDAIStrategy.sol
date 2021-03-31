/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


// 
// From https://gist.github.com/cryptoscopia/1156a368c19a82be2d083e04376d261e
// The ABI encoder is necessary, but older Solidity versions should work
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

// Standard ERC-20 interface
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract FlashLoanTemplate {
    // The DAI token contract, since we're assuming we want a loan in DAI
    IERC20 internal DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // The dydx Solo Margin contract, as can be found here:
    // https://github.com/dydxprotocol/solo/blob/master/migrations/deployed.json
    ISoloMargin internal soloMargin = ISoloMargin(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    // // RINKEBY testnet contracts
    // ISoloMargin internal soloMargin = ISoloMargin(0x4EC3570cADaAEE08Ae384779B0f3A45EF85289DE);
    // IERC20 internal DAI = IERC20(0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa);

    enum OperationType { Inflate, Deflate }

    constructor() {
        // Give infinite approval to dydx to withdraw WETH on contract deployment,
        // so we don't have to approve the loan repayment amount (+2 wei) on each call.
        // The approval is used by the dydx contract to pay the loan back to itself.
        DAI.approve(address(soloMargin), uint(-1));
    }
    
    // This is the function we call
    function _flashLoan(uint loanAmount, OperationType opType) internal {

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
            primaryMarketId: 3, // DAI
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
                    loanAmount,
                    opType
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
            primaryMarketId: 3, // DAI
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
    function callFunction(address sender, Account.Info memory accountInfo, bytes memory data) external virtual;
}

// 
interface ICERC20 is IERC20 {
    function mint(uint256) external returns (uint256);
    function borrow(uint256) external returns (uint);
    function repayBorrow(uint256) external returns (uint);
    function redeem(uint) external returns (uint);
    function redeemUnderlying(uint) external returns (uint);
    function borrowBalanceCurrent(address) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
}

interface Comptroller {
    function enterMarkets(address[] calldata)
        external
        returns (uint256[] memory);

    function claimComp(address holder) external;
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}

/**
 * @dev CompoundDAIStrategy contract.
 * This contracts implements strategy to incresea income in COMP.
 * @author Grigorii Melnikov <[email protected]>
 */
contract CompoundDAIStrategy is FlashLoanTemplate {
    using SafeMath for uint256;

    // The cDAI token contract
    ICERC20 private cDAI = ICERC20(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    // The COMP token contract
    IERC20 private COMP = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    // The Comptroller token contract
    Comptroller private comptroller = Comptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    
    address public owner;

    // // RINKEBY testnet
    // ICERC20 private cDAI = ICERC20(0x6D7F0754FFeb405d23C51CE938289d4835bE3b14);
    // IERC20 private COMP = IERC20(0x61460874a7196d6a22D1eE4922473664b3E95270);
    // Comptroller private comptroller = Comptroller(0x2EAa9D77AE4D8f9cdD9FAAcd44016E746485bddb);

    // Current collateral factor (k) for DAI = 75%
    // x - initial supply in DAI, y - additional supply in DAI and borrow amount
    // y < k * (x + y) => y < [ k / (1 - k) ] * x
    // COLLATERAL_VALUE = k / (1 - k) = 3
    // uint256 public constant COLLATERAL_VALUE = 3;

    constructor(address agent) FlashLoanTemplate() {
        owner = agent;
        _enterDaiMarket();
        // Approve transfers on the cDAI contract
        DAI.approve(address(cDAI), uint256(-1));
        DAI.approve(owner, uint256(-1));
    }

    modifier onlyOwner() {
        require (owner == msg.sender, "CompoundDAIStrategy: not owner.");
        _;
    }

    function _supplyDaiInternal(uint256 numTokensToSupply) private {
        // Mint cTokens
        uint256 mintResult = cDAI.mint(numTokensToSupply);
        require(mintResult == 0, "CompoundDAIStrategy: mint failed.");
    }

    /**
     * @notice Sender supply DAI tokens to Compound protocol
     * @param numTokensToSupply The amount of DAIs to supply in Compound
     * @param loanFee The amount of loans' fee
     */
    function supplyDai(uint256 numTokensToSupply, uint256 loanFee) external onlyOwner {
        DAI.transferFrom(owner, address(this), numTokensToSupply.add(loanFee));

        _supplyDaiInternal(numTokensToSupply);
    }

    function _redeemUnderlyingInternal(uint256 numTokensToRedeem) private {
        uint256 result = cDAI.redeemUnderlying(numTokensToRedeem);

        require(result == 0, "CompoundDAIStrategy: redeemUnderlying failed.");
    }

    /**
     * @notice Redeem all DAIs from Compound and transfer them to owner
     */
    function redeemAll() external onlyOwner {
        uint256 result = cDAI.redeem(cDAI.balanceOf(address(this)));

        require(result == 0, "CompoundDAIStrategy: redeemAll failed.");
        DAI.transfer(owner, DAI.balanceOf(address(this)));
    }

    function _enterDaiMarket() private {
        address[] memory cTokens = new address[](1);
        cTokens[0] = address(cDAI);
        uint256[] memory errors = comptroller.enterMarkets(cTokens);

        require(errors[0] == 0, "CompoundDAIStrategy: enterMarkets failed.");
    }

    function _borrowDaiFromCompound(uint256 numTokensToBorrow) private {
        uint256 borrowResult = cDAI.borrow(numTokensToBorrow);
        if (borrowResult == 0) {
            return;
        } else if (borrowResult == 3 /* COMPTROLLER_REJECTION */) {
            revert("CompoundDAIStrategy: Insuficient collateral.");
        } else {
            revert("CompoundDAIStrategy: borrow failed.");
        }
    }

    function _repayBorrow(uint256 repayAmmount) private {
        uint256 error = cDAI.repayBorrow(repayAmmount);

        require(error == 0, "CompoundDAIStrategy: repayment borrow failed.");
    }

    /**
     * @notice Sender takes a flashloan, supplies loan on Compound and borrows the same amount to return loan
     * @dev Size of the flashloan should be less than COLLATERAL FACTOR * balanceUnderlying
     * @param numTokensToInflate The amount of DAI tokens to inflate
     */
    function inflate(uint256 numTokensToInflate) external onlyOwner {
        require(numTokensToInflate > 0, "CompoundDAIStrategy: Inflate request with zero amount.");
        require(DAI.balanceOf(address(this)) >= 2, "CompoundDAIStrategy: Not enough DAIs for DyDx flashloan.");

        require(
            numTokensToInflate <= DAI.balanceOf(address(soloMargin)),
            "CompoundDAIStrategy: Not enough DAIs in DyDx pool."
        );
        _flashLoan(numTokensToInflate, OperationType.Inflate);
    }

    /**
     * @notice Sender takes a flashloan, repays borrow and redeem underlying tokens to return loan
     */
    function deflate() external onlyOwner {
        require(DAI.balanceOf(address(this)) >= 2, "CompoundDAIStrategy: Not enoug DAIs for DyDx flashloan.");

        uint256 borrowBalance = cDAI.borrowBalanceCurrent(address(this));

        require(
            borrowBalance <= DAI.balanceOf(address(soloMargin)),
            "CompoundDAIStrategy: Not enough DAIs in DyDx pool."
        );
        _flashLoan(borrowBalance, OperationType.Deflate);
    }

    function callFunction(address /* sender */, Account.Info memory /* accountInfo */, bytes memory data)
        external 
        override 
    {
        require(msg.sender == address(soloMargin), "CompoundDAIStrategy: Only DyDx Solo margin contract can call.");

        // This must match the variables defined in the FlashLoanTemplate
        (
            uint loanAmount,
            OperationType opType
        ) = abi.decode(data, (
            uint, OperationType
        ));

        if (opType == OperationType.Inflate) {
            _supplyDaiInternal(loanAmount);
            _borrowDaiFromCompound(loanAmount);
        } else {
            _repayBorrow(loanAmount);
            _redeemUnderlyingInternal(loanAmount);
        }
    }

    /**
     * @notice Claim COMP tokens
     */
    function claimComp() external onlyOwner {
        comptroller.claimComp(address(this));

        COMP.transfer(owner, COMP.balanceOf(address(this)));
    }

    function changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function repayManually(address cTokenAddr) external onlyOwner {
        ICERC20 cToken = ICERC20(cTokenAddr);

        cToken.repayBorrow(uint256(-1));
    }
}