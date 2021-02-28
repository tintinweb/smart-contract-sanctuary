/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

/*
B.PROTOCOL TERMS OF USE
=======================

THE TERMS OF USE CONTAINED HEREIN (THESE “TERMS”) GOVERN YOUR USE OF B.PROTOCOL, WHICH IS A DECENTRALIZED PROTOCOL ON THE ETHEREUM BLOCKCHAIN (the “PROTOCOL”) THAT enables a backstop liquidity mechanism FOR DECENTRALIZED LENDING PLATFORMS (“DLPs”).  
PLEASE READ THESE TERMS CAREFULLY AT https://github.com/backstop-protocol/Terms-and-Conditions, INCLUDING ALL DISCLAIMERS AND RISK FACTORS, BEFORE USING THE PROTOCOL. BY USING THE PROTOCOL, YOU ARE IRREVOCABLY CONSENTING TO BE BOUND BY THESE TERMS. 
IF YOU DO NOT AGREE TO ALL OF THESE TERMS, DO NOT USE THE PROTOCOL. YOUR RIGHT TO USE THE PROTOCOL IS SUBJECT AND DEPENDENT BY YOUR AGREEMENT TO ALL TERMS AND CONDITIONS SET FORTH HEREIN, WHICH AGREEMENT SHALL BE EVIDENCED BY YOUR USE OF THE PROTOCOL.
Minors Prohibited: The Protocol is not directed to individuals under the age of eighteen (18) or the age of majority in your jurisdiction if the age of majority is greater. If you are under the age of eighteen or the age of majority (if greater), you are not authorized to access or use the Protocol. By using the Protocol, you represent and warrant that you are above such age.

License; No Warranties; Limitation of Liability;
(a) The software underlying the Protocol is licensed for use in accordance with the 3-clause BSD License, which can be accessed here: https://opensource.org/licenses/BSD-3-Clause.
(b) THE PROTOCOL IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS", “WITH ALL FAULTS” and “AS AVAILABLE” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
(c) IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/

// File: contracts/bprotocol/interfaces/IRegistry.sol

pragma solidity 0.5.16;


interface IRegistry {

    // Ownable
    function transferOwnership(address newOwner) external;

    // Compound contracts
    function comp() external view returns (address);
    function comptroller() external view returns (address);
    function cEther() external view returns (address);

    // B.Protocol contracts
    function bComptroller() external view returns (address);
    function score() external view returns (address);
    function pool() external view returns (address);

    // Avatar functions
    function delegate(address avatar, address delegatee) external view returns (bool);
    function doesAvatarExist(address avatar) external view returns (bool);
    function doesAvatarExistFor(address owner) external view returns (bool);
    function ownerOf(address avatar) external view returns (address);
    function avatarOf(address owner) external view returns (address);
    function newAvatar() external returns (address);
    function getAvatar(address owner) external returns (address);
    // avatar whitelisted calls
    function whitelistedAvatarCalls(address target, bytes4 functionSig) external view returns(bool);

    function setPool(address newPool) external;
    function setWhitelistAvatarCall(address target, bytes4 functionSig, bool list) external;
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/bprotocol/governance/GovernanceExecutor.sol

pragma solidity 0.5.16;



contract GovernanceExecutor is Ownable {

    IRegistry public registry;
    uint public delay;
    // newPoolAddr => requestTime
    mapping(address => uint) public poolRequests;
    // target => function => list => requestTime
    mapping(address => mapping(bytes4 => mapping(bool => uint))) whitelistRequests;
    address public governance;

    event RequestPoolUpgrade(address indexed pool);
    event PoolUpgraded(address indexed pool);

    event RequestSetWhitelistCall(address indexed target, bytes4 functionSig, bool list);
    event WhitelistCallUpdated(address indexed target, bytes4 functionSig, bool list);

    constructor(address registry_, uint delay_) public {
        registry = IRegistry(registry_);
        delay = delay_;
    }

    /**
     * @dev Sets governance address
     * @param governance_ Address of the governance
     */
    function setGovernance(address governance_) external onlyOwner {
        require(governance == address(0), "governance-already-set");
        governance = governance_;
    }

    /**
     * @dev Transfer admin of BCdpManager
     * @param owner New admin address
     */
    function doTransferAdmin(address owner) external {
        require(msg.sender == governance, "unauthorized");
        registry.transferOwnership(owner);
    }

    /**
     * @dev Request pool contract upgrade
     * @param pool Address of new pool contract
     */
    function reqUpgradePool(address pool) external onlyOwner {
        poolRequests[pool] = now;
        emit RequestPoolUpgrade(pool);
    }

    /**
     * @dev Drop upgrade pool request
     * @param pool Address of pool contract
     */
    function dropUpgradePool(address pool) external onlyOwner {
        delete poolRequests[pool];
    }

    /**
     * @dev Execute pool contract upgrade after delay
     * @param pool Address of the new pool contract
     */
    function execUpgradePool(address pool) external {
        uint reqTime = poolRequests[pool];
        require(reqTime != 0, "request-not-valid");
        require(now >= add(reqTime, delay), "delay-not-over");

        delete poolRequests[pool];
        registry.setPool(pool);
        emit PoolUpgraded(pool);
    }

    /**
     * @dev Request whitelist upgrade
     * @param target Address of new whitelisted contract
     * @param functionSig function signature as bytes4
     * @param list `true` to whitelist, `false` otherwise
     */
    function reqSetWhitelistCall(address target, bytes4 functionSig, bool list) external onlyOwner {
        whitelistRequests[target][functionSig][list] = now;
        emit RequestSetWhitelistCall(target, functionSig, list);
    }

    /**
     * @dev Drop upgrade whitelist request
     * @param target Address of new whitelisted contract
     * @param functionSig function signature as bytes4
     * @param list `true` to whitelist, `false` otherwise
     */
    function dropWhitelistCall(address target, bytes4 functionSig, bool list) external onlyOwner {
        delete whitelistRequests[target][functionSig][list];
    }

    /**
     * @dev Execute pool contract upgrade after delay
     * @param target Address of the new whitelisted contract
     * @param functionSig function signature as bytes4
     * @param list `true` to whitelist, `false` otherwise
     */
    function execSetWhitelistCall(address target, bytes4 functionSig, bool list) external {
        uint reqTime = whitelistRequests[target][functionSig][list];
        require(reqTime != 0, "request-not-valid");
        require(now >= add(reqTime, delay), "delay-not-over");

        delete whitelistRequests[target][functionSig][list];
        registry.setWhitelistAvatarCall(target, functionSig, list);
        emit WhitelistCallUpdated(target, functionSig, list);
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "overflow");
        return c;
    }
}