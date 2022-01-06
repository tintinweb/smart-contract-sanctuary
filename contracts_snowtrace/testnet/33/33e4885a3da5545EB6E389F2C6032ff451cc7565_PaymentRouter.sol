// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dependencies/Context.sol";
import "../Dependencies/IERC20.sol";
import "./IPaymentRouter.sol";

contract PaymentRouter is Context {
  // ****PAYMENT ROUTES****

  // Fires when a new payment route is created
  event RouteCreated(address indexed creator, bytes32 routeID, address[] recipients, uint16[] commissions);

  // Fires when a route creator changes route tax
  event RouteTaxChanged(bytes32 routeID, uint16 newTax);

  // Fires when a route tax bounds is changed
  event RouteTaxBoundsChanged(uint16 minTax, uint16 maxTax);

  // Fires when a route has processed a push-transfer operation
  event TransferReceipt(
    address indexed sender,
    bytes32 routeID,
    address tokenContract,
    uint256 amount,
    uint256 tax,
    uint256 timeStamp
  );

  // Fires when a push-transfer operation fails
  event TransferFailed(
    address indexed sender,
    bytes32 routeID,
    uint256 payment,
    uint256 timestamp,
    address recipient
  );

  // Fires when tokens are deposited into a payment route for holding
  event TokensHeld(bytes32 routeID, address tokenAddress, uint256 amount);

  // Fires when tokens are collected from holding by a recipient
  event TokensCollected(address indexed recipient, address tokenAddress, uint256 amount);

  // Maps available payment token balance per recipient for pull function
  // recipient address => token address => balance available to collect
  mapping(address => mapping(address => uint256)) public tokenBalanceToCollect;

  // Mapping for route ID to route data
  // route ID => payment route
  mapping(bytes32 => PaymentRoute) public paymentRouteID;

  // Mapping of all routeIDs created by a route creator address
  // creator's address => routeIDs
  mapping(address => bytes32[]) public creatorRoutes;

  // Mapping that tracks if an address is a developer
  // ****REMOVE BEFORE DEPLOYMENT****
  mapping(address => bool) public isDev;

  // Struct that defines a new PaymentRoute
  struct PaymentRoute {
    address routeCreator; // Address of payment route creator
    address[] recipients; // Recipients in this payment route
    uint16[] commissions; // Commissions for each recipient--in fractions of 10000
    uint16 routeTax; // Tax paid by this route
    bool isActive; // Is route currently active?
  }

  // Min and max tax rates that routes must meet
  uint16 public minTax;
  uint16 public maxTax;

  // Address of treasury contract where route taxes will be sent
  address public treasuryAddress;

  // For testing, just use accounts[0] (Truffle) for treasury and developers
  // ****LINK TO TREASURY CONTRACT, GRAB DEVELOPER LIST FROM THERE****
  constructor(
    address _treasuryAddress,
    address[] memory _developers,
    uint16 _minTax,
    uint16 _maxTax
  ) {
    treasuryAddress = _treasuryAddress;
    for (uint256 i = 0; i < _developers.length; i++) {
      isDev[_developers[i]] = true;
    }
    minTax = _minTax;
    maxTax = _maxTax;
    emit RouteTaxBoundsChanged(_minTax, _maxTax);
  }

  /**
   * @dev Modifier to restrict access to the creator of paymentRouteID[_routeID]
   */
  modifier onlyCreator(bytes32 _routeID) {
    require(paymentRouteID[_routeID].routeCreator == msg.sender, "Unauthorized, only creator");
    _;
  }

  // ****REMOVE WHEN TREASURY CONTRACT READY, CHANGE MODIFIER TO FUNCTION CALL TO CHECK DEV STATUS****
  modifier onlyDev() {
    require(isDev[msg.sender], "Only developers can access this function");
    _;
  }

  /**
   * @dev Checks that need to be run when a payment route is created..
   *
   * @dev Requirements to pass this modifier:
   * - _recipients and _commissions arrays must be same length
   * - No recipient is address(0)
   * - Commissions are greater than 0% but less than 100%
   * - All commissions add up to exactly 100%
   */
  modifier newRouteChecks(address[] memory _recipients, uint16[] memory _commissions) {
    // Check for front-end errors
    require(_recipients.length == _commissions.length, "Array lengths must match");
    require(_recipients.length <= 256, "Max recipients exceeded");

    // Iterate through all entries submitted and check for upload errors
    uint16 totalCommissions;
    for (uint8 i = 0; i < _recipients.length; i++) {
      totalCommissions += _commissions[i];
      require(totalCommissions <= 10000, "Commissions cannot add up to more than 100%");
      require(_recipients[i] != address(0), "Cannot burn tokens with payment router");
      require(_commissions[i] != 0, "Cannot assign 0% commission");
      require(_commissions[i] <= 10000, "Cannot assign more than 100% commission");
    }
    require(totalCommissions == 10000, "Commissions don't add up to 100%");
    _;
  }

  /**
   * @dev Checks that the routeTax conforms to required bounds. If routeTax is less
   * than minTax or greater than maxTax then routeTax is updated to minTax or maxTax,
   * depending on which one is triggered by the modifier. This modifier is used by
   * _pushTokens() and _holdTokens() when a payment is made to auto-adjust the
   * routeTax if the developers change it.
   *
   * @dev The only situation this does not cover is when maxTax is raised or minTax is
   * reduced.
   */
  modifier checkRouteTax(bytes32 _routeID) {
    PaymentRoute memory route = paymentRouteID[_routeID];

    // If routeTax doesn't meet minTax/maxTax requirements, then it is updated
    if (route.routeTax < minTax) {
      route.routeTax = minTax;
    }
    // Only sponsor items pay maxTax
    if (route.routeTax > maxTax) {
      route.routeTax = maxTax;
    }
    _;
  }

  /**
   * @notice External function to transfer tokens from msg.sender to all recipients[].
   *
   * @dev The size of each payment is determined by commissions[i]/10000, which added up
   * will always equal 10000. The first minTax units are transferred to the treasury. This
   * function is a push design that will incur higher gas costs on the user, but
   * is more convenient for the creators.
   *
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being transferred
   * @param _senderAddress Wallet address of token sender
   * @param _amount Amount of tokens being routed
   *
   * @dev If any of the transfers should fail for whatever reason, then the transaction should
   * *not* revert. Instead, it will run _storeFailedTransfer which holds on to the recipient's
   * tokens until they are collected. This also throws the TransferReceipt event.
   */
  function pushTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) public checkRouteTax(_routeID) returns (bool) {
    require(paymentRouteID[_routeID].isActive, "Error: Route inactive");

    // Store PaymentRoute struct into local variable
    PaymentRoute memory route = paymentRouteID[_routeID];
    // Transfer full _amount from buyer to contract
    IERC20(_tokenAddress).transferFrom(_senderAddress, address(this), _amount);

    // Transfer route tax first
    uint256 tax = (_amount * route.routeTax) / 10000;
    uint256 totalAmount = _amount - tax; // Total amount to be transferred after tax
    IERC20(_tokenAddress).transfer(treasuryAddress, tax);

    // Now transfer the commissions
    uint256 payment; // Individual recipient's payment

    // Transfer tokens from contract to route.recipients[i]:
    for (uint256 i = 0; i < route.commissions.length; i++) {
      payment = (totalAmount * route.commissions[i]) / 10000;
      // If transfer() fails:
      if (!IERC20(_tokenAddress).transfer(route.recipients[i], payment)) {
        // Emit failure event alerting recipient they have tokens to collect
        emit TransferFailed(_msgSender(), _routeID, payment, block.timestamp, route.recipients[i]);
        // Store tokens in contract for holding until recipient collects them
        tokenBalanceToCollect[_senderAddress][_tokenAddress] += payment;
        continue; // Continue to next recipient
      }
    }

    // Emit a TransferReceipt event to all recipients
    emit TransferReceipt(_senderAddress, _routeID, _tokenAddress, totalAmount, tax, block.timestamp);
    return true;
  }

  /**
   * @notice External function that deposits and sorts tokens for collection, tokens are
   * divided up by each recipient's commission rate
   *
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being deposited for collection
   * @param _senderAddress Address of token sender
   * @param _amount Amount of tokens held in escrow by payment route
   * @return success boolean
   */
  function holdTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external checkRouteTax(_routeID) returns (bool) {
    PaymentRoute memory route = paymentRouteID[_routeID];
    uint256 payment; // Each recipient's payment

    // Calculate platform tax and taxedAmount
    uint256 tax = (_amount * route.routeTax) / 10000;
    uint256 taxedAmount = _amount - tax;

    // Calculate each recipient's payment, add to token balance mapping
    // We + 1 to tokenBalanceToCollect as part of a gas-saving design that saves
    // gas on never allowing the token balance mapping to reach 0, while also
    // not counting against the user's actual token balance.
    for (uint256 i = 0; i < route.commissions.length; i++) {
      if (tokenBalanceToCollect[route.recipients[i]][_tokenAddress] == 0) {
        tokenBalanceToCollect[route.recipients[i]][_tokenAddress] = 1;
      }
      payment = ((taxedAmount * route.commissions[i]) / 10000);
      tokenBalanceToCollect[route.recipients[i]][_tokenAddress] += payment;
    }

    // Transfer tokens from senderAddress to this contract
    IERC20(_tokenAddress).transferFrom(_senderAddress, address(this), _amount);

    // Transfer treasury's commission from this contract to treasuryAddress
    IERC20(_tokenAddress).transfer(treasuryAddress, tax);

    // Fire event alerting recipients they have tokens to collect
    emit TokensHeld(_routeID, _tokenAddress, _amount);
    return true;
  }

  /**
   * @notice Collects all earnings stored in PaymentRouter
   *
   * @param _tokenAddress Contract address of payment token to be collected
   * @return success boolean
   */
  function pullTokens(address _tokenAddress) external returns (bool) {
    // Store recipient's balance as their payment
    uint256 payment = tokenBalanceToCollect[_msgSender()][_tokenAddress] - 1;
    require(payment > 0, "No payment to collect");

    // Erase recipient's balance
    tokenBalanceToCollect[_msgSender()][_tokenAddress] = 1; // Use 1 for 0 to save on gas

    // Call token contract and transfer balance from this contract to recipient
    require(IERC20(_tokenAddress).transfer(msg.sender, payment), "Transfer failed");

    // Emit a TokensCollected event as a recipient's receipt
    emit TokensCollected(msg.sender, _tokenAddress, payment);
    return true;
  }

  /**
   * @notice Opens a new payment route
   *
   * @param _recipients Array of all recipient addresses for this payment route
   * @param _commissions Array of all recipients' commissions--in percentages with two decimals
   * @return routeID Hash of the created PaymentRoute
   */
  function openPaymentRoute(
    address[] memory _recipients,
    uint16[] memory _commissions,
    uint16 _routeTax
  ) external newRouteChecks(_recipients, _commissions) returns (bytes32 routeID) {
    // Creates routeID from hashing contents of new PaymentRoute
    routeID = getPaymentRouteID(_msgSender(), _recipients, _commissions);

    // Maps the routeID to the new PaymentRoute
    paymentRouteID[routeID] = PaymentRoute(msg.sender, _recipients, _commissions, _routeTax, true);

    // Maps the routeID to the address that created it, and pushes to creator's routes array
    creatorRoutes[_msgSender()].push(routeID);

    emit RouteCreated(msg.sender, routeID, _recipients, _commissions);
  }

  event RouteToggled(bytes32 indexed routeID, bool isActive, uint256 timestamp);

  /**
   * @dev Toggles a payment route with ID _routeID
   */
  function togglePaymentRoute(bytes32 _routeID) external onlyCreator(_routeID) {
    paymentRouteID[_routeID].isActive
      ? paymentRouteID[_routeID].isActive = false
      : paymentRouteID[_routeID].isActive = true;

    // If isActive == true, then route was re-opened, if isActive == false, then route was closed
    emit RouteToggled(_routeID, paymentRouteID[_routeID].isActive, block.timestamp);
  }

  /**
   * @notice Function for calculating the routeID of a payment route.
   *
   * @param _routeCreator Address of payment route's creator
   * @param _recipients Array of all commission recipients
   * @param _commissions Array of all commissions relative to _recipients
   * @return routeID Calculated routeID
   */
  function getPaymentRouteID(
    address _routeCreator,
    address[] memory _recipients,
    uint16[] memory _commissions
  ) public pure returns (bytes32 routeID) {
    routeID = keccak256(abi.encodePacked(_routeCreator, _recipients, _commissions));
  }

  /**
   * @notice Returns a list of the caller's created payment routes
   */
  function getMyPaymentRoutes() public view returns (bytes32[] memory) {
    return creatorRoutes[msg.sender];
  }

  /**
   * @notice Adjusts the tax applied to a payment route.
   * @dev Only a route creator should be allowed to change this, and the platform
   * should respond accordingly. In this way, route creators set their own platform
   * taxes, and we cater to those who pay us more.
   *
   * If a route creator chooses to pay a higher tax, then the platform's search algorithm will
   * place items tied to that route higher on the search results.
   *
   * idea If a route creator chooses maxTax then they become a "sponsor" of the platform
   * and receive promotional boosts for the items tied to the route.
   */
  function adjustRouteTax(bytes32 _routeID, uint16 _newTax) external onlyCreator(_routeID) returns (bool) {
    require(_newTax >= minTax, "Minimum tax not met");
    require(_newTax <= maxTax, "Maximum tax exceeded");

    paymentRouteID[_routeID].routeTax = _newTax;

    // Emit event so all recipients can be notified of the routeTax change
    emit RouteTaxChanged(_routeID, _newTax);
    return true;
  }

  /**
   * @dev This function allows us to set the min/max tax bounds that can be set by a creator
   */
  function adjustTaxBounds(uint16 _minTax, uint16 _maxTax) external onlyDev {
    require(_minTax >= 0, "Minimum tax < 0.00%");
    require(_maxTax <= 10000, "Maximum tax > 100.00%");

    minTax = _minTax;
    maxTax = _maxTax;

    emit RouteTaxBoundsChanged(_minTax, _maxTax);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPaymentRouter {
  // Fires when a new payment route is created
  event RouteCreated(address indexed creator, bytes32 routeID, address[] recipients, uint16[] commissions);

  // Fires when a route creator changes route tax
  event RouteTaxChanged(bytes32 routeID, uint16 newTax);

  // Fires when tokens are deposited into a payment route for holding
  event TokensHeld(bytes32 routeID, address tokenAddress, uint256 amount);

  // Fires when tokens are collected from holding by a recipient
  event TokensCollected(address indexed recipient, address tokenAddress, uint256 amount);

  // Fires when route is actived or deactivated
  event RouteToggled(bytes32 indexed routeID, bool isActive, uint256 timestamp);

  // Fires when a route has processed a push-transfer operation
  event TransferReceipt(
    address indexed sender,
    bytes32 routeID,
    address tokenContract,
    uint256 amount,
    uint256 tax,
    uint256 timeStamp
  );

  // Fires when a push-transfer operation fails
  event TransferFailed(
    address indexed sender,
    bytes32 routeID,
    uint256 payment,
    uint256 timestamp,
    address recipient
  );

  /**
   * @notice Returns the properties of a PaymentRoute struct for _routeID
   */
  function paymentRouteID(bytes32 _routeID)
    external
    view
    returns (
      address,
      uint16,
      bool
    );

  /**
   * @notice Returns a balance of tokens/stablecoins ready for collection
   *
   * @param _recipientAddress Address of recipient who can collect tokens
   * @param _tokenContract Contract address of tokens/stablecoins to be collected
   */
  function tokenBalanceToCollect(address _recipientAddress, address _tokenContract)
    external
    view
    returns (uint256);

  /**
   * @notice Returns an array of all routeIDs created by an address
   * @param _creatorAddress Address of route creator
   */
  function creatorRoutes(address _creatorAddress) external view returns (bytes32[] memory);

  /**
   * @notice External function to transfer tokens from msg.sender to all recipients[].
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being transferred
   * @param _senderAddress Wallet address of token sender
   * @param _amount Amount of tokens being routed
   */
  function pushTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external returns (bool);

  /**
   * @notice External function that deposits and sorts tokens for collection, tokens are
   * divided up by each recipient's commission rate
   *
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being deposited for collection
   * @param _senderAddress Address of token sender
   * @param _amount Amount of tokens held in escrow by payment route
   * @return success boolean
   */
  function holdTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external returns (bool);

  /**
   * @notice Collects all earnings stored in PaymentRouter
   *
   * @param _tokenAddress Contract address of payment token to be collected
   * @return success boolean
   */
  function pullTokens(address _tokenAddress) external returns (bool);

  /**
   * @notice Opens a new payment route
   *
   * @param _recipients Array of all recipient addresses for this payment route
   * @param _commissions Array of all recipients' commissions--in percentages with two decimals
   * @return routeID Hash of the created PaymentRoute
   */
  function openPaymentRoute(
    address[] memory _recipients,
    uint16[] memory _commissions,
    uint16 _routeTax
  ) external returns (bytes32 routeID);
}