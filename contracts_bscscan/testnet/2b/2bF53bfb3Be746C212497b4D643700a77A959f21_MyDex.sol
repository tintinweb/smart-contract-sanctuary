/**
 *Submitted for verification at BscScan.com on 2021-08-29
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

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract MyDex is Governance {
    using SafeMath for uint256;
    
    MyNFT nftContract;
    MyCoin coinContract;
    

    uint256 private nftToBNB = 10; // price per nft in BNB
    bool public saleUnlocked = true;

    uint256 private coinToNFT = 150000000000000000000; // Buy NFT per 150 coins
    bool public saleWithTokenUnlocked = true;
    
    uint256 private coinToBNB = 1500; // 1 BNB
    bool public saleCoinUnlocked = true;
    

    function transferNFTToDexOwner(uint256 tokenId) external onlyGovernance {
        require(isBuyableToken(tokenId), "Item is not to sale" );
        nftContract.transferFrom(address(this), msg.sender, tokenId );
    }

    function transferCoinToDexOwner(uint256 amount) external onlyGovernance {
        uint256 bal = getCoinBalance();
        require(bal > 0, "Coin balance is 0");
        require(bal >= amount, "Coin balance is not enougth");
        coinContract.transfer(msg.sender, amount);
    }
    


    function transferBNBToDexOwner() external onlyGovernance {
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
  
    function changeSaleCoinLock() public onlyGovernance {
        saleCoinUnlocked = !saleCoinUnlocked;
    }
     


    function getBNBBalance() public view returns (uint256) {
        return address(this).balance;
    }
    function getCoinBalance() public view returns (uint256){
        return coinContract.balanceOf(address(this));
    }


    function setNFTToBNB(uint256 _newNftToBNB) public onlyGovernance() {
        nftToBNB = _newNftToBNB;
    }

    function getPrice() public view returns (uint256){
        return nftToBNB;
    }
     
    function setCoinToNFT(uint256 _newCoinToNFT) public onlyGovernance() {
        coinToNFT = _newCoinToNFT;
    }

    function getPriceWithToken() public view returns (uint256){
        return coinToNFT;
    }

    function setCoinToBNB(uint256 _newCoinToBNB) public onlyGovernance() {
        coinToBNB = _newCoinToBNB;
    }

    function getPriceCoin() public view returns (uint256){
        return coinToBNB;
    }


    function buyCoin() payable public {
        require(saleCoinUnlocked, "Sale is not active" );
        require(msg.value > 0, "BNB value sent is not correct");
        uint256 amount = msg.value.mul(coinToBNB) ;
        require(amount <= coinContract.balanceOf(address(this)), "BNB balance is low");
        require(coinContract.transfer(msg.sender, amount ));
    }

    function buyNFT(uint256 tokenId) payable public {
        require(saleUnlocked, "Sale is not active" );
        require(isBuyableToken(tokenId), "Item is not to sale" );
        require(msg.value.div(nftToBNB) >= 1, "BNB value sent is not correct");
        nftContract.safeTransferFrom(address(this), msg.sender, tokenId );
    }


    function buyNFTWithToken(uint256 tokenId,uint256 value) public {
        require(saleWithTokenUnlocked, "Sale is not active" );
        require(isBuyableToken(tokenId), "Item is not to sale" );
        require(value >= coinToNFT, "Coin value sent is not correct");
        require(coinContract.allowance(msg.sender, address(this)) >= coinToNFT, "Coin value sent is not approved");
        coinContract.transferFrom(msg.sender, address(this), coinToNFT );
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
  function totalSupply() public view  returns (uint256 supply){}
  function balanceOf(address _owner) public view  returns (uint256 balance){}
  function transfer(address _to, uint256 _value)  external returns (bool success){}
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