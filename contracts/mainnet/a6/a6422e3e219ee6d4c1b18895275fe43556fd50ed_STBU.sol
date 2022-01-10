pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract STBU is ERC20, Ownable {
    using SafeMath for uint;
    using Address for address;

    mapping(address => bool) public allowedContracts;
    mapping(address => Manager) public managers;

    uint256 private _maxSupply;
    uint256 private _minSupply;
    address public treasury;

    struct Manager {
        bool active;
        Limits burn;
        Limits mint;
    }

    struct Limits {
        uint256 max;
        uint256 actual;
    }

    modifier onlyAllowedContracts() {
        require(address(msg.sender).isContract() && allowedContracts[msg.sender] || !address(msg.sender).isContract(),
            "Address: should be allowed");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender].active, "Address is not manager");
        _;
    }

    constructor (string memory name, string memory symbol, uint256 maxSupply, uint256 minSupply) ERC20(name, symbol) public {
        _maxSupply = maxSupply;
        _minSupply = minSupply;
    }

    function addManager(uint256 maxBurn, uint256 maxMint, address manager) public onlyOwner returns(bool) {
        require(!managers[manager].active, "Manager already exists");
        managers[manager].active = true;
        managers[manager].mint.max = maxMint;
        managers[manager].burn.max = maxBurn;
        return true;
    }

    function removeManager(address manager) public onlyOwner returns(bool) {
        require(managers[manager].active, "Manager not exists");
        managers[manager].active = false;
        managers[manager].mint.max = 0;
        managers[manager].burn.max = 0;
        return true;
    }

    function addAllowedContract(address _contract) external onlyOwner returns (bool) {
        require(_contract.isContract(), "Address: is not contract or not deployed");
        allowedContracts[_contract] = true;
        return true;
    }

    function removeAllowedContract(address _contract) external onlyOwner returns (bool) {
        require(_contract.isContract(), "Address: is not contract or not deployed");
        allowedContracts[_contract] = false;
        return true;
    }

    function changeTreasury(address _treasury) public onlyOwner returns(bool) {
        treasury = _treasury;
        return true;
    }

    function transfer(address recipient, uint256 amount) override public onlyAllowedContracts returns (bool) {
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) override public onlyAllowedContracts returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function mint(uint256 amount) onlyManager public returns(bool) {
        require(managers[msg.sender].mint.max >= managers[msg.sender].mint.actual.add(amount), "Limit exceeded");
        uint256 supply = totalSupply();
        require(_maxSupply >= supply.add(amount), "Supply exceeded cap");
        managers[msg.sender].mint.actual = managers[msg.sender].mint.actual.add(amount);
        _mint(treasury, amount);
        return true;
    }

    function burn(uint256 amount) onlyManager public returns(bool) {
        require(managers[msg.sender].burn.max >= managers[msg.sender].burn.actual.add(amount), "Limit exceeded");
        uint256 supply = totalSupply();
        require(_minSupply >= supply.sub(amount), "Supply exceeded cap");
        managers[msg.sender].burn.actual = managers[msg.sender].burn.actual.add(amount);
        _burn(treasury, amount);
        return true;
    }

    function receiveStuckTokens(address token) public onlyOwner returns(bool) {
        IERC20 coin = IERC20(token);
        require(coin.balanceOf(address(this)) > 0, "Zero balance");
        require(coin.transfer(treasury, coin.balanceOf(address(this))), "Transfer: error");
        return true;
    }

}