pragma solidity ^0.4.18;
 
/**
 * Copyright 2018, Flowchain.co
 *
 * The FlowchainCoin (FLC) smart contract of private sale Round A
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface Token {
    function mintToken(address to, uint amount) external returns (bool success);  
    function setupMintableAddress(address _mintable) public returns (bool success);
}

contract MintableSale {
    // @notice Create a new mintable sale
    /// @param rate The exchange rate
    /// @param fundingGoalInEthers The funding goal in ethers
    /// @param durationInMinutes The duration of the sale in minutes
    /// @return 
    function createMintableSale(uint256 rate, uint256 fundingGoalInEthers, uint durationInMinutes) external returns (bool success);
}

contract EarlyTokenSale is MintableSale {
    using SafeMath for uint256;
    uint256 public fundingGoal;
    uint256 public tokensPerEther;
    uint public deadline;
    address public multiSigWallet;
    uint256 public amountRaised;
    Token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    address public creator;
    address public addressOfTokenUsedAsReward;
    bool public isFunding = false;

    /* accredited investors */
    mapping (address => uint256) public accredited;

    event FundTransfer(address backer, uint amount);

    /* Constrctor function */
    function EarlyTokenSale(
        address _addressOfTokenUsedAsReward
    ) payable {
        creator = msg.sender;
        multiSigWallet = 0x9581973c54fce63d0f5c4c706020028af20ff723;
        // Token Contract
        addressOfTokenUsedAsReward = _addressOfTokenUsedAsReward;
        tokenReward = Token(addressOfTokenUsedAsReward);
        // Setup accredited investors
        setupAccreditedAddress(0xec7210E3db72651Ca21DA35309A20561a6F374dd, 1000);
    }

    // @dev Start a new mintable sale.
    // @param rate The exchange rate in ether, for example 1 ETH = 6400 FLC
    // @param fundingGoalInEthers
    // @param durationInMinutes
    function createMintableSale(uint256 rate, uint256 fundingGoalInEthers, uint durationInMinutes) external returns (bool success) {
        require(msg.sender == creator);
        require(isFunding == false);
        require(rate <= 6400 && rate >= 1);                   // rate must be between 1 and 6400
        require(fundingGoalInEthers >= 1000);        
        require(durationInMinutes >= 60 minutes);

        deadline = now + durationInMinutes * 1 minutes;
        fundingGoal = amountRaised + fundingGoalInEthers * 1 ether;
        tokensPerEther = rate;
        isFunding = true;
        return true;    
    }

    modifier afterDeadline() { if (now > deadline) _; }
    modifier beforeDeadline() { if (now <= deadline) _; }

    /// @param _accredited The address of the accredited investor
    /// @param _amountInEthers The amount of remaining ethers allowed to invested
    /// @return Amount of remaining tokens allowed to spent
    function setupAccreditedAddress(address _accredited, uint _amountInEthers) public returns (bool success) {
        require(msg.sender == creator);    
        accredited[_accredited] = _amountInEthers * 1 ether;
        return true;
    }

    /// @dev This function returns the amount of remaining ethers allowed to invested
    /// @return The amount
    function getAmountAccredited(address _accredited) view returns (uint256) {
        uint256 amount = accredited[_accredited];
        return amount;
    }

    function closeSale() beforeDeadline {
        require(msg.sender == creator);    
        isFunding = false;
    }

    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender == creator);
        creator = _creator;
    }

    /// @dev This function returns the current exchange rate during the sale
    /// @return The address of token creator
    function getRate() beforeDeadline view returns (uint) {
        return tokensPerEther;
    }

    /// @dev This function returns the amount raised in wei
    /// @return The address of token creator
    function getAmountRaised() view returns (uint) {
        return amountRaised;
    }

    function () payable {
        // check if we can offer the private sale
        require(isFunding == true && amountRaised < fundingGoal);

        // the minimum deposit is 1 ETH
        uint256 amount = msg.value;        
        require(amount >= 1 ether);

        require(accredited[msg.sender] - amount >= 0); 

        multiSigWallet.transfer(amount);      
        balanceOf[msg.sender] += amount;
        accredited[msg.sender] -= amount;
        amountRaised += amount;
        FundTransfer(msg.sender, amount);

        uint256 value = amount.mul(tokensPerEther);        
        tokenReward.mintToken(msg.sender, value);        
    }
}