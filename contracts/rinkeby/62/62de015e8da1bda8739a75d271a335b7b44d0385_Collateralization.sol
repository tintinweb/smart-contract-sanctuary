pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./IERC20.sol";
import "./ICollateralizationERC20.sol";

contract Collateralization is ICollateralization {
    address public _poolAddress;
    address public _governanceAddress;
    address public _whiteTokenAddress;
    address public _blackTokenAddress;
    address public _collateralTokenAddress;

    IERC20  _whiteToken;
    IERC20  _blackToken;
    IERC20  _collateralToken;
    
    event PoolAddressChanged(address previousAddress,address poolAddress);
    event GovernanceAddressChanged(address previousAddress, address governanceAddress);

    constructor (
        address poolAddress,
        address governanceAddress,
        address whiteTokenAddress,
        address blackTokenAddress,
        address collateralTokenAddress
    ) {
        require (whiteTokenAddress != address(0), "WHITE TOKEN ADDRESS SHOULD BE NOT NULL");
        require (blackTokenAddress != address(0), "BLACK TOKEN ADDRESS SHOULD BE NOT NULL");
        require (collateralTokenAddress != address(0), "COLLATERAL TOKEN ADDRESS SHOULD BE NOT NULL");

        _poolAddress = poolAddress == address(0) ? msg.sender : poolAddress;
        _governanceAddress  = governanceAddress  == address(0) ? msg.sender : governanceAddress;

        _whiteTokenAddress = whiteTokenAddress;
        _blackTokenAddress = blackTokenAddress;
        _collateralTokenAddress = collateralTokenAddress;
        _whiteToken        = IERC20(whiteTokenAddress);
        _blackToken        = IERC20(blackTokenAddress);
        _collateralToken   = IERC20(collateralTokenAddress);
    }

    modifier onlyPool () {
        require (_poolAddress == msg.sender, "CALLER SHOULD BE THE POOL");
        _;
    }

    modifier onlyGovernance () {
        require (_governanceAddress == msg.sender, "CALLER SHOULD BE GOVERNANCE");
        _;
    }
    
    function withdraw (address destination, uint256 tokensAmount, uint256 collateralAmount) 
    external override onlyPool {
        require (destination != address(0), 
        "Destination address shouold be not null");
        require (_whiteToken.balanceOf(address(this)) >= tokensAmount, 
        "Not enough WHITE tokens on Collateralization contract balance");
        require (_blackToken.balanceOf(address(this)) >= tokensAmount, 
        "Not enough BLACK tokens on Collateralization contract balance");
        require (_collateralToken.balanceOf(address(this)) >= collateralAmount, 
        "Not enough Collateral tokens on Collateralization contract balance");

        if(tokensAmount > 0) {
            _whiteToken.transfer(destination, tokensAmount);
            _blackToken.transfer(destination, tokensAmount);
        }
        if(collateralAmount > 0) {
            _collateralToken.transfer(destination, collateralAmount);
        }
    }

    function buySeparately(
        address destination, 
        uint256 tokensAmount, 
        bool isWhite,
        uint256 payment) 
        public override onlyPool {
        require (destination != address(0), "DESTINATION ADDRESS SHOULD BE NOT NULL");
        require (_collateralToken.allowance(destination, address(this)) >= payment, 
        "NOT ENOUGH DELEGATED TOKENS");
        _collateralToken.transferFrom(destination, address(this), payment);

        if (isWhite) {
            require (_whiteToken.balanceOf(address(this)) >= tokensAmount, 
            "NOT ENOUGH WHITE TOKENS ON COLLATERALIZATION CONTRACT BALANCE");
            _whiteToken.transfer(destination, tokensAmount);
        }
        else {
            require (_blackToken.balanceOf(address(this)) >= tokensAmount, 
            "NOT ENOUGH BLACK TOKENS ON COLLATERALIZATION CONTRACT BALANCE");
            _blackToken.transfer(destination, tokensAmount);
        }
    }

    function buyBackSeparately(
        address destination, 
        uint256 tokensAmount, 
        bool isWhite, 
        uint256 payment) 
        public override onlyPool {
        require (destination != address(0), "DESTINATION ADDRESS SHOULD BE NOT NULL");
        require (_collateralToken.balanceOf(address(this)) >= payment, "NOT ENOUGH COLLATERALIZATION ON THE CONTRACT");

        if(tokensAmount > 0) {
            if (isWhite) {
                require (_whiteToken.allowance(destination, address(this)) >= tokensAmount, 
                "NOT ENOUGH DELEGATED WHITE TOKENS ON DESTINATION BALANCE");
                _whiteToken.transferFrom(destination, address(this), tokensAmount);
            } else {
                require (_blackToken.allowance(destination, address(this)) >= tokensAmount, 
                "NOT ENOUGH DELEGATED BLACK TOKENS ON DESTINATION BALANCE");
                _blackToken.transferFrom(destination, address(this), tokensAmount);
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

    function getStoredTokensAmount()
    override external view returns (uint256 white, uint256 black) {
        uint256 whiteTokensAmount = _whiteToken.balanceOf(address(this));
        uint256 blackTokensAmount = _blackToken.balanceOf(address(this));

        return (whiteTokensAmount, blackTokensAmount);
    }
}