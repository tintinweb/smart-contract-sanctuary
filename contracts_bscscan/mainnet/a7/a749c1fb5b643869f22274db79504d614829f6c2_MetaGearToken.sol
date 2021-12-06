pragma solidity ^0.8.5;

import "./ERC20Snapshot.sol";
import "./Pausable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract MetaGearToken is ERC20Snapshot, Pausable, AccessControl {
    using SafeMath for uint256;

    bytes32 private constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 private initialTokensSupply = 1000000000 * 10**decimals(); //1B
    mapping(address => bool) private blackListedList;

    constructor() ERC20("MetaGear Token", "GEAR") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _mint(msg.sender, initialTokensSupply);
    }

    function snapshot() external onlyRole(ADMIN_ROLE) {
        _snapshot();
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
    function pause() public onlyRole(PAUSER_ROLE) {
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
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual onlyRole(BURNER_ROLE) {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount)
        public
        virtual
        onlyRole(BURNER_ROLE)
    {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused notBlackListed {
        super._beforeTokenTransfer(from, to, amount);
    }

    function isBacklisted(address _address) external view returns (bool) {
        return blackListedList[_address];
    }

    function addBlackList(address _address) external onlyRole(ADMIN_ROLE) {
        blackListedList[_address] = true;
    }

    function removeBlackList(address _address) external onlyRole(ADMIN_ROLE) {
        blackListedList[_address] = false;
    }

    function getBurnedTotal() external view returns (uint256 _amount) {
        return initialTokensSupply.sub(totalSupply());
    }

    function withdrawBalance() public onlyRole(ADMIN_ROLE) {
        address payable _owner = payable(_msgSender());
        _owner.transfer(address(this).balance);
    }

    function withdrawTokens(address _tokenAddr, address _to)
        public
        onlyRole(ADMIN_ROLE)
    {
        require(
            _tokenAddr != address(this),
            "Cannot transfer out tokens from contract!"
        );
        require(isContract(_tokenAddr), "Need a contract address");
        ERC20(_tokenAddr).transfer(
            _to,
            ERC20(_tokenAddr).balanceOf(address(this))
        );
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    modifier notBlackListed() {
        require(!blackListedList[msg.sender], "Address is blacklisted");
        _;
    }
}