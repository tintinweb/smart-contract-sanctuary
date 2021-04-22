pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./IERC20.sol";
import "./TokenTemplate.sol";
import "./ISecondaryCollateralizationBWT.sol";

contract Collateralization is ICollateralization {
    address public _poolAddress;
    address public _governanceAddress;

    TokenTemplate public _whiteToken;
    TokenTemplate public _blackToken;
    IERC20 public _collateralToken;
    IERC20 public _bwToken;
    
    event PoolAddressChanged(address previousAddress,address poolAddress);
    event GovernanceAddressChanged(address previousAddress, address governanceAddress);
    event AddLiquidity(uint256 amount);
    event WithdrawLiquidity(uint256 amount);

    constructor (
        address poolAddress,
        address governanceAddress,
        address bwtAddress,
        address collateralTokenAddress,
        string memory whiteName,
        string memory whiteSymbol,
        string memory blackName,
        string memory blackSymbol
    ) {
        require (bwtAddress != address(0), "WHITE TOKEN ADDRESS SHOULD BE NOT NULL");
        require (collateralTokenAddress != address(0), "COLLATERAL TOKEN ADDRESS SHOULD BE NOT NULL");

        _poolAddress = poolAddress == address(0) ? msg.sender : poolAddress;
        _governanceAddress  = governanceAddress  == address(0) ? msg.sender : governanceAddress;

        _whiteToken        = new TokenTemplate(whiteName, whiteSymbol, 18, address(this), 0);
        _blackToken        = new TokenTemplate(blackName, blackSymbol, 18, address(this), 0);
        _collateralToken   = IERC20(collateralTokenAddress);
    }

    modifier onlyPool () {
        require (_poolAddress == msg.sender, "Caller should be pool");
        _;
    }

    modifier onlyGovernance () {
        require (_governanceAddress == msg.sender, "Caller should be pool");
        _;
    }
    
    function addLiquidity (address destination, uint256 tokensAmount) 
    external override onlyPool {
        require (destination != address(0), "Destination address shouold be not null");
        require (_bwToken.allowance(destination, address(this)) >= tokensAmount, "Not enough delegated BWT");
        
        _bwToken.transferFrom(destination, address(this), tokensAmount);
        
        _whiteToken.mintTokens(address(this), tokensAmount);
        _blackToken.mintTokens(address(this), tokensAmount);
        emit AddLiquidity(tokensAmount);
    }
    
    function withdraw (address destination, uint256 tokensAmount) 
    external override onlyPool {
        require (destination != address(0), 
        "Destination address shouold be not null");
        require (_whiteToken.balanceOf(address(this)) >= tokensAmount, 
        "Not enough WHITE tokens on Collateralization contract balance");
        require (_blackToken.balanceOf(address(this)) >= tokensAmount, 
        "Not enough BLACK tokens on Collateralization contract balance");

        if(tokensAmount > 0) {
            _whiteToken.burn(tokensAmount);
            _blackToken.burn(tokensAmount);
            _bwToken.transfer(destination, tokensAmount);
        }
        emit WithdrawLiquidity(tokensAmount);
    }
    
    function withdrawCollateral(address destination, uint256 tokensAmount) 
    external override onlyPool {
        require (destination != address(0), 
        "Destination address shouold be not null");
        require (_collateralToken.balanceOf(address(this)) >= tokensAmount, 
        "Not enough Collateral tokens on Collateralization contract balance");

        if(tokensAmount > 0) {
            _collateralToken.transfer(destination, tokensAmount);
        }
        emit WithdrawLiquidity(tokensAmount);
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
    override external view returns (uint256 white, uint256 black, uint256 bwt) {
        uint256 whiteTokensAmount = _whiteToken.balanceOf(address(this));
        uint256 blackTokensAmount = _blackToken.balanceOf(address(this));
        uint256 bwtAmount = _bwToken.balanceOf(address(this));

        return (whiteTokensAmount, blackTokensAmount, bwtAmount);
    }
    
    function delegate(address newCollateralization) override external onlyPool {
        _bwToken.transfer(newCollateralization, _bwToken.balanceOf(address(this)));
        _collateralToken.transfer(newCollateralization, _collateralToken.balanceOf(address(this)));
    }
}