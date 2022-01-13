// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <=0.8.11;

import "./SoladayContract.sol";
import "./SoladayToken.sol";

// @transmissions11 custom errors vs require() messages, save some gas
error noReentracy();
error invalidAddress();

/**
 * @title SoladayRegistry
 * @dev contract to track deployers and deployments
 * @author kethcode (https://github.com/kethcode)
 */
contract SoladayRegistry is SoladayContract {

    /*********
    * Events *
    **********/

    /**     * Announce Registry Deployment 
     * @param _contract Address of deployed Contract
     * @param _tokenContract Address of token contract used to issue rewards
     */
    event SoladayRegistryDeployed(
        address indexed _contract,
        address indexed _tokenContract
    );

    /**     * Announce a general Registration
     * @param _contract Address of deployed Contract
     * @param _deployer Address of account that deployed the Contract
     */
    event SoladayContractRegistered(
        address indexed _contract,
        address indexed _deployer
    );

    /************
    * Variables *
    *************/
    
    address[] deployers;
    mapping( address => address[] ) deployments;
    bool private locked;
    address private tokenContract;

    /*******************
    * Public Functions *
    ********************/

    modifier validAddress(address _addr) {
        if(_addr == address(0)) revert invalidAddress();
        _;
    }

    modifier noReentrancy() {
        if(locked) revert noReentracy();

        locked = true;
        _;
        locked = false;
    }

    constructor(address _tokenContract) validAddress(_tokenContract)
    {
        tokenContract =  _tokenContract;
        emit SoladayRegistryDeployed(address(this), tokenContract);
    }

    function getDeployers() public view returns (address[] memory) {
        return deployers;
    }

    function getDeployments(address _deployer) public view returns (address[] memory) {
        return deployments[_deployer];
    }

    function registerDeployment(address _contract, address _deployer) public noReentrancy validAddress(_contract) validAddress(_deployer)
    {
        // find deployer
        // TODO:    redundant and a waste of storage. extract this data from emitted events.
        //          being overly cautious, expect I'll need to migrate this data

        bool hasDeployed = false;
        for(uint256 i = 0; i < deployers.length; i++)
        {
            if(_deployer == deployers[i])
            {
                hasDeployed = true;
            }
        }

        if(!hasDeployed)
        {
            deployers.push(_deployer);
        }

        // check for dups
        bool duplicateFound = false;
        for(uint256 i = 0; i < deployments[_deployer].length; i++)
        {
            if(deployments[_deployer][i] == _contract)
            {
                duplicateFound = true;
            }
        }

        // no dup, log it
        if(!duplicateFound)
        {
            deployments[_deployer].push(_contract);
            
            SoladayToken token = SoladayToken(tokenContract);
            token.mint(_deployer, 1e18);

            emit SoladayContractRegistered(
                _contract,
                _deployer
            );
        }
    }

    // noticed both transmissions11 and m1guelpf use ERC165 interface declarations
    // seems like a good idea to follow suit
    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     pure
    //     override(LilOwnable, ERC20)
    //     returns (bool)
    // {
    //     return
    //         interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
    //         interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC20
    //         interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
    // }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <=0.8.11;

/**
 * @title SoladayContract
 * @dev Contract for announcing deployments
 * @author kethcode (https://github.com/kethcode)
 */
contract SoladayContract {

    /*********
    * Events *
    **********/
    
    /**     * Announce a Deployment
     * @param _contract Address of deployed Contract
     * @param _deployer Address of account that deployed the Contract
     * @param _timestamp Timestamp of current block of deployment, 
     */
    event SoladayContractDeployed(
        address indexed _contract,
        address indexed _deployer, 
        uint256 _timestamp
    );

    /************
    * Variables *
    *************/

    /*******************
    * Public Functions *
    ********************/

    constructor() {
        emit SoladayContractDeployed ( 
            address(this),
            msg.sender,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <=0.8.11;

import "@rari-capital/solmate/src/tokens/ERC20.sol";

/**
 * @title SoladayToken
 * @dev Contract for announcing deployments
 * @author kethcode (https://github.com/kethcode)
 */
contract SoladayToken is ERC20 {

    /*********
    * Events *
    **********/

    /**     * Announce Token Deployment 
     * @param _tokenContract Address of token contract
     */
    event SoladayTokenDeployed(
        address indexed _tokenContract
    );

    /************
    * Variables *
    *************/

    /*******************
    * Public Functions *
    ********************/
    constructor() ERC20 ("Soladay_20220103", "SAD20220103", 18)
    {
        emit SoladayTokenDeployed(address(this));
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}