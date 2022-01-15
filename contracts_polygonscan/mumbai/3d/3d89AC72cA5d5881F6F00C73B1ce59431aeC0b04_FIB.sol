// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC20.sol";
import "./OwnableApprovers.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";

contract FIB is OwnableApprovers, ERC20, ERC20Burnable, Pausable {
    struct Frozen {
        uint256 amount;
        uint256 until;
    }
    uint256 public constant MAX_SUPPLY = 1000000000000000000; // 10 Billion

    mapping(address => Frozen[]) private frozenTokens;

    constructor() ERC20("Fibo Car", "FIB") {}

    modifier checkFrozenBalance(address account, uint256 amount) {
        uint256 frozenBalance = frozenBalanceOf(account);
        uint256 balance = balanceOf(account);
        require(
            balance - frozenBalance >= amount,
            "This account's balance is frozen"
        );
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
        require( totalSupply() <= MAX_SUPPLY, "MAX_SUPPLY limit" );
    }

    function mintAndFreeze(
        address _to,
        uint256 _amount,
        uint256 _until
    ) external onlyOwner {
        require(
            _until > block.timestamp,
            "_until param should be greater than current block.timestamp"
        );
        Frozen memory _frozen = Frozen(_amount, _until);
        frozenTokens[_to].push(_frozen);
        _mint(_to, _amount);
    }

    function frozenBalanceOf(address _account) public view returns (uint256) {
        if (frozenTokens[_account].length < 1) {
            return 0;
        }
        uint256 totalFrozen = 0;
        for (uint256 i = 0; i < frozenTokens[_account].length; i++) {
            Frozen memory frozen = frozenTokens[_account][i];
            if (frozen.until >= block.timestamp) {
                totalFrozen += frozen.amount;
            }
        }
        return totalFrozen;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        virtual
        override
        checkFrozenBalance(sender, amount)
        whenNotPaused
        returns (bool)
    {
        return super.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        whenNotPaused
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        checkFrozenBalance(_msgSender(), amount)
        whenNotPaused
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }
}