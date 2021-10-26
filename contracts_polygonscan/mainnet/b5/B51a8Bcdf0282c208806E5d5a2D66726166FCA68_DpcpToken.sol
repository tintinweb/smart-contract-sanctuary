pragma solidity ^0.6.6;
import "./Context.sol";
import "./ERC20Burnable.sol";
import "./SafeMath.sol";
import "./IDpcp.sol";
import "./ICore.sol";
import "./Address.sol";
import "./ERC20.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address public _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }


    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }


    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}



contract DpcpToken is Context, IDpcp, Ownable,ERC20Burnable {
    using SafeMath for uint256;
    using Address for address;


    address[] minters; 
    address[] burners;

    ICore public _core;

    constructor ( address core) public ERC20("dgcg token", "DGCG"){
        _core = ICore(core);
        _owner = msg.sender;

    }



    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // 交易前执行额外的合约操作
        uint256 newAmount = _core.executeExtra(from,to,amount);

        super._transfer(from,to,newAmount);

    }



    function mint(address account, uint256 amount)
    external
    override
    onlyMinter
    {
        _mint(account, amount);
        emit Minting(account, msg.sender, amount);
    }

    function burn(uint256 amount) public override(IDpcp, ERC20Burnable) {
        super.burn(amount);
        emit Burning(msg.sender, msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount)
    public
    override(IDpcp, ERC20Burnable)
    onlyBurner
    {
        _burn(account, amount);
        emit Burning(account, msg.sender, amount);
    }

    function setCoreContract(address core) external onlyOwner{
        _core = ICore(core);
    }

    modifier onlyMinter() {
        require(_core.isMinter(msg.sender), "CoreRef: Caller is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(_core.isBurner(msg.sender), "CoreRef: Caller is not a burner");
        _;
    }
}