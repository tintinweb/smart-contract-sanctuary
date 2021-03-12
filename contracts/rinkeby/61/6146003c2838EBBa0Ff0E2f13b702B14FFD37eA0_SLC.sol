/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface mintNFTcontract{
     function mint(address,uint256,string memory) external;
}

interface SLFContract{
     function listFromTempInfo(uint) external;
}

interface AuctionContract{
     function CheckBidderIdentity(string memory,address,uint) external returns(bool);
     function Enlist_Auction(string memory,uint,uint,uint,uint,uint,string memory) external returns(bool);
     function End_Auction(string memory) external returns(bool,uint,uint);
}
interface USDC {
    
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
    address public SLf_contract_address; 
    
    /*Deployed address of mintNFT contract*/
    address public mintNFT_contract_address; 
    
    /*Deployed address of Auction Contract*/
    address public auction_contract_address;
    
    /*Token Name*/
    string  public name = "SLC";
    
    //usdc contract Instance
    USDC public usdcInstance = USDC(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);
    
    /*Token Symbol*/
    string  public symbol = "S";
    
    /*Number of decimal in Token Amount*/
    uint256 public decimals = 0;
    
    /*Total supply of token*/
    uint256 public totalSupply;
    
    /*Minimum Number of Signatures required in order to complete a pending transaction*/
    uint constant MIN_SIGNATURES = 2;
    
    /*Cuurent Transaction Number*/
    uint public _transactionIdx;
    
    address private Escrow_Address;
    
    /*Structure to store Transaction Details*/
    struct Transaction {
      address to;
      uint amount;
      uint tokenid;
      uint8 signatureCount;
      string tokenURI;
      string propertyID;
      mapping (address => uint8) signatures;
    }

    /*Mapping to store Trnsaction details structure with their transaction number*/
    mapping (uint => Transaction) public _transactions;
    
    /*Mapping to show token balance of particular address*/
    mapping(address =>uint256) balances;
    
    /*Mapping to show current token allowance given to particular address*/
    mapping(address =>mapping(address=>uint256)) public allowance;
    
    /*Mapping to show particular Address is owner or not*/
    mapping(address => bool) public _owners;
    
    /*Mapping to store particular address to a region number*/
    mapping(uint => address) region_no_to_admin_address;
    
    /*Array to store Transaction Number of Pending Transaction*/
    uint[] private _pendingTransactions;
    
