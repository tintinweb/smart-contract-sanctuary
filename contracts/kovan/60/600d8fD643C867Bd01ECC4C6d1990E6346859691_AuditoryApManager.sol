// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IAuditoryAssetPool.sol";
import "./AuditoryAssetPool.sol";

contract AuditoryApManager {
    address[] public allAssetPools;

    mapping(address => AssetPoolInfo[]) public artistWithAps;

    event AssetPoolCreated(
        address artist,
        address assetPool,
        uint256 bondValue
    );

    struct AssetPoolInfo {
        address apAddress;
        uint256 bondValue;
    }

    function allAssetPoolsLength() external view returns (uint256) {
        return allAssetPools.length;
    }

    function getArtistAps() external view returns (AssetPoolInfo[] memory) {
        address _artist = address(msg.sender);
        return artistWithAps[_artist];
    }

    function createAssetPool(uint256 _bondValue) external {
        require(_bondValue > 0, "Value of the bond cannot be 0");
        address _artist = address(msg.sender);
        address apAddress;
        AssetPoolInfo[] memory existingAps = artistWithAps[_artist];
        uint256 artistApsLength = existingAps.length;
        //  Deploy Asset pool for the artist
        bytes memory bytecode = type(AuditoryAssetPool).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(_artist, artistApsLength));
        assembly {
            apAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //  Set bond value to the created Asset pool for the artist
        IAuditoryAssetPool(apAddress).initialize(_artist, _bondValue);

        artistWithAps[_artist].push(AssetPoolInfo(apAddress, _bondValue));
        allAssetPools.push(apAddress);
        emit AssetPoolCreated(_artist, apAddress, _bondValue);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AuditoryAssetPool {
    constructor() {
        manager = msg.sender;
    }

    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    address public manager;
    address public artist;
    uint256 public bondValue;
    mapping(address => uint256) public balanceOf;

    receive() external payable {}

    // called once by the manager at time of deployment
    function initialize(address _artist, uint256 _bondValue) external {
        require(msg.sender == manager, "AuditoryAssetPool: FORBIDDEN"); // sufficient check
        artist = _artist;
        bondValue = _bondValue;
    }

    function deposit(address _sender, uint256 _amount) external {
        balanceOf[_sender] += _amount;
        emit Deposit(_sender, _amount);
    }

    function withdraw(
        address _recipient,
        uint256 _amount,
        address _token
    ) external {
        require(balanceOf[_recipient] >= _amount, "user: INSUFFICIENT BALANCE");
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(address(this), _recipient, _amount);
        balanceOf[_recipient] -= _amount;
        emit Withdrawal(_recipient, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAuditoryAssetPool {
    function deposit(address sender, uint256 amount) external;

    function withdraw(
        address recipient,
        uint256 amount,
        address token
    ) external;

    function initialize(address artist, uint256 bondValue) external;
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

