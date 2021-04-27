/**
 *Submitted for verification at Etherscan.io on 2021-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


interface CEth {
    function balanceOf(address owner) external view returns (uint256);
    
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract NexenFarming { // is Ownable
    address DAI = 0x31F42841c2db5173425b5223809CF3A38FEde360;
    address cDAI = 0xbc689667C13FB2a04f09272753760E38a95B998C;
    address USDT = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;
    address cUSDT = 0xF6958Cf3127e62d3EB26c79F4f45d3F3b2CcdeD4;
    address payable cETH = payable(0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8);
    
    IERC20 NexenToken = IERC20(0x80a35F3E05a5511725c7042cD9D8b5dCcE1919ad);
    
    uint256 public cDAIFees;
    uint256 public cUSDTFees;
    uint256 public cETHFees;

    struct Supply {
        bool exists;
        uint256 totaltokens;   
        uint256 dateCreated;
    }
    
    mapping(address => Supply) public DAISupplies;
    mapping(address => Supply) public USDTSupplies;
    mapping(address => Supply) public ETHSupplies;

    function supplyDAI(uint256 _numTokensToSupply) public payable {
        CErc20 cDAIToken = CErc20(cDAI);
        cDAIToken.transferFrom(msg.sender, address(this), _numTokensToSupply);

        uint mintResult = supplyErc20ToCompound(DAI, cDAI, _numTokensToSupply);
        
        Supply storage supply = DAISupplies[msg.sender];
        supply.exists = true;
        supply.totaltokens += mintResult;
    }
    
    function supplyUSDT(uint256 _numTokensToSupply) public payable {
        CErc20 cUSDTToken = CErc20(cUSDT);
        cUSDTToken.transferFrom(msg.sender, address(this), _numTokensToSupply);

        uint mintResult = supplyErc20ToCompound(USDT, cUSDT, _numTokensToSupply);
        
        Supply storage supply = USDTSupplies[msg.sender];
        supply.exists = true;
        supply.totaltokens += mintResult;
    }
    
    function supplyETH() public payable {
        uint mintResult = supplyEthToCompound(cETH);
        
        Supply storage supply = ETHSupplies[msg.sender];
        supply.exists = true;
        supply.totaltokens += mintResult;
    }
    
    function redeemETH() public {
        Supply storage supply = ETHSupplies[msg.sender];
        
        require(supply.exists, 'Invalid caller');

        uint256 redeemResult = redeemCEth(supply.totaltokens, true, cETH);
        
        uint256 returnToUser = redeemResult / 2;
        
        uint256 keep = redeemResult - returnToUser;
        
        cETHFees += keep;

        uint256 nexenTokensToReturn = redeemResult * 100 / 14;

        NexenToken.transferFrom(address(this), msg.sender, nexenTokensToReturn);
        
        payable(msg.sender).transfer(returnToUser);
    }
    
    function redeemDAI() public {
        Supply storage supply = DAISupplies[msg.sender];
        
        require(supply.exists, 'Invalid caller');

        uint256 redeemResult = redeemCErc20Tokens(supply.totaltokens, true, cDAI);
        
        uint256 returnToUser = redeemResult / 2;
        
        uint256 keep = redeemResult - returnToUser;
        
        cDAIFees += keep;
        
        uint256 nexenTokensToReturn = redeemResult * 100 / 14;

        NexenToken.transferFrom(address(this), msg.sender, nexenTokensToReturn);

        CErc20 cDAIToken = CErc20(cDAI);
        cDAIToken.transferFrom(address(this), msg.sender, returnToUser);
    }
    
    function redeemUSDT() public {
        Supply storage supply = USDTSupplies[msg.sender];
        
        require(supply.exists, 'Invalid caller');

        uint256 redeemResult = redeemCErc20Tokens(supply.totaltokens, true, cUSDT);
        
        uint256 returnToUser = redeemResult / 2;
        
        uint256 keep = redeemResult - returnToUser;
        
        cUSDTFees += keep;
        
        uint256 nexenTokensToReturn = redeemResult * 100 / 14;

        NexenToken.transferFrom(address(this), msg.sender, nexenTokensToReturn);
        
        CErc20 cUSDTToken = CErc20(cUSDT);
        cUSDTToken.transferFrom(address(this), msg.sender, returnToUser);
    }
    
    event MyLog(string, uint256);

    function supplyEthToCompound(address payable _cEtherContract)
        public payable
        returns (uint256)
    {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        uint256 balance = cToken.balanceOf(address(this));

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up by 1e18)", supplyRateMantissa);

        cToken.mint{value:msg.value, gas: 250000}();
        return cToken.balanceOf(address(this)) - balance;
    }
    
    function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _numTokensToSupply
    ) public returns (uint) {
        // Create a reference to the underlying asset contract, like DAI.
        IERC20 underlying = IERC20(_erc20Contract);

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up)", supplyRateMantissa);

        // Approve transfer on the ERC20 contract
        underlying.approve(_cErc20Contract, _numTokensToSupply);

        // Mint cTokens
        uint mintResult = cToken.mint(_numTokensToSupply);
        return mintResult;
    }

    function redeemCErc20Tokens(
        uint256 amount,
        bool redeemType,
        address _cErc20Contract
    ) public returns (uint256) {
        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // `amount` is scaled up, see decimal table here:
        // https://compound.finance/docs#protocol-math

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/developers/ctokens#ctoken-error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return redeemResult;
    }

    function redeemCEth(
        uint256 amount,
        bool redeemType,
        address _cEtherContract
    ) public returns (uint256) {
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#ctoken-error-codes
        emit MyLog("If this is not 0, there was an error", redeemResult);

        return redeemResult;
    }
    
    function withdrawFees() public { //onlyOwner
        CEth cETHToken = CEth(cETH);
        CErc20 cDAIToken = CErc20(cDAI);
        CErc20 cUSDTToken = CErc20(cUSDT);

        uint256 totalcETHFees = cETHFees;
        cETHFees = 0;
        
        cETHToken.transfer(msg.sender, totalcETHFees);

        uint256 totalcDAIFees = cDAIFees;
        cDAIFees = 0;
        
        cDAIToken.transfer(msg.sender, totalcDAIFees);

        uint256 totalcUSDTFees = cUSDTFees;
        cUSDTFees = 0;
        
        cUSDTToken.transfer(msg.sender, totalcUSDTFees);
    }

    // This is needed to receive ETH when calling `redeemCEth`
    receive() external payable {}
}