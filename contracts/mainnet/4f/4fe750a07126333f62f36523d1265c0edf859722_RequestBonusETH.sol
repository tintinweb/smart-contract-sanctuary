/**
 *Submitted for verification at Etherscan.io on 2020-12-14
*/

// SPDX-License-Identifier: No License (None)
pragma solidity ^0.7.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 *
 * Source https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-solidity/v2.1.3/contracts/ownership/Ownable.sol
 * This contract is copied here and renamed from the original to avoid clashes in the compiled artifacts
 * when the user imports a zos-lib contract (that transitively causes this contract to be compiled and added to the
 * build/artifacts folder) as well as the vanilla Ownable implementation from an openzeppelin version.
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(),"Not Owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),"Zero address not allowed");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}

contract RequestBonusETH is Ownable {
    
    uint256 public fee = 0.00025 ether; // 0.00025 ETH
    
    address public system;          // system address may change fee amount
    
    address payable public company; // company address receive fee

    mapping(address => address) vaultToken ; // vault => token;
    
    mapping (address => uint256) public companyRate;       // % the our company received as fee (with 2 decimals i.e. 1250 = 12.5%)
    
    mapping (address => uint256[]) private allowedAmount;   // amount of ETH that have to be send to request bonus
    
    mapping (address => address payable) public bonusOwners;
    
    mapping (address => bool) public isActive;
    
    mapping(address => mapping(address => uint256)) public paidETH; // token => user => paid ETH amount
    
    event TokenRequest(address indexed vault, address indexed user, uint256 amount);
    
    event CompanyRate(address indexed vault, uint256 rate);

    modifier onlySystem() {
        require(msg.sender == system || isOwner(), "Caller is not the system");
        _;
    }

    constructor (address _system, address payable _company) {
        require(_company != address(0) && _system != address(0));
        system = _system;
        company = _company;
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    // set our company rate in % that will be send to it as a fee
    function setCompanyRate(address vault, uint256 _rate) external onlyOwner returns(bool) {
        require(_rate <= 10000);
        companyRate[vault] = _rate;
        emit CompanyRate(vault, _rate);
        return true;
    }

    function setSystem(address _system) external onlyOwner returns(bool) {
        require(_system != address(0));
        system = _system;
        return true;
    }

    function setFee(uint256 _fee) external onlySystem returns(bool) {
        fee = _fee;
        return true;
    }

    function setCompany(address payable _company) external onlyOwner returns(bool) {
        require(_company != address(0));
        company = _company;
        return true;
    }

    function getAllowedAmount(address vault) external view returns(uint256[] memory) {
        return allowedAmount[vault];
    }
    
    function tokenRequest(address vault) public payable {
        require(isActive[vault], "Not active");
        require(fee < msg.value, "Not enough value");
        address token = vaultToken[vault];
        require(paidETH[token][msg.sender] == 0, "You already participated in this bonus program");

        uint256 value = msg.value - fee;
        require(isAllowedAmount(vault, value), "Wrong value");
        paidETH[token][msg.sender] = value;
        uint256 companyPart = value * companyRate[vault] / 10000 + fee;
        safeTransferETH(company, companyPart);
        safeTransferETH(bonusOwners[vault], msg.value - companyPart);
        emit TokenRequest(vault, msg.sender, value);
    }
    

    function isAllowedAmount(address vault, uint256 amount) internal view returns(bool) {
        uint256 len = allowedAmount[vault].length;
        for (uint256 i = 0; i < len; i++) {
            if(allowedAmount[vault][i] == amount) {
                return true;
            }
        }
        return false;
    }

    function registerBonus(
        address vault,
        address token,              // token contract address
        address payable bonusOwner, // owner of bonus program (who create bonus program)
        uint256 rate,               // % the our company received as fee (with 2 decimals i.e. 1250 = 12.5%)
        uint256[] memory amountETH  // amount of ETH that have to be send to request bonus
    ) external onlySystem returns(bool) {
        
        require(bonusOwners[vault] == address(0) && bonusOwner != address(0) ,"bonusOwner is not ok");
        vaultToken[vault] = token;
        companyRate[vault] = rate;
        bonusOwners[vault] = bonusOwner;
        createOptions(vault, amountETH);
        isActive[vault] = true;
        return true;
    }

    // create set of options by customer (bonusOwner)
    function createOptions(
        address vault,              // token contract address
        uint256[] memory amountETH // amount of ETH that have to be send to request bonus
    ) public returns(bool) {
        
        require(msg.sender == bonusOwners[vault] || msg.sender == system, "Caller is not the bonusOwners or system");
        if(allowedAmount[vault].length > 0) delete allowedAmount[vault];    // delete old allowedAmount if exist
        allowedAmount[vault] = amountETH;
        return true;
    }

    function setActiveBonus(address vault, bool active) external returns(bool) {
        require(msg.sender == bonusOwners[vault], "Caller is not the bonusOwners");
        isActive[vault] = active;
        return true;
    }

    // allow bonus owner change address
    function changeBonusOwner(address vault, address payable newBonusOwner) external returns(bool) {
        require(newBonusOwner != address(0));
        require(msg.sender == bonusOwners[vault], "Caller is not the bonusOwners");
        bonusOwners[vault] = newBonusOwner;
        return true;
    }
}