// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Dependencies/Context.sol";
import "../Dependencies/IERC20.sol";

/**
 * @dev This serves as a storage area for all mappings, events, modifiers, and functions
 * needed for access control. There are Pazari admins and there are route admins.
 * @dev Original route creators will *always* have admin privileges, even if they are
 * hacked and removed as admins they can still add themselves back on. There is no way
 * to remove a routeCreator mapping once created.
 */
contract AccessControlPR {
  // Maps Pazari-owned addresses to a bool
  mapping(address => bool) public isAdmin;
  // Maps each routeID's admin addresses to a bool
  mapping(bytes32 => mapping(address => bool)) public isRouteAdmin;
  // Maps each routeID to its creator address
  mapping(bytes32 => address) internal routeCreator;

  // Fires when Pazari admins are added/removed
  event AdminAdded(address indexed newAdmin, address indexed adminAuthorized, string memo, uint256 timestamp);
  event AdminRemoved(
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Fires when route admins are added/removed, returns _msgSender() for callerAdmin
  event RouteAdminAdded(
    bytes32 indexed routeID,
    address indexed newAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );
  event RouteAdminRemoved(
    bytes32 indexed routeID,
    address indexed oldAdmin,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  constructor(address[] memory _adminAddresses) {
    for (uint256 i = 0; i < _adminAddresses.length; i++) {
      isAdmin[_adminAddresses[i]] = true;
    }
  }

  /**
   * @notice Requires that both msg.sender and tx.origin be admins. This restricts all
   * calls to only Pazari-owned admin addresses, including wallets and contracts, and
   * eliminates phishing attacks.
   */
  modifier onlyAdmin() {
    require(isAdmin[msg.sender] && isAdmin[tx.origin], "Only Pazari-owned addresses");
    _;
  }

  /**
   * @notice Requires caller is using a Pazari-owned contract, or is a Pazari admin address.
   * @dev Only developer wallets can directly call functions with this modifier, everyone else
   * must use a Pazari admin smart contract.
   */
  modifier onlyPazariContract() {
    // Permit developers to directly call via private wallet
    if (isAdmin[msg.sender] && isAdmin[tx.origin]) {
      _;
    }
    // Everyone else must use a Pazari admin contract, no private wallets
    else {
      require(tx.origin != msg.sender && isAdmin[msg.sender], "Only Pazari-owned contracts");
      _;
    }
  }

  /**
   * @notice Requires caller be the original route creator or has isRouteAdmin
   * @dev Route creators will always be able to pass this check, even if they are
   * removed as isAdmin. This ensures route creators will always be in control of
   * their payment routes, even if they are hacked.
   */
  modifier onlyRouteAdmin(bytes32 _routeID) {
    require(
      routeCreator[_routeID] == _msgSender() || isRouteAdmin[_routeID][_msgSender()] || isAdmin[_msgSender()],
      "Caller is neither admin nor route creator"
    );
    _;
  }

  /**
   * @notice Returns tx.origin for any Pazari-owned admin contracts, returns msg.sender
   * for everything else. This only permits Pazari helper contracts to use tx.origin,
   * and all external non-admin contracts and wallets will use msg.sender. This is
   * essential for accurately recording owner addresses while restricting access to
   * PaymentRouter functions.
   * @dev Caution: This design is vulnerable to phishing attacks if a helper contract that
   * has isAdmin does NOT run the same _msgSender() logic.
   */
  function _msgSender() public view returns (address) {
    if (tx.origin != msg.sender && isAdmin[msg.sender]) {
      return tx.origin;
    } else return msg.sender;
  }

  // Adds an address to isAdmin mapping
  function addAdmin(address _newAddress, string calldata _memo) external onlyAdmin returns (bool) {
    require(!isAdmin[_newAddress], "Address is already an admin");

    isAdmin[_newAddress] = true;

    emit AdminAdded(_newAddress, tx.origin, _memo, block.timestamp);
    return true;
  }

  // Adds an address to isRouteAdmin mapping for a payment route
  function addRouteAdmin(
    bytes32 _routeID,
    address _newAddress,
    string calldata _memo
  ) external onlyRouteAdmin(_routeID) returns (bool) {
    require(!isRouteAdmin[_routeID][_newAddress], "Address is already a route admin");

    isRouteAdmin[_routeID][_newAddress] = true;

    emit RouteAdminAdded(_routeID, _newAddress, _msgSender(), _memo, block.timestamp);
    return true;
  }

  // Removes an address from isAdmin mapping
  function removeAdmin(address _oldAddress, string calldata _memo) external onlyAdmin returns (bool) {
    require(isAdmin[_oldAddress], "Address is not an admin");

    isAdmin[_oldAddress] = false;

    emit AdminRemoved(_oldAddress, tx.origin, _memo, block.timestamp);
    return true;
  }

  // Removes an address from isRouteAdmin mapping for a payment route
  function removeRouteAdmin(
    bytes32 _routeID,
    address _oldAddress,
    string calldata _memo
  ) external onlyRouteAdmin(_routeID) returns (bool) {
    require(isRouteAdmin[_routeID][_oldAddress], "Address is not a route admin");

    isRouteAdmin[_routeID][_oldAddress] = false;

    emit RouteAdminRemoved(_routeID, _oldAddress, _msgSender(), _memo, block.timestamp);
    return true;
  }
}

contract PaymentRouter is AccessControlPR {
  //***EVENTS***\\
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

  // Fires when a PaymentRoute's isActive property is toggled on or off
  // isActive == true => Route was reactivated
  // isActive == false => Route was deactivated
  event RouteToggled(bytes32 indexed routeID, bool isActive, uint256 timestamp);

  // Fires when an admin sets a new address for the Pazari treasury
  event TreasurySet(address oldAddress, address newAddress, address adminCaller, uint256 timestamp);

  // Fires when the pazariTreasury address is altered
  event TreasuryChanged(
    address oldAddress,
    address newAddress,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  // Fires when recipient max values are altered
  event MaxRecipientsChanged(
    uint8 newMaxRecipients,
    address indexed adminAuthorized,
    string memo,
    uint256 timestamp
  );

  //***MAPPINGS***\\
  // Maps available payment token balance per recipient for pull function
  // recipient address => token address => balance available to collect
  mapping(address => mapping(address => uint256)) internal tokenBalanceToCollect;

  // Mapping for route ID to route data
  // route ID => payment route
  mapping(bytes32 => PaymentRoute) public paymentRouteID;

  // Mapping of all routeIDs created by a route creator address
  // creator's address => routeIDs
  mapping(address => bytes32[]) public creatorRoutes;

  //***STATE VARIABLES, STRUCTS, ENUMS***\\
  // Struct that defines a new PaymentRoute
  struct PaymentRoute {
    address routeCreator; // Address of payment route creator
    address[] recipients; // Recipients in this payment route
    uint16[] commissions; // Commissions for each recipient--in fractions of 10000
    uint16 routeTax; // Tax paid by this route
    TAXTYPE taxType; // Determines if PaymentRoute auto-adjusts to minTax or maxTax
    bool isActive; // Is route currently active?
  }

  // Enum that is used to auto-adjust routeTax if minTax/maxTax are adjusted
  enum TAXTYPE {
    CUSTOM,
    MINTAX,
    MAXTAX
  }

  // Min and max tax rates that routes must meet
  uint16 public minTax;
  uint16 public maxTax;

  // Address of treasury contract where route taxes will be sent
  address public pazariTreasury;

  // Maximum amount of recipients a new PaymentRoute is allowed to have;
  uint8 public maxRecipients;

  //***CONSTRUCTOR AND MODIFIERS***\\
  constructor(
    address _pazariTreasury,
    address[] memory _routerAdmins,
    uint16 _minTax,
    uint16 _maxTax
  ) AccessControlPR(_routerAdmins) {
    require(_minTax <= _maxTax, "minTax must be <= maxTax");
    require(_routerAdmins.length > 0, "Must provide at least one developer address");
    require(_pazariTreasury != address(0), "Must provide a valid address for treasury");
    string memory memo = "Deployment";

    pazariTreasury = _pazariTreasury;
    isAdmin[_pazariTreasury];
    emit TreasuryChanged(address(0), _pazariTreasury, tx.origin, memo, block.timestamp);
    for (uint256 i = 0; i < _routerAdmins.length; i++) {
      isAdmin[_routerAdmins[i]] = true;
      emit AdminAdded(_routerAdmins[i], tx.origin, memo, block.timestamp);
    }
    minTax = _minTax;
    maxTax = _maxTax;
    maxRecipients = 10;
    emit RouteTaxBoundsChanged(_minTax, _maxTax);
    emit MaxRecipientsChanged(maxRecipients, tx.origin, memo, block.timestamp);
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
  modifier newRouteChecks(address[] calldata _recipients, uint16[] calldata _commissions) {
    // Check for front-end errors
    require(_recipients.length == _commissions.length, "Array lengths must match");
    require(_recipients.length <= maxRecipients, "Max recipients exceeded");

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
   * @notice Checks that the routeTax conforms to required bounds, and updates it if
   * developers change the minTax or maxTax
   *
   * @dev Thanks to TAXTYPE, we can now specify if a PaymentRoute auto-adjusts to the
   * minTax or maxTax bounds when they are adjusted, or retains its custom setting.
   * - If taxType is Custom, then it only needs to be higher than the minTax
   * - If taxType is Minimum, then it is auto-set to minTax
   * - If taxType is Maximum, then it is auto-set to maxTax
   */
  modifier checkRouteTax(bytes32 _routeID) {
    PaymentRoute memory route = paymentRouteID[_routeID];

    // If route tax is set to Custom:
    if (route.taxType == TAXTYPE.CUSTOM) {
      // If routeTax doesn't meet minTax, then it is set to minTax
      // Else if routeTax exceex maxTax, then it is set to maxTax
      if (route.routeTax < minTax) {
        route.routeTax = minTax;
      } else if (route.routeTax > maxTax) {
        route.routeTax = maxTax;
      }
    } else {
      route.routeTax = route.taxType == TAXTYPE.MINTAX ? minTax : maxTax;
    }
    _;
  }

  //***CORE FUNCTIONS***\\
  /**
   * @notice External function to transfer tokens from msg.sender to all payment route recipients.
   *
   * @param _routeID Unique ID of payment route
   * @param _tokenAddress Contract address of tokens being transferred
   * @param _senderAddress Wallet address of token sender
   * @param _amount Amount of tokens being routed
   *
   * @dev Emits TransferReceipt event for all purchases, and emits TransferFailed when ERC20
   * token transfer fails. TransferReceipt is the total amount sent through minus failed transfers.
   *
   * @dev Whether this or the pull function is used for a PaymentRoute depends on the price of the item
   * versus the number of recipients. Experimentation will be needed to discover what the ratio is for
   * price to recipients.length in order for gas fees to be less than 7% of the item's price. We don't
   * want the platform and gas fees to exceed 10% of the item's listing price.
   */
  function pushTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external onlyPazariContract checkRouteTax(_routeID) returns (bool) {
    require(paymentRouteID[_routeID].isActive, "Error: Route inactive");

    // Store PaymentRoute struct into local variable
    PaymentRoute memory route = getPaymentRoute(_routeID);
    // Transfer full _amount from sender to contract
    require(
      IERC20(_tokenAddress).transferFrom(_senderAddress, address(this), _amount),
      "ERC20 transferFrom failed"
    );

    // Transfer route tax first
    uint256 tax = (_amount * route.routeTax) / 10000;
    uint256 totalAmount = _amount - tax; // Total amount to be transferred after tax
    require(IERC20(_tokenAddress).transfer(pazariTreasury, tax), "ERC20 transfer failed");

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
        tokenBalanceToCollect[route.recipients[i]][_tokenAddress] += payment;
        continue; // Continue to next recipient
      }
    }

    // Emit a TransferReceipt event to all recipients
    emit TransferReceipt(_senderAddress, _routeID, _tokenAddress, totalAmount, tax, block.timestamp);
    return true;
    /*
     */
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
   *
   * @dev Emits TokensHeld event
   */
  function holdTokens(
    bytes32 _routeID,
    address _tokenAddress,
    address _senderAddress,
    uint256 _amount
  ) external onlyPazariContract checkRouteTax(_routeID) returns (bool) {
    PaymentRoute memory route = paymentRouteID[_routeID];
    //PaymentRoute memory route = getPaymentRoute(_routeID);
    require(route.isActive, "Payment route inactive");
    uint256 payment; // Each recipient's payment

    // Calculate platform tax and taxedAmount
    uint256 tax = (_amount * route.routeTax) / 10000;
    uint256 taxedAmount = _amount - tax;

    // Calculate each recipient's payment, add to token balance mapping
    // We + 1 to tokenBalanceToCollect as part of a gas-saving design
    for (uint256 i = 0; i < route.commissions.length; i++) {
      payment = ((taxedAmount * route.commissions[i]) / 10000);

      // If balance to collect is 0, then it needs to be initialized to 1
      if (tokenBalanceToCollect[route.recipients[i]][_tokenAddress] == 0) {
        tokenBalanceToCollect[route.recipients[i]][_tokenAddress] = 1;
      }

      tokenBalanceToCollect[route.recipients[i]][_tokenAddress] += payment;
    }

    // Transfer tokens from senderAddress to this contract
    require(
      IERC20(_tokenAddress).transferFrom(_senderAddress, address(this), _amount),
      "ERC20 transferFrom failed"
    );

    // Transfer treasury's commission from this contract to pazariTreasury
    require(IERC20(_tokenAddress).transfer(pazariTreasury, tax), "ERC20 transfer failed");

    // Fire event alerting recipients they have tokens to collect
    emit TokensHeld(_routeID, _tokenAddress, _amount);
    return true;
  }

  /**
   * @notice Collects all earnings stored in PaymentRouter
   *
   * @param _tokenAddress Contract address of payment token to be collected
   * @return success boolean
   *
   * @dev Emits TokensCollected event
   * @dev I decided not to require isActive for the route, since that will stop
   * recipients from collecting their payments after the route closes.
   */
  function pullTokens(address _tokenAddress) external returns (bool) {
    // Initialized accounts reset back to 1 instead of 0
    require(tokenBalanceToCollect[_msgSender()][_tokenAddress] > 1, "No payment to collect");

    // Store recipient's balance - 1 as their payment
    uint256 payment = tokenBalanceToCollect[_msgSender()][_tokenAddress] - 1;

    // Reset recipient's balance
    tokenBalanceToCollect[_msgSender()][_tokenAddress] -= payment; // This should always settle at 1
    //Comment: Assiging to 0 and 1 shouldn't change the gas cost. I think it's *delete* that will free up the space.
    //It does, by quite a lot. 0 => N costs ~46K gas, N => N costs ~26K gas, and N => 0 costs ~24K gas

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
   * @param _routeTax Percentage paid to Pazari Treasury (MVP: 0, sets to minTax)
   * @return routeID Hash of the created PaymentRoute
   *
   * @dev Emits RouteCreated event
   */
  function openPaymentRoute(
    address[] calldata _recipients,
    uint16[] calldata _commissions,
    uint16 _routeTax
  ) external onlyPazariContract newRouteChecks(_recipients, _commissions) returns (bytes32 routeID) {
    // Creates routeID from hashing contents of new PaymentRoute
    routeID = getPaymentRouteID(_msgSender(), _recipients, _commissions);

    TAXTYPE taxType = TAXTYPE.CUSTOM;

    // Logic for fixing _routeTax to minTax or maxTax values
    // _routeTax < minTax sets to minTax
    // _routeTax > 10000 sets to maxTax
    if (_routeTax < minTax) {
      _routeTax = minTax;
      taxType = TAXTYPE.MINTAX;
    }
    if (_routeTax > maxTax) {
      _routeTax = maxTax;
      taxType = TAXTYPE.MAXTAX;
    }

    // Maps the routeID to the new PaymentRoute
    paymentRouteID[routeID] = PaymentRoute(msg.sender, _recipients, _commissions, _routeTax, taxType, true);

    // Maps the routeID to the address that created it, and pushes to creator's routes array
    routeCreator[routeID] = _msgSender();
    creatorRoutes[_msgSender()].push(routeID);

    emit RouteCreated(msg.sender, routeID, _recipients, _commissions);
  }

  /**
   * @notice Toggles a payment route with ID _routeID
   *
   * @dev Emits RouteToggled event
   */
  function togglePaymentRoute(bytes32 _routeID) external onlyRouteAdmin(_routeID) {
    paymentRouteID[_routeID].isActive
      ? paymentRouteID[_routeID].isActive = false
      : paymentRouteID[_routeID].isActive = true;

    // If isActive == true, then route was re-opened, if isActive == false, then route was closed
    emit RouteToggled(_routeID, paymentRouteID[_routeID].isActive, block.timestamp);
  }

  /**
   * @notice Calculates the routeID of a payment route.
   *
   * @param _routeCreator Address of payment route's creator
   * @param _recipients Array of all commission recipients
   * @param _commissions Array of all commissions relative to _recipients
   * @return routeID Calculated routeID
   *
   * @dev RouteIDs are calculated by keccak256(_routeCreator, _recipients, _commissions)
   * @dev If a non-Pazari helper contract was used, then _routeCreator will be contract's address
   */
  function getPaymentRouteID(
    address _routeCreator,
    address[] calldata _recipients,
    uint16[] calldata _commissions
  ) public pure returns (bytes32 routeID) {
    routeID = keccak256(abi.encodePacked(_routeCreator, _recipients, _commissions));
  }

  /**
   * @notice Returns a list of the caller's created payment routes
   * @notice restricted to route's original creator, route admins, or Pazari admins
   *
   * @dev Routes are stored in arrays mapped to the addresses that created them.
   */
  function getCreatorRoutes(address _routeCreator) public view returns (bytes32[] memory) {
    bytes32[] memory routeIDs = creatorRoutes[_routeCreator];
    bytes32 routeID = routeIDs[0];
    // Caller must be either:
    // - The route's original creator
    // - A route admin
    // - A Pazari admin
    require(
      routeCreator[routeID] == _msgSender() || isRouteAdmin[routeID][_msgSender()] || (isAdmin[_msgSender()]),
      "Unauthorized: Only creator, route admins, or Pazari admins permitted"
    );
    return routeIDs;
  }

  /**
   * @notice Adjusts the tax applied to a payment route. Minimum is minTax, and
   * maximum is maxTax.
   *
   * @param _routeID PaymentRoute's routeID
   * @param _newTax New tax applied to route, calculated in fractions of 10000
   *
   * @dev Emits RouteTaxChanged event
   *
   * @dev Developers can alter minTax and maxTax, and the changes will be auto-applied
   * to an item the first time it is purchased.
   */
  function adjustRouteTax(bytes32 _routeID, uint16 _newTax) external onlyRouteAdmin(_routeID) returns (bool) {
    // Assume the taxType is custom for now
    TAXTYPE taxType = TAXTYPE.CUSTOM;

    // Logic for fixing _routeTax to minTax or maxTax values
    // _routeTax <= minTax auto-sets to minTax
    // _routeTax > maxTax sets to maxTax
    if (_newTax <= minTax) {
      _newTax = minTax;
      taxType = TAXTYPE.MINTAX;
    }
    if (_newTax > maxTax) {
      // changed back to > maxTax, let's use maxTax as the absolute upper-bound
      _newTax = maxTax;
      taxType = TAXTYPE.MAXTAX;
    }
    // Store values for routeTax and taxType
    paymentRouteID[_routeID].routeTax = _newTax;
    paymentRouteID[_routeID].taxType = taxType;

    // Route recipients receive notification of routeTax change
    emit RouteTaxChanged(_routeID, _newTax);
    return true;
  }

  /**
   * @notice This function allows devs to set the minTax and maxTax global variables
   *
   * @dev Emits RouteTaxBoundsChanged
   */
  function adjustTaxBounds(uint16 _minTax, uint16 _maxTax) external onlyAdmin {
    require(_minTax >= 0, "Minimum tax < 0.00%");
    require(_maxTax <= 10000, "Maximum tax > 100.00%");
    require(_maxTax >= _minTax, "Maximum cannot be greater than minimum");

    minTax = _minTax;
    maxTax = _maxTax;

    emit RouteTaxBoundsChanged(_minTax, _maxTax);
  }

  /**
   * @notice Sets the treasury's address
   *
   * @dev Emits TreasurySet event
   */
  function setTreasuryAddress(address _newTreasuryAddress, string calldata _memo)
    external
    onlyAdmin
    returns (
      bool success,
      address oldAddress,
      address newAddress
    )
  {
    // Store return values
    oldAddress = pazariTreasury;
    newAddress = _newTreasuryAddress;
    pazariTreasury = _newTreasuryAddress;

    emit TreasuryChanged(oldAddress, newAddress, _msgSender(), _memo, block.timestamp);
    success = true;
  }

  /**
   * @notice Sets the maximum number of recipients allowed for a PaymentRoute
   * @dev Does not affect pre-existing routes, only new routes
   *
   * @param _newMax Maximum recipient size for new PaymentRoutes
   * @return (bool, uint8) Success bool, new value for maxRecipients
   */
  function setMaxRecipients(uint8 _newMax, string calldata _memo) external onlyAdmin returns (bool, uint8) {
    maxRecipients = _newMax;

    emit MaxRecipientsChanged(maxRecipients, _msgSender(), _memo, block.timestamp);
    return (true, maxRecipients);
  }

  /**
   * @notice Returns a PaymentRoute struct
   * @dev This exists because directly accessing the mapping wasn't returning the recipients and
   * an commissions arrays inside holdTokens() and pushTokens().
   */
  function getPaymentRoute(bytes32 _routeID) public view returns (PaymentRoute memory paymentRoute) {
    return paymentRouteID[_routeID];
  }

  /**
   * @notice Returns the caller's ERC20 balance that is available to withdraw
   *
   * @dev The mapping is always +1 to the actual balance, and this function compensates for that.
   * @dev This function hides account balances from public view, only account owners and admins may call it.
   */
  function getPaymentBalance(address _recipientAddress, address _tokenAddress)
    public
    view
    returns (uint256 balance)
  {
    require(_msgSender() == _recipientAddress || isAdmin[_msgSender()], "Caller not owner of account");
    // Logic for returning 0 when account is empty
    if (tokenBalanceToCollect[_recipientAddress][_tokenAddress] <= 1) {
      return 0;
    } else balance = tokenBalanceToCollect[_recipientAddress][_tokenAddress] - 1;
  }

  /**
   * @notice Returns the minTax and maxTax values that PaymentRoutes must stay within
   */
  function getTaxBounds() public view returns (uint256 min, uint256 max) {
    return (minTax, maxTax);
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