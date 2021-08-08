/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

// SPDX-License-Identifier: MIXED
//  _____ _          _   _____            
// |  __ (_)        | | |_   _|           
// | |__) |__  _____| |   | |  _ __   ___ 
// |  ___/ \ \/ / _ \ |   | | | '_ \ / __|
// | |   | |>  <  __/ |  _| |_| | | | (__ 
// |_|   |_/_/\_\___|_| |_____|_| |_|\___| on Ethereum!
//
// Flung together by BoringCrypto during COVID-19 lockdown in 2021
// Project started on Polygon for 2 weeks and this is the migrated to Ethereum version
// The canvas starts where it left off on Polygon (as well as PIXEL balances and ambassador program info)
// This version has a lot of gas optimizations vs the Polygon one

// WARNING: No audits were done on this code...

// Stay safe! 

// Get your alpha here https://bit.ly/3icxSru

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]
// License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// File @boringcrypto/boring-solidity/contracts/interfaces/[email protected]
// License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
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

// File @boringcrypto/boring-solidity/contracts/libraries/[email protected]
// License-Identifier: MIT
pragma solidity 0.6.12;

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while(i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }
    
    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    } 

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// File @boringcrypto/boring-solidity/contracts/[email protected]
// License-Identifier: MIT
pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// File @boringcrypto/boring-solidity/contracts/[email protected]
// License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity 0.6.12;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;    

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_SIGNATURE_HASH,
                chainId,
                address(this)
            )
        );
    }

    constructor() public {
        uint256 chainId; assembly {chainId := chainid()}
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        uint256 chainId; assembly {chainId := chainid()}
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest =
            keccak256(
                abi.encodePacked(
                    EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                    _domainSeparator(),
                    dataHash
                )
            );
    }
}

// File @boringcrypto/boring-solidity/contracts/[email protected]
// License-Identifier: MIT
pragma solidity 0.6.12;


// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}

// File contracts/Pixel.sol
//License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls

contract AddressList {
    address[] public addresses;
    function addressesCount() public view returns (uint256) { return addresses.length; }

    constructor() public {
        addresses.push(address(0));
    }

    function addAddresses(
        address[] calldata addresses_
    ) public {
        for (uint256 i = 0; i < addresses_.length; i++) { addresses.push(addresses_[i]); }
    }

    function getAddresses() public view returns (address[] memory) { return addresses; }
    function getAddressesRange(
        uint256 start,
        uint256 end
    ) public view returns (address[] memory) {
        address[] memory result = new address[](end - start);
        for (uint256 i = start; i < (end == 0 ? addresses.length : end); i++)
        {
            result[i - start] = addresses[i];
        }
        return result; 
    }
}

