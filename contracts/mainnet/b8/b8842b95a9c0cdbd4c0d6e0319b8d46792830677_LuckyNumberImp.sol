pragma solidity ^0.4.15;

// MMMMWKkk0KNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkOKWMMMMMM //
// MMMMXl.....,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOo:,.....dNMMMM //
// MMMWd.        .&#39;cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d:&#39;.        .xMMMM //
// MMMK,   ......   ..:xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.    .....    :XMMM //
// MMWd.   .;;;,,&#39;..   .&#39;lkXNWWNNNWMMMMMMMMMMWNNWWWNKkc..  ...&#39;,;;;,.   .kMMM //
// MMNc   .,::::::;,&#39;..   ..,;;,,dNMMMMMMMMMMXl,;;;,..   ..&#39;;;::::::&#39;.  .lWMM //
// MM0&#39;   .;:::::::;;&#39;..        ;0MMMMMMMMMMMWO&#39;        ..,;;:::::::;.   ;KMM //
// MMx.  .&#39;;::::;,&#39;...        .:0MMMMMMMMMMMMMWO;.        ...&#39;;;::::;..  .OMM //
// MWd.  .,:::;&#39;..          .,xNMMMMMMMMMMMMMMMMXd&#39;.          ..,;:::&#39;.  .xMM //
// MNl.  .,:;&#39;..         .,ckNMMMMMMMMMMMMMMMMMMMMXxc&#39;.         ..&#39;;:,.  .dWM //
// MNc   .,,..    .;:clox0NWXXWMMMMMMMMMMMMMMMMMMWXXWXOxolc:;.    ..,&#39;.  .oWM //
// MNc   ...     .oWMMMNXNMW0odXMMMMMMMMMMMMMMMMKooKWMNXNMMMNc.     ...  .oWM //
// MNc.          ;KMMMMNkokNMXlcKMMMMMMMMMMMMMM0coNMNxoOWMMMM0,          .oWM //
// MNc         .;0MMMMMMWO:dNMNoxWMMMMMMMMMMMMNddNMNocKMMMMMMWO,         .oWM //
// MX:        .lXMMMMMMMMM0lOMMNXWMMMMMMMMMMMMWXNMMklKMMMMMMMMM0:.       .lNM //
// MX;      .;kWMMMMMMMMMMMXNMMMMMMMMMMMMMMMMMMMMMMNNMMMMMMMMMMMNx,.      cNM //
// MO.    .:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:.  . ,0M //
// Wl..&#39;:dKWMMMMMMMWNK000KNMMMMMMMMMMMMMMMMMMMMMMMMMWNK000KNMMMMMMMMW0o;...dW //
// NxdOXWMMMMMMMW0olcc::;,,cxXWMMMMMMMMMMMMMMMMMMWKd:,,;::ccld0WMMMMMMMWKkokW //
// MMMMMMMMMMMWOlcd0XWWWN0x:.,OMMMMMMMMMMMMMMMMMWk,&#39;cxKNWWWXOdcl0MMMMMMMMMMMM //
// MMMMMMMMMMMWKKWMMMMMMMMMWK0XMMMMMMMMMMMMMMMMMMXOXWMMMMMMMMMN0XMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK0OOOO0KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.......&#39;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMMNKOkkkk0XNMMMMMMMMMMMMMMMMMMWO;.    .:0WMMMMMMMMMMMMMMMMMWNKOkkkkOKNMMM //
// MMWXOkxddoddxxkKWMMMMMMMMMMMMMMMMXo...&#39;dNMMMMMMMMMMMMMMMMN0kxxdodddxk0XMMM //
// MMMMMMMMMMMMWNKKNMMMMMMMMMMMMMMMMWOc,,c0WMMMMMMMMMMMMMMMMXKKNWMMMMMMMMMMMM //
// MMMMMMMMWXKKXXNWMMMMMMMMMMWWWWWX0xcclc:cxKNWWWWWMMMMMMMMMMWNXXKKXWMMMMMMMM //
// MMMWXOxdoooddxkO0NMMMMMMMWKkxxdlloxKNX0dolodxxkXMMMMMMMWX0OkxddooddxOXWMMM //
// MMMWXKKNNWMMMMMWWWMMMMMMMMMWNXXXNWMMMMMMWXXXXNWMMMMMMMMMWWWMMMMWWNXKKNWMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM Lucky  MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM Number MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM ------ MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM Random MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MM Contract design by MMMMMMMMMMM Ledger MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// => 0x7C601D5DCd97B680dd623ff816D233898e6AD8dC <=MMMMMMM +.+.+. -> MMXVII M //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //


