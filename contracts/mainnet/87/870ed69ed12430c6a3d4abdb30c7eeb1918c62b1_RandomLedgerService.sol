pragma solidity ^0.4.11;//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkOKWMMMMMM //
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
// MMMWXOxdoooddxkO0NMMMMMMMWKkfoahheitNX0GlikkdakXMMMMMMMWX0OkxddooddxOXWMMM //
// MMMWXKKNNWMMMMMWWWMMMMMMMMMWNXXXNWMMMMMMWXXXXNWMMMMMMMMMWWWMMMMWWNXKKNWMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM Lucky* MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// MMM> *~+> we are the MMMMMMMMMMMM Number MMMMMMM> we are the <+~* <MMMMMMM //
// MMMMMMMMMM> music <MMMMMMMMMMMMMM ------ MMMMMMMMMM> dreamer <MMMMMMMMMMMM //
// MMMMMMMM> *~+> makers <MMMMM<MMMM Random MMMMMMMMMMMMM> of <MMMMMMMMMMMMMM //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM Ledger MMMMMMMMMMMMMM> dreams. <+~* <MMM //
// M> palimpsest by <MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //
// ~> arkimedes.eth <~+~+~+~~+~+~+~~+~+~+~~+~+~+~~+~+~+~~> VIII*XII*MMXVII <~ //
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM //

/**
 * Manages contract ownership.
 */
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

/**
 * Function to recover the funds on the contract
 */
contract Mortal is Owned {
    function kill() onlyOwner {
        selfdestruct(owner);
    }
}

/**
 * SafeMath
 * Math operations with safety checks that throw on error.
 * Taking ideas from FirstBlood token. Enhanced by OpenZeppelin.
 */
contract SafeMath {
  function mul(uint256 a, uint256 b)
  internal
  constant
  returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b)
  internal
  constant
  returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b)
  internal
  constant
  returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b)
  internal
  constant
  returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * Random number generator from mined block hash.
 */
contract Random is SafeMath {
    // Generates a random number from 1 to max based on the last block hash.
    function getRandomFromBlockHash(uint blockNumber, uint max)
    public
    constant 
    returns(uint) {
        // block.blockhash(uint blockNumber)
        //    returns
        //    (bytes32):
        //        hash of the given block
        // !! only works for 256 most recent blocks excluding current !!
        return(add(uint(sha3(block.blockhash(blockNumber))) % max, 1));
    }
}

/**
 * RandomLedger is the main public interface for a random number ledger.
 * To make a request:
 * Step 1: Call requestNumber with the `cost` as the value
 * Step 2: Wait waitTime in blocks past the block which mines transaction for requestNumber
 * Step 3: Call revealNumber to generate the number, and make it publicly accessable in the UI.
 *         this is required to create the Events which generate the Ledger. 
 */
contract RandomLedger is Owned {
    // ~> cost to generate a random number in Wei.
    uint256 public cost;
    // ~> waitTime is the number of blocks before random is generated.
    uint8 public waitTime;
    // ~> set default max
    uint256 public max;

    // PendingNumber represents one number.
    struct PendingNumber {
        address requestProxy;
        uint256 renderedNumber;
        uint256 originBlock;
        uint256 max;
        // blocks to wait,
        // also maintains pending state
        uint8 waitTime;
    }

    // for Number Ledger
    event EventRandomLedgerRequested(address requestor, uint256 max, uint256 originBlock, uint8 waitTime, address indexed requestProxy);
    event EventRandomLedgerRevealed(address requestor, uint256 originBlock, uint256 renderedNumber, address indexed requestProxy);
    
    mapping (address => PendingNumber) pendingNumbers;
    mapping (address => bool) public whiteList;

    function requestNumber(address _requestor, uint256 _max, uint8 _waitTime) payable public;
    function revealNumber(address _requestor) payable public;
}

/**
 * Lucky Number :: Random Ledger Service *~+>
 * Any contract or address can make a request from this implementation
 * on behalf of any other address as a requestProxy.
 */
