// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "AccessControlEnumerable.sol";
import "ERC20Pausable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
abstract contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) internal virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
    
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have admin role");
        _;
    }
}

contract eWit is ERC20PresetMinterPauser {
    address public platform;
    address public immutable developer;
    uint256 public totalSwapped;
    
    string constant NAME = 'eWit';
    string constant SYMBOL = 'EWIT';
    uint8 constant DECIMALS = 9;
    
    uint8 public feePercentage = 50; // Corresponds to 5%
    uint256 public minimumSwap = 10000 * 10 ** uint256(decimals());
    uint256 pendingAllowedToMint = 100000 * 10 ** uint256(decimals());

    event Swap(address indexed sender, string indexed witAddress, uint256 total);
    event Mint(address indexed sender, address indexed etherAddress, uint256 total, uint256 totalMinusFees, string indexed witnetFundsReceivedAt);
    
    function swap(string memory _wit_address, uint256 _total) external whenNotPaused {
        require(_total >= minimumSwap, "Invalid number of tokens");
        require(bytes(_wit_address).length == 42, "Invalid witnet address");

        _burn(msg.sender, _total);

        totalSwapped += _total;
        
        emit Swap(msg.sender, _wit_address, _total);
   }
    
   function mint(address _ether_address, uint256 _total, string memory _witnet_funds_received_at) external {
        require(pendingAllowedToMint >= _total, "Mint round needs to be renewed");
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");
        require(bytes(_witnet_funds_received_at).length == 42, "Invalid witnet address");

        pendingAllowedToMint -= _total;

        (uint256 swapAmount, uint256 platformFees, uint256 developerFees) = getFees(_total);

        _mint(_ether_address, swapAmount);

        if (platformFees > 0) {
            _mint(platform, platformFees);
            _mint(developer, developerFees);
        }
        
        emit Mint(msg.sender, _ether_address, _total, swapAmount, _witnet_funds_received_at);
    }
    
   function getFees(uint256 _total) internal view returns (uint256 swapAmount, uint256 platformFees, uint256 developerFees) {
        uint256 totalFees = _total * feePercentage / 1000;
        developerFees = totalFees / 10;
        platformFees = totalFees - developerFees;
        swapAmount = _total - totalFees;
   } 
    
    function updateMinimum(uint256 _new_minimum) external onlyAdmin {
        minimumSwap = _new_minimum;
    }
    
    function updateFees(uint8 _new_fees) external onlyAdmin {
        require(_new_fees <= 50, 'Fees cannot surpass 5%');
        feePercentage = _new_fees;
    }
    
    function updatePlatformWallet(address _new_wallet) external onlyAdmin {
        require(_new_wallet != address(0), 'Cannot set the zero address');
        platform = _new_wallet;
    }
    
    function renewMintRound(uint256 _allowed_to_mint) external onlyAdmin {
        pendingAllowedToMint = _allowed_to_mint;
    }
    
    function decimals() override public view virtual returns (uint8) {
        return DECIMALS;
    }
    
    constructor(address _multisig, address _platform, address _developer) ERC20(NAME, SYMBOL)
    {
        require(_platform != address(0), 'Platform: cannot set the zero address');
        require(_developer != address(0), 'Developer: cannot set the zero address');

        platform = _platform;
        developer = _developer;

        _setupRole(DEFAULT_ADMIN_ROLE, _multisig);
    }
}