// Manages contract ownership.
contract Owned {
    address public owner;
    function owned() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address _newOwner) onlyOwner {
        owner = _newOwner;
    }
}

contract Mortal is Owned {
    /* Function to recover the funds on the contract */
    function kill() onlyOwner {
        selfdestruct(owner);
    }
}

/* taking ideas from FirstBlood token */
contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}

// Random is a block hash based random number generator.
// this is public so requestors can validate thier numbers
// independent of the native user interface
contract Random is SafeMath {
    // Generates a random number from 1 to max based on the last block hash.
    function getRand(uint blockNumber, uint max)
    public
    constant 
    returns(uint) {
        // block.blockhash(uint blockNumber) returns (bytes32): hash of the given block
        // only works for 256 most recent blocks excluding current
        return(safeAdd(uint(sha3(block.blockhash(blockNumber))) % max, 1));
    }
}

// LuckyNumber is the main public interface for a random number ledger.
// To make a request:
//   Step 1: Call requestNumber with the `cost` as the value
//   Step 2: Wait waitTime in blocks past the block which mines transaction for requestNumber
//   Step 3: Call revealNumber() to generate the number, and make it publicly accessable in the UI.
//           this is required to create the Events which generate the Ledger. 
contract LuckyNumber is Owned {
    // cost to generate a random number in Wei.
    uint256 public cost;
    // waitTime is the number of blocks before random is generated.
    uint8 public waitTime;
    // set default max
    uint256 public max;

    // PendingNumber represents one number.
    struct PendingNumber {
        address proxy;
        uint256 renderedNumber;
        uint256 creationBlockNumber;
        uint256 max;
        // block to wait
        // this will also be used as
        // an active bool to save some storage
        uint8 waitTime;
    }

    // for Number Config
    event EventLuckyNumberUpdated(uint256 cost, uint256 max, uint8 waitTime);
    // for Number Ledger
    event EventLuckyNumberRequested(address requestor, uint256 max, uint256 creationBlockNumber, uint8 waitTime);
    event EventLuckyNumberRevealed(address requestor, uint256 max, uint256 renderedNumber);
    
    mapping (address => PendingNumber) public pendingNumbers;
    mapping (address => bool) public whiteList;

    function requestNumber(address _requestor, uint256 _max, uint8 _waitTime) payable public;
    function revealNumber(address _requestor) payable public;
}

