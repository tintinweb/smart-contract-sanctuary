// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./libs.sol";
import "./IBEP20.sol";
import "./MultiCollection.sol";
import "./ReentrancyGuard.sol";


contract InoCrowdFunding is Ownable, AdminRole, ReentrancyGuard{
    using SafeMath for uint;
    using UintLibrary for uint;
    using SafeBEP20 for IBEP20;
    
    // @notice The struct manages Ino deadlines
    // @param start - Start time of Ino funding in UNIX format 
    // @param end - End time of Ino funding in UNIX format 
    struct Deadlines{
        uint start;
        uint end;
    }

    // @notice The Main Ino funding's struct
    // @param tokenId - Token id to minting
    // @param creator - The address of the creator of the new token
    // @param fixContribution - The fixed amount of contributions
    // @param fundingFee -  fundingFee - Percent of fee that will gold in this contract
    // For example - fundingFee = 10. Contributions amount - 1000 
    // Will remain in the contract -1000*(10/100)
    // @param deadlines - Filled Deadline struct
    // @param completing - Filled Completing struct
    struct Funding{
        uint tokenId;
        address payable creator;
        uint fixContribution;
        uint fundingFee;
        uint maxCopies;
        Deadlines deadlines;
    }
    
    // Amount of the tokens that was holded in this contract.
    // Owner can transfer this tokens to his address
    uint public holdedTokensAmount;
    // All ino fudings by their id
    mapping (uint => Funding) public fundings;
    // Is funding by fundId opened
    mapping (uint => bool) public isOpen;
    // Array of contributions by ino funding id
    mapping (uint => address payable[]) public contributions;

    
    IBEP20 OriInterface;
    InoMultiCollection InoInterface;
    
    // @param _interfaceOri - address of the BEP20 token (ORI main contract)
    // @param _interfaceIno - address of the InoMultiCollection contract (NFT)
    constructor(IBEP20 _interfaceOri, InoMultiCollection _interfaceIno, address _admin) {
        OriInterface = _interfaceOri;
        InoInterface = _interfaceIno;
        holdedTokensAmount = 0;
        
        _addAdmin(msg.sender);
        _addAdmin(_admin);
    }
    
    modifier isOpened(uint256 _fundId){
        require(isOpen[_fundId], "This funding is closed");
        _;
    }
    
    event InoCreated(uint256 indexed tokenId, bool isOpen);
    event InoContributed(uint256 inoId, uint256 indexed tokenId, uint256 contributeAmount, address buyer, address creator, uint numberCopies);
    event InoClosed(uint256 inoId, uint256 indexed tokenId, uint256 contributeAmount);
    event InoCompleted(uint256 inoId, uint256 indexed tokenId, uint256 awardAmount);
    
    // @notice Checks the existence of the token by its Id
    // @param _id - token id
    // @return True if token aldready exists
    function isMinted(uint _id) view internal returns(bool) {
        if(InoInterface.creators(_id) == address(0)){return false;}
        return true;
    }

    // @notice Creates Ino funding
    // @param _fundId - Id of new token to minting. The funding will be created with this Id
    // @param _creator - Address of the new token creator
    // @param _fixContribution - Fixed contribution amount
    // @param _startTime - Time of start in UNIX format
    // @param _endTime - Time of end in UNIX format
    // @param _fee - Amount of fee in percent format. 1% = 100
    // @param _copies - The allowed number of tokens for minting
    function createIno(uint _fundId, address payable _creator, uint _fixContribution,
        uint _startTime, uint _endTime, uint _fee, uint _copies) public onlyAdmin nonReentrant{
        require(!isMinted(_fundId), "Token is already minted");
        require(!isOpen[_fundId], "Ino is aldready created");
        require(_creator != address(0), "Creator addres must be non zero");
        require(_fixContribution > 0, "Amount of fixContribution must be more 0");
        require(_fee <= 10000, "Amount of fee must be less");
        require(_copies <= 1000 && _copies > 0, "Number of copies must be non-zero and less than 1000");
        
        fundings[_fundId] = Funding(_fundId, _creator, _fixContribution, _fee, _copies, Deadlines(_startTime, _endTime));
        isOpen[_fundId] = true;
        
        emit InoCreated(fundings[_fundId].tokenId, isOpen[_fundId]);
    }
    
    // @notice Returns Ino funding by its id
    // @param _id - Ino funding id
    function getFunding(uint _id) view public returns(Funding memory) {
        return fundings[_id];
    }
    
    // @notice Returns list of the contributions by Ino funding id
    // @param _id - Ino funding id
    function getContributions(uint _id) view public returns(address payable[] memory){
        return contributions[_id];
    }
    
    // @notice Adds new contribution to Ino by its id
    // Before calling you need to approve some token's amount to this contract
    // Some amount will be holded at this contract
    // @param _fundId - Ino funding id
    // @param amount - amount of contributing ino
    function contribute(uint _fundId, uint amount) external isOpened(_fundId) nonReentrant{
        require(amount > 0, "Amount must be non-zero");
        require(fundings[_fundId].deadlines.start < block.timestamp, "Too early");
        require(fundings[_fundId].deadlines.end > block.timestamp, "Too late");
        require(fundings[_fundId].maxCopies >= contributions[_fundId].length+amount, "There are no more copies");
        require(OriInterface.allowance(msg.sender, address(this)) >= amount.mul(fundings[_fundId].fixContribution), "Not enough approved tokens");
        
        OriInterface.safeTransferFrom(msg.sender, address(this), amount.mul(fundings[_fundId].fixContribution));
        
        for (uint i = 0; i < amount; i++)
            contributions[_fundId].push(payable(msg.sender));
            
        uint awardAmount = fundings[_fundId].fixContribution.sub(fundings[_fundId].fixContribution.mul(amount).bp(fundings[_fundId].fundingFee));
        holdedTokensAmount = holdedTokensAmount.add(fundings[_fundId].fixContribution.mul(amount).bp(fundings[_fundId].fundingFee));

        emit InoContributed(_fundId, fundings[_fundId].tokenId, awardAmount, msg.sender, fundings[_fundId].creator, amount);
    }
    
    // @notice Only for owner. Closes Ino by its id
    // All contributions will be refunded to contributors
    // But some amount already holded at this contract
    // Ino will be closed if all contributors have recieved their contributions
    // @param _fundId - Ino funding id 
    function closeIno(uint _fundId) external onlyAdmin isOpened(_fundId) nonReentrant{
        uint awardAmount = fundings[_fundId].fixContribution.sub(fundings[_fundId].fixContribution.bp(fundings[_fundId].fundingFee));
        
        for(uint i = 0; i < contributions[_fundId].length; i++){
            OriInterface.safeTransfer(contributions[_fundId][i], awardAmount);
        }

        isOpen[_fundId] = false;

        emit InoClosed(_fundId, fundings[_fundId].tokenId, awardAmount);
    } 

    // @notice Only for owner. Completes and closes Ino by its id
    // Will complete minting a new NFT
    // Contributions will be transfered to Ino creator address
    // But some amount already holded at this contract
    // @param _fundId - Ino funding id 
    // @param _creatorFee - Creator fee for minting
    // @param _uri - Uri for minting
    function completeIno(uint _fundId, uint _creatorFee, string calldata _uri) external onlyAdmin isOpened(_fundId) nonReentrant{
        uint awardAmount = fundings[_fundId].fixContribution.mul(contributions[_fundId].length);
        awardAmount = awardAmount.sub(awardAmount.bp(fundings[_fundId].fundingFee));

        OriInterface.safeTransfer(fundings[_fundId].creator, awardAmount);    
        InoInterface.mintIno(fundings[_fundId].tokenId, fundings[_fundId].creator, contributions[_fundId], fundings[_fundId].fixContribution, _creatorFee, _uri);
        isOpen[_fundId] = false;

        emit InoCompleted(_fundId, fundings[_fundId].tokenId, awardAmount);
    } 

    function getFundingAmount(uint _fundId) external view returns(uint256 contributedAmount, uint256 holdedByContract){
        uint awardAmount = fundings[_fundId].fixContribution * contributions[_fundId].length;
        uint holdedAmount =  awardAmount.bp(fundings[_fundId].fundingFee);
        awardAmount = awardAmount.sub(holdedAmount);
        return (awardAmount, holdedAmount);
    } 
    
    // @notice Transfers holded BEP20 tokens to the contract owner
    // Only for contract owner
    // @param _amount - amount of tokens to transfer
    function transferHoldedOri(uint _amount) public onlyOwner nonReentrant{
        require(holdedTokensAmount >= _amount, "Not enough tokens");
        OriInterface.safeTransfer(owner(), _amount);
        holdedTokensAmount = holdedTokensAmount.sub(_amount);
    }
    
    // @notice Adds the Admin Role to new address
    function addAdmin(address admin) public onlyOwner{
        _addAdmin(admin);
    }
    
    // @notice Removes the Admin Role from the address 
    function removeAdmin(address admin) public onlyOwner{
        _removeAdmin(admin);
    }
}