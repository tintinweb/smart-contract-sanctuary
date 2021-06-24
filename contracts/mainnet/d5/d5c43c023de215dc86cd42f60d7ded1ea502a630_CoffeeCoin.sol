/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity >=0.6.0 <= 0.8.5;
  
// SPDX-License-Identifier: MIT
// @title ERC20 Token
// @created_by  Stonoex

/**
 * 
 * @dev Operations with Overflow chechs.
 * 
 **/
 
library Math { 
    
    /**
     * 
     * @dev Return the subtraction of two integers, reverting with message on overflow
     * 
     **/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b <= a, "Subtraction overflow");
      return a - b;
    }
    
    /**
     * 
     * @dev Return the addition of two integers, reverting with message on overflow
     * 
     **/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a, "Addition overflow");
      return c;
    }
    
    /**
     * 
     * @dev Return the multiplication of two two integers, reverting with message on overflow
     * 
     **/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }
}


/**
 * 
 * @dev Contract that guarantees exclusive access to specific functions for the owner
 * 
 * */
abstract contract Ownable {
    address private _owner;
    address private _newOwner;
    
    event OwnerShipTransferred(address indexed oldOwner, address indexed newOwner);
    
    /**
     * 
     * @dev Setting the deployer as the initial owner.
     * 
     */
     
    constructor() {
        _owner = msg.sender;
        _newOwner = msg.sender;
        emit OwnerShipTransferred(address(0), _owner);
    }
    
     /**
     * 
     * @dev Returns the address of the current owner.
     * 
     */
    
    function owner() public view returns(address){
        return _owner;
    }
    
    /**
     * 
     * @dev Reverting with message on overflow if called by any account other than the owner.
     * 
     */
    modifier onlyOwner(){
        require(msg.sender == _owner, "You are not the owner");
        _;
    }
    
    /**
     * 
     * @dev Set new owner to transfer ownership, reverting with message on overflow if account is not the owner
     * 
     */
    function transferOwnership(address newOwner_) public onlyOwner{
        require(newOwner_ != address(0), "Invalid address");
        _newOwner = newOwner_;
    }
    
    /**
     * 
     * @dev Accept ownership, reverting with message on overflow if account is not the new owner
     * 
     */
    function acceptOwnership()public{
        require(msg.sender == _newOwner, "You are not the new owner");
        _transferOwnership(_newOwner);
    }
    
    function _transferOwnership(address newOwner_) internal{
        emit OwnerShipTransferred(_owner,newOwner_);
        _owner = newOwner_;
    }
}

