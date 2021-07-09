/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-01
*/

/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
/*
*     * * *      *   *       *      *      * *   * * * * *
* *   *        *     * *   * *    *   *    *  *      *
*  *  * *     *      *   *   *   * * * *   * *       *
* *   *        *     *       *  *       *  *  *      *
*     * * *      *   *       * *         * *   *     *
*/

contract DecMark{
    using SafeMath for uint256;
    
    uint256 SECURITY_DEPOSIT = 0.01 ether;
    uint256 TAX_RATE = 2;    // 2%
    uint256 JUDGE_FEE = 0.1 ether;
    address public judge;
    uint256 public savingWallet;
    uint256 public totalSellers;
    uint256 public totalBuyers;
    uint256 public totalItems;
    uint256 public taxWallet;
    address public govAddress;
    uint256 public judgeAmount;
    /*
    1 -> adhaar
    2 -> pancard
    3 -> voterId
    4 -> passport
    */
    
    struct Product{
        uint256 pid;
        string name;
        uint256 price;
        address prevOwner;
        address owner;
        bool isExist;
        uint256 category;
        bool isPurchased;
        uint256 timestamp;
        bool paymentRecieved;
        string imageUrl;
    }
    
    struct Seller{
        uint256 sid;
        uint256 identityNumber;
        uint256 identityType;
        uint256 totalItemsSelled;
        uint256 rating;
        bool isExist;
        uint256 amountWithdrawn;
        uint256 stars;
    }
    
    struct Buyer{
        uint256 bid;
        uint256[] totalItemsPurchased;
        bool isExist;
    }
    
    mapping(address=>Seller) public sellers;
    mapping(address=>Buyer) public buyers;
    mapping(uint256=>Product) public products;
    mapping(address => uint256[]) public buyersPurchases;
    mapping(address => uint256) public totalPurchasesCount;
    mapping(address=>uint256) public balances;
    
    constructor(){
        // judge = msg.sender;
        govAddress = msg.sender;
    }
    
    modifier onlySeller{
        require(sellers[msg.sender].isExist);
        _;
    }
    modifier onlyBuyer{
        require(buyers[msg.sender].bid>0);
        _;
    }
    modifier onlyJudge{
        require(msg.sender==judge);
        _;
    }
    
    function RegisterAsSeller(uint256 _identityNumber, uint256 _identityType) public payable{
        require(msg.value>=SECURITY_DEPOSIT,"You must pay security amount");
        require(!sellers[msg.sender].isExist,"Seller already exist");
        sellers[msg.sender] = Seller({
            sid:totalSellers.add(1),
            identityNumber:_identityNumber,
            identityType:_identityType,
            totalItemsSelled:0,
            rating:0,
            isExist:true,
            amountWithdrawn:0,
            stars:5
        });
        totalSellers = totalSellers.add(1);
        savingWallet = savingWallet.add(msg.value);
    }
    
    function RegisterAsBuyer() public{
        require(!buyers[msg.sender].isExist==true, "Buyer already exist");
        buyers[msg.sender]=Buyer({
            bid:totalBuyers.add(1),
            totalItemsPurchased:buyers[msg.sender].totalItemsPurchased,
            isExist:true
        });
        totalBuyers = totalBuyers.add(1);
    }
    
    function AddItem(string memory _name, uint256 _price,uint256 _category,string memory _imageUrl) public onlySeller(){
        totalItems = totalItems.add(1);
        products[totalItems] = Product({
           pid:totalItems,
           name:_name,
           price:_price,
           prevOwner:address(0),
           owner:msg.sender,
           isExist:true,
           category:_category,
           isPurchased:false,
           timestamp:0,
           paymentRecieved:false,
           imageUrl:_imageUrl
        });
    }
    
    function UpdateItem(uint256 _itemId,uint256 _price, string calldata _name, address _owner) public onlySeller(){
        require(products[_itemId].isExist,"Item not exist");
        require(products[_itemId].owner == msg.sender);
        products[_itemId].price = _price;
        products[_itemId].owner = _owner;
        products[_itemId].name = _name;
    }
    
    function DeleteItem(uint256 _itemId) public onlySeller(){
        require(products[_itemId].isExist,"Item not exist");
        require(products[_itemId].owner == msg.sender);
        delete(products[_itemId]);
        totalItems = totalItems.sub(1);
    }
    
    function PurchaseItem(uint256 _itemId) public payable onlyBuyer(){
        require(msg.value>=products[_itemId].price, "You need to pay more amount");
        require(products[_itemId].isExist == true && products[_itemId].isPurchased == false , "Item not exist or already purchased");
        balances[products[_itemId].owner] = balances[products[_itemId].owner].add(products[_itemId].price);
        products[_itemId].prevOwner = products[_itemId].owner;
        products[_itemId].owner = msg.sender;
        products[_itemId].timestamp = block.timestamp;
        buyersPurchases[msg.sender].push(_itemId);
        totalPurchasesCount[msg.sender] = totalPurchasesCount[msg.sender].add(1);
    }
    
    function RaiseDispute(uint256 _itemId) public payable onlyBuyer(){
        require(products[_itemId].timestamp.add(1 days)>=block.timestamp, "you can't raise dispute after 24 hours");
        require(msg.value>=JUDGE_FEE, "you need to give judge fee it will be refunded if dispute is valid");
        judgeAmount = judgeAmount.add(msg.value);
    }
    
    function WithdrawAmountBySeller() public onlySeller(){
        // require(products[_itemId].timestamp.add(1 days) < block.timestamp, "you need to wait for atleast 24 hours to withdraw payment");
        // require(products[_itemId].paymentRecieved == false, "you have already withdrawn payment for this item");
        require(balances[msg.sender]>0, "insufficient balance");
        payable(msg.sender).transfer(balances[msg.sender].sub(balances[msg.sender].mul(2).div(100)));
      
        sellers[msg.sender].amountWithdrawn = sellers[msg.sender].amountWithdrawn.add(balances[msg.sender]);
        taxWallet = taxWallet.add(balances[msg.sender].mul(2).div(100));
        balances[msg.sender] = 0;
    }
    
    // judge can decrease the sellers rating if it found dispute to be valid and give fees back 
    // to buyer and if it becomes less than 0 then terminate seller account and they have to re register
    function DecreaseSellerRating(address _buyer,address _seller) public onlyJudge(){
        if(sellers[_seller].rating == 0){
            sellers[_seller].isExist = false;
        }
        else{
            sellers[_seller].rating =sellers[_seller].rating.sub(1);
        }
        payable(_buyer).transfer(JUDGE_FEE);
    }
    
    function WithdrawGovernanceAmount() public{
        require(msg.sender == govAddress, "you are not eligible person");
        payable(govAddress).transfer(taxWallet);
        taxWallet = 0;
    }
    
    function WithdrawJudgeFee() public onlyJudge{
        payable(judge).transfer(judgeAmount);
        judgeAmount = 0;
    } 
}

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}