pragma solidity 0.5.17;

import "./ERC20Interface.sol";
import "./TreasuryBasev3.sol";
import "./TreasuryFactoryBasev3.sol";

/**
 * @author Quant Network
 * @title TreasuryFactoryv3
 * @dev Allows virtual payment channels to be easily created for gateways. Virtual in the sense that they are not a separate smart contract (which was the V1 design)
 * After V1.0 audit
 */
contract TreasuryFactoryv3 is TreasuryFactoryBasev3  {

            //**All variables are in the following format so there is no overiding of variables in the EVM
            //**Variables are prefixed with the upgrade version they first appear in
    // Hardcoded link to contracts:
    ERC20Interface private constant QNTContract = ERC20Interface(0x19Bc592A0E1BAb3AFFB1A8746D8454743EE6E838);
        //recomplie with the address of the deployed treasury added
    TreasuryBasev3 private constant t = TreasuryBasev3(0xdDc145e1ADfCeE9B13426c5FC716EeA04592A548); 
    
    //**payment channel events: 
     // The event fired when the payment channel's timeout variable is changed:
    event expirationChanged(address operatorAddress,uint256 expirationTime);
    // The event fired when the receiver has claimed some of the payment channel's balance:
    event QNTPaymentClaimed(address operatorAddress, uint256 claimedQNT, uint256 remainingQNT);
    // The event fired when the sender has re-claimed the remaining QNT after the payment channel has timed out:
    event QNTReclaimed(address operatorAddress,uint256 returnedQNT);

    
    /**
     * All functions with this modifier can only be called by the current treasury smart contract owner
     * of the contract
     */
    modifier onlyTreasuryOperator(){
        address operator = t.getOperatorAddress();
        if (msg.sender != operator){
            revert("Only treasury can call this");
        } else {
            _; // otherwise carry on with the computation
        }
    }
    
    /**
     * Adds a new gateway to the treasury and creates the virtual payment channel
     * @param gateway - is this stakeholder a gateway owner (true) or is the stakeholder a mDapp creator (false). Currently only accepts true.
     * @param newStakeholderQNTAddress - the Ethereum address associated to the stakeholder's (possibly cold) wallet
     * @param newStakeholderOperatorAddress - the Ethereum address associated to the stakeholder's operator address
     * @param QNTForPaymentChannel - The QNT for the payment channel that is to be taken from this contract's unlocked QNT 
     * @param expirationTime - when the payment channel will time out
     */
    function addNewPaymentChannel(bool gateway, address newStakeholderQNTAddress,  address newStakeholderOperatorAddress, uint256 QNTForPaymentChannel, uint256 expirationTime) external onlyTreasuryOperator() {
            //future upgrade MAY allow developers to have channels again
        require(gateway == true, "Currently only gateway channels can be created");
             //you can only add a new user if (s)he has not previously been added.
        require(getQNTAddress(newStakeholderOperatorAddress) == address(0x0),"User cannot be re-added"); //especially for a payment channel! Otherwise there maybe replay attacks (signed messages of the sender being used more than once)");
        //now to check that the requested additional funds are in the contract, so that we do not get accounting errors. 
        require(QNTContract.balanceOf(address(this)) - getTotalQNTlocked() >= QNTForPaymentChannel, "QNT funds are not available");
        //add payment channel
        createChannel(newStakeholderOperatorAddress, newStakeholderQNTAddress, expirationTime, QNTForPaymentChannel);
        setGatewayCount(getGatewayCount()+1);
        setCreationTime(newStakeholderOperatorAddress, block.timestamp);
        setTotalQNTlocked(getTotalQNTlocked()+QNTForPaymentChannel);

    }

    
    /**
     * Any user can send a payment through the payment channel (to the payment channel receiver's QNT address), 
     * if that user can produce a valid message from the sender authorising this payment 
     * @param operatorAddress - the operator address of the gateway owner of the payment channel
     * @param tokenAmount - the amount to claim
     * @param signedPayment - the signed payment message (which must include the above variables)
     */
     function claimQNTPayment(address operatorAddress, uint256 tokenAmount, bytes calldata signedPayment) external {
        require(block.timestamp < getExpiration(operatorAddress), "The channel has timed out");
        require(block.timestamp > getCreationTime(operatorAddress) + 7 days, "First claim must be over 7 days after creation");
        // Only the receiver's operator address can refund the channel:
        uint256 balance = getCurrentBalance(operatorAddress);
        require(tokenAmount <= balance,"Amount requested must be <= the current balance");            
        // the following recreates the message that was signed by the sender's operator address
        // the receiver's operator address is included so that payments from the treasury cannot be used on other channels
        // the receiver operator address must be unique (it indexes channels), but the receiver QNTaddress does not have to be unique
        bytes32 message = prefixed(keccak256(abi.encodePacked(operatorAddress, tokenAmount, getCurrentNonce(operatorAddress)))); 
        if(recoverSigner(message, signedPayment) != getSenderAddress(true)){
            revert("signedPayment is not valid for this channel");
        }
        // update the nonce so no replay attacks can occur
        setCurrentNonce(operatorAddress, getCurrentNonce(operatorAddress)+1);
        // transfer the QNT
        address receiverQNT = getReceiverAddress(operatorAddress,false);
        QNTContract.transfer(receiverQNT, tokenAmount); 
        //set the new balance
        setCurrentBalance(operatorAddress, balance-tokenAmount);
        setTotalQNTlocked(getTotalQNTlocked()-tokenAmount);
        // emit event
        emit QNTPaymentClaimed(operatorAddress,tokenAmount,balance-tokenAmount);
    }
    
    /**
     * Increases the expiry time of the channel
     * @param operatorAddress - the operator address of the gateway owner of the payment channel
     * @param newExpirationTime - the new expiration time
     */
    function updateExpirationTime(address operatorAddress, uint256 newExpirationTime) external {
        require(msg.sender == getSenderAddress(true), "Only the senders operator can increase the time");
        require(getExpiration(operatorAddress) < newExpirationTime, "You must increase the expiration time");
        setExpiration(operatorAddress,newExpirationTime);
        // emit event
        emit expirationChanged(operatorAddress,newExpirationTime);

    }
    
    /**
     * Allows the sender to reclaim QNT from the channel, if this channel has expired
     * @param operatorAddress - the operator address of the gateway owner of the payment channel
     * @param tokenAmount - the token amount to reclaim
     */
    function reclaimQNTfromPaymentChannel(address operatorAddress,uint256 tokenAmount) external {
      require(getCurrentBalance(operatorAddress) >= tokenAmount,"Balance is < than the requested amount");
      require(msg.sender == getSenderAddress(true), "Only the senders operator can reclaim the QNT");
      require(block.timestamp >= getExpiration(operatorAddress), "Expiration has not occurred");
        //transfer required amount back to the sender's QNT address
        QNTContract.transfer(getSenderAddress(false), tokenAmount);
        //set the new balance
        setCurrentBalance(operatorAddress, getCurrentBalance(operatorAddress)-tokenAmount);
        setTotalQNTlocked(getTotalQNTlocked()-tokenAmount);
        // Emit event
        emit QNTReclaimed(operatorAddress,tokenAmount);
    }
    
    /**
     * Allows the treasury to reclaim any QNT from this contract, if that QNT has never been moved into a payment channel (i.e. if this QNT is not currently locked)
     * @param tokenAmount - the token amount to reclaim
     */
    function reclaimUnlockedQNT(uint256 tokenAmount) external onlyTreasuryOperator() {
        require(QNTContract.balanceOf(address(this))-getTotalQNTlocked() >= tokenAmount,"Not that much QNT available");   
        //transfer required amount back to the sender's QNT address
        address treasuryQNTAddress = t.getQNTAddress();
        QNTContract.transfer(treasuryQNTAddress, tokenAmount);
        // Emit event
        emit QNTReclaimed(treasuryQNTAddress,tokenAmount);
    }

    /**
     * Allows the treasury to move approved QNT into the relevant payment channel
     * @param tokenAmount - the token amount to move into the payment channel
     * @param operatorAddress - the operator address of the gateway owner of the payment channel
     */    
    function addApprovedQNT(uint256 tokenAmount, address operatorAddress) external onlyTreasuryOperator() {
        //check paymentChannel exists
        address thisQNTAddress = getQNTAddress(operatorAddress);
        require(thisQNTAddress != address(0x0),"Payment channel does not exist"); 
        //check there is enough unlocked QNT in this contract
        require(QNTContract.balanceOf(address(this))-getTotalQNTlocked() >= tokenAmount,"QNT funds are not available"); 
        uint256 balance = getCurrentBalance(operatorAddress);
        require(balance+tokenAmount >= balance,"Underflow will occur");        
        //update balances (totalLocked & specific payment channel)
        setCurrentBalance(operatorAddress, balance+tokenAmount);
        setTotalQNTlocked(getTotalQNTlocked()+tokenAmount);
    }
    
    /**
     * Reads the receiver addresses of this channel
     * @param operatorAddress - the operator address of the gateway owner associated to this payment channel
     * @param operatorAddressReturned - should the operator address be returned (true) or the QNTAddress (false)
     * @return - the chosen receiver address
     */       
    function getReceiverAddress(address operatorAddress, bool operatorAddressReturned) public view returns (address) {
        if (operatorAddressReturned == true){
            return operatorAddress;                
        } else {
            return getQNTAddress(operatorAddress);
        }
    }
    
    /**
     * Reads the sender addresses of this payment channel 
     * @param operatorAddressReturned - should the operator address be returned (true) or the QNTAddress (false)
     * @return - the chosen sender address
     */        
    function getSenderAddress(bool operatorAddressReturned) public view returns (address) {
        //note that this code allows the treasury's current operator and QNT address to be connected to the channel
        if (operatorAddressReturned == true){
            return t.getOperatorAddress();
        } else {
            return t.getQNTAddress();
        }
    }

    /**
     * Finds the signer of a message
     * @param message - the message
     * @param sig - the signed bytes
     * @return - the address of the signer
     */
    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }
    
    /**
     * Finds the v, r and s value of the signature
     * @param sig - the signed bytes
     * @return - the v, r and s values
     */
    function splitSignature(bytes memory sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    /**
     * builds a prefixed hash to mimic the behavior of eth_sign.
     * @param hash - the hash of the message
     * @return - hash of the message mimicing the signing
     */
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
    
    /**
     * return the address of the treasury 
     * 
     */
    function getTreasuryAddress() public pure returns  (address){
        return address(t);
    }
    
    /**
     * @param evaluatingAddress - is this address an admin? Currently not used, will be used in a future multi-sig upgrade
    * @return - the admin of the proxy. Only the admin address can upgrade the smart contract logic
    */
    function getAdmin(address evaluatingAddress) public view returns (address) {
        return t.getAdmin(msg.sender);   
    }
      
    /**
    * @return - the number of hours wait time for any critical update
    */        
    function getSpeedBumpHours() public view returns (uint16){
        return t.getSpeedBumpHours();
    }

}