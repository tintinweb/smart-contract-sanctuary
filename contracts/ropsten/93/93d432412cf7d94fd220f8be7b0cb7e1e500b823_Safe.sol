pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// token contract interface
interface Token{
    function balanceOf(address user) external returns(uint256);
    function transfer(address to, uint256 amount) external returns(bool);
}

contract Safe{
    using SafeMath for uint256;
    
    // counter for signing transactions
    uint8 public count;
    
    uint256 internal end;
    uint256 internal timeOutAuthentication;
    
    // arrays of safe keys
    mapping (address => bool) internal safeKeys;
    address [] internal massSafeKeys = new address[](4);
    
    // array of keys that signed the transaction
    mapping (address => bool) internal signKeys;
    
    // free amount in safe
    uint256 internal freeAmount; 
    // event transferring money to safe
    bool internal tranche;
    
    // fixing lockup in safe
    bool internal lockupIsSet;
    
    // lockup of safe
    uint256 internal mainLockup; 
    
    address internal lastSafeKey;
    
    Token public token;
    
    // Amount of cells
    uint256 public countOfCell;
    
    // cell structure
    struct _Cell{
        uint256 lockup;
        uint256 balance;
        bool exist;
        uint256 timeOfDeposit;
    }
    
    // cell addresses
    mapping (address => _Cell) internal userCells;
    
    event CreateCell(address indexed key);
    event Deposit(address indexed key, uint256 balance);
    event Delete(address indexed key);
    event Edit(address indexed key, uint256 lockup);
    event Withdraw(address indexed who, uint256 balance);
    event InternalTransfer(address indexed from, address indexed to, uint256 balance);

    modifier firstLevel() {
        require(msg.sender == lastSafeKey);
        require(count>=1);
        require(now < end);
        _;
    }
    
    modifier secondLevel() {
        require(msg.sender == lastSafeKey);
        require(count>=2);
        require(now < end);
        _;
    }
    
    modifier thirdLevel() {
        require(msg.sender == lastSafeKey);
        require(count>=3);
        require(now < end);
        _;
    }
    
    constructor (address _first, address _second, address _third, address _fourth) public {
        require(
            _first != _second && 
            _first != _third && 
            _first != _fourth && 
            _second != _third &&
            _second != _fourth &&
            _third != _fourth &&
            _first != 0x0 &&
            _second != 0x0 &&
            _third != 0x0 &&
            _fourth != 0x0
        );
        safeKeys[_first] = true;
        safeKeys[_second] = true;
        safeKeys[_third] = true;
        safeKeys[_fourth] = true;
        massSafeKeys[0] = _first;
        massSafeKeys[1] = _second;
        massSafeKeys[2] = _third;
        massSafeKeys[3] = _fourth;
        timeOutAuthentication = 1 hours;
    }
    
    function AuthStart() public returns(bool){
        require(safeKeys[msg.sender]);
        require(timeOutAuthentication >=0);
        require(!signKeys[msg.sender]);
        signKeys[msg.sender] = true;
        count++;
        end = now.add(timeOutAuthentication);
        lastSafeKey = msg.sender;
        return true;
    }
    
    // completion of operation with safe-keys
    function AuthEnd() public returns(bool){
        require (safeKeys[msg.sender]);
        for(uint i=0; i<4; i++){
          signKeys[massSafeKeys[i]] = false;
        }
        count = 0;
        end = 0;
        lastSafeKey = 0x0;
        return true;
    }
    
    function getTimeOutAuthentication() firstLevel public view returns(uint256){
        return timeOutAuthentication;
    }
    
    function getFreeAmount() firstLevel public view returns(uint256){
        return freeAmount;
    }
    
    function getLockupCell(address _user) firstLevel public view returns(uint256){
        return userCells[_user].lockup;
    }
    
    function getBalanceCell(address _user) firstLevel public view returns(uint256){
        return userCells[_user].balance;
    }
    
    function getExistCell(address _user) firstLevel public view returns(bool){
        return userCells[_user].exist;
    }
    
    function getSafeKey(uint i) firstLevel view public returns(address){
        return massSafeKeys[i];
    }
    
    // withdrawal tokens from safe for issuer
    function AssetWithdraw(address _to, uint256 _balance) secondLevel public returns(bool){
        require(_balance<=freeAmount);
        require(now>=mainLockup);
        freeAmount = freeAmount.sub(_balance);
        token.transfer(_to, _balance);
        emit Withdraw(this, _balance);
        return true;
    }
    
    function setCell(address _cell, uint256 _lockup) secondLevel public returns(bool){
        require(userCells[_cell].lockup==0 && userCells[_cell].balance==0);
        require(!userCells[_cell].exist);
        require(_lockup >= mainLockup);
        userCells[_cell].lockup = _lockup;
        userCells[_cell].exist = true;
        countOfCell = countOfCell.add(1);
        emit CreateCell(_cell);
        return true;
    }

    function deleteCell(address _key) secondLevel public returns(bool){
        require(getBalanceCell(_key)==0);
        require(userCells[_key].exist);
        userCells[_key].lockup = 0;
        userCells[_key].exist = false;
        countOfCell = countOfCell.sub(1);
        emit Delete(_key);
        return true;
    }
    
    // change parameters of the cell
    function editCell(address _key, uint256 _lockup) secondLevel public returns(bool){
        require(getBalanceCell(_key)==0);
        require(_lockup>= mainLockup);
        require(userCells[_key].exist);
        userCells[_key].lockup = _lockup;
        emit Edit(_key, _lockup);
        return true;
    }

    function depositCell(address _key, uint256 _balance) secondLevel public returns(bool){
        require(userCells[_key].exist);
        require(_balance<=freeAmount);
        freeAmount = freeAmount.sub(_balance);
        userCells[_key].balance = userCells[_key].balance.add(_balance);
        userCells[_key].timeOfDeposit = now;
        emit Deposit(_key, _balance);
        return true;
    }
    
    function changeDepositCell(address _key, uint256 _balance) secondLevel public returns(bool){
        require(userCells[_key].timeOfDeposit.add(1 hours)>now);
        userCells[_key].balance = userCells[_key].balance.sub(_balance);
        freeAmount = freeAmount.add(_balance);
        return true;
    }
    
    // installation of a lockup for safe, 
    // fixing free amount on balance, 
    // token installation
    // (run once)
    function setContract(Token _token, uint256 _lockup) thirdLevel public returns(bool){
        require(_token != address(0x0));
        require(!lockupIsSet);
        require(!tranche);
        token = _token;
        freeAmount = getMainBalance();
        mainLockup = _lockup;
        tranche = true;
        lockupIsSet = true;
        return true;
    }
    
    // change of safe-key
    function changeKey(address _oldKey, address _newKey) thirdLevel public returns(bool){
        require(safeKeys[_oldKey]);
        require(_newKey != 0x0);
        for(uint i=0; i<4; i++){
          if(massSafeKeys[i]==_oldKey){
            massSafeKeys[i] = _newKey;
          }
        }
        safeKeys[_oldKey] = false;
        safeKeys[_newKey] = true;
        
        if(_oldKey==lastSafeKey){
            lastSafeKey = _newKey;
        }
        
        return true;
    }

    function setTimeOutAuthentication(uint256 _time) thirdLevel public returns(bool){
        require(
            _time > 0 && 
            timeOutAuthentication != _time &&
            _time <= (5000 * 1 minutes)
        );
        timeOutAuthentication = _time;
        return true;
    }

    function withdrawCell(uint256 _balance) public returns(bool){
        require(userCells[msg.sender].balance >= _balance);
        require(now >= userCells[msg.sender].lockup);
        userCells[msg.sender].balance = userCells[msg.sender].balance.sub(_balance);
        token.transfer(msg.sender, _balance);
        emit Withdraw(msg.sender, _balance);
        return true;
    }
    
    // transferring tokens from one cell to another
    function transferCell(address _to, uint256 _balance) public returns(bool){
        require(userCells[msg.sender].balance >= _balance);
        require(userCells[_to].lockup>=userCells[msg.sender].lockup);
        require(userCells[_to].exist);
        userCells[msg.sender].balance = userCells[msg.sender].balance.sub(_balance);
        userCells[_to].balance = userCells[_to].balance.add(_balance);
        emit InternalTransfer(msg.sender, _to, _balance);
        return true;
    }
    
    // information on balance of cell for holder
    
    function getInfoCellBalance() view public returns(uint256){
        return userCells[msg.sender].balance;
    }
    
    // information on lockup of cell for holder
    
    function getInfoCellLockup() view public returns(uint256){
        return userCells[msg.sender].lockup;
    }
    
    function getMainBalance() public view returns(uint256){
        return token.balanceOf(this);
    }
    
    function getMainLockup() public view returns(uint256){
        return mainLockup;
    }
    
    function isTimeOver() view public returns(bool){
        if(now > end){
            return true;
        } else{
            return false;
        }
    }
}