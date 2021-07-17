/**
 *Submitted for verification at polygonscan.com on 2021-07-16
*/

// SPDX-License-Identifier: MIXED

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
//  _____ _          _   _____            
// |  __ (_)        | | |_   _|           
// | |__) |__  _____| |   | |  _ __   ___ 
// |  ___/ \ \/ / _ \ |   | | | '_ \ / __|
// | |   | |>  <  __/ |  _| |_| | | | (__ 
// |_|   |_/_/\_\___|_| |_____|_| |_|\___|
//
// Flung together by BoringCrypto during COVID-19 lockdown in 2021
// Stay safe! 

// Alpha here https://bit.ly/3icxSru

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;




interface ISushiSwapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ISushiSwapRouter {
    function WETH() external pure returns (address);
    function factory() external pure returns (ISushiSwapFactory);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// solhint-disable avoid-low-level-calls
// solhint-disable

interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

contract Canvas {
    using BoringMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event Buy(address hodler, address buyer, uint256 price, uint256 hodler_share);

    string public constant name = "The Canvas of Pixels";
    string public constant symbol = "CANVAS";

    address public hodler;
    address public allowed;

    uint256 public price;
    IERC20 public immutable pixel;
    string public info;

    mapping(address => mapping(address => bool)) public operators;

    constructor(IERC20 _pixel) public {
        pixel = _pixel;
        price = _pixel.totalSupply() / 10;
        hodler = address(_pixel);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // EIP-165
            interfaceID == 0x80ac58cd; // EIP-721
    }

    function tokenURI(uint256 _tokenId) public pure returns (string memory) {
        require(_tokenId == 0, "Invalid token ID");
        return "https://pixel.inc/canvas.json";
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "No zero address");
        return _owner == hodler ? 1 : 0;
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_tokenId == 0, "Invalid token ID");
        require(hodler != address(0), "No owner");
        return hodler;
    }

    function _transfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal {
        require(_tokenId == 0, "Invalid token ID");
        require(from == hodler, "From not owner");
        require(from == msg.sender || from == allowed || operators[hodler][from], "Transfer not allowed");
        require(to != address(0), "No zero address");
        hodler = to;
        allowed = address(0);
        emit Transfer(from, to, _tokenId);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public payable {
        _transfer(_from, _to, _tokenId);
        if (isContract(_to)) {
            require(
                ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) ==
                    bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),
                "Wrong return value"
            );
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public payable {
        require(_tokenId == 0, "Invalid token ID");
        require(msg.sender == hodler, "Not hodler");
        allowed = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_tokenId == 0, "Invalid token ID");
        return allowed;
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operators[_owner][_operator];
    }

    function totalSupply() external pure returns (uint256) {
        return 1;
    }

    function buy() external payable {
        require(msg.value == price, "Value != price");

        // Send original price paid + 10% back to the hodler with max 20.000 gas. If this fails, continue anyway to prevent grieving/blocking attacks.
        uint256 hodler_share = hodler == address(pixel) ? 0 : price.mul(110) / 150;
        (bool success, ) = hodler.call{value: hodler_share, gas: 20000}("");

        // Send the remaining funds to the PIXEL token hodlers.
        (success, ) = address(pixel).call{value: price.sub(hodler_share), gas: 20000}("");
        require(success, "Funding pixel pool failed");

        emit Transfer(hodler, msg.sender, 0);
        emit Buy(hodler, msg.sender, price, hodler_share);

        price = price.mul(150) / 100; // Increase price by 50%
        hodler = msg.sender;
        allowed = address(0);
    }

    function setInfo(string memory info_) external {
        require(msg.sender == hodler, "Canvas: not hodler");
        info = info_;
    }

    function poll() public view returns(address hodler_, address allowed_, uint256 price_) {
        hodler_ = hodler;
        allowed_ = allowed;
        price_ = price;
    }
}

// Simple Multi Level Marketing contract with 3 tiers
contract MLM {
    struct DownlineStats {
        uint128 earnings1;
        uint128 earnings2;
        uint128 earnings3;
        uint32 tier1;
        uint32 tier2;
        uint32 tier3;
    }
    mapping (address => address) public upline;
    mapping (address => DownlineStats) public downline;

    event MLMAddRep(address rep, address upline);
    event MLMEarn(address rep, uint128 amount, uint8 lvl);

    function _setUpline(address rep, address upline_) internal {
        upline[rep] = upline_;
    }

    function _setDownline(address rep, uint128 earnings1, uint128 earnings2, uint128 earnings3, uint32 tier1, uint32 tier2, uint32 tier3) internal {
        downline[rep] = DownlineStats({
            earnings1: earnings1,
            earnings2: earnings2,
            earnings3: earnings3,
            tier1: tier1,
            tier2: tier2,
            tier3: tier3
        });
    }

    function _addRep(address rep, address upline_) internal {
        if (upline_ == address(0) || upline[rep] != address(0)) { return; }
        require(rep != upline_, "MLM: Can't refer yourself");
        upline[rep] = upline_;
        (address lvl1, address lvl2, address lvl3) = _getUpline(rep);
        if (lvl1 != address(0)) { downline[lvl1].tier1++; downline[lvl1].tier2 += downline[rep].tier1; downline[lvl1].tier2 += downline[rep].tier3; }
        if (lvl2 != address(0)) { downline[lvl2].tier2++; downline[lvl2].tier2 += downline[rep].tier3; }
        if (lvl3 != address(0)) { downline[lvl3].tier3++; }
        emit MLMAddRep(rep, upline_);
    }

    function _getUpline(address rep) internal view returns (address lvl1, address lvl2, address lvl3) {
        lvl1 = upline[rep];
        if (lvl1 != address(0)) {
            lvl2 = upline[lvl1];
            if (lvl2 != address(0)) {
                lvl3 = upline[lvl2];
            }
        }
    }

    function _recordEarnings(address lvl1, address lvl2, address lvl3, uint128 earnings1, uint128 earnings2, uint128 earnings3) internal {
        if (lvl1 != address(0)) {
            downline[lvl1].earnings1 += earnings1;
            emit MLMEarn(lvl1, earnings1, 1);
        }
        if (lvl2 != address(0)) {
            downline[lvl2].earnings2 += earnings2;
            emit MLMEarn(lvl2, earnings1, 2);
        }
        if (lvl3 != address(0)) {
            downline[lvl3].earnings3 += earnings3;
            emit MLMEarn(lvl3, earnings1, 3);
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

contract PixelV2 is ERC20WithSupply, MLM, BoringOwnable, ReentrancyGuard {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;

    event PixelBlockTransfer(address from, address to, uint256 pricePerPixel);

    string public constant symbol = "PIXEL";
    string public constant name = "Pixel";
    uint8 public constant decimals = 18;
    address public canvas;

    uint256 private constant START_BLOCK_PRICE = 10e18; // Price starts at 0.1 MATIC/pixel = 10 MATIC/block
    
    // 50.000 PIXEL tokens will be minted for the initial AMM pool
    // To keep this fair, we set the price at DOUBLE the cost (because the PIXEL tokens are free to the deployer)
    // Cost of 1 PIXEL token at launch will be 0.1 MATIC / 1.4 (due to ambassador program) = 0.0714
    // So price should be set at twice that: 0.1428
    // For 50,000 PIXELs = 50,000 * 0.1428 ≈ 7000 (rounded down to the nearest thousand)
    uint256 private constant SUSHI_PIXEL_BALANCE = 50000e18;
    // uint256 private constant SUSHI_MATIC_BALANCE = 7000e18;
    // Will be added manually to SushiSwap, ran out of time to put it in the contract

    struct BlockLink {
        string url; // url for this block (should be < 256 characters)
        string description; // description for this block (should be < 256 characters)
    }

    struct Block {
        address owner; // current owner of the block
        uint128 lastPrice; // last sale price - 0 = never sold
        uint32 link; // The BlockLink for this block
        bytes pixels; // pixels as bytes
    }

    struct ExportBlock {
        uint32 number;
        address owner; // current owner of the block
        uint128 lastPrice; // last sale price - 0 = never sold
        string url; // url for this block (should be < 256 characters)
        string description; // description for this block (should be < 256 characters)
        bytes pixels; // pixels as bytes
    }

    BlockLink[] public link;
    // data is organized in blocks of 10x10. There are 100x100 blocks. Base is 0 and counting goes left to right, then top to bottom.
    Block[10000] public blk;
    uint256 public constant START_TIMESTAMP = 1626368400;
    uint256 public constant LOCK_TIMESTAMP = START_TIMESTAMP + 2 weeks;
    uint256[] public updates;

    constructor() public payable {
        // Set link[0] to blank
        link.push(BlockLink({
            url: "",
            description: ""
        }));

        // Balances that were in SushiSwap LP to restore in wallet
        // MATIC - PIXEL
        _mint(0x1EF5526ee1A6D8c596cce90e774A2c41372cC8cD, 2100910959916803821587);
        _mint(0x4ef416AA741053b5F3968900379DF2e3d0229065, 828212788936684322556);
        _mint(0x2B23D9B02FffA1F5441Ef951B4B95c09faa57EBA, 77234571546476346077);
        // WETH - PIXEL
        _mint(0x8f54C8c2df62c94772ac14CcFc85603742976312, 6725081405432150000);
        
        // On-chain token balances to be restored
        _mint(0x000000000000000000000000000000000000dEaD, 100000000000000000000);
        _mint(0x00A5af2D7DA07dF76073A6f478f0fB4942D2659a, 76993000000000000000000);
        _mint(0x00e13f97e1980126cbe90F21B9C1b853878031Dd, 100000000000000000000);
        _mint(0x012550D59aE4E7938830fA13C5D5791752ADc4a5, 100000000000000000000);
        _mint(0x01485557C2BC6E26c7187ff4cC38d5d9474405D4, 600000000000000000000);
        _mint(0x01C2bF2F59215A1AcAe7B485aa82A582d31fD613, 100000000000000000000);
        _mint(0x05F0BA0f63b401BC9B86089265Cee2f79c955768, 100000000000000000000);
        _mint(0x0655E4DEAA64b4C6da6b68Db283934a15d9AfC8D, 1000000000000000000);
        _mint(0x069e85D4F1010DD961897dC8C095FBB5FF297434, 400000000000000000000);
        _mint(0x070Ae2385DEdC927f821e75434E881cA5FD549fb, 2500000000000000000000);
        _mint(0x092471cfFe4B941C896bfeC001fe8Bcc73a991D9, 20000000000000000000);
        _mint(0x0b981d98e857C888E00D2C494D24DC16a12F8f3A, 2500000000000000000000);
        _mint(0x0D35324061F620f66AF983Dee02076B2E45E57fc, 1000000000000000000);
        _mint(0x0f278c56b52B4C0E2a69b30A0b591d237C783907, 7410838942006850000000);
        _mint(0x1200b4a3A90dCDc504443130572e840c988eC13C, 4700000000000000000000);
        _mint(0x157B6c44f47ecD30c0A2c428a6f35DBC606Aa81b, 97686009836727800000);
        _mint(0x1F427A6FCdb95A7393C58552093e10A932890FA8, 200000000000000000000);
        _mint(0x201b5Abfd44A8F9b75F0fE1BaE74CDaC7675E54B, 15700000000000000000000);
        _mint(0x206971261B391763458134212FeEab2360874676, 108905833669697000000);
        _mint(0x218d75b17f491793a96ab4326c7875950359a80C, 900000000000000000000);
        _mint(0x22D16ED158722107F9B22B7346A65E193717c9e8, 1600000000000000000000);
        _mint(0x235B5aC21eE516410300DeC89F9ed413cB5d948C, 1500000000000000000000);
        _mint(0x2493C86B62E8ff26208399144817EF2898c59460, 12000000000000000000000);
        _mint(0x251794fb2875c1f735c2983Af79BDeA28A81309b, 510349509928504000000);
        _mint(0x256D49d87cbb877D26E2Bcf2bF0A40D26bdfB5d4, 7540000000000000000000);
        _mint(0x25C89a394E37268c33628BD3cC54908B5F8D1Bd5, 34600000000000000000000);
        _mint(0x27883c6bD1AEd855D020fA587ae6D841Adf0391D, 49070792707637400000);
        _mint(0x28c24f2Da9B6E517968300Eb1A4F4aE1B235238E, 220000000000000000000);
        _mint(0x29a4ea26AC9eEd2fBdCd649CFd707948B18F4c67, 800000000000000000000);
        _mint(0x2B19fDE5d7377b48BE50a5D0A78398a496e8B15C, 135100000000000000000000);
        _mint(0x30a0911731f6eC80c87C4b99f27c254639A3Abcd, 83071433783691100000000);
        _mint(0x315388deb1608BDcF532CE0BF6fC130542f5132C, 1600000000000000000000);
        _mint(0x357dfdC34F93388059D2eb09996d80F233037cBa, 8100000000000000000000);
        _mint(0x36568Dd8A7C4B33cb21Bdfe595329133deFDf7c4, 805596835216419000);
        _mint(0x3c0a3d1994C567Fd4BF17dc5858eC84fF1F87501, 900000000000000000000);
        _mint(0x3c5Aac016EF2F178e8699D6208796A2D67557fe2, 20000000000000000000);
        _mint(0x3D343914EB418F465401e617a19CC9dd072922E7, 400000000000000000000);
        _mint(0x3D9B0A7ef1CcEAda457001A6d51F28FF61E39904, 855000000000000000000);
        _mint(0x404e35fDB39AFdb77d8eA5b63bEcd6a5Ad50A6dE, 5000000000000000000000);
        _mint(0x41381649B2231caFc8293F501Bb3dF422aeBA5E4, 1800000000000000000000);
        _mint(0x43d20d5efA78Ff0e465DDa2e58109F9fb3A2becE, 100000000000000000000);
        _mint(0x4757b9DFC3b8b685Dd227B0b4104B1Ca762f18b0, 200000000000000000000);
        _mint(0x496ea957960Bf9A2BBC1D3c114EaA124e07D0543, 4587762750670830000000);
        _mint(0x4cb1a8Bb524Ec318AAad1c63cA51b2189Df00560, 1000000000000000000);
        _mint(0x4fD95c6FA765e64eC9313E465F4D2B88Cbf8dEaa, 1100000000000000000000);
        _mint(0x528d4e4E0dbF071eC23013f06D8487BaD5A8a68B, 4400000000000000000000);
        _mint(0x53033C9697339942256845dD4d428085eC7261B8, 100000000000000000000);
        _mint(0x54D925F320400139f9F2925767F1ec68B027e7C0, 3624011874909200000000);
        _mint(0x57d9b1E86A1f4a0b76bec742f8e9E6F70650E6B0, 6708775655099830000000);
        _mint(0x58a5D0D2D5CDa76806f48A3b255D2b0238F965c5, 800000000000000000000);
        _mint(0x592F1a037EB4CBE529E80CA0f855525e13993380, 100000000000000000000);
        _mint(0x5b52bF12e7D8737ED61f06147fc655514679Ce72, 1000000000000000000);
        _mint(0x5b7dCB8Ce882f3D4C953C9F9d79E08730EFe4939, 3285265451149960000000);
        _mint(0x5bA8bE640c84e294BD7285b4d7a676ed8E1FF2ec, 5000000000000000000);
        _mint(0x5E190617C7cfB30C3C87dd55920e117280D3F8E6, 300000000000000000000);
        _mint(0x62b979923922045FB5A77bEd9E0753941B1DA52c, 100000000000000000000);
        _mint(0x62c04cc455520708958C9ce3FAFfF51745e42189, 20968136766813700000000);
        //_mint(0x65204c0183B29778d2b19513930ed8bDfDf044c0, 6725081405432150000); // SushiSwap PIXEL-ETH LP Pool
        _mint(0x66AB3988D11B493cBe632C7d4471A68350a786e9, 400000000000000000000);
        _mint(0x6b9C944DEB574Ed6f2A5b6B3e6c25165535b71DA, 200000000000000000000);
        _mint(0x79b1A32EC97537486E75d99850BD56ECfA09D643, 1500000000000000000000);
        _mint(0x7a4A8f7b3707Ecc86B50CAE33f83edc5F8c8F57E, 100000000000000000000);
        _mint(0x7bf4d5E579a26dd09F1ddDB2391566e7BA575B5B, 16300000000000000000000);
        _mint(0x7f3D32C56b94a9B7878fdfAC4F40Aaa2A6E11EdF, 34500000000000000000000);
        _mint(0x81F185CB71A4b98777a5Ee50CA55e80608DB61c1, 200000000000000000000);
        _mint(0x826a471055333505E596F424348983aF0Aa8411B, 200000000000000000000);
        _mint(0x835f394f3D770B6FF818303f045e39f541B3d781, 100000000000000000000);
        _mint(0x8469032c8B6F94E95c0659a9a3a34dE959999999, 150000000000000000000);
        _mint(0x862c6f0373AC129fc66A324B234943139CA10c92, 10000000000000000000000);
        _mint(0x897656B1Fb6C3688e48e1DD8259f7E092364754d, 20120000000000000000000);
        _mint(0x8fB07b21383d331F3752A7590b0cfEAc85514A1F, 3900000000000000000000);
        _mint(0x94E169525d86df638CC51d801eaC8D60275a8047, 2500000000000000000000);
        _mint(0x97a2f4fa661c1898678cfb5C77B1CDC22816076B, 4074296045848550000000);
        _mint(0x9a568bFeB8CB19e4bAfcB57ee69498D57D9591cA, 400000000000000000000);
        _mint(0x9D0b92468Ef23D156F1bd5042Fe0B45C80a4418e, 100000000000000000000);
        _mint(0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E, 17410000000000000000000);
        _mint(0x9EFb6D49Fd5496626E80Ad0B07017744aE9A0efA, 100000000000000000000);
        _mint(0x9f7F67699b6B35ee2C37E3c9BE43e437E2FA4bf7, 2400000000000000000000);
        _mint(0xa03D1648Be58e6957C81C1C201236E189b6eE6AF, 10000000000000000000000);
        _mint(0xA03DEE508d09Ba9401a661F154036B36328e0F0C, 401680275849628000000);
        _mint(0xa0bf4E5640e5db6FA82967d2C160e35a9a28AE83, 14400000000000000000000);
        _mint(0xa2db5F9313a553F572fA44AA1BA5B5871Ed68406, 100000000000000000000);
        //_mint(0xa30B98148Ef97b6F6dCd911B129c7Dd68c0B09Ff, 3006358320399960000000); // SushiSwap PIXEL-MATIC LP Pool
        _mint(0xA8Ec58Dd533E0cF82eC417bcA3C4dbCa48aE5a8B, 1);
        _mint(0xAD2074361FC5a7D392B4b7b5b97B8C0a9ec3A1ED, 100000000000000000000);
        _mint(0xaf1ca20615F84c48782F2f23b3cC737Db9c3514c, 100000000000000000000);
        _mint(0xB11A0Ce3A6EA30D8aA906E0f84eB92be8aF5aFcb, 1000000000000000000);
        _mint(0xb17524239b58963Cf2D9b9A7A92d4EfAE3dF1A3e, 100000000000000000000);
        _mint(0xB2F6Be1d6c18514eABdc352B97B63273608af8FE, 5797867809847100000000);
        _mint(0xB3160404ca9581784b3dec9e85bcd354397B8C72, 7500000000000000000000);
        _mint(0xb3D1e41F84AcD0E77F83473aa62fc8560C2A3c0C, 100000000000000000000);
        _mint(0xb4A3f907ec1611F22543219AE9Bb33ec5E96e116, 2500000000000000000000);
        _mint(0xb5EDE9893FcCd62a110fd9D0CcE5C89418a8540b, 400000000000000000000);
        _mint(0xB96863b5a9bb3783c5BA0665e4382b766746D6fa, 10000000000000000000000);
        _mint(0xB9956c74639D8E11c64D8005dC0c2262945Af074, 100000000000000000000);
        _mint(0xbcc1a3455BFE501cD163c3f1AE85e038253F252E, 600000000000000000000);
        _mint(0xbf2116D0a79da0E5710Df8AB00eb20415bCA94C8, 409563635515185000000);
        _mint(0xBF912CB4d1c3f93e51622fAe0bfa28be1B4b6C6c, 1600000000000000000000);
        _mint(0xC16414AC1fedfDAC4F8A09674D994e1BbB9d7113, 603300000000000000000000);
        _mint(0xC53f5a27021455293Aa34da308280abC4cAD210A, 100000000000000000000);
        _mint(0xc572c95996653ae98Ec3A59d9a511eDA142b98C1, 3200000000000000000000);
        _mint(0xc61a2Bb414a41ce492a94b5F59F5FD72f3a71C97, 900000000000000000000);
        _mint(0xc70C99C1485eCcc693e434433edBF5C27f937499, 2200000000000000000000);
        _mint(0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7, 4120000000000000000000);
        _mint(0xc962Ba9a1a45B79C1228636db5a6eFA4a4b75D76, 200000000000000000000);
        _mint(0xC9fD84728F98dF2820896DB89D7d47aC9998228c, 400000000000000000000);
        _mint(0xce3C49dC6E0ee03cBd5fAB568CC638f09ac4a7D7, 2000000000000000000000);
        _mint(0xcE3C9E357425c99cC27Dc9bF963d06E739811465, 15000000000000000000000);
        _mint(0xD264da372aeFcd5269Ca212BFD3C56e8e95bcCca, 100000000000000000000);
        _mint(0xd6e371526cdaeE04cd8AF225D42e37Bc14688D9E, 3000000000000000000000);
        _mint(0xDf547EaB8944D9Ef06475dF8eEe372B9808f425E, 400000000000000000000);
        _mint(0xE0878a84505A33e0beCE816F8d70A0c635CaEf00, 18090005479138400000000);
        _mint(0xe0D62CC9233C7E2F1f23fE8C77D6b4D1a265D7Cd, 1600000000000000000000);
        _mint(0xE5625a6EE4908f67B7024849daf95f8FaDCb89d5, 17494768321937100000000);
        _mint(0xe61a0809eF3f1d2D695555413ac354284BF23915, 3400000000000000000000);
        _mint(0xE744048f7D1B63B4e233A1D63c3153b913D7a2cc, 200000000000000000000);
        _mint(0xe9f654994f1135eBFab3183f50603dA5C6aBD4C3, 3400000000000000000000);
        _mint(0xEbaCA45c63BA3981B083064A8Dcf5D2999430bD6, 12677692062739300000000);
        _mint(0xEd3C50209648e2b4794D47b0973E2b95E6B756Ce, 10000000000000000000000);
        _mint(0xf07504A96601b35Dd702b07EcC57B2b169866f57, 4100000000000000000000);
        _mint(0xf1228C34651348F12d05D138896DC6d2E946F970, 18600000000000000000000);
        _mint(0xf58aA8E0832DeAc36550296Dc92fC091d5de2B7D, 3400000000000000000000);
        _mint(0xF82a5d0168cc93e63dc217314AdB87f15891d124, 100000000000000000000);
        _mint(0xfD5A25ef7396384C2D43645f32609BC869c36208, 97800000000000000000000);
        _mint(0xfEdcBda26763eF4660d5204F4252f2A9B1276D4a, 200000000000000000000);

        _setUpline(0x30a0911731f6eC80c87C4b99f27c254639A3Abcd, 0x256D49d87cbb877D26E2Bcf2bF0A40D26bdfB5d4);
        _setDownline(0x30a0911731f6eC80c87C4b99f27c254639A3Abcd, 1960000000000000000000, 0, 0, 3, 0, 0);
        _setDownline(0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7, 320000000000000000000, 0, 0, 8, 0, 0);
        _setUpline(0xA03DEE508d09Ba9401a661F154036B36328e0F0C, 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E);
        _setDownline(0xA03DEE508d09Ba9401a661F154036B36328e0F0C, 4720000000000000000000, 0, 0, 6, 0, 0);
        _setUpline(0x1E4135cF6E2B9feeBD52C6e90817fb19cFe294b9, 0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7);
        _setDownline(0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E, 14480000000000000000000, 2440000000000000000000, 490000000000000000000, 7, 10, 3);
        _setUpline(0xf07504A96601b35Dd702b07EcC57B2b169866f57, 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E);
        _setUpline(0xaf1ca20615F84c48782F2f23b3cC737Db9c3514c, 0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7);
        _setUpline(0x7f3D32C56b94a9B7878fdfAC4F40Aaa2A6E11EdF, 0xe61a0809eF3f1d2D695555413ac354284BF23915);
        _setUpline(0x256D49d87cbb877D26E2Bcf2bF0A40D26bdfB5d4, 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E);
        _setDownline(0x256D49d87cbb877D26E2Bcf2bF0A40D26bdfB5d4, 660000000000000000000, 980000000000000000000, 0, 1, 3, 0);
        _setDownline(0x1EF5526ee1A6D8c596cce90e774A2c41372cC8cD, 1000000000000000000000, 0, 0, 1, 0, 0);
        _setUpline(0x528d4e4E0dbF071eC23013f06D8487BaD5A8a68B, 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E);
        _setUpline(0xDf547EaB8944D9Ef06475dF8eEe372B9808f425E, 0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7);
        _setUpline(0x51c25230335472236853676290062c8C7a0825b6, 0xA03DEE508d09Ba9401a661F154036B36328e0F0C);
        _setUpline(0x91B12c04Ba95cede8E7cDD1a17D961cbdfd2e00b, 0xA03DEE508d09Ba9401a661F154036B36328e0F0C);
        _setUpline(0x3D9B0A7ef1CcEAda457001A6d51F28FF61E39904, 0x496ea957960Bf9A2BBC1D3c114EaA124e07D0543);
        _setDownline(0x3D9B0A7ef1CcEAda457001A6d51F28FF61E39904, 120000000000000000000, 10000000000000000000, 25000000000000000000, 1, 1, 0);
        _setUpline(0x7bD8A74a0B06FA03A9C2275F58081a7CCf549f16, 0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7);
        _setDownline(0x897656B1Fb6C3688e48e1DD8259f7E092364754d, 20000000000000000000, 0, 0, 1, 0, 0);
        _setUpline(0xa0bf4E5640e5db6FA82967d2C160e35a9a28AE83, 0xe61a0809eF3f1d2D695555413ac354284BF23915);
        _setDownline(0xe61a0809eF3f1d2D695555413ac354284BF23915, 3400000000000000000000, 0, 0, 2, 0, 0);
        _setUpline(0x218d75b17f491793a96ab4326c7875950359a80C, 0xA03DEE508d09Ba9401a661F154036B36328e0F0C);
        _setUpline(0xbf2116D0a79da0E5710Df8AB00eb20415bCA94C8, 0x131Ee3bE2E3803Bf9E8976dDf0306236f001B7F2);
        _setUpline(0x131Ee3bE2E3803Bf9E8976dDf0306236f001B7F2, 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E);
        _setDownline(0x131Ee3bE2E3803Bf9E8976dDf0306236f001B7F2, 600000000000000000000, 0, 0, 3, 0, 0);
        _setUpline(0x54D925F320400139f9F2925767F1ec68B027e7C0, 0x1EF5526ee1A6D8c596cce90e774A2c41372cC8cD);
        _setUpline(0x1F427A6FCdb95A7393C58552093e10A932890FA8, 0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7);
        _setUpline(0x43d20d5efA78Ff0e465DDa2e58109F9fb3A2becE, 0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7);
        _setUpline(0xF82a5d0168cc93e63dc217314AdB87f15891d124, 0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7);
        _setUpline(0xc572c95996653ae98Ec3A59d9a511eDA142b98C1, 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E);
        _setUpline(0x8fB07b21383d331F3752A7590b0cfEAc85514A1F, 0xA03DEE508d09Ba9401a661F154036B36328e0F0C);
        _setUpline(0x0b981d98e857C888E00D2C494D24DC16a12F8f3A, 0x131Ee3bE2E3803Bf9E8976dDf0306236f001B7F2);
        _setUpline(0x357dfdC34F93388059D2eb09996d80F233037cBa, 0x30a0911731f6eC80c87C4b99f27c254639A3Abcd);
        _setUpline(0xBF912CB4d1c3f93e51622fAe0bfa28be1B4b6C6c, 0x30a0911731f6eC80c87C4b99f27c254639A3Abcd);
        _setUpline(0x496ea957960Bf9A2BBC1D3c114EaA124e07D0543, 0x3D9B0A7ef1CcEAda457001A6d51F28FF61E39904);
        _setDownline(0x496ea957960Bf9A2BBC1D3c114EaA124e07D0543, 20000000000000000000, 50000000000000000000, 5000000000000000000, 1, 1, 1);
        _setUpline(0x9EFb6D49Fd5496626E80Ad0B07017744aE9A0efA, 0xC858Dd4F2a80a859D491A16BeEe6708a6743bfb7);
        _setDownline(0x28c24f2Da9B6E517968300Eb1A4F4aE1B235238E, 20000000000000000000, 0, 0, 1, 0, 0);
        _setUpline(0x2493C86B62E8ff26208399144817EF2898c59460, 0xA03DEE508d09Ba9401a661F154036B36328e0F0C);
        _setUpline(0x4fD95c6FA765e64eC9313E465F4D2B88Cbf8dEaa, 0xA03DEE508d09Ba9401a661F154036B36328e0F0C);
        _setUpline(0x66AB3988D11B493cBe632C7d4471A68350a786e9, 0x131Ee3bE2E3803Bf9E8976dDf0306236f001B7F2);
        _setUpline(0xfEdcBda26763eF4660d5204F4252f2A9B1276D4a, 0x9e6e344f94305d36eA59912b0911fE2c9149Ed3E);
        _setUpline(0xb3D1e41F84AcD0E77F83473aa62fc8560C2A3c0C, 0x28c24f2Da9B6E517968300Eb1A4F4aE1B235238E);
        _setUpline(0x9D0b92468Ef23D156F1bd5042Fe0B45C80a4418e, 0x30a0911731f6eC80c87C4b99f27c254639A3Abcd);
        _setUpline(0xa9f078B3b6DD6C04308f19DEF394b6D5a1B8b732, 0x897656B1Fb6C3688e48e1DD8259f7E092364754d);
        _setUpline(0x53033C9697339942256845dD4d428085eC7261B8, 0x3c5Aac016EF2F178e8699D6208796A2D67557fe2);
        _setDownline(0x3c5Aac016EF2F178e8699D6208796A2D67557fe2, 20000000000000000000, 0, 0, 1, 0, 0);
    }

    function mintCanvas() external {
        // The canvas is final
        require(block.timestamp >= LOCK_TIMESTAMP, "Creation Phase not finished");
        // Send any funds left to the owner. If this fails, continue anyway to prevent blocking.
        bool success;
        (success, ) = owner.call{value: address(this).balance}("");
        // Create Canvas
        canvas = address(new Canvas(this));
    }

    modifier onlyCreationPhase() {
        require(block.timestamp >= START_TIMESTAMP && block.timestamp < LOCK_TIMESTAMP, "Not in creation phase");
        _;
    }

    function getBlocks(uint256[] calldata blockNumbers) public view returns (ExportBlock[] memory blocks) {
        blocks = new ExportBlock[](blockNumbers.length);
        for (uint256 i = 0; i < blockNumbers.length; i++) {
            Block memory _blk = blk[blockNumbers[i]];
            BlockLink memory _link = link[_blk.link];
            blocks[i].number = blockNumbers[i].to32();
            blocks[i].owner = _blk.owner;
            blocks[i].lastPrice = _blk.lastPrice;
            blocks[i].url = _link.url;
            blocks[i].description = _link.description;
            blocks[i].pixels = _blk.pixels;
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

    function initBlocks(
        uint256[] calldata blockNumbers,
        string[] calldata url,
        string[] calldata description,
        bytes[] calldata pixels,
        uint128[] calldata lastPrice,
        address[] calldata blockOwner
    ) public onlyOwner {
        require(block.timestamp < START_TIMESTAMP, "Already started");

        for (uint256 i = 0; i < blockNumbers.length; i++) {
            BlockLink memory newLink;
            newLink.url = url[i];
            newLink.description = description[i];
            uint32 linkNumber = link.length.to32();
            link.push(newLink);

            uint256 blockNumber = blockNumbers[i];

            Block memory newBlock;
            newBlock.owner = blockOwner[i];
            newBlock.link = linkNumber;
            newBlock.pixels = pixels[i];
            newBlock.lastPrice = lastPrice[i];
            blk[blockNumber] = newBlock;
            updates.push(blockNumber);
        }
    }

    function setBlocks(
        uint256[] calldata blockNumbers,
        uint32 linkNumber,
        bytes[] calldata pixels,
        address referrer
    ) public payable onlyCreationPhase() nonReentrant() {
        // This error may happen when you calculate the correct cost, but someone buys one of your blocks before your transaction goes through
        // This is tested first to reduce wasted gas in case of failure
        uint256 cost = getCost(blockNumbers);
        require(msg.value == cost, "Pixel: not enough funds");

        _addRep(msg.sender, referrer);

        for (uint256 i = 0; i < blockNumbers.length; i++) {
            uint256 blockNumber = blockNumbers[i];
            // Forward a maximum of 20000 gas to the previous owner for accepting the refund to avoid griefing attacks
            bool success;
            address previousOwner = blk[blockNumber].owner;
            (success, ) = previousOwner.call{value: blk[blockNumber].lastPrice, gas: 20000}("");

            Block memory newBlock;
            newBlock.owner = msg.sender;
            newBlock.lastPrice = getCost(blockNumber).to128();
            newBlock.link = linkNumber;
            newBlock.pixels = pixels[i];
            blk[blockNumber] = newBlock;

            updates.push(blockNumber);

            emit PixelBlockTransfer(previousOwner, msg.sender, newBlock.lastPrice);
        }

        // Mint a PIXEL token for each pixel bought
        uint256 blocks = blockNumbers.length;
        _mint(msg.sender, blocks.mul(1e20));
        (address lvl1, address lvl2, address lvl3) = _getUpline(msg.sender);
        if (lvl1 != address(0)) { _mint(lvl1, blocks.mul(20e18)); }
        if (lvl2 != address(0)) { _mint(lvl2, blocks.mul(10e18)); }
        if (lvl3 != address(0)) { _mint(lvl3, blocks.mul(5e18)); }
        _recordEarnings(lvl1, lvl2, lvl3, blocks.mul(20e18).to128(), blocks.mul(10e18).to128(), blocks.mul(5e18).to128());
    }

    function setBlocks(
        uint256[] calldata blockNumbers,
        string calldata url,
        string calldata description,
        bytes[] calldata pixels,
        address referrer
    ) public payable onlyCreationPhase() returns (uint32 linkNumber) {
        BlockLink memory newLink;
        newLink.url = url;
        newLink.description = description;
        linkNumber = link.length.to32();
        link.push(newLink);

        setBlocks(blockNumbers, linkNumber, pixels, referrer);
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
        } else if (block.timestamp < LOCK_TIMESTAMP) {
            // After canvas is created, funds go to PIXEL hodlers and can't be withdrawn by the owner
            bool success;
            (success, ) = owner.call{value: address(this).balance}("");
        }
    }

    function poll(address user) public view returns (address canvas_, uint256 updates_, uint256 balance, uint256 supply, address upline_, DownlineStats memory downline_) {
        canvas_ = canvas;
        updates_ = updates.length;
        balance = balanceOf[user];
        supply = totalSupply;
        upline_ = upline[user];
        downline_ = downline[user];
    }

    // Receive funds from NFT sales for all PIXEL hodlers
    receive() external payable {}
}