/**
 *Submitted for verification at Etherscan.io on 2021-02-26
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

// File: contracts/bprotocol/proxy/GnosisSafeProxy.sol

pragma solidity >=0.5.0 <0.7.0;

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <[email protected]>
interface IProxy {
    function masterCopy() external view returns (address);
}

/// @title GnosisSafeProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract GnosisSafeProxy {

    // masterCopy always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal masterCopy;

    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "Invalid master copy address provided");
        masterCopy = _masterCopy;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    function ()
        external
        payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, masterCopy)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}

// File: contracts/bprotocol/interfaces/IAvatar.sol

pragma solidity 0.5.16;

contract IAvatarERC20 {
    function transfer(address cToken, address dst, uint256 amount) external returns (bool);
    function transferFrom(address cToken, address src, address dst, uint256 amount) external returns (bool);
    function approve(address cToken, address spender, uint256 amount) public returns (bool);
}

contract IAvatar is IAvatarERC20 {
    function initialize(address _registry, address comp, address compVoter) external;
    function quit() external returns (bool);
    function canUntop() public returns (bool);
    function toppedUpCToken() external returns (address);
    function toppedUpAmount() external returns (uint256);
    function redeem(address cToken, uint256 redeemTokens, address payable userOrDelegatee) external returns (uint256);
    function redeemUnderlying(address cToken, uint256 redeemAmount, address payable userOrDelegatee) external returns (uint256);
    function borrow(address cToken, uint256 borrowAmount, address payable userOrDelegatee) external returns (uint256);
    function borrowBalanceCurrent(address cToken) external returns (uint256);
    function collectCToken(address cToken, address from, uint256 cTokenAmt) public;
    function liquidateBorrow(uint repayAmount, address cTokenCollateral) external payable returns (uint256);

    // Comptroller functions
    function enterMarket(address cToken) external returns (uint256);
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);
    function exitMarket(address cToken) external returns (uint256);
    function claimComp() external;
    function claimComp(address[] calldata bTokens) external;
    function claimComp(address[] calldata bTokens, bool borrowers, bool suppliers) external;
    function getAccountLiquidity() external view returns (uint err, uint liquidity, uint shortFall);
}

// Workaround for issue https://github.com/ethereum/solidity/issues/526
// CEther
contract IAvatarCEther is IAvatar {
    function mint() external payable;
    function repayBorrow() external payable;
    function repayBorrowBehalf(address borrower) external payable;
}

// CErc20
contract IAvatarCErc20 is IAvatar {
    function mint(address cToken, uint256 mintAmount) external returns (uint256);
    function repayBorrow(address cToken, uint256 repayAmount) external returns (uint256);
    function repayBorrowBehalf(address cToken, address borrower, uint256 repayAmount) external returns (uint256);
}

contract ICushion {
    function liquidateBorrow(uint256 underlyingAmtToLiquidate, uint256 amtToDeductFromTopup, address cTokenCollateral) external payable returns (uint256);    
    function canLiquidate() external returns (bool);
    function untop(uint amount) external;
    function toppedUpAmount() external returns (uint);
    function remainingLiquidationAmount() external returns(uint);
    function getMaxLiquidationAmount(address debtCToken) public returns (uint256);
}

contract ICushionCErc20 is ICushion {
    function topup(address cToken, uint256 topupAmount) external;
}

contract ICushionCEther is ICushion {
    function topup() external payable;
}

// File: contracts/bprotocol/Registry.sol

pragma solidity 0.5.16;




/**
 * @dev Registry contract to maintain Compound, BProtocol and avatar address.
 */
