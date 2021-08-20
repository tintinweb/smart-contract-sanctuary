/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-25
*/

pragma solidity 0.6.6;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// File: contracts/common/EIP712Base.sol

abstract contract ERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external virtual view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external virtual view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external virtual returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external virtual view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external virtual returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// File: contracts/common/NativeMetaTransaction.sol

contract NativeMetaTransaction is EIP712Base {
        using SafeMath for uint256;

    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// File: contracts/common/ContextMixin.sol


abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
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

contract Betting is NativeMetaTransaction, ContextMixin {

    using SafeMath for uint;
    
    ERC20 public SportChain;
    // struct
    struct UserStruct{
        uint totalbetting;
        uint totalEarnings;
        uint[] gamesID;
    }
    
    struct UserGameStruct{
        address userAddress;
        uint opponentId;
        uint betPair;
        uint betAmount;
        uint betTime;
        bool isWithdrawn;
    }
    
    struct GameStruct{
        uint gameID;
        uint8 gameType;
        uint currUserGameID;
        uint totalBetPairWin;
        uint totalBetPairLoss;
        uint totalBetPairDraw;
        uint winningPair;
        uint startTime;
        uint endTime;
        bool isGameCompleted;
        mapping(uint => uint) pairEarned;
        mapping(uint => UserGameStruct) users;
    }
    
    // global variables
    address public owner;
    uint public currGameID;
    uint public lockStatus=1;
    
    mapping(uint => GameStruct) public games;
    mapping(address => UserStruct) public user;
    mapping(uint => mapping(address => uint)) public listGameUser;
    
    event AddGameEvent( uint indexed _gameID, uint _startTime, uint _endTime, uint _time);
    event SetGameWinnerEvent( uint indexed _gameID, uint _Winner, uint _time);
    event AddGameUsersEvent( uint indexed _gameID, uint _userID, uint _betPair, uint _betAmount, uint _pairUserID, uint _time);
    event RefundEvent(address indexed _user, uint _amount, uint _time);
    event WithdrawalEvent(address indexed _user, uint _amount, uint _time);
    
    modifier lockCheck(){
        require(lockStatus == 1, "contract is locked");
        _;
    }
    
    modifier OnlyOwner(){
        require(msgSender() == owner);
        _;
    }
    constructor( address _tokenAddress, address _owner) public {
        owner = _owner;
        SportChain = ERC20(_tokenAddress);
        _initializeEIP712("Betting");

    }

    // only owner
    function addGame( uint8 _gameType, uint _gameEndTime, address _betWallet, uint _betPair, uint _betAmount) public OnlyOwner lockCheck returns(bool){
        require((_gameEndTime > block.timestamp), "Game End time must be greater than current time");
        require((_gameType == 1) || (_gameType == 2), "game type must be 1 or 2");
        
        currGameID++;
        
        games[currGameID].gameID = currGameID;
        games[currGameID].gameType = _gameType;
        games[currGameID].startTime = block.timestamp;
        games[currGameID].endTime = _gameEndTime;
        games[currGameID].currUserGameID = 0;
        games[currGameID].isGameCompleted = false;
        
        if(_gameType == 1){ _betting(_betWallet, currGameID, _betPair, _betAmount, 0); }
        
        emit AddGameEvent(currGameID, block.timestamp, _gameEndTime, block.timestamp);
        
        return true;
    }
    
    function setGameWin( uint _gameID, uint _wining) public OnlyOwner lockCheck returns(bool){
        require((_gameID > 0) && (_gameID <= currGameID), "Invalid Game ID");
        require((_wining == 1) || (_wining == 2) || (_wining == 3), "_Wining pair should be 1 or 2"); // 1 - win, 2 - draw, 3 - loss
        require(!games[_gameID].isGameCompleted, "game closed");
        require(games[_gameID].endTime < now, "games exists");
        
        games[_gameID].winningPair = _wining;
        games[_gameID].isGameCompleted = true;
        
        if(games[_gameID].currUserGameID == 1){
            address _user = games[_gameID].users[1].userAddress;
            require(SportChain.transfer(_user, games[_gameID].users[1].betAmount), "refund transfer failed");
            user[_user].totalEarnings = user[_user].totalEarnings.add(games[_gameID].users[1].betAmount);
            games[_gameID].users[listGameUser[_gameID][_user]].isWithdrawn = true;
            emit RefundEvent(_user, games[_gameID].users[1].betAmount, now);
        }
        
        emit SetGameWinnerEvent( _gameID, _wining, now);
        
        return  true;
    }
    
    function betting( uint _gameID, uint _betPair, uint _betAmount, uint _pairID) public lockCheck returns(bool){
        require(isContract(msgSender()) == 0, "invalid user address");
        require(games[_gameID].startTime <= now, "games betting is not started");
        require(games[_gameID].endTime >= now, "games betting ends");
        
        _betting(msgSender(), _gameID, _betPair, _betAmount, _pairID);
    }
    
    function _betting( address _betWallet, uint _gameID, uint _betPair, uint _betAmount, uint _pairID) private returns(bool){
        
        require((_gameID > 0) && (_gameID <= currGameID), "Invalid Game ID");
        require(listGameUser[_gameID][_betWallet] == 0, "user exist");
        require((_betPair == 1) || (_betPair == 2) || (_betPair == 3), "_betPair should be 1, 2 or 3");
        require( _betAmount > 0, "_betAmount must be greater than zero");
        require(SportChain.balanceOf(_betWallet) >= _betAmount, "insufficient balance");
        require(SportChain.allowance(_betWallet, address(this)) >= _betAmount, "insufficient allowance");
        require((_pairID >= 0) && (_pairID <=games[_gameID].currUserGameID), "_pairType must be 1 or 2");
        
        if(games[currGameID].gameType == 2) { require(_pairID == 0, "pair id must be zero if users bets on pool betting"); }
        else{ require(games[_gameID].users[_pairID].opponentId == 0,"opponent already has a pair"); require(games[_gameID].users[_pairID].betPair != _betPair, "bet pair cannot choosen the same betting pair");}
        
        require(SportChain.transferFrom(_betWallet, address(this), _betAmount), "winning reward transfer failed");
        
        games[_gameID].currUserGameID++;
        games[_gameID].users[games[_gameID].currUserGameID].userAddress = _betWallet;
        games[_gameID].users[games[_gameID].currUserGameID].opponentId = _pairID;
        games[_gameID].users[games[_gameID].currUserGameID].betPair = _betPair;
        games[_gameID].users[games[_gameID].currUserGameID].betAmount = _betAmount;
        games[_gameID].users[games[_gameID].currUserGameID].betTime = now;
        
        listGameUser[_gameID][_betWallet] = games[_gameID].currUserGameID;
        
        user[_betWallet].totalbetting = user[_betWallet].totalbetting.add(_betAmount);
        user[_betWallet].gamesID.push(games[_gameID].currUserGameID);
        
        if(_betPair == 1)
            games[_gameID].totalBetPairWin = games[_gameID].totalBetPairWin.add(_betAmount);
        else if(_betPair == 2)
            games[_gameID].totalBetPairDraw = games[_gameID].totalBetPairDraw.add(_betAmount);
        else
            games[_gameID].totalBetPairLoss = games[_gameID].totalBetPairLoss.add(_betAmount);
        
        if(_pairID > 0)
            games[_gameID].users[_pairID].opponentId = games[_gameID].currUserGameID;
        
        emit AddGameUsersEvent( _gameID, games[_gameID].currUserGameID, _betPair, _betAmount, _pairID, now);    
        
        return true;
    }

    function WithdrawGameReward( uint _gameID) public lockCheck returns(bool){
        require(isContract(msgSender()) == 0, "invalid user address");
        require((_gameID > 0) && (_gameID <= currGameID), "Invalid Game ID");
        require(games[_gameID].currUserGameID > 1,"total user limit did not reach");
        require(games[_gameID].endTime < now, "games exists");
        require(games[_gameID].isGameCompleted, "Winner is not decided");
        require(listGameUser[_gameID][msgSender()] > 0, " user not participated in this game");
        require(games[_gameID].winningPair == games[_gameID].users[listGameUser[_gameID][msgSender()]].betPair, "user is not a winner in this game");
        require(!games[_gameID].users[listGameUser[_gameID][msgSender()]].isWithdrawn, "user already withdrawn his winning amount");
        
        uint totalBetInGame = games[_gameID].totalBetPairWin.add((games[_gameID].totalBetPairDraw.add(games[_gameID].totalBetPairLoss)));
        
        uint winingBet;
        
        if(games[_gameID].winningPair == 1)
            winingBet = games[_gameID].totalBetPairWin;
        else if(games[_gameID].winningPair == 2)
            winingBet = games[_gameID].totalBetPairDraw;
        else
            winingBet = games[_gameID].totalBetPairLoss;
            
        uint totalBetRatio = (totalBetInGame.mul(1 ether)).div(winingBet);
        
        uint userBetAmount = games[_gameID].users[listGameUser[_gameID][msgSender()]].betAmount;
        
        winingBet = (userBetAmount.mul(totalBetRatio)).div(1 ether);
        
        require(SportChain.transfer(msgSender(), winingBet), "winning reward transfer failed");
        user[msgSender()].totalEarnings = user[msgSender()].totalEarnings.add(winingBet);
        
        games[_gameID].users[listGameUser[_gameID][msgSender()]].isWithdrawn = true;
        emit WithdrawalEvent( msgSender(), winingBet, now);
    }
    
    /**
     * @dev Contract balance withdraw
     * @param _toUser  receiver addrress
     * @param _amount  withdraw amount
     */ 
    function failSafe(address payable _toUser, uint _amount) public OnlyOwner returns (bool) {
        require(_toUser != address(0), "Invalid Address");
        require(SportChain.balanceOf(address(this)) >= _amount, "insufficient balance");

        SportChain.transfer(_toUser, _amount);
        return true;
    }
    
    /**
     * @dev To lock/unlock the contract
     * @param _lockStatus  status in bool
     */
    function contractLock(uint _lockStatus) public OnlyOwner returns (bool) {
        require(_lockStatus == 1 || _lockStatus == 2, "invalid lock status");
        
        lockStatus = _lockStatus;
        return true;
    }
    
    function viewUserGameDetails(uint _gameID, uint _userID) public view returns(address userAddress, uint opponentId, uint betPair, uint betAmount,uint betTime){
        return(games[_gameID].users[_userID].userAddress,games[_gameID].users[_userID].opponentId,games[_gameID].users[_userID].betPair,games[_gameID].users[_userID].betAmount,games[_gameID].users[_userID].betTime);
    }
    
    function isContract( address _userAddress) internal view returns(uint32){
        uint32 size;
        
        assembly {
            size := extcodesize(_userAddress)
        }
        
        return size;
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead This
    function _msgSender()
        internal
        view
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }
}