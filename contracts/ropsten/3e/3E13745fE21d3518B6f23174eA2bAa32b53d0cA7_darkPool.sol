/**
 *Submitted for verification at Etherscan.io on 2021-05-05
*/

// SPDX-License-Identifier: GPLv3

pragma solidity ^0.8.1;
pragma abicoder v2;
pragma experimental SMTChecker;

contract darkPool {
    // State:
    //      Registration (Reg): operator can add, delete and modify client data,
    //      Trading (Tr): clients commit orders
    //      Reveil (Rev): clients "reveil" orders
    //      Calculation (Cal): operator performs the computation
    //      Results (Res): operator publishes matched orders
    // Then we move back to registration (next "trading day")
    enum Phase { Reg, Trd, Rev, Cal, Res }
    Phase public phase;
    address public operator; // adress of the dark pool operator
    mapping(address => bytes) public us_pk; // user specific public key
    // Stores details about each order
    struct Order {
        bytes _commitment;
        bytes _ciphertext;
        bytes _sk;
    }
    // Stores user orders
    mapping(address => Order) public orders;
    // 0: Periodic, 1: Volume, 2: MV
    uint public auctionMode;
    uint public expiration;

    // inform participants about current state
    event startPhase(
        Phase currentState,
        uint expirationTime
    );

    // inform participants about "revealed" commitments only since
    // the rest are automatically rejected (invalid)
    event commitmentRevealed(
        address sender,
        bytes commitment,
        bytes ciphertext
    );

    // reveal secret for a matched order
    event secretRevealed(
      address sender,
      bytes commitment,
      bytes ciphertext,
      bytes secret
    );

    // log trades after they were matched
    event logTrade(
        string buyer,
        address buyerAddr,
        string seller,
        address sellerAddr,
        string asset,
        uint amount,
        uint price
    );

    // log when a registered client claims fraud
    event fraudClaimed(
        address claimer
    );

    constructor() {
        // save address of dark pool operator
        operator = msg.sender;
        // start registration phase
        phase = Phase.Reg;
        // emit event
        emit startPhase(Phase.Reg, 0);
    }

    // *** Operator functions ***

    function register_client(address client_address, bytes memory pk) external {
        // only the operator can add new clients
        require(msg.sender == operator, "Only the operator can call this.");
        // check if we are at the registration phase
        require(phase == Phase.Reg, "This function is not callable at this phase.");
        // add client
        us_pk[client_address] = pk;
    }

    // time: time for clients to send their hashed orders
    //       (this is basicly the trading duration)
    function trading_phase(uint time, uint mode) external {
        // only the operator can initiate the trading phase
        require(msg.sender == operator, "Only the operator can call this.");
         // check if we are at the registration phase
        require(phase == Phase.Reg, "This function is not callable at this phase.");
        // check if it's a valid auction mode
        require(mode < 3, "Auction mode should be 0 or 1 or 2.");
        // set auction mode
        auctionMode = mode;
        // change to trading phase
        phase = Phase.Trd;
        // set expiration time for trading day
        // trading time in blocks, 1 block is mined every ~12 seconds
        expiration = block.number + time;
        // emit event
        emit startPhase(Phase.Trd, expiration);
    }

    // time: time for clients to "reveal" their orders,
    //       otherwise orders are deemed invalid
    function reveal_phase(uint time) external {
        // only the operator can initiate the reveal phase
        require(msg.sender == operator, "Only the operator can call this.");
         // check if we are at the trading phase
        require(phase == Phase.Trd, "This function is not callable at this phase.");
        // check if we are at or past expiration
        require(block.number >= expiration, "Please wait for the expiration of the previous phase.");
        // change to reveal phase
        phase = Phase.Rev;
        // set expiration time
        expiration = block.number + time;
        // emit event
        emit startPhase(Phase.Rev, expiration);
    }

    function calc_phase() external {
        // only the operator can initiate the calculation phase
        require(msg.sender == operator, "Only the operator can call this.");
         // check if we are at the reveal phase
        require(phase == Phase.Rev, "This function is not callable at this phase.");
        // check if we are at or past expiration
        require(block.number >= expiration, "Please wait for the expiration of the previous phase.");
        // change to calculation phase
        phase = Phase.Cal;
        // emit event
        emit startPhase(Phase.Cal, 0);
    }

    function reveal_match(string memory asset, address buyer, bytes memory skB, string memory nameB, address seller,
                          bytes memory skS, string memory nameS, uint amount, uint price) external {
        // only the operator can reveal a match
        require(msg.sender == operator, "Only the operator can call this.");
         // check if we are at the calculation phase
        require(phase == Phase.Cal, "This function is not callable at this phase.");
        // check that two different clients were provided
        require(buyer != seller, "Buyer and Seller must not be the same.");
        // check if buyer has provided all details
        // check if commitment exists
        require(orders[buyer]._commitment.length > 0, "No commitment provided by this buyer.");
        // check if ciphertext exists
        require(orders[buyer]._ciphertext.length > 0, "No ciphertext provided by this buyer.");
        // check if seller has provided all details
        // check if commitment exists
        require(orders[seller]._commitment.length > 0, "No commitment provided by this buyer.");
        // check if ciphertext exists
        require(orders[seller]._ciphertext.length > 0, "No ciphertext provided by this buyer.");
        // publish secret keys, allowing verification
        // check if seller key was already published
        if(orders[seller]._sk.length == 0) {
            orders[seller]._sk = skS;
            emit secretRevealed(seller, orders[seller]._commitment, orders[seller]._ciphertext, skS);
        }
        // check if buyer key was already published
        if(orders[buyer]._sk.length == 0) {
            orders[buyer]._sk = skB;
            emit secretRevealed(buyer, orders[buyer]._commitment, orders[buyer]._ciphertext, skB);
        }
        // emit trade event
        emit logTrade(nameB, buyer, nameS, seller, asset, amount, price);
    }

    // time: time for clients to check if their order was executed, validate
    //       the algorithm and send new address for the next trading day
    function res_phase(uint time) external {
        // only the operator can initiate the results phase
        require(msg.sender == operator, "Only the operator can call this.");
         // check if we are at the calculation phase
        require(phase == Phase.Cal, "This function is not callable at this phase.");
        // change to results phase
        phase = Phase.Res;
        // set expiration time
        expiration = block.number + time;
        // emit event
        emit startPhase(Phase.Res, expiration);
    }

    function reg_phase() external {
        // only the operator can initiate the registration phase
        require(msg.sender == operator, "Only the operator can call this.");
         // check if we are at the results phase
        require(phase == Phase.Res, "This function is not callable at this phase.");
        // check if we are at or past expiration
        require(block.number >= expiration, "Please wait for the expiration of the previous phase.");
        // change to the registration phase
        phase = Phase.Reg;
        // emit event
        emit startPhase(Phase.Reg, 0);
    }

    // *** IMPORTANT NOTE: ***
    // At the end of a trading day, the operator MUST delete all orders or delete
    // and reregister(in random order) every client that took part in the previous
    // trading day, otherwise their previous order won't be deleted from the smart
    // contract (this could lead to previous orders re-executing)

    function remove_order(address client_address) external {
        // only the operator can delete orders
        require(msg.sender == operator, "Only the operator can call this.");
        // check if we are at the registration phase
        require(phase == Phase.Reg, "This function is not callable at this phase.");
        // check if client already assigned a public key
        require(us_pk[client_address].length != 0, "Client not registered.");
        // remove old order if any
        delete orders[client_address];
    }

    function remove_client(address client_address) external {
        // only the operator can delete clients
        require(msg.sender == operator, "Only the operator can call this.");
        // check if we are at the registration phase
        require(phase == Phase.Reg, "This function is not callable at this phase.");
        // check if client already assigned a public key
        require(us_pk[client_address].length != 0, "Client not registered.");
        // remove old order if any
        delete orders[client_address];
        // delete clients public key
        delete us_pk[client_address];
    }

    // *** Client functions ***

    function commit_order(bytes memory hashed_order) external {
         // check if we are at the trading phase
        require(phase == Phase.Trd, "This function is not callable at this phase.");
        // only a registered user can commit an order
        require(us_pk[msg.sender].length > 0, "Transaction address does not correspond to a registered user.");
        // check if commitment exists
        require(orders[msg.sender]._commitment.length == 0, "Order already commited.");
        // add commitment only (nonce and ciphertext set to default values)
        orders[msg.sender]._commitment = hashed_order;
    }

    function cancel_order() external {
         // check if we are at the trading phase
        require(phase == Phase.Trd, "This function is not callable at this phase.");
        // only a registered user can cancel an order
        require(us_pk[msg.sender].length > 0, "Transaction address does not correspond to a registered user.");
        // check if client has commited to an order
        require(orders[msg.sender]._commitment.length > 0, "No commitment was made.");
        // delete commitment
        delete orders[msg.sender]._commitment;
    }

    function change_order(bytes memory hashed_order) external {
         // check if we are at the trading phase
        require(phase == Phase.Trd, "This function is not callable at this phase.");
        // only a registered user can change an order
        require(us_pk[msg.sender].length > 0, "Transaction address does not correspond to a registered user.");
        // check if client has commited to an order
        require(orders[msg.sender]._commitment.length > 0, "No commitment was made.");
        // change the commitment
        orders[msg.sender]._commitment = hashed_order;
    }

    function reveal_order(bytes memory ciphertext) external {
        // check if we are at the reveal phase
        require(phase == Phase.Rev, "This function is not callable at this phase.");
        // only a registered user can commit an order
        require(us_pk[msg.sender].length > 0, "Transaction address doesn't correspond to a registered user.");
        // check if commitment exists
        require(orders[msg.sender]._commitment.length > 0, "No commitment was made.");
        // check if ciphertext exists
        require(orders[msg.sender]._ciphertext.length == 0, "Ciphertext already revealed.");
        // add ciphertext
        orders[msg.sender]._ciphertext = ciphertext;
        // emit event
        emit commitmentRevealed(msg.sender, orders[msg.sender]._commitment, orders[msg.sender]._ciphertext);
    }

    function claim_fraud() external {
        // check if we are at the reveal phase
        require(phase == Phase.Res, "This function is not callable at this phase.");
        // only a registered user can commit an order
        require(us_pk[msg.sender].length > 0, "Transaction address doesn't correspond to a registered user.");
        // emit event
        emit fraudClaimed(msg.sender);
    }
}