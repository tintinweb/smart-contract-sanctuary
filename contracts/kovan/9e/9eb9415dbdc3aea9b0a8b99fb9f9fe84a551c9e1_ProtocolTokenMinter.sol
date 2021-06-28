/**
 *Submitted for verification at Etherscan.io on 2021-06-28
*/

pragma solidity 0.6.7;

contract GebMath {
    uint256 public constant RAY = 10 ** 27;
    uint256 public constant WAD = 10 ** 18;

    function ray(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 9);
    }
    function rad(uint x) public pure returns (uint z) {
        z = multiply(x, 10 ** 27);
    }
    function minimum(uint x, uint y) public pure returns (uint z) {
        z = (x <= y) ? x : y;
    }
    function addition(uint x, uint y) public pure returns (uint z) {
        z = x + y;
        require(z >= x, "uint-uint-add-overflow");
    }
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }
    function rmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / RAY;
    }
    function rdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, RAY) / y;
    }
    function wdivide(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, WAD) / y;
    }
    function wmultiply(uint x, uint y) public pure returns (uint z) {
        z = multiply(x, y) / WAD;
    }
    function rpower(uint x, uint n, uint base) public pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }
}

abstract contract DSTokenLike {
    function totalSupply() virtual public view returns (uint256);
    function mint(address, uint256) virtual public;
    function transfer(address, uint256) virtual public;
}

contract ProtocolTokenMinter is GebMath {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "ProtocolTokenMinter/account-not-authorized");
        _;
    }

    // --- Variables ---
    // Current amount to mint per week
    uint256 public amountToMintPerWeek;                                   // wad
    // Last timestamp when the contract accrued inflation
    uint256 public lastWeeklyMint;                                        // timestamp
    // Last week number when the contract accrued inflation
    uint256 public lastTaggedWeek;
    // Decay for the weekly amount to mint
    uint256 public weeklyMintDecay;                                       // wad
    // Timestamp when minting starts
    uint256 public mintStartTime;
    // Whether minting is currently allowed
    uint256 public mintAllowed = 1;

    uint256 public constant WEEK                     = 1 weeks;
    uint256 public constant WEEKS_IN_YEAR            = 52;
    uint256 public constant INITIAL_INFLATION_PERIOD = WEEKS_IN_YEAR * 3; // 3 years
    uint256 public constant TERMINAL_INFLATION       = 1.02E18;           // 2% compounded weekly

    // Address that receives minted tokens
    address     public mintReceiver;

    // The token being minted
    DSTokenLike public protocolToken;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Mint(uint256 weeklyAmount);
    event ModifyParameters(bytes32 parameter, address data);
    event ModifyParameters(bytes32 parameter, uint256 data);

    constructor(
      address mintReceiver_,
      address protocolToken_,
      uint256 mintStartTime_,
      uint256 amountToMintPerWeek_,
      uint256 weeklyMintDecay_
    ) public {
      require(mintReceiver_ != address(0), "ProtocolTokenMinter/null-mint-receiver");
      require(protocolToken_ != address(0), "ProtocolTokenMinter/null-prot-token");

      require(mintStartTime_ > now, "ProtocolTokenMinter/invalid-start-time");
      require(amountToMintPerWeek_ > 0, "ProtocolTokenMinter/null-amount-to-mint");
      require(weeklyMintDecay_ < WAD, "ProtocolTokenMinter/invalid-mint-decay");

      authorizedAccounts[msg.sender] = 1;

      mintReceiver        = mintReceiver_;
      protocolToken       = DSTokenLike(protocolToken_);
      mintStartTime       = mintStartTime_;
      amountToMintPerWeek = amountToMintPerWeek_;
      weeklyMintDecay     = weeklyMintDecay_;

      emit AddAuthorization(msg.sender);
    }

    // --- Administration ---
    /*
    * @notify Change the mintReceiver
    * @param parameter The parameter name
    * @param data The new address for the receiver
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "mintReceiver") {
          mintReceiver = data;
        }
        else revert("ProtocolTokenMinter/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }
    /*
    * @notify Change mintAllowed
    * @param parameter The parameter name
    * @param data The new value for mintAllowed
    */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "mintAllowed") {
          mintAllowed = data;
        }
        else revert("ProtocolTokenMinter/modify-unrecognized-param");
        emit ModifyParameters(parameter, data);
    }

    // --- Core Logic ---
    /*
    * @notice Mint tokens for this contract
    */
    function mint() external {
      require(now > mintStartTime, "ProtocolTokenMinter/too-early");
      require(mintAllowed == 1, "ProtocolTokenMinter/mint-not-allowed");
      require(addition(lastWeeklyMint, WEEK) <= now, "ProtocolTokenMinter/week-not-elapsed");

      uint256 weeklyAmount;
      lastWeeklyMint = (lastWeeklyMint == 0) ? now : addition(lastWeeklyMint, WEEK);

      if (lastTaggedWeek < INITIAL_INFLATION_PERIOD) {
        weeklyAmount        = amountToMintPerWeek;
        amountToMintPerWeek = multiply(amountToMintPerWeek, weeklyMintDecay) / WAD;
      } else {
        weeklyAmount = wdivide(protocolToken.totalSupply(), TERMINAL_INFLATION) / WEEKS_IN_YEAR;
      }

      lastTaggedWeek = addition(lastTaggedWeek, 1);

      protocolToken.mint(address(this), weeklyAmount);

      emit Mint(weeklyAmount);
    }

    /*
    * @notice Transfer minted tokens
    * @param amount The amount to transfer
    */
    function transferMintedAmount(uint256 amount) external isAuthorized {
      protocolToken.transfer(mintReceiver, amount);
    }
}