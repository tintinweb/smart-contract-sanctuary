/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

pragma solidity 0.6.7;

abstract contract TokenLike {
    function balanceOf(address) virtual public view returns (uint256);
}
abstract contract AccountingEngineLike {
    function debtAuctionBidSize() virtual public view returns (uint256);
    function unqueuedUnauctionedDebt() virtual public view returns (uint256);
}
abstract contract GebLenderFirstResortLike {
    function ancestorPool() virtual external view returns (address);
    function modifyParameters(bytes32, uint256) virtual external;
}
abstract contract SAFEEngineLike {
    function coinBalance(address) virtual public view returns (uint256);
    function debtBalance(address) virtual public view returns (uint256);
}
abstract contract TokenPoolLike {
    function token() virtual external view returns (address);
}

contract StakedTokensToKeepSetter {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) virtual external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "StakedTokensToKeepSetter/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Percentage of tokens to keep in the pool at all times
    uint256                  public tokenPercentageToKeep;
    // The lender of first resort pool
    GebLenderFirstResortLike public lenderFirstResort;
    // Accounting engine contract
    AccountingEngineLike     public accountingEngine;
    // SAFE database
    SAFEEngineLike           public safeEngine;

    uint256 public constant  MIN_TOKENS = 1 ether;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event RecomputeTokensToKeep(uint256 tokensToKeep);

    constructor(address safeEngine_, address accountingEngine_, address lenderFirstResort_, uint256 tokenPercentageToKeep_) public {
        require(accountingEngine_ != address(0), "StakedTokensToKeepSetter/null-accounting-engine");
        require(lenderFirstResort_ != address(0), "StakedTokensToKeepSetter/null-lender-first-resort");
        require(safeEngine_ != address(0), "StakedTokensToKeepSetter/null-safe-engine");
        require(both(tokenPercentageToKeep_ > 0, tokenPercentageToKeep_ < HUNDRED), "StakedTokensToKeepSetter/invalid-pc-to-keep");

        authorizedAccounts[msg.sender] = 1;

        accountingEngine      = AccountingEngineLike(accountingEngine_);
        lenderFirstResort     = GebLenderFirstResortLike(lenderFirstResort_);
        safeEngine            = SAFEEngineLike(safeEngine_);
        tokenPercentageToKeep = tokenPercentageToKeep_;

        emit AddAuthorization(msg.sender);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- Math ---
    uint256 public constant HUNDRED = 100;
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "StakedTokensToKeepSetter/mul-overflow");
    }

    // --- Administration ---
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "tokenPercentageToKeep") {
          require(both(data > 0, data < HUNDRED), "StakedTokensToKeepSetter/invalid-pc-to-keep");
          tokenPercentageToKeep = data;
        }
        else revert("StakedTokensToKeepSetter/modify-unrecognized-param");
    }

    // --- Core Logic ---
    /*
    * @notice Returns whether the protocol is underwater or not
    */
    function protocolUnderwater() public view returns (bool) {
        uint256 unqueuedUnauctionedDebt = accountingEngine.unqueuedUnauctionedDebt();

        return both(
          accountingEngine.debtAuctionBidSize() <= unqueuedUnauctionedDebt,
          safeEngine.coinBalance(address(accountingEngine)) < unqueuedUnauctionedDebt
        );
    }

    /*
    * @notice Recompute and set the new min amount of tokens to keep unauctioned in the lender of first resort pool
    */
    function recomputeTokensToKeep() external {
        require(!protocolUnderwater(), "StakedTokensToKeepSetter/cannot-compute-when-underwater");

        TokenPoolLike ancestorPool = TokenPoolLike(address(lenderFirstResort.ancestorPool()));
        TokenLike ancestorToken    = TokenLike(address(ancestorPool.token()));

        uint256 tokensToKeep       = multiply(tokenPercentageToKeep, ancestorToken.balanceOf(address(ancestorPool))) / HUNDRED;
        if (tokensToKeep == 0) {
          tokensToKeep = MIN_TOKENS;
        }

        lenderFirstResort.modifyParameters("minStakedTokensToKeep", tokensToKeep);

        emit RecomputeTokensToKeep(tokensToKeep);
    }
}