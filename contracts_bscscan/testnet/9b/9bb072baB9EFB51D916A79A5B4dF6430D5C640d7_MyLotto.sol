/**
 *Submitted for verification at BscScan.com on 2021-07-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-20
*/

pragma solidity ^0.5.2;
// -----------------------------------------------------//
// Symbol : MYL                                         //
// Name : My Lotto Coin                                 //
// Total supply: 100000000                              //
// Decimals :18                                         //
// Token Price : 10000000000000000                      //
// Purchase Token Amount : 10000000000000000000         //
//------------------------------------------------------//

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event EtherTransfer(address toAddress, uint256 amount);

}

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b,"Invalid values");
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0,"Invalid values");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a,"Invalid values");
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a,"Invalid values");
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"Invalid values");
        return a % b;
    }
}

contract MyLotto is IERC20 {
    using SafeMath for uint256;
    address private _owner;                                 // Variable for Owner of the Contract.
    string private _name;                                   // Variable for Name of the token.
    string private _symbol;                                 // Variable for symbol of the token.
    uint8 private _decimals;                                // variable to maintain decimal precision of the token.
    uint256 private _totalSupply;                           // Variable for total supply of token.
    uint256 private _ticketPrice;                           // Variable for price of each ticket (set as 0.01 eth)
    uint256 private _purchaseTokenAmount;                   // variable for Amount of tokens per ticket purchase (set as 10 lotto)
    address private _buyerPoolAddress;                      // Variable for pool address for tokens for ticket purchase
    
    uint256 public airdropTokenCount = 0;                   // Variable for token airdrop count
    uint256 public airdropETHCount = 0;                     // Variable for ETH airdrop count

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;
    
    constructor (string memory name, string memory symbol, uint8 decimals, uint256 totalSupply, uint256 ticketPrice, uint256 purchaseTokenAmount, address buyerPoolAddress, address owner) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = totalSupply*(10**uint256(decimals));
        _balances[owner] = _totalSupply;
        _ticketPrice =ticketPrice;
        _purchaseTokenAmount = purchaseTokenAmount;
        _buyerPoolAddress = buyerPoolAddress;
        _owner = owner;
    }

    /*----------------------------------------------------------------------------
     * Functions for owner
     *----------------------------------------------------------------------------
     */

    /**
    * @dev get address of smart contract owner
    * @return address of owner
    */
    function getowner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev modifier to check if the message sender is owner
    */
    modifier onlyOwner() {
        require(isOwner(),"You are not authenticate to make this transfer");
        _;
    }
    
    // modifier onlyairdropAddress(){
    //     require(_airdropETHAddress,"");
    //     _;
    // }

    /**
     * @dev Internal function for modifier
     */
    function isOwner() internal view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfer ownership of the smart contract. For owner only
     * @return request status
      */
    function transferOwnership(address newOwner) public onlyOwner returns (bool){
        _owner = newOwner;
        return true;
    }


    /* ----------------------------------------------------------------------------
     * View only functions
     * ----------------------------------------------------------------------------
     */

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
     * @dev Total number of tokens in existence.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /* ----------------------------------------------------------------------------
     * Transfer, allow, mint, airdrop and burn functions
     * ----------------------------------------------------------------------------
     */

    /**
     * @dev Transfer token to a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
            _transfer(msg.sender, to, value);
            return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
             _transfer(from, to, value);
             _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
             return true;
    }


     /**
      * @dev Airdrop function to airdrop tokens. Best works upto 50 addresses in one time. Maximum limit is 200 addresses in one time.
      * @param _addresses array of address in serial order
      * @param _amount amount in serial order with respect to address array
      */
    function airdropToken(address[] memory _addresses, uint256[] memory _amount) public onlyOwner returns (bool){
          require(_addresses.length == _amount.length,"Invalid Array");
          uint256 count = _addresses.length;
          for (uint256 i = 0; i < count; i++){
               _transfer(msg.sender, _addresses[i], _amount[i]);
               airdropTokenCount = airdropTokenCount + 1;
          }
          return true;
    }
    
    /**
      * @dev Airdrop function to airdrop ETH. 
      * @param _toAddresses array of address in serial order
      * @param _amount amount in serial order with respect to address array
      */
    function airdropEther(address payable[] memory _toAddresses, uint256[] memory _amount) public payable returns (bool) {
        require(_toAddresses.length == _amount.length,"Invalid Array length, Please Try Again!!!");
        uint256 total = 0;
        for(uint256 j = 0; j < _amount.length; j++) {
            total = total.add(_amount[j]);
        }
        require(total <= msg.value,"Invalid Amount, Please try again!!!");
        for (uint256 i = 0; i < _toAddresses.length; i++) {
            require(_toAddresses[i] != address(0),"Invalid Address, Please try again");
            _toAddresses[i].transfer(_amount[i]);
            emit EtherTransfer(_toAddresses[i], _amount[i]);
            airdropETHCount = airdropETHCount + 1;
        }
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses.
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0),"Invalid to address");
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
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
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0),"Invalid address");
        require(owner != address(0),"Invalid address");
        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0.
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0),"Invalid account");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public onlyOwner{
        _burn(msg.sender, value);
    }
    
    //Contract for managing business logic for this application 
    
    mapping (uint256 => address[]) private allAddressList;                                      //list of all address participating in a saleId
    mapping (uint256 => address[]) private winner;                                              //winner address for a saleId
    mapping (uint256 => uint256) private winningPowerBallNumber;                                //winning powerball number by saleId
    mapping (uint256 => mapping (address => uint256[])) private ticketNumberByAddress;          //user ticket number for a saleId
    mapping (uint256 => mapping (uint256 => address[])) private addressesByTicketNumber;        //list of addresses for ticketId
    mapping (uint256 => mapping (address => uint256)) private totalSaleAmountByAddAndSaleID;    //list of addresses for ticketId
    mapping (uint256 => uint256) private totalSaleAmount;                                       //total collection for a saleId
    mapping (uint256 => uint256[]) private winningAmount;                                       //winning price for a saleId
    mapping (uint256 => uint256) private saleStartTimeStamp;                                    //start timestamp for a saleId
    mapping (uint256 => uint256) private saleEndTimeStamp;                                      //end timestamp for a  saleId
    mapping (uint256 => uint256) private saleRunningStatus;                                     //sale running status for a saleId
    mapping (uint256 => uint256[]) private winningNumber;                                       //winning lottery number for a saleId
    mapping (uint256 => uint256) private saleParticipants;                                      //total number sales per sale session
    
    uint256 private elapsedTime;                                                                //variable to set time for powerball winning 
    uint256 private saleIdNow = 1;                                                              //saleIdNow for sale now 
    address[] private AllParticipantAddresses;                                                  //list of all participants participated in the sale
    uint256 private totalSaleAmountForAllSales;                                                 //total amount including all sales
    uint256 private totalDonation;                                                              //total donated amount
    uint256[] public checkerEmpty;
    

    //Internal function for checking values for purchaseTicket
    function getNumber(uint256 _number) internal pure returns(uint256){
       return  _number.div(6);
    }

    
    /**
     * @dev InitiateSmartContractValue 
    */
    function initiateSmartContractValue(uint256 _elapseTime) public onlyOwner returns(bool){
        saleStartTimeStamp[saleIdNow] = now;                                                        //Initiate time
        saleParticipants[saleIdNow] = 0;                                                            //Initiate sale participants
        elapsedTime = _elapseTime;                                                                  //Time for next sale                                                        
        return true;  
    }
    
    /**
     * @dev perform purchase
     * @param _ticketNumbers ticket number from the list in application
    */
    function purchaseTicket(uint256[] memory _ticketNumbers) public payable returns(bool){
        require(( _ticketNumbers.length == 1 || _ticketNumbers.length == 2 || _ticketNumbers.length == 3 || _ticketNumbers.length == 4 || _ticketNumbers.length == 5 || _ticketNumbers.length == 6 || 
            _ticketNumbers.length == 7 || _ticketNumbers.length == 8 || _ticketNumbers.length == 9 || _ticketNumbers.length == 10) , "Invalid Value");
            require(msg.value >= _ticketNumbers.length.mul(_ticketPrice), "Insufficient eth value");
            // require(_ticketNumbers.div(10**(_ticketCount.mul(12))) ==0 || _ticketNumbers.div(10**(_ticketCount.mul(12).sub(2))) >0, "Invalid ticket value/count" );
        // if(_ticketNumbers.length > 1){
            uint256 saleId;
            if((saleStartTimeStamp[saleIdNow] + elapsedTime) > now){
                 saleId = saleIdNow;
            } else {
                 saleId = saleIdNow.add(1);
            }
          AllParticipantAddresses.push(msg.sender);
          totalSaleAmount[saleId] = totalSaleAmount[saleId] + msg.value;
          totalSaleAmountForAllSales = totalSaleAmountForAllSales + msg.value;
          totalSaleAmountByAddAndSaleID[saleId][msg.sender] = totalSaleAmountByAddAndSaleID[saleId][msg.sender] + msg.value;
          for (uint256 i = 0; i < _ticketNumbers.length; i++){
              for(uint256 j = 0; j < 6; j++ ){
            
                ticketNumberByAddress[saleId][msg.sender].push(_ticketNumbers[i]%100);
                _ticketNumbers[i] = _ticketNumbers[i].div(100);
              }
              
            
          }
           if(_ticketNumbers.length == 10){
            _transfer(_buyerPoolAddress,msg.sender,_purchaseTokenAmount);
           }
          allAddressList[saleId].push(msg.sender);
          saleParticipants[saleId]  = saleParticipants[saleId] + 1;
          return true;
            // }
            // else {
            //   AllParticipantAddresses.push(msg.sender);
            //   totalSaleAmount[saleIdNow + 1] = totalSaleAmount[saleIdNow + 1] + msg.value;
            //   totalSaleAmountForAllSales = totalSaleAmountForAllSales + msg.value;
            //   for (uint256 i = 0; i < _ticketNumbers.length; i++){
            //       for(uint256 j = 0; j < 6; j++ ){
                
            //         ticketNumberByAddress[saleIdNow + 1][msg.sender].push(_ticketNumbers[i]%100);
            //         _ticketNumbers[i] = _ticketNumbers[i].div(100);
            //       }
            //   }
            //   if(_ticketNumbers.length == 60){
            //      _transfer(_buyerPoolAddress,msg.sender,_purchaseTokenAmount);
            //   }
            //   allAddressList[saleIdNow + 1].push(msg.sender);
            //   saleParticipants[saleIdNow + 1]  = saleParticipants[saleIdNow + 1] + 1;
            //   return true;
            // }
        // }
        // else{
        //     totalDonation = totalDonation + 1;
        // }
    }

    /**
     * @dev declare winner for a sale session
    */
    function declareWinner(uint256[] calldata _winningSequence, uint256 _powerballNumber, address payable[] calldata _winnerAddressArray, uint256[] calldata _winnerPositions, uint256[]  calldata _winnerAmountInWei) external payable onlyOwner returns(bool){
        require(_winnerAddressArray.length == _winnerAmountInWei.length || _winnerAmountInWei.length == _winnerPositions.length, "Invalid winner declaration data");
        for(uint256 i=0;i<_winnerAddressArray.length;i++){
             winner[saleIdNow].push(_winnerAddressArray[i]);
             winningAmount[saleIdNow].push(_winnerAmountInWei[i]);
            _winnerAddressArray[i].transfer(_winnerAmountInWei[i]);
        }
        for(uint256 j=0;j<_winningSequence.length;j++){
            winningNumber[saleIdNow].push(_winningSequence[j]);
        }
        winningPowerBallNumber[saleIdNow] =  _powerballNumber;
        saleEndTimeStamp[saleIdNow] = now;
        saleStartTimeStamp[saleIdNow+1] = now;
        saleIdNow = saleIdNow +1;
    }
    
    /**
     * @dev set elapsed time for powerball
    */
    function setElapsedTime(uint256 time) public onlyOwner returns(bool){
        require(time > 0,"Invalid time provided, Please try Again!!");
        elapsedTime = time;
        return true;
    }
    
    /**
     * @dev get elapsed time for powerball
    */
    function getElapsedTime() external view returns(uint256){
        return elapsedTime;
    }
    
    /**
     * @dev get winning powerball number
    */
    function getWinningPowerballNumberBySaleId(uint256 _saleId) external view returns(uint256){
        return winningPowerBallNumber[_saleId];
    }
    
    /**
     * @dev get current saleId for this session
    */
    function getSaleIdNow() external view returns(uint256){
        return saleIdNow;
    }

    /**
     * @dev withdraw all eth from the smart contract
    */
    function withdrawETHFromContract(uint256 _savingsValue,address payable _savingsReceiver, uint256 _opexValue, address payable _opexReceiver) external onlyOwner returns(bool){
        _savingsReceiver.transfer(_savingsValue);
        _opexReceiver.transfer(_opexValue);
        return true;
    }

    /**
     * @dev get end timeStamp by sale session 
    */
    function getEndTime(uint256 _saleId) external view returns(uint256){
        return saleEndTimeStamp[_saleId] ;
    }

    /**
     * @dev get start timeStamp by sale session 
    */
    function getStartTime(uint256 _saleId) external view returns(uint256){
        return saleStartTimeStamp[_saleId+1];
    }
    
    /**
     * @dev get winning number by sale ID
    */
    function getWinningNumber(uint256 _saleId) external view returns(uint256[] memory){
        return winningNumber[_saleId];
    }

    /**
     * @dev get winning amount by sale ID
    */
    function getWinningAmount(uint256 _saleId) external view returns(uint256[] memory){
        return winningAmount[_saleId];
    }
    

    /**
     * @dev get winning address by sale ID
    */
    function getWinningAddress(uint256 _saleId) external view returns(address[] memory){
        return winner[_saleId];
    }
    

    /**
     * @dev get list of all addresses in the Sale
    */
    function getAllSaleAddressesBySaleID(uint256 _saleId) external view returns(address[] memory){
        return allAddressList[_saleId];
    }

    /**
     * @dev get list of all addresses in the contract
    */
    function getAllParticipantAddresses() external view returns(address[] memory){
        return AllParticipantAddresses;
    }

    /**
     * @dev get total sale amount for a sale session
    */
    function getTotalSaleAmountBySaleID(uint256 _saleId) external view returns(uint256){
        return totalSaleAmount[_saleId];
    }

    /**
     * @dev get total sale amount for all sale session
    */
    function getTotalSaleAmountForAllSale() external view returns(uint256){
        return totalSaleAmountForAllSales;
    }

    /**
     * @dev get total number of participants by saleId
    */
    function getParticipantCountBySaleId(uint256 _saleId) external view returns(uint256){
        return saleParticipants[_saleId];
    }

    /**
     * @dev get price of one ticket
    */
    function getPriceOfOneTicket() external view returns(uint256){
        return _ticketPrice;
    }

    /**
     * @dev set price of one ticket by owner only
     * @param _newPrice New price of each token
    */
    function setPriceOfOneTicket(uint256 _newPrice) external onlyOwner returns(bool){
        _ticketPrice = _newPrice;
        return true;
    }

    /**
     * @dev get ticket number for the given address
     * @param _saleId Sale id for the sale session
     * @param _add New price of each token
    */
    function getticketNumberByAddress(uint256 _saleId, address _add) external view returns(uint256[] memory){
        return ticketNumberByAddress[_saleId][_add];
    }

    /**
     * @dev get amount of token sent per ticket purchase
    */
    function getpurchaseTokenAmount() external view returns(uint256){
        return _purchaseTokenAmount;
    }

    /**
     * @dev set amount of token sent per ticket purchase
    */
    function setpurchaseTokenAmount(uint256 purchaseTokenAmount) external onlyOwner returns(bool){
        _purchaseTokenAmount = purchaseTokenAmount;
        return true;
    }

    /**
     * @dev get address of pool for puchase ticket and get tokens 
    */
    function getbuyerPoolAddress() external view returns(address){
        return _buyerPoolAddress;
    }

    /**
     * @dev set address of pool for puchase ticket and get tokens 
    */
    function setbuyerPoolAddress(address buyerPoolAddress) external onlyOwner returns(bool){
        _buyerPoolAddress = buyerPoolAddress;
        return true;
    }

    /**
     * @dev get total eth by user address and saleId 
    */
    function getTotalSaleAmountByAddAndSaleID(uint256 _saleId, address _userAddress) external view returns(uint256){
        return totalSaleAmountByAddAndSaleID[_saleId][_userAddress];
    }
 
}