/**
 * 
 * @dev Contract that guarantees pause and unpause specific functions
 * 
 * */
 
 contract Pausable is Ownable{
    event Pause();
    event Unpause();
     
    bool private _isPaused = true;
     
    function isPaused() public view returns(bool){
        return _isPaused;
    }
    
    modifier whenNotPaused(){
        require(!_isPaused, "Contract is paused.");
        _;
    }
    
    modifier whenPaused(){
        require(_isPaused, "Contract is not paused.");
        _;
    }
    
    function pause()public onlyOwner whenNotPaused{
        _isPaused = true;
        emit Pause();
    }
    
    function unpause()public onlyOwner whenPaused{
        _isPaused = false;
        emit Unpause();
    }
 }
 
 interface IERC20 {
    
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CollateralDetails is Ownable {
    
    event record(uint position, string document, string book, uint256 bags, uint256 tokens, string executionType);
    
    uint256 private _currentBags;
    string private _docURL;
    
    struct Collateral {
        string cda_wa_document;
        string book;
        uint256 bags;
        uint256 tokenAmount;
        string executionType;
    }
    
    Collateral[] private _collateralList;
    mapping(uint => Collateral) private _collateral;
    
    function getDocURL() public view returns(string memory){
        return _docURL;
    }
    
    function setDocURL(string memory url) public onlyOwner {
        _docURL = url;
    }
    
    function getCurrentBags() public view returns(uint256){
        return _currentBags;
    }
    
    function setCurrentBags(uint256 bags_) internal onlyOwner{
        _currentBags = bags_;
    }
    
    function getRecords(uint indexes_) public view returns(string [] memory documents, string[] memory books, uint256[] memory bags, uint256[] memory tokensAmounts,string[] memory executionTypes){
     require(indexes_ <= _collateralList.length, "Invalid indexes, value is greater than the _collateralList!");
       string [] memory _documents = new string[](indexes_);
       string [] memory _books = new string[](indexes_);
       uint256 [] memory _bags = new uint256[](indexes_);
       uint256 [] memory _tokenAmount = new uint256[](indexes_);
       string [] memory _executionTypes = new string[](indexes_);
       
       for( uint i = 0; i < indexes_; i++){
           Collateral storage c = _collateral[i];
           _documents[i] = c.cda_wa_document;
           _books[i] = c.book;
           _bags[i] = c.bags;
           _tokenAmount[i] = c.tokenAmount;
           _executionTypes[i] = c.executionType;
       }
       return(_documents,_books,_bags,_tokenAmount,_executionTypes);
    }
    
    function getCollateral(uint position_) public view returns(string memory cda_wa_document, string memory book, uint256 bags, uint256 tokenAmount ,string memory executionType){
        require(position_ <= _collateralList.length, "Invalid position, value is greater than the _collateralList");
        Collateral storage c = _collateral[position_];
        return (c.cda_wa_document, c.book, c.bags, c.tokenAmount,c.executionType);
    }
    
    function lastId() public view returns(uint256){
        return _collateralList.length-1;
        
    }
    
    function recordCollateral(string memory cda_wa_document_, string memory book_, uint256 bags_, uint256 tokenAmount_, string memory executionType_) internal onlyOwner{
        _collateralList.push(Collateral(cda_wa_document_,book_,bags_,tokenAmount_,executionType_));
        _collateral[_collateralList.length-1] = Collateral(cda_wa_document_,book_,bags_,tokenAmount_,executionType_);
        emit record(_collateralList.length-1, cda_wa_document_,book_,bags_,tokenAmount_,executionType_);
    }
    
}

contract CoffeeCoin is IERC20, Ownable, Pausable, CollateralDetails{
    
    using Math for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    event Burn(address indexed account, uint256 value);
    event Mint(address indexed from, address indexed to, uint256 value);
    
    constructor (string memory name_, string memory symbol_, uint256 totalSupply_, uint8 decimals_, string memory cda_wa_document_, string memory book_, uint256 bags_)  {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_.mul(10 ** decimals_);
        _decimals = decimals_;
        _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
        recordCollateral(cda_wa_document_, book_, bags_, totalSupply_, "INIT");
        setCurrentBags(bags_);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 value) public override returns (bool) {
        _transfer(sender, recipient, value);
        _approve(sender, msg.sender, _allowed[sender][msg.sender].sub(value));
        return true;
    }
    
    
    function _transfer(address from_, address to_, uint256 amount_) internal{
        require(from_ != address(0), "Sender Invalid address");
        require(to_ != address(0), "Recipient Invalid Address");
        _balances[from_] = _balances[from_].sub(amount_);
        _balances[to_] = _balances[to_].add(amount_);
        emit Transfer(from_, to_, amount_);
    }
    
    function _approve(address owner_, address spender_, uint256 amount_) internal{
        require(owner_ != address(0), "Approve from the zero address");
        require(spender_ != address(0), "Approve to the zero address");
        _allowed[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }
    
    /**
    * 
    * @dev Destroy Tokens from the caller, reverting with message on overflow if caller is not the contract owner, event Burn will record CollateralDetails
    * 
    */
    function burn(uint256 amount_, string memory cda_wa_document_, string memory book_, uint256 bags_) public onlyOwner whenNotPaused{
        require(msg.sender != address(0), "Invalid account address");
         uint256 _amount = amount_.mul(10 ** _decimals);
        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        uint256 _currentBags = getCurrentBags();
        setCurrentBags(_currentBags.sub(bags_));
        recordCollateral(cda_wa_document_, book_, bags_, amount_, "BURN");
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }
    
    /**
    * 
    * @dev Mint Tokens, reverting with message on overflow if caller is not the contract owner or the contract is not paused, event Mint will record CollateralDetails
    * 
    */
    function mint(uint256 amount_, string memory cda_wa_document_, string memory book_, uint256 bags_)public onlyOwner whenNotPaused{
        uint256 _amount = amount_.mul(10 ** _decimals);
        _totalSupply = _totalSupply.add(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        uint256 _currentBags = getCurrentBags();
        setCurrentBags(_currentBags.add(bags_));
        recordCollateral(cda_wa_document_, book_, bags_, amount_, "MINT");
        emit Mint(address(0), msg.sender, _amount);
        emit Transfer(address(0), msg.sender, _amount);
    }

}