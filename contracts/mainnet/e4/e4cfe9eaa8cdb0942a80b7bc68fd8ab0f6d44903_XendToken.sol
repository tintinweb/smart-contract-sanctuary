// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;
import "./ERC20Pausable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract MintAccessor {
    address payable public owner;

    constructor() internal {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized access to contract");
        _;
    }

    function transferOwnership(address payable newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract XendToken is ERC20Pausable {
    using SafeMath for uint256;

    uint256 private _price;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply
    ) public ERC20(name, symbol, decimals, totalSupply) {}

    // receive() external payable {
    //     address sender = address(this);

    //     address recipient = msg.sender;

    //     uint256 decimal = decimals();
    //     uint256 amount = msg.value.mul(10**uint256(decimal)).div(_price); // calculates the amount

    //     _transfer(sender, recipient, amount);
    // }

    function mint(uint256 amount) public virtual onlyOwner {
        address account = msg.sender;
        _mint(account, amount);
    }

    function mint(address payable recipient, uint256 amount)
        public
        virtual
        onlyMinter
    {
        _transfer(owner, recipient, amount);
    }

    function withdraw() public virtual onlyOwner {
        uint256 etherBalance = address(this).balance;
        msg.sender.transfer(etherBalance);
    }

    function withdrawTokens() public virtual onlyOwner{
        address contractAddress = address(this);
        uint tokenBalance = balanceOf(contractAddress);
        _transfer(contractAddress,owner,tokenBalance);
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function SetPrice(uint256 priceInWei) public onlyOwner {
        _price = priceInWei;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
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
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(
            amount,
            "ERC20: burn amount exceeds allowance"
        );

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}