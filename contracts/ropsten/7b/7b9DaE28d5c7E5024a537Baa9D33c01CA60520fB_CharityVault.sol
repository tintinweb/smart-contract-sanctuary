/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;


//Idea: No-loss Lending Charity Vault/Lock

//Create Vault for Charity,-Emit
//Users deposit funds(token/Eth) into Vault -Emit
//Funds get locked and sent to Lending(Compound) for X days -Emit
//After X days, withdraw said Funds by input -Emit
//Send funds back to users of Vault & close Vault -Emit

//Send interest(Token/Eth) to Charity -Emit

//Additional to implement:
//Chainlink Oracle for Lending Rates
//NFT to User for POD(Proof-Of-Donation)
//List of Charities that are approved
//DAO that approves Vault on creation
//Send COMP(fee) to DAO


interface Erc20 {
    function approve(address, uint256) external returns (bool);

    function transfer(address, uint256) external returns (bool);
}

interface CErc20 {
    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}


interface CEth {
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);
}

contract CharityVault {
    
        //Events
    event VaultCreated(address user, uint value, address token);
    event AddedToVault(address _from, uint _value, address token);
    event FundsSentBack(uint vaultId, uint _value, address token);
    
    event CharityFundsSent(uint vaultId, uint _value, address token);
    event CharityAdded(address charityAddress);
    
    struct Vault {
        string name;
        string description;
        address payable[] users;
        address payable charityAddress;
        uint256 amountAvailable;
        uint256 donationPerUser;    
        uint userGoal;    
        uint unlockDate;
        uint startingRate;
        uint endingRate;
        bool open_for_deposit;
        bool ethVault;
        string token;
    }
    
    //Vaults Overall
    uint totalVaults;
    mapping(uint256 => Vault) public vaults;
    mapping(address => uint256) public balance;
    address devAddress;
    mapping (address => bool) public allowedAddresses;  

    //Compound tokens

    address _cEtherContract; //cEth
    address _cErc20ContractUSDT; //cUSDT
    address _cErc20ContractUSDC; //cUSDC
    address _cErc20ContractDAI; //cDAI
    address _cErc20ContractTUSD; //cTUSD
    
    
    constructor() {
        _cEtherContract = payable(0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8); //0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8-Ropsten cEth address
        //_cErc20ContractUSDT = payable(0xf6958cf3127e62d3eb26c79f4f45d3f3b2ccded4); //ropsten
        //_cErc20ContractUSDC = payable(0x2973e69b20563bcc66dc63bde153072c33ef37fe); //ropsten
        //_cErc20ContractDAI = payable(0xbc689667c13fb2a04f09272753760e38a95b998c); //ropsten
        //_cErc20ContractTUSD = payable(0x12392f67bdf24fae0af363c24ac620a2f67dad86); //mainnet
        devAddress = payable(msg.sender);
    }
    
    
    
    function createVault(
        string memory name,
        string memory description,
        uint donationPerUser,
        uint userGoal,
        address payable charityAddress,
        bool ethVault, 
        uint daysLocked
        ) public returns(uint256 vaultId) {
            Vault storage vault = vaults[totalVaults];
            
            vault.name = name;
            vault.description = description;
            vault.donationPerUser = donationPerUser;
            vault.charityAddress = charityAddress;
            vault.open_for_deposit = true;
            vault.userGoal = userGoal;
            vault.ethVault = ethVault;
            vault.unlockDate = getBlockTimestamp(daysLocked);
            totalVaults += 1;
            
            //emit VaultCreated(totalVaults - 1, name);
            return totalVaults - 1;
        }

        
    function addAmount(uint vaultId) 
        public 
        payable 
        {
        Vault storage vault = vaults[vaultId];
        require (vault.open_for_deposit, 'can only deposit when the vault is open');
        if(vault.ethVault == true)
        {
            require(msg.value == vault.donationPerUser, 'can only donate exactly the set size');
            vault.users.push(payable(msg.sender));
            //emit DonationSent(msg.sender, msg.value);
            vault.amountAvailable += msg.value;
            
            if(vault.users.length == vault.userGoal)
            {
                supplyEthToCompound(vaultId);
            }
        }
        
    }
    
    function supplyEthToCompound(uint256 vaultId)
        public
        payable
        returns (bool)
    {
        Vault storage vault = vaults[vaultId];
        // Create a reference to the corresponding cToken contract
        CEth cToken = CEth(_cEtherContract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        //emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        //uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        //emit MyLog("Supply Rate: (scaled up by 1e18)", supplyRateMantissa);
        vault.open_for_deposit = false;
        cToken.mint{ value: vault.amountAvailable, gas: 250000 }();
        
        vault.startingRate = exchangeRateMantissa;
        return true;
    }
    
     function redeemCEth(
            uint256 vaultId,
            bool redeemByAmount
        ) public returns (bool) {
            Vault storage vault = vaults[vaultId];
            uint currentTime = getBlockTimestamp(0);
            require(vault.unlockDate < currentTime, 'It is not time yet');
            // Create a reference to the corresponding cToken contract
            CEth cToken = CEth(_cEtherContract);
    
            // `amount` is scaled up by 1e18 to avoid decimals
    
            uint256 redeemResult;
          

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        
            if (redeemByAmount == true) {//edited line for clarity - original being "redeemType"
                // Retrieve your asset based on a cToken amount
                redeemResult = cToken.redeem(vault.amountAvailable);
            } else {
                // Retrieve your asset based on an amount of the asset
                redeemResult = cToken.redeemUnderlying(vault.amountAvailable);
            }
            vault.endingRate = exchangeRateMantissa;

            // Error codes are listed here:
            // https://compound.finance/docs/ctokens#error-codes
            //emit MyLog("If this is not 0, there was an error", redeemResult);
            
            return true;
        }
    
        // This is needed to receive ETH when calling `redeemCEth`
        receive() external payable {}
        
    function distributeFundsBack(uint256 vaultId) external payable {
        Vault storage vault = vaults[vaultId];
        //require vault.unlockTime > getBlockTimestamp;
        redeemCEth(vaultId, false);
        uint256 amountPerUser = vault.donationPerUser;
        for (uint32 i; i < vault.users.length; i++) {
            vault.users[i].transfer(amountPerUser);
            vault.amountAvailable -= amountPerUser;
           
        }
    }
    
     function supplyErc20ToCompound(
        address _erc20Contract,
        address _cErc20Contract,
        uint256 _numTokensToSupply
    ) public returns (uint) {
        // Create a reference to the underlying asset contract, like DAI.
        Erc20 underlying = Erc20(_erc20Contract);

        // Create a reference to the corresponding cToken contract, like cDAI
        CErc20 cToken = CErc20(_cErc20Contract);

        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = cToken.exchangeRateCurrent();
        //emit MyLog("Exchange Rate (scaled up): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = cToken.supplyRatePerBlock();
        //emit MyLog("Supply Rate: (scaled up)", supplyRateMantissa);

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
    ) public returns (bool) {
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
        // https://compound.finance/docs/ctokens#error-codes
        //emit MyLog("If this is not 0, there was an error", redeemResult);
        
        return true;
    }

    function getBlockTimestamp(uint daysInput) public view returns (uint) {
        return block.timestamp + daysInput;
    }
    
    function getVaultCount() view public returns (uint) {
        return totalVaults;
    }

    function validateAddress( address _address) onlyAdmin external {
        allowedAddresses[_address] = true;
    }

    function invalidateAddress( address _address) onlyAdmin external {
        allowedAddresses[_address] = false;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == devAddress, 'only admin');
        _;
    }
    modifier isValidAddress(address _address){
        require(allowedAddresses[_address]);
        _;
    }
    
}