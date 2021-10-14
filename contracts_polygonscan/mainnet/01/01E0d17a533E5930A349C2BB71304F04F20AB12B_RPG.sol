pragma solidity ^0.8.0;

import "./LERC20.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract RPG is LERC20 {

    using SafeMath for uint;
    using Address for address;

    address public _pool;
    address public _treasury;

    mapping(address => bool) public freeOfCharge;
    mapping(address => bool) public trustedAddresses;
    mapping(address => bool) public allowedContracts;

    uint256 public _stakingFee;
    uint256 public _treasuryFee;
    uint256 public constant maxFee = 1500;
    uint256 public constant percentageConst = 10000;
    bool public feeEnabled;

    modifier onlyAllowedContracts() {
        require(address(msg.sender).isContract() && allowedContracts[msg.sender] || !address(msg.sender).isContract(),
            "Address: should be allowed");
        _;
    }

    modifier onlyTrusted() {
        require(trustedAddresses[msg.sender], "Address: should be allowed");
        _;
    }

    constructor(uint256 totalSupply_, string memory name_, string memory symbol_,
        address admin_, address recoveryAdmin_, uint256 timelockPeriod_, address lossless_, address stakingPool, address treasuryPool)
    LERC20(totalSupply_, name_, symbol_, admin_, recoveryAdmin_, timelockPeriod_, lossless_)  {
        _setStakingPool(stakingPool);
        _setTreasury(treasuryPool);
        _setFees(300, 100);
        feeEnabled = false;

    }

    function updateStakingPool(address pool) external onlyOwner {
        _setStakingPool(pool);
    }

    function updateTreasury(address treasury) external onlyOwner {
        _setTreasury(treasury);
    }

    function addFreeOfChargeAddress(address _free) external onlyOwner {
        freeOfCharge[_free] = true;
    }

    function deleteFreeOfChargeAddress(address _free) external onlyOwner {
        freeOfCharge[_free] = false;
    }

    function addTrustedAddress(address _free) external onlyOwner {
        trustedAddresses[_free] = true;
    }

    function deleteTrustedAddress(address _free) external onlyOwner {
        trustedAddresses[_free] = false;
    }

    function enableFee(bool status) external onlyOwner {
        feeEnabled = status;
    }

    function updateFee(uint256 fee, uint256 treasury) onlyOwner external {
        _setFees(fee, treasury);
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

    function transferValueToSend(address sender, uint256 amount) public view returns (uint256){
        return freeOfCharge[sender] ? amount : amount.sub(amount.mul(_stakingFee.add(_treasuryFee)).div(percentageConst));
    }

    function transfer(address recipient, uint256 amount) override public onlyAllowedContracts returns (bool) {
        if (freeOfCharge[msg.sender] || !feeEnabled) {
            require(super.transfer(recipient, amount));
        } else {
            require(balanceOf(msg.sender) >= amount, "Insufficient balance");
            uint256 feeAmount;
            uint256 sendingAmount;
            feeAmount = amount.mul(_stakingFee).div(percentageConst);
            sendingAmount = amount.sub(feeAmount);
            if (_treasuryFee > 0) {
                uint256 treasuryAmount = amount.mul(_treasuryFee).div(percentageConst);
                sendingAmount = sendingAmount.sub(treasuryAmount);
                require(super.transfer(_treasury, treasuryAmount));
            }
            require(super.transfer(recipient, sendingAmount));
            require(super.transfer(_pool, feeAmount));
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) override public onlyAllowedContracts returns (bool) {
        if (freeOfCharge[sender] || !feeEnabled) {
            require(super.transferFrom(sender, recipient, amount));
        } else {
            require(balanceOf(sender) >= amount, "Insufficient balance");
            uint256 feeAmount;
            uint256 sendingAmount;
            feeAmount = amount.mul(_stakingFee).div(percentageConst);
            sendingAmount = amount.sub(feeAmount);
            if (_treasuryFee > 0) {
                uint256 treasuryAmount = amount.mul(_treasuryFee).div(percentageConst);
                sendingAmount = sendingAmount.sub(treasuryAmount);
                require(super.transferFrom(sender, _treasury, treasuryAmount));
            }
            require(super.transferFrom(sender, recipient, sendingAmount));
            require(super.transferFrom(sender, _pool, feeAmount));
        }
        return true;
    }

    function transferTrusted(address recipient, uint256 amount) public onlyTrusted returns (bool) {
        require(super.transfer(recipient, amount));
        return true;
    }

    function transferFromTrusted(address sender, address recipient, uint256 amount) public onlyTrusted returns (bool) {
        require(super.transferFrom(sender, recipient, amount));
        return true;
    }

    function _setFees(uint256 fee, uint256 treasury) internal {
        require(fee + treasury <= maxFee, "Fee: value exceeded limit");
        _stakingFee = fee;
        _treasuryFee = treasury;
    }

    function _setStakingPool(address pool) internal {
        _pool = pool;
    }

    function _setTreasury(address pool) internal {
        _treasury = pool;
    }
}