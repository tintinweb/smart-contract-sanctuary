pragma solidity >=0.4.25 <0.6.0;

import "./ownable.sol";
import "./safemath.sol";

//@title creates sales (ICOs) for ERC-20 tokens created on contract 0x0c199144D2952294daDBE14ea2D01155eE921232 only
//@R^3
//@notice create token sales for ERC-20 tokens

//@dev sets up interface with ERC-20 token contract
contract ERCInterface {
  function transfer(address to, uint256 value) public returns (bool);
  function totalSupply() public view returns (uint256);
   function balanceOf(address who) public view returns (uint256);
   function owner() public view returns(address);
   function decimals() public view returns (uint256);
   function creator() public view returns(address);
}

//@dev token sale factory creates sales for ERC-20 tokens
contract TokenSaleFactory is Ownable{
    //@logs all depoloyed sales
    address[] public deployedSales;
    TokenSales public newTokenSale;
    //@allows checking of which sales are associated with a specific address
    mapping (address => address) public mySales;


    //@dev fee for generating Sale
    uint public tokenFee = 0.01 ether;
    //@dev set token fee (owner only)
    function setTokenFee(uint _fee) external onlyOwner {
      tokenFee = _fee;
    }

  ERCInterface tokenContract;

    //@function that creates sale
    function createTokenSale(address _tokenAddress) external payable returns (TokenSales) {
      tokenContract = ERCInterface(_tokenAddress);
       require(tokenContract.creator() == msg.sender);
        require(msg.value == tokenFee);
        newTokenSale = new TokenSales(msg.sender, _tokenAddress);
        deployedSales.push(address(newTokenSale));
        mySales[address(newTokenSale)] = msg.sender;
        return(newTokenSale);
    }

    //@retreives all deployed sales
    function getDeployedSales() public view returns (address[] memory) {
        return deployedSales;
    }

    //@allows owner to withdraw fees
    function withdraw() external onlyOwner {
      address _owner = address(uint160(owner()));
      _owner.transfer(address(this).balance);
      }
}

//@ sets structure for token sale
contract TokenSales is Ownable {

    constructor (address _creator, address _tokenAddress) public {
        tokenOwner = _creator;
        tokenAddress = _tokenAddress;
         tokenContract = ERCInterface(_tokenAddress);

    }
    using SafeMath for uint256;
  using SafeMath32 for uint32;
  using SafeMath16 for uint16;

    bool saleActive = false;
      uint256 public tokenPrice;
      uint256 public tokensSold;
      address public tokenOwner;
        address public tokenAddress;

        event Sell(address _buyer, uint256 _amount);


  ERCInterface tokenContract;

   modifier onlyTokenOwner() {
        require(msg.sender == tokenOwner);
        _;
    }

    //@dev this function allows purchase of ERC-20 tokens
      function buyTokens(uint256 _numberOfTokens) external payable {
        require(msg.value == _numberOfTokens.mul(tokenPrice));
        uint256 numberOfTokens = _numberOfTokens.mul(10**(tokenContract.decimals()));
       //@mul only to prevent overflow
        require(tokenContract.totalSupply() >= numberOfTokens);
        require(saleActive == true);
        tokenContract.transfer(msg.sender, numberOfTokens);
        tokensSold += numberOfTokens;
        emit Sell(msg.sender, _numberOfTokens);
      }

        //@dev function ends sale and send remaining tokens to sale creator
      function endSale() public onlyTokenOwner {
        tokenContract.transfer(msg.sender, (tokenContract.balanceOf(address(this))));
        saleActive = false;
      }

        //@dev starts sale and initiates sale price
       function startSale(uint _tokenPrice, uint _multiplier) public onlyTokenOwner {
        //@dev e.g. multiplier 1 = wei, 9 = gwei, 18 = ether
        tokenPrice = _tokenPrice.mul(10**_multiplier);
        saleActive = true;
      }

    //@dev checks whether sale is active
    //@returns true or false
      function saleStatus() public view returns (bool) {
        return saleActive;
      }

    //@dev allows sale creator to withdraw fees from token sale
      function withdraw() external onlyTokenOwner {
        address _owner = address(uint160(tokenOwner));
        _owner.transfer(address(this).balance);
        }

        //@returns the owner of the sale
        function tokenOwnerAdd() public view returns (address) {
            return tokenOwner;
        }

}