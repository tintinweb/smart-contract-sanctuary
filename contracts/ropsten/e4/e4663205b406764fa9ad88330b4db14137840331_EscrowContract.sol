pragma solidity ^0.5.17;

import "./EIP20Interface.sol";


contract EscrowContract {

    enum TokenStandard {WEI,ERC20} 
    enum EscrowLockType {HASHLOCK, TIMELOCK, HASHTIMELOCK, DEX, EXTENDABLEIMELOCK}
    mapping (string => Escrow) listOfEscrows;

   struct Escrow {
        uint8 thisEscrowLockType;
        address payable sender; 
        address payable receiver; 
        uint8 thisTokenStandard; 
        uint amount; //this is number of Wei or tokens (ERC20)
        address thisTokenContractAddress; // empty if Wei
        bytes32 hashlock; 
        uint timelock;
        bool completed;
    }

    event newEscrow(string escrowId, uint8 thisEscrowLockType); 
    event extendedEscrow(string escrowId); 
    event completedEscrow(string escrowId);
    event cancelledEscrow(string escrowId);
    
    constructor () public {}
    
   
    /** 
     * @dev Create an extendableTimeLockEscrow
     * @param escrowId the assigned escrowId
     * @param thisSender address of payee into the escrow
     * @param thisReceiver address of receiver of the escrow
     * @param thisTokenStandard the type of value stored in the escrow
     * @param thisERC20TokenAmount the ERC20 amount stored in the escrow (0 if Wei stored)
     * @param thisERCTokenContract if the value stored is ERC20, where is this ERC20 smart contract (0x0 if Wei stored)
     * @param thisTimelock where only after can the funds be moved
     */
    function createExtendableTimeLockEscrow(string calldata escrowId, address payable thisSender, address payable thisReceiver, uint8 thisTokenStandard, uint thisERC20TokenAmount, address thisERCTokenContract, uint thisTimelock)  payable external {

        require(listOfEscrows[escrowId].sender==address(0x0),"EscrowId exists");
        require(thisTimelock > now, "timelock must be in the future"); 
        basicEscrowElements(escrowId,uint8(EscrowLockType.EXTENDABLEIMELOCK), thisSender, thisReceiver, thisTokenStandard, thisERC20TokenAmount, thisERCTokenContract);
        listOfEscrows[escrowId].timelock = thisTimelock;   
        //other Escrow parameters remain at default/null value            
        erc20EscrowBasicElements(thisSender, thisTokenStandard, thisERCTokenContract, thisERC20TokenAmount);
        //emit event and  record  new ID
        emit newEscrow(escrowId, uint8(EscrowLockType.EXTENDABLEIMELOCK)); 

    }
    

     /** 
     * @dev Extend an extendableTimeLockEscrow, can only be called by the original sender
     * @param escrowId reference to the escrow to extend
     * @param thisTimelock the time to extend this escrow until
     */
    function extendExtendableTimeLockEscrow(string calldata escrowId, uint thisTimelock) external {
        //check time, see if it has passed
        Escrow storage thisEscrow = listOfEscrows[escrowId];
        require(msg.sender == thisEscrow.sender, "only the sender of the escrowed funds can increase the escrow time");
        require(thisEscrow.timelock < thisTimelock, "new timelock must be greater than previously");
        thisEscrow.timelock = thisTimelock;
        emit extendedEscrow(escrowId);
    }
    
     /** 
     * @dev Close an extendableTimeLockEscrow, can only be called by the original sender
     * @param escrowId reference to the escrow to extend
     */
    function closeExtendableTimeLockEscrow(string calldata escrowId) external {
        //check time, see if it has passed
        Escrow storage thisEscrow = listOfEscrows[escrowId];
        require(msg.sender == thisEscrow.receiver, "only the receiver of the escrowed can claim the funds");
        require(thisEscrow.timelock > now, "timelock not yet expired");
        thisEscrow.completed = true;
        finaliseEscrow(thisEscrow.receiver, thisEscrow.amount, thisEscrow.thisTokenStandard, thisEscrow.thisTokenContractAddress);
        emit completedEscrow(escrowId);
    }

    
     /** 
     * @dev Set the basic elements of the escrow object (it is in a separate function to save on gas for contract deployment)
     * @param escrowId reference to the escrow to create
     * @param thisEscrowLockType the type of escrow to create
     * @param thisSender address of payee into the escrow
     * @param thisReceiver address of receiver of the escrow
     * @param thisTokenStandard the type of value stored in the escrow
     * @param thisERC20TokenAmount the ERC20 amount stored in the escrow (0 if Wei stored)
     * @param thisERCTokenContract if the value stored is ERC20, where is this ERC20 smart contract (0x0 if Wei stored)
     */ 
    function basicEscrowElements(string memory escrowId, uint8 thisEscrowLockType, address payable thisSender, address payable thisReceiver, uint8 thisTokenStandard, uint thisERC20TokenAmount, address thisERCTokenContract) internal {
        
        Escrow storage thisEscrow = listOfEscrows[escrowId];
        require((thisTokenStandard <= uint8(TokenStandard.ERC20) + 1), "thisTokenStandard is out of bounds.");
        if (thisTokenStandard == uint8(TokenStandard.ERC20)){
            require(thisERCTokenContract != address(0x0), "ERC20 contract address missing");
        }
            // save basic escrow elements
        thisEscrow.thisEscrowLockType = uint8(thisEscrowLockType);
        thisEscrow.sender = thisSender;
        thisEscrow.receiver = thisReceiver;
        thisEscrow.thisTokenStandard = thisTokenStandard;
        if (thisTokenStandard == uint8(TokenStandard.WEI)){
            thisEscrow.amount = msg.value;
            // listOfEscrows[escrowCounter].thisDLTokenContractAddress is set (takes default value)      
        } else {
            thisEscrow.amount = thisERC20TokenAmount;
            thisEscrow.thisTokenContractAddress = thisERCTokenContract;            
        }
        
    }
    
    
     /** 
     * @dev Takes (pre-approved) ERC20 tokens from the escrow sender and assigns them to this contract address
     * @param sender the sender of this escrow
     * @param tokenContractAddress the address of this ECR20 token contract
     * @param toSend the amount to transfer from the escrow sender, to this smart contract address
     */     
    function HoldERC20TokensInEscrow(address sender, address tokenContractAddress, uint toSend)  internal {
        
            ERC20Interface thisErc20 = ERC20Interface(tokenContractAddress);
            uint tokensAtStart =  thisErc20.balanceOf(address(this));
            //take from sender
            bool resp = thisErc20.transferFrom(sender, address(this), toSend);
            require(resp == true, "Failure in ERC20 transferFrom function");
            uint tokensAtEnd =  thisErc20.balanceOf(address(this));
            //compare before and after balance (making sure ERC20 contract is not malicious)
            require(tokensAtEnd == tokensAtStart+toSend, "ERC20 balance not updated correctly");
    
    }
    
    
        /** 
     * @dev If the token being escrowed is NOT ETH, then it needs to be transferred to this contract using the ERC20 contract transferFrom function
     * @param tokenSender address of payee into the escrow
     * @param thisTokenStandard the type of value stored in the escrow
     * @param thisERCTokenContract if the value stored is ERC20, where is this ERC20 smart contract (0x0 if Wei stored)
     * @param thisERC20TokenAmount the ERC20 amount stored in the escrow (0 if Wei stored)
     */ 
    function erc20EscrowBasicElements(address tokenSender, uint8 thisTokenStandard, address thisERCTokenContract, uint thisERC20TokenAmount) internal{
        //if ETH is to be in this escrow, it has already been send to this contract address due to the payable keyword on all of the create escrow functions
        if (thisTokenStandard == uint8(TokenStandard.ERC20)){
                //check the approved tokens - the smart contract can only take up to the approved amount of tokens from this user.
                //this is why the sender of the escrow must have already called the approve function of thisERCTokenContract for at least thisERC20TokenAmount
                ERC20Interface thisErc20 = ERC20Interface(thisERCTokenContract);
                uint sendersAvailableTokens = thisErc20.allowance(tokenSender,address(this));
                require(sendersAvailableTokens >= thisERC20TokenAmount, "Not enough ERC20 tokens approved");
                //if greater than or equal to the correct amount of tokens have been approved, take these tokens to be assigned to this contract address
                HoldERC20TokensInEscrow(tokenSender, thisERCTokenContract,thisERC20TokenAmount);
        }
    }


    /** 
     * @dev Performs the transfers to close the escrows
     * @param receiver address of receiver of escrow funds
     * @param amount the ERC20 amount stored in the escrow (0 if Wei stored)
     * @param thisTokenStandard the type of value stored in the escrow
     * @param tokenAddress if the value stored is ERC20, where is this ERC20 smart contract (0x0 if Wei stored)
     */ 
    function finaliseEscrow(address payable receiver, uint amount, uint8 thisTokenStandard, address tokenAddress)  internal {
        
        if (thisTokenStandard == uint8(TokenStandard.ERC20)){
            ERC20Interface thisErc20 = ERC20Interface(tokenAddress);
            //tokens were taken on escrow creation (and assigned to this smart contract address), so now give these tokens to receiver
            uint receiverTokensAtStart = thisErc20.balanceOf(receiver);
            bool success = thisErc20.transfer(receiver, amount);
            uint receiverTokensAtEnd = thisErc20.balanceOf(receiver);
            require (success == true, "Escrow finalisation error");
            //check to make sure before and after balance updated correctly (making sure ERC20 contract code is not faulty)
            require (receiverTokensAtEnd != receiverTokensAtStart + amount, "Finalisation did not update balance");

        } else if (thisTokenStandard == uint8(TokenStandard.WEI)) {
            //ETH transfer has a simple built in function
            receiver.transfer(amount);
            
        }
    
    }

    
    function generateHash(string calldata hashInput) external pure returns (bytes32){
        return sha256(abi.encodePacked(hashInput)); 
    }
    
    //getters
    
    function getEscrowLockType (string calldata escrowId) external view returns(uint8){
        return listOfEscrows[escrowId].thisEscrowLockType;
    }
    
    function getEscrowSender (string calldata escrowId) external view returns(address){
        return listOfEscrows[escrowId].sender;
    }
    
    function getEscrowReceiver (string calldata escrowId) external view returns(address){
        return listOfEscrows[escrowId].receiver;
    }
    
    function getEscrowTokenStandard (string calldata escrowId) external view returns(uint8){
        return listOfEscrows[escrowId].thisTokenStandard;
    }
    
    function getEscrowAmount (string calldata escrowId) external view returns(uint){
        return listOfEscrows[escrowId].amount;
    }
    
    function getEscrowTokenContractAddress (string calldata escrowId) external view returns(address){
        return listOfEscrows[escrowId].thisTokenContractAddress;
    }
    
    function getEscrowTimeLock (string calldata escrowId) external view returns(uint){
        return listOfEscrows[escrowId].timelock;
    }
    
    
    function getEscrowCompleted (string calldata escrowId) external view returns(bool){
        return listOfEscrows[escrowId].completed;
    }

    
}