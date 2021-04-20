pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./IERC20.sol";
import "./ICollateralizationPrimary.sol";
import "./TokenTemplate.sol";

contract Collateralization is ICollateralizationPrimary {
    address public _poolAddress;
    address public _governanceAddress;
    address public _bwtAddress;
    address public _collateralTokenAddress;

    TokenTemplate public  _bwt;
    IERC20 public _collateralToken;
    
    event PoolAddressChanged(address previousAddress,address poolAddress);
    event GovernanceAddressChanged(address previousAddress, address governanceAddress);
    event NewOwner(address newAddress);

    constructor (
        address poolAddress,
        address governanceAddress,
        address collateralTokenAddress,
        string memory bwtName,
        string memory bwtSymbol
    ) {
        require (collateralTokenAddress != address(0), "Collateral token address should be not null");

        _poolAddress = poolAddress == address(0) ? msg.sender : poolAddress;
        _governanceAddress  = governanceAddress  == address(0) ? msg.sender : governanceAddress;

        _bwt = new TokenTemplate(bwtName, bwtSymbol, 18, address(this), 0);
        
        _bwtAddress = address(_bwt);
        
        _collateralTokenAddress = collateralTokenAddress;
        _collateralToken = IERC20(collateralTokenAddress);
    }

    modifier onlyPool () {
        require (_poolAddress == msg.sender, "Caller chould be pool");
        _;
    }

    modifier onlyGovernance () {
        require (_governanceAddress == msg.sender, "Caller should be governance");
        _;
    }

    function buy (
        address destination,
        uint256 tokensAmount,
        uint256 payment) 
        public override onlyPool {
        require (destination != address(0), 
        "Destination should be not null");
        require (_collateralToken.allowance(destination, address(this)) >= payment, 
        "Not enough delegated tokens");

        _collateralToken.transferFrom(destination, address(this), payment);
        _bwt.mintTokens(destination, tokensAmount);
    }

    function buyBack (
        address destination, 
        uint256 tokensAmount, 
        uint256 payment) 
        public override onlyPool {
        require (destination != address(0), "Destination address should be not null");
        require (_collateralToken.balanceOf(address(this)) >= payment, 
        "Not enough collateralization on the contract");
        require (_bwt.allowance(destination, address(this)) >= tokensAmount, 
        "Not enough delegated BWT tokens on the user balance");

        _bwt.burnFrom(destination, tokensAmount);

        _collateralToken.transfer(destination, payment);
    }

    /*
    Function changes the pool address
    */
    function changePoolAddress (address poolAddress) public override onlyGovernance {
        require (poolAddress != address(0), "New pool address should not be empty");
        
        address previousAddress = _poolAddress;
        _poolAddress = poolAddress;

        emit PoolAddressChanged(previousAddress, poolAddress);
    }

    function changeGovernanceAddress(address governanceAddress) 
    public 
    override 
    onlyGovernance {
        require (governanceAddress != address(0), "NEW GOVERNANCE ADDRESS SHOULD BE NOT NULL");

        address previousAddress = _governanceAddress;
        _governanceAddress = governanceAddress;

        emit GovernanceAddressChanged(previousAddress, governanceAddress);
    }

    function getCollateralization() external override view returns (uint256) {
        return _collateralToken.balanceOf(address(this));
    }
    
    function getBwtSupply() override external view returns (uint256) {
        return _bwt.totalSupply();
    }
    
    function changeBwtOwner(address newOwner) external override onlyGovernance {
        _bwt.transferOwnership(newOwner);
        emit NewOwner(newOwner);
    }
    
}