pragma solidity ^0.4.20;

/*
 * @FadyAro 15 Aug 2018
 *
 * Private Personal Bet
 */
contract PrivateBet {

    /*
     * subscription event
     */ 
    event NewBet(address indexed _address);
    
    /*
     * subscription status
     */ 
    uint8 private paused = 0;

    /*
     * subscription price
     */ 
    uint private price;
    
    /*
     * subscription code
     */ 
    bytes16 private name;
    
    /*
     * contract owner
     */ 
    address private owner;

    /*
     * subscribed users
     */ 
    address[] public users;
    
    /*
     * bet parameters
     */
    constructor(bytes16 _name, uint _price) public {
        owner = msg.sender;
        name = _name;
        price = _price;
    }
    
    /*
     * fallback subscription logic
     */
    function() public payable {
        
        /*
         * only when contract is active
         */
        require(paused == 0, &#39;paused&#39;);
        
        /*
         * smart contracts are not allowed to participate
         */
        require(tx.origin == msg.sender, &#39;not allowed&#39;);
        
        /*
         * only when contract is active
         */
        require(msg.value >= price, &#39;low amount&#39;);

        /*
         * subscribe the user
         */
        users.push(msg.sender);
        
        /*
         * log the event
         */
        emit NewBet(msg.sender);
         
         /*
          * collect the ETH
          */
        owner.transfer(msg.value);
    }
    
    /*
     * bet details
     */
    function details() public view returns (
        address _owner
        , bytes16 _name 
        , uint _price 
        , uint _total
        , uint _paused
        ) {
        return (
            owner
            , name
            , price
            , users.length
            , paused
        );
    }
    
    /*
     * pause the subscriptions
     */
    function pause() public {
        
        require(msg.sender == owner, &#39;not allowed&#39;);
        
        paused = 1;
    }
}