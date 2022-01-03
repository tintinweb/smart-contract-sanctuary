/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

pragma solidity ^0.4.24;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

    interface ERC20 {
        function transfer(address _beneficiary, uint256 _tokenAmount) external returns (bool);
        function transferFromICO(address _to, uint256 _value) external returns(bool);
    }

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

 
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract MainSale is Ownable {

    using SafeMath for uint;

    ERC20 public token;
    
    address reserve = 0x611200beabeac749071b30db84d17ec205654463; // !!!!!!
    address promouters = 0x2632d043ac8bbbad07c7dabd326ade3ca4f6b53e; // !!!!
    address bounty = 0xff5a1984fade92bfb0e5fd7986186d432545b834; // !!!

    uint256 public constant decimals = 18;
    uint256 constant dec = 10**decimals;

    mapping(address=>bool) whitelist;

    uint256 public startCloseSale = now; // start 
    uint256 public endCloseSale = 1533160800; // Wed, 01 Aug 2018 22:00:00 GMT

    uint256 public startStage1 = 1533160801; // Wed, 01 Aug 2018 22:00:01 GMT
    uint256 public endStage1 = 1533247200; // Thu, 02 Aug 2018 22:00:00 GMT

    uint256 public startStage2 = 1533247201; // Thu, 02 Aug 2018 22:00:01 GMT
    uint256 public endStage2 = 1533679199; // Tuesday, 07-Aug-18 23:59:59 UTC-2

    uint256 public startStage3 = 1533679200; // Wednesday, 08-Aug-18 00:00:00 UTC-2 
    uint256 public endStage3 = 1535752799; // Friday, 31-Aug-18 23:59:59 UTC-2

    uint256 public buyPrice = 92000000000000000; // 0.092 BNB
    
    uint256 public BNBUSD;

    uint256 public weisRaised = 0;

    event Authorized(address wlCandidate, uint timestamp);
    event Revoked(address wlCandidate, uint timestamp);

    constructor(ERC20 _token, uint256 _ethUSD) public {
        token = _token;
        BNBUSD = _ethUSD;
    }

    function setToken (ERC20 _token) public onlyOwner {
        token = _token;
    }
    
    /*******************************************************************************
     * Whitelist's section
     */
    function authorize(address wlCandidate) public onlyOwner  {
        require(wlCandidate != address(0x0));
        require(!isWhitelisted(wlCandidate));
        whitelist[wlCandidate] = true;
        emit Authorized(wlCandidate, now);
    }

    function revoke(address wlCandidate) public  onlyOwner {
        whitelist[wlCandidate] = false;
        emit Revoked(wlCandidate, now);
    }

    function isWhitelisted(address wlCandidate) public view returns(bool) {
        return whitelist[wlCandidate];
    }
    
    /*******************************************************************************
     * Setter's Section
     */

    function setStartCloseSale(uint256 newStartSale) public onlyOwner {
        startCloseSale = newStartSale;
    }

    function setEndCloseSale(uint256 newEndSale) public onlyOwner{
        endCloseSale = newEndSale;
    }

    function setStartStage1(uint256 newsetStage2) public onlyOwner{
        startStage1 = newsetStage2;
    }

    function setEndStage1(uint256 newsetStage3) public onlyOwner{
        endStage1 = newsetStage3;
    }

    function setStartStage2(uint256 newsetStage4) public onlyOwner{
        startStage2 = newsetStage4;
    }

    function setEndStage2(uint256 newsetStage5) public onlyOwner{
        endStage2 = newsetStage5;
    }

    function setStartStage3(uint256 newsetStage5) public onlyOwner{
        startStage3 = newsetStage5;
    }

    function setEndStage3(uint256 newsetStage5) public onlyOwner{
        endStage3 = newsetStage5;
    }

    function setPrices(uint256 newPrice) public onlyOwner {
        buyPrice = newPrice;
    }
    
    function setETHUSD(uint256 _ethUSD) public onlyOwner { 
        BNBUSD = _ethUSD;
    }
    
    /*******************************************************************************
     * Payable Section
     */
    function ()  public payable {
        
        require(msg.value >= (1*1e18/BNBUSD*100)); // min sale = 100 USD
        
        if (isWhitelisted(msg.sender) == true) { // 30% на весь период для wl
            closeSale(msg.sender, msg.value);
        } else if (isWhitelisted(msg.sender) != true && now >= startStage1 && now <= endStage1) {
            sale1(msg.sender, msg.value);
        } else if (isWhitelisted(msg.sender) != true && now >= startStage2 && now <= endStage2) {
            sale2(msg.sender, msg.value);
        } else if (isWhitelisted(msg.sender) != true && now >= startStage3 && now <= endStage3) {
            sale3(msg.sender, msg.value);
        } else {
            revert();
        }
    }

    // issue token in a period of closed sales
    function closeSale(address _investor, uint256 _value) internal {
        uint256 tokens = _value.mul(1e18).div(buyPrice); // 68%
        uint256 bonusTokens = tokens.mul(30).div(100); // + 30% per stage
        tokens = tokens.add(bonusTokens); 
        token.transferFromICO(_investor, tokens);
        weisRaised = weisRaised.add(msg.value);

        uint256 tokensReserve = tokens.mul(15).div(68); // 15 %
        token.transferFromICO(reserve, tokensReserve);

        uint256 tokensBoynty = tokens.div(34); // 2 %
        token.transferFromICO(bounty, tokensBoynty);

        uint256 tokensPromo = tokens.mul(15).div(68); // 15%
        token.transferFromICO(promouters, tokensPromo);
    }
    
    // the issue of tokens in period 1 sales
    function sale1(address _investor, uint256 _value) internal {

        uint256 tokens = _value.mul(1e18).div(buyPrice); // 66% 

        uint256 bonusTokens = tokens.mul(10).div(100); // + 10% per stage
        tokens = tokens.add(bonusTokens); // 66 %

        token.transferFromICO(_investor, tokens);

        uint256 tokensReserve = tokens.mul(5).div(22); // 15 %
        token.transferFromICO(reserve, tokensReserve);

        uint256 tokensBoynty = tokens.mul(2).div(33); // 4 %
        token.transferFromICO(bounty, tokensBoynty);

        uint256 tokensPromo = tokens.mul(5).div(22); // 15%
        token.transferFromICO(promouters, tokensPromo);

        weisRaised = weisRaised.add(msg.value);
    }
    
    // the issue of tokens in period 2 sales
    function sale2(address _investor, uint256 _value) internal {

        uint256 tokens = _value.mul(1e18).div(buyPrice); // 64 %

        uint256 bonusTokens = tokens.mul(5).div(100); // + 5% 
        tokens = tokens.add(bonusTokens);

        token.transferFromICO(_investor, tokens);

        uint256 tokensReserve = tokens.mul(15).div(64); // 15 %
        token.transferFromICO(reserve, tokensReserve);

        uint256 tokensBoynty = tokens.mul(3).div(32); // 6 %
        token.transferFromICO(bounty, tokensBoynty);

        uint256 tokensPromo = tokens.mul(15).div(64); // 15%
        token.transferFromICO(promouters, tokensPromo);

        weisRaised = weisRaised.add(msg.value);
    }

    // the issue of tokens in period 3 sales
    function sale3(address _investor, uint256 _value) internal {

        uint256 tokens = _value.mul(1e18).div(buyPrice); // 62 %
        token.transferFromICO(_investor, tokens);

        uint256 tokensReserve = tokens.mul(15).div(62); // 15 %
        token.transferFromICO(reserve, tokensReserve);

        uint256 tokensBoynty = tokens.mul(4).div(31); // 8 %
        token.transferFromICO(bounty, tokensBoynty);

        uint256 tokensPromo = tokens.mul(15).div(62); // 15%
        token.transferFromICO(promouters, tokensPromo);

        weisRaised = weisRaised.add(msg.value);
    }

    /*******************************************************************************
     * Manual Management
     */
    function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
        _to.transfer(amount);
    }
}