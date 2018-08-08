pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface token {
    function mint(address _to, uint256 _amount) public returns (bool);     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function transferOwnership(address newOwner) public;
    
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable() public {
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
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale {
    using SafeMath for uint256;

    // The token being sold
    token public tokenReward;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _token) public {
        //require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));

        // token = createTokenContract();
        tokenReward = token(_token);
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

    // creates the token to be sold.
    // override this method to have crowdsale of a specific mintable token.
    // function createTokenContract() internal returns (MintableToken) {
    //     return new MintableToken();
    // }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }


}

/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}


/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract&#39;s finalization function.
    */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
    function finalization() internal {
    }
}
/**
 * @title RefundableCrowdsale
 * @dev Extension of Crowdsale contract that adds a funding goal, and
 * the possibility of users getting a refund if goal is not met.
 * Uses a RefundVault as the crowdsale&#39;s vault.
 */
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

    // minimum amount of funds to be raised in weis
    uint256 public goal;

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;

    function RefundableCrowdsale(uint256 _goal) public {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

    // We&#39;re overriding the fund forwarding from Crowdsale.
    // In addition to sending the funds, we want to call
    // the RefundVault deposit function
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    // vault finalization task, called when owner calls finalize()
    function finalization() internal {
        if (!goalReached()) {
            vault.enableRefunds(); 
        } 

        super.finalization();
    }

    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }

}

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;

    function CappedCrowdsale(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }


    // overriding Crowdsale#hasEnded to add cap logic
    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        bool capReached = weiRaised >= cap;
        return super.hasEnded() || capReached;
    }

}

contract ControlledAccess is Ownable {
    address public signer;
    event SignerTransferred(address indexed previousSigner, address indexed newSigner);

     /**
    * @dev Throws if called by any account other than the signer.
    */
    modifier onlySigner() {
        require(msg.sender == signer);
        _;
    }
    /**
    * @dev Allows the current owner to transfer the signer of the contract to a newSigner.
    * @param newSigner The address to transfer signership to.
    */

    function transferSigner(address newSigner) public onlyOwner {
        require(newSigner != address(0));
        emit SignerTransferred(signer, newSigner);
        signer = newSigner;
    }
    
   /* 
    * @dev Requires msg.sender to have valid access message.
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    */
    modifier onlyValidAccess(uint8 _v, bytes32 _r, bytes32 _s) 
    {
        require(isValidAccessMessage(msg.sender,_v,_r,_s) );
        _;
    }
 
    /* 
    * @dev Verifies if message was signed by owner to give access to _add for this contract.
    *      Assumes Geth signature prefix.
    * @param _add Address of agent with access
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    * @return Validity of access message for a given address.
    */
    function isValidAccessMessage(
        address _add,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s) 
        view public returns (bool)
    {
        bytes32 hash = keccak256(this, _add);
        return signer == ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            _v,
            _r,
            _s
        );
    }
}

