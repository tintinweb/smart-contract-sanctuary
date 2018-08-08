pragma solidity ^0.4.15;

/*
  https://cryptogs.io
  --Austin Thomas Griffith for ETHDenver
  ( PS this gas guzzling beast is still unaudited )
*/


//adapted from https://github.com/ethereum/EIPs/issues/721
// thanks to Dieter Shirley && http://axiomzen.co

contract NFT {

  function NFT() public { }

  mapping (uint256 => address) public tokenIndexToOwner;
  mapping (address => uint256) ownershipTokenCount;
  mapping (uint256 => address) public tokenIndexToApproved;

  function transfer(address _to,uint256 _tokenId) public {
      require(_to != address(0));
      require(_to != address(this));
      require(_owns(msg.sender, _tokenId));
      _transfer(msg.sender, _to, _tokenId);
  }
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
      ownershipTokenCount[_to]++;
      tokenIndexToOwner[_tokenId] = _to;
      if (_from != address(0)) {
          ownershipTokenCount[_from]--;
          delete tokenIndexToApproved[_tokenId];
      }
      Transfer(_from, _to, _tokenId);
  }
  event Transfer(address from, address to, uint256 tokenId);

  function transferFrom(address _from,address _to,uint256 _tokenId) external {
      require(_to != address(0));
      require(_to != address(this));
      require(_approvedFor(msg.sender, _tokenId));
      require(_owns(_from, _tokenId));
      _transfer(_from, _to, _tokenId);
  }

  function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return tokenIndexToOwner[_tokenId] == _claimant;
  }
  function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
      return tokenIndexToApproved[_tokenId] == _claimant;
  }
  function _approve(uint256 _tokenId, address _approved) internal {
      tokenIndexToApproved[_tokenId] = _approved;
  }

  function approve(address _to,uint256 _tokenId) public returns (bool) {
      require(_owns(msg.sender, _tokenId));
      _approve(_tokenId, _to);
      Approval(msg.sender, _to, _tokenId);
      return true;
  }
  event Approval(address owner, address approved, uint256 tokenId);

  function balanceOf(address _owner) public view returns (uint256 count) {
      return ownershipTokenCount[_owner];
  }

  function ownerOf(uint256 _tokenId) external view returns (address owner) {
      owner = tokenIndexToOwner[_tokenId];
      require(owner != address(0));
  }

  function allowance(address _claimant, uint256 _tokenId) public view returns (bool) {
      return _approvedFor(_claimant,_tokenId);
  }
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract Cryptogs is NFT, Ownable {

    string public constant name = "Cryptogs";
    string public constant symbol = "POGS";

    string public constant purpose = "ETHDenver";
    string public constant contact = "https://cryptogs.io";
    string public constant author = "Austin Thomas Griffith";

    uint8 public constant FLIPPINESS = 64;
    uint8 public constant FLIPPINESSROUNDBONUS = 16;
    uint8 public constant TIMEOUTBLOCKS = 180;
    uint8 public constant BLOCKSUNTILCLEANUPSTACK=1;

    string public ipfs;
    function setIpfs(string _ipfs) public onlyOwner returns (bool){
      ipfs=_ipfs;
      IPFS(ipfs);
      return true;
    }
    event IPFS(string ipfs);

    function Cryptogs() public {
      //0 index should be a blank item owned by no one
      Item memory _item = Item({
        image: ""
      });
      items.push(_item);
    }

    address public slammerTime;
    function setSlammerTime(address _slammerTime) public onlyOwner returns (bool){
      //in order to trust that this contract isn&#39;t sending a player&#39;s tokens
      // to a different contract, the slammertime contract is set once and
      // only once -- at deploy
      require(slammerTime==address(0));
      slammerTime=_slammerTime;
      return true;
    }

    struct Item{
      bytes32 image;
      //perhaps some are harder to flip over?
      //perhaps some have magical metadata?
      //I don&#39;t know, it&#39;s late and I&#39;m weird
    }

    Item[] private items;

    function mint(bytes32 _image,address _owner) public onlyOwner returns (uint){
      uint256 newId = _mint(_image);
      _transfer(0, _owner, newId);
      Mint(items[newId].image,tokenIndexToOwner[newId],newId);
      return newId;
    }
    event Mint(bytes32 _image,address _owner,uint256 _id);

    function mintBatch(bytes32 _image1,bytes32 _image2,bytes32 _image3,bytes32 _image4,bytes32 _image5,address _owner) public onlyOwner returns (bool){
      uint256 newId = _mint(_image1);
      _transfer(0, _owner, newId);
      Mint(_image1,tokenIndexToOwner[newId],newId);
      newId=_mint(_image2);
      _transfer(0, _owner, newId);
      Mint(_image2,tokenIndexToOwner[newId],newId);
      newId=_mint(_image3);
      _transfer(0, _owner, newId);
      Mint(_image3,tokenIndexToOwner[newId],newId);
      newId=_mint(_image4);
      _transfer(0, _owner, newId);
      Mint(_image4,tokenIndexToOwner[newId],newId);
      newId=_mint(_image5);
      _transfer(0, _owner, newId);
      Mint(_image5,tokenIndexToOwner[newId],newId);
      return true;
    }

    function _mint(bytes32 _image) internal returns (uint){
      Item memory _item = Item({
        image: _image
      });
      uint256 newId = items.push(_item) - 1;
      tokensOfImage[items[newId].image]++;
      return newId;
    }

    Pack[] private packs;
    struct Pack{
      uint256[10] tokens;
      uint256 price;
    }
    function mintPack(uint256 _price,bytes32 _image1,bytes32 _image2,bytes32 _image3,bytes32 _image4,bytes32 _image5,bytes32 _image6,bytes32 _image7,bytes32 _image8,bytes32 _image9,bytes32 _image10) public onlyOwner returns (bool){
      uint256[10] memory tokens;
      tokens[0] = _mint(_image1);
      tokens[1] = _mint(_image2);
      tokens[2] = _mint(_image3);
      tokens[3] = _mint(_image4);
      tokens[4] = _mint(_image5);
      tokens[5] = _mint(_image6);
      tokens[6] = _mint(_image7);
      tokens[7] = _mint(_image8);
      tokens[8] = _mint(_image9);
      tokens[9] = _mint(_image10);
      Pack memory _pack = Pack({
        tokens: tokens,
        price: _price
      });
      MintPack(packs.push(_pack) - 1, _price,tokens[0],tokens[1],tokens[2],tokens[3],tokens[4],tokens[5],tokens[6],tokens[7],tokens[8],tokens[9]);
      return true;
    }
    event MintPack(uint256 packId,uint256 price,uint256 token1,uint256 token2,uint256 token3,uint256 token4,uint256 token5,uint256 token6,uint256 token7,uint256 token8,uint256 token9,uint256 token10);

    function buyPack(uint256 packId) public payable returns (bool) {
      //make sure pack is for sale
      require( packs[packId].price > 0 );
      //make sure they sent in enough value
      require( msg.value >= packs[packId].price );
      //right away set price to 0 to avoid some sort of reentrance
      packs[packId].price=0;
      //give tokens to owner
      for(uint8 i=0;i<10;i++){
        tokenIndexToOwner[packs[packId].tokens[i]]=msg.sender;
        _transfer(0, msg.sender, packs[packId].tokens[i]);
      }
      //clear the price so it is no longer for sale
      delete packs[packId];
      BuyPack(msg.sender,packId,msg.value);
    }
    event BuyPack(address sender, uint256 packId, uint256 price);

    //lets keep a count of how many of a specific image is created too
    //that will allow us to calculate rarity on-chain if we want
    mapping (bytes32 => uint256) public tokensOfImage;

    function getToken(uint256 _id) public view returns (address owner,bytes32 image,uint256 copies) {
      image = items[_id].image;
      copies = tokensOfImage[image];
      return (
        tokenIndexToOwner[_id],
        image,
        copies
      );
    }

    uint256 nonce = 0;

    struct Stack{
      //this will be an array of ids but for now just doing one for simplicity
      uint256[5] ids;
      address owner;
      uint32 block;

    }

    mapping (bytes32 => Stack) public stacks;
    mapping (bytes32 => bytes32) public stackCounter;

    function stackOwner(bytes32 _stack) public constant returns (address owner) {
      return stacks[_stack].owner;
    }

    function getStack(bytes32 _stack) public constant returns (address owner,uint32 block,uint256 token1,uint256 token2,uint256 token3,uint256 token4,uint256 token5) {
      return (stacks[_stack].owner,stacks[_stack].block,stacks[_stack].ids[0],stacks[_stack].ids[1],stacks[_stack].ids[2],stacks[_stack].ids[3],stacks[_stack].ids[4]);
    }

    //tx 1: of a game, player one approves the SlammerTime contract to take their tokens
    //this triggers an event to broadcast to other players that there is an open challenge
    function submitStack(uint256 _id,uint256 _id2,uint256 _id3,uint256 _id4,uint256 _id5, bool _public) public returns (bool) {
      //make sure slammerTime was set at deploy
      require(slammerTime!=address(0));
      //the sender must own the token
      require(tokenIndexToOwner[_id]==msg.sender);
      require(tokenIndexToOwner[_id2]==msg.sender);
      require(tokenIndexToOwner[_id3]==msg.sender);
      require(tokenIndexToOwner[_id4]==msg.sender);
      require(tokenIndexToOwner[_id5]==msg.sender);
      //they approve the slammertime contract to take the token away from them
      require(approve(slammerTime,_id));
      require(approve(slammerTime,_id2));
      require(approve(slammerTime,_id3));
      require(approve(slammerTime,_id4));
      require(approve(slammerTime,_id5));

      bytes32 stack = keccak256(nonce++,msg.sender);
      uint256[5] memory ids = [_id,_id2,_id3,_id4,_id5];
      stacks[stack] = Stack(ids,msg.sender,uint32(block.number));

      //the event is triggered to the frontend to display the stack
      //the frontend will check if they want it public or not
      SubmitStack(msg.sender,now,stack,_id,_id2,_id3,_id4,_id5,_public);
    }
    event SubmitStack(address indexed _sender,uint256 indexed timestamp,bytes32 indexed _stack,uint256 _token1,uint256 _token2,uint256 _token3,uint256 _token4,uint256 _token5,bool _public);

    //tx 2: of a game, player two approves the SlammerTime contract to take their tokens
    //this triggers an event to broadcast to player one that this player wants to rumble
    function submitCounterStack(bytes32 _stack, uint256 _id, uint256 _id2, uint256 _id3, uint256 _id4, uint256 _id5) public returns (bool) {
      //make sure slammerTime was set at deploy
      require(slammerTime!=address(0));
      //the sender must own the token
      require(tokenIndexToOwner[_id]==msg.sender);
      require(tokenIndexToOwner[_id2]==msg.sender);
      require(tokenIndexToOwner[_id3]==msg.sender);
      require(tokenIndexToOwner[_id4]==msg.sender);
      require(tokenIndexToOwner[_id5]==msg.sender);
      //they approve the slammertime contract to take the token away from them
      require(approve(slammerTime,_id));
      require(approve(slammerTime,_id2));
      require(approve(slammerTime,_id3));
      require(approve(slammerTime,_id4));
      require(approve(slammerTime,_id5));
      //stop playing with yourself
      require(msg.sender!=stacks[_stack].owner);

      bytes32 counterstack = keccak256(nonce++,msg.sender,_id);
      uint256[5] memory ids = [_id,_id2,_id3,_id4,_id5];
      stacks[counterstack] = Stack(ids,msg.sender,uint32(block.number));
      stackCounter[counterstack] = _stack;

      //the event is triggered to the frontend to display the stack
      //the frontend will check if they want it public or not
      CounterStack(msg.sender,now,_stack,counterstack,_id,_id2,_id3,_id4,_id5);
    }
    event CounterStack(address indexed _sender,uint256 indexed timestamp,bytes32 indexed _stack, bytes32 _counterStack, uint256 _token1, uint256 _token2, uint256 _token3, uint256 _token4, uint256 _token5);

    // if someone creates a stack they should be able to clean it up
    // its not really that big of a deal because we will have a timeout
    // in the frontent, but still...
    function cancelStack(bytes32 _stack) public returns (bool) {
      //it must be your stack
      require(msg.sender==stacks[_stack].owner);
      //make sure there is no mode set yet
      require(mode[_stack]==0);
      //make sure they aren&#39;t trying to cancel a counterstack using this function
      require(stackCounter[_stack]==0x00000000000000000000000000000000);

      delete stacks[_stack];

      CancelStack(msg.sender,now,_stack);
    }
    event CancelStack(address indexed _sender,uint256 indexed timestamp,bytes32 indexed _stack);

    function cancelCounterStack(bytes32 _stack,bytes32 _counterstack) public returns (bool) {
      //it must be your stack
      require(msg.sender==stacks[_counterstack].owner);
      //the counter must be a counter of stack 1
      require(stackCounter[_counterstack]==_stack);
      //make sure there is no mode set yet
      require(mode[_stack]==0);

      delete stacks[_counterstack];
      delete stackCounter[_counterstack];

      CancelCounterStack(msg.sender,now,_stack,_counterstack);
    }
    event CancelCounterStack(address indexed _sender,uint256 indexed timestamp,bytes32 indexed _stack,bytes32 _counterstack);

    mapping (bytes32 => bytes32) public counterOfStack;
    mapping (bytes32 => uint8) public mode;
    mapping (bytes32 => uint8) public round;
    mapping (bytes32 => uint32) public lastBlock;
    mapping (bytes32 => uint32) public commitBlock;
    mapping (bytes32 => address) public lastActor;
    mapping (bytes32 => uint256[10]) public mixedStack;

    //tx 3: of a game, player one approves counter stack and transfers everything in
    function acceptCounterStack(bytes32 _stack, bytes32 _counterStack) public returns (bool) {
      //sender must be owner of stack 1
      require(msg.sender==stacks[_stack].owner);
      //the counter must be a counter of stack 1
      require(stackCounter[_counterStack]==_stack);
      //make sure there is no mode set yet
      require(mode[_stack]==0);

      //do the transfer
      SlammerTime slammerTimeContract = SlammerTime(slammerTime);
      require( slammerTimeContract.startSlammerTime(msg.sender,stacks[_stack].ids,stacks[_counterStack].owner,stacks[_counterStack].ids) );

      //save the block for a timeout
      lastBlock[_stack]=uint32(block.number);
      lastActor[_stack]=stacks[_counterStack].owner;
      mode[_stack]=1;
      counterOfStack[_stack]=_counterStack;

      //// LOL @
      mixedStack[_stack][0] = stacks[_stack].ids[0];
      mixedStack[_stack][1] = stacks[_counterStack].ids[0];
      mixedStack[_stack][2] = stacks[_stack].ids[1];
      mixedStack[_stack][3] = stacks[_counterStack].ids[1];
      mixedStack[_stack][4] = stacks[_stack].ids[2];
      mixedStack[_stack][5] = stacks[_counterStack].ids[2];
      mixedStack[_stack][6] = stacks[_stack].ids[3];
      mixedStack[_stack][7] = stacks[_counterStack].ids[3];
      mixedStack[_stack][8] = stacks[_stack].ids[4];
      mixedStack[_stack][9] = stacks[_counterStack].ids[4];

      //let the front end know that the transfer is good and we are ready for the coin flip
      AcceptCounterStack(msg.sender,_stack,_counterStack);
    }
    event AcceptCounterStack(address indexed _sender,bytes32 indexed _stack, bytes32 indexed _counterStack);

    mapping (bytes32 => bytes32) public commit;

    function getMixedStack(bytes32 _stack) external view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
      uint256[10] thisStack = mixedStack[_stack];
      return (thisStack[0],thisStack[1],thisStack[2],thisStack[3],thisStack[4],thisStack[5],thisStack[6],thisStack[7],thisStack[8],thisStack[9]);
    }

    //tx 4: player one commits and flips coin up
    //at this point, the timeout goes into effect and if any transaction including
    //the coin flip don&#39;t come back in time, we need to allow the other party
    //to withdraw all tokens... this keeps either player from refusing to
    //reveal their commit. (every tx from here on out needs to update the lastBlock and lastActor)
    //and in the withdraw function you check currentblock-lastBlock > timeout = refund to lastActor
    //and by refund I mean let them withdraw if they want
    //we could even have a little timer on the front end that tells you how long your opponnet has
    //before they will forfet
    function startCoinFlip(bytes32 _stack, bytes32 _counterStack, bytes32 _commit) public returns (bool) {
      //make sure it&#39;s the owner of the first stack (player one) doing the flip
      require(stacks[_stack].owner==msg.sender);
      //the counter must be a counter of stack 1
      require(stackCounter[_counterStack]==_stack);
      require(counterOfStack[_stack]==_counterStack);
      //make sure that we are in mode 1
      require(mode[_stack]==1);
      //store the commit for the next tx
      commit[_stack]=_commit;
      commitBlock[_stack]=uint32(block.number);
      //inc the mode to 2
      mode[_stack]=2;
      StartCoinFlip(_stack,_commit);
    }
    event StartCoinFlip(bytes32 stack, bytes32 commit);

    //tx5: player one ends coin flip with reveal
    function endCoinFlip(bytes32 _stack, bytes32 _counterStack, bytes32 _reveal) public returns (bool) {
      //make sure it&#39;s the owner of the first stack (player one) doing the flip
      require(stacks[_stack].owner==msg.sender);
      //the counter must be a counter of stack 1
      require(stackCounter[_counterStack]==_stack);
      require(counterOfStack[_stack]==_counterStack);
      //make sure that we are in mode 2
      require(mode[_stack]==2);

      //make sure that we are on a later block than the commit block
      require(uint32(block.number)>commitBlock[_stack]);

      //make sure hash of reveal == commit
      if(keccak256(_reveal)!=commit[_stack]){
        //commit/reveal failed.. this can happen if they
        //reload, so don&#39;t punish, just go back to the
        //start of the coin flip stage
        mode[_stack]=1;
        CoinFlipFail(_stack);
        return false;
      }else{
        //successful coin flip, ready to get random
        mode[_stack]=3;
        round[_stack]=1;
        bytes32 pseudoRandomHash = keccak256(_reveal,block.blockhash(commitBlock[_stack]));
        if(uint256(pseudoRandomHash)%2==0){
          //player1 goes first
          lastBlock[_stack]=uint32(block.number);
          lastActor[_stack]=stacks[_counterStack].owner;
          CoinFlipSuccess(_stack,stacks[_stack].owner,true);
        }else{
          //player2 goes first
          lastBlock[_stack]=uint32(block.number);
          lastActor[_stack]=stacks[_stack].owner;
          CoinFlipSuccess(_stack,stacks[_counterStack].owner,false);
        }
        return true;
      }

    }
    event CoinFlipSuccess(bytes32 indexed stack,address whosTurn,bool heads);
    event CoinFlipFail(bytes32 stack);


    //tx6 next player raises slammer
    function raiseSlammer(bytes32 _stack, bytes32 _counterStack, bytes32 _commit) public returns (bool) {
      if(lastActor[_stack]==stacks[_stack].owner){
        //it is player2&#39;s turn
        require(stacks[_counterStack].owner==msg.sender);
      }else{
        //it is player1&#39;s turn
        require(stacks[_stack].owner==msg.sender);
      }
      //the counter must be a counter of stack 1
      require(stackCounter[_counterStack]==_stack);
      require(counterOfStack[_stack]==_counterStack);
      //make sure that we are in mode 3
      require(mode[_stack]==3);
      //store the commit for the next tx
      commit[_stack]=_commit;
      commitBlock[_stack]=uint32(block.number);
      //inc the mode to 2
      mode[_stack]=4;
      RaiseSlammer(_stack,_commit);
    }
    event RaiseSlammer(bytes32 stack, bytes32 commit);


    //tx7 player throws slammer
    function throwSlammer(bytes32 _stack, bytes32 _counterStack, bytes32 _reveal) public returns (bool) {
      if(lastActor[_stack]==stacks[_stack].owner){
        //it is player2&#39;s turn
        require(stacks[_counterStack].owner==msg.sender);
      }else{
        //it is player1&#39;s turn
        require(stacks[_stack].owner==msg.sender);
      }
      //the counter must be a counter of stack 1
      require(stackCounter[_counterStack]==_stack);
      require(counterOfStack[_stack]==_counterStack);
      //make sure that we are in mode 4
      require(mode[_stack]==4);

      //make sure that we are on a later block than the commit block
      require(uint32(block.number)>commitBlock[_stack]);

      uint256[10] memory flipped;
      if(keccak256(_reveal)!=commit[_stack]){
        //commit/reveal failed.. this can happen if they
        //reload, so don&#39;t punish, just go back to the
        //start of the slammer raise
        mode[_stack]=3;
        throwSlammerEvent(_stack,msg.sender,address(0),flipped);
        return false;
      }else{
        //successful slam!!!!!!!!!!!! At this point I have officially been awake for 24 hours !!!!!!!!!!
        mode[_stack]=3;

        address previousLastActor = lastActor[_stack];

        bytes32 pseudoRandomHash = keccak256(_reveal,block.blockhash(commitBlock[_stack]));
        //Debug(_reveal,block.blockhash(block.number-1),pseudoRandomHash);
        if(lastActor[_stack]==stacks[_stack].owner){
          //player1 goes next
          lastBlock[_stack]=uint32(block.number);
          lastActor[_stack]=stacks[_counterStack].owner;
        }else{
          //player2 goes next
          lastBlock[_stack]=uint32(block.number);
          lastActor[_stack]=stacks[_stack].owner;
        }

        //look through the stack of remaining pogs and compare to byte to see if less than FLIPPINESS and transfer back to correct owner
        // oh man, that smells like reentrance --  I think the mode would actually break that right?
        bool done=true;
        uint8 randIndex = 0;
        for(uint8 i=0;i<10;i++){
          if(mixedStack[_stack][i]>0){
            //there is still a pog here, check for flip
            uint8 thisFlipper = uint8(pseudoRandomHash[randIndex++]);
            //DebugFlip(pseudoRandomHash,i,randIndex,thisFlipper,FLIPPINESS);
            if(thisFlipper<(FLIPPINESS+round[_stack]*FLIPPINESSROUNDBONUS)){
              //ITS A FLIP!
               uint256 tempId = mixedStack[_stack][i];
               flipped[i]=tempId;
               mixedStack[_stack][i]=0;
               SlammerTime slammerTimeContract = SlammerTime(slammerTime);
               //require( slammerTimeContract.transferBack(msg.sender,tempId) );
               slammerTimeContract.transferBack(msg.sender,tempId);
            }else{
              done=false;
            }
          }
        }

        throwSlammerEvent(_stack,msg.sender,previousLastActor,flipped);

        if(done){
          FinishGame(_stack);
          mode[_stack]=9;
          delete mixedStack[_stack];
          delete stacks[_stack];
          delete stackCounter[_counterStack];
          delete stacks[_counterStack];
          delete lastBlock[_stack];
          delete lastActor[_stack];
          delete counterOfStack[_stack];
          delete round[_stack];
          delete commitBlock[_stack];
          delete commit[_stack];
        }else{
          round[_stack]++;
        }

        return true;
      }
    }
    event ThrowSlammer(bytes32 indexed stack, address indexed whoDoneIt, address indexed otherPlayer, uint256 token1Flipped, uint256 token2Flipped, uint256 token3Flipped, uint256 token4Flipped, uint256 token5Flipped, uint256 token6Flipped, uint256 token7Flipped, uint256 token8Flipped, uint256 token9Flipped, uint256 token10Flipped);
    event FinishGame(bytes32 stack);

    function throwSlammerEvent(bytes32 stack,address whoDoneIt,address otherAccount, uint256[10] flipArray) internal {
      ThrowSlammer(stack,whoDoneIt,otherAccount,flipArray[0],flipArray[1],flipArray[2],flipArray[3],flipArray[4],flipArray[5],flipArray[6],flipArray[7],flipArray[8],flipArray[9]);
    }


    function drainStack(bytes32 _stack, bytes32 _counterStack) public returns (bool) {
      //this function is for the case of a timeout in the commit / reveal
      // if a player realizes they are going to lose, they can refuse to reveal
      // therefore we must have a timeout of TIMEOUTBLOCKS and if that time is reached
      // the other player can get in and drain the remaining tokens from the game
      require( stacks[_stack].owner==msg.sender || stacks[_counterStack].owner==msg.sender );
      //the counter must be a counter of stack 1
      require( stackCounter[_counterStack]==_stack );
      require( counterOfStack[_stack]==_counterStack );
      //the bad guy shouldn&#39;t be able to drain
      require( lastActor[_stack]==msg.sender );
      //must be after timeout period
      require( block.number - lastBlock[_stack] >= TIMEOUTBLOCKS);
      //game must still be going
      require( mode[_stack]<9 );

      for(uint8 i=0;i<10;i++){
        if(mixedStack[_stack][i]>0){
          uint256 tempId = mixedStack[_stack][i];
          mixedStack[_stack][i]=0;
          SlammerTime slammerTimeContract = SlammerTime(slammerTime);
          slammerTimeContract.transferBack(msg.sender,tempId);
        }
      }

      FinishGame(_stack);
      mode[_stack]=9;

      delete mixedStack[_stack];
      delete stacks[_stack];
      delete stackCounter[_counterStack];
      delete stacks[_counterStack];
      delete lastBlock[_stack];
      delete lastActor[_stack];
      delete counterOfStack[_stack];
      delete round[_stack];
      delete commitBlock[_stack];
      delete commit[_stack];

      DrainStack(_stack,_counterStack,msg.sender);
    }
    event DrainStack(bytes32 stack,bytes32 counterStack,address sender);

    function totalSupply() public view returns (uint) {
        return items.length - 1;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;
            uint256 id;
            for (id = 1; id <= total; id++) {
                if (tokenIndexToOwner[id] == _owner) {
                    result[resultIndex] = id;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    function withdraw(uint256 _amount) public onlyOwner returns (bool) {
      require(this.balance >= _amount);
      assert(owner.send(_amount));
      return true;
    }

    function withdrawToken(address _token,uint256 _amount) public onlyOwner returns (bool) {
      StandardToken token = StandardToken(_token);
      token.transfer(msg.sender,_amount);
      return true;
    }


    //adapted from ERC-677 from my dude Steve Ellis - thanks man!
    function transferStackAndCall(address _to, uint _token1, uint _token2, uint _token3, uint _token4, uint _token5, bytes32 _data) public returns (bool) {
      transfer(_to, _token1);
      transfer(_to, _token2);
      transfer(_to, _token3);
      transfer(_to, _token4);
      transfer(_to, _token5);

      if (isContract(_to)) {
        contractFallback(_to,_token1,_token2,_token3,_token4,_token5,_data);
      }
      return true;
    }

    function contractFallback(address _to, uint _token1, uint _token2, uint _token3, uint _token4, uint _token5, bytes32 _data) private {
      StackReceiver receiver = StackReceiver(_to);
      receiver.onTransferStack(msg.sender,_token1,_token2,_token3,_token4,_token5,_data);
    }

    function isContract(address _addr) private returns (bool hasCode) {
      uint length;
      assembly { length := extcodesize(_addr) }
      return length > 0;
    }

}

contract StackReceiver {
  function onTransferStack(address _sender, uint _token1, uint _token2, uint _token3, uint _token4, uint _token5, bytes32 _data);
}

contract StandardToken {
  function transfer(address _to, uint256 _value) public returns (bool) { }
}

contract SlammerTime {
  function startSlammerTime(address _player1,uint256[5] _id1,address _player2,uint256[5] _id2) public returns (bool) { }
  function transferBack(address _toWhom, uint256 _id) public returns (bool) { }
}