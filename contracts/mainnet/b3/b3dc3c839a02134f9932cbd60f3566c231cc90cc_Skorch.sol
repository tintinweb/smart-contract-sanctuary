pragma solidity ^0.4.18;

 

//-------------------------------
// (        )   )  (            )  
// )\ )  ( /(( /(  )\ )  (   ( /(  
//(()/(  )\())\())(()/(  )\  )\()) 
// /(_))((_)((_)\  /(_)|((_)((_)\  
//(_)) |_ ((_)((_)(_)) )\___ _((_) 
/// __|| |/ // _ \| _ ((/ __| || | 
//\__ \  &#39; <| (_) |   /| (__| __ | 
//|___/ _|\_\\___/|_|_\ \___|_||_| 
//--------------------------------

//------------------------------------------
// Official Website: https://skorch.io
// Github: https://github.com/skorchtoken
// Twitter: https://twitter.com/SkorchToken
// Reddit: https://reddit.com/r/SkorchToken
// Medium: https://medium.com/@skorchtoken
// Discord: https://discord.gg/yxZAnfe
// Telegram: https://t.me/skorchtoken

// ALWAYS refer to our official social media channels and website for project announcements.
//------------------------------------------

// Skorch is the first PoW+PoS mineable ERC20 token using Keccak256 (Sha3) algorithm
// 210 Million Total Supply 
// 21 Million available for Proof of Work mining based on Bitcoin&#39;s SHA256 Algorithm
// 21k (21,000) SKO Required to be held in your wallet to gain Proof of Stake Rewards
// 189 Million of 210 Million total supply will be minted by the smart contract for PoS rewards 
// 30% PoS rewards for the first year but decreases each year after until 0 
// PoS requirement decreases after first year and each year after until 0

// Difficulty target auto-adjusts with PoW hashrate
// Mining rewards decrease as more tokens are minted

// To fix and improve the original Skorch token contract a snapshot was taken at block 5882054.


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

//209899900000000

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