contract RandomLedgerService is RandomLedger, Mortal, Random {
    
    // Initialize state +.+.+.
    function RandomLedgerService() {
        owned();
        cost = 20000000000000000; // 0.02 ether // 20 finney
        max = 21; // generate number between 1 and 21
        waitTime = 5; // 5 blocks
    }

    // Let owner customize defauts.
    // Allow the owner to set max.
    function setMax(uint256 _max)
    onlyOwner
    public
    returns (bool) {
        max = _max;
        return true;
    }

    // Allow the owner to set waitTime. (in blocks)
    function setWaitTime(uint8 _waitTime)
    onlyOwner
    public
    returns (bool) {
        waitTime = _waitTime;
        return true;
    }

    // Allow the owner to set cost.
    function setCost(uint256 _cost)
    onlyOwner
    public
    returns (bool) {
        cost = _cost;
        return true;
    }

    // Allow the owner to set a transaction proxy
    // which can perform value exchanges on behalf of this contract.
    // (unrelated to the requestProxy which is not whiteList)
    function enableProxy(address _proxy)
    onlyOwner
    public
    returns (bool) {
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

    // Allow the owner to cash out the holdings of this contract.
    function withdraw(address _recipient, uint256 _balance)
    onlyOwner
    public
    returns (bool) {
        _recipient.transfer(_balance);
        return true;
    }

    // Assume that simple transactions are trying to request a number,
    // unless it is from the owner.
    function () payable public {
        assert(msg.sender != owner);
        requestNumber(msg.sender, max, waitTime);
    }
    
    // Request a Number ... *~>
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
        assert(!isRequestPending(_requestor));
        // set pending number
        pendingNumbers[_requestor] = PendingNumber({
            requestProxy: tx.origin, // requestProxy: original address that kicked off the transaction
            renderedNumber: 0,
            max: max,
            originBlock: block.number,
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
        EventRandomLedgerRequested(_requestor, pendingNumbers[_requestor].max, pendingNumbers[_requestor].originBlock, pendingNumbers[_requestor].waitTime, pendingNumbers[_requestor].requestProxy);
    }

    // Reveal your number ... *~>
    // Only requestor or proxy can generate the number
    function revealNumber(address _requestor)
    public
    payable {
        assert(_canReveal(_requestor, msg.sender));
        // waitTime has passed, render this requestor&#39;s number.
        _revealNumber(_requestor);
    }

    // Internal implementation of revealNumber().
    function _revealNumber(address _requestor) 
    internal {
        uint256 luckyBlock = _revealBlock(_requestor);
        // 
        // TIME LIMITATION ~> should handle in user interface
        // blocks older than (currentBlock - 256) 
        // "expire" and read the same hash as most recent valid block
        // 
        uint256 luckyNumber = getRandomFromBlockHash(luckyBlock, pendingNumbers[_requestor].max);

        // set new values
        pendingNumbers[_requestor].renderedNumber = luckyNumber;
        // event
        EventRandomLedgerRevealed(_requestor, pendingNumbers[_requestor].originBlock, pendingNumbers[_requestor].renderedNumber, pendingNumbers[_requestor].requestProxy);
        // zero out wait blocks since this is now inactive (for state management)
        pendingNumbers[_requestor].waitTime = 0;
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
        if (isRequestPending(_requestor)) {
            // check for no remaining blocks to be mined
            // must wait for `pendingNumbers[_requestor].waitTime` to be excceeded
            if (_remainingBlocks(_requestor) == 0) {
                // check for ownership
                if (pendingNumbers[_requestor].requestProxy == _requestor || pendingNumbers[_requestor].requestProxy == _proxy) {
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
        uint256 revealBlock = add(pendingNumbers[_requestor].originBlock, pendingNumbers[_requestor].waitTime);
        uint256 remainingBlocks = 0;
        if (revealBlock > block.number) {
            remainingBlocks = sub(revealBlock, block.number);
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
        return add(pendingNumbers[_requestor].originBlock, pendingNumbers[_requestor].waitTime);
    }


    function getNumber(address _requestor)
    public
    constant
    returns (uint, uint, uint, address) {
        return (pendingNumbers[_requestor].renderedNumber, pendingNumbers[_requestor].max, pendingNumbers[_requestor].originBlock, _requestor);
    }

    // is a number request pending for the address
    function isRequestPending(address _requestor)
    public
    constant
    returns (bool) {
        if (pendingNumbers[_requestor].renderedNumber == 0 && pendingNumbers[_requestor].waitTime > 0) {
            return true;
        }
        return false;
    }
// 0xMMWKkk0KN/>HBBi/MASSa/DANTi/LANTen.MI.MI.MI.M+.+.+.M->MMWNKOkOKWJ.J.J.M*~+>
}