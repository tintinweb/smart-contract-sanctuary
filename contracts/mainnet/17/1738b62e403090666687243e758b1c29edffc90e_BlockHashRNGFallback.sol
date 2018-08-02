contract RNG{

    /** @dev Contribute to the reward of a random number.
     *  @param _block Block the random number is linked to.
     */
    function contribute(uint _block) public payable;

    /** @dev Request a random number.
     *  @param _block Block linked to the request.
     */
    function requestRN(uint _block) public payable {
        contribute(_block);
    }

    /** @dev Get the random number.
     *  @param _block Block the random number is linked to.
     *  @return RN Random Number. If the number is not ready or has not been required 0 instead.
     */
    function getRN(uint _block) public returns (uint RN);

    /** @dev Get a uncorrelated random number. Act like getRN but give a different number for each sender.
     *  This is to prevent users from getting correlated numbers.
     *  @param _block Block the random number is linked to.
     *  @return RN Random Number. If the number is not ready or has not been required 0 instead.
     */
    function getUncorrelatedRN(uint _block) public returns (uint RN) {
        uint baseRN=getRN(_block);
        if (baseRN==0)
            return 0;
        else
            return uint(keccak256(msg.sender,baseRN));
    }

 }

/** Simple Random Number Generator returning the blockhash.
 *  Allows saving the random number for use in the future.
 *  It allows the contract to still access the blockhash even after 256 blocks.
 *  The first party to call the save function gets the reward.
 */
contract BlockHashRNG is RNG {

    mapping (uint => uint) public randomNumber; // randomNumber[block] is the random number for this block, 0 otherwise.
    mapping (uint => uint) public reward; // reward[block] is the amount to be paid to the party w.



    /** @dev Contribute to the reward of a random number.
     *  @param _block Block the random number is linked to.
     */
    function contribute(uint _block) public payable { reward[_block]+=msg.value; }


    /** @dev Return the random number. If it has not been saved and is still computable compute it.
     *  @param _block Block the random number is linked to.
     *  @return RN Random Number. If the number is not ready or has not been requested 0 instead.
     */
    function getRN(uint _block) public returns (uint RN) {
        RN=randomNumber[_block];
        if (RN==0){
            saveRN(_block);
            return randomNumber[_block];
        }
        else
            return RN;
    }

    /** @dev Save the random number for this blockhash and give the reward to the caller.
     *  @param _block Block the random number is linked to.
     */
    function saveRN(uint _block) public {
        if (blockhash(_block) != 0x0)
            randomNumber[_block] = uint(blockhash(_block));
        if (randomNumber[_block] != 0) { // If the number is set.
            uint rewardToSend = reward[_block];
            reward[_block] = 0;
            msg.sender.send(rewardToSend); // Note that the use of send is on purpose as we don&#39;t want to block in case msg.sender has a fallback issue.
        }
    }

}


/** Random Number Generator returning the blockhash with a backup behaviour.
 *  Allows saving the random number for use in the future. 
 *  It allows the contract to still access the blockhash even after 256 blocks.
 *  The first party to call the save function gets the reward.
 *  If no one calls the contract within 256 blocks, the contract fallback in returning the blockhash of the previous block.
 */
contract BlockHashRNGFallback is BlockHashRNG {
    
    /** @dev Save the random number for this blockhash and give the reward to the caller.
     *  @param _block Block the random number is linked to.
     */
    function saveRN(uint _block) public {
        if (_block<block.number && randomNumber[_block]==0) {// If the random number is not already set and can be.
            if (blockhash(_block)!=0x0) // Normal case.
                randomNumber[_block]=uint(blockhash(_block));
            else // The contract was not called in time. Fallback to returning previous blockhash.
                randomNumber[_block]=uint(blockhash(block.number-1));
        }
        if (randomNumber[_block] != 0) { // If the random number is set.
            uint rewardToSend=reward[_block];
            reward[_block]=0;
            msg.sender.send(rewardToSend); // Note that the use of send is on purpose as we don&#39;t want to block in case the msg.sender has a fallback issue.
        }
    }
    
}