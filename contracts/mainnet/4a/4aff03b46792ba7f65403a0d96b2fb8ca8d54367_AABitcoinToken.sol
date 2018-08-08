pragma solidity ^0.4.18;

// To fix the original Skorch token contract a snapshot was taken at block 5772500. Snapshot is applied here 

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

library ExtendedMath {
    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
}

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract Owned {

    address public owner;

    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract AABitcoinToken is ERC20Interface, Owned {

    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;
    uint public latestDifficultyPeriodStarted;
    uint public epochCount;
    uint public _BLOCKS_PER_READJUSTMENT = 1024;

    uint public  _MINIMUM_TARGET = 2**16;

    uint public  _MAXIMUM_TARGET = 2**234;

    uint public miningTarget;

    bytes32 public challengeNumber;   //generate a new one when a new reward is minted

    uint public rewardEra;
    uint public maxSupplyForEra;

    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;

    bool locked = false;

    mapping(bytes32 => bytes32) solutionForChallenge;

    uint public tokensMinted;
    
    uint internal GLOBAL_START_TIMER;

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;
    
    mapping(address => uint256) timer; // timer to check PoS 
    
    // how to calculate doubleUnit: 
    // specify how much percent increase you want per year 
    // e.g. 130% -> 2.3 multiplier every year 
    // now divide (1 years) by LOG(2.3) where LOG is the natural logarithm (not LOG10)
    // in this case LOG(2.3) is 0.83290912293
    // hence multiplying by 1/0.83290912293 is the same 
    // 31536000 = 1 years (to prevent deprecated warning in solc)
    uint256 doubleUnit = (31536000) * 3.811;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
    event PoS(address indexed from, uint reward_amount);

    constructor()
        public 
        onlyOwner()
    {
        symbol = "SKO";
        name = "Skorch Token";
        decimals = 8;
        // uncomment this to test 
        //balances[msg.sender] = (20000) * (10 ** uint(decimals)); // change 20000 to some lower number than 20000 
        //to see you will not get PoS tokens if you have less than 20000 tokens 
        //timer[msg.sender] = now - (1 years);
        _totalSupply = 21000000 * 10**uint(decimals);
        if(locked) revert();
        locked = true;
        tokensMinted = 0;
        rewardEra = 0;
        maxSupplyForEra = _totalSupply.div(2);
        miningTarget = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;
        //_startNewMiningEpoch(); all relevant vars are set below
        GLOBAL_START_TIMER = now;
        challengeNumber = 0x85d676fa25011d060e3c7405f6e55de1921372c788bfaaed75c00b63a63c510d;
        epochCount = 6231;
        rewardEra = 0;
        maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));
        miningTarget = 431359146674410236714672241392314090778194310760649159697657763988184;
        
        // token balances as of block 5772500
balances[0xbf45f4280cfbe7c2d2515a7d984b8c71c15e82b7] = 2000 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xbf45f4280cfbe7c2d2515a7d984b8c71c15e82b7, 2000 * 10 ** uint(decimals));
balances[0xb38094d492af4fffff760707f36869713bfb2250] = 20050 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xb38094d492af4fffff760707f36869713bfb2250, 20050 * 10 ** uint(decimals));
balances[0x8f3dd21c9334980030ba95c37565ba25df9574cd] = 200 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x8f3dd21c9334980030ba95c37565ba25df9574cd, 200 * 10 ** uint(decimals));
balances[0xaa7a7c2decb180f68f11e975e6d92b5dc06083a6] = 1150 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xaa7a7c2decb180f68f11e975e6d92b5dc06083a6, 1150 * 10 ** uint(decimals));
balances[0x07a68bd44a526e09b8dbfc7085b265450362b61a] = 1000 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x07a68bd44a526e09b8dbfc7085b265450362b61a, 1000 * 10 ** uint(decimals));
balances[0x4e27a678c8dc883035c542c83124e7e3f39842b0] = 350 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x4e27a678c8dc883035c542c83124e7e3f39842b0, 350 * 10 ** uint(decimals));
balances[0x0102f6ca7278e7d96a6d649da30bfe07e87155a3] = 2800 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x0102f6ca7278e7d96a6d649da30bfe07e87155a3, 2800 * 10 ** uint(decimals));
balances[0xfc313f77c2cbc6cd0dd82b9a0ed1620ba906e46d] = 1900 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xfc313f77c2cbc6cd0dd82b9a0ed1620ba906e46d, 1900 * 10 ** uint(decimals));
balances[0xfec55e783595682141c4b5e6ad9ea605f1683844] = 100 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xfec55e783595682141c4b5e6ad9ea605f1683844, 100 * 10 ** uint(decimals));
balances[0x167e733de0861f0d61b179d3d1891e6b90587732] = 20200 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x167e733de0861f0d61b179d3d1891e6b90587732, 20200 * 10 ** uint(decimals));
balances[0x22dd964193df4de2e6954a2a9d9cbbd6f44f0b28] = 7650 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x22dd964193df4de2e6954a2a9d9cbbd6f44f0b28, 7650 * 10 ** uint(decimals));
balances[0xd2b752bec2fe5c7e5cc600eb5ce465a210cb857a] = 3750 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xd2b752bec2fe5c7e5cc600eb5ce465a210cb857a, 3750 * 10 ** uint(decimals));
balances[0xe14cffadb6bbad8de69bd5ba214441a9582ec548] = 700 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xe14cffadb6bbad8de69bd5ba214441a9582ec548, 700 * 10 ** uint(decimals));
balances[0xfe5a94e5bab010f52ae8fd8589b7d0a7b0b433ae] = 20000 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xfe5a94e5bab010f52ae8fd8589b7d0a7b0b433ae, 20000 * 10 ** uint(decimals));
balances[0xae7c95f2192c739edfb16412a6112a54f8965305] = 550 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xae7c95f2192c739edfb16412a6112a54f8965305, 550 * 10 ** uint(decimals));
balances[0x30385a99e66469a8c0bf172896758dd4595704a9] = 50 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x30385a99e66469a8c0bf172896758dd4595704a9, 50 * 10 ** uint(decimals));
balances[0x219fdb55ea364fcaf29aaa87fb1c45ba7db8128e] = 200 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x219fdb55ea364fcaf29aaa87fb1c45ba7db8128e, 200 * 10 ** uint(decimals));
balances[0xab4485ca338b91087a09ae8bc141648bb1c6e967] = 1100 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xab4485ca338b91087a09ae8bc141648bb1c6e967, 1100 * 10 ** uint(decimals));
balances[0xafaf9a165408737e11191393fe695c1ebc7a5429] = 35500 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xafaf9a165408737e11191393fe695c1ebc7a5429, 35500 * 10 ** uint(decimals));
balances[0xebd76aa221968b8ba9cdd6e6b4dbb889140088a3] = 3050 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xebd76aa221968b8ba9cdd6e6b4dbb889140088a3, 3050 * 10 ** uint(decimals));
balances[0x26b8c7606e828a509bbb208a0322cf960c17b225] = 4300 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x26b8c7606e828a509bbb208a0322cf960c17b225, 4300 * 10 ** uint(decimals));
balances[0x9b8957d1ac592bd388dcde346933ac1269b7c314] = 1050 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x9b8957d1ac592bd388dcde346933ac1269b7c314, 1050 * 10 ** uint(decimals));
balances[0xad9f11d1dd6d202243473a0cdae606308ab243b4] = 1000 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xad9f11d1dd6d202243473a0cdae606308ab243b4, 1000 * 10 ** uint(decimals));
balances[0x2f0d5a1d6bb5d7eaa0eaad39518621911a4a1d9f] = 200 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x2f0d5a1d6bb5d7eaa0eaad39518621911a4a1d9f, 200 * 10 ** uint(decimals));
balances[0xfbc2b315ac1fba765597a92ff100222425ce66fd] = 6000 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xfbc2b315ac1fba765597a92ff100222425ce66fd, 6000 * 10 ** uint(decimals));
balances[0x0a26d9674c2a1581ada4316e3f5960bb70fb0fb2] = 5100 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x0a26d9674c2a1581ada4316e3f5960bb70fb0fb2, 5100 * 10 ** uint(decimals));
balances[0xdc680cc11a535e45329f49566850668fef34054f] = 9750 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xdc680cc11a535e45329f49566850668fef34054f, 9750 * 10 ** uint(decimals));
balances[0x9fc5b0edc0309745c6974f1a6718029ea41a4d6e] = 400 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x9fc5b0edc0309745c6974f1a6718029ea41a4d6e, 400 * 10 ** uint(decimals));
balances[0xe0c059faabce16dd5ddb4817f427f5cf3b40f4c4] = 1800 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xe0c059faabce16dd5ddb4817f427f5cf3b40f4c4, 1800 * 10 ** uint(decimals));
balances[0x85d66f3a8da35f47e03d6bb51f51c2d70a61e12e] = 13200 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x85d66f3a8da35f47e03d6bb51f51c2d70a61e12e, 13200 * 10 ** uint(decimals));
balances[0xa5b3725e37431dc6a103961749cb9c98954202cd] = 4400 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xa5b3725e37431dc6a103961749cb9c98954202cd, 4400 * 10 ** uint(decimals));
balances[0xf3552d4018fad9fcc390f5684a243f7318d8b570] = 2500 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xf3552d4018fad9fcc390f5684a243f7318d8b570, 2500 * 10 ** uint(decimals));
balances[0x1fca39ed4f19edd12eb274dc467c099eb5106a13] = 2750 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x1fca39ed4f19edd12eb274dc467c099eb5106a13, 2750 * 10 ** uint(decimals));
balances[0xf95f528d7c25904f15d4154e45eab8e5d4b6c160] = 350 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xf95f528d7c25904f15d4154e45eab8e5d4b6c160, 350 * 10 ** uint(decimals));
balances[0xa62178f120cccba370d2d2d12ec6fb1ff276d706] = 20250 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xa62178f120cccba370d2d2d12ec6fb1ff276d706, 20250 * 10 ** uint(decimals));
balances[0xc446073e0c00a1138812b3a99a19df3cb8ace70d] = 20050 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xc446073e0c00a1138812b3a99a19df3cb8ace70d, 20050 * 10 ** uint(decimals));
balances[0xfcc6bf3369077e22a90e05ad567744bf5109e4d4] = 300 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xfcc6bf3369077e22a90e05ad567744bf5109e4d4, 300 * 10 ** uint(decimals));
balances[0x25e5c43d5f53ee1a7dd5ad7560348e29baea3048] = 50 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x25e5c43d5f53ee1a7dd5ad7560348e29baea3048, 50 * 10 ** uint(decimals));
balances[0x4d01d11697f00097064d7e05114ecd3843e82867] = 6050 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x4d01d11697f00097064d7e05114ecd3843e82867, 6050 * 10 ** uint(decimals));
balances[0xe585ba86b84283f0f1118041837b06d03b96885e] = 1350 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xe585ba86b84283f0f1118041837b06d03b96885e, 1350 * 10 ** uint(decimals));
balances[0x21a6043877a0ac376b7ca91195521de88d440eba] = 1600 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x21a6043877a0ac376b7ca91195521de88d440eba, 1600 * 10 ** uint(decimals));
balances[0xe8a01b61f80130aefda985ee2e9c6899a57a17c8] = 1750 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xe8a01b61f80130aefda985ee2e9c6899a57a17c8, 1750 * 10 ** uint(decimals));
balances[0x8d12a197cb00d4747a1fe03395095ce2a5cc6819] = 46800 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x8d12a197cb00d4747a1fe03395095ce2a5cc6819, 46800 * 10 ** uint(decimals));
balances[0xa1a3e2fcc1e7c805994ca7309f9a829908a18b4c] = 4100 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xa1a3e2fcc1e7c805994ca7309f9a829908a18b4c, 4100 * 10 ** uint(decimals));
balances[0x51138ab5497b2c3d85be94d23905f5ead9e533a7] = 50 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x51138ab5497b2c3d85be94d23905f5ead9e533a7, 50 * 10 ** uint(decimals));
balances[0x559a922941f84ebe6b9f0ed58e3b96530614237e] = 650 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x559a922941f84ebe6b9f0ed58e3b96530614237e, 650 * 10 ** uint(decimals));
balances[0xe539a7645d2f33103c89b5b03abb422a163b7c73] = 600 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xe539a7645d2f33103c89b5b03abb422a163b7c73, 600 * 10 ** uint(decimals));
balances[0x4ffe17a2a72bc7422cb176bc71c04ee6d87ce329] = 4300 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x4ffe17a2a72bc7422cb176bc71c04ee6d87ce329, 4300 * 10 ** uint(decimals));
balances[0x88058d4d90cc9d9471509e5be819b2be361b51c6] = 9450 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x88058d4d90cc9d9471509e5be819b2be361b51c6, 9450 * 10 ** uint(decimals));
balances[0x0000bb50ee5f5df06be902d1f9cb774949c337ed] = 1150 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0x0000bb50ee5f5df06be902d1f9cb774949c337ed, 1150 * 10 ** uint(decimals));
balances[0xd7dd80404d3d923c8a40c47c1f61aacbccb4191e] = 6450 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xd7dd80404d3d923c8a40c47c1f61aacbccb4191e, 6450 * 10 ** uint(decimals));
balances[0xf2119e50578b3dfa248652c4fbec76b9e415acb2] = 100 * 10 ** uint(decimals);
emit Transfer(address(0x0), 0xf2119e50578b3dfa248652c4fbec76b9e415acb2, 100 * 10 ** uint(decimals));
balances[0xd2470aacd96242207f06111819111d17ca055dfb] = 9450 * 10 ** uint(decimals); 
emit Transfer(address(0x0), 0xd2470aacd96242207f06111819111d17ca055dfb, 9450 * 10 ** uint(decimals));

