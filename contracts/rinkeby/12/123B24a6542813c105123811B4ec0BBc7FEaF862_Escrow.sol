// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.4 <0.9.0;

contract Escrow {
    uint256 public price; // price of the product to be sold
    address payable public seller;
    address payable public buyer;

    // price * collateralFactor must be provided as collateral
    uint constant public collateralFactor = 2;

    enum State {
        Inactive,
        Priced,
        Paid,
        Settled
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
    /// The transferred escrow value does not match the price
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

    modifier secured(uint256 _price) {
        if (_price * collateralFactor != msg.value) revert InvalidCollateral();
        _;
    }

    event Priced();
    event Paid();
    event Settled();
    event Refunded();
    event Payout();

    /// Step 1:
    /// The seller constructs the Escrow contract
    /// Contract starts in State.Inactive.
    constructor() {
        seller = payable(msg.sender);
    }

    /// Step 2:
    /// The seller sets the product price and sends twice the product's price as escrow.
    /// Contract goes into in State.Priced.
    function setPrice(uint256 _price) public payable onlySeller inState(State.Inactive) secured(_price) {
        emit Priced();
        price = _price;
        state = State.Priced;
    }

    /// Step 3a:
    /// The seller aborts the purchase and reclaims his ether by calling payout (see below).

    /// Step 3b:
    /// A buyer pays the priced product and secures the transaction
    /// by sending price * collateralFactor to the contract.
    /// Contract stores the buyer and goes into State.Paid.
    function pay() public payable inState(State.Priced) secured(price) {
        emit Paid();
        buyer = payable(msg.sender);
        state = State.Paid;
    }

    /// Step 4a:
    /// The buyer confirms that he/she has received the product.
    /// In this case he/she receives the collateral back that has been paid on top of the price.
    /// Contract goes into State.Settled
    function confirmReceived() public onlyBuyer inState(State.Paid) {
        emit Settled();
        state = State.Settled;
        buyer.transfer(price * (collateralFactor - 1));
    }

    /// Step 4b:
    /// If the product is not received by the buyer the seller can refund him.
    /// The buyer receives the 2*price he has paid to the escrow contract back.
    /// Contract goes back into State.Priced
    function refund() public onlySeller inState(State.Paid) {
        emit Refunded();
        state = State.Priced;
        address payable _recipient = buyer;
        buyer = payable(0);
        // the transfer function reverts the state in case of errors
        _recipient.transfer(price * collateralFactor);
    }

    /// Step 3a and 5:
    /// After the buyer has confirmed reception of the product the seller can
    /// take out the remaining funds in the escrow which is his
    /// compound (2*price) + the payment of the buyer (1*price)
    /// Contract goes into State.Inactive
    function payout() public onlySeller {
        if (state != State.Priced && state != State.Settled) {
            revert InvalidState();
        }
        emit Payout();
        price = 0;
        state = State.Inactive;
        seller.transfer(address(this).balance);
    }
}