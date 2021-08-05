pragma solidity 0.5.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./I_Token.sol";
import "./I_Curve.sol";

contract Curve is Ownable, I_Curve {
    using SafeMath for uint256;
    // The instance of the token this curve controls (has mint rights to)
    I_Token internal bzz_;
    // The instance of the collateral token that is used to buy and sell tokens
    IERC20 internal dai_;
    // Stores if the curve has been initialised
    bool internal init_;
    // The active state of the curve (false after emergency shutdown)
    bool internal active_;
    // Mutex guard for state modifying functions
    uint256 private status_;
    // States for the guard 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    // Emitted when tokens are minted
    event mintTokens(
        address indexed buyer,      // The address of the buyer
        uint256 amount,             // The amount of bonded tokens to mint
        uint256 pricePaid,          // The price in collateral tokens 
        uint256 maxSpend            // The max amount of collateral to spend
    );
    // Emitted when tokens are minted
    event mintTokensTo(
        address indexed buyer,      // The address of the buyer
        address indexed receiver,   // The address of the receiver of the tokens
        uint256 amount,             // The amount of bonded tokens to mint
        uint256 pricePaid,          // The price in collateral tokens 
        uint256 maxSpend            // The max amount of collateral to spend
    );
    // Emitted when tokens are burnt
    event burnTokens(
        address indexed seller,     // The address of the seller
        uint256 amount,             // The amount of bonded tokens to sell
        uint256 rewardReceived,     // The collateral tokens received
        uint256 minReward           // The min collateral reward for tokens
    );
    // Emitted when the curve is permanently shut down
    event shutDownOccurred(address indexed owner);

    // -------------------------------------------------------------------------
    // Modifiers
    // -------------------------------------------------------------------------

    /**
      * @notice Requires the curve to be initialised and active.
      */
    modifier isActive() {
        require(active_ && init_, "Curve inactive");
        _;
    }

    /**
      * @notice Protects against re-entrancy attacks
      */
    modifier mutex() {
        require(status_ != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        status_ = _ENTERED;
        // Function executes
        _;
        // Status set to not entered
        status_ = _NOT_ENTERED;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    constructor(address _bondedToken, address _collateralToken) public Ownable() {
        bzz_ = I_Token(_bondedToken);
        dai_ = IERC20(_collateralToken);
        status_ = _NOT_ENTERED;
    }

    // -------------------------------------------------------------------------
    // View functions
    // -------------------------------------------------------------------------

    /**
     * @notice This function is only callable after the curve contract has been
     *         initialized.
     * @param  _amount The amount of tokens a user wants to buy
     * @return uint256 The cost to buy the _amount of tokens in the collateral
     *         currency (see collateral token).
     */
    function buyPrice(uint256 _amount)
        public
        view
        isActive()
        returns (uint256 collateralRequired)
    {
        collateralRequired = _mint(_amount, bzz_.totalSupply());
        return collateralRequired;
    }

    /**
     * @notice This function is only callable after the curve contract has been
     *         initialized.
     * @param  _amount The amount of tokens a user wants to sell
     * @return collateralReward The reward for selling the _amount of tokens in the
     *         collateral currency (see collateral token).
     */
    function sellReward(uint256 _amount)
        public
        view
        isActive()
        returns (uint256 collateralReward)
    {
        (collateralReward, ) = _withdraw(_amount, bzz_.totalSupply());
        return collateralReward;
    }

    /**
      * @return If the curve is both active and initialised.
      */
    function isCurveActive() public view returns (bool) {
        if (active_ && init_) {
            return true;
        }
        return false;
    }

    /**
      * @param  _initialSupply The expected initial supply the bonded token
      *         will have.
      * @return The required collateral amount (DAI) to initialise the curve.
      */
    function requiredCollateral(uint256 _initialSupply)
        public
        view
        returns (uint256)
    {
        return _initializeCurve(_initialSupply);
    }

    /**
      * @return The address of the bonded token (BZZ).
      */
    function bondedToken() external view returns (address) {
        return address(bzz_);
    }

    /**
      * @return The address of the collateral token (DAI)
      */
    function collateralToken() external view returns (address) {
        return address(dai_);
    }

    // -------------------------------------------------------------------------
    // State modifying functions
    // -------------------------------------------------------------------------

    /**
     * @notice This function initializes the curve contract, and ensure the
     *         curve has the required permissions on the token contract needed
     *         to function.
     */
    function init() external {
        // Checks the curve has not already been initialized
        require(!init_, "Curve is init");
        // Checks the curve has the correct permissions on the given token
        require(bzz_.isMinter(address(this)), "Curve is not minter");
        // Gets the total supply of the token
        uint256 initialSupply = bzz_.totalSupply();
        // The curve requires that the initial supply is at least the expected
        // open market supply
        require(
            initialSupply >= _MARKET_OPENING_SUPPLY,
            "Curve equation requires pre-mint"
        );
        // Gets the price for the current supply
        uint256 price = _initializeCurve(initialSupply);
        // Requires the transfer for the collateral needed to back fill for the
        // minted supply
        require(
            dai_.transferFrom(msg.sender, address(this), price),
            "Failed to collateralized the curve"
        );
        // Sets the Curve to being active and initialised
        active_ = true;
        init_ = true;
    }

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to buy.
      * @param  _maxCollateralSpend The max amount of collateral (DAI) the user is
      *         willing to spend in order to buy the _amount of tokens.
      * @return The status of the mint. Note that should the total cost of the
      *         purchase exceed the _maxCollateralSpend the transaction will revert.
      */
    function mint(
        uint256 _amount, 
        uint256 _maxCollateralSpend
    )
        external
        isActive()
        mutex()
        returns (bool success)
    {
        // Gets the price for the amount of tokens
        uint256 price = _commonMint(_amount, _maxCollateralSpend, msg.sender);
        // Emitting event with all important info
        emit mintTokens(
            msg.sender, 
            _amount, 
            price, 
            _maxCollateralSpend
        );
        // Returning that the mint executed successfully
        return true;
    }

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to buy.
      * @param  _maxCollateralSpend The max amount of collateral (DAI) the user is
      *         willing to spend in order to buy the _amount of tokens.
      * @param  _to The address to send the tokens to.
      * @return The status of the mint. Note that should the total cost of the
      *         purchase exceed the _maxCollateralSpend the transaction will revert.
      */
    function mintTo(
        uint256 _amount, 
        uint256 _maxCollateralSpend, 
        address _to
    )
        external
        isActive()
        mutex()
        returns (bool success)
    {
        // Gets the price for the amount of tokens
        uint256 price =  _commonMint(_amount, _maxCollateralSpend, _to);
        // Emitting event with all important info
        emit mintTokensTo(
            msg.sender,
            _to, 
            _amount, 
            price, 
            _maxCollateralSpend
        );
        // Returning that the mint executed successfully
        return true;
    }

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to sell.
      * @param  _minCollateralReward The min amount of collateral (DAI) the user is
      *         willing to receive for their tokens.
      * @return The status of the burn. Note that should the total reward of the
      *         burn be below the _minCollateralReward the transaction will revert.
      */
    function redeem(uint256 _amount, uint256 _minCollateralReward)
        external
        isActive()
        mutex()
        returns (bool success)
    {
        // Gets the reward for the amount of tokens
        uint256 reward = sellReward(_amount);
        // Checks the reward has not slipped below the min amount the user
        // wishes to receive.
        require(reward >= _minCollateralReward, "Reward under min sell");
        // Burns the number of tokens (fails - no bool return)
        bzz_.burnFrom(msg.sender, _amount);
        // Transfers the reward from the curve to the collateral token
        require(
            dai_.transfer(msg.sender, reward),
            "Transferring collateral failed"
        );
        // Emitting event with all important info
        emit burnTokens(
            msg.sender, 
            _amount, 
            reward, 
            _minCollateralReward
        );
        // Returning that the burn executed successfully
        return true;
    }

    /**
      * @notice Shuts down the curve, disabling buying, selling and both price
      *         functions. Can only be called by the owner. Will renounce the
      *         minter role on the bonded token.
      */
    function shutDown() external onlyOwner() {
        // Removes the curve as a minter on the token
        bzz_.renounceMinter();
        // Irreversibly shuts down the curve
        active_ = false;
        // Emitting address of owner who shut down curve permanently
        emit shutDownOccurred(msg.sender);
    }

    // -------------------------------------------------------------------------
    // Internal functions
    // -------------------------------------------------------------------------

    /**
      * @param  _amount The amount of tokens (BZZ) the user wants to buy.
      * @param  _maxCollateralSpend The max amount of collateral (DAI) the user is
      *         willing to spend in order to buy the _amount of tokens.
      * @param  _to The address to send the tokens to.
      * @return uint256 The price the user has paid for buying the _amount of 
      *         BUZZ tokens. 
      */
    function _commonMint(
        uint256 _amount,
        uint256 _maxCollateralSpend,
        address _to
    )
        internal
        returns(uint256)
    {
        // Gets the price for the amount of tokens
        uint256 price = buyPrice(_amount);
        // Checks the price has not risen above the max amount the user wishes
        // to spend.
        require(price <= _maxCollateralSpend, "Price exceeds max spend");
        // Transfers the price of tokens in the collateral token to the curve
        require(
            dai_.transferFrom(msg.sender, address(this), price),
            "Transferring collateral failed"
        );
        // Mints the user their tokens
        require(bzz_.mint(_to, _amount), "Minting tokens failed");
        // Returns the price the user will pay for buy
        return price;
    }

    // -------------------------------------------------------------------------
    // Curve mathematical functions

    uint256 internal constant _BZZ_SCALE = 1e16;
    uint256 internal constant _N = 5;
    uint256 internal constant _MARKET_OPENING_SUPPLY = 62500000 * _BZZ_SCALE;
    // Equation for curve: 

    /**
     * @param   x The supply to calculate at.
     * @return  x^32/_MARKET_OPENING_SUPPLY^5
     * @dev     Calculates the 32 power of `x` (`x` squared 5 times) times a 
     *          constant. Each time it squares the function it divides by the 
     *          `_MARKET_OPENING_SUPPLY` so when `x` = `_MARKET_OPENING_SUPPLY` 
     *          it doesn't change `x`. 
     *
     *          `c*x^32` | `c` is chosen in such a way that 
     *          `_MARKET_OPENING_SUPPLY` is the fixed point of the helper 
     *          function.
     *
     *          The division by `_MARKET_OPENING_SUPPLY` also helps avoid an 
     *          overflow.
     *
     *          The `_helper` function is separate to the `_primitiveFunction` 
     *          as we modify `x`. 
     */
    function _helper(uint256 x) internal pure returns (uint256) {
        for (uint256 index = 1; index <= _N; index++) {
            x = (x.mul(x)).div(_MARKET_OPENING_SUPPLY);
        }
        return x;
    }

    /**
     * @param   s The supply point being calculated for. 
     * @return  The amount of DAI required for the requested amount of BZZ (s). 
     * @dev     `s` is being added because it is the linear term in the 
     *          polynomial (this ensures no free BUZZ tokens).
     *
     *          primitive function equation: s + c*s^32.
     * 
     *          See the helper function for the definition of `c`.
     *
     *          Converts from something measured in BZZ (1e16) to dai atomic 
     *          units 1e18.
     */
    function _primitiveFunction(uint256 s) internal pure returns (uint256) {
        return s.add(_helper(s));
    }

    /**
     * @param  _supply The number of tokens that exist.
     * @return uint256 The price for the next token up the curve.
     */
    function _spotPrice(uint256 _supply) internal pure returns (uint256) {
        return (_primitiveFunction(_supply.add(1)).sub(_primitiveFunction(_supply)));
    }

    /**
     * @param  _amount The amount of tokens to be minted
     * @param  _currentSupply The current supply of tokens
     * @return uint256 The cost for the tokens
     * @return uint256 The price being paid per token
     */
    function _mint(uint256 _amount, uint256 _currentSupply)
        internal
        pure
        returns (uint256)
    {
        uint256 deltaR = _primitiveFunction(_currentSupply.add(_amount)).sub(
            _primitiveFunction(_currentSupply));
        return deltaR;
    }

    /**
     * @param  _amount The amount of tokens to be sold
     * @param  _currentSupply The current supply of tokens
     * @return uint256 The reward for the tokens
     * @return uint256 The price being received per token
     */
    function _withdraw(uint256 _amount, uint256 _currentSupply)
        internal
        pure
        returns (uint256, uint256)
    {
        assert(_currentSupply - _amount > 0);
        uint256 deltaR = _primitiveFunction(_currentSupply).sub(
            _primitiveFunction(_currentSupply.sub(_amount)));
        uint256 realized_price = deltaR.div(_amount);
        return (deltaR, realized_price);
    }

    /**
     * @param  _initial_supply The supply the curve is going to start with.
     * @return initial_reserve How much collateral is needed to collateralized
     *         the bonding curve.
     * @return price The price being paid per token (averaged).
     */
    function _initializeCurve(uint256 _initial_supply)
        internal
        pure
        returns (uint256 price)
    {
        price = _mint(_initial_supply, 0);
        return price;
    }
}