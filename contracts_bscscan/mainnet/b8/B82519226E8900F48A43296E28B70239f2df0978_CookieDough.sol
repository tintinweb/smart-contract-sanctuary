pragma solidity ^0.8.0;
import "Context.sol";
import "ERC20.sol";
import "SafeMath.sol";

contract CookieDough is ERC20 {


  using SafeMath for uint256;

    mapping(address => bool) private hasSold;
    address private  _owner;
    mapping(uint256 => address) private Wallets; // 0 = marketing , 1 = dev, 2 = dev2, 3 = prize


    uint256 bnb = 1000000000000000000;
    uint256 public airdropTokensAvailable = 150000000000000000000000;

    mapping(address => uint256) private airDropReceiver;


    uint256 softbakerate = 800000000000000000000000; // cookie dough to bnb soft sale
    uint256 softbakemaxbuy = 1600000000000000000000000; //maximum purchase Amount
    uint256 hardbakerate = 450000000000000000000000; // cookie dough to bnb hard sale


    uint256 public SoftBakeCookiesAvailable = 500000000000000000000000000;
    uint256 public SoftBakeCookiesPurchased = 0;

    uint public HardBakeCookiesAvailable = 1500000000000000000000000000;
    uint public HardBakeCookiesPurchased = 0;

    bool public CrowdsaleComplete  = false;
    bool public CrowdsaleActive = false;

    bool public SoftBakeActive = false;
    bool public HardBakeActive = false;


    mapping (address => uint256) _SoftBakeBal;
    mapping (address => uint256) _HardBakeBal;

    bool ReleasePresale = false;


    constructor() ERC20("Cookie Dough", "DOUGH") {
      _mint(msg.sender, 900000000000000000000000000 );
      hasSold[msg.sender] = false;
      _owner = msg.sender;

    }




    event Reward(address winner, uint256 amount);
    event CookiePurchased(address buyer, uint256 amount);
    event walletchanged(address wallet, uint256 id);
    event tokenBought(address buyer, uint256 amount);
    event PrizeWithdraw(address sender, address winner, uint256 prizeamount );
    event Airdrop(address receiver, uint256 amount);



    modifier CrowdsaleOver{

      require(CrowdsaleComplete==true, "Crowdsale has not completed");

      _;
    }



    function HasAirDrop(address account) public view returns (bool airdrop){


      bool ad = false;

      if(airDropReceiver[account] > 0){

        ad = true;
      }


      return ad;


    }





    function GetAirDrop() public returns(bool) {
      uint256 amt = 25;
      require(_msgSender()!= address(0), "Invalid address");
      require(airDropReceiver[_msgSender()] < 1, "Already received an airdrop");
      require(airdropTokensAvailable >= amt.mul(bnb), "No more air drop tokens available" );

      airDropReceiver[_msgSender()] = amt.mul(bnb);
      airdropTokensAvailable = airdropTokensAvailable.sub(amt.mul(bnb));
      _transfer(_owner, _msgSender(), amt.mul(bnb));
      emit Airdrop(_msgSender(), amt.mul(bnb));

      return true;

    }



    function releasePresale() public CrowdsaleOver returns(bool){

      require(msg.sender == _owner, "Not owner");

      ReleasePresale = true;

      return true;

    }







    function BuyHardBake() public payable returns (bool success, uint256 cookieamount){

      uint256 amount = msg.value;

      uint256 cookieDough = amount.mul(hardbakerate);
      require(CrowdsaleActive==true, "Crowdsale has not started");
      require(HardBakeActive==true, "Hard Bake Is Unavailable");
      require(cookieDough.add(HardBakeCookiesPurchased) <= HardBakeCookiesAvailable, "Not enough cookies remaining"); // check that there is still enough cookie for purchase


      require(address(msg.sender).balance > msg.value , "Insufficient BNB balance");


      payable(_owner).transfer(msg.value);

      uint256 b = _HardBakeBal[msg.sender];

      _HardBakeBal[msg.sender] =  b.add(cookieDough);
      HardBakeCookiesPurchased = HardBakeCookiesPurchased.add(cookieDough);

      _transfer(_owner, msg.sender, cookieDough);

      return (true, cookieDough);

    }

    function EndBakeSale() public payable returns(bool success){

      require(msg.sender == _owner , "Not Owner");
      SoftBakeActive = false;
      HardBakeActive = false;
      CrowdsaleComplete = true;
      CrowdsaleActive = false;

      return true;


    }


    function RandomReward(uint256 val, address winner) public returns(bool){


        require(msg.sender == _owner, "Not Owner");
        require(val != 0 , "Invalid amount");
        require(winner != address(0));
        require(val < balanceOf(Wallets[3]).div(3));


        _transfer(Wallets[3], winner, val);
        emit Reward(winner, val);

        return true;



    }





    function StartHardBake() public  returns(bool success) {

      require(msg.sender == _owner , "Not Owner");
      SoftBakeActive = false;
      HardBakeActive = true;

      return true;

    }


    function StartSoftBake() public returns(bool success) {

      require(msg.sender == _owner , "Not Owner");
      HardBakeActive = false;
      SoftBakeActive = true;
      CrowdsaleActive = true;
      return true;

    }


    function mycookieBalance() public view returns(uint256 balance, uint256 softbakebal, uint256 hardbakebal){

      return (balanceOf(msg.sender), _SoftBakeBal[msg.sender], _HardBakeBal[msg.sender]);

    }


    function getSoftQuote(uint256 amount) public view returns(uint256 amt){


      return amount.mul(softbakerate);


    }



    function getHardQuote(uint256 amount) public view returns(uint256 amt){


      return amount.mul(hardbakerate);


    }



    function remainingSoftBakeTokens() public view returns(uint256 amt){


      return SoftBakeCookiesAvailable.sub(SoftBakeCookiesPurchased);
    }





    function remainingHardBakeTokens() public view returns(uint256 amt){


      return HardBakeCookiesAvailable.sub(HardBakeCookiesPurchased);
    }



    function BuySoftBake() public payable returns (bool success, uint256 cookieamount){

      uint256 amount = msg.value;

      uint256 cookieDough = amount.mul(softbakerate);



      require(_SoftBakeBal[msg.sender] < softbakemaxbuy, "Already reached maximum purchase amount"); //check user hasent reached soft bake cap
      require(cookieDough.add(SoftBakeCookiesPurchased) <= SoftBakeCookiesAvailable, "Not enough cookies remaining"); // check that there is still enough cookie for purchase
      require(_SoftBakeBal[msg.sender].add(cookieDough) <= SoftBakeCookiesAvailable, "Not enough cookies remaining"); // check that there is still enough cookie for purchase

      require(CrowdsaleActive==true, "Crowdsale has not started");
      require(SoftBakeActive==true, "Soft Bake Is Unavailable");

      require(address(msg.sender).balance  > msg.value , "Insufficient BNB balance");



      payable(_owner).transfer(msg.value);
      uint256 b = _SoftBakeBal[msg.sender];
      _SoftBakeBal[msg.sender] = b.add(cookieDough);
      _transfer(_owner, msg.sender, cookieDough);
      SoftBakeCookiesPurchased = SoftBakeCookiesPurchased.add(cookieDough);


      return (true, cookieDough);

    }









    function setWallet(address add, uint256 index) public returns (bool success){

      require(msg.sender == _owner, "Not Owner");

      Wallets[index] = add;
      emit walletchanged(add, index);
      return true;
    }



    function CrowdsaleBalLock(uint256 amount) internal view returns(bool){

      if(_SoftBakeBal[_msgSender()].add(_HardBakeBal[_msgSender()]) > 0 ){

        uint256 a = balanceOf(_msgSender()).sub(amount);
        uint256 b = _SoftBakeBal[_msgSender()].add(_HardBakeBal[_msgSender()]);

        require( a < b, "Cannot Withdraw all Presale Tokens" );


}

  return true;

    }


    function transfer(address recipient, uint256 amount) public virtual CrowdsaleOver override returns (bool) {
      CrowdsaleBalLock(amount);
        _transfer(_msgSender(), recipient, amount);
        hasSold[msg.sender] = false;
        if(recipient == address(this)){
        hasSold[msg.sender] = true;
      }
        return true;
    }


    function buyCookie(uint256 amount) public CrowdsaleOver  returns(uint256 amt, bool processed){

      require(msg.sender != address(0), "Invalid Address");
      require(amount > 0 , "Invalid Amount");
      require(amount < balanceOf(msg.sender), "Insufficient Balance");

      uint256 devTax = amount.mul(2).div(100);
      uint256 marketingTax = amount.mul(1).div(100);
      uint256 prizeTax = amount.mul(1).div(100);
        _transfer(msg.sender, Wallets[1], devTax);
        _transfer(msg.sender, Wallets[2], devTax);
        _transfer(msg.sender, Wallets[0], marketingTax);
          _transfer(msg.sender, Wallets[3], prizeTax);

          emit CookiePurchased(_msgSender(), amount);
        return (amount, processed);
    }

    function BuyDough(uint amount) public CrowdsaleOver payable returns(bool success){

      require(amount < balanceOf(_owner), "Insufficient Amount" );
      require(msg.value >0, "Invalid amount of BNB");

      uint devTax = amount.mul(2).div(100);
      uint marketingTax = amount.mul(1).div(100);
      uint prizeTax = amount.mul(1).div(100);
      uint remaining = amount.sub(devTax).sub(devTax).sub(prizeTax).sub(marketingTax);

      _transfer(_owner, Wallets[2], devTax);
      _transfer(_owner, Wallets[1], devTax);
      _transfer(_owner, Wallets[0], marketingTax);
      _transfer(_owner, Wallets[3], prizeTax);
      _transfer(_owner, msg.sender, remaining);

      emit Transfer(_owner, msg.sender, amount);

      return true;
    }

    function GetHasSold(address user) public view returns(bool Sold){


      return hasSold[user];


    }


    function WithdrawPrize(uint amount) public CrowdsaleOver returns (bool success, uint amt){

      require(amount >0, "Invalid amount");
      require(amount < balanceOf(Wallets[3]).div(10));
      require(msg.sender != address(0), "Invalid address");

      _transfer(Wallets[3], msg.sender, amount);

      emit PrizeWithdraw(Wallets[3], msg.sender, amount);

      return (true, amount);


    }






}