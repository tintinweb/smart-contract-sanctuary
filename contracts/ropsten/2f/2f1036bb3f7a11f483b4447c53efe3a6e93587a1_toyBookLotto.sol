pragma solidity ^0.4.21;


//------------------------------
//  Draw Lotto for book price
//------------------------------
contract toyBookLotto {

  //owner of lotto
  mapping (uint => address) public lottoToOwner;
  //current number of lottos
  uint public numOfLotto;
  uint public timeStamp;

  //winner id and address
  address public winnerAddress;
  uint public winnerLottoId;

  //winner reward price (before fee substract)
  uint public winnerReward;

  //owner of this contract can get the fee 
  address public owner;


  event DrawBookLotto(address _address, uint _lottoId);
  event BuyBookLotto(address _address, uint _lottoId);

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  constructor() public {
    numOfLotto = 0;
    owner = msg.sender;
    winnerReward = 0;
  }

  //fallback function 
  function () external {
    buyBookLotto();
  }

  //buy a lottery for free
  function buyBookLotto() public {
    //check the person already have it or not
    for(uint i=0 ; i<numOfLotto ; i++){
      require(msg.sender != lottoToOwner[i]);
    }
    //allocate new owner of lotto
    lottoToOwner[numOfLotto++] = msg.sender;
    emit BuyBookLotto(msg.sender, numOfLotto);
  }

  //function draw a lottery
  function drawBookLotto() public onlyOwner {
    //require(numOfLotto > 3);
    timeStamp = block.timestamp;
    //set winner 
    winnerLottoId = timeStamp % numOfLotto;
    winnerAddress = lottoToOwner[winnerLottoId];

    uint winnerAmount = address(this).balance;
    winnerAddress.transfer(winnerAmount);

    //delete all 
    for (uint i=0 ; i<numOfLotto ; i++){
      delete lottoToOwner[i];
    }
    numOfLotto = 0;
    emit DrawBookLotto(winnerAddress, winnerLottoId);
  }

  //for winner Reward with 9 ETH
  function depositReward() public payable onlyOwner {
    winnerReward = winnerReward + msg.value;
  }

  //check whos winner
  function checkWinner() public view returns(address, uint) {
    return (winnerAddress, winnerLottoId);
  }

  function getNumOfLotto() public view returns(uint) {
    return numOfLotto;
  }



}