// test lines 
//balances[msg.sender] = 1000 * 10 ** uint(decimals);
//timer[msg.sender ] = ( now - ( 1 years));

    }


        function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
            bytes32 digest =  keccak256(challengeNumber, msg.sender, nonce );
            if (digest != challenge_digest) revert();
            if(uint256(digest) > miningTarget) revert();
             bytes32 solution = solutionForChallenge[challengeNumber];
             solutionForChallenge[challengeNumber] = digest;
             if(solution != 0x0) revert();  //prevent the same answer from awarding twice
             _claimTokens(msg.sender);
             timer[msg.sender]=now;
            uint reward_amount = getMiningReward();
            balances[msg.sender] = balances[msg.sender].add(reward_amount);
            tokensMinted = tokensMinted.add(reward_amount);
            assert(tokensMinted <= maxSupplyForEra);
            lastRewardTo = msg.sender;
            lastRewardAmount = reward_amount;
            lastRewardEthBlockNumber = block.number;
             _startNewMiningEpoch();
              emit Mint(msg.sender, reward_amount, epochCount, challengeNumber );
              emit Transfer(address(0x0), msg.sender, reward_amount);
           return true;
        }

    function _startNewMiningEpoch() internal {
      if( tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < 39)
      {
        rewardEra = rewardEra + 1;
      }
      maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));
      epochCount = epochCount.add(1);
      if(epochCount % _BLOCKS_PER_READJUSTMENT == 0)
      {
        _reAdjustDifficulty();
      }
      challengeNumber = block.blockhash(block.number - 1);
    }

    function _reAdjustDifficulty() internal {
        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        uint epochsMined = _BLOCKS_PER_READJUSTMENT; 
        uint targetEthBlocksPerDiffPeriod = epochsMined * 60; //should be 60 times slower than ethereum
        if( ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod )
        {
          uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );
          uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
          miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));   //by up to 50 %
        }else{
          uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div( targetEthBlocksPerDiffPeriod );
          uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000
          miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));   //by up to 50 %
        }
        latestDifficultyPeriodStarted = block.number;
        if(miningTarget < _MINIMUM_TARGET) //very difficult
        {
          miningTarget = _MINIMUM_TARGET;
        }
        if(miningTarget > _MAXIMUM_TARGET) //very easy
        {
          miningTarget = _MAXIMUM_TARGET;
        }
    }

    function getChallengeNumber() public constant returns (bytes32) {
        return challengeNumber;
    }

    function getMiningDifficulty() public constant returns (uint) {
        return _MAXIMUM_TARGET.div(miningTarget);
    }

    function getMiningTarget() public constant returns (uint) {
       return miningTarget;
   }

    function getMiningReward() public constant returns (uint) {
         return (50 * 10**uint(decimals) ).div( 2**rewardEra ) ;
    }

    function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {
        bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
        return digest;
      }
      
      function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {
          bytes32 digest = keccak256(challenge_number,msg.sender,nonce);
          if(uint256(digest) > testTarget) revert();
          return (digest == challenge_digest);
        }

    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner] + _getPoS(tokenOwner); // add unclaimed pos tokens 
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        _claimTokens(msg.sender);
        _claimTokens(to);
        timer[msg.sender] = now;
        timer[to] = now;
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        _claimTokens(from);
        _claimTokens(to);
        timer[from] = now;
        timer[to] = now;
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function () public payable {
        revert();
    } 
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function claimTokens() public {
        _claimTokens(msg.sender);        
        timer[msg.sender] = now;
    }
    
    function _claimTokens(address target) internal{
        if (timer[target] == 0){
            // russian hackers BTFO

            if (balances[target] > 0){
                // timer is handled in _getPoS 
            }
            else{
                return;
            }
        }
        if (timer[target] == now){
            // 0 seconds passed, 0 tokens gotten via PoS 
            // return so no gas waste 
            return;
        }
        
        uint256 totalTkn = _getPoS(target);
        if (totalTkn > 0){
            balances[target] = balances[target].add(totalTkn);
            _totalSupply.add(totalTkn);
            emit PoS(target, totalTkn);
        }

        //timer[target] = now; every time you claim tokens this timer is set. this is to prevent people claiming 0 tokens and then setting their timer
        emit Transfer(address(0x0), target, totalTkn);
    }
    
    function _getPoS(address target) internal view returns (uint256){
        int ONE_SECOND = 0x10000000000000000;
        uint TIME = timer[target];
        if (TIME == 0){
            TIME = GLOBAL_START_TIMER;
        }
        int PORTION_SCALED = (int(now - TIME) * ONE_SECOND) / int(doubleUnit); 
        uint256 exp = fixedExp(PORTION_SCALED);
        
        return ((balances[target].mul(exp)) / uint(one)).sub(balances[target]); 
    }
    
    
    
    int256 constant ln2       = 0x0b17217f7d1cf79ac;
    int256 constant ln2_64dot5= 0x2cb53f09f05cc627c8;
    int256 constant one       = 0x10000000000000000;
    int256 constant c2 =  0x02aaaaaaaaa015db0;
    int256 constant c4 = -0x000b60b60808399d1;
    int256 constant c6 =  0x0000455956bccdd06;
    int256 constant c8 = -0x000001b893ad04b3a;
    function fixedExp(int256 a) public pure returns (uint256 exp) {
        int256 scale = (a + (ln2_64dot5)) / ln2 - 64;
        a -= scale*ln2;
        // The polynomial R = 2 + c2*x^2 + c4*x^4 + ...
        // approximates the function x*(exp(x)+1)/(exp(x)-1)
        // Hence exp(x) = (R(x)+x)/(R(x)-x)
        int256 z = (a*a) / one;
        int256 R = ((int256)(2) * one) +
            (z*(c2 + (z*(c4 + (z*(c6 + (z*c8/one))/one))/one))/one);
        exp = (uint256) (((R + a) * one) / (R - a));
        if (scale >= 0)
            exp <<= scale;
        else
            exp >>= -scale;
        return exp;
    }

}