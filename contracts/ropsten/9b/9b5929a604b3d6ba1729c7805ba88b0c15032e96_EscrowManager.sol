pragma solidity ^0.4.20;

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

contract EscrowManager {

    // CONTRACT VARIABLES ###########################################################################################

    uint public numberOfSuccessfullExecutions;
    uint private constant escrowShelfLife = 1000;

    struct Escrow {
        address seller;
        uint amountTokenSell;
        address tokenAddressSell;
        uint amountTokenBuy;
        address tokenAddressBuy;
        uint createdInBlock;
    }

    mapping (address => mapping (address => Escrow[])) sellToBuyToEscrows; // Stores all the escrows trading with said sell and by tokens

    enum EscrowState{Uninitialized, Created, Accepted, Completed, Expired, Died}

    // ##############################################################################################################


    // EVENTS #######################################################################################################

    event EscrowManagerInitialized();
    event EscrowCreated(EscrowState escrowState);
    event EscrowAccepted(EscrowState escrowState);
    event EscrowCompleted(EscrowState escrowState);
    event EscrowExpired(EscrowState escrowState);
    event EscrowDied(EscrowState escrowState);

    // ##############################################################################################################


    // MODIFIERS ####################################################################################################

    modifier onlyValidEscrowId(address _tokenAddressSell, address _tokenAddressBuy, uint escrowId){
        require(
            sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy].length > escrowId,
            &quot;Invalid EscrowId!&quot;
        );
        _;
    }

    modifier onlyNonZeroAmts(uint amt1, uint amt2){
        require(
            amt1 > 0 && amt2 > 0,
            &quot;Escrow amounts are 0!&quot;
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
        onlyNonZeroAmts(_amountTokenSell, _amountTokenBuy)
    {
        Escrow memory newEscrow = Escrow({
            seller: msg.sender,
            amountTokenSell: _amountTokenSell,
            tokenAddressSell: _tokenAddressSell,
            amountTokenBuy: _amountTokenBuy,
            tokenAddressBuy: _tokenAddressBuy,
            createdInBlock: block.number
        });

        ERC20Interface(_tokenAddressSell).transferFrom(msg.sender, this, _amountTokenSell);
        sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy].push(newEscrow);
        EscrowCreated(EscrowState.Created);
    }

    function acceptEscrow(address _tokenAddressSell, address _tokenAddressBuy, uint escrowId)
        payable
        onlyValidEscrowId(_tokenAddressSell, _tokenAddressBuy, escrowId)
    {
        Escrow memory chosenEscrow = sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy][escrowId];
        if(chosenEscrow.createdInBlock + escrowShelfLife >= block.number){
            ERC20Interface(chosenEscrow.tokenAddressBuy).transferFrom(msg.sender, this, chosenEscrow.amountTokenBuy);
            EscrowAccepted(EscrowState.Accepted);
            executeEscrow(chosenEscrow, msg.sender);
        } else{
            EscrowExpired(EscrowState.Expired);
        }
        escrowDeletion(_tokenAddressSell, _tokenAddressBuy, escrowId);
    }

    function executeEscrow(Escrow escrow, address buyer)
        private
    {
        ERC20Interface(escrow.tokenAddressBuy).transfer(escrow.seller, escrow.amountTokenBuy);
        ERC20Interface(escrow.tokenAddressSell).transfer(buyer, escrow.amountTokenSell);
        numberOfSuccessfullExecutions++;
        EscrowCompleted(EscrowState.Completed);
    }

    function removeEscrow(address _tokenAddressSell, address _tokenAddressBuy, uint escrowId){
        if(sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy][escrowId].createdInBlock + escrowShelfLife < block.number ||
            sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy][escrowId].seller == msg.sender)
        {
            escrowDeletion(_tokenAddressSell, _tokenAddressBuy, escrowId);
        } else{
            revert();
        }
    }

    function escrowDeletion(address _tokenAddressSell, address _tokenAddressBuy, uint escrowId)
        private
    {
        for(uint i=escrowId; i<sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy].length-1; i++){
            sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy][i] = sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy][i+1];
        }
        sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy].length--;
        EscrowDied(EscrowState.Died);
    }

    // ##############################################################################################################


    // GETTERS ######################################################################################################

    function getOrderBook(address _tokenAddressSell, address _tokenAddressBuy)
        constant returns (uint[] sellAmts, uint[] buyAmts)
    {
        Escrow[] memory escrows = sellToBuyToEscrows[_tokenAddressSell][_tokenAddressBuy];
        uint numEscrows = escrows.length;
        uint[] memory sellAmounts = new uint[](numEscrows);
        uint[] memory buyAmounts = new uint[](numEscrows);
        for(uint i = 0; i < numEscrows; i++){
            sellAmounts[i] = escrows[i].amountTokenSell;
            buyAmounts[i] = escrows[i].amountTokenBuy;
        }
        return (sellAmounts, buyAmounts);
    }

    // ##############################################################################################################

}