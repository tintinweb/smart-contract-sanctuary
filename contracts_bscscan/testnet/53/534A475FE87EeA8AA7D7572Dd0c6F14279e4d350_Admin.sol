pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@openzeppelin/contracts/proxy/Clones.sol';
import './interfaces/IAdmin.sol';
import "./LithiumAdmin.sol";

contract Admin is LithiumAdmin, IAdmin {
    address[] public tokenSales;

    address public masterTokenSale;
    address public stakingContract;
    address public override forAirdrop;
    mapping (address => bool) public override tokenSalesM;

    event CreateTokenSale (address instanceAddress);
    event SetAirdrop(address airdrop);

    constructor () {}


    function setMasterContract(address _address) override external {
        require(isMaintainer(msg.sender));
        require(_address != address(0), 'address == address(0)');
        require(masterTokenSale != _address, 'addresses match');
        masterTokenSale = _address;
        //TODO: event? 
    }

    function setAirdrop(address _address) external override{
        require(isMaintainer(msg.sender));
        require(_address != address(0), 'address == address(0)');
        forAirdrop = _address;
        emit SetAirdrop(_address);
    }

    function setStakingContract(address _address) external override {
        require(isMaintainer(msg.sender));
        require(_address != address(0), 'address == address(0)');
        stakingContract = _address;
    }

    function getTokenSales() external view override returns (address[] memory) {
        return tokenSales;
    }

    function createPool(ITokenSale.Params calldata _params) external override {
        require(isMaintainer(msg.sender));
         require(
            _params.totalSaleSupply > 0,
            "Token supply for sale should be greater then 0"
        );
        require(
            _params.privatePoolSaleEndTime > _params.privatePoolSaleStartTime,
            "End time should be greater then start time"
        );
        require(
            _params.publicPoolSaleStartTime > _params.privatePoolSaleStartTime,
            "Public round should start after private round"
        );
        require(
            _params.publicPoolSaleEndTime > _params.publicPoolSaleStartTime,
            "End time should be greater then start time"
        );
        // require(
        //     _params.democracyHourEndTimestamp == _params.privatePoolSaleStartTime + 1 hours,
        //     'democracy hour != private end + hour'
        // );
        require(
            _params.initialAddress != address(0) && _params.token != address(0),
            'initialAddress || token == 0'
        );

        address instance = Clones.clone(masterTokenSale);
        ITokenSale(instance).initialize(_params, stakingContract, address(this));
        tokenSales.push(instance);
        tokenSalesM[instance] = true;
        emit CreateTokenSale(instance);
        IERC20(_params.token).transferFrom(_params.initialAddress, instance, _params.totalSaleSupply);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

import './ITokenSale.sol';

interface IAdmin {
    function forAirdrop() external returns(address);
    function tokenSalesM(address) external returns(bool);
    function setMasterContract(address) external;
    function setAirdrop(address _newAddress) external;
    function setStakingContract(address) external;
    function createPool(ITokenSale.Params calldata _params) external;
    function getTokenSales() external view returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract LithiumAdmin {
    mapping(address => bool) private maintainers;
    address[] private maintainersList;
    
    constructor() public {
        maintainers[msg.sender] = true;
        maintainersList.push(msg.sender);
    }
    
    function addMaintainer(address candidate) public {
        require(maintainers[msg.sender], "Only maintainers can add candidates, or vote for candidates");
        require(!maintainers[candidate], "Candidate already is maintainer");
        maintainers[candidate] = true;
        maintainersList.push(candidate);
    }
    
    function removeMaintainer(address maintainer) public {
        require(maintainers[msg.sender], "Only maintainers can remove maintainers");
        require(maintainers[maintainer], "Address owner is not a maintainer");
        uint i = 0;
        while(maintainersList[i] != maintainer || i < maintainersList.length) {
            i++;
        }
        if(maintainersList[i] == maintainer) {
            maintainers[maintainer] = false;
            if(i < maintainersList.length - 1) {
                maintainersList[i] = maintainersList[maintainersList.length - 1];
            }
            maintainersList.pop();
        }
    }
    
    function isMaintainer(address maintainer) public view returns(bool) {
        return maintainers[maintainer] == true;
    }
    
    function getMaintainers() public view returns(address[] memory) {
        require(maintainers[msg.sender], "Only maintainers can query maintainers list");
        return maintainersList;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

interface ITokenSale {
    struct Params {
        address initialAddress;
        address token;
        uint256 totalSaleSupply;
        uint256 privatePoolSaleStartTime;
        uint256 privatePoolSaleEndTime;
        uint256 publicPoolSaleStartTime;
        uint256 publicPoolSaleEndTime;
        uint256 privatePoolTokenPrice;
        uint256 publicPoolTokenPrice;
        uint256 democracyHourEndTimestamp;
        uint256 publicRoundBuyLimit;
        uint256 escrowPercentage;
        uint256[3] tierPrices; //TODO: MUST BE 10 ** 8 like chainlink
        uint256[2][] escrowReturnMilestones;
        uint256 thresholdPublicAmount;
    }
    function initialize(Params memory, address, address) external;
    function claim() external;
    function addToBlackList(address[] memory) external;
    function takeLeftovers() external;
    function takeAirdrop() external;
}

