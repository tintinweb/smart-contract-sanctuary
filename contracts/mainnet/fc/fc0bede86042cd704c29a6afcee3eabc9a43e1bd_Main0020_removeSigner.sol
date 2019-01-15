// File: contracts/generic/SafeMath.sol

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error

    TODO: check against ds-math: https://blog.dapphub.com/ds-math/
    TODO: move roundedDiv to a sep lib? (eg. Math.sol)
    TODO: more unit tests!
*/
pragma solidity 0.4.24;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b, "mul overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by 0"); // Solidity automatically throws for div by 0 but require to emit reason
        uint256 c = a / b;
        // require(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "sub underflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");
        return c;
    }

    // Division, round to nearest integer, round half up
    function roundedDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by 0"); // Solidity automatically throws for div by 0 but require to emit reason
        uint256 halfB = (b % 2 == 0) ? (b / 2) : (b / 2 + 1);
        return (a % b >= halfB) ? (a / b + 1) : (a / b);
    }

    // Division, always rounds up
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "div by 0"); // Solidity automatically throws for div by 0 but require to emit reason
        return (a % b != 0) ? (a / b + 1) : (a / b);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? b : a;
    }    
}

// File: contracts/generic/MultiSig.sol

/* Abstract multisig contract to allow multi approval execution of atomic contracts scripts
        e.g. migrations or settings.
    * Script added by signing a script address by a signer  (NEW state)
    * Script goes to ALLOWED state once a quorom of signers sign it (quorom fx is defined in each derived contracts)
    * Script can be signed even in APPROVED state
    * APPROVED scripts can be executed only once.
        - if script succeeds then state set to DONE
        - If script runs out of gas or reverts then script state set to FAILEd and not allowed to run again
          (To avoid leaving "behind" scripts which fail in a given state but eventually execute in the future)
    * Scripts can be cancelled by an other multisig script approved and calling cancelScript()
    * Adding/removing signers is only via multisig approved scripts using addSigners / removeSigners fxs
*/
pragma solidity 0.4.24;