contract Skorch is ERC20Interface, Owned {

    using SafeMath for uint;
    using ExtendedMath for uint;

    string public symbol;

    string public  name;

    uint8 public decimals = 8;

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
   
    
  //  uint256 timerUnit = 2.2075199 * (10**8);
    uint256 timerUnit = 88416639; // unit for staking req
    uint256 stakingRequirement = (21000 * (10**uint(decimals)));
    
    
    uint stakeUnit = 930222908; // unit  for staking 
    
    //uint256 stakingCap = (210000000 * (10**uint(decimals)));

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
    event PoS(address indexed from, uint reward_amount);

    constructor()
        public 
        onlyOwner()
    {
        symbol = "SKO";
        name = "Skorch";
        decimals = 8;
        // uncomment this to test 
        //balances[msg.sender] = (21000) * (10 ** uint(decimals)); // change 21000 to some lower number than 21000 
        //to see you will not get PoS tokens if you have less than 21000 tokens 
        //timer[msg.sender] = now - (1 years);
        _totalSupply = 210000000 * 10**uint(decimals);
        if(locked) revert();
        locked = true;
        tokensMinted = 69750000000000;
        rewardEra = 0;
        maxSupplyForEra = 1050000000000000;
        //miningTarget = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;
        //_startNewMiningEpoch(); all relevant vars are set below
        GLOBAL_START_TIMER = now;
        challengeNumber = 0x48f499eca7dc41858c2a53fded09096d138b8b88a9da8f488dccd5118bb1bbe2;
        epochCount = 20181;
        rewardEra = 0;
        maxSupplyForEra = (_totalSupply/10) - _totalSupply.div( 20**(rewardEra + 1)); // multiplied by 10 since totalsupply is 210 million here 
        miningTarget = 462884030900683306229868328231836786922375156766639975465481078398;
        
        
        
        // SNAPSHOT DATA 
// NEW FILE
balances[0xab4485ca338b91087a09ae8bc141648bb1c6e967]=111501588282;
emit Transfer(address(0x0), 0xab4485ca338b91087a09ae8bc141648bb1c6e967, 111501588282);
balances[0xf2119e50578b3dfa248652c4fbec76b9e415acb2]=10136508025;
emit Transfer(address(0x0), 0xf2119e50578b3dfa248652c4fbec76b9e415acb2, 10136508025);
balances[0xb12b538cb67fceb50bbc1a31d2011eb92e6f7188]=1583682;
emit Transfer(address(0x0), 0xb12b538cb67fceb50bbc1a31d2011eb92e6f7188, 1583682);
balances[0x21b7e18dacde5c004a0a56e74f071ac3fb2e98ff]=10790714329;
emit Transfer(address(0x0), 0x21b7e18dacde5c004a0a56e74f071ac3fb2e98ff, 10790714329);
balances[0xe539a7645d2f33103c89b5b03abb422a163b7c73]=60819048154;
emit Transfer(address(0x0), 0xe539a7645d2f33103c89b5b03abb422a163b7c73, 60819048154);
balances[0x4ffe17a2a72bc7422cb176bc71c04ee6d87ce329]=451048209723;
emit Transfer(address(0x0), 0x4ffe17a2a72bc7422cb176bc71c04ee6d87ce329, 451048209723);
balances[0xc0a2002e74b3b22e77098cb87232f446d813ce31]=33885;
emit Transfer(address(0x0), 0xc0a2002e74b3b22e77098cb87232f446d813ce31, 33885);
balances[0xfc313f77c2cbc6cd0dd82b9a0ed1620ba906e46d]=192593652488;
emit Transfer(address(0x0), 0xfc313f77c2cbc6cd0dd82b9a0ed1620ba906e46d, 192593652488);
balances[0x219fdb55ea364fcaf29aaa87fb1c45ba7db8128e]=20273016051;
emit Transfer(address(0x0), 0x219fdb55ea364fcaf29aaa87fb1c45ba7db8128e, 20273016051);
balances[0xfbc2b315ac1fba765597a92ff100222425ce66fd]=608190481542;
emit Transfer(address(0x0), 0xfbc2b315ac1fba765597a92ff100222425ce66fd, 608190481542);
balances[0x852563d88480decbc9bfb4428bb689af48dd92a9]=1008618359915;
emit Transfer(address(0x0), 0x852563d88480decbc9bfb4428bb689af48dd92a9, 1008618359915);
balances[0x4d01d11697f00097064d7e05114ecd3843e82867]=789840293838;
emit Transfer(address(0x0), 0x4d01d11697f00097064d7e05114ecd3843e82867, 789840293838);
balances[0xe75ea07e4b90e46e13c37644138aa99ec69020ae]=526108154879;
emit Transfer(address(0x0), 0xe75ea07e4b90e46e13c37644138aa99ec69020ae, 526108154879);
balances[0x51138ab5497b2c3d85be94d23905f5ead9e533a7]=5068254012;
emit Transfer(address(0x0), 0x51138ab5497b2c3d85be94d23905f5ead9e533a7, 5068254012);
balances[0xae7c95f2192c739edfb16412a6112a54f8965305]=55750794141;
emit Transfer(address(0x0), 0xae7c95f2192c739edfb16412a6112a54f8965305, 55750794141);
balances[0xe0261acfdd10508c75b6a60b1534c8386c4daa52]=5047016671743;
emit Transfer(address(0x0), 0xe0261acfdd10508c75b6a60b1534c8386c4daa52, 5047016671743);
balances[0x0a26d9674c2a1581ada4316e3f5960bb70fb0fb2]=516961909310;
emit Transfer(address(0x0), 0x0a26d9674c2a1581ada4316e3f5960bb70fb0fb2, 516961909310);
balances[0xa62178f120cccba370d2d2d12ec6fb1ff276d706]=2052642875205;
emit Transfer(address(0x0), 0xa62178f120cccba370d2d2d12ec6fb1ff276d706, 2052642875205);
balances[0xe57a18783640c9fa3c5e8e4d4b4443e2024a7ff9]=2494738345632;
emit Transfer(address(0x0), 0xe57a18783640c9fa3c5e8e4d4b4443e2024a7ff9, 2494738345632);
balances[0x9b8957d1ac592bd388dcde346933ac1269b7c314]=106433334269;
emit Transfer(address(0x0), 0x9b8957d1ac592bd388dcde346933ac1269b7c314, 106433334269);
balances[0xf27bb893a4d9574378c4b1d089bdb6b9fce5099e]=380845;
emit Transfer(address(0x0), 0xf27bb893a4d9574378c4b1d089bdb6b9fce5099e, 380845);
balances[0x54a8f792298af9489de7a1245169a943fb69f5a6]=707886981662;
emit Transfer(address(0x0), 0x54a8f792298af9489de7a1245169a943fb69f5a6, 707886981662);
balances[0x004ba728a652bded4d4b79fb04b5a92ad8ce15e7]=21250198;
emit Transfer(address(0x0), 0x004ba728a652bded4d4b79fb04b5a92ad8ce15e7, 21250198);
balances[0xd05803aee240195460f8589a6d6487fcea0097c1]=85731;
emit Transfer(address(0x0), 0xd05803aee240195460f8589a6d6487fcea0097c1, 85731);
balances[0xad9f11d1dd6d202243473a0cdae606308ab243b4]=101365080257;
emit Transfer(address(0x0), 0xad9f11d1dd6d202243473a0cdae606308ab243b4, 101365080257);
balances[0xfec55e783595682141c4b5e6ad9ea605f1683844]=60657099080;
emit Transfer(address(0x0), 0xfec55e783595682141c4b5e6ad9ea605f1683844, 60657099080);
balances[0x99a7e5777b711ff23e2b6961232a4009f7cec1b0]=456860909542;
emit Transfer(address(0x0), 0x99a7e5777b711ff23e2b6961232a4009f7cec1b0, 456860909542);
balances[0xbf45f4280cfbe7c2d2515a7d984b8c71c15e82b7]=1366848029003;
emit Transfer(address(0x0), 0xbf45f4280cfbe7c2d2515a7d984b8c71c15e82b7, 1366848029003);
balances[0xb38094d492af4fffff760707f36869713bfb2250]=2032369859152;
emit Transfer(address(0x0), 0xb38094d492af4fffff760707f36869713bfb2250, 2032369859152);
balances[0x900953b10460908ec636b46307dca13a759275cb]=1856435;
emit Transfer(address(0x0), 0x900953b10460908ec636b46307dca13a759275cb, 1856435);
balances[0x167e733de0861f0d61b179d3d1891e6b90587732]=2047574621189;
emit Transfer(address(0x0), 0x167e733de0861f0d61b179d3d1891e6b90587732, 2047574621189);
balances[0xdb3cbb8aa4dec854e6e60982dd9d4e85a8b422bc]=2;
emit Transfer(address(0x0), 0xdb3cbb8aa4dec854e6e60982dd9d4e85a8b422bc, 2);
balances[0x072e8711704654019c3d9bc242b3f9a4ee1963ce]=10136236279;
emit Transfer(address(0x0), 0x072e8711704654019c3d9bc242b3f9a4ee1963ce, 10136236279);
balances[0x04f72aa695b65a54d79db635005077293d111635]=167020515303;
emit Transfer(address(0x0), 0x04f72aa695b65a54d79db635005077293d111635, 167020515303);
balances[0x30385a99e66469a8c0bf172896758dd4595704a9]=614699515479;
emit Transfer(address(0x0), 0x30385a99e66469a8c0bf172896758dd4595704a9, 614699515479);
balances[0xfe5a94e5bab010f52ae8fd8589b7d0a7b0b433ae]=2067847571118;
emit Transfer(address(0x0), 0xfe5a94e5bab010f52ae8fd8589b7d0a7b0b433ae, 2067847571118);
balances[0x88058d4d90cc9d9471509e5be819b2be361b51c6]=957900008429;
emit Transfer(address(0x0), 0x88058d4d90cc9d9471509e5be819b2be361b51c6, 957900008429);
balances[0xfcc6bf3369077e22a90e05ad567744bf5109e4d4]=1635580659302;
emit Transfer(address(0x0), 0xfcc6bf3369077e22a90e05ad567744bf5109e4d4, 1635580659302);
balances[0x21a6043877a0ac376b7ca91195521de88d440eba]=162184128411;
emit Transfer(address(0x0), 0x21a6043877a0ac376b7ca91195521de88d440eba, 162184128411);
balances[0xd7dd80404d3d923c8a40c47c1f61aacbccb4191e]=3569292763171;
emit Transfer(address(0x0), 0xd7dd80404d3d923c8a40c47c1f61aacbccb4191e, 3569292763171);
balances[0xa1a3e2fcc1e7c805994ca7309f9a829908a18b4c]=633301706054;
emit Transfer(address(0x0), 0xa1a3e2fcc1e7c805994ca7309f9a829908a18b4c, 633301706054);
balances[0xc5556ce5c51d2f6a8d7a54bec2a9961dfada84db]=2471775966918;
emit Transfer(address(0x0), 0xc5556ce5c51d2f6a8d7a54bec2a9961dfada84db, 2471775966918);
balances[0xb4894098be4dbfdc0024dfb9d2e9f6654e0e3786]=10053178133;
emit Transfer(address(0x0), 0xb4894098be4dbfdc0024dfb9d2e9f6654e0e3786, 10053178133);
balances[0xe8a01b61f80130aefda985ee2e9c6899a57a17c8]=177388890449;
emit Transfer(address(0x0), 0xe8a01b61f80130aefda985ee2e9c6899a57a17c8, 177388890449);
balances[0x559a922941f84ebe6b9f0ed58e3b96530614237e]=65887302167;
emit Transfer(address(0x0), 0x559a922941f84ebe6b9f0ed58e3b96530614237e, 65887302167);
balances[0xf95f528d7c25904f15d4154e45eab8e5d4b6c160]=425572373267;
emit Transfer(address(0x0), 0xf95f528d7c25904f15d4154e45eab8e5d4b6c160, 425572373267);
balances[0x0045b9707913eae3889283ed4d72077a904b9848]=1507541146428;
emit Transfer(address(0x0), 0x0045b9707913eae3889283ed4d72077a904b9848, 1507541146428);
balances[0x586389feed58c2c6a0ce6258cb1c58833abdb093]=2603426;
emit Transfer(address(0x0), 0x586389feed58c2c6a0ce6258cb1c58833abdb093, 2603426);
balances[0xd2b752bec2fe5c7e5cc600eb5ce465a210cb857a]=380119050963;
emit Transfer(address(0x0), 0xd2b752bec2fe5c7e5cc600eb5ce465a210cb857a, 380119050963);
balances[0x518bbb5e4a1e8f8f21a09436c35b9cb5c20c7b43]=5037433249;
emit Transfer(address(0x0), 0x518bbb5e4a1e8f8f21a09436c35b9cb5c20c7b43, 5037433249);
balances[0x25e5c43d5f53ee1a7dd5ad7560348e29baea3048]=5068254012;
emit Transfer(address(0x0), 0x25e5c43d5f53ee1a7dd5ad7560348e29baea3048, 5068254012);
balances[0x22dd964193df4de2e6954a2a9d9cbbd6f44f0b28]=2754253183453;
emit Transfer(address(0x0), 0x22dd964193df4de2e6954a2a9d9cbbd6f44f0b28, 2754253183453);
balances[0xaa7a7c2decb180f68f11e975e6d92b5dc06083a6]=116569842295;
emit Transfer(address(0x0), 0xaa7a7c2decb180f68f11e975e6d92b5dc06083a6, 116569842295);
balances[0x4e27a678c8dc883035c542c83124e7e3f39842b0]=35477778089;
emit Transfer(address(0x0), 0x4e27a678c8dc883035c542c83124e7e3f39842b0, 35477778089);
balances[0x3bd56f97876d3af248b1fe92e361c05038c74c27]=15181683975;
emit Transfer(address(0x0), 0x3bd56f97876d3af248b1fe92e361c05038c74c27, 15181683975);
balances[0x674194d05bfc9a176a5b84711c8687609ff3d17b]=4287056630970;
emit Transfer(address(0x0), 0x674194d05bfc9a176a5b84711c8687609ff3d17b, 4287056630970);
balances[0x0102f6ca7278e7d96a6d649da30bfe07e87155a3]=1233053375653;
emit Transfer(address(0x0), 0x0102f6ca7278e7d96a6d649da30bfe07e87155a3, 1233053375653);
balances[0x3750ecf5e0536d04dd3858173ab571a0dcbdf7e0]=50270330036;
emit Transfer(address(0x0), 0x3750ecf5e0536d04dd3858173ab571a0dcbdf7e0, 50270330036);
balances[0x07a68bd44a526e09b8dbfc7085b265450362b61a]=101365080257;
emit Transfer(address(0x0), 0x07a68bd44a526e09b8dbfc7085b265450362b61a, 101365080257);
balances[0xebd76aa221968b8ba9cdd6e6b4dbb889140088a3]=309163494783;
emit Transfer(address(0x0), 0xebd76aa221968b8ba9cdd6e6b4dbb889140088a3, 309163494783);
balances[0xc7ee330d69cdddc1b9955618ff0df27bb8de3143]=10098567209;
emit Transfer(address(0x0), 0xc7ee330d69cdddc1b9955618ff0df27bb8de3143, 10098567209);
balances[0xe0c059faabce16dd5ddb4817f427f5cf3b40f4c4]=656449480989;
emit Transfer(address(0x0), 0xe0c059faabce16dd5ddb4817f427f5cf3b40f4c4, 656449480989);
balances[0xdc680cc11a535e45329f49566850668fef34054f]=1629652247199;
emit Transfer(address(0x0), 0xdc680cc11a535e45329f49566850668fef34054f, 1629652247199);
balances[0x22ef324a534ba9aa0d060c92294fdd0fc4aca065]=105388398778;
emit Transfer(address(0x0), 0x22ef324a534ba9aa0d060c92294fdd0fc4aca065, 105388398778);
balances[0xe14cffadb6bbad8de69bd5ba214441a9582ec548]=70955556179;
emit Transfer(address(0x0), 0xe14cffadb6bbad8de69bd5ba214441a9582ec548, 70955556179);
balances[0xdfb895c870c4956261f4839dd12786ef612d7314]=307632851383;
emit Transfer(address(0x0), 0xdfb895c870c4956261f4839dd12786ef612d7314, 307632851383);
balances[0x620103bb2b263ab0a50a47f73140d218401541c0]=10780637244561;
emit Transfer(address(0x0), 0x620103bb2b263ab0a50a47f73140d218401541c0, 10780637244561);
balances[0x9fc5b0edc0309745c6974f1a6718029ea41a4d6e]=65859631176;
emit Transfer(address(0x0), 0x9fc5b0edc0309745c6974f1a6718029ea41a4d6e, 65859631176);
balances[0xd6ceae2756f2af0a2f825b6e3ca8a9cfb4d082e2]=1122517124649;
emit Transfer(address(0x0), 0xd6ceae2756f2af0a2f825b6e3ca8a9cfb4d082e2, 1122517124649);
balances[0x25437b6a20021ea94d549ddd50403994e532e9d7]=1711954946632;
emit Transfer(address(0x0), 0x25437b6a20021ea94d549ddd50403994e532e9d7, 1711954946632);
balances[0xeb4f4c886b402c65ff6f619716efe9319ce40fcf]=526035186557;
emit Transfer(address(0x0), 0xeb4f4c886b402c65ff6f619716efe9319ce40fcf, 526035186557);
balances[0xf3552d4018fad9fcc390f5684a243f7318d8b570]=253412700642;
emit Transfer(address(0x0), 0xf3552d4018fad9fcc390f5684a243f7318d8b570, 253412700642);
balances[0x85abe8e3bed0d4891ba201af1e212fe50bb65a26]=1060373239943;
emit Transfer(address(0x0), 0x85abe8e3bed0d4891ba201af1e212fe50bb65a26, 1060373239943);
balances[0xc446073e0c00a1138812b3a99a19df3cb8ace70d]=2032369859153;
emit Transfer(address(0x0), 0xc446073e0c00a1138812b3a99a19df3cb8ace70d, 2032369859153);
balances[0x195d65187a4aeb24b563dd2d52709a6b67064ad3]=235803680643;
emit Transfer(address(0x0), 0x195d65187a4aeb24b563dd2d52709a6b67064ad3, 235803680643);
balances[0x588611841bd8b134f3d6ca3ff2796b483dfca4c6]=27875;
emit Transfer(address(0x0), 0x588611841bd8b134f3d6ca3ff2796b483dfca4c6, 27875);
balances[0x43237ce180fc47cb4e3d32eb23e420f5ecf7a95e]=5087020825285;
emit Transfer(address(0x0), 0x43237ce180fc47cb4e3d32eb23e420f5ecf7a95e, 5087020825285);
balances[0x394299ef1650ac563a9adbec4061b25e50570f49]=65523270720;
emit Transfer(address(0x0), 0x394299ef1650ac563a9adbec4061b25e50570f49, 65523270720);
balances[0x0000bb50ee5f5df06be902d1f9cb774949c337ed]=728415;
emit Transfer(address(0x0), 0x0000bb50ee5f5df06be902d1f9cb774949c337ed, 728415);
balances[0x4927fb34fff626adb7b07305c447ac89ded8bea2]=15181318646;
emit Transfer(address(0x0), 0x4927fb34fff626adb7b07305c447ac89ded8bea2, 15181318646);
balances[0x93da7b2830e3932d906749e67a7ce1fbf3a5366d]=2768553093810;
emit Transfer(address(0x0), 0x93da7b2830e3932d906749e67a7ce1fbf3a5366d, 2768553093810);
balances[0x7f4924f55e215e1fe44e3b5bb7fdfced2154b30f]=506445600761;
emit Transfer(address(0x0), 0x7f4924f55e215e1fe44e3b5bb7fdfced2154b30f, 506445600761);
balances[0x9834977aa420b078b8fd47c73a9520f968d66a3a]=1035039327674;
emit Transfer(address(0x0), 0x9834977aa420b078b8fd47c73a9520f968d66a3a, 1035039327674);
balances[0x26b8c7606e828a509bbb208a0322cf960c17b225]=1314664139193;
emit Transfer(address(0x0), 0x26b8c7606e828a509bbb208a0322cf960c17b225, 1314664139193);
balances[0x8f3dd21c9334980030ba95c37565ba25df9574cd]=20273016051;
emit Transfer(address(0x0), 0x8f3dd21c9334980030ba95c37565ba25df9574cd, 20273016051);
balances[0x85d66f3a8da35f47e03d6bb51f51c2d70a61e12e]=10419370357974;
emit Transfer(address(0x0), 0x85d66f3a8da35f47e03d6bb51f51c2d70a61e12e, 10419370357974);
balances[0xbafc492638a2ec4f89aff258c8f18f806a844d72]=396663813367;
emit Transfer(address(0x0), 0xbafc492638a2ec4f89aff258c8f18f806a844d72, 396663813367);
balances[0x2f0d5a1d6bb5d7eaa0eaad39518621911a4a1d9f]=45613275677;
emit Transfer(address(0x0), 0x2f0d5a1d6bb5d7eaa0eaad39518621911a4a1d9f, 45613275677);
balances[0xae5910c6f3cd709bf497bae2b8eae8cf983aca1b]=561729123519;
emit Transfer(address(0x0), 0xae5910c6f3cd709bf497bae2b8eae8cf983aca1b, 561729123519);
balances[0xb963db36d28468ce64bce65e560e5f27e75f2f50]=50497795029;
emit Transfer(address(0x0), 0xb963db36d28468ce64bce65e560e5f27e75f2f50, 50497795029);
balances[0x7134161b9e6fa84d62f156037870ee77fa50f607]=806825;
emit Transfer(address(0x0), 0x7134161b9e6fa84d62f156037870ee77fa50f607, 806825);
balances[0x111fd8a12981d1174cfa8eef3b0141b3d5d4e5b3]=5023380788;
emit Transfer(address(0x0), 0x111fd8a12981d1174cfa8eef3b0141b3d5d4e5b3, 5023380788);
balances[0xafaf9a165408737e11191393fe695c1ebc7a5429]=3750469994332;
emit Transfer(address(0x0), 0xafaf9a165408737e11191393fe695c1ebc7a5429, 3750469994332);
balances[0x5329fcc196c445009aac138b22d25543ed195888]=126671028590;
emit Transfer(address(0x0), 0x5329fcc196c445009aac138b22d25543ed195888, 126671028590);
balances[0xa5b3725e37431dc6a103961749cb9c98954202cd]=446006353130;
emit Transfer(address(0x0), 0xa5b3725e37431dc6a103961749cb9c98954202cd, 446006353130);
balances[0xb8ab7387076f022c28481fafb28911ce4377e0ea]=3045242779146;
emit Transfer(address(0x0), 0xb8ab7387076f022c28481fafb28911ce4377e0ea, 3045242779146);
balances[0xd2470aacd96242207f06111819111d17ca055dfb]=957900008429;
emit Transfer(address(0x0), 0xd2470aacd96242207f06111819111d17ca055dfb, 957900008429);
balances[0x1fca39ed4f19edd12eb274dc467c099eb5106a13]=278753970706;
emit Transfer(address(0x0), 0x1fca39ed4f19edd12eb274dc467c099eb5106a13, 278753970706);
balances[0x8d12a197cb00d4747a1fe03395095ce2a5cc6819]=4743885756029;
emit Transfer(address(0x0), 0x8d12a197cb00d4747a1fe03395095ce2a5cc6819, 4743885756029);
balances[0x2a23527a6dbafae390514686d50f47747d01e44d]=652376852116;
emit Transfer(address(0x0), 0x2a23527a6dbafae390514686d50f47747d01e44d, 652376852116);
balances[0x371e31169df00563eafab334c738e66dd0476a8f]=226377928506;
emit Transfer(address(0x0), 0x371e31169df00563eafab334c738e66dd0476a8f, 226377928506);
balances[0x40ea0a2abc9479e51e411870cafd759cb110c258]=30282012248;
emit Transfer(address(0x0), 0x40ea0a2abc9479e51e411870cafd759cb110c258, 30282012248);
balances[0xe585ba86b84283f0f1118041837b06d03b96885e]=170791;
emit Transfer(address(0x0), 0xe585ba86b84283f0f1118041837b06d03b96885e, 170791);
balances[0xbede88c495132efb90b5039bc2942042e07814df]=40513641855;
emit Transfer(address(0x0), 0xbede88c495132efb90b5039bc2942042e07814df, 40513641855);
        


// test lines 
//balances[msg.sender] = 21000 * (10 ** uint(decimals));
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
      maxSupplyForEra = _totalSupply/10 - _totalSupply.div( 20**(rewardEra + 1));
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
            //_totalSupply.add(totalTkn); total supply is fixed 
            emit PoS(target, totalTkn);
        }

        //timer[target] = now; every time you claim tokens this timer is set. this is to prevent people claiming 0 tokens and then setting their timer
        emit Transfer(address(0x0), target, totalTkn);
    }
    
    function getStakingRequirementTime(address target, uint256 TIME) view returns (uint256){



            return (stakingRequirement * fixedExp(((int(GLOBAL_START_TIMER) - int(TIME)) * one) / int(timerUnit)))/uint(one) ; 

    }
    
    function getRequirementTime(address target) view returns (uint256) {
        uint256 balance = balances[target];
        int ONE = 0x10000000000000000;
        if (balance == 0){
            return (uint256(0) - 1); // inf 
        }
        uint TIME = timer[target];
        if (TIME == 0){
            TIME = GLOBAL_START_TIMER;
        }
        
        int ln = fixedLog((balance * uint(one)) / stakingRequirement);
        int mul = (int(timerUnit) * ln) / (int(one));
        uint pos = uint( -mul);
        
        
        return (pos + GLOBAL_START_TIMER);
    }
    
    function GetStakingNow() view returns (uint256){
        return (stakingRequirement * fixedExp(((int(GLOBAL_START_TIMER) - int(now)) * one) / int(timerUnit)))/uint(one) ; 
    }
    

    
    
    function _getPoS(address target) internal view returns (uint256){
        if (balances[target] == 0){
            return 0;
        }
        int ONE_SECOND = 0x10000000000000000;
        uint TIME = timer[target];
        if (TIME == 0){
            TIME = GLOBAL_START_TIMER;
        }
        if (balances[target] < getStakingRequirementTime(target, TIME)){
            // staking requirement was too low at update 
            // maybe it has since surpassed the requirement? 
            uint flipTime = getRequirementTime(target);
            if ( now > flipTime ){
                TIME = flipTime;
            }
            else{
                return 0;
            }
        }
        int PORTION_SCALED = ( (int(GLOBAL_START_TIMER) - int(TIME)) * ONE_SECOND) / int(stakeUnit); 
        uint256 exp = fixedExp(PORTION_SCALED);
        
        PORTION_SCALED = ( (int(GLOBAL_START_TIMER) - int(now)) * ONE_SECOND) / int(stakeUnit); 
        uint256 exp2 = fixedExp(PORTION_SCALED);
        
        uint256 MULT = (9 * (exp.sub(exp2)) * (balances[target])) / (uint(one)); 
        

        
        return (MULT);
    }
    
    
    
    int256 constant ln2       = 0x0b17217f7d1cf79ac;
    int256 constant ln2_64dot5= 0x2cb53f09f05cc627c8;
    int256 constant one       = 0x10000000000000000;
    int256 constant c2 =  0x02aaaaaaaaa015db0;
    int256 constant c4 = -0x000b60b60808399d1;
    int256 constant c6 =  0x0000455956bccdd06;
    int256 constant c8 = -0x000001b893ad04b3a;
    uint256 constant sqrt2    = 0x16a09e667f3bcc908;
    uint256 constant sqrtdot5 = 0x0b504f333f9de6484;
    int256 constant c1        = 0x1ffffffffff9dac9b;
    int256 constant c3        = 0x0aaaaaaac16877908;
    int256 constant c5        = 0x0666664e5e9fa0c99;
    int256 constant c7        = 0x049254026a7630acf;
    int256 constant c9        = 0x038bd75ed37753d68;
    int256 constant c11       = 0x03284a0c14610924f;
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

    function fixedLog(uint256 a) internal pure returns (int256 log) {
        int32 scale = 0;
        while (a > sqrt2) {
            a /= 2;
            scale++;
        }
        while (a <= sqrtdot5) {
            a *= 2;
            scale--;
        }
        int256 s = (((int256)(a) - one) * one) / ((int256)(a) + one);
        // The polynomial R = c1*x + c3*x^3 + ... + c11 * x^11
        // approximates the function log(1+x)-log(1-x)
        // Hence R(s) = log((1+s)/(1-s)) = log(a)
        var z = (s*s) / one;
        return scale * ln2 +
            (s*(c1 + (z*(c3 + (z*(c5 + (z*(c7 + (z*(c9 + (z*c11/one))
                /one))/one))/one))/one))/one);
    }

}