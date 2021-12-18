//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import './ERC20.sol';
import './Ownable.sol';
import './AggregatorV3Interface.sol';

/// @title A simple single IDO token sale contract
/// @author Morphware
/// @notice Opens an IDO token sale contract upon deployment. The deployer can end the IDO at any point.

contract SingleTokenSale is Ownable {

    ERC20 public tokenContract;

    uint256 public USDMWTTokenPrice = 10;
    uint256 public IDOTokenSupply;
    uint256 public maxTokensPerWallet;
    uint256 public tokensSold;

    //The decimal precision of the returned value from Chainlink. Using 8 Decimals for our Oracle (0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419) on https://docs.chain.link/docs/ethereum-addresses/
    uint256 public decimals;

    //Re-calculated each time in setEthPrice
    uint256 public ETHMWTExchangeRate;

    //Returned from the ETHUSDS chainlink data feed
    uint256 public ETHUSDPrice;

    //To hold the IDO state
    IDOState public currentState;

    //The Chainlink Oracle interface to get the ETHUSD data feed foods
    AggregatorV3Interface internal priceFeed;

    //Track how many tokens each wallet has bought
    mapping(address => uint256) public tokensBought;

    //Track whitlisted addresses. Only these addresses can buy tokens during theh OpenForWhitelisted IDO state
    mapping(address => bool) public whitelists;

    //All possible IDO states. Closed -> OpenForWhitelisted -> Open -> Closed
    enum IDOState {Closed, OpenForWhitelisted, Open}

    event Bought(uint256 amountTobuy);
    event IDOEnded(uint256 tokensSold);

    constructor(address _tokenContract, uint256 _IDOTokenSupply, uint256 _maxTokensPerWallet, address[] memory _whitelists) {
        tokenContract = ERC20(_tokenContract);
        IDOTokenSupply = _IDOTokenSupply;
        maxTokensPerWallet = _maxTokensPerWallet;
        currentState = IDOState.Closed;
        //The address of the Oracle we use for ETHUSD on Mainnet
        // priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        addWhitelistAddress(_whitelists);
    }

    function setupOracle() public onlyOwner {
        //The decimal precision for this Oracle. Its 8 - Look at  (0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419) on https://docs.chain.link/docs/ethereum-addresses/
        decimals = priceFeed.decimals();
        setETHMWTExchangeRate();
    }

    /// @notice Set the IDO state to "OpenForWhitelisted".
    function openToWhitelistedAddresses() public onlyOwner {
        currentState = IDOState.OpenForWhitelisted;
    }

    /// @notice Set the IDO state to "Open".
    function openToAllAddresses() public onlyOwner {
        currentState = IDOState.Open;
    }

    /// @notice Add an address to the whitelisted group
    function addWhitelistAddress(address[] memory _whitelists) public onlyOwner {
        for(uint i = 0; i < _whitelists.length; i++){
            whitelists[_whitelists[i]] = true;
        }
    }

    /// @notice Remove an address to the whitelisted group
    function removeWhiteList(address whiteList) public onlyOwner {
        whitelists[whiteList] = false;
    }

    /// @notice A payable function to buy tokens from the IDO
    /// @dev Uses the ETHMWT exchange rate to calculate the tokens to buy. Enforce sa maximum buyable token amount per wallet
    function buyTokens() public payable{
        require(currentState != IDOState.Closed, "IDO sale is currently closed");
        if(currentState == IDOState.OpenForWhitelisted) {
            require(whitelists[msg.sender], "This address is not whitelisted");
        }

        setETHMWTExchangeRate();

        require(msg.value > 0, "Ether sent needs to be non-negative");
        require(ETHMWTExchangeRate > 0, "ETHMWTExchangeRate cannot be negative");

        uint256 amountTobuy = msg.value * ETHMWTExchangeRate;
        uint256 IDOBalance = tokenContract.balanceOf(address(this));

        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= IDOBalance, "Not enough tokens in the reserve");
        require(tokensBought[msg.sender] + amountTobuy <= maxTokensPerWallet, "Cannot exceed maximum allowable tokens per wallet");
        require(tokenContract.transfer(msg.sender, amountTobuy));

        tokensBought[msg.sender] += amountTobuy;
        tokensSold += amountTobuy;

        emit Bought(amountTobuy);
        amountTobuy = 0;
    }

    /// @notice Ends the IDO token sale. Drain all ETH raised and MWT left in this IDO contract
    /// @return Boolean on successfully ending IDO
    function endIDOSale() public onlyOwner returns (bool) {
        withdrawRemainingTokens();
        withdrawTokenSaleFunds();
        currentState = IDOState.Closed;
        emit IDOEnded(tokensSold);
        return true;
    }

    /// @notice Sends all remaining IDO tokens back to deployer
    function withdrawRemainingTokens() private onlyOwner{
        if(tokenContract.balanceOf(address(this)) > 0) {
            require(tokenContract.transfer(owner(), tokenContract.balanceOf(address(this))));
        }
    }

    /// @notice Sends all IDO funds back to deployer address
    function withdrawTokenSaleFunds() public payable onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Get updated ETHUSD price from chainlink and calculate ETHMWT Exchange rate
    /// @dev Calculate and save the ETHMWT and ETHUSD exchange rate
    function setETHMWTExchangeRate() public {
        (
            , 
            int price,
            ,
            uint timeStamp,
        ) = priceFeed.latestRoundData();
        require(timeStamp > 0, "Round not complete");
        uint256 _ETHMWTExchangeRate = USDMWTTokenPrice * uint256(price) / 10**decimals;
        require(_ETHMWTExchangeRate > 0, "ETHMWTExchangeRate cannot be negative");
        ETHMWTExchangeRate = _ETHMWTExchangeRate;
        ETHUSDPrice = uint256(price);
    }

    receive() external payable{}
}