// Simple Multi Level Marketing contract with 3 tiers
contract MLM is AddressList {
    using BoringMath for uint256;

    struct RepInfo {
        uint32 upline;
        uint32 earnings1;
        uint32 earnings2;
        uint32 earnings3;
        uint16 tier1;
        uint16 tier2;
        uint16 tier3;
    }
    mapping (address => RepInfo) public mlm;

    event MLMAddRep(address rep, address upline);
    event MLMEarn(address rep, uint32 amount, uint8 lvl);

    function _set(address rep, uint32 upline_, uint32 earnings1, uint32 earnings2, uint32 earnings3, uint16 tier1, uint16 tier2, uint16 tier3) internal {
        mlm[rep] = RepInfo({
            upline: upline_,
            earnings1: earnings1,
            earnings2: earnings2,
            earnings3: earnings3,
            tier1: tier1,
            tier2: tier2,
            tier3: tier3
        });
    }

    function _mlm(address rep, uint32 upline_, uint32 earnings1, uint32 earnings2, uint32 earnings3) internal returns (address lvl1, address lvl2, address lvl3) {
        RepInfo memory info = mlm[rep];
        bool added;
        if (info.upline == 0) {
            if (upline_ != 0) {
                lvl1 = addresses[upline_];
                require(rep != lvl1, "MLM: Can't refer yourself");

                if (lvl1 != address(0)) {
                    info.upline = upline_;
                    mlm[rep] = info;
                    emit MLMAddRep(rep, lvl1);
                    added = true;
                }
            }
        } else {
            lvl1 = addresses[info.upline];
        }

        if (lvl1 != address(0)) {
            RepInfo memory info1 = mlm[lvl1];
            if (added) {
                info1.tier1++;
                info1.tier2 += info.tier1;
                info1.tier3 += info.tier2;
            }
            info1.earnings1 += earnings1;
            emit MLMEarn(lvl1, earnings1, 1);
            mlm[lvl1] = info1;
            if (info1.upline != 0) {
                lvl2 = addresses[info1.upline];
                RepInfo memory info2 = mlm[lvl2];
                if (added) {
                    info2.tier2++;
                    info2.tier3 += info.tier1;
                }
                info2.earnings2 += earnings2;
                emit MLMEarn(lvl2, earnings2, 2);
                mlm[lvl2] = info2;
                if (info2.upline != 0) {
                    lvl3 = addresses[info2.upline];
                    RepInfo memory info3 = mlm[lvl3];
                    if (added) {
                        info3.tier3++;
                    }
                    info3.earnings3 += earnings3;
                    emit MLMEarn(lvl3, earnings3, 3);
                    mlm[lvl3] = info3;
                }
            }
        }
    }
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract PixelV2 is ERC20WithSupply, BoringOwnable, MLM, ReentrancyGuard {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    event PixelBlockTransfer(address from, address to, uint256 pricePerPixel);

    string public constant symbol = "PIXEL";
    string public constant name = "Pixel";
    uint8 public constant decimals = 18;
    uint256 private constant START_BLOCK_PRICE = 5e15; // Price starts at 0.00005 ETH/pixel = 0.005 ETH/block
    uint256 public START_TIMESTAMP;
    uint256 public LOCK_TIMESTAMP;
    
    // Block info compressed into a single storage slot
    struct Block {
        uint32 owner; // current owner nr of the block
        uint32 url; // Data nr for url
        uint32 description; // Data nr for description
        uint32 pixels; // Data nr for pixels
        uint128 lastPrice; // last sale price - 0 = never sold
    }

    struct ExportBlock {
        address owner; // current owner of the block
        string url; // url for this block (should be < 256 characters)
        string description; // description for this block (should be < 256 characters)
        bytes pixels; // pixels as bytes
        uint128 lastPrice; // last sale price - 0 = never sold
        uint32 number;
    }

    struct ExportRawBlock {
        uint32 owner; // current owner nr of the block
        uint32 url; // Data nr for url
        uint32 description; // Data nr for description
        uint32 pixels; // Data nr for pixels
        uint128 lastPrice; // last sale price - 0 = never sold
        uint32 number;
    }

    // lookup tables
    bytes[] public data;
    string[] public text;

    function dataCount() public view returns (uint256) { return data.length; }
    function textCount() public view returns (uint256) { return text.length; }

    // data is organized in blocks of 10x10. There are 100x100 blocks. Base is 0 and counting goes left to right, then top to bottom.
    Block[10000] public blk;
    uint256[] public updates;

    constructor() public payable {
        // Set data[0] to blank
        text.push("");
        data.push(bytes(""));
    }

    modifier onlyCreationPhase() {
        require(block.timestamp >= START_TIMESTAMP && block.timestamp < LOCK_TIMESTAMP, "Not in creation phase");
        _;
    }

    function getBlocks(uint256[] calldata blockNumbers) public view returns (ExportBlock[] memory blocks) {
        blocks = new ExportBlock[](blockNumbers.length);
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            Block memory _blk = blk[blockNumbers[i]];
            blocks[i].number = blockNumbers[i].to32();
            blocks[i].owner = addresses[_blk.owner];
            blocks[i].url = text[_blk.url];
            blocks[i].description = text[_blk.description];
            blocks[i].pixels = data[_blk.pixels];
            blocks[i].lastPrice = _blk.lastPrice;
        }
    }

    function getRawBlocks(uint256[] calldata blockNumbers) public view returns (ExportRawBlock[] memory blocks) {
        blocks = new ExportRawBlock[](blockNumbers.length);
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            Block memory _blk = blk[blockNumbers[i]];
            blocks[i].number = blockNumbers[i].to32();
            blocks[i].owner = _blk.owner;
            blocks[i].url = _blk.url;
            blocks[i].description = _blk.description;
            blocks[i].pixels = _blk.pixels;
            blocks[i].lastPrice = _blk.lastPrice;
        }
    }

    function updatesCount() public view returns (uint256) {
        return updates.length;
    }

    function getUpdates(uint256 since, uint256 max) public view returns (uint256[] memory updatesSince) {
        uint256 length = updates.length - since;
        if (length > max) { 
            length = max; 
        }
        updatesSince = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            updatesSince[i] = updates[since + i];
        }
    }

    function addText(
        string[] calldata text_
    ) public {
        for (uint256 i = 0; i < text_.length; i++) { text.push(text_[i]); }
    }

    function addData(
        bytes[] calldata data_
    ) public {
        for (uint256 i = 0; i < data_.length; i++) { data.push(data_[i]); }
    }

    function getText() public view returns (string[] memory) { return text; }
    function getTextRange(
        uint256 start,
        uint256 end
    ) public view returns (string[] memory) {
        string[] memory result = new string[](end - start);
        for (uint256 i = start; i < (end == 0 ? text.length : end); i++)
        {
            result[i - start] = text[i];
        }
        return result; 
    }

    function getDataRange(
        uint256 start,
        uint256 end
    ) public view returns (bytes[] memory) {
        bytes[] memory result = new bytes[](end - start);
        for (uint256 i = start; i < (end == 0 ? data.length : end); i++)
        {
            result[i - start] = data[i];
        }
        return result; 
    }

    function mint(address[] calldata to, uint256[] calldata amount) public onlyOwner {
        require(START_TIMESTAMP == 0, "Initialization finished");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], amount[i]);
        }
    }

    function initMLM(
        address[] memory reps,
        uint32[] memory upline,
        uint32[] memory earn1,
        uint32[] memory earn2,
        uint32[] memory earn3,
        uint16[] memory tier1,
        uint16[] memory tier2,
        uint16[] memory tier3
    ) public onlyOwner {
        require(START_TIMESTAMP == 0, "Initialization finished");
        for (uint256 i = 0; i < reps.length; i++) {
            _set(reps[i], upline[i], earn1[i], earn2[i], earn3[i], tier1[i], tier2[i], tier3[i]);
        }
    }

    function initBlocks(
        uint256[] calldata blockNumbers,
        uint128[] calldata lastPrice,
        uint32[] calldata ownerNr,
        uint32[] calldata urlNr,
        uint32[] calldata descriptionNr,
        uint32[] calldata pixelsNr
    ) public onlyOwner {
        require(START_TIMESTAMP == 0, "Initialization finished");

        for (uint256 i = 0; i < blockNumbers.length; i++) {
            uint256 blockNumber = blockNumbers[i];

            blk[blockNumber] = Block({
                owner: ownerNr[i],
                url: urlNr[i],
                description: descriptionNr[i],
                pixels: pixelsNr[i],
                lastPrice: lastPrice[i]
            });
        }
    }

    function finishInit() public onlyOwner {
        START_TIMESTAMP = block.timestamp + 2 hours;
        LOCK_TIMESTAMP = block.timestamp + 14 days + 2 hours;
        updates.push(10000); // Update of 10000 means: update all blocks from 0 to 9999
    }

    function _setBlock(
        uint256 blockNumber,
        uint32 ownerNr,
        uint32 urlNr,
        uint32 descriptionNr,
        uint32 pixelsNr
    ) private returns(uint256 blockCost) {
        require(pixelsNr < data.length, "Wrong pixelNr");

        Block memory block_ = blk[blockNumber];
        // Forward a maximum of 20000 gas to the previous owner for accepting the refund to avoid griefing attacks
        bool success;
        address previousOwner = addresses[block_.owner];
        uint256 lastPrice = block_.lastPrice;
        (success, ) = previousOwner.call{value: lastPrice, gas: 20000}("");

        blockCost = lastPrice == 0 ? START_BLOCK_PRICE : lastPrice.mul(2);

        block_.owner = ownerNr;
        block_.url = urlNr;
        block_.description = descriptionNr;
        block_.lastPrice = blockCost.to128();
        block_.pixels = pixelsNr;
        blk[blockNumber] = block_;

        updates.push(blockNumber);

        emit PixelBlockTransfer(previousOwner, addresses[ownerNr], blockCost);
    }

    function setBlocks(
        address owner,
        uint32 ownerNr,

        string memory url,
        uint32 urlNr,

        string memory description,
        uint32 descriptionNr,

        uint256[] memory blockNumbers,
        bytes[] memory pixels,
        // Positive numbers refer to existing data. Negative numbers refer to the index in the passed in pixels array
        int32[] memory pixelsNr,
        address referrer,
        uint32 referrerNr
    ) public payable onlyCreationPhase() nonReentrant() {
        if (ownerNr == uint32(-1)) {
            ownerNr = addresses.length.to32();
            addresses.push(owner);
        }
        require(ownerNr < addresses.length, "Wrong owner");

        if (urlNr == uint32(-1)) {
            urlNr = text.length.to32();
            text.push(url);
        }
        require(urlNr < text.length, "Wrong url");

        if (descriptionNr == uint32(-1)) {
            descriptionNr = text.length.to32();
            text.push(description);
        }
        require(descriptionNr < text.length, "Wrong description");

        if (referrerNr == uint32(-1)) {
            referrerNr = addresses.length.to32();
            addresses.push(referrer);
        }
        require(referrerNr < addresses.length, "Wrong referrer");

        uint256 startPixelNr = data.length;
        for (uint256 i = 0; i < pixels.length; i++) { data.push(pixels[i]); }

        uint256 cost;
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            cost = cost.add(_setBlock(blockNumbers[i], ownerNr, urlNr, descriptionNr, (pixelsNr[i] >=0 ? uint256(pixelsNr[i]) : startPixelNr + uint256(-1-pixelsNr[i])).to32()));
        }

        require(msg.value == cost, "Pixel: not enough funds");

        // Mint a PIXEL token for each pixel bought
        uint256 blocks = blockNumbers.length;
        (address lvl1, address lvl2, address lvl3) = _mlm(msg.sender, referrerNr, blocks.mul(20).to32(), blocks.mul(10).to32(), blocks.mul(5).to32());

        _mint(msg.sender, blocks.mul(100e18));
        if (lvl1 != address(0)) { _mint(lvl1, blocks.mul(20e18)); }
        if (lvl2 != address(0)) { _mint(lvl2, blocks.mul(10e18)); }
        if (lvl3 != address(0)) { _mint(lvl3, blocks.mul(5e18)); }
    }

    function getCost(uint256 blockNumber) public view returns (uint256 cost) {
        uint256 last = blk[blockNumber].lastPrice;
        cost = last == 0 ? START_BLOCK_PRICE : last.mul(2);
    }

    function getCost(uint256[] calldata blockNumbers) public view returns (uint256 cost) {
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            cost = cost.add(getCost(blockNumbers[i]));
        }
    }

    function withdraw(IERC20 token) public onlyOwner {
        if (token != IERC20(0)) {
            // Withdraw any accidental token deposits
            token.safeTransfer(owner, token.balanceOf(address(this)));
        } else {
            bool success;
            (success, ) = owner.call{value: address(this).balance}("");
        }
    }

    function poll(address user) public view returns (uint256 updates_, uint256 addresses_, uint256 text_, uint256 data_, uint256 balance, uint256 supply, RepInfo memory mlm_, address upline_) {
        updates_ = updates.length;
        addresses_ = addresses.length;
        text_ = text.length;
        data_ = data.length;
        balance = balanceOf[user];
        supply = totalSupply;
        mlm_ = mlm[user];
        upline_ = addresses[mlm[user].upline];
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}