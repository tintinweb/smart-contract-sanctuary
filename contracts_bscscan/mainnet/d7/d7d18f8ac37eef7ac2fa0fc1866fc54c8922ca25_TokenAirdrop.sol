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
     * @dev AirdropSender
     */
    address public Creator;
    
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
     * @dev AirdropFee
     */
    uint256 public AirdropFee;
    

    /**
     * @dev has user claimed his Airdrop
     */
    mapping(address => bool) public claimed;
    
    /**
     * @dev Whitelist Uaser list
     */
    mapping(address => bool) public WhiteList;
    
    /**
     * @dev how many can user claim
     */
    mapping(address => uint256) public AirdropBalance;
    
    address[] internal investers;
    
    /**
     * @dev some events
     */
    event addAirdrops(address user, uint balance);
    event deleteAirdrops(address user);
    event claimAirdrop(address user, uint balance, uint date);
    event resetAirdrop(address admin, uint date);
    event withdrawFees(address admin, address recipient, uint balance, uint date);
    event withdrawWelb(address admin, address recipient, uint balance, uint date);
    event changeFeeWallet(address admin, address newfeewallet, uint date);
    /**
     * @dev set the `WELBv2` ERC20/BEP20 contract Address and set the `feeowner`
     */
    constructor(address token, address feeowner){
        FeeOwner = payable(feeowner);
        Creator = msg.sender;
        AirdropToken = IERC20(token);
        AirdropFee = 25e14;
    }
    
    
    /**
     * @dev add array of `user` by the same value of `balance`
     * to the Airdrop Sender
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {addAirdrops} event.
     */
    function AddAirdrops(address[] memory user, uint[] memory balance) OnlyTeam() external returns(bool){
        require(user.length == balance.length, "address and balance not the same count");
        for(uint i = 0; i < user.length; i++){
            
            if(claimed[user[i]])
                continue;
            WhiteList[user[i]] = true;
            AirdropBalance[user[i]] = balance[i].mul(1 ether);
            totalAirdropSupply = totalAirdropSupply.add(AirdropBalance[user[i]]);
            totalAirdropUser++;
            investers.push(user[i]);
            emit addAirdrops(user[i], AirdropBalance[user[i]]);
        }
        return true;
    }
    
    /**
     * @dev delete `user` from the Airdrop Sender
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {deleteAirdrops} event.
     */
    function DeleteAirdrop(address user) OnlyTeam() external returns(bool){
        address[] memory _user;
        _user[0] = user;
        return DeleteAirdrop(_user);
    }
    
    /**
     * @dev delete an array of `user` from the Airdrop Sender
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {deleteAirdrops} event.
     */
    function DeleteAirdrop(address[] memory user) internal returns(bool){
        for(uint i = 0; i < user.length; i++){
            if(user[i] == investers[i]){
                investers[i] = investers[investers.length - 1];
                investers.pop();
            }
            delete claimed[user[i]];
            delete WhiteList[user[i]];
            delete AirdropBalance[user[i]];
            totalAirdropSupply = totalAirdropSupply.sub(AirdropBalance[user[i]]);
            totalAirdropUser--;
            emit deleteAirdrops(user[i]);
        }

        return true;
    }
    
    
    /**
     * @dev reset the Airdrop Contract
     * 
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {deleteAirdrops} event.
     */
    function ResetAirdrop() OnlyTeam() external returns(bool){
        for (uint i = 0; i < investers.length ; i++){
            delete claimed[investers[i]];
            delete WhiteList[investers[i]];
            delete AirdropBalance[investers[i]];

        }
        
        delete totalAirdropUser;
        delete totalAirdropSupply;
        delete totalAirdropClaimed;
        delete investers;
        
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
    function Claim() StartAirdrop() payable external returns(bool){
        require(WhiteList[msg.sender], "not in Whitelist");
        require(claimed[msg.sender] == false, "you have already claimed");
        require(msg.value == AirdropFee, "You do not have enough funds to pay the distribution fees");
        
        uint _airdropBalance = AirdropBalance[msg.sender];
        AirdropBalance[msg.sender] = 0;
        claimed[msg.sender] = true;
        totalAirdropClaimed = totalAirdropClaimed.add(_airdropBalance);
        
        AirdropToken.transfer(msg.sender, _airdropBalance);
        emit claimAirdrop(msg.sender, _airdropBalance, block.timestamp);
        
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
     * @dev Check the availability of the tokens in the contract. 
     * The number must be the same or higher than the Airdop tokens
     * 
     * Returns a boolean value and a uint value with the number of Token.
     * by false returns the differents between Contract Balance and Airdop User Balance
     */
    function CheckBalanceForAirdrop() external OnlyTeam() view returns(bool, uint){
        return _CheckBalanceForAirdrop();
    }
 
    /**
     * @dev see CheckBalanceForAirdrop()
     */
    function _CheckBalanceForAirdrop() internal view returns(bool, uint){
        uint contractBalance = AirdropToken.balanceOf(address(this));
        if(totalAirdropSupply == contractBalance){
            return (true, totalAirdropSupply);
            
        }else if(totalAirdropSupply < contractBalance){
            return (true, contractBalance.sub(totalAirdropSupply));
            
        }else {
            return (false, totalAirdropSupply.sub(contractBalance));
        }
    }
    
    /**
     * @dev modifire to check the Status to Start or Stop the Airdrop
     */
    modifier StartAirdrop(){
        (bool _StartAirdrop, ) = _CheckBalanceForAirdrop();
        require(_StartAirdrop, "Airdrop does not have enough WELB. Contact Support");
        _;
    }
    
    /**
     * @dev modifire to access some function only for Team
     */
    modifier OnlyTeam(){
        require(msg.sender == FeeOwner || msg.sender == Creator, "OnlyTeam");
        _;
    }
    
    
}