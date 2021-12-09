// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

/*
  basic assumptions:
  - every new whitelisted user is distinct from (1) old whitelisted users and (2) old LBE participants
    i.e. an address can only participate in either the old or the new LBE
  - every blacklisted user is a bot who should not be able to claim
*/

contract SBRSale {
    function dev() public view returns( address ) {}
    function sold() public view returns( uint ) {}
    function invested( address addr ) public view returns( uint ) {}
}

contract SBRPresale is Ownable {
    using SafeERC20 for ERC20;
    using Address for address;

    uint constant MIMdecimals = 10 ** 18;
    uint constant SBRdecimals = 10 ** 9;
    uint public constant MAX_SOLD = 15000 * SBRdecimals;
    uint public constant PRICE = 5 * MIMdecimals / SBRdecimals ;
    uint public constant MIN_PRESALE_PER_ACCOUNT = 1 * SBRdecimals;
    uint public constant MAX_PRESALE_PER_ACCOUNT = 100 * SBRdecimals;

    address public dev;
    ERC20 MIM;

    uint public sold;
    address public SBR;
    bool canClaim;
    bool privateSale;
    mapping( address => uint256 ) public invested;
    mapping( address => bool ) public claimed;
    mapping( address => bool ) public approvedBuyers;
    mapping( address => bool ) public blacklisted;

    constructor() {
        MIM = ERC20(0x130966628846BFd36ff31a822705796e8cb8C18D);
        dev = 0xF1a02ad80a71F37386473eA713F03F8FaBd25044;
    }


    modifier onlyEOA() {
        require(msg.sender == tx.origin, "!EOA");
        _;
    }

    /* approving buyers into new whitelist */

    function _approveBuyer( address newBuyer_ ) internal onlyOwner() returns ( bool ) {
        approvedBuyers[newBuyer_] = true;
        return approvedBuyers[newBuyer_];
    }

    function approveBuyer( address newBuyer_ ) external onlyOwner() returns ( bool ) {
        return _approveBuyer( newBuyer_ );
    }

    function approveBuyers( address[] calldata newBuyers_ ) external onlyOwner() returns ( uint256 ) {
        for( uint256 iteration_ = 0; newBuyers_.length > iteration_; iteration_++ ) {
            _approveBuyer( newBuyers_[iteration_] );
        }
        return newBuyers_.length;
    }

    function _deapproveBuyer( address newBuyer_ ) internal onlyOwner() returns ( bool ) {
        approvedBuyers[newBuyer_] = false;
        return approvedBuyers[newBuyer_];
    }

    function deapproveBuyer( address newBuyer_ ) external onlyOwner() returns ( bool ) {
        return _deapproveBuyer(newBuyer_);
    }

    /* blacklisting old buyers who shouldn't be able to claim; subtract contrib from sold allocation */

    function _blacklistBuyer( address badBuyer_ ) internal onlyOwner() returns ( bool ) {
        blacklisted[badBuyer_] = true;
        return blacklisted[badBuyer_];
    }

    function blacklistBuyer( address badBuyer_ ) external onlyOwner() returns ( bool ) {
        return _blacklistBuyer( badBuyer_ );
    }

    function blacklistBuyers ( address[] calldata badBuyers_ ) external onlyOwner() returns ( uint256 ) {
        for ( uint256 iteration_ = 0; badBuyers_.length > iteration_; iteration_++ ) {
            _blacklistBuyer( badBuyers_[iteration_] );
        }
        return badBuyers_.length;
    }

    /* allow non-blacklisted users to buy SBR */

    function amountBuyable(address buyer) public view returns (uint256) {
        uint256 max;
        if ( approvedBuyers[buyer] && privateSale ) {
            max = MAX_PRESALE_PER_ACCOUNT;
        }
        return max - invested[buyer];
    }

    function buySBR(uint256 amount) public onlyEOA {
        require(sold < MAX_SOLD, "sold out");
        require(sold + amount < MAX_SOLD, "not enough remaining");
        require(amount <= amountBuyable(msg.sender), "amount exceeds buyable amount");
        require(amount + invested[msg.sender] >= MIN_PRESALE_PER_ACCOUNT, "amount is not sufficient");
        MIM.safeTransferFrom( msg.sender, address(this), amount * PRICE  );
        invested[msg.sender] += amount;
        sold += amount;
    }

    // set SBR token address and activate claiming
    function setClaimingActive(address sbr) public {
        require(msg.sender == dev, "!dev");
        SBR = sbr;
        canClaim = true;
    }

    // claim SBR allocation based on old + new invested amounts
    function claimSBR() public onlyEOA {
        require(canClaim, "cannot claim yet");
        require(!claimed[msg.sender], "already claimed");
        require(!blacklisted[msg.sender], "blacklisted");
        if ( invested[msg.sender] > 0 ) {
            ERC20(SBR).transfer(msg.sender, invested[msg.sender]);
        } 
        claimed[msg.sender] = true;
    }

    // token withdrawal by dev
    function withdraw(address _token) public {
        require(msg.sender == dev, "!dev");
        uint b = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(dev,b);
    }

    // manual activation of whitelisted sales
    function activatePrivateSale() public {
        require(msg.sender == dev, "!dev");
        privateSale = true;
    }

    // manual deactivation of whitelisted sales
    function deactivatePrivateSale() public {
        require(msg.sender == dev, "!dev");
        privateSale = false;
    }

    function setSold(uint _soldAmount) public onlyOwner {
        sold = _soldAmount;
    }
}