pragma solidity ^0.4.23;

/*

Options Exchange
========================

An Exchange for American Options.
An American Option is a contract between its Buyer and its Seller, giving the Buyer the ability
to buy (or sell) an Asset at a specified Strike Price any time before a specified time (Maturation).

Authors: /u/Cintix and /u/Hdizzle83

*/

// Using the SafeMath Library helps prevent integer overflow bugs.
library SafeMath {

  function mul(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a * b;
    assert((a == 0) || (c / a == b));
    return c;
  }

  function div(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) pure internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) pure internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

// Options can only be created for tokens adhering to the ERC20 Interface.
// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract Token {
  function transferFrom(address from, address to, uint256 value) public returns (bool success) {}
  function transfer(address to, uint256 value) public returns (bool success) {}
}

// An Option is a bet between two users on the relative price of two assets on a given date.
// The Seller locks amountLocked of assetLocked in the Option in exchange for immediate payment of amountPremium of assetPremium from the Buyer.
// The Buyer is then free to exercise the Option by trading amountTraded of assetTraded for the locked funds.
// The ratio of amountTraded and amountLocked is called the Strike Price.
// At the closing date (Maturation) or when the Buyer exercises the Option, the Option&#39;s funds are sent back to the Seller.
contract OptionsExchange {

  using SafeMath for uint256;

  // Admin takes a 1% cut of each purchased Option&#39;s Premium, stored as a ratio with 1 ether as the denominator.
  uint256 public fee_ratio = 10 ** 16;
  
  // Admin is initialized to the contract creator.
  address public admin = msg.sender;
  
  // User balances are stored as userBalance[user][asset], where ETH is stored as address 0.
  mapping (address => mapping(address => uint256)) public userBalance;
  
  // Onchain Option data indicates the current Buyer and Seller along with corresponding nonces used to invalidate old offchain orders.
  // The Seller and Buyer addresses and their nonces take up two 32 byte storage slots, making up the only onchain data for each Option.
  // When both storage slots are zero (i.e. uninitialized), the Option is Available or Invalid.
  // When both storage slots are non-zero, the Option is Live or Matured.
  // When only the Buyer storage slot is non-zero, the Option is Closed.
  // When only the Seller storage slot is non-zero, the Option is Exercised or Cancelled.
  // When only nonceSeller is non-zero, the Option is Cancelled.
  // When an Option is Live, nonceSeller and nonceBuyer store how many users have been the Option&#39;s Seller and Buyer, respectively.
  // The storage slots are zeroed out when the Option is Closed or Exercised to refund 10,000 gas.
  struct optionDatum {
    address seller;
    uint96 nonceSeller;
    address buyer;
    uint96 nonceBuyer;
  }
  
  // To reduce onchain storage, Options are indexed by a hash of their offchain parameters, optionHash.
  mapping (bytes32 => optionDatum) public optionData;
  
  // Possible states an Option (or its offchain order) can be in.
  // Options implicitly store locked funds when they&#39;re Live or Matured.
  enum optionStates {
    Invalid,   // Option parameters are invalid.
    Available, // Option hasn&#39;t been created or filled yet.
    Cancelled, // Option&#39;s initial offchain order has been cancelled by the Maker.
    Live,      // Option contains implicitly stored funds, can be resold or exercised any time before its Maturation time.
    Exercised, // Option has been exercised by its buyer, withdrawing its implicitly stored funds.
    Matured,   // Option still contains implicitly stored funds but has passed its Maturation time and is ready to be closed.
    Closed     // Option has been closed by its Seller, who has withdrawn its implicitly stored funds.
  }
  
  // Events emitted by the contract for use in tracking exchange activity.
  // For Deposits and Withdrawals, ETH balances are stored as an asset with address 0.
  event Deposit(address indexed user, address indexed asset, uint256 amount);
  event Withdrawal(address indexed user, address indexed asset, uint256 amount);
  event OrderFilled(bytes32 indexed optionHash,
                    address indexed maker,
                    address indexed taker,
                    address[3] assetLocked_assetTraded_firstMaker,
                    uint256[3] amountLocked_amountTraded_maturation,
                    uint256[2] amountPremium_expiration,
                    address assetPremium,
                    bool makerIsSeller,
                    uint96 nonce);
  event OrderCancelled(bytes32 indexed optionHash, bool bySeller, uint96 nonce);
  event OptionExercised(bytes32 indexed optionHash, address indexed buyer, address indexed seller);
  event OptionClosed(bytes32 indexed optionHash, address indexed seller);
  event UserBalanceUpdated(address indexed user, address indexed asset, uint256 newBalance);
  
  // Allow the admin to transfer ownership.
  function changeAdmin(address _admin) external {
    require(msg.sender == admin);
    admin = _admin;
  }
  
  // Users must first deposit assets into the Exchange in order to create, purchase, or exercise Options.
  // ETH balances are stored as an asset with address 0.
  function depositETH() external payable {
    userBalance[msg.sender][0] = userBalance[msg.sender][0].add(msg.value);
    emit Deposit(msg.sender, 0, msg.value);
    emit UserBalanceUpdated(msg.sender, 0, userBalance[msg.sender][0]);
  }
  
  // Users can withdraw any amount of ETH up to their current balance.
  function withdrawETH(uint256 amount) external {
    require(userBalance[msg.sender][0] >= amount);
    userBalance[msg.sender][0] = userBalance[msg.sender][0].sub(amount);
    msg.sender.transfer(amount);
    emit Withdrawal(msg.sender, 0, amount);
    emit UserBalanceUpdated(msg.sender, 0, userBalance[msg.sender][0]);
  }
  
  // To deposit tokens, users must first "approve" the transfer in the token contract.
  // Users must first deposit assets into the Exchange in order to create, purchase, or exercise Options.
  function depositToken(address token, uint256 amount) external {
    require(Token(token).transferFrom(msg.sender, this, amount));  
    userBalance[msg.sender][token] = userBalance[msg.sender][token].add(amount);
    emit Deposit(msg.sender, token, amount);
    emit UserBalanceUpdated(msg.sender, token, userBalance[msg.sender][token]);
  }
  
  // Users can withdraw any amount of a given token up to their current balance.
  function withdrawToken(address token, uint256 amount) external {
    require(userBalance[msg.sender][token] >= amount);
    userBalance[msg.sender][token] = userBalance[msg.sender][token].sub(amount);
    require(Token(token).transfer(msg.sender, amount));
    emit Withdrawal(msg.sender, token, amount);
    emit UserBalanceUpdated(msg.sender, token, userBalance[msg.sender][token]);
  }
  
  // Transfer funds from one user&#39;s balance to another&#39;s.  Not externally callable.
  function transferUserToUser(address from, address to, address asset, uint256 amount) private {
    require(userBalance[from][asset] >= amount);
    userBalance[from][asset] = userBalance[from][asset].sub(amount);
    userBalance[to][asset] = userBalance[to][asset].add(amount);
    emit UserBalanceUpdated(from, asset, userBalance[from][asset]);
    emit UserBalanceUpdated(to, asset, userBalance[to][asset]);
  }
  
  // Hashes an Option&#39;s parameters for use in looking up information about the Option.  Callable internally and externally.
  // Variables are grouped into arrays as a workaround for the "too many local variables" problem.
  // Instead of directly encoding the asset exchange rate (Strike Price), it is instead implicitly
  // stored as the ratio of amountLocked, the amount of assetLocked stored in the Option, and amountTraded,
  // the amount of assetTraded needed to exercise the Option.
  function getOptionHash(address[3] assetLocked_assetTraded_firstMaker,
                         uint256[3] amountLocked_amountTraded_maturation) pure public returns(bytes32) {
    bytes32 optionHash = keccak256(assetLocked_assetTraded_firstMaker[0],
                                   assetLocked_assetTraded_firstMaker[1],
                                   assetLocked_assetTraded_firstMaker[2],
                                   amountLocked_amountTraded_maturation[0],
                                   amountLocked_amountTraded_maturation[1],
                                   amountLocked_amountTraded_maturation[2]);
    return optionHash;
  }
  
  // Hashes an Order&#39;s parameters for use in ecrecover.  Callable internally and externally.
  function getOrderHash(bytes32 optionHash,
                        uint256[2] amountPremium_expiration,
                        address assetPremium,
                        bool makerIsSeller,
                        uint96 nonce) view public returns(bytes32) {
    // A hash of the Order&#39;s information which was signed by the Maker to create the offchain order.
    bytes32 orderHash = keccak256("\x19Ethereum Signed Message:\n32",
                                  keccak256(address(this),
                                            optionHash,
                                            amountPremium_expiration[0],
                                            amountPremium_expiration[1],
                                            assetPremium,
                                            makerIsSeller,
                                            nonce));
    return orderHash;
  }
  
  // Computes the current state of an Option given its parameters.  Callable internally and externally.
  function getOptionState(address[3] assetLocked_assetTraded_firstMaker,
                          uint256[3] amountLocked_amountTraded_maturation) view public returns(optionStates) {
    // Tokens must be different for Option to be Valid.
    if(assetLocked_assetTraded_firstMaker[0] == assetLocked_assetTraded_firstMaker[1]) return optionStates.Invalid;
    // Options must have a non-zero amount of locked assets to be Valid.
    if(amountLocked_amountTraded_maturation[0] == 0) return optionStates.Invalid;
    // Exercising an Option must require trading a non-zero amount of assets.
    if(amountLocked_amountTraded_maturation[1] == 0) return optionStates.Invalid;
    // Options must reach Maturation between 2018 and 2030 to be Valid.
    if(amountLocked_amountTraded_maturation[2] < 1514764800) return optionStates.Invalid;
    if(amountLocked_amountTraded_maturation[2] > 1893456000) return optionStates.Invalid;
    bytes32 optionHash = getOptionHash(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation);
    address seller = optionData[optionHash].seller;
    uint96 nonceSeller = optionData[optionHash].nonceSeller;
    address buyer = optionData[optionHash].buyer;
    if(seller == 0x0) {
      // Check if the Option&#39;s offchain order was cancelled.
      if(nonceSeller != 0) return optionStates.Cancelled;
      // If both Buyer and Seller are still 0, Option is Available, even if it&#39;s past Maturation.
      if(buyer == 0x0) return optionStates.Available;
      // If Seller is 0 and Buyer is non-zero, Option must have been Closed.
      return optionStates.Closed;
    }
    // If Seller is non-zero and Buyer is 0, Option must have been Exercised.
    if(buyer == 0x0) return optionStates.Exercised;
    // If Seller and Buyer are both non-zero and the Option hasn&#39;t passed Maturation, it&#39;s Live.
    if(now < amountLocked_amountTraded_maturation[2]) return optionStates.Live;
    // Otherwise, the Option must have Matured.
    return optionStates.Matured;
  }
  
  // Transfer payment from an Option&#39;s Buyer to the Seller less the 1% fee sent to the admin.  Not externally callable.
  function payForOption(address buyer, address seller, address assetPremium, uint256 amountPremium) private {
    uint256 fee = (amountPremium.mul(fee_ratio)).div(1 ether);
    transferUserToUser(buyer, seller, assetPremium, amountPremium.sub(fee));
    transferUserToUser(buyer, admin, assetPremium, fee);
  }
  
  // Allows a Taker to fill an offchain Option order created by a Maker.
  // Transitions new Options from Available to Live, depositing its implicitly stored locked funds.
  // Maintains state of existing Options as Live, without affecting their implicitly stored locked funds.
  function fillOptionOrder(address[3] assetLocked_assetTraded_firstMaker,
                           uint256[3] amountLocked_amountTraded_maturation,
                           uint256[2] amountPremium_expiration,
                           address assetPremium,
                           bool makerIsSeller,
                           uint96 nonce,
                           uint8 v,
                           bytes32[2] r_s) external {
    // Verify offchain order hasn&#39;t expired.
    require(now < amountPremium_expiration[1]);
    bytes32 optionHash = getOptionHash(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation);
    // A hash of the Order&#39;s information which was signed by the Maker to create the offchain order.
    bytes32 orderHash = getOrderHash(optionHash, amountPremium_expiration, assetPremium, makerIsSeller, nonce);
    // A nonce of zero corresponds to creating a new Option, while nonzero means reselling an old one.
    if(nonce == 0) {
      // Option must be Available, which means it is valid, unfilled, and uncancelled.
      require(getOptionState(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation) == optionStates.Available);
      // Option must not already be past its Maturation time.
      require(now < amountLocked_amountTraded_maturation[2]);
      // Verify the Maker&#39;s offchain order is valid by checking whether it was signed by the first Maker.
      require(ecrecover(orderHash, v, r_s[0], r_s[1]) == assetLocked_assetTraded_firstMaker[2]);
      // Set the Option&#39;s Buyer and Seller and initialize the nonces to 1, marking the Option as Live.
      // Ternary operator to assign the Seller and Buyer from the Maker and Taker: (<conditional> ? <if-true> : <if-false>)
      optionData[optionHash].seller = makerIsSeller ? assetLocked_assetTraded_firstMaker[2] : msg.sender;
      optionData[optionHash].nonceSeller = 1;
      optionData[optionHash].buyer = makerIsSeller ? msg.sender : assetLocked_assetTraded_firstMaker[2];
      optionData[optionHash].nonceBuyer = 1;
      // The Buyer pays the Seller the premium for the Option.
      payForOption(optionData[optionHash].buyer, optionData[optionHash].seller, assetPremium, amountPremium_expiration[0]);
      // Lock amountLocked of the Seller&#39;s assetLocked in implicit storage as specified by the Option parameters.
      require(userBalance[optionData[optionHash].seller][assetLocked_assetTraded_firstMaker[0]] >= amountLocked_amountTraded_maturation[0]);
      userBalance[optionData[optionHash].seller][assetLocked_assetTraded_firstMaker[0]] = userBalance[optionData[optionHash].seller][assetLocked_assetTraded_firstMaker[0]].sub(amountLocked_amountTraded_maturation[0]);
      emit UserBalanceUpdated(optionData[optionHash].seller, assetLocked_assetTraded_firstMaker[0], userBalance[optionData[optionHash].seller][assetLocked_assetTraded_firstMaker[0]]);
      emit OrderFilled(optionHash, 
                       assetLocked_assetTraded_firstMaker[2],
                       msg.sender,
                       assetLocked_assetTraded_firstMaker,
                       amountLocked_amountTraded_maturation,
                       amountPremium_expiration,
                       assetPremium,
                       makerIsSeller,
                       nonce);
    } else {
      // Option must be Live, which means this order is a resale by the current buyer or seller.
      require(getOptionState(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation) == optionStates.Live);
      // If the Maker is the Seller, they&#39;re buying back out their locked asset.
      // Otherwise, the Maker is the Buyer and they&#39;re reselling their ability to exercise the Option.
      if(makerIsSeller) {
        // Verify the nonce of the Maker&#39;s offchain order matches to ensure the order isn&#39;t old or cancelled.
        require(optionData[optionHash].nonceSeller == nonce);
        // Verify the Maker&#39;s offchain order is valid by checking whether it was signed by the Maker.
        require(ecrecover(orderHash, v, r_s[0], r_s[1]) == optionData[optionHash].seller);
        // The Maker pays the Taker the premium for buying out their locked asset.
        payForOption(optionData[optionHash].seller, msg.sender, assetPremium, amountPremium_expiration[0]);
        // The Taker directly sends the Maker an amount equal to the Maker&#39;s locked assets, replacing them as the Seller.
        transferUserToUser(msg.sender, optionData[optionHash].seller, assetLocked_assetTraded_firstMaker[0], amountLocked_amountTraded_maturation[0]);
        // Update the Option&#39;s Seller to be the Taker and increment the nonce to prevent double-filling.
        optionData[optionHash].seller = msg.sender;
        optionData[optionHash].nonceSeller += 1;
        emit OrderFilled(optionHash, 
                         optionData[optionHash].seller,
                         msg.sender,
                         assetLocked_assetTraded_firstMaker,
                         amountLocked_amountTraded_maturation,
                         amountPremium_expiration,
                         assetPremium,
                         makerIsSeller,
                         nonce);
      } else {
        // Verify the nonce of the Maker&#39;s offchain order matches to ensure the order isn&#39;t old or cancelled.
        require(optionData[optionHash].nonceBuyer == nonce);
        // Verify the Maker&#39;s offchain order is valid by checking whether it was signed by the Maker.
        require(ecrecover(orderHash, v, r_s[0], r_s[1]) == optionData[optionHash].buyer);
        // The Taker pays the Maker the premium for the ability to exercise the Option.
        payForOption(msg.sender, optionData[optionHash].buyer, assetPremium, amountPremium_expiration[0]);
        // Update the Option&#39;s Buyer to be the Taker and increment the nonce to prevent double-filling.
        optionData[optionHash].buyer = msg.sender;
        optionData[optionHash].nonceBuyer += 1;
        emit OrderFilled(optionHash, 
                         optionData[optionHash].buyer,
                         msg.sender,
                         assetLocked_assetTraded_firstMaker,
                         amountLocked_amountTraded_maturation,
                         amountPremium_expiration,
                         assetPremium,
                         makerIsSeller,
                         nonce);
      }      
    }
  }
  
  // Allows a Maker to cancel their offchain Option order early (i.e. before its expiration).
  function cancelOptionOrder(address[3] assetLocked_assetTraded_firstMaker,
                             uint256[3] amountLocked_amountTraded_maturation,
                             bool makerIsSeller) external {
    optionStates state = getOptionState(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation);
    // Option must be Available or Live.  Orders can&#39;t be filled in any other state.
    require(state == optionStates.Available || state == optionStates.Live);
    bytes32 optionHash = getOptionHash(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation);
    // If the Option is Available, the first order hasn&#39;t been filled yet.
    if(state == optionStates.Available) {
      // Only allow the Maker to cancel their own offchain Option order.
      require(msg.sender == assetLocked_assetTraded_firstMaker[2]);
      emit OrderCancelled(optionHash, makerIsSeller, 0);
      // Mark the Option as Cancelled by setting the Seller nonce nonzero while the Seller is still 0x0.
      optionData[optionHash].nonceSeller = 1;
    } else {
      // Live Options can be resold by either the Buyer or the Seller.
      if(makerIsSeller) {
        // Only allow the Maker to cancel their own offchain Option order.
        require(msg.sender == optionData[optionHash].seller);
        emit OrderCancelled(optionHash, makerIsSeller, optionData[optionHash].nonceSeller);
        // Invalidate the old offchain order by incrementing the Maker&#39;s nonce.
        optionData[optionHash].nonceSeller += 1;
      } else {
        // Only allow the Maker to cancel their own offchain Option order.
        require(msg.sender == optionData[optionHash].buyer);
        emit OrderCancelled(optionHash, makerIsSeller, optionData[optionHash].nonceBuyer);
        // Invalidate the old offchain order by incrementing the Maker&#39;s nonce.
        optionData[optionHash].nonceBuyer += 1;
      }
    }
  }
  
  // Allow an Option&#39;s Buyer to exercise the Option, trading amountTraded of assetTraded to the Option for amountLocked of assetLocked.
  // The traded funds are sent directly to the Seller so they don&#39;t need to close it afterwards.
  // Transitions an Option from Live to Exercised, withdrawing its implicitly stored locked funds.
  function exerciseOption(address[3] assetLocked_assetTraded_firstMaker,
                          uint256[3] amountLocked_amountTraded_maturation) external {
    // Option must be Live, which means it&#39;s been filled and hasn&#39;t passed its trading deadline (Maturation).
    require(getOptionState(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation) == optionStates.Live);
    bytes32 optionHash = getOptionHash(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation);
    address buyer = optionData[optionHash].buyer;
    address seller = optionData[optionHash].seller;
    // Only allow the current Buyer to exercise the Option.
    require(msg.sender == buyer);
    // The Buyer sends the Seller the traded assets as specified by the Option parameters.
    transferUserToUser(buyer, seller, assetLocked_assetTraded_firstMaker[1], amountLocked_amountTraded_maturation[1]);
    // Mark the Option as Exercised by zeroing out the Buyer and the corresponding nonce.
    delete optionData[optionHash].buyer;
    delete optionData[optionHash].nonceBuyer;
    // The Buyer receives the implicitly stored locked assets as specified by the Option parameters.
    userBalance[buyer][assetLocked_assetTraded_firstMaker[0]] = userBalance[buyer][assetLocked_assetTraded_firstMaker[0]].add(amountLocked_amountTraded_maturation[0]);
    emit UserBalanceUpdated(buyer, assetLocked_assetTraded_firstMaker[0], userBalance[buyer][assetLocked_assetTraded_firstMaker[0]]);
    emit OptionExercised(optionHash, buyer, seller);
  }
  
  // Allows an Option&#39;s Seller to withdraw their funds after the Option&#39;s Maturation.
  // Transitions an Option from Matured to Closed, withdrawing its implicitly stored locked funds.
  function closeOption(address[3] assetLocked_assetTraded_firstMaker,
                       uint256[3] amountLocked_amountTraded_maturation) external {
    // Option must have Matured, which means it&#39;s filled, unexercised, and has passed its Maturation time.
    require(getOptionState(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation) == optionStates.Matured);
    bytes32 optionHash = getOptionHash(assetLocked_assetTraded_firstMaker, amountLocked_amountTraded_maturation);
    address seller = optionData[optionHash].seller;
    // Only allow the Seller to close their own Option.
    require(msg.sender == seller);
    // Mark the Option as Closed by zeroing out the Seller and the corresponding nonce.
    delete optionData[optionHash].seller;
    delete optionData[optionHash].nonceSeller;
    // Transfer the Option&#39;s implicitly stored locked funds back to the Seller.
    userBalance[seller][assetLocked_assetTraded_firstMaker[0]] = userBalance[seller][assetLocked_assetTraded_firstMaker[0]].add(amountLocked_amountTraded_maturation[0]);
    emit UserBalanceUpdated(seller, assetLocked_assetTraded_firstMaker[0], userBalance[seller][assetLocked_assetTraded_firstMaker[0]]);
    emit OptionClosed(optionHash, seller);
  }
  
  function() payable external {
    revert();
  }
  
}