contract MultiSig {
    using SafeMath for uint256;

    mapping(address => bool) public isSigner;
    address[] public allSigners; // all signers, even the disabled ones
                                // NB: it can contain duplicates when a signer is added, removed then readded again
                                //   the purpose of this array is to being able to iterate on signers in isSigner
    uint public activeSignersCount;

    enum ScriptState {New, Approved, Done, Cancelled, Failed}

    struct Script {
        ScriptState state;
        uint signCount;
        mapping(address => bool) signedBy;
        address[] allSigners;
    }

    mapping(address => Script) public scripts;
    address[] public scriptAddresses;

    event SignerAdded(address signer);
    event SignerRemoved(address signer);

    event ScriptSigned(address scriptAddress, address signer);
    event ScriptApproved(address scriptAddress);
    event ScriptCancelled(address scriptAddress);

    event ScriptExecuted(address scriptAddress, bool result);

    constructor() public {
        // deployer address is the first signer. Deployer can configure new contracts by itself being the only "signer"
        // The first script which sets the new contracts live should add signers and revoke deployer&#39;s signature right
        isSigner[msg.sender] = true;
        allSigners.push(msg.sender);
        activeSignersCount = 1;
        emit SignerAdded(msg.sender);
    }

    function sign(address scriptAddress) public {
        require(isSigner[msg.sender], "sender must be signer");
        Script storage script = scripts[scriptAddress];
        require(script.state == ScriptState.Approved || script.state == ScriptState.New,
                "script state must be New or Approved");
        require(!script.signedBy[msg.sender], "script must not be signed by signer yet");

        if (script.allSigners.length == 0) {
            // first sign of a new script
            scriptAddresses.push(scriptAddress);
        }

        script.allSigners.push(msg.sender);
        script.signedBy[msg.sender] = true;
        script.signCount = script.signCount.add(1);

        emit ScriptSigned(scriptAddress, msg.sender);

        if (checkQuorum(script.signCount)) {
            script.state = ScriptState.Approved;
            emit ScriptApproved(scriptAddress);
        }
    }

    function execute(address scriptAddress) public returns (bool result) {
        // only allow execute to signers to avoid someone set an approved script failed by calling it with low gaslimit
        require(isSigner[msg.sender], "sender must be signer");
        Script storage script = scripts[scriptAddress];
        require(script.state == ScriptState.Approved, "script state must be Approved");

        // passing scriptAddress to allow called script access its own public fx-s if needed
        if (scriptAddress.delegatecall.gas(gasleft() - 23000)
            (abi.encodeWithSignature("execute(address)", scriptAddress))) {
            script.state = ScriptState.Done;
            result = true;
        } else {
            script.state = ScriptState.Failed;
            result = false;
        }
        emit ScriptExecuted(scriptAddress, result);
    }

    function cancelScript(address scriptAddress) public {
        require(msg.sender == address(this), "only callable via MultiSig");
        Script storage script = scripts[scriptAddress];
        require(script.state == ScriptState.Approved || script.state == ScriptState.New,
                "script state must be New or Approved");

        script.state = ScriptState.Cancelled;

        emit ScriptCancelled(scriptAddress);
    }

    /* requires quorum so it&#39;s callable only via a script executed by this contract */
    function addSigners(address[] signers) public {
        require(msg.sender == address(this), "only callable via MultiSig");
        for (uint i= 0; i < signers.length; i++) {
            if (!isSigner[signers[i]]) {
                require(signers[i] != address(0), "new signer must not be 0x0");
                activeSignersCount++;
                allSigners.push(signers[i]);
                isSigner[signers[i]] = true;
                emit SignerAdded(signers[i]);
            }
        }
    }

    /* requires quorum so it&#39;s callable only via a script executed by this contract */
    function removeSigners(address[] signers) public {
        require(msg.sender == address(this), "only callable via MultiSig");
        for (uint i= 0; i < signers.length; i++) {
            if (isSigner[signers[i]]) {
                require(activeSignersCount > 1, "must not remove last signer");
                activeSignersCount--;
                isSigner[signers[i]] = false;
                emit SignerRemoved(signers[i]);
            }
        }
    }

    /* implement it in derived contract */
    function checkQuorum(uint signersCount) internal view returns(bool isQuorum);

    function getAllSignersCount() view external returns (uint allSignersCount) {
        return allSigners.length;
    }

    // UI helper fx - Returns signers from offset as [signer id (index in allSigners), address as uint, isActive 0 or 1]
    function getSigners(uint offset, uint16 chunkSize)
    external view returns(uint[3][]) {
        uint limit = SafeMath.min(offset.add(chunkSize), allSigners.length);
        uint[3][] memory response = new uint[3][](limit.sub(offset));
        for (uint i = offset; i < limit; i++) {
            address signerAddress = allSigners[i];
            response[i - offset] = [i, uint(signerAddress), isSigner[signerAddress] ? 1 : 0];
        }
        return response;
    }

    function getScriptsCount() view external returns (uint scriptsCount) {
        return scriptAddresses.length;
    }

    // UI helper fx - Returns scripts from offset as
    //  [scriptId (index in scriptAddresses[]), address as uint, state, signCount]
    function getScripts(uint offset, uint16 chunkSize)
    external view returns(uint[4][]) {
        uint limit = SafeMath.min(offset.add(chunkSize), scriptAddresses.length);
        uint[4][] memory response = new uint[4][](limit.sub(offset));
        for (uint i = offset; i < limit; i++) {
            address scriptAddress = scriptAddresses[i];
            response[i - offset] = [i, uint(scriptAddress),
                uint(scripts[scriptAddress].state), scripts[scriptAddress].signCount];
        }
        return response;
    }
}

// File: contracts/StabilityBoardProxy.sol

/* allows tx to execute if 50% +1 vote of active signers signed */
pragma solidity 0.4.24;



contract StabilityBoardProxy is MultiSig {

    function checkQuorum(uint signersCount) internal view returns(bool isQuorum) {
        isQuorum = signersCount > activeSignersCount / 2 ;
    }
}

// File: contracts/SB_scripts/mainnet/Main0020_removeSigner.sol

/* Remove deployer account from mainnet signers */

pragma solidity 0.4.24;



contract Main0020_removeSigner {

    StabilityBoardProxy public constant STABILITY_BOARD_PROXY = StabilityBoardProxy(0xde36a8773531406dCBefFdfd3C7b89fCed7A9F84);

    function execute(Main0020_removeSigner /* self, not used */) external {
        // called via StabilityBoardProxy
        require(address(this) == address(STABILITY_BOARD_PROXY), "only execute via StabilityBoardProxy");

         // revoke deployer account signer rights
         address[] memory signersToRemove = new address[](1); // dynamic array needed for addSigners() & removeSigners()
         signersToRemove[0] = 0x23445fFDDA92567a4c6168D376C35d93AcB96e01;   // treer deployer account
         STABILITY_BOARD_PROXY.removeSigners(signersToRemove);
    }
}