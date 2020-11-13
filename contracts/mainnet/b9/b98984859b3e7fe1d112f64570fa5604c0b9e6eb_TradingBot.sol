pragma solidity ^0.5.0;
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

contract DyDxPool is Structs {
    function getAccountWei(Info memory account, uint256 marketId) public view returns (Wei memory);
    function operate(Info[] memory, ActionArgs[] memory) public;
}


pragma solidity ^0.5.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
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


pragma solidity ^0.5.0;




contract DyDxFlashLoan is Structs {
    DyDxPool pool = DyDxPool(0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e);

    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public SAI = 0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    
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


pragma solidity ^0.5.0;


contract IOneSplit {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
        public
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
    ) public payable;
}

contract TradingBot is DyDxFlashLoan {
    uint256 public loan;

    // Addresses
    address payable OWNER;

    // OneSplit Config
    address ONE_SPLIT_ADDRESS = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    uint256 PARTS = 10;
    uint256 FLAGS = 0;

    // ZRX Config
    address ZRX_EXCHANGE_ADDRESS = 0x61935CbDd02287B511119DDb11Aeb42F1593b7Ef;
    address ZRX_ERC20_PROXY_ADDRESS = 0x95E6F48254609A6ee006F7D493c8e5fB97094ceF;
    address ZRX_STAKING_PROXY = 0xa26e80e7Dea86279c6d778D702Cc413E6CFfA777; // Fee collector

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == OWNER, "caller is not the owner!");
        _;
    }

    // Allow the contract to receive Ether
    function () external payable  {}

    constructor() public payable {
        _getWeth(msg.value);
        _approveWeth(msg.value);
        OWNER = msg.sender;
    }

    function getFlashloan(address flashToken, uint256 flashAmount, address arbToken, bytes calldata zrxData, uint256 oneSplitMinReturn, uint256[] calldata oneSplitDistribution) external payable onlyOwner {
        uint256 balanceBefore = IERC20(flashToken).balanceOf(address(this));
        bytes memory data = abi.encode(flashToken, flashAmount, balanceBefore, arbToken, zrxData, oneSplitMinReturn, oneSplitDistribution);
        flashloan(flashToken, flashAmount, data); // execution goes to `callFunction`

        // and this point we have succefully paid the dept
    }

    function callFunction(
        address, /* sender */
        Info calldata, /* accountInfo */
        bytes calldata data
    ) external onlyPool {
        (address flashToken, uint256 flashAmount, uint256 balanceBefore, address arbToken, bytes memory zrxData, uint256 oneSplitMinReturn, uint256[] memory oneSplitDistribution) = abi
            .decode(data, (address, uint256, uint256, address, bytes, uint256, uint256[]));
        uint256 balanceAfter = IERC20(flashToken).balanceOf(address(this));
        require(
            balanceAfter - balanceBefore == flashAmount,
            "contract did not get the loan"
        );
        loan = balanceAfter;

        // do whatever you want with the money
        // the dept will be automatically withdrawn from this contract at the end of execution
        _arb(flashToken, arbToken, flashAmount, zrxData, oneSplitMinReturn, oneSplitDistribution);
    }

    function arb(address _fromToken, address _toToken, uint256 _fromAmount, bytes memory _0xData, uint256 _1SplitMinReturn, uint256[] memory _1SplitDistribution) onlyOwner payable public {
        _arb(_fromToken, _toToken, _fromAmount, _0xData, _1SplitMinReturn, _1SplitDistribution);
    }

    function _arb(address _fromToken, address _toToken, uint256 _fromAmount, bytes memory _0xData, uint256 _1SplitMinReturn, uint256[] memory _1SplitDistribution) internal {
        // Track original balance
        uint256 _startBalance = IERC20(_fromToken).balanceOf(address(this));

        // Perform the arb trade
        _trade(_fromToken, _toToken, _fromAmount, _0xData, _1SplitMinReturn, _1SplitDistribution);

        // Track result balance
        uint256 _endBalance = IERC20(_fromToken).balanceOf(address(this));

        // Require that arbitrage is profitable
        require(_endBalance > _startBalance, "End balance must exceed start balance.");
    }

    function trade(address _fromToken, address _toToken, uint256 _fromAmount, bytes memory _0xData, uint256 _1SplitMinReturn, uint256[] memory _1SplitDistribution) onlyOwner payable public {
        _trade(_fromToken, _toToken, _fromAmount, _0xData, _1SplitMinReturn, _1SplitDistribution);
    }

    function _trade(address _fromToken, address _toToken, uint256 _fromAmount, bytes memory _0xData, uint256 _1SplitMinReturn, uint256[] memory _1SplitDistribution) internal {
        // Track the balance of the token RECEIVED from the trade
        uint256 _beforeBalance = IERC20(_toToken).balanceOf(address(this));

        // Swap on 0x: give _fromToken, receive _toToken
        _zrxSwap(_fromToken, _fromAmount, _0xData);

        // Calculate the how much of the token we received
        uint256 _afterBalance = IERC20(_toToken).balanceOf(address(this));

        // Read _toToken balance after swap
        uint256 _toAmount = _afterBalance - _beforeBalance;

        // Swap on 1Split: give _toToken, receive _fromToken
        _oneSplitSwap(_toToken, _fromToken, _toAmount, _1SplitMinReturn, _1SplitDistribution);
    }

    function zrxSwap(address _from, uint256 _amount, bytes memory _calldataHexString) onlyOwner public payable {
        _zrxSwap(_from, _amount, _calldataHexString);
    }

    function _zrxSwap(address _from, uint256 _amount, bytes memory _calldataHexString) internal {
        // Approve tokens
        IERC20 _fromIERC20 = IERC20(_from);
        _fromIERC20.approve(ZRX_ERC20_PROXY_ADDRESS, _amount);

        // Swap tokens
        address(ZRX_EXCHANGE_ADDRESS).call.value(msg.value)(_calldataHexString);

        // Reset approval
        _fromIERC20.approve(ZRX_ERC20_PROXY_ADDRESS, 0);
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

    function getWeth() public payable onlyOwner {
        _getWeth(msg.value);
    }

    function _getWeth(uint256 _amount) internal {
        (bool success, ) = WETH.call.value(_amount)("");
        require(success, "failed to get weth");
    }

    function approveWeth(uint256 _amount) public onlyOwner {
        _approveWeth(_amount);
    }

    function _approveWeth(uint256 _amount) internal {
        IERC20(WETH).approve(ZRX_STAKING_PROXY, _amount);
    }

    // KEEP THIS FUNCTION IN CASE THE CONTRACT RECEIVES TOKENS!
    function withdrawToken(address _tokenAddress) public onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(OWNER, balance);
    }

    // KEEP THIS FUNCTION IN CASE THE CONTRACT KEEPS LEFTOVER ETHER!
    function withdrawEther() public onlyOwner {
        address self = address(this); // workaround for a possible solidity bug
        uint256 balance = self.balance;
        address(OWNER).transfer(balance);
    }
}