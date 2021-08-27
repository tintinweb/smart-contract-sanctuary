/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;
// 2021-08-16 version
// contract addrees in Kovan 0xCf59b6f6d2370bDdd01F86A3178444840abF9728 
// интерфейс


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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}








contract Emergency is Pausable{

  address public one;
  address public two;
  address public three;
 


  mapping(address => bool) internal vote;

  constructor()  {
    
          
    one = 0xe10fC2E9A046D94AF465c14002399e4173d79376;
    two = 0xDd813a2558C9a373300F3FF94Eac5b447f3609a5;
    three = 0x8C9903042af113691f4cA9Db2b0f22b1F606aCCe;

   
    
    require (one != address(0), "zero address");
    require (two != address(0), "zero address");
    require (three != address(0), "zero address");
  }


// shareholders voting

    modifier agreement() {
        require(vote[one] && vote[two] && vote[three]);
        _;
    }
    
    function voting() external {
        vote[msg.sender] = true;
    }
    
    function voteInfo(address _shareholder) external view returns (bool){
        return vote[_shareholder];
    }


}
// contract SafeMath{
    
//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "SafeMath: addition overflow");

//         return c;
//     }
    
//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         return sub(a, b, "SafeMath: subtraction overflow");
//     }
    
//     function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         uint256 c = a - b;

//         return c;
//     }
    
//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) {
//             return 0;
//         }

//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");

//         return c;
//     }
    
//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         return div(a, b, "SafeMath: division by zero");
//     }
    
//     function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         uint256 c = a / b;
//         // assert(a == b * c + a % b); // There is no case in which this doesn't hold

//         return c;
//     }
    
// }







