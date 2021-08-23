/**
 *Submitted for verification at BscScan.com on 2021-08-23
*/

pragma solidity ^0.5.5;


contract Governance {

    address public _governance;

    constructor() public {
        _governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == _governance, "not governance");
        _;
    }

    function setGovernance(address governance)  public  onlyGovernance
    {
        require(governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(_governance, governance);
        _governance = governance;
    }


}

contract MyNFTDex is Governance {

    MyNFT nftContract;
    MyCoin coinContract;

    uint256 private price = 250000000000000000; // 0.25 BNB
    bool public saleUnlocked = true;

    uint256 private priceWithToken = 15000000000000000000;
    bool public saleWithTokenUnlocked = true;
    

    function transferNFTToDexOwner(uint256 tokenId) payable external onlyGovernance {
        require(isBuyableToken(tokenId), "Item is not to sale" );
        nftContract.transferFrom(address(this), msg.sender, tokenId );
    }

    function transferCoinToDexOwner() payable external onlyGovernance {
        coinContract.transfer(msg.sender, getCoinBalance() );
    }


    function transferBNBToDexOwner() payable external onlyGovernance {
        uint256 bal = address(this).balance;
        require(bal > 0, "BNB balance is 0");
        msg.sender.transfer(address(this).balance);
    }


    function SetCoinTokenAddress(address tokenAddress) external onlyGovernance {
        coinContract = MyCoin(tokenAddress);
    }

    function SetNFTTokenAddress(address tokenAddress) external onlyGovernance {
        nftContract = MyNFT(tokenAddress);
    }


  
    function changeSaleLock() public onlyGovernance {
        saleUnlocked = !saleUnlocked;
    }
  
    function changeSaleWithTokenLock() public onlyGovernance {
        saleWithTokenUnlocked = !saleWithTokenUnlocked;
    }
     


    function getBNBBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function getCoinBalance() public view returns (uint256){
        return coinContract.balanceOf(address(this));
    }


    function setPrice(uint256 _newPrice) public onlyGovernance() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }
     
    function setPriceWithToken(uint256 _newPrice) public onlyGovernance() {
        priceWithToken = _newPrice;
    }

    function getPriceWithToken() public view returns (uint256){
        return priceWithToken;
    }




    function buy(uint256 tokenId) payable public {
        require(saleUnlocked, "Sale is not active" );
        require(isBuyableToken(tokenId), "Item is not to sale" );
        require(msg.value >= price, "BNB value sent is not correct");
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId );
    }


    function buyWithToken(uint256 tokenId,uint256 value) public {
        require(saleWithTokenUnlocked, "Sale is not active" );
        require(isBuyableToken(tokenId), "Item is not to sale" );
        require(value >= priceWithToken, "Coin value sent is not correct");
        require(coinContract.allowance(msg.sender, address(this)) >= priceWithToken, "Coin value sent is not approved");
        coinContract.transferFrom(msg.sender, address(this), priceWithToken );
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId );
    }





    function isBuyableToken(uint256 tokenId) public view returns (bool) {
        return nftContract.ownerOf(tokenId) == address(this);
    }

    function getDexTokens() public view returns (uint256[] memory) {
        return nftContract.tokensOfOwner(address(this));
    }




}





contract MyCoin {
  function totalSupply() view external returns (uint256 supply){}
  function balanceOf(address _owner) view external returns (uint256 balance){}
  function transfer(address _to, uint256 _value)  view external returns (bool success){}
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){}
  function approve(address _spender, uint256 _value) public returns (bool success){}
  function allowance(address _owner, address _spender) public returns (uint256 remaining){}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
  address public owner;
}




/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract MyNFT {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


    function balanceOf(address owner) public view returns (uint256 balance){}
    function ownerOf(uint256 tokenId) public view returns (address owner){}
    function safeTransferFrom(address from, address to, uint256 tokenId) public{}
    function transferFrom(address from, address to, uint256 tokenId) public{}
    function approve(address to, uint256 tokenId) public{}
    function getApproved(uint256 tokenId) public view returns (address operator){}
    
    function setApprovalForAll(address operator, bool _approved) public{}
    function isApprovedForAll(address owner, address operator) public view returns (bool){}
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public{}
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {}
}