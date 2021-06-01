/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: UNLICENSED
// @title Meowshi (MEOW) 🐈 🍣 🍱
// @author Gatoshi Nyakamoto

pragma solidity 0.8.4;

// File @boringcrypto/boring-solidity/contracts/[email protected]
// License-Identifier: MIT

/// @dev Adapted for Meowshi.
contract Domain {
    string constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01"; // see https://eips.ethereum.org/EIPS/eip-191
    bytes32 constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    bytes32 immutable _DOMAIN_SEPARATOR;
    uint256 immutable DOMAIN_SEPARATOR_CHAIN_ID;

    constructor() {
        uint256 chainId;
        assembly { chainId := chainid() }
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }
    
    /// @dev Calculates the DOMAIN_SEPARATOR.
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }
    
    /// @dev Returns the DOMAIN_SEPARATOR.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }
    
    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, DOMAIN_SEPARATOR(), dataHash));
    }
}

// File @boringcrypto/boring-solidity/contracts/[email protected]
// License-Identifier: MIT

/// @dev Adapted for Meowshi.
contract ERC20 is Domain {
    /// @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)").
    bytes32 constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > nonce mapping used in {permit}.
    mapping(address => uint256) public nonces;
    
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Approves `amount` from msg.sender to be spent by `spender`.
    /// @param spender Address of the party that can draw tokens from msg.sender's account.
    /// @param amount The maximum collective `amount` that `spender` can draw.
    /// @return (bool) Returns 'true' if succeeded.
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Approves `amount` from `owner` to be spent by `spender` using the EIP-2612 method.
    /// @param owner Address of the `owner`.
    /// @param spender The address of the `spender` that gets approved to draw from `owner`.
    /// @param amount The maximum collective `amount` that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(owner != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner, spender, amount, nonces[owner]++, deadline))), v, r, s) ==
                owner, "ERC20: Invalid Signature");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move tokens `to`.
    /// @param amount The token `amount` to move.
    /// @return (bool) Returns 'true' if succeeded.
    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount; 
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval from `from`.
    /// @param from Address to draw tokens `from`.
    /// @param to The address to move tokens `to`.
    /// @param amount The token `amount` to move.
    /// @return (bool) Returns 'true' if succeeded.
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount; 
        emit Transfer(from, to, amount);
        return true;
    }
}

// File @boringcrypto/boring-solidity/contracts/[email protected]
// License-Identifier: MIT

/// @dev Adapted for Meowshi.
contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    function _getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
        if (_returnData.length < 68) return "Transaction reverted silently"; // if length is less than 68, tx failed w/o revert message
        assembly { _returnData := add(_returnData, 0x04) } return abi.decode(_returnData, (string)); // all that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If 'true', reverts after a failed call and stops further calls.
    function batch(bytes[] calldata calls, bool revertOnFail) external {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) revert(_getRevertMsg(result));
        }
    }
}

/// @notice Interface for depositing into and withdrawing from BentoBox vault.
interface IERC20{} interface IBentoBoxBasic {
    function deposit( 
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

/// @notice Interface for depositing into and withdrawing from SushiBar.
interface ISushiBar { 
    function balanceOf(address account) external view returns (uint256);
    function enter(uint256 amount) external;
    function leave(uint256 share) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/// @notice Meowshi takes SUSHI/xSUSHI to mint MEOW tokens that can be burned to claim SUSHI/xSUSHI from BENTO with yields.
//  ៱˳_˳៱   ∫
contract Meowshi is ERC20, BaseBoringBatchable {
    IBentoBoxBasic constant bentoBox = IBentoBoxBasic(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966); // BENTO vault contract (multinet)
    ISushiBar constant sushiToken = ISushiBar(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2); // SUSHI token contract (mainnet)
    address constant sushiBar = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272; // xSUSHI token contract for staking SUSHI (mainnet)
    string public constant name = "Meowshi";
    string public constant symbol = "MEOW";
    uint8 public constant decimals = 18;
    uint256 constant multiplier = 100_000; // 1 xSUSHI BENTO share = 100,000 MEOW
    uint256 public totalSupply;
    
    constructor() {
        sushiToken.approve(sushiBar, type(uint256).max); // max {approve} xSUSHI to draw SUSHI from this contract
        ISushiBar(sushiBar).approve(address(bentoBox), type(uint256).max); // max {approve} BENTO to draw xSUSHI from this contract
    }
    
    // **** xSUSHI
    /// @notice Enter Meowshi. Deposit xSUSHI `amount`. Mint MEOW for `to`.
    function meow(address to, uint256 amount) external returns (uint256 shares) {
        ISushiBar(sushiBar).transferFrom(msg.sender, address(bentoBox), amount); // forward to BENTO for skim
        (, shares) = bentoBox.deposit(IERC20(sushiBar), address(bentoBox), address(this), amount, 0);
        meowMint(to, shares * multiplier);
    }

    /// @notice Leave Meowshi. Burn MEOW `amount`. Claim xSUSHI for `to`.
    function unmeow(address to, uint256 amount) external returns (uint256 amountOut) {
        meowBurn(amount);
        (amountOut, ) = bentoBox.withdraw(IERC20(sushiBar), address(this), to, 0, amount / multiplier);
    }
    
    // **** SUSHI
    /// @notice Enter Meowshi. Deposit SUSHI `amount`. Mint MEOW for `to`.
    function meowSushi(address to, uint256 amount) external returns (uint256 shares) {
        sushiToken.transferFrom(msg.sender, address(this), amount);
        ISushiBar(sushiBar).enter(amount);
        (, shares) = bentoBox.deposit(IERC20(sushiBar), address(this), address(this), ISushiBar(sushiBar).balanceOf(address(this)), 0);
        meowMint(to, shares * multiplier);
    }

    /// @notice Leave Meowshi. Burn MEOW `amount`. Claim SUSHI for `to`.
    function unmeowSushi(address to, uint256 amount) external returns (uint256 amountOut) {
        meowBurn(amount);
        (amountOut, ) = bentoBox.withdraw(IERC20(sushiBar), address(this), address(this), 0, amount / multiplier);
        ISushiBar(sushiBar).leave(amountOut);
        sushiToken.transfer(to, sushiToken.balanceOf(address(this))); 
    }

    // **** SUPPLY MGMT
    /// @notice Internal mint function for *meow*.
    function meowMint(address to, uint256 amount) private {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    
    /// @notice Internal burn function for *unmeow*.
    function meowBurn(uint256 amount) private {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}