pragma solidity ^0.4.21;

contract SafeMath {
    
    uint256 constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
    }
}
contract Owned {
    address public owner;
    address public newOwner;

    function Owned() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}
contract IERC20Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}   

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract CreditGAMEInterface {
    function isGameApproved(address _gameAddress) view public returns(bool);
    function createLock(address _winner, uint _totalParticipationAmount, uint _tokenLockDuration) public;
    function removeFailedGame() public;
    function removeLock() public;
    function cleanUp() public;
    function checkIfLockCanBeRemoved(address _gameAddress) public view returns(bool);
}


contract LuckyTree is Owned, SafeMath{
    
    uint public leafPrice;
    uint public gameStart;
    uint public gameDuration;
    uint public tokenLockDuration;
    uint public totalParticipationAmount;
    uint public totalLockedAmount;
    uint public numberOfLeafs;
    uint public participantIndex;
    bool public fundsTransfered;
    address public winner;
    mapping(uint => address) public participants;
    mapping(uint => uint) public participationAmount;
    mapping(address => bool) public hasParticipated;
    mapping(address => bool) public hasWithdrawn;
    mapping(address => uint) public participantIndexes;
    mapping(uint => address) public leafOwners;
    
    event GameWinner(address winner);
    event GameEnded(uint block);
    event GameStarted(uint block);
    event GameFailed(uint block);
    event GameLocked(uint block);
    event GameUnlocked(uint block);
    
    enum state{
        pending,
        running,
        paused,
        finished,
        closed,
        claimed
    }
    
    state public gameState;
    
    //SET BEFORE DEPLOY
    address public tokenAddress = 0xfc6b46d20584a7f736c0d9084ab8b1a8e8c01a38;
    address public creditGameAddress = 0x7f135d5d5c1d2d44cf6abb7d09735466ba474799;

    /**
     *leafPrice = price in crb for one leafPrice
     * _gamestart = block.number when the game _gamestart
     * _gameduration = block.number when game ends
     * _tokenLockDuration = number of block for when the tokens are locked
     */
    function LuckyTree(
        uint _leafPrice,
        uint _gameStart,
        uint _gameDuration,
        uint _tokenLockDuration) public{
        
        leafPrice = _leafPrice;
        gameStart = _gameStart;
        gameDuration = _gameDuration;
        tokenLockDuration = _tokenLockDuration;
        
        gameState = state.pending;
        totalParticipationAmount = 0;
        numberOfLeafs = 0;
        participantIndex = 0;
        fundsTransfered = false;
        winner = 0x0;
    }
    
    /**
     * Generate random winner.
     * 
     **/
    function random() internal view returns(uint){
        return uint(keccak256(block.number, block.difficulty, numberOfLeafs));
    }
    
    /**
     * Set token address.
     * 
     **/
    function setTokenAddress(address _tokenAddress) public onlyOwner{
        tokenAddress = _tokenAddress;
    }
    
    /**
     * Set game address.
     * 
     **/
    function setCreditGameAddress(address _creditGameAddress) public onlyOwner{
        creditGameAddress = _creditGameAddress;
    }
    
    /**
     * Method called when game ends. 
     * Check that more than 1 wallet contributed
     **/
    function pickWinner() internal{
        if(numberOfLeafs > 0){
            if(participantIndex == 1){
                //a single account contributed - just transfer funds back
                IERC20Token(tokenAddress).transfer(leafOwners[0], totalParticipationAmount);
                hasWithdrawn[leafOwners[0]] = true;
                CreditGAMEInterface(creditGameAddress).removeFailedGame();
                emit GameFailed(block.number);
            }else{
                uint leafOwnerIndex = random() % numberOfLeafs;
                winner = leafOwners[leafOwnerIndex];
                emit GameWinner(winner);
                lockFunds(winner);
                
            }
        }
        gameState = state.closed;
    }
    
    /**
     * Method called when winner is picked
     * Funds are transferred to game contract and lock is created by calling game contract
     **/
    function lockFunds(address _winner) internal{
        require(totalParticipationAmount != 0);
        //transfer and lock tokens on game contract
        IERC20Token(tokenAddress).transfer(creditGameAddress, totalParticipationAmount);
        CreditGAMEInterface(creditGameAddress).createLock(_winner, totalParticipationAmount, tokenLockDuration);
        totalLockedAmount = totalParticipationAmount;
        emit GameLocked(block.number);
    }
    
    /**
     * Method for manually Locking fiunds
     **/
    function manualLockFunds() public onlyOwner{
        require(totalParticipationAmount != 0);
        require(CreditGAMEInterface(creditGameAddress).isGameApproved(address(this)) == true);
        require(gameState == state.closed);
        //pick winner
        pickWinner();
    }
    
    /**
     * To manually allow game locking
     */
    function closeGame() public onlyOwner{
        gameState = state.closed;
    }
    
    /**
     * Method called by participants to unlock and transfer their funds 
     * First call to method transfers tokens from game contract to this contractđ
     * Last call to method cleans up the game contract
     **/
    function unlockFunds() public {
        require(gameState == state.closed);
        require(hasParticipated[msg.sender] == true);
        require(hasWithdrawn[msg.sender] == false);
        
        if(fundsTransfered == false){
            require(CreditGAMEInterface(creditGameAddress).checkIfLockCanBeRemoved(address(this)) == true);
            CreditGAMEInterface(creditGameAddress).removeLock();
            fundsTransfered = true;
            emit GameUnlocked(block.number);
        }
        
        hasWithdrawn[msg.sender] = true;
        uint index = participantIndexes[msg.sender];
        uint amount = participationAmount[index];
        IERC20Token(tokenAddress).transfer(msg.sender, amount);
        totalLockedAmount = IERC20Token(tokenAddress).balanceOf(address(this));
        if(totalLockedAmount == 0){
            gameState = state.claimed;
            CreditGAMEInterface(creditGameAddress).cleanUp();
        }
    }
    
    /**
     * Check internall balance of this.
     * 
     **/
    function checkInternalBalance() public view returns(uint256 tokenBalance) {
        return IERC20Token(tokenAddress).balanceOf(address(this));
    }
    
    /**
     * Implemented token interface to transfer tokens to this.
     * 
     **/
    function receiveApproval(address _from, uint256 _value, address _to, bytes _extraData) public {
        require(_to == tokenAddress);
        require(_value == leafPrice);
        require(gameState != state.closed);
        //check if game approved;
        require(CreditGAMEInterface(creditGameAddress).isGameApproved(address(this)) == true);

        uint tokensToTake = processTransaction(_from, _value);
        IERC20Token(tokenAddress).transferFrom(_from, address(this), tokensToTake);
    }

    /**
     * Calibrate game state and take tokens.
     * 
     **/
    function processTransaction(address _from, uint _value) internal returns (uint) {
        require(gameStart <= block.number);
        
        uint valueToProcess = 0;
        
        if(gameStart <= block.number && gameDuration >= block.number){
            if(gameState != state.running){
                gameState = state.running;
                emit GameStarted(block.number);
            }
            // take tokens
            leafOwners[numberOfLeafs] = _from;
            numberOfLeafs++;
            totalParticipationAmount += _value;
            
            //check if contributed before
            if(hasParticipated[_from] == false){
                hasParticipated[_from] = true;
                
                participants[participantIndex] = _from;
                participationAmount[participantIndex] = _value;
                participantIndexes[_from] = participantIndex;
                participantIndex++;
            }else{
                uint index = participantIndexes[_from];
                participationAmount[index] = participationAmount[index] + _value;
            }
            
            valueToProcess = _value;
            return valueToProcess;
        //If block.number over game duration, pick winner
        }else if(gameDuration < block.number){
            gameState = state.finished;
            pickWinner();
            return valueToProcess;
        }
    }

    /**
     * Return all variables needed for dapp in a single call
     * 
     **/
    function getVariablesForDapp() public view returns(uint, uint, uint, uint, uint, uint, state){
      return(leafPrice, gameStart, gameDuration, tokenLockDuration, totalParticipationAmount, numberOfLeafs, gameState);
    }

    /**
     * Manually send tokens to this.
     * 
     **/
    function manuallyProcessTransaction(address _from, uint _value) onlyOwner public {
        require(_value == leafPrice);
        require(IERC20Token(tokenAddress).balanceOf(address(this)) >= _value + totalParticipationAmount);

        if(gameState == state.running && block.number < gameDuration){
            uint tokensToTake = processTransaction(_from, _value);
            IERC20Token(tokenAddress).transferFrom(_from, address(this), tokensToTake);
        }

    }

    /**
     * Salvage tokens from this.
     * 
     **/
    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner public {
        require(_tokenAddress != tokenAddress);
        IERC20Token(_tokenAddress).transfer(_to, _amount);
    }

    /**
     * Kill contract if needed
     * 
     **/
    function killContract() onlyOwner public {
      selfdestruct(owner);
    }
}