contract ElepigCrowdsale is CappedCrowdsale, RefundableCrowdsale, ControlledAccess {
    using SafeMath for uint256;
    
    // ICO Stage  
    // ============
    enum CrowdsaleStage { PreICO, ICO1, ICO2, ICO3, ICO4 } //Sale has pre-ico and 4 bonus rounds
    CrowdsaleStage public stage = CrowdsaleStage.PreICO; // By default stage is Pre ICO
    // =============

    address public community;    

  // Token Distribution
    // =============================
    // 150MM of Elepig are already minted. 
    uint256 public totalTokensForSale = 150000000000000000000000000;  // 150 EPGs will be sold in Crowdsale (50% of total tokens for community) 
    uint256 public totalTokensForSaleDuringPreICO = 30000000000000000000000000; // 30MM out of 150MM EPGs will be sold during Pre ICO
    uint256 public totalTokensForSaleDuringICO1 = 37500000000000000000000000;   // 37.5MM out of 150MM EPGs will be sold during Bonus Round 1
    uint256 public totalTokensForSaleDuringICO2 = 37500000000000000000000000;   // 37.5MM out of 150MM EPGs will be sold during Bonus Round 2
    uint256 public totalTokensForSaleDuringICO3 = 30000000000000000000000000;   // 30MM out of 150MM EPGs will be sold during Bonus Round 3
    uint256 public totalTokensForSaleDuringICO4 = 15000000000000000000000000;   // 15MM out of 150MM EPGs will be sold during Bonus Round 4
  // ==============================

    // Amount raised
    // ==================
    
    // store amount sold at each stage of sale
    uint256 public totalWeiRaisedDuringPreICO;
    uint256 public totalWeiRaisedDuringICO1;
    uint256 public totalWeiRaisedDuringICO2;
    uint256 public totalWeiRaisedDuringICO3;
    uint256 public totalWeiRaisedDuringICO4;
    uint256 public totalWeiRaised;


    // store amount sold at each stage of sale
    uint256 public totalTokensPreICO;
    uint256 public totalTokensICO1;
    uint256 public totalTokensICO2;
    uint256 public totalTokensICO3;
    uint256 public totalTokensICO4;
    uint256 public tokensMinted;
    

    uint256 public airDropsClaimed = 0;
    // ===================

    mapping (address => bool) public airdrops;
    mapping (address => bool) public blacklist;
    
    
    // Events
    event EthTransferred(string text);
    event EthRefunded(string text);
   


    // Constructor
    // ============
    function ElepigCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        uint256 _goal,
        uint256 _cap,
        address _communityAddress,
        address _token,
        address _signer
    ) 
    CappedCrowdsale(_cap) FinalizableCrowdsale() RefundableCrowdsale(_goal) Crowdsale( _startTime, _endTime,  _rate, _wallet, _token) public {
        require(_goal <= _cap);   // goal is softcap
        require(_signer != address(0));
        require(_communityAddress != address(0));
        require(_token != address(0));


        community = _communityAddress; // sets address of community wallet - address where tokens not sold will be minted
        signer = _signer; // sets original address of signer

        
    }
    

  // =========================================================
  // Crowdsale Stage Management
  // =========================================================

  // Change Crowdsale Stage. Available Options: PreICO, ICO1, ICO2, ICO3, ICO4
    function setCrowdsaleStage(uint value) public onlyOwner {
        require(value <= 4);
        if (uint(CrowdsaleStage.PreICO) == value) {
            rate = 2380; // 1 EPG = 0.00042 ETH
            stage = CrowdsaleStage.PreICO;
        } else if (uint(CrowdsaleStage.ICO1) == value) {
            rate = 2040; // 1 EPG = 0.00049 ETH
            stage = CrowdsaleStage.ICO1;
        }
        else if (uint(CrowdsaleStage.ICO2) == value) {
            rate = 1785; // 1 EPG = 0.00056 ETH
            stage = CrowdsaleStage.ICO2;
        }
        else if (uint(CrowdsaleStage.ICO3) == value) {
            rate = 1587; // 1 EPG = 0.00063 ETH
            stage = CrowdsaleStage.ICO3;
        }
        else if (uint(CrowdsaleStage.ICO4) == value) {
            rate = 1503; // 1 EPG = 0.000665 ETH
            stage = CrowdsaleStage.ICO4;
        }
    }


    // Change the current rate
    function setCurrentRate(uint256 _rate) private {
        rate = _rate;
    }    
    // ================ Stage Management Over =====================

    // ============================================================
    //                     Address Management 
    // ============================================================


    // adding an address to the blacklist, addresses on this list cannot send ETH to the contract     
    function addBlacklistAddress (address _address) public onlyOwner {
        blacklist[_address] = true;
    }
    
    // removing an address from the blacklist    
    function removeBlacklistAddress (address _address) public onlyOwner {
        blacklist[_address] = false;
    } 

    // ================= Address Management Over ==================


    // Token Purchase, function will be called when &#39;data&#39; is sent in 
    // FOR KYC
    function donate(uint8 _v, bytes32 _r, bytes32 _s) 
    onlyValidAccess(_v,_r,_s) public payable{
        require(msg.value >= 150000000000000000); // minimum limit - no max
        require(blacklist[msg.sender] == false); // require that the sender is not in the blacklist      
        
        require(validPurchase()); // after ico start date and not value of 0  
        
        uint256 tokensThatWillBeMintedAfterPurchase = msg.value.mul(rate);

        // if Pre-ICO sale limit is reached, refund sender
        if ((stage == CrowdsaleStage.PreICO) && (totalTokensPreICO + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringPreICO)) {
            msg.sender.transfer(msg.value); // Refund them
            emit EthRefunded("PreICO Limit Hit");
            return;
        } 
        if ((stage == CrowdsaleStage.ICO1) && (totalTokensICO1 + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringICO1)) {
            msg.sender.transfer(msg.value); // Refund them
            emit EthRefunded("ICO1 Limit Hit");
            return;

        }         
        if ((stage == CrowdsaleStage.ICO2) && (totalTokensICO2 + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringICO2)) {
            msg.sender.transfer(msg.value); // Refund them
            emit EthRefunded("ICO2 Limit Hit");
            return;

        }  
        if ((stage == CrowdsaleStage.ICO3) && (totalTokensICO3 + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringICO3)) {
            msg.sender.transfer(msg.value); // Refund them
            emit EthRefunded("ICO3 Limit Hit");
            return;        
        } 

        if ((stage == CrowdsaleStage.ICO4) && (totalTokensICO4 + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringICO4)) {
            msg.sender.transfer(msg.value); // Refund them
            emit EthRefunded("ICO4 Limit Hit");
            return;
        } else {                
            // calculate token amount to be created
            uint256 tokens = msg.value.mul(rate);
            weiRaised = weiRaised.add(msg.value);          

            // mint token
            tokenReward.mint(msg.sender, tokens);
            emit TokenPurchase(msg.sender, msg.sender, msg.value, tokens);
            forwardFunds();            
            // end of buy tokens

            if (stage == CrowdsaleStage.PreICO) {
                totalWeiRaisedDuringPreICO = totalWeiRaisedDuringPreICO.add(msg.value);
                totalTokensPreICO = totalTokensPreICO.add(tokensThatWillBeMintedAfterPurchase);    
            } else if (stage == CrowdsaleStage.ICO1) {
                totalWeiRaisedDuringICO1 = totalWeiRaisedDuringICO1.add(msg.value);
                totalTokensICO1 = totalTokensICO1.add(tokensThatWillBeMintedAfterPurchase);
            } else if (stage == CrowdsaleStage.ICO2) {
                totalWeiRaisedDuringICO2 = totalWeiRaisedDuringICO2.add(msg.value);
                totalTokensICO2 = totalTokensICO2.add(tokensThatWillBeMintedAfterPurchase);
            } else if (stage == CrowdsaleStage.ICO3) {
                totalWeiRaisedDuringICO3 = totalWeiRaisedDuringICO3.add(msg.value);
                totalTokensICO3 = totalTokensICO3.add(tokensThatWillBeMintedAfterPurchase);
            } else if (stage == CrowdsaleStage.ICO4) {
                totalWeiRaisedDuringICO4 = totalWeiRaisedDuringICO4.add(msg.value);
                totalTokensICO4 = totalTokensICO4.add(tokensThatWillBeMintedAfterPurchase);
            }

        }
        // update state
        tokensMinted = tokensMinted.add(tokensThatWillBeMintedAfterPurchase);      
        
    }

    // =========================
    function () external payable {
        revert();
    }

    function forwardFunds() internal {
        // if Wei raised greater than softcap, send to wallet else put in refund vault
        if (goalReached()) {
            wallet.transfer(msg.value);
            emit EthTransferred("forwarding funds to wallet");
        } else  {
            emit EthTransferred("forwarding funds to refundable vault");
            super.forwardFunds();
        }
    }
  
     /**
    * @dev perform a transfer of allocations (recommend doing in batches of 80 due to gas block limit)
    * @param _from is the address the tokens will come from
    * @param _recipient is a list of recipients
    * @param _premium is a bool of if the list of addresses are premium or not
    */
    function airdropTokens(address _from, address[] _recipient, bool _premium) public onlyOwner {
        uint airdropped;
        uint tokens;

        if(_premium == true) {
            tokens = 500000000000000000000;
        } else {
            tokens = 50000000000000000000;
        }

        for(uint256 i = 0; i < _recipient.length; i++)
        {
            if (!airdrops[_recipient[i]]) {
                airdrops[_recipient[i]] = true;
                require(tokenReward.transferFrom(_from, _recipient[i], tokens));
                airdropped = airdropped.add(tokens);
            }
        }
        
        airDropsClaimed = airDropsClaimed.add(airdropped);
    }

  // Finish: Mint Extra Tokens as needed before finalizing the Crowdsale.
  // ====================================================================

    function finish() public onlyOwner {

        require(!isFinalized);
        
        if(tokensMinted < totalTokensForSale) {

            uint256 unsoldTokens = totalTokensForSale - tokensMinted;            
            tokenReward.mint(community, unsoldTokens);
            
        }
             
        finalize();
    } 

    // if goal reached, manually close the vault
    function releaseVault() public onlyOwner {
        require(goalReached());
        vault.close();
    }

    // transfers ownership of contract back to wallet
    function transferTokenOwnership(address _newOwner) public onlyOwner {
        tokenReward.transferOwnership(_newOwner);
    }
  // ===============================

  
}