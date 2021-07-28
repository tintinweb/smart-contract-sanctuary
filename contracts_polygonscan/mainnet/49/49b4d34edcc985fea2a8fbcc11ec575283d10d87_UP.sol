/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}




contract OwnerRole {
  


    event OwnerRemoved(address indexed account);
    event OwnershipTransferred(address indexed previousAccount,address indexed newAccount);

    address private _owner;

    constructor ()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender));
         _;
    }

    function isOwner(address account) public view returns (bool) {
        return _owner == account;
        
    }

    function transferOwnership(address account) public onlyOwner {
        _transferOwnership(account);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner,newOwner);
        _owner = newOwner ;
        
    }

    function renounceOwnership() public onlyOwner {
       
         emit OwnershipTransferred(address(0), _owner);
        _owner = address(0);
    }
}





contract MinterRole is OwnerRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor ()  {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}



interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event ProposalUpdated(address indexed owner,
                        uint256 proposalID,
                        bool result,
                        uint256 value);
}





/**
 * @title UnifiProtocolTokens interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
interface UnifiProtocolTokens {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function updateFeeState(uint256 fee) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );


}

interface IUnifiCallee {
    function unifiCall(address sender, uint amount0) external payable;
}


contract UP is MinterRole {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _percentFactor = 100000;
    uint256 private _mintRate = 95000;
    uint256 private _burnRate = 100000;
    uint256 private _ulRate=100000;
    uint256 private BaseFactor =10 ;
    UnifiProtocolTokens FTToken;
    UnifiProtocolTokens DexToken;
    address FTAddress;
    uint256 private totalUPBurnt = 0;
    uint256 private totalFeesGiven = 0;
    mapping (address => uint256) private _balances;  
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    bool public defaultFlashLoanEnabled = false;
    uint public  defaultFlashLoanFees = 50;//0.5%
    uint public  defaultFeesDenominator = 10000;
    
    mapping(address =>bool) public flashloanEnabled;
    mapping(address =>bool) public isZeroFeeContract;
    mapping(address =>uint) public flashLoanFees;
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor (uint8 _tokenDecimals,address _FTtoken) payable  {
        _name = "UPmatic";
        _symbol = "UPmatic";
        _decimals = _tokenDecimals;//set it same as blockchain decimals
        FTToken = UnifiProtocolTokens(_FTtoken);
        BaseFactor =BaseFactor ** _tokenDecimals ;
        require(msg.value>0 ,"Invalid amount");
        _mint(msg.sender, msg.value);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount) public onlyMinter payable returns (bool) {
       require(msg.value == amount);
        uint256 Value = getVirtualPriceForMinting(amount);
        uint256 MintAmount = amount*(_mintRate)*(BaseFactor)/(Value*(_percentFactor));  
        uint256 ULAmount = MintAmount*(_ulRate)/(_percentFactor);
        uint256 FTAmount = MintAmount*(_percentFactor- _ulRate)/_percentFactor;
        _mint(to, ULAmount);
  
        DexToken =  UnifiProtocolTokens(to);
        DexToken.updateFeeState(ULAmount);

        if(FTAmount > 0){
            _mint(address(FTToken), FTAmount); 
            FTToken.updateFeeState( FTAmount);            
        }
        return true;
    }


        /**
     * @dev Burns a specific amount of tokens and return the backed value
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

            /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function justBurn(uint256 value) public {
        _justBurn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The address which you want to send tokens from
     * @param value uint256 The amount of token to be burned
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }


    function getFlashloanFee(address _pool) public view returns(uint){
        if(isZeroFeeContract[_pool] == true){
            return 0;
        }else{
            return flashLoanFees[_pool]> 0?flashLoanFees[_pool]:defaultFlashLoanFees;
        }

    }
    function flashLoan( address to , uint amount) public{
        
        if((defaultFlashLoanEnabled || flashloanEnabled[msg.sender]) && amount <= address(this).balance){
            uint currentBalance = address(this).balance;
           // address(to).transfer(amount);//optimially give to user
            IUnifiCallee(to).unifiCall{value:amount}(to, amount);
            uint newBalanceMinimumAmount = currentBalance + (loanFeeAmount( msg.sender ,  amount));
            require(newBalanceMinimumAmount <= address(this).balance , 'Unifi: INSUFFICIENT_INPUT_AMOUNT'); 
        }


    }

    function loanReturnAmount(address from , uint loanAmount)public view  returns(uint){
       return  loanAmount + (loanFeeAmount(from , loanAmount));
    }
    
    function loanFeeAmount(address from , uint loanAmount)public view  returns(uint){
       return loanAmount*(getFlashloanFee(from))/(defaultFeesDenominator);
    }
    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @return the number of price of UP token
     */
    function getVirtualPrice() public view returns(uint256){
        uint256 baseTokenbal = address(this).balance;
        uint256 Value =(baseTokenbal*(BaseFactor))/(_totalSupply); 
        return Value;
    }

    function getVirtualPriceForMinting(uint value) public view returns(uint256){
        uint256 baseTokenbal = (address(this).balance)-(value);
        uint256 Value =(baseTokenbal*(BaseFactor))/(_totalSupply); 
        return Value;
    }


    function updateDefaultFlashLoanFees(uint _amount) public onlyOwner{
        defaultFlashLoanFees = _amount;
    }

    function updateDefaultFlashLoanEnable(bool _value) public onlyOwner{
        defaultFlashLoanEnabled = _value;
    }
    function updateFlashLoanFees(address _pool , uint _amount) public onlyOwner{
        flashLoanFees[_pool] = _amount;
    }
    
    function updateFlashLoanFees(address _pool , bool _value) public onlyOwner{
        flashloanEnabled[_pool] = _value;
    }
    
    function updateisZeroFeeContract(address _pool , bool _value) public onlyOwner{
        isZeroFeeContract[_pool] = _value;
    }    

    function updateFTToken(address account) public onlyOwner returns (address){
        FTToken  = UnifiProtocolTokens(account);
        FTAddress = account;
        return address(FTToken);
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param _account The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _account) public view returns (uint256) {
        return _balances[_account];
    }
    

    function getTotalFeesGiven() public view returns (uint256) {
        return totalFeesGiven;
    }


    function getTotalUPBurnt() public view returns (uint256) {
        return totalUPBurnt;
    }             
    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address owner,
        address spender
    )
    public
    view
    returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token for a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }


    function transferMulti(address[]memory  to, uint256[] memory value) public returns (bool) {

        uint256 i = 0;
        while (i < to.length) {
             _transfer(msg.sender,to[i] , value[i]);
            i++;
         }
         return true;
    }
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    public
    returns (bool)
    {
        _allowed[from][msg.sender] = _allowed[from][msg.sender]-(value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(
        address spender,
        uint256 addedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender] + (addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    )
    public
    returns (bool)
    {
        require(spender != address(0));

        _allowed[msg.sender][spender] = (
        _allowed[msg.sender][spender]-(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from] - (value);
        _balances[to] = _balances[to] + (value);
        emit Transfer(from, to, value);

    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply + (value);
        _balances[account] = _balances[account] + (value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account and returns the backed value
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        uint256 virtualPrice = getVirtualPrice();
        uint256 redeemValue = (virtualPrice * (value)) / (BaseFactor);
        totalUPBurnt = totalUPBurnt + (value);
        totalFeesGiven = totalFeesGiven+ (redeemValue);
        payable(address(account)).transfer(redeemValue);
        _totalSupply = _totalSupply - (value);
        _balances[account] = _balances[account] - (value);
        emit Transfer(account, address(0), value);
    }


        /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _justBurn(address account, uint256 value) internal {
        require(account != address(0));
        _totalSupply = _totalSupply - (value);
        _balances[account] = _balances[account] - (value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
        // this function needs to emit an event with the updated approval.
        _allowed[account][msg.sender] = _allowed[account][msg.sender] - (
            value);
        _burn(account, value);
    }
     
    /**
     * @dev Withdraw airdrop tokens or accidental transfer
     * @param tokenAddress The aToken Address
     * @param amount Amount to withdraw
     */     
    function transferOtherTokens(address tokenAddress,uint256 amount )public onlyOwner returns (bool){
  
        require(address(this) != tokenAddress);
        IBEP20 otherTokens = IBEP20(tokenAddress);
        otherTokens.transfer(msg.sender, amount);
        return true;
    
    }
    function updateValues(string calldata fieldName,uint256 amount) public  returns (bool) {
    require(isOwner(msg.sender) ,'UPToken: NOT_AUTHORIZED');

    if(compareStrings(fieldName,"MintRate")){
      _mintRate = amount;
      return true;
    }
    else if(compareStrings(fieldName,"ULRate")){
      _ulRate = amount;
      return true;
    }
    else if(compareStrings(fieldName,"BurnRate")){
      _burnRate = amount;
      return true;
    }


    return false;
  }

   function compareStrings (string memory a, string memory b) internal pure   
       returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))) );

  }

      fallback() external payable {

    }

    receive() external payable {

    }

}