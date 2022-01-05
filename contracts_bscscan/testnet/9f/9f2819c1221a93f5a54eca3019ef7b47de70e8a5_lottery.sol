/**
 *Submitted for verification at BscScan.com on 2022-01-05
*/

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: lottery/lottery.sol



pragma solidity ^0.8.0;


contract lottery is Ownable {
    mapping(address => uint[]) Investers;
    address[] private invsetAdd;
    uint[] private listOfTickets;
    uint public winnerTicket = 123456;
    uint public numberOfLevel = 999999;
    uint public cost = 0.002 ether;
    uint private endTime;

    
    //events 
    event PriceMoney(uint value);

    //for buying tickets
    function buyTicket(uint _numberOfTickets) public payable returns(uint) {
      delete listOfTickets;
      require(msg.value >= cost * _numberOfTickets,"Insufficient Funds");
      uint newTickets  = random(numberOfLevel);
      for(uint i = 0; i < _numberOfTickets; i++) {
        newTickets = newTickets + 38;
        listOfTickets.push(newTickets);
      }
      Investers[msg.sender] = listOfTickets;
      invsetAdd.push(msg.sender);
      emit PriceMoney(address(this).balance / 100);
      return _numberOfTickets;
    }


    //for buying more tickets
    function buyMoreTicket(uint _nuberOfTickets) public payable returns(uint) {
      delete listOfTickets;
      require(msg.value >= cost * _nuberOfTickets,"Insufficient Funds");
      uint[] memory arr = Investers[msg.sender];
      listOfTickets = arr;
      uint newTickets = random(numberOfLevel);
      for (uint i =0; i < _nuberOfTickets; i++) {
        newTickets = newTickets + 38;
        listOfTickets.push(newTickets);
      }
      Investers[msg.sender] = listOfTickets;
      invsetAdd.push(msg.sender);
      emit PriceMoney(address(this).balance / 100);
      return _nuberOfTickets;
    }

    function getWinner() public view returns(uint) {
      require(block.timestamp > endTime, "Time Left"); 
      return winnerTicket;
    }


    //set winner 
    function WinnerTicket() public onlyOwner returns(uint) {
        winnerTicket = random(numberOfLevel);
        return winnerTicket;
    }


    function withdrawal(uint _ticketNumber) public returns(uint) {
        require(block.timestamp > endTime, "Time Left...");
        uint reverseUserTicket = reverse_int(_ticketNumber);
        uint reverseWinnerTicket = reverse_int(winnerTicket);
        uint level = getLevel(reverseUserTicket, 0 , reverseWinnerTicket);
        uint [] memory usersTickets = Investers[msg.sender];
        require(level > 0, "No Match Found. Best Of Luck For Next Time");
        require(usersTickets.length > 0 , "You Aren't An Invester");
        bool isValid = false;
        for (uint i =0; i < usersTickets.length; i++) {
             if(usersTickets[i] == _ticketNumber) {
               isValid = true;
               uint amount = getPercentages(level);
               (bool success,) = msg.sender.call{value : amount}("");
               require(success, "Transfer failed.");
               delete Investers[msg.sender];
             }
        }
        require(isValid, "Your Ticket Is Not Found In Your Address Please Check And Try Again");
        return level;
    }

    function getPercentages(uint level) private view returns(uint) { 
        uint intireAmount = address(this).balance / 10;
        uint value = 0;
        if(level == 1) {
            value = ((10 * intireAmount) / 100);
        } else if(level == 2) {
            value = ((20 * intireAmount) / 100);
        } else if(level == 3) {
            value = ((40 * intireAmount) / 100);
        } else if(level == 4) {
            value = ((60 * intireAmount) / 100);
        } else if(level == 5) {
            value = ((80 * intireAmount) / 100);
        } else if(level == 6) {
            value = ((100 * intireAmount) / 100);
        }
        return value;
    }

    function getLevel(uint i, uint level, uint winnerAmount) public returns(uint){
        if(i != 0) {
            uint lastvalue = i % 10;
            uint wa = winnerAmount % 10;
            if(lastvalue == wa) {
                level = level + 1; 
                level = getLevel(i / 10, level, winnerAmount / 10);  
            } else {
            //   test.push(lastvalue);
              return level;
            }
        } 
        return level;
    }

    //Get All Tickets Here
    function getAllTickets(address _user) public view returns(uint [] memory) {
        uint[] memory newArr =  Investers[_user];
        uint value;
        for(uint a = 0 ; a < newArr.length ; a++) {
          value = newArr[a];
        }
        return newArr;
    }

    // reset 
    function restartLottery (uint _time) public onlyOwner returns(bool) {
      for(uint i=0; i < invsetAdd.length ; i++) {
        // Investers[invsetAdd[i]] = 0;
        delete Investers[invsetAdd[i]];
      }
      endTime = block.timestamp + _time;
      delete invsetAdd;
      winnerTicket = 0;
      return true;
    }

    //these two function responsible for random number
    function random(uint _limit) public view returns(uint) {
        uint start = 100000;
        uint randomValue = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, start))) % _limit;
        if(randomValue < start) {
            randomValue = random(_limit);
        }
        return  randomValue;
    }


    function reverse_recurse(uint i, uint r) internal returns(uint) {
      if (i != 0) {
        uint least_digit = i % 10;
        if (r >= type(uint).max / 10 && (r > type(uint).max / 10 || least_digit > type(uint).max % 10)) {
          return 0; /// Overflow
        }
        r = reverse_recurse(i / 10, r * 10 + least_digit);
      }
      return r;
    }
    
    // Reverses digits in a uint, overflow returns 0
    function reverse_int(uint i) public returns(uint) {
      return reverse_recurse(i, 0);
    }

    function changePrice(uint _value) public onlyOwner returns(uint) {
      cost = _value;
      return cost;
    }

}