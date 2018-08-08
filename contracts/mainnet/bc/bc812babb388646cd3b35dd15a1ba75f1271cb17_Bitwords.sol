pragma solidity ^0.4.23;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  // transfer ownership event
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor () public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


/**
 * @title Bitwords 
 * 
 * @dev The Bitwords smart contract that allows advertisers and publishers to
 * safetly deposit/receive ether and interact with the Bitwords platform.
 */ 
contract Bitwords is Ownable {
    mapping(address => uint) public advertiserBalances;
    
    // The bitwords address, where all the 30% cut is received ETH
    address public bitwordsWithdrawlAddress = 0xe4eecf51618e1ec3c07837e8bee39f0a33d1eb2b;

    // How much cut out of 100 Bitwords takes. By default 30%
    uint public bitwordsCutOutof100 = 30;
      
    
    function() public payable {
        advertiserBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    
    /**
     * Used by the owner to set the withdrawal address.
     */
    function setBitwordsWithdrawlAddress (address newAddress) onlyOwner public {
        bitwordsWithdrawlAddress = newAddress;
    }
    
    
    /**
     * Change the cut that Bitwords takes.
     * @param cut   the amount of cut that Bitwords takes.
     */
    function setBitwordsCut (uint cut) onlyOwner public {
        require(cut <= 30, "cut cannot be more than 30%");
        bitwordsCutOutof100 = cut;
    }
    
    
    /**
     * Charge the advertiser with whatever clicks have been served by the ad engine.
     * 
     * @param advertiser    The address of the advertiser from whom we should debit ether
     * @param clicks        The number of clicks that has been served
     * @param cpc           The cost-per-click
     * @param publisher     The address of the publisher from whom we should credit ether
     * 
     * TODO: have the advertiser&#39;s signature also involved.
     */ 
    function chargeAdvertiser (address advertiser, uint clicks, uint cpc, address publisher) onlyOwner public {
        uint cost = clicks * cpc;
        
        // Bail if the advertiser does not have enough balance.
        if (advertiserBalances[advertiser] - cost <= 0) return;
        
        // Bail if bitwords takes more than a 30% cut.
        if (bitwordsCutOutof100 > 30) return;
        
        advertiserBalances[advertiser] -= cost;
        
        uint publisherCut = cost * (100 - bitwordsCutOutof100) / 100;
        uint bitwordsCut = cost - publisherCut;
        
        // Send the ether to the publisher and to Bitwords
        publisher.transfer(publisherCut);
        bitwordsWithdrawlAddress.transfer(bitwordsCut);
        
        // Emit events
        emit PayoutToPublisher(publisher, publisherCut);
        emit DeductFromAdvertiser(advertiser, cost);
    }
    
    
    /**
     * Called by an advertiser when he/she would like to get a refund.
     * 
     * @param amount    The amount the advertiser would like to withdraw
     */
    function refundAdveriser (uint amount) public {
        // Ensure that the advertiser has enough balance to refund the smart 
        // contract
        require(advertiserBalances[msg.sender] - amount >= 0, "Insufficient balance");
        
        // deduct balance and send the ether
        advertiserBalances[msg.sender] -= amount;
        msg.sender.transfer(amount);
        
        // Emit events
        emit RefundAdvertiser(msg.sender, amount);
    }
    
    /** Events */
    event Deposit(address indexed _from, uint _value);
    event DeductFromAdvertiser(address indexed _to, uint _value);
    event PayoutToPublisher(address indexed _to, uint _value);
    event RefundAdvertiser(address indexed _from, uint _value);
}