/**
 *Submitted for verification at polygonscan.com on 2021-11-24
*/

pragma solidity 0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FirewallFactory is Ownable {
    mapping(bytes => bool) public whitelist;

    event NotWhitelisted(bytes code);
    event WhitelistUpdated(bytes _code, bool _value);
    event Deployed(address addr);

    modifier onlyWhitelisted(bytes memory _code) {
        require(_code.length != 0, 'ERROR: no code');

        if (!whitelist[_code]) {
            emit NotWhitelisted(_code);
            revert("Not Whitelisted !");
        }
        _;
    }

    // *many improvements possible - init data for example
    function deploy2(bytes memory _code, uint256 _salt) onlyWhitelisted(_code)
    public returns (address addr) {
        assembly {
            addr := create2(0, add(_code, 0x20), mload(_code), _salt)
        }
        require(addr != address(0), "Failed on deploy");

        emit Deployed(addr);
        return addr;
    }

    function deploy(bytes memory _code) onlyWhitelisted(_code) public returns (address addr) {
        assembly {
            addr := create(0, add(_code, 0x20), mload(_code))
        }
        require(addr != address(0), "Failed on deploy");

        emit Deployed(addr);
        return addr;
    }

    function updateWhitelist(bytes memory _code, bool _value) public onlyOwner returns (bool) {
        whitelist[_code] = _value;
        emit WhitelistUpdated(_code, _value);
        return true;
    }

    fallback() external payable {}

    receive() external payable {}
}


// draw.io flow chart (execution)
// I would create a template with comments. For such an easy task I would implement it myself.
// Add document explaining why is it important & timeframe
// TODO: read what must be done !
// add a readme with - key resources to read.
// Add spec that it must be deployed on ETH which means it must be very optimized !

// Key points: / Key KPIs
// 1. Deploy contract given bytecode
// 2. Add whitelisting collection & ADD/REMOVE functions
// 3. Add inWhitelist function & modifier with Event
// 4. Test with hardhat & eth-gas-profiler to see how efficient it is.

// I won't give any particular assets as research (like "how to deploy bytecode")
// neighter will I bring up the conversation on "what collection is most optimal" because
// 2 reasons: answering these questions give people the most /kudos/ and delight
// if done incorrectly -> an opportunity to learn !
// Key KPI is the first task.

// component diagrams, sequence diagrams, use-cases, short
// written documentation and/or any other specifications that you would normally do when planning
// architecture.


/*
1. Use Cases:
We need a dapp that generates wallets for new approved users. Why ? Because we want to give the users full custody of their own funds & wallet
by not storing any private keys & having no ownership.
That's why we'll deploy a contract each time a user logs-in. CREATE op-code might feel like the solution, however since we'll be
using Ethereum we need a better solution gas-wise. That's where CREATE2 comes in. It gives us the ability to determine the address
of the newly deployed wallet and only deploy it once the first interaction with the wallet get's made, saving gas.
You need to built the contract serving as a factory and you need to provide tools for easily integrating an UI that accepts code as input.

ps: I like giving people a sense of purpose by providing context for the task. Here is an example:
Use Case 2:
Hi X,
We have seen a big use & need of upgradability for our contracts having made mistakes in the past that led to critical errors.
We want to create the so called - UpgradeProxy that lets us change our business logic if need be.
Your part is the most core one - The FirewallFactory contract.
As you may guess from the name it does 2 main things
- it deployes contracts given the bytecode as input.
- it serves as a firewall, allowing only whitelisted bytecode to be deployed.
Spec:
only the owner can add to whitelist.
Please see the diagram for the desired flow & if any questions, feel free to ping me.

Extra Requinments:
- used on Ethereum = optimized gas-wise.

Tips:
* use CREATE for simplicity
*/