    /*How many trnsactions are still pending*/
    uint private count_pending_transactions;

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
        require(msg.sender == Escrow_Address,"caller is not contract owner");
        _;
    }
    
    function get_escrow_address() public view onlyOwner returns(address){
        return Escrow_Address;
    }
    
     function set_escrow_address(address new_address) public onlyOwner returns(bool){
        require(new_address!=address(0));
        Escrow_Address = new_address;
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
    modifier onlySLFcontract{
        require(msg.sender == SLf_contract_address,"caller is not SLF contract");
        _;
    }
    
    /*To check whether a function is call by Auction contract or not*/
    modifier onlyAuctionContract{
        require(msg.sender == auction_contract_address,"caller is not Auction contract");
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
    
    /*Emits when a transaction is created to sign*/
    event TransactionCreated(address,uint,uint,string);
    
    /*Emits when a transaction is Signed by minimum no of Owners required*/
    event TransactionCompleted(address,uint,uint,string);
    
    /*Emits when a transaction is Signed*/
    event TransactionSigned(address,uint);

    constructor(uint256 _initialSupply) public {
        owner = msg.sender;
        balances[msg.sender] = _initialSupply;
        totalSupply=_initialSupply;
        emit Transfer(address(0),msg.sender,_initialSupply);
    }
    
    /*Approve Auction Contract*/
    function Approve_Auction_Contract(address from , address spender ,uint256 _value) public onlyAuctionContract returns(bool) {
        require(spender == msg.sender,"spender is not auction contract");
        allowance[from][spender] += _value;
        emit Approval(from,spender,_value);
        return true;
    }
    
    /*Set Auction Contract Address*/
    function setAuctionContractAddress(address _address) public onlyOwner returns(bool){
        require(_address!=address(0));
        auction_contract_address = _address;
        return true;
    }
    
    /*Store SLF Contract Deployed Address*/
    function setSLF_contract_address(address _address) public onlyOwner returns(bool){
        require(_address!=address(0));
        SLf_contract_address = _address;
        return true;
    }
    
    /*Store mintNFT Contract Deployed Address*/
    function setmintNFT_contract_address(address _address) public onlyOwner returns(bool){
        mintNFT_contract_address = _address;
        return true;
    }
    
    /*Store a particular region admin*/
    function add_region_admin(uint region_no,address _address) public onlyOwner returns(bool){
        require(region_no_to_admin_address[region_no] == address(0),"An admin is already there for this region");
        region_no_to_admin_address[region_no] = _address;
        emit RegionAdminAdded(region_no,_address);
        return true;
    }
     
    /*Change particular region Admin*/ 
    function change_region_admin(uint256 _region_no ,address _address) public onlyOwner returns(bool){
        require(region_no_to_admin_address[_region_no] != address(0),"no admin for this region number");
        region_no_to_admin_address[_region_no] = _address;
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
    
    function EnlistAuction(string memory uid,
                           uint s_date,
                           uint e_date,
                           uint res_price,
                           uint sl_reserve,
                           uint noOfTokens,
                           string memory property_id) public onlyOwner returns(bool){
        bool success = AuctionContract(auction_contract_address).Enlist_Auction(uid,s_date,e_date,res_price,sl_reserve,noOfTokens,property_id);
        require(success,"Auction Not Enlistedr");
        return success;
    }
    
    function claimAuctionTokensIfSuccess(string memory auctionID,address Treasury_Admin,uint tokens) public returns(bool){
        bool success = AuctionContract(auction_contract_address).CheckBidderIdentity(auctionID,msg.sender,tokens);
        require(success,"caller is not valid bidder");
        require(transferFrom(Treasury_Admin,msg.sender,tokens),"Auction Tokens Transfer Error");
        emit SLC_TOKEN_TRANSFER_SUCCESS(auctionID,msg.sender);
        return true;
    }
    
    function EndAuction(string memory uid,address Treasury_Admin,address Token_Owner) public onlyEscrow returns(bool){
        //call only by escrow account owner
        (bool success,uint owner_money,uint treasury_money) = AuctionContract(auction_contract_address).End_Auction(uid);
        require(success,"Auction Not Success");
        if(success){
            //Transfer usdc tokens to Treasury and TokenOwner
            require(usdcInstance.transferFrom(msg.sender,Token_Owner,owner_money),"USDC TRANSFER TO TOKEN OWNER FAIL ");
            require(usdcInstance.transferFrom(msg.sender,Treasury_Admin,treasury_money),"USDC TRANSFER TO TREASURY ADMIN FAIL");
            return true;
        }
        else{
            //Transfer SLC tokens back to owner
            //require(transferFrom(Treasury_Admin,msg.sender,tokens),"Auction Tokens Transfer Error");
        
        }
        return false;
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

    /*Only SLF contract can call this function*/
    function InitiateTransaction(uint tokenid,address receiver,uint amount,string memory token_uri,string memory propertyID) public onlySLFcontract returns(uint256){
        //require(region_no_to_admin_address[property_region] != address(0),"no admin for this region");
        return transferTo(tokenid,receiver, amount,token_uri,propertyID);
    }
    
    /*Store transaction details*/
    function transferTo(uint tokenid,address to, uint amount,string memory token_uri,string memory propertyID) internal returns(uint256) {
        uint transactionId = ++_transactionIdx;
        Transaction memory transaction;
        transaction.to = to;
        transaction.amount = amount;
        transaction.tokenid = tokenid;
        transaction.signatureCount = 0;
        transaction.tokenURI = token_uri;
        transaction.propertyID = propertyID;
        _transactions[transactionId] = transaction;
        _pendingTransactions.push(transactionId);
        count_pending_transactions++;
        emit TransactionCreated(to, amount, transactionId,propertyID);
        return transactionId;
    }
    
    /*Mint erc20 tokens*/
    function mint(address account, uint256 amount) private  {
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /*return array of pending transactions*/
    function getPendingTransactions() public view validOwner returns (uint[] memory) {
      uint[] memory temp = new uint[](count_pending_transactions);
      uint j;
      for(uint i = 0; i < _pendingTransactions.length; i++) {
              if (_pendingTransactions[i] != 0) {
                temp[j++] = _pendingTransactions[i];
              }
      }
      return temp;
    }

    /*Only a valid owner can sign the transaction*/
    function signTransaction(uint transactionId) public validOwner payable{
      Transaction storage transaction = _transactions[transactionId];
      require(transaction.signatures[msg.sender] != 1);
      transaction.signatures[msg.sender] = 1;
      transaction.signatureCount++;
      emit TransactionSigned(msg.sender, transactionId);
      if (transaction.signatureCount >= MIN_SIGNATURES) {
        mint(transaction.to,transaction.amount);
        SLFContract(SLf_contract_address).listFromTempInfo(transaction.tokenid);
        mintNFTcontract(mintNFT_contract_address).mint(transaction.to,transaction.tokenid,transaction.tokenURI);
        emit TransactionCompleted(transaction.to, transaction.amount, transactionId,transaction.propertyID);
        deleteTransaction(transactionId);
      }
    }

   /*Delete particular transaction using its id*/
    function deleteTransaction(uint transactionId) validOwner public {
      for(uint i = 0; i < _pendingTransactions.length; i++) {
         if (transactionId == _pendingTransactions[i]) {
          _pendingTransactions[i] = 0;
          break;
        }
      }
      count_pending_transactions--;
      delete _transactions[transactionId];
    }

    function walletBalance() view public returns (uint) {
      return address(this).balance;
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