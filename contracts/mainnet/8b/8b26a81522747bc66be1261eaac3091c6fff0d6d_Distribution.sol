pragma solidity ^0.4.13;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Distribution is Ownable {
    using SafeMath for uint256;

    struct Recipient {
        address addr;
        uint256 share;
        uint256 balance;
        uint256 received;
    }

    uint256 sharesSum;
    uint8 constant maxRecsAmount = 12;
    mapping(address => Recipient) public recs;
    address[maxRecsAmount] public recsLookUpTable; //to iterate

    event Payment(address indexed to, uint256 value);
    event AddShare(address to, uint256 value);
    event ChangeShare(address to, uint256 value);
    event DeleteShare(address to);
    event ChangeAddessShare(address newAddress);
    event FoundsReceived(uint256 value);

    function Distribution() public {
        sharesSum = 0;
    }

    function receiveFunds() public payable {
        emit FoundsReceived(msg.value);
        for (uint8 i = 0; i < maxRecsAmount; i++) {
            Recipient storage rec = recs[recsLookUpTable[i]];
            uint ethAmount = (rec.share.mul(msg.value)).div(sharesSum);
            rec.balance = rec.balance + ethAmount;
        }
    }

    modifier onlyMembers(){
        require(recs[msg.sender].addr != address(0));
        _;
    }

    function doPayments() public {
        Recipient storage rec = recs[msg.sender];
        require(rec.balance >= 1e12);
        rec.addr.transfer(rec.balance);
        emit Payment(rec.addr, rec.balance);
        rec.received = (rec.received).add(rec.balance);
        rec.balance = 0;
    }

    function addShare(address _rec, uint256 share) public onlyOwner {
        require(_rec != address(0));
        require(share > 0);
        require(recs[_rec].addr == address(0));
        recs[_rec].addr = _rec;
        recs[_rec].share = share;
        recs[_rec].received = 0;
        for(uint8 i = 0; i < maxRecsAmount; i++ ) {
            if (recsLookUpTable[i] == address(0)) {
                recsLookUpTable[i] = _rec;
                break;
            }
        }
        sharesSum = sharesSum.add(share);
        emit AddShare(_rec, share);
    }

    function changeShare(address _rec, uint share) public onlyOwner {
        require(_rec != address(0));
        require(share > 0);
        require(recs[_rec].addr != address(0));
        Recipient storage rec = recs[_rec];
        sharesSum = sharesSum.sub(rec.share).add(share);
        rec.share = share;
        emit ChangeShare(_rec, share);
    }

    function deleteShare(address _rec) public onlyOwner {
        require(_rec != address(0));
        require(recs[_rec].addr != address(0));
        sharesSum = sharesSum.sub(recs[_rec].share);
        for(uint8 i = 0; i < maxRecsAmount; i++ ) {
            if (recsLookUpTable[i] == recs[_rec].addr) {
                recsLookUpTable[i] = address(0);
                break;
            }
        }
        delete recs[_rec];
        emit DeleteShare(msg.sender);
    }

    function changeRecipientAddress(address _newRec) public {
        require(msg.sender != address(0));
        require(_newRec != address(0));
        require(recs[msg.sender].addr != address(0));
        require(recs[_newRec].addr == address(0));
        require(recs[msg.sender].addr != _newRec);

        Recipient storage rec = recs[msg.sender];
        uint256 prevBalance = rec.balance;
        addShare(_newRec, rec.share);
        emit ChangeAddessShare(_newRec);
        deleteShare(msg.sender);
        recs[_newRec].balance = prevBalance;
        emit DeleteShare(msg.sender);

    }

    function getMyBalance() public view returns(uint256) {
        return recs[msg.sender].balance;
    }
}