pragma solidity ^0.4.24;

// File: node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/MyanmarDonations.sol

// ----------------------------------------------------------------------------
// MyanmarDonations - Donations Contract to help people due to Myanmar flood
//
// Copyright (c) 2018 InfoCorp Technologies Pte Ltd.
// http://www.sentinel-chain.org/
//
// The MIT Licence.
// ----------------------------------------------------------------------------

pragma solidity ^0.4.24;


contract MyanmarDonations{

    // SENC Token Address
    address public SENC_CONTRACT_ADDRESS = 0xA13f0743951B4f6E3e3AA039f682E17279f52bc3;
    // Donation Wallet Address
    address public donationWallet;
    // Foundation Wallet Address
    address public foundationWallet;
    // Start time for donation campaign
    uint256 public startDate;
    // End time for donation campaign
    uint256 public endDate;
    // SENC-ETH pegged rate based on EOD rate of the 8nd August from coingecko in Wei
    uint256 public sencEthRate;

    // Ether hard cap
    uint256 public ETHER_HARD_CAP;
    // InfoCorp committed ETH donation amount
    uint256 public INFOCORP_DONATION;
    // Total Ether hard cap to receive
    uint256 public TOTAL_ETHER_HARD_CAP;
    // Total of SENC collected at the end of the donation
    uint256 public totalSencCollected;
    // Marks the end of the donation.
    bool public finalized = false;

    uint256 public sencHardCap;

    modifier onlyDonationAddress() {
        require(msg.sender == donationWallet);
        _;
    }

    constructor(                           
                address _donationWallet, //0xB4ea16258020993520F59cC786c80175C1b807D7
                address _foundationWallet, //0x2c76E65d3b3E38602CAa2fAB56e0640D0182D8F8
                uint256 _startDate, //1534125600 [2018-08-13 10:00:00 (GMT +8)]
                uint256 _endDate, //1534327200 [2018-08-15 18:00:00 (GMT +8)]
                uint256 _sencEthRate, // 40187198103877
                uint256 _etherHardCap,
                uint256 _infocorpDonation
                ) public {
        donationWallet = _donationWallet;
        foundationWallet = _foundationWallet;
        startDate = _startDate;
        endDate = _endDate;
        sencEthRate = _sencEthRate;
        ETHER_HARD_CAP = _etherHardCap;
        sencHardCap = ETHER_HARD_CAP * 10 ** 18 / sencEthRate;
        INFOCORP_DONATION = _infocorpDonation;

        TOTAL_ETHER_HARD_CAP = ETHER_HARD_CAP + INFOCORP_DONATION;
    }

    /// @notice Receive initial funds.
    function() public payable {
        require(msg.value == TOTAL_ETHER_HARD_CAP);
        require(
            address(this).balance <= TOTAL_ETHER_HARD_CAP,
            "Contract balance hardcap reachead"
        );
    }

    /**
     * @notice The `finalize()` should only be called after donation
     * hard cap reached or the campaign reached the final day.
     */
    function finalize() public onlyDonationAddress returns (bool) {
        require(getSencBalance() >= sencHardCap || now >= endDate, "SENC hard cap rached OR End date reached");
        require(!finalized, "Donation not already finalized");
        // The Ether balance collected in Wei
        totalSencCollected = getSencBalance();
        if (totalSencCollected >= sencHardCap) {
            // Transfer of donations to the donations address
            donationWallet.transfer(address(this).balance);
        } else {
            uint256 totalDonatedEthers = convertToEther(totalSencCollected) + INFOCORP_DONATION;
            // Transfer of donations to the donations address
            donationWallet.transfer(totalDonatedEthers);
            // Transfer ETH remaining to foundation
            claimTokens(address(0), foundationWallet);
        }
        // Transfer SENC to foundation
        claimTokens(SENC_CONTRACT_ADDRESS, foundationWallet);
        finalized = true;
        return finalized;
    }

    /**
     * @notice The `claimTokens()` should only be called after donation
     * ends or if a security issue is found.
     * @param _to the recipient that receives the tokens.
     */
    function claimTokens(address _token, address _to) public onlyDonationAddress {
        require(_to != address(0), "Wallet format error");
        if (_token == address(0)) {
            _to.transfer(address(this).balance);
            return;
        }

        ERC20Basic token = ERC20Basic(_token);
        uint256 balance = token.balanceOf(this);
        require(token.transfer(_to, balance), "Token transfer unsuccessful");
    }

    /// @notice The `sencToken()` is the getter for the SENC Token.
    function sencToken() public view returns (ERC20Basic) {
        return ERC20Basic(SENC_CONTRACT_ADDRESS);
    }

    /// @notice The `getSencBalance()` retrieve the SENC balance of the contract in Wei.
    function getSencBalance() public view returns (uint256) {
        return sencToken().balanceOf(address(this));
    }

    /// @notice The `getTotalDonations()` retrieve the Ether balance collected so far in Wei.
    function getTotalDonations() public view returns (uint256) {
        return convertToEther(finalized ? totalSencCollected : getSencBalance());
    }
    
    /// @notice The `setEndDate()` changes unit timestamp on wich de donations ends.
    function setEndDate(uint256 _endDate) external onlyDonationAddress returns (bool){
        endDate = _endDate;
        return true;
    }

    /**
     * @notice The `convertToEther()` converts value of SENC Tokens to Ether based on pegged rate.
     * @param _value the amount of SENC to be converted.
     */
    function convertToEther(uint256 _value) public view returns (uint256) {
        return _value * sencEthRate / 10 ** 18;
    }

}