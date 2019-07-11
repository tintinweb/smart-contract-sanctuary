/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.5.0;


// Safe math
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
     //not a SafeMath function
    function max(uint a, uint b) private pure returns (uint) {
        return a > b ? a : b;
    }
    
}


// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// Owned contract
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

/// @title  Version 0.1 of the InchWorm Contract, which allows INCH tokens to be traded for Dai and Ether at an adjustable peg. 
/// @author Fakuterin
/// @notice In order to use, permission must be given to the Dai token contract and the InchWorm token contract.
///         Call the "allow" function on each, passing this address and the number of tokens to allow as parameters.
///         Use the 4 withdrawel and deposit functions in your this contract to buy and sell INCH for Ether and Dai
///         Because there is no UI for this contract, KEEP IN MIND THAT ALL VALUES ARE IN MINIMUM DENOMINATIONS
///         IN OTHER WORDS ALL TOKENS UNCLUDING ETHER ARE DISPLAYED AND INPUT AS 10^-18 * THE BASE UNIT OF CURRENCY
///         Other warnings: This is a test contract. Do not risk any significant value. You are not guaranteed a 
///         refund, even if it&#39;s my fault. Do not send any tokens or assets directly to the contract. 
///         DO NOT SEND ANY TOKENS OR ASSETS DIRECTLY TO THE CONTRACT. Use only the withdrawel and deposit functions
/// @dev    Addresses and &#39;deployership&#39; should be initialized before use. INCH must be deposited in contract
///         Ownership should be set to 0x0 after initialization
contract InchWormVaultLiveTest is Owned {
    using SafeMath for uint;


    event SellInchForWei(uint inch, uint _wei);
    event SellInchForDai(uint inch, uint dai);
    event BuyInchWithWei(uint inch, uint _wei);
    event BuyInchWithDai(uint inch, uint dai);
    event PremiumIncreased(uint inchSold, uint premiumIncrease);

    // The premium controls both the INCH/Dai price and the INCH/ETH price. It increases as fees are paid. If 1 dai 
    // worth of fees are paid  and there are 10 circulating tokens, the premium will increase by 100,000,
    // or 10% of the base premium. The premium may decrease as the peg changes over time
    uint public premium = 1000000; 
    
    // Used for internal calculations. Represents the initial value of premium
    uint internal constant premiumDigits = 1000000;
    
    // The etherPeg controls the Dai/ETH price. There is no way to exchange Dai and ETH directly, so the peg actually changes the rate of 
    // INCH/Dai and INCH/ETH simultaneously. The peg can be increased or decreased by increments of 2%, given certain global conditions
    uint public etherPeg = 300;
    
    // Used for internal mathematics, represents fee rate. Fees = (10,000 - conserveRate)/100
    uint internal constant conserveRate = 9700; //out of 10,000
    uint internal constant conserveRateDigits = 10000;
    
    // Defines the minimum time to wait in between Dai/Ether peg adjustments
    uint public pegMoveCooldown = 12 hours; 
    // Represents the next unix time that a call can be made to the increase and decrease peg functions
    uint public pegMoveReadyTime;
    
    ERC20Interface inchWormContract; // must be initialized to the ERC20 InchWorm Contract
    ERC20Interface daiContract; // must be initialized to the ERC20 Dai Contract (check on compatitbility with MCD)
    
    // Retains ability to transfer mistaken ERC20s after ownership is revoked. Recieves portion of fees. In future versions
    // these fees will be distributed to holders of the "Ownership Token", and not to the deployer.
    address payable deployer; 
    
    
    // Formula: premium += (FeeAmountInDai *1000000) / CirculatingSupplyAfterTransaction
    
    /// @param  _inchFeesPaid: the amount of INCH sent to this contract, which adjusts the premium using the same logic as used in withdrawal 
    ///         methods below.
    /// @notice This method allows other contracts to buy into the InchWorm System. They can pay INCH in order to adjust the 
    ///         premium, allowing them to create vaults which can hold ERC20 assets instead of Ether.
    function increasePremium(uint _inchFeesPaid) external {
        //need to get permissions for this. AddOnVault needs to approve vault address for payments
        inchWormContract.transferFrom(msg.sender, address(this), _inchFeesPaid);
        
        uint _premiumIncrease = _inchFeesPaid.mul(premium).div((inchWormContract.totalSupply().sub(inchWormContract.balanceOf(address(this)))));
        premium = premium.add(_premiumIncrease);
    }
    
    
    
    
    
    /*____________________________________________________________________________________*/
    /*______________________________Inititialization Functions____________________________*/
    
    /// @param  _inchwormAddress: deployment address of the InchWorm contract
    /// @param  _daiAddress: deployment address of the ERC20 Dai token contract
    /// @param  _deployer: address of initial deployer. Receives fees and can transfer unrelated ERC20s
    /// @notice Sets the address for the INCH and Dai tokens, as well as the deployer
    ///         Sets the pegMoveReadyTime to now, allowing the peg to be moved immediately (if balances are correct)
    function initialize(address _inchwormAddress, address _daiAddress, address payable _deployer) external onlyOwner {
        inchWormContract = ERC20Interface(_inchwormAddress);
        daiContract = ERC20Interface(_daiAddress);
        deployer = _deployer;
        pegMoveReadyTime = now;
    }
    

    /*^__^__^__^__^__^__^__^__^__^__Inititialization Functions__^__^__^__^__^__^__^__^__^ */
    /*____________________________________________________________________________________*/
    
    
    
    
    
    
    /*____________________________________________________________________________________*/
    /*_________________________________Peg Functions______________________________________*/
    
    /// @notice A public call to increase the peg by 4%. Can only be called once every 12 hours, and only if
    ///         there is there is <= 2% as much Ether value in the contract as there is Dai value.
    ///         Example: with a peg of 100, and 10000 total Dai in the vault, the ether balance of the
    ///         vault must be less than or equal to 2 to execute this function.
    function increasePeg() external {
        // check that the total value of eth in contract is <= 2% the total value of dai in the contract
        require (address(this).balance.mul(etherPeg) <= daiContract.balanceOf(address(this)).div(50)); 
        // check that peg hasn&#39;t been changed in last 12 hours
        require (now > pegMoveReadyTime);
        // increase peg
        etherPeg = etherPeg.mul(104).div(100);
        // reset cooldown
        pegMoveReadyTime = now+pegMoveCooldown;
    }
    
    /// @notice A public call to decrease the peg by 4%. Can only be called once every 12 hours, and only if
    ///         there is there is < 2% as much Dai value in the contract as there is Ether value.
    ///         Example: with a peg of 100, and 100 total Ether in the vault, the dai balance of the
    ///         vault must be less than or equal to 200 to execute this function. 
    function decreasePeg() external {
         // check that the total value of eth in contract is <= 2% the total value of dai in the contract
        require (daiContract.balanceOf(address(this)) <= address(this).balance.mul(etherPeg).div(50));
        // check that peg hasn&#39;t been changed in last 12 hours
        require (now > pegMoveReadyTime);
        // increase peg
        etherPeg = etherPeg.mul(96).div(100);
        // reset cooldown
        pegMoveReadyTime = now+pegMoveCooldown;
        
        premium = premium.mul(96).div(100);
    }
    
    /* ^__^__^__^__^__^__^__^__^__^__^__^__Peg Functions__^__^__^__^__^__^__^__^__^__^__^ */
    /*____________________________________________________________________________________*/
    
    
    
    
    /*____________________________________________________________________________________*/
    /*__________________________Deposit and Withdrawel Functions_________________________ */
    // All functions begin with __ in order to help with organization. Will be changed after UI is developed

    /// @notice All units are minimum denomination, ie base unit *10**-18
    ///         Use this payable function to buy INCH from the contract with Wei. Rates are based on premium
    ///         and etherPeg. For every Wei deposited, msg.sender recieves etherPeg/(0.000001*premium) INCH.
    ///         Example: If the peg is 100, and the premium is 2000000, msg.sender will recieve 50 INCH.
    /// @dev    Transaction reverts if payment results in 0 INCH returned
    function __buyInchWithWei() external payable {
        // Calculate the amount of inch give to msg.sender
        uint _inchToBuy = msg.value.mul(etherPeg).mul(premiumDigits).div(premium);
        // Require that INCH returned is not 0
        require(_inchToBuy > 0);
        // Transfer INCH to Purchaser
        inchWormContract.transfer(msg.sender, _inchToBuy);
        
        emit BuyInchWithWei(_inchToBuy, msg.value);
    }
    
    /// @param  _inchToBuy: amount of INCH (in mininum denomination) msg.sender wishes to purchase
    /// @notice All units are in minimum denomination, ie base unit *10**-18
    ///         Use this payable to buy INCH from the contract using Dai. Rates are based on premium.
    ///         For every Dai deposited, msg.sender recieves 1/(0.000001*premium) INCH.
    ///         Example: If the premium is 5000000, calling the function with input 1 will result in 
    ///         msg.sender paying 5 DaiSats. 
    function __buyInchWithDai(uint _inchToBuy) external {
        // Calculate the amount of Dai to extract from the purchaser&#39;s wallet based on the premium
        uint _daiOwed = _inchToBuy.mul(premium).div(premiumDigits);
        // Take Dai from the purchaser and transfer to vault contract
        daiContract.transferFrom(msg.sender, address(this), _daiOwed);
        // Send INCH to purchaser
        inchWormContract.transfer(msg.sender, _inchToBuy);
        
        emit BuyInchWithDai(_inchToBuy, _daiOwed);
    }
    
    
    /// @param  _inchToSell: amount of INCH (in mininum denomination) msg.sender wishes to sell to the vault contract
    /// @notice All units are in minimum denomination, ie base unit *10**-18
    ///         Use this payable to sell INCH to the contract and withdraw Wei. Rates are based on premium and etherPeg.
    ///         Fees are paid automatically and increase the premium for remaining tokens. Fee is currently 3%
    ///         For every Inch sold, msg.sender recieves (0.97 * 0.000001*premium) / (etherPeg)   Ether.
    ///         Example: If the peg is 100, and the premium is 2000000, each unit of INCHSat sold will return 0.0194 Wei. 
    ///         Because fractions of a Wei are not possible, no value will be returned for miniscule sales of INCH
    ///         With a peg of 100, values of less than 104 will return 0
    /// @dev    Future versions may add a require (_etherToReturn >0). This should be an edge case. However, rounding 
    ///         will still result in negligible losses for user. This could be fixed by rounding user input down to the nearest
    ///         viable withdrawal amount. 
    ///         Premium increases are functionally the same as distributing fees to all remaining INCH tokens
    function __sellInchForEth(uint _inchToSell) external {
        // Deduct fee (currenly 3%)
        uint _trueInchToSell = _inchToSell.mul(conserveRate).div(conserveRateDigits);
        // Calculate Ether to send to user based on premium and peg
        uint _etherToReturn = _trueInchToSell.mul(premium).div(premiumDigits.mul(etherPeg));
       
        // Send Ether to user
        msg.sender.transfer(_etherToReturn);
        // Deposit INCH from user into vault
        inchWormContract.transferFrom(msg.sender, address(this), _inchToSell);
        // Transfer 1% to deployer. In the future, this will go to holders of the "ownership Token"
        uint _deployerPayment = _inchToSell.mul(100).div(10000).mul(premium).div(premiumDigits.mul(etherPeg));
        deployer.transfer(_deployerPayment);
        
        // Increase the premium. Premium increases are based on fees. It is functionally equivalent to distributing the fee to 
        // remaining INCH tokens in the form of a redeemable dividend. Example: Given 1 Ether worth of fees paid and a peg of 100.
        // Convert to dai value, so fees = 100 Dai. If 1000 tokens remain after the transaction, the premium must increase by an amount
        // such that each INCH is worth 0.1 more Dai. If the premium was previously 1500000, then the new premium should be 1600000.
        // Formula: premium += (FeeAmountInDai *1000000) / CirculatingSupplyAfterTransaction
        uint _premiumIncrease = _inchToSell.sub(_trueInchToSell).mul(premium).div(inchWormContract.totalSupply().sub(inchWormContract.balanceOf(address(this))));
        premium = premium.add(_premiumIncrease);
        
        emit PremiumIncreased(_inchToSell, _premiumIncrease);
        emit SellInchForWei(_inchToSell, _etherToReturn);
    }
    
    
    
    /// @param  _inchToSell: amount of INCH (in mininum denomination) msg.sender wishes to sell to the vault contract
    /// @notice All units are in minimum denomination, ie base unit *10**-18
    ///         Use this payable to sell INCH to the contract and withdraw Dai. Rates are based on premium.
    ///         Fees are paid automatically and increase the premium for remaining tokens. Fee is currently 3%
    ///         For every Inch sold, msg.sender recieves (0.97 * 0.000001*premium) Dai.
    ///         Example: If the premium is 5000000, each unit of INCHSat sold will return 4.85 DaiSat. 
    ///         Because fee functions round down, this does not work for low values of INCHSat. For instance, a single 
    ///         INCHSat will return 0 DaiSats and 101 INCHSats will return 485, instead of 489.85 INCHSats
    /// @dev    Rounding down for minimum denomination units will result in negligible losses for user. 
    ///         Premium increases are functionally the same as distributing fees to all remaining INCH tokens
    function __sellInchForDai(uint _inchToSell) external {
        // Deduct fee (currenly 3%). Rounds down to nearest INCH. Input of 1 will return 0. Input of 3 will return 2
        // Input of 101 will return 97
        uint _trueInchToSell = _inchToSell.mul(conserveRate).div(conserveRateDigits);
        // Calculate Dai to send to user based on premium
        uint _daiToReturn = _trueInchToSell.mul(premium).div(premiumDigits);
        
        // Send Dai to user
        daiContract.transfer(msg.sender, _daiToReturn);
        // Deposit INCH from user into vault
        inchWormContract.transferFrom(msg.sender, address(this), _inchToSell);
        // Transfer 1% to deployer. In the future, this will go to holders of the "ownership Token"
        uint _deployerPayment = _inchToSell.mul(100).div(10000).mul(premium).div(premiumDigits);
        daiContract.transfer(deployer, _deployerPayment);
        
        // Increase the premium. Premium increases are based on fees. It is functionally equivalent to distributing the fee to 
        // remaining INCH tokens in the form of a redeemable dividend. Example: Given 100 Dai worth of fees paid  and 5000 tokens
        // remaining after the transaction, the premium must increase by an amount such that each INCH is worth 0.02 more Dai.
        // If the premium was previously 2000000, then the new premium should be 2020000.
        // Formula: premium += (FeeAmountInDai *1000000) / CirculatingSupplyAfterTransaction
        uint _premiumIncrease = _inchToSell.sub(_trueInchToSell).mul(premium).div(inchWormContract.totalSupply().sub(inchWormContract.balanceOf(address(this))));
        premium = premium.add(_premiumIncrease);
        
        emit PremiumIncreased(_inchToSell, _premiumIncrease);
        emit SellInchForDai(_inchToSell, _daiToReturn);
    }
    
    /* ^__^__^__^__^__^__^__^__Deposit and Withdrawel Functions__^__^__^__^__^__^__^__^__^*/
    /*____________________________________________________________________________________*/
    
    
    
    
    /*____________________________________________________________________________________*/
    /*___________________________________View Functions___________________________________*/
    

    /// @return The current premium, which is initially 1,000,000
    /// @notice The premium changes the rate at which INCH is exchanged for Dai and Ether
    function getPremium() external view returns(uint){
        return premium;
    } 
    
    /// @return The percentage fee that is paid when withdrawing Ether or Dai
    function getFeePercent() external pure returns(uint) {
        return (conserveRateDigits - conserveRate)/100;    
    }
    
    function canPegBeIncreased() external view returns(bool) {
        return (address(this).balance.mul(etherPeg) <= daiContract.balanceOf(address(this)).div(50) && (now > pegMoveReadyTime)); 
    }
    
    /// @return true if a call can be made to decrease peg
    function canPegBeDecreased() external view returns(bool) {
        return (daiContract.balanceOf(address(this)) <= address(this).balance.mul(etherPeg).div(50) && (now > pegMoveReadyTime));
    }
    
    /// @return true if a call can be made to increase peg
    function vzgetCirculatingSupply() public view returns(uint) {
        return inchWormContract.totalSupply().sub(inchWormContract.balanceOf(address(this)));
    }
    
    
    /// @return The amount of ETH you will get after selling X INCH
    function afterFeeEthReturns(uint _inchToSell) public view returns(uint) {
        uint _trueInchToSell = _inchToSell.mul(conserveRate).div(conserveRateDigits);
        return _trueInchToSell.mul(premium).div(premiumDigits.mul(etherPeg));
    }
    
    /// @return The amount of ETH you will get after selling X INCH
    function afterFeeDaiReturns(uint _inchToSell) public view returns(uint) {
        uint _trueInchToSell = _inchToSell.mul(conserveRate).div(conserveRateDigits);
        return _trueInchToSell.mul(premium).div(premiumDigits);
    }
    
    /// @return The Wei balance of the vault contract
    ///         ALL TOKENS UNCLUDING ETHER ARE DISPLAYED AS 10^-18 * THE BASE UNIT OF CURRENCY
    function getEthBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    /// @return The INCH balance of the vault contract
    ///         ALL TOKENS UNCLUDING ETHER ARE DISPLAYED AS 10^-18 * THE BASE UNIT OF CURRENCY
    function getInchBalance() public view returns(uint) {
        return inchWormContract.balanceOf(address(this));
    }
    
    /// @return The Dai balance of the vault contract
    ///         ALL TOKENS UNCLUDING ETHER ARE DISPLAYED AS 10^-18 * THE BASE UNIT OF CURRENCY
    function getDaiBalance() public view returns(uint) {
        return daiContract.balanceOf(address(this));
    }
    
    /// @param _a: the address to check balance of
    /// @return INCH balance of target address
    /// @notice This is just the balanceOf function from inchWormContract. Put here for ease of access
    function getOwnerInch(address _a) public view returns(uint) {
        return inchWormContract.balanceOf(_a);
    }
    
    /* ^__^__^__^__^__^__^__^__^__^__^__View Functions__^__^__^__^__^__^__^__^__^__^__^__^*/
    /*____________________________________________________________________________________*/


    
    
    /*____________________________________________________________________________________*/
    /*__________________________Emergency and Fallback Functions__________________________*/
    
    /// @notice Original deployer can transfer out tokens other than Dai and INCH
    /// @dev    This function can be used to steal funds if there is any way to alter the inchWormContract address or daiContract address
    function transferAccidentalERC20Tokens(address tokenAddress, uint tokens) external returns (bool success) {
        require(msg.sender == deployer);
        require(tokenAddress != address(inchWormContract));
        require(tokenAddress != address(daiContract));
        
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // fallback function
    function () external payable {
        revert();
    }
    
    /* ^__^__^__^__^__^__^__^__emergency and fallback functions__^__^__^__^__^__^__^__^__^*/
    /*____________________________________________________________________________________*/
    
}