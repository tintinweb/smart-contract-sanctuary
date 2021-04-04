pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./IERC20.sol";
import "./ICollateralizationPrimary.sol";
import "./TokenTemplate.sol";

contract Collateralization is ICollateralizationPrimary {
    address public _poolAddress;
    address public _governanceAddress;
    address public _whiteTokenAddress;
    address public _blackTokenAddress;
    address public _collateralTokenAddress;

    TokenTemplate  _whiteToken;
    TokenTemplate  _blackToken;
    IERC20  _collateralToken;
    
    event PoolAddressChanged(address previousAddress,address poolAddress);
    event GovernanceAddressChanged(address previousAddress, address governanceAddress);

    constructor (
        address poolAddress,
        address governanceAddress,
        address collateralTokenAddress,
        string memory whiteName,
        string memory blackName,
        string memory whiteSymbol,
        string memory blackSymbol
    ) {
        require (collateralTokenAddress != address(0), "Collateral token address should be not null");

        _poolAddress = poolAddress == address(0) ? msg.sender : poolAddress;
        _governanceAddress  = governanceAddress  == address(0) ? msg.sender : governanceAddress;

        _whiteToken        = new TokenTemplate(whiteName, whiteSymbol, 18, address(this), 0);
        _blackToken        = new TokenTemplate(blackName, blackSymbol, 18, address(this), 0);
        
        _whiteTokenAddress = address(_whiteToken);
        _blackTokenAddress = address(_blackToken);
        
        _collateralTokenAddress = collateralTokenAddress;
        _collateralToken   = IERC20(collateralTokenAddress);
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
        _whiteToken.mintTokens(destination, tokensAmount);
        _blackToken.mintTokens(destination, tokensAmount);
    }

    function buySeparately(
        address destination, 
        uint256 tokensAmount, 
        bool isWhite,
        uint256 payment) 
        public override onlyPool {
        require (destination != address(0), "Destination address should be not null");
        require (_collateralToken.allowance(destination, address(this)) >= payment, 
        "Not enough delegated tokens");
        _collateralToken.transferFrom(destination, address(this), payment);

        if (isWhite) {
            _whiteToken.mintTokens(destination, tokensAmount);
        }
        else {
            _blackToken.mintTokens(destination, tokensAmount);
        }
    }

    function buyBack (
        address destination, 
        uint256 tokensAmount, 
        uint256 payment) 
        public override onlyPool {
        require (destination != address(0), "Destination address should be not null");
        require (_collateralToken.balanceOf(address(this)) >= payment, 
        "Not enough collateralization on the contract");
        require (_whiteToken.allowance(destination, address(this)) >= tokensAmount, 
        "Not enough delegated White tokens on the user balance");
        require (_blackToken.allowance(destination, address(this)) >= tokensAmount, 
        "Not enough delegated Black tokens on the user balance");

        _whiteToken.burnFrom(destination, tokensAmount);
        _blackToken.burnFrom(destination, tokensAmount);

        _collateralToken.transfer(destination, payment);
    }

    function buyBackSeparately(
        address destination, 
        uint256 tokensAmount, 
        bool isWhite, 
        uint256 payment) 
        public override onlyPool {
        require (destination != address(0), "Destination address should be not null");
        require (_collateralToken.balanceOf(address(this)) >= payment, "Not enough collateralization on the contract");

        if(tokensAmount > 0) {
            if (isWhite) {
                require (_whiteToken.allowance(destination, address(this)) >= tokensAmount, 
                "Not enough delegated White tokens on the user balance");
                _whiteToken.burnFrom(destination, tokensAmount);
            } else {
                require (_blackToken.allowance(destination, address(this)) >= tokensAmount, 
                "Not enough delegated Black tokens on the user balance");
                _blackToken.burnFrom(destination, tokensAmount);
            }
        }
        _collateralToken.transfer(destination, payment);
    }

    /*
    Function changes the pool address
    */
    function changePoolAddress (address poolAddress) public override onlyGovernance {
        require (poolAddress != address(0), "NEW POOL ADDRESS SHOULD BE NOT NULL");
        
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

    function getCollateralization() public override view returns (uint256) {
        return _collateralToken.balanceOf(address(this));
    }
    
    function getWhiteSupply () override external view returns (uint256) {
        return _whiteToken.totalSupply();
    }
    function getBlackSupply () override external view returns (uint256) {
                return _blackToken.totalSupply();
    }
    
}