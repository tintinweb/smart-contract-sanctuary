pragma solidity 0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Address.sol";

contract RPG is ERC20, Ownable {

    using SafeMath for uint;
    using Address for address;

    address private _minter;
    address private _pool;

    mapping(address => bool) private freeOfCharge;
    mapping(address => bool) private allowedContracts;

    uint256 private _maxSupply;
    uint256 private _fee;
    uint256 private percentageConst;

    event MinterSet(address indexed account);
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to,  uint256 value);

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     * @param minter the multi-sig contract address
     */
    constructor(address minter, uint256 supply, address stakingPool) public ERC20("RPG", "RPG") {
        _setupDecimals(8);
        _setMinter(minter);
        _setMaxSupply(supply);
        _setStakingPool(stakingPool);
        percentageConst = 10000;
        _setFee(300);

    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "caller is not a minter");
        _;
    }

    modifier onlyAllowedContracts() {
        require(address(msg.sender).isContract() && allowedContracts[msg.sender] || !address(msg.sender).isContract(),
            "Address: should be allowed");
        _;
    }

    /**
     * @dev See {maxSupply}.
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function _setMaxSupply(uint256 supply) internal {
        _maxSupply = supply;
    }

    function _setStakingPool(address pool) internal {
        _pool = pool;
    }

    function addFreeOfChargeAddress(address _free) public onlyOwner {
        freeOfCharge[_free] = true;
    }

    function deleteFreeOfChargeAddress(address _free) public onlyOwner {
        freeOfCharge[_free] = false;
    }

    function _setFee(uint256 fee) internal {
        _fee = fee;
    }

    /**
     * @dev Burns a specific amount of tokens and emit transfer event for native chain
     * @param value The amount of token to be burned.
     */
    function burnFrom(uint256 value) public {
        _burn(msg.sender, value);
        emit Burn(msg.sender, value);
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param value The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mintTo(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        emit Mint(to, value);
        return true;
    }

    function _mint(address account, uint256 value) override internal {
        require(totalSupply().add(value) <= maxSupply(), "ERC20Capped: cap exceeded");
        super._mint(account, value);
    }

    function addAllowedContract(address _contract) public onlyOwner returns (bool) {
        require(_contract.isContract(), "Address: is not contract or not deployed");
        allowedContracts[_contract] = true;
        return true;
    }

    function removeAllowedContract(address _contract) public onlyOwner returns (bool) {
        require(_contract.isContract(), "Address: is not contract or not deployed");
        allowedContracts[_contract] = false;
        return true;
    }

    function isMinter(address account) public view returns (bool) {
        return _minter == account;
    }

    function _setMinter(address account) internal {
        _minter = account;
        emit MinterSet(account);
    }

    function changeMinter(address newMinter) public onlyOwner {
        _setMinter(newMinter);
    }

    function transfer(address recipient, uint256 amount) override public onlyAllowedContracts returns (bool) {
        if (freeOfCharge[recipient]) {
            require(super.transfer(recipient, amount));
        } else {
            require(balanceOf(msg.sender) >= amount, "Insufficient balance");
            uint256 feeAmount;
            uint256 sendingAmount;
            feeAmount = amount.mul(_fee).div(percentageConst);
            sendingAmount = amount.sub(feeAmount);
            require(super.transfer(recipient, sendingAmount));
            require(super.transfer(_pool, feeAmount));
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) override public onlyAllowedContracts returns (bool) {
        if (freeOfCharge[recipient] || freeOfCharge[sender]) {
            require(super.transferFrom(sender, recipient, amount));
        } else {
            require(balanceOf(sender) >= amount, "Insufficient balance");
            uint256 feeAmount;
            uint256 sendingAmount;
            feeAmount = amount.mul(_fee).div(percentageConst);
            sendingAmount = amount.sub(feeAmount);
            require(super.transferFrom(sender, recipient, sendingAmount));
            require(super.transferFrom(sender, _pool, feeAmount));
        }
        return true;
    }
}