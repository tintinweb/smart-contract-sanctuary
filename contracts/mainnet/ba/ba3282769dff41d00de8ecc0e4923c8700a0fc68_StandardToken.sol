/**
 *Submitted for verification at Etherscan.io on 2020-11-19
*/

// Sources flattened with hardhat v2.0.3 https://hardhat.org

// File contracts/Library/SafeMath.sol

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.6.0;

library SafeMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "Math/Add-Overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "Math/Sub-Overflow");
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || ((z = x * y) / y) == x, "Math/Mul-Overflow");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y > 0, "Math/Div-Overflow");
        z = x / y;
    }

    function mod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y != 0, "Math/Mod-Overflow");
        z = x % y;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function toWAD(uint256 wad, uint256 decimal)
        internal
        pure
        returns (uint256 z)
    {
        require(decimal < 18, "Math/Too-high-decimal");
        z = mul(wad, 10**(18 - decimal));
    }
}


// File contracts/Library/Address.sol

pragma solidity ^0.6.0;

library Address {
    function isContract(address target) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            result := gt(extcodesize(target), 0)
        }
    }
}


// File contracts/Interface/IERC173.sol

pragma solidity ^0.6.0;

/// @title ERC-173 Contract Ownership Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @param newOwner The address of the new owner of the contract
    function transferOwnership(address newOwner) external;
}


// File contracts/Library/Authority.sol

pragma solidity ^0.6.0;

contract Authority is IERC173 {
    address private _owner;

    modifier onlyAuthority() {
        require(_owner == msg.sender, "Authority/Not-Authorized");
        _;
    }

    function owner() external override view returns (address) {
        return _owner;
    }

    function initialize(address newOwner) internal {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

    function transferOwnership(address newOwner)
        external
        override
        onlyAuthority
    {
        _owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}


// File contracts/Interface/IERC20.sol

pragma solidity ^0.6.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address target) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}


// File contracts/Interface/IERC165.sol

pragma solidity ^0.6.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID)
        external
        view
        returns (bool);
}


// File contracts/Interface/IERC2612.sol

pragma solidity ^0.6.0;


interface IERC2612 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File contracts/Interface/Iinitialize.sol

pragma solidity ^0.6.0;

interface Iinitialize {
    function initialize(
        string calldata contractVersion,
        string calldata tokenName,
        string calldata tokenSymbol,
        uint8 tokenDecimals
    ) external;
}


// File contracts/abstract/ERC20.sol

pragma solidity ^0.6.0;

abstract contract AbstractERC20 {
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual;

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual;
}


// File contracts/abstract/ERC2612.sol

pragma solidity ^0.6.0;

/**
 * @title Permit
 * @notice An alternative to approveWithAuthorization, provided for
 * compatibility with the draft EIP2612 proposed by Uniswap.
 * @dev Differences:
 * - Uses sequential nonce, which restricts transaction submission to one at a
 *   time, or else it will revert
 * - Has deadline (= validBefore - 1) but does not have validAfter
 * - Doesn't have a way to change allowance atomically to prevent ERC20 multiple
 *   withdrawal attacks
 */
abstract contract AbstractERC2612 is AbstractERC20 {
    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    bytes32 public DOMAIN_SEPARATOR;

    string private _version;

    mapping(address => uint256) public nonces;

    function version() external view returns (string memory) {
        return _version;
    }

    /**
     * @notice Initialize EIP712 Domain Separator
     * @param version     version of contract
     * @param name        name of contract
     */
    function _initDomainSeparator(string memory version, string memory name)
        internal
    {
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        _version = version;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(name)), // name
                keccak256(bytes(version)), // version
                chainId, // chainid
                address(this) // this address
            )
        );
    }

    /**
     * @notice Verify a signed approval permit and execute if valid
     * @param owner     Token owner's address (Authorizer)
     * @param spender   Spender's address
     * @param value     Amount of allowance
     * @param deadline  The time at which this expires (unix time)
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     */
    function _permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(owner != address(0), "ERC2612/Invalid-address-0");
        require(deadline >= now, "ERC2612/Expired-time");

        // @TODO: Gas Testing
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );

        // bytes memory digest = abi.encode(
        //     PERMIT_TYPEHASH,
        //     owner,
        //     spender,
        //     value,
        //     nonces[owner]++,
        //     deadline
        // );

        address recovered = ecrecover(digest, v, r, s);
        require(
            recovered != address(0) && recovered == owner,
            "ERC2612/Invalid-Signature"
        );

        _approve(owner, spender, value);
    }
}


// File contracts/StandardToken.sol

pragma solidity ^0.6.0;









contract StandardToken is
    Authority,
    AbstractERC2612,
    IERC2612,
    IERC165,
    IERC20
{
    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory contractVersion,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 tokenDecimals
    ) public {
        Authority.initialize(msg.sender);
        _initDomainSeparator(contractVersion, tokenName);

        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function balanceOf(address target)
        external
        view
        override
        returns (uint256)
    {
        return _balances[target];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(
            value,
            "ERC20/Not-Enough-Allowance"
        );
        _transfer(from, to, value);
        return true;
    }

    function mint(uint256 value) external onlyAuthority returns (bool) {
        _totalSupply = _totalSupply.add(value);
        _balances[msg.sender] = _balances[msg.sender].add(value);
        emit Transfer(address(0), msg.sender, value);
        return true;
    }

    function burn(uint256 value) external onlyAuthority returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(
            value,
            "ERC20/Not-Enough-Balance"
        );
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(msg.sender, address(0), value);
        return true;
    }

    /**
     * @notice Update allowance with a signed permit
     * @param owner       Token owner's address (Authorizer)
     * @param spender     Spender's address
     * @param value       Amount of allowance
     * @param deadline    Expiration time, seconds since the epoch
     * @param v           v of the signature
     * @param r           r of the signature
     * @param s           s of the signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        _permit(owner, spender, value, deadline, v, r, s);
    }

    function supportsInterface(bytes4 interfaceID)
        external
        view
        override
        returns (bool)
    {
        return
            interfaceID == type(IERC20).interfaceId || // ERC20
            interfaceID == type(IERC165).interfaceId || // ERC165
            interfaceID == type(IERC173).interfaceId || // ERC173
            interfaceID == type(IERC2612).interfaceId ||
            interfaceID == type(Iinitialize).interfaceId; // ERC2612
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(to != address(this), "ERC20/Not-Allowed-Transfer");
        _balances[from] = _balances[from].sub(
            value,
            "ERC20/Not-Enough-Balance"
        );
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal override {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}