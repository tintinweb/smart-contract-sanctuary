// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./SafeMath.sol";


contract TokenAirdrop {
    using SafeMath for uint;
    /**
     * @dev Airdrop Token Address
     */
    IERC20 public AirdropToken;
    
    /**
     * @dev Creator
     */
    address public Creator;
    
    /**
     * @dev Verify
     */
    address internal Verify;
    
    /**
     * @dev Airdrop Owner
     */
    address payable public FeeOwner;
    
    /**
     * @dev totalAirdropSupply
     */
    uint256 public totalAirdropSupply;
    
    /**
     * @dev totalAirdropClaimed
     */
    uint256 public totalAirdropClaimed;
    
    /**
     * @dev totalAirdropUser
     */
    uint256 public totalAirdropUser;
    
    /**
     * @dev maxAirdropUser
     */
    uint256 internal maxAirdropUser;
    
    /**
     * @dev AirdropFee
     */
    uint256 public AirdropFee;
    
    
    /**
     * @dev AirdropStart
     */
    bool internal AirdropStart;
    
    /**
     * @dev has user claimed his Airdrop
     */
    mapping(address => bool) public claimed;
    

    /**
     * @dev List of Investors
     */
    address[] internal investors;
    
    /**
     * @dev some events
     */
    event deleteAirdrops(address user);
    event claimAirdrop(address user, uint balance, uint date);
    event resetAirdrop(address admin, uint date);
    event withdrawFees(address admin, address recipient, uint balance, uint date);
    event withdrawWelb(address admin, address recipient, uint balance, uint date);
    event changeFeeWallet(address admin, address newfeewallet, uint date);
    
    /**
     * @dev set the `WELBv2` ERC20/BEP20 contract Address and set the `feeowner`
     */
    constructor(address _token, address _feeowner, uint _totalAirdropSupply, uint _totalAirdropUser){
        FeeOwner = payable(_feeowner);
        Creator = msg.sender;
        AirdropToken = IERC20(_token);
        AirdropFee = 25e14;
        totalAirdropSupply = _totalAirdropSupply.mul(1 ether);
        totalAirdropUser = _totalAirdropUser;
        genRandomAddress();
    }

    
    /**
     * @dev reset the Airdrop Contract
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {deleteAirdrops} event.
     */
    function ResetAirdrop() OnlyTeam() external returns(bool){
        for (uint i = 0; i < investors.length ; i++){
            delete claimed[investors[i]];
        }
        
        delete totalAirdropUser;
        delete totalAirdropClaimed;
        
        uint balance = address(this).balance;
        if(balance > 0){
            FeeOwner.transfer(address(this).balance);
            emit withdrawFees(msg.sender, FeeOwner, balance, block.timestamp);
        }
               
        
        uint TokenBalance = AirdropToken.balanceOf(address(this));
        if(TokenBalance > 0){
            AirdropToken.transfer(Creator, TokenBalance);
            emit withdrawWelb(msg.sender, FeeOwner, TokenBalance, block.timestamp);
        }
        
        emit resetAirdrop(msg.sender, block.timestamp);
        
        return true;
    }
    
    /**
     * @dev The Airdrop user requests his token by calling this function.
     * If the user is not on the whitelist or the user has already claimed, 
     * then the feature will be reset.
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {claimAirdrop} event.
     */
    function Claim(uint balance, address _verify) payable external returns(bool){
        require(totalAirdropUser > 0, "Total User claimed");
        require(AirdropStart, "Airdrop has not Started");
        require(_verify == Verify, "you not Verify");
        require(claimed[msg.sender] == false, "you have already claimed");
        require(msg.value == AirdropFee, "You do not have enough funds to pay the distribution fees");
        require(balance > 0, "balance must greater then zero");
        
        claimed[msg.sender] = true;
        investors.push(msg.sender);
        totalAirdropUser--;
        totalAirdropClaimed = totalAirdropClaimed.add(balance.mul(1 ether));
        totalAirdropSupply = totalAirdropSupply.sub(balance.mul(1 ether));

        AirdropToken.transfer(msg.sender, balance.mul(1 ether));
        
        emit claimAirdrop(msg.sender, balance.mul(1 ether), block.timestamp);
        
        return true;
    }
    
    /**
     * @dev cahnge the transaction fee by `fee`
     * fee will convert to ether.
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function ChangeAirdropFee(uint fee) external OnlyTeam() returns(bool){
        AirdropFee = fee;
        return true;
    }
    
    /**
     * @dev check the Fee Balance
     * 
     * 
     * Returns a uint value indicating whether the operation succeeded.
     */
    function FeeBalance() external OnlyTeam() view returns(uint){
        return address(this).balance;
    }
    
    /**
     * @dev check the Welb Contract Balance
     * 
     * 
     * Returns a uint value indicating whether the operation succeeded.
     */
    function AirdropTokenBalance() external OnlyTeam() view returns(uint){
        return AirdropToken.balanceOf(address(this));
    }
    
     /**
     * @dev change the Fee Wallet `feewallet`
     * 
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function ChangeFeeWallet(address payable feewallet) external OnlyTeam() returns(bool){
        require(feewallet != address(0), "Wallet is Zero address");
        require(feewallet != FeeOwner, "Wallet is Zero address");
        FeeOwner = feewallet;
        
        emit changeFeeWallet(msg.sender, feewallet, block.timestamp);
        return true;
    }
    
    /**
     * @dev withdraw the Fees to Owner
     * 
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function WithdrawFees() external OnlyTeam() returns(bool){
        uint balance = address(this).balance;
        require(balance > 0, "no balance");
        FeeOwner.transfer(address(this).balance);
        
        emit withdrawFees(msg.sender, FeeOwner, balance, block.timestamp);
        return true;
    }
    
    /**
     * @dev withdraws the remaining Token after the airdop
     * 
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function WithdrawWelb() external OnlyTeam() returns(bool){
        uint TokenBalance = AirdropToken.balanceOf(address(this));
        require(TokenBalance > 0, "no balance");
        AirdropToken.transfer(Creator, TokenBalance);
        
        emit withdrawWelb(msg.sender, FeeOwner, TokenBalance, block.timestamp);
        return true;
    }
    
    /**
     * @dev withdraws the remaining Token after the airdop
     * 
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function ChangeAirdropToken(address newToken) external OnlyTeam() returns(bool){
        IERC20 _newtoken = IERC20(newToken);
        require(_newtoken != AirdropToken, "Airdoptoken are the same Address");
        AirdropToken = _newtoken;
        
        return true;
    }
    
    /**
     * @dev see getRandomAddress()
     * 
     * 
     * Returns a address value indicating whether the operation succeeded.
     */
    function getRandomAddress() external OnlyTeam() view returns(address) {
        return Verify;
    }
    
    
    /**
     * @dev see genRandomAddress()
     * 
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function setRandomAddress() external OnlyTeam() {
        genRandomAddress();
    }
    
    /**
     * @dev get verfy address for Claiming the Airdrop
     * 
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function genRandomAddress() internal {
        Verify = address(bytes20(keccak256(abi.encodePacked(block.timestamp))));
    }
    
    /**
     * @dev see genRandomAddress()
     * 
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function setTotalsAirdropSupplyAndUser(uint _totalAirdropSupply, uint _totalAirdropUser) external OnlyTeam() {
        totalAirdropSupply = _totalAirdropSupply;
        totalAirdropUser = _totalAirdropUser;
    }
    
    /**
     * @dev get the Airdrop Status
     * 
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function AirdropStatus() external view returns(bool){
        return AirdropStart;
    }
    
    /**
     * @dev Start / Stop the Airdrop
     * 
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function StartAirdrop(bool start) external OnlyTeam() returns(bool){
        AirdropStart = start;
        return true;
    }

    /**
     * @dev modifire to access some function only for Team
     */
    modifier OnlyTeam(){
        require(msg.sender == FeeOwner || msg.sender == Creator, "OnlyTeam");
        _;
    }
    
    
}