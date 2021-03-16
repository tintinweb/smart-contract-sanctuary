pragma solidity >=0.5.0 <0.8.0;

import "IERC20.sol";
import "ERC20.sol";
import "SafeMath.sol";
import "Crowdsale.sol";
import "CappedCrowdsale.sol";
import "TimedCrowdsale.sol";
import "MintedCrowdsale.sol";
import "ERC20Mintable.sol";
import "ERC20Detailed.sol";



contract SWpLGE is ERC20, ERC20Detailed, ERC20Mintable {
    constructor() ERC20Detailed("SWENE preLGE", "SWpLGE", 18) public {

    }
}

contract SWpreLiquiditySale is Crowdsale, CappedCrowdsale, TimedCrowdsale, MintedCrowdsale {
    using SafeMath for uint256;
    constructor(
        uint256 rate,            // rate, in TKNbits
        address payable wallet,  // wallet to send Ether
        IERC20 token,            // the token
        uint256 cap,             // total cap, in wei
        uint256 openingTime,     // opening time in unix epoch seconds
        uint256 closingTime      // closing time in unix epoch seconds
    )
        CappedCrowdsale(cap)
        TimedCrowdsale(openingTime, closingTime)
        Crowdsale(rate, wallet, token)
        public
    {
        // nice, we just created a crowdsale that's only open
        // for a certain amount of time
        // and stops accepting contributions once it reaches `cap`
    }
}

contract SWpreLiquiditySaleDeployer {
    using SafeMath for uint256;
    ERC20Mintable token;            // the token
    address token_;
    uint256 cap;             // total cap, in wei
    uint256 openingTime;     // opening time in unix epoch seconds
    uint256 closingTime;      // closing time in unix epoch seconds
    address crowdsaleAddress;
    Crowdsale crowdsale;
    constructor()
        public
    {
        // create SWN token interface
        token = new SWpLGE();
        openingTime = now; // Setup openingTime in unix epoch seconds
        closingTime = now.add(1209600); // Setup openingTime in unix epoch seconds, open for 2 weeks
        cap = 1000000000000000000; // 75 ETH cap
        // create the crowdsale and tell it about the token
        crowdsale = new SWpreLiquiditySale(
            100,               // rate, still in TKNbits
            msg.sender,      // send Ether to the deployer
            token,           // the token
            cap,             // max cap
            openingTime,     // opening time in unix epoch seconds
            closingTime      // closing time in unix epoch seconds
        );
        // transfer the minter role from this contract (the default)
        // to the crowdsale, so it can mint tokens
        crowdsaleAddress = address(crowdsale);
        token.addMinter(crowdsaleAddress);
        token.renounceMinter();

    }
    function getSaleAddress() public view returns (address) {
        return crowdsaleAddress;
    }
    function totalFundsRaisedInWei() public view returns (uint256) {
        return crowdsale.weiRaised();
    }
    function contractBalanceInWei() public view returns (uint256) {
        return address(this).balance;
    }

}