/**
 *Submitted for verification at BscScan.com on 2021-11-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;


/// @title Windoge Defender
/// @dev A smart contract that splits and sends BNB to three different wallets

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WindogeDefender is Context, Ownable{

    address private _teamAdd;
    address private _devAdd;
    uint256 private teamFee;
    uint256 private devFee;

    constructor( address teamWallet, address devWallet){
        _teamAdd = teamWallet;
        _devAdd = devWallet;
    }

    receive() external payable {
    }
    
    //// @notice Send BNB to the wallets
    /// @dev Split BNB balance based on marketing and team tax.
    ///   "devWallet" will receive always 25% of team part.
    function forwardFunds() internal {
        uint256 BNBbalance = address(this).balance;
        uint256 teamBNB = BNBbalance  * teamFee / 100;
        uint256 devBNB = BNBbalance * devFee / 100;

        if(teamBNB > 0) payable(_teamAdd).transfer(teamBNB);
        if(devBNB > 0) payable(_devAdd).transfer(devBNB);
    }

    function forceForwardFunds() external {
        forwardFunds();
    }
    
    /// @dev Update the wallets. They must be different from dead address
    ///    to avoid BNB losts.
    function setWallets(address teamWallet, address devWallet) external onlyOwner{
        require(teamWallet != address(0x000000000000000000000000000000000000dEaD));
        require(devWallet != address(0x000000000000000000000000000000000000dEaD));
        _teamAdd = teamWallet;
        _devAdd = devWallet;
    }
    
    function setFees(uint256 _teamFee, uint256 _devFee) external onlyOwner{
        teamFee = _teamFee;
        devFee = _devFee;
    }
    
    /// @notice Withdraws tokens sent by mistake to the contract
    /// @param tokenAddress The address of the token to withdraw
    function rescueTokensWronglySent(IERC20 tokenAddress) external onlyOwner{
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        address payable wallet = payable(msg.sender);
        tokenBEP.transfer(wallet, tokenAmt);
    }
}