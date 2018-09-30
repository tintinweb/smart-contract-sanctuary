pragma solidity 0.4.25;

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/// @title Intel contract
/// @author Pareto Admin
/// @notice Intel, A contract for creating, rewarding and distributing Intels
contract Intel{
    
    using SafeMath for uint256;
    
    struct IntelState {
        address intelProvider;
        uint depositAmount;
        uint desiredReward;
        // total balance of Pareto tokens given for this intel
        // including the intel provider’s deposit
        uint balance;
        uint intelID;
        // timestamp for when rewards can be collected
        uint rewardAfter;
        // flag indicating whether the rewards have been collected
        bool rewarded;
                // stores how many Pareto tokens were given for this intel
        // in case you want to enforce a max amount per contributor
        address[] contributionsList;
        mapping(address => uint) contributions;

    }


    mapping(uint => IntelState) intelDB;
    mapping(address => IntelState[]) public IntelsByProvider;
    uint[] intelIndexes;
    
    uint public intelCount;
    

    address public owner;    // Storage variable to hold the address of owner
    
    ERC20 public token;   // Storage variable of type ERC20 to hold Pareto token&#39;s address
    address public ParetoAddress;

    
    constructor(address _owner, address _token) public {
        owner = _owner;  // owner is a Pareto wallet which should be able to perform admin functions
        token = ERC20(_token);
        ParetoAddress = _token;
    }
    

    // modifier to check of the sender of transaction is the owner
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    

    event Reward( address sender, uint intelIndex, uint rewardAmount);
    event NewIntel(address intelProvider, uint depositAmount, uint desiredReward, uint intelID, uint ttl);
    event RewardDistributed(uint intelIndex, uint provider_amount, address provider, address distributor, uint distributor_amount);
    event LogProxy(address destination, address account, uint amount, uint gasLimit);
    

    /// @author Pareto Admin
    /// @notice this function creates an Intel
    /// @dev Uses &#39;now&#39; for timestamps.
    /// @param intelProvider is the address of the Intel&#39;s provider
    /// @param depositAmount is the amount of Pareto tokens deposited by provider
    /// @param desiredReward is the amount of Pareto tokens desired by provider as reward
    /// @param intelID is the ID of Intel which is mapped against an Intel in IntelDB as well as the database external to Ethereum
    /// @param ttl is the time in EPOCH format until the Intel remains active and accepts rewards
    /// requires 210769 gas in Rinkeby Network
    function create(address intelProvider, uint depositAmount, uint desiredReward, uint intelID, uint ttl) public {

        require(address(intelProvider) != address(0x0));
        require(depositAmount > 0);
        require(desiredReward > 0);
        require(ttl > now);
        
        token.transferFrom(intelProvider, address(this), depositAmount);  // transfer token from caller to Intel contract
        
        address[] memory contributionsList;
        IntelState memory newIntel = IntelState(intelProvider, depositAmount, desiredReward, depositAmount, intelID, ttl, false, contributionsList);
        intelDB[intelID] = newIntel;
        IntelsByProvider[intelProvider].push(newIntel);

        intelIndexes.push(intelID);
        intelCount++;
        

        emit NewIntel(intelProvider, depositAmount, desiredReward, intelID, ttl);
        
    }
    

    /// @author Pareto Admin
    /// @notice this function sends rewards to the Intel
    /// @dev Uses &#39;now&#39; for timestamps.
    /// @param intelIndex is the ID of the Intel to send the rewards to
    /// @param rewardAmount is the amount of Pareto tokens the rewarder wants to reward to the Intel
    /// @return returns true in case of successfull completion
    /// requires 72283 gas on Rinkeby Network
    function sendReward(uint intelIndex, uint rewardAmount) public returns(bool success){

        IntelState storage intel = intelDB[intelIndex];
        require(intel.intelProvider != address(0x0));  // make sure that Intel exists
        require(msg.sender != intel.intelProvider); // rewarding address should not be an intel address
        require(intel.rewardAfter > now);       //You cannot reward intel if the timestamp of the transaction is greater than rewardAfter
        require(!intel.rewarded);  // You cannot reward intel if the intel’s rewards have already been distributed
        

        token.transferFrom(msg.sender, address(this), rewardAmount);  // transfer token from caller to Intel contract
        intel.balance = intel.balance.add(rewardAmount);

        if(intel.contributions[msg.sender] == 0){
            intel.contributionsList.push(msg.sender);
        }
        
        intel.contributions[msg.sender] = intel.contributions[msg.sender].add(rewardAmount);
        

        emit Reward(msg.sender, intelIndex, rewardAmount);


        return true;

    }
    

    /// @author Pareto Admin
    /// @notice this function distributes rewards to the Intel provider
    /// @dev Uses &#39;now&#39; for timestamps.
    /// @param intelIndex is the ID of the Intel to distribute tokens to
    /// @return returns true in case of successfull completion
    /// requires 91837 gas on Rinkeby Network
    function distributeReward(uint intelIndex) public returns(bool success){

        require(intelIndex > 0);
        

        IntelState storage intel = intelDB[intelIndex];
        
        require(!intel.rewarded);
        require(now >= intel.rewardAfter);
        

        intel.rewarded = true;
        uint distributed_amount = 0;

       


        if (intel.balance > intel.desiredReward){         // check if the Intel&#39;s balance is greater than the reward desired by Provider
            distributed_amount = intel.desiredReward;    // tarnsfer tokens to the provider&#39;s address equal to the desired reward

        } else {
            distributed_amount = intel.balance;  // transfer token to the provider&#39;s address equal to Intel&#39;s balance
        }

        uint fee = distributed_amount.div(10);    // calculate 10% as the fee for distribution
        distributed_amount = distributed_amount.sub(fee);   // calculate final distribution amount

        token.transfer(intel.intelProvider, distributed_amount); // send Intel tokens to providers
        token.transfer(msg.sender, fee);                     // send Intel tokens to the caller of distribute reward function
        emit RewardDistributed(intelIndex, distributed_amount, intel.intelProvider, msg.sender, fee);


        return true;

    }
    
    /// @author Pareto Admin
    /// @notice this function sets the address of Pareto Token
    /// @dev only owner can call it
    /// @param _token is the Pareto token address
    /// requires 63767 gas on Rinkeby Network
    function setParetoToken(address _token) public onlyOwner{

        token = ERC20(_token);
        ParetoAddress = _token;

    }
    

    /// @author Pareto Admin
    /// @notice this function sends back the mistankenly sent non-Pareto ERC20 tokens
    /// @dev only owner can call it
    /// @param destination is the contract address where the tokens were received from mistakenly
    /// @param account is the external account&#39;s address which sent the wrong tokens
    /// @param amount is the amount of tokens sent
    /// @param gasLimit is the amount of gas to be sent along with external contract&#39;s transfer call
    /// requires 27431 gas on Rinkeby Network
    function proxy(address destination, address account, uint amount, uint gasLimit) public onlyOwner{

        require(destination != ParetoAddress);    // check that the destination is not the Pareto token contract

        // make the call to transfer function of the &#39;destination&#39; contract
        // if(!address(destination).call.gas(gasLimit)(bytes4(keccak256("transfer(address,uint256)")),account, amount)){
        //     revert();
        // }


        // ERC20(destination).transfer(account,amount);


        bytes4  sig = bytes4(keccak256("transfer(address,uint256)"));

        assembly {
            let x := mload(0x40) //Find empty storage location using "free memory pointer"
        mstore(x,sig) //Place signature at begining of empty storage 
        mstore(add(x,0x04),account)
        mstore(add(x,0x24),amount)

        let success := call(      //This is the critical change (Pop the top stack value)
                            gasLimit, //5k gas
                            destination, //To addr
                            0,    //No value
                            x,    //Inputs are stored at location x
                            0x44, //Inputs are 68 bytes long
                            x,    //Store output over input (saves space)
                            0x0) //Outputs are 32 bytes long

        // Check return value and jump to bad destination if zero
		jumpi(0x02,iszero(success))

        }
        emit LogProxy(destination, account, amount, gasLimit);
    }

    /// @author Pareto Admin
    /// @notice It&#39;s a fallback function supposed to return sent Ethers by reverting the transaction
    function() external{
        revert();
    }

    /// @author Pareto Admin
    /// @notice this function provide the Intel based on its index
    /// @dev it&#39;s a constant function which can be called
    /// @param intelIndex is the ID of Intel that is to be returned from intelDB
    function getIntel(uint intelIndex) public view returns(address intelProvider, uint depositAmount, uint desiredReward, uint balance, uint intelID, uint rewardAfter, bool rewarded) {
        
        IntelState storage intel = intelDB[intelIndex];
        intelProvider = intel.intelProvider;
        depositAmount = intel.depositAmount;
        desiredReward = intel.desiredReward;
        balance = intel.balance;
        rewardAfter = intel.rewardAfter;
        intelID = intel.intelID;
        rewarded = intel.rewarded;

    }

    function getAllIntel() public view returns (uint[] intelID, address[] intelProvider, uint[] depositAmount, uint[] desiredReward, uint[] balance, uint[] rewardAfter, bool[] rewarded){
        
        uint length = intelIndexes.length;
        intelID = new uint[](length);
        intelProvider = new address[](length);
        depositAmount = new uint[](length);
        desiredReward = new uint[](length);
        balance = new uint[](length);
        rewardAfter = new uint[](length);
        rewarded = new bool[](length);

        for(uint i = 0; i < intelIndexes.length; i++){
            intelID[i] = intelDB[intelIndexes[i]].intelID;
            intelProvider[i] = intelDB[intelIndexes[i]].intelProvider;
            depositAmount[i] = intelDB[intelIndexes[i]].depositAmount;
            desiredReward[i] = intelDB[intelIndexes[i]].desiredReward;
            balance[i] = intelDB[intelIndexes[i]].balance;
            rewardAfter[i] = intelDB[intelIndexes[i]].rewardAfter;
            rewarded[i] = intelDB[intelIndexes[i]].rewarded;
        }
    }


      function getIntelsByProvider(address _provider) public view returns (uint[] intelID, address[] intelProvider, uint[] depositAmount, uint[] desiredReward, uint[] balance, uint[] rewardAfter, bool[] rewarded){
        
        uint length = IntelsByProvider[_provider].length;

        intelID = new uint[](length);
        intelProvider = new address[](length);
        depositAmount = new uint[](length);
        desiredReward = new uint[](length);
        balance = new uint[](length);
        rewardAfter = new uint[](length);
        rewarded = new bool[](length);

        IntelState[] memory intels = IntelsByProvider[_provider];

        for(uint i = 0; i < length; i++){
            intelID[i] = intels[i].intelID;
            intelProvider[i] = intels[i].intelProvider;
            depositAmount[i] = intels[i].depositAmount;
            desiredReward[i] = intels[i].desiredReward;
            balance[i] = intels[i].balance;
            rewardAfter[i] = intels[i].rewardAfter;
            rewarded[i] = intels[i].rewarded;
        }
    }

    function contributionsByIntel(uint intelIndex) public view returns(address[] addresses, uint[] amounts){
        IntelState storage intel = intelDB[intelIndex];
                
        uint length = intel.contributionsList.length;

        addresses = new address[](length);
        amounts = new uint[](length);

        for(uint i = 0; i < length; i++){
            addresses[i] = intel.contributionsList[i]; 
            amounts[i] = intel.contributions[intel.contributionsList[i]];       
        }

    }

}