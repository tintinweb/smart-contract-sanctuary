/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

contract MYLPowerball {
    using SafeMath for uint256;
    address private _owner;                                 // Variable for Owner of the Contract.
    uint256 private _ticketPrice;                           // Variable for price of each ticket (set as 0.01 eth)
    uint256 private _purchaseTokenAmount;                   // variable for Amount of tokens per ticket purchase (set as 10 lotto)
    // address private _buyerPoolAddress;                      // Variable for pool address for tokens for ticket purchase
    
    IERC20 lottoCoin;



    constructor (uint256 ticketPrice, uint256 purchaseTokenAmount, address owner, address _poolToken)  {
        _ticketPrice = ticketPrice;
        _purchaseTokenAmount = purchaseTokenAmount;
        _owner = owner;
        lottoCoin = IERC20(_poolToken);
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
    

    // //Internal function for checking values for purchaseTicket
    // function getNumber(uint256 _number) internal pure returns(uint256){
    //   return  _number.div(6);
    // }

    
    /**
     * @dev InitiateSmartContractValue 
    */
    function initiateSmartContractValue(uint256 _elapseTime) public onlyOwner returns(bool){
        saleStartTimeStamp[saleIdNow] = block.timestamp;                                                        //Initiate time
        saleParticipants[saleIdNow] = 0;                                                            //Initiate sale participants
        elapsedTime = _elapseTime;                                                                  //Time for next sale                                                        
        return true;  
    }
    
    /**
     * @dev perform purchase
     * @param _ticketNumbers ticket number from the list in application
    */
    
    
    function purchaseTicket(uint256 _ticketNumbers, uint256 ticketCount) external payable returns(bool)
    {
            if(_ticketNumbers == 0){
                totalDonation = totalDonation + 1;
                return true;
            }
            require(msg.value >= ticketCount.mul(_ticketPrice), "Insufficient eth value");
            require(_ticketNumbers.div(10**(ticketCount.mul(12))) ==0 && _ticketNumbers.div(10**(ticketCount.mul(12).sub(2))) >0, "Invalid ticket value/count" );
       
            uint256 saleId;
            if((saleStartTimeStamp[saleIdNow] + elapsedTime) > block.timestamp){
                 saleId = saleIdNow;
            } else {
                 saleId = saleIdNow.add(1);
            }
    
          AllParticipantAddresses.push(msg.sender);
          totalSaleAmount[saleId] = totalSaleAmount[saleId] + msg.value;
          totalSaleAmountForAllSales = totalSaleAmountForAllSales + msg.value;
          totalSaleAmountByAddAndSaleID[saleId][msg.sender] = totalSaleAmountByAddAndSaleID[saleId][msg.sender] + msg.value;
       
            ticketNumberByAddress[saleId][msg.sender].push(_ticketNumbers);
            
        if(ticketCount == 5){
            lottoCoin.transfer(msg.sender,_purchaseTokenAmount);
            
          allAddressList[saleId].push(msg.sender);
          saleParticipants[saleId]  = saleParticipants[saleId] + 1;
          return true;
           
        }
        return true;
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
        saleEndTimeStamp[saleIdNow] = block.timestamp;
        saleStartTimeStamp[saleIdNow+1] = block.timestamp;
        saleIdNow = saleIdNow +1;
        return true;
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
    
    function withdrawTokenFromContract(address tokenAddress, uint256 amount, address receiver) external onlyOwner {
        require(IERC20(tokenAddress).balanceOf(address(this))>= amount, "Insufficient amount to transfer");
        IERC20(tokenAddress).transfer(receiver,amount);
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
     * @dev get total eth by user address and saleId 
    */
    function getTotalSaleAmountByAddAndSaleID(uint256 _saleId, address _userAddress) external view returns(uint256){
        return totalSaleAmountByAddAndSaleID[_saleId][_userAddress];
    }
    
    function getprize(uint256 ticketCount) public view returns(uint256)
    {
        return ticketCount.mul(_ticketPrice);
    }
 
}