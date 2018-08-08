pragma solidity ^0.4.20;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
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

contract EscrowManager {

    // CONTRACT VARIABLES ###########################################################################################

    uint public numberOfSuccessfullExecutions;
    uint public escrowId;

    struct Escrow {
        address seller;
        uint amountTokenSell;
        address tokenAddressSell;
        uint amountTokenBuy;
        address tokenAddressBuy;
        uint createdDate;
    }

    mapping (address => mapping (address => uint)) tokenAddressToSellerToDeposit;
    Escrow[] allEscrowOrders;

    enum EscrowState{Uninitialized, Created, Accepted, Completed, Died}
    EscrowState[] escrowStates;

    // ##############################################################################################################

    // EVENTS

    event EscrowManagerInitialized();
    event EscrowCreated(uint escrowId, EscrowState escrowState);
    event EscrowAccepted(uint escrowId, EscrowState escrowState);
    event EscrowCompleted(uint escrowId, EscrowState escrowState);
    event EscrowDied(uint escrowId, EscrowState escrowState);

    // ##############################################################################################################

    // MODIFIERS ####################################################################################################

    modifier onlyEscrowInStateCreated(uint chosenEscrowId){
        require(
            escrowStates[chosenEscrowId] == EscrowState.Created,
            "Escrow not in Created Yet!"
        );
        _;
    }

    // ##############################################################################################################

    // MAIN CONTRACT METHODS ########################################################################################

    function EscrowManager() {
        numberOfSuccessfullExecutions = 0;
        EscrowManagerInitialized();
    }

    function createEscrow(address _tokenAddressSell, uint _amountTokenSell,
                          address _tokenAddressBuy, uint _amountTokenBuy)
        payable
        returns (uint)
    {
        Escrow memory newEscrow = Escrow({
            seller: msg.sender,
            amountTokenSell: _amountTokenSell,
            tokenAddressSell: _tokenAddressSell,
            amountTokenBuy: _amountTokenBuy,
            tokenAddressBuy: _tokenAddressBuy,
            createdDate: now
        });
        
        // Contract deposits tokens from _seller to escrow
        // msg.sender must have allowed contract to send transferFrom tokens to contract address
        // msg sender needs to have performed ERC20Interface(_tokenAddressSell).allowed("contractAddress", _amountTokenSell);

        ERC20Interface(_tokenAddressSell).transferFrom(msg.sender, this, _amountTokenSell);
        allEscrowOrders.push(newEscrow);
        escrowStates.push(EscrowState.Created);
        EscrowCreated(escrowId, escrowStates[escrowId]);
        return escrowId++;
    }

    function acceptEscrow(uint chosenEscrowId) 
        payable
    {
        // msg.sender is the buyer
        Escrow memory chosenEscrow = allEscrowOrders[chosenEscrowId];
        ERC20Interface(chosenEscrow.tokenAddressBuy).transferFrom(msg.sender, this, chosenEscrow.amountTokenBuy);
        escrowStates[chosenEscrowId] = EscrowState.Accepted;
        EscrowAccepted(chosenEscrowId, escrowStates[chosenEscrowId]);
        executeEscrow(chosenEscrowId, msg.sender);
    }

    function executeEscrow(uint chosenEscrowId, address buyer)
        private
    {
        Escrow memory escrow = allEscrowOrders[chosenEscrowId];
        ERC20Interface(escrow.tokenAddressBuy).transfer(escrow.seller, escrow.amountTokenBuy);
        ERC20Interface(escrow.tokenAddressSell).transfer(buyer, escrow.amountTokenSell);
        escrowStates[chosenEscrowId] = EscrowState.Completed;
        EscrowCompleted(chosenEscrowId, escrowStates[chosenEscrowId]);
        numberOfSuccessfullExecutions++;
    }


    // ##############################################################################################################

    // SETTERS ######################################################################################################


    // ##############################################################################################################

    // GETTERS ######################################################################################################

    function getContractAddress() public constant returns(address){
        return this;
    }

    function getEscrowOrder_seller(uint id) public constant returns (address){
        return allEscrowOrders[id].seller;
    }
    
    // ##############################################################################################################

    // MISCELLANEOUS Functions

    function compareStrings (string a, string b) view returns (bool){
       return keccak256(a) == keccak256(b);
    }

    // ##############################################################################################################
}