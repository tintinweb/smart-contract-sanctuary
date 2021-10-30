//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ReentrantGuard.sol";
import "./IPresale.sol";


/**
 *
 * Presale Contract Developed by Markymark ( MoonMark / DeFi Mark )
 * Cause DxSale is overpriced and inefficient
 *
 */
contract PresaleManager is ReentrancyGuard{

    using SafeMath for uint256;
    using Address for address;
    
    // Token owners to enable sale
    address _owner;
    
    uint256 public totalCustomers;

    // list of Presale Users
    mapping ( address => uint256 ) users;

    // number of tokens to give to holder per BNB
    uint256 _tokensPerBNB = 400000 * 10**9;
    
    // presale token
    address constant _tokenContract = 0xcEff4b7001Db64e12131ce70FA96f42C4ad52058;
    
    uint256 dataIndex;
    
    // Contract Control Modifiers 
    modifier onlyOwner() {require(msg.sender == _owner, 'Only Owner Function'); _;}

    // initialize
    constructor(
        
    ) {
        _owner = msg.sender;
    }
    
    function claimTokens() external nonReentrant{
        uint256 currentClaim = users[msg.sender];
        require(currentClaim > 0, 'No Tokens To Claim');
        users[msg.sender] = 0;
        bool success = IERC20(_tokenContract).transfer(msg.sender, currentClaim);
        require(success, 'Token Transfer Failed');
        emit TokenClaimed(msg.sender, currentClaim);
    }
    
    function getNUsers() external view returns (uint256) {
        return IPresale(0x70059A0B4eC9FAED2ea49e8409b9eb366964abe5).getRegisteredUsers().length;
    }
    
    function loadData(uint256 iterations) external onlyOwner {
        
        address[] memory oldUsers = IPresale(0x70059A0B4eC9FAED2ea49e8409b9eb366964abe5).getRegisteredUsers();
        for (uint i = 0; i < iterations; i++) {
            if (dataIndex >= oldUsers.length) {
                dataIndex = 0;
                return;
            }
            
            users[oldUsers[dataIndex]] = IPresale(0x70059A0B4eC9FAED2ea49e8409b9eb366964abe5).tokensToClaim(oldUsers[dataIndex]);
            totalCustomers++;
            dataIndex++;
        }
        
    }
    
    function emergencyWithdraw() external onlyOwner {
        
        uint256 bal = IERC20(_tokenContract).balanceOf(address(this));
        if (bal > 0) {
            IERC20(_tokenContract).transfer(_owner, bal);
        }
        if (address(this).balance > 0) {
            (bool s,) = payable(_owner).call{value: address(this).balance}("");
            require(s, 'Fee Payment Failed');
        }
    }
    
    function tokenBalanceInContract() public view returns (uint256) {
        return IERC20(_tokenContract).balanceOf(address(this));
    }
    
    function tokensToClaim(address holder) external view returns(uint256) {
        return users[holder];
    }


    /** Register Sender In Presale */
    receive() external payable {
        uint256 currentClaim = users[msg.sender];
        require(currentClaim > 0, 'No Tokens To Claim');
        users[msg.sender] = 0;
        bool success = IERC20(_tokenContract).transfer(msg.sender, currentClaim);
        require(success, 'Token Transfer Failed');
        emit TokenClaimed(msg.sender, currentClaim);
    }

    // Events
    event PresaleStarted();
    event PresaleCanceled();
    event PresaleFinished();
    event WhitelistEnabled();
    event WhitelistDisabled();
    event PresaleDestroyedByOwner();
    event TokensPairedIntoLiquidity(uint256 tokensPaired, uint256 bnbPaired);
    event UserRegisteredInPresale(address user, uint256 tokenClaim);
    event TokenClaimed(address claimer, uint256 tokenBalance);
    event BNBReClaimed(address claimer, uint256 BNBBalance);
}