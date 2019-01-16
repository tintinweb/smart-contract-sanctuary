pragma solidity ^0.4.24;


/**
 * here we define the ABI fingerprints of the functions of the contact of Token1,
 * which we wish to access in our contract
 * 
 * this needs to be done for every token,
 * which we want to integrate in our contract
 */
contract Token1{
    /**
     * for every function that we want to access,
     * we define it&#39;s respective ABI fingerprint.
     */
    function balanceOf(address) public view returns (uint256) {}
    function transferFrom(address, address, uint256) pure public returns (bool) {}
    function decimals() public pure returns(uint256);
}


/**
 * for any additional tokens to be integrated,
 * their ABI fingerprints need to be defined here
 */

/**
 * our EquityUp smart contract
 */
contract EquityUpContract{
    //address store_address = address(this);
    
    /**
     * creating an instance of Token1 in our contract
     * 
     * we will be accessing Token1s&#39; functions through this instance
     */
    Token1 fc1;
    
    
    /**
     * For additional tokens,
     * their instances are to be created here
     */
    
    /**
     * Constructor function
     *
     * Instantiates the token instances at the time of deployment of our contract
     * 
     * &#39;deployed_token_contract_addresss&#39; stores the contract addresses of the tokens we intend to integrate
     */
    constructor(address[1] memory deployed_token_contract_addresss) public{
        
        /**
         * Instantiating token1 instance with it&#39;s deployed contract address.
         */
        fc1 = Token1(deployed_token_contract_addresss[0]);
        
        /**
         * If additional token instances are present,
         * they need to be instantiated here.
         */
    }
    
    function getBalance1(address target_address) public view returns(uint){
        return fc1.balanceOf(target_address)  ;
    }  
    

   /**   
    * EquityUps&#39; own pool of tokens.
    * Not currently required
   
    // Create contracts&#39; own pool of tokens to handle transactions
    function transfer_token1_toContract(address _from, address _to, uint256 _amount) public returns(bool){
        uint256 no_of_token1_totransfer = _amount * (10**fc1.decimals());
        return fc1.transferFrom(_from, _to, no_of_token1_totransfer);
    }
    
    function transfer_token2_toContract(address _from, address _to, uint256 _amount) public returns(bool){
        uint256 no_of_token2_totransfer = _amount * (10**fc2.decimals());
        return fc2.transferFrom(_from, _to, no_of_token2_totransfer);
    }
    */

    
    /**
     * modified transaction function for token1
     * 
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transact_token1(address _from, address _to, uint256 _value) public{
        uint256 tokens_to_transact = _value * (10**fc1.decimals());
        
        /**
         * Calling transferFrom of Token1
         * 
         * &#39;_to&#39; must have approval for transaction to happen
         * <require(_value <= allowance[_from][msg.sender])> should be true
         */
        fc1.transferFrom(_from, _to, tokens_to_transact);
    }
    
}