// LuckyNumber Implementation
contract LuckyNumberImp is LuckyNumber, Mortal, Random {
    
    // Initialize state +.+.+.
    function LuckyNumberImp() {
        owned();
        // defaults
        cost = 20000000000000000; // 0.02 ether // 20 finney
        max = 15; // generate number between 1 and 15
        waitTime = 3; // 3 blocks
    }

    // Allow the owner to set proxy contracts
    // which can accept tokens
    // on behalf of this contract
    function enableProxy(address _proxy)
    onlyOwner
    public
    returns (bool) {
        // _cost
        whiteList[_proxy] = true;
        return whiteList[_proxy];
    }

    function removeProxy(address _proxy)
    onlyOwner
    public
    returns (bool) {
        delete whiteList[_proxy];
        return true;
    }

    // Allow the owner to set max.
    function setMax(uint256 _max)
    onlyOwner
    public
    returns (bool) {
        max = _max;
        EventLuckyNumberUpdated(cost, max, waitTime);
        return true;
    }

    // Allow the owner to set waitTime. (in blocks)
    function setWaitTime(uint8 _waitTime)
    onlyOwner
    public
    returns (bool) {
        waitTime = _waitTime;
        EventLuckyNumberUpdated(cost, max, waitTime);
        return true;
    }

    // Allow the owner to set cost.
    function setCost(uint256 _cost)
    onlyOwner
    public
    returns (bool) {
        cost = _cost;
        EventLuckyNumberUpdated(cost, max, waitTime);
        return true;
    }
    
    // Allow the owner to cash out the holdings of this contract.
    function withdraw(address _recipient, uint256 _balance)
    onlyOwner
    public
    returns (bool) {
        _recipient.transfer(_balance);
        return true;
    }

    // Assume that simple transactions are trying to request a number, unless it is
    // from the owner.
    function () payable public {
        if (msg.sender != owner) {
            requestNumber(msg.sender, max, waitTime);
        }
    }
    
    // Request a Number.
    function requestNumber(address _requestor, uint256 _max, uint8 _waitTime)
    payable 
    public {
        // external requirement: 
        // value must exceed cost
        // unless address is whitelisted
        if (!whiteList[msg.sender]) {
            require(!(msg.value < cost));
        }

        // internal requirement: 
        // request address must not have pending number
        assert(!checkNumber(_requestor));
        // set pending number
        pendingNumbers[_requestor] = PendingNumber({
            proxy: tx.origin,
            renderedNumber: 0,
            max: max,
            creationBlockNumber: block.number,
            waitTime: waitTime
        });
        if (_max > 1) {
            pendingNumbers[_requestor].max = _max;
        }
        // max 250 wait to leave a few blocks
        // for the reveal transction to occur
        // and write from the pending numbers block
        // before it expires
        if (_waitTime > 0 && _waitTime < 250) {
            pendingNumbers[_requestor].waitTime = _waitTime;
        }
        EventLuckyNumberRequested(_requestor, pendingNumbers[_requestor].max, pendingNumbers[_requestor].creationBlockNumber, pendingNumbers[_requestor].waitTime);
    }

    // Only requestor or proxy can generate the number
    function revealNumber(address _requestor)
    public
    payable {
        assert(_canReveal(_requestor, msg.sender));
        _revealNumber(_requestor);
    }

    // Internal implementation of revealNumber().
    function _revealNumber(address _requestor) 
    internal {
        // waitTime has passed, render this requestor&#39;s number.
        uint256 luckyBlock = _revealBlock(_requestor);
        // 
        // TIME LIMITATION:
        // blocks older than (currentBlock - 256) 
        // "expire" and read the same hash as most recent valid block
        // 
        uint256 luckyNumber = getRand(luckyBlock, pendingNumbers[_requestor].max);

        // set new values
        pendingNumbers[_requestor].renderedNumber = luckyNumber;
        // event
        EventLuckyNumberRevealed(_requestor, pendingNumbers[_requestor].creationBlockNumber, pendingNumbers[_requestor].renderedNumber);
        // zero out wait blocks since this is now inactive
        pendingNumbers[_requestor].waitTime = 0;
        // update creation block as one use for number (record keeping)
        pendingNumbers[_requestor].creationBlockNumber = 0;
    }

    function canReveal(address _requestor)
    public
    constant
    returns (bool, uint, uint, address, address) {
        return (_canReveal(_requestor, msg.sender), _remainingBlocks(_requestor), _revealBlock(_requestor), _requestor, msg.sender);
    }

    function _canReveal(address _requestor, address _proxy) 
    internal
    constant
    returns (bool) {
        // check for pending number request
        if (checkNumber(_requestor)) {
            // check for no remaining blocks to be mined
            // must wait for `pendingNumbers[_requestor].waitTime` to be excceeded
            if (_remainingBlocks(_requestor) == 0) {
                // check for ownership
                if (pendingNumbers[_requestor].proxy == _requestor || pendingNumbers[_requestor].proxy == _proxy) {
                    return true;
                }
            }
        }
        return false;
    }

    function _remainingBlocks(address _requestor)
    internal
    constant
    returns (uint) {
        uint256 revealBlock = safeAdd(pendingNumbers[_requestor].creationBlockNumber, pendingNumbers[_requestor].waitTime);
        uint256 remainingBlocks = 0;
        if (revealBlock > block.number) {
            remainingBlocks = safeSubtract(revealBlock, block.number);
        }
        return remainingBlocks;
    }

    function _revealBlock(address _requestor)
    internal
    constant
    returns (uint) {
        // add wait block time
        // to creation block time
        // then subtract 1
        return safeAdd(pendingNumbers[_requestor].creationBlockNumber, pendingNumbers[_requestor].waitTime);
    }


    function getNumber(address _requestor)
    public
    constant
    returns (uint, uint, uint, address) {
        return (pendingNumbers[_requestor].renderedNumber, pendingNumbers[_requestor].max, pendingNumbers[_requestor].creationBlockNumber, _requestor);
    }

    // is a number pending for this requestor?
    // TRUE: there is a number pending
    // can not request, can reveal
    // FALSE: there is not a number yet pending
    function checkNumber(address _requestor)
    public
    constant
    returns (bool) {
        if (pendingNumbers[_requestor].renderedNumber == 0 && pendingNumbers[_requestor].waitTime > 0) {
            return true;
        }
        return false;
    }
// 0xMMWKkk0KNM>HBBi\MASSa\DANTi\LANTen.MI.MI.MI.M+.+.+.M->MMMWNKOkOKWJ.J.J.M //
}