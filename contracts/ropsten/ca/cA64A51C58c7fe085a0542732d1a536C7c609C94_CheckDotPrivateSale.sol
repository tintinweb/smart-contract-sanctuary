// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./IExtendedERC20.sol";

contract CheckDotPrivateSale {
    using SafeMath for uint256;


    address private                         _owner;
    IExtendedERC20 private                  _cdtToken;
    mapping(address => uint256) private     _wallets_investment;

    uint256 public                          _ethSolded;
    uint256 public                          _cdtSolded;
    uint256 public                          _cdtPereth;
    uint256 public                          _maxethPerWallet;
    bool public                             _paused = false;
    bool public                             _claim = false;

    event NewAmountPresale (
        uint256 srcAmount,
        uint256 cdtPereth,
        uint256 totaCdt
    );

    /*
    ** Description: constructing the contract basic informations, containing the CDT token addr, the ratio price eth:CDT
    ** and the max authorized eth amount per wallet
    */
    constructor(address checkDotTokenAddr, uint256 cdtPereth, uint256 maxethPerWallet)
    {
        _owner = msg.sender;
        _ethSolded = 0;
        _cdtPereth = cdtPereth;
        _cdtToken = IExtendedERC20(checkDotTokenAddr);
        _maxethPerWallet = maxethPerWallet;
    }

    /*
    ** Description: Check that the transaction sender is the CDT owner
    */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can do this action");
        _;
    }

    /*
    ** Receive eth payment for the presale raise
    */
    receive() external payable {
        require(_paused == false, "Presale is paused");
        uint256 totalInvested = _wallets_investment[address(msg.sender)].add(msg.value);
        require(totalInvested <= _maxethPerWallet, "You depassed the limit of max eth per wallet for the presale.");
        _transfertCDT(msg.value);
    }

    /*
    ** Description: Set the presale in pause state (no more deposits are accepted once it's turned back)
    */
    function setPaused(bool value) public payable onlyOwner {
        _paused = value;
    }

    /*
    ** Description: Set the presale claim mode 
    */
    function setClaim(bool value) public payable onlyOwner {
        _claim = value;
    }

    /*
    ** Description: Claim the CDT once the presale is done
    */
    function claimCdt() public
    {
        require(_claim == true, "You cant claim your CDT yet");
        uint256 srcAmount =  _wallets_investment[address(msg.sender)];
        require(srcAmount > 0, "You dont have any CDT to claim");
        
        uint256 cdtAmount = (srcAmount.mul(_cdtPereth)).div(10 ** 18);
         require(
            _cdtToken.balanceOf(address(this)) >= cdtAmount,
            "No CDT amount required on the contract"
        );
        _wallets_investment[address(msg.sender)] = 0;
        _cdtToken.transfer(msg.sender, cdtAmount);
    }


    /*
    ** Description: Return the amount raised from the Presale (as ETH)
    */
    function getTotalRaisedEth() public view returns(uint256) {
        return _ethSolded;
    }

        /*
    ** Description: Return the amount raised from the Presale (as CDT)
    */
    function getTotalRaisedCdt() public view returns(uint256) {
        return _cdtSolded;
    }

    /*
    ** Description: Return the total amount invested from a specific address
    */
    function getAddressInvestment(address addr) public view returns(uint256) {
        return  _wallets_investment[addr];
    }

    /*
    ** Description: Transfer the specific CDT amount to the payer address
    */
    function _transfertCDT(uint256 _srcAmount) private {
        uint256 cdtAmount = (_srcAmount.mul(_cdtPereth)).div(10 ** 18);
        emit NewAmountPresale(
            _srcAmount,
            _cdtPereth,
            cdtAmount
        );

        require(
            _cdtToken.balanceOf(address(this)) >= cdtAmount.add(_cdtSolded),
            "No CDT amount required on the contract"
        );

        _ethSolded += _srcAmount;
        _cdtSolded += cdtAmount;
        _wallets_investment[address(msg.sender)] += _srcAmount;
    }

    /*
    ** Description: Authorize the contract owner to withdraw the raised funds from the presale
    */
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        _cdtToken.transfer(msg.sender, _cdtToken.balanceOf(address(this)));
    }
}