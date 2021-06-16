/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

pragma solidity ^0.6.7;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


abstract contract TokenLike {
    function decimals() virtual public view returns (uint8);
    function totalSupply() virtual public view returns (uint256);
    function balanceOf(address) virtual public view returns (uint256);
    function mint(address, uint) virtual public;
    function burn(address, uint) virtual public;
    function approve(address, uint256) virtual external returns (bool);
    function transfer(address, uint256) virtual external returns (bool);
    function transferFrom(address,address,uint256) virtual external returns (bool);
}
abstract contract AuctionHouseLike {
    function activeStakedTokenAuctions() virtual public view returns (uint256);
    function startAuction(uint256, uint256) virtual external returns (uint256);
}
abstract contract AccountingEngineLike {
    function debtAuctionBidSize() virtual public view returns (uint256);
    function unqueuedUnauctionedDebt() virtual public view returns (uint256);
    function totalOnAuctionDebt() virtual public returns (uint256);
    function cancelAuctionedDebtWithSurplus(uint256) virtual external;    
    function safeEngine() virtual public view returns (address);
    function systemStakingPool() virtual public view returns (address);
    function modifyParameters(bytes32, address) external virtual;    
}
abstract contract SAFEEngineLike {
    function coinBalance(address) virtual public view returns (uint256);
    function debtBalance(address) virtual public view returns (uint256);
    function transferInternalCoins(address,address,uint256) virtual external;
    function createUnbackedDebt(address,address,uint256) virtual external;    
}

