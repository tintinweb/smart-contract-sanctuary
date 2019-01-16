pragma solidity ^0.4.25; // solhint-disable-line


contract EtherAsteroid{
  using SafeMath for uint;
  uint16 public xPos;//position of eth transport ship in space
  uint16 public yPos;
  int256 public xVel=0;//units ship will travel per hour, can be negative
  int256 public yVel=0;
  uint public Nfuel=0;//north fuel, accelerates ship downward
  uint public Sfuel=0;//south fuel, up
  uint public Efuel=0;//east, left
  uint public Wfuel=0;//west, right
  uint public FUEL_BURN_PERCENT=15;//percent of current fuel burned every hour
  uint16 public MAXVALUE=0;//max uint (set in constructor)
  uint16 public MAX_VELOCITY=1000;//maximum velocity
  int public MAX_RAW_VELOCITY=10000;//maximum velocity before transformation
  int256 private PSN=10000;//variable used to compensate for lack of floats
  uint public constant NUM_SECTORS=64;//how many sectors across and vertically the universe is divided into
  uint16 public sectorDivisor;
  uint public lastBurn;//the last recorded time fuel was burned to generate thrust.
  uint public BURN_INTERVAL=1 hours;//how long between fuel burns
  address public ceo;
  FuelBuys public fuelMarket;
  bool public initialized=false;
  uint public constant PLANET_START_PRICE=0.05 ether;
  struct Planet{
    address owner;
    uint price;
  }
  uint[NUM_SECTORS][NUM_SECTORS] public planetLocations;// X,Y  contains index of planet
  Planet[10] public planets;//contains info on the various planets. Array starts at 1 (because planetLocations has to use zero for default value).

  uint public additionalTime=0;//used for testing, artificially advance time

  event FuelBurn(int256 xAccel,int256 yAccel);


  function EtherAsteroid(){
      //set xPos and yPos to half of the maximum uint256 value
      MAXVALUE-=1;
      xPos=MAXVALUE/2;
      yPos=MAXVALUE/2;
      sectorDivisor=uint16(MAXVALUE/NUM_SECTORS);
      lastBurn=now;
      ceo=msg.sender;
      fuelMarket=new FuelBuys();
      fuelMarket.setFuelDestination(address(this));
      for(uint i=1;i<planets.length;i++){
        planets[i]=Planet({owner:address(0),price:PLANET_START_PRICE});
      }
      //fuelContract=address(0x555555555555555);
  }
  function setFuelContract(address fuel) public{
    require(msg.sender==ceo);
    fuelMarket=FuelBuys(fuel);
  }
  /*






    FOR USE IN TESTING ONLY IF THIS IS STILL IN MAINNET TELL ME BC I FUCKED UP







  */
  function addFuelFree(uint n,uint s,uint e,uint w) public{
    Nfuel+=n;
    Sfuel+=s;
    Efuel+=e;
    Wfuel+=w;
    updatePosition();
  }
  function addCurrentTime(uint8 steps) public {
    additionalTime+=steps*BURN_INTERVAL;
  }


  function addFuel(uint n,uint s,uint e,uint w,uint fuelBought) public payable{
    require(msg.sender==address(fuelMarket));
    require(initialized);
    updatePosition();//update position before adding new fuel
    //uint fuelBought=fuelMarket.buyFuel(fuelPay);
    require(fuelBought>=n.add(s).add(e).add(w)); //ensure all fuel is paid for
    Nfuel+=n;
    Sfuel+=s;
    Efuel+=e;
    Wfuel+=w;


  }
  //allow sending eth to the contract (used internally, don&#39;t send eth directly to this contract or it will be loset forever)
  function () public payable {}

  function positionAtIteration(uint iteration) public view returns(uint16 x,uint16 y){
    uint16 tempx=xPos;
    uint16 tempy=yPos;
    int256 tempvelx=xVel;
    int256 tempvely=yVel;
    uint Nfueltemp=Nfuel;//north fuel, accelerates ship downward
    uint Sfueltemp=Sfuel;//south fuel, up
    uint Efueltemp=Efuel;//east, left
    uint Wfueltemp=Wfuel;//west, right
    uint count=0;
    while(count<iteration){
      count++;
      tempx=uint16(tempx+velReduction(tempvelx));//these can underflow and overflow, that is intended, classic arcade rules
      tempy=uint16(tempy+velReduction(tempvely));
      processCollision();

      //update velocity and fuel
      uint wBurn=Wfueltemp.mul(FUEL_BURN_PERCENT).div(100);
      uint eBurn=Efueltemp.mul(FUEL_BURN_PERCENT).div(100);
      uint nBurn=Nfueltemp.mul(FUEL_BURN_PERCENT).div(100);
      uint sBurn=Sfueltemp.mul(FUEL_BURN_PERCENT).div(100);
      tempvelx=min(MAX_RAW_VELOCITY,tempvelx+int(wBurn)-int(eBurn));
      tempvely=min(MAX_RAW_VELOCITY,tempvely+int(sBurn)-int(nBurn));

      Wfueltemp=Wfueltemp.sub(wBurn);
      Efueltemp=Efueltemp.sub(eBurn);
      Nfueltemp=Nfueltemp.sub(nBurn);
      Sfueltemp=Sfueltemp.sub(sBurn);

      lastBurn=lastBurn.add(BURN_INTERVAL);
    }
    return (tempx,tempy);
  }
  function currentTime() public view returns(uint){
    return now+additionalTime;
  }
  function updatePosition() public{
    uint16 tempx=xPos;
    uint16 tempy=yPos;
    int256 tempvelx=xVel;
    int256 tempvely=yVel;
    uint Nfueltemp=Nfuel;//north fuel, accelerates ship downward
    uint Sfueltemp=Sfuel;//south fuel, up
    uint Efueltemp=Efuel;//east, left
    uint Wfueltemp=Wfuel;//west, right
    while(lastBurn.add(BURN_INTERVAL)<currentTime()){
      tempx=uint16(tempx+velReduction(tempvelx));//these can underflow and overflow, that is intended, classic arcade rules
      tempy=uint16(tempy+velReduction(tempvely));
      processCollision();

      //update velocity and fuel
      uint wBurn=Wfueltemp.mul(FUEL_BURN_PERCENT).div(100);
      uint eBurn=Efueltemp.mul(FUEL_BURN_PERCENT).div(100);
      uint nBurn=Nfueltemp.mul(FUEL_BURN_PERCENT).div(100);
      uint sBurn=Sfueltemp.mul(FUEL_BURN_PERCENT).div(100);
      tempvelx=tempvelx+int(wBurn)-int(eBurn);
      tempvely=tempvely+int(sBurn)-int(nBurn);
      if(tempvelx>MAX_RAW_VELOCITY){
        tempvelx=MAX_RAW_VELOCITY;
      }
      if(tempvelx<-1*MAX_RAW_VELOCITY){
        tempvelx=-1*MAX_RAW_VELOCITY;
      }
      if(tempvely>MAX_RAW_VELOCITY){
        tempvely=MAX_RAW_VELOCITY;
      }
      if(tempvely<-1*MAX_RAW_VELOCITY){
        tempvely=-1*MAX_RAW_VELOCITY;
      }
      emit FuelBurn(tempvelx,tempvely);
      Wfueltemp=Wfueltemp.sub(wBurn);
      Efueltemp=Efueltemp.sub(eBurn);
      Nfueltemp=Nfueltemp.sub(nBurn);
      Sfueltemp=Sfueltemp.sub(sBurn);

      lastBurn=lastBurn.add(BURN_INTERVAL);
    }
    //write at the end to save gas
    xPos=tempx;
    yPos=tempy;
    xVel=tempvelx;
    yVel=tempvely;
    Nfuel=Nfueltemp;
    Sfuel=Sfueltemp;
    Efuel=Efueltemp;
    Wfuel=Wfueltemp;
  }
  function processCollision() public{
    uint planetId=planetLocations[xPos/sectorDivisor][yPos/sectorDivisor];
    if(planetId!=0){
      //Game is over! distribute eth package to the winner
      planets[planetId].owner.send(this.balance);
      initialized=false;
    }
  }
  function purchasePlanet(uint index) public payable{
    Planet storage planet=planets[index];
    require(msg.value >= planet.price);
    uint256 sellingPrice=planet.price;
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 90), 100));
    //10 percent remaining in the contract goes to the pot
    //if the owner is 0, this is the first purchase, and payment should go to the pot
    if(planet.owner!=0x0){
        planet.owner.send(payment);
    }
    planet.price= SafeMath.div(SafeMath.mul(sellingPrice, 120), 90); //purchaser gets 120% of sent eth if it is purchased again
    planet.owner=msg.sender;//transfer ownership
    msg.sender.transfer(purchaseExcess);//returns excess eth
  }
  function velReduction(int256 velocity) public view returns(int256){
    int velmul=1;
    if(velocity<0){
      velocity=velocity*-1;
      velmul=-1;
    }
    assert(PSN*(velocity+MAX_VELOCITY)>velocity);

    //this formula gives a value lower than the input velocity, increasing up to a maximum of MAX_VELOCITY in a curve with increasingly diminishing returns.
    velocity=(PSN*velocity)/((PSN*(velocity+MAX_VELOCITY))/MAX_VELOCITY);
    return velmul*velocity;
  }
  function min(int256 a, int256 b) private pure returns (int256) {
      return a < b ? a : b;
  }
  function getBalance() public view returns(uint){
    return this.balance;
  }
}
contract FuelBuys{
  using SafeMath for uint;
  mapping(address => uint256) public tokenBalanceLedger_;
  mapping(address => int256) public payoutsTo_;
  uint256 public tokenSupply_ = 0;
  uint256 public profitPerShare_;
  uint8 constant public decimals = 18;
  uint256 constant internal magnitude = 2**64;
  uint256 constant internal tokenPriceInitial_ = 0.0000001 ether;
  uint256 constant internal tokenPriceIncremental_ = 0.00000001 ether;
  //uint8 constant internal dividendFee_ = 10;
  uint public constant POT_TAKE=20;//percent of fuel buys that go to the pot
  uint public constant DEV_FEE=3;//percent of buys that go to dev
  uint public constant REF_FEE=2;//percent of buys that go to referral address
  EtherAsteroid fuelDestination;

  event onTokenPurchase(
      address indexed customerAddress,
      uint256 incomingEthereum,
      uint256 tokensMinted,
      address indexed referredBy
  );

  function setFuelDestination(address dest){
    fuelDestination=EtherAsteroid(dest);
  }
  function buyFuel(uint n,uint s,uint e,uint w, address referral) public payable{
    uint dfee=msg.value.mul(DEV_FEE).div(100);
    uint rfee=msg.value.mul(REF_FEE).div(100);
    uint pfee=msg.value.mul(POT_TAKE).div(100);
    uint fuelPay=msg.value.sub(dfee).sub(rfee).sub(pfee);

    uint fuelBought=purchaseTokens(fuelPay);//msg.value);

    fuelDestination.addFuel(n,s,e,w,fuelBought);

    //pay fees
    fuelDestination.send(pfee);
    fuelDestination.ceo().send(dfee);
    if(referral!=0x0){
      referral.send(rfee);
    }
    else{
      fuelDestination.ceo().send(rfee);
    }
  }
  function purchaseTokens(uint _incomingEthereum) private returns(uint256)
    {
        address _customerAddress = msg.sender;
        //uint256 _undividedDividends = SafeMath.div(_incomingEthereum, dividendFee_);
        uint256 _dividends = _incomingEthereum;//_undividedDividends;
        //uint256 _taxedEthereum = SafeMath.sub(_incomingEthereum, _undividedDividends);
        uint256 _amountOfTokens = ethereumToTokens_(_incomingEthereum);//_taxedEthereum);
        uint256 _fee = _dividends * magnitude;

        require(_amountOfTokens.add(tokenSupply_) > tokenSupply_);

        // we can&#39;t give people infinite ethereum
        if(tokenSupply_ > 0){

            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += (_dividends * magnitude / (tokenSupply_));

            // calculate the amount of tokens the customer receives over his purchase
            _fee = _fee - (_fee-(_amountOfTokens * (_dividends * magnitude / (tokenSupply_))));

        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(tokenBalanceLedger_[_customerAddress], _amountOfTokens);

        //remove divs from before buy
        int256 _updatedPayouts = (int256) ((profitPerShare_ * _amountOfTokens) - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        // fire event
        onTokenPurchase(_customerAddress, _incomingEthereum, _amountOfTokens, 0);

        return _amountOfTokens;
    }
  function withdraw() public
{
    // setup data
    address _customerAddress = msg.sender;
    uint256 _dividends = myDividends();
    require(_dividends>0);

    // update dividend tracker
    payoutsTo_[_customerAddress] +=  (int256) (_dividends * magnitude);

    // lambo delivery service
    _customerAddress.transfer(_dividends);
}
function myDividends()
    public
    view
    returns(uint256)
{
    return dividendsOf(msg.sender) ;
}
  function dividendsOf(address _customerAddress)
    view
    public
    returns(uint256)
{
    return (uint256) ((int256)(profitPerShare_ * tokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
}
  function ethereumToTokens_(uint256 _ethereum)
    public
    view
    returns(uint256)
{
    uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e18;
    uint256 _tokensReceived =
     (
        (
            // underflow attempts BTFO
            SafeMath.sub(
                (sqrt
                    (
                        (_tokenPriceInitial**2)
                        +
                        (2*(tokenPriceIncremental_ * 1e18)*(_ethereum * 1e18))
                        +
                        (((tokenPriceIncremental_)**2)*(tokenSupply_**2))
                        +
                        (2*(tokenPriceIncremental_)*_tokenPriceInitial*tokenSupply_)
                    )
                ), _tokenPriceInitial
            )
        )/(tokenPriceIncremental_)
    )-(tokenSupply_)
    ;

    return _tokensReceived;
}
function sqrt(uint x) internal pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }
}

}
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