contract Registry is Ownable {

    // Compound Contracts
    address public comptroller;
    address public comp;
    address public cEther;

    // BProtocol Contracts
    address public pool;
    address public score;
    address public compVoter; // this will not be used
    address public bComptroller;


    // Avatar
    address public avatarImpl;

    // Owner => Avatar
    mapping (address => address) public avatarOf;

    // Avatar => Owner
    mapping (address => address) public ownerOf;

    address[] public avatars;

    // An Avatar can have multiple Delegatee
    // Avatar => Delegatee => bool
    mapping (address => mapping(address => bool)) public delegate;

    // dummy caller, for safer delegate and execute
    DummyCaller public dummyCaller;

    // (target, 4 bytes) => boolean. For each target address and function call, can avatar call it?
    // this is to support upgradable features in compound
    // calls that allow user to change collateral and debt size, and enter/exit market should not be listed
    mapping (address => mapping(bytes4 => bool)) public whitelistedAvatarCalls;

    event NewAvatar(address indexed avatar, address owner);
    event Delegate(address indexed delegator, address avatar, address delegatee);
    event RevokeDelegate(address indexed delegator, address avatar, address delegatee);
    event NewPool(address oldPool, address newPool);
    event NewScore(address oldScore, address newScore);
    event AvatarCallWhitelisted(address target, bytes4 functionSig, bool whitelist);

    constructor(
        address _comptroller,
        address _comp,
        address _cEther,
        address _pool,
        address _bComptroller,
        address _compVoter,
        address _avatarImpl
    )
        public
    {
        comptroller = _comptroller;
        comp = _comp;
        cEther = _cEther;
        pool = _pool;
        bComptroller = _bComptroller;
        compVoter = _compVoter;

        avatarImpl = _avatarImpl;
        dummyCaller = new DummyCaller();
    }

    function setPool(address newPool) external onlyOwner {
        require(newPool != address(0), "Registry: pool-address-is-zero");
        address oldPool = pool;
        pool = newPool;
        emit NewPool(oldPool, newPool);
    }

    function setScore(address newScore) external onlyOwner {
        require(newScore != address(0), "Registry: score-address-is-zero");
        address oldScore = score;
        score = newScore;
        emit NewScore(oldScore, newScore);
    }

    function setWhitelistAvatarCall(address target, bytes4 functionSig, bool list) external onlyOwner {
        whitelistedAvatarCalls[target][functionSig] = list;
        emit AvatarCallWhitelisted(target, functionSig, list);
    }

    function newAvatar() external returns (address) {
        return _newAvatar(msg.sender);
    }

    function getAvatar(address _owner) public returns (address) {
        require(_owner != address(0), "Registry: owner-address-is-zero");
        address _avatar = avatarOf[_owner];
        if(_avatar == address(0)) {
            _avatar = _newAvatar(_owner);
        }
        return _avatar;
    }

    function delegateAvatar(address delegatee) public {
        require(delegatee != address(0), "Registry: delegatee-address-is-zero");
        address _avatar = avatarOf[msg.sender];
        require(_avatar != address(0), "Registry: avatar-not-found");

        delegate[_avatar][delegatee] = true;
        emit Delegate(msg.sender, _avatar, delegatee);
    }

    function revokeDelegateAvatar(address delegatee) public {
        address _avatar = avatarOf[msg.sender];
        require(_avatar != address(0), "Registry: avatar-not-found");
        require(delegate[_avatar][delegatee], "Registry: not-delegated");

        delegate[_avatar][delegatee] = false;
        emit RevokeDelegate(msg.sender, _avatar, delegatee);
    }

    function delegateAndExecuteOnce(address delegatee, address payable target, bytes calldata data) external payable {
        // make sure there is an avatar
        getAvatar(msg.sender);
        delegateAvatar(delegatee);
        dummyCaller.execute.value(msg.value)(target, data);
        revokeDelegateAvatar(delegatee);
    }

    function _newAvatar(address _owner) internal returns (address) {
        require(avatarOf[_owner] == address(0), "Registry: avatar-exits-for-owner");
        // _owner should not be an avatar address
        require(ownerOf[_owner] == address(0), "Registry: cannot-create-an-avatar-of-avatar");

        // Deploy GnosisSafeProxy with the Avatar contract as logic contract
        address _avatar = _deployAvatarProxy(_owner);
        // Initialize Avatar
        IAvatar(_avatar).initialize(address(this), comp, compVoter);

        avatarOf[_owner] = _avatar;
        ownerOf[_avatar] = _owner;
        avatars.push(_avatar);
        emit NewAvatar(_avatar, _owner);
        return _avatar;
    }

    function _deployAvatarProxy(address _owner) internal returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(_owner));
        bytes memory proxyCode = type(GnosisSafeProxy).creationCode;
        bytes memory deploymentData = abi.encodePacked(proxyCode, uint256(avatarImpl));

        assembly {
            proxy := create2(0, add(deploymentData, 0x20), mload(deploymentData), salt)
            if iszero(extcodesize(proxy)) { revert(0, 0) }
        }
    }

    function avatarLength() external view returns (uint256) {
        return avatars.length;
    }

    function avatarList() external view returns (address[] memory) {
        return avatars;
    }

    function doesAvatarExist(address _avatar) public view returns (bool) {
        return ownerOf[_avatar] != address(0);
    }

    function doesAvatarExistFor(address _owner) public view returns (bool) {
        return avatarOf[_owner] != address(0);
    }
}

contract DummyCaller {
    function execute(address target, bytes calldata data) external payable {
        (bool succ, bytes memory err) = target.call.value(msg.value)(data);
        require(succ, string(err));
    }
}