contract GebLenderFirstResort is ReentrancyGuard {
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
        require(authorizedAccounts[msg.sender] == 1, "ProtocolTokenLenderFirstResort/account-not-authorized");
        _;
    }

    // --- Structs ---
    struct ExitRequest {
        // Exit window deadline
        uint256 deadline;
        // Ancestor amount queued for exit
        uint256 lockedAmount;
    }

    // --- Variables ---
    // Flag that allows/blocks joining
    bool      public canJoin;
    // Flag that indicates whether canPrintProtocolTokens can ignore auctioning ancestor tokens
    bool      public bypassAuctions;
    // Whether the contract allows forced exits or not
    bool      public forcedExit;
    // Last block when a reward was pulled
    uint256   public lastRewardBlock;
    // The current delay enforced on an exit
    uint256   public exitDelay;
    // Min maount of ancestor tokens that must remain in the contract and not be auctioned
    uint256   public minStakedTokensToKeep;
    // Max number of auctions that can be active at a time
    uint256   public maxConcurrentAuctions;
    // Amount of ancestor tokens to auction at a time
    uint256   public tokensToAuction;
    // Initial amount of system coins to request in exchange for tokensToAuction
    uint256   public systemCoinsToRequest;

    // Exit data
    mapping(address => ExitRequest) public exitRequests;

    // The token being deposited in the pool
    TokenLike            public ancestor;
    // The token being backed by ancestor tokens
    TokenLike            public descendant;
    // Auction house for staked tokens
    AuctionHouseLike     public auctionHouse;
    // Accounting engine contract
    AccountingEngineLike public accountingEngine;
    // The safe engine contract
    SAFEEngineLike       public safeEngine;

    // Max delay that can be enforced for an exit
    uint256 public immutable MAX_DELAY;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(bytes32 indexed parameter, uint256 data);
    event ModifyParameters(bytes32 indexed parameter, address data);
    event ToggleJoin(bool canJoin);
    event ToggleBypassAuctions(bool bypassAuctions);
    event ToggleForcedExit(bool forcedExit);
    event AuctionAncestorTokens(address auctionHouse, uint256 amountAuctioned, uint256 amountRequested);
    event RequestExit(address indexed account, uint256 start, uint256 end);
    event Join(address indexed account, uint256 price, uint256 amount);
    event Exit(address indexed account, uint256 price, uint256 amount);

    constructor(
      address ancestor_,
      address descendant_,
      address auctionHouse_,
      address accountingEngine_,
      address safeEngine_,
      uint256 maxDelay_,
      uint256 exitDelay_,
      uint256 minStakedTokensToKeep_,
      uint256 tokensToAuction_,
      uint256 systemCoinsToRequest_
    ) public {
        require(maxDelay_ > 0, "ProtocolTokenLenderFirstResort/null-max-delay");
        require(exitDelay_ <= maxDelay_, "ProtocolTokenLenderFirstResort/invalid-exit-delay");
        require(minStakedTokensToKeep_ > 0, "ProtocolTokenLenderFirstResort/null-min-staked-tokens");
        require(tokensToAuction_ > 0, "ProtocolTokenLenderFirstResort/null-tokens-to-auction");
        require(systemCoinsToRequest_ > 0, "ProtocolTokenLenderFirstResort/null-sys-coins-to-request");
        require(auctionHouse_ != address(0), "ProtocolTokenLenderFirstResort/null-auction-house");
        require(accountingEngine_ != address(0), "ProtocolTokenLenderFirstResort/null-accounting-engine");
        require(safeEngine_ != address(0), "ProtocolTokenLenderFirstResort/null-safe-engine");

        authorizedAccounts[msg.sender] = 1;
        canJoin                        = true;
        maxConcurrentAuctions          = uint(-1);

        MAX_DELAY                      = maxDelay_;

        exitDelay                      = exitDelay_;

        minStakedTokensToKeep          = minStakedTokensToKeep_;
        tokensToAuction                = tokensToAuction_;
        systemCoinsToRequest           = systemCoinsToRequest_;

        auctionHouse                   = AuctionHouseLike(auctionHouse_);
        accountingEngine               = AccountingEngineLike(accountingEngine_);
        safeEngine                     = SAFEEngineLike(safeEngine_);

        ancestor                       = TokenLike(ancestor_);
        descendant                     = TokenLike(descendant_);

        require(ancestor.decimals() == 18, "ProtocolTokenLenderFirstResort/ancestor-decimal-mismatch");
        require(descendant.decimals() == 18, "ProtocolTokenLenderFirstResort/descendant-decimal-mismatch");

        emit AddAuthorization(msg.sender);
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    uint256 public constant WAD = 10 ** 18;

    function addition(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ProtocolTokenLenderFirstResort/add-overflow");
    }
    function subtract(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ProtocolTokenLenderFirstResort/sub-uint-uint-underflow");
    }
    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ProtocolTokenLenderFirstResort/mul-overflow");
    }
    function wdivide(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "ProtocolTokenLenderFirstResort/wdiv-by-zero");
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) internal pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }

    // --- Administration ---
    /*
    * @notify Switch between allowing and disallowing joins
    */
    function toggleJoin() external isAuthorized {
        canJoin = !canJoin;
        emit ToggleJoin(canJoin);
    }
    /*
    * @notify Switch between ignoring and taking into account auctions in canPrintProtocolTokens
    */
    function toggleBypassAuctions() external isAuthorized {
        bypassAuctions = !bypassAuctions;
        emit ToggleBypassAuctions(bypassAuctions);
    }
    /*
    * @notify Switch between allowing exits when the system is underwater or blocking them
    */
    function toggleForcedExit() external isAuthorized {
        forcedExit = !forcedExit;
        emit ToggleForcedExit(forcedExit);
    }
    /*
    * @notify Modify an uint256 parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "exitDelay") {
          require(data <= MAX_DELAY, "ProtocolTokenLenderFirstResort/invalid-exit-delay");
          exitDelay = data;
        }
        else if (parameter == "minStakedTokensToKeep") {
          require(data > 0, "ProtocolTokenLenderFirstResort/null-min-staked-tokens");
          minStakedTokensToKeep = data;
        }
        else if (parameter == "tokensToAuction") {
          require(data > 0, "ProtocolTokenLenderFirstResort/invalid-tokens-to-auction");
          tokensToAuction = data;
        }
        else if (parameter == "systemCoinsToRequest") {
          require(data > 0, "ProtocolTokenLenderFirstResort/invalid-sys-coins-to-request");
          systemCoinsToRequest = data;
        }
        else if (parameter == "maxConcurrentAuctions") {
          require(data > 1, "ProtocolTokenLenderFirstResort/invalid-max-concurrent-auctions");
          maxConcurrentAuctions = data;
        }
        else revert("ProtocolTokenLenderFirstResort/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Modify an address parameter
    * @param parameter The name of the parameter to modify
    * @param data New value for the parameter
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "ProtocolTokenLenderFirstResort/null-data");

        if (parameter == "auctionHouse") {
          auctionHouse = AuctionHouseLike(data);
        }
        else if (parameter == "accountingEngine") {
          accountingEngine = AccountingEngineLike(data);
        }
        else revert("ProtocolTokenLenderFirstResort/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Getters ---
    /*
    * @notify Return the ancestor token balance for this contract
    */
    function depositedAncestor() public view returns (uint256) {
        return ancestor.balanceOf(address(this));
    }
    /*
    * @notify Returns how many ancestor tokens are offered for one descendant token
    */
    function ancestorPerDescendant() public view returns (uint256) {
        return descendant.totalSupply() == 0 ? WAD : wdivide(depositedAncestor(), descendant.totalSupply());
    }
    /*
    * @notify Returns how many descendant tokens are offered for one ancestor token
    */
    function descendantPerAncestor() public view returns (uint256) {
        return descendant.totalSupply() == 0 ? WAD : wdivide(descendant.totalSupply(), depositedAncestor());
    }
    /*
    * @notify Given a custom amount of ancestor tokens, it returns the corresponding amount of descendant tokens to mint when someone joins
    * @param wad The amount of ancestor tokens to compute the descendant tokens for
    */
    function joinPrice(uint256 wad) public view returns (uint256) {
        return wmultiply(wad, descendantPerAncestor());
    }
    /*
    * @notify Given a custom amount of descendant tokens, it returns the corresponding amount of ancestor tokens to send when someone exits
    * @param wad The amount of descendant tokens to compute the ancestor tokens for
    */
    function exitPrice(uint256 wad) public view returns (uint256) {
        return wmultiply(wad, ancestorPerDescendant());
    }

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
    * @notice Returns whether the pool can auction ancestor tokens
    */
    function canAuctionTokens() public view returns (bool) {
        return both(
          both(protocolUnderwater(), addition(minStakedTokensToKeep, tokensToAuction) <= depositedAncestor()),
          auctionHouse.activeStakedTokenAuctions() < maxConcurrentAuctions
        );
    }

    /*
    * @notice Returns whether the system can mint new ancestor tokens
    */
    function canPrintProtocolTokens() public view returns (bool) {
        return both(
          !canAuctionTokens(),
          either(auctionHouse.activeStakedTokenAuctions() == 0, bypassAuctions)
        );
    }

    // --- Core Logic ---
    /*
    * @notify Create a new auction that sells ancestor tokens in exchange for system coins
    */
    function auctionAncestorTokens() external nonReentrant {
        require(canAuctionTokens(), "ProtocolTokenLenderFirstResort/cannot-auction-tokens");

        ancestor.approve(address(auctionHouse), tokensToAuction);
        auctionHouse.startAuction(tokensToAuction, systemCoinsToRequest);

        emit AuctionAncestorTokens(address(auctionHouse), tokensToAuction, systemCoinsToRequest);
    }

    /*
    * @notify Join ancestor tokens in exchange for descendant tokens
    * @param wad The amount of ancestor tokens to join
    */
    function join(uint256 wad) public {
        require(both(canJoin, !protocolUnderwater()), "ProtocolTokenLenderFirstResort/join-not-allowed");
        require(wad > 0, "ProtocolTokenLenderFirstResort/null-ancestor-to-join");

        uint256 price = joinPrice(wad);
        require(price > 0, "ProtocolTokenLenderFirstResort/null-join-price");

        require(ancestor.transferFrom(msg.sender, address(this), wad), "ProtocolTokenLenderFirstResort/could-not-transfer-ancestor");
        descendant.mint(msg.sender, price);

        emit Join(msg.sender, price, wad);
    }
    /*
    * @notice Request a new exit window during which you can burn descendant tokens in exchange for ancestor tokens
    * @param wad The amount of tokens to exit
    */
    function requestExit(uint wad) public {
        require(wad > 0, "ProtocolTokenLenderFirstResort/null-amount-to-exit");
        require(now > exitRequests[msg.sender].deadline, "ProtocolTokenLenderFirstResort/ongoing-request");
        exitRequests[msg.sender].deadline   = addition(now, exitDelay);
        exitRequests[msg.sender].lockedAmount  = addition(exitRequests[msg.sender].lockedAmount, wad);

        emit RequestExit(msg.sender, exitRequests[msg.sender].deadline, wad);
    }
    /*
    * @notify Burn descendant tokens in exchange for getting ancestor tokens from this contract
    */
    function exit() public nonReentrant {
        require(both(now >= exitRequests[msg.sender].deadline, exitRequests[msg.sender].lockedAmount > 0), "ProtocolTokenLenderFirstResort/wait-more");
        require(either(!protocolUnderwater(), forcedExit), "ProtocolTokenLenderFirstResort/exit-not-allowed");

        uint256 price = exitPrice(exitRequests[msg.sender].lockedAmount);

        require(ancestor.transfer(msg.sender, price), "ProtocolTokenLenderFirstResort/could-not-transfer-ancestor");
        descendant.burn(msg.sender, exitRequests[msg.sender].lockedAmount);
        emit Exit(msg.sender, price, exitRequests[msg.sender].lockedAmount);
        delete exitRequests[msg.sender];
    }
}