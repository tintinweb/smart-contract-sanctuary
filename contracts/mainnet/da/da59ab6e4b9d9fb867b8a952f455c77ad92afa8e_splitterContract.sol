pragma solidity ^0.4.11;


/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 */
contract Ownable {
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) {
      throw;
    }
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract splitterContract is Ownable{

    event ev(string msg, address whom, uint256 val);

    struct xRec {
        bool inList;
        address next;
        address prev;
        uint256 val;
    }

    struct l8r {
        address whom;
        uint256 val;
    }
    address public myAddress = this;
    address public first;
    address public last;
    address public ddf;
    bool    public thinkMode;
    uint256 public pos;

    mapping (address => xRec) public theList;

    l8r[]  afterParty;

    modifier onlyMeOrDDF() {
        if (msg.sender == ddf || msg.sender == myAddress || msg.sender == owner) {
            _;
            return;
        }
    }

    function setDDF(address ddf_) onlyOwner {
        ddf = ddf_;
    }

    function splitterContract(address seed, uint256 seedVal) {
        first = seed;
        last = seed;
        theList[seed] = xRec(true,0x0,0x0,seedVal);
    }

    function startThinking() onlyOwner {
        thinkMode = true;
        pos = 0;
    }

    function stopThinking(uint256 num) onlyOwner {
        thinkMode = false;
        for (uint256 i = 0; i < num; i++) {
            if (pos >= afterParty.length) {
                delete afterParty;
                return;
            }
            update(afterParty[pos].whom,afterParty[pos].val);
            pos++;
        }
        thinkMode = true;
    } 

    function thinkLength() constant returns (uint256) {
        return afterParty.length;
    }

    function addRec4L8R(address whom, uint256 val) internal {
        afterParty.push(l8r(whom,val));
    }

    function add(address whom, uint256 value) internal {
        theList[whom] = xRec(true,0x0,last,value);
        theList[last].next = whom;
        last = whom;
        ev("add",whom,value);
    }

    function remove(address whom) internal {
        if (first == whom) {
            first = theList[whom].next;
            theList[whom] = xRec(false,0x0,0x0,0);
            return;
        }
        address next = theList[whom].next;
        address prev = theList[whom].prev;
        if (prev != 0x0) {
            theList[prev].next = next;
        }
        if (next != 0x0) {
            theList[next].prev = prev;
        }
        theList[whom] = xRec(false,0x0,0x0,0);
        ev("remove",whom,0);
    }

    function update(address whom, uint256 value) onlyMeOrDDF {
        if (thinkMode) {
            addRec4L8R(whom,value);
            return;
        }
        if (value != 0) {
            if (!theList[whom].inList) {
                add(whom,value);
            } else {
                theList[whom].val = value;
                ev("update",whom,value);
            }
            return;
        }
        if (theList[whom].inList) {
                remove(whom);
        }
    }

}