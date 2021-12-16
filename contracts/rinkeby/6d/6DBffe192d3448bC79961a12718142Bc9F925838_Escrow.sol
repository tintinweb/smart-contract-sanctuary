// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

contract Escrow {
    uint256 public price; // price of the product to be sold
    address payable public seller;
    address payable public buyer;

    enum State {
        Created,
        Locked,
        Released,
        Inactive
    } // 0, 1, 2, 3
    // The state variable has a default value of the first member, `State.Created`
    State public state;

    /// Custom errors were added in Solidity v0.8.4
    /// Only the buyer can call this function.
    error OnlyBuyer();
    /// Only the seller can call this function.
    error OnlySeller();
    /// The function cannot be called at the current state.
    error InvalidState();
    /// The provided value has to be even.
    error ValueNotEven();
    /// The buyer needs to give a collateral of twice the price
    error InvalidCollateral();

    modifier onlyBuyer() {
        if (msg.sender != buyer) revert OnlyBuyer();
        _;
    }

    modifier onlySeller() {
        if (msg.sender != seller) revert OnlySeller();
        _;
    }

    modifier inState(State _state) {
        if (state != _state) revert InvalidState();
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event BuyerRefunded();
    event Payout();

    /// Step 1:
    /// The seller constructs the contract by sending twice the
    /// product's price as escrow
    /// Contract starts in State.Created.
    constructor() payable {
        seller = payable(msg.sender);
        price = msg.value / 2;
        if ((2 * price) != msg.value) {
            revert ValueNotEven();
        }
    }

    /// Step 2a:
    /// The seller abort the purchase and reclaims the ether.
    /// Contract goes into State.Inactive.
    function abort() public onlySeller inState(State.Created) {
        emit Aborted();
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }

    /// Step 2b:
    /// A buyer confirms his desire to purchase the product
    /// by sending twice the product's price to the escrow contract.
    /// Contract goes into State.Locked.
    function confirmPurchase() public payable inState(State.Created) {
        if (msg.value != (2 * price)) {
            revert InvalidCollateral();
        }
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        state = State.Locked;
    }

    /// Step 3a:
    /// The buyer confirms that he has received the product.
    /// In this case he receives the product price back that he has paid twice before.
    /// Contract goes into State.Released
    function confirmReceived() public onlyBuyer inState(State.Locked) {
        emit ItemReceived();
        state = State.Released;
        buyer.transfer(price); // Buyer receive 1 x value here
    }

    /// Step 3b:
    /// If the product is not received by the buyer the seller can refund him.
    /// The buyer receives the 2*price he has paid to the escrow contract back.
    /// Contract goes back into State.Created
    function refundBuyer() public onlySeller inState(State.Locked) {
        emit BuyerRefunded();
        state = State.Created;
        address payable _recipient = buyer;
        buyer = payable(0);
        // the transfer function reverts the state in case of errors
        _recipient.transfer(2 * price);
    }

    /// Step 4:
    /// After the buyer has confirmed reception of the product the seller can
    /// take out the remaining funds in the escrow which is his
    /// compound (2*price) + the payment of the buyer (1*price)
    /// Contract goes into State.Inactive
    function payout() public onlySeller inState(State.Released) {
        emit Payout();
        state = State.Inactive;
        seller.transfer(3 * price);
    }
}