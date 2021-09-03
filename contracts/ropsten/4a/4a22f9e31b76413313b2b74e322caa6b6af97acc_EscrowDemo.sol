pragma solidity ^0.5.0;

import "./ERC20Interface.sol";
import "./ERC721Interface.sol";

//we need a list of approved/verified ERC20 token addresses

contract EscrowDemo {

    enum TokenStandard {ERC20, ERC721, NativeMain, NativeSub} //i.e. nativeMain for Ethereum is Eth, nativeSub for Ethereum is Wei. XRP and drops for XRP Ledger respectively
    mapping (string => EscrowSwapOrder) listOfEscrowOrders;
    uint public swapOrderCounter = 0;
    uint public constant maxInt = ~uint256(0);

    struct EscrowSwapOrder {
        
        address payable initialSender;
        address payable initialReceiver; //the roles of the users in phase 1 of the cross chain swap
        bytes32 hash;
        string secret;
        uint8 tokenStandard;
        uint valueSender; //this is number of tokens (ERC20) or tokenID (ERC721), or Eth (amount in Wei)
        address tokenContractAddress;
        uint lockTimeOut;
        bool completed;
        
    }

    
    modifier swapLive(string memory swapOrderId){
        if (listOfEscrowOrders[swapOrderId].completed == true){
            revert("This swapOrder has already been fulfilled");
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
    function createEscrowOrder(string calldata escrowId, address payable receiver, bytes32 hash, uint sendersTokens, uint8 tokenStandard,  address tokenContract, uint lockTimeOut) payable external maximumSwapOrderIdCheck(){
        
            if ((tokenStandard >= uint8(TokenStandard.NativeSub) + 1)){
                revert("At least one of the TokenStandards are out of bounds.");
            }
        //check sender has approved these specific number of tokens to THIS CONTRACTS Address.
            //go to sendersTokenContract
            //look up allowance for THIS Address
            if ((tokenStandard == uint(TokenStandard.NativeMain))||(tokenStandard == uint(TokenStandard.NativeSub))){
                
            } else {
                if(sendersTokens >= allowanceCheck(msg.sender, tokenContract, TokenStandard.ERC20)){
                    revert("The sender has not sent this contract enough ERC-20 tokens to be able to complete the transfer");
                }
                
            }
            
            //check balance equals or exceeds sendersTokens
                //add to storage by creating a new swap orgSendersTokenContract
                //SwapOrder memory latestSwapOrder;
                listOfEscrowOrders[escrowId].initialSender = msg.sender;
                listOfEscrowOrders[escrowId].initialReceiver = receiver;
                listOfEscrowOrders[escrowId].hash = hash;
                listOfEscrowOrders[escrowId].tokenStandard = tokenStandard;
                if ((tokenStandard == uint8(TokenStandard.NativeMain))||(tokenStandard == uint8(TokenStandard.NativeSub))){
                    listOfEscrowOrders[escrowId].valueSender = msg.value;
                } else {
                    listOfEscrowOrders[escrowId].valueSender = sendersTokens;
                }
                listOfEscrowOrders[escrowId].lockTimeOut = block.timestamp + lockTimeOut;

                swapOrderCounter++;
                //emit event and  record  new ID
                //emit newSwapOrder(msg.sender, senderAddressOnOtherDL, otherDLName, sendersTokens, receiversTokensRequired, thisDLsTokenContract, receiversTokenContract, lockTimeOut, swapOrderCounter-1);
                if ((tokenStandard != uint(TokenStandard.NativeMain))&&(tokenStandard != uint(TokenStandard.NativeSub))){
                    //if a token is to be sent, take it now 
                    holdInEscrow(msg.sender, tokenContract, tokenStandard, sendersTokens);
                }
                
    }
    
    function withdrawTokenAfterLock(string memory escrowId) internal {
        
        //check sender is the sender of this swap order and lock has expired (so the swap can be cancelled)
        EscrowSwapOrder storage thisEscrowOrder = listOfEscrowOrders[escrowId];
        if (msg.sender != thisEscrowOrder.initialSender){
            revert("Sender of message needs to be the same as the sender of the swapOrder");
        } else if (block.timestamp <= thisEscrowOrder.lockTimeOut){
            revert("The lock of the swapOrder has not yet expired");
        }
        
        //release the lock
        thisEscrowOrder.completed = true;
        finaliseSwap(thisEscrowOrder.initialSender, thisEscrowOrder.tokenContractAddress, thisEscrowOrder.tokenStandard, thisEscrowOrder.valueSender); 
        
    }
    
    function closeEscrowOrder(string calldata escrowId, string calldata hashInput) external payable maximumSwapOrderIdCheck(){
        
        if (bytes(hashInput).length == 0){
            withdrawTokenAfterLock(escrowId);
        } else {
                   //msg.sender can be either party of the swap
            EscrowSwapOrder storage thisEscrowOrder = listOfEscrowOrders[escrowId];
            if ((msg.sender != thisEscrowOrder.initialSender)&&(msg.sender != thisEscrowOrder.initialReceiver)){
                revert("Sender of message needs to be either the sender or receiver of the swapOrder");
            } else if (thisEscrowOrder.completed == true){
                revert("The swapOrder has already completed");            
            } else if (block.timestamp > thisEscrowOrder.lockTimeOut){
                revert("The swapOrder cannot be completed as it has expired");
            }
            //check that the hash input is correct
            bytes32 hashOutput = sha256(abi.encodePacked(hashInput));
            if (hashOutput == thisEscrowOrder.hash){
                //release the lock
                thisEscrowOrder.completed = true;
                thisEscrowOrder.secret = hashInput;
                finaliseSwap(thisEscrowOrder.initialReceiver, thisEscrowOrder.tokenContractAddress, thisEscrowOrder.tokenStandard, thisEscrowOrder.valueSender); 
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
    function getEscrowSender (string calldata escrowId) external view returns(address){
        return listOfEscrowOrders[escrowId].initialSender;
    }
    
    function getEscrowReceiver (string calldata escrowId) external view returns(address){
        return listOfEscrowOrders[escrowId].initialReceiver;
    }
    
    function getEscrowHash (string calldata escrowId) external view returns(bytes32){
        return listOfEscrowOrders[escrowId].hash;
    }
    
    function getEscrowHashAsUint (string calldata escrowId) external view returns(uint256){
        return uint(listOfEscrowOrders[escrowId].hash);
    }
    
    function getEscrowSenderValue (string calldata escrowId) external view returns(uint){
        return listOfEscrowOrders[escrowId].valueSender;
    }
    
    function getEscrowSenderContractAddress (string calldata escrowId) external view returns(address){
        return listOfEscrowOrders[escrowId].tokenContractAddress;
    }
    
    function getEscrowLockTimeOut (string calldata escrowId) external view returns(uint){
        return listOfEscrowOrders[escrowId].lockTimeOut;
    }    
    
    function getEscrowCompleted (string calldata escrowId) external view returns(bool){
        return listOfEscrowOrders[escrowId].completed;
    }
    
    function getEscrowSecret (string calldata escrowId) external view returns(string memory){
        return listOfEscrowOrders[escrowId].secret;
    }

    
}