contract MyStream is Emergency, Ownable{
    
    
     constructor()  {
       
        fee = 0;
        nextStreamId = 1;
    }
    
    // Variables
    
    uint256 public nextStreamId;
    uint256 public fee;
    
    
    //Mappings
    
    mapping(uint256 => Stream) private streams; 
    uint256 public contractBalance;
    
    //Modifiers
    
     
    modifier onlySenderOrRecipient(uint256 streamId) {
        require(
            msg.sender == streams[streamId].sender || msg.sender == streams[streamId].recipient,
            "caller is not the sender or the recipient of the stream"
        );
        _;
    }

   
    modifier streamExists(uint256 streamId) {
        require(streams[streamId].isEntity, "stream does not exist");
        _;
    }
    
    function exist(uint256 streamId) public view returns (bool){
        return streams[streamId].isEntity;
    }
    
    // Structs
    
    struct Stream {
        uint256 deposit;
        uint256 ratePerSecond;
        uint256 remainingBalance;// остаток баланса
        uint256 startTime;
        uint256 stopTime;
        address recipient;
        address sender;
        address tokenAddress;
        uint256 remainder;
        bool isEntity; // объект
        uint256 blockTime;
        bool senderCancel;
        bool recipientCancel;
    }
    
    struct CreateStreamLocalVars {
        
        uint256 duration;
        uint256 ratePerSecond;
    }
    
    struct BalanceOfLocalVars {
        
        uint256 recipientBalance;
        uint256 withdrawalAmount;
        uint256 senderBalance;
    }
    
    
    
    // Events
    
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 blockTime,
        bool senderCancel,
        bool recipientCancel
    );
    
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance,
        uint256 cancelTime
    );
    
    event WithdrawFromStream(
        uint256 indexed streamId, 
        address indexed recipient, 
        uint256 amount
    );
    
    event FeeFromStream60(
        uint256 indexed streamId, 
        address indexed companyAccount, 
        uint256 fee60
    );
    
    event FeeFromStream25(
        uint256 indexed streamId, 
        address indexed companyAccount, 
        uint256 fee25
    );
    
    event FeeFromStream15(
        uint256 indexed streamId, 
        address indexed companyAccount, 
        uint256 fee_5
    );

    event TranferRecipientFromCancelStream(
        uint256 indexed streamId, 
        address indexed recipient, 
        uint256 clientAmount
    );

    event TranferSenderFromCancelStream(
        uint256 indexed streamId, 
        address indexed sender, 
        uint256 senderBalance

    );
    
    event newFee(
        uint256 newFee
    );
    
    event newCompanyAccount(
        address companyAccount
    );
    
    event remFromContract(
        uint256 amount,
        address indexed reciver
    );
    
    
    function createStream(address recipient, uint256 deposit, address tokenAddress, uint256 startTime, uint256 stopTime, uint256 blockTime, bool senderCancel, bool recipientCancel) whenNotPaused external  returns (uint256){
        
        if (startTime == 0){
            startTime = block.timestamp;
        }
        
        require(recipient != address(0x00), "stream to the zero address");
        require(recipient != address(this), "stream to the contract itself");
        require(recipient != msg.sender, "stream to the caller");
        require(deposit > 0, "deposit is zero");
        require(startTime >= block.timestamp, "start time before block.timestamp");
        require(stopTime > startTime, "stop time before the start time");
        require (accept[tokenAddress], "token not accepted ");

        CreateStreamLocalVars memory vars;
        vars.duration = stopTime - startTime;
        

        /* Without this, the rate per second would be zero. */
        require(deposit >= vars.duration, "deposit smaller than time delta");

        /* This condition avoids dealing with remainders */
        //require(deposit % vars.duration == 0, "deposit not multiple of time delta");
        
        
        
        uint256 rem;
        
        if (deposit % vars.duration == 0){
            rem = 0;
        }
        
        else{
            rem = deposit % vars.duration;
            contractBalance = contractBalance + rem;
        }

        vars.ratePerSecond = deposit/ vars.duration;
        uint256 mainDeposit = deposit - rem;
        
        /* Create and store the stream object. */
        uint256 streamId = nextStreamId;
        streams[streamId] = Stream({
            remainingBalance: deposit,
            deposit: deposit,
            isEntity: true,
            ratePerSecond: vars.ratePerSecond,
            recipient: recipient,
            sender: msg.sender,
            startTime: startTime,
            stopTime: stopTime,
            tokenAddress: tokenAddress,
            blockTime: blockTime,
            senderCancel: senderCancel,
            recipientCancel: recipientCancel,
            remainder: rem
        });

        /* Increment the next stream id. */
        nextStreamId = nextStreamId + uint256(1);
        
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), rem), "token transfer failure");
        require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), mainDeposit), "token transfer failure");
        
        emit CreateStream(streamId, msg.sender, recipient, deposit, tokenAddress, startTime, stopTime, blockTime, senderCancel, recipientCancel);
        return streamId;
    }
    
   
   
  
    
    function getStream(uint256 streamId) external view streamExists(streamId) returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            uint256 senderRemainder,
            uint256 blockTime,
            bool senderCancel,
            bool recipientCancel
            
        )
    {
        sender = streams[streamId].sender;
        recipient = streams[streamId].recipient;
        deposit = streams[streamId].deposit;
        tokenAddress = streams[streamId].tokenAddress;
        startTime = streams[streamId].startTime;
        stopTime = streams[streamId].stopTime;
        remainingBalance = streams[streamId].remainingBalance;
        ratePerSecond = streams[streamId].ratePerSecond;
        senderRemainder = streams[streamId].remainder;
        blockTime = streams[streamId].blockTime;
        senderCancel = streams[streamId].senderCancel;
        recipientCancel = streams[streamId].recipientCancel;
    }
    
    
    function cancelStream(uint256 streamId)
        external
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        
        cancelStreamInternal(streamId);
        
        return true;
    }
    
    
    function cancelStreamInternal(uint256 streamId) internal {
        Stream memory stream = streams[streamId];
        uint256 period = stream.startTime + stream.blockTime;
        require (stream.blockTime == 0 || period >= block.timestamp);
        
        if (msg.sender == stream.sender && !stream.senderCancel){
            return;
        }
        if (msg.sender == stream.recipient && !stream.recipientCancel){
            return;
        }
        
        
        uint256 senderBalance = balanceOf(streamId, stream.sender);
        uint256 recipientBalance = balanceOf(streamId, stream.recipient);
        uint256 companyAmount  = recipientBalance * fee / 10000;
        uint256 clientAmount  = recipientBalance - companyAmount;

       // delete streams[streamId];

        IERC20 token = IERC20(stream.tokenAddress);
            if (recipientBalance > 0){
            
            
            // distribution to the shareholders
            uint256 fee60 = companyAmount * 60 / 100;
            uint256 fee25 = companyAmount * 25 / 100;
            uint256 fee15 = companyAmount * 15 / 100;
        
            require(IERC20(stream.tokenAddress).transfer(stream.recipient, clientAmount), "token transfer failure");
            require(IERC20(stream.tokenAddress).transfer(one, fee60), "fee60 transfer failure");
            require(IERC20(stream.tokenAddress).transfer(two, fee25), "fee25 transfer failure");
            require(IERC20(stream.tokenAddress).transfer(three, fee15), "fee15 transfer failure");

            emit TranferRecipientFromCancelStream(streamId, stream.recipient, clientAmount);

            emit TranferRecipientFromCancelStream(streamId, one, fee60);
            emit TranferRecipientFromCancelStream(streamId, two, fee25);
            emit TranferRecipientFromCancelStream(streamId, three, fee15);


            }
            if (senderBalance > 0){
                require(token.transfer(stream.sender, senderBalance), "sender token transfer failure");
                emit TranferSenderFromCancelStream(streamId, stream.sender, senderBalance);
            }
            uint256 cancelTime = block.timestamp;

        emit CancelStream(streamId, stream.sender, stream.recipient, senderBalance, recipientBalance, cancelTime);
    }
    
    function balanceOf(uint256 streamId, address who) public view streamExists(streamId) returns (uint256 balance) {
        Stream memory stream = streams[streamId];
        BalanceOfLocalVars memory vars;

        uint256 delta = deltaOf(streamId);
        vars.recipientBalance = delta * stream.ratePerSecond;
       

        /*
         * If the stream `balance` does not equal `deposit`, it means there have been withdrawals.
         * We have to subtract the total amount withdrawn from the amount of money that has been
         * streamed until now.
         */
        if (stream.deposit > stream.remainingBalance) {
            vars.withdrawalAmount = stream.deposit - stream.remainingBalance;
            
            vars.recipientBalance = vars.recipientBalance - vars.withdrawalAmount;
            
        }

        if (who == stream.recipient) return vars.recipientBalance;
        if (who == stream.sender) {
            vars.senderBalance = stream.remainingBalance - vars.recipientBalance;
            
            return vars.senderBalance;
        }
        return 0;
    }
    
    function deltaOf(uint256 streamId) internal view streamExists(streamId) returns (uint256 delta) {
        Stream memory stream = streams[streamId];
        
        if (block.timestamp <= stream.startTime) return 0;
        
        if (block.timestamp < stream.stopTime) return block.timestamp - stream.startTime;
        
        return stream.stopTime - stream.startTime;
    }
    
    
    
    
    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        //whenNotPaused
        streamExists(streamId)
        onlySenderOrRecipient(streamId)
        returns (bool)
    {
        require(amount > 0, "amount is zero");
        Stream memory stream = streams[streamId];
        uint256 balance = balanceOf(streamId, stream.recipient);
        
        require(balance >= amount, "amount exceeds the available balance");

        withdrawFromStreamInternal(streamId, amount);
        
        return true;
    }
    
    function withdrawFromStreamInternal(uint256 streamId, uint256 amount) internal {
        Stream memory stream = streams[streamId];
        
        streams[streamId].remainingBalance = stream.remainingBalance - amount;
        

        if (streams[streamId].remainingBalance == 0) delete streams[streamId];
        
        uint256 companyAmount  = amount * fee / 10000;
        
        uint256 clientAmount  = amount - companyAmount;
        
        // distribution to the shareholders
        uint256 fee60 = companyAmount * 60 /100;
        uint256 fee25 = companyAmount * 25 /100;
        uint256 fee15 = companyAmount * 15 /100;
    
        require(IERC20(stream.tokenAddress).transfer(stream.recipient, clientAmount), "token transfer failure");
        require(IERC20(stream.tokenAddress).transfer(one, fee60), "fee60 transfer failure");
        require(IERC20(stream.tokenAddress).transfer(two, fee25), "fee25 transfer failure");
        require(IERC20(stream.tokenAddress).transfer(three, fee15), "fee15 transfer failure");
        
        
        
        emit WithdrawFromStream(streamId, stream.recipient, clientAmount);
        emit FeeFromStream60(streamId, one, fee60);
        emit FeeFromStream25(streamId, two, fee25);
        emit FeeFromStream15(streamId, three, fee15);
        
    }
    
     // Admin functions
   
   
    // work with sender remainders
    function getBalanceOfThisContract() external view returns (uint){
        return contractBalance;
    }
    
    function withdrawRem(address _tokenAddress, uint256 _amount, address _reciver) external onlyOwner returns (bool){
        require (_amount <= contractBalance);
        require(_tokenAddress != address(0) && _reciver != address(0));
        contractBalance = contractBalance - _amount;
        require(IERC20(_tokenAddress).transfer(_reciver, _amount), "token transfer failure");
        emit remFromContract(_amount, _reciver);
        return true;
    }
    
    mapping(address => bool) public accept;
    
    function addNewToken(address _token) external onlyOwner{
        accept[_token] = true;
    }
    
    function removeToken(address _token) external onlyOwner{
        accept[_token] = false;
    }
    
    
    // TO DO  add onlyOwner
    function changeFee(uint _fee) external agreement returns(bool){
        vote[one] = false;
        vote[two] = false;
        vote[three] = false;
        fee = _fee;
        emit newFee(fee);
        return true;
        
    }
    
    
    
    
}