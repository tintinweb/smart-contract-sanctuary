pragma solidity ^0.5.0;

import "./ERC20Interface.sol";
import "./ERC721Interface.sol";

//we need a list of approved/verified ERC20 token addresses

contract EscrowDemo {

    enum TokenStandard {ERC20, ERC721, NativeMain, NativeSub} //i.e. nativeMain for Ethereum is Eth, nativeSub for Ethereum is Wei. XRP and drops for XRP Ledger respectively
    mapping (uint => EscrowSwapOrder) listOfSwapOrders;
    uint public swapOrderCounter = 0;
    uint public constant maxInt = ~uint256(0);

    struct EscrowSwapOrder {
        
        address payable initialSender;
        address payable initialReceiver; //the roles of the users in phase 1 of the cross chain swap
        string senderAddressOnOtherDL;
        string otherDLName;
        bytes32 hash;
        string secret;
        uint8 senderTokenStandard;
        uint8 receiverTokenStandard;
        uint valueSender; //this is number of tokens (ERC20) or tokenID (ERC721), or Eth (amount in Wei)
        uint valueReceiver; //see above
        address thisDLTokenContractAddress;
        string otherDLTokenContractAddress;
        uint lockTimeOut;
        string otherLedgerMetaData;
        bool completed;
        
    }

    //event newSwapOrder(address initialSender, string senderOtherDLAddress, string otherDLName, uint valueSender, uint valueReceiver, address thisDLTokenContractAddress,string otherDLTokenContractAddress, uint blockNumberTimeOut, uint swapOrderId); 
    
    modifier swapLive(uint swapOrderId){
        if (listOfSwapOrders[swapOrderId].completed == true){
            revert("This swapOrder has already been fulfilled");
        } else if (swapOrderId >= swapOrderCounter){
            revert("This is not a valid swap order ID");
        }else {
            _;
        }
    }
    
    modifier maximumSwapOrderIdCheck(){
        if (swapOrderCounter == maxInt){
            revert("Maximum order limit reached");
        } else {
            _;
        }
    }
    
    constructor () public {
    }

    //works for tokens or ether
    function createEscrowOrder(string calldata senderAddressOnOtherDL, address payable receiver, string calldata otherDLName, bytes32 hash, uint sendersTokens, uint receiversTokensRequired, uint8 senderTokenStandard, uint8 receiverTokenStandard, address thisDLsTokenContract, string calldata receiversTokenContract, uint lockTimeOut, string calldata otherLedgerMetaData) payable external maximumSwapOrderIdCheck(){
        
            if ((senderTokenStandard >= uint8(TokenStandard.NativeSub) + 1)||(receiverTokenStandard >= uint8(TokenStandard.NativeSub) + 1)){
                revert("At least one of the TokenStandards are out of bounds.");
            }
        //check sender has approved these specific number of tokens to THIS CONTRACTS Address.
            //go to sendersTokenContract
            //look up allowance for THIS Address
            if ((senderTokenStandard == uint(TokenStandard.NativeMain))||(senderTokenStandard == uint(TokenStandard.NativeSub))){
                
            } else {
                if(sendersTokens >= allowanceCheck(msg.sender, thisDLsTokenContract, TokenStandard.ERC20)){
                    revert("The sender has not sent this contract enough ERC-20 tokens to be able to complete the transfer");
                }
                
            }
            

            
            //check balance equals or exceeds sendersTokens
                //add to storage by creating a new swap orgSendersTokenContract
                //SwapOrder memory latestSwapOrder;
                listOfSwapOrders[swapOrderCounter].initialSender = msg.sender;
                listOfSwapOrders[swapOrderCounter].initialReceiver = receiver;
                listOfSwapOrders[swapOrderCounter].senderAddressOnOtherDL = senderAddressOnOtherDL;
                listOfSwapOrders[swapOrderCounter].otherDLName = otherDLName;
                listOfSwapOrders[swapOrderCounter].hash = hash;
                listOfSwapOrders[swapOrderCounter].senderTokenStandard = senderTokenStandard;
                listOfSwapOrders[swapOrderCounter].receiverTokenStandard = receiverTokenStandard;
                if ((senderTokenStandard == uint8(TokenStandard.NativeMain))||(senderTokenStandard == uint8(TokenStandard.NativeSub))){
                    listOfSwapOrders[swapOrderCounter].valueSender = msg.value;
                } else {
                    listOfSwapOrders[swapOrderCounter].valueSender = sendersTokens;
                }
                listOfSwapOrders[swapOrderCounter].valueReceiver = receiversTokensRequired;
                listOfSwapOrders[swapOrderCounter].thisDLTokenContractAddress = thisDLsTokenContract;
                listOfSwapOrders[swapOrderCounter].otherDLTokenContractAddress = receiversTokenContract;
                listOfSwapOrders[swapOrderCounter].otherLedgerMetaData = otherLedgerMetaData;
                listOfSwapOrders[swapOrderCounter].lockTimeOut = block.number + lockTimeOut;
                //listOfSwapOrders[swapOrderCounter] = latestSwapOrder;
                swapOrderCounter++;
                //emit event and  record  new ID
                //emit newSwapOrder(msg.sender, senderAddressOnOtherDL, otherDLName, sendersTokens, receiversTokensRequired, thisDLsTokenContract, receiversTokenContract, lockTimeOut, swapOrderCounter-1);
                if ((senderTokenStandard != uint(TokenStandard.NativeMain))&&(senderTokenStandard != uint(TokenStandard.NativeSub))){
                    //if a token is to be sent, take it now 
                    holdInEscrow(msg.sender, thisDLsTokenContract, senderTokenStandard, sendersTokens);
                }
                
    }
    
    function withdrawTokenAfterLock(uint swapOrderId) internal {
        
        //check sender is the sender of this swap order and lock has expired (so the swap can be cancelled)
        EscrowSwapOrder storage thisSwapOrder = listOfSwapOrders[swapOrderId];
        if (msg.sender != thisSwapOrder.initialSender){
            revert("Sender of message needs to be the same as the sender of the swapOrder");
        } else if (block.number <= thisSwapOrder.lockTimeOut){
            revert("The lock of the swapOrder has not yet expired");
        }
        
        //release the lock
        thisSwapOrder.completed = true;
        finaliseSwap(thisSwapOrder.initialSender, thisSwapOrder.thisDLTokenContractAddress, thisSwapOrder.senderTokenStandard, thisSwapOrder.valueSender); 
        
    }
    
    function closeEscrowOrder(uint swapOrderId, string calldata hashInput) external payable maximumSwapOrderIdCheck(){
        
        if (bytes(hashInput).length == 0){
            withdrawTokenAfterLock(swapOrderId);
        } else {
                   //msg.sender can be either party of the swap
            EscrowSwapOrder storage thisSwapOrder = listOfSwapOrders[swapOrderId];
            if ((msg.sender != thisSwapOrder.initialSender)&&(msg.sender != thisSwapOrder.initialReceiver)){
                revert("Sender of message needs to be either the sender or receiver of the swapOrder");
            } else if (thisSwapOrder.completed == true){
                revert("The swapOrder has already completed");            
            } else if (block.number > thisSwapOrder.lockTimeOut){
                revert("The swapOrder cannot be completed as it has expired");
            }
            //check that the hash input is correct
            bytes32 hashOutput = sha256(abi.encodePacked(hashInput));
            if (hashOutput == thisSwapOrder.hash){
                //release the lock
                thisSwapOrder.completed = true;
                thisSwapOrder.secret = hashInput;
                finaliseSwap(thisSwapOrder.initialReceiver, thisSwapOrder.thisDLTokenContractAddress, thisSwapOrder.senderTokenStandard, thisSwapOrder.valueSender); 
            } else {
                revert("Hash of input did not match the hashString of the swapOrder");
            } 
        }

        
    }
    
    function holdInEscrow(address sender, address tokenContractAddress, uint8 standard, uint toSend)  internal {
        
        if (standard == uint8(TokenStandard.ERC20)){
            ERC20Interface thisErc20 = ERC20Interface(tokenContractAddress);
            //take from sender
            uint addressTokensAtStart =  thisErc20.balanceOf(address(this));
            if (thisErc20.transferFrom(sender, address(this), toSend) != true){
                revert("Swap could not be finalised due to failure of transferFrom");
            } else if(thisErc20.balanceOf(address(this)) != addressTokensAtStart + toSend){
                revert("Swap could not be finalised as QuantSwap token balance was not updated");
            }
            
        } else if (standard == uint8(TokenStandard.ERC721)){
            
            //ERC721 Erc721 = ERC721(tokenContractAddress);
            //to do
            
        } else {
            revert("No other token contract standard types are supported");
        }
    
    }
    
    function finaliseSwap(address payable receiver, address tokenContractAddress, uint8 standard, uint toSend)  internal{
        
        if (standard == uint8(TokenStandard.ERC20)){
            ERC20Interface thisErc20 = ERC20Interface(tokenContractAddress);
            
            //now give to receiver
            uint receiverTokensAtStart = thisErc20.balanceOf(receiver);
            bool success2 = thisErc20.transfer(receiver, toSend);
            if (success2 != true){
                revert("Swap could not be finalised");
            } else if(thisErc20.balanceOf(receiver) != receiverTokensAtStart + toSend){
                revert("Swap could not be finalised as a user token balance was not updated ");
            }
            
        } else if (standard == uint8(TokenStandard.ERC721)){
            
            //ERC721 Erc721 = ERC721(tokenContractAddress);
            //to do
            
        } else if ((standard == uint8(TokenStandard.NativeMain))||(standard == uint8(TokenStandard.NativeSub))) {
            
            receiver.transfer(toSend);
            
        }else {
            revert("No other token contract standard types are supported");
        }
    
    }

    function allowanceCheck(address toCheck, address tokenContract, TokenStandard standard)  internal view returns (uint){
        
        uint allowance = 0;
        if (standard == TokenStandard.ERC20){
            
            ERC20Interface thisErc20 = ERC20Interface(tokenContract);
            allowance = thisErc20.allowance(toCheck,address(this));
            
        } else if (standard == TokenStandard.ERC721){
            
            //ERC721 Erc721 = ERC721(tokenContract);
            //allowance = ERC721.at(tokenContract);
            
        } else {
            revert("No other token contract standard types are supported");
        }
        
        return allowance;
        
    }
    
    function generateHash(string calldata hashInput) external pure returns (bytes32){
        return sha256(abi.encodePacked(hashInput)); //this works in the standard sha256 way - not abi.encode(...)
    }
    
    //getters
    function getEscrowSender (uint swapOrderId) external view returns(address){
        return listOfSwapOrders[swapOrderId].initialSender;
    }
    
    function getEscrowSenderAddressOnOtherDL (uint swapOrderId) external view returns(string memory){
        return listOfSwapOrders[swapOrderId].senderAddressOnOtherDL;
    }
    
    function getEscrowReceiver (uint swapOrderId) external view returns(address){
        return listOfSwapOrders[swapOrderId].initialReceiver;
    }
    
    function getEscrowOtherDLName (uint swapOrderId) external view returns(string memory){
        return listOfSwapOrders[swapOrderId].otherDLName;
    }
    
    function getEscrowHash (uint swapOrderId) external view returns(bytes32){
        return listOfSwapOrders[swapOrderId].hash;
    }
    
    function getEscrowHashAsUint (uint swapOrderId) external view returns(uint256){
        return uint(listOfSwapOrders[swapOrderId].hash);
    }
    
    function getEscrowSenderTokenStandard (uint swapOrderId) external view returns(uint8){
        return listOfSwapOrders[swapOrderId].senderTokenStandard;
    }
    
    function getEscrowReceiverTokenStandard (uint swapOrderId) external view returns(uint8){
        return listOfSwapOrders[swapOrderId].receiverTokenStandard;
    }
    
    function getEscrowSenderValue (uint swapOrderId) external view returns(uint){
        return listOfSwapOrders[swapOrderId].valueSender;
    }
    
    function getEscrowReceiverValue (uint swapOrderId) external view returns(uint){
        return listOfSwapOrders[swapOrderId].valueReceiver;
    }    
    
    function getEscrowSenderContractAddress (uint swapOrderId) external view returns(address){
        return listOfSwapOrders[swapOrderId].thisDLTokenContractAddress;
    }
    
    function getEscrowReceiverContractAddress (uint swapOrderId) external view returns(string memory){
        return listOfSwapOrders[swapOrderId].otherDLTokenContractAddress;
    }
    
    function getEscrowLockTimeOut (uint swapOrderId) external view returns(uint){
        return listOfSwapOrders[swapOrderId].lockTimeOut;
    }    
    
    function getEscrowCompleted (uint swapOrderId) external view returns(bool){
        return listOfSwapOrders[swapOrderId].completed;
    }
    
    function getEscrowMetaData (uint swapOrderId) external view returns(string memory){
        return listOfSwapOrders[swapOrderId].otherLedgerMetaData;
    }
    function getEscrowSecret (uint swapOrderId) external view returns(string memory){
        return listOfSwapOrders[swapOrderId].secret;
    }

    
}