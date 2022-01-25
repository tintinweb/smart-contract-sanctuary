/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract CalypsoPay is Ownable {
    event PayETH(uint256 amount, uint companyId, uint id);
    event PayToken(address tokenAddress, uint256 amount, uint companyId, uint id);
    event AddCompany(uint companyId, address companyAddress);

    mapping (uint => address) companyMapping;

    function payETH(uint companyId, uint id) payable external {
        address companyAddress = extractCompanyAddress(companyId);

        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = companyAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit PayETH(msg.value, companyId, id);
    }

    function payToken(address tokenAddress, uint256 amount, uint companyId, uint id) external {
        IERC20 token = IERC20(tokenAddress);

        address companyAddress = extractCompanyAddress(companyId);

        bool sent = token.transferFrom(msg.sender, companyAddress, amount);
        require(sent, "Failed to send Token");

        emit PayToken(tokenAddress, amount, companyId, id);
    }

    function extractCompanyAddress(uint companyId) public view returns (address) {
        address companyAddress = companyMapping[companyId];
        require(companyAddress != address(0), "Company id not found");

        return companyAddress;
    }

    function setCompany(uint companyId, address companyAddress) external onlyOwner {
        companyMapping[companyId] = companyAddress;

        emit AddCompany(companyId, companyAddress);
    }
}