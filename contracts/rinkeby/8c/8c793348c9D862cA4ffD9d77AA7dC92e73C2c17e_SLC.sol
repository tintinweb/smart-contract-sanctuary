/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface mintNFTcontract{
     function mint(address,uint256,string memory) external;
}

interface AuctionContract{
     function CheckBidderIdentity(string memory,address) external returns(bool);
     function Enlist_Auction(string memory,uint,uint,uint,uint,uint,string memory) external returns(bool);
     function End_Auction(string memory) external returns(bool,uint,uint);
}
interface DAI {
    
    function transfer(address , uint256) payable external returns(bool);
    function transferFrom(address ,address , uint256) payable external returns(bool) ;
    function balanceOf(address)  external view  returns(uint256);
    function approve(address , uint256) external payable  returns(bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function safetransferFrom(address ,address , uint256) payable external returns(bool);
}  
contract SLC{
    
    /*Using Safemath for arithemetic operations*/
    using SafeMaths for uint256;
    
    /*Deployed address of SLF contract*/
    address public SLF_DEPLOYED_ADDRESS; 
    
    /*Deployed address of mintNFT contract*/
    address public MINTNFT_DEPLOYED_ADDRESS; 
    
    /*Deployed address of Auction Contract*/
    address public AUCTION_DEPLOYED_ADDRESS;
    
    /*Token Name*/
    string  public name = "SLC";
    
    /*Token Symbol*/
    string  public symbol = "S";
    
    /*Number of decimal in Token Amount*/
    uint256 public decimals = 18;
    
    /*Token IDs*/
    uint TOKEN_ID = 0;
    
    //DAI contract Instance
    DAI public daiInstance = DAI(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);
    
    /*Total supply of token*/
    uint256 public totalSupply;

    /*Escrow Account Address*/
    address private ESCROW_ACCOUNT_ADDRESS;

    /*Mapping to show token balance of particular address*/
    mapping(address =>uint256) public balances;
    
    /*Mapping to show current token allowance given to particular address*/
    mapping(address =>mapping(address=>uint256)) public allowance;
    
    /*Mapping to show particular Address is owner or not*/
    mapping(address => bool) public _owners;
    
    /*Mapping to store particular address to a region number*/
    mapping(uint => address) public REGION_NO_TO_ADMIN_ADDRESS;
    
    /*Mapping to store how much auction tokens win by particular address*/
    mapping(string => mapping(address => uint)) public GET_WIN_SLC;

    /*Emit when a request to transfer tokens occur*/
    event Transfer(address indexed _from,address indexed _to,uint256 _value);

    /*Emit when a no. of token approval is given to address*/
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    
    /*Emit when SLC tokens transferred */
    event SLC_TOKEN_TRANSFER_SUCCESS(string auc_id,address bid_add);

    /*Address of contract deployer*/
    address public owner;

    /*To check whether a function is call by contract owner or not*/
    modifier onlyOwner(){
        require(msg.sender == owner,"caller is not contract owner");
        _;
    }
    
    modifier onlyEscrow(){
        require(msg.sender == ESCROW_ACCOUNT_ADDRESS,"caller is not contract owner");
        _;
    }
    
    function GET_ESCROW_ACCOUNT_ADDRESS() public view onlyOwner returns(address){
        return ESCROW_ACCOUNT_ADDRESS;
    }
    
     function SET_ESCROW_ACCOUNT_ADDRESS(address new_address) public onlyOwner returns(bool){
        require(new_address!=address(0));
        ESCROW_ACCOUNT_ADDRESS = new_address;
        return true;
    }
    
    /*To check whether a function is call by Admin or not*/
    modifier isAdmin(address _address){
        require(_owners[_address],"caller is not Admin");
        _;
    }
    
    /*To check whether a function is call by ValidOwner or not*/
    modifier validOwner() {
        require((msg.sender == owner || _owners[msg.sender]),"caller is not valid owner");
        _;
    }
    
    /*To check whether a function is call by SLF contract or not*/
    modifier ONLY_SLF_AND_OWNERS{
        require(msg.sender == SLF_DEPLOYED_ADDRESS || _owners[msg.sender],"caller is not SLF contract or Owner");
        _;
    }
    
    /*To check whether a function is call by Auction contract or not*/
    modifier onlyAuctionContract{
        require(msg.sender == AUCTION_DEPLOYED_ADDRESS,"caller is not Auction contract");
        _;
    }
    
    /*Emits when New Owner is added*/
    event ownerAdded(address);

    /*Emits when existing Owner is removed*/
    event ownerRemoved(address);
    
    /*Emits when New Region Admin is added*/
    event RegionAdminAdded(uint,address);

    /*Emits when existing Region Admin is changed*/
    event RegionAdminChanged(uint,address);
    
    /*Emits when fund is deposited*/
    event DepositFunds(address,uint);

    constructor(uint256 _initialSupply) public {
        owner = msg.sender;
        _owners[msg.sender] = true;
        balances[msg.sender] = _initialSupply;
        totalSupply=_initialSupply;
        emit Transfer(address(0),msg.sender,_initialSupply);
    }

    /*Store SLF Contract Deployed Address*/
    function SET_SLF_DEPLOYED_ADDRESS(address _address) public onlyOwner returns(bool){
        require(_address!=address(0));
        SLF_DEPLOYED_ADDRESS = _address;
        return true;
    }
    
    /*Store mintNFT Contract Deployed Address*/
    function SET_MINTNFT_DEPLOYED_ADDRESS(address _address) public onlyOwner returns(bool){
        MINTNFT_DEPLOYED_ADDRESS = _address;
        return true;
    }
    
    /*Set Auction Contract Address*/
    function SET_AUCTION_DEPLOYED_ADDRESS(address _address) public onlyOwner returns(bool){
        require(_address!=address(0));
        AUCTION_DEPLOYED_ADDRESS = _address;
        return true;
    }
   
    
    /*Store a particular region admin*/
    function ADD_REGION_ADMIN(uint region_no,address _address) public onlyOwner returns(bool){
        require(REGION_NO_TO_ADMIN_ADDRESS[region_no] == address(0),"An admin is already there for this region");
        REGION_NO_TO_ADMIN_ADDRESS[region_no] = _address;
        emit RegionAdminAdded(region_no,_address);
        return true;
    }
     
    /*Change particular region Admin*/ 
    function CHANGE_REGION_ADMIN(uint256 _region_no ,address _address) public onlyOwner returns(bool){
        require(REGION_NO_TO_ADMIN_ADDRESS[_region_no] != address(0),"no admin for this region number");
        REGION_NO_TO_ADMIN_ADDRESS[_region_no] = _address;
        emit RegionAdminChanged(_region_no,_address);
        return true;
    }
    
    /*Remove existing owner and add new owner*/
    function modify(address _oldAddress ,address _newAddress)public onlyOwner isAdmin(_oldAddress){
        removeOwner(_oldAddress);
        addOwner(_newAddress);
    }
    
     /*Add new owner*/
    function addOwner(address _owner) onlyOwner public returns(bool){         
        require(_owners[owner] == false,"owner is already an owner");  
        _owners[_owner] = true;
        emit ownerAdded(owner);
        return true;
    }
    
    /*Remove existing owner*/
    function removeOwner(address _owner) onlyOwner public {
        require(_owners[owner],"owner is not an owner");  
        _owners[_owner] = false;
        emit ownerRemoved(_owner);
    }
    
    /*Tranfer erc20 tokens*/
    function transferFrom(address from ,address _to, uint256 _value) private  returns (bool success) {
        require(_value>0);
        require(balances[from]>=_value);
        balances[from] = balances[from].sub(_value);     
        balances[_to] =balances[_to].add(_value);
        emit Transfer(from, _to, _value);
        return true;
    }
    
    /*Tranfer erc20 tokens when approval is given*/
    function safetransferFrom(address _from, address _to, uint256 _value) public payable returns (bool success) {
        require (_value>0);
        require(_value <= allowance[_from][msg.sender]); 
        balances[_from]= balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowance[_from][msg.sender]=allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    /*Approve a particular Spender Address*/
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] += _value;                               
        emit Approval(msg.sender,_spender, _value);
        return true;
    }
    
    /*Return token balance of a particular account*/
    function balanceOf(address request) public view returns (uint256){
        return balances[request];
    }

    receive() external payable {
        emit DepositFunds(msg.sender, msg.value);
    }
    
    function InitiateTransaction(uint amount,string memory token_uri) public ONLY_SLF_AND_OWNERS returns(bool){
        ++TOKEN_ID;
        mint(owner,amount);
        mintNFTcontract(MINTNFT_DEPLOYED_ADDRESS).mint(owner,TOKEN_ID,token_uri);
        return true;
    }
    
    function MINT_SLC(address account,uint256 amount) public onlyOwner {
        mint(account,amount);
    }
    
    /*Mint erc20 tokens*/
    function mint(address account, uint256 amount) private  {
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function walletBalance() view public returns (uint) {
      return address(this).balance;
    }
    
    
    /*-------------------------------------------------------------------------AUCTION_FUNCTIONS---------------------------------------------------------------*/
    
    /*Enlist or Configure Auction*/
    function EnlistAuction(string memory uid,
                           uint s_date,
                           uint e_date,
                           uint res_price,
                           uint sl_reserve,
                           uint noOfTokens,
                           string memory property_id) public onlyOwner returns(bool){
        bool success = AuctionContract(AUCTION_DEPLOYED_ADDRESS).Enlist_Auction(uid,s_date,e_date,res_price,sl_reserve,noOfTokens,property_id);
        require(success,"Auction Not Enlisted");
        return success;
    }
    
    /*EndAuction*/
    function EndAuction(string memory uid) public onlyOwner returns(bool,uint,uint){
        //call only by escrow account owner
        (bool success,uint owner_money,uint treasury_money) = AuctionContract(AUCTION_DEPLOYED_ADDRESS).End_Auction(uid);
        return(success,owner_money,treasury_money);

        /* ------------------------------------------------------Do this part from application if success is true-----------------------------------------
        if(success){
            //Transfer DAI tokens to Treasury and PropertyTokenOwner
            require(daiInstance.transferFrom(msg.sender,Property_Token_Owner,owner_money),"DAI TRANSFER TO TOKEN OWNER FAIL ");
            require(daiInstance.transferFrom(msg.sender,Treasury_Admin,treasury_money),"DAI TRANSFER TO TREASURY ADMIN FAIL");
            return true;
        }
        else{
            //Transfer SLC tokens back to owner
            //require(transferFrom(Treasury_Admin,msg.sender,tokens),"AUCTION_TOKENS_TRANSFER_ERROR");
        
        }
        */
        
    }
    
    /*Store amount of SLC TOKENS WIN IN AUCTION */
    function STORE_AUCTION_TOKENS_TO_BE_GIVEN(string memory auctionID,address[] memory BiddersArray,uint[] memory BidAmount) public onlyOwner{
        for(uint i=0;i<BiddersArray.length;i++)
        GET_WIN_SLC[auctionID][BiddersArray[i]] = BidAmount[i];
    }
    
    /*Get Auction Tokens if you are eligible and auction is completed successfully*/
    function GET_AUCTION_WIN_SLC(string memory auctionID,address Treasury_Admin) public returns(bool){
        bool success = AuctionContract(AUCTION_DEPLOYED_ADDRESS).CheckBidderIdentity(auctionID,msg.sender);
        require(success,"CALLER_IS_NOT_VALID_BIDDER");
        require(transferFrom(Treasury_Admin,msg.sender,GET_WIN_SLC[auctionID][msg.sender]),"AUCTION_TOKENS_TRANSFER_ERROR");
        delete GET_WIN_SLC[auctionID][msg.sender];
        emit SLC_TOKEN_TRANSFER_SUCCESS(auctionID,msg.sender);
        return true;
    }
    
    
    
}

library SafeMaths {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}