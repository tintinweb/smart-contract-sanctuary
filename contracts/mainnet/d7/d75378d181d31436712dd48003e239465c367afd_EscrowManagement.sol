pragma solidity ^0.4.25;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract EscrowManagement {

    // CONTRACT VARIABLES ###########################################################################################

    uint public numberOfSuccessfullExecutions;

    // Escrow Order Template
    struct Escrow {
        address creator;          // address of the creator of the order
        uint amountTokenSell;     // amount of sell units creator is selling
        address tokenAddressSell; // address of the sell unit
        uint amountTokenBuy;      // amount of buy units creator is buying
        address tokenAddressBuy;  // address of the buy unit
    }

    mapping (address => mapping (address => Escrow[])) allOrders; // Stores all the escrows trading with said sell and by tokens

    enum EscrowState{
        Created,       // State representing that escrow order has been created by the seller
        Accepted,      // State representing that escrow order has been accepted by the buyer
        Completed,     // State representing that escrow order has been fulfilled and the exchange of tokens completed
        Died           // State representing that escrow order has been removed and deleted from the order book
    }

    // ##############################################################################################################


    // EVENTS #######################################################################################################

    event EscrowManagerInitialized();               // Escrow Manager Contract has been deployed and ready for usage
    event EscrowCreated(EscrowState escrowState);   // Escrow order has been created by the seller
    event EscrowAccepted(EscrowState escrowState);  // Escrow order has been accepted by the buyer
    event EscrowCompleted(EscrowState escrowState); // Escrow order has been fulfilled and the exchange of tokens completed
    event EscrowDied(EscrowState escrowState);      // Escrow order has been removed and deleted from the order book

    // ##############################################################################################################


    // MODIFIERS ####################################################################################################

    // Asserts that the escrow order chosen is valid
    // inputs:
    //     address _tokenAddressSell : contract address of the sell unit
    //      address _tokenAddressBuy : contract address of the buy unit
    //                 uint escrowId : position id of the escrow order in the order book
    modifier onlyValidEscrowId(address _tokenAddressSell, address _tokenAddressBuy, uint escrowId){
        require(
            allOrders[_tokenAddressSell][_tokenAddressBuy].length > escrowId, // Ensure that escrowId is less than the length of the escrow order list being referred to
            "Invalid Escrow Order!"                                           // Message to send if the condition above has failed, revert transaction
        );
        _;
    }

    // Asserts that the escrow order chosen is valid
    // inputs:
    //     uint sellTokenAmount : amount of sell tokens
    //      uint buyTokenAmount : amount of buy tokens
    modifier onlyNonZeroAmts(uint sellTokenAmount, uint buyTokenAmount){
        require(
            sellTokenAmount > 0 && buyTokenAmount > 0, // Ensure that the amounts entered into the creation of an escrow order are non-zero and positive
            "Escrow order amounts are 0!"              // Message to send if the condition above has failed, revert transaction
        );
        _;
    }

    // ##############################################################################################################


    // MAIN CONTRACT METHODS ########################################################################################

    // Constructor function for EscrowManager contract deployment
    function EscrowManager() {
        numberOfSuccessfullExecutions = 0;
        EscrowManagerInitialized();
    }

    // Creates the escrow order and stores the order in the escrow manager
    // inputs:
    //     address _tokenAddressSell: contract address of the sell unit
    //         uint _amountTokenSell: amount of sell units to sell
    //      address _tokenAddressBuy: contract address of buy unit
    //          uint _amountTokenBuy: amount of buy units to buy
    // events:
    //     EscrowCreated(EscrowState.Created): Escrow order has been created and is added to the orderbook
    function createEscrow(address _tokenAddressSell, uint _amountTokenSell,
                          address _tokenAddressBuy, uint _amountTokenBuy)
        payable
        onlyNonZeroAmts(_amountTokenSell, _amountTokenBuy)
    {

        Escrow memory newEscrow = Escrow({       // Create escrow order based on the &#39;Escrow&#39; template
            creator: msg.sender,                 // Assign the sender of the transaction to be the creator of the escrow order
            amountTokenSell: _amountTokenSell,   // Creator&#39;s specified sell amount
            tokenAddressSell: _tokenAddressSell, // Creator&#39;s specified sell unit
            amountTokenBuy: _amountTokenBuy,     // Creator&#39;s specified buy amount
            tokenAddressBuy: _tokenAddressBuy    // Creator&#39;s specified buy unit
        });

        ERC20Interface(_tokenAddressSell).transferFrom(msg.sender, this, _amountTokenSell); // EscrowManager transfers the amount of sell units from Creator to itself
        allOrders[_tokenAddressSell][_tokenAddressBuy].push(newEscrow);                     // Adds the new escrow order to the end of the order list in allOrders
        EscrowCreated(EscrowState.Created);                                                 // Event thrown to indicate that escrow order has been created
    }

    // Escrow order is chosen and fulfilled
    // inputs:
    //     address _tokenAddressSell: contract address of the sell unit
    //      address _tokenAddressBuy: contract address of buy unit
    //                 uint escrowId: position of the escrow order in allOrders based on the sell and buy contract address
    // events:
    //     EscrowAccepted(EscrowState.Accepted): Escrow order has been accepted by the sender of the transaction
    function acceptEscrow(address _tokenAddressSell, address _tokenAddressBuy, uint escrowId)
        payable
        onlyValidEscrowId(_tokenAddressSell, _tokenAddressBuy, escrowId)
    {
        Escrow memory chosenEscrow = allOrders[_tokenAddressSell][_tokenAddressBuy][escrowId];                    // Extract the chosen escrow order from allOrders based on escrowId
        ERC20Interface(chosenEscrow.tokenAddressBuy).transferFrom(msg.sender, this, chosenEscrow.amountTokenBuy); // EscrowManager transfers the amount of buy units from transaction sender to itself
        EscrowAccepted(EscrowState.Accepted);                                                                     // Escrow order amounts have been transfered to EscrowManager and thus order is accepted by transaction sender
        executeEscrow(chosenEscrow, msg.sender);                                                                  // EscrowManager to respective token amounts to seller and buyer
        escrowDeletion(_tokenAddressSell, _tokenAddressBuy, escrowId);                                            // EscrowManager to remove the fulfilled escrow order from allOrders
    }

    // EscrowManager transfers the respective tokens amounts to the seller and the buyer
    // inputs:
    //      Escrow escrow: Chosen escrow order to execute the exchange of tokens
    //      address buyer: Address of the buyer that accepted the escrow order
    // events:
    //     EscrowCompleted(EscrowState.Completed): Escrow order has been executed and exchange of tokens is completed
    function executeEscrow(Escrow escrow, address buyer)
        private
    {
        ERC20Interface(escrow.tokenAddressBuy).transfer(escrow.creator, escrow.amountTokenBuy); // EscrowManager transfers buy token amount to escrow creator (seller)
        ERC20Interface(escrow.tokenAddressSell).transfer(buyer, escrow.amountTokenSell);        // EscrowManager transfers sell token amount to buyer
        numberOfSuccessfullExecutions++;                                                        // Increment the number of successful executions of the escrow orders
        EscrowCompleted(EscrowState.Completed);                                                 // Escrow order execution of the exchange of tokens is completed
    }

    // EscrowManager removes the fulfilled escrow from allOrders
    // inputs:
    //     address _tokenAddressSell: contract address of the sell unit
    //      address _tokenAddressBuy: contract address of buy unit
    //                 uint escrowId: position of the escrow order in allOrders based on the sell and buy contract address
    // events:
    //     EscrowDied(EscrowState.Died): Escrow order is removed from allOrders
    function escrowDeletion(address _tokenAddressSell, address _tokenAddressBuy, uint escrowId)
        private
    {
        for(uint i=escrowId; i<allOrders[_tokenAddressSell][_tokenAddressBuy].length-1; i++){                        // Iterate through list of orders in allOrders starting from the current escrow order&#39;s position
            allOrders[_tokenAddressSell][_tokenAddressBuy][i] = allOrders[_tokenAddressSell][_tokenAddressBuy][i+1]; // Shift the all the orders in the list 1 position to the left
        }
        allOrders[_tokenAddressSell][_tokenAddressBuy].length--;                                                     // Decrement the total length of the list of orders to account for the removal of 1 escrow order
        EscrowDied(EscrowState.Died);                                                                                // Escrow order has been removed from allOrders
    }

    // ##############################################################################################################


    // GETTERS ######################################################################################################

    // Retrieves all the escrow orders based on the sell unit and the buy unit
    // inputs:
    //     address _tokenAddressSell: contract address of the sell unit
    //      address _tokenAddressBuy: contract address of the buy unit
    // outputs:
    //     uint[] sellAmount: list of the all the amounts in terms sell units in the list of escrow orders
    //     uint[] buyAmount: list of the all the amounts in terms buy units in the list of escrow orders
    function getOrderBook(address _tokenAddressSell, address _tokenAddressBuy)
        constant returns (uint[] sellAmount, uint[] buyAmount)
    {
        Escrow[] memory escrows = allOrders[_tokenAddressSell][_tokenAddressBuy]; // Extract the list of escrow orders from allOrders
        uint numEscrows = escrows.length;                                         // Length of the list of escrow orders
        uint[] memory sellAmounts = new uint[](numEscrows);                       // Initiate list of sell amounts
        uint[] memory buyAmounts = new uint[](numEscrows);                        // Initiate list of buy amounts
        for(uint i = 0; i < numEscrows; i++){                                     // Iterate through list of escrow orders from position 0 to the end of the list of escrow orders
            sellAmounts[i] = escrows[i].amountTokenSell;                          // Assign the position of the sell amount in the escrow order list to the same position in the sell amounts list
            buyAmounts[i] = escrows[i].amountTokenBuy;                            // Assign the position of the buy amount in the escrow order list to the same position in the buy amounts list
        }
        return (sellAmounts, buyAmounts);                                         // Returns the sell and buy amounts lists
    }

    // ##############################################################################################################

}