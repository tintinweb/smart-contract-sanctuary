pragma solidity ^0.4.24;

// File: node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

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



contract MyanmarDonations is Ownable {

    // SENC Token Address
    address public SENC_CONTRACT_ADDRESS = 0xA13f0743951B4f6E3e3AA039f682E17279f52bc3;
    // Exchange Wallet Address
    address public DONATION_WALLET = 0xB4ea16258020993520F59cC786c80175C1b807D7;
    // Foundation Wallet Address
    address public FOUNDATION_WALLET = 0x2c76E65d3b3E38602CAa2fAB56e0640D0182D8F8;
    // Start date: 2018-08-08 10:00:00 (GMT +8)
    uint256 public START_DATE = 1533693600;
    // End date:   2018-08-10 18:00:00 (GMT +8)
    uint256 public END_DATE = 1533895200;
    // Ether hard cap
    uint256 public ETHER_HARD_CAP = 30 ether;
    // InfoCorp donation
    uint256 public INFOCORP_DONATION = 30 ether;
    // Total Ether hard cap to receive
    uint256 public TOTAL_ETHER_HARD_CAP = ETHER_HARD_CAP + INFOCORP_DONATION;
    // SENC-ETH pegged rate based on EOD rate of the 2nd August from coingecko in Wei
    uint256 constant public FIXED_RATE = 41369152116499 wei;
    // 30 is the max cap in Ether
    uint256 public SENC_HARD_CAP = ETHER_HARD_CAP * 10 ** 18 / FIXED_RATE;
    // Total of SENC collected at the end of the donation
    uint256 public totalSencCollected;
    // Marks the end of the donation.
    bool public finalized = false;

    modifier onlyDonationAddress() {
        require(msg.sender == DONATION_WALLET);
        _;
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
        require(getSencBalance() >= SENC_HARD_CAP || now >= END_DATE, "SENC hard cap rached OR End date reached");
        require(!finalized, "Donation not already finalized");
        // The Ether balance collected in Wei
        totalSencCollected = getSencBalance();
        if (totalSencCollected >= SENC_HARD_CAP) {
            // Transfer of donations to the donations address
            DONATION_WALLET.transfer(address(this).balance);
        } else {
            uint256 totalDonatedEthers = convertToEther(totalSencCollected) + INFOCORP_DONATION;
            // Transfer of donations to the donations address
            DONATION_WALLET.transfer(totalDonatedEthers);
            // Transfer ETH remaining to foundation
            claimTokens(address(0), FOUNDATION_WALLET);
        }
        // Transfer SENC to foundation
        claimTokens(SENC_CONTRACT_ADDRESS, FOUNDATION_WALLET);
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
    function setEndDate(uint256 _endDate) external onlyOwner returns (bool){
        END_DATE = _endDate;
        return true;
    }

    /**
     * @notice The `convertToEther()` converts value of SENC Tokens to Ether based on pegged rate.
     * @param _value the amount of SENC to be converted.
     */
    function convertToEther(uint256 _value) private pure returns (uint256) {
        return _value * FIXED_RATE / 10 ** 18;
    }

}