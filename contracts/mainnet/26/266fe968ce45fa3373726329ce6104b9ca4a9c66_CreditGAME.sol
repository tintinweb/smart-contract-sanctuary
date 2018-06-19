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


contract LinkedList {

    struct Element {
        uint previous;
        uint next;

        address data;
    }

    uint public size;
    uint public tail;
    uint public head;
    mapping(uint => Element) elements;
    mapping(address => uint) elementLocation;

    function addItem(address _newItem) public returns (bool) {
        Element memory elem = Element(0, 0, _newItem);

        if (size == 0) {
            head = 1;
        } else {
            elements[tail].next = tail + 1;
            elem.previous = tail;
        }

        elementLocation[_newItem] = tail + 1;
        elements[tail + 1] = elem;
        size++;
        tail++;
        return true;
    }

    function removeItem(address _item) public returns (bool) {
        uint key;
        if (elementLocation[_item] == 0) {
            return false;
        }else {
            key = elementLocation[_item];
        }

        if (size == 1) {
            tail = 0;
            head = 0;
        }else if (key == head) {
            head = elements[head].next;
        }else if (key == tail) {
            tail = elements[tail].previous;
            elements[tail].next = 0;
        }else {
            elements[key - 1].next = elements[key].next;
            elements[key + 1].previous = elements[key].previous;
        }

        size--;
        delete elements[key];
        elementLocation[_item] = 0;
        return true;
    }

    function getAllElements() constant public returns(address[]) {
        address[] memory tempElementArray = new address[](size);
        uint cnt = 0;
        uint currentElemId = head;
        while (cnt < size) {
            tempElementArray[cnt] = elements[currentElemId].data;
            currentElemId = elements[currentElemId].next;
            cnt += 1;
        }
        return tempElementArray;
    }

    function getElementAt(uint _index) constant public returns (address) {
        return elements[_index].data;
    }

    function getElementLocation(address _element) constant public returns (uint) {
        return elementLocation[_element];
    }

    function getNextElement(uint _currElementId) constant public returns (uint) {
        return elements[_currElementId].next;
    }
}

contract ICreditBIT{
    function claimGameReward(address _champion, uint _lockedTokenAmount, uint _lockTime) returns (uint error);
}

contract CreditGAME is Owned, SafeMath, LinkedList{
    
    mapping(address => bool) approvedGames;
    mapping(address => GameLock) gameLocks;
    mapping(address => bool) public isGameLocked;
    mapping(uint => address) public concludedGames;
    
    uint public amountLocked = 0;
    uint public concludedGameIndex = 0;
    
    struct GameLock{
        uint amount;
        uint lockDuration;
    }
    
    event LockParameters(address gameAddress, uint totalParticipationAmount, uint tokenLockDuration);
    event UnlockParameters(address gameAddress, uint totalParticipationAmount);
    event GameConcluded(address gameAddress);

    //SET TOKEN ADDRESS BEFORE DEPLOY
    address public tokenAddress = 0xAef38fBFBF932D1AeF3B808Bc8fBd8Cd8E1f8BC5;
    
    /**
     * Set CRB token address here
     * 
     **/
    function setTokenAddress(address _tokenAddress) onlyOwner public {
        tokenAddress = _tokenAddress;
    }

    /**
     * When new game is created it needs to be approved here before it starts.
     * 
     **/
    function addApprovedGame(address _gameAddress) onlyOwner public{
        approvedGames[_gameAddress] = true;
        addItem(_gameAddress);
    }
    
    /**
     * Manually remove approved game.
     * 
     **/
    function removeApprovedGame(address _gameAddress) onlyOwner public{
        approvedGames[_gameAddress] = false;
        removeItem(_gameAddress);
    }

    /**
     * Remove failed game.
     * 
     **/
    function removeFailedGame() public{
      require(approvedGames[msg.sender] == true);
      removeItem(msg.sender);
      approvedGames[msg.sender] = false;
      concludedGames[concludedGameIndex] = msg.sender; 
      concludedGameIndex++;
      emit GameConcluded(msg.sender);
    }
    
    /**
     * Verify if game is approved
     * 
     **/
    function isGameApproved(address _gameAddress) view public returns(bool){
        if(approvedGames[_gameAddress] == true){
            return true;
        }else{
            return false;
        }
    }
    
    /**
     * Funds must be transfered by calling contract before calling this contract. 
     * msg.sender is address of calling contract that must be approved.
     * 
     **/
    function createLock(address _winner, uint _totalParticipationAmount, uint _tokenLockDuration) public {
        require(approvedGames[msg.sender] == true);
        require(isGameLocked[msg.sender] == false);
        
        //Create gameLock
        GameLock memory gameLock = GameLock(_totalParticipationAmount, block.number + _tokenLockDuration);
        gameLocks[msg.sender] = gameLock;
        isGameLocked[msg.sender] = true;
        amountLocked = safeAdd(amountLocked, _totalParticipationAmount);
        
        //Transfer game credits to winner
        generateChampionTokens(_winner, _totalParticipationAmount, _tokenLockDuration);
        emit LockParameters(msg.sender, _totalParticipationAmount, block.number + _tokenLockDuration);
    }
    
    /**
     * Call CRB token to mint champion tokens
     * 
     **/
    function generateChampionTokens(address _winner, uint _totalParticipationAmount, uint _tokenLockDuration) internal{
        ICreditBIT(tokenAddress).claimGameReward(_winner, _totalParticipationAmount, _tokenLockDuration);
    }
    
    /**
     * Check the CRB balance of this.
     * 
     **/
    function checkInternalBalance() public view returns(uint256 tokenBalance) {
        return IERC20Token(tokenAddress).balanceOf(address(this));
    }
    
    /**
     * Method called by game contract
     * msg.sender is address of calling contract that must be approved.
     **/
    function removeLock() public{
        require(approvedGames[msg.sender] == true);
        require(isGameLocked[msg.sender] == true);
        require(checkIfLockCanBeRemoved(msg.sender) == true);
        GameLock memory gameLock = gameLocks[msg.sender];
        
        //transfer tokens to game contract
        IERC20Token(tokenAddress).transfer(msg.sender, gameLock.amount);
        
        delete(gameLocks[msg.sender]);
        
        //clean up
        amountLocked = safeSub(amountLocked, gameLock.amount);
        
        isGameLocked[msg.sender] = false;
        emit UnlockParameters(msg.sender, gameLock.amount);
    }
    
    /**
     * Method called by game contract when last participant has withdrawn
     * msg.sender is address of calling contract that must be approved.
     **/
    function cleanUp() public{
        require(approvedGames[msg.sender] == true);
        require(isGameLocked[msg.sender] == false);
        removeItem(msg.sender);
        
        approvedGames[msg.sender] = false;
        concludedGames[concludedGameIndex] = msg.sender; 
        concludedGameIndex++;
        emit GameConcluded(msg.sender);
    }

    /**
     * Failsafe if game needs to be removed. Tokens are transfered to _tokenHolder address
     * 
     **/
    function removeGameManually(address _gameAddress, address _tokenHolder) onlyOwner public{
      GameLock memory gameLock = gameLocks[_gameAddress];
      //transfer tokens to game contract
      IERC20Token(tokenAddress).transfer(_tokenHolder, gameLock.amount);
      //clean up
      amountLocked = safeSub(amountLocked, gameLock.amount);
      delete(gameLocks[_gameAddress]);
      isGameLocked[_gameAddress] = false;
      removeItem(_gameAddress);
      approvedGames[_gameAddress] = false;
    }
    
    /**
     * Get gamelock parameters: CRB amount locked, CRB lock duration
     * 
     **/
    function getGameLock(address _gameAddress) public view returns(uint, uint){
        require(isGameLocked[_gameAddress] == true);
        GameLock memory gameLock = gameLocks[_gameAddress];
        return(gameLock.amount, gameLock.lockDuration);
    }

    /**
     * Verify if game is locked
     * 
     **/
    function isGameLocked(address _gameAddress) public view returns(bool){
      if(isGameLocked[_gameAddress] == true){
        return true;
      }else{
        return false;
      }
    }
    
    /**
     * Check if game lock can be removed
     * 
     **/
    function checkIfLockCanBeRemoved(address _gameAddress) public view returns(bool){
        require(approvedGames[_gameAddress] == true);
        require(isGameLocked[_gameAddress] == true);
        GameLock memory gameLock = gameLocks[_gameAddress];
        if(gameLock.lockDuration < block.number){
            return true;
        }else{
            return false;
        }
    }

    /**
     * Kill contract if needed
     * 
     **/
    function killContract() onlyOwner public {
      selfdestruct(owner);
    }
}