pragma solidity ^0.4.15;

/*
  https://cryptogs.io
  --Austin Thomas Griffith for ETHDenver
  PizzaParlor -- a new venue for cryptogs games
  less transactions than original Cryptogs.sol assuming some
  centralization and a single commit reveal for randomness
*/



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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract PizzaParlor {

  uint8 public constant FLIPPINESS = 64;
  uint8 public constant FLIPPINESSROUNDBONUS = 16;
  uint8 public constant MAXROUNDS = 12; //must be greater than (255-FLIPPINESS)/FLIPPINESSROUNDBONUS
  uint32 public constant BLOCKTIMEOUT = 40;// a few hours?

  address public cryptogsAddress;
  function PizzaParlor(address _cryptogsAddress) public {
    cryptogsAddress=_cryptogsAddress;
  }

  //to make less transactions on-chain, game creation will happen off-chain
  //at this point, two players have agreed upon the ten cryptogs that will
  //be in the game, five from each player
  // the server will generate a secret, reveal, and commit
  // this commit is used as the game id and both players share it
  // the server will pick one user at random to be the game master
  // this player will get the reveal and be in charge of generating the game
  // technically either player can generate the game with the reveal
  // (and either player can drain the stack with the secret)

    //     commit      ->      player  -> stack hash
  mapping (bytes32 => mapping (address => bytes32)) public commitReceipt;

    //     commit      ->      player  -> block number
  mapping (bytes32 => mapping (address => uint32)) public commitBlock;

  mapping (bytes32 => uint8) public stacksTransferred;

  //tx1&2: players submit to a particular commit hash their stack of pogs (the two txs can happen on the same block, no one is waiting)
  //these go to the Cryptogs contract and it is transferStackAndCall&#39;ed to here
  function onTransferStack(address _sender, uint _token1, uint _token2, uint _token3, uint _token4, uint _token5, bytes32 _commit){

    //make sure this came from the Cryptogs contract
    require(msg.sender == cryptogsAddress);

    //make sure this commit is unique / doesn&#39;t already exist
    require(commitReceipt[_commit][_sender] == 0);

    //make sure there aren&#39;t already two stacks submitted
    require(stacksTransferred[_commit]<2);
    stacksTransferred[_commit]++;

    //make sure this contract now owns these tokens
    NFT cryptogsContract = NFT(cryptogsAddress);
    require(cryptogsContract.tokenIndexToOwner(_token1)==address(this));
    require(cryptogsContract.tokenIndexToOwner(_token2)==address(this));
    require(cryptogsContract.tokenIndexToOwner(_token3)==address(this));
    require(cryptogsContract.tokenIndexToOwner(_token4)==address(this));
    require(cryptogsContract.tokenIndexToOwner(_token5)==address(this));

    //generate a receipt for the transfer
    bytes32 receipt = keccak256(_commit,_sender,_token1,_token2,_token3,_token4,_token5);
    commitReceipt[_commit][_sender] = receipt;
    commitBlock[_commit][_sender] = uint32(block.number);

    //fire an event for the frontend
    TransferStack(_commit,_sender,receipt,now,_token1,_token2,_token3,_token4,_token5);
  }
  event TransferStack(bytes32 indexed _commit,address indexed _sender,bytes32 indexed _receipt,uint _timestamp,uint256 _token1,uint256 _token2,uint256 _token3,uint256 _token4,uint256 _token5);

  //tx3: either player, knowing the reveal, can generate the game
  //this tx calculates random, generates game events, and transfers
  // tokens back to winners
  //in order to make game costs fair, the frontend should randomly select
  // one of the two players and give them the reveal to generate the game
  // in a bit you could give it to the other player too .... then after the
  // timeout, they would get the secret to drain the stack
  function generateGame(bytes32 _commit,bytes32 _reveal,address _opponent,uint _token1, uint _token2, uint _token3, uint _token4, uint _token5,uint _token6, uint _token7, uint _token8, uint _token9, uint _token10){
    //verify that receipts are valid
    require( commitReceipt[_commit][msg.sender] == keccak256(_commit,msg.sender,_token1,_token2,_token3,_token4,_token5) );
    require( commitReceipt[_commit][_opponent] == keccak256(_commit,_opponent,_token6,_token7,_token8,_token9,_token10) );

    //verify we are on a later block so random will work
    require( uint32(block.number) > commitBlock[_commit][msg.sender]);
    require( uint32(block.number) > commitBlock[_commit][_opponent]);

    //verify that the reveal is correct
    require(_commit == keccak256(_reveal));

    //make sure there are exactly two stacks submitted
    require(stacksTransferred[_commit]==2);

    _generateGame(_commit,_reveal,_opponent,[_token1,_token2,_token3,_token4,_token5,_token6,_token7,_token8,_token9,_token10]);
  }

  function _generateGame(bytes32 _commit,bytes32 _reveal,address _opponent,uint[10] _tokens) internal {
    //create Cryptogs contract for transfers
    NFT cryptogsContract = NFT(cryptogsAddress);

    //generate the random using commit / reveal and blockhash from future (now past) block
    bytes32[4] memory pseudoRandoms = _generateRandom(_reveal,commitBlock[_commit][msg.sender],commitBlock[_commit][_opponent]);

    bool whosTurn = uint8(pseudoRandoms[0][0])%2==0;
    CoinFlip(_commit,whosTurn,whosTurn ? msg.sender : _opponent);
    for(uint8 round=1;round<=MAXROUNDS;round++){
      for(uint8 i=1;i<=10;i++){
        //first check and see if this token has flipped yet
        if(_tokens[i-1]>0){

          //get the random byte between 0-255 from our pseudoRandoms array of bytes32
          uint8 rand = _getRandom(pseudoRandoms,(round-1)*10 + i);

          uint8 threshold = (FLIPPINESS+round*FLIPPINESSROUNDBONUS);
          if( rand < threshold || round==MAXROUNDS ){
            _flip(_commit,round,cryptogsContract,_tokens,i-1,_opponent,whosTurn);
          }
        }
      }
      whosTurn = !whosTurn;
    }


    delete commitReceipt[_commit][msg.sender];
    delete commitReceipt[_commit][_opponent];

    GenerateGame(_commit,msg.sender);
  }
  event CoinFlip(bytes32 indexed _commit,bool _result,address _winner);
  event GenerateGame(bytes32 indexed _commit,address indexed _sender);

  function _getRandom(bytes32[4] pseudoRandoms,uint8 randIndex) internal returns (uint8 rand){
    if(randIndex<32){
      rand = uint8(pseudoRandoms[0][randIndex]);
    }else if(randIndex<64){
      rand = uint8(pseudoRandoms[1][randIndex-32]);
    }else if(randIndex<96){
      rand = uint8(pseudoRandoms[1][randIndex-64]);
    }else{
      rand = uint8(pseudoRandoms[1][randIndex-96]);
    }
    return rand;
  }

  function _generateRandom(bytes32 _reveal, uint32 block1,uint32 block2) internal returns(bytes32[4] pseudoRandoms){
    pseudoRandoms[0] = keccak256(_reveal,block.blockhash(max(block1,block2)));
    pseudoRandoms[1] = keccak256(pseudoRandoms[0]);
    pseudoRandoms[2] = keccak256(pseudoRandoms[1]);
    pseudoRandoms[3] = keccak256(pseudoRandoms[2]);
    return pseudoRandoms;
  }

  function max(uint32 a, uint32 b) private pure returns (uint32) {
      return a > b ? a : b;
  }

  function _flip(bytes32 _commit,uint8 round,NFT cryptogsContract,uint[10] _tokens,uint8 tokenIndex,address _opponent,bool whosTurn) internal {
    address flipper;
    if(whosTurn) {
      flipper=msg.sender;
    }else{
      flipper=_opponent;
    }
    cryptogsContract.transfer(flipper,_tokens[tokenIndex]);
    Flip(_commit,round,flipper,_tokens[tokenIndex]);
    _tokens[tokenIndex]=0;
  }
  event Flip(bytes32 indexed _commit,uint8 _round,address indexed _flipper,uint indexed _token);

  //if the game times out without either player generating the game,
  // (the frontend should have selected one of the players randomly to generate the game)
  //the frontend should give the other player the secret to drain the game
  // secret -> reveal -> commit
  function drainGame(bytes32 _commit,bytes32 _secret,address _opponent,uint _token1, uint _token2, uint _token3, uint _token4, uint _token5,uint _token6, uint _token7, uint _token8, uint _token9, uint _token10){
    //verify that receipts are valid
    require( commitReceipt[_commit][msg.sender] == keccak256(_commit,msg.sender,_token1,_token2,_token3,_token4,_token5) );
    require( commitReceipt[_commit][_opponent] == keccak256(_commit,_opponent,_token6,_token7,_token8,_token9,_token10) );

    //verify we are on a later block so random will work
    require( uint32(block.number) > commitBlock[_commit][msg.sender]+BLOCKTIMEOUT);
    require( uint32(block.number) > commitBlock[_commit][_opponent]+BLOCKTIMEOUT);

    //make sure the commit is the doublehash of the secret
    require(_commit == keccak256(keccak256(_secret)));

    //make sure there are exactly two stacks submitted
    require(stacksTransferred[_commit]==2);

    _drainGame(_commit,_opponent,[_token1,_token2,_token3,_token4,_token5,_token6,_token7,_token8,_token9,_token10]);
  }

  function _drainGame(bytes32 _commit,address _opponent, uint[10] _tokens) internal {
    //create Cryptogs contract for transfers
    NFT cryptogsContract = NFT(cryptogsAddress);

    cryptogsContract.transfer(msg.sender,_tokens[0]);
    cryptogsContract.transfer(msg.sender,_tokens[1]);
    cryptogsContract.transfer(msg.sender,_tokens[2]);
    cryptogsContract.transfer(msg.sender,_tokens[3]);
    cryptogsContract.transfer(msg.sender,_tokens[4]);
    cryptogsContract.transfer(msg.sender,_tokens[5]);
    cryptogsContract.transfer(msg.sender,_tokens[6]);
    cryptogsContract.transfer(msg.sender,_tokens[7]);
    cryptogsContract.transfer(msg.sender,_tokens[8]);
    cryptogsContract.transfer(msg.sender,_tokens[9]);

    Flip(_commit,1,msg.sender,_tokens[0]);
    Flip(_commit,1,msg.sender,_tokens[1]);
    Flip(_commit,1,msg.sender,_tokens[2]);
    Flip(_commit,1,msg.sender,_tokens[3]);
    Flip(_commit,1,msg.sender,_tokens[4]);
    Flip(_commit,1,msg.sender,_tokens[5]);
    Flip(_commit,1,msg.sender,_tokens[6]);
    Flip(_commit,1,msg.sender,_tokens[7]);
    Flip(_commit,1,msg.sender,_tokens[8]);
    Flip(_commit,1,msg.sender,_tokens[9]);

    delete commitReceipt[_commit][msg.sender];
    delete commitReceipt[_commit][_opponent];
    DrainGame(_commit,msg.sender);
  }
  event DrainGame(bytes32 indexed _commit,address indexed _sender);

  //if only one player ever ends up submitting a stack, they need to be able
  //to pull thier tokens back
  function revokeStack(bytes32 _commit,uint _token1, uint _token2, uint _token3, uint _token4, uint _token5){
    //verify that receipt is valid
    require( commitReceipt[_commit][msg.sender] == keccak256(_commit,msg.sender,_token1,_token2,_token3,_token4,_token5) );

    //make sure there is exactly one stacks submitted
    require(stacksTransferred[_commit]==1);

    stacksTransferred[_commit]=0;

    NFT cryptogsContract = NFT(cryptogsAddress);

    cryptogsContract.transfer(msg.sender,_token1);
    cryptogsContract.transfer(msg.sender,_token2);
    cryptogsContract.transfer(msg.sender,_token3);
    cryptogsContract.transfer(msg.sender,_token4);
    cryptogsContract.transfer(msg.sender,_token5);


    bytes32 previousReceipt = commitReceipt[_commit][msg.sender];

    delete commitReceipt[_commit][msg.sender];
    //fire an event for the frontend
    RevokeStack(_commit,msg.sender,now,_token1,_token2,_token3,_token4,_token5,previousReceipt);
  }
  event RevokeStack(bytes32 indexed _commit,address indexed _sender,uint _timestamp,uint256 _token1,uint256 _token2,uint256 _token3,uint256 _token4,uint256 _token5,bytes32 _receipt);

}

contract NFT {
  function approve(address _to,uint256 _tokenId) public returns (bool) { }
  function transfer(address _to,uint256 _tokenId) external { }
  mapping (uint256 => address) public tokenIndexToOwner;
}