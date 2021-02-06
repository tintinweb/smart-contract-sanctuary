/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

interface IyVault {
    function token() external view returns (address);
    function deposit(uint, address) external returns (uint);
    function withdraw(uint, address, uint) external returns (uint);
    function permit(address, address, uint, uint, bytes32) external view returns (bool);
    function pricePerShare() external view returns (uint);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract yAffiliateTokenV2 {
    using SafeERC20 for IERC20;
    
    /// @notice EIP-20 token name for this token
    string public name;

    /// @notice EIP-20 token symbol for this token
    string public symbol;

    /// @notice EIP-20 token decimals for this token
    uint256 public decimals;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0;

    mapping(address => mapping (address => uint)) internal allowances;
    mapping(address => uint) internal balances;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");
    bytes32 public immutable DOMAINSEPARATOR;

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);
    
    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);
    
    uint public index = 0;
    uint public bal = 0;
    
    function update() external {
        _update();
    }
    
    function _update() internal {
        if (totalSupply > 0) {
            uint256 _bal = IyVault(vault).pricePerShare();
            if (_bal > bal) {
                uint256 _diff = _bal - bal;
                if (_diff > 0) {
                    uint256 _ratio = _diff * 10**decimals / totalSupply;
                    if (_ratio > 0) {
                      index += _ratio;
                      bal = _bal;
                    }
                }
            }
        } else {
            bal = IyVault(vault).pricePerShare();
        }
    }
    
    function _mint(address dst, uint amount) internal {
        // mint the amount
        totalSupply += amount;
        // transfer the amount to the recipient
        balances[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }
    
    function _burn(address dst, uint amount) internal {
        // burn the amount
        totalSupply -= amount;
        // transfer the amount from the recipient
        balances[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }
    
    address public affiliate;
    address public governance;
    address public pendingGovernance;
    
    address public immutable token;
    address public immutable vault;
    
    constructor(address _governance, string memory _moniker, address _affiliate, address _token, address _vault) {
        DOMAINSEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), _getChainId(), address(this)));
        affiliate = _affiliate;
        governance = _governance;
        token = _token;
        vault = _vault;
        
        name = string(abi.encodePacked(_moniker, "-yearn ", IERC20(_token).name()));
        symbol = string(abi.encodePacked(_moniker, "-yv", IERC20(_token).symbol()));
        decimals = IERC20(_token).decimals();
        
        IERC20(_token).approve(_vault, type(uint).max);
    }
    
    function setGovernance(address _gov) external {
        require(msg.sender == governance);
        pendingGovernance = _gov;
    } 
    
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
    }
    
    function currentContribution() external view returns (uint) {
        return 1e18 * IERC20(vault).balanceOf(address(this)) / IERC20(vault).totalSupply();
    }
    
    function setAffiliate(address _affiliate) external {
        require(msg.sender == governance || msg.sender == affiliate);
        affiliate = _affiliate;
    }
    
    function depositAll() external {
        _deposit(IERC20(token).balanceOf(msg.sender));
    }
    
    function deposit(uint amount) external {
        _deposit(amount);
    }
    
    function _deposit(uint amount) internal {
        _update();
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, IyVault(vault).deposit(amount, address(this)));
    }
    
    function withdrawAll(uint maxLoss) external {
        _withdraw(balances[msg.sender], maxLoss);
    }
    
    function withdraw(uint amount, uint maxLoss) external {
        _withdraw(amount, maxLoss);
    }
    
    function _withdraw(uint amount, uint maxLoss) internal {
        _update();
        _burn(msg.sender, amount);
        IyVault(vault).withdraw(amount, msg.sender, maxLoss);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAINSEPARATOR, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "permit: signature");
        require(signatory == owner, "permit: unauthorized");
        require(block.timestamp <= deadline, "permit: expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != type(uint).max) {
            uint newAllowance = spenderAllowance - amount;
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        balances[src] -= amount;
        balances[dst] += amount;
        
        emit Transfer(src, dst, amount);
    }

    function _getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

contract yAffiliateFactoryV2 {
    using SafeERC20 for IERC20;
    
    address public governance;
    address public pendingGovernance;
    
    address[] public _affiliates;
    mapping(address => bool) isAffiliate;
    
    address[] public _yAffiliateTokens;
    
    mapping(address => mapping(address => address[])) affiliateTokens;
    mapping(address => mapping(address => bool)) isTokenAffiliate;
    mapping(address => address[]) tokenAffiliates;
    
    function yAffiliateTokens() external view returns (address[] memory) {
        return _yAffiliateTokens;
    }
    
    function affiliates() external view returns (address[] memory) {
        return _affiliates;
    }
    
    constructor() {
        governance = msg.sender;
    }
    
    function lookupAffiliates(address token) external view returns (address[] memory) {
        return tokenAffiliates[token];
    }
    
    function lookupAffiliateToken(address token, address affiliate) external view returns (address[] memory) {
        return affiliateTokens[token][affiliate];
    }
    
    function setGovernance(address _gov) external {
        require(msg.sender == governance);
        pendingGovernance = _gov;
    } 
    
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
    }
    
    function deploy(string memory _moniker, address _affiliate, address _token, address _vault) external {
        require(msg.sender == governance);
        if (!isAffiliate[_affiliate]) {
            _affiliates.push(_affiliate);
            isAffiliate[_affiliate] = true;
        }
        if (!isTokenAffiliate[_token][_affiliate]) {
            tokenAffiliates[_token].push(_affiliate);
            isTokenAffiliate[_token][_affiliate] = true;
        }
        address _yAffiliateToken = address(new yAffiliateTokenV2(governance, _moniker, _affiliate, _token, _vault));
        _yAffiliateTokens.push(_yAffiliateToken);
        
        affiliateTokens[_token][_affiliate].push(_yAffiliateToken);
    }
    
}