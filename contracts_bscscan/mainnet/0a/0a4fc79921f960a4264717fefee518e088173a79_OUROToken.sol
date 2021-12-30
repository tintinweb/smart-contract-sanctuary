// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./library.sol";

/**
 * @notice OURO token contract (ERC20)
 */
contract OUROToken is ERC20, Ownable, IOUROToken {
    
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using Address for address payable;
    using SafeMath for uint256;
    
   /**
     * @dev Emitted when an account is set mintable
     */
    event Mintable(address account);
    /**
     * @dev Emitted when an account is set unmintable
     */
    event Unmintable(address account);
    
    // @dev mintable group
    mapping(address => bool) public mintableGroup;
    
    // @dev record mintable accounts
    address [] public mintableAccounts;
    
    modifier onlyMintableGroup() {
        require(mintableGroup[msg.sender], "OURO: not in mintable group");
        _;
    }

    /**
     * @dev Initialize the contract give all tokens to the deployer
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        
        setMintable(owner(), true); // default mintable at constructor
        _mint(_msgSender(), _initialSupply * (10 ** uint256(_decimals)));
    }
    
    /**
     * @dev set or remove address to mintable group
     */
    function setMintable(address account, bool allow) public override onlyOwner {
        mintableGroup[account] = allow;
        mintableAccounts.push(account);
        
        if (allow) {
            emit Mintable(account);
        }  else {
            emit Unmintable(account);
        }
    }
    
    /**
     * @dev remove all mintable account
     */
    function revokeAllMintable() public onlyOwner {
        uint n = mintableAccounts.length;
        for (uint i=0;i<n;i++) {
            delete mintableGroup[mintableAccounts[i]];
        }
        delete mintableAccounts;
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mint(address account, uint256 amount) public override onlyMintableGroup {
        _mint(account, amount);
        
    }
    
    /**
     * @dev Destroys `amount` tokens from the user.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public override onlyMintableGroup {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Batch transfer amount to recipient
     * @notice that excessive gas consumption causes transaction revert
     */
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length > 0, "OURO: least one recipient address");
        require(recipients.length == amounts.length, "OURO: number of recipient addresses does not match the number of tokens");

        for(uint256 i = 0; i < recipients.length; ++i) {
            _transfer(_msgSender(), recipients[i], amounts[